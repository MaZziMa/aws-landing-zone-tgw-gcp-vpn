variable "name" {
  type        = string
  description = "Workload VPC name."
}

variable "vpc_cidr" {
  type        = string
  description = "Workload VPC CIDR."
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones to use."
}

variable "web_subnet_cidrs" {
  type        = list(string)
  description = "Public web subnet CIDRs for ALB or other ingress resources."
  default     = []
}

variable "app_subnet_cidrs" {
  type        = list(string)
  description = "Private app subnet CIDRs."
}

variable "data_subnet_cidrs" {
  type        = list(string)
  description = "Private data subnet CIDRs."
}

variable "tgw_subnet_cidrs" {
  type        = list(string)
  description = "TGW attachment subnet CIDRs."
}

variable "transit_gateway_id" {
  type        = string
  description = "Shared Transit Gateway ID."
}

variable "create_internet_gateway" {
  type        = bool
  description = "Whether to create an Internet Gateway for public web subnets."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to resources."
  default     = {}
}
