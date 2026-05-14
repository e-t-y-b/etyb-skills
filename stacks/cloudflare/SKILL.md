---
name: stack-cloudflare
description: >
  Cloudflare platform knowledge overlay for the ETYB team. Loads when work involves the Cloudflare ecosystem — Workers, Workers Bindings, Wrangler, Durable Objects, D1, R2, KV, Hyperdrive, Queues, Workflows, Pipelines, Vectorize, Workers AI, AI Gateway, AI Search (formerly AutoRAG), Realtime, Stream, Images, Pages, Workers Static Assets, Browser Rendering, Email Routing/Workers, Zaraz, Turnstile, Access (ZTNA), Tunnel, WAF, Rate Limiting, DDoS, Magic Transit, Argo, Logpush, Analytics Engine, Workers Logs, mTLS, CASB. This is NOT a new team member; it is a context overlay that teaches each existing ETYB role what it needs to know to ship production-grade Cloudflare work as of 2026-Q2.
  Triggers: cloudflare, workers, cloudflare workers, worker, wrangler, durable object, durable objects, do, sqlite-backed do, alarms, d1, d1 database, r2, r2 bucket, kv, kv namespace, hyperdrive, queues, cloudflare queues, workflows, cloudflare workflows, pipelines, cloudflare pipelines, vectorize, vectorize v2, workers ai, ai gateway, ai search, autorag, cloudflare ai, llama 4 on workers, deepseek on workers, realtime, sfu, turn, cloudflare stream, cloudflare images, pages, cloudflare pages, workers static assets, _routes.json, _headers, _redirects, browser rendering, puppeteer worker, email routing, email workers, zaraz, turnstile, captcha alternative, access, cloudflare access, ztna, zero trust, cloudflare tunnel, cloudflared, argo tunnel, waf, owasp managed ruleset, rate limiting, rule, ddos, l3 ddos, magic transit, magic wan, argo smart routing, logpush, analytics engine, workers logs, tail workers, smart placement, workers for platforms, dispatch namespace, outbound worker, containers, workers and containers, container binding, rpc, service binding, env binding, queue binding, do binding, mtls cert, cloudflare casb, cloudflare radar, browser isolation, gateway dns, gateway http, miniflare, vitest-pool-workers, .dev.vars, .wrangler, workerd, nodejs_compat, compatibility_date, compatibility_flag, cron trigger, scheduled handler, fetch handler, queue handler, email handler, alarm handler.
license: MIT
compatibility: ETYB stack pack — Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "4.0.0"
  category: stack-pack
  last_verified_release: "2026-Q2"
  last_verified_on: "2026-05-14"
  applies_to_roles:
    - backend-architect
    - system-architect
    - devops-engineer
    - ai-ml-engineer
    - database-architect
    - security-engineer
authoritative_sources:
  primary:
    - { name: "Cloudflare Developer Docs",      url: "https://developers.cloudflare.com/",                                       type: official_docs }
    - { name: "Workers Documentation",           url: "https://developers.cloudflare.com/workers/",                              type: official_docs }
    - { name: "Wrangler CLI Reference",          url: "https://developers.cloudflare.com/workers/wrangler/commands/",            type: cli_reference }
    - { name: "Workers Changelog",               url: "https://developers.cloudflare.com/workers/platform/changelog/",           type: changelog }
    - { name: "Cloudflare REST API",             url: "https://developers.cloudflare.com/api/",                                  type: api_reference }
    - { name: "Cloudflare Blog (product launches)", url: "https://blog.cloudflare.com/",                                         type: changelog }
    - { name: "Cloudflare GitHub",               url: "https://github.com/cloudflare",                                           type: source_repo }
    - { name: "Cloudflare Status",               url: "https://www.cloudflarestatus.com/",                                       type: status_page }
    - { name: "workerd runtime (open source)",   url: "https://github.com/cloudflare/workerd",                                   type: source_repo }
    - { name: "Cloudflare Compatibility Dates",  url: "https://developers.cloudflare.com/workers/configuration/compatibility-dates/", type: official_docs }
delegate_to_skills:
  # The Cloudflare-hosted MCP server family ships with cloudflare:cloudflare-mcp when
  # the user has the Cloudflare plugin installed. When present, prefer it for live
  # account introspection (worker code, D1 query, KV/R2 listing, Hyperdrive config).
  - { skill: "cloudflare:cloudflare-mcp", covers: [Workers, "Durable Objects", D1, R2, KV, Hyperdrive, Pages, "Workers AI", "Vectorize", "Account API", "Documentation Search"] }
