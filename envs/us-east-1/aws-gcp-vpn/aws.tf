resource "aws_customer_gateway" "gcp_if0" {
  bgp_asn    = var.gcp_bgp_asn
  ip_address = google_compute_ha_vpn_gateway.this.vpn_interfaces[0].ip_address
  type       = "ipsec.1"
  tags       = merge(local.tags, { Name = local.names.aws_customer_gw_if0 })
}

resource "aws_customer_gateway" "gcp_if1" {
  bgp_asn    = var.gcp_bgp_asn
  ip_address = google_compute_ha_vpn_gateway.this.vpn_interfaces[1].ip_address
  type       = "ipsec.1"
  tags       = merge(local.tags, { Name = local.names.aws_customer_gw_if1 })
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

  tags = merge(local.tags, { Name = local.names.aws_vpn_if0 })
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

  tags = merge(local.tags, { Name = local.names.aws_vpn_if1 })
}
