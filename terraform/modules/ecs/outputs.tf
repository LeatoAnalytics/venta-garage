output "cluster_name" {
  description = "Nombre del cluster ECS"
  value       = aws_ecs_cluster.main.name
}

output "cluster_id" {
  description = "ID del cluster ECS"
  value       = aws_ecs_cluster.main.id
}

output "service_name" {
  description = "Nombre del servicio ECS"
  value       = aws_ecs_service.app.name
}

output "task_definition_arn" {
  description = "ARN de la definición de tarea"
  value       = aws_ecs_task_definition.app.arn
}

output "load_balancer_dns" {
  description = "DNS del Load Balancer"
  value       = aws_lb.main.dns_name
}

output "target_group_arn" {
  description = "ARN del target group"
  value       = aws_lb_target_group.app.arn
} 