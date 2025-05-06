# Usar una imagen base de Python oficial
FROM python:3.10-slim

# Establecer el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiar el archivo de requerimientos primero para aprovechar el caché de Docker
COPY requirements.txt requirements.txt

# Instalar las dependencias
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el resto del código de la aplicación al directorio de trabajo
COPY . .

# Exponer el puerto en el que la aplicación se ejecutará dentro del contenedor
# App Runner espera por defecto el puerto 8080, así que usaremos ese.
EXPOSE 8080

# Comando para ejecutar la aplicación usando Gunicorn (un servidor WSGI de producción)
# Asegúrate de que 'gunicorn' esté en tu requirements.txt
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app:app"] 