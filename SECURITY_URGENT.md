# 🚨 ALERTA DE SEGURIDAD CRÍTICA

## PROBLEMA DETECTADO

En el deployment de EasyPanel, las credenciales AWS están siendo expuestas en texto plano en los logs de Docker build:

```
--build-arg 'AWS_ACCESS_KEY_ID=AKIA***' 
--build-arg 'AWS_SECRET_ACCESS_KEY=***'
```

**ESTO ES EXTREMADAMENTE PELIGROSO** - Los logs de Docker build son visibles y pueden ser accedidos por terceros.

## CREDENCIALES COMPROMETIDAS

Las siguientes credenciales están COMPROMETIDAS y deben ser INMEDIATAMENTE desactivadas:

- **AWS Access Key ID**: `AKIA2UC26PEPZ6EY****` (termina en LXQ3)
- **AWS Secret Access Key**: `***` (credencial comprometida en logs)

## ACCIONES INMEDIATAS REQUERIDAS

### 1. DESACTIVAR CREDENCIALES COMPROMETIDAS (URGENTE)
```bash
# En AWS Console:
# IAM → Users → script-s3-venta-garage-reader → Security credentials
# → Deactivate/Delete Access Key que termina en LXQ3
```

### 2. CREAR NUEVAS CREDENCIALES
```bash
# Crear nuevas credenciales AWS
# Actualizar AWS Secrets Manager con las nuevas credenciales
```

### 3. ACTUALIZAR EASYPANEL
- **NO** usar build arguments para credenciales
- Usar **SOLO** variables de entorno en runtime
- Configurar credenciales en EasyPanel UI (Environment Variables)

## SOLUCIÓN IMPLEMENTADA

✅ Dockerfile actualizado - eliminados build args para credenciales
✅ start_simple.sh creado
✅ easypanel.yml actualizado para usar solo environment variables

## PRÓXIMOS PASOS

1. **INMEDIATO**: Desactivar credenciales comprometidas
2. Crear nuevas credenciales AWS
3. Configurar nuevas credenciales en EasyPanel UI
4. Re-deploy con configuración segura

## PREVENCIÓN FUTURA

- ✅ NUNCA usar build arguments para credenciales
- ✅ SIEMPRE usar variables de entorno en runtime
- ✅ SIEMPRE verificar logs antes de deployment
- ✅ Usar AWS Secrets Manager cuando sea posible 