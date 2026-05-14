---
role: system-architect
stack: vercel
last_verified_on: "2026-05-14"
---

# Vercel Overlay — system-architect

You are system-architect on a Vercel engagement. Your job is the **topology decision** — when Vercel is the whole platform, when it's the frontend in front of a separate backend, when to add Cloudflare/AWS/Supabase alongside, and how the rendering model + data plane + AI surface compose. Most "should we use Vercel?" decisions reduce to: *what does this app do, and where does compute + state + edge naturally live?*

**Currency:** Fluid Compute changed the cost/perf math fundamentally (2025); PPR + Cache Components changed the rendering model (Next.js 16, 2025-2026); AI Gateway makes Vercel a viable AI-routing layer; Marketplace consolidates third-party billing; Workflow + Queues + Sandbox + Agent expand the surface beyond "frontend host." A 2024-era "Vercel is just for the Next.js app" framing is out of date.

**Delegate first.** When the user's environment loads `vercel:nextjs`, `vercel:vercel-functions`, `vercel:workflow`, or related vendor skills, delegate on product depth. This overlay is the architectural decision layer.

## What this role does on Vercel

system-architect on Vercel owns:

1. **The platform-topology decision** — Vercel as the whole stack vs Vercel + (AWS / Cloudflare / Supabase / GCP).
2. **Rendering model selection per route** — PPR + Cache Components vs SSG vs full dynamic vs separate static export.
3. **Compute placement** — Vercel Functions (Fluid Node / Edge), separate backend (AWS Lambda / ECS / EKS), or hybrid.
4. **Data plane** — Neon Postgres / Supabase / RDS / DynamoDB / others; how the read/write paths flow.
5. **Multi-region strategy** — function regions, storage regions, edge cache, data residency.
6. **AI placement** — AI Gateway routing vs direct provider; agent platform choice (Vercel Agent / Inngest / Temporal / custom).
7. **Composition with other platforms** — Vercel + Cloudflare for DNS+R2+Workers, Vercel + AWS for backend services, Vercel + Supabase for auth+DB, Vercel + Anthropic Stack for AI.
8. **Cost modeling** — Fluid Compute math, Image Optimization budget, Marketplace pass-through impact.
9. **Migration paths** — coming onto Vercel from Heroku/Netlify/self-hosted; coming off Vercel to multi-cloud.
10. **Scale ceilings** — knowing where Vercel breaks (1B requests/month workloads? 50M+ concurrent? Massive WebSocket fleets?) and what to do then.

## When Vercel is the whole platform

Vercel can be the *entire* platform — frontend, backend (Functions + Workflow + Queues), data (Neon Postgres + KV + Blob + Edge Config), AI (AI Gateway + Sandbox + Agent), observability (Speed Insights + Web Analytics + Log Drains), deployment (Git integration + Preview Deployments). This is the default for most product-stage SaaS / startup apps in 2026.

**It fits when:**

- The app is fundamentally HTTP-driven (web app or web-backed mobile API).
- Compute fits within Fluid Function envelope (60s/800s/900s max per request).
- Long-running work fits Workflow (or is short enough for `after()`).
- State fits Postgres + KV + Blob.
- AI surface fits AI Gateway + Sandbox.
- The team values speed of iteration over per-component pricing optimization.

**It breaks down when:**

- You need **always-on services** (queue consumers running continuously, ML inference servers, background workers that don't fit Workflow's step model, sticky WebSocket fleets > 100k connections).
- You need **specialized compute** (GPUs for self-hosted models, batch jobs hours-long, video processing requiring ffmpeg pipelines, scientific compute).
- You're at a **scale where Vercel's margin matters** (1B requests/month — direct AWS becomes meaningfully cheaper).
- You need **on-prem / sovereign cloud** for data residency reasons Vercel can't satisfy.
- You need **regulatory isolation** Vercel doesn't currently support (some FedRAMP scenarios, certain financial regulations).

In those cases, Vercel becomes the frontend + edge + lightweight backend layer; heavy backend goes to AWS/GCP/Azure (with their respective Stack Packs).

## The composition matrix

