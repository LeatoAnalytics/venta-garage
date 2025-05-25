#!/bin/bash

# Script de inicio simple para la aplicación Flask
set -e

echo "🚀 Iniciando aplicación Venta Garage..."
echo "📅 $(date)"

# Verificar que las variables de entorno críticas estén configuradas
if [ -z "$SUPABASE_URL" ]; then
    echo "❌ ERROR: SUPABASE_URL no está configurado"
    exit 1
fi

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
    echo "❌ ERROR: AWS_ACCESS_KEY_ID no está configurado"
    exit 1
fi

if [ -z "$S3_BUCKET_NAME" ]; then
    echo "❌ ERROR: S3_BUCKET_NAME no está configurado"
    exit 1
fi

echo "✅ Variables de entorno verificadas"

# Iniciar la aplicación con gunicorn
echo "🌟 Iniciando servidor con gunicorn..."
exec gunicorn --bind 0.0.0.0:5001 --workers 1 --timeout 120 --preload app_docker:app 