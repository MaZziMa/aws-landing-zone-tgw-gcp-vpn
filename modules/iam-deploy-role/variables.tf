variable "role_name" {
  type        = string
  description = "Name of the deploy role to create."
}

variable "trusted_principal_arns" {
  type        = list(string)
  description = "IAM principals allowed to assume the deploy role."
}

variable "managed_policy_arns" {
  type        = list(string)
  description = "Managed policies attached to the deploy role."
  default     = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}