products_covered:
  - { name: "Workers Runtime (workerd)",     drift_risk: high,   notes: "Compatibility-date model + nodejs_compat / nodejs_als / nodejs_compat_v2 flags shift roughly quarterly; runtime keeps adding Node-compat surface" }
  - { name: "Wrangler CLI",                  drift_risk: high,   notes: "Major v4 line; flag/command names mutate per minor release; deploys, dev modes, secret bulk, and observability commands all changed in 2025" }
  - { name: "Workers Bindings (RPC, Service, Queue, DO, Env)", drift_risk: high, notes: "Workers RPC (entrypoint classes) is now the canonical inter-worker pattern as of 2024-25; older 'fetcher.fetch' service-binding code is legacy" }
  - { name: "Durable Objects",               drift_risk: high,   notes: "SQLite-backed DOs went GA in 2024, became the default class type in 2025; alarms + transactions semantics shifted" }
  - { name: "D1",                            drift_risk: high,   notes: "GA 2024; global read replication + Sessions API + larger DB sizes landed 2024-2025" }
  - { name: "R2",                            drift_risk: medium, notes: "S3-compatible, stable surface; event notifications, R2 SQL, and bucket lifecycle features expanded 2024-2025" }
  - { name: "KV",                            drift_risk: low,    notes: "Eventually-consistent KV semantics stable for years; limits and pricing tier (Standard) shifted 2024" }
  - { name: "Hyperdrive",                    drift_risk: high,   notes: "Hyperdrive for Postgres + MySQL; query plan + connection pooling behavior evolves; supports private DBs over Tunnel" }
  - { name: "Queues",                        drift_risk: medium, notes: "GA; pull consumers, message delays, dead-letter, batch retry semantics added through 2025" }
  - { name: "Workflows",                     drift_risk: high,   notes: "Durable-execution primitive, GA in 2025; new pattern most teams have not seen" }
  - { name: "Pipelines",                     drift_risk: high,   notes: "Data-ingest product (HTTP → R2 + transform); newer surface, naming and limits in flux" }
  - { name: "Vectorize",                     drift_risk: high,   notes: "Vectorize V2: increased dimensions, metadata indexes, larger index sizes; v1 indexes have migration path" }
  - { name: "AI Gateway",                    drift_risk: high,   notes: "Provider catalog + features (cache, fallback, guardrails, BYOK) ship continuously; pricing model evolves" }
  - { name: "Workers AI",                    drift_risk: high,   notes: "Model catalog churns weekly — Llama 4 family, DeepSeek, Mistral, Whisper, Stable Diffusion; pricing per-neuron model still current 2026" }
  - { name: "AI Search (ex-AutoRAG)",        drift_risk: high,   notes: "Renamed from AutoRAG in 2025; managed RAG pipeline on R2 + Vectorize + Workers AI" }
  - { name: "Realtime",                      drift_risk: high,   notes: "Cloudflare Realtime (TURN + SFU + Realtime API) GA 2025; replaces the older Calls naming" }
  - { name: "Stream",                        drift_risk: medium, notes: "Video ingest/playback; Live Input + Stream Connect stable; pricing per-minute" }
  - { name: "Images",                        drift_risk: medium, notes: "Polish + Resizing + Images delivery; transforms URL grammar stable" }
  - { name: "Pages",                         drift_risk: high,   notes: "Pages is in maintenance — new builds should use Workers Static Assets; migration guide published 2024" }
  - { name: "Workers Static Assets",         drift_risk: high,   notes: "Replaces Pages for new projects; assets binding + _headers + _routes.json + run_worker_first semantics still evolving" }
  - { name: "Browser Rendering",             drift_risk: medium, notes: "Puppeteer-compatible API served from Workers; pricing per browser-hour; concurrency limits per account" }
  - { name: "Cron Triggers",                 drift_risk: low,    notes: "Scheduled handler stable; UTC only, max one-minute granularity" }
  - { name: "Email Routing / Email Workers", drift_risk: medium, notes: "Inbound-only; outbound via MailChannels or providers via SMTP; Email Workers let you write JS handlers" }
  - { name: "Zaraz",                         drift_risk: medium, notes: "Server-side tag manager; Worker-emitted server-side events" }
  - { name: "Turnstile",                     drift_risk: low,    notes: "CAPTCHA alternative; widget + server validation API stable" }
  - { name: "Access (ZTNA)",                 drift_risk: medium, notes: "Identity-aware proxy; integrates with IdPs and Tunnel; Service Auth tokens + JWT validation patterns stable" }
  - { name: "Cloudflare Tunnel",             drift_risk: medium, notes: "cloudflared replaces VPN ingress; preferred path to expose private origins to Access/Workers" }
  - { name: "WAF + Managed Rulesets",        drift_risk: medium, notes: "OWASP and Cloudflare-managed rules; custom rule engine syntax stable; logging via Logpush" }
  - { name: "Rate Limiting",                 drift_risk: medium, notes: "Two products: Rules-engine rate limiting (per-zone) and Workers Rate Limiting binding (in-Worker)" }
  - { name: "DDoS Protection",               drift_risk: low,    notes: "L3-L7 protection always-on; managed ruleset + Spectrum for non-HTTP" }
  - { name: "Magic Transit / Magic WAN",     drift_risk: medium, notes: "L3 protection + SD-WAN replacement for enterprise networking" }
  - { name: "Argo Smart Routing",            drift_risk: low,    notes: "Tiered cache + smart routing; cost-add for HTTP zones" }
  - { name: "Logpush",                       drift_risk: medium, notes: "Streaming logs to S3/R2/GCS/Datadog/Splunk; per-dataset configs stable" }
  - { name: "Workers Logs + Tail",           drift_risk: high,   notes: "Workers Logs (queryable persistent logs) replaced legacy Logpush-for-Workers in 2024-25; wrangler tail still exists for live streams" }
  - { name: "Analytics Engine",              drift_risk: medium, notes: "Time-series datapoints with SQL queries; pricing per million datapoints" }
  - { name: "mTLS Certificates",             drift_risk: low,    notes: "mTLS binding for Workers, mTLS at zone level; certificate management API stable" }
  - { name: "Cloudflare CASB",               drift_risk: medium, notes: "Cloud SaaS scanning + DLP; part of Zero Trust suite" }
  - { name: "Smart Placement",               drift_risk: medium, notes: "Workers config flag that runs the Worker close to backend rather than user; useful when egress dominates" }
  - { name: "Workers for Platforms",         drift_risk: high,   notes: "Multi-tenant Worker execution (Dispatch Namespaces, Outbound Workers); SaaS-platform pattern, premium SKU" }
  - { name: "Containers on Workers",         drift_risk: high,   notes: "Workers + Containers (beta through 2025); container binding lets a Worker boot an isolated container instance for long-running / heavy workloads" }
