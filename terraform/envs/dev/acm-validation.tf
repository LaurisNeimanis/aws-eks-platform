# -----------------------------------------------------
# ACM DNS validation (Cloudflare automated)
# -----------------------------------------------------

resource "aws_acm_certificate_validation" "this" {
  certificate_arn = aws_acm_certificate.this.arn

  validation_record_fqdns = [
    for r in cloudflare_dns_record.acm_validation :
    r.name
  ]
}
