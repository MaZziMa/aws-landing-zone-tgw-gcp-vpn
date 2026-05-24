variable "enable_security_hub" {
  type        = bool
  description = "Whether to enable Security Hub in this account."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to resources."
  default     = {}
}
