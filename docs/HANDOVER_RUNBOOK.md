# Landing Zone Handover Runbook

This runbook is for operating and demonstrating the AWS Landing Zone with centralized egress and AWS-GCP HA VPN connectivity.

## Architecture Summary

The design uses a hub-and-spoke network model:

- Management account owns AWS Organizations and foundation deployment access.
- Network account owns Transit Gateway, Egress VPC, NAT Gateways, TGW route tables, RAM share, and AWS side of the GCP VPN.
- Dev and Prod workload accounts own workload VPCs and attach to the Network account TGW.
- GCP owns HA VPN Gateway, Cloud Router, VPN tunnels, firewall rules, and BGP peers.

Traffic flows:

- Workload app subnets send `0.0.0.0/0` to TGW.
- TGW sends Internet-bound traffic to the Network account Egress VPC.
- Egress VPC sends outbound traffic through NAT Gateway and Internet Gateway.
- AWS-GCP private traffic uses the dedicated TGW VPN route table and dynamic BGP propagation.

## Account Responsibility Matrix

| Account | Code | Responsibilities |
| --- | --- | --- |
| Management | `mgmt` | Organizations, account governance, Terraform bootstrap identity |
| Log Archive | `log` | Central log storage |
| Security | `sec` | Security baseline and delegated admin services |
| Network | `net` | TGW, egress VPC, NAT, TGW route tables, hybrid VPN |
| Shared Services | `ss` | Optional shared tooling VPC |
| Dev | `dev` | Non-production workload VPC |
| Test | `test` | Optional non-production workload VPC |
| Prod | `prod` | Production workload VPC |

## Deployment Order

Run each stack from its own directory.

```powershell
$env:AWS_PROFILE = "aws-gcp-vpn"
Remove-Item Env:\AWS_ACCESS_KEY_ID -ErrorAction SilentlyContinue
Remove-Item Env:\AWS_SECRET_ACCESS_KEY -ErrorAction SilentlyContinue
Remove-Item Env:\AWS_SESSION_TOKEN -ErrorAction SilentlyContinue
aws sts get-caller-identity
```

Recommended sequence:

1. `envs/us-east-1/org-baseline`
2. `envs/us-east-1/logging`
3. `envs/us-east-1/security-baseline`
4. `envs/us-east-1/network`
5. `envs/us-east-1/workloads/dev`
6. `envs/us-east-1/workloads/prod`
7. `envs/us-east-1/aws-gcp-vpn`

For each stack:

```powershell
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

The workload and VPN stacks currently read Network stack outputs from local Terraform state. In production, replace this with S3 remote state or an SSM Parameter Store output contract.

## Destroy Order

Use reverse dependency order:

1. `envs/us-east-1/aws-gcp-vpn`
2. `envs/us-east-1/workloads/prod`
3. `envs/us-east-1/workloads/dev`
4. `envs/us-east-1/network`

Leave `org-baseline`, `logging`, and `security-baseline` in place unless intentionally resetting the foundation.

## Validation Commands

Format and validate:

```powershell
terraform fmt -check -recursive

cd D:\LandingZoneV3\envs\us-east-1\network
terraform validate

cd D:\LandingZoneV3\envs\us-east-1\workloads\dev
terraform validate

cd D:\LandingZoneV3\envs\us-east-1\workloads\prod
terraform validate

cd D:\LandingZoneV3\envs\us-east-1\aws-gcp-vpn
terraform validate
```

Confirm AWS account identity:

```powershell
aws sts get-caller-identity
```

Assume the Network account deployment role when checking VPNs directly:

```powershell
$role = aws sts assume-role `
  --role-arn arn:aws:iam::<network-account-id>:role/LandingZoneDeployRole `
  --role-session-name check-vpn | ConvertFrom-Json

$env:AWS_ACCESS_KEY_ID = $role.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $role.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN = $role.Credentials.SessionToken
aws sts get-caller-identity
```

Check AWS VPN tunnel status:

```powershell
aws ec2 describe-vpn-connections `
  --region us-east-1 `
  --vpn-connection-ids <vpn-id-1> <vpn-id-2> `
  --query "VpnConnections[*].{VpnId:VpnConnectionId,State:State,Tunnels:VgwTelemetry[*].{OutsideIp:OutsideIpAddress,Status:Status,Message:StatusMessage}}" `
  --output table
