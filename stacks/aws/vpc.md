---
title: VPC
description: AWS networking — private subnets without NAT, VPC endpoints (gateway + interface), VPC Lattice for L7 service-to-service, Transit Gateway for multi-VPC, PrivateLink for service-as-a-service.
product:
  name: VPC
  stack: aws
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, devops-engineer, security-engineer, backend-architect]
  authoritative_url: https://docs.aws.amazon.com/vpc/
  notes: "VPC Lattice — custom domains (Nov 2025), IPv6 dual-stack (Aug 2025), Resource Gateway IP config (Oct 2025). Surface keeps growing."
---

## What it is

Amazon VPC is the network primitive — your isolated virtual network with private subnets, public subnets, route tables, security groups, NACLs, NAT gateways, VPC endpoints, and Transit Gateway / Direct Connect for hybrid. **VPC Lattice** is the modern L7 service-to-service mesh.

Canonical surface: [docs.aws.amazon.com/vpc](https://docs.aws.amazon.com/vpc/).

## When to use

Every AWS workload runs in a VPC — the question is how to design it.

| Need | VPC pattern |
|---|---|
| Workload with no internet egress | Private subnets + VPC endpoints, no NAT |
| Public-facing web app | Public subnets for ALB/NLB only; private for app; private for data |
| Hybrid (on-prem connection) | Direct Connect or VPN to Transit Gateway |
| Multi-account network | Transit Gateway hub; spoke accounts attach |
| East-west service traffic (same VPC) | Service Connect ([ECS](/stacks/aws/ecs/)) or VPC CNI direct ([EKS](/stacks/aws/eks/)) |
| East-west cross-VPC / cross-account | VPC Lattice |
| Service-as-a-service across accounts | PrivateLink |

## 2025-2026 currency anchors

- **VPC Lattice matured** — IPv6 dual-stack (Aug 2025), custom domains (Nov 2025), configurable Resource Gateway IPs (Oct 2025). Default L7 service-to-service surface with IAM auth.
- **Gateway endpoints** for S3 and DynamoDB are **free** — route-table-based, no per-hour cost.
- **Interface endpoints (PrivateLink)** for AWS services — paid (~$7/mo per endpoint per AZ + data), but enable private access to virtually every AWS service.
- **Transit Gateway** mature — multi-VPC, multi-account, multi-region hub.
- **Route 53 Profiles** — share Route 53 private zone configs across accounts.

## Patterns

### Standard VPC layout

```
+--------------------------------------------------------------+
|                    Public Subnets (DMZ)                       |
|              (ALB / NLB / NAT Gateway only)                   |
+--------------------------------------------------------------+
                              |
+--------------------------------------------------------------+
|                    Private App Subnets                        |
|              (EC2 / ECS tasks / EKS pods / Lambda)            |
+--------------------------------------------------------------+
                              |
+--------------------------------------------------------------+
|                    Private Data Subnets                       |
|              (RDS / ElastiCache / EBS-backed services)        |
+--------------------------------------------------------------+
```

App subnets reach the internet via NAT (or via VPC endpoints + Network Firewall egress filtering). Data subnets have **no route to the internet** — period.

### NAT cost discipline

NAT Gateway: ~$0.045/hr + $0.045/GB processed. Multi-AZ HA = 3x. Cross-AZ data transfer ($0.01/GB each way) compounds.

**For Lambda-only or container-only architectures with no outbound internet need**, put resources in private subnets without NAT and use VPC endpoints for AWS service traffic:
- Gateway endpoints (free) for **S3** and **DynamoDB**.
- Interface endpoints for everything else.

This is the single biggest 2026 VPC cost lever for serverless / container workloads.

### Security Groups vs NACLs

| | Security Groups | NACLs |
|---|---|---|
| **Layer** | Stateful, per-ENI | Stateless, per-subnet |
| **Default** | Deny all inbound; allow all outbound | Allow all both directions |
| **Use** | Primary access control | Defense-in-depth supplemental layer |

Security Groups do the work. NACLs are coarse-grained defense in depth (e.g., "deny port 22 on the data subnet's NACL"). Don't try to manage detailed traffic flow via NACLs.

### VPC endpoint policies

Restrict an interface endpoint to specific principals or resources:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:*",
    "Resource": "*",
    "Condition": {
      "StringEquals": { "aws:PrincipalOrgID": "o-xxxxxx" }
    }
  }]
}
```

Combined with [SCPs/RCPs](/stacks/aws/security-engineer/), endpoint policies define the data perimeter.

### VPC Lattice

For L7 service-to-service across VPCs / accounts:
- Service-level IAM auth (no mTLS required).
- Configurable resource gateway IPs.
- Custom domains.
- IPv6 dual-stack.

Replaces self-managed service mesh for many AWS-native workloads. App Mesh is in maintenance — VPC Lattice is the new path.

### Transit Gateway

Hub-and-spoke for multi-VPC and multi-account. Centralize:
- Inter-VPC routing.
- On-prem connections via VPN / Direct Connect.
- Egress filtering through a centralized inspection VPC ([AWS Network Firewall](/stacks/aws/security-engineer/)).

### Subnet sizing

- **/24 (256 IPs)** is the typical minimum per subnet — leaves room for EKS pods, Lambda ENIs.
- **/22 or larger** when running EKS at scale with VPC CNI (each pod is an IP).
- **Custom CIDR** for non-overlapping ranges across VPCs that will peer or share via TGW.

### Network Firewall

Stateful, deep-packet-inspection firewall for VPCs. Use for:
- Egress filtering (deny outbound to anything not on an allowlist).
- Intrusion detection (Suricata-compatible rules).
- Centralized inspection in a shared services VPC + Transit Gateway.

Costs scale with traffic; not for every VPC. Pick when compliance demands it (FedRAMP, HIPAA-heavy) or threat profile justifies it.

## Anti-patterns

- **"NAT Gateway in every AZ for everything."** $0.045/hr × 3 AZs + data processing + cross-AZ traffic = $100s/month minimum, $1000s/month routinely. If outbound internet isn't needed, **don't have one.**
- **Workload subnets in public subnets.** App and data tiers belong in private subnets; only ALB/NLB/NAT in public.
- **Default VPC for production workloads.** Build a deliberate VPC with private subnets, endpoints, no NAT unless needed.
- **One VPC for all environments.** Separate dev/staging/prod into separate accounts (and separate VPCs by extension).
- **Detailed traffic flow controls in NACLs.** Use security groups.
- **Hard-coded IP allowlists in security groups for AWS services.** Use VPC endpoints + endpoint policies.
- **VPC peering for everything.** Transit Gateway is cleaner at >2 VPCs.

## Gotchas

- **Cross-AZ data transfer ($0.01/GB each way)** compounds. Audit chatty cross-AZ traffic via VPC Flow Logs.
- **NAT Gateway max bandwidth** is 100 Gbps per Gateway — usually plenty, but verify for high-volume egress.
- **Interface endpoint pricing per AZ** — 3 AZs = 3x. Plan placement carefully.
- **Private hosted zones** require VPC association — Route 53 Profiles simplify multi-account sharing.
- **Default ENI quotas** vary by instance type and per region — large EKS clusters exhaust ENI capacity.
- **VPC Flow Logs ingestion cost** can be significant at scale — route via Firehose → S3 for cheaper retention.

## Cross-references

- [`/stacks/aws/lambda/`](/stacks/aws/lambda/) — VPC attach and endpoints
- [`/stacks/aws/ecs/`](/stacks/aws/ecs/) — Service Connect for east-west
- [`/stacks/aws/eks/`](/stacks/aws/eks/) — VPC CNI for pod networking
- [`/stacks/aws/s3/`](/stacks/aws/s3/) — Gateway endpoint
- [`/stacks/aws/dynamodb/`](/stacks/aws/dynamodb/) — Gateway endpoint
- [`/stacks/aws/security-engineer/`](/stacks/aws/security-engineer/) — endpoint policies, RCPs, Network Firewall
- [`/stacks/aws/system-architect/`](/stacks/aws/system-architect/) — role view; topology decisions
- [VPC Lattice docs](https://docs.aws.amazon.com/vpc-lattice/)
