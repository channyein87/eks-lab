variable "route53_domain_name" {
  description = "Route53 zone name for ACM and TLS."
  type        = string
}

variable "oauth_credentials" {
  description = "GitHub OAuth application credentials."
  type = object({
    organization  = string
    client_id     = string
    client_secret = string
  })
}