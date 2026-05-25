locals {
  name_parts = split("-", var.name)
  cloud      = try(local.name_parts[0], "aws")
  region     = try(local.name_parts[1], "use1")
  app        = try(local.name_parts[3], "workload")
  env        = try(local.name_parts[4], "dev")

  web_tier  = "plb"
  app_tier  = "app"
  data_tier = "dbz"
  tgw_tier  = "tgw"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_internet_gateway" "this" {
  count = var.create_internet_gateway && length(var.web_subnet_cidrs) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-igw-${local.app}-${local.env}-${local.web_tier}-001" })
}

resource "aws_subnet" "web" {
  count = length(var.web_subnet_cidrs)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.web_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-snet-${local.app}-${local.env}-${local.web_tier}-${format("%03d", count.index + 1)}", Tier = "web" })
}

resource "aws_subnet" "app" {
  count = length(var.app_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.app_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-snet-${local.app}-${local.env}-${local.app_tier}-${format("%03d", count.index + 1)}", Tier = "app" })
}

resource "aws_subnet" "data" {
  count = length(var.data_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.data_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-snet-${local.app}-${local.env}-${local.data_tier}-${format("%03d", count.index + 1)}", Tier = "data" })
}

resource "aws_subnet" "tgw" {
  count = length(var.tgw_subnet_cidrs)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.tgw_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-snet-${local.app}-${local.env}-${local.tgw_tier}-${format("%03d", count.index + 1)}", Tier = "tgw" })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  subnet_ids         = aws_subnet.tgw[*].id
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.this.id

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

resource "aws_route_table" "web" {
  count = length(aws_subnet.web) > 0 ? 1 : 0

  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-rtb-${local.app}-${local.env}-${local.web_tier}-001" })
}

resource "aws_route_table_association" "web" {
  count = length(aws_subnet.web)

  subnet_id      = aws_subnet.web[count.index].id
  route_table_id = aws_route_table.web[0].id
}

resource "aws_route_table" "app" {
  count = length(aws_subnet.app)

  vpc_id = aws_vpc.this.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = var.transit_gateway_id
  }

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-rtb-${local.app}-${local.env}-${local.app_tier}-${format("%03d", count.index + 1)}" })

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.this]
}

resource "aws_route_table_association" "app" {
  count = length(aws_subnet.app)

  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[count.index].id
}

resource "aws_route_table" "data" {
  count = length(aws_subnet.data)

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${local.cloud}-${local.region}-rtb-${local.app}-${local.env}-${local.data_tier}-${format("%03d", count.index + 1)}" })
}

resource "aws_route_table_association" "data" {
  count = length(aws_subnet.data)

  subnet_id      = aws_subnet.data[count.index].id
  route_table_id = aws_route_table.data[count.index].id
}
