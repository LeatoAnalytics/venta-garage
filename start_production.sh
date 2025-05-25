#!/bin/bash

echo "🚀 Iniciando aplicación Venta Garage en producción..."
echo "📅 $(date)"

# Validar variables críticas de Supabase
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ Error: Faltan credenciales de Supabase"
    echo "SUPABASE_URL: ${SUPABASE_URL:+✅}${SUPABASE_URL:-❌}"
    echo "SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:+✅}${SUPABASE_ANON_KEY:-❌}"
    exit 1
fi

# Validar variables críticas de AWS
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$S3_BUCKET_NAME" ]; then
    echo "❌ Error: Faltan credenciales de AWS"
    echo "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID:+✅}${AWS_ACCESS_KEY_ID:-❌}"
    echo "AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY:+✅}${AWS_SECRET_ACCESS_KEY:-❌}"
    echo "S3_BUCKET_NAME: ${S3_BUCKET_NAME:+✅}${S3_BUCKET_NAME:-❌}"
    exit 1
fi

echo "✅ Todas las credenciales validadas correctamente"

# Configurar variables de entorno para Flask
export FLASK_APP=app_supabase.py
export FLASK_ENV=production
export PORT=${PORT:-5001}

echo "🔧 Configuración:"
echo "   - FLASK_APP: $FLASK_APP"
echo "   - FLASK_ENV: $FLASK_ENV"
echo "   - PORT: $PORT"

# Verificar que la aplicación existe
if [ ! -f "$FLASK_APP" ]; then
    echo "❌ Error: Archivo de aplicación $FLASK_APP no encontrado"
    exit 1
fi

echo "✅ Archivo de aplicación encontrado: $FLASK_APP"

# Iniciar aplicación con Gunicorn
echo "🚀 Iniciando servidor con Gunicorn..."
exec gunicorn \
    --bind 0.0.0.0:$PORT \
    --workers 2 \
    --worker-class sync \
    --timeout 30 \
    --log-level info \
    --access-logfile - \
    --error-logfile - \
    app_supabase:app 