variable "name" {
  type        = string
  description = "Name of the Transit Gateway."
}

variable "ram_principal_account_ids" {
  type        = list(string)
  description = "Account IDs that can attach VPCs to this TGW."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to resources."
  default     = {}
}
