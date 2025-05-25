#!/bin/bash

echo "🔍 DEBUG: Iniciando aplicación..."
echo "📅 Fecha: $(date)"

# Mostrar todas las variables de entorno (sin valores sensibles)
echo "🔧 Variables de entorno disponibles:"
env | grep -E "^(SUPABASE|AWS|FLASK|PORT)" | sed 's/=.*/=***/' || echo "No hay variables configuradas"

# Verificar archivos
echo "📁 Archivos en directorio:"
ls -la

# Verificar Python y dependencias
echo "🐍 Versión de Python:"
python --version

echo "📦 Paquetes instalados:"
pip list | grep -E "(flask|supabase|boto3)" || echo "Paquetes no encontrados"

# Intentar importar módulos críticos
echo "🧪 Probando imports:"
python -c "import flask; print('✅ Flask OK')" || echo "❌ Flask falla"
python -c "import supabase; print('✅ Supabase OK')" || echo "❌ Supabase falla"
python -c "import boto3; print('✅ Boto3 OK')" || echo "❌ Boto3 falla"

# Iniciar aplicación simple
echo "🚀 Iniciando aplicación..."
python app_supabase.py 