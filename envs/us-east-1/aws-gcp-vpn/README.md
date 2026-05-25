# AWS to GCP HA VPN with BGP

This environment records the AWS Network account to GCP HA VPN design:

- GCP HA VPN gateway in `us-central1`
- GCP Cloud Router with BGP ASN `65001`
- Two AWS Customer Gateways, one for each Terraform-managed GCP HA VPN interface
- Two AWS Site-to-Site VPN connections using dynamic routing attached to the Network account Transit Gateway
- Four GCP VPN tunnels and four BGP peers
- AWS TGW VPN route table association and propagation into selected workload TGW route tables
- GCP firewall rule allowing test traffic from explicit AWS CIDR ranges

Default naming follows `<cloud>-<region>-<type>-<app>-<env>-<zone>-<inst>`, for example `gcp-usc1-havpn-net-shared-prv-001`.

## Why four tunnels

AWS creates two tunnels for every Site-to-Site VPN connection. GCP HA VPN has two gateway interfaces. This config creates two AWS VPN connections, one per GCP interface, and uses all four AWS tunnels.

## Secrets

Do not commit real pre-shared keys. Copy `terraform.tfvars.example` to `terraform.tfvars` locally and replace the four `CHANGE_ME` values.

## Deploy order

First apply the Network stack so the dedicated TGW VPN route table exists:

```powershell
cd D:\LandingZoneV3\envs\us-east-1\network
terraform init
terraform plan `
  -out=tfplan `
  -var="network_account_id=<network-account-id>" `
  -var="shared_services_account_id=<shared-services-account-id>" `
  -var="dev_account_id=<dev-account-id>" `
  -var="prod_account_id=<prod-account-id>"
terraform apply tfplan
terraform output vpn_route_table_id
```

Then re-apply the workload stacks. They read TGW IDs from the Network stack state, including `vpn_route_table_id`, so you only need the account IDs:

```powershell
cd D:\LandingZoneV3\envs\us-east-1\workloads\dev
terraform plan `
  -out=tfplan `
  -var="dev_account_id=<dev-account-id>" `
  -var="network_account_id=<network-account-id>"
terraform apply tfplan

cd D:\LandingZoneV3\envs\us-east-1\workloads\prod
terraform plan `
  -out=tfplan `
  -var="prod_account_id=<prod-account-id>" `
  -var="network_account_id=<network-account-id>"
terraform apply tfplan
```

Finally deploy the GCP-AWS VPN stack. It reads the TGW ID, VPN route table ID, and workload route table IDs from the Network stack state:

```powershell
cd D:\LandingZoneV3\envs\us-east-1\aws-gcp-vpn
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Local credentials

By default this project uses your active AWS credentials directly and Google Application Default Credentials.

For AWS, authenticate with a user or profile that can read and manage VPC VPN resources:

```bash
aws sts get-caller-identity
```

For GCP, create Application Default Credentials:

```bash
gcloud auth application-default login
gcloud config set project <PROJECT_ID>
```

For this landing zone, deploy AWS resources in the Network account. Set:

```hcl
aws_assume_role_arn = "arn:aws:iam::<network-account-id>:role/LandingZoneDeployRole"
```

or run Terraform with credentials already assumed into the Network account.

By default this stack reads the `network` stack local state:

```hcl
data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "${path.module}/../network/terraform.tfstate"
  }
}
```

Run the `network` stack first so it creates and outputs `vpn_route_table_id`. Dev, Prod, and AWS-GCP VPN then consume that output automatically. You can still override TGW IDs with variables if you intentionally need to point at another Network stack.

Customer Gateway public IPs are not input variables. Terraform reads them from `google_compute_ha_vpn_gateway.this.vpn_interfaces` so AWS always points at the GCP HA VPN gateway created in this stack.

GCP resource names are effectively immutable. Apply naming changes during a clean redeploy or a planned maintenance window.

Use explicit CIDRs for AWS-to-GCP firewall source ranges:

```hcl
aws_allowed_source_cidrs = [
  "10.0.0.0/16",
  "10.10.0.0/16",
  "10.30.0.0/16"
]
```

Use `gcp_advertised_cidrs` to control what GCP advertises to AWS over BGP. The default is `10.128.0.0/20`.

## Import existing resources

If these resources were created manually in the consoles, write matching values in `terraform.tfvars`, then import the existing resources before running a normal plan.

Example import commands:

```bash
terraform import google_compute_ha_vpn_gateway.this projects/<PROJECT_ID>/regions/us-central1/vpnGateways/gcp-usc1-havpn-net-shared-prv-001
terraform import google_compute_router.this projects/<PROJECT_ID>/regions/us-central1/routers/gcp-usc1-cr-net-shared-prv-001
terraform import google_compute_external_vpn_gateway.aws projects/<PROJECT_ID>/global/externalVpnGateways/gcp-usc1-extvpngw-net-shared-prv-001

terraform import aws_customer_gateway.gcp_if0 cgw-xxxxxxxxxxxxxxxxx
terraform import aws_customer_gateway.gcp_if1 cgw-yyyyyyyyyyyyyyyyy
terraform import aws_vpn_connection.if0 vpn-xxxxxxxxxxxxxxxxx
terraform import aws_vpn_connection.if1 vpn-yyyyyyyyyyyyyyyyy

terraform import google_compute_vpn_tunnel.this["if0_tunnel1"] projects/<PROJECT_ID>/regions/us-central1/vpnTunnels/gcp-usc1-vpntun-net-shared-prv-001
terraform import google_compute_vpn_tunnel.this["if0_tunnel2"] projects/<PROJECT_ID>/regions/us-central1/vpnTunnels/gcp-usc1-vpntun-net-shared-prv-002
terraform import google_compute_vpn_tunnel.this["if1_tunnel1"] projects/<PROJECT_ID>/regions/us-central1/vpnTunnels/gcp-usc1-vpntun-net-shared-prv-003
terraform import google_compute_vpn_tunnel.this["if1_tunnel2"] projects/<PROJECT_ID>/regions/us-central1/vpnTunnels/gcp-usc1-vpntun-net-shared-prv-004
```

After importing, run `terraform plan` and adjust config until Terraform shows no unexpected replacement. VPN resources are sensitive to tunnel ordering, PSKs, and BGP inside IPs, so review any planned replacement carefully.
