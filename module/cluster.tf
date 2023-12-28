module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = "eks-lab"
  cluster_version = "1.27"

  cluster_endpoint_public_access = true
  cluster_encryption_config      = {}
  create_kms_key                 = false
  manage_aws_auth_configmap      = true
  aws_auth_users                 = var.aws_auth_users

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
      configuration_values = var.nodes_size != "large" ? jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      }) : null
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = aws_iam_role.ebs_addon.arn
    }
  }

  vpc_id     = var.network.vpc_id
  subnet_ids = var.network.private_subnet_ids

  eks_managed_node_groups = {
    lab-cluster-ng = {
      min_size       = 2
      max_size       = 5
      desired_size   = 2
      instance_types = ["t3a.${var.nodes_size}", "t3.${var.nodes_size}"]
      capacity_type  = "SPOT"

      iam_role_additional_policies = {
        AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      }

      update_config = {
        max_unavailable = 2
      }

      labels = {
        type     = "${var.nodes_size}"
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

  # Fargate Profile(s)
  fargate_profiles = {}
}
