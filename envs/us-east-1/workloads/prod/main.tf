locals {
  tags = {
    ManagedBy   = "Terraform"
    Project     = "LandingZone"
    Environment = "prod"
  }

  transit_gateway_id    = coalesce(var.transit_gateway_id, data.terraform_remote_state.network.outputs.transit_gateway_id)
  prod_route_table_id   = coalesce(var.prod_route_table_id, data.terraform_remote_state.network.outputs.prod_route_table_id)
  egress_route_table_id = coalesce(var.egress_route_table_id, data.terraform_remote_state.network.outputs.egress_route_table_id)
  vpn_route_table_id    = coalesce(var.vpn_route_table_id, try(data.terraform_remote_state.network.outputs.vpn_route_table_id, ""))
}

data "terraform_remote_state" "network" {
  backend = "local"

  config = {
    path = "${path.module}/../../network/terraform.tfstate"
  }
}

module "vpc" {
  source = "../../../../modules/network/workload-vpc"

  name               = "prod-workload"
  vpc_cidr           = var.vpc_cidr
  azs                = var.azs
  web_subnet_cidrs   = ["10.30.0.0/24", "10.30.1.0/24"]
  app_subnet_cidrs   = ["10.30.10.0/24", "10.30.11.0/24"]
  data_subnet_cidrs  = ["10.30.20.0/24", "10.30.21.0/24"]
  tgw_subnet_cidrs   = ["10.30.30.0/28", "10.30.30.16/28"]
  transit_gateway_id = local.transit_gateway_id
  tags               = local.tags
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  provider = aws.network

  transit_gateway_attachment_id  = module.vpc.attachment_id
  transit_gateway_route_table_id = local.prod_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "to_egress" {
  provider = aws.network

  transit_gateway_attachment_id  = module.vpc.attachment_id
  transit_gateway_route_table_id = local.egress_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "to_vpn" {
  count    = local.vpn_route_table_id != "" ? 1 : 0
  provider = aws.network

  transit_gateway_attachment_id  = module.vpc.attachment_id
  transit_gateway_route_table_id = local.vpn_route_table_id
}
