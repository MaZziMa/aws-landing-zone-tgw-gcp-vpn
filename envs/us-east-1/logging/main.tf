locals {
  tags = {
    ManagedBy = "Terraform"
    Project   = "LandingZone"
    Account   = "LogArchive"
  }
}

module "logging" {
  source = "../../../modules/logging-baseline"

  providers = {
    aws = aws.log_archive
  }

  name                  = var.log_bucket_name
  organization_id       = var.organization_id
  management_account_id = var.management_account_id
  tags                  = local.tags
}

resource "aws_cloudtrail" "organization" {
  provider = aws.management

  name                          = "landing-zone-organization-trail"
  s3_bucket_name                = module.logging.bucket_name
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [module.logging]
}
