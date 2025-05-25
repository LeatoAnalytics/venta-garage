import json
import os
import hashlib
import boto3
from datetime import datetime
from pyairtable import Table
from supabase import create_client, Client

def lambda_handler(event, context):
    """
    Función Lambda para sincronizar Airtable con Supabase
    Se ejecuta automáticamente cada 15 minutos via EventBridge
    """
    
    print(f"🔄 Iniciando sincronización Lambda - {datetime.now()}")
    
    try:
        # Obtener credenciales desde AWS Secrets Manager
        secrets = get_credentials()
        
        # Configurar clientes
        airtable_table = Table(
            secrets['AIRTABLE_API_KEY'], 
            secrets['AIRTABLE_BASE_ID'], 
            'Table 1'
        )
        
        supabase = create_client(
            secrets['SUPABASE_URL'], 
            secrets['SUPABASE_SERVICE_KEY']
        )
        
        # Ejecutar sincronización
        result = sync_products(airtable_table, supabase)
        
        print(f"✅ Sincronización completada: {result}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'success': True,
                'message': 'Sincronización completada exitosamente',
                'stats': result,
                'timestamp': datetime.now().isoformat()
            })
        }
        
    except Exception as e:
        error_msg = f"❌ Error en sincronización: {str(e)}"
        print(error_msg)
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'success': False,
                'error': error_msg,
                'timestamp': datetime.now().isoformat()
            })
        }

def get_credentials():
    """Obtiene credenciales desde AWS Secrets Manager"""
    secret_name = "airtable-to-supabase-credentials"
    region_name = "us-east-1"
    
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=region_name
    )
    
    try:
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)
        secret = json.loads(get_secret_value_response['SecretString'])
        return secret
    except Exception as e:
        print(f"Error obteniendo credenciales: {e}")
        raise

def get_product_hash(product_fields):
    """Generar hash de un producto para detectar cambios"""
    relevant_fields = {
        'nombre_producto': product_fields.get('nombre_producto', ''),
        'descripcion': product_fields.get('descripcion', ''),
        'precio_original': product_fields.get('precio_original'),
        'precio_rebajado': product_fields.get('precio_rebajado'),
        'categoria': product_fields.get('categoria', ''),
        'status': product_fields.get('status', 'Disponible'),
        'activo': product_fields.get('activo', ''),
        'imagenes_s3': product_fields.get('imagenes_s3', '')
    }
    
    product_string = json.dumps(relevant_fields, sort_keys=True)
    return hashlib.md5(product_string.encode()).hexdigest()

def convert_airtable_to_supabase(airtable_product):
    """Convertir formato de Airtable a formato de Supabase"""
    fields = airtable_product.get('fields', {})
    
    return {
        'nombre_producto': fields.get('nombre_producto', ''),
        'descripcion': fields.get('descripcion', ''),
        'precio_original': fields.get('precio_original'),
        'precio_rebajado': fields.get('precio_rebajado'),
        'categoria': fields.get('categoria', ''),
        'status': fields.get('status', 'Disponible'),
        'activo': fields.get('activo') == 'SI',  # Convertir 'SI'/'NO' a boolean
        'imagenes_s3': fields.get('imagenes_s3', '')
    }

def get_existing_products_map(supabase):
    """Obtener mapa de productos existentes en Supabase"""
    try:
        result = supabase.table('productos').select('*').execute()
        products_map = {}
        
        for product in result.data:
            key = product.get('nombre_producto', '')
            if key:
                products_map[key] = product
        
        return products_map
    except Exception as e:
        print(f"Error obteniendo productos de Supabase: {e}")
        return {}

def get_last_sync_state():
    """Obtener estado de última sincronización desde DynamoDB"""
    try:
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        table = dynamodb.Table('venta-garage-sync-state')
        
        response = table.get_item(Key={'sync_id': 'last_sync'})
        
        if 'Item' in response:
            return response['Item'].get('state', {})
        else:
            return {}
    except Exception as e:
        print(f"Error obteniendo estado de sincronización: {e}")
        return {}

def save_sync_state(state):
    """Guardar estado de sincronización en DynamoDB"""
    try:
        dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
        table = dynamodb.Table('venta-garage-sync-state')
        
        table.put_item(
            Item={
                'sync_id': 'last_sync',
                'state': state,
                'timestamp': datetime.now().isoformat()
            }
        )
    except Exception as e:
        print(f"Error guardando estado de sincronización: {e}")

def sync_products(airtable_table, supabase):
    """Sincronizar productos de Airtable a Supabase"""
    print("📥 Obteniendo productos de Airtable...")
    airtable_products = airtable_table.all()
    print(f"✅ Obtenidos {len(airtable_products)} productos de Airtable")
    
    print("📥 Obteniendo productos existentes de Supabase...")
    existing_products = get_existing_products_map(supabase)
    print(f"✅ Encontrados {len(existing_products)} productos en Supabase")
    
    # Obtener estado de última sincronización
    last_sync_state = get_last_sync_state()
    
    # Contadores
    created_count = 0
    updated_count = 0
    skipped_count = 0
    error_count = 0
    
    current_sync_state = {}
    
    for airtable_product in airtable_products:
        try:
            fields = airtable_product.get('fields', {})
            product_name = fields.get('nombre_producto', '')
            
            if not product_name:
                continue
            
            # Generar hash para detectar cambios
            current_hash = get_product_hash(fields)
            current_sync_state[product_name] = current_hash
            
            # Verificar si el producto ha cambiado
            last_hash = last_sync_state.get(product_name)
            
            if current_hash == last_hash:
                skipped_count += 1
                continue
            
            # Convertir formato
            supabase_product = convert_airtable_to_supabase(airtable_product)
            
            # Verificar si existe en Supabase
            if product_name in existing_products:
                # Actualizar producto existente
                existing_id = existing_products[product_name]['id']
                
                result = supabase.table('productos')\
                    .update(supabase_product)\
                    .eq('id', existing_id)\
                    .execute()
                
                updated_count += 1
                print(f"🔄 Actualizado: {product_name}")
            else:
                # Crear nuevo producto
                result = supabase.table('productos')\
                    .insert(supabase_product)\
                    .execute()
                
                created_count += 1
                print(f"➕ Creado: {product_name}")
        
        except Exception as e:
            error_count += 1
            print(f"❌ Error procesando {product_name}: {e}")
    
    # Guardar estado de sincronización
    save_sync_state(current_sync_state)
    
    result = {
        'created': created_count,
        'updated': updated_count,
        'skipped': skipped_count,
        'errors': error_count,
        'total_processed': len(airtable_products)
    }
    
    print(f"📊 Estadísticas: {result}")
    return result 