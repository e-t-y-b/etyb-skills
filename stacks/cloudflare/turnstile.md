---
title: Turnstile
description: Cloudflare's CAPTCHA alternative — an invisible-most-of-the-time challenge widget for forms, signups, and abuse-prone endpoints.
product:
  name: Turnstile
  stack: cloudflare
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, frontend-architect, backend-architect]
  authoritative_url: https://developers.cloudflare.com/turnstile/
  notes: "Widget + server validation API stable; modes (invisible, managed, non-interactive) and pricing are unchanged through 2026-Q2."
---

## What it is

Turnstile is Cloudflare's CAPTCHA replacement. Drop a widget on your form (or run it invisibly in the background), get back a token, and verify the token server-side via Cloudflare's siteverify endpoint. For ~90%+ of legitimate users, it's a non-event — no images of buses to click. Suspicious traffic gets a managed challenge.

Authoritative reference: [developers.cloudflare.com/turnstile](https://developers.cloudflare.com/turnstile/).

## When to use

- **User signup, password reset, contact forms** — anywhere account-creation abuse is a problem.
- **Anonymous comments / public reviews** — bot scraping and spam.
- **High-stakes form submissions** (large purchases, account changes) — pair with Bot Management score check for defense in depth.
- **Anywhere you'd otherwise reach for reCAPTCHA / hCaptcha.** Turnstile is a strict UX win at parity-or-better detection.

Don't reach for Turnstile when:

- The endpoint is API-only / machine-to-machine — use mTLS or API tokens.
- The endpoint is behind [Cloudflare Access](/stacks/cloudflare/access/) with SSO — Access handles abuse.
- The form is internal / employee-facing — overkill.

## 2025-2026 currency anchors

- **Three widget modes:** `managed` (Cloudflare decides whether to challenge), `non-interactive` (always shows the widget but no user action), `invisible` (no UI at all unless challenge needed). `managed` is the default and the right call for most cases.
- **Token TTL is short** (~5 minutes from issue); verify server-side immediately after the form submit.
- **Stable API.** The siteverify endpoint and widget shape haven't shifted materially since GA.

## Patterns

### Drop-in widget on a form

```html
<head>
  <script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
</head>
<form action="/signup" method="POST">
  <input name="email" type="email" required />
  <div class="cf-turnstile" data-sitekey="0x4AAA..."></div>
  <button type="submit">Sign up</button>
</form>
```

### Server-side verification

```ts
async function verifyTurnstile(token: string, env: Env, remoteIp?: string): Promise<boolean> {
  const r = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      secret: env.TURNSTILE_SECRET,
      response: token,
      ...(remoteIp ? { remoteip: remoteIp } : {})
    })
  });
  const data = await r.json<{ success: boolean }>();
  return data.success;
}

// In a Worker handler
const formData = await req.formData();
const token = formData.get("cf-turnstile-response") as string;
if (!await verifyTurnstile(token, env, req.headers.get("cf-connecting-ip") ?? undefined)) {
  return new Response("Forbidden", { status: 403 });
}
// proceed with signup
```

### Composition with Bot Management

```ts
const bot = (req as any).cf?.botManagement;
if (bot?.score && bot.score < 30) {
  // Suspect bot; require fresh Turnstile token even on otherwise-unprotected endpoint
  if (!await verifyTurnstile(token, env)) return new Response("Forbidden", { status: 403 });
}
```

Bot Management gives the macro signal; Turnstile is the user-friendly challenge when the score warrants it.

## Anti-patterns

- **Skipping Turnstile because "we only get 10 signups a day."** Until an abuser finds the endpoint. The user-facing cost is near-zero; add it.
- **Reusing tokens across requests.** Tokens are single-use, time-limited. Each form submit needs its own.
- **Verifying client-side only.** The widget produces a token; the *server* must call siteverify with the secret. Don't trust the browser.
- **Using `non-interactive` mode when `managed` would do.** `managed` adapts to threat level — `non-interactive` always shows UI to legitimate users.

## Gotchas

1. **Token TTL is short.** If your form has a long authoring flow before submit, the token can expire mid-write. Refresh on submit or use the widget's auto-refresh hooks.
2. **`secret` belongs in a Wrangler secret**, not in `[vars]` — see [Wrangler](/stacks/cloudflare/wrangler/).
3. **`hostname` in the verify response matters** — if you serve the same widget across multiple zones, the response includes which domain it was solved on; validate.
4. **Mobile/native apps need the iOS/Android SDKs**, not the JS widget. Verify still goes through the same siteverify endpoint.

## Cross-references

- [WAF + Managed Rulesets](/stacks/cloudflare/waf/) — runs before the form ever loads; complements Turnstile
- [Rate Limiting](/stacks/cloudflare/rate-limiting/) — slower abuse signals warrant rate limits, not Turnstile alone
- [Workers](/stacks/cloudflare/workers/) — server-side verification runs in a Worker handler
- [Access (ZTNA)](/stacks/cloudflare/access/) — different problem (employee auth), not a Turnstile substitute
- Role overlay: [security-engineer on Cloudflare](/stacks/cloudflare/security-engineer/)
- Authoritative: [developers.cloudflare.com/turnstile](https://developers.cloudflare.com/turnstile/), [siteverify reference](https://developers.cloudflare.com/turnstile/get-started/server-side-validation/)
