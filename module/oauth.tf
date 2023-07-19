variable "oauth_credentials" {
  description = "GitHub OAuth application credentials."
  type = object({
    organization  = string
    client_id     = string
    client_secret = string
  })
}

resource "random_password" "cookie_secret" {
  length           = 32
  override_special = "-_"
}

resource "kubernetes_namespace_v1" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }

  depends_on = [time_sleep.eks_blueprints_addons]
}

resource "kubernetes_secret_v1" "github_oauth_app" {
  metadata {
    name      = "oauth2-proxy-creds"
    namespace = kubernetes_namespace_v1.ingress_nginx.metadata[0].name
  }

  data = {
    "client-id"     = var.oauth_credentials.client_id
    "client-secret" = var.oauth_credentials.client_secret
    "cookie-secret" = random_password.cookie_secret.result
  }
}
