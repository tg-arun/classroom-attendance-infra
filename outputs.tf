output "service_url" {
  description = "Public URL of the attendance service."
  value       = "http://${aws_lb.main.dns_name}"
}

output "alb_dns_name" {
  description = "Load balancer DNS name (used by the smoke and load tests)."
  value       = aws_lb.main.dns_name
}

output "autoscaling_group_name" {
  description = "Name of the web tier Auto Scaling group."
  value       = aws_autoscaling_group.web.name
}

output "dashboard_url" {
  description = "CloudWatch dashboard showing the SLO metrics."
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.slo.dashboard_name}"
}
