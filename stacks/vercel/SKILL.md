---
name: stack-vercel
description: >
  Vercel platform knowledge overlay for the ETYB team. Loads when work involves the Vercel Frontend Cloud — Next.js, Turbopack, Vercel Functions, Vercel Edge Network, Fluid Compute, Cache Components, Partial Prerendering (PPR), Workflow durable functions, Vercel Queues, Cron, Sandbox, KV/Postgres/Blob/Edge Config storage, Vercel CLI, AI Gateway, AI SDK, Chat SDK, Vercel Agent, v0, Marketplace integrations, Speed Insights, Web Analytics, Log Drains, Preview Deployments, Git integration. This is NOT a new team member; it is a context overlay that teaches each existing ETYB role what it needs to know to ship production-grade Vercel work as of 2026-Q2.
  Triggers: vercel, next.js, nextjs, next 15, next 16, app router, app directory, server components, rsc, react server components, server actions, use server, use client, use cache, cache components, partial prerendering, ppr, isr, on-demand revalidation, revalidatePath, revalidateTag, unstable_cache, fluid compute, vercel functions, edge functions, edge runtime, node runtime, edge middleware, middleware.ts, vercel.json, vercel cli, preview url, preview deployment, deploy to vercel, vercel deploy, vercel git, vercel kv, vercel postgres, vercel blob, vercel edge config, vercel sandbox, microvm, vercel queues, vercel cron, workflow, durable workflow, durable function, turbopack, turborepo, remote cache, build cache, image optimization, next/image, next/font, speed insights, web analytics, log drains, log drain, marketplace, vercel marketplace, ai gateway, ai sdk, vercel ai sdk, useChat, streamText, generateText, generateObject, streamObject, ai elements, chat sdk, vercel agent, v0, v0.dev, v0.app, react 19, react 20, neon postgres vercel, shadcn vercel, vercel storage, frontend cloud, vercel platform, vercel build, vercel dev, vercel env, vercel link, vercel teams, vercel domains, vercel monitoring, edge config read, vercel toolbar, draft mode, dynamic io, dynamicIO, after, unstable_after, taintObjectReference, taintUniqueValue.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "4.0.0"
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

# Vercel Stack Pack — Team Briefing

You're working on the Vercel Frontend Cloud. This is a **knowledge overlay**, not a new specialist. The existing ETYB team is doing the work — frontend-architect writes the Next.js App Router code, backend-architect writes the Server Actions and Route Handlers, ai-ml-engineer wires the AI SDK and AI Gateway, devops-engineer owns deployment + observability, system-architect picks the topology. This pack teaches each role what the platform expects in 2026-Q2.

**Currency stamp:** verified against Next.js 16 (and the 15.x LTS line), Vercel AI SDK v5+, Fluid Compute GA (2025), Cache Components default-on (2025-2026), PPR GA (2025-2026), Vercel Sandbox GA (2025), Workflow GA (2025-2026), and the Vercel changelog through `last_verified_on`. If today's date is more than 6 months past that, the pack is stale — warn the user and consult [vercel.com/changelog](https://vercel.com/changelog) + [github.com/vercel/next.js/releases](https://github.com/vercel/next.js/releases) before asserting feature-level details.

## What changed in 2025-2026 that older training data misses

Critical context. An LLM with a 2024 cutoff will get these wrong:

