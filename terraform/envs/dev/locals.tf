locals {
  resource_prefix = "${var.name}-${var.environment}"

  cluster_name = "${local.resource_prefix}-cluster"

  common_tags = merge(
    {
      Project     = var.name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Lauris Neimanis"
    },
    var.tags
  )
}