# Naming Convention

This project uses the final enterprise naming grammar from the naming workbook:

```text
<cloud>-<region>-<type>-<app>-<env>-<zone>-<inst>
```

Example:

```text
aws-use1-tgw-net-shared-prv-001
```

## Token Rules

| Token | Meaning | Examples |
| --- | --- | --- |
| `cloud` | Cloud provider code | `aws`, `gcp` |
| `region` | Short region code | `use1`, `usc1` |
| `type` | Resource type abbreviation | `vpc`, `snet`, `rtb`, `tgw`, `tgwrt`, `natgw`, `igw`, `cgw`, `vpn`, `havpn`, `cr`, `vpntun` |
| `app` | Application or platform domain | `net`, `workload` |
| `env` | Environment or account scope | `shared`, `dev`, `test`, `prod` |
| `zone` | Tier, role, or placement | `prv`, `plb`, `app`, `dbz`, `tgw`, `vpn`, `egress`, `nonprod`, `prod` |
| `inst` | Three digit sequence | `001`, `002` |

## Current Standards

| Resource | Name |
| --- | --- |
| Transit Gateway | `aws-use1-tgw-net-shared-prv-001` |
| TGW egress route table | `aws-use1-tgwrt-net-shared-egress-001` |
| TGW nonprod route table | `aws-use1-tgwrt-net-shared-nonprod-001` |
| TGW prod route table | `aws-use1-tgwrt-net-shared-prod-001` |
| TGW VPN route table | `aws-use1-tgwrt-net-shared-vpn-001` |
| Egress VPC | `aws-use1-vpc-net-shared-plb-001` |
| Dev workload VPC | `aws-use1-vpc-workload-dev-prv-001` |
| Prod workload VPC | `aws-use1-vpc-workload-prod-prv-001` |
| GCP HA VPN gateway | `gcp-usc1-havpn-net-shared-prv-001` |
| GCP Cloud Router | `gcp-usc1-cr-net-shared-prv-001` |
| GCP VPN tunnel | `gcp-usc1-vpntun-net-shared-prv-001` |

## Exceptions

Some resources do not support names or tags. Examples include Transit Gateway route table associations, propagations, route table associations, and some route resources. For those resources, ownership is tracked through:

- Terraform resource address.
- Parent route table or attachment ID.
- Tags on the parent resource.

GCP resource `name` fields are often immutable. Renaming GCP HA VPN, Cloud Router, VPN tunnels, router interfaces, and BGP peers can force replacement. Apply naming changes to GCP resources during a clean redeploy or a planned maintenance window.