```

Expected result: all four tunnels show `UP`, and each tunnel reports learned BGP routes.

## Connectivity Tests

From an EC2 instance in a private app subnet:

```bash
curl https://checkip.amazonaws.com
curl -I https://aws.amazon.com
ping <gcp-private-ip>
curl http://<gcp-private-ip>:8080
```

From a GCP VM:

```bash
ping <aws-private-ip>
curl http://<aws-private-ip>:8080
```

Security groups, NACLs, and GCP firewall rules must allow the tested protocol.

## Troubleshooting

### Wrong AWS Profile or Account

Symptom: AWS CLI cannot find VPN IDs, TGW IDs, or VPC IDs that Terraform just created.

Fix:

```powershell
aws sts get-caller-identity
$env:AWS_PROFILE = "aws-gcp-vpn"
Remove-Item Env:\AWS_ACCESS_KEY_ID -ErrorAction SilentlyContinue
Remove-Item Env:\AWS_SECRET_ACCESS_KEY -ErrorAction SilentlyContinue
Remove-Item Env:\AWS_SESSION_TOKEN -ErrorAction SilentlyContinue
```

Temporary environment credentials override `AWS_PROFILE`, so clear them before switching profiles.

### SSM Offline

Likely causes:

- Instance has no IAM instance profile with `AmazonSSMManagedInstanceCore`.
- Default Host Management Configuration is not enabled or not ready.
- Private subnet cannot reach SSM endpoints or Internet egress.
- Security group or route table blocks outbound HTTPS.

Fix:

- Attach the instance profile.
- Confirm outbound route through TGW to Network NAT or use VPC endpoints for SSM.
- Wait a few minutes and re-check SSM ping status.

### VPN Tunnel Down

Check:

- AWS VPN tunnel outside IPs match the GCP External VPN Gateway interfaces.
- PSKs in Terraform match on both AWS and GCP.
- IKE version is `ikev2`.
- GCP tunnels point to the correct HA VPN gateway interface and peer interface.

### BGP Has No Routes

Check:

- GCP Cloud Router advertises the expected CIDR, for example `10.128.0.0/20`.
- AWS TGW VPN attachments propagate to NonProd and Prod TGW route tables.
- Dev and Prod VPC attachments propagate into the VPN route table.
- BGP ASN values are AWS `64512` and GCP `65001`.

### TGW Route Missing

Check:

- Attachment association is in the correct route table.
- Propagation is enabled on the destination route table.
- The propagated CIDR does not overlap another route.
- Static default routes to egress still point to the egress VPC attachment.

### VPC Destroy Stuck

Common dependencies:

- EC2 instances or ENIs still in the VPC.
- NAT Gateways or EIPs still attached.
- TGW VPC attachment still deleting.
- Security group references or VPC endpoints still present.

Fix by listing and removing dependencies before retrying `terraform destroy`.

### Local State Limitation

This demo uses local state for stack output sharing in some places. If local state is missing or stale, downstream stacks may read old IDs.

Production recommendation:

- Store Terraform state in S3 with DynamoDB locking and KMS encryption.
- Use explicit remote-state data sources or SSM parameters for cross-stack outputs.

## Cost Cleanup

Destroy after demo if not needed:

- AWS-GCP VPN stack.
- NAT Gateways and EIPs in the Network stack.
- EC2 instances, GCP VMs, and unattached EBS disks.

Low or no-cost resources that can usually remain:

- OUs and IAM roles.
- VPCs, subnets, route tables, and security groups when no NAT, VPN, or compute resources remain.
- Documentation and sanitized examples.

## Production Next Steps

- Move all stacks to S3 remote backend with DynamoDB locking.
- Store VPN PSKs in SSM SecureString or Secrets Manager.
- Add CI checks for `terraform fmt`, `terraform validate`, TFLint, Checkov, and secret scanning.
- Add VPC Flow Logs and centralized log retention.
- Add deployment modes such as `skeleton`, `egress`, `hybrid`, and `full` for cost control.
