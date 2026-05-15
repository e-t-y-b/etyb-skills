---
title: Web Analytics
description: Privacy-first first-party analytics — page views, referrers, devices. Stable; not a replacement for product analytics (PostHog, Amplitude, Mixpanel).
product:
  name: Web Analytics
  stack: vercel
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, devops-engineer]
  authoritative_url: https://vercel.com/docs/analytics
  notes: "Stable. Privacy-first (no third-party cookies, no PII). Good for traffic intuition; not a product analytics replacement."
---

## What it is

Web Analytics is Vercel's first-party, privacy-first page-view analytics. One component (`<Analytics />`) in the root layout; data appears in the Vercel dashboard. Tracks page views, referrers, devices, and routes. No third-party cookies, no PII collection. See [vercel.com/docs/analytics](https://vercel.com/docs/analytics).

## When to use

- **Production traffic intuition** — "is the new homepage getting hits?", "where are users coming from?"
- **GDPR/privacy-friendly stack** — no consent banner needed for Web Analytics alone.
- **Lightweight alternative to Google Analytics** for product-stage apps that don't yet need full product analytics.

Don't substitute Web Analytics for:

- **Product analytics** — PostHog, Amplitude, Mixpanel for funnels, retention, event tracking.
- **Conversion attribution** — needs UTM + event tracking; use a real analytics platform.
- **A/B test analysis** — pair with Statsig/LaunchDarkly or a dedicated tool.

## 2025-2026 currency anchors

- **Stable.** API + dashboard largely unchanged in 2026.
- **First-party** — data goes to Vercel, not a third-party tracker.
- **Privacy-first** — no third-party cookies, no PII, no fingerprinting.
- **Pair with [Speed Insights](/stacks/vercel/speed-insights/)** for perf + analytics in one stack.

## Patterns + anti-patterns

**Pattern: One component in root layout.**

```tsx
// app/layout.tsx
import { Analytics } from '@vercel/analytics/next';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}<Analytics /></body>
    </html>
  );
}
```

**Pattern: Pair with a real product analytics tool** when the team needs funnel/retention insight.

**Anti-pattern: Treating Web Analytics as a substitute for product analytics.** No event tracking, no user properties, no funnels — it's page views only.

**Anti-pattern: Skipping consent banner because "Web Analytics is privacy-first"** — if you ALSO have third-party trackers (Google Ads, Meta Pixel), you still need consent. Web Analytics on its own doesn't trigger consent requirements in most jurisdictions.

## Gotchas

- **Free tier capped** — verify per-plan limits.
- **No custom events** out of the box; for event tracking, use a real analytics platform.
- **Dashboard surfaces only Vercel-detected routes** — non-Vercel-rendered surfaces aren't tracked.

## Cross-references

- [Speed Insights](/stacks/vercel/speed-insights/) — perf RUM (different product)
- [Marketplace](/stacks/vercel/marketplace/) — install PostHog / Amplitude there
- [frontend-architect on Vercel](/stacks/vercel/frontend-architect/)
- Authoritative: [Analytics docs](https://vercel.com/docs/analytics)
