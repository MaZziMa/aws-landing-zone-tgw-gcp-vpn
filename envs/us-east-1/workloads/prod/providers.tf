provider "aws" {
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.prod_account_id}:role/${var.deploy_role_name}"
  }
}

provider "aws" {
  alias  = "network"
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.network_account_id}:role/${var.deploy_role_name}"
  }
}
