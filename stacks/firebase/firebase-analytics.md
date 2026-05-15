---
title: Firebase Analytics (GA4)
description: Firebase's analytics SDK — same SKU as Google Analytics 4. Event-driven, mobile-friendly, with Consent Mode v2 and Apple ATT integration.
product:
  name: Firebase Analytics (GA4)
  stack: firebase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, mobile-architect, ai-ml-engineer]
  authoritative_url: https://firebase.google.com/docs/analytics
  notes: "Now the same SKU as GA4; consent mode v2 + Apple ATT compliance evolving."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Firebase Analytics is the mobile-friendly client SDK that emits events to **Google Analytics 4 (GA4)** for storage, querying, attribution, and dashboards. The "Firebase Analytics" name persists in SDK class names; the data plane is GA4. Don't think of them as two products — they're one SKU.

Canonical reference: [Firebase Analytics docs](https://firebase.google.com/docs/analytics).

## When to use it

**Use Firebase Analytics when:**

- You're already on Firebase and need attribution + ad measurement
- You want a mobile-friendly events SDK (vs. web-first gtag.js)
- You need Consent Mode v2 integration for EEA compliance
- You want GA4's free tier + BigQuery export for advanced analysis

**Use a dedicated product analytics tool (Mixpanel, Amplitude, PostHog) when:**

- Your team needs cohort analysis, funnel builders that GA4 doesn't ship strong
- You need rich user-property targeting beyond GA4
- Marketing/ad attribution isn't a primary concern

Many teams ship both — Firebase Analytics for the ads/attribution side, Mixpanel/Amplitude/PostHog for product analytics. Just pick a shared event schema and route both ways from a single emitter; don't double-instrument by hand.

## 2025-2026 currency anchors

- **Consent Mode v2** (2024) — required for EEA / UK / Swiss traffic. Set consent state before logging events.
- **Apple ATT (App Tracking Transparency)** governs whether IDFA is available — without consent, attribution falls back to SKAdNetwork.
- **GA4 export to BigQuery** is standard now — historical analysis is via BigQuery SQL, not the GA4 UI.
- **Consent state affects what GA4 stores** — with ad consent denied, GA4 still receives the event but does not use it for ad personalization.

## Patterns

### Logging events (mobile — iOS)

```swift
Analytics.logEvent(AnalyticsEventBeginCheckout, parameters: [
  AnalyticsParameterCurrency: "USD",
  AnalyticsParameterValue: 42.99,
  AnalyticsParameterItems: items,
])
```

Use the **predefined event names** (`AnalyticsEventBeginCheckout`, `add_to_cart`, etc.) when they fit your domain — they get free GA4 dashboards. Custom events are fine for app-specific actions (`level_completed`, `paywall_shown`).

### Logging events (web)

```ts
import { getAnalytics, logEvent, setUserProperties } from "firebase/analytics";

const analytics = getAnalytics(app);

logEvent(analytics, "purchase", {
  currency: "USD",
  value: 42.99,
  items: [{ item_id: "sku1", item_name: "Pro plan", quantity: 1, price: 42.99 }],
});

setUserProperties(analytics, { subscription_tier: "pro" });
```

### Consent Mode v2

```ts
import { setConsent } from "firebase/analytics";

setConsent({
  ad_storage: "denied",
  ad_user_data: "denied",
  ad_personalization: "denied",
  analytics_storage: "granted",
});
```

Mobile (iOS):

```swift
Analytics.setConsent([
  .analyticsStorage: .granted,
  .adStorage: .denied,
  .adUserData: .denied,
  .adPersonalization: .denied,
])
```

**Required for EEA traffic.** Set consent before logging events. Default to denied; update when user grants.

### Apple ATT (App Tracking Transparency)

If you want IDFA-based attribution / personalization on iOS, request ATT:

```swift
import AppTrackingTransparency
ATTrackingManager.requestTrackingAuthorization { status in /* ... */ }
```

Without ATT consent (`.authorized`), `IDFA` is zeroes and Analytics falls back to **SKAdNetwork** for attribution. **Don't gate features on having IDFA** — most users won't grant it.

### User properties — the privacy-critical surface

```ts
setUserProperties(analytics, { subscription_tier: "pro" });
```

User properties persist for the user across sessions. **Never set PII as a user property.** No emails, phone, names, exact location. Use only enums/buckets:

- `subscription_tier`: `free` / `pro` / `enterprise` — OK
- `signup_year`: `2024` — OK
- `email`: `user@example.com` — wrong (GA4 will reject and flag, but the SDK has already transmitted)

Firebase Analytics has built-in PII detection that rejects obvious patterns (email, US SSN, phone). It is **not** a substitute for not sending PII in the first place.

## Parameter limits

- 25 event parameters per event
- 100-character parameter name max
- 100-character string value max
- 50 custom event types per project (default; can be raised)

## Anti-patterns

- **PII in user properties or event parameters** — GA4 rejects; Apple's privacy review flags; remediation is painful.
- **Logging events before consent is set** in EEA contexts — Consent Mode v2 violation.
- **Gating features on IDFA without ATT consent path** — most iOS users won't grant; features fail silently.
- **Setting `userId` to email / phone** — same PII trap as user properties.
- **`gtag.js` + Firebase Analytics on the same page** — they interfere. Pick one Analytics integration per page.
- **No BigQuery export** — historical analysis in the GA4 UI is limited; BigQuery export is free and unlocks the real value.

## Gotchas

- **GA4 event delays** — events take minutes to appear in dashboards. Use debug view for real-time event inspection during development.
- **Analytics consent state propagates immediately, but ad personalization downstream uses what was set at event time** — set consent before the first event.
- **`gtag.js` coexistence** — if marketing has gtag.js on the page already, picking one is non-trivial. Firebase Analytics IS a GA4 client, so use it as the single integration if possible.
- **Cross-platform user identity** — same user on mobile + web doesn't unify unless you set a consistent `userId` (opaque, server-set). Firebase Auth UID is the standard choice.

## Cross-references

- [A/B Testing](/stacks/firebase/ab-testing/) — uses GA4 events as goal metrics
- [Remote Config](/stacks/firebase/remote-config/) — Analytics user properties feed Remote Config conditions
- [Crashlytics](/stacks/firebase/crashlytics/) — crash-free user metrics flow into GA4
- [mobile-architect overlay](/stacks/firebase/mobile-architect/#firebase-analytics--ga4) — mobile event discipline
- [frontend-architect overlay](/stacks/firebase/frontend-architect/#firebase-analytics-on-web) — web event discipline
- Authoritative: [firebase.google.com/docs/analytics](https://firebase.google.com/docs/analytics)
