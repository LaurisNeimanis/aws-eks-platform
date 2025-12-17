output "certificate_arn" {
  description = "Validated ACM certificate ARN"
  value       = aws_acm_certificate.this.arn
}

output "certificate_status" {
  value = aws_acm_certificate.this.status
}
