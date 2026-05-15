---
title: Sentry Replay
description: Session replay — DOM mutations recorded, played back alongside errors. The unique UX investigation surface.
product:
  name: Sentry Replay
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, sre-engineer]
  authoritative_url: https://docs.sentry.io/product/session-replay/
  notes: "Quotas changed 2025; mobile replay landing; replaysOnErrorSampleRate 1.0 + replaysSessionSampleRate 0.1 is the canonical pattern."
---

## What it is

Sentry Replay records DOM mutations in the browser (and increasingly mobile) and plays them back as video alongside errors. You see exactly what the user saw before the bug. See [docs.sentry.io/product/session-replay](https://docs.sentry.io/product/session-replay/).

## When to use

Pick Sentry Replay when:
- Error reproduction is hard ("I clicked the button and nothing happened").
- Frontend issues need UX context.
- You're already on [Sentry Errors](/stacks/observability/sentry-errors/).

Alternatives for RUM (without replay): [Datadog RUM](/stacks/observability/datadog-rum/), [New Relic Browser](/stacks/observability/newrelic-apm/), [Grafana Faro](/stacks/observability/grafana-faro/).

## 2025-2026 currency anchors

- **Quotas changed 2025** — per-replay billing reshaped.
- **Mobile replay** launching/landing through 2025-2026.
- **Privacy controls** — `maskAllText: true`, `blockAllMedia: true`, per-element `data-sentry-mask`.

## Patterns

Canonical browser config:

```typescript
Sentry.init({
  integrations: [
    Sentry.replayIntegration({ maskAllText: false, blockAllMedia: false }),
  ],
  replaysSessionSampleRate: 0.1,     // 10% of sessions
  replaysOnErrorSampleRate: 1.0,     // 100% of error sessions
});
```

- **`replaysSessionSampleRate: 0.1`** — sample 10% of normal sessions.
- **`replaysOnErrorSampleRate: 1.0`** — keep 100% of error sessions (the highest-value).

## Anti-patterns

- **`replaysSessionSampleRate: 1.0`** — quota burn.
- **No PII masking** — replay captures form fields, includes potential PII.
- **Replay alone (no Errors)** — replay's value is in error correlation; pair them.

## Gotchas

- **Bundle size** — replay SDK adds ~50KB gzip.
- **Cross-domain iframe** capture limitations.
- **React Native replay** is newer; mobile-native replay landing through 2026.

## Cross-references

- [Sentry Errors](/stacks/observability/sentry-errors/)
- RUM strategy → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Authoritative: [docs.sentry.io/product/session-replay](https://docs.sentry.io/product/session-replay/)
