---
title: Defender for Cloud
description: CSPM + CWPP. Plans bill per-resource per-hour — scope carefully. AI Security Posture, Defender for AI Services, API Security Posture among recent additions.
product:
  name: Defender for Cloud
  stack: azure
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, devops-engineer, sre-engineer]
  authoritative_url: https://learn.microsoft.com/azure/defender-for-cloud/
  notes: "CSPM + CWPP plans evolve quarterly; AI Security Posture extended to GCP Vertex 2026."
---

## What it is

Microsoft Defender for Cloud is Azure's CSPM (Cloud Security Posture Management) + CWPP (Cloud Workload Protection Platform) — secure score, regulatory compliance, threat detection per workload type. Plans bill per-resource per-hour. Canonical reference: [Defender for Cloud docs](https://learn.microsoft.com/azure/defender-for-cloud/).

## When to use

Always — at minimum **CSPM Foundational** (free) at tenant level. CSPM Premium and per-workload plans (Servers / Containers / Storage / Databases / App Service / Key Vault / AI / APIs / etc.) scoped to where data sensitivity + threat model justify.

## 2025-2026 currency anchors

- **CSPM Foundational** — free; secure score, basic recommendations.
- **CSPM Premium** — $$$ per workload; attack path analysis, regulatory compliance, sensitive data discovery.
- **Defender for AI Services** — Azure OpenAI / Foundry threat detection (prompt injection, abuse).
- **API Security Posture** (CSPM Premium) — GA; Defender for APIs adds runtime protection.
- **Sensitive data scanning** (CSPM Premium) — now covers Azure file shares GA, blob containers, databases — discovers PII without sampling.
- **Attack path analysis** — visualizes chains of vulnerabilities → likely attacker path. Now includes compromised Entra OAuth apps.
- **AI security posture** (CSPM Premium) extends to **GCP Vertex AI** — multicloud AI discovery + attack path analysis.
- **Unified SecOps portal** merges Defender for Cloud + Defender XDR + [Sentinel](/stacks/azure/sentinel/) (2024-25).

## Patterns + anti-patterns

### Pattern: Scoped plan enablement via Azure Policy

```
- CSPM Foundational: tenant-wide (free)
- CSPM Premium: management-group "Production"
- Defender for Servers Plan 2: RGs with environment=prod
- Defender for Containers: production AKS clusters
- Defender for Storage: storage accounts with customer data
- Defender for Databases: DBs with PII / regulated data
- Defender for Key Vault: every Key Vault (low cost, high value)
- Defender for Resource Manager: every subscription (control-plane attacks)
- Defender for AI Services: Azure OpenAI / Foundry endpoints
```

Use Azure Policy assignments at MG/RG scope, not blanket-on at subscription.

### Pattern: Defender + Sentinel unified workflow

Defender for Cloud detects → alerts flow to Sentinel via connector → Sentinel correlates with other sources → incident → playbook → response.

### Pattern: Secure Score as the KPI

Track trend over time. Recommendations have remediation steps + estimated impact on score. Drive improvement.

### Anti-pattern: Blanket-on every plan

Defender plans bill per-resource per-hour. Enabling Defender for Servers Plan 2 across a multi-thousand-resource subscription is a budget event. **Run `az security pricing list` before flipping a plan on at large scale.**

### Anti-pattern: Ignoring Defender recommendations

Secure Score doesn't improve itself. Track, prioritize, remediate.

### Anti-pattern: All-off in production

CSPM Foundational is free. There's no reason not to have it. Per-workload plans for production = standard hygiene.

## Gotchas

- **Per-resource pricing** — review every time a plan is enabled at higher scope.
- **Plan availability per region** — verify in current docs; rolls out unevenly.
- **Sensitive data scanning takes time** — initial discovery can take days on large estates.
- **Attack path analysis quality** depends on what's enabled — more signals = better paths.

## Cross-references

- [Microsoft Sentinel](/stacks/azure/sentinel/) — SIEM that consumes Defender alerts
- [Microsoft Purview](/stacks/azure/microsoft-purview/) — data classification source
- [Security Engineer on Azure](/stacks/azure/security-engineer/) — full plan design
- [Azure OpenAI](/stacks/azure/azure-openai/) — Defender for AI Services target
- [Defender for Cloud overview](https://learn.microsoft.com/azure/defender-for-cloud/defender-for-cloud-introduction)
