# Usar imagen base de Python 3.10 slim
FROM python:3.10-slim

# Establecer directorio de trabajo
WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copiar archivos de dependencias
COPY requirements.txt .

# Instalar dependencias de Python
RUN pip install --no-cache-dir -r requirements.txt

# Crear usuario no-root para seguridad
RUN useradd --create-home --shell /bin/bash app

# Copiar código de la aplicación
COPY . .

# Copiar script de inicio
COPY start_simple.sh .
RUN chmod +x start_simple.sh

# Crear directorio para logs
RUN mkdir -p /app/logs && chown -R app:app /app

# Cambiar a usuario no-root
USER app

# Exponer puerto
EXPOSE 5001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5001/ || exit 1

# Comando por defecto
CMD ["./start_simple.sh"] 