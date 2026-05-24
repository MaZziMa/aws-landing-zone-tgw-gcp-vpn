variable "region" {
  type    = string
  default = "us-east-1"
}

variable "deploy_role_name" {
  type    = string
  default = "LandingZoneDeployRole"
}

variable "test_account_id" {
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
  default = "10.20.0.0/16"
}
