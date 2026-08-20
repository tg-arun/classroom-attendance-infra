provider "aws" {
  region = var.region

  # Every resource gets these tags, so we never repeat them per resource.
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
