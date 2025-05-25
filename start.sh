#!/bin/bash

# Configurar logging
exec > >(tee -a /app/logs/app.log) 2>&1

echo "🚀 Iniciando aplicación Venta Garage..."
echo "📅 $(date)"

# Verificar que el archivo .env existe
if [ ! -f ".env" ]; then
    echo "❌ Error: Archivo .env no encontrado"
    echo "💡 Asegúrate de montar el archivo .env en el contenedor"
    exit 1
fi

echo "✅ Archivo .env encontrado"

# Cargar variables de entorno desde .env de forma más segura
set -a  # Exportar automáticamente todas las variables
source .env
set +a  # Desactivar exportación automática

# Validar variables críticas de Supabase
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ Error: Faltan credenciales de Supabase en .env"
    echo "SUPABASE_URL: ${SUPABASE_URL:+✅}${SUPABASE_URL:-❌}"
    echo "SUPABASE_ANON_KEY: ${SUPABASE_ANON_KEY:+✅}${SUPABASE_ANON_KEY:-❌}"
    exit 1
fi

# Validar variables críticas de AWS
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$S3_BUCKET_NAME" ]; then
    echo "❌ Error: Faltan credenciales de AWS en .env"
    echo "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID:+✅}${AWS_ACCESS_KEY_ID:-❌}"
    echo "AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY:+✅}${AWS_SECRET_ACCESS_KEY:-❌}"
    echo "S3_BUCKET_NAME: ${S3_BUCKET_NAME:+✅}${S3_BUCKET_NAME:-❌}"
    exit 1
fi

echo "✅ Todas las credenciales validadas correctamente"

# Configurar variables de entorno para Flask
export FLASK_APP=app_docker.py
export FLASK_ENV=${FLASK_ENV:-production}
export PORT=${PORT:-5001}

echo "🔧 Configuración:"
echo "   - FLASK_APP: $FLASK_APP"
echo "   - FLASK_ENV: $FLASK_ENV"
echo "   - PORT: $PORT"
echo "   - AWS_REGION: ${AWS_REGION:-us-east-1}"

# Verificar que la aplicación existe
if [ ! -f "$FLASK_APP" ]; then
    echo "❌ Error: Archivo de aplicación $FLASK_APP no encontrado"
    exit 1
fi

echo "✅ Archivo de aplicación encontrado: $FLASK_APP"

# Función para manejar señales de terminación
cleanup() {
    echo "🛑 Recibida señal de terminación, cerrando aplicación..."
    kill -TERM "$child" 2>/dev/null
    wait "$child"
    echo "✅ Aplicación cerrada correctamente"
    exit 0
}

# Configurar manejo de señales
trap cleanup SIGTERM SIGINT

# Iniciar aplicación
echo "🌟 Iniciando servidor Flask..."

if [ "$FLASK_ENV" = "development" ]; then
    echo "🔧 Modo desarrollo - usando Flask dev server"
    python $FLASK_APP &
    child=$!
else
    echo "🚀 Modo producción - usando Gunicorn"
    # Usar Gunicorn para producción
    gunicorn \
        --bind 0.0.0.0:$PORT \
        --workers 2 \
        --worker-class sync \
        --worker-connections 1000 \
        --max-requests 1000 \
        --max-requests-jitter 100 \
        --timeout 30 \
        --keep-alive 2 \
        --log-level info \
        --access-logfile - \
        --error-logfile - \
        --capture-output \
        app_docker:app &
    child=$!
fi

echo "✅ Servidor iniciado con PID: $child"
echo "🌐 Aplicación disponible en http://0.0.0.0:$PORT"

# Esperar a que termine el proceso
wait "$child" 