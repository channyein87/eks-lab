data "github_repository" "repo" {
  full_name = var.flux_config.repository_full_name
}

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

resource "tls_private_key" "this" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "this" {
  title      = "staging-cluster"
  repository = data.github_repository.repo.name
  key        = tls_private_key.this.public_key_openssh
  read_only  = false
}

resource "flux_bootstrap_git" "this" {
  path       = var.flux_config.target_path
  depends_on = [github_repository_deploy_key.this]
}

resource "helm_release" "flux_ui" {
  name            = "ww-gitops"
  namespace       = "flux-system"
  chart           = "weave-gitops"
  repository      = "oci://ghcr.io/weaveworks/charts"
  version         = "4.0.25"
  atomic          = true
  cleanup_on_fail = true

  values = [
    <<-EOT
      adminUser:
        create: true
        passwordHash: ${bcrypt("admin")}
        username: admin
      ingress:
        enabled: true
        className: "nginx"
        annotations: {}
        hosts:
          - host: gitops.${var.route53_domain_name}
            paths:
              - path: /
                pathType: ImplementationSpecific
    EOT
  ]

  depends_on = [
    time_sleep.eks,
    flux_bootstrap_git.this
  ]
}
