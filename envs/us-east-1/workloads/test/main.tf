locals {
  tags = {
    ManagedBy   = "Terraform"
    Project     = "LandingZone"
    Environment = "test"
  }
}

module "vpc" {
  source = "../../../../modules/network/workload-vpc"

  name               = "test-workload"
  vpc_cidr           = var.vpc_cidr
  azs                = var.azs
  web_subnet_cidrs   = ["10.20.0.0/24", "10.20.1.0/24"]
  app_subnet_cidrs   = ["10.20.10.0/24", "10.20.11.0/24"]
  data_subnet_cidrs  = ["10.20.20.0/24", "10.20.21.0/24"]
  tgw_subnet_cidrs   = ["10.20.30.0/28", "10.20.30.16/28"]
  transit_gateway_id = var.transit_gateway_id
  tags               = local.tags
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  provider = aws.network

  transit_gateway_attachment_id  = module.vpc.attachment_id
  transit_gateway_route_table_id = var.nonprod_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "to_egress" {
  provider = aws.network

  transit_gateway_attachment_id  = module.vpc.attachment_id
  transit_gateway_route_table_id = var.egress_route_table_id
}
