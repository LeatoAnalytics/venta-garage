output "ecr_repository_url" {
  description = "URL del repositorio ECR"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "Nombre del cluster ECS"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Nombre del servicio ECS"
  value       = module.ecs.service_name
}

output "load_balancer_dns" {
  description = "DNS del Load Balancer"
  value       = module.ecs.load_balancer_dns
}

output "application_url" {
  description = "URL de la aplicación"
  value       = "http://${module.ecs.load_balancer_dns}"
} 