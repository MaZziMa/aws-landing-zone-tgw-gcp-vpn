locals {
  cloud_code  = "aws"
  region_code = "use1"
  app_code    = "workload"
  env_code    = "prod"
  vpc_name    = "${local.cloud_code}-${local.region_code}-vpc-${local.app_code}-${local.env_code}-prv-001"

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

  name               = local.vpc_name
  vpc_cidr           = var.vpc_cidr
  azs                = var.azs
  web_subnet_cidrs   = var.web_subnet_cidrs
  app_subnet_cidrs   = var.app_subnet_cidrs
  data_subnet_cidrs  = var.data_subnet_cidrs
  tgw_subnet_cidrs   = var.tgw_subnet_cidrs
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
