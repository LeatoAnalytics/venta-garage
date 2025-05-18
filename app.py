import os
from flask import Flask, render_template, redirect, url_for, request, jsonify
from pyairtable import Table
from pyairtable.formulas import match
from dotenv import load_dotenv
import boto3
from botocore.exceptions import NoCredentialsError
from datetime import datetime, timedelta
import json
import requests
import locale
from functools import lru_cache

# Load environment variables
load_dotenv()

app = Flask(__name__)

# Airtable configuration
AIRTABLE_API_KEY = os.getenv('AIRTABLE_API_KEY')
AIRTABLE_BASE_ID = os.getenv('AIRTABLE_BASE_ID')
productos_table = Table(AIRTABLE_API_KEY, AIRTABLE_BASE_ID, 'Table 1')

# AWS S3 configuration
AWS_ACCESS_KEY = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
S3_BUCKET = os.getenv('S3_BUCKET_NAME')
S3_REGION = os.getenv('S3_REGION')

# URL expiration time (reduced from 7 days to 3 hours)
URL_EXPIRATION = 10800  # 3 hours in seconds

# Initialize S3 client
s3_client = boto3.client(
    's3',
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY,
    region_name=S3_REGION
)

# Cache for S3 image URLs (TTL slightly less than URL_EXPIRATION)
# This keeps URLs in memory to avoid regenerating them for every request
url_cache = {}
CACHE_TTL = URL_EXPIRATION - 300  # 5 minutes less than URL_EXPIRATION

# Function to clean expired cache entries
def clean_url_cache():
    now = datetime.now()
    expired_keys = [key for key, (_, timestamp) in url_cache.items() 
                   if (now - timestamp).total_seconds() > CACHE_TTL]
    for key in expired_keys:
        url_cache.pop(key, None)

# Filtro personalizado para formatear precios
@app.template_filter('format_price')
def format_price(value):
    """Formato de precio con puntos como separador de miles y símbolo $ al inicio"""
    if value is None:
        return "$0"
    try:
        # Convertir a entero si es posible
        value = int(value)
        # Formatear con puntos como separador de miles
        formatted = "${:,.0f}".format(value).replace(",", ".")
        return formatted
    except (ValueError, TypeError):
        # Devolver el valor original si no se puede formatear
        return f"${value}"

# Cache for active categories - refreshed every 30 minutes
@lru_cache(maxsize=1)
def get_cached_categories():
    return get_active_categories()

# Function to refresh cached categories periodically
def refresh_category_cache():
    get_cached_categories.cache_clear()
    return get_cached_categories()

@app.context_processor
def inject_now():
    """Add date-related variables and active categories to all templates"""
    return {
        'now': datetime.now(),
        'active_categories': get_cached_categories()
    }

def is_product_active(product):
    """Checks if a product is active based on the 'activo' field"""
    # Product is active if the 'activo' field exists and equals 'SI'
    return product.get('fields', {}).get('activo') == 'SI'

def get_active_categories():
    """Get unique categories from products in Airtable"""
    try:
        # Get all products from Airtable
        products = productos_table.all()
        
        # Extract unique categories from active products only
        categories = set()
        for product in products:
            # Only consider categories from active products
            if is_product_active(product):
                category = product.get('fields', {}).get('categoria')
                if category:
                    categories.add(category)
        
        # Sort categories alphabetically
        return sorted(list(categories))
    except Exception as e:
        print(f"Error fetching categories: {e}")
        return []

