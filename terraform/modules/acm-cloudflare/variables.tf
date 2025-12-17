variable "primary_domain" {
  type = string
}

variable "san_domains" {
  type    = list(string)
  default = []
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID where validation records will be created."
  type        = string
}

variable "tags" {
  description = "Tags applied to ACM certificates."
  type        = map(string)
  default     = {}
}
