terraform {
  required_version = "~> 1.14"

  # Enforces consistent provider versions across environments
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# AWS provider configured per-environment via variables
provider "aws" {
  region = var.aws_region
}