def get_s3_images_from_folder(base_url):
    """
    Genera URLs prefirmadas para todas las imágenes en una carpeta de S3 a partir de la URL base.
    Retorna la URL de portada.jpg/jpeg como principal y una lista con las demás URLs.
    """
    if not base_url.endswith('/'):
        base_url += '/'
    
    # Check cache first to avoid unnecessary S3 operations
    cache_key = f"s3_folder_{base_url}"
    if cache_key in url_cache:
        urls, timestamp = url_cache[cache_key]
        if (datetime.now() - timestamp).total_seconds() < CACHE_TTL:
            return urls
    
    # Clean expired cache entries periodically
    clean_url_cache()
    
    # Intentar listar los archivos usando boto3
    try:
        # Extraer el nombre del bucket y el prefijo de la carpeta de la URL
        url_parts = base_url.replace('https://', '').split('/')
        bucket_name = url_parts[0].split('.')[0]  # venta-garage
        prefix = '/'.join(url_parts[1:])  # por ejemplo: 'tesla/'
        
        # Listar objetos en esta carpeta
        response = s3_client.list_objects_v2(
            Bucket=S3_BUCKET,
            Prefix=prefix
        )
        
        # URLs para todas las imágenes
        main_image_url = None
        additional_images = []
        
        if 'Contents' in response:
            for obj in response['Contents']:
                key = obj['Key']
                # Verificar si es un archivo de imagen (usar extensiones más comunes)
                if key.lower().endswith(('.jpg', '.jpeg', '.png', '.gif', '.webp')):
                    # Generar URL prefirmada con tiempo de expiración reducido
                    presigned_url = s3_client.generate_presigned_url(
                        'get_object',
                        Params={'Bucket': S3_BUCKET, 'Key': key},
                        ExpiresIn=URL_EXPIRATION
                    )
                    
                    # Verificar si es la imagen principal (portada)
                    if 'portada' in key.lower():
                        main_image_url = presigned_url
                    else:
                        additional_images.append(presigned_url)
        
        # Si no se encontró portada, usar la primera imagen como principal
        if not main_image_url and additional_images:
            main_image_url = additional_images[0]
            additional_images = additional_images[1:]
        elif not main_image_url:
            # Si no hay imágenes, usar un fallback genérico (imagen de placeholder)
            main_image_url = "/static/img/placeholder.jpg"
        
        # Guardar en caché
        result = (main_image_url, additional_images)
        url_cache[cache_key] = (result, datetime.now())
        
        return result
    
    except Exception as e:
        print(f"Error al listar imágenes de S3: {e}")
        # En caso de error, devolver una imagen de placeholder como fallback
        return "/static/img/placeholder.jpg", []

def process_airtable_fields(product):
    """Función para procesar los campos de Airtable y asegurar el formato correcto para las plantillas"""
    # Si el campo imagenes_s3 existe y contiene datos
    if 'imagenes_s3' in product['fields'] and product['fields']['imagenes_s3']:
        base_url = product['fields']['imagenes_s3']
        
        # Generar URLs para todas las imágenes en esta carpeta
        main_image_url, additional_images = get_s3_images_from_folder(base_url)
        
        # Actualizar los campos del producto
        product['fields']['imagenes_s3'] = main_image_url
        product['fields']['imagenes_s3_adicionales'] = additional_images
    
    return product

@app.route('/')
def index():
    """Home page showing all products"""
    try:
        # Get all products from Airtable
        products = productos_table.all()
        
        # Filter active products only
        active_products = [p for p in products if is_product_active(p)]
        
        # Procesar campos para cada producto pero solo obtener la imagen principal
        # para la vista de listado, no todas las imágenes adicionales
        processed_products = []
        for product in active_products:
            # Solo procesamos las imágenes S3 si estamos en la página de detalle
            # Para la página principal, solo necesitamos la imagen de portada
            if 'imagenes_s3' in product['fields'] and product['fields']['imagenes_s3']:
                base_url = product['fields']['imagenes_s3']
                cache_key = f"main_image_{base_url}"
                
                # Intentar obtener de caché primero
                if cache_key in url_cache:
                    main_url, timestamp = url_cache[cache_key]
                    if (datetime.now() - timestamp).total_seconds() < CACHE_TTL:
                        product['fields']['imagenes_s3'] = main_url
                        processed_products.append(product)
                        continue
                
                # Si no está en caché, obtener solo la imagen principal
                try:
                    main_image_url, _ = get_s3_images_from_folder(base_url)
                    product['fields']['imagenes_s3'] = main_image_url
                    url_cache[cache_key] = (main_image_url, datetime.now())
                except Exception as e:
                    print(f"Error al obtener imagen principal: {e}")
                    product['fields']['imagenes_s3'] = "/static/img/placeholder.jpg"
            
            processed_products.append(product)
        
        # No longer filter out sold products, show all active products
        return render_template('index.html', products=processed_products)
    except Exception as e:
        print(f"Error fetching products: {e}")
        # En caso de error, mostramos una página con mensaje de error
        error_message = f"Error al conectar con Airtable: {str(e)}"
        return render_template('error.html', error_message=error_message), 500

