---
name: stack-vercel
description: |-
  Vercel platform knowledge overlay for the ETYB team. Loads when work involves the Vercel Frontend Cloud — Next.js, Turbopack, Vercel Functions, Vercel Edge Network, Fluid Compute, Cache Components, Partial Prerendering (PPR), Workflow durable functions, Vercel Queues, Cron, Sandbox, KV/Postgres/Blob/Edge Config storage, Vercel CLI, AI Gateway, AI SDK, Chat SDK, Vercel Agent, v0, Marketplace integrations, Speed Insights, Web Analytics, Log Drains, Preview Deployments, Git integration.
  Triggers: vercel, next.js, nextjs, next 15, next 16, app router, app directory, server components, rsc, react server components, server actions, use server, use client, use cache, cache components, partial prerendering, ppr, isr, on-demand revalidation, revalidatePath, revalidateTag, unstable_cache, fluid compute, vercel functions, edge functions, edge runtime, node runtime, edge middleware, middleware.ts, vercel.json, vercel cli, preview url, preview deployment, deploy to vercel, vercel deploy.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "5.0.0"
  category: stack-pack
  last_verified_on: "2026-05-14"
  applies_to_roles:
    - frontend-architect
    - backend-architect
    - devops-engineer
    - ai-ml-engineer
    - system-architect
authoritative_sources:
  primary:
    - { name: "Vercel Docs",                     url: "https://vercel.com/docs",                                       type: official_docs }
    - { name: "Vercel CLI Reference",            url: "https://vercel.com/docs/cli",                                   type: cli_reference }
    - { name: "Vercel Changelog",                url: "https://vercel.com/changelog",                                  type: changelog }
    - { name: "Vercel Security",                 url: "https://vercel.com/security",                                   type: official_docs }
    - { name: "Vercel REST API",                 url: "https://vercel.com/docs/rest-api",                              type: api_reference }
    - { name: "Next.js Docs",                    url: "https://nextjs.org/docs",                                       type: official_docs }
    - { name: "Next.js Releases (GitHub)",       url: "https://github.com/vercel/next.js/releases",                    type: changelog }
    - { name: "AI SDK Docs",                     url: "https://sdk.vercel.ai/docs",                                    type: official_docs }
    - { name: "Vercel GitHub Org",               url: "https://github.com/vercel",                                     type: official_docs }
    - { name: "Vercel Status",                   url: "https://www.vercel-status.com/",                                type: status_page }
