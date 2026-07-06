---
title: Marketplace
description: Consolidated vendor integrations — Stripe, Sentry, Datadog, Neon, Upstash, Resend, Inngest, more. One install, one bill, auto-wired env vars + webhooks.
product:
  name: Marketplace
  stack: vercel
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, backend-architect, system-architect]
  authoritative_url: https://vercel.com/marketplace
  notes: "Consolidated through 2025. Provisioning flow + billing pass-through shifted. One install + Vercel-billed for partner products. Convenient for startups; evaluate direct vendor billing at scale."
---

## What it is

Vercel Marketplace consolidates third-party integrations behind a one-click install. When you install Stripe, Neon, Upstash, Sentry, Datadog, Resend, Inngest, Pinecone, Statsig, WorkOS, and many more, Vercel:

- **Auto-creates env vars** in all three scopes (Production/Preview/Development).
- **Passes billing through** to your Vercel invoice (with Vercel's margin).
- **Registers webhook endpoints** where applicable.
- **One-click upgrade** path in the dashboard.

See [vercel.com/marketplace](https://vercel.com/marketplace).

## When to use

- **Startups / new projects** — Marketplace is the right default. Speed of iteration > vendor pricing optimization.
- **Rapid prototyping** — install Stripe + Neon + Resend in minutes, env vars wired automatically.
- **One-bill simplicity** — one invoice covers Vercel + Stripe + Neon + Datadog etc.

When to skip Marketplace:

- **Enterprise scale** (~$100k+/mo infra) — direct vendor billing usually wins on price; Marketplace's margin adds up.
- **Existing vendor relationships** — if you have a Datadog Enterprise contract, install Datadog directly, not via Marketplace.
- **Need fine-grained config** Marketplace's wrapper doesn't expose — go direct.

## 2025-2026 currency anchors

- **Consolidated provisioning flow in 2025** — one OAuth, env vars auto-wired, webhooks registered.
- **Billing pass-through with Vercel margin** — convenient at startup scale; less compelling at enterprise.
- **Multi-environment support** — most integrations support separate dev/preview/prod credentials.
- **One-click uninstall removes env vars** — be careful if your code depends on those vars without alternatives.

## Patterns + anti-patterns

**Pattern: Marketplace-first for startup speed.** Install Stripe + Neon + Upstash + Sentry + Resend in the first day; iterate.

**Pattern: Document ownership in `INTEGRATIONS.md`.** Quarterly audit who owns each integration and whether it's still used.

**Pattern: Recognize when direct beats Marketplace.** At enterprise volume, Datadog direct + Stripe high-volume agreement + Neon Business direct beat Marketplace pricing.

**Pattern: Multi-env credentials per integration.** Most Marketplace integrations support separate keys per environment — confirm during install.

**Anti-pattern: Editing Marketplace-wired env vars by hand.** Marketplace integrations sometimes rename/rotate; manual edits break the integration's auto-management.

**Anti-pattern: Marketplace install without ownership.** Unowned integrations accumulate cost and break silently.

**Anti-pattern: Marketplace-only thinking at enterprise scale.** Margin adds up; periodically evaluate direct.

## Common installs

| Integration | What it does | Watch for |
|-------------|--------------|-----------|
| **Stripe** | Auto-wires keys + webhook URLs | Single Stripe account per Vercel project; multi-env needs Stripe restricted keys per env |
| **Neon Postgres** | Provisions Postgres with branching per Preview | Bill at-rest + per-compute-second; tune autosuspend |
| **Upstash Redis (KV)** | Provisions Redis | Per-command pricing; cache hit rate matters |
| **Sentry** | Error tracking | Auto-source-map upload; sample rate controls cost |
| **Datadog** | Logs + traces + metrics | Volume-based; aggressive filtering at source |
| **Resend** | Transactional email | Domain verification per-environment |
| **Inngest** | Event-driven workflows | Alternative to Vercel Workflow for some use cases |
| **Pinecone / Upstash Vector** | Vector DB for RAG | Index dimensions + size; pre-plan |
| **PostHog** | Product analytics | Event-based pricing |
| **Better Stack** | Uptime + status pages | Heartbeats for crons |
| **Statsig / LaunchDarkly** | Feature flags (mirrored to Edge Config) | Reads from Edge Config are sub-15ms globally |
| **WorkOS** | Enterprise SSO/SCIM | Auto auth config |

## Gotchas

- **Removing an integration removes its env vars.** Plan migrations carefully.
- **Marketplace billing shows on the Vercel invoice** — track per-line so the bill doesn't surprise you.
- **Vercel's margin is implicit** — for high-volume vendors, do the math vs direct.
- **Some integrations don't yet support all three env scopes** — verify at install.

## Cross-references

- [Vercel CLI](/stacks/vercel/vercel-cli/) — env var management after install
- [Vercel Postgres](/stacks/vercel/vercel-postgres/) — Neon via Marketplace
- [Vercel KV](/stacks/vercel/vercel-kv/) — Upstash via Marketplace
- [devops-engineer on Vercel](/stacks/vercel/devops-engineer/) — integration governance
- [system-architect on Vercel](/stacks/vercel/system-architect/) — Marketplace vs direct decision
- Authoritative: [Marketplace](https://vercel.com/marketplace)