@app.route('/producto/<product_id>')
def product_detail(product_id):
    """Product detail page"""
    try:
        # Get product from Airtable by ID
        product = productos_table.get(product_id)
        
        if not product or not is_product_active(product):
            # Return 404 if product doesn't exist or is not active
            return render_template('404.html'), 404
        
        # Procesar imágenes solo si el producto tiene el campo imagenes_s3
        if 'imagenes_s3' in product['fields'] and product['fields']['imagenes_s3']:
            base_url = product['fields']['imagenes_s3']
            
            # Para la vista de detalle, sí necesitamos todas las imágenes
            # pero primero intentamos usar la caché
            cache_key = f"s3_folder_{base_url}"
            if cache_key in url_cache:
                urls, timestamp = url_cache[cache_key]
                if (datetime.now() - timestamp).total_seconds() < CACHE_TTL:
                    main_image_url, additional_images = urls
                    product['fields']['imagenes_s3'] = main_image_url
                    product['fields']['imagenes_s3_adicionales'] = additional_images
                else:
                    # Si la caché expiró, refrescar
                    main_image_url, additional_images = get_s3_images_from_folder(base_url)
                    product['fields']['imagenes_s3'] = main_image_url
                    product['fields']['imagenes_s3_adicionales'] = additional_images
            else:
                # Si no está en caché, obtener de S3
                main_image_url, additional_images = get_s3_images_from_folder(base_url)
                product['fields']['imagenes_s3'] = main_image_url
                product['fields']['imagenes_s3_adicionales'] = additional_images
        
        return render_template('product_detail.html', product=product)
    except Exception as e:
        print(f"Error fetching product: {e}")
        return render_template('404.html'), 404

@app.route('/categorias/<category>')
def category_view(category):
    """View products by category"""
    try:
        # Get all products
        all_products = productos_table.all()
        
        # Filter active products only
        active_products = [p for p in all_products if is_product_active(p)]
        
        # Primero filtramos por categoría para procesar menos productos
        if category == 'Ofertas':
            # For "Ofertas" category, get products with rebajado price
            filtered_products = [p for p in active_products if p['fields'].get('precio_rebajado')]
        else:
            # For regular categories, filter by the specific category
            filtered_products = [p for p in active_products if p['fields'].get('categoria', '') == category]
        
        # Ahora solo procesamos las imágenes de los productos filtrados
        processed_products = []
        for product in filtered_products:
            # Solo procesamos las imágenes S3 si el producto tiene el campo imagenes_s3
            if 'imagenes_s3' in product['fields'] and product['fields']['imagenes_s3']:
                base_url = product['fields']['imagenes_s3']
                cache_key = f"main_image_{base_url}"
                
                # Intentar obtener de caché primero
                if cache_key in url_cache:
                    main_url, timestamp = url_cache[cache_key]
                    if (datetime.now() - timestamp).total_seconds() < CACHE_TTL:
                        product['fields']['imagenes_s3'] = main_url
                        processed_products.append(product)
                        continue
                
                # Si no está en caché, obtener solo la imagen principal
                try:
                    main_image_url, _ = get_s3_images_from_folder(base_url)
                    product['fields']['imagenes_s3'] = main_image_url
                    url_cache[cache_key] = (main_image_url, datetime.now())
                except Exception as e:
                    print(f"Error al obtener imagen principal: {e}")
                    product['fields']['imagenes_s3'] = "/static/img/placeholder.jpg"
            
            processed_products.append(product)
        
        return render_template('index.html', 
                              products=processed_products, 
                              current_category=category)
    except Exception as e:
        print(f"Error fetching category: {e}")
        return render_template('index.html', products=[], current_category=category)

@app.errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404

# Programar la limpieza de caché periódicamente si estamos en producción
if not app.debug:
    from apscheduler.schedulers.background import BackgroundScheduler
    scheduler = BackgroundScheduler()
    scheduler.add_job(func=clean_url_cache, trigger="interval", minutes=30)
    scheduler.add_job(func=refresh_category_cache, trigger="interval", minutes=30)
    scheduler.start()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5001))) 