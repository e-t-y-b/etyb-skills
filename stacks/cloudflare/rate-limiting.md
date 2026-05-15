---
title: Rate Limiting
description: Two distinct rate-limit surfaces on Cloudflare — zone-level Rate Limiting Rules (in the WAF engine) and the per-Worker Rate Limiting binding for in-code business limits.
product:
  name: Rate Limiting
  stack: cloudflare
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, backend-architect, devops-engineer]
  authoritative_url: https://developers.cloudflare.com/waf/rate-limiting-rules/
  notes: "Two products with related but distinct semantics; Workers Rate Limiting binding API has matured through 2025-2026."
---

## What it is

Cloudflare ships two rate-limiting surfaces and they are not interchangeable:

1. **Rate Limiting Rules (zone-level)** — part of the WAF rule engine. Runs at the edge before any [Worker](/stacks/cloudflare/workers/) sees the request. Free traffic shedding for abusive patterns.
2. **Workers Rate Limiting binding (in-Worker)** — call `env.RATE_LIMITER.limit({ key })` from a Worker handler. Per-user / per-tenant / per-business-resource limits expressed in code.

Both can — and usually should — coexist. Authoritative references: [zone-level rate limiting](https://developers.cloudflare.com/waf/rate-limiting-rules/) and [Workers Rate Limiting binding](https://developers.cloudflare.com/workers/runtime-apis/bindings/rate-limit/).

## When to use

| Need | Use |
|------|-----|
| Block abusive patterns at the edge before reaching your Worker | **Rate Limiting Rules** (zone-level) |
| Per-user, per-tenant, per-resource business limits | **Workers Rate Limiting binding** |
| Sliding window or complex keying | **Workers Rate Limiting binding** with custom keys |
| Login brute-force defense | **Rate Limiting Rules** (geo + path) + **Worker binding** (per-account lockout) |
| Free-tier traffic shedding before billing kicks in | **Rate Limiting Rules** |

## 2025-2026 currency anchors

- **Workers Rate Limiting binding** stabilized in 2024-2025; the `unsafe.bindings` `ratelimit` type with `simple = { limit, period }` is the canonical wrangler shape — verify against current docs as the binding type is migrating toward stable form.
- **Zone Rate Limiting Rules** sit in the WAF custom phase; the rule-engine language is shared with [WAF](/stacks/cloudflare/waf/) custom rules.

## Patterns

### Zone-level rate limiting (login endpoint)

```
when (http.request.uri.path eq "/login")
counted by (ip.src)
characteristics: 10 requests in 60 seconds
action: block (or managed_challenge)
```

Runs before any Worker. Cheap, fast, edge.

### Workers Rate Limiting binding

`wrangler.toml`:

```toml
[[unsafe.bindings]]
name = "RATE_LIMITER"
type = "ratelimit"
namespace_id = "100"
simple = { limit = 100, period = 60 }
```

Handler:

```ts
const { success } = await env.RATE_LIMITER.limit({ key: `user:${userId}` });
if (!success) return new Response("Too Many Requests", { status: 429 });
```

Per-user / per-tenant limits where the key is something the WAF can't see (validated user ID, decoded JWT subject).

### Composition: zone + Worker

```
[Edge: Rate Limiting Rule blocks > 1000 req/min/IP]
   ↓ (survives that)
[Worker: env.RATE_LIMITER.limit({ key: `user:${id}` }) — 100 req/min/user]
   ↓ (survives that too)
[Business logic]
```

Zone-level shed the obvious abuse; Worker enforces business-logic limits on real users.

## Anti-patterns

- **Putting all rate limiting in the Worker.** Every request burns Worker CPU + subrequests; the WAF can drop abuse at the edge for free.
- **Putting all rate limiting at the zone.** The zone can key by IP or header — it can't key by your validated user ID. Per-tenant limits live in the Worker.
- **KV as a rate-limit counter.** KV writes are eventually consistent and per-key rate-limited (~1/sec). Use the Workers Rate Limiting binding or a per-user [Durable Object](/stacks/cloudflare/durable-objects/).
- **Same limits across all paths.** A `/health` endpoint and a `/login` endpoint don't need the same limits — segment by route.

## Gotchas

1. **Workers Rate Limiting state is regional, not strictly global** — limits are enforced per Cloudflare region. An attacker rotating regions can hit `limit × regions`. For strict global limits, use a [Durable Object](/stacks/cloudflare/durable-objects/) counter.
2. **`Cf-Connecting-IP` as a key** is only reliable for traffic that actually passed through Cloudflare. Direct-origin requests bypass; ensure the Worker rejects non-Cloudflare traffic if you rely on this for security.
3. **Zone rate limits count by the rule's `characteristics`** — pick deliberately (per-IP, per-path, per-header).
4. **Cost.** Zone-level Rate Limiting Rules have plan-tiered request budgets; check before enabling many rules on a high-volume zone.

## Cross-references

- [WAF + Managed Rulesets](/stacks/cloudflare/waf/) — shares the rule engine
- [Workers](/stacks/cloudflare/workers/) — runtime for the binding
- [Durable Objects](/stacks/cloudflare/durable-objects/) — strictly-global counter alternative
- [Turnstile](/stacks/cloudflare/turnstile/) — for the abuse vector rate limits can't fix
- [Logpush](/stacks/cloudflare/logpush/) — `firewall_events` dataset captures Rate Limiting Rule hits
- Role overlay: [security-engineer on Cloudflare](/stacks/cloudflare/security-engineer/), [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/)
- Authoritative: [zone-level rate limiting](https://developers.cloudflare.com/waf/rate-limiting-rules/), [Workers Rate Limiting binding](https://developers.cloudflare.com/workers/runtime-apis/bindings/rate-limit/)
