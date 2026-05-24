# Account Deployment Matrix

Use this matrix to decide which AWS account each Terraform stack should deploy into.

## Rule Of Thumb

- Deploy **organization resources** from the Management account.
- Deploy **central logs** into the Log Archive account, but create the organization trail from the Management account.
- Deploy **security services** into the Security account.
- Deploy **Transit Gateway, RAM shares, centralized NAT, and egress VPC** into the Network account.
- Deploy each workload VPC into its own workload account.
- Do not create NAT Gateways in workload accounts.

## Stack Matrix

| Terraform stack | Primary account | Extra account access | What it deploys |
| --- | --- | --- | --- |
| `envs/us-east-1/org-baseline` | Management | Security, Log Archive, Network, Shared Services, Dev, Test, Prod via `OrganizationAccountAccessRole` | OUs, SCPs, RAM org sharing, `LandingZoneDeployRole` bootstrap |
| `envs/us-east-1/logging` | Log Archive | Management | Central S3 log bucket and organization CloudTrail |
| `envs/us-east-1/security-baseline` | Security | None | GuardDuty detector and optional Security Hub |
| `envs/us-east-1/network` | Network | None | Transit Gateway, RAM share, Egress VPC, NAT Gateways, TGW route tables |
| `envs/us-east-1/workloads/shared-services` | Shared Services | Network | Shared-services VPC, TGW attachment, route association/propagation |
| `envs/us-east-1/workloads/dev` | Dev | Network | Dev VPC, TGW attachment, route association/propagation |
| `envs/us-east-1/workloads/test` | Test | Network | Test VPC, TGW attachment, route association/propagation |
| `envs/us-east-1/workloads/prod` | Prod | Network | Prod VPC, TGW attachment, route association/propagation |

## How The Provider Choice Works

Each stack has a primary AWS provider:

```hcl
provider "aws" {
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::<target-account-id>:role/${var.deploy_role_name}"
  }
}
```

If a stack must change a resource owned by another account, it declares a provider alias. For example, workload stacks deploy the VPC in Dev/Test/Prod, but associate the TGW attachment to a route table owned by the Network account:

```hcl
provider "aws" {
  alias  = "network"
  region = var.region

  assume_role {
    role_arn = "arn:aws:iam::${var.network_account_id}:role/${var.deploy_role_name}"
  }
}
```

## Required Account IDs

Copy `accounts.auto.tfvars.example` to each stack as `accounts.auto.tfvars`, then replace placeholders with real account IDs:

```hcl
management_account_id      = "111111111111"
security_account_id        = "222222222222"
log_archive_account_id     = "333333333333"
network_account_id         = "444444444444"
shared_services_account_id = "555555555555"
dev_account_id             = "666666666666"
test_account_id            = "777777777777"
prod_account_id            = "888888888888"
```

## Account Selection By Service

| Service or resource | Deploy in account |
| --- | --- |
| AWS Organizations, OUs, SCPs | Management |
| Control Tower setup/enrollment | Management |
| `LandingZoneDeployRole` | Every managed account |
| CloudTrail organization trail | Management, writing to Log Archive bucket |
| Central S3 log bucket | Log Archive |
| GuardDuty delegated/security baseline | Security |
| Transit Gateway | Network |
| RAM share for TGW | Network |
| Egress VPC | Network |
| NAT Gateway | Network only |
| Dev VPC | Dev |
| Test VPC | Test |
| Prod VPC | Prod |
| CI runners/artifact tooling | Shared Services |
| ALB/ECS/RDS/app resources | The target workload account, usually Dev/Test/Prod |

## Deployment Order

1. Management: Control Tower landing zone and account enrollment.
2. Management: `org-baseline`.
3. Log Archive and Management: `logging`.
4. Security: `security-baseline`.
5. Network: `network`.
6. Shared Services: `workloads/shared-services`.
7. Dev/Test/Prod: workload stacks.
