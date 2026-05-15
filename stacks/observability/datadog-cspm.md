---
title: Datadog CSPM / CWPP
description: Cloud Security Posture Management (CSPM) + Cloud Workload Protection Platform (CWPP) inside the Datadog Security product line.
product:
  name: Datadog CSPM/CWPP
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, devops-engineer]
  authoritative_url: https://docs.datadoghq.com/security/
  notes: "Cloud Security surface unified (CSPM + CWPP); competes with Wiz, Lacework, Aqua, Sysdig, Prisma Cloud."
---

## What it is

**CSPM** continuously checks cloud accounts (AWS, GCP, Azure) against benchmarks — CIS, AWS Foundational, custom rules. Surfaces misconfigurations: public S3 buckets, IAM keys with `*:*` permissions, unencrypted EBS volumes, etc.

**CWPP** is runtime security on workloads — containers, hosts. File integrity monitoring, process behavior anomalies, network connection anomalies, vulnerability scanning.

Both surfaces inside Datadog Security. See [docs.datadoghq.com/security](https://docs.datadoghq.com/security/).

## When to use

Pick DD CSPM/CWPP when:
- Datadog is already your observability platform.
- Your security tooling needs aren't deep (mature SOC teams pick Wiz or Prisma Cloud).
- You want correlation: a CWPP runtime alert pivots to the [APM trace](/stacks/observability/datadog-apm/) that ran the suspicious process.

Don't pick if:
- You have a dedicated SOC running Wiz / Lacework / Prisma Cloud / Sysdig Secure — overlap is high.
- You need agentless CSPM-only — Wiz's strength.
- Compliance demands a specialized CWPP — Aqua, Sysdig Secure offer deeper container runtime defense.

## 2025-2026 currency anchors

- **CSPM + CWPP unified surface** (2024-2025) — was separate products.
- **CIEM (Cloud Infrastructure Entitlement Management)** added 2025 — IAM least-privilege analysis.
- **Vulnerability detection for container images** — SBOM-based; integrates with CI pipeline.

## Patterns

- **CSPM rule sets per cloud account** — AWS Foundational + CIS + custom.
- **CWPP via DD Agent + system-probe** — eBPF-based runtime detection.
- **Pivot from runtime alert to APM trace** — DD's correlation strength.

## Anti-patterns

- **DD CSPM + Wiz CSPM** in the same org — double-cost, double-noise. Pick one.
- **CWPP without `runtime security` enabled on Agent** — false sense of coverage.
- **No tuning of out-of-box rules** — alert fatigue.

## Gotchas

- **Agent footprint** for CWPP requires `system-probe` DaemonSet with `CAP_SYS_ADMIN`. PSS-incompatible by default.
- **CIEM analysis depth varies by cloud** — AWS most mature; GCP and Azure catching up.
- **License model** is separate from APM — review the security-tier pricing before enabling.

## Cross-references

- DD ASM (App Security) → [datadog-asm](/stacks/observability/datadog-asm/)
- Security overlay (PII, audit logs, SIEM vs APM) → [security-engineer overlay](/stacks/observability/security-engineer/)
- DD APM correlation → [datadog-apm](/stacks/observability/datadog-apm/)
- Authoritative: [docs.datadoghq.com/security](https://docs.datadoghq.com/security/)
