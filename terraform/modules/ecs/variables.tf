variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
}

variable "environment" {
  description = "Entorno (dev, prod, etc.)"
  type        = string
}

variable "ecr_repo_url" {
  description = "URL del repositorio ECR"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "public_subnets" {
  description = "IDs de las subnets públicas"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ID del grupo de seguridad para ALB"
  type        = string
}

variable "ecs_security_group_id" {
  description = "ID del grupo de seguridad para ECS"
  type        = string
}

variable "container_port" {
  description = "Puerto expuesto por el contenedor"
  type        = number
}

variable "container_cpu" {
  description = "Unidades de CPU para el contenedor"
  type        = number
}

variable "container_memory" {
  description = "Memoria para el contenedor en MiB"
  type        = number
}

variable "aws_region" {
  description = "Región de AWS"
  type        = string
}

variable "container_environment" {
  description = "Variables de entorno para el contenedor"
  type        = list(object({
    name  = string
    value = string
  }))
}

variable "s3_bucket_name" {
  description = "Nombre del bucket S3"
  type        = string
  default     = "venta-garage"
} 