---

# Cloudflare Stack Pack — Team Briefing

You're working on the Cloudflare platform. This is a **knowledge overlay**, not a new specialist. ETYB's existing team does the work — backend-architect writes the Workers, devops-engineer wires the CI and Wrangler, database-architect picks D1 vs R2 vs Hyperdrive, ai-ml-engineer composes Workers AI + AI Gateway + Vectorize, security-engineer enforces Access + WAF + mTLS, system-architect picks the topology. This pack teaches each role what the platform expects in 2026.

**Currency stamp:** verified against Cloudflare's public docs, changelog, and blog through 2026-05-14. If today's date is more than 6 months past `last_verified_on`, the pack is stale — warn the user and consult the Workers changelog before recommending API-level details. Workers ship changes weekly; the Wrangler CLI and bindings surface drifts faster than almost any platform in this repo.

## What changed in 2025-2026 that older training data misses

An LLM with a 2024 cutoff will be wrong about most of this. Read carefully before recommending anything specific:

- **Workers RPC is the canonical inter-worker pattern.** Service bindings that did `env.OTHER.fetch(request)` are legacy. Modern bindings use `WorkerEntrypoint` classes and method calls (`await env.OTHER.someMethod(args)`). RPC traverses Workers, Durable Objects, and Workers for Platforms — same primitive. ([RPC docs](https://developers.cloudflare.com/workers/runtime-apis/rpc/))
- **Durable Objects are SQLite-backed by default.** New DO classes get a per-DO SQLite database, not the legacy KV-style storage. Transactions, full SQL, alarms, and ~10GB per DO are standard. Old DO storage API (`this.state.storage.put/get`) still works but new code should use SQL. ([Durable Objects: SQL storage](https://developers.cloudflare.com/durable-objects/api/storage-api/))
- **D1 supports global read replication and the Sessions API.** Multi-region read replicas as of 2025; the Sessions API ensures read-your-writes consistency across replicas. Don't build D1 apps that assume a single primary location anymore.
- **Hyperdrive supports MySQL** in addition to Postgres, and can target private databases over Cloudflare Tunnel. It is now the standard way to put a relational DB behind Workers — connection pooling + query caching + private connectivity in one binding.
- **Vectorize V2** is the current generation: up to 1536-dim (and larger for some plans), metadata indexes for filtered search, multi-million-vector indexes per account, namespace partitioning. v1 indexes still exist but new builds should target V2.
- **Workflows GA'd in 2025.** Durable-execution primitive (think Temporal-as-a-binding). Long-running, retry-aware, sleepable. New mental model for orchestrating async work — don't reach for Queues + state-in-DO when Workflows fit.
- **Pages is in maintenance mode.** New projects should use **Workers Static Assets** with the `assets` binding. Pages keeps working; new platform features land in Workers Static Assets first. The Pages → Workers migration guide exists; recommend the migration on any non-trivial Pages project. ([Pages → Workers migration](https://developers.cloudflare.com/workers/static-assets/migration-guides/migrate-from-pages/))
- **AutoRAG was renamed to Cloudflare AI Search** in 2025. Same product (managed RAG pipeline on R2 + Vectorize + Workers AI). If you say "AutoRAG" to a Cloudflare account team in 2026 they'll know what you mean, but the docs/console use AI Search.
- **Realtime (TURN + SFU + Realtime API) is GA.** Replaces the older "Cloudflare Calls" naming. Real-time audio/video apps on Workers without managing your own SFU.
- **Workers Logs** (queryable, persistent, no Logpush needed) replaced the older pattern of pushing Worker invocations to external sinks for casual debugging. Logpush is still the path for fanning logs to Datadog/Splunk/S3 in volume.
- **Containers on Workers (beta through 2025)** lets a Worker spawn a long-running container for heavy or stateful workloads — bridges the gap to Node/Python apps that don't fit the V8-isolate model.
- **Workers AI catalog expanded substantially.** Llama 4 family, DeepSeek-R1/V3, Mistral 8B, Whisper-large-v3-turbo, Stable Diffusion XL, BGE embeddings. Pricing model is per-neuron; many models have free tier inclusions.
- **AI Gateway** is the universal model proxy: caching, fallback, rate limiting, guardrails, BYOK, and unified analytics across OpenAI/Anthropic/Workers AI/etc. If you're calling models from Workers, you should be calling them through AI Gateway.
- **Wrangler v4** is current. `wrangler deploy` (not `publish`), `wrangler dev` (with --remote), `wrangler tail`, `wrangler types`, `wrangler secret bulk`. Old `wrangler publish` and Wrangler v1/v2 syntax must be flagged and replaced.
- **`compatibility_date` + `compatibility_flags` are mandatory.** Without them the runtime falls back to old behavior. New projects should pin `compatibility_date` near current and set `nodejs_compat` or `nodejs_compat_v2` if needed.
- **Smart Placement** is now broadly recommended for Workers that talk to a single backend region. The flag (`placement = { mode = "smart" }` in `wrangler.toml`) lets Cloudflare run the Worker close to the backend instead of the user — wins when backend roundtrips dominate.
- **Workers for Platforms** matured: Dispatch Namespaces, Outbound Workers, Tail Workers for tenants. The pattern for "your customers write code that runs on your platform" — SaaS that exposes a programmable surface.

If you find yourself recommending `wrangler publish`, raw service bindings with `.fetch()`, KV-style DO storage for new code, Pages for net-new projects, AutoRAG, or "Cloudflare Calls" — you're working from stale knowledge. Refresh from the references below.

## How this pack plugs in

ETYB's router detects Cloudflare signals via `skills/etyb/core/stack-registry.md` and loads this SKILL.md as the team briefing. When the router dispatches to a specific role, it also loads `references/<role>.md` if one exists.

**Always-on protocols still apply unchanged.** TDD, verification, debugging, review, plan execution, brainstorm-first, branch safety, subagent coordination, self-improvement. The Cloudflare overlay does not relax engineering discipline; it shapes how the discipline is applied on this platform (e.g., TDD on Workers = Vitest with `@cloudflare/vitest-pool-workers` against Miniflare; integration tests = `wrangler dev --remote` or staged deploys).

If the user environment has `cloudflare:cloudflare-mcp` available, prefer that for live introspection (current Worker code, D1 schema, KV/R2 listings, Hyperdrive configs) over guessing from baked knowledge. See `delegate_to_skills` above.

## Reference Map — what each role reads

| Role | Reference | Owns |
|------|-----------|------|
| `backend-architect` | [`references/backend-architect.md`](references/backend-architect.md) | **The Worker code itself** — handlers (fetch/scheduled/queue/email/alarm), bindings (env/RPC/service/DO/queue/AI), Durable Objects (SQLite, alarms, transactions, WebSockets), Workflows, Queues, error handling, Hono / Itty / OpenAPI patterns, compatibility flags, request lifecycle, subrequest budget, CPU & wall-clock limits, RPC entrypoints |
| `system-architect` | [`references/system-architect.md`](references/system-architect.md) | **Topology decisions** — when to use Workers vs Pages vs containers; D1 vs Hyperdrive vs external Postgres; KV vs DO storage vs D1; Queues vs Workflows vs DO alarms; Workers for Platforms vs many Workers; Smart Placement; cross-region patterns; cost ceilings and free-tier vs paid plan boundaries |
| `devops-engineer` | [`references/devops-engineer.md`](references/devops-engineer.md) | Wrangler v4 + `.dev.vars` + `wrangler.toml`/`wrangler.jsonc`; **Workers CI/CD** (GitHub Actions, GitLab, Cloudflare Workers Builds); secrets and `wrangler secret bulk`; multi-env config; preview deployments; gradual rollouts and version overrides; routes/domains/zones; observability (Workers Logs, tail, Logpush, Analytics Engine); IaC (Terraform Cloudflare provider, Pulumi); compatibility-date discipline |
| `ai-ml-engineer` | [`references/ai-ml-engineer.md`](references/ai-ml-engineer.md) | **The AI stack** — Workers AI model catalog and selection, AI Gateway features (cache, fallback, BYOK, guardrails, evaluations), Vectorize V2 index design, AI Search (RAG-as-a-product), prompt cost containment, streaming responses on Workers, tool-using agents in Workers, real-time voice via Realtime + Workers AI |
| `database-architect` | [`references/database-architect.md`](references/database-architect.md) | **Where data lives** — D1 schema design, indexes, Sessions API, read replicas, migrations; R2 as object store + R2 SQL for table-like analytics; KV semantics and TTL discipline; Durable Object SQLite as a per-tenant micro-DB; Hyperdrive sizing and connection pooling; Vectorize as the vector store of record; data residency and Region: Earth |
| `security-engineer` | [`references/security-engineer.md`](references/security-engineer.md) | **Edge security** — WAF managed rulesets, rate limiting (rules vs binding), Turnstile, Access policies + Service Auth + JWT validation, Tunnel for private origins, mTLS (zone + Workers binding), API Shield, Browser Isolation, Gateway DNS/HTTP, CASB, secrets handling on Workers, prompt-injection defenses for AI Workers |

The 6 role overlays in v4.0.0 cover ETYB's most-exercised Cloudflare-touching roles. Verticals (saas-architect, real-time-architect, e-commerce-architect, healthcare-architect, fintech-architect) and other specialists (frontend-architect, qa-engineer, sre-engineer, technical-writer, project-planner, code-reviewer) should compose with the cross-cutting protocol references and the role overlays above when their work intersects Cloudflare.

## Product surface at a glance (2026-Q2)

Cloudflare's catalog is wider than most teams realize. Quick map of where each major product fits:

**Compute and runtime**
- Workers (the V8 isolate runtime; `fetch`, `scheduled`, `queue`, `email`, `alarm`, RPC handlers)
- Workers for Platforms (multi-tenant Worker execution — Dispatch Namespaces, Outbound Workers, Tail Workers)
- Containers on Workers (beta through 2025; container binding for code that doesn't fit V8)
- Browser Rendering (Puppeteer-compatible headless browser as a binding)

**Bindings, RPC, scheduling**
- Service bindings + RPC (`WorkerEntrypoint`)
- Durable Object bindings (and DO RPC)
- Queue bindings (producers + consumers)
- Cron Triggers (`scheduled` handler)
- mTLS certificate binding (outbound mTLS)
- Workers Rate Limiting binding
- Hyperdrive binding (Postgres/MySQL pool + cache)
- AI binding (Workers AI inference)
- AI Search / Vectorize bindings

**Storage and data**
- D1 (distributed SQLite + Sessions API + replicas + time-travel restore)
- Durable Object SQLite (per-DO SQLite, default since 2025)
- R2 (S3-compatible object storage, zero egress) + R2 SQL (Parquet queries)
- KV (eventually-consistent key-value)
- Vectorize V2 (managed vector DB)
- Hyperdrive (front Postgres/MySQL — pool, cache, private connectivity)
- Analytics Engine (time-series datapoints with SQL)
- Pipelines (HTTP ingest → R2 Parquet/JSON)
- Workers Logs (queryable persistent logs)

**AI / ML**
- Workers AI (model inference: Llama 4, DeepSeek, Mistral, Whisper, SDXL, BGE embeddings, etc.)
- AI Gateway (provider-agnostic proxy: cache, fallback, guardrails, BYOK, eval)
- AI Search (managed RAG over R2 docs; formerly AutoRAG)
- Vectorize V2 (vector index)

**Networking and edge**
- DNS / Zones
- Cache (Cache API, CDN)
- Smart Placement (run Workers close to backend)
- Argo Smart Routing
- Magic Transit / Magic WAN / Spectrum (enterprise networking)
- Cloudflare for SaaS (custom hostnames)

**Security and Zero Trust**
- WAF + Managed Rulesets + custom rules
- Rate Limiting Rules (zone-level)
- Bot Management
- DDoS Protection (always-on L3-L7)
- API Shield (schema + JWT validation at edge)
- Turnstile (CAPTCHA alternative)
- Cloudflare Access (ZTNA)
- Cloudflare Tunnel (outbound origin connections)
- mTLS at the zone + Authenticated Origin Pulls
- Gateway (DNS + HTTP filtering for users/devices)
- CASB (SaaS discovery)
- Browser Isolation
- Cloudflare One / Zero Trust suite

**Media**
- Stream (video ingest/playback)
- Images (resize, polish, delivery)
- Realtime (TURN + SFU + Realtime API)

**Email**
- Email Routing (inbound routing)
- Email Workers (programmable inbound handlers)

**Tag management / analytics**
- Zaraz (server-side tag manager)
- Cloudflare Analytics (zone + Worker analytics)

**Developer tooling**
- Wrangler CLI v4
- Miniflare (built into Wrangler)
- `@cloudflare/vitest-pool-workers`
- Cloudflare Terraform / Pulumi providers
- Cloudflare-hosted MCP servers (when installed)

**Static assets**
- Workers Static Assets (preferred for new builds)
- Pages (maintenance mode)

This pack overlays the **bold-italic intersection** of these with ETYB roles. Anything in this catalog is in-scope for a Cloudflare-shaped engagement; the role overlays focus on the high-frequency intersections.

## Top 10 platform gotchas the team must know

These bite first-time and second-time Cloudflare engineers alike. Internalize them before shipping.

1. **There is no Node.js by default.** Workers run on V8 isolates (workerd), not Node. `fs`, `child_process`, `net`, raw TCP sockets — none of it exists. Enable `compatibility_flags = ["nodejs_compat_v2"]` for the polyfilled subset (Buffer, EventEmitter, util, crypto, async_hooks, etc.). Even then, modules that shell out or open ports won't work. **Library choice is gated by this** — pick edge-compatible libraries (Hono, drizzle-orm with HTTP/D1 drivers, Stripe SDK supports edge, etc.).

2. **CPU time vs wall-clock time are different limits.** Free tier: 10ms CPU per request. Paid: 30s CPU. Wall clock can be much longer if you're waiting on I/O (`waitUntil` extends background work up to 30s, longer for some triggers). Code that does heavy synchronous compute (hashing big payloads, parsing 100MB JSON) will hit CPU limits regardless of how long it has to run. **Move compute to Workers AI, R2 transformations, or containers** when this binds.

3. **Subrequest budget is 50 (free) / 1000 (paid) per Worker invocation.** Every `fetch()` you make from a Worker — to your D1, R2, Vectorize, KV, another Worker, an external API — counts. Loop-heavy code that issues a subrequest per iteration breaks at scale. Batch (D1 batch, R2 list, Vectorize batch upsert), or fan out across DO instances.

4. **`fetch()` from a Worker has different semantics depending on URL.** Hitting `cloudflare-worker.example.com` from your own Worker will loop back through the Cloudflare network and re-trigger Workers (good for routing, surprising for performance). Hitting your own zone may hit cache. Use service bindings or RPC for in-Cloudflare calls — they're free, internal, and skip the egress hop.

5. **Durable Objects guarantee single-instance routing per ID, not global serialization.** Two requests to the same DO ID run on the same instance, in-order — that's the contract. But that one instance is a single point of contention. Hot keys are your enemy. Shard DO IDs by user/tenant/entity; don't centralize all writes through one DO unless you genuinely need strict serialization on that key.

6. **KV is eventually consistent (~60s).** Writes propagate to read POPs over up to about a minute. KV is for read-heavy config, feature flags, sessions where stale-by-a-minute is acceptable. **Don't use KV for anything where read-your-writes matters.** Use D1 with the Sessions API or a DO if you need that.

7. **D1 reads from replicas by default once you enable replication.** Without the Sessions API, you can read a stale row right after writing it. Wire `D1_SESSION` (or pass `bookmark` explicitly) on requests that need read-your-writes. The cost of forgetting this is real: write a row, redirect, fail to find the row, render a 404, user reports a bug.

8. **R2 is S3-compatible but has zero egress fees.** This is the whole point. If your design involves serving big assets to users, R2 dominates S3 on TCO unless you have egress credits. But "S3-compatible" has gaps — some less-common S3 operations are not implemented. Stick to the documented S3 surface ([R2 S3 API compatibility](https://developers.cloudflare.com/r2/api/s3/api/)).

9. **Hyperdrive caches reads but you must opt in per query.** By default queries are pooled but not cached. Enable caching (`disable: false` in the config, or use a hyperdrive_disable hint per query). Cache invalidation is TTL-based — if you cache writes-followed-by-reads you'll see stale data. Treat Hyperdrive cache like a CDN over your DB.

10. **`compatibility_date` is not optional.** Without one, Workers run with old (pre-2022-ish) semantics — fetch streams, encoding, headers all behave differently. Pin `compatibility_date` near deployment date and don't blindly bump it; runtime semantics can change (rare but real). Read `developers.cloudflare.com/workers/configuration/compatibility-dates/` before changing it. ([compatibility-dates docs](https://developers.cloudflare.com/workers/configuration/compatibility-dates/))

## Cloudflare-shaped scaling recipe (startup → enterprise)

A team that adopts Cloudflare typically goes through these stages. The team should recognize where they are and not over- or under-engineer for the stage.

### Stage 1 — single-Worker MVP (1-5 engineers)

- One Worker (Hono router), one D1 database, one R2 bucket if needed.
- KV for session tokens.
- Workers AI through AI Gateway for any LLM features.
- Wrangler v4 + GitHub Actions or Cloudflare Workers Builds.
- WAF managed rulesets in log mode while the app stabilizes.
- One Cloudflare account; per-env via `--env` flag.
- Compatibility date pinned to current.
- Workers Logs enabled, full sampling.
- Cost: typically <$100/month all-in for early-stage apps.

What to skip: Workers for Platforms, containers, Workflows (unless you genuinely need multi-step durable), Magic Transit, Browser Isolation, CASB. Most enterprise products don't apply.

### Stage 2 — multi-Worker (5-20 engineers)

- Workers split by bounded context (auth, api, billing, jobs), linked via RPC bindings.
- D1 with Sessions API where read-your-writes matters.
- DO for per-entity hot paths (per-user wallet, per-room state, per-document collab).
- Queues for decoupled async work; Workflows for multi-step business flows.
- Terraform for the infra around Workers; Wrangler for the script deploys.
- Versions + gradual rollout for prod deploys.
- WAF tuned and in block mode; rate limiting in place at edge and in Workers.
- Cloudflare Access for internal tools.
- Logpush to a SIEM (Datadog / Splunk / S3) for audit + compliance.
- AI Gateway with cache and fallback; eval suite in CI.
- Vectorize V2 for retrieval; AI Search for managed RAG over R2 docs.

### Stage 3 — multi-team / multi-product (20-100 engineers)

- Multiple Cloudflare accounts (per env, optionally per business unit).
- Workers for Platforms when running customer code.
- Containers on Workers for the workloads that don't fit V8.
- API Shield for high-value APIs.
- mTLS for partner B2B integrations.
- Cloudflare for SaaS for customer-branded hostnames.
- Comprehensive observability (Workers Logs sampled, Analytics Engine for custom metrics, Logpush to SIEM, alerts wired to PagerDuty).
- IaC (Terraform / Pulumi) owns everything; Wrangler only deploys the script.
- Per-purpose API tokens; secret rotation automation; OIDC federation from CI.

### Stage 4 — enterprise (100+ engineers)

- Multi-region data residency enforcement.
- Magic Transit / Magic WAN for network-level edge.
- Cloudflare One / Zero Trust suite for employee endpoints.
- CASB for SaaS posture.
- BAA / SOC 2 / ISO 27001 documentation aligned to product-in-scope list.
- Golden path documented in an internal IDP; new services use the Cloudflare template.
- Workers for Platforms with full tenant isolation (Dispatch Namespaces, Outbound Workers, Tail Workers per tenant).

ETYB will encounter teams at every stage. **Match recommendations to stage** — proposing Workers for Platforms to a 3-person startup is over-engineering; proposing one Worker to a 50-engineer org with 10 product surfaces is under-engineering.

## Cross-stack composition (Cloudflare with other clouds)

Cloudflare is often the front end for an app whose back end runs elsewhere. Cross-cutting rules when composing:

- **Cloudflare + AWS** — Cloudflare for TLS/WAF/Bot/Access/edge transforms; AWS for compute/DBs. Use Tunnel to private VPC subnets where possible. Common pattern: Worker → Tunnel → ALB → ECS/Lambda. Pair with `aws` stack pack (when present).
- **Cloudflare + GCP** — Same shape. Worker → Tunnel or public LB → Cloud Run / GKE / Cloud Functions. Pair with `gcp` stack pack.
- **Cloudflare + Azure** — Same shape. Worker → Tunnel or App Gateway → AKS / App Service / Functions. Pair with `azure` stack pack.
- **Cloudflare + Supabase / Neon / PlanetScale** — Hyperdrive in front of these Postgres/MySQL services is the canonical pattern. The DB vendor handles HA + backups + extensions; Cloudflare handles pool + cache + private connectivity.
- **Cloudflare + Stripe / Adyen / payment processors** — Workers call payment APIs via `fetch()`; through AI Gateway for analytics; webhooks ingest via Email Workers or Worker handlers with signature verification. PCI scope analysis lives in `fintech-architect`.
- **Cloudflare + Vercel / Netlify** — Pages-style hosts that overlap with Workers Static Assets. Pick one for the static layer; don't run a Cloudflare zone in front of Vercel if you don't have to (double-CDN tax). Pair: Cloudflare for DNS + WAF + Workers; Vercel for the SSR frontend if the framework support is materially better there.

## Compliance composition (verticals)

When a Cloudflare engagement touches a vertical:

| Situation | Defer to | Cloudflare-side responsibility |
|-----------|----------|---------------------------------|
| Healthcare (HIPAA, FHIR) | `healthcare-architect` | Cloudflare offers BAA on Enterprise plans for in-scope products (Workers, R2, KV, D1, DO, AI Gateway with private models, Access, WAF, etc.). Confirm in-scope list at contract time. PHI in logs is the most common gotcha — `Logpush` filters and Workers Logs sampling. |
| Fintech (PCI, PSD2, AML) | `fintech-architect` | Workers + R2 + D1 are PCI-DSS-eligible on appropriate plans. Cardholder data should never hit KV (eventual consistency + no TTL guarantees on deletes). Use Stripe/Adyen at the edge; Cloudflare's job is the WAF / rate limiting / mTLS plumbing, not the ledger. |
| Real-time (SFU, chat) | `real-time-architect` | Realtime API, Durable Objects (WebSockets + Hibernation API), Workers' WebSocket support. DO Hibernation is the cost-controlling primitive for many idle connections. |
| Multi-tenant SaaS | `saas-architect` | Workers for Platforms (Dispatch Namespaces + Outbound Workers + Tail Workers). Per-tenant isolation lives here, not in `if (tenantId)` branches in one Worker. |
| Commerce (cart, catalog) | `e-commerce-architect` | R2 for catalog assets, Images for thumbnails, KV for cart sessions (only if eventual is OK), D1 for catalog with Vectorize for search; Bot Management + Turnstile for checkout abuse. |

Don't restate compliance content from this pack. Route to the vertical; the Cloudflare overlay tells the team which **platform** primitives compose with the vertical's pattern.

## Standing instructions for every role on a Cloudflare engagement

1. **Anchor to currency.** Workers and bindings move weekly. Before recommending API shapes, CLI flags, or product names, consult the role overlay; for anything specific (a method signature, a limit, a pricing number), prefer the linked authoritative source over baked knowledge.

2. **Honor compatibility-date discipline.** Every Worker has a `compatibility_date` and 0+ `compatibility_flags`. Treat them like a runtime version pin. New project: pin to the current month's date. Existing project: don't bump silently — runtime behavior can shift.

3. **Prefer bindings over network calls.** If two Workers need to talk, use a service binding (RPC). If a Worker needs storage, use a binding (D1, R2, KV, DO, Vectorize). Bindings are free, secure, and faster than `fetch()` over the public internet. **The bindings list in `wrangler.toml` is the architecture diagram.**

4. **Respect the V8 isolate model.** No stateful in-memory caches that you expect to persist between requests (the isolate can be recycled at any time). No long-running threads or persistent connections. State lives in DO, D1, KV, or R2. The isolate's job is request handling, period.

5. **Stay specific about which Workers plan and which products.** "Cloudflare" spans 30+ products with different free/paid tiers and limits. Workers Paid ($5/mo) unlocks Cron Triggers, Queues, large CPU limits, Durable Objects, R2 (also has its own pricing), etc. Workers Free has hard caps. **Ask if it's unclear which plan; recommendations branch heavily on this.**

## Cost ceiling — quick math the team should internalize

Cloudflare's pricing has unusual properties that affect architecture decisions:

- **Workers Free** — 100K requests/day, 10ms CPU/req. Hobby projects only.
- **Workers Paid ($5/month)** — 10M requests included, $0.30/M after; 30s CPU/req; 50ms CPU budget per request before billing (paid). Unlocks Durable Objects, Queues, Cron, KV beyond free, large CPU.
- **D1** — usage-based: rows read, rows written, storage. Aggressive free tier; designed to be cheap at moderate scale.
- **R2** — storage + Class A/B ops; **zero egress fees**. This is the killer feature. If you serve 100TB/mo to users out of S3, that's ~$9000 in egress; out of R2, $0.
- **KV** — usage-based: reads, writes, storage. Reads are cheap; writes are not (especially with rapid invalidation).
- **Durable Objects** — request count + duration + storage. SQLite-backed DOs have separate storage pricing.
- **Workers AI** — per-neuron pricing; some models have free tier inclusions. Pricing is tiered by model size.
- **AI Gateway** — free tier covers most teams; paid tiers add log retention and advanced features.
- **Vectorize** — vector count + queries. Cheaper than most managed vector DBs.
- **Hyperdrive** — request-based + a fee for cached vs uncached queries; cheap relative to managed DB costs.
- **Queues** — paid feature; messages-based pricing.
- **Workflows** — paid feature; request-based pricing.
- **Workers Logs / Logpush / Analytics Engine** — usage-based; can add up at volume.
- **AI Search** — usage-based; combines underlying R2 + Vectorize + Workers AI costs.

Standing guidance:
- **Move egress-heavy workloads to R2.** Always wins at any scale beyond hobby.
- **Cache aggressively at the AI Gateway tier.** Same prompts → same cached responses, free.
- **Sample Workers Logs above ~100 req/sec/Worker.** Full sampling adds up.
- **Use the Cache API (`caches.default`) before going to KV** for short-TTL data that doesn't need to be globally consistent.
- **Hyperdrive replaces the cost of running a Postgres pooler in your own infra**, plus reduces DB connection pressure.

Always confirm pricing against [Cloudflare's pricing page](https://www.cloudflare.com/plans/) for net-new commitments; pricing models occasionally shift.

## Tooling specifics — what to install / configure

- **Wrangler v4** — `npm i -D wrangler`. CLI for dev, deploy, secret, tail, types generation. **Don't install globally**; pin per project.
- **Miniflare** (now built into Wrangler) — local-fidelity simulator for Workers + bindings. Used under the hood by `wrangler dev` and by Vitest.
- **`@cloudflare/vitest-pool-workers`** — TDD primitive for Workers. Runs Vitest tests against an actual workerd runtime with bindings configured the same way as production. Required for any non-trivial Worker.
- **`@cloudflare/workers-types`** — TypeScript types for the runtime. Generated per project by `wrangler types` to include your bindings. Re-run after binding changes.
- **`cloudflared`** — for Tunnel + local Hyperdrive private-DB connectivity.
- **`cloudflare:cloudflare-mcp`** plugin — when installed, gives ETYB live read access to the account: Worker code, D1 query, KV keys, R2 listings, Hyperdrive configs. Prefer this for "what's currently deployed" questions; baked knowledge can't answer those.

## Currency — when this Stack is stale

- If `last_verified_on` is **>90 days old**, treat any `high` drift_risk product (Workers runtime, Wrangler, bindings, DO, D1, Hyperdrive, Vectorize, Workers AI catalog, AI Gateway, AI Search, Pages/Static Assets, Workflows, Pipelines, Workers Logs, Smart Placement, Workers for Platforms, Containers) as **needing verification** before you commit to specifics. Use the strict path: WebFetch the linked authoritative source, or invoke `cloudflare:cloudflare-mcp` if present.
- If `last_verified_on` is **>180 days old**, the whole pack is suspect. Open an issue against the maintainer; do not produce production-grade guidance without re-verification.
- The high-velocity products on this platform are: **Workers runtime, Wrangler, AI catalog, AI Gateway, Workflows, Pipelines, Workers Static Assets, Vectorize, Workers Logs, Workers for Platforms, Containers**. Verify these first when refreshing.

Refresh recipe (for the maintainer):
1. Read the [Workers changelog](https://developers.cloudflare.com/workers/platform/changelog/) since `last_verified_on`.
2. Skim the [Cloudflare blog](https://blog.cloudflare.com/) for product launches and renames.
3. Diff `wrangler` releases on [npm](https://www.npmjs.com/package/wrangler) — look at major/minor changelogs.
4. Confirm `delegate_to_skills` entries still exist (does `cloudflare:cloudflare-mcp` still ship?).
5. Bump `last_verified_on`. Note verification basis in commit.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Frontend code that's mostly framework-shaped (Next.js, Nuxt, Astro, SvelteKit) and only touches Cloudflare via Workers Static Assets or Pages | `frontend-architect` (without this pack) — they own the framework; bring this pack back for the deployment surface only |
| Backend service architecture for non-Cloudflare runtimes (Node service, JVM app, Go service) | `backend-architect` (without this pack) |
| K8s, ECS, GCE compute that happens to be Cloudflare-fronted | `devops-engineer` for the compute side; this pack only owns Cloudflare-side primitives |
| Generic test strategy / pyramid / framework selection that isn't Worker-specific | `qa-engineer` (without this pack) |
| Production reliability (SLOs, incident response) on Cloudflare | `sre-engineer` plus this pack — Cloudflare-specific observability lives in `devops-engineer` overlay, SLO definition lives in sre-engineer |
| Skill/MCP authoring on top of Cloudflare's MCP catalog | this pack's `backend-architect` overlay (Workers + RPC + MCP patterns) plus generic skill-authoring guidance |

## Anti-patterns to refuse on Cloudflare engagements

These come up often enough that the team should refuse them on sight and route to a better pattern:

1. **"Just run Express on Workers."** No. Use Hono or itty-router or write fetch handlers directly. Express expects Node primitives that Workers don't have (req/res streams, body parser internals, fs). Express adapters exist but degrade — pick a router built for the web-standards fetch model.
2. **"Put cart state in KV."** No — KV is eventually consistent. Carts go in DO (per-user) or D1 (transactional). The user adds an item, hits checkout, doesn't see the item, files a bug.
3. **"Use Pages for a new project."** Pages is in maintenance. Use Workers Static Assets.
4. **"Build the multi-step async flow with Queues + DO + cron."** Not anymore — use Workflows. Workflows are the durable-execution primitive specifically for that pattern.
5. **"Skip AI Gateway, call OpenAI directly."** You lose cache, fallback, eval, analytics, BYOK. AI Gateway is free-tier-friendly; turn it on.
6. **"One Worker, 50 routes, all teams contribute."** Bound the Worker by domain. Use RPC bindings between Workers. Independent rollback, independent risk.
7. **"Hardcoded model IDs everywhere."** Workers AI catalog churns; deprecations happen. Models in env vars, deploys roll forward.
8. **"`if (env === 'prod')` branching."** Use `--env` with Wrangler. Different bindings, different secrets, different deploys.
9. **"WAF in block mode on day one without tuning."** False positives will block real users. Log mode → tune → block mode.
10. **"Origin IP in `Cf-Connecting-IP` is authoritative for security decisions in the Worker."** Only when `req.cf` is populated. Direct-origin requests bypass.

## Open gaps in v4.0.0

Explicit so future iterations know what's missing:

- No standalone overlay for `frontend-architect` — Cloudflare's frontend surface (Workers Static Assets, Pages migration, Hono SSR, framework adapters) is covered as cross-references inside `backend-architect.md` and `devops-engineer.md`. A dedicated overlay is a v4.1 candidate if request signal justifies.
- No standalone overlay for `qa-engineer` — Worker testing patterns (`vitest-pool-workers`, integration via `wrangler dev --remote`, staged deploys, Browser Rendering for E2E) are covered inside `devops-engineer.md` and `backend-architect.md`.
- No `sre-engineer` overlay — Workers' production-reliability surface (Workers Logs, Logpush, Analytics Engine, Workers Health Checks, alerting via Cloudflare Notifications or webhook → PagerDuty) is partially in `devops-engineer.md`; a dedicated overlay is reasonable in v4.1.
- No `technical-writer` overlay — documentation tooling around Cloudflare is generic (the pack doesn't change writing patterns).
- Magic Transit / Magic WAN / Spectrum get one paragraph in `security-engineer.md` and `system-architect.md`. Deep enterprise-network coverage (BYOIP, GRE, IPsec, anycast routes) is a separate Stack candidate if demand justifies.
- Cloudflare for SaaS (custom hostnames, SSL for SaaS) gets one section in `system-architect.md`. SaaS-platform patterns themselves are `saas-architect`'s territory; the platform mechanics are here.

If a user's request hits any of these gaps, say so explicitly and proceed with general-purpose knowledge plus current-release validation.
