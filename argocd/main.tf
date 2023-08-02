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
      config:
        secret:
          argocdServerAdminPassword: ${bcrypt(var.argocd_admin_password)}
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
  create_duration  = "30s"
  destroy_duration = "60s"
  depends_on       = [helm_release.argocd]

  triggers = {
    "argocd_server"  = "argocd.${var.route53_domain_name}:443"
    "admin_password" = var.argocd_admin_password
  }
}

resource "argocd_application" "apps" {
  metadata {
    name      = "apps"
    namespace = "argocd"
  }

  spec {
    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "default"
    }

    source {
      repo_url        = var.argocd_apps_repo
      target_revision = "HEAD"
      ref             = "main"
      path            = "argocd/app-of-apps"

      helm {
        parameter {
          name  = "spec.source.repoURL"
          value = var.argocd_apps_repo
        }
      }
    }

    sync_policy {
      automated {
        self_heal = true
        prune     = true
      }
    }
  }

  depends_on = [time_sleep.argocd]
}
