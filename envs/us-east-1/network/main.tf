locals {
  cloud_code  = "aws"
  region_code = "use1"
  app_code    = "net"
  env_code    = "shared"

  tgw_name        = "${local.cloud_code}-${local.region_code}-tgw-${local.app_code}-${local.env_code}-prv-001"
  egress_vpc_name = "${local.cloud_code}-${local.region_code}-vpc-${local.app_code}-${local.env_code}-plb-001"

  tags = {
    ManagedBy = "Terraform"
    Project   = "LandingZone"
    Account   = "Network"
  }

  workload_cidrs = [
    var.shared_services_vpc_cidr,
    var.dev_vpc_cidr,
    var.prod_vpc_cidr
  ]

  optional_workload_cidrs = var.test_account_id != "" && var.test_account_id != var.dev_account_id ? [
    var.test_vpc_cidr
  ] : []

  return_route_cidrs = concat(local.workload_cidrs, local.optional_workload_cidrs)

  ram_principal_account_ids = distinct(compact([
    var.shared_services_account_id,
    var.dev_account_id,
    var.test_account_id,
    var.prod_account_id
  ]))
}

module "transit_gateway" {
  source = "../../../modules/network/transit-gateway"

  name = local.tgw_name

  ram_principal_account_ids = local.ram_principal_account_ids

  tags = local.tags
}

module "egress_vpc" {
  source = "../../../modules/network/egress-vpc"

  name                = local.egress_vpc_name
  vpc_cidr            = var.network_vpc_cidr
  azs                 = var.azs
  public_subnet_cidrs = var.egress_public_subnet_cidrs
  tgw_subnet_cidrs    = var.egress_tgw_subnet_cidrs
  transit_gateway_id  = module.transit_gateway.transit_gateway_id
  workload_cidrs      = local.return_route_cidrs
  tags                = local.tags
}

resource "aws_ec2_transit_gateway_route_table_association" "egress" {
  transit_gateway_attachment_id  = module.egress_vpc.attachment_id
  transit_gateway_route_table_id = module.transit_gateway.egress_route_table_id
}

resource "aws_ec2_transit_gateway_route" "prod_default_to_egress" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.egress_vpc.attachment_id
  transit_gateway_route_table_id = module.transit_gateway.prod_route_table_id
}

resource "aws_ec2_transit_gateway_route" "nonprod_default_to_egress" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = module.egress_vpc.attachment_id
  transit_gateway_route_table_id = module.transit_gateway.nonprod_route_table_id
}
