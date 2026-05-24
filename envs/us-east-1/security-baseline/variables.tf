variable "region" {
  type    = string
  default = "us-east-1"
}

variable "deploy_role_name" {
  type    = string
  default = "LandingZoneDeployRole"
}

variable "security_account_id" {
  type = string
}

variable "enable_security_hub" {
  type    = bool
  default = false
}
