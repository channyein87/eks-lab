resource "aws_eks_access_entry" "admin" {
  count = var.additional_cluster_admin_arn != null ? 1 : 0

  cluster_name  = module.eks.cluster_name
  principal_arn = var.additional_cluster_admin_arn
  region        = data.aws_region.current.region
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  count = var.additional_cluster_admin_arn != null ? 1 : 0

  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.additional_cluster_admin_arn
  region        = data.aws_region.current.region

  access_scope {
    type = "cluster"
  }
}
