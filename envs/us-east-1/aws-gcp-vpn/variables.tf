variable "aws_region" {
  type    = string
  default = "us-east-1"

  validation {
    condition     = contains(["us-east-1"], var.aws_region)
    error_message = "Only us-east-1 is supported by this VPN stack."
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

variable "aws_assume_role_arn" {
  type        = string
  description = "Optional AWS role ARN to assume. Leave null to use the active AWS CLI/profile credentials directly."
  default     = null

  validation {
    condition     = var.aws_assume_role_arn == null || can(regex("^arn:aws:iam::[0-9]{12}:role/.+", var.aws_assume_role_arn))
    error_message = "aws_assume_role_arn must be null or a valid IAM role ARN."
  }
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_credentials_file" {
  type        = string
  description = "Optional path to a GCP service account JSON key. Leave null to use Application Default Credentials."
  default     = null
  sensitive   = true
}

variable "gcp_region" {
  type    = string
  default = "us-central1"

  validation {
    condition     = contains(["us-central1"], var.gcp_region)
    error_message = "Only us-central1 is supported by this VPN stack."
  }
}

variable "aws_transit_gateway_id" {
  type        = string
  description = "Optional override. Defaults to the network stack output."
  default     = null

  validation {
    condition     = var.aws_transit_gateway_id == null || can(regex("^tgw-[0-9a-f]+$", var.aws_transit_gateway_id))
    error_message = "aws_transit_gateway_id must be null or a valid TGW ID."
  }
}

variable "gcp_network" {
  type    = string
  default = "default"
}

variable "aws_allowed_source_cidrs" {
  type        = list(string)
  description = "AWS CIDR ranges allowed through the GCP firewall for VPN test traffic."
  default     = ["10.0.0.0/16", "10.10.0.0/16", "10.30.0.0/16"]

  validation {
    condition     = length(var.aws_allowed_source_cidrs) > 0 && alltrue([for cidr in var.aws_allowed_source_cidrs : can(cidrhost(cidr, 0))])
    error_message = "aws_allowed_source_cidrs must contain valid IPv4 CIDRs."
  }
}

variable "gcp_advertised_cidrs" {
  type        = list(string)
  description = "GCP CIDR ranges advertised to AWS over BGP."
  default     = ["10.128.0.0/20"]

  validation {
    condition     = length(var.gcp_advertised_cidrs) > 0 && alltrue([for cidr in var.gcp_advertised_cidrs : can(cidrhost(cidr, 0))])
    error_message = "gcp_advertised_cidrs must contain valid IPv4 CIDRs."
  }
}

variable "aws_bgp_asn" {
  type        = number
  description = "BGP ASN used by the AWS Transit Gateway."
  default     = 64512

  validation {
    condition     = var.aws_bgp_asn >= 64512 && var.aws_bgp_asn <= 65534
    error_message = "aws_bgp_asn must be in the private 16-bit ASN range 64512-65534."
  }
}

variable "gcp_bgp_asn" {
  type    = number
  default = 65001

  validation {
    condition     = var.gcp_bgp_asn >= 64512 && var.gcp_bgp_asn <= 65534
    error_message = "gcp_bgp_asn must be in the private 16-bit ASN range 64512-65534."
  }
}

variable "associate_tgw_route_table_id" {
  type        = string
  description = "Optional override. Defaults to the network stack VPN route table output."
  default     = null

  validation {
    condition     = var.associate_tgw_route_table_id == null || can(regex("^tgw-rtb-[0-9a-f]+$", var.associate_tgw_route_table_id))
    error_message = "associate_tgw_route_table_id must be null or a valid TGW route table ID."
  }
}

variable "propagate_tgw_route_table_ids" {
  type        = set(string)
  description = "Optional override. Defaults to the network stack NonProd and Prod route table outputs."
  default     = null

  validation {
    condition     = var.propagate_tgw_route_table_ids == null || alltrue([for id in var.propagate_tgw_route_table_ids : can(regex("^tgw-rtb-[0-9a-f]+$", id))])
    error_message = "propagate_tgw_route_table_ids must be null or a set of valid TGW route table IDs."
  }
}

variable "tunnel_psks" {
  type = object({
    if0_tunnel1 = string
    if0_tunnel2 = string
    if1_tunnel1 = string
    if1_tunnel2 = string
  })
  description = "Pre-shared keys for the four AWS to GCP HA VPN tunnels."
  sensitive   = true

  validation {
    condition = alltrue([
      for psk in values(var.tunnel_psks) :
      length(psk) >= 8 && length(psk) <= 64 && can(regex("^[A-Za-z0-9._-]+$", psk))
    ])
    error_message = "Each tunnel PSK must be 8-64 characters and use only letters, numbers, dot, underscore, or hyphen."
  }
}

variable "labels" {
  type = map(string)
  default = {
    managed_by = "terraform"
    project    = "landing-zone"
  }

  validation {
    condition = alltrue([
      for key, value in var.labels :
      can(regex("^[a-z][a-z0-9_-]{0,62}$", key)) && can(regex("^[a-z0-9_-]{0,63}$", value))
    ])
    error_message = "GCP label keys and values must use lowercase letters, numbers, underscores, or hyphens."
  }
}
