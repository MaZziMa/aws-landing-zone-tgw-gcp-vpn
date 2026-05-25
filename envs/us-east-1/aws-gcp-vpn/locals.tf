locals {
  aws_cloud_code  = "aws"
  gcp_cloud_code  = "gcp"
  aws_region_code = "use1"
  gcp_region_code = "usc1"
  app_code        = "net"
  env_code        = "shared"
  zone_code       = "prv"

  tags = {
    ManagedBy = "Terraform"
    Project   = "LandingZone"
    Component = "GcpAwsHaVpn"
  }

  aws_transit_gateway_id       = coalesce(var.aws_transit_gateway_id, data.terraform_remote_state.network.outputs.transit_gateway_id)
  associate_tgw_route_table_id = coalesce(var.associate_tgw_route_table_id, data.terraform_remote_state.network.outputs.vpn_route_table_id)
  propagate_tgw_route_table_ids = var.propagate_tgw_route_table_ids != null ? var.propagate_tgw_route_table_ids : toset([
    data.terraform_remote_state.network.outputs.nonprod_route_table_id,
    data.terraform_remote_state.network.outputs.prod_route_table_id
  ])

  names = {
    gcp_ha_vpn_gateway     = "${local.gcp_cloud_code}-${local.gcp_region_code}-havpn-${local.app_code}-${local.env_code}-${local.zone_code}-001"
    gcp_router             = "${local.gcp_cloud_code}-${local.gcp_region_code}-cr-${local.app_code}-${local.env_code}-${local.zone_code}-001"
    gcp_external_vpn_gw    = "${local.gcp_cloud_code}-${local.gcp_region_code}-extvpngw-${local.app_code}-${local.env_code}-${local.zone_code}-001"
    gcp_firewall_allow_aws = "${local.gcp_cloud_code}-${local.gcp_region_code}-fw-${local.app_code}-${local.env_code}-${local.zone_code}-001"
    aws_customer_gw_if0    = "${local.aws_cloud_code}-${local.aws_region_code}-cgw-${local.app_code}-${local.env_code}-${local.zone_code}-001"
    aws_customer_gw_if1    = "${local.aws_cloud_code}-${local.aws_region_code}-cgw-${local.app_code}-${local.env_code}-${local.zone_code}-002"
    aws_vpn_if0            = "${local.aws_cloud_code}-${local.aws_region_code}-vpn-${local.app_code}-${local.env_code}-${local.zone_code}-001"
    aws_vpn_if1            = "${local.aws_cloud_code}-${local.aws_region_code}-vpn-${local.app_code}-${local.env_code}-${local.zone_code}-002"
  }

  tunnels = {
    if0_tunnel1 = {
      name                  = "${local.gcp_cloud_code}-${local.gcp_region_code}-vpntun-${local.app_code}-${local.env_code}-${local.zone_code}-001"
      router_interface_name = "${local.gcp_cloud_code}-${local.gcp_region_code}-crif-${local.app_code}-${local.env_code}-${local.zone_code}-001"
      bgp_peer_name         = "${local.gcp_cloud_code}-${local.gcp_region_code}-bgp-${local.app_code}-${local.env_code}-${local.zone_code}-001"
      gcp_interface         = 0
      peer_interface        = 0
      aws_vpn_key           = "if0"
      aws_tunnel_number     = 1
      psk                   = var.tunnel_psks.if0_tunnel1
      advertised_priority   = 100
    }
    if0_tunnel2 = {
      name                  = "${local.gcp_cloud_code}-${local.gcp_region_code}-vpntun-${local.app_code}-${local.env_code}-${local.zone_code}-002"
      router_interface_name = "${local.gcp_cloud_code}-${local.gcp_region_code}-crif-${local.app_code}-${local.env_code}-${local.zone_code}-002"
      bgp_peer_name         = "${local.gcp_cloud_code}-${local.gcp_region_code}-bgp-${local.app_code}-${local.env_code}-${local.zone_code}-002"
      gcp_interface         = 0
      peer_interface        = 1
      aws_vpn_key           = "if0"
      aws_tunnel_number     = 2
      psk                   = var.tunnel_psks.if0_tunnel2
      advertised_priority   = 100
    }
    if1_tunnel1 = {
      name                  = "${local.gcp_cloud_code}-${local.gcp_region_code}-vpntun-${local.app_code}-${local.env_code}-${local.zone_code}-003"
      router_interface_name = "${local.gcp_cloud_code}-${local.gcp_region_code}-crif-${local.app_code}-${local.env_code}-${local.zone_code}-003"
      bgp_peer_name         = "${local.gcp_cloud_code}-${local.gcp_region_code}-bgp-${local.app_code}-${local.env_code}-${local.zone_code}-003"
      gcp_interface         = 1
      peer_interface        = 2
      aws_vpn_key           = "if1"
      aws_tunnel_number     = 1
      psk                   = var.tunnel_psks.if1_tunnel1
      advertised_priority   = 100
    }
    if1_tunnel2 = {
      name                  = "${local.gcp_cloud_code}-${local.gcp_region_code}-vpntun-${local.app_code}-${local.env_code}-${local.zone_code}-004"
      router_interface_name = "${local.gcp_cloud_code}-${local.gcp_region_code}-crif-${local.app_code}-${local.env_code}-${local.zone_code}-004"
      bgp_peer_name         = "${local.gcp_cloud_code}-${local.gcp_region_code}-bgp-${local.app_code}-${local.env_code}-${local.zone_code}-004"
      gcp_interface         = 1
      peer_interface        = 3
      aws_vpn_key           = "if1"
      aws_tunnel_number     = 2
      psk                   = var.tunnel_psks.if1_tunnel2
      advertised_priority   = 100
    }
  }
}
