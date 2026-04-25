# Terraform configuration block — locks AWS provider to version 6.x
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Default AWS provider — used for all resources except ACM
provider "aws" {
  region  = "eu-north-1"
  profile = "limonlab"
}

# ACM provider — CloudFront requires SSL certificates to be in us-east-1
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = "limonlab"
}