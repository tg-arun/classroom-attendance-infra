terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state is intentionally left as a comment: the backend bucket and the
  # DynamoDB lock table live outside this stack (they have a different lifecycle).
  # In a real account this would be uncommented and pointed at that bucket.
  #
  # backend "s3" {
  #   bucket         = "classroom-attendance-tfstate"
  #   key            = "attendance/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "classroom-attendance-tflock"
  #   encrypt        = true
  # }
}
