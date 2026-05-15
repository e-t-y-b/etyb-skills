---
title: Security Hub
description: "AWS unified security findings — next-gen (re:Invent 2025) with near-real-time risk analytics, auto-aggregation across GuardDuty/Inspector/Macie/CSPM, one year of historical trends."
product:
  name: Security Hub
  stack: aws
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, devops-engineer]
  authoritative_url: https://docs.aws.amazon.com/securityhub/
  notes: "Re:Invent 2025 overhaul — near-real-time risk analytics, cross-region aggregation, auto-aggregation across detection services."
---

## What it is

AWS Security Hub is the unified security-findings aggregator — automatically pulls findings from GuardDuty, Inspector, Macie, IAM Access Analyzer, Config, third-party tools (via partner integrations), and applies industry-standard frameworks (PCI DSS, CIS, NIST, AFSBP).

Canonical surface: [docs.aws.amazon.com/securityhub](https://docs.aws.amazon.com/securityhub/).

## When to use

Mandatory in every production AWS account. Configuration decisions:
- Enable in every account; delegate admin to Security Tooling account.
- AFSBP (AWS Foundational Security Best Practices) standard at minimum.
- Auto-aggregate to Security Tooling account.

## 2025-2026 currency anchors

- **Re:Invent 2025 overhaul** — near-real-time risk analytics, risk-scored prioritization, cross-region aggregation, one year of historical trends.
- **Auto-aggregation** across [GuardDuty](/stacks/aws/guardduty/), Inspector, Macie, IAM Access Analyzer, Config, third-party tools.
- **Custom action workflows** → EventBridge → SOAR / ticketing.
- **Industry-standard frameworks**: PCI DSS, CIS, NIST, AFSBP.

## Patterns

### Default for production accounts

- Security Hub enabled in every account.
- **AFSBP (AWS Foundational Security Best Practices)** standard enabled.
- Findings auto-aggregated to Security Tooling account (delegated admin).
- Custom actions → EventBridge → ticketing (Jira, ServiceNow) or paging (PagerDuty).
- Cross-region aggregation to a single monitoring region.

### Frameworks to enable

- **AFSBP** — always.
- **CIS AWS Foundations Benchmark** — common compliance baseline.
- **PCI DSS** — if handling card data; pair with [`/stacks/aws/fintech-architect/`](/stacks/aws/fintech-architect/) overlay.
- **NIST 800-53** — federal/regulated industries.

### Triage workflow

Every finding must have:
- An **owner** (team).
- A **SLA** (P1 24h, P2 1wk, P3 1mo).
- A **triage outcome** (remediate, accept-risk-with-justification, false-positive).

Findings without owners pile up and become noise.

### Custom insights

Build custom dashboards / insights for org-specific patterns:
- Findings by tag (Application, Environment).
- Findings by severity over time.
- Top-10 noisy accounts / services.

## Anti-patterns

- **Security Hub disabled.** SCP should make this impossible; verify.
- **Findings ignored.** Every finding needs an owner, SLA, triage outcome.
- **One person reviewing all findings.** Distribute to service owners.
- **Auto-resolve without context.** Don't suppress unless you understand the finding.
- **Only AFSBP, no other frameworks for regulated workloads.** Layer compliance-specific standards.

## Gotchas

- **Security Hub free tier** is limited; full features need paid tier per region per finding type.
- **Cross-region aggregation** requires explicit setup.
- **Findings have ASFF (AWS Security Finding Format)** — a unified schema.
- **Custom actions** require EventBridge wiring; not zero-config.
- **Re:Invent 2025 overhaul** — features and pricing are post-cutoff for many LLMs; verify current state.

## Cross-references

- [`/stacks/aws/guardduty/`](/stacks/aws/guardduty/) — threat detection findings
- [`/stacks/aws/iam/`](/stacks/aws/iam/) — Access Analyzer findings
- [`/stacks/aws/cloudtrail/`](/stacks/aws/cloudtrail/) — audit trail backing many findings
- [`/stacks/aws/security-engineer/`](/stacks/aws/security-engineer/) — role view; full detective-control posture
- [Security Hub User Guide](https://docs.aws.amazon.com/securityhub/latest/userguide/)
