# AWS Multi-Account Landing Zone

Terraform skeleton for an enterprise-lean AWS landing zone using Control Tower for account governance and Terraform for network, logging, security, and workload foundations.

Default design:

- Region: `us-east-1`
- Deployment identity: CI/CD assumes `LandingZoneDeployRole` in each managed account
- Egress model: centralized NAT-only egress in the Network account
- Account model: Management, Security, Log Archive, Network, Shared Services, Dev, Test, Prod
- Naming standard: `<cloud>-<region>-<type>-<app>-<env>-<zone>-<inst>`

## Account Responsibilities

| Account | Responsibilities |
| --- | --- |
| Management | AWS Organizations, Control Tower, billing, org-level Terraform |
| Security | Delegated admin for security services and audit access |
| Log Archive | Organization CloudTrail, VPC Flow Logs, ALB logs, central S3 log buckets |
| Network | Transit Gateway, Egress VPC, NAT Gateways, RAM shares |
| Shared Services | CI/CD runners, artifact services, shared tools |
| Dev/Test/Prod | Workload VPCs and application primitives |

## Repository Layout

```text
envs/us-east-1/
  org-baseline/       # OUs, SCPs, RAM sharing, account metadata
  logging/            # Organization CloudTrail and central buckets
  security-baseline/  # GuardDuty/Security Hub delegated admin
  network/            # Transit Gateway and centralized egress VPC
  aws-gcp-vpn/        # AWS to GCP HA VPN through Transit Gateway
  workloads/
    dev/
    test/
    prod/
modules/
  iam-deploy-role/
  logging-baseline/
  network/
    egress-vpc/
    transit-gateway/
    workload-vpc/
  security-baseline/
```

## Prerequisites

1. Enable or configure AWS Control Tower in the Management account.
2. Enroll existing accounts where possible and create missing accounts with Account Factory.
3. Create or bootstrap `LandingZoneDeployRole` in every target account.
4. Create an S3/DynamoDB Terraform backend. Use `backend.example.hcl` as the template.
5. Copy `accounts.auto.tfvars.example` to each stack that needs account IDs and replace placeholders.

## Deployment Order

Run each stack from its directory:

```powershell
terraform init -backend-config=..\..\..\backend.example.hcl
terraform plan
terraform apply
```

Recommended order:

1. `envs/us-east-1/org-baseline`
2. `envs/us-east-1/logging`
3. `envs/us-east-1/security-baseline`
4. `envs/us-east-1/network`
5. `envs/us-east-1/workloads/shared-services`
6. `envs/us-east-1/workloads/dev`
7. `envs/us-east-1/workloads/test`
8. `envs/us-east-1/workloads/prod`
9. `envs/us-east-1/aws-gcp-vpn`

For VPN, apply `network` first to create `vpn_route_table_id`, then apply Dev/Prod workloads so their attachments propagate into the VPN route table before applying `envs/us-east-1/aws-gcp-vpn`.

Convenience scripts are available from the repository root:

```powershell
.\scripts\validate.ps1 -Init
.\scripts\deploy.ps1 -PlanOnly
.\scripts\deploy.ps1
```

See `docs/ACCOUNT_DEPLOYMENT_MATRIX.md` for the account-by-account deployment matrix.
See `docs/HANDOVER_RUNBOOK.md` for operational handover, validation, destroy order, and troubleshooting.
See `docs/NAMING_CONVENTION.md` for naming rules, examples, exceptions, and rename-risk notes.

## Centralized Egress Flow

Workload private subnets route `0.0.0.0/0` to Transit Gateway. The Transit Gateway sends outbound Internet traffic to the Network account Egress VPC. The Egress VPC routes traffic to NAT Gateway and then Internet Gateway.

No NAT Gateway is created in workload accounts by default.

## Validation Checklist

- CI/CD can assume `LandingZoneDeployRole` in every account.
- Dev/Test/Prod VPCs have TGW attachments.
- Private app subnets route `0.0.0.0/0` to TGW.
- Egress VPC TGW subnets route `0.0.0.0/0` to NAT Gateway.
- No NAT Gateway exists outside the Network account.
- CloudTrail and VPC Flow Logs land in the Log Archive bucket.
- Dev/Test cannot route to Prod unless explicitly added later.
- GCP HA VPN learns Dev/Prod routes through the dedicated TGW VPN route table.
