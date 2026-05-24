locals {
  name = var.name_prefix

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

  tunnels = {
    if0_tunnel1 = {
      name                  = "int0-cus2"
      router_interface_name = "if-bgp-vpn-aws-0"
      bgp_peer_name         = "bgp-vpn-aws-0"
      gcp_interface         = 0
      peer_interface        = 0
      aws_vpn_key           = "if0"
      aws_tunnel_number     = 1
      psk                   = var.tunnel_psks.if0_tunnel1
      advertised_priority   = 100
    }
    if0_tunnel2 = {
      name                  = "int1-cus2"
      router_interface_name = "if-bgp-vpn-aws-1"
      bgp_peer_name         = "bgp-vpn-aws-1"
      gcp_interface         = 0
      peer_interface        = 1
      aws_vpn_key           = "if0"
      aws_tunnel_number     = 2
      psk                   = var.tunnel_psks.if0_tunnel2
      advertised_priority   = 100
    }
    if1_tunnel1 = {
      name                  = "int2-cus4"
      router_interface_name = "if-bgp-vpn-aws-2"
      bgp_peer_name         = "bgp-vpn-aws-2"
      gcp_interface         = 1
      peer_interface        = 2
      aws_vpn_key           = "if1"
      aws_tunnel_number     = 1
      psk                   = var.tunnel_psks.if1_tunnel1
      advertised_priority   = 100
    }
    if1_tunnel2 = {
      name                  = "int3-cus4"
      router_interface_name = "if-bgp-vpn-aws-3"
      bgp_peer_name         = "bgp-vpn-aws-3"
      gcp_interface         = 1
      peer_interface        = 3
      aws_vpn_key           = "if1"
      aws_tunnel_number     = 2
      psk                   = var.tunnel_psks.if1_tunnel2
      advertised_priority   = 100
    }
  }
}

resource "google_compute_ha_vpn_gateway" "this" {
  name    = local.name
  network = var.gcp_network
  region  = var.gcp_region
  labels  = var.labels
}

resource "google_compute_router" "this" {
  name    = "${local.name}-router"
  network = var.gcp_network
  region  = var.gcp_region

  bgp {
    asn            = var.gcp_bgp_asn
    advertise_mode = "CUSTOM"

    dynamic "advertised_ip_ranges" {
      for_each = toset(var.gcp_advertised_cidrs)

      content {
        range       = advertised_ip_ranges.value
        description = "GCP route advertised to AWS over HA VPN"
      }
    }
  }
}

data "terraform_remote_state" "network" {
  backend = "local"

  config = {
    path = "${path.module}/../network/terraform.tfstate"
  }
}

resource "aws_customer_gateway" "gcp_if0" {
  bgp_asn    = var.gcp_bgp_asn
  ip_address = google_compute_ha_vpn_gateway.this.vpn_interfaces[0].ip_address
  type       = "ipsec.1"
  tags       = merge(local.tags, { Name = "${local.name}-cgw-gcp-if0" })

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_customer_gateway" "gcp_if1" {
  bgp_asn    = var.gcp_bgp_asn
  ip_address = google_compute_ha_vpn_gateway.this.vpn_interfaces[1].ip_address
  type       = "ipsec.1"
  tags       = merge(local.tags, { Name = "${local.name}-cgw-gcp-if1" })

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_vpn_connection" "if0" {
  customer_gateway_id = aws_customer_gateway.gcp_if0.id
  transit_gateway_id  = local.aws_transit_gateway_id
  type                = "ipsec.1"

  tunnel1_ike_versions     = ["ikev2"]
  tunnel1_preshared_key    = var.tunnel_psks.if0_tunnel1
  tunnel1_startup_action   = "start"
  tunnel2_ike_versions     = ["ikev2"]
  tunnel2_preshared_key    = var.tunnel_psks.if0_tunnel2
  tunnel2_startup_action   = "start"
  tunnel_inside_ip_version = "ipv4"
  outside_ip_address_type  = "PublicIpv4"
  static_routes_only       = false
  local_ipv4_network_cidr  = "0.0.0.0/0"
  remote_ipv4_network_cidr = "0.0.0.0/0"

  tags = merge(local.tags, { Name = "${local.name}-aws-if0" })

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_vpn_connection" "if1" {
  customer_gateway_id = aws_customer_gateway.gcp_if1.id
  transit_gateway_id  = local.aws_transit_gateway_id
  type                = "ipsec.1"

  tunnel1_ike_versions     = ["ikev2"]
  tunnel1_preshared_key    = var.tunnel_psks.if1_tunnel1
  tunnel1_startup_action   = "start"
  tunnel2_ike_versions     = ["ikev2"]
  tunnel2_preshared_key    = var.tunnel_psks.if1_tunnel2
  tunnel2_startup_action   = "start"
  tunnel_inside_ip_version = "ipv4"
  outside_ip_address_type  = "PublicIpv4"
  static_routes_only       = false
  local_ipv4_network_cidr  = "0.0.0.0/0"
  remote_ipv4_network_cidr = "0.0.0.0/0"

  tags = merge(local.tags, { Name = "${local.name}-aws-if1" })

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_compute_external_vpn_gateway" "aws" {
  name            = "${local.name}-aws-peer"
  redundancy_type = "FOUR_IPS_REDUNDANCY"
  labels          = var.labels

  interface {
    id         = 0
    ip_address = aws_vpn_connection.if0.tunnel1_address
  }

  interface {
    id         = 1
    ip_address = aws_vpn_connection.if0.tunnel2_address
  }

  interface {
    id         = 2
    ip_address = aws_vpn_connection.if1.tunnel1_address
  }

  interface {
    id         = 3
    ip_address = aws_vpn_connection.if1.tunnel2_address
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_compute_vpn_tunnel" "this" {
  for_each = local.tunnels

  name                            = each.value.name
  region                          = var.gcp_region
  vpn_gateway                     = google_compute_ha_vpn_gateway.this.id
  vpn_gateway_interface           = each.value.gcp_interface
  peer_external_gateway           = google_compute_external_vpn_gateway.aws.id
  peer_external_gateway_interface = each.value.peer_interface
  shared_secret                   = each.value.psk
  ike_version                     = 2
  router                          = google_compute_router.this.id
  labels                          = var.labels

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      shared_secret
    ]
  }
}

