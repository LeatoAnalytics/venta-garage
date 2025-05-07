variable "aws_region" {
  description = "Región de AWS donde se desplegarán los recursos"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "venta-garage"
}

variable "environment" {
  description = "Entorno (dev, prod, etc.)"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_port" {
  description = "Puerto expuesto por el contenedor"
  type        = number
  default     = 8080
}

variable "container_cpu" {
  description = "Unidades de CPU para el contenedor"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Memoria para el contenedor en MiB"
  type        = number
  default     = 512
}

# Variables sensibles
variable "airtable_api_key" {
  description = "API Key de Airtable"
  type        = string
  sensitive   = true
}

variable "airtable_base_id" {
  description = "ID de la base de Airtable"
  type        = string
  sensitive   = true
}

variable "aws_access_key_id" {
  description = "ID de la clave de acceso para S3"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "Clave secreta de acceso para S3"
  type        = string
  sensitive   = true
}

variable "s3_bucket_name" {
  description = "Nombre del bucket S3"
  type        = string
} 