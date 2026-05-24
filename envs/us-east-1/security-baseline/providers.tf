provider "aws" {
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.security_account_id}:role/${var.deploy_role_name}"
  }
}