- **Next.js 16 shipped** (late 2025) with **Cache Components** as the recommended caching model. The `'use cache'` directive at file, function, or component scope, paired with `cacheLife()` and `cacheTag()`, is the new default — replacing ad-hoc `fetch(..., { next: { revalidate } })`, `unstable_cache`, and `export const revalidate = N` for most cases. Old patterns still work in 15.x, but new builds should adopt Cache Components.
- **Partial Prerendering (PPR) is GA** and the **default rendering model** for new App Router projects in Next.js 16. A single route can ship a static shell with streamed Suspense holes — this is neither SSG, SSR, nor ISR in the classical sense. Mental models built before PPR will fight the framework.
- **Fluid Compute went GA in 2025** and changed Vercel Functions billing/concurrency math fundamentally. Functions now multiplex in-process concurrency, bill on active CPU rather than wall-clock GB-seconds, and dynamically scale CPU within a single instance. "Cold start vs warm" reasoning from the pre-Fluid era is wrong. Edge and Node runtimes are converging — many use cases that demanded Edge Runtime now run cheaply on Fluid Node.
- **Vercel Postgres is Neon under the hood.** Old `@vercel/postgres` SDK calls still work but the Marketplace direction is for users to provision Neon (or another Marketplace Postgres) directly. New projects should use `@neondatabase/serverless` (or Prisma/Drizzle pointing at Neon) rather than reaching for `@vercel/postgres`.
- **Vercel KV is a Marketplace integration**, typically powered by Upstash. Same pattern — new code should treat Marketplace as the primary path. `@vercel/kv` still works but the storage UX leads with partner provisioning.
- **Vercel Sandbox GA'd in 2025** — microVM-isolated execution for running untrusted code (AI-generated code, agent tool outputs, user-submitted scripts). If a request involves "let an LLM run code" or "execute user-submitted code," Sandbox is the answer, not a homegrown VM2/subprocess.
- **Vercel Workflow** ships durable functions (long-running, multi-step, replay-safe) for background jobs and AI agent orchestration. Don't reach for Temporal/Inngest on Vercel before checking whether Workflow fits.
- **Vercel Queues** ships first-party producer/consumer queues with visibility timeouts and DLQs. Stop bolting on SQS/Upstash QStash for routine work-deferral.
- **Vercel AI SDK v5+** is a major rewrite. The streaming UI primitives (`streamUI`, `experimental_StreamingReactResponse`) from v3 are deprecated. Current canon: `streamText`, `generateText`, `generateObject`, `streamObject`, `tool()` definitions, `useChat()` v2, plus **AI Elements** — a shadcn-layered component library specifically for AI UIs.
- **AI Gateway** routes across providers (Anthropic, OpenAI, Google, Mistral, xAI, Groq, Fireworks, Bedrock, etc.) with observability, caching, rate limiting, and fallback — a real alternative to OpenRouter/Portkey when you're already on Vercel. Use `@ai-sdk/gateway` + `gateway('anthropic/claude-sonnet-4.7')` etc.
- **Speed Insights moved out of beta**. INP is the headline metric (replaced FID). Real User Monitoring of Core Web Vitals is one `<SpeedInsights />` component.
- **Turbopack is the production build** path for Next.js 16+ (stable for dev since Next.js 15, stable for build is rolling out). Webpack is still supported but no longer the default story.
- **Vercel Agent** (2025-2026) is the company's first-party agent platform — distinct from generic AI SDK use; verify current docs before assuming feature parity with ad-hoc agent frameworks.
- **v0** has expanded from a UI generator to a chat-driven app scaffolder (v0.app), shipping full Next.js + Tailwind + shadcn + AI SDK projects. Output quality + framework support move monthly.
- **Marketplace consolidated** vendor integrations (Stripe, Sentry, Datadog, Neon, Upstash, Resend, Inngest, etc.) with billing pass-through and one-click env var wiring. Don't manually set up integrations the user can install in two clicks.
- **`after()`** (formerly `unstable_after`) is GA: schedule work *after* the response is sent without blocking the user.
- **`taintObjectReference` / `taintUniqueValue`** are the canonical guard against accidentally serializing server-only objects/secrets into a Client Component.
- **Edge Runtime constraints loosened**. Many `node:*` modules now run in Edge contexts; some always-Edge APIs (`waitUntil`, `geolocation`) are now available in Node functions via `@vercel/functions`.

If you find yourself recommending the Pages Router for new code, `getServerSideProps`/`getStaticProps`, `unstable_cache` as the default, `streamUI` from AI SDK v3, the `@vercel/postgres` package as the primary path, or "deploy this Lambda separately" for compute that fits Fluid — you're using stale knowledge. Read the references below.

## How this pack plugs in

ETYB's router detects Vercel signals via `skills/etyb/core/stack-registry.md` and loads this SKILL.md as the team briefing. When the router dispatches to a specific role, it also loads `references/<role>.md` if one exists.

**Always-on protocols still apply unchanged.** TDD, verification, debugging, review, plan execution, brainstorm-first, branch safety, subagent coordination, self-improvement. The Vercel overlay does not relax engineering discipline; it shapes how it's applied on this platform — e.g., TDD on Next.js Server Components = Vitest + React Testing Library + msw + Playwright (component test mode); TDD on Server Actions = direct invocation in unit tests + Playwright for the form workflow.

