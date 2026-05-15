---
title: OTel Semantic Conventions
description: The versioned attribute schema — pin a version, migrate in lockstep. Mixing versions across services breaks dashboards silently.
product:
  name: OTel Semantic Conventions
  stack: observability
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer, sre-engineer]
  authoritative_url: https://opentelemetry.io/docs/specs/semconv/
  notes: "1.28 → 1.32 reshaped HTTP/RPC/GenAI attributes; pin a version repo-wide; rotate via Collector transform during migration."
---

## What it is

Semantic Conventions (semconv) are the standardized attribute names that telemetry signals carry. `service.name`, `http.request.method`, `db.system`, `messaging.destination.name`, `gen_ai.system` — all defined by the OTel semconv spec at [opentelemetry.io/docs/specs/semconv](https://opentelemetry.io/docs/specs/semconv/).

Versions ship every quarter. Most are additive, but some rotate names — `http.method` (legacy) → `http.request.method` (1.28+). When services across your stack emit different versions, your dashboards split data across two attribute names and look broken.

## When to use

**Pin a semconv version repo-wide** and upgrade in lockstep across services. Set the version in your shared OTel SDK config or via a wrapper module that every service imports. Don't let individual services float forward independently.

Use the OTel-provided semconv constants (e.g., `from opentelemetry.semconv.resource import ResourceAttributes`) rather than hardcoded strings — when you bump the SDK, the constants point at the current version's names.

## 2025-2026 currency anchors

- **semconv 1.28** (mid-2024) stabilized HTTP, RPC, messaging, DB attributes — the big rotation. This is the baseline for 2026 work.
- **semconv 1.29-1.32** (2025-2026) added GenAI (`gen_ai.*`), Kafka, Kubernetes, CI/CD conventions. GenAI is the most active area — see [OTel GenAI](/stacks/observability/otel-genai/).
- **Attribute rename window for HTTP** was 1.20 → 1.25 → 1.28 incremental. The names rotated:

| Concept | Legacy (≤1.20) | Current (1.28+) |
|---|---|---|
| HTTP method | `http.method` | `http.request.method` |
| HTTP status | `http.status_code` | `http.response.status_code` |
| HTTP URL | `http.url` | `url.full` |
| HTTP scheme | `http.scheme` | `url.scheme` |
| HTTP user agent | `http.user_agent` | `user_agent.original` |
| Messaging dest | `messaging.destination` | `messaging.destination.name` |

- **`http.route` and `db.statement` unchanged** across versions — safe references.

## Patterns

### Pin and lockstep

Declare the semconv version in a shared service-bootstrap module. Bump it as a coordinated PR across the monorepo (or via a fanout PR set across poly-repo).

### Migration via Collector transform

When services straddle versions during migration, run a transform processor at the Collector that renames legacy attributes to current:

```yaml
processors:
  transform/semconv_migration:
    trace_statements:
      - context: span
        statements:
          - set(attributes["http.request.method"], attributes["http.method"]) where attributes["http.method"] != nil
          - set(attributes["http.response.status_code"], attributes["http.status_code"]) where attributes["http.status_code"] != nil
          - set(attributes["url.full"], attributes["http.url"]) where attributes["http.url"] != nil
          - delete_key(attributes, "http.method")
          - delete_key(attributes, "http.status_code")
          - delete_key(attributes, "http.url")
```

Run this for 1-2 quarters during migration, then sunset.

### Track which services are on which version

Add a custom resource attribute `semconv.version=1.28` per service. Aggregate as a label on a dashboard — see migration progress at a glance.

## Anti-patterns

- **Hardcoded attribute strings** in app code — when you bump SDK, your tests pass but the dashboards break because no one updated the strings.
- **Letting one service float to a new semconv version** without a Collector transform or a coordinated bump — dashboards split.
- **Custom attributes that collide with semconv names** — `app.user.id` is fine; `user.id` conflicts with reserved-ish namespaces.
- **No `service.version` resource attribute** — can't filter dashboards by deploy, can't see deploy regressions.

## Gotchas

- **Auto-instrumentation libraries may lag the SDK** in adopting new semconv. Check the auto-instrumentation package version against the SDK version when names look wrong.
- **The `_total` suffix is added by Prometheus exporters** automatically — don't put it in OTel metric names yourself (`http.server.request.count`, not `http.server.request.count.total`).
- **GenAI semconv is still moving.** Pin 1.32 for stability; expect agent-specific conventions to land 2026-2027.
- **Some vendors mix legacy + current** in their UI — Datadog displays both `http.method` and `http.request.method` if both arrive. Doesn't help when your dashboard query filters by one.

## Cross-references

- Per-language SDK setup with semconv constants → [backend-architect overlay](/stacks/observability/backend-architect/)
- Collector transform processor → [otel-collector](/stacks/observability/otel-collector/)
- LLM-specific GenAI conventions → [otel-genai](/stacks/observability/otel-genai/)
- Authoritative: [opentelemetry.io/docs/specs/semconv](https://opentelemetry.io/docs/specs/semconv/), [GitHub semantic-conventions](https://github.com/open-telemetry/semantic-conventions)
