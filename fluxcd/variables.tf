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

variable "github_owner" {
  description = "GitHub username."
  type        = string
}

variable "github_token" {
  description = "GitHub PAT."
  type        = string
  sensitive   = true
}

variable "flux_config" {
  description = "Git repository for Flux bootstrap."
  type = object({
    repository_full_name = string
    target_path          = string
  })
  default = {
    repository_full_name = "channyein87/eks-lab"
    target_path          = "fluxcd/eks-lab"
  }
}