delegate_to_skills:
  # Heavy Vercel skill suite exists in user environments. Defer aggressively to vendor skills
  # for product depth; this Stack focuses on architectural judgment and role-specific framing.
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
products_covered:
  - { name: "Next.js (App Router)",         drift_risk: high,   notes: "Next.js 15 → 16 cadence in 2025-2026; App Router defaults shifted (PPR GA, Cache Components default, Server Actions stabilized); Pages Router patterns now legacy" }
  - { name: "Cache Components / 'use cache'", drift_risk: high, notes: "New default caching model in Next.js 16 (2025-2026); replaces ad-hoc fetch caching + ISR for most use cases; old caching mental models are wrong" }
  - { name: "Partial Prerendering (PPR)",   drift_risk: high,   notes: "GA in Next.js 16; default rendering for most routes; static shell + streamed Suspense boundaries — different from pure SSR/SSG/ISR" }
  - { name: "Server Actions",               drift_risk: medium, notes: "Stable, but security hardening guidance shifted in 2025 (taint APIs, default forbidden methods, encryption keys per deployment)" }
  - { name: "Vercel Functions",             drift_risk: high,   notes: "Fluid Compute (2025) replaces traditional serverless billing model — fundamentally changes cost + concurrency math; Edge vs Node runtime convergence ongoing" }
  - { name: "Fluid Compute",                drift_risk: high,   notes: "GA 2025; in-function concurrency, active CPU billing, dynamic scaling within a single instance — invalidates old 'cold start vs warm' guidance" }
  - { name: "Vercel Edge Network",          drift_risk: medium, notes: "Underlying CDN + edge runtime stable, but headers/caching directives evolve with Cache Components" }
  - { name: "Edge Middleware",              drift_risk: medium, notes: "Stable, but Node runtime convergence means some prior 'edge only' constraints are loosening" }
  - { name: "Vercel Workflow",              drift_risk: high,   notes: "Durable functions surface; new in 2025-2026; semantics still maturing — verify against current docs before committing" }
  - { name: "Vercel Queues",                drift_risk: high,   notes: "Newer surface; producer/consumer semantics + visibility timeout patterns; check changelog for limits" }
  - { name: "Vercel Cron",                  drift_risk: low,    notes: "Stable; declared in vercel.json; min interval 1 min on Pro" }
  - { name: "Vercel Sandbox",               drift_risk: high,   notes: "GA 2025; microVM-isolated execution for untrusted code (AI agents, user code); rapidly evolving" }
  - { name: "Vercel KV (Redis-compatible)", drift_risk: medium, notes: "Now part of unified Vercel Storage; transitioning to managed Upstash/marketplace partners — provisioning UX shifts" }
  - { name: "Vercel Postgres (Neon-backed)", drift_risk: high,  notes: "Migrated to Neon backend in 2024-2025; old @vercel/postgres SDK guidance partially stale; prefer @neondatabase/serverless or direct Neon clients" }
  - { name: "Vercel Blob",                  drift_risk: low,    notes: "Object storage; stable API; pricing tiers updated 2025" }
  - { name: "Edge Config",                  drift_risk: low,    notes: "Ultra-low-latency read-only config store; stable; use for feature flags, allowlists, geo routing" }
  - { name: "Turbopack",                    drift_risk: medium, notes: "Stable for dev in 2024-2025; stable for build is rolling out — verify before turning on production builds" }
  - { name: "Turborepo + Remote Cache",     drift_risk: low,    notes: "Monorepo tooling stable; remote cache patterns mature; ownership tooling steady" }
  - { name: "Image Optimization (next/image)", drift_risk: low, notes: "Mature; pricing model (image transforms) is the lever to watch — defaults can blow budgets" }
  - { name: "Vercel CLI (vercel/v0)",       drift_risk: medium, notes: "`vercel` is stable; `v0` CLI is newer (chat-driven scaffolding) and evolves rapidly" }
  - { name: "Vercel AI SDK",                drift_risk: high,   notes: "v5+ (2025) shipped major rewrites — streaming UI primitives, generateObject schemas, tool use, AI Elements; old streamUI / v3 patterns are stale" }
  - { name: "AI Elements (UI components)",  drift_risk: high,   notes: "New 2025 component library for AI UIs; layered on shadcn — surface area is new" }
  - { name: "AI Gateway",                   drift_risk: high,   notes: "Vercel-hosted multi-provider routing + observability + caching for LLMs; model catalog + pricing changes monthly" }
  - { name: "Chat SDK",                     drift_risk: high,   notes: "Opinionated chatbot template + libs; tightly coupled to AI SDK version cadence" }
  - { name: "Vercel Agent",                 drift_risk: high,   notes: "Vercel's first-party agent platform — surface is brand new (2025-2026); check current docs" }
  - { name: "v0 (v0.dev / v0.app)",         drift_risk: high,   notes: "Chat-driven scaffolding; output quality + supported frameworks expand monthly" }
  - { name: "Marketplace integrations",     drift_risk: medium, notes: "Stripe, Sentry, Datadog, Neon, Upstash, etc. consolidated through Marketplace; provisioning flow + billing pass-through shifted 2025" }
  - { name: "Speed Insights",               drift_risk: low,    notes: "Out of beta; production-ready Core Web Vitals + INP capture; integrates with @vercel/speed-insights" }
  - { name: "Web Analytics",                drift_risk: low,    notes: "Privacy-first first-party analytics; stable; not a replacement for product analytics tools" }
  - { name: "Log Drains",                   drift_risk: low,    notes: "Stable; route runtime + build logs to Datadog, Axiom, Logtail, etc." }
  - { name: "Preview Deployments",          drift_risk: low,    notes: "Core platform feature; stable; integrates with Comments, password protection, Toolbar" }
  - { name: "vercel.json",                  drift_risk: low,    notes: "Config schema stable; rewrites/redirects/headers/cron/regions/functions" }
---

# Vercel Stack — Team Briefing

This is a **knowledge overlay**, not a new specialist. The existing ETYB team does the work — backend-architect writes the backend code, devops-engineer wires the deploys, security-engineer enforces the boundary. This pack tells each role where the current Vercel knowledge lives.

## Where the full briefing lives

The full Stack briefing lives in this same folder. Per-product and per-role pages are siblings of this `SKILL.md`. Every page carries `last_verified_on` stamps and authoritative-source URLs in its frontmatter; see `skills/etyb/core/knowledge-currency.md` for the drift-check protocol that uses them.

- **Stack briefing:** [`stacks/vercel/index.md`](index.md)
- **Per-product pages:** `stacks/vercel/<product>.md` — one per entry in `products_covered` above
- **Per-role views:** `stacks/vercel/<role>.md` — one per role in `applies_to_roles` above

When ETYB is installed locally these are read directly from disk. For third-party agents without the install, the same content is reachable as raw markdown at `https://raw.githubusercontent.com/e-t-y-b/etyb-skills/main/stacks/vercel/<page>.md`.

When `delegate_to_skills` (frontmatter above) lists a first-party vendor MCP/skill that's installed in the user's environment, ETYB defers to it first. The in-repo Stack content is the curated fallback.
## What changed in 2025-2026 that older training data misses

