output "service_url" {
  description = "Public URL of the attendance service."
  value       = "http://${module.service.alb_dns_name}"
}

output "alb_dns_name" {
  description = "Load balancer DNS name (used by the smoke and load tests)."
  value       = module.service.alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster running the service."
  value       = module.service.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name, for describe-services and ECS Exec."
  value       = module.service.service_name
}

output "dashboard_url" {
  description = "CloudWatch dashboard showing the SLO metrics."
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${module.observability.dashboard_name}"
}
