output "organization_id" {
  value = data.aws_organizations_organization.this.id
}

output "organizational_units" {
  value = {
    security       = local.security_ou_id
    infrastructure = local.infrastructure_ou_id
    workloads      = local.workloads_ou_id
    nonprod        = local.nonprod_ou_id
    prod           = local.prod_ou_id
  }
}
