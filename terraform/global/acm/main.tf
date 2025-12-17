terraform {
  required_version = "~> 1.14"

  backend "s3" {
    bucket         = "foundation-terraform-state-ltn"
    key            = "global/acm/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "foundation-terraform-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

locals {
  common_tags = merge(
    {
      Project   = "eks-platform"
      Scope     = "global-acm"
      ManagedBy = "Terraform"
    },
    var.tags
  )
}

module "acm" {
  source = "../../modules/acm-cloudflare"

  primary_domain     = var.primary_domain
  san_domains        = var.san_domains
  cloudflare_zone_id = var.cloudflare_zone_id
  tags               = local.common_tags
}