resource "google_compute_router_interface" "this" {
  for_each = local.tunnels

  name       = each.value.router_interface_name
  region     = var.gcp_region
  router     = google_compute_router.this.name
  vpn_tunnel = google_compute_vpn_tunnel.this[each.key].name

  ip_range = each.value.aws_vpn_key == "if0" && each.value.aws_tunnel_number == 1 ? "${cidrhost(aws_vpn_connection.if0.tunnel1_inside_cidr, 2)}/30" : (
    each.value.aws_vpn_key == "if0" && each.value.aws_tunnel_number == 2 ? "${cidrhost(aws_vpn_connection.if0.tunnel2_inside_cidr, 2)}/30" : (
      each.value.aws_vpn_key == "if1" && each.value.aws_tunnel_number == 1 ? "${cidrhost(aws_vpn_connection.if1.tunnel1_inside_cidr, 2)}/30" : "${cidrhost(aws_vpn_connection.if1.tunnel2_inside_cidr, 2)}/30"
    )
  )
}

resource "google_compute_router_peer" "this" {
  for_each = local.tunnels

  name                      = each.value.bgp_peer_name
  region                    = var.gcp_region
  router                    = google_compute_router.this.name
  interface                 = google_compute_router_interface.this[each.key].name
  peer_asn                  = var.aws_bgp_asn
  advertised_route_priority = each.value.advertised_priority

  peer_ip_address = each.value.aws_vpn_key == "if0" && each.value.aws_tunnel_number == 1 ? cidrhost(aws_vpn_connection.if0.tunnel1_inside_cidr, 1) : (
    each.value.aws_vpn_key == "if0" && each.value.aws_tunnel_number == 2 ? cidrhost(aws_vpn_connection.if0.tunnel2_inside_cidr, 1) : (
      each.value.aws_vpn_key == "if1" && each.value.aws_tunnel_number == 1 ? cidrhost(aws_vpn_connection.if1.tunnel1_inside_cidr, 1) : cidrhost(aws_vpn_connection.if1.tunnel2_inside_cidr, 1)
    )
  )
}

resource "aws_ec2_transit_gateway_route_table_association" "vpn_if0" {
  transit_gateway_attachment_id  = aws_vpn_connection.if0.transit_gateway_attachment_id
  transit_gateway_route_table_id = local.associate_tgw_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_association" "vpn_if1" {
  transit_gateway_attachment_id  = aws_vpn_connection.if1.transit_gateway_attachment_id
  transit_gateway_route_table_id = local.associate_tgw_route_table_id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_if0" {
  for_each = local.propagate_tgw_route_table_ids

  transit_gateway_attachment_id  = aws_vpn_connection.if0.transit_gateway_attachment_id
  transit_gateway_route_table_id = each.value
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_if1" {
  for_each = local.propagate_tgw_route_table_ids

  transit_gateway_attachment_id  = aws_vpn_connection.if1.transit_gateway_attachment_id
  transit_gateway_route_table_id = each.value
}

resource "google_compute_firewall" "allow_aws_to_gcp_vpn" {
  name    = "${local.name}-allow-aws"
  network = var.gcp_network

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = var.aws_allowed_source_cidrs

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "8080"]
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "sctp"
  }
}
