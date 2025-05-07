output "vpc_id" {
  description = "ID de la VPC creada"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "IDs de las subnets públicas"
  value       = aws_subnet.public[*].id
}

output "alb_security_group_id" {
  description = "ID del grupo de seguridad para ALB"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ID del grupo de seguridad para ECS"
  value       = aws_security_group.ecs.id
} 