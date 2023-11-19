variable "oauth_credentials" {
  description = "GitHub OAuth application credentials."
  type = object({
    organization  = string
    client_id     = string
    client_secret = string
  })
}

variable "network" {
  description = "VPC and subnets."
  type = object({
    vpc_id             = string
    public_subnet_ids  = list(string)
    private_subnet_ids = list(string)
  })
}

variable "route53_domain_name" {
  description = "Route53 zone name for ACM and TLS."
  type        = string
}

variable "aws_auth_users" {
  description = "List of map users to cluster access."
  type        = list(map(any))
}
