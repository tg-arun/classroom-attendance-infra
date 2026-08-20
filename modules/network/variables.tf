variable "project" {
  description = "Name prefix used for every resource."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "az_count" {
  description = "How many Availability Zones to spread across."
  type        = number

  validation {
    condition     = var.az_count >= 2
    error_message = "At least 2 AZs are required to survive the loss of one AZ."
  }
}
