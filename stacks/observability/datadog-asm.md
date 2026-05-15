---
title: Datadog ASM
description: Application Security Management — agent-side WAF, attacker traces, business-logic abuse detection, IAST.
product:
  name: Datadog ASM
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, backend-architect]
  authoritative_url: https://docs.datadoghq.com/security/application_security/
  notes: "Agent-side WAF + IAST; tied to dd-trace SDK (OTel-only does not get ASM today)."
---

## What it is

Datadog ASM is the application-layer security signal inside the Datadog APM pipeline. It does:
- **Agent-side WAF rules** — OWASP Top 10 patterns, injection attempts, command injection.
- **Attacker traces** — every blocked or detected attack is traceable in [DD APM](/stacks/observability/datadog-apm/).
- **Business logic abuse detection** — account takeover, credential stuffing, scraping.
- **SCA (Software Composition Analysis)** — vulnerable dependencies.
- **Exposed secrets in code**.
- **IAST (Interactive Application Security Testing)** — runtime taint analysis on traced requests.

See [docs.datadoghq.com/security/application_security](https://docs.datadoghq.com/security/application_security/).

## When to use

Pick DD ASM when:
- You're already on [Datadog APM](/stacks/observability/datadog-apm/) and want WAF + AppSec + APM correlated in one UI.
- You don't have a dedicated WAF (Cloudflare, AWS WAF, Imperva, Akamai) and want defense-in-depth at the app layer.

Don't pick if:
- Your WAF strategy is at the edge (Cloudflare / AWS WAF) and you're satisfied — duplicate detection is noise.
- **You're OTel-only** — ASM requires `dd-trace-*` SDK (or [Library Injection v2](/stacks/observability/datadog-apm/)). No OTel equivalent today.

## 2025-2026 currency anchors

- **Library Injection v2 compatibility** — ASM works through the injected `dd-trace`, no separate install.
- **IAST capability** matured 2024-2025 — runtime taint flows traced per request.
- **GenAI attack detection** (prompt injection) emerging 2026; pair with [LLM Observability](/stacks/observability/datadog-llm-observability/).

## Patterns

- **Block mode** for high-confidence rules (SQL injection, command injection).
- **Monitor mode** for novel-pattern detection — surface to SOC, don't block.
- **Pair with edge WAF** for layered defense — edge for volumetric, ASM for app-aware.

## Anti-patterns

- **ASM block-mode on novel rules** without baseline — false-positive cascade blocking legit users.
- **ASM as the only AppSec layer** — edge WAF, dependency scanning, secret scanning all complement.
- **OTel-first stacks pulling in `dd-trace` only for ASM** — operational complexity not always worth it.

## Gotchas

- **OTel-only stacks have no ASM equivalent today**. If you need ASM, you need `dd-trace` (which can run alongside OTel — see [DD APM](/stacks/observability/datadog-apm/)).
- **IAST adds per-request overhead** — measure latency impact before enabling on hot paths.
- **WAF rule updates land via Agent updates** — pin Agent version with rollout cadence.

## Cross-references

- DD APM (the underlying SDK requirement) → [datadog-apm](/stacks/observability/datadog-apm/)
- DD CSPM/CWPP (cloud + runtime security) → [datadog-cspm](/stacks/observability/datadog-cspm/)
- AppSec composition (edge WAF, dep scanning) → [security-engineer overlay](/stacks/observability/security-engineer/)
- Authoritative: [docs.datadoghq.com/security/application_security](https://docs.datadoghq.com/security/application_security/)
