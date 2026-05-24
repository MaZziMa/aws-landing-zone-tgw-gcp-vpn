variable "region" {
  type    = string
  default = "us-east-1"
}

variable "deploy_role_name" {
  type    = string
  default = "LandingZoneDeployRole"
}

variable "management_account_id" {
  type = string
}

variable "log_archive_account_id" {
  type = string
}

variable "organization_id" {
  type        = string
  description = "AWS Organization ID from org-baseline output."
}

variable "log_bucket_name" {
  type        = string
  description = "Globally unique bucket name for central logs."
}
