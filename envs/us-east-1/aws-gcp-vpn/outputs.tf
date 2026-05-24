output "gcp_ha_vpn_gateway_interfaces" {
  value = {
    for interface in google_compute_ha_vpn_gateway.this.vpn_interfaces :
    interface.id => interface.ip_address
  }
}

output "aws_vpn_connection_ids" {
  value = {
    if0 = aws_vpn_connection.if0.id
    if1 = aws_vpn_connection.if1.id
  }
}

output "aws_vpn_tgw_attachment_ids" {
  value = {
    if0 = aws_vpn_connection.if0.transit_gateway_attachment_id
    if1 = aws_vpn_connection.if1.transit_gateway_attachment_id
  }
}

output "aws_tunnel_outside_ips" {
  value = {
    if0_tunnel1 = aws_vpn_connection.if0.tunnel1_address
    if0_tunnel2 = aws_vpn_connection.if0.tunnel2_address
    if1_tunnel1 = aws_vpn_connection.if1.tunnel1_address
    if1_tunnel2 = aws_vpn_connection.if1.tunnel2_address
  }
}

output "aws_tunnel_inside_cidrs" {
  value = {
    if0_tunnel1 = aws_vpn_connection.if0.tunnel1_inside_cidr
    if0_tunnel2 = aws_vpn_connection.if0.tunnel2_inside_cidr
    if1_tunnel1 = aws_vpn_connection.if1.tunnel1_inside_cidr
    if1_tunnel2 = aws_vpn_connection.if1.tunnel2_inside_cidr
  }
}

output "gcp_bgp_interface_ips" {
  value = {
    if0_tunnel1 = cidrhost(aws_vpn_connection.if0.tunnel1_inside_cidr, 2)
    if0_tunnel2 = cidrhost(aws_vpn_connection.if0.tunnel2_inside_cidr, 2)
    if1_tunnel1 = cidrhost(aws_vpn_connection.if1.tunnel1_inside_cidr, 2)
    if1_tunnel2 = cidrhost(aws_vpn_connection.if1.tunnel2_inside_cidr, 2)
  }
}

output "aws_bgp_peer_ips" {
  value = {
    if0_tunnel1 = cidrhost(aws_vpn_connection.if0.tunnel1_inside_cidr, 1)
    if0_tunnel2 = cidrhost(aws_vpn_connection.if0.tunnel2_inside_cidr, 1)
    if1_tunnel1 = cidrhost(aws_vpn_connection.if1.tunnel1_inside_cidr, 1)
    if1_tunnel2 = cidrhost(aws_vpn_connection.if1.tunnel2_inside_cidr, 1)
  }
}
