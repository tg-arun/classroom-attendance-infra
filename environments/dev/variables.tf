variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "ap-south-1"
}

variable "alert_email" {
  description = "Email address that receives SLO alerts. Leave empty to skip the subscription."
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN. Set it and the load balancer serves HTTPS and redirects port 80 to it."
  type        = string
  default     = ""
}
