variable "region" {
  type    = string
  default = "us-east-1"
}

variable "deploy_role_name" {
  type    = string
  default = "LandingZoneDeployRole"
}

variable "shared_services_account_id" {
  type = string
}

variable "network_account_id" {
  type = string
}

variable "transit_gateway_id" {
  type = string
}

variable "nonprod_route_table_id" {
  type = string
}

variable "egress_route_table_id" {
  type = string
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "web_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.0.0/24", "10.1.1.0/24"]
}

variable "app_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.10.0/24", "10.1.11.0/24"]
}

variable "data_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.20.0/24", "10.1.21.0/24"]
}

variable "tgw_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.30.0/28", "10.1.30.16/28"]
}
