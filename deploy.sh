#!/bin/bash
set -e

# Colores para mejor lectura
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Script de Despliegue para Venta Garage ===${NC}"

# Verificar que AWS CLI está instalado
if ! command -v aws &> /dev/null
then
    echo -e "${RED}AWS CLI no está instalado. Por favor, instálalo primero.${NC}"
    exit 1
fi

# Verificar que Terraform está instalado
if ! command -v terraform &> /dev/null
then
    echo -e "${RED}Terraform no está instalado. Por favor, instálalo primero.${NC}"
    exit 1
fi

# Verificar que Docker está instalado
if ! command -v docker &> /dev/null
then
    echo -e "${RED}Docker no está instalado. Por favor, instálalo primero.${NC}"
    exit 1
fi

# Función para desplegar la infraestructura
deploy_infrastructure() {
    echo -e "${YELLOW}Iniciando despliegue de infraestructura con Terraform...${NC}"
    
    # Navegar al directorio de Terraform
    cd terraform

    # Inicializar Terraform
    echo -e "${YELLOW}Inicializando Terraform...${NC}"
    terraform init
    
    # Validar la configuración
    echo -e "${YELLOW}Validando configuración...${NC}"
    terraform validate
    
    # Crear un plan
    echo -e "${YELLOW}Creando plan de despliegue...${NC}"
    terraform plan -out=tfplan
    
    # Aplicar el plan
    echo -e "${YELLOW}Aplicando plan de infraestructura...${NC}"
    terraform apply tfplan
    
    # Obtener outputs
    REPO_URL=$(terraform output -raw ecr_repository_url)
    APP_URL=$(terraform output -raw application_url)
    
    echo -e "${GREEN}Infraestructura desplegada correctamente.${NC}"
    echo -e "ECR Repository URL: ${REPO_URL}"
    echo -e "Application URL: ${APP_URL}"
    
    # Guardar las URLs para su uso posterior
    echo "REPO_URL=${REPO_URL}" > ../deployment_info.env
    echo "APP_URL=${APP_URL}" >> ../deployment_info.env
    
    cd ..
}

# Función para construir y subir la imagen Docker
build_and_push_image() {
    echo -e "${YELLOW}Construyendo y subiendo imagen Docker...${NC}"
    
    # Cargar la información del despliegue
    source deployment_info.env
    
    # Extraer registro base
    ECR_REGISTRY=$(echo $REPO_URL | cut -d'/' -f1)
    
    # Iniciar sesión en ECR
    echo -e "${YELLOW}Iniciando sesión en ECR...${NC}"
    aws ecr get-login-password --region $(aws configure get region) | docker login --username AWS --password-stdin $ECR_REGISTRY
    
    # Construir imagen
    echo -e "${YELLOW}Construyendo imagen Docker...${NC}"
    docker build -t venta-garage .
    
    # Etiquetar imagen
    echo -e "${YELLOW}Etiquetando imagen...${NC}"
    docker tag venta-garage:latest $REPO_URL:latest
    
    # Subir imagen
    echo -e "${YELLOW}Subiendo imagen a ECR...${NC}"
    docker push $REPO_URL:latest
    
    echo -e "${GREEN}Imagen Docker construida y subida correctamente.${NC}"
    echo -e "La aplicación estará disponible en: ${APP_URL}"
    echo -e "${YELLOW}Nota: Puede tomar unos minutos hasta que ECS implemente la nueva tarea.${NC}"
}

# Función principal
main() {
    echo -e "${YELLOW}¿Qué acción deseas realizar?${NC}"
    echo "1. Desplegar infraestructura"
    echo "2. Construir y subir imagen Docker"
    echo "3. Realizar ambas acciones"
    echo "4. Destruir infraestructura"
    read -p "Selecciona una opción (1-4): " choice
    
    case $choice in
        1)
            deploy_infrastructure
            ;;
        2)
            build_and_push_image
            ;;
        3)
            deploy_infrastructure
            build_and_push_image
            ;;
        4)
            echo -e "${RED}ATENCIÓN: Esto eliminará TODOS los recursos creados.${NC}"
            read -p "¿Estás seguro? (s/n): " confirm
            if [[ $confirm == "s" || $confirm == "S" ]]; then
                cd terraform && terraform destroy
            else
                echo "Operación cancelada."
            fi
            ;;
        *)
            echo -e "${RED}Opción no válida.${NC}"
            ;;
    esac
}

# Ejecutar la función principal
main 