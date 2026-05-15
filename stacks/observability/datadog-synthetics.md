---
title: Datadog Synthetics
description: Outside-in API + browser checks from managed global locations — correlated with Datadog APM for end-to-end visibility.
product:
  name: Datadog Synthetics
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, devops-engineer]
  authoritative_url: https://docs.datadoghq.com/synthetics/
  notes: "Per-check pricing; browser >> API; managed locations + private locations stable."
---

## What it is

Datadog Synthetics runs scheduled outside-in checks against your endpoints — **API tests** (HTTP, gRPC, SSL, DNS, TCP, UDP, ICMP) and **browser tests** (Playwright-style multi-step user journeys). Runs from Datadog's managed global locations or your **private locations** (containers you operate). See [docs.datadoghq.com/synthetics](https://docs.datadoghq.com/synthetics/).

Pricing: per-check (API $5/1K runs, browser $12/1K runs). Browser tests cost roughly 2.5x API.

## When to use

Pick DD Synthetics when:
- You're on Datadog and want one-click synthetic → APM trace correlation.
- You need both API and browser, managed and private locations.
- CI integration matters — run tests in PR pipelines.

Alternatives:
- **Checkly** — Playwright + TypeScript + Terraform, often preferred for monitoring-as-code purists.
- **Grafana Cloud Synthetic** — k6-based, global probe network, cheaper.
- **Pingdom / Catchpoint** — legacy, less integrated.

## 2025-2026 currency anchors

- **Managed locations** in 20+ regions globally.
- **Private locations** as Docker containers — useful for monitoring internal-only endpoints.
- **CI integration** with GitHub Actions, GitLab, CircleCI — synthetic-as-code regression gate.

## Patterns

- **API tests for endpoint health** (`GET /health`, JSON contract validation).
- **Browser tests for tier-1 user journeys** (login → search → checkout, multi-step).
- **Run from at least 3 geographic locations** for tier-1 endpoints — catch CDN, ISP, TLS issues.
- **Alert on degradation, not just failure** — checks slower than baseline by 2-3x are worth a ticket.
- **Block deploys on synthetic regression** — synthetic test fails → deploy paused.

## Anti-patterns

- **Synthetic from the same VPC as the app** — misses DNS, CDN, ISP, TLS issues. Always run externally.
- **Single-location synthetic checks** — geographic outages invisible.
- **`GET /health` only** — health endpoint passes while real user flows are broken.
- **Browser tests at 1-minute interval** — bill burn. Use 5-min for tier-1, 15-min for tier-2.

## Gotchas

- Browser tests have a 60s default timeout; raise for complex flows.
- Private locations need persistent network access to Datadog API; egress allowlist required.
- Cookie/session handling in browser tests may need explicit setup for OAuth flows.

## Cross-references

- DD APM trace correlation → [datadog-apm](/stacks/observability/datadog-apm/)
- Alternative tools (Checkly, k6, Grafana Synthetic) → [sre-engineer overlay](/stacks/observability/sre-engineer/) synthetics section
- Authoritative: [docs.datadoghq.com/synthetics](https://docs.datadoghq.com/synthetics/)
