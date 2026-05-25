variable "region" {
  type    = string
  default = "us-east-1"

  validation {
    condition     = contains(["us-east-1"], var.region)
    error_message = "Only us-east-1 is supported by this environment stack."
  }
}

variable "deploy_role_name" {
  type    = string
  default = "LandingZoneDeployRole"
}

variable "prod_account_id" {
  type = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.prod_account_id))
    error_message = "prod_account_id must be a 12 digit AWS account ID."
  }
}

variable "network_account_id" {
  type = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.network_account_id))
    error_message = "network_account_id must be a 12 digit AWS account ID."
  }
}

variable "transit_gateway_id" {
  type        = string
  description = "Optional override. Defaults to the network stack output."
  default     = null

  validation {
    condition     = var.transit_gateway_id == null || can(regex("^tgw-[0-9a-f]+$", var.transit_gateway_id))
    error_message = "transit_gateway_id must be null or a valid TGW ID."
  }
}

variable "prod_route_table_id" {
  type        = string
  description = "Optional override. Defaults to the network stack output."
  default     = null

  validation {
    condition     = var.prod_route_table_id == null || can(regex("^tgw-rtb-[0-9a-f]+$", var.prod_route_table_id))
    error_message = "prod_route_table_id must be null or a valid TGW route table ID."
  }
}

variable "egress_route_table_id" {
  type        = string
  description = "Optional override. Defaults to the network stack output."
  default     = null

  validation {
    condition     = var.egress_route_table_id == null || can(regex("^tgw-rtb-[0-9a-f]+$", var.egress_route_table_id))
    error_message = "egress_route_table_id must be null or a valid TGW route table ID."
  }
}

variable "vpn_route_table_id" {
  type        = string
  description = "Optional override. Defaults to the network stack output."
  default     = null

  validation {
    condition     = var.vpn_route_table_id == null || can(regex("^tgw-rtb-[0-9a-f]+$", var.vpn_route_table_id))
    error_message = "vpn_route_table_id must be null or a valid TGW route table ID."
  }
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "web_subnet_cidrs" {
  type        = list(string)
  description = "Public web subnet CIDRs."
  default     = ["10.30.0.0/24", "10.30.1.0/24"]

  validation {
    condition     = length(var.web_subnet_cidrs) > 0 && alltrue([for cidr in var.web_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "web_subnet_cidrs must contain valid IPv4 CIDRs."
  }
}

variable "app_subnet_cidrs" {
  type        = list(string)
  description = "Private app subnet CIDRs."
  default     = ["10.30.10.0/24", "10.30.11.0/24"]

  validation {
    condition     = length(var.app_subnet_cidrs) > 0 && alltrue([for cidr in var.app_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "app_subnet_cidrs must contain valid IPv4 CIDRs."
  }
}

variable "data_subnet_cidrs" {
  type        = list(string)
  description = "Private data subnet CIDRs."
  default     = ["10.30.20.0/24", "10.30.21.0/24"]

  validation {
    condition     = length(var.data_subnet_cidrs) > 0 && alltrue([for cidr in var.data_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "data_subnet_cidrs must contain valid IPv4 CIDRs."
  }
}

variable "tgw_subnet_cidrs" {
  type        = list(string)
  description = "TGW attachment subnet CIDRs."
  default     = ["10.30.30.0/28", "10.30.30.16/28"]

  validation {
    condition     = length(var.tgw_subnet_cidrs) > 0 && alltrue([for cidr in var.tgw_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "tgw_subnet_cidrs must contain valid IPv4 CIDRs."
  }
}
