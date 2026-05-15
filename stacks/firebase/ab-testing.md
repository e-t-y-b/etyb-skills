---
title: A/B Testing
description: Experiment infrastructure on top of Remote Config + Analytics — variant assignment, goal metrics, cohort analysis. Same UI for mobile and web.
product:
  name: A/B Testing
  stack: firebase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, mobile-architect, ai-ml-engineer, backend-architect]
  authoritative_url: https://firebase.google.com/docs/ab-testing
  notes: "Integrated with Remote Config; goal metrics via GA4; experiment infra steady."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Firebase A/B Testing is the experimentation layer that sits on top of [Remote Config](/stacks/firebase/remote-config/) and [Firebase Analytics (GA4)](/stacks/firebase/firebase-analytics/). You define an experiment in the Firebase Console: a Remote Config parameter, two or more variant values, target audience (percentage rollout, user properties, app version), and a goal metric (from GA4). Firebase handles variant assignment, exposure tracking, and statistical significance.

Canonical reference: [A/B Testing docs](https://firebase.google.com/docs/ab-testing).

## When to use it

**Use A/B Testing when:**

- You have a Remote Config-driven feature and want to measure impact
- You want server-or-client variant assignment with attribution to GA4 metrics
- Cohort-based rollouts (e.g., "20% of users get the new paywall copy")
- AI prompt experimentation (variant A vs variant B for a generated response)

**Use a dedicated experimentation tool (Optimizely, LaunchDarkly Experimentation, GrowthBook) when:**

- You need richer statistical machinery (sequential testing, multi-armed bandits)
- You need experiment lifecycle UI for non-Firebase parameters
- You're not on Firebase / GA4

## 2025-2026 currency anchors

- **Goal metrics via GA4** — the experiment ties to a GA4 conversion event or custom event.
- **Server-side variant assignment** via server-side Remote Config templates (2024). Useful for SSR / Cloud Function-driven experiments.
- **AI prompt experimentation pattern** — variant A is `gemini-flash`, variant B is `gemini-pro`; ship both; measure response quality + cost.

## Patterns

### Standard mobile/web experiment

1. Define Remote Config parameter (e.g., `paywall_button_text`) with a default value.
2. Create an A/B Testing experiment in console — variants: A = "Subscribe", B = "Start Free Trial".
3. Set audience (e.g., 50% of new US iOS users).
4. Set goal metric (e.g., `purchase` event from GA4).
5. Start experiment. Firebase assigns each eligible user to A or B; logs exposure.
6. Watch the experiment dashboard for lift / loss with confidence intervals.
7. Promote winner to default value; end experiment.

### Server-side experiment

```ts
import { getRemoteConfig } from "firebase-admin/remote-config";

const template = await getRemoteConfig().getServerTemplate();
const config = template.evaluate({ randomizationId: userId });
const variant = config.getString("paywall_variant");
```

Server-side variant assignment is stable per user (via `randomizationId`) and integrates with the same A/B Testing dashboard. Use for SSR or Cloud Functions when the client doesn't directly fetch Remote Config.

### AI prompt experimentation

Pair with [Firebase AI Logic](/stacks/firebase/firebase-ai-logic/) or [Genkit](/stacks/firebase/genkit/) — variant A picks one prompt template + model; variant B picks another. Goal metric is a downstream user-facing outcome (e.g., session length, conversion).

## Anti-patterns

- **Ending experiments too early** — confidence intervals require sample size. Don't peek and stop on day 2.
- **Multiple overlapping experiments without isolation** — variant assignments interact. Use stratification or limit concurrent experiments.
- **Goal metrics that don't reflect what you care about** — proxy metrics that aren't aligned with revenue / retention can mislead.
- **Permanent A/B tests** — graduate a winner to the default and end the experiment. Lingering experiments are technical debt.
- **No exposure tracking** — Firebase A/B Testing auto-tracks exposure; if you bypass it (custom assignment logic), you lose attribution.

## Gotchas

- **Variant assignment is sticky per user** — once assigned, the user stays in their variant.
- **Sample size matters** — small audience experiments need more time to reach significance.
- **GA4 event delays** — events take minutes to appear in dashboards; significance calculations factor this in.
- **Experiments share Remote Config conditions** — be careful that a new condition for one experiment doesn't break another.
- **Server-side experiments require `randomizationId`** — pass a stable user identifier; otherwise each request gets a fresh assignment.

## Cross-references

- [Remote Config](/stacks/firebase/remote-config/) — the parameter store experiments operate on
- [Firebase Analytics (GA4)](/stacks/firebase/firebase-analytics/) — goal metric source
- [Firebase AI Logic](/stacks/firebase/firebase-ai-logic/) — AI prompt experimentation pattern
- [ai-ml-engineer overlay](/stacks/firebase/ai-ml-engineer/) — prompt eval + A/B together
- Authoritative: [firebase.google.com/docs/ab-testing](https://firebase.google.com/docs/ab-testing)
