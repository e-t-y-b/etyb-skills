---
title: Microsoft Purview
description: Unified data governance + DLP + insider risk + AI Hub. Replaces older Azure Purview branding. Classification, sensitivity labels, lineage, eDiscovery.
product:
  name: Microsoft Purview
  stack: azure
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, database-architect, ai-ml-engineer, healthcare-architect]
  authoritative_url: https://learn.microsoft.com/purview/
  notes: "Unified data governance + DLP + insider risk + AI Hub; replaces older Azure Purview branding."
---

## What it is

Microsoft Purview is the unified data governance suite (2024+ consolidation) — Data Map, Data Catalog, Information Protection (sensitivity labels), DLP, Insider Risk Management, Communication Compliance, eDiscovery, **AI Hub** (visibility into AI prompts + risky AI usage). Canonical reference: [Purview docs](https://learn.microsoft.com/purview/).

## When to use

Pick Purview when:

- **Regulated data** — PII / PCI / PHI classification + DLP enforcement.
- **Cross-data-source governance** — Azure + AWS + on-prem + SaaS in one catalog.
- **AI-aware DLP** — monitor prompts to [Azure OpenAI](/stacks/azure/azure-openai/) / [Foundry](/stacks/azure/foundry-agents/) for sensitive data leakage (AI Hub).
- **Compliance Manager** — assessment + control mapping for SOC 2 / HIPAA / GDPR / etc.

## 2025-2026 currency anchors

- **Consolidation** (2024+) — older Azure Purview branding subsumed; one Purview portal at purview.microsoft.com.
- **AI Hub** (2025+) — visibility into AI prompts, risky AI usage, sensitive data flowing to AI.
- **Built-in classifiers** for PII / PCI / PHI; custom regex / dictionary / ML model classifiers.
- **Sensitivity labels** — visual marking + encryption + DLP policy attachment.
- **Lineage tracking** across pipelines + apps + DBs.
- **Sensitive data discovery integration** with [Defender for Cloud](/stacks/azure/defender-for-cloud/) CSPM Premium.

## Patterns + anti-patterns

### Pattern: Classify before encrypting

Purview discovers data → sensitivity labels applied → DLP enforces. Encrypting unclassified data is fine, but you can't enforce DLP without classification.

### Pattern: Lineage tracking for regulated data

When PHI flows from EHR → FHIR service → analytics pipeline → ML model → app, Purview lineage shows the path. Auditor's first question: "where does this data go?" Lineage answers.

### Pattern: AI Hub on every AI workload

Prompts to Azure OpenAI / Foundry contain user data — sometimes PII / PHI. AI Hub monitors; DLP enforces; risky usage surfaces. Defense in depth alongside Content Safety.

### Pattern: Compliance Manager assessment + evidence

Map controls (HIPAA technical safeguards, SOC 2 CC, etc.) to Azure implementations; collect evidence (Activity Log exports, Defender alerts, Policy compliance) into Compliance Manager.

### Anti-pattern: PHI / PII in unclassified data stores

Classify before storing. Sensitivity labels applied; DLP enforces.

### Anti-pattern: Purview without Defender CSPM Premium

Both surfaces show classified data findings; together they're more powerful (Defender adds attack-path-aware sensitive data findings).

### Anti-pattern: Prompt logging without redaction or classification

User prompts contain PII / confidential. Redact at app layer; AI Hub + DLP on prompt logs as defense in depth.

## Gotchas

- **Initial scan time** on large estates — days for full classification.
- **Custom classifier accuracy** depends on training data — validate before relying on DLP enforcement.
- **Cross-tenant scope** — Purview is workforce-tenant-scoped by default; multi-tenant orgs plan accordingly.
- **Pricing** has multiple components — Data Map, Information Protection, Insider Risk Management, eDiscovery, AI Hub — read the model.

## Cross-references

- [Defender for Cloud](/stacks/azure/defender-for-cloud/) — sensitive data discovery overlap
- [Azure OpenAI](/stacks/azure/azure-openai/) / [AI Foundry](/stacks/azure/ai-foundry/) — AI Hub monitors prompts
- [Healthcare Architect on Azure](/stacks/azure/healthcare-architect/) — PHI classification
- [Security Engineer on Azure](/stacks/azure/security-engineer/) — DLP design
- [Database Architect on Azure](/stacks/azure/database-architect/) — classification on data stores
- [Purview docs](https://learn.microsoft.com/purview/)
- [Purview AI Hub](https://learn.microsoft.com/purview/ai-microsoft-purview)
