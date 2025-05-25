#!/usr/bin/env python3
"""
Script de prueba para verificar AWS Secrets Manager
"""

from secrets_manager import get_secret, get_all_secrets
import sys

def test_secrets_manager():
    """Probar la conexión y obtención de secretos"""
    print("🔐 PRUEBA DE AWS SECRETS MANAGER")
    print("=" * 50)
    
    try:
        # Obtener todos los secretos
        print("📡 Obteniendo secretos desde AWS...")
        secrets = get_all_secrets()
        
        if not secrets:
            print("❌ No se pudieron obtener secretos")
            return False
        
        print("✅ Secretos obtenidos exitosamente")
        print(f"📊 Total de secretos encontrados: {len(secrets)}")
        
        # Verificar secretos específicos (sin mostrar valores)
        expected_secrets = [
            'AIRTABLE_API_KEY',
            'AIRTABLE_BASE_ID', 
            'AWS_ACCESS_KEY_ID',
            'AWS_SECRET_ACCESS_KEY',
            'S3_BUCKET_NAME',
            'S3_REGION'
        ]
        
        print("\n🔍 Verificando secretos requeridos:")
        all_present = True
        
        for secret_name in expected_secrets:
            value = secrets.get(secret_name)
            if value:
                # Mostrar solo los primeros y últimos caracteres para verificación
                masked_value = f"{value[:4]}...{value[-4:]}" if len(value) > 8 else "***"
                print(f"  ✅ {secret_name}: {masked_value}")
            else:
                print(f"  ❌ {secret_name}: NO ENCONTRADO")
                all_present = False
        
        # Verificar secretos de Supabase (opcionales por ahora)
        supabase_secrets = ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'SUPABASE_SERVICE_KEY']
        print("\n🔍 Verificando secretos de Supabase (opcionales):")
        
        for secret_name in supabase_secrets:
            value = secrets.get(secret_name)
            if value:
                masked_value = f"{value[:4]}...{value[-4:]}" if len(value) > 8 else "***"
                print(f"  ✅ {secret_name}: {masked_value}")
            else:
                print(f"  ⚠️  {secret_name}: NO CONFIGURADO (agregar cuando tengas las credenciales)")
        
        if all_present:
            print("\n🎉 ¡Todos los secretos requeridos están configurados!")
            return True
        else:
            print("\n⚠️  Algunos secretos requeridos faltan")
            return False
            
    except Exception as e:
        print(f"❌ Error al probar Secrets Manager: {e}")
        return False

def test_individual_secret():
    """Probar obtención de un secreto individual"""
    print("\n🔍 PRUEBA DE SECRETO INDIVIDUAL")
    print("-" * 30)
    
    try:
        # Probar obtener un secreto específico
        bucket_name = get_secret('S3_BUCKET_NAME')
        if bucket_name:
            print(f"✅ S3_BUCKET_NAME: {bucket_name}")
            return True
        else:
            print("❌ No se pudo obtener S3_BUCKET_NAME")
            return False
    except Exception as e:
        print(f"❌ Error obteniendo secreto individual: {e}")
        return False

if __name__ == "__main__":
    print("🧪 PRUEBAS DE AWS SECRETS MANAGER")
    print("=" * 50)
    
    # Ejecutar pruebas
    test1_passed = test_secrets_manager()
    test2_passed = test_individual_secret()
    
    print("\n" + "=" * 50)
    print("📊 RESUMEN DE PRUEBAS")
    print("=" * 50)
    print(f"✅ Obtención de todos los secretos: {'PASÓ' if test1_passed else 'FALLÓ'}")
    print(f"✅ Obtención de secreto individual: {'PASÓ' if test2_passed else 'FALLÓ'}")
    
    if test1_passed and test2_passed:
        print("\n🎉 ¡Todas las pruebas pasaron! AWS Secrets Manager está funcionando correctamente.")
        print("\n📝 Próximos pasos:")
        print("1. Agregar las credenciales de Supabase al secret manager")
        print("2. Ejecutar la migración de datos")
        print("3. Probar la aplicación Flask")
        sys.exit(0)
    else:
        print("\n❌ Algunas pruebas fallaron.")
        print("\n🔧 Posibles soluciones:")
        print("1. Verificar que el ARN del secret sea correcto")
        print("2. Verificar permisos de AWS IAM")
        print("3. Verificar que todas las credenciales estén en el secret")
        sys.exit(1) 