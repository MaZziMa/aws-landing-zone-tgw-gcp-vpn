# AWS Config Cost Control With AWS Control Tower

AWS Control Tower can enable AWS Config in enrolled accounts to support detective controls, compliance tracking, and centralized configuration history. This can become expensive in accounts with frequent create/update/delete activity, especially ephemeral workloads.

## Recommendation

Do not immediately disable AWS Config across all enrolled accounts.

Use this order:

1. Disable optional detective controls that depend on AWS Config.
2. Keep AWS Config in `Security`, `Log Archive`, `Network`, and `Prod`.
3. Reduce or disable AWS Config in `Dev`, `Sandbox`, and short-lived workload accounts.
4. If you must fully stop AWS Config in an enrolled account, unenroll or unmanage the account first.

## Account Policy

| Account or OU | Recommended AWS Config posture | Reason |
| --- | --- | --- |
| Management | Keep minimal/Control Tower managed | Organization governance |
| Security-Tooling | Keep | Security aggregation and delegated admin |
| Log-Archive | Keep | Central audit/log retention |
| Network | Keep | TGW, NAT, route, VPN change tracking |
| Marketing-Prod | Keep | Production compliance and audit |
| Marketing-Dev | Reduce or stop if cost is high | High churn, lower compliance requirement |
| Shared-Services | Keep or reduce | Depends on CI/CD resource churn |
| Data-Platform | Keep when created | Sensitive data and AI platform governance |
| Sandbox | Prefer unenrolled or stop recorder | Cost control for experiments |

## Option A: Avoid Enabling AWS Config During Setup

If you are still setting up or updating the landing zone, choose not to enable AWS Config unless you need detective controls immediately.

Tradeoff:

- Lower cost.
- No Control Tower detective controls that require AWS Config.
- You can enable AWS Config later.

## Option B: Keep Control Tower Managed, But Reduce Controls

Use this when accounts remain enrolled in Control Tower.

Actions:

- Disable optional detective controls.
- Avoid Security Hub CSPM standards that create many AWS Config rule evaluations until needed.
- Keep only preventive controls and SCPs for the first phase.
- Monitor AWS Config configuration item count per account and Region.

Tradeoff:

- Keeps accounts governed by Control Tower.
- Reduces rule evaluation cost, but configuration item recording may still cost money.

## Option C: Unenroll NonProd/Sandbox, Then Stop AWS Config

Use this for high-churn non-production accounts where AWS Config cost is not justified.

Actions:

1. Unmanage or unenroll the account from AWS Control Tower.
2. Stop the AWS Config recorder in all governed Regions.
3. Optionally delete the recorder and delivery channel if you do not need them.
4. Keep SCPs at the AWS Organizations OU level for baseline restrictions.

Tradeoff:

- Lower cost.
- Control Tower cannot enforce detective controls for that account.
- You must manage security baselines separately.

## Example CLI For One Account And Region

Run only after confirming the account should no longer rely on Control Tower detective controls.

```bash
aws configservice stop-configuration-recorder \
  --configuration-recorder-name default \
  --region us-east-1
```

If the recorder name is not `default`, discover it first:

```bash
aws configservice describe-configuration-recorders \
  --region us-east-1
```

## Multi-Account Automation Pattern

Use a CI/CD job or AWS StackSets with an execution role in each target account.

Inputs:

- Target account IDs
- Target regions
- Recorder names
- Exclusion list: `Security`, `Log-Archive`, `Network`, `Prod`

Safe default:

- Only stop Config in `Sandbox` and `Marketing-Dev`.
- Never stop Config in `Security`, `Log-Archive`, `Network`, or `Marketing-Prod`.

## Guardrail

Before stopping AWS Config, verify:

- No Control Tower detective controls are required for the target account.
- No Security Hub controls depend on Config in that account.
- Audit/compliance owners approve the change.
- CloudTrail remains enabled.
- SCPs still protect critical actions.

## Landing Zone Default For This Project

Recommended phase 1:

- Keep AWS Config in `Security-Tooling`, `Log-Archive`, `Network`, `Marketing-Prod`.
- Disable or avoid AWS Config in `Marketing-Dev` if cost is the priority.
- Do not create `Data-Platform` until needed; when created, keep AWS Config enabled.
