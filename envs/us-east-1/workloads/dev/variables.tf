variable "region" {
  type    = string
  default = "us-east-1"
}

variable "deploy_role_name" {
  type    = string
  default = "LandingZoneDeployRole"
}

variable "dev_account_id" {
  type = string
}

variable "network_account_id" {
  type = string
}

variable "transit_gateway_id" {
  type        = string
  description = "Optional override. Defaults to the network stack output."
  default     = null
}

variable "nonprod_route_table_id" {
  type        = string
  description = "Optional override. Defaults to the network stack output."
  default     = null
}

variable "egress_route_table_id" {
  type        = string
  description = "Optional override. Defaults to the network stack output."
  default     = null
}

variable "vpn_route_table_id" {
  type        = string
  description = "Optional override. Defaults to the network stack output."
  default     = null
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}
