#!/usr/bin/env python3
"""
Script para migrar datos de Airtable a Supabase
Ejecutar después de configurar la base de datos en Supabase
"""

import os
from dotenv import load_dotenv
from pyairtable import Table
from supabase import create_client, Client
import json

# Cargar variables de entorno
load_dotenv()

# Configuración de Airtable
AIRTABLE_API_KEY = os.getenv('AIRTABLE_API_KEY')
AIRTABLE_BASE_ID = os.getenv('AIRTABLE_BASE_ID')

# Configuración de Supabase
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_SERVICE_KEY = os.getenv('SUPABASE_SERVICE_KEY')  # Service role key para operaciones de escritura

def migrate_data():
    """Migra todos los datos de Airtable a Supabase"""
    
    # Conectar a Airtable
    productos_table = Table(AIRTABLE_API_KEY, AIRTABLE_BASE_ID, 'Table 1')
    
    # Conectar a Supabase
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    
    try:
        # Obtener todos los productos de Airtable
        print("Obteniendo productos de Airtable...")
        airtable_products = productos_table.all()
        print(f"Encontrados {len(airtable_products)} productos en Airtable")
        
        # Convertir formato de Airtable a formato de Supabase
        supabase_products = []
        
        for product in airtable_products:
            fields = product.get('fields', {})
            
            # Mapear campos de Airtable a Supabase
            supabase_product = {
                'nombre_producto': fields.get('nombre_producto', ''),
                'descripcion': fields.get('descripcion', ''),
                'precio_original': fields.get('precio_original'),
                'precio_rebajado': fields.get('precio_rebajado'),
                'categoria': fields.get('categoria', ''),
                'status': fields.get('status', 'Disponible'),
                'activo': fields.get('activo') == 'SI',  # Convertir 'SI'/'NO' a boolean
                'imagenes_s3': fields.get('imagenes_s3', '')
            }
            
            # Solo agregar productos con nombre
            if supabase_product['nombre_producto']:
                supabase_products.append(supabase_product)
        
        print(f"Preparados {len(supabase_products)} productos para migrar")
        
        # Limpiar tabla existente (opcional - comentar si no quieres borrar datos existentes)
        print("Limpiando tabla productos en Supabase...")
        supabase.table('productos').delete().neq('id', '00000000-0000-0000-0000-000000000000').execute()
        
        # Insertar productos en Supabase en lotes
        batch_size = 50
        total_inserted = 0
        
        for i in range(0, len(supabase_products), batch_size):
            batch = supabase_products[i:i + batch_size]
            
            try:
                result = supabase.table('productos').insert(batch).execute()
                total_inserted += len(batch)
                print(f"Insertados {len(batch)} productos (total: {total_inserted}/{len(supabase_products)})")
            except Exception as e:
                print(f"Error insertando lote {i//batch_size + 1}: {e}")
                # Intentar insertar uno por uno en caso de error
                for product in batch:
                    try:
                        supabase.table('productos').insert(product).execute()
                        total_inserted += 1
                        print(f"Insertado producto individual: {product['nombre_producto']}")
                    except Exception as individual_error:
                        print(f"Error insertando producto {product['nombre_producto']}: {individual_error}")
        
        print(f"\n✅ Migración completada!")
        print(f"Total de productos migrados: {total_inserted}")
        
        # Verificar migración
        result = supabase.table('productos').select('count').execute()
        print(f"Productos en Supabase después de la migración: {len(result.data) if result.data else 0}")
        
    except Exception as e:
        print(f"❌ Error durante la migración: {e}")
        return False
    
    return True

def verify_migration():
    """Verifica que la migración fue exitosa"""
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    
    try:
        # Obtener estadísticas
        result = supabase.table('productos').select('*').execute()
        products = result.data
        
        print(f"\n📊 Estadísticas de migración:")
        print(f"Total de productos: {len(products)}")
        
        # Contar por categoría
        categories = {}
        active_count = 0
        
        for product in products:
            categoria = product.get('categoria', 'Sin categoría')
            categories[categoria] = categories.get(categoria, 0) + 1
            
            if product.get('activo'):
                active_count += 1
        
        print(f"Productos activos: {active_count}")
        print(f"Productos por categoría:")
        for categoria, count in categories.items():
            print(f"  - {categoria}: {count}")
            
    except Exception as e:
        print(f"Error verificando migración: {e}")

if __name__ == "__main__":
    print("🚀 Iniciando migración de Airtable a Supabase...")
    print("Asegúrate de haber configurado las variables de entorno:")
    print("- SUPABASE_URL")
    print("- SUPABASE_SERVICE_KEY")
    print("- AIRTABLE_API_KEY")
    print("- AIRTABLE_BASE_ID")
    print()
    
    # Verificar variables de entorno
    required_vars = ['SUPABASE_URL', 'SUPABASE_SERVICE_KEY', 'AIRTABLE_API_KEY', 'AIRTABLE_BASE_ID']
    missing_vars = [var for var in required_vars if not os.getenv(var)]
    
    if missing_vars:
        print(f"❌ Faltan las siguientes variables de entorno: {', '.join(missing_vars)}")
        exit(1)
    
    # Ejecutar migración
    if migrate_data():
        verify_migration()
    else:
        print("❌ La migración falló")
        exit(1) 