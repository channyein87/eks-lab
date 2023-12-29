terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.8"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20"
    }
  }
}

data "aws_route53_zone" "zone" {
  name = "${var.route53_domain_name}."
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "zones" {}
