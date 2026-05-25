locals {
  name_parts = split("-", var.name)
  cloud      = try(local.name_parts[0], "aws")
  region     = try(local.name_parts[1], "use1")
  app        = try(local.name_parts[3], "net")
  env        = try(local.name_parts[4], "shared")

  public_tier = "plb"
  tgw_tier    = "tgw"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-igw-${local.app}-${local.env}-${local.public_tier}-001" })
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-snet-${local.app}-${local.env}-${local.public_tier}-${format("%03d", count.index + 1)}" })
}

resource "aws_subnet" "tgw" {
  count = length(var.tgw_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.tgw_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-snet-${local.app}-${local.env}-${local.tgw_tier}-${format("%03d", count.index + 1)}" })
}

resource "aws_eip" "nat" {
  count = length(var.public_subnet_cidrs)

  domain = "vpc"

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-eip-${local.app}-${local.env}-${local.public_tier}-${format("%03d", count.index + 1)}" })
}

resource "aws_nat_gateway" "this" {
  count = length(var.public_subnet_cidrs)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-natgw-${local.app}-${local.env}-${local.public_tier}-${format("%03d", count.index + 1)}" })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-rtb-${local.app}-${local.env}-${local.public_tier}-001" })
}

resource "aws_route" "public_default_to_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route" "public_to_workloads" {
  for_each = toset(var.workload_cidrs)

  route_table_id         = aws_route_table.public.id
  destination_cidr_block = each.value
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.this]
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "tgw" {
  count = length(aws_subnet.tgw)

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[min(count.index, length(aws_nat_gateway.this) - 1)].id
  }

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-rtb-${local.app}-${local.env}-${local.tgw_tier}-${format("%03d", count.index + 1)}" })
}

resource "aws_route_table_association" "tgw" {
  count = length(aws_subnet.tgw)

  subnet_id      = aws_subnet.tgw[count.index].id
  route_table_id = aws_route_table.tgw[count.index].id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  subnet_ids         = aws_subnet.tgw[*].id
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.this.id

  appliance_mode_support                          = "disable"
  dns_support                                     = "enable"
  ipv6_support                                    = "disable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-tgwatt-${local.app}-${local.env}-${local.tgw_tier}-001" })

  lifecycle {
    ignore_changes = [
      transit_gateway_default_route_table_association,
      transit_gateway_default_route_table_propagation
    ]
  }
}
