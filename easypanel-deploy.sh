#!/bin/bash

# Script de despliegue específico para EasyPanel
set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}🚀 Despliegue EasyPanel - Venta Garage${NC}"

# Variables
REGISTRY=${REGISTRY:-""}
IMAGE_NAME="venta-garage"
TAG=${TAG:-"latest"}
EASYPANEL_URL=${EASYPANEL_URL:-""}
EASYPANEL_TOKEN=${EASYPANEL_TOKEN:-""}

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [OPCIONES]"
    echo ""
    echo "Variables de entorno requeridas:"
    echo "  REGISTRY           Registry de Docker (ej: tu-usuario/ para Docker Hub)"
    echo "  EASYPANEL_URL      URL de tu EasyPanel (ej: http://tu-ip:3000)"
    echo "  EASYPANEL_TOKEN    Token de API de EasyPanel (opcional)"
    echo ""
    echo "Opciones:"
    echo "  -h, --help         Mostrar esta ayuda"
    echo "  -b, --build        Solo construir imagen"
    echo "  -p, --push         Solo subir imagen"
    echo "  -d, --deploy       Solo desplegar en EasyPanel"
    echo ""
    echo "Ejemplos:"
    echo "  REGISTRY=tu-usuario/ $0"
    echo "  REGISTRY=123456789.dkr.ecr.us-east-1.amazonaws.com/ $0"
}

# Función para construir imagen
build_image() {
    echo -e "${YELLOW}📦 Construyendo imagen Docker...${NC}"
    
    if [ ! -f "Dockerfile" ]; then
        echo -e "${RED}❌ Error: Dockerfile no encontrado${NC}"
        exit 1
    fi
    
    docker build -t ${IMAGE_NAME}:${TAG} .
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Imagen construida: ${IMAGE_NAME}:${TAG}${NC}"
    else
        echo -e "${RED}❌ Error al construir imagen${NC}"
        exit 1
    fi
}

# Función para subir imagen
push_image() {
    if [ -z "$REGISTRY" ]; then
        echo -e "${RED}❌ Error: REGISTRY no configurado${NC}"
        echo "Configura REGISTRY con tu registry de Docker"
        exit 1
    fi
    
    echo -e "${YELLOW}📤 Subiendo imagen...${NC}"
    
    # Etiquetar para registry
    FULL_IMAGE="${REGISTRY}${IMAGE_NAME}:${TAG}"
    docker tag ${IMAGE_NAME}:${TAG} ${FULL_IMAGE}
    
    # Subir imagen
    docker push ${FULL_IMAGE}
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Imagen subida: ${FULL_IMAGE}${NC}"
        echo "FULL_IMAGE=${FULL_IMAGE}" > .env.deploy
    else
        echo -e "${RED}❌ Error al subir imagen${NC}"
        exit 1
    fi
}

# Función para generar configuración EasyPanel
generate_easypanel_config() {
    if [ -f ".env.deploy" ]; then
        source .env.deploy
    else
        FULL_IMAGE="${REGISTRY}${IMAGE_NAME}:${TAG}"
    fi
    
    echo -e "${YELLOW}📝 Generando configuración EasyPanel...${NC}"
    
    cat > easypanel-config.json << EOF
{
  "name": "venta-garage",
  "image": "${FULL_IMAGE}",
  "env": [
    {
      "name": "FLASK_ENV",
      "value": "production"
    },
    {
      "name": "PORT",
      "value": "5001"
    },
    {
      "name": "WORKERS",
      "value": "2"
    },
    {
      "name": "AWS_REGION",
      "value": "us-east-1"
    },
    {
      "name": "SECRET_ARN",
      "value": "arn:aws:secretsmanager:us-east-1:730335181087:secret:venta-garage-secrets-yO4WWw"
    }
  ],
  "ports": [
    {
      "published": 80,
      "target": 5001,
      "protocol": "tcp"
    }
  ],
  "healthcheck": {
    "test": ["CMD", "curl", "-f", "http://localhost:5001/"],
    "interval": "30s",
    "timeout": "10s",
    "retries": 3,
    "start_period": "40s"
  },
  "resources": {
    "memory": "1G",
    "cpu": "1.0"
  },
  "restart_policy": "unless-stopped"
}
EOF
    
    echo -e "${GREEN}✅ Configuración generada: easypanel-config.json${NC}"
}

# Función para desplegar en EasyPanel
deploy_to_easypanel() {
    generate_easypanel_config
    
    echo -e "${YELLOW}🚀 Desplegando en EasyPanel...${NC}"
    
    if [ -z "$EASYPANEL_URL" ]; then
        echo -e "${YELLOW}⚠️  EASYPANEL_URL no configurado${NC}"
        echo "Configuración manual requerida:"
        echo "1. Accede a tu EasyPanel: http://tu-ip:3000"
        echo "2. Crea nueva aplicación"
        echo "3. Usa la configuración de: easypanel-config.json"
        echo "4. O importa el archivo easypanel.yml"
        return
    fi
    
    # Si hay token, intentar despliegue automático
    if [ -n "$EASYPANEL_TOKEN" ]; then
        echo "Intentando despliegue automático..."
        # Aquí iría la lógica de API de EasyPanel
        # curl -X POST "${EASYPANEL_URL}/api/apps" \
        #   -H "Authorization: Bearer ${EASYPANEL_TOKEN}" \
        #   -H "Content-Type: application/json" \
        #   -d @easypanel-config.json
    else
        echo -e "${YELLOW}⚠️  Token no configurado, despliegue manual requerido${NC}"
    fi
}

# Función para verificar prerrequisitos
check_prerequisites() {
    echo -e "${YELLOW}🔍 Verificando prerrequisitos...${NC}"
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ Docker no está instalado${NC}"
        exit 1
    fi
    
    # Verificar que Docker esté corriendo
    if ! docker info &> /dev/null; then
        echo -e "${RED}❌ Docker no está corriendo${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerrequisitos verificados${NC}"
}

# Función principal
main() {
    check_prerequisites
    
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;
        -b|--build)
            build_image
            ;;
        -p|--push)
            push_image
            ;;
        -d|--deploy)
            deploy_to_easypanel
            ;;
        *)
            # Flujo completo
            build_image
            push_image
            deploy_to_easypanel
            
            echo -e "${GREEN}🎉 Despliegue completado${NC}"
            echo ""
            echo "Próximos pasos:"
            echo "1. Accede a EasyPanel: ${EASYPANEL_URL:-http://tu-ip:3000}"
            echo "2. Verifica que la aplicación esté corriendo"
            echo "3. Configura dominio y SSL si es necesario"
            ;;
    esac
}

# Ejecutar función principal
main "$@" 