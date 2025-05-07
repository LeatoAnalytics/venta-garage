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

### Despliegue en AWS (con contenedores)

La aplicación está preparada para desplegarse en AWS utilizando contenedores Docker y ECS (Elastic Container Service):

#### Prerrequisitos para despliegue en AWS

- Cuenta de AWS con permisos adecuados
- [AWS CLI](https://aws.amazon.com/cli/) configurado con credenciales 
- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0 o superior)
- [Docker](https://www.docker.com/get-started) para construcción de imágenes

#### Despliegue con script asistente

Se incluye un script para facilitar el despliegue:

```bash
./deploy.sh
```

El script ofrece opciones para:
1. Desplegar solo infraestructura
2. Construir y subir imagen Docker
3. Realizar ambas acciones
4. Destruir infraestructura

#### Despliegue manual

Para un despliegue manual, consulta la documentación en el directorio `terraform/`.

#### Arquitectura en AWS

La infraestructura en AWS incluye:
- VPC con subnets en múltiples zonas de disponibilidad
- Elastic Container Registry (ECR) para almacenar la imagen Docker
- ECS Fargate para ejecutar la aplicación sin administrar servidores
- Application Load Balancer para distribuir el tráfico
- Roles IAM para acceso a servicios necesarios
- CloudWatch para logs y monitoreo

## Posibles Mejoras Futuras

- Sistema de administración para actualizar productos
- Integración de pagos
- Autenticación de usuarios
- Optimización de caché para reducir llamadas a la API
- Implementación PWA para experiencia móvil mejorada

## Licencia

Este proyecto es para uso personal. 