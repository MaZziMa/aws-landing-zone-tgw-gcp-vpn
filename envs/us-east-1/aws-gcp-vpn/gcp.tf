resource "google_compute_ha_vpn_gateway" "this" {
  name    = local.names.gcp_ha_vpn_gateway
  network = var.gcp_network
  region  = var.gcp_region
  labels  = var.labels
}

resource "google_compute_router" "this" {
  name    = local.names.gcp_router
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

resource "google_compute_external_vpn_gateway" "aws" {
  name            = local.names.gcp_external_vpn_gw
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

resource "google_compute_firewall" "allow_aws_to_gcp_vpn" {
  name    = local.names.gcp_firewall_allow_aws
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
