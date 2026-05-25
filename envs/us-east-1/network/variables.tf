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

variable "network_account_id" {
  type = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.network_account_id))
    error_message = "network_account_id must be a 12 digit AWS account ID."
  }
}

variable "shared_services_account_id" {
  type = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.shared_services_account_id))
    error_message = "shared_services_account_id must be a 12 digit AWS account ID."
  }
}

variable "dev_account_id" {
  type = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.dev_account_id))
    error_message = "dev_account_id must be a 12 digit AWS account ID."
  }
}

variable "test_account_id" {
  type        = string
  description = "Optional Test account ID. Leave empty if Test is not created yet."
  default     = ""

  validation {
    condition     = var.test_account_id == "" || can(regex("^[0-9]{12}$", var.test_account_id))
    error_message = "test_account_id must be empty or a 12 digit AWS account ID."
  }
}

variable "prod_account_id" {
  type = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.prod_account_id))
    error_message = "prod_account_id must be a 12 digit AWS account ID."
  }
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "network_vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.network_vpc_cidr, 0))
    error_message = "network_vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "dev_vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"

  validation {
    condition     = can(cidrhost(var.dev_vpc_cidr, 0))
    error_message = "dev_vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "test_vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.test_vpc_cidr, 0))
    error_message = "test_vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "prod_vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"

  validation {
    condition     = can(cidrhost(var.prod_vpc_cidr, 0))
    error_message = "prod_vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "shared_services_vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.shared_services_vpc_cidr, 0))
    error_message = "shared_services_vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "data_vpc_cidr" {
  type        = string
  description = "Reserved CIDR for future Data Platform VPC. Not deployed in phase 1."
  default     = "10.6.0.0/16"

  validation {
    condition     = can(cidrhost(var.data_vpc_cidr, 0))
    error_message = "data_vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "egress_public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs for centralized NAT Gateways."
  default     = ["10.0.0.0/24", "10.0.1.0/24"]

  validation {
    condition     = length(var.egress_public_subnet_cidrs) > 0 && alltrue([for cidr in var.egress_public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "egress_public_subnet_cidrs must contain valid IPv4 CIDRs."
  }
}

variable "egress_tgw_subnet_cidrs" {
  type        = list(string)
  description = "TGW attachment subnet CIDRs for centralized egress."
  default     = ["10.0.10.0/28", "10.0.10.16/28"]

  validation {
    condition     = length(var.egress_tgw_subnet_cidrs) > 0 && alltrue([for cidr in var.egress_tgw_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "egress_tgw_subnet_cidrs must contain valid IPv4 CIDRs."
  }
}
