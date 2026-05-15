---
title: Speed Insights
description: Real-user monitoring for Core Web Vitals — LCP, INP, CLS, TTFB, FCP. Out of beta in 2025; one component, captured per page view.
product:
  name: Speed Insights
  stack: vercel
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, devops-engineer]
  authoritative_url: https://vercel.com/docs/speed-insights
  notes: "Out of beta as of 2025; production-ready. INP is the headline metric (replaced FID). Free tier has caps; Pro removes them."
---

## What it is

Speed Insights captures real-user Core Web Vitals — LCP, INP, CLS, TTFB, FCP — for every page view, surfaced in the Vercel dashboard. One component (`<SpeedInsights />`) in the root layout. See [vercel.com/docs/speed-insights](https://vercel.com/docs/speed-insights).

## When to use

- **Any production Vercel project.** RUM is essential; lab-only metrics (Lighthouse, WebPageTest) miss real-world variance.
- **Performance gating in CI** — pull thresholds from Speed Insights via the REST API to gate PRs.

Don't substitute Speed Insights for:

- **Synthetic monitoring** — Lighthouse / Unlighthouse / WebPageTest for repeatable benchmarks.
- **Product analytics** — Speed Insights tracks perf, not user behavior.
- **a11y testing** — axe-core in CI, not Speed Insights.

## 2025-2026 currency anchors

- **GA (out of beta).** Production-ready in 2025.
- **INP is the headline metric** (replaced FID in 2024). Watch INP closely — it's the most JS-driven of the trio.
- **Free tier capped**; Pro removes the cap.
- **Surfaced in Toolbar** on Preview URLs — see real-user data per deployment.

## The metrics that matter

- **LCP** — largest contentful paint. Aim < 2.5s. Driven by image optimization, font loading, server response time, render-blocking JS.
- **INP** — interaction to next paint. Aim < 200ms. Driven by main-thread work, hydration cost, third-party scripts.
- **CLS** — cumulative layout shift. Aim < 0.1. Driven by image dimensions, font swap, late-loaded ads/iframes.
- **TTFB** — time to first byte. PPR's static shell crushes this for cached pages.

## Patterns + anti-patterns

**Pattern: One component in root layout.**

```tsx
// app/layout.tsx
import { SpeedInsights } from '@vercel/speed-insights/next';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}<SpeedInsights /></body>
    </html>
  );
}
```

**Pattern: Threshold check in CI.** Pull RUM data via Vercel REST API; fail PR if LCP/INP regresses past threshold vs main.

**Pattern: Pair with Lighthouse in CI** for repeatable lab metrics + Speed Insights for real-world variance.

**Anti-pattern: Optimizing without measuring.** Lab metrics lie at the tails; INP especially needs RUM.

**Anti-pattern: Watching p50.** p75 (Core Web Vitals official threshold) is what users on slow networks feel.

## Gotchas

- **Free tier caps** — Pro removes; verify your plan if metrics are dropping out.
- **First-party only** — Speed Insights doesn't track third-party iframes.
- **Privacy-respecting** — no per-user identifiers by default; data is aggregated.
- **Lag in dashboard** — recently-collected metrics may take minutes to appear.

## Cross-references

- [Web Analytics](/stacks/vercel/web-analytics/) — different product; page views not perf
- [Log Drains](/stacks/vercel/log-drains/) — for log-level observability
- [Image Optimization](/stacks/vercel/image-optimization/) — LCP driver
- [frontend-architect on Vercel](/stacks/vercel/frontend-architect/) — performance budget
- [devops-engineer on Vercel](/stacks/vercel/devops-engineer/) — observability wiring
- Authoritative: [Speed Insights docs](https://vercel.com/docs/speed-insights)
