# AWS Landing Zone and AWS-GCP HA VPN Project Report

## 1. Executive Summary

This project builds a Terraform-managed AWS multi-account landing zone with centralized egress and hybrid connectivity to Google Cloud through AWS Transit Gateway and GCP HA VPN.

The current implementation is suitable for a technical demo, mentor review, and job approval discussion. It demonstrates the core capabilities expected from a cloud/network infrastructure engineer:

- AWS Organizations-aligned account separation.
- Centralized Network account with Transit Gateway and egress VPC.
- Dev and Prod workload VPCs attached to Transit Gateway.
- Dedicated Transit Gateway route table for hybrid VPN traffic.
- AWS-GCP HA VPN with dynamic BGP routing.
- Repeatable Terraform deployment and destroy workflow.
- Operational handover documentation and route table workbook artifacts.

The design is intentionally stronger than a simple lab, but it should still be presented as a demo/MVP rather than a fully enterprise-hardened production platform.

## 2. Architecture Overview

The platform follows a hub-and-spoke model.

| Area | Purpose |
| --- | --- |
| Management account | AWS Organizations, account governance, bootstrap identity |
| Network account | Transit Gateway, route tables, centralized egress, VPN attachments |
| Security account | Security baseline and delegated security services |
| Log Archive account | Central logging baseline |
| Dev/Test/Prod accounts | Workload VPCs attached to the central Transit Gateway |
| GCP project | HA VPN gateway, Cloud Router, BGP peers, firewall rules |

Traffic patterns:

- Workload app subnets route `0.0.0.0/0` to Transit Gateway.
- Transit Gateway sends Internet-bound traffic to the Network account egress VPC.
- Egress VPC sends outbound traffic through NAT Gateway and Internet Gateway.
- AWS-GCP private traffic uses a dedicated TGW VPN route table and BGP propagation.
- Dev and Prod attachments propagate into the VPN route table so GCP can reach workload CIDRs.
- VPN attachments propagate into Dev/Prod route tables so AWS workloads can learn GCP CIDRs.

## 3. Terraform Implementation Review

### What Is Implemented Well

- Terraform stacks are separated by responsibility: organization baseline, logging, security, network, workloads, and AWS-GCP VPN.
- Reusable modules exist for deploy roles, logging baseline, security baseline, Transit Gateway, egress VPC, and workload VPC.
- Transit Gateway default association and propagation are disabled, which is the right pattern for controlled route domains.
- TGW route tables are separated into egress, nonprod, prod, and vpn route domains.
- Workload VPCs do not create NAT Gateways by default; centralized egress is used instead.
- AWS Customer Gateway IPs for GCP are derived from the Terraform-managed GCP HA VPN gateway interfaces, avoiding stale static IPs.
- VPN uses BGP instead of static routes, which is the correct direction for hybrid routing.
- Terraform variables mark VPN PSKs as sensitive.
- `.gitignore` excludes Terraform state, tfvars, plans, crash logs, and override files.
- Documentation exists for deployment, handover, naming, SCP/RCP design, and route table review.

### Review Findings

| Severity | Finding | Impact | Recommendation |
| --- | --- | --- | --- |
| High | Local Terraform state is still used for stack output sharing in several places. | Good for demo, but not safe for multi-user production workflows. State can go stale or be lost. | Move to S3 backend with DynamoDB locking and KMS encryption. Use remote state or SSM Parameter Store as the cross-stack output contract. |
| Medium | VPN PSKs are passed through local `terraform.tfvars`. | Ignored by Git, but secrets still exist in local files and Terraform state. | For production, store PSKs in AWS Secrets Manager or SSM SecureString and avoid committing or sharing state files. |
| Medium | `outputs/` is not ignored. | Generated Excel, PNG, and DOCX artifacts can be accidentally committed. They may contain environment identifiers. | Either add `outputs/` to `.gitignore` or move only sanitized artifacts into `docs/`. |
| Medium | The demo permits broad GCP firewall protocols from AWS CIDRs, including UDP and SCTP. | Useful for testing, but too open for production. | Restrict to exact demo/test protocols or application ports. |
| Medium | Web subnets are named and route to IGW, but `map_public_ip_on_launch` is false. | This is not wrong, but can confuse readers because they may expect public web subnets to auto-assign public IPs. | Document the intent or rename as public-ingress subnets only if they are meant to host public resources later. |
| Low | Some naming is still partly demo-oriented, especially the GCP network default usage. | Acceptable for demo, less polished for production. | Use a dedicated GCP VPC and keep the naming convention consistently applied. |
| Low | Validate/plan results are partly based on local terminal execution, not CI. | Demo evidence is manual. | Add CI later for `terraform fmt`, `terraform validate`, TFLint, Checkov, and secret scanning. |

