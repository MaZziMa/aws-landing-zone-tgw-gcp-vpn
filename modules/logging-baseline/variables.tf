variable "name" {
  type        = string
  description = "Name prefix for logging resources."
}

variable "organization_id" {
  type        = string
  description = "AWS Organization ID allowed to write logs."
}

variable "management_account_id" {
  type        = string
  description = "Management account ID for CloudTrail permissions."
}

variable "retention_days" {
  type        = number
  description = "Days before transitioning logs to infrequent access."
  default     = 90
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to resources."
  default     = {}
}
