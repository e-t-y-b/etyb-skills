---
title: Smart Placement
description: Cloudflare Workers configuration flag that runs the Worker near its backend instead of the user — wins when backend roundtrips dominate end-to-end latency.
product:
  name: Smart Placement
  stack: cloudflare
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [system-architect, devops-engineer, backend-architect]
  authoritative_url: https://developers.cloudflare.com/workers/configuration/smart-placement/
  notes: "Config flag; broadly recommended for backend-bound Workers as of 2025-26."
---

## What it is

Smart Placement is a Workers configuration flag that runs your Worker close to its backend (database, external API) instead of close to the user. Cloudflare's default placement runs Workers in every data center — great for stateless edge transforms, often slower for Workers that make several roundtrips to a single backend region.

Authoritative reference: [developers.cloudflare.com/workers/configuration/smart-placement](https://developers.cloudflare.com/workers/configuration/smart-placement/).

```toml
# wrangler.toml
[placement]
mode = "smart"
```

## When to use

Turn Smart Placement **on** when:

- The Worker makes **>1 roundtrip** to a single backend (D1 primary, Hyperdrive'd Postgres, external API in one region).
- The backend has a **single home region**, not distributed.
- End-to-end roundtrip with default placement >> end-to-end with smart placement.

Turn it **off** when:

- Worker is essentially **stateless** and edge-only (transforms, no backend).
- Worker fans out to multiple geographically distributed backends.
- You want predictably global low-latency without backend reach (serving cached responses).

**Default for ETYB recommendations:** on for any Worker that does substantial backend I/O. Off for pure edge transforms.

## 2025-2026 currency anchors

- **Smart Placement is broadly recommended** as of 2025-26 for backend-bound Workers — the heuristics have matured.
- Configuration is `[placement] mode = "smart"` in `wrangler.toml`. Verify against the [docs](https://developers.cloudflare.com/workers/configuration/smart-placement/) — flag syntax has been stable but Cloudflare occasionally adjusts placement-related knobs.

## Patterns

### Backend-bound Worker (turn on)

A typical CRUD API talking to D1 primary in one region + Hyperdrive to a Postgres in another region:

```toml
name = "orders-api"
[placement]
mode = "smart"

[[d1_databases]]
binding = "DB"
database_name = "orders-prod"

[[hyperdrive]]
binding = "ANALYTICS_PG"
id = "..."
```

Without Smart Placement, a request from a user in Tokyo round-trips to the D1 primary (say us-east-1) repeatedly — once per binding call. With Smart Placement, the Worker runs near the D1 primary; user→edge→backend is now one fat roundtrip instead of N.

### Edge transform Worker (turn off)

A Worker that only reads request headers, rewrites paths, applies geolocation logic, and serves from cache — no backend reach at all. Default placement (global) is right; Smart Placement would unnecessarily route through a single region.

## Anti-patterns

- **Enabling Smart Placement for fan-out Workers** that talk to multiple regional backends — Cloudflare picks one home region, so calls to backends elsewhere become slower.
- **Assuming Smart Placement is "always faster."** It's only faster when backend roundtrips dominate. For cached or stateless responses, default placement wins.
- **Forgetting Smart Placement when migrating** an existing Worker to use a new D1 binding — re-evaluate placement when bindings change.

## Gotchas

1. **Smart Placement is a placement *hint*, not a guarantee.** Cloudflare's heuristics may move the home region as traffic patterns change.
2. **Cold-start behavior** may shift — Workers in fewer locations may have longer cold-start tail for first-hit users in distant regions.
3. **Observability:** check actual placement via Workers Logs or `wrangler tail` — the `colo` field tells you where the Worker ran.

## Cross-references

- [Workers](/stacks/cloudflare/workers/) — runtime context
- [D1](/stacks/cloudflare/d1/) — primary region matters for Smart Placement decision
- [Hyperdrive](/stacks/cloudflare/hyperdrive/) — points at a regional backend; Smart Placement aligns with it
- Role overlay: [system-architect on Cloudflare](/stacks/cloudflare/system-architect/), [devops-engineer on Cloudflare](/stacks/cloudflare/devops-engineer/)
- Authoritative: [developers.cloudflare.com/workers/configuration/smart-placement](https://developers.cloudflare.com/workers/configuration/smart-placement/)
