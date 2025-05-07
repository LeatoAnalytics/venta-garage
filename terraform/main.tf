provider "aws" {
  region = var.aws_region
}

# Módulo de red para crear la VPC y subredes
module "network" {
  source = "./modules/network"

  project_name   = var.project_name
  vpc_cidr       = var.vpc_cidr
  environment    = var.environment
  container_port = var.container_port
}

# Módulo ECR para el registro de contenedores
module "ecr" {
  source = "./modules/ecr"

  repository_name = "${var.project_name}-repo"
}

# Módulo ECS para el servicio de contenedores
module "ecs" {
  source = "./modules/ecs"

  project_name           = var.project_name
  environment            = var.environment
  ecr_repo_url           = module.ecr.repository_url
  vpc_id                 = module.network.vpc_id
  public_subnets         = module.network.public_subnets
  alb_security_group_id  = module.network.alb_security_group_id
  ecs_security_group_id  = module.network.ecs_security_group_id
  container_port         = var.container_port
  container_cpu          = var.container_cpu
  container_memory       = var.container_memory
  aws_region             = var.aws_region
  s3_bucket_name         = var.s3_bucket_name
  
  # Variables de entorno para el contenedor
  container_environment = [
    { name = "AIRTABLE_API_KEY", value = var.airtable_api_key },
    { name = "AIRTABLE_BASE_ID", value = var.airtable_base_id },
    { name = "AWS_ACCESS_KEY_ID", value = var.aws_access_key_id },
    { name = "AWS_SECRET_ACCESS_KEY", value = var.aws_secret_access_key },
    { name = "S3_BUCKET_NAME", value = var.s3_bucket_name },
    { name = "S3_REGION", value = var.aws_region },
    { name = "PORT", value = tostring(var.container_port) }
  ]
} 