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

resource "helm_release" "cert_issuer" {
  name            = "cert-issuer"
  namespace       = "vault"
  chart           = "${path.module}/helm/cert-issuer"
  atomic          = true
  cleanup_on_fail = true

  depends_on = [time_sleep.eks]
}

resource "time_sleep" "cert_issuer" {
  create_duration = "30s"
  depends_on      = [helm_release.cert_issuer]
}

resource "helm_release" "linkerd" {
  name              = "linkerd"
  namespace         = "linkerd"
  chart             = "${path.module}/helm/linkerd"
  atomic            = true
  cleanup_on_fail   = true
  dependency_update = true

  depends_on = [time_sleep.cert_issuer]
}

resource "time_sleep" "linkerd" {
  create_duration = "30s"
  depends_on      = [helm_release.linkerd]
}

resource "helm_release" "linkerd_viz" {
  name              = "linkerd-viz"
  namespace         = "linkerd-viz"
  chart             = "${path.module}/helm/linkerd-viz"
  create_namespace  = true
  atomic            = true
  cleanup_on_fail   = true
  dependency_update = true

  values = [
    <<-EOT
      ingress:
        host: linkerd.${var.route53_domain_name}
        annotations:
          nginx.ingress.kubernetes.io/upstream-vhost: $service_name.$namespace.svc.cluster.local:8084
          nginx.ingress.kubernetes.io/configuration-snippet: |
            proxy_set_header Origin "";
            proxy_hide_header l5d-remote-ip;
            proxy_hide_header l5d-server-id;      
          nginx.ingress.kubernetes.io/auth-signin: https://auth.${var.route53_domain_name}/oauth2/start?rd=https%3A%2F%2F$host$request_uri
          nginx.ingress.kubernetes.io/auth-url: https://auth.${var.route53_domain_name}/oauth2/auth
    EOT
  ]

  depends_on = [time_sleep.linkerd]
}