## 4. Demo Readiness Assessment

This project is demo-ready if the goal is to show practical capability to a mentor or interviewer.

Recommended demo narrative:

1. Show the account and folder structure.
2. Explain why Network account owns TGW, egress, and VPN.
3. Show TGW route table separation: egress, nonprod, prod, vpn.
4. Explain Dev and Prod workload VPC attachments.
5. Show AWS-GCP HA VPN Terraform design and how GCP public VPN IPs feed AWS Customer Gateways.
6. Show the validation result: four VPN tunnels UP and BGP routes learned.
7. Show connectivity test from a private EC2 instance through TGW/NAT to the Internet.
8. Show private connectivity test between AWS workload CIDR and GCP private CIDR if the test VM still exists.
9. Close with production hardening steps.

For a mentor approval demo, do not over-focus on enterprise add-ons such as full CI/CD, centralized SIEM integration, or secrets rotation. Mention them as next steps instead.

## 5. Cost and Cleanup Guidance

Resources that should be destroyed after demo if not actively needed:

- AWS-GCP VPN stack.
- NAT Gateways and Elastic IPs.
- EC2 instances, GCP VMs, unattached EBS disks.
- Temporary test security group rules or firewall rules.

Resources that can usually remain with little or no direct cost:

- AWS Organizations OUs.
- IAM roles and policies.
- Documentation and sanitized example files.
- VPCs, subnets, route tables, and security groups when no NAT, VPN, endpoints, or compute resources remain.

Recommended demo cleanup order:

1. `envs/us-east-1/aws-gcp-vpn`
2. `envs/us-east-1/workloads/prod`
3. `envs/us-east-1/workloads/dev`
4. `envs/us-east-1/network`

Leave org, logging, and security baseline in place unless the goal is a full reset.

## 6. Security and Git Push Review

The repository is mostly safe to push if only tracked/sanitized files are committed.

Safe to commit:

- Terraform modules and stack definitions.
- `.terraform.lock.hcl` files.
- `.auto.tfvars.example` and `terraform.tfvars.example` files with placeholder values only.
- Markdown documentation in `docs/`.
- Sanitized architecture diagrams or reports that do not expose secrets.

Do not commit:

- `terraform.tfvars`
- `*.tfstate`
- `*.tfstate.backup`
- `tfplan`, `*.tfplan`, `*.plan`, `*.out`
- `.terraform/`
- Any AWS access keys, GCP service account JSON files, VPN PSKs, or temporary STS credentials.
- Generated artifacts in `outputs/` unless they are reviewed and intentionally sanitized.

Before pushing:

```powershell
git status --short
git diff --check
git diff --cached --check
git ls-files --others --exclude-standard
```

Optional but recommended:

```powershell
terraform fmt -check -recursive
```

Run `terraform validate` in the major stack directories when credentials and provider initialization are available.

## 7. Production Hardening Roadmap

The next production-grade improvements should be incremental:

1. Move Terraform state to S3 with DynamoDB locking and KMS encryption.
2. Replace local state references with remote-state or SSM Parameter Store output contracts.
3. Store VPN PSKs in Secrets Manager or SSM SecureString.
4. Add deployment modes such as `skeleton`, `egress`, `hybrid`, and `full` to control cost.
5. Add CI checks for formatting, validation, static analysis, policy checks, and secret scanning.
6. Tighten GCP firewall and AWS security group rules to exact protocol and port requirements.
7. Add VPC Flow Logs and log retention policies for network troubleshooting.
8. Add architecture diagrams and route table exports as sanitized documentation artifacts.

## 8. Final Assessment

Overall, the project is strong for a mentor/job approval demo. It shows real cloud engineering depth: multi-account thinking, centralized networking, TGW route segmentation, hybrid VPN, BGP, Terraform modularity, and operational awareness.

The main message should be:

> This is a working landing zone demo with production-oriented architecture. It is intentionally scoped for review, and the next step is enterprise hardening through remote state, CI/CD, secrets management, and stricter network controls.

