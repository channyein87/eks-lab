module "eks" {
  source = "../module"

  oauth_credentials   = var.oauth_credentials
  network             = var.network
  route53_domain_name = var.route53_domain_name
}

resource "time_sleep" "eks" {
  create_duration = "30s"
  depends_on      = [module.eks]
}

resource "helm_release" "linkerd_viz" {
  name              = "argo-cd"
  namespace         = "argocd"
  chart             = "argo-cd"
  chart_version     = "5.29.1"
  repository        = "https://argoproj.github.io/argo-helm"
  create_namespace  = true
  atomic            = true
  cleanup_on_fail   = true
  dependency_update = true

  values = [
    <<-EOT
      server:
        ingress:
          enabled: true
          annotations:      
            nginx.ingress.kubernetes.io/auth-signin: https://auth.${var.route53_domain_name}/oauth2/start?rd=https%3A%2F%2F$host$request_uri
            nginx.ingress.kubernetes.io/auth-url: https://auth.${var.route53_domain_name}/oauth2/auth
          hosts: 
            - argocd.${var.route53_domain_name}
    EOT
  ]

  depends_on = [time_sleep.eks]
}