**Delegate aggressively.** The Vercel skill suite is the most fully-featured of any vendor MCP collection — when one of the `delegate_to_skills` entries above covers a question, defer to it. This overlay is for cross-cutting judgment, role framing, and 2026 currency anchors. For depth on a single product (e.g., "how do I configure Cache Components for revalidation tags"), let the vendor skill drive.

## The Vercel surface in one diagram

Mental model of where each product sits and what role touches it:

```
                            ┌────────────────────────────────────────┐
                            │           User's Browser               │
                            └────────────────────────────────────────┘
                                            │
                                            ▼
       ┌──────────────────────────────────────────────────────────────┐
       │                    Vercel Edge Network (global CDN)          │   ← frontend-architect (caching contract)
       │   - Static assets (next/image transforms, public/)           │     devops-engineer (regions, headers)
       │   - Cached PPR shells + Cache Components data                │
       │   - Edge Config reads (<15ms)                                │
       └──────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
       ┌──────────────────────────────────────────────────────────────┐
       │       Edge Middleware (middleware.ts) — runs on every match  │   ← frontend-architect (matcher)
       │   - Auth cookie check, geo, A/B variant, redirects           │     backend-architect (auth flow)
       └──────────────────────────────────────────────────────────────┘
                                            │
                                            ▼
       ┌──────────────────────────────────────────────────────────────┐
       │              Vercel Functions (Fluid Compute)                │   ← backend-architect (topology, security)
       │   - Server Components rendering                              │     frontend-architect (RSC, Server Actions)
       │   - Server Actions (mutations)                               │     ai-ml-engineer (AI calls)
       │   - Route Handlers (webhooks, public APIs, SSE)              │
       │   - Streaming AI responses                                   │
       │   Runtime: Node (Fluid default) | Edge (specific cases)      │
       └──────────────────────────────────────────────────────────────┘
                       │              │              │
                       ▼              ▼              ▼
       ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐
       │  Workflow    │  │  Queues      │  │  Sandbox (microVM)    │   ← backend-architect (Workflow/Queues)
       │  (durable)   │  │ (async)      │  │  - AI-gen code        │     ai-ml-engineer (Sandbox for tools)
       │  Long-runs   │  │  DLQ, retry  │  │  - User scripts       │
       │  Cron driven │  │              │  │  - Agent tools        │
       └──────────────┘  └──────────────┘  └────────────────────────┘
                                            │
                                            ▼
       ┌──────────────────────────────────────────────────────────────┐
       │                       Data Plane                             │   ← backend-architect (storage choice)
       │   - Vercel Postgres / Neon  (relational + branching)         │     system-architect (data plane)
       │   - Vercel KV / Upstash Redis (sessions, rate limit, cache)  │
       │   - Vercel Blob              (uploads, generated artifacts)  │
       │   - Edge Config              (hot-path config)               │
       │   - + Marketplace: Pinecone, Upstash Vector, etc.            │
       └──────────────────────────────────────────────────────────────┘

       ┌──────────────────────────────────────────────────────────────┐
       │                    AI Layer (cross-cutting)                  │   ← ai-ml-engineer (model + tools)
       │   - AI Gateway (multi-provider routing, caching, BYOK)       │     backend-architect (tool execution)
       │   - AI SDK (streamText, generateObject, tool(), useChat())   │     frontend-architect (AI UI)
       │   - AI Elements (shadcn UI for AI)                           │
       │   - Chat SDK / Vercel Agent                                  │
       └──────────────────────────────────────────────────────────────┘

       ┌──────────────────────────────────────────────────────────────┐
       │              Observability + Deployment                      │   ← devops-engineer (everything)
       │   - Speed Insights (RUM Core Web Vitals)                     │
       │   - Web Analytics (page views)                               │
       │   - Log Drains → Datadog/Axiom/Better Stack                  │
       │   - @vercel/otel (OpenTelemetry)                             │
       │   - Preview Deployments + Comments + Toolbar                 │
       │   - Vercel CLI + Git integration + Marketplace               │
       └──────────────────────────────────────────────────────────────┘
```

Each layer is a separate engagement decision. The Vercel overlay's job is to make sure each role sees their layer correctly in 2026 — not pre-Fluid Compute, not pre-Cache Components, not pre-AI Gateway, not pre-Marketplace consolidation.

## Reference Map — what each role reads

