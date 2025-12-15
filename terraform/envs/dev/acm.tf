# -----------------------------------------------------
# ACM certificate (manual DNS validation via Cloudflare)
# -----------------------------------------------------

variable "acm_domain_name" {
  description = "Primary domain name for ACM certificate"
  type        = string
}

variable "acm_subject_alternative_names" {
  description = "Optional SANs for the ACM certificate"
  type        = list(string)
  default     = []
}

resource "aws_acm_certificate" "this" {
  domain_name               = var.acm_domain_name
  subject_alternative_names = var.acm_subject_alternative_names
  validation_method         = "DNS"

  tags = local.common_tags
}
