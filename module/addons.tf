resource "time_sleep" "eks_cluster" {
  destroy_duration = "30s"
  depends_on       = [module.eks]
}

module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_aws_load_balancer_controller = true
  enable_cluster_autoscaler           = true
  enable_metrics_server               = true
  enable_external_dns                 = true
  enable_cert_manager                 = true
  external_dns_route53_zone_arns      = [data.aws_route53_zone.zone.arn]

  external_dns = {
    repository    = "https://charts.bitnami.com/bitnami"
    chart_version = "6.20.4"
    values = [
      <<-EOT
        aws:
          region: ap-southeast-2
          zoneType: public
        labelFilter: "ingress in (externaldns)"
        namespace: ingress-nginx
        policy: sync
        forceTxtOwnerId: true
        sources:
          - ingress
        txtOwnerId: lab-cluster
      EOT
    ]
  }

  cluster_autoscaler = {
    values = [
      <<-EOT
        extraArgs:
          scale-down-enabled: true
          scale-down-utilization-threshold: 0.8
          scale-down-delay-after-add: 1m
          skip-nodes-with-system-pods: false
      EOT
    ]
  }

  depends_on = [time_sleep.eks_cluster]
}

resource "aws_iam_role" "ebs_addon" {
  name = "ebs-addon-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
            "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
          }
        }
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "ebs_addon" {
  name       = "ebs-addon-attachment"
  roles      = [aws_iam_role.ebs_addon.id]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "time_sleep" "eks_blueprints_addons" {
  create_duration  = "30s"
  destroy_duration = "30s" # buffer to delete ingress alb
  depends_on       = [module.eks_blueprints_addons]
}

resource "helm_release" "trust_manager" {
  name            = "trust-manager"
  namespace       = "cert-manager"
  chart           = "trust-manager"
  repository      = "https://charts.jetstack.io"
  atomic          = true
  cleanup_on_fail = true

  depends_on = [time_sleep.eks_blueprints_addons]
}

resource "helm_release" "ingress_nginx" {
  name              = "ingress-nginx"
  namespace         = "ingress-nginx"
  chart             = "${path.module}/helm/ingress-nginx"
  atomic            = true
  cleanup_on_fail   = true
  dependency_update = true

  values = [
    <<-EOT
      nginx:
        ingress:
          certARN: "${aws_acm_certificate.acm_cert.arn}"
          host: "${aws_acm_certificate.acm_cert.domain_name}"

      oauth2-proxy:
        config:
          existingSecret: oauth2-proxy-creds
          configFile: |
            github_org = "${var.oauth_credentials.organization}"
            scope = "user:email read:org"
            email_domains = [ "*" ]
            provider = "github"
            cookie_secure = false
            cookie_domains = [ ".${var.route53_domain_name}" ]
            whitelist_domains = [ ".${var.route53_domain_name}" ]
            redirect_url = "https://auth.${var.route53_domain_name}/oauth2/callback"

        ingress:
          enabled: true
          path: /
          hosts:
            - auth.${var.route53_domain_name}
          className: nginx
          tls:
            - hosts:
                - auth.${var.route53_domain_name}
    EOT
  ]

  depends_on = [kubernetes_namespace_v1.ingress_nginx]
}

resource "time_sleep" "ingress_nginx" {
  create_duration = "30s"
  depends_on      = [helm_release.ingress_nginx]
}

resource "aws_kms_key" "vault_kms" {
  description             = "EKS lab Vault KMS key"
  deletion_window_in_days = 7
}

resource "aws_dynamodb_table" "vault_dynamo" {
  name         = "eks-lab-vault-table"
  hash_key     = "Path"
  range_key    = "Key"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "Path"
    type = "S"
  }

  attribute {
    name = "Key"
    type = "S"
  }
}

module "vault" {
  source = "aws-ia/eks-blueprints-addon/aws"

  create_release       = true
  name                 = "vault"
  namespace            = "vault"
  create_namespace     = true
  chart                = "${path.module}/helm/vault"
  atomic               = true
  cleanup_on_fail      = true
  dependency_update    = true
  set_irsa_names       = ["vault.server.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"]
  create_role          = true
  role_name            = "vault-sa"
  role_name_use_prefix = true
  role_description     = "IRSA for vault-sa"
  role_policies        = { PowerUserAccess = "arn:aws:iam::aws:policy/PowerUserAccess" }
  create_policy        = false

  oidc_providers = {
    this = {
      provider_arn    = module.eks.oidc_provider_arn
      service_account = "vault-sa"
    }
  }

  values = [
    <<-EOT
      vault:
        server:
          ingress:
            enabled: true
            ingressClassName: "nginx"
            annotations:
              nginx.ingress.kubernetes.io/auth-signin: https://auth.${var.route53_domain_name}/oauth2/start?rd=https%3A%2F%2F$host$request_uri
              nginx.ingress.kubernetes.io/auth-url: https://auth.${var.route53_domain_name}/oauth2/auth
            hosts:
              - host: vault.${var.route53_domain_name}
          ha:
            enabled: true
            replicas: 2
            config: |
              ui = true

              listener "tcp" {
                tls_disable = 1
                address = "[::]:8200"
                cluster_address = "[::]:8201"
              }

              storage "dynamodb" {
                ha_enabled = "true"
                region     = "${data.aws_region.current.id}"
                table      = "${aws_dynamodb_table.vault_dynamo.id}"
              }

              service_registration "kubernetes" {}

              seal "awskms" {
                region     = "ap-southeast-2"
                kms_key_id = "${aws_kms_key.vault_kms.id}"
              }
    EOT
  ]

  depends_on = [time_sleep.ingress_nginx]
}
