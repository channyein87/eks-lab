module "eks" {
  source = "../module"

  oauth_credentials   = var.oauth_credentials
  network             = var.network
  route53_domain_name = var.route53_domain_name
  aws_auth_users      = var.aws_auth_users
  nodes_size          = "large"
}

resource "time_sleep" "eks" {
  create_duration = "30s"
  depends_on      = [module.eks]
}

resource "helm_release" "cfk" {
  name              = "cfk"
  namespace         = "confluent"
  chart             = "${path.module}/helm/cfk"
  create_namespace  = true
  atomic            = true
  cleanup_on_fail   = true
  dependency_update = true

  values = [
    <<-EOT
      domain: ${var.route53_domain_name}
    EOT
  ]

  depends_on = [time_sleep.eks]
}
