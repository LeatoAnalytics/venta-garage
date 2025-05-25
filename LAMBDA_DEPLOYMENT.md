# 🚀 Guía de Despliegue - Lambda de Sincronización

Esta guía te ayudará a desplegar una función Lambda que sincroniza automáticamente Airtable con Supabase **cada 1 hora**.

## 📋 **Prerrequisitos**

1. **AWS CLI configurado**:
   ```bash
   aws configure
   # Ingresa tus credenciales AWS
   ```

2. **Crear AWS Secrets Manager**:
   
   **Opción A: Desde archivo .env (Recomendado)**
   ```bash
   # Usar credenciales existentes del archivo .env
   chmod +x create_lambda_secrets_from_env.sh
   ./create_lambda_secrets_from_env.sh
   ```
   
   **Opción B: Ingreso manual**
   ```bash
   # Ingresar credenciales manualmente
   chmod +x create_lambda_secrets.sh
   ./create_lambda_secrets.sh
   ```
   
   **Opción C: Comando directo**
   ```bash
   # Crear el secret con todas las credenciales necesarias
   aws secretsmanager create-secret \
       --name "airtable-to-supabase-credentials" \
       --description "Credenciales para sincronización Airtable-Supabase" \
       --secret-string '{
           "SUPABASE_URL": "tu_supabase_url",
           "SUPABASE_ANON_KEY": "tu_supabase_anon_key", 
           "SUPABASE_SERVICE_KEY": "tu_supabase_service_key",
           "AIRTABLE_API_KEY": "tu_airtable_api_key",
           "AIRTABLE_BASE_ID": "tu_airtable_base_id"
       }' \
       --region us-east-1
   ```

3. **Python y pip instalados**

## 🚀 **Despliegue Rápido**

### **Opción 1: Script Automático (Recomendado)**

```bash
# 1. Hacer ejecutable el script
chmod +x deploy_lambda_simple.sh

# 2. Ejecutar despliegue
./deploy_lambda_simple.sh
```

### **Opción 2: Paso a Paso Manual**

```bash
# 1. Crear paquete de dependencias
pip install -r requirements_lambda.txt -t ./lambda_package/
cp lambda_sync.py ./lambda_package/

# 2. Crear ZIP
cd lambda_package && zip -r ../lambda_function.zip . && cd ..

# 3. Desplegar infraestructura
aws cloudformation deploy \
    --template-file lambda_template.yaml \
    --stack-name venta-garage-sync-stack \
    --capabilities CAPABILITY_NAMED_IAM \
    --region us-east-1

# 4. Subir código
aws lambda update-function-code \
    --function-name airtable_to_supabase_sync \
    --zip-file fileb://lambda_function.zip \
    --region us-east-1
```

## ⚡ **¿Qué se Crea?**

### **🔧 Infraestructura AWS**
- **Lambda Function**: `airtable_to_supabase_sync`
- **EventBridge Rule**: Ejecuta cada 1 hora
- **DynamoDB Table**: `venta-garage-sync-state` (para tracking de cambios)
- **IAM Role**: Con permisos para Secrets Manager y DynamoDB
- **CloudWatch Logs**: Para monitoreo

### **⏰ Programación**
- **Frecuencia**: Cada 1 hora (en punto)
- **Ejemplo**: 10:00, 11:00, 12:00, etc.
- **Timeout**: 5 minutos máximo por ejecución
- **Memoria**: 256 MB

## 📊 **Monitoreo y Gestión**

### **Ver Logs en Tiempo Real**
```bash
aws logs tail /aws/lambda/airtable_to_supabase_sync --follow --region us-east-1
```

### **Probar Manualmente**
```bash
aws lambda invoke \
    --function-name airtable_to_supabase_sync \
    --region us-east-1 \
    response.json && cat response.json
```

### **Ver Métricas**
```bash
# Invocaciones de la última hora
aws cloudwatch get-metric-statistics \
    --namespace AWS/Lambda \
    --metric-name Invocations \
    --dimensions Name=FunctionName,Value=airtable_to_supabase_sync \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 3600 \
    --statistics Sum \
    --region us-east-1
```

## 🔧 **Configuración Avanzada**

### **Cambiar Frecuencia de Ejecución**

Para cambiar la frecuencia, edita `lambda_template.yaml`:

```yaml
# Cada 30 minutos
ScheduleExpression: 'rate(30 minutes)'

# Cada 2 horas
ScheduleExpression: 'rate(2 hours)'

# Todos los días a las 9:00 AM UTC
ScheduleExpression: 'cron(0 9 * * ? *)'
```

### **Ajustar Timeout y Memoria**

En `lambda_template.yaml`:

```yaml
SyncLambdaFunction:
  Properties:
    Timeout: 600      # 10 minutos
    MemorySize: 512   # 512 MB
```

## 🧠 **Características Inteligentes**

### **Detección de Cambios**
- Solo sincroniza productos que realmente cambiaron
- Usa hash MD5 para detectar diferencias
- Guarda estado en DynamoDB

### **Manejo de Errores**
- Continúa aunque falle un producto específico
- Logs detallados de errores
- Reintentos automáticos por AWS

### **Optimización de Costos**
- Solo ejecuta cuando hay cambios
- DynamoDB en modo Pay-per-Request
- Logs con retención de 14 días

## 📈 **Estadísticas de Ejecución**

Cada ejecución reporta:
- ✅ **Productos creados**
- 🔄 **Productos actualizados**
- ⏭️ **Productos sin cambios**
- ❌ **Errores encontrados**

## 🗑️ **Eliminar Todo**

```bash
# Eliminar stack completo
aws cloudformation delete-stack \
    --stack-name venta-garage-sync-stack \
    --region us-east-1

# Verificar eliminación
aws cloudformation describe-stacks \
    --stack-name venta-garage-sync-stack \
    --region us-east-1
```

## 💰 **Costos Estimados**

### **Lambda**
- **Ejecuciones**: 24 por día × 30 días = 720/mes
- **Duración**: ~30 segundos promedio
- **Costo**: ~$0.01/mes

### **DynamoDB**
- **Operaciones**: ~100 read/write por día
- **Costo**: ~$0.01/mes

### **CloudWatch Logs**
- **Logs**: ~1 MB por día
- **Costo**: ~$0.01/mes

**Total estimado: ~$0.03/mes** 💸

## 🎯 **Próximos Pasos**

1. **Ejecutar despliegue**: `./deploy_lambda_simple.sh`
2. **Verificar primera ejecución**: Revisar logs
3. **Monitorear**: Configurar alertas si es necesario
4. **Optimizar**: Ajustar frecuencia según necesidades

¡Tu sincronización automática estará lista en menos de 5 minutos! 🚀 