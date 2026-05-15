---
title: Datadog RUM
description: Real User Monitoring for browser and mobile — session replay, click analytics, deep correlation with Datadog APM.
product:
  name: Datadog RUM
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, sre-engineer]
  authoritative_url: https://docs.datadoghq.com/real_user_monitoring/
  notes: "Per-session pricing; Browser + Mobile SDKs (iOS, Android, RN, Flutter) at parity 2025-26."
---

## What it is

Datadog RUM captures performance and behavior on the **user's device** — page loads, route changes, errors, user interactions, network requests, session replays. SDKs for Browser, iOS, Android, React Native, Flutter. See [docs.datadoghq.com/real_user_monitoring](https://docs.datadoghq.com/real_user_monitoring/).

Strength: **one-click correlation** from RUM session → backend APM trace. Server-side p99 of 300ms can map to user-side LCP of 4s due to network/CDN/JS bundle/render blocking. DD RUM pairs them.

## When to use

Pick DD RUM when:
- You're already on [Datadog APM](/stacks/observability/datadog-apm/) and want trace ↔ RUM correlation.
- Mobile + Browser both matter — DD has both at parity.

Don't pick if:
- Per-session pricing concerns you at consumer scale — [Sentry Replay](/stacks/observability/sentry-replay/) is more cost-friendly for error-driven RUM.
- You need server-side render visibility — [New Relic Browser](/stacks/observability/newrelic-apm/) and [Sentry](/stacks/observability/sentry-replay/) are competitive.

## 2025-2026 currency anchors

- **Browser + Mobile SDKs at feature parity** (2025-26) including session replay, click analytics, heatmaps.
- **Per-session pricing** with RUM Premium tier for replay + advanced analytics.
- **Auto-capture network requests** + first-party trace propagation via `traceparent` header.

## Patterns

- **Sample sessions** — `sessionSampleRate: 0.1` for steady traffic, 1.0 for low-volume tier-1 paths.
- **Mask sensitive content in replay** — `defaultPrivacyLevel: 'mask'` plus per-field `data-dd-privacy="hidden"` markers.
- **Tag sessions** with user role, plan tier — drives funnel analysis.

## Anti-patterns

- **100% session sampling without budget review** — per-session billing surprise.
- **Recording PII in replay** — set `defaultPrivacyLevel`, mask form fields, hash user IDs.
- **No `service.name` correlation between RUM SDK and backend services** — breaks one-click pivot.

## Gotchas

- Browser SDK adds ~30-60KB gzip to your initial bundle. Lazy-load if first-paint is critical.
- React Native replay requires bridge cooperation; may not capture native modal content.
- Cross-domain trace propagation needs server-side CORS for `traceparent` header.

## Cross-references

- DD APM trace correlation → [datadog-apm](/stacks/observability/datadog-apm/)
- Alternative: Sentry session replay → [sentry-replay](/stacks/observability/sentry-replay/)
- RUM strategy + sampling discipline → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Authoritative: [docs.datadoghq.com/real_user_monitoring](https://docs.datadoghq.com/real_user_monitoring/)
