output "vpc_id" {
  value = module.vpc.vpc_id
}

output "attachment_id" {
  value = module.vpc.attachment_id
}

output "web_subnet_ids" {
  value = module.vpc.web_subnet_ids
}

output "app_subnet_ids" {
  value = module.vpc.app_subnet_ids
}

output "data_subnet_ids" {
  value = module.vpc.data_subnet_ids
}
