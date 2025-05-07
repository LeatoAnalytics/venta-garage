FROM python:3.8-slim

WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copiar archivos de requisitos
COPY requirements.txt .

# Instalar dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código fuente
COPY . .

# Exponer puerto
EXPOSE 8080

# Configurar variables de entorno
ENV PYTHONUNBUFFERED=1
ENV PORT=8080

# Ejecutar con gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"] 