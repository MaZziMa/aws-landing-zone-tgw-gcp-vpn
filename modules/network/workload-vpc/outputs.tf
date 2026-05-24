output "vpc_id" {
  value = aws_vpc.this.id
}

output "attachment_id" {
  value = aws_ec2_transit_gateway_vpc_attachment.this.id
}

output "web_subnet_ids" {
  value = aws_subnet.web[*].id
}

output "app_subnet_ids" {
  value = aws_subnet.app[*].id
}

output "data_subnet_ids" {
  value = aws_subnet.data[*].id
}
