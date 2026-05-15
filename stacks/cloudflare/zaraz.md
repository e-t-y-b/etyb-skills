---
title: Zaraz
description: Server-side tag manager — runs marketing and analytics tags on Cloudflare's edge instead of in the browser, with Worker-emitted server-side events.
product:
  name: Zaraz
  stack: cloudflare
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, frontend-architect, security-engineer]
  authoritative_url: https://developers.cloudflare.com/zaraz/
  notes: "Tag templates and consent management surface evolves; the core server-side event API is stable."
---

## What it is

Zaraz is a server-side tag manager. Instead of loading Google Analytics, Facebook Pixel, Segment, etc. as third-party scripts in the browser, you configure them in the Cloudflare dashboard and Zaraz fires the requests from the edge. The page sends a small `zaraz.track(...)` payload to your zone; Cloudflare fans out to the configured destinations.

Authoritative reference: [developers.cloudflare.com/zaraz](https://developers.cloudflare.com/zaraz/).

## When to use

- **Performance-critical sites where third-party tags dominate LCP / INP.** Move them server-side; your browser ships milliseconds of script instead of megabytes.
- **Strict consent regimes (GDPR, ePrivacy).** Zaraz integrates a consent manager and fires tags only after consent is granted, on the edge.
- **First-party data control.** All analytics traffic flows through your Cloudflare zone; you can inspect, transform, or block before it reaches vendors.
- **Server-side events from [Workers](/stacks/cloudflare/workers/).** Fire conversion or business events from your backend without exposing them to the browser at all.

Don't reach for Zaraz when:

- You're already on Segment / Rudderstack / mParticle as your CDP — Zaraz overlaps; pick one canonical event router.
- The destination requires browser-only context (full DOM, full client storage) that server-side firing loses.

## 2025-2026 currency anchors

- **Server-side events from Workers** (`zaraz.track` via the Workers API) is the canonical 2025 pattern for backend conversion events — replaces the older "send a beacon from the browser then trust it" model.
- **Consent management** has matured; Zaraz can gate every tag on a per-purpose consent decision.
- **Tag library is large but vendor-curated.** New vendors land regularly; verify your destination is supported before committing.

## Patterns

### Browser tracking with consent gate

```html
<!-- Zaraz auto-injects when enabled on the zone -->
<script>
  zaraz.track("page_view", { path: location.pathname });
  // Buttons / forms wire to zaraz.track("signup_started", { plan: "pro" })
</script>
```

Zaraz fires only the tags the user has consented to; the rest are silently held.

### Server-side event from a Worker

```ts
import { Zaraz } from "@cloudflare/zaraz-workers";

export default {
  async fetch(req, env, ctx) {
    const result = await processOrder(req, env);
    ctx.waitUntil(env.ZARAZ.track("order_completed", {
      order_id: result.id,
      revenue_cents: result.total_cents,
      currency: result.currency
    }));
    return Response.json(result);
  }
};
```

Server-side firing is harder to spoof than a browser beacon — useful for revenue events that drive billing or attribution decisions.

### A/B testing with first-party events

Zaraz events feed your analytics destinations; pair with [Workers](/stacks/cloudflare/workers/) routing logic for the experiment assignment and emit a `variant_assigned` event from the Worker so attribution is server-truth, not browser-truth.

## Anti-patterns

- **Stacking Zaraz on top of GTM.** Pick one. Running both doubles the tag-management surface and confuses consent.
- **Server-side firing without verifying the destination accepts it.** Some vendors require browser context (cookies, fingerprints) and silently drop server-side payloads.
- **Ignoring consent integration.** If your site is subject to GDPR/ePrivacy, configure Zaraz's consent manager — don't fire tags pre-consent on principle.

## Gotchas

1. **The browser still loads `zaraz.js`** (small, Cloudflare-served) — Zaraz isn't zero-script; it's drastically-less-script.
2. **Pricing scales with events.** High-volume sites should estimate event volume × destinations before flipping it on.
3. **Some tags require server-side keys** (e.g., Facebook Conversions API token). Manage those as Zaraz tool credentials; rotate.
4. **Custom HTML tags still run client-side.** If you push raw HTML/JS tags through Zaraz, you've reintroduced the third-party-script problem you came to fix.

## Cross-references

- [Workers](/stacks/cloudflare/workers/) — runtime for server-side `zaraz.track()`
- [WAF + Managed Rulesets](/stacks/cloudflare/waf/) — block known-bad bot traffic before it pollutes your analytics
- [Logpush](/stacks/cloudflare/logpush/) — fan event data to your warehouse for joining with operational data
- Role overlay: [devops-engineer on Cloudflare](/stacks/cloudflare/devops-engineer/), [security-engineer on Cloudflare](/stacks/cloudflare/security-engineer/)
- Authoritative: [developers.cloudflare.com/zaraz](https://developers.cloudflare.com/zaraz/)
