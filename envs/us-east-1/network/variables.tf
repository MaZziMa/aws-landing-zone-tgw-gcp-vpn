variable "region" {
  type    = string
  default = "us-east-1"
}

variable "deploy_role_name" {
  type    = string
  default = "LandingZoneDeployRole"
}

variable "network_account_id" {
  type = string
}

variable "shared_services_account_id" {
  type = string
}

variable "dev_account_id" {
  type = string
}

variable "test_account_id" {
  type        = string
  description = "Optional Test account ID. Leave empty if Test is not created yet."
  default     = ""
}

variable "prod_account_id" {
  type = string
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "network_vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "dev_vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "test_vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "prod_vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "shared_services_vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "data_vpc_cidr" {
  type        = string
  description = "Reserved CIDR for future Data Platform VPC. Not deployed in phase 1."
  default     = "10.6.0.0/16"
}

variable "egress_public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs for centralized NAT Gateways."
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "egress_tgw_subnet_cidrs" {
  type        = list(string)
  description = "TGW attachment subnet CIDRs for centralized egress."
  default     = ["10.0.10.0/28", "10.0.10.16/28"]
}