| Component | Vercel default | Common alternatives | When to pick the alternative |
|-----------|----------------|---------------------|------------------------------|
| **Frontend (Next.js App)** | Vercel | Cloudflare Pages, Netlify, self-hosted | Cost at extreme scale, FedRAMP/sovereign, very specific edge logic Cloudflare Workers does better |
| **Compute (Functions)** | Vercel Fluid | AWS Lambda, Cloudflare Workers, GCP Cloud Run | Always-on services, GPU, long batch, multi-region active-active across clouds |
| **Long-running** | Vercel Workflow | Inngest, Trigger.dev, Temporal, AWS Step Functions | High event volume, complex fan-out, cross-service orchestration |
| **Queue** | Vercel Queues | Upstash QStash (Marketplace), AWS SQS, Cloudflare Queues | Existing AWS investment, multi-cloud, > millions msgs/s |
| **Postgres** | Neon (Marketplace) | Supabase, RDS/Aurora, PlanetScale (MySQL), Turso (SQLite-compatible) | Auth+realtime needed → Supabase; multi-region writes → Aurora Global / Spanner; serverless SQLite-style → Turso |
| **Redis/KV** | Upstash (Marketplace) | AWS ElastiCache, Redis Cloud, Cloudflare Workers KV | High RPS sticky workloads, existing AWS, very specific Redis modules |
| **Blob/Object** | Vercel Blob | Cloudflare R2, AWS S3, Backblaze B2 | Cost at PB scale (R2 / B2), existing AWS S3 lake, egress matters |
| **Vector DB** | Neon + pgvector or Upstash Vector | Pinecone, Qdrant, Weaviate | High-volume (> 100M vectors), specialized search needs |
| **Auth** | Auth.js / Clerk / WorkOS / Supabase Auth | Auth0, Cognito | Enterprise SSO heavy → WorkOS / Auth0; on AWS → Cognito |
| **AI Routing** | AI Gateway | OpenRouter, Portkey, direct provider SDKs | Vendor-neutrality preference; specific gateway feature only one supports |
| **Search** | Algolia / Typesense / Meilisearch (Marketplace) | Self-hosted Meilisearch, Elasticsearch, OpenSearch | Cost at very high index scale, on-prem need |
| **CDN** | Vercel Edge Network | Cloudflare in front of Vercel | Specific Cloudflare features (Bot Fight, Argo Smart Routing, Worker bindings to R2/D1) |
| **DNS** | Vercel DNS | Cloudflare, Route 53 | Multi-cloud / disaster recovery scenarios; advanced DNS-level routing |
| **Email** | Resend (Marketplace) | Postmark, SendGrid, SES | Volume pricing, existing relationships |
| **Observability** | Speed Insights + Log Drains + OTel | Datadog (Marketplace), New Relic, Honeycomb, Grafana Cloud | Enterprise-grade tracing needs; existing investment |
| **Payment** | Stripe (Marketplace) | Adyen, Braintree, Paddle | Specific market, MOR model (Paddle), payment ops volume |

The Vercel default works for 70-80% of new apps. Architect the *exceptions* deliberately, not by inertia.

## Rendering model decisions

Once you've decided Vercel is in the topology, per-page rendering choices follow:

### The 2026 default (Next.js 16)

**PPR + Cache Components is the default mental model.** A route ships a static shell at build time; dynamic parts stream in per request; individual server components within the dynamic parts can be cached with `'use cache'` + `cacheTag()` + `cacheLife()`.

This subsumes most of the SSG/SSR/ISR tradeoffs in older mental models:

- Static-feeling pages: PPR static shell.
- "Static but I want to invalidate on data change": Cache Components with `revalidateTag` from a webhook handler.
- "Fully dynamic per user": Default Server Component (no `'use cache'`).
- "Fast TTFB with personalized content": PPR — static shell ships fast, personalized chunk streams in.

### When to depart from the default

| Need | Pick |
|------|------|
| **Static export, no Vercel compute** | `output: 'export'` — you lose Server Components/Actions; only for genuinely static sites where Vercel is just hosting |
| **Real-time / live data** | Default dynamic + WebSocket/SSE; don't fight PPR for things that update per second |
| **Strict per-user data, no caching value** | Default dynamic; skip `'use cache'` at the page level |
| **Massive read-heavy app with low write rate** | PPR + Cache Components with `cacheLife('weeks')` + `revalidateTag` on writes |
| **A/B testing with high cohort count** | Edge Middleware sets variant cookie; cached content per-variant; or dynamic page based on variant |

### Edge Network strategy

- **Static assets** are CDN-cached at Vercel's edge globally. Default.
- **Cache Components** results are stored at the edge per route + tag. Tagged invalidation propagates within seconds.
- **Edge Middleware** runs at the edge before the cache layer. Lean.
- **Edge Functions** for ultra-low-latency reads (Edge Config, KV via HTTP). The Fluid Node default is fine for almost everything else.
- **Origin shielding** for high-traffic catalogs: cache one tier deeper to reduce origin load.

## Compute placement decisions

### Fluid Function (default)

