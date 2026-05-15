---
title: Cloud Armor
description: GCP's WAF + DDoS at the edge — OWASP CRS 3.3, JA4 fingerprinting, hierarchical policies, Adaptive Protection ML. Sits in front of GLB / regional ALB.
product:
  name: Cloud Armor
  stack: gcp
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, devops-engineer, backend-architect]
  authoritative_url: https://cloud.google.com/armor/docs
  notes: "JA4 fingerprinting GA, hierarchical policies GA, body inspection ceiling raised in 2025; ModSecurity CRS 3.3 GA."
---

## What it is

Cloud Armor is Google's WAF + DDoS layer in front of Global External Application Load Balancers (and now Regional internal ALBs, GA). Features in 2026:

- Preconfigured WAF rules (OWASP Top 10 via ModSecurity CRS 3.3)
- Body inspection up to 64 KB
- Rate limiting per IP / cookie / header / **JA4**
- JA4 / JA3 TLS fingerprinting
- Hierarchical security policies (org / folder / project)
- Organization-scoped address groups
- Adaptive Protection (ML-based DDoS)
- Bot Management (reCAPTCHA Enterprise integration)
- Regional internal ALB support

Authoritative reference: [cloud.google.com/armor/docs](https://cloud.google.com/armor/docs).

## When to use

Cloud Armor in front of every public-facing HTTPS endpoint. Compose with:
- **GLB** (Global External Application Load Balancer) — public web/API
- **Regional internal ALB** — internal HTTP services
- **Cloud CDN** — edge caching + Cloud Armor protection at the same layer

Don't try to replace Cloud Armor with app-layer rate limiting alone — edge enforcement is more efficient and protects upstream.

## 2025-2026 currency anchors

- **JA4 fingerprinting GA** — TLS client identification beyond JA3; rate-limit / block by JA4.
- **Hierarchical security policies GA** — org / folder / project policy inheritance; central security team enforces baseline rules across all projects.
- **Body inspection up to 64 KB** for all preconfigured WAF rules (up from earlier 8 KB).
- **ModSecurity CRS 3.3** preconfigured WAF rule set GA.
- **Adaptive Protection** (ML-based DDoS) GA — produces signed signatures during attack.
- **Regional internal ALB support** GA.

## Patterns

### Policy structure

A Cloud Armor policy is a list of rules evaluated in order by priority:

```bash
# Block known bad IPs (priority 1000)
gcloud compute security-policies rules create 1000 \
  --security-policy=api-protection \
  --src-ip-ranges=192.0.2.0/24 \
  --action=deny-403

# OWASP CRS SQLi (priority 1100)
gcloud compute security-policies rules create 1100 \
  --security-policy=api-protection \
  --expression="evaluatePreconfiguredExpr('sqli-v33-stable')" \
  --action=deny-403

# OWASP CRS XSS (priority 1110)
gcloud compute security-policies rules create 1110 \
  --security-policy=api-protection \
  --expression="evaluatePreconfiguredExpr('xss-v33-stable')" \
  --action=deny-403

# Rate limit unauthenticated traffic (priority 2000)
gcloud compute security-policies rules create 2000 \
  --security-policy=api-protection \
  --expression="true" \
  --action=throttle \
  --rate-limit-threshold-count=100 \
  --rate-limit-threshold-interval-sec=60 \
  --conform-action=allow \
  --exceed-action=deny-429 \
  --enforce-on-key=IP

# JA4 rate limit (priority 2100)
gcloud compute security-policies rules create 2100 \
  --security-policy=api-protection \
  --expression="request.ja4 == 't13d1715h2_5b57614c22b0_3d5424432f57'" \
  --action=throttle \
  --rate-limit-threshold-count=10 \
  --rate-limit-threshold-interval-sec=60 \
  --enforce-on-key=JA4
```

### Hierarchical policies

Apply security policies at org / folder level to enforce baseline rules across all projects:

```bash
gcloud compute security-policies create --global-organization-policy \
  baseline-org-policy \
  --type=CLOUD_ARMOR_INTERNAL_SERVICE \
  --organization=123456789
```

Project-level policies layer additional rules. This is the 2026 pattern for "central security team enforces baselines, app teams customize per service."

### Adaptive Protection

ML-based DDoS detection. Enable per policy; produces signed signatures suggesting rules to add during an attack. **Don't auto-apply suggested rules without review** — false positives can lock out legitimate users.

## Anti-patterns

- **Cloud Armor with only rate-limiting** — needs OWASP CRS + JA4 + Adaptive at minimum.
- **No Cloud Armor on public Cloud Run / GKE Ingress** — inviting bots and DDoS.
- **Auto-applying Adaptive Protection suggestions** without review — false-positive risk.
- **No hierarchical baseline** — every team writes their own rules; baseline drift.
- **No logging of denied requests** — Cloud Armor logs to Cloud Logging; verify they're flowing.

## Gotchas

- **Body inspection limit** applies per rule type — verify your custom expression doesn't exceed.
- **Rate limit keys**: `IP`, `IP_AND_ALL_REQ_HEADERS`, `HTTP_PATH`, `JA4`, `JA3`, etc. Pick deliberately.
- **reCAPTCHA Enterprise** integration requires extra setup; useful against headless bot traffic.
- **Preview mode** lets you observe without enforcing — use during rule tuning.

## Cross-references

- Related: [Cloud CDN](/stacks/gcp/cloud-cdn/), [Cloud Run](/stacks/gcp/cloud-run/), [GKE](/stacks/gcp/gke/), [VPC](/stacks/gcp/vpc/) (Global LB sits in front of services)
- Roles: [security-engineer on GCP](/stacks/gcp/security-engineer/), [backend-architect on GCP](/stacks/gcp/backend-architect/), [devops-engineer on GCP](/stacks/gcp/devops-engineer/)
- Authoritative: [cloud.google.com/armor/docs](https://cloud.google.com/armor/docs)
