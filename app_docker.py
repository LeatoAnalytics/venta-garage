import os
from flask import Flask, render_template
from dotenv import load_dotenv
from supabase import create_client, Client
import boto3
from datetime import datetime, timedelta
from apscheduler.schedulers.background import BackgroundScheduler

# Cargar variables de entorno
load_dotenv()

# Configuración de la aplicación
app = Flask(__name__)

# Configuración de Supabase desde .env
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_ANON_KEY = os.getenv('SUPABASE_ANON_KEY')

# Configuración de AWS S3 desde .env
AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')
S3_BUCKET = os.getenv('S3_BUCKET_NAME')

# Verificar que las variables críticas estén configuradas
if not SUPABASE_URL or not SUPABASE_ANON_KEY:
    print("❌ Error: Faltan credenciales de Supabase")
    print(f"SUPABASE_URL: {'✅' if SUPABASE_URL else '❌'}")
    print(f"SUPABASE_ANON_KEY: {'✅' if SUPABASE_ANON_KEY else '❌'}")
    exit(1)

if not AWS_ACCESS_KEY_ID or not AWS_SECRET_ACCESS_KEY or not S3_BUCKET:
    print("❌ Error: Faltan credenciales de AWS")
    print(f"AWS_ACCESS_KEY_ID: {'✅' if AWS_ACCESS_KEY_ID else '❌'}")
    print(f"AWS_SECRET_ACCESS_KEY: {'✅' if AWS_SECRET_ACCESS_KEY else '❌'}")
    print(f"S3_BUCKET: {'✅' if S3_BUCKET else '❌'}")
    exit(1)

print("✅ Todas las credenciales cargadas correctamente desde .env")

# Inicializar clientes
supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)

s3_client = boto3.client(
    's3',
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
    region_name=AWS_REGION
)

# Cache para URLs de S3
url_cache = {}
CACHE_TTL = 3600  # 1 hora
URL_EXPIRATION = 3600  # URLs válidas por 1 hora

def clean_url_cache():
    """Limpiar cache de URLs expiradas"""
    current_time = datetime.now()
    expired_keys = [
        key for key, (_, timestamp) in url_cache.items()
        if (current_time - timestamp).total_seconds() > CACHE_TTL
    ]
    for key in expired_keys:
        del url_cache[key]

@app.template_filter('format_price')
def format_price(value):
    """Formatear precio con separadores de miles"""
    if value is None:
        return "N/A"
    try:
        # Convertir a float si es string
        if isinstance(value, str):
            value = float(value.replace(',', '').replace('.', ''))
        # Formatear con puntos como separadores de miles (formato español)
        return f"${value:,.0f}".replace(',', '.')
    except (ValueError, TypeError):
        return "N/A"

def get_cached_categories():
    """Obtener categorías únicas de la base de datos (dinámico)"""
    return get_active_categories()

def refresh_category_cache():
    """Refrescar cache de categorías (ya no necesario)"""
    pass

@app.context_processor
def inject_now():
    """Inyectar función datetime.now en templates"""
    return {
        'now': datetime.now(),
        'active_categories': get_cached_categories()
    }

def is_product_active(product):
    """Verificar si un producto está activo"""
    return product.get('activo', False) and product.get('status') != 'Vendido'

def get_active_categories():
    """Obtener categorías de productos activos y no vendidos"""
    try:
        # Obtener productos activos que no estén vendidos
        response = supabase.table('productos').select('categoria').eq('activo', True).neq('status', 'Vendido').execute()
        if response.data:
            categories = list(set([p['categoria'] for p in response.data if p.get('categoria')]))
            
            # Ordenar las categorías alfabéticamente
            sorted_categories = sorted(categories)
            
            # Agregar "Ofertas" al final solo si hay productos con precio rebajado que no estén vendidos
            ofertas_response = supabase.table('productos').select('id').eq('activo', True).neq('status', 'Vendido').not_.is_('precio_rebajado', 'null').execute()
            if ofertas_response.data:
                sorted_categories.append('Ofertas')
            
            return sorted_categories
        return []
    except Exception as e:
        print(f"Error al obtener categorías: {e}")
        return []

def get_s3_images_from_folder(base_url):
    """Obtener imágenes de una carpeta S3 y generar URLs prefirmadas"""
    if not base_url:
        return "/static/img/placeholder.jpg", []
    
    # Asegurar que la URL termine con /
    if not base_url.endswith('/'):
        base_url += '/'
    
    # Check cache first
    cache_key = f"s3_folder_{base_url}"
    if cache_key in url_cache:
        urls, timestamp = url_cache[cache_key]
        if (datetime.now() - timestamp).total_seconds() < CACHE_TTL:
            return urls
    
    clean_url_cache()
    
    try:
        # Extract bucket name and prefix from URL
        url_parts = base_url.replace('https://', '').split('/')
        bucket_name = url_parts[0].split('.')[0]
        prefix = '/'.join(url_parts[1:])
        
        # List objects in this folder
        response = s3_client.list_objects_v2(
            Bucket=S3_BUCKET,
            Prefix=prefix
        )
        
        main_image_url = None
        additional_images = []
        
        if 'Contents' in response:
            for obj in response['Contents']:
                key = obj['Key']
                if key.lower().endswith(('.jpg', '.jpeg', '.png', '.gif', '.webp')):
                    presigned_url = s3_client.generate_presigned_url(
                        'get_object',
                        Params={'Bucket': S3_BUCKET, 'Key': key},
                        ExpiresIn=URL_EXPIRATION
                    )
                    
                    if 'portada' in key.lower():
                        main_image_url = presigned_url
                    else:
                        additional_images.append(presigned_url)
        
        # If no main image found, use first additional image
        if not main_image_url and additional_images:
            main_image_url = additional_images[0]
            additional_images = additional_images[1:]
        elif not main_image_url:
            main_image_url = "/static/img/placeholder.jpg"
        
        # Cache the result
        result = (main_image_url, additional_images)
        url_cache[cache_key] = (result, datetime.now())
        
        return result
    
    except Exception as e:
        print(f"Error al listar imágenes de S3: {e}")
        return "/static/img/placeholder.jpg", []

