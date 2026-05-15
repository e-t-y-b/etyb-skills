---
title: Sentry Crons
description: Heartbeat monitoring for scheduled jobs — alert when a cron fails to check in. Lightweight alternative to Healthchecks.io.
product:
  name: Sentry Crons
  stack: observability
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, sre-engineer, devops-engineer]
  authoritative_url: https://docs.sentry.io/product/crons/
  notes: "Heartbeat monitoring stable; alternative to Healthchecks.io; tightly integrated with Sentry alerting."
---

## What it is

Sentry Crons monitors scheduled jobs by accepting heartbeat check-ins from each run — start, finish, duration. Alerts when a job fails to check in or runs too slow. See [docs.sentry.io/product/crons](https://docs.sentry.io/product/crons/).

## When to use

Pick Sentry Crons when:
- You're already on Sentry and want one-vendor cron monitoring.
- Lightweight heartbeat over a separate service like Healthchecks.io.

## 2025-2026 currency anchors

- **Stable** product; few changes.
- **SDK auto-integration** for Celery, RQ, sidekiq, BullMQ.

## Patterns

- **Check-in at start + completion** of each job run.
- **Set max-runtime alert** for runaway jobs.
- **Cron schedule expression** declared in Sentry — schedule mismatch = "missed" alert.

## Anti-patterns

- **No start check-in** — can't detect jobs that never start.
- **No max-runtime** — runaway jobs go unnoticed.

## Gotchas

- **Schedule must match** the actual cron schedule — drift causes false-missed alerts.
- **DSN per project**; cron checks count against the project's quota.

## Cross-references

- [Sentry Errors](/stacks/observability/sentry-errors/)
- Authoritative: [docs.sentry.io/product/crons](https://docs.sentry.io/product/crons/)
