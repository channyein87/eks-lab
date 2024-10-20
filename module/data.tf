locals {
  host   = split(".", route53_domain_name)[0]
  domain = replace(route53_domain_name, "/^[^.]*\\./", "")
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "zones" {}

data "cloudflare_zone" "zone" {
  name = local.domain
}
