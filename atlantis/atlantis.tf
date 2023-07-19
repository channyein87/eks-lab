resource "aws_iam_role" "atlantis" {
  name = "atlantis-role"

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
            "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:atlantis:atlantis-sa"
          }
        }
      },
    ]
  })

  inline_policy {
    name = "default"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action   = ["s3:*"]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
    })
  }
}

# resource "helm_release" "atlantis" {
#   name             = "atlantis"
#   namespace        = "atlantis"
#   create_namespace = true
#   chart            = "./helm/atlantis"
#   values           = [file("./helm/atlantis/values.yaml")]
#   atomic           = true
# }