| Role | Reference | Owns |
|------|-----------|------|
| `frontend-architect` | [`references/frontend-architect.md`](references/frontend-architect.md) | **The deep one.** Next.js 15/16 App Router defaults, Server Components vs Client Components, Server Actions, Cache Components + `'use cache'`, PPR, streaming + Suspense, `next/image`, `next/font`, Turbopack, Speed Insights/Web Vitals (INP focus), AI SDK on the client (`useChat`, AI Elements, generative UI), v0 integration, Preview Deployments + Comments workflow |
| `backend-architect` | [`references/backend-architect.md`](references/backend-architect.md) | Server Actions (security + design), Route Handlers, Vercel Functions (Fluid Compute math, Node vs Edge runtime), Workflow (durable functions), Queues, Cron, Sandbox (untrusted code), Edge Config, KV/Postgres/Blob choice, Marketplace integration patterns, webhook design, `after()` for post-response work |
| `devops-engineer` | [`references/devops-engineer.md`](references/devops-engineer.md) | Vercel CLI workflows, Git integration, Preview Deployments + branch protection, `vercel.json` config, env var management (encrypted, environment-scoped, Marketplace-wired), Turborepo + Remote Cache, Log Drains, Speed Insights/Web Analytics deployment, Marketplace add-ons, regional deployments, custom domains, build optimization, rollback flow |
| `ai-ml-engineer` | [`references/ai-ml-engineer.md`](references/ai-ml-engineer.md) | Vercel AI SDK v5+ (streamText, generateObject, tool use), AI Gateway (multi-provider routing, caching, fallback), Chat SDK, AI Elements component library, Vercel Agent, RAG patterns on Vercel (Postgres + pgvector via Neon, Upstash Vector via Marketplace), Sandbox for code-execution tools, observability (LangSmith/Helicone via Marketplace) |
| `system-architect` | [`references/system-architect.md`](references/system-architect.md) | Topology decisions — when Vercel is the whole platform vs the frontend in front of a separate backend; rendering model picks (PPR + Cache Components vs static export vs separate backend); Fluid Compute vs going to AWS/GCP for compute-heavy workloads; data-plane choice (Neon vs Supabase vs Aurora behind Vercel); multi-region patterns; cost modeling under Fluid + Image Optimization |

## The product map — what each Vercel surface is for

A grouping of the surface to ground the team's conversations:

### App layer (Next.js + framework features)

- **Next.js (App Router)** — the framework. App Router is the path forward; Pages Router is legacy maintenance.
- **Cache Components / `'use cache'`** — the 2026 default caching primitive. Tag + TTL + invalidation.
- **Partial Prerendering (PPR)** — static shell + streamed dynamic Suspense holes per route.
- **Server Components / Server Actions** — React 19 + Next.js primitives for server-rendered UI and form mutations.
- **Image Optimization (`next/image`)** — auto WebP/AVIF + multi-size srcset; budget-watch.
- **Fonts (`next/font`)** — self-hosted, zero CLS, swap-optimized.
- **Turbopack** — build + dev bundler; stable for dev in Next 15+; build is rolling out.

### Compute layer (where code runs)

- **Vercel Functions** — serverless compute; Fluid Compute model since 2025.
- **Fluid Compute** — in-instance concurrency, active-CPU billing, dynamic CPU scaling within one instance.
- **Edge Runtime** — narrower, lower-latency runtime; converging with Node since 2025.
- **Edge Middleware** — `middleware.ts`; runs before cache layer per matched request.
- **`after()`** — schedule post-response work without blocking the user.
- **Workflow** — durable, multi-step, replay-safe long-running functions.
- **Queues** — first-party async producer/consumer.
- **Cron** — scheduled HTTP calls declared in `vercel.json`.
- **Sandbox** — microVM-isolated runtime for untrusted code.
- **Vercel Agent** — Vercel's first-party agent platform (new, evolving).

### Storage layer

- **Vercel Postgres (Neon-backed)** — serverless Postgres with branching per Preview.
- **Vercel KV (Upstash-backed)** — Redis-compatible KV.
- **Vercel Blob** — object storage with presigned upload.
- **Edge Config** — read-only, ultra-low-latency config store for hot-path lookups.
- **Marketplace storage** — Pinecone, Upstash Vector, MongoDB Atlas, etc., wired via Marketplace.

### AI layer

