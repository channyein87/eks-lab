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

variable "nodes_size" {
  description = "T shirt size for nodes."
  type        = string
  default     = "small"
}

variable "node_desired_count" {
  description = "Desired size of node group."
  type        = number
  default     = 2
}
