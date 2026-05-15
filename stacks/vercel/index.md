---
title: Vercel
description: Vercel Frontend Cloud knowledge overlay — Next.js 16, Fluid Compute, Cache Components, PPR, AI SDK v5+, AI Gateway, Workflow, Sandbox. Current to 2026-Q2.
stack:
  vendor: vercel
  last_verified_on: "2026-05-14"
  drift_risk_default: medium
  applies_to_roles:
    - frontend-architect
    - backend-architect
    - devops-engineer
    - ai-ml-engineer
    - system-architect
  authoritative_sources:
    - { name: "Vercel Docs",               url: "https://vercel.com/docs",                          type: official_docs }
    - { name: "Vercel CLI Reference",      url: "https://vercel.com/docs/cli",                      type: cli_reference }
    - { name: "Vercel Changelog",          url: "https://vercel.com/changelog",                     type: changelog }
    - { name: "Vercel Security",           url: "https://vercel.com/security",                      type: official_docs }
    - { name: "Vercel REST API",           url: "https://vercel.com/docs/rest-api",                 type: api_reference }
    - { name: "Next.js Docs",              url: "https://nextjs.org/docs",                          type: official_docs }
    - { name: "Next.js Releases (GitHub)", url: "https://github.com/vercel/next.js/releases",       type: changelog }
    - { name: "AI SDK Docs",               url: "https://sdk.vercel.ai/docs",                       type: official_docs }
  delegate_to_skills:
    - { skill: "vercel:nextjs",                covers: ["Next.js", "App Router", "Server Components", "Server Actions", "ISR", "PPR"] }
    - { skill: "vercel:react-best-practices",  covers: ["React", "Next.js performance", "LCP", "hydration", "bundle optimization"] }
    - { skill: "vercel:ai-sdk",                covers: ["Vercel AI SDK", "AI Elements", "streaming", "tool use", "structured outputs"] }
    - { skill: "vercel:chat-sdk",              covers: ["Chat SDK", "chatbots"] }
    - { skill: "vercel:ai-gateway",            covers: ["AI Gateway", "model routing"] }
    - { skill: "vercel:vercel-functions",      covers: ["Vercel Functions", "Edge Functions", "Serverless"] }
    - { skill: "vercel:workflow",              covers: ["Workflow", "durable functions"] }
    - { skill: "vercel:vercel-storage",        covers: ["Vercel KV", "Vercel Postgres", "Vercel Blob", "Edge Config"] }
    - { skill: "vercel:vercel-cli",            covers: ["Vercel CLI", "deployments"] }
    - { skill: "vercel:vercel-sandbox",        covers: ["Vercel Sandbox", "microVM execution"] }
    - { skill: "vercel:next-upgrade",          covers: ["Next.js version migration"] }
    - { skill: "vercel:env-vars",              covers: ["environment variables", "secrets"] }
    - { skill: "vercel:turbopack",             covers: ["Turbopack"] }
    - { skill: "vercel:auth",                  covers: ["auth on Vercel", "NextAuth-style patterns"] }
    - { skill: "vercel:routing-middleware",    covers: ["Next.js routing", "middleware", "edge middleware"] }
    - { skill: "deploy-to-vercel",             covers: ["deployments", "Preview URLs", "production promotion"] }
    - { skill: "vercel:deployments-cicd",      covers: ["Vercel CI/CD", "Git integration", "build cache"] }
    - { skill: "vercel:next-cache-components", covers: ["Cache Components", "use cache directive"] }
---

## Currency

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Next.js 16 (with 15.x LTS still widely deployed), Vercel AI SDK v5+, Fluid Compute GA (2025), Cache Components default-on (2025-2026), PPR GA (2025-2026), Vercel Sandbox GA (2025), Workflow GA (2025-2026).</div>

If today's date is more than 6 months past the last_verified_on above, treat platform specifics with extra care — bias toward the [authoritative sources](#authoritative-sources) for time-sensitive claims. The drift-check protocol at [/conventions/knowledge-currency/](/conventions/knowledge-currency/) governs how agents handle staleness.

