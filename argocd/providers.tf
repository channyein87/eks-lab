terraform {
  backend "s3" {}
}

terraform {
  required_providers {
    argocd = {
      source  = "oboukili/argocd"
      version = ">= 6.0.1"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

provider "argocd" {
  server_addr = time_sleep.argocd.triggers["argocd_server"]
  username    = "admin"
  password    = time_sleep.argocd.triggers["admin_password"]
}
