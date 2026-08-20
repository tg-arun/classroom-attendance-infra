terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # State lives in S3. The bucket name is account specific, so it is passed at
  # init time instead of being committed:
  #
  #   terraform init -backend-config=backend.hcl
  #
  # use_lockfile puts the lock next to the state object in S3. The old
  # DynamoDB lock table is no longer needed.
  backend "s3" {
    key          = "attendance/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}
