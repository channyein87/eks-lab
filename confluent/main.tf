module "eks" {
  source = "../module"

  oauth_credentials   = var.oauth_credentials
  network             = var.network
  route53_domain_name = var.route53_domain_name
  aws_auth_users      = var.aws_auth_users
  nodes_size          = "large"
  node_desired_count  = 3
}

resource "helm_release" "operator" {
  name             = "operator"
  namespace        = "confluent"
  chart            = "confluent-for-kubernetes"
  repository       = "https://packages.confluent.io/helm"
  create_namespace = true
  atomic           = true
  cleanup_on_fail  = true

  depends_on = [module.eks]
}

resource "time_sleep" "operator" {
  create_duration  = "5s"
  destroy_duration = "30s"
  depends_on       = [helm_release.operator]
}

resource "helm_release" "platform" {
  name            = "platform"
  namespace       = "confluent"
  chart           = "${path.module}/helm/confluent-platform"
  atomic          = true
  cleanup_on_fail = true

  values = [
    <<-EOT
      domain: ${var.route53_domain_name}
    EOT
  ]

  depends_on = [time_sleep.operator]
}
