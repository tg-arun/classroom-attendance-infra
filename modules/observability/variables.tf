variable "project" {
  description = "Name prefix used for every resource."
  type        = string
}

variable "region" {
  description = "Region the dashboard reads metrics from."
  type        = string
}

variable "alb_arn_suffix" {
  description = "Load balancer ARN suffix, from the service module."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix, from the service module."
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name, from the service module."
  type        = string
}

variable "service_name" {
  description = "ECS service name, from the service module."
  type        = string
}

variable "alert_email" {
  description = "Optional email address that receives SLO alerts. Leave empty to skip the subscription."
  type        = string
  default     = ""
}

variable "error_rate_threshold" {
  description = "Percentage of 5xx responses that breaches the success SLO."
  type        = number
  default     = 0.1
}

variable "latency_threshold_seconds" {
  description = "Response time at p99.9 that breaches the latency SLO."
  type        = number
  default     = 0.3
}
