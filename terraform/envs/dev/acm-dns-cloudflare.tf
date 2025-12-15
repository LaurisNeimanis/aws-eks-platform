# -----------------------------------------------------
# ACM DNS validation records (Cloudflare – automated)
# -----------------------------------------------------

resource "cloudflare_dns_record" "acm_validation" {
  for_each = {
    for k, v in {
      for dvo in aws_acm_certificate.this.domain_validation_options :
      "${trimsuffix(dvo.resource_record_name, ".")}|${dvo.resource_record_type}" => {
        name    = trimsuffix(dvo.resource_record_name, ".")
        type    = dvo.resource_record_type
        content = dvo.resource_record_value
      }...
    } : k => one(distinct(v))
  }

  zone_id = var.cloudflare_zone_id

  name    = each.value.name
  type    = each.value.type
  content = each.value.content

  ttl     = 300
  proxied = false
}
