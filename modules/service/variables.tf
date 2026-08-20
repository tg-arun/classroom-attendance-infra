variable "project" {
  description = "Name prefix used for every resource."
  type        = string
}

variable "region" {
  description = "Region, used for the log driver configuration."
  type        = string
}

variable "vpc_id" {
  description = "VPC to run in."
  type        = string
}

variable "public_subnet_ids" {
  description = "Subnets for the load balancer."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Subnets for the tasks."
  type        = list(string)
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
  description = "Target tracking goal: requests per task per minute. See the README for the 6,000 req/s maths."
  type        = number
  default     = 60000
}

variable "allowed_http_cidrs" {
  description = "Who may reach the load balancer."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "certificate_arn" {
  description = "ACM certificate ARN. Set it and the load balancer serves HTTPS and redirects port 80 to it."
  type        = string
  default     = ""
}

variable "enable_deletion_protection" {
  description = "Stops the load balancer being deleted by accident."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "How long to keep container logs in CloudWatch."
  type        = number
  default     = 30
}

variable "access_logs_retention_days" {
  description = "How long to keep load balancer access logs."
  type        = number
  default     = 30
}
