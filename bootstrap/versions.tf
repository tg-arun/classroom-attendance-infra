terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # This stack keeps local state on purpose. It is the bucket that holds
  # everyone else's state, so it cannot store its own state there. It is also
  # three resources that are trivial to recreate or import if the local file is
  # ever lost.
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
      Purpose   = "terraform-state"
    }
  }
}
