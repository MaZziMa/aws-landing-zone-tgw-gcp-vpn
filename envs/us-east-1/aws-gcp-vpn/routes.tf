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