Critical context — an LLM with a 2024 cutoff will get these wrong:

- **Next.js 16 shipped** (late 2025) with **Cache Components** as the recommended caching model. The `'use cache'` directive at file, function, or component scope, paired with `cacheLife()` and `cacheTag()`, is the new default — replacing ad-hoc `fetch(..., { next: { revalidate } })`, `unstable_cache`, and `export const revalidate = N` for most cases. Old patterns still work in 15.x, but new builds should adopt Cache Components.
- **Partial Prerendering (PPR) is GA** and the **default rendering model** for new App Router projects in Next.js 16. A single route can ship a static shell with streamed Suspense holes — this is neither SSG, SSR, nor ISR in the classical sense. Mental models built before PPR will fight the framework.
- **Fluid Compute went GA in 2025** and changed Vercel Functions billing/concurrency math fundamentally. Functions now multiplex in-process concurrency, bill on active CPU rather than wall-clock GB-seconds, and dynamically scale CPU within a single instance. "Cold start vs warm" reasoning from the pre-Fluid era is wrong.
- **Vercel Postgres is Neon under the hood.** Old `@vercel/postgres` SDK calls still work but the Marketplace direction is for users to provision Neon (or another Marketplace Postgres) directly. New projects should use `@neondatabase/serverless` rather than reaching for `@vercel/postgres`.
- **Vercel KV is a Marketplace integration**, typically powered by Upstash. New code should treat Marketplace as the primary path.
- **Vercel Sandbox GA'd in 2025** — microVM-isolated execution for running untrusted code (AI-generated code, agent tool outputs, user-submitted scripts). If a request involves "let an LLM run code" or "execute user-submitted code," Sandbox is the answer, not a homegrown VM2/subprocess.
- **Vercel Workflow** ships durable functions (long-running, multi-step, replay-safe) for background jobs and AI agent orchestration. Don't reach for Temporal/Inngest on Vercel before checking whether Workflow fits.
- **Vercel Queues** ships first-party producer/consumer queues with visibility timeouts and DLQs.
- **Vercel AI SDK v5+** is a major rewrite. The streaming UI primitives (`streamUI`, `experimental_StreamingReactResponse`) from v3 are deprecated. Current canon: `streamText`, `generateText`, `generateObject`, `streamObject`, `tool()` definitions, `useChat()` v2, plus **AI Elements** — a shadcn-layered component library specifically for AI UIs.
- **AI Gateway** routes across providers (Anthropic, OpenAI, Google, Mistral, xAI, Groq, Fireworks, Bedrock, etc.) with observability, caching, rate limiting, and fallback. Use `@ai-sdk/gateway` + `gateway('anthropic/claude-sonnet-4.7')` etc.
- **Turbopack is the production build** path for Next.js 16+ (stable for dev since Next.js 15, stable for build is rolling out). Webpack is still supported but no longer the default story.
- **`after()`** (formerly `unstable_after`) is GA: schedule work *after* the response is sent without blocking the user.
- **`taintObjectReference` / `taintUniqueValue`** are the canonical guard against accidentally serializing server-only objects/secrets into a Client Component.

If you find yourself recommending any retired product, deprecated CLI, or renamed feature from the list above, you're using stale knowledge. Read the relevant sibling file in this folder before continuing.

## Standing instructions for every role on a Vercel engagement

1. **Anchor to currency.** Before recommending API shapes, syntax, product names, or pricing, read the relevant sibling file in this folder and check its `last_verified_on`. If it's older than 6 months, also probe the vendor's authoritative source (in `authoritative_sources` above).

2. **Defer to verticals on domain compliance.** This pack covers platform mechanics. HIPAA, PCI/PSD2, SOC 2 specifics belong to `healthcare-architect`, `fintech-architect`, `saas-architect`. Route to the vertical; don't restate compliance content from this pack.

3. **Respect platform-specific limits.** Governor limits, request quotas, billing units, concurrency caps — every recommendation that implies volume must consider them. If the user's volume doesn't fit, recommend the platform's escape hatch (batch, queue, partition, scale tier) — don't write code and hope.

4. **Honor Server Component / Client Component boundaries.** A huge class of Vercel/Next.js bugs comes from violating these — secrets leaking, hydration mismatches, "module not found in browser bundle." `import 'server-only'` and `import 'client-only'` are not optional hygiene; they're the boundary contract.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Compliance specifics (HIPAA, PCI, SOC 2) | `healthcare-architect` / `fintech-architect` / `saas-architect` |
| Multi-stack architecture spanning vendors | `system-architect` (without the pack overlay) |
| Vendor-agnostic work that happens to touch Vercel | the relevant specialist (without the pack overlay) |

## Stack composition

If the user is running Vercel alongside another stack that has its own pack registered, both overlays load. Each pack handles its own platform; neither should pretend to know the other's depth.
