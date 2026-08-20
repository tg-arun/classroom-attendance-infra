output "alerts_topic_arn" {
  description = "SNS topic every SLO alarm publishes to."
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard."
  value       = aws_cloudwatch_dashboard.slo.dashboard_name
}
