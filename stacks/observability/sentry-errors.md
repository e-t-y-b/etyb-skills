---
title: Sentry Errors
description: Deduplicated error capture across services — fingerprint-based grouping, Issue Owners routing, release/deploy correlation.
product:
  name: Sentry Errors
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, security-engineer, sre-engineer]
  authoritative_url: https://docs.sentry.io/product/issues/
  notes: "Dedup + Issue Owners stable; SDK 8.x ergonomics changed (2024); source maps require Debug IDs."
---

## What it is

Sentry Errors is the canonical dedicated error-tracking product — captures exceptions from app code, deduplicates by stack trace fingerprint, assigns to teams via Issue Owners, correlates errors with releases. See [docs.sentry.io/product/issues](https://docs.sentry.io/product/issues/).

## When to use

**Add Sentry early** in product lifecycle. Errors compound silently; finding them in logs after the fact is wasted MTTR. Add it before you add deep APM.

Sentry is complementary to APM/metrics, not a replacement. Pair with [Datadog APM](/stacks/observability/datadog-apm/) or [Grafana Cloud](/stacks/observability/grafana-cloud/) for traces/metrics.

## 2025-2026 currency anchors

- **SDK 8.x** ergonomics changed (2024) — `instrumenter: "otel"` for OTel integration; OTel SpanProcessor merges OTel + Sentry traces.
- **Issue Owners** with file/path/URL-based rules — routes errors to teams.
- **Release correlation** — every error tagged with `release`; surface regressions.

## Patterns

- **OTel + Sentry integration** — `instrumenter: "otel"` so OTel spans flow into Sentry.
- **Issue Owners file** — like CODEOWNERS:
  ```
  path:src/checkout/*     #checkout-team
  url:https://api.example.com/v1/payments*  #payments-team
  ```
- **`beforeSend` hook** — redact PII before transmission (auth headers, cookies).
- **Release tag every event** — `release: process.env.SERVICE_VERSION`.

## Anti-patterns

- **No Issue Owners configured** — Sentry becomes an unowned-issue dumpster.
- **No release correlation** — regressions invisible.
- **PII in error context** — request bodies + headers — use `beforeSend` to redact.

## Gotchas

- **Server-side scrubbing** rules apply regardless of client config. Pair with `beforeSend` for defense-in-depth.
- **Fingerprinting can over-collapse** distinct errors — manual ungrouping available.

## Cross-references

- [Sentry Performance](/stacks/observability/sentry-performance/)
- [Sentry Replay](/stacks/observability/sentry-replay/)
- [Sentry Debug IDs](/stacks/observability/sentry-debug-ids/) (source maps)
- PII scrubbing patterns → [security-engineer overlay](/stacks/observability/security-engineer/)
- Authoritative: [docs.sentry.io/product/issues](https://docs.sentry.io/product/issues/)
