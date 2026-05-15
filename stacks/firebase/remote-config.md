---
title: Remote Config
description: Server-driven configuration for clients and SSR — feature flags, kill switches, A/B variant selection, prompt iteration. Client and server-side templates.
product:
  name: Remote Config
  stack: firebase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, mobile-architect, backend-architect, ai-ml-engineer]
  authoritative_url: https://firebase.google.com/docs/remote-config
  notes: "Server-side Remote Config GA 2024; integrates with A/B Testing; AI personalization via Remote Config + Firebase AI Logic."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Remote Config is Firebase's runtime configuration store — typed key-value pairs delivered to clients (and, since 2024, server runtimes) with conditions for user segmentation. The canonical use is feature flags, kill switches, server-driven copy, and A/B test variant selection. Pairs with [A/B Testing](/stacks/firebase/ab-testing/) for experimentation.

Canonical reference: [Remote Config docs](https://firebase.google.com/docs/remote-config).

## When to use it

**Use Remote Config when:**

- Feature flags and kill switches
- A/B test variant selection (paired with A/B Testing)
- Per-region or per-cohort config (e.g., `payment_methods` differs by user country)
- Server-driven copy / prompt iteration
- AI personalization — driving model selection or prompt variants for Firebase AI Logic / Genkit

**Don't use Remote Config when:**

- You need real-time data (eventually-consistent; fetch latency)
- You need per-user data (use Firestore)
- The data is a database — Remote Config has a quota and isn't a primary store

## 2025-2026 currency anchors

- **Server-side Remote Config GA** (2024) — usable from Next.js server components / Angular SSR / Cloud Functions for per-request flag evaluation, not just client-side.
- **AI personalization via Remote Config + Firebase AI Logic** — drive prompt variants, model selection per cohort without a client redeploy.
- **Conditions support recent platform signals** — country, language, user properties (set via Analytics), random percentile, app version.

## Patterns

### Client-side fetch

```ts
import { getRemoteConfig, fetchAndActivate, getValue } from "firebase/remote-config";

const rc = getRemoteConfig(app);
rc.settings.minimumFetchIntervalMillis = 3600000;
rc.defaultConfig = { show_new_feature: false };

await fetchAndActivate(rc);
const showNewFeature = getValue(rc, "show_new_feature").asBoolean();
```

**Set defaults** — they ship in your bundle. If the network is down or the user is new, defaults apply.

**Activate explicitly** — `fetchAndActivate` fetches the latest values and activates them for use. You can `fetch` ahead of time and `activate` at a controlled moment to avoid mid-session UI changes.

### Mobile pattern (iOS Swift)

```swift
let rc = RemoteConfig.remoteConfig()
let settings = RemoteConfigSettings()
settings.minimumFetchInterval = 3600
rc.configSettings = settings
rc.setDefaults([
  "show_new_paywall": false as NSObject,
  "paywall_button_text": "Subscribe" as NSObject,
])
try await rc.fetchAndActivate()
let showNewPaywall = rc.configValue(forKey: "show_new_paywall").boolValue
```

### Server-side (2024 GA)

Useful in SSR / Cloud Functions for per-request flag evaluation:

```ts
import { getRemoteConfig } from "firebase-admin/remote-config";

const template = await getRemoteConfig().getServerTemplate();
const config = template.evaluate({ /* user signals */ });
const variant = config.getString("paywall_variant");
```

Server-side Remote Config integrates with [A/B Testing](/stacks/firebase/ab-testing/) — you can ship variants per cohort with goal-metric tracking via [Analytics (GA4)](/stacks/firebase/firebase-analytics/).

### Drive AI prompts via Remote Config

```ts
const template = await getRemoteConfig().getServerTemplate();
const config = template.evaluate();
const promptVariant = config.getString("summarize_prompt_v");  // "v1" or "v2"

const prompt = ai.prompt(`summarize_${promptVariant}`);
const { output } = await prompt({ text });
```

The 2025 pattern for prompt iteration — A/B test prompts, swap models per cohort, roll back without redeploying. See [ai-ml-engineer overlay](/stacks/firebase/ai-ml-engineer/#pattern-server-side-remote-config-drives-prompts).

## Anti-patterns

- **Treating Remote Config as a database** — eventually-consistent; has fetch latency; has quotas. For real-time data, use [Firestore](/stacks/firebase/cloud-firestore/) / [RTDB](/stacks/firebase/realtime-database/).
- **No defaults shipped in the bundle** — new users / offline users get nothing.
- **Reading Remote Config values before activation** — you get the previous activated value or default.
- **Per-user values in Remote Config** — segment by conditions, not by user ID. Use Firestore for per-user state.
- **`minimumFetchInterval` too low in production** — burns quota; gives no real freshness benefit. Hourly is fine for most flags.

## Gotchas

- **Fetch is async** — UI gating must wait for activation, or you risk flash-of-old-value.
- **Conditions evaluate on a snapshot of user signals** at fetch time. A user whose country changes mid-session sees the old condition until next fetch.
- **`fetchAndActivate` once per minute by default in dev** — `minimumFetchInterval: 0` to bypass during testing.
- **Quota** — fetch calls are billed; not free at scale.
- **Server-side templates require service account credentials** — wire via Admin SDK in your SSR / Cloud Function context.

## Cross-references

- [A/B Testing](/stacks/firebase/ab-testing/) — experiment infrastructure layered on Remote Config
- [Firebase Analytics (GA4)](/stacks/firebase/firebase-analytics/) — goal metrics for A/B Testing
- [Firebase AI Logic](/stacks/firebase/firebase-ai-logic/) — Remote Config-driven prompt variants
- [Genkit](/stacks/firebase/genkit/) — prompt iteration via Remote Config
- [ai-ml-engineer overlay](/stacks/firebase/ai-ml-engineer/) — Remote Config + AI personalization
- Authoritative: [firebase.google.com/docs/remote-config](https://firebase.google.com/docs/remote-config)
