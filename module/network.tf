variable "network" {
  description = "VPC and subnets."
  type = object({
    vpc_id             = string
    public_subnet_ids  = list(string)
    private_subnet_ids = list(string)
  })
}

resource "aws_ec2_tag" "public_subnet" {
  for_each = toset(var.network.public_subnet_ids)

  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = ""
}

resource "aws_ec2_tag" "private_subnets" {
  for_each = toset(var.network.private_subnet_ids)

  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = ""
}

resource "aws_ec2_tag" "vpc" {
  resource_id = var.network.vpc_id
  key         = "kubernetes.io/cluster/lab-cluster"
  value       = "shared"
}

resource "aws_route53_zone" "zone" {
  name = var.route53_domain_name
}

resource "cloudflare_record" "name_servers" {
  for_each = local.name_servers

  zone_id = data.cloudflare_zone.zone.id
  name    = local.host
  content = each.value
  type    = "NS"
}
