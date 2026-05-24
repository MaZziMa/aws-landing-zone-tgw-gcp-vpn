output "transit_gateway_id" {
  value = module.transit_gateway.transit_gateway_id
}

output "egress_attachment_id" {
  value = module.egress_vpc.attachment_id
}

output "prod_route_table_id" {
  value = module.transit_gateway.prod_route_table_id
}

output "nonprod_route_table_id" {
  value = module.transit_gateway.nonprod_route_table_id
}

output "egress_route_table_id" {
  value = module.transit_gateway.egress_route_table_id
}

output "vpn_route_table_id" {
  value = module.transit_gateway.vpn_route_table_id
}