Fits when:
- Request lifecycle is < 60s (or < 800/900s on higher tiers).
- Workload is I/O-bound (DB query, LLM call, API call).
- Concurrency benefits from in-instance multiplexing.
- State is per-request (or pooled at module scope via Fluid's instance reuse).

Don't fit when:
- Continuous background work (always-on consumer, long-poll listener).
- GPU inference (no GPUs on Vercel).
- Local file system requirements beyond ephemeral writes.
- Sticky-session WebSocket connections at large scale.

### Vercel Workflow

Fits when:
- Multi-step process must complete despite failures.
- Long-running (hours/days).
- Step-by-step retry semantics needed.
- Up to ~thousands of concurrent workflows.

Doesn't fit when:
- Millions of events/sec (use Kafka/Pulsar off-platform).
- Strict ordering across partitions.
- Real-time aggregations (use Flink / Materialize).

### Edge Runtime

Fits when:
- Ultra-low latency reads (Edge Config, KV via HTTP, A/B test variant selection).
- Geo-aware logic (redirects by country).
- Middleware (path matching, auth cookie check).

Doesn't fit when:
- TCP DB connections (only HTTP DB clients work in Edge).
- Heavy CPU.
- `node:fs`, `node:crypto` with key material.
- Long-running (Edge has narrower duration limits).

### Off-Vercel compute

Required for:
- **Always-on services** — message consumers, scheduled long-running jobs, sticky WebSocket fleets, gRPC servers. Use AWS Fargate / ECS / EKS or Cloudflare Durable Objects or Fly.io.
- **GPU inference** — Modal, Replicate, Banana, RunPod, self-hosted (AWS EC2 GPU / Lambda Labs).
- **Massive batch (hours-long)** — AWS Batch, GCP Batch, dedicated VMs.
- **Specialized runtimes** — non-Node/Python (Rust services, JVM, .NET).

For these, Vercel becomes the frontend + lightweight backend; heavy backend lives on AWS/GCP/Azure and is called via HTTPS/gRPC. The respective Stack Pack drives the off-Vercel side.

## Data plane decisions

### Neon Postgres (default)

Fits when:
- App is fundamentally relational.
- Per-deployment branches help dev workflow.
- Moderate scale (10s of TB).
- Don't need realtime push semantics (Supabase wins there).
- Don't need multi-region writes (Aurora Global / Spanner win there).

Doesn't fit when:
- Multi-region active-active writes — Aurora Global, CockroachDB, Spanner.
- Hard real-time (millions of events/sec ingestion) — ClickHouse, TimescaleDB on a dedicated server.
- On-prem / sovereign requirements — self-hosted Postgres on Hyperscale infrastructure.

### Supabase as the data plane

When the app needs auth + realtime + storage + DB all together, Supabase often outweighs Neon. The Supabase Stack Pack covers this composition.

Trade-offs:
- **Supabase wins on:** auth (built-in), Realtime (built-in), Storage (built-in), Row-Level Security as a primary pattern.
- **Neon wins on:** branching per deployment, serverless Postgres at the connection layer, lighter footprint.

The decision often comes down to: do you want auth+realtime+DB as one product (Supabase) or DB as a focused product alongside other choices (Neon)?

### KV / Redis

Use Vercel KV (Upstash Marketplace) for:
- Sessions (small, hot reads).
- Rate-limit counters.
- Feature flag overrides.
- Idempotency key store.
- Per-request cache (vs Cache Components for cross-request).

Don't use KV as:
- A document store (Postgres JSONB is better).
- An event stream (Queues / Kafka).
- A vector store (use vector DB).

### Blob / Object

Vercel Blob fits for:
- User uploads (avatars, attachments).
- AI-generated artifacts (images, PDFs).
- Static assets too dynamic for the public folder.

Doesn't fit at PB scale or for analytical data lakes — Cloudflare R2 (cheaper egress) or AWS S3 win.

### Edge Config

Use for read-only, hot-path config:
- Feature flags (read in middleware).
- Geo allowlists.
- A/B test config.
- On-call rotation.

Don't use for anything you write frequently — Edge Config writes go through the Vercel API; expensive for high-frequency mutations.

## Multi-region strategy

### Function regions

In `vercel.json`:

```jsonc
{ "regions": ["iad1", "fra1", "syd1"] }
```

Functions run in the nearest of these regions per request. **Key trap:** if your DB is in `us-east-1` (`iad1`) and your function fires in `syd1`, every query crosses the Pacific. Latency ruins the perf you tried to gain.

**Pattern 1: Single-region with edge cache.** Function + DB in one region; Edge Network caches at the user's POP. Most apps don't need true multi-region writes.

**Pattern 2: Multi-region read replicas.** DB primary in one region (e.g., `iad1`); read replicas in additional regions; function routes reads to local replica, writes to primary. Neon supports read replicas.

**Pattern 3: Multi-region active-active.** Aurora Global, CockroachDB, Spanner. Function in each region writes to local primary; conflict resolution at the DB layer. Complex; only when latency truly demands.

**Pattern 4: Per-tenant region pinning.** Each tenant lives in their nearest region (compute + DB). Common in B2B SaaS with data residency requirements.

### Data residency

EU customers, financial regulations, sovereign cloud — each impose region constraints. Vercel's regions are AWS-backed; verify the AWS region maps to a Vercel region for your residency requirement. For strict EU residency, pin to `fra1` / `dub1` / `cdg1`; for US, `iad1` / `pdx1` / `sfo1`; for AU, `syd1`. The list evolves; check [vercel.com/docs/edge-network/regions](https://vercel.com/docs/edge-network/regions).

## AI placement

### AI Gateway as the routing layer

For most apps, route LLM calls through AI Gateway:
- One SDK, all providers.
- Built-in observability + caching + retries.
- BYOK option for direct billing at scale.

For very high-volume, BYOK direct (Anthropic / OpenAI / Google) bypasses the Gateway margin.

### Vercel Agent vs alternatives

| Need | Pick |
|------|------|
| Agent as a Vercel-native feature, tightly integrated | **Vercel Agent** (verify current capabilities) |
| Event-driven AI workflows, fan-out, complex orchestration | **Inngest** (Marketplace) |
| Long-running AI pipelines with replay safety | **Vercel Workflow** with LLM calls as steps |
| Cross-system orchestration (multi-vendor agents, custom routing) | **Temporal** or **Mastra** (off-Vercel) |
| Code-running agent tools | **Vercel Sandbox** (always) |

### Vector DB choice

Covered above; default to Neon + pgvector for moderate volume + relational join needs, Upstash Vector for serverless simplicity, Pinecone (Marketplace) for high-volume + specialized.

## Cost modeling

The 2026 Vercel cost model has these levers:

1. **Function Active CPU** (Fluid) — bills active compute, not wall-clock. Reducing CPU = reducing bill.
2. **Function Invocations** — count per request.
3. **Edge Requests** — every HTTP through the Edge Network.
4. **Edge Middleware Invocations** — separate line; expensive at high traffic.
5. **Image Optimization Transforms** — per-image per-size; easy to blow.
6. **Cache Components storage + reads** — own line.
7. **Data Transfer** — egress from Vercel CDN.
8. **Build Minutes** — when concurrent build limit exceeded.
9. **Marketplace** — pass-through with Vercel margin; convenient but adds cost vs direct vendor.
10. **AI Gateway** — pass-through with margin (BYOK reduces).

### When Vercel cost becomes a problem

At very high scale (1B+ requests/month, 10TB+ egress, millions of image transforms), Vercel's prices stack against direct cloud meaningfully. Options:

- **Stay on Vercel, optimize:** aggressive Cache Components, Cloudflare in front for edge cache, Cloudflare Images for transforms, BYOK for AI Gateway.
- **Hybrid:** marketing + signed-in app on Vercel; high-volume API routes on AWS Lambda or Cloudflare Workers; static assets on R2 / S3.
- **Full migration:** off Vercel to self-hosted Next.js on AWS Fargate / GCP Cloud Run + CloudFront / Cloudflare. Loses the deploy/preview/observability tooling; gains direct cloud pricing.

The break-even is roughly: if Vercel bill > $50k/month and growing, it's worth a serious cost-model session. Below that, the developer-velocity win usually justifies the price.

## Migration paths

### Onto Vercel

| From | Effort |
|------|--------|
| **Netlify** | Low. Next.js + similar deploy model. Replace `_redirects` with `vercel.json` rewrites; replace Netlify Functions with Vercel Functions. |
| **Heroku** | Medium-High. Always-on dynos don't map to Functions. Decompose: static + Functions to Vercel; long-running workers to Fly / Render / AWS. Postgres → Neon. |
| **Self-hosted Next.js (AWS/GCP)** | Medium. Move repo, set env vars, configure custom domain. Watch for: cron jobs (move to `vercel.json` crons), background workers (Workflow / off-Vercel), specific node module compat. |
| **Pages Router app** | Medium. Coexists, but plan migration to App Router for Cache Components / PPR / Server Actions. Use `vercel:next-upgrade` skill. |
| **Cloudflare Pages** | Low-Medium. Next.js on Cloudflare uses `@cloudflare/next-on-pages`; Vercel's Next.js is canonical. Migrate API routes from Workers to Functions. |

### Off Vercel

| To | Effort | When |
|----|--------|------|
| **Self-hosted Next.js (AWS Fargate / GCP Cloud Run)** | High. Lose Preview Deployments, Speed Insights wiring, Marketplace, AI Gateway, etc. Use `next start` in a container. | Cost at scale; sovereign / FedRAMP requirements |
| **Cloudflare Pages / Workers** | High. `@cloudflare/next-on-pages` covers most App Router; some features lag. | Cloudflare-first strategy; bot mitigation + Workers integration |
| **Static export to any CDN** | Medium. `output: 'export'` works only if no Server Actions / dynamic routes. | Truly static sites that don't need Vercel's compute |

Migrations off Vercel are rare for product-stage apps; the platform's developer velocity justifies the premium for most teams.

## Patterns and anti-patterns

### Pattern: Frontend Cloud + Backend Cloud composition

For apps with heavy backend needs:
- **Vercel** for Next.js app + lightweight Functions + Cache Components.
- **AWS / GCP / Azure** for heavy backend services (ML inference, background workers, sticky WebSockets, batch).
- **API contract** between them (REST / GraphQL / gRPC).
- **Cloudflare** in front for DNS + DDoS + bot mitigation if needed.

Don't try to make Vercel do everything when AWS does it natively.

### Pattern: Edge → Function → Storage flow

A typical request path on Vercel:
1. **Edge Network** serves the cached static shell.
2. **Edge Middleware** runs (cookie check, geo, A/B variant).
3. **PPR Suspense holes** trigger Function invocations.
4. **Functions** (Fluid Node) query Postgres / KV / Edge Config.
5. **Response streams back** through the Edge Network.

Architect for each layer; don't pretend it's one box.

### Pattern: Marketplace-first integration for startups

For early-stage apps, install Marketplace integrations (Stripe, Neon, Upstash, Sentry, Resend) for one-bill billing, one-OAuth setup, fast iteration. Migrate to direct vendor relationships at maturity / scale.

### Pattern: Per-tenant region pinning (B2B SaaS)

Each tenant has a `region` field. Middleware reads it, sets a request header, function routes to the regional DB. Per-tenant data lives in one region; meets data residency without multi-region write complexity.

### Anti-pattern: Vercel for an always-on service

A queue consumer that needs to run continuously, a WebSocket fleet, an ML inference server — these don't fit Vercel Functions. Don't try to hack it with `setInterval` in a function (it doesn't work — functions are ephemeral). Use AWS Fargate / Fly / Render / Cloudflare Durable Objects.

### Anti-pattern: Cross-region DB chatter

Function in `syd1`, DB in `iad1`. Every query crosses the Pacific. Either pin function to DB region or add a regional read replica. Not both far apart.

### Anti-pattern: All-in on Marketplace for enterprise apps

At enterprise scale, Marketplace pass-through cost > direct vendor. The Marketplace developer-velocity benefit is huge for startups; less compelling at $100k/mo+ infra spend.

### Anti-pattern: Static export when you have dynamic data

`output: 'export'` means no Server Components/Actions, no `revalidate`, no `next/image` optimization. Use it only for genuinely static sites. For everything else, default Vercel compute.

### Anti-pattern: Treating Vercel like a single-region platform

Vercel's Edge Network is multi-region by default; your *Functions* default to one region unless you configure `regions`. For latency-sensitive apps, configure regions explicitly; for most apps, single-region (US-East) is fine.

### Anti-pattern: "Vercel is just hosting"

Treating Vercel as a glorified CDN ignores Functions, Workflow, Queues, AI Gateway, Sandbox. If your architecture spec says "frontend on Vercel, backend on AWS" without a real reason, ask why — Vercel's backend tier is competitive for most workloads in 2026.

## Architectural decision records (ADRs)

When making a topology decision on Vercel, document it. Standard ADR template:

```markdown
# ADR-NNN: <Decision title>

## Status
Accepted | Proposed | Superseded by ADR-MMM

## Context
What's the problem? What constraints (scale, latency, budget, team) bound the decision?

## Decision
We chose <option>.

## Alternatives considered
- Option A: <description>. Pros: ... Cons: ...
- Option B: ...

## Consequences
- What this enables.
- What this costs (engineering, money, ops).
- What this rules out.

## Verification
How will we know if this was the right call? (Latency target, cost target, etc.)
```

Common ADRs on Vercel projects:
- Rendering model per route family (marketing / dashboard / admin).
- Data plane choice (Neon vs Supabase).
- AI routing (Gateway vs direct).
- Vector store choice.
- Region strategy.
- Auth provider.
- Marketplace integration governance.
- Cost ceiling triggers (when do we re-evaluate Vercel as the platform?).

## Cross-references

- **`references/frontend-architect.md`** — rendering model details, Server Component patterns.
- **`references/backend-architect.md`** — Function tiering, Workflow, Queues, storage clients.
- **`references/devops-engineer.md`** — Marketplace + cost monitoring + observability wiring.
- **`references/ai-ml-engineer.md`** — AI Gateway, AI SDK, Sandbox, RAG patterns.
- **AWS / GCP / Azure / Cloudflare Stack Packs** — for off-Vercel compute decisions.
- **Supabase Stack Pack** — for the auth+realtime+DB composition alternative.
- **Anthropic Claude / OpenAI Stack Packs** — for direct-provider AI deep dives.
- **Stripe Stack Pack** — for the payments+Marketplace composition.

## Integration with always-on protocols

- **TDD on architecture work:** prototype with the chosen topology before committing. A real Preview Deployment with the proposed data plane + compute tier + caching strategy is the test — does it meet latency? does it scale to expected volume? does it fit budget? Don't ADR a topology without validating it.
- **Verification:** before committing to a topology, you should have (a) a working Preview with the chosen stack, (b) load test results showing it meets target throughput/latency, (c) cost projection from the Vercel dashboard + Marketplace integrations, (d) a documented ADR with alternatives weighed.
- **Debugging:** topology-level debugging requires the trace stack — OTel through Functions, AI Gateway dashboard for AI, DB performance dashboard for storage. Isolate "where is the latency?" before optimizing.
- **Plan execution:** topology migrations are *programs*, not tasks. Plan: discovery → ADR → prototype → load test → migration plan → migrate → monitor → cleanup. Don't make a topology change in a single PR.
- **Brainstorm-first:** for greenfield Vercel architectures, brainstorm-first protocol fits — write the design brief before committing to compute / data / AI stack. Many "we should rebuild on Vercel" decisions don't survive a design brief.
- **Subagent coordination:** topology decisions touch every other role — frontend (rendering model), backend (compute tier), devops (cost + observability), ai-ml (AI placement). One ADR review, all four roles weigh in.

## Reference topologies — common Vercel architectures

The four shapes that account for ~80% of new Vercel apps in 2026:

### Topology 1: Pure Vercel (startup MVP / SaaS)

```
                User
                  │
                  ▼
         Vercel Edge Network (cache + CDN)
                  │
                  ▼
         Edge Middleware (auth + geo)
                  │
                  ▼
         Next.js Functions (Fluid Node)
        /         |          \
       ▼          ▼           ▼
   Neon         Upstash    Vercel Blob
   Postgres     KV          (uploads)
                  │
                  ▼
              AI Gateway → Claude / GPT / Gemini

Auth: Clerk or Auth.js
Email: Resend (Marketplace)
Payments: Stripe (Marketplace)
Observability: Speed Insights + Datadog (Marketplace)
```

Fits 90% of B2B SaaS MVPs and B2C product launches. One bill, one deploy story, one provider for almost everything.

### Topology 2: Vercel frontend + AWS heavy backend

```
                User
                  │
                  ▼
         Vercel Edge Network
                  │
                  ▼
         Next.js Functions (Fluid Node)
                  │
                  │ HTTPS (REST/GraphQL)
                  ▼
         AWS ALB / API Gateway
                  │
        ┌─────────┼─────────┐
        ▼         ▼         ▼
       ECS      Lambda    Step
       Fargate            Functions
                  │
                  ▼
              RDS / DynamoDB / S3 / SQS

Auth: WorkOS or Cognito
AI: AI Gateway from Vercel side
Observability: Datadog (Marketplace + AWS-native)
```

Fits when the team has existing AWS backends, ML inference fleets, sticky WebSocket workloads, or batch jobs. Vercel hosts the user-facing app; AWS owns the heavy compute.

### Topology 3: Vercel + Cloudflare composition

```
                User
                  │
                  ▼
         Cloudflare DNS + WAF + Bot Mgmt
                  │
                  ▼
         Vercel Edge Network (origin)
                  │
                  ▼
         Next.js Functions (Fluid Node)
                  │
        ┌─────────┼─────────────────┐
        ▼         ▼                 ▼
       Neon    Cloudflare R2    Cloudflare Workers
       Postgres  (cheap egress)  (edge compute Vercel can't)
                  │
                  ▼
              AI Gateway → Cloudflare AI / Claude / GPT
```

Fits when you need Cloudflare's edge features (Bot Fight Mode, R2 egress pricing, Workers for specific edge logic). Cloudflare sits in front; Vercel is the origin for the app; specific routes/workloads run on Cloudflare directly.

### Topology 4: Vercel + Supabase (full-stack DX)

```
                User
                  │
                  ▼
         Vercel Edge Network
                  │
                  ▼
         Next.js Functions (Fluid Node)
                  │
                  │ Supabase JS / @supabase/ssr
                  ▼
         Supabase
        - Auth (with RLS)
        - Postgres (with RLS)
        - Storage
        - Realtime (postgres-cdc)
        - Edge Functions (Deno)
```

Fits when the app's data + auth + realtime are tightly coupled. Supabase wins on developer DX for this composition; Vercel handles the Next.js layer and any Vercel-specific concerns (Cache Components, Server Actions calling Supabase).

## Multi-tenancy on Vercel

For B2B SaaS, the tenancy model shapes everything else:

### Shared schema + tenant column (default)

- One Postgres DB; every table has `tenant_id`; row-level security or app-level enforcement.
- One Vercel project; routes are tenant-agnostic; middleware reads tenant from subdomain or path.
- Cheap, fast, simple. Trade-off: noisy neighbor risk, harder per-tenant scaling.

### Schema-per-tenant

- One Postgres DB; one schema per tenant; same code, different `search_path`.
- Per-tenant migration discipline gets heavy at > ~100 tenants.

### Database-per-tenant

- Separate Neon project (or branch) per tenant.
- True isolation; per-tenant backups; per-tenant residency.
- Trade-off: ops complexity, connection-pooling friction.

### Vercel-side considerations

- **Subdomain routing**: `<tenant>.example.com`; Vercel supports wildcard SSL.
- **Path routing**: `example.com/<tenant>`; simpler, breaks per-tenant SEO.
- **Custom domains per tenant**: `acme.com` → user's tenant; Vercel supports adding domains via API.
- **Per-tenant feature flags**: Edge Config or Statsig/LaunchDarkly (Marketplace).
- **Per-tenant Postgres**: Neon branching gives an easy path; one branch per tenant.

The saas-architect role owns multi-tenancy in depth — this overlay just calls the Vercel-platform implications.

## Real-time semantics

Vercel Functions are request-response. For real-time, options:

| Need | Pick |
|------|------|
| **Server-Sent Events (SSE)** for one-way updates | Stream from a Route Handler; works on Fluid Node. |
| **WebSockets, < 100k concurrent** | Pusher (Marketplace), Ably (Marketplace), or Liveblocks (Marketplace). Vercel doesn't host the WebSocket; you host the connection at the partner and notify your Vercel functions via webhook. |
| **WebSockets, > 100k concurrent** | Cloudflare Durable Objects, AWS API Gateway WebSockets, or self-hosted (Soketi, uWebSockets on Fargate). |
| **Postgres realtime (CDC)** | Supabase Realtime (in Supabase composition), or Neon + a separate Pusher/Ably layer. |
| **Collaborative editing** | Liveblocks, PartyKit (now Cloudflare), Yjs over WebSocket. |
| **Push notifications** | OneSignal, Pusher Beams, Firebase Cloud Messaging via own server. |

Vercel is not in the WebSocket business at large scale. Compose with a real-time provider.

## Vercel Sandbox in architecture

When the app's user-facing surface includes "run code" (data analysis, AI agents, sandboxed scripting), Sandbox is the canonical answer. Architecturally:

- Sandbox runs in a microVM separately from your Function.
- Per-session lifecycle; design for short-lived (per-request) sessions for security; longer for cost-efficiency.
- Network egress is controlled — allowlist what the Sandbox can call.
- Outputs are streamed back to the calling Function; cap size.

The architectural decision is: which workloads go through Sandbox? Heuristic: anything where the *code itself* comes from outside your trust boundary (user input, LLM output, third-party plugin). Don't run untrusted code outside Sandbox even with VM2 / Node `vm` — those have escape histories.

## Where Vercel sits in a Big Enterprise

For large enterprises adopting Vercel, the typical adoption path:

1. **Pilot project** — marketing site or internal tool on Vercel; prove the deploy model.
2. **Adjacent product** — a new customer-facing app on Vercel; production traffic, but bounded.
3. **Replatform** — existing flagship app moves to Vercel App Router; Cache Components + PPR + Server Actions adopted incrementally.
4. **Stable state** — Vercel is the frontend layer of the org; backend services remain on AWS/GCP for compliance/IT reasons; Vercel + WorkOS for SSO; Datadog (Marketplace) for one observability layer across.

Common enterprise objections + their resolutions:

- **"We need a BAA for HIPAA."** Vercel Enterprise signs BAA; verify current scope. Pair with AI Gateway HIPAA-eligible providers (Anthropic with BAA, Azure OpenAI).
- **"We need SOC 2."** Vercel has SOC 2 Type 2; reports in Trust Center.
- **"We need EU data residency."** Pin function regions to EU; pair with EU-region Neon. Log Drain to EU destination. Document residency in DPA addendum.
- **"We're worried about vendor lock-in."** Next.js itself runs anywhere (self-hosted, Cloudflare Pages, Netlify, AWS). The Vercel-specific bits (AI Gateway, Marketplace, Speed Insights) are replaceable but require integration work. Document the exit story in your ADR.
- **"We need on-prem."** Vercel doesn't do on-prem. Self-hosted Next.js on Kubernetes is the path. Lose the dev velocity, gain control.

## Cost-aware architectural patterns

Architectural choices that materially lower the bill:

1. **Aggressive Cache Components** at the right granularity — cache the read patterns, not the writes.
2. **Cloudflare in front for static + bot mitigation** — reduces Vercel edge request count; cheaper bot blocking.
3. **Image optimization off Vercel for high-volume catalogs** — Cloudflare Images, imgix, or self-hosted Sharp on a separate service.
4. **BYOK for AI Gateway** at high volume — direct provider billing skips Vercel margin.
5. **Direct vendor billing past startup phase** — Datadog Enterprise, Stripe high-volume, Neon Business directly rather than via Marketplace.
6. **Aggressive function tiering** — `maxDuration` and `memory` per-route, not blanket.
7. **Cold-path Lambdas off-Vercel** — for very-low-frequency batch (nightly reports, weekly emails), running on AWS Lambda is sometimes cheaper than a Vercel cron job.
8. **Right-size the Image Optimization matrix** — `deviceSizes` + `imageSizes` config controls how many transforms get generated per image.

## Architecture review pattern

Before greenlighting a Vercel architecture for production, run an architecture review with these stations:

| Station | Owner | Asks |
|---------|-------|------|
| **Rendering** | frontend-architect | Per route family, what's the rendering model? PPR? Cache Components? Why? |
| **Compute** | backend-architect | Functions vs Workflow vs Queue vs off-Vercel? maxDuration/memory tuned? |
| **Data** | database-architect (consulted) + system-architect | Storage choices justified? Region match? Backup + DR? |
| **AI** | ai-ml-engineer | Provider choice? AI Gateway or direct? Sandbox where needed? Cost model? |
| **Security** | security-engineer | Server Action security? Sandbox for untrusted code? Auth provider? Headers? |
| **Observability** | sre-engineer + devops-engineer | OTel? Log Drain? Speed Insights? Alerts? |
| **Cost** | devops-engineer + system-architect | Volume projection × per-line price = bill? Caps set? |
| **Composition** | system-architect | Off-Vercel stacks identified? Cross-pack delegation working? |
| **Verticals** | the relevant vertical architect | Compliance? Tenancy? Domain-specific? |
| **Migration** | system-architect | If existing app: migration plan + rollback gates? |

The output of the review is an ADR signed by all stations. Don't merge a new architecture without it.

## Quick reference: the 2026 system-architect checklist

Before merging a new Vercel architecture (or migration):

- [ ] ADR documents the topology, alternatives, and verification criteria.
- [ ] Rendering model is decided per route family (PPR+Cache Components default, with explicit exceptions).
- [ ] Data plane is chosen with read/write paths mapped to it (Neon / Supabase / RDS / ...).
- [ ] Function region(s) match storage region(s) — no cross-region chatter.
- [ ] Compute placement is documented (Functions / Workflow / off-Vercel) with rationale.
- [ ] AI placement is documented (Gateway / direct provider / Vercel Agent / off-Vercel).
- [ ] Marketplace integration list is approved (no surprise installs).
- [ ] Cost projection at expected volume is within target.
- [ ] Multi-region strategy (if applicable) handles writes + residency.
- [ ] Migration plan (if migrating onto / off Vercel) has explicit phases + rollback gates.
- [ ] Always-on services are off Vercel (or explicitly justified as fitting Workflow).
- [ ] Sandbox is the runtime for any untrusted code execution.
- [ ] Composition with other Stack Packs (Cloudflare / AWS / Supabase / Anthropic / OpenAI / Stripe) is documented.
- [ ] Observability stack is wired (Speed Insights, Log Drain, OTel).
- [ ] Auth strategy is decided + integrated (Auth.js / Clerk / WorkOS / Supabase).
- [ ] Backup + DR plan exists for the data plane.
- [ ] Compliance requirements (HIPAA / PCI / GDPR / SOC 2) are routed to the appropriate vertical role for review.
- [ ] Scale ceiling is identified ("at X RPS we re-evaluate Vercel").
- [ ] Cost monitoring alerts are configured at the team level.
- [ ] Status page + incident runbook reference Vercel + Marketplace vendor status pages.
