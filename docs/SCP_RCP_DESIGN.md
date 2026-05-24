# SCP and RCP Design

This design uses both authorization policy types in AWS Organizations:

- **SCP** limits what IAM principals inside member accounts can do.
- **RCP** limits how resources inside member accounts can be accessed, especially from principals outside the organization.

RCPs require AWS Organizations all-features mode and the RCP policy type enabled.

## OU Layout

```text
Root
├── Security
│   ├── Security-Tooling Account
│   └── Log-Archive Account
├── Infrastructure
│   ├── Network Account
│   └── Shared-Services Account
├── Workloads
│   ├── Prod
│   │   └── Marketing-Prod Account
│   └── NonProd
│       └── Marketing-Dev Account
└── Data
    └── Data-Platform Account
```

## Policy Attachment Matrix

| Attach target | SCPs | RCPs |
| --- | --- | --- |
| Root | `DenyLeaveOrganization`, `DenyDisableCloudTrail`, `DenyUnsupportedRegions`, `DenyRootUserActions` | `DenyInsecureTransport`, `DenyExternalAccessUnlessOrg`, `DenyPublicS3Access` |
| Security OU | Root SCPs plus `ProtectSecurityServices` | Root RCPs |
| Infrastructure OU | Root SCPs plus `RestrictNetworkChangesOutsideNetworkRole` | Root RCPs |
| Workloads OU | Root SCPs plus `DenyWorkloadNatGateway`, `DenyDirectInternetGatewayChanges`, `DenySecurityToolDisable` | Root RCPs plus `DenyCrossOrgResourceAccess` |
| Prod OU | Workloads SCPs plus `DenyProdDeleteCriticalResources`, `RequireEncryptionForDataServices` | Workloads RCPs plus stricter S3/KMS/Secrets rules |
| NonProd OU | Workloads SCPs plus `LimitExpensiveServices` | Workloads RCPs |
| Data OU | Root SCPs plus `ProtectDataServices`, `RequireDataEncryption` | Root RCPs plus strict S3/KMS/Secrets external access controls |

## Baseline SCPs

### Root: `DenyLeaveOrganization`

Attach to Root.

Purpose: prevent member accounts from leaving the organization.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyLeaveOrganization",
      "Effect": "Deny",
      "Action": "organizations:LeaveOrganization",
      "Resource": "*"
    }
  ]
}
```

### Root: `DenyRootUserActions`

Attach to Root.

Purpose: prevent routine root usage in member accounts.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyRootUserActions",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:PrincipalArn": "arn:aws:iam::*:root"
        }
      }
    }
  ]
}
```

### Root: `DenyUnsupportedRegions`

Attach to Root. Keep global services exempted.

Purpose: restrict deployments to approved regions. Current default approved region is `us-east-1`.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyUnsupportedRegions",
      "Effect": "Deny",
      "NotAction": [
        "a4b:*",
        "acm:*",
        "aws-marketplace:*",
        "budgets:*",
        "ce:*",
        "chime:*",
        "cloudfront:*",
        "config:*",
        "controltower:*",
        "globalaccelerator:*",
        "health:*",
        "iam:*",
        "importexport:*",
        "kms:*",
        "mobileanalytics:*",
        "networkmanager:*",
        "organizations:*",
        "pricing:*",
        "route53:*",
        "route53domains:*",
        "s3:GetAccountPublicAccessBlock",
        "s3:ListAllMyBuckets",
        "shield:*",
        "sts:*",
        "support:*",
        "trustedadvisor:*",
        "waf:*",
        "waf-regional:*",
        "wafv2:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": [
            "us-east-1"
          ]
        }
      }
    }
  ]
}
```

### Root: `DenyDisableCloudTrail`

Attach to Root.

Purpose: protect organization audit trail.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyCloudTrailTampering",
      "Effect": "Deny",
      "Action": [
        "cloudtrail:DeleteTrail",
        "cloudtrail:PutEventSelectors",
        "cloudtrail:StopLogging",
        "cloudtrail:UpdateTrail"
      ],
      "Resource": "*"
    }
  ]
}
```

