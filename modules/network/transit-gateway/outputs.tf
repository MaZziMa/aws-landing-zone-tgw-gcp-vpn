output "transit_gateway_id" {
  value = aws_ec2_transit_gateway.this.id
}

output "egress_route_table_id" {
  value = aws_ec2_transit_gateway_route_table.egress.id
}

output "prod_route_table_id" {
  value = aws_ec2_transit_gateway_route_table.prod.id
}

output "nonprod_route_table_id" {
  value = aws_ec2_transit_gateway_route_table.nonprod.id
}

output "vpn_route_table_id" {
  value = aws_ec2_transit_gateway_route_table.vpn.id
}
