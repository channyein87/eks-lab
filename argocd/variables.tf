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

variable "argocd_admin_password" {
  description = "ArgoCD user admin password."
  type        = string
  default     = "admin"
}

variable "argocd_apps_repo" {
  description = "ArgoCD App of Apps repo."
  type        = string
  default     = "https://github.com/channyein87/eks-lab"
}
