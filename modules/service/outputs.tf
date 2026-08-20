output "alb_dns_name" {
  description = "Load balancer DNS name."
  value       = aws_lb.main.dns_name
}

# The observability module needs these two to build its alarm dimensions.
output "alb_arn_suffix" {
  description = "Load balancer ARN suffix, as CloudWatch dimensions use it."
  value       = aws_lb.main.arn_suffix
}

output "target_group_arn_suffix" {
  description = "Target group ARN suffix, as CloudWatch dimensions use it."
  value       = aws_lb_target_group.web.arn_suffix
}

output "cluster_name" {
  description = "ECS cluster name."
  value       = aws_ecs_cluster.main.name
}

output "service_name" {
  description = "ECS service name."
  value       = aws_ecs_service.web.name
}
