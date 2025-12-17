# -----------------------------------------------------
# ACM certificates (1 domain = 1 cert)
# -----------------------------------------------------
resource "aws_acm_certificate" "this" {
  domain_name               = var.primary_domain
  subject_alternative_names = var.san_domains
  validation_method         = "DNS"

  tags = var.tags
}

# -----------------------------------------------------
# Normalize ACM validation records
#
# Each certificate has exactly ONE validation record
# because each cert contains exactly ONE domain.
# -----------------------------------------------------
locals {
  acm_validation_record = tolist(aws_acm_certificate.this.domain_validation_options)[0]
}

# -----------------------------------------------------
# Cloudflare DNS validation records
# -----------------------------------------------------
resource "cloudflare_dns_record" "validation" {
  zone_id = var.cloudflare_zone_id

  name = trimsuffix(local.acm_validation_record.resource_record_name, ".")
  type = local.acm_validation_record.resource_record_type

  # IMPORTANT: normalize trailing dot to avoid perpetual diff
  content = trimsuffix(
    local.acm_validation_record.resource_record_value,
    "."
  )

  ttl     = 1
  proxied = false
}

# -----------------------------------------------------
# ACM certificate validation
# -----------------------------------------------------
resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn

  validation_record_fqdns = [
    cloudflare_dns_record.validation.name
  ]

  depends_on = [
    cloudflare_dns_record.validation
  ]
}
