variable "name" {
  type        = string
  description = "Name prefix for the egress VPC."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the egress VPC."
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones to use."
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs for NAT Gateways."
}

variable "tgw_subnet_cidrs" {
  type        = list(string)
  description = "TGW attachment subnet CIDRs."
}

variable "transit_gateway_id" {
  type        = string
  description = "Transit Gateway ID."
}

variable "workload_cidrs" {
  type        = list(string)
  description = "Workload CIDRs routed back to TGW from NAT subnets."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to resources."
  default     = {}
}
