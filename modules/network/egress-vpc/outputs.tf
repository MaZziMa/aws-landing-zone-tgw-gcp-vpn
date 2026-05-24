output "vpc_id" {
  value = aws_vpc.this.id
}

output "attachment_id" {
  value = aws_ec2_transit_gateway_vpc_attachment.this.id
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.this[*].id
}
