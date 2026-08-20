terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State goes to S3 so it is not sitting on one laptop, and so two people
  # cannot apply at the same time. The bucket was created separately.
  backend "s3" {
    bucket       = "classroom-attendance-infra-tfstate"
    key          = "attendance/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      ManagedBy = "terraform"
    }
  }
}
