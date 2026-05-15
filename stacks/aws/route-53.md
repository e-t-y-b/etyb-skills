---
title: Route 53
description: AWS managed DNS — alias records for AWS resources, health checks for failover, geo / latency routing, Route 53 Profiles for cross-account private zone sharing.
product:
  name: Route 53
  stack: aws
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, devops-engineer, security-engineer]
  authoritative_url: https://docs.aws.amazon.com/route53/
  notes: "Mature DNS surface; Route 53 Profiles is the main new pattern for cross-account private zone sharing."
---

## What it is

Amazon Route 53 is AWS's managed DNS — public hosted zones, private hosted zones (VPC-attached), health checks, latency / geo / weighted / multivalue / failover routing policies. **Route 53 Profiles** share private zone configs across accounts.

Canonical surface: [docs.aws.amazon.com/route53](https://docs.aws.amazon.com/route53/).

## When to use

Every AWS architecture with custom domains uses Route 53 in some form.

## 2025-2026 currency anchors

- **Route 53 Profiles** — share private zone configs across accounts without per-account VPC associations.
- **Route 53 Resolver** for hybrid DNS (on-prem ↔ AWS resolver endpoints).
- Alias records for [CloudFront](/stacks/aws/cloudfront/), [API Gateway](/stacks/aws/api-gateway/), ALB, NLB, S3 static sites.

## Patterns

### Alias vs CNAME

- **Alias** for AWS resources — no charge per resolution; works at apex domain.
- **CNAME** for non-AWS or arbitrary targets; **cannot be set at apex domain** (DNS spec).

### Routing policies

| Policy | Use when |
|---|---|
| **Simple** | Single resource |
| **Weighted** | Blue-green / canary |
| **Latency** | Global apps, route to nearest region |
| **Geo** | Region-specific compliance / content |
| **Failover** | Primary/secondary active-passive |
| **Multivalue answer** | Health-checked round-robin |

### Health checks

For failover routing — when endpoint is unhealthy, secondary takes over.
- **HTTP/HTTPS health check** — basic endpoint check.
- **Calculated health check** — combine multiple child health checks.
- **CloudWatch alarm-based** — health driven by metric.

### Route 53 Profiles

Cross-account private hosted zone sharing — define profile once in network account, associate with VPCs in workload accounts.

### DNSSEC

DNSSEC signing supported on public hosted zones. Required by some regulators; not default.

## Anti-patterns

- **CNAME at apex domain** — DNS spec forbids; use alias.
- **TTL too long** for resources that change frequently — slow failover.
- **TTL too short** for stable resources — excess query cost.
- **No health checks on failover records.** Defeats the point.
- **Public hosted zone for internal resources.** Use private hosted zones.

## Gotchas

- **Hosted zone deletion** requires removing all records first.
- **Private hosted zones** require VPC association — Route 53 Profiles simplify multi-VPC.
- **Latency routing data** depends on AWS's view of network latency.
- **Pricing per million queries** — visible cost at scale.

## Cross-references

- [`/stacks/aws/cloudfront/`](/stacks/aws/cloudfront/) — alias target
- [`/stacks/aws/api-gateway/`](/stacks/aws/api-gateway/) — alias target via custom domain
- [`/stacks/aws/vpc/`](/stacks/aws/vpc/) — private hosted zones, Resolver
- [Route 53 docs](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html)
