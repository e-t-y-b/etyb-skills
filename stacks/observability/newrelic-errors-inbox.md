---
title: New Relic Errors Inbox
description: Cross-service error triage surface — deduplicates errors, assigns to teams, correlates with deploys for regression detection.
product:
  name: New Relic Errors Inbox
  stack: observability
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, sre-engineer]
  authoritative_url: https://docs.newrelic.com/docs/errors-inbox/
  notes: "Mature; deploy-correlation surface stable; chain SLO burn-rate alerts into Errors Inbox triage workflow."
---

## What it is

New Relic Errors Inbox surfaces errors across services in one queue, deduplicates by fingerprint, assigns to teams, and correlates each error spike with the deploy that introduced it. See [docs.newrelic.com/docs/errors-inbox](https://docs.newrelic.com/docs/errors-inbox/).

## When to use

Pick Errors Inbox when:
- You're on [NR APM](/stacks/observability/newrelic-apm/) and want a single error-triage queue across all services.
- Deploy regression detection matters — Errors Inbox auto-surfaces "errors introduced by deploy X."

Comparable: [Sentry Errors](/stacks/observability/sentry-errors/) is the dedicated alternative with deeper symbolication and replay correlation. Use both if you have both vendors.

## 2025-2026 currency anchors

- **Deploy markers** auto-populate from CI integration; pin to specific commits.
- **Issue Owners** route errors to teams by service / file / path.

## Patterns

- **Chain SLO burn-rate alerts → Errors Inbox** — when a burn-rate fires, triage what's actually breaking via Errors Inbox.
- **Set Issue Owners** per service — don't let errors land unowned.
- **Use deploy correlation** as the first triage step — "what changed."

## Anti-patterns

- **No Issue Owners configured** — Errors Inbox becomes unowned-issue dumpster.
- **Treating every error as paging-worthy** — most are noise; tune to actionable.

## Gotchas

- **Fingerprinting can over-collapse** distinct errors with similar stack traces. Manual ungrouping available.
- **Source map / symbolication quality** drives stack-trace usefulness — verify your build pipeline uploads.

## Cross-references

- NR APM → [newrelic-apm](/stacks/observability/newrelic-apm/)
- Alternative: Sentry Errors → [sentry-errors](/stacks/observability/sentry-errors/)
- SLO + alerting integration → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Authoritative: [docs.newrelic.com/docs/errors-inbox](https://docs.newrelic.com/docs/errors-inbox/)