## What changed in 2025-2026 that older training data misses

An LLM with a 2024 cutoff will get these wrong:

- **Next.js 16 shipped** (late 2025) with **Cache Components** as the recommended caching model. The `'use cache'` directive at file, function, or component scope, paired with `cacheLife()` and `cacheTag()`, is the new default — replacing ad-hoc `fetch(..., { next: { revalidate } })`, `unstable_cache`, and `export const revalidate = N` for most cases.
- **Partial Prerendering (PPR) is GA** and the **default rendering model** for new App Router projects in Next.js 16. A single route ships a static shell with streamed Suspense holes — neither SSG, SSR, nor ISR in the classical sense.
- **Fluid Compute went GA in 2025** and changed Vercel Functions billing/concurrency math fundamentally. Functions multiplex in-process concurrency, bill on active CPU rather than wall-clock GB-seconds, and dynamically scale CPU within a single instance. "Cold start vs warm" reasoning from the pre-Fluid era is wrong.
- **Vercel Postgres is Neon under the hood.** New projects should use `@neondatabase/serverless` (or Prisma/Drizzle pointing at Neon) rather than reaching for `@vercel/postgres`.
- **Vercel KV is a Marketplace integration**, typically powered by Upstash. `@vercel/kv` still works but the storage UX leads with partner provisioning.
- **Vercel Sandbox GA'd in 2025** — microVM-isolated execution for running untrusted code (AI-generated code, agent tool outputs, user-submitted scripts).
- **Vercel Workflow** ships durable functions (long-running, multi-step, replay-safe) for background jobs and AI agent orchestration.
- **Vercel Queues** ships first-party producer/consumer queues with visibility timeouts and DLQs.
- **Vercel AI SDK v5+** is a major rewrite. Streaming UI primitives (`streamUI`, `experimental_StreamingReactResponse`) from v3 are deprecated. Current canon: `streamText`, `generateText`, `generateObject`, `streamObject`, `tool()` definitions, `useChat()` v2, plus **AI Elements**.
- **AI Gateway** routes across providers (Anthropic, OpenAI, Google, Mistral, xAI, Groq, Fireworks, Bedrock, etc.) with observability, caching, rate limiting, and fallback.
- **Speed Insights moved out of beta**. INP is the headline metric (replaced FID).
- **Turbopack is the production build** path for Next.js 16+ (stable for dev since Next.js 15, stable for build is rolling out).
- **Vercel Agent** (2025-2026) is the company's first-party agent platform — verify current docs before assuming feature parity.
- **v0** has expanded from a UI generator to a chat-driven app scaffolder (v0.app).
- **Marketplace consolidated** vendor integrations (Stripe, Sentry, Datadog, Neon, Upstash, Resend, Inngest) with billing pass-through and one-click env var wiring.
- **`after()`** (formerly `unstable_after`) is GA: schedule work *after* the response is sent without blocking the user.
- **`taintObjectReference` / `taintUniqueValue`** are the canonical guard against accidentally serializing server-only objects/secrets into a Client Component.
- **Edge Runtime constraints loosened** — many `node:*` modules now run in Edge contexts.

If you find yourself recommending the Pages Router for new code, `getServerSideProps`/`getStaticProps`, `unstable_cache` as the default, `streamUI` from AI SDK v3, the `@vercel/postgres` package as the primary path, or "deploy this Lambda separately" for compute that fits Fluid — you're using stale knowledge.

## Products covered

Per-product pages live under `/stacks/vercel/<product>/`. Each carries its own drift_risk + last_verified_on stamp.

### App layer

