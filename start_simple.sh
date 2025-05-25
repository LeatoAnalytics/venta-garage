#!/bin/bash

echo "🚀 Iniciando Venta Garage..."

# Configurar variables básicas
export FLASK_ENV=production
export PORT=5001

# Validar que las variables críticas existan
if [ -z "$SUPABASE_URL" ]; then
    echo "❌ Error: SUPABASE_URL no configurada"
    exit 1
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
    echo "❌ Error: SUPABASE_ANON_KEY no configurada"
    exit 1
fi

echo "✅ Variables de entorno validadas"
echo "🌐 Iniciando servidor en puerto $PORT..."

# Usar Gunicorn directamente
exec gunicorn \
    --bind 0.0.0.0:$PORT \
    --workers 1 \
    --timeout 120 \
    --log-level info \
    --access-logfile - \
    --error-logfile - \
    app_supabase:app 