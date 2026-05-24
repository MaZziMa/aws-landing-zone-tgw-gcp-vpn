provider "aws" {
  region = var.aws_region

  dynamic "assume_role" {
    for_each = var.aws_assume_role_arn == null ? [] : [var.aws_assume_role_arn]

    content {
      role_arn = assume_role.value
    }
  }
}

provider "google" {
  project     = var.gcp_project_id
  region      = var.gcp_region
  credentials = var.gcp_credentials_file == null ? null : file(var.gcp_credentials_file)
}
