variable "project" {
  description = "Name prefix, matched to the root stack."
  type        = string
  default     = "classroom-attendance"
}

variable "region" {
  description = "Region for the state bucket. Keep it the same as the stack it serves."
  type        = string
  default     = "us-east-1"
}
