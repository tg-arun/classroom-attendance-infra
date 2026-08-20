variable "project" {
  description = "Name prefix used for every resource."
  type        = string
  default     = "classroom-attendance"
}

variable "environment" {
  description = "Environment name (dev / staging / prod)."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "How many Availability Zones to spread across."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2
    error_message = "At least 2 AZs are required to survive the loss of one AZ."
  }
}

variable "container_image" {
  description = "Image to run. Pinned to a version on purpose - :latest would let a scale-out event change what is running."
  type        = string
  default     = "nginx:1.27-alpine"
}

variable "task_cpu" {
  description = "CPU units per task. 1024 = 1 vCPU."
  type        = number
  default     = 1024
}

variable "task_memory" {
  description = "Memory per task in MiB. Fargate only allows certain pairings with task_cpu."
  type        = number
  default     = 2048
}

variable "min_tasks" {
  description = "Minimum running tasks (at least one per AZ)."
  type        = number
  default     = 2
}

variable "max_tasks" {
  description = "Maximum tasks the service may scale to."
  type        = number
  default     = 12
}

variable "requests_per_target" {
  description = "Target tracking goal: requests per task per minute. See README for the 6,000 req/s maths."
  type        = number
  default     = 60000
}

variable "log_retention_days" {
  description = "How long to keep container logs in CloudWatch."
  type        = number
  default     = 30
}

variable "allowed_http_cidrs" {
  description = "Who may reach the load balancer. Narrow this down for non-public environments."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "alert_email" {
  description = "Optional email address that receives SLO alerts. Leave empty to skip the subscription."
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN. Set it and the load balancer serves HTTPS and redirects port 80 to it. Empty means plain HTTP, which is only acceptable for a review environment."
  type        = string
  default     = ""
}

variable "enable_deletion_protection" {
  description = "Stops the load balancer being deleted by accident. Turn this on for production."
  type        = bool
  default     = false
}

variable "access_logs_retention_days" {
  description = "How long to keep load balancer access logs."
  type        = number
  default     = 30
}
