#!/bin/bash

# Script simplificado para desplegar función Lambda
# Ejecutar con: chmod +x deploy_lambda_simple.sh && ./deploy_lambda_simple.sh

set -e

echo "🚀 Desplegando función Lambda de sincronización (cada 1 hora)..."

# Variables
FUNCTION_NAME="airtable_to_supabase_sync"
REGION="us-east-1"

# Verificar que AWS CLI esté configurado
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ Error: AWS CLI no está configurado"
    echo "💡 Ejecuta: aws configure"
    exit 1
fi

echo "✅ AWS CLI configurado correctamente"

# Crear paquete de la función
echo "📦 Creando paquete de la función..."
rm -f lambda_function.zip

# Guardar directorio actual
ORIGINAL_DIR="$(pwd)"

# Crear directorio temporal
TEMP_DIR=$(mktemp -d)
cp lambda_sync.py "$TEMP_DIR/"
cp requirements_lambda.txt "$TEMP_DIR/requirements.txt"

# Instalar dependencias
echo "📦 Instalando dependencias..."
cd "$TEMP_DIR"
pip install -r requirements.txt -t . --quiet

# Crear ZIP
zip -r lambda_function.zip . -q
mv lambda_function.zip "$ORIGINAL_DIR/"

cd "$ORIGINAL_DIR"
rm -rf "$TEMP_DIR"

echo "✅ Paquete creado: lambda_function.zip"

# Desplegar stack de CloudFormation
echo "☁️ Desplegando infraestructura..."
aws cloudformation deploy \
    --template-file lambda_template.yaml \
    --stack-name venta-garage-sync-stack \
    --parameter-overrides FunctionName=$FUNCTION_NAME \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION \
    --no-fail-on-empty-changeset

echo "✅ Infraestructura desplegada"

# Actualizar código de la función
echo "📤 Actualizando código de la función..."
aws lambda update-function-code \
    --function-name $FUNCTION_NAME \
    --zip-file fileb://lambda_function.zip \
    --region $REGION > /dev/null

echo "✅ Código actualizado"

# Limpiar
rm -f lambda_function.zip

echo ""
echo "🎉 ¡Despliegue completado exitosamente!"
echo ""
echo "📊 Información de la función:"
aws lambda get-function \
    --function-name $FUNCTION_NAME \
    --region $REGION \
    --query 'Configuration.[FunctionName,Runtime,Timeout,MemorySize,LastModified]' \
    --output table

echo ""
echo "⏰ Programación:"
echo "   ✅ Se ejecutará automáticamente cada 1 hora"
echo "   ✅ Próxima ejecución: en la siguiente hora en punto"
echo ""
echo "🔧 Comandos útiles:"
echo "   📝 Ver logs:"
echo "      aws logs tail /aws/lambda/$FUNCTION_NAME --follow --region $REGION"
echo ""
echo "   🧪 Probar manualmente:"
echo "      aws lambda invoke --function-name $FUNCTION_NAME --region $REGION response.json && cat response.json"
echo ""
echo "   📊 Ver métricas:"
echo "      aws cloudwatch get-metric-statistics --namespace AWS/Lambda --metric-name Invocations --dimensions Name=FunctionName,Value=$FUNCTION_NAME --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 3600 --statistics Sum --region $REGION"
echo ""
echo "   🗑️ Eliminar todo:"
echo "      aws cloudformation delete-stack --stack-name venta-garage-sync-stack --region $REGION" 