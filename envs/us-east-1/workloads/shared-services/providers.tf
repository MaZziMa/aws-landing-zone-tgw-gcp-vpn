provider "aws" {
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.shared_services_account_id}:role/${var.deploy_role_name}"
  }
}

provider "aws" {
  alias  = "network"
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.network_account_id}:role/${var.deploy_role_name}"
  }
}
