# Guía de Despliegue Docker - Venta Garage

Esta guía te ayudará a desplegar la aplicación Venta Garage usando Docker en AWS Lightsail con EasyPanel.

## 📋 Prerrequisitos

### 1. Servidor Lightsail
- Instancia Ubuntu 20.04 LTS o superior
- Mínimo 2GB RAM, 2 vCPUs
- Docker y Docker Compose instalados
- EasyPanel instalado

### 2. Credenciales AWS
- AWS Secrets Manager configurado con el ARN: `arn:aws:secretsmanager:us-east-1:730335181087:secret:venta-garage-secrets-yO4WWw`
- Permisos IAM para acceder a Secrets Manager y S3

### 3. Base de datos Supabase
- Proyecto configurado con la tabla `productos`
- URL y API Key disponibles

## 🚀 Despliegue Local (Desarrollo)

### 1. Construir la imagen
```bash
# Construir imagen con tag latest
./deploy.sh --build

# O construir con tag específico
./deploy.sh --build v1.0.0
```

### 2. Ejecutar localmente
```bash
# Usando Docker Compose
docker-compose up -d

# O usando Docker directamente
docker run -d \
  -p 5001:5001 \
  -e AWS_REGION=us-east-1 \
  -e SECRET_ARN=arn:aws:secretsmanager:us-east-1:730335181087:secret:venta-garage-secrets-yO4WWw \
  venta-garage:latest
```

### 3. Verificar funcionamiento
```bash
# Test automático
./deploy.sh --test

# O verificar manualmente
curl http://localhost:5001/
```

## 🌐 Despliegue en Lightsail con EasyPanel

### 1. Preparar el servidor

#### Instalar Docker
```bash
# Conectar por SSH a tu instancia Lightsail
ssh -i tu-clave.pem ubuntu@tu-ip-publica

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### Instalar EasyPanel
```bash
# Instalar EasyPanel
curl -sSL https://get.easypanel.io | sh
```

### 2. Configurar Registry de Docker

#### Opción A: Docker Hub
```bash
# En tu máquina local
docker tag venta-garage:latest tu-usuario/venta-garage:latest
docker push tu-usuario/venta-garage:latest
```

#### Opción B: AWS ECR
```bash
# Crear repositorio ECR
aws ecr create-repository --repository-name venta-garage --region us-east-1

# Obtener URL del repositorio
aws ecr describe-repositories --repository-names venta-garage --region us-east-1

# Login y push
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin TU-ACCOUNT-ID.dkr.ecr.us-east-1.amazonaws.com
docker tag venta-garage:latest TU-ACCOUNT-ID.dkr.ecr.us-east-1.amazonaws.com/venta-garage:latest
docker push TU-ACCOUNT-ID.dkr.ecr.us-east-1.amazonaws.com/venta-garage:latest
```

### 3. Configurar EasyPanel

#### Crear aplicación en EasyPanel
1. Acceder a EasyPanel: `http://tu-ip-lightsail:3000`
2. Crear nueva aplicación
3. Seleccionar "Docker Image"
4. Configurar según `easypanel.yml`

#### Variables de entorno requeridas
```
FLASK_ENV=production
PORT=5001
WORKERS=2
AWS_REGION=us-east-1
SECRET_ARN=arn:aws:secretsmanager:us-east-1:730335181087:secret:venta-garage-secrets-yO4WWw
```

#### Configuración de red
- Puerto interno: 5001
- Puerto público: 80 o 443 (con SSL)
- Dominio: tu-dominio.com (opcional)

### 4. Configurar IAM para Lightsail

#### Crear rol IAM
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:730335181087:secret:venta-garage-secrets-yO4WWw"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::tu-bucket-s3",
        "arn:aws:s3:::tu-bucket-s3/*"
      ]
    }
  ]
}
```

#### Configurar credenciales en Lightsail
```bash
# En el servidor Lightsail
aws configure
# Introducir Access Key ID y Secret Access Key
```

## 🔧 Configuración Avanzada

### 1. SSL/HTTPS
```bash
# Instalar Certbot en Lightsail
sudo apt install certbot

# Obtener certificado SSL
sudo certbot certonly --standalone -d tu-dominio.com

# Configurar en EasyPanel o usar proxy reverso
```

### 2. Monitoreo y Logs
```bash
# Ver logs de la aplicación
docker logs -f nombre-contenedor

# Monitoreo de recursos
docker stats

# Health check
curl -f http://localhost:5001/ || echo "Servicio no disponible"
```

### 3. Backup y Restauración
```bash
# Backup de la imagen
docker save venta-garage:latest | gzip > venta-garage-backup.tar.gz

# Restaurar imagen
gunzip -c venta-garage-backup.tar.gz | docker load
```

## 🔄 Actualizaciones

### 1. Actualización automática
```bash
# Script de actualización
#!/bin/bash
cd /path/to/app
git pull origin main
./deploy.sh --build
docker-compose down
docker-compose up -d
```

### 2. Rollback
```bash
# Volver a versión anterior
docker tag venta-garage:v1.0.0 venta-garage:latest
docker-compose down
docker-compose up -d
```

## 🛠️ Troubleshooting

### Problemas comunes

#### 1. Error de conexión a AWS Secrets Manager
```bash
# Verificar credenciales
aws sts get-caller-identity

# Verificar permisos
aws secretsmanager get-secret-value --secret-id arn:aws:secretsmanager:us-east-1:730335181087:secret:venta-garage-secrets-yO4WWw
```

#### 2. Error de conexión a Supabase
```bash
# Verificar conectividad
curl -I https://tu-proyecto.supabase.co

# Verificar en logs
docker logs nombre-contenedor | grep -i supabase
```

#### 3. Problemas de memoria
```bash
# Verificar uso de memoria
docker stats

# Ajustar recursos en EasyPanel o docker-compose.yml
```

### Logs útiles
```bash
# Logs de aplicación
docker logs -f venta-garage

# Logs del sistema
sudo journalctl -u docker

# Logs de EasyPanel
sudo journalctl -u easypanel
```

## 📊 Métricas y Monitoreo

### Health Checks
- Endpoint: `http://tu-dominio.com/`
- Intervalo: 30 segundos
- Timeout: 10 segundos
- Reintentos: 3

### Recursos recomendados
- **Desarrollo**: 512MB RAM, 0.5 CPU
- **Producción**: 1GB RAM, 1 CPU
- **Alta carga**: 2GB RAM, 2 CPU

## 🔐 Seguridad

### Mejores prácticas
1. Usar usuario no-root en contenedor ✅
2. Variables de entorno para secretos ✅
3. Health checks configurados ✅
4. Logs centralizados ✅
5. SSL/TLS habilitado (configurar)
6. Firewall configurado (configurar)

### Configuración de firewall
```bash
# En Lightsail, configurar reglas:
# - Puerto 22 (SSH) - Solo tu IP
# - Puerto 80 (HTTP) - Público
# - Puerto 443 (HTTPS) - Público
# - Puerto 3000 (EasyPanel) - Solo tu IP
```

## 📞 Soporte

Si encuentras problemas:
1. Revisar logs: `docker logs nombre-contenedor`
2. Verificar health check: `curl -f http://localhost:5001/`
3. Revisar configuración de variables de entorno
4. Verificar conectividad a AWS y Supabase

---

¡Tu aplicación Venta Garage está lista para producción! 🎉 