@app.route('/')
def index():
    """Home page showing all active products"""
    try:
        # Get all active products from Supabase
        response = supabase.table('productos').select('*').eq('activo', True).execute()
        
        if not response.data:
            return render_template('index.html', products=[])
        
        # Process S3 images for each product
        processed_products = []
        for product in response.data:
            if product.get('imagenes_s3'):
                base_url = product['imagenes_s3']
                cache_key = f"main_image_{base_url}"
                
                # Try to get from cache first
                if cache_key in url_cache:
                    main_url, timestamp = url_cache[cache_key]
                    if (datetime.now() - timestamp).total_seconds() < CACHE_TTL:
                        product['imagenes_s3'] = main_url
                        processed_products.append(product)
                        continue
                
                # If not in cache, get main image
                try:
                    main_image_url, _ = get_s3_images_from_folder(base_url)
                    product['imagenes_s3'] = main_image_url
                    url_cache[cache_key] = (main_image_url, datetime.now())
                except Exception as e:
                    print(f"Error al obtener imagen principal: {e}")
                    product['imagenes_s3'] = "/static/img/placeholder.jpg"
            
            processed_products.append(product)
        
        return render_template('index.html', products=processed_products)
    except Exception as e:
        print(f"Error fetching products from Supabase: {e}")
        error_message = f"Error al conectar con la base de datos: {str(e)}"
        return render_template('error.html', error_message=error_message), 500

@app.route('/producto/<product_id>')
def product_detail(product_id):
    """Product detail page"""
    try:
        # Get product from Supabase by ID
        response = supabase.table('productos').select('*').eq('id', product_id).execute()
        
        if not response.data or not is_product_active(response.data[0]):
            return render_template('404.html'), 404
        
        product = response.data[0]
        
        # Process S3 images if available
        if product.get('imagenes_s3'):
            base_url = product['imagenes_s3']
            
            # Check cache first
            cache_key = f"s3_folder_{base_url}"
            if cache_key in url_cache:
                urls, timestamp = url_cache[cache_key]
                if (datetime.now() - timestamp).total_seconds() < CACHE_TTL:
                    main_image_url, additional_images = urls
                    product['imagenes_s3'] = main_image_url
                    product['imagenes_s3_adicionales'] = additional_images
                else:
                    # Cache expired, refresh
                    main_image_url, additional_images = get_s3_images_from_folder(base_url)
                    product['imagenes_s3'] = main_image_url
                    product['imagenes_s3_adicionales'] = additional_images
            else:
                # Not in cache, get from S3
                main_image_url, additional_images = get_s3_images_from_folder(base_url)
                product['imagenes_s3'] = main_image_url
                product['imagenes_s3_adicionales'] = additional_images
        
        return render_template('product_detail.html', product=product)
    except Exception as e:
        print(f"Error fetching product from Supabase: {e}")
        return render_template('404.html'), 404

@app.route('/categorias/<category>')
def category_view(category):
    """View products by category"""
    try:
        if category == 'Ofertas':
            # For "Ofertas" category, get products with rebajado price
            response = supabase.table('productos').select('*').eq('activo', True).not_.is_('precio_rebajado', 'null').execute()
        else:
            # For regular categories, filter by specific category
            response = supabase.table('productos').select('*').eq('activo', True).eq('categoria', category).execute()
        
        products = response.data or []
        
        # Process S3 images for filtered products
        processed_products = []
        for product in products:
            if product.get('imagenes_s3'):
                base_url = product['imagenes_s3']
                cache_key = f"main_image_{base_url}"
                
                # Try to get from cache first
                if cache_key in url_cache:
                    main_url, timestamp = url_cache[cache_key]
                    if (datetime.now() - timestamp).total_seconds() < CACHE_TTL:
                        product['imagenes_s3'] = main_url
                        processed_products.append(product)
                        continue
                
                # If not in cache, get main image
                try:
                    main_image_url, _ = get_s3_images_from_folder(base_url)
                    product['imagenes_s3'] = main_image_url
                    url_cache[cache_key] = (main_image_url, datetime.now())
                except Exception as e:
                    print(f"Error al obtener imagen principal: {e}")
                    product['imagenes_s3'] = "/static/img/placeholder.jpg"
            
            processed_products.append(product)
        
        return render_template('index.html', 
                              products=processed_products, 
                              current_category=category)
    except Exception as e:
        print(f"Error fetching category from Supabase: {e}")
        return render_template('index.html', products=[], current_category=category)

@app.errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404

# Schedule cache cleanup in production
if not app.debug:
    scheduler = BackgroundScheduler()
    scheduler.add_job(func=clean_url_cache, trigger="interval", minutes=30)
    scheduler.start()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5001))) 