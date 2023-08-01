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

resource "helm_release" "argocd" {
  name              = "argo-cd"
  namespace         = "argocd"
  chart             = "argo-cd"
  version           = "5.29.1"
  repository        = "https://argoproj.github.io/argo-helm"
  create_namespace  = true
  atomic            = true
  cleanup_on_fail   = true
  dependency_update = true

  values = [
    <<-EOT
      server:
        extraArgs:
        - --insecure
        ingress:
          enabled: true
          ingressClassName: nginx
          annotations:
            nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
            nginx.ingress.kubernetes.io/ssl-passthrough: "true"
          hosts: 
            - argocd.${var.route53_domain_name}
    EOT
  ]

  depends_on = [time_sleep.eks]
}

resource "time_sleep" "argocd" {
  create_duration = "30s"
  depends_on      = [helm_release.argocd]
}

resource "helm_release" "argo_apps" {
  name            = "apps"
  namespace       = "argocd"
  chart           = "${path.module}/app-of-apps"
  atomic          = true
  cleanup_on_fail = true

  values = [
    <<-EOT
      spec:
        source:
          repoURL: ${var.argocd_apps_repo}
    EOT
  ]

  depends_on = [time_sleep.argocd]
}
