---
title: Browser Rendering
description: Puppeteer-compatible headless browser as a Workers binding — for JS-rendered scraping, dynamic auth flows, screenshot generation, agent steps requiring a real browser.
product:
  name: Browser Rendering
  stack: cloudflare
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, ai-ml-engineer]
  authoritative_url: https://developers.cloudflare.com/browser-rendering/
  notes: "Puppeteer-compatible API served from Workers; pricing per browser-hour; concurrency limits per account."
---

## What it is

Browser Rendering exposes a Puppeteer-compatible headless browser as a Workers binding. The Worker requests a browser session; Cloudflare provides one; the Worker drives it via the Puppeteer API. Useful for any task that needs a real browser — JS-rendered scraping, dynamic auth flows, screenshot generation, agent steps that need to fill forms or click through UIs.

Authoritative reference: [developers.cloudflare.com/browser-rendering](https://developers.cloudflare.com/browser-rendering/).

## When to use

- **Pages requiring JS execution to render** — SPAs, hydrated content.
- **Dynamic auth flows** — OAuth redirects, MFA, anything not driveable via plain HTTP.
- **Scraping protected content** that requires session state, cookies, fingerprinting.
- **Agent steps that need a real browser** to complete a task.
- **Screenshot generation** at scale.

Don't use Browser Rendering when:

- **Trivial scraping** — `fetch()` of HTML and parsing is dramatically cheaper and faster.
- **Static content** — no JS needed.
- **High-frequency / low-budget tasks** — per-browser-hour pricing adds up.

## 2025-2026 currency anchors

- **Pricing is per browser-hour** with concurrency limits per account. Plan around session length and parallelism.
- **`@cloudflare/puppeteer`** is the Cloudflare-flavored Puppeteer client for the Workers runtime.

## Patterns

### Worker → browser → page → text

```toml
[[browser]]
binding = "BROWSER"
```

```ts
import puppeteer from "@cloudflare/puppeteer";

async fetch(req, env) {
  const browser = await puppeteer.launch(env.BROWSER);
  const page = await browser.newPage();
  await page.goto("https://example.com");
  const text = await page.evaluate(() => document.body.innerText);
  await browser.close();
  return Response.json({ text });
}
```

### Pair with Workflows for durable scraping

For multi-step scraping jobs (login → navigate → extract → repeat), wrap each step in a [Workflow](/stacks/cloudflare/workflows/) `step.do()` so failures don't lose progress.

### Screenshot for sharing/preview

```ts
const browser = await puppeteer.launch(env.BROWSER);
const page = await browser.newPage();
await page.goto(url);
const buffer = await page.screenshot({ type: "png" });
await browser.close();
return new Response(buffer, { headers: { "content-type": "image/png" } });
```

## Anti-patterns

- **Using Browser Rendering for trivial GET requests** — `fetch()` is 100x cheaper.
- **Long-lived browser sessions** for many users — sessions are per-tenant; per-user concurrency hits limits quickly.
- **Forgetting `browser.close()`** — leaks session resources.

## Gotchas

1. **Per-browser-hour pricing** — short sessions are cheap; long sessions add up.
2. **Concurrency limits per account** — design around the cap or shard across accounts.
3. **Browser sessions aren't free CPU/wall-clock** for the calling Worker — pair with [Workflows](/stacks/cloudflare/workflows/) for long jobs.
4. **Anti-bot measures on target sites** still apply — Browser Rendering doesn't bypass Captchas or sophisticated detection.

## Cross-references

- [Workers](/stacks/cloudflare/workers/) — runtime
- [Workflows](/stacks/cloudflare/workflows/) — durable multi-step browser scripts
- [R2](/stacks/cloudflare/r2/) — store screenshots/scraped artifacts
- Role overlay: [ai-ml-engineer on Cloudflare](/stacks/cloudflare/ai-ml-engineer/), [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/)
- Authoritative: [developers.cloudflare.com/browser-rendering](https://developers.cloudflare.com/browser-rendering/)
