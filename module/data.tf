locals {
  host   = split(".", var.route53_domain_name)[0]
  domain = replace(var.route53_domain_name, "/^[^.]*\\./", "")

  name_servers = {
    ns1 = aws_route53_zone.zone.name_servers[0],
    ns2 = aws_route53_zone.zone.name_servers[1]
    ns3 = aws_route53_zone.zone.name_servers[2]
    ns4 = aws_route53_zone.zone.name_servers[3]
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "zones" {}

data "cloudflare_zone" "zone" {
  name = local.domain
}
