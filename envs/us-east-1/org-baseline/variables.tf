variable "region" {
  type        = string
  description = "AWS region."
  default     = "us-east-1"
}

variable "deploy_role_name" {
  type        = string
  description = "Role name used by CI/CD in each account."
  default     = "LandingZoneDeployRole"
}

variable "management_account_id" {
  type = string
}

variable "security_account_id" {
  type = string
}

variable "log_archive_account_id" {
  type = string
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

variable "trusted_deploy_principal_arns" {
  type        = list(string)
  description = "CI/CD principals allowed to assume LandingZoneDeployRole."
  default     = []
}

variable "security_ou_id" {
  type        = string
  description = "Existing Security OU ID. Leave empty to let Terraform create it."
  default     = ""
}

variable "infrastructure_ou_id" {
  type        = string
  description = "Existing Infrastructure OU ID. Leave empty to let Terraform create it."
  default     = ""
}

variable "workloads_ou_id" {
  type        = string
  description = "Existing Workloads OU ID. Leave empty to let Terraform create it."
  default     = ""
}

variable "prod_ou_id" {
  type        = string
  description = "Existing Workloads/Prod OU ID. Leave empty to let Terraform create it."
  default     = ""
}

variable "nonprod_ou_id" {
  type        = string
  description = "Existing Workloads/NonProd OU ID. Leave empty to let Terraform create it."
  default     = ""
}
