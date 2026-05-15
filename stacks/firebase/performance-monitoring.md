---
title: Performance Monitoring
description: App performance telemetry — auto-captured page loads + network requests + screen renders, custom traces, integrated with Cloud Trace for end-to-end visibility.
product:
  name: Performance Monitoring
  stack: firebase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, frontend-architect, backend-architect, sre-engineer]
  authoritative_url: https://firebase.google.com/docs/perf-mon
  notes: "Cloud Trace integration 2024-2025; custom traces + network monitoring; web JS support stable."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Firebase Performance Monitoring captures runtime performance telemetry from your app — automatic traces for app start, screen rendering, and HTTP/HTTPS network calls, plus custom traces for any code path you instrument. Since 2024-2025, Performance Monitoring traces flow to **Cloud Trace** for a unified view across mobile, web, and backend ([Cloud Functions](/stacks/firebase/cloud-functions-firebase/) / Cloud Run).

Canonical reference: [Performance Monitoring docs](https://firebase.google.com/docs/perf-mon).

## When to use it

**Use Performance Monitoring when:**

- You want a baseline of app start, screen render, network latency without manual instrumentation
- You want custom traces around user-facing critical paths (login, checkout, search)
- You want end-to-end traces correlating mobile → backend → DB

**Use a dedicated APM (Datadog, New Relic, Sentry Performance, Honeycomb) when:**

- You need richer query/correlation features
- You're already standardized on another APM
- You need distributed tracing across many non-Firebase services

## 2025-2026 currency anchors

- **Cloud Trace integration** (2024-2025) — Performance traces appear in Cloud Trace alongside Cloud Functions / Cloud Run traces, allowing end-to-end mobile → backend visibility.
- **Web JS SDK stable** — auto-captures page load (LCP-like metric) and network requests.
- **Mobile SDKs (iOS, Android, Flutter, RN)** stable; minimal config required.

## Patterns

### Automatic traces

The SDK auto-captures, with no code changes:

- **App start time** (cold/warm/hot)
- **Screen rendering** (slow frames, frozen frames)
- **HTTP/HTTPS network requests** (latency, payload size, success rate)
- **Page load** (web — LCP-like metric, full-load duration)
- **Network requests** (web — every `fetch`/XHR with timing breakdown)

### Custom traces (mobile — iOS)

```swift
let trace = Performance.startTrace(name: "checkout_flow")
trace?.incrementMetric("retries", by: 1)
trace?.setValue("pro", forAttribute: "user_tier")
// ... work ...
trace?.stop()
```

### Custom traces (web)

```ts
import { getPerformance, trace } from "firebase/performance";

const perf = getPerformance(app);
const t = trace(perf, "checkout_flow");
t.start();
// ...
t.stop();
```

Custom traces appear alongside auto traces in the console. Use them for any user-facing critical path you care about latency on.

### End-to-end traces via Cloud Trace

When Performance Monitoring + Cloud Functions + Cloud Run all flow to Cloud Trace, you can see a single trace spanning: mobile checkout button tap → network call → Cloud Function execution → Firestore query → response. Useful for "the user's checkout took 3 seconds; where did the time go?"

## Anti-patterns

- **Per-user custom attributes that contain PII** — same rules as Analytics. Use enums.
- **Custom traces around trivial code** — auto traces cover most things; custom traces are for *named user flows* you want to track.
- **Stopping traces in error paths but not finally blocks** — leak traces.
- **Treating Performance Monitoring as a real-time dashboard** — it's eventually-consistent; minutes-to-hours for full aggregation.

## Gotchas

- **Sample rates** — high-traffic apps may be sampled. The console shows aggregates, not every request.
- **Network monitoring captures URL paths** — be careful with sensitive query parameters; consider stripping or hashing in URL templates.
- **Disable in dev/test environments** — otherwise dev traffic pollutes prod aggregates. Use the `dataCollectionEnabled` flag.
- **Cloud Trace correlation requires propagation headers** — your backend must emit OpenTelemetry-compatible trace context to participate.

## Cross-references

- [Crashlytics](/stacks/firebase/crashlytics/) — the crash-side sibling
- [Cloud Functions for Firebase](/stacks/firebase/cloud-functions-firebase/) — backend traces in Cloud Trace
- [mobile-architect overlay](/stacks/firebase/mobile-architect/#performance-monitoring) — mobile perf playbook
- [frontend-architect overlay](/stacks/firebase/frontend-architect/#performance-monitoring--web) — web perf
- Authoritative: [firebase.google.com/docs/perf-mon](https://firebase.google.com/docs/perf-mon)
