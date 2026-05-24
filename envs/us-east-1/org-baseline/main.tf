data "aws_organizations_organization" "this" {}

locals {
  tags = {
    ManagedBy = "Terraform"
    Project   = "LandingZone"
  }

  deploy_principals = length(var.trusted_deploy_principal_arns) > 0 ? var.trusted_deploy_principal_arns : [
    "arn:aws:iam::${var.management_account_id}:root"
  ]

  create_test_deploy_role = var.test_account_id != "" && var.test_account_id != var.dev_account_id

  security_ou_id       = var.security_ou_id != "" ? var.security_ou_id : aws_organizations_organizational_unit.security[0].id
  infrastructure_ou_id = var.infrastructure_ou_id != "" ? var.infrastructure_ou_id : aws_organizations_organizational_unit.infrastructure[0].id
  workloads_ou_id      = var.workloads_ou_id != "" ? var.workloads_ou_id : aws_organizations_organizational_unit.workloads[0].id
  prod_ou_id           = var.prod_ou_id != "" ? var.prod_ou_id : aws_organizations_organizational_unit.prod[0].id
  nonprod_ou_id        = var.nonprod_ou_id != "" ? var.nonprod_ou_id : aws_organizations_organizational_unit.nonprod[0].id
}

resource "aws_organizations_organizational_unit" "security" {
  count = var.security_ou_id == "" ? 1 : 0

  name      = "Security"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "infrastructure" {
  count = var.infrastructure_ou_id == "" ? 1 : 0

  name      = "Infrastructure"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads" {
  count = var.workloads_ou_id == "" ? 1 : 0

  name      = "Workloads"
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_organizational_unit" "nonprod" {
  count = var.nonprod_ou_id == "" ? 1 : 0

  name      = "NonProd"
  parent_id = local.workloads_ou_id
}

resource "aws_organizations_organizational_unit" "prod" {
  count = var.prod_ou_id == "" ? 1 : 0

  name      = "Prod"
  parent_id = local.workloads_ou_id
}

data "aws_iam_policy_document" "deny_workload_nat" {
  statement {
    sid    = "DenyWorkloadNatGateways"
    effect = "Deny"

    actions = [
      "ec2:CreateNatGateway",
      "ec2:DeleteNatGateway"
    ]

    resources = ["*"]
  }
}

resource "aws_organizations_policy" "deny_workload_nat" {
  name        = "DenyWorkloadNatGateways"
  description = "Prevent NAT Gateway creation in workload OUs; centralized egress lives in Network account."
  content     = data.aws_iam_policy_document.deny_workload_nat.json
}

resource "aws_organizations_policy_attachment" "deny_nonprod_nat" {
  policy_id = aws_organizations_policy.deny_workload_nat.id
  target_id = local.nonprod_ou_id
}

resource "aws_organizations_policy_attachment" "deny_prod_nat" {
  policy_id = aws_organizations_policy.deny_workload_nat.id
  target_id = local.prod_ou_id
}

resource "aws_ram_sharing_with_organization" "this" {}

module "deploy_role_security" {
  source = "../../../modules/iam-deploy-role"

  providers = {
    aws = aws.security
  }

  role_name              = var.deploy_role_name
  trusted_principal_arns = local.deploy_principals
}

module "deploy_role_log_archive" {
  source = "../../../modules/iam-deploy-role"

  providers = {
    aws = aws.log_archive
  }

  role_name              = var.deploy_role_name
  trusted_principal_arns = local.deploy_principals
}

module "deploy_role_network" {
  source = "../../../modules/iam-deploy-role"

  providers = {
    aws = aws.network
  }

  role_name              = var.deploy_role_name
  trusted_principal_arns = local.deploy_principals
}

module "deploy_role_shared_services" {
  source = "../../../modules/iam-deploy-role"

  providers = {
    aws = aws.shared_services
  }

  role_name              = var.deploy_role_name
  trusted_principal_arns = local.deploy_principals
}

module "deploy_role_dev" {
  source = "../../../modules/iam-deploy-role"

  providers = {
    aws = aws.dev
  }

  role_name              = var.deploy_role_name
  trusted_principal_arns = local.deploy_principals
}

module "deploy_role_test" {
  count = local.create_test_deploy_role ? 1 : 0

  source = "../../../modules/iam-deploy-role"

  providers = {
    aws = aws.test
  }

  role_name              = var.deploy_role_name
  trusted_principal_arns = local.deploy_principals
}

module "deploy_role_prod" {
  source = "../../../modules/iam-deploy-role"

  providers = {
    aws = aws.prod
  }

  role_name              = var.deploy_role_name
  trusted_principal_arns = local.deploy_principals
}
