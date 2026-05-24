# Deployment Guide

## 1. Prepare Accounts

Use AWS Control Tower to enroll existing accounts and create missing accounts.

Required accounts:

- Management
- Security
- Log Archive
- Network
- Shared Services
- Dev
- Test
- Prod

After enrollment, confirm each account has either:

- `OrganizationAccountAccessRole` for initial bootstrap from Management, or
- `LandingZoneDeployRole` after `org-baseline` has been applied.

## 2. Configure Terraform Inputs

Copy the root example and replace placeholder values:

```powershell
Copy-Item accounts.auto.tfvars.example accounts.auto.tfvars
```

For real usage, copy relevant values into each stack directory or pass them through CI/CD variables.

Important values produced by `envs/us-east-1/network` and consumed by workload stacks:

- `transit_gateway_id`
- `prod_route_table_id`
- `nonprod_route_table_id`
- `egress_route_table_id`

## 3. Initialize Backend

Create an S3 bucket and DynamoDB lock table for Terraform state. Then copy and customize:

```powershell
Copy-Item backend.example.hcl backend.hcl
```

Use a unique `key` per stack, for example:

```hcl
key = "landing-zone/us-east-1/network/terraform.tfstate"
```

## 4. Apply Stacks

Run stacks in this order:

```powershell
terraform -chdir=envs/us-east-1/org-baseline init -backend-config=../../../backend.hcl
terraform -chdir=envs/us-east-1/org-baseline apply

terraform -chdir=envs/us-east-1/logging init -backend-config=../../../backend.hcl
terraform -chdir=envs/us-east-1/logging apply

terraform -chdir=envs/us-east-1/security-baseline init -backend-config=../../../backend.hcl
terraform -chdir=envs/us-east-1/security-baseline apply

terraform -chdir=envs/us-east-1/network init -backend-config=../../../backend.hcl
terraform -chdir=envs/us-east-1/network apply

terraform -chdir=envs/us-east-1/workloads/shared-services init -backend-config=../../../../backend.hcl
terraform -chdir=envs/us-east-1/workloads/shared-services apply

terraform -chdir=envs/us-east-1/workloads/dev init -backend-config=../../../../backend.hcl
terraform -chdir=envs/us-east-1/workloads/dev apply

terraform -chdir=envs/us-east-1/workloads/test init -backend-config=../../../../backend.hcl
terraform -chdir=envs/us-east-1/workloads/test apply

terraform -chdir=envs/us-east-1/workloads/prod init -backend-config=../../../../backend.hcl
terraform -chdir=envs/us-east-1/workloads/prod apply
```

## 5. Validate Egress

After workload VPC deployment:

- Launch a private test instance or ECS task in an app subnet.
- Confirm outbound HTTPS works.
- Confirm the instance/task has no public IP.
- Confirm NAT Gateways exist only in the Network account.
- Confirm data subnets have no `0.0.0.0/0` route.
- Confirm workload TGW attachments propagate to the egress TGW route table.
