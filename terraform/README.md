# Despliegue de Venta Garage en AWS ECS con Terraform

Este directorio contiene la configuración de Terraform para desplegar la aplicación Venta Garage en AWS utilizando ECS (Elastic Container Service) y ECR (Elastic Container Registry).

## Arquitectura

La infraestructura desplegada incluye:

- **VPC y Redes**: VPC con subnets públicas en dos zonas de disponibilidad
- **ECR**: Repositorio para almacenar la imagen Docker de la aplicación
- **ECS**: Servicio Fargate para ejecutar contenedores sin administrar servidores
- **ALB**: Application Load Balancer para dirigir el tráfico
- **IAM**: Roles y políticas para permisos adecuados
- **CloudWatch**: Logs para monitoreo

## Prerrequisitos

- [Terraform](https://www.terraform.io/downloads.html) (v1.0.0 o superior)
- [AWS CLI](https://aws.amazon.com/cli/) configurado con credenciales adecuadas
- [Docker](https://www.docker.com/get-started) para construir la imagen

## Uso

### 1. Configuración de variables

Crea un archivo `terraform.tfvars` basado en el ejemplo proporcionado:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edita el archivo con tus valores específicos.

### 2. Inicializar Terraform

```bash
terraform init
```

### 3. Validar la configuración

```bash
terraform validate
```

### 4. Revisar el plan de ejecución

```bash
terraform plan
```

### 5. Aplicar la configuración

```bash
terraform apply
```

Confirma la aplicación escribiendo `yes` cuando se te solicite.

### 6. Construir y subir la imagen Docker

Una vez creada la infraestructura, debes construir y subir la imagen Docker al repositorio ECR:

```bash
# Inicia sesión en ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(terraform output -raw ecr_repository_url | cut -d'/' -f1)

# Construye la imagen
docker build -t venta-garage .

# Etiqueta la imagen
docker tag venta-garage:latest $(terraform output -raw ecr_repository_url):latest

# Sube la imagen
docker push $(terraform output -raw ecr_repository_url):latest
```

## Acceso a la aplicación

Una vez completado el despliegue, accede a la aplicación a través de la URL del balanceador de carga:

```bash
echo "Aplicación disponible en: $(terraform output -raw application_url)"
```

## Limpieza

Para eliminar todos los recursos creados:

```bash
terraform destroy
```

Confirma la eliminación escribiendo `yes` cuando se te solicite.

## Notas adicionales

- La aplicación se despliega con un único contenedor Fargate para minimizar costos
- La configuración utiliza subnets públicas para simplificar la arquitectura
- Para un entorno de producción, considera añadir HTTPS, redes privadas y más replicas 