module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "eks-lab"
  cluster_version = "1.25"

  cluster_endpoint_public_access = true
  cluster_encryption_config      = {}
  create_kms_key                 = false
  manage_aws_auth_configmap      = true

  cluster_enabled_log_types              = ["api"]
  create_cloudwatch_log_group            = false
  cloudwatch_log_group_retention_in_days = 1

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = aws_iam_role.ebs_addon.arn
    }
  }

  vpc_id     = var.network.vpc_id
  subnet_ids = var.network.private_subnet_ids

  eks_managed_node_groups = {
    lab-cluster-small-ng = {
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      instance_types = ["t3a.small", "t3.small"]
      capacity_type  = "SPOT"

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      labels = {
        type     = "small"
        capacity = "spot"
      }
    }
  }

  node_security_group_additional_rules = {
    trust_cluster = {
      description                   = "Cluster API to node groups"
      protocol                      = "-1"
      from_port                     = "0"
      to_port                       = "0"
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::487523894433:user/cnnn.izzo"
      username = "cnnn.izzo"
      groups   = ["system:masters"]
    },
    {
      userarn  = "arn:aws:iam::487523894433:user/gitlab"
      username = "gitlab"
      groups   = ["system:masters"]
    },
  ]

  # Fargate Profile(s)
  fargate_profiles = {}
}
