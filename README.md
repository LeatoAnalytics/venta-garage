# Venta Garage - Plataforma Minimalista para Venta Personal

Una aplicación web minimalista desarrollada en Python con Flask para listar y detallar artículos personales para venta antes de una mudanza al extranjero.

## Características

- Vista de todos los productos organizados por categorías
- Página detallada para cada producto
- Botón para copiar enlace del producto
- Diseño responsivo y minimalista
- Integración con Airtable para gestión de datos
- Imágenes servidas desde Amazon S3

## Tecnologías Utilizadas

- **Backend**: Python, Flask
- **Frontend**: HTML, CSS, JavaScript
- **Gestión de Datos**: Airtable
- **Almacenamiento de Imágenes**: Amazon S3

## Estructura de Datos en Airtable

**Tabla**: Productos
- ID_Producto
- NombreProducto
- Descripcion
- PrecioOriginal
- PrecioRebajado
- ImagenesURLs
- Categoria
- Estado

## Configuración y Despliegue

### Requisitos Previos

- Python 3.8+
- Cuenta de Airtable con API Key
- Cuenta de AWS con S3 bucket configurado

### Instalación Local

1. Clonar el repositorio:
```
git clone <url-del-repositorio>
cd venta-garage
```

2. Crear y activar un entorno virtual:
```
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
```

3. Instalar dependencias:
```
pip install -r requirements.txt
```

4. Configurar variables de entorno:
Crear un archivo `.env` en la raíz del proyecto con los siguientes valores:
```
FLASK_APP=app.py
FLASK_ENV=development
FLASK_DEBUG=1

AIRTABLE_API_KEY=tu_api_key
AIRTABLE_BASE_ID=tu_base_id

AWS_ACCESS_KEY_ID=tu_aws_key
AWS_SECRET_ACCESS_KEY=tu_aws_secret
S3_BUCKET_NAME=tu_bucket
S3_REGION=tu_region
```

5. Ejecutar la aplicación:
```
flask run
```

### Despliegue en AWS (futuro)

La estructura de la aplicación está diseñada para ser compatible con varios servicios de AWS:
- Amazon EC2
- AWS Elastic Beanstalk
- AWS Fargate
- AWS Lambda (con adaptaciones adicionales)

## Posibles Mejoras Futuras

- Sistema de administración para actualizar productos
- Integración de pagos
- Autenticación de usuarios
- Optimización de caché para reducir llamadas a la API
- Implementación PWA para experiencia móvil mejorada

## Licencia

Este proyecto es para uso personal. 