- **AI SDK** — TypeScript-first SDK; `streamText`/`generateText`/`streamObject`/`generateObject`/`tool()`/`useChat()`.
- **AI Gateway** — multi-provider routing, caching, fallback, observability, BYOK.
- **AI Elements** — shadcn-layered AI UI component library.
- **Chat SDK** — opinionated chatbot template.
- **Vercel Agent** — first-party agent platform.

### Deployment / observability layer

- **Vercel CLI (`vercel`)** — deploy, env vars, logs, links.
- **`v0` / v0.app** — chat-driven scaffolding for Next.js + Tailwind + shadcn + AI SDK.
- **Vercel Git integration** — auto Preview per PR.
- **Preview Deployments** — per-PR/branch URL.
- **Comments + Toolbar** — inline feedback on Preview URLs.
- **Speed Insights** — RUM Core Web Vitals.
- **Web Analytics** — first-party page views.
- **Log Drains** — route logs to external destinations.
- **`@vercel/otel`** — OpenTelemetry auto-instrumentation.
- **Marketplace** — Stripe, Sentry, Datadog, Neon, Upstash, Resend, etc.
- **`vercel.json`** — config: rewrites, redirects, headers, cron, regions, function tiers.

### What's *not* on Vercel

Be explicit about what Vercel doesn't do:

- **No GPU inference.** Self-hosted models live on Modal, Replicate, Banana, RunPod, AWS, GCP, Lambda Labs.
- **No always-on background workers.** Workflow is the closest fit; for continuous consumers, use Fly/Render/Fargate/Cloudflare Durable Objects.
- **No managed search** (use Algolia, Typesense, Meilisearch via Marketplace).
- **No managed Kafka** (use Confluent, AWS MSK, Redpanda via Marketplace).
- **No relational DB beyond Postgres-flavor** (no managed MySQL, no DynamoDB-style).
- **No CI runners beyond build minutes** (use GitHub Actions, GitLab CI, etc., for non-build CI).
- **No video processing pipeline** (use Mux, Cloudflare Stream, AWS MediaConvert).
- **No native mobile build farm** (use Expo EAS, App Center).

When the user's need fits one of these, this Stack will frame the *boundary* between Vercel and the off-Vercel piece; the relevant other Stack Pack drives the off-Vercel surface.

## Top 10 platform gotchas the team must know

These are the named, high-cost mistakes that come up in real engagements. Internalize them.

1. **"Cache everything" + dynamic data = broken pages or stale data.** Next.js 16's default with Cache Components is *not* "cache nothing" — it's "cache what you tagged, render the rest dynamically." If you don't mark a Server Component or function with `'use cache'`, it renders dynamically per request (or per PPR Suspense boundary). Forgetting `cacheTag()` means you can't invalidate. Forgetting `cacheLife()` means TTL is the platform default. Tag aggressively, invalidate via `revalidateTag()` in Server Actions.

2. **Server Components leaking server-only data into the client.** Returning a raw DB row from a Server Component to a Client Component child via props can serialize and ship secrets (or PII) to the browser if you're not careful. Use `taintObjectReference()` on sensitive objects and `taintUniqueValue()` on secrets — they make `Server Component → Client Component` boundary crossings throw. Pair with `import 'server-only'` at the top of any module that must never reach the client.

3. **Server Actions are public HTTP endpoints with hidden POST bodies.** They look like function calls but every Server Action is a callable URL. Authorize *inside* every action (`auth()` check), validate input (Zod) every time, rate-limit any action that creates state, and never trust the `formData` shape. Use `taintUniqueValue` on the action's encryption key if you handle it. Action IDs rotate per deployment; pin the encryption key (`NEXT_SERVER_ACTIONS_ENCRYPTION_KEY`) if you have multiple regions or rollover sensitivity.

4. **Image Optimization can blow your budget.** `next/image` transforms count against a per-plan quota. A page that lists 100 user-uploaded avatars at 4 sizes each will burn through the quota in days. Mitigations: set realistic `sizes`/`deviceSizes`/`imageSizes`, host static assets on Blob with CDN-cached fixed URLs (skip optimization), use `placeholder="blur"` only when you have blurDataURL pre-computed, consider Cloudflare Images / imgix for high-volume catalogs.

5. **Fluid Compute concurrency hides bad code.** Because functions multiplex in-process, a slow downstream (DB, LLM) no longer maps 1:1 to "cold function" cost. Bad N+1 queries and unbounded fetches become "expensive but not obvious" instead of "timeout and fail." Add tracing (OpenTelemetry via `@vercel/otel`), watch active CPU, set `maxDuration` on the function (vercel.json `functions` block).

