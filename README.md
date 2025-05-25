# 🏪 Venta Garage - Aplicación Web

Aplicación web para gestionar ventas de garage con una arquitectura moderna y simplificada.

## 🏗️ Arquitectura

```
Frontend (Flask + Bootstrap)
    ↓
Docker Container (LightSail + EasyPanel)
    ↓
Supabase (PostgreSQL + Auth + API)
    ↓
Amazon S3 (Almacenamiento de imágenes)
```

## ✨ Características

- **🔐 Autenticación:** Sistema de login/registro con Supabase Auth
- **📦 Gestión de Productos:** CRUD completo para productos
- **🖼️ Subida de Imágenes:** Almacenamiento directo en Amazon S3
- **📱 Responsive:** Interfaz adaptable a todos los dispositivos
- **🚀 Deployment:** Automatizado con Docker y EasyPanel
- **💾 Base de Datos:** PostgreSQL gestionado por Supabase

## 🚀 Deployment Rápido

### Con EasyPanel (Recomendado)

```bash
# 1. Clonar el repositorio
git clone <tu-repo>
cd script

# 2. Configurar variables de entorno
cp .env.example .env
# Editar .env con tus credenciales

# 3. Desplegar con EasyPanel
./easypanel-deploy.sh
```

### Con Docker Compose

```bash
# Desarrollo
docker-compose up

# Producción
docker-compose -f docker-compose.prod.yml up -d
```

## ⚙️ Configuración

### Variables de Entorno Requeridas

```bash
# Supabase
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_SERVICE_KEY=tu-service-key
SUPABASE_ANON_KEY=tu-anon-key

# AWS S3
AWS_ACCESS_KEY_ID=tu-access-key
AWS_SECRET_ACCESS_KEY=tu-secret-key
AWS_S3_BUCKET=tu-bucket-name
AWS_REGION=us-east-1

# Flask
FLASK_SECRET_KEY=tu-secret-key-muy-seguro
FLASK_ENV=production
```

### Base de Datos

1. Crear proyecto en [Supabase](https://supabase.com)
2. Ejecutar el esquema:

```sql
-- Ver database_setup.sql para el esquema completo
```

## 📦 Estructura del Proyecto

```
script/
├── app_docker.py           # Aplicación Flask principal
├── database_setup.sql      # Esquema de base de datos
├── requirements.txt        # Dependencias Python
├── Dockerfile             # Imagen Docker
├── docker-compose.yml     # Desarrollo
├── docker-compose.prod.yml # Producción
├── easypanel-deploy.sh    # Script de deployment
├── easypanel.yml          # Configuración EasyPanel
├── templates/             # Plantillas HTML
├── static/                # Archivos estáticos (CSS, JS)
└── DOCKER_DEPLOYMENT.md   # Documentación de deployment
```

## 🛠️ Desarrollo Local

```bash
# 1. Crear entorno virtual
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate   # Windows

# 2. Instalar dependencias
pip install -r requirements.txt

# 3. Configurar variables de entorno
cp .env.example .env
# Editar .env

# 4. Ejecutar aplicación
python app_docker.py
```

## 🌟 Beneficios de esta Arquitectura

### ✅ **Simplificada**
- Sin sincronización compleja entre sistemas
- Un solo punto de verdad (Supabase)
- Menos componentes = menos problemas

### ✅ **Económica**
- Supabase Free Tier: 50,000 MAU, 500MB DB, 5GB bandwidth
- S3: Solo pagas por lo que usas
- LightSail: Hosting predictible desde $5/mes

### ✅ **Escalable**
- Supabase escala automáticamente
- S3 almacenamiento ilimitado
- EasyPanel facilita el deployment

### ✅ **Moderna**
- API REST automática con Supabase
- Autenticación robusta incluida
- Real-time capabilities
- Interfaz administrativa web

## 🚀 Próximos Pasos

1. **Configurar Supabase:** Crear proyecto y configurar esquema
2. **Configurar S3:** Crear bucket y políticas
3. **Deployment:** Usar EasyPanel para desplegar en LightSail
4. **Personalizar:** Ajustar templates y estilos según necesidades

## 📚 Documentación

- [Supabase Docs](https://supabase.com/docs)
- [EasyPanel Docs](https://easypanel.io/docs)
- [Docker Deployment Guide](DOCKER_DEPLOYMENT.md)

---

**¡Tu venta garage nunca fue tan fácil de gestionar!** 🎉 