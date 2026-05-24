provider "aws" {
  alias  = "management"
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.management_account_id}:role/${var.deploy_role_name}"
  }
}

provider "aws" {
  alias  = "log_archive"
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.log_archive_account_id}:role/${var.deploy_role_name}"
  }
}