6. **Edge Middleware is on the hot path of *every* matched request.** `middleware.ts` runs before the cache layer — a 50ms middleware adds 50ms to every cached page hit. Keep it ruthless: feature flag reads from Edge Config, auth cookie checks, geo redirects. Anything that needs a DB query belongs in the page/action, not middleware. The `matcher` config is your friend; default-match is a trap.

7. **Preview Deployments are isolated environments, not staging.** Every PR/branch gets its own URL with its own env scope. Don't assume "preview" means "staging DB" — it pulls Preview-scoped env vars. If you have a single staging DB, point Preview env to it explicitly; otherwise plan for ephemeral data (Neon branching is the right answer). Preview password protection + Comments are useful but not a substitute for SSO/auth on the app itself.

8. **AI Gateway is opinionated — don't fight the abstraction.** It's a unified provider API with built-in caching, retries, fallback, BYOK, and observability. If you're building your own router on top of `streamText`, you're duplicating Gateway. The provider catalog updates faster than docs cache; check `/v1/models` at runtime for the live catalog. Watch token pricing — Gateway prices are pass-through plus a margin; for huge volume, BYOK to your provider directly is cheaper.

9. **Marketplace billing passes through to your Vercel invoice.** Convenient, but it makes the "cheapest stack" question harder than reading individual vendor pricing — Vercel's margin sits between you and the provider. For mature/large teams, install the underlying vendor (Neon, Upstash, Stripe, Datadog) directly and use Marketplace only for the rapid wiring of new dependencies. For startups it's the right default — one bill, one OAuth, no surprises.

10. **The Pages Router and the App Router are different products in the same repo.** Mixing is supported but every "mix" page is a fork in your team's mental model. If a codebase still has `pages/`, finish the migration before adopting Cache Components, PPR, Server Actions in earnest — those features are App Router-only and the Pages Router fallback paths drift in subtle ways. Use `vercel:next-upgrade` skill for migrations.

## Standing instructions for every role on a Vercel engagement

