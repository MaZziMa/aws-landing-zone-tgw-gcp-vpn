variable "aws_region" {
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

variable "aws_assume_role_arn" {
  type        = string
  description = "Optional AWS role ARN to assume. Leave null to use the active AWS CLI/profile credentials directly."
  default     = null
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
}

variable "aws_transit_gateway_id" {
  type        = string
  description = "Optional override. Defaults to the network stack output."
  default     = null
}

variable "name_prefix" {
  type        = string
  description = "Name prefix for GCP and AWS VPN resources."
  default     = "aws-gcp-vpn"
}

variable "gcp_network" {
  type    = string
  default = "default"
}

variable "aws_allowed_source_cidrs" {
  type        = list(string)
  description = "AWS CIDR ranges allowed through the GCP firewall for VPN test traffic."
  default     = ["10.0.0.0/16", "10.10.0.0/16", "10.30.0.0/16"]
}

variable "gcp_advertised_cidrs" {
  type        = list(string)
  description = "GCP CIDR ranges advertised to AWS over BGP."
  default     = ["10.128.0.0/20"]
}

variable "aws_bgp_asn" {
  type        = number
  description = "BGP ASN used by the AWS Transit Gateway."
  default     = 64512
}

variable "gcp_bgp_asn" {
  type    = number
  default = 65001
}

variable "associate_tgw_route_table_id" {
  type        = string
  description = "Optional override. Defaults to the network stack VPN route table output."
  default     = null
}

variable "propagate_tgw_route_table_ids" {
  type        = set(string)
  description = "Optional override. Defaults to the network stack NonProd and Prod route table outputs."
  default     = null
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
}

variable "labels" {
  type = map(string)
  default = {
    managed_by = "terraform"
    project    = "landing-zone"
  }
}
