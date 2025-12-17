variable "aws_region" {
  type        = string
  description = "AWS region for ACM"
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_zone_id" {
  type = string
}

variable "primary_domain" {
  type = string
}

variable "san_domains" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