1. **Anchor to currency.** Before recommending Next.js version-specific syntax, `vercel.json` schema, AI SDK API shape, or CLI flags, check whether the role overlay covers your area. If covered, follow it; do not pattern-match from older general-purpose knowledge. If not yet covered, say so explicitly and consult [vercel.com/changelog](https://vercel.com/changelog) + [nextjs.org/docs](https://nextjs.org/docs) before asserting specifics. Cite source URLs when making time-sensitive claims.

2. **Delegate when a vendor skill is loaded.** If the user's environment has `vercel:nextjs`, `vercel:ai-sdk`, `vercel:vercel-cli`, etc., let them drive on their product depth. This overlay's value is *across* products + *role-shaped* framing. Don't duplicate their material when they're present.

3. **Defer to verticals on domain compliance.** Vercel runs on AWS infrastructure — that's a platform fact in scope. HIPAA-eligible BAA, PCI scope reduction, SOC 2 controls — those route to healthcare-architect/fintech-architect/security-engineer respectively. Don't restate compliance content; route to the vertical.

4. **Respect platform limits.** Every Fluid function recommendation must consider: `maxDuration` (60s default, up to 800s on Pro / 900s Enterprise), function payload size (4.5MB request body default), response streaming chunk limits, function instance memory, Image Optimization transforms per month, Cache Components storage quotas, KV/Postgres/Blob quotas. Read [vercel.com/docs/limits](https://vercel.com/docs/limits) before designing around them.

5. **Stay specific about Vercel surfaces.** "Vercel" is not one thing. Next.js (the framework) vs the deploy platform (Vercel as deployer) vs the runtime (Fluid Compute / Edge Network) vs the integrated products (Workflow, Queues, AI Gateway, KV, Postgres, Blob, Sandbox) — these have different constraints, pricing, and maturity. Ask if it's unclear.

6. **Honor Server Component / Client Component boundaries.** A huge class of Vercel/Next.js bugs comes from violating these — secrets leaking, hydration mismatches, "module not found in browser bundle." `import 'server-only'` and `import 'client-only'` are not optional hygiene; they're the boundary contract. Use them.

## Compliance composition

When Vercel work touches a regulated vertical, the Stack defers to the vertical for the compliance shape and only owns the platform-side wiring:

| Vertical concern | Owns | Vercel Stack handles |
|------------------|------|----------------------|
| **HIPAA / PHI** | `healthcare-architect` | BAA scope (Vercel signs BAA on Enterprise tier — verify current), routing PHI through Vercel Functions, log-drain redaction patterns, Sandbox isolation for AI-with-PHI |
| **PCI DSS / payments** | `fintech-architect` (also `e-commerce-architect`) | Stripe Marketplace integration patterns, never log card data in Functions, Edge Middleware for fraud scoring, Server Actions for tokenized flows |
| **SOC 2 / general controls** | `security-engineer` | Vercel's own SOC 2 reports (download from Trust Center), env var encryption, deployment audit logs, log-drain retention, RBAC on Vercel Teams |
| **GDPR / data residency** | `security-engineer` + `system-architect` | Function `regions` config in `vercel.json`, Edge Network regions, Neon/Marketplace data residency, Log Drain destination region |
| **AI/LLM safety, EU AI Act** | `ai-ml-engineer` + `security-engineer` | AI Gateway PII redaction, Sandbox isolation, prompt injection defenses, `taintObjectReference` for secret-flow |

Don't restate the vertical's compliance content. Route to the vertical for the *what*; this Stack supplies the *how on Vercel*.

## Stack composition

If the user is using Vercel **plus** another stack (Cloudflare for DNS/Workers at the edge, AWS for backend services, Supabase for auth+DB, Anthropic Claude direct, Stripe for billing), and that other stack has its own pack registered in `STACKS.md`, both overlays load. The Vercel pack handles Vercel-side patterns (Server Actions calling out, Marketplace wiring, deployment topology); the other pack handles its side. Neither pack pretends to know the other's depth.

Common Vercel × other combinations:

- **Vercel + Cloudflare** — Cloudflare for DNS, R2 for object storage when Blob doesn't fit budget, Workers for ultra-low-latency edge logic Vercel Functions can't reach. Vercel for the app surface + Functions for app logic. Both packs need to agree on cache hierarchy (Cloudflare Cache → Vercel Edge → Cache Components).
- **Vercel + AWS** — Vercel for the user-facing app; AWS for heavy backend (RDS Postgres, SQS, Lambda for legacy services, S3 for blob at scale). Talk via REST/GraphQL/webhook. Vercel pack handles the frontend; AWS pack handles the backend services.
- **Vercel + Supabase** — Supabase for auth + Postgres + Realtime + Storage; Vercel for the Next.js layer. Server Components fetch via Supabase server client (cookie-bound) + Server Actions write via Supabase. Both packs need to agree on session management.
- **Vercel + Anthropic Claude** — Anthropic Stack covers Claude API patterns + Agent SDK; Vercel Stack covers AI SDK provider config + AI Gateway routing + AI Elements UI. AI Gateway can front Claude API + give Vercel-native observability.
- **Vercel + Stripe** — Stripe Marketplace integration auto-wires env vars + webhook URLs; Stripe Stack covers product/price/subscription semantics; Vercel Stack covers webhook Route Handlers + Server Action checkout flows + Edge Middleware for entitlement checks.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Compliance specifics for HIPAA / PCI / GDPR / EU AI Act | `healthcare-architect` / `fintech-architect` / `security-engineer` |
| Multi-tenant SaaS architecture (tenant isolation, billing) | `saas-architect` |
| E-commerce checkout / catalog architecture | `e-commerce-architect` |
| Real-time at scale (millions of concurrent connections) | `real-time-architect` + likely Cloudflare/AWS Stack |
| Mobile app consuming a Vercel-hosted API | `mobile-architect` + `expo` Stack if Expo |
| Database design + migration beyond "Neon Postgres" surface | `database-architect` |
| Generic React/UI question not Vercel-specific | `frontend-architect` (without the pack overlay) |
| Backend service that doesn't run on Vercel | `backend-architect` (without the pack overlay) |
| Non-Vercel observability stack | `sre-engineer` + `observability` Stack |

## Currency

This pack moves on every release review. Maintainers set `last_verified_on` and verify every `authoritative_sources.primary` URL returns 200. Drift-risk thresholds:

- **High-drift products** (Next.js, Cache Components, PPR, Fluid Compute, AI SDK, AI Gateway, Workflow, Sandbox, v0, Vercel Agent, Vercel Postgres) — refresh every **90 days**. The Vercel + Next.js cadence is fast; a 4-month-stale Next.js claim is likely wrong.
- **Medium-drift products** (Server Actions, Edge Middleware, KV, CLI, Turbopack, Marketplace) — refresh every **180 days**.
- **Low-drift products** (Cron, Edge Config, Blob, vercel.json schema, Speed Insights, Web Analytics, Log Drains, Preview Deployments, Image Optimization, Turborepo Remote Cache) — refresh every **365 days**.

If `last_verified_on` is more than 6 months ago, treat every claim in this pack about high-drift products as suspect and re-verify against [vercel.com/changelog](https://vercel.com/changelog) and [nextjs.org/blog](https://nextjs.org/blog) before recommending API-level details.

## Defaults this overlay assumes

When the team is on a Vercel engagement and no other constraint argues otherwise, these are the 2026 defaults to start from:

- **Framework**: Next.js App Router on the latest stable major (16 at last_verified_on; 15.x LTS still acceptable for legacy projects).
- **Package manager**: pnpm (Vercel's first-class), or bun for greenfield where the ecosystem fits.
- **Runtime**: Node (Fluid Compute). Edge runtime only when there's a measured reason.
- **Caching**: Cache Components with `'use cache'` + `cacheLife()` + `cacheTag()`. Old fetch caching as fallback.
- **Rendering**: PPR with explicit `<Suspense>` boundaries. Static export only for genuinely static sites.
- **State**: React Server Components for data fetch, Server Actions for mutations, Client Components only when interactive.
- **Database**: Vercel Postgres / Neon (Marketplace), Drizzle or `@neondatabase/serverless` HTTP driver.
- **KV / cache**: Vercel KV (Upstash Marketplace) for sessions, rate limit, idempotency.
- **Object storage**: Vercel Blob for uploads under PB scale; Cloudflare R2 for large catalogs / egress-sensitive.
- **Config**: Edge Config for hot-path config; env vars for secrets; Marketplace integrations auto-wire env vars.
- **Auth**: Auth.js for general OAuth + email/passkey; Clerk for turnkey; WorkOS for enterprise SSO; Supabase Auth in Supabase composition.
- **AI**: AI Gateway for provider-agnostic routing; AI SDK v5+ for the call surface; AI Elements for UI; Sandbox for untrusted-code tools.
- **Long-running**: Workflow for durable steps; Queues for async work; `after()` for fire-and-forget; Cron for schedules.
- **Observability**: `@vercel/otel` + Log Drain to Axiom/Datadog; `<SpeedInsights />` + `<Analytics />` in root layout.
- **Deployment**: Git-integrated Preview Deployments; required CI checks on PR (lint, typecheck, unit, E2E against Preview URL, visual regression, a11y); production via merge to main.
- **Security headers**: HSTS, X-Content-Type-Options, Permissions-Policy, Referrer-Policy in `vercel.json`; CSP iteratively from `report-only`.
- **Cost discipline**: per-route function tiers in `vercel.json`; image transform budget tuned; cost alerts at team level.

Depart from defaults *deliberately* with a recorded rationale (PR description, ADR), not by inertia.

## Open gaps in v4.0.0

Explicit so future iterations know what's missing:

- **No mobile-architect overlay** — React Native on Vercel is limited (Vercel hosts the API + web app; the mobile build itself is Expo/EAS). When a Vercel-backed React Native app is the topic, the Expo Stack drives mobile concerns, this pack drives the Vercel API surface; no dedicated overlay yet.
- **No qa-engineer overlay** — Vercel-specific QA patterns (Preview URL E2E in CI, Comments workflow, Playwright on Vercel) are covered piecemeal across other overlays; standalone overlay deferred until demand justifies.
- **No technical-writer overlay** — `llms.txt`, doc-as-code, and AI-ready docs patterns sit naturally on Vercel but aren't yet broken out.
- **No vertical overlays inside this pack** — saas-architect and e-commerce-architect have heavy use cases on Vercel but the vertical references already cover them; no pack-internal vertical overlay yet.
- **No deep Turborepo coverage** — covered at a level sufficient for devops-engineer + system-architect; deep Turborepo refactoring deferred to a future iteration or a Turborepo-specific reference.

If a user's request hits any of these gaps, say so explicitly and proceed with general-purpose knowledge plus current-changelog validation.
