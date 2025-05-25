#!/bin/bash
set -e

# Colores para mejor lectura
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Script de Despliegue para Venta Garage ===${NC}"

# Variables por defecto
IMAGE_NAME="venta-garage"
TAG="latest"
REGISTRY=${REGISTRY:-""}

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [OPCIONES] [TAG]"
    echo ""
    echo "Opciones:"
    echo "  -h, --help     Mostrar esta ayuda"
    echo "  -b, --build    Solo construir la imagen"
    echo "  -p, --push     Solo subir la imagen (requiere REGISTRY)"
    echo "  -t, --test     Ejecutar tests locales"
    echo ""
    echo "Variables de entorno:"
    echo "  REGISTRY       Registry de Docker (ej: your-registry.com/)"
    echo ""
    echo "Ejemplos:"
    echo "  $0 --build           # Construir con tag 'latest'"
    echo "  $0 --build v1.0.0    # Construir con tag 'v1.0.0'"
    echo "  $0 --test            # Ejecutar tests"
    echo "  REGISTRY=myregistry.com/ $0 --push  # Solo subir"
}

# Verificar que Docker está instalado y corriendo
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker no está instalado${NC}"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker no está corriendo. Inicia Docker Desktop primero.${NC}"
        exit 1
    fi
}

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

# Función para construir la imagen
build_image() {
    echo -e "${YELLOW}📦 Construyendo imagen Docker...${NC}"
    
    # Verificar que los archivos necesarios existen
    if [ ! -f "Dockerfile" ]; then
        echo -e "${RED}❌ Error: Dockerfile no encontrado${NC}"
        exit 1
    fi
    
    if [ ! -f "requirements.txt" ]; then
        echo -e "${RED}❌ Error: requirements.txt no encontrado${NC}"
        exit 1
    fi
    
    # Construir la imagen
    echo "Construyendo imagen: ${IMAGE_NAME}:${TAG}"
    docker build -t ${IMAGE_NAME}:${TAG} .
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Imagen construida exitosamente: ${IMAGE_NAME}:${TAG}${NC}"
    else
        echo -e "${RED}❌ Error al construir la imagen${NC}"
        exit 1
    fi
}

# Función para subir la imagen
push_image() {
    if [ -z "$REGISTRY" ]; then
        echo -e "${RED}❌ Error: REGISTRY no está configurado${NC}"
        echo "Configura la variable REGISTRY con tu registry de Docker"
        exit 1
    fi
    
    echo -e "${YELLOW}📤 Subiendo imagen al registry...${NC}"
    
    # Etiquetar para el registry
    docker tag ${IMAGE_NAME}:${TAG} ${REGISTRY}${IMAGE_NAME}:${TAG}
    
    # Subir la imagen
    docker push ${REGISTRY}${IMAGE_NAME}:${TAG}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Imagen subida exitosamente: ${REGISTRY}${IMAGE_NAME}:${TAG}${NC}"
    else
        echo -e "${RED}❌ Error al subir la imagen${NC}"
        exit 1
    fi
}

# Función para ejecutar tests locales
run_tests() {
    echo -e "${YELLOW}🧪 Ejecutando tests locales...${NC}"
    
    # Verificar que la imagen existe
    if ! docker image inspect ${IMAGE_NAME}:${TAG} > /dev/null 2>&1; then
        echo -e "${RED}❌ Error: Imagen ${IMAGE_NAME}:${TAG} no encontrada${NC}"
        echo "Ejecuta primero: $0 --build"
        exit 1
    fi
    
    # Ejecutar contenedor de prueba
    echo "Iniciando contenedor de prueba..."
    CONTAINER_ID=$(docker run -d -p 5002:5001 \
        -e AWS_REGION=us-east-1 \
        -e SECRET_ARN=arn:aws:secretsmanager:us-east-1:730335181087:secret:venta-garage-secrets-yO4WWw \
        ${IMAGE_NAME}:${TAG})
    
    # Esperar a que el contenedor esté listo
    echo "Esperando a que el servicio esté listo..."
    sleep 15
    
    # Verificar que el servicio responde
    echo "Verificando que el servicio responde..."
    if curl -f http://localhost:5002/ > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Test exitoso: El servicio responde correctamente${NC}"
    else
        echo -e "${RED}❌ Test fallido: El servicio no responde${NC}"
        echo "Logs del contenedor:"
        docker logs $CONTAINER_ID
    fi
    
    # Limpiar
    echo "Limpiando contenedor de prueba..."
    docker stop $CONTAINER_ID > /dev/null 2>&1
    docker rm $CONTAINER_ID > /dev/null 2>&1
}

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -b|--build)
            ACTION="build"
            shift
            # Si hay un argumento siguiente que no empieza con -, es el tag
            if [[ $# -gt 0 && ! $1 =~ ^- ]]; then
                TAG="$1"
                shift
            fi
            ;;
        -p|--push)
            ACTION="push"
            shift
            # Si hay un argumento siguiente que no empieza con -, es el tag
            if [[ $# -gt 0 && ! $1 =~ ^- ]]; then
                TAG="$1"
                shift
            fi
            ;;
        -t|--test)
            ACTION="test"
            shift
            # Si hay un argumento siguiente que no empieza con -, es el tag
            if [[ $# -gt 0 && ! $1 =~ ^- ]]; then
                TAG="$1"
                shift
            fi
            ;;
        *)
            # Si no es una opción, debe ser el tag
            if [[ ! $1 =~ ^- ]]; then
                TAG="$1"
            else
                echo -e "${RED}❌ Opción desconocida: $1${NC}"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Verificar Docker antes de cualquier operación
check_docker

# Ejecutar la acción correspondiente
case "${ACTION:-default}" in
    build)
        build_image
        ;;
    push)
        push_image
        ;;
    test)
        run_tests
        ;;
    default)
        echo -e "${YELLOW}⚠️  No se especificó una acción. Usa --help para ver las opciones disponibles.${NC}"
        echo ""
        echo "Acciones disponibles:"
        echo "  ./deploy.sh --build    # Construir imagen"
        echo "  ./deploy.sh --test     # Ejecutar tests"
        echo "  ./deploy.sh --push     # Subir imagen (requiere REGISTRY)"
        echo "  ./deploy.sh --help     # Mostrar ayuda"
        ;;
esac 