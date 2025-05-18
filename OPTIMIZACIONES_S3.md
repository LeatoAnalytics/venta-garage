# Optimizaciones para Reducir Costos de S3

Este documento detalla las optimizaciones implementadas para reducir los costos de Amazon S3 en la aplicación Venta Garage.

## 1. Optimizaciones Implementadas en el Código

### 1.1 Reducción del Tiempo de Expiración de URLs Prefirmadas
- **Antes:** URLs prefirmadas con expiración de 7 días (604800 segundos)
- **Ahora:** Reducido a 3 horas (10800 segundos)
- **Beneficio:** Menor número de solicitudes GET y generatePresignedUrl

### 1.2 Sistema de Caché en Memoria
- Se implementó un sistema de caché en memoria para almacenar:
  - URLs prefirmadas de imágenes principales
  - Conjuntos completos de imágenes por carpeta
  - Categorías activas
- **Beneficio:** Reducción drástica de operaciones list_objects_v2 y generatePresignedUrl

### 1.3 Carga Bajo Demanda de Imágenes
- En la página principal y de categorías, solo se cargan las imágenes principales
- Las imágenes adicionales solo se cargan en la página de detalles del producto
- **Beneficio:** Reducción de solicitudes S3 innecesarias

### 1.4 Limpieza Periódica de Caché
- Se implementó un sistema de limpieza automática de caché cada 30 minutos
- **Beneficio:** Previene fugas de memoria y asegura que las URLs prefirmadas estén actualizadas

## 2. Recomendaciones Adicionales para AWS

### 2.1 Configurar CloudFront CDN
Para reducir aún más los costos, se recomienda implementar Amazon CloudFront como CDN:

```terraform
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = "${var.s3_bucket_name}.s3.amazonaws.com"
    origin_id   = "S3-${var.s3_bucket_name}"
    
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }
  
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.s3_bucket_name}"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }
  
  price_class = "PriceClass_100"
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.s3_bucket_name}"
}
```

### 2.2 Configurar Política de Ciclo de Vida para S3

Configurar una política de ciclo de vida para mover objetos menos accedidos a clases de almacenamiento más económicas:

```terraform
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  bucket = aws_s3_bucket.venta_garage.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    filter {
      prefix = ""
    }
  }
}
```

### 2.3 Configurar Métricas de CloudWatch para S3

Configurar métricas detalladas para monitorear el uso de S3:

```terraform
resource "aws_s3_bucket_metric" "venta_garage_metrics" {
  bucket = aws_s3_bucket.venta_garage.id
  name   = "EntireBucket"
}
```

## 3. Estimación de Reducción de Costos

Con las optimizaciones implementadas, se espera una reducción de costos en:

1. **Solicitudes GET**: Reducción de aproximadamente 70-80%
2. **Operaciones list_objects_v2**: Reducción de aproximadamente 90%
3. **Ancho de banda**: Reducción de aproximadamente 40-50%

## 4. Monitoreo de Mejoras

Para validar la efectividad de estas optimizaciones, se recomienda:

1. Monitorear las métricas de S3 durante 30 días después de la implementación
2. Comparar la factura de AWS antes y después de las optimizaciones
3. Ajustar los tiempos de caché según sea necesario
4. Considerar la implementación de CloudFront si los costos siguen siendo altos 