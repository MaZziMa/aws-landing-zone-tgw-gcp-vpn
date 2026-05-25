locals {
  name_parts = split("-", var.name)
  cloud      = try(local.name_parts[0], "aws")
  region     = try(local.name_parts[1], "use1")
  app        = try(local.name_parts[3], "net")
  env        = try(local.name_parts[4], "shared")
}

resource "aws_ec2_transit_gateway" "this" {
  description                     = var.name
  amazon_side_asn                 = 64512
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_ec2_transit_gateway_route_table" "egress" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-tgwrt-${local.app}-${local.env}-egress-001" })
}

resource "aws_ec2_transit_gateway_route_table" "prod" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-tgwrt-${local.app}-${local.env}-prod-001" })
}

resource "aws_ec2_transit_gateway_route_table" "nonprod" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-tgwrt-${local.app}-${local.env}-nonprod-001" })
}

resource "aws_ec2_transit_gateway_route_table" "vpn" {
  transit_gateway_id = aws_ec2_transit_gateway.this.id

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-tgwrt-${local.app}-${local.env}-vpn-001" })
}

resource "aws_ram_resource_share" "this" {
  name                      = "${local.cloud}-${local.region}-ram-${local.app}-${local.env}-prv-001"
  allow_external_principals = false

  tags = var.tags
}

resource "aws_ram_resource_association" "this" {
  resource_arn       = aws_ec2_transit_gateway.this.arn
  resource_share_arn = aws_ram_resource_share.this.arn
}

resource "aws_ram_principal_association" "accounts" {
  for_each = toset(var.ram_principal_account_ids)

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.this.arn
}