## Infrastructure SCPs

### Infrastructure OU: `AllowCentralNetworkOnly`

Attach to Infrastructure OU, then exempt or scope operational permissions to approved network roles.

Purpose: central network account owns TGW, NAT, VPN, and shared routing.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyNetworkChangesExceptApprovedRoles",
      "Effect": "Deny",
      "Action": [
        "ec2:CreateTransitGateway",
        "ec2:DeleteTransitGateway",
        "ec2:CreateTransitGatewayRoute",
        "ec2:DeleteTransitGatewayRoute",
        "ec2:CreateNatGateway",
        "ec2:DeleteNatGateway",
        "ec2:CreateVpnConnection",
        "ec2:DeleteVpnConnection"
      ],
      "Resource": "*",
      "Condition": {
        "ArnNotLike": {
          "aws:PrincipalArn": [
            "arn:aws:iam::*:role/LandingZoneDeployRole",
            "arn:aws:iam::*:role/NetworkAdminRole"
          ]
        }
      }
    }
  ]
}
```

## Workload SCPs

### Workloads OU: `DenyWorkloadNatGateway`

Attach to Workloads OU.

Purpose: force outbound traffic through centralized egress in Network account.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyNatGatewayInWorkloadAccounts",
      "Effect": "Deny",
      "Action": [
        "ec2:CreateNatGateway",
        "ec2:DeleteNatGateway"
      ],
      "Resource": "*"
    }
  ]
}
```

### Workloads OU: `DenySecurityToolDisable`

Attach to Workloads OU.

Purpose: prevent application teams from disabling security controls.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyDisableSecurityServices",
      "Effect": "Deny",
      "Action": [
        "guardduty:DeleteDetector",
        "guardduty:DisassociateFromAdministratorAccount",
        "guardduty:StopMonitoringMembers",
        "securityhub:DisableSecurityHub",
        "config:DeleteConfigurationRecorder",
        "config:StopConfigurationRecorder"
      ],
      "Resource": "*"
    }
  ]
}
```

### Prod OU: `DenyProdDeleteCriticalResources`

Attach to Prod OU.

Purpose: require break-glass or pipeline exception for destructive production actions.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyProdDestructiveActionsExceptBreakGlass",
      "Effect": "Deny",
      "Action": [
        "rds:DeleteDBCluster",
        "rds:DeleteDBInstance",
        "ec2:DeleteVpc",
        "ec2:DeleteSubnet",
        "elasticloadbalancing:DeleteLoadBalancer",
        "kms:ScheduleKeyDeletion",
        "secretsmanager:DeleteSecret"
      ],
      "Resource": "*",
      "Condition": {
        "ArnNotLike": {
          "aws:PrincipalArn": [
            "arn:aws:iam::*:role/BreakGlassAdminRole",
            "arn:aws:iam::*:role/LandingZoneDeployRole"
          ]
        }
      }
    }
  ]
}
```

### NonProd OU: `LimitExpensiveServices`

Attach to NonProd OU.

Purpose: reduce accidental cost in development accounts.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyExpensiveOrOutOfScopeServicesInNonProd",
      "Effect": "Deny",
      "Action": [
        "redshift:*",
        "emr:*",
        "sagemaker:*",
        "es:CreateDomain",
        "opensearch:CreateDomain"
      ],
      "Resource": "*"
    }
  ]
}
```

## Security OU SCPs

### Security OU: `ProtectSecurityServices`

Attach to Security OU.

Purpose: protect security delegated-admin services from tampering.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ProtectSecurityAdministration",
      "Effect": "Deny",
      "Action": [
        "guardduty:DisableOrganizationAdminAccount",
        "securityhub:DisableOrganizationAdminAccount",
        "config:DeleteAggregationAuthorization",
        "config:DeleteConfigurationAggregator"
      ],
      "Resource": "*",
      "Condition": {
        "ArnNotLike": {
          "aws:PrincipalArn": [
            "arn:aws:iam::*:role/SecurityAdminRole",
            "arn:aws:iam::*:role/LandingZoneDeployRole"
          ]
        }
      }
    }
  ]
}
```

