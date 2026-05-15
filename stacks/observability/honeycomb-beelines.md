---
title: Honeycomb Beelines
description: Honeycomb's legacy per-language SDKs. Superseded by OTel-based instrumentation for 2026 greenfield.
product:
  name: Honeycomb Beelines
  stack: observability
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect]
  authoritative_url: https://docs.honeycomb.io/getting-data-in/
  notes: "Legacy SDKs; OTel-based instrumentation preferred for 2026 greenfield; Beelines still supported for existing installs."
---

## What it is

Beelines are Honeycomb's legacy per-language SDKs (Node, Python, Java, Go, Ruby) for emitting events to Honeycomb directly (not over OTLP). See [docs.honeycomb.io/getting-data-in](https://docs.honeycomb.io/getting-data-in/).

## When to use

For new instrumentation in 2026, **prefer [OpenTelemetry](/stacks/observability/opentelemetry/) SDKs sending OTLP to Honeycomb**. Honeycomb ingests OTLP first-class.

Use Beelines only when:
- You have existing Beelines instrumentation and aren't ready to migrate.
- A language has a Beeline but no mature OTel SDK (rare in 2026).

## 2025-2026 currency anchors

- **Honeycomb OTLP ingest** is fully supported — no reason for new Beelines installs.
- **Beelines still maintained** for existing installs.

## Patterns

- **Migrate to OTel** at the next major service refactor.
- **Pair with [Refinery](/stacks/observability/honeycomb-refinery/)** for tail sampling regardless of SDK.

## Anti-patterns

- **New Beelines installs in 2026** — chooses lock-in over OTel portability.

## Gotchas

- **Beelines + OTel SDK in the same service** — pick one. Double-instrumentation is a footgun.

## Cross-references

- OTel-based instrumentation → [opentelemetry](/stacks/observability/opentelemetry/)
- Honeycomb base → [honeycomb-events](/stacks/observability/honeycomb-events/)
- Authoritative: [docs.honeycomb.io](https://docs.honeycomb.io/)
