variable "project" {
  description = "Name prefix for all resources."
  type        = string
  default     = "classroom-attendance"
}

variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "min_tasks" {
  description = "One task per AZ when things are quiet."
  type        = number
  default     = 2
}

variable "max_tasks" {
  type    = number
  default = 12
}

variable "requests_per_target" {
  description = "Scaling target: requests per task per minute. 60000 = 1000 req/s."
  type        = number
  default     = 60000
}

variable "alert_email" {
  description = "Where alarms are sent. Leave empty to skip the subscription."
  type        = string
  default     = ""
}
