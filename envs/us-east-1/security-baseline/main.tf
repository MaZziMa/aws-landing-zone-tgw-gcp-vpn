module "security_baseline" {
  source = "../../../modules/security-baseline"

  enable_security_hub = var.enable_security_hub

  tags = {
    ManagedBy = "Terraform"
    Project   = "LandingZone"
    Account   = "Security"
  }
}