## Data OU SCPs

### Data OU: `ProtectDataServices`

Attach to Data OU when `Data-Platform` is created.

Purpose: protect AI/data platform resources.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyDataDestructiveActionsExceptApprovedRoles",
      "Effect": "Deny",
      "Action": [
        "s3:DeleteBucket",
        "s3:DeleteBucketPolicy",
        "kms:ScheduleKeyDeletion",
        "secretsmanager:DeleteSecret",
        "opensearch:DeleteDomain",
        "glue:DeleteDatabase",
        "glue:DeleteTable"
      ],
      "Resource": "*",
      "Condition": {
        "ArnNotLike": {
          "aws:PrincipalArn": [
            "arn:aws:iam::*:role/DataAdminRole",
            "arn:aws:iam::*:role/LandingZoneDeployRole"
          ]
        }
      }
    }
  ]
}
```

## Baseline RCPs

### Root: `DenyInsecureTransport`

Attach to Root.

Purpose: deny access to supported resource types when the request is not using TLS.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

### Root: `DenyExternalAccessUnlessOrg`

Attach to Root, then test carefully.

Purpose: prevent resource-based policies from granting access to principals outside the organization unless explicitly exempted.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyExternalPrincipalsOutsideOrganization",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringNotEqualsIfExists": {
          "aws:PrincipalOrgID": "o-replace-with-your-org-id"
        },
        "BoolIfExists": {
          "aws:PrincipalIsAWSService": "false"
        }
      }
    }
  ]
}
```

### Root or Workloads OU: `DenyPublicS3Access`

Attach to Root or Workloads OU.

Purpose: deny public S3 access through resource policies.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyPublicS3BucketAccess",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::*",
        "arn:aws:s3:::*/*"
      ],
      "Condition": {
        "StringNotEqualsIfExists": {
          "aws:PrincipalOrgID": "o-replace-with-your-org-id"
        },
        "BoolIfExists": {
          "aws:PrincipalIsAWSService": "false"
        }
      }
    }
  ]
}
```

### Data OU: `DenyExternalKmsAndSecretsAccess`

Attach to Data OU.

Purpose: prevent KMS keys and Secrets Manager secrets from being shared outside the organization.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyExternalAccessToDataSecretsAndKeys",
      "Effect": "Deny",
      "Principal": "*",
      "Action": [
        "kms:*",
        "secretsmanager:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEqualsIfExists": {
          "aws:PrincipalOrgID": "o-replace-with-your-org-id"
        },
        "BoolIfExists": {
          "aws:PrincipalIsAWSService": "false"
        }
      }
    }
  ]
}
```

## Account-Level Exceptions

Use account-level policy attachments sparingly.

| Account | Exception policy | Reason |
| --- | --- | --- |
| Network | Allow network admins and deploy role to manage TGW/NAT/VPN | Network account owns centralized egress |
| Log Archive | Protect log buckets from deletion | Preserve audit evidence |
| Security-Tooling | Allow security admins to configure delegated admin services | Security tooling account owns controls |
| Marketing-Prod | Stricter delete protection | Production stability |
| Marketing-Dev | Cost restrictions | Prevent expensive experiments |
| Data-Platform | Strong external access restrictions | Sensitive data and AI platform boundary |

## Rollout Order

1. Enable SCPs and keep `FullAWSAccess` attached.
2. Attach Root baseline SCPs in report-only/change-window style, one at a time.
3. Attach Workloads OU NAT/security SCPs.
4. Attach Prod and NonProd OU specific SCPs.
5. Enable RCPs and confirm `RCPFullAWSAccess` remains attached.
6. Attach RCPs first to a sandbox OU, then NonProd, then Prod/Data.
7. Monitor CloudTrail, IAM Access Analyzer, Security Hub, and application deploy pipelines after each attachment.
