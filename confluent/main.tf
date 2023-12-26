module "eks" {
  source = "../module"

  oauth_credentials   = var.oauth_credentials
  network             = var.network
  route53_domain_name = var.route53_domain_name
  aws_auth_users      = var.aws_auth_users
}

resource "time_sleep" "eks" {
  create_duration = "30s"
  depends_on      = [module.eks]
}