| Product | Drift risk | Why |
|---|---|---|
| [Next.js](/stacks/vercel/nextjs/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Next.js 15 → 16 cadence in 2025-2026; App Router defaults shifted; Pages Router now legacy |
| [App Router](/stacks/vercel/app-router/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Cache Components, PPR, Server Actions all converge here; mental model shift since 2024 |
| [Server Components](/stacks/vercel/server-components/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | React 19 stable; `use()`, `taintObjectReference` are the 2026 boundary contract |
| [Server Actions](/stacks/vercel/server-actions/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Stable, but 2025 security hardening shifted defaults (taint APIs, encryption keys) |
| [ISR](/stacks/vercel/isr/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Legacy revalidation model; Cache Components is the 2026 successor for most cases |
| [Partial Prerendering (PPR)](/stacks/vercel/partial-prerendering/) | <span class="etyb-drift-badge" data-risk="high">high</span> | GA in Next.js 16; default rendering for most routes |
| [Cache Components](/stacks/vercel/cache-components/) | <span class="etyb-drift-badge" data-risk="high">high</span> | New default caching model in Next.js 16; replaces ad-hoc fetch caching + ISR |
| [Turbopack](/stacks/vercel/turbopack/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Stable for dev in 2024-2025; stable for build is rolling out |

### Compute layer

| Product | Drift risk | Why |
|---|---|---|
| [Vercel Functions](/stacks/vercel/vercel-functions/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Fluid Compute (2025) replaces traditional serverless billing model |
| [Fluid Compute](/stacks/vercel/fluid-compute/) | <span class="etyb-drift-badge" data-risk="high">high</span> | GA 2025; in-function concurrency, active CPU billing — invalidates old cold-start math |
| [Vercel Cron](/stacks/vercel/vercel-cron/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Stable; declared in vercel.json; min interval 1 min on Pro |
| [Vercel Queues](/stacks/vercel/vercel-queues/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Newer surface; producer/consumer semantics + visibility timeout |
| [Workflow](/stacks/vercel/workflow/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Durable functions; new in 2025-2026; semantics still maturing |
| [Vercel Sandbox](/stacks/vercel/vercel-sandbox/) | <span class="etyb-drift-badge" data-risk="high">high</span> | GA 2025; microVM-isolated execution for untrusted code |

### Storage layer

| Product | Drift risk | Why |
|---|---|---|
| [Vercel KV](/stacks/vercel/vercel-kv/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Now Marketplace-driven via Upstash; provisioning UX shifted |
| [Vercel Postgres](/stacks/vercel/vercel-postgres/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Migrated to Neon backend in 2024-2025; old `@vercel/postgres` guidance stale |
| [Vercel Blob](/stacks/vercel/vercel-blob/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Object storage; stable API; pricing tiers updated 2025 |
| [Vercel Cache](/stacks/vercel/vercel-cache/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Edge cache + Cache Components storage tier; line-item visible in pricing |
| [Edge Config](/stacks/vercel/edge-config/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Ultra-low-latency read-only config store; stable |
| [Image Optimization](/stacks/vercel/image-optimization/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Mature; pricing model (image transforms) is the lever to watch |

### Tooling layer

| Product | Drift risk | Why |
|---|---|---|
| [Vercel CLI](/stacks/vercel/vercel-cli/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | `vercel` is stable; commands evolve modestly |
| [v0](/stacks/vercel/v0/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Chat-driven scaffolding; output quality + supported frameworks expand monthly |
| [Build Cache](/stacks/vercel/build-cache/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Turborepo Remote Cache stable; build cache patterns mature |
| [Marketplace](/stacks/vercel/marketplace/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Consolidated through 2025; provisioning flow + billing pass-through shifted |

### AI layer

| Product | Drift risk | Why |
|---|---|---|
| [AI SDK](/stacks/vercel/ai-sdk/) | <span class="etyb-drift-badge" data-risk="high">high</span> | v5+ (2025) major rewrite; old streamUI / v3 patterns are stale |
| [AI Gateway](/stacks/vercel/ai-gateway/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Multi-provider routing + caching; model catalog + pricing changes monthly |
| [Chat SDK](/stacks/vercel/chat-sdk/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Tightly coupled to AI SDK version cadence |
| [Vercel Agent](/stacks/vercel/vercel-agent/) | <span class="etyb-drift-badge" data-risk="high">high</span> | First-party agent platform; brand new (2025-2026) |

### Observability layer

| Product | Drift risk | Why |
|---|---|---|
| [Speed Insights](/stacks/vercel/speed-insights/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Out of beta; production-ready Core Web Vitals + INP capture |
| [Web Analytics](/stacks/vercel/web-analytics/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Privacy-first first-party analytics; stable |
| [Log Drains](/stacks/vercel/log-drains/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Stable; route runtime + build logs to Datadog, Axiom, Better Stack |

## Role overlays

Composed views under `/stacks/vercel/<role>/`. Each stitches the products that role touches into the lens of *how to use them together*.

- [`/stacks/vercel/frontend-architect/`](/stacks/vercel/frontend-architect/) — App Router defaults, Cache Components, PPR, Server Actions, AI UI, Speed Insights, v0
- [`/stacks/vercel/backend-architect/`](/stacks/vercel/backend-architect/) — Server Action security, Vercel Functions topology, Workflow, Queues, Sandbox, Edge Config, Marketplace
- [`/stacks/vercel/devops-engineer/`](/stacks/vercel/devops-engineer/) — CLI workflows, Preview Deployments, `vercel.json`, env vars, Turborepo, Log Drains, cost monitoring
- [`/stacks/vercel/ai-ml-engineer/`](/stacks/vercel/ai-ml-engineer/) — AI SDK v5+, AI Gateway, Chat SDK, Vercel Agent, RAG patterns, Sandbox for AI tools, evals
- [`/stacks/vercel/system-architect/`](/stacks/vercel/system-architect/) — topology decisions; when Vercel is the whole platform vs the frontend; data plane choice; multi-region

## Authoritative sources

For verified-current behavior, see the official Vercel surfaces:

- **[Vercel Docs](https://vercel.com/docs)** — canonical reference
- **[Vercel Changelog](https://vercel.com/changelog)** — release-by-release deltas
- **[Vercel CLI Reference](https://vercel.com/docs/cli)** — `vercel` command-line surface
- **[Vercel REST API](https://vercel.com/docs/rest-api)** — programmatic deployments + env vars + integrations
- **[Vercel Security](https://vercel.com/security)** — compliance + Trust Center
- **[Next.js Docs](https://nextjs.org/docs)** — framework reference
- **[Next.js Releases (GitHub)](https://github.com/vercel/next.js/releases)** — precise per-version feature mapping
- **[AI SDK Docs](https://sdk.vercel.ai/docs)** — AI SDK v5+ canon
- **[vercel-status.com](https://www.vercel-status.com/)** — platform health

## Delegate skills

The Vercel skill suite is the most fully-featured of any vendor MCP collection. When the user's environment loads any of the skills below, **defer to them on product depth**. This Stack's value is *across* products and *role-shaped* framing — not duplication of vendor depth.

- `vercel:nextjs` — Next.js, App Router, Server Components, Server Actions, ISR, PPR
- `vercel:next-cache-components` — Cache Components + `'use cache'` directive
- `vercel:react-best-practices` — React + Next.js performance, hydration, bundle
- `vercel:routing-middleware` — Next.js routing + middleware
- `vercel:next-upgrade` — Next.js version migrations
- `vercel:turbopack` — Turbopack config
- `vercel:vercel-functions` — Vercel Functions + Edge Functions
- `vercel:workflow` — Workflow durable functions
- `vercel:vercel-sandbox` — Sandbox microVM execution
- `vercel:vercel-storage` — KV / Postgres / Blob / Edge Config
- `vercel:env-vars` — environment variables + secrets
- `vercel:auth` — auth patterns (NextAuth-style)
- `vercel:vercel-cli` — CLI commands + deployments
- `vercel:deployments-cicd` — CI/CD + Git integration + build cache
- `deploy-to-vercel` — one-shot deploy
- `vercel:ai-sdk` — AI SDK v5+, AI Elements
- `vercel:ai-gateway` — AI Gateway routing
- `vercel:chat-sdk` — Chat SDK chatbot template
