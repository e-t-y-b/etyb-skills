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

# Cloudflare Stack — Team Briefing

This is a **knowledge overlay**, not a new specialist. The existing ETYB team does the work — backend-architect writes the backend code, devops-engineer wires the deploys, security-engineer enforces the boundary. This pack tells each role where the current Cloudflare knowledge lives.

## Where the full briefing lives

The full Stack briefing lives in this same folder. Per-product and per-role pages are siblings of this `SKILL.md`. Every page carries `last_verified_on` stamps and authoritative-source URLs in its frontmatter; see `skills/etyb/core/knowledge-currency.md` for the drift-check protocol that uses them.

- **Stack briefing:** [`stacks/cloudflare/index.md`](index.md)
- **Per-product pages:** `stacks/cloudflare/<product>.md` — one per entry in `products_covered` above
- **Per-role views:** `stacks/cloudflare/<role>.md` — one per role in `applies_to_roles` above

When ETYB is installed locally these are read directly from disk. For third-party agents without the install, the same content is reachable as raw markdown at `https://raw.githubusercontent.com/e-t-y-b/etyb-skills/main/stacks/cloudflare/<page>.md`.

When `delegate_to_skills` (frontmatter above) lists a first-party vendor MCP/skill that's installed in the user's environment, ETYB defers to it first. The in-repo Stack content is the curated fallback.
## What changed in 2025-2026 that older training data misses

Critical context — an LLM with a 2024 cutoff will get these wrong:

- **Workers RPC is the canonical inter-worker pattern.** Service bindings that did `env.OTHER.fetch(request)` are legacy. Modern bindings use `WorkerEntrypoint` classes and method calls (`await env.OTHER.someMethod(args)`). RPC traverses Workers, Durable Objects, and Workers for Platforms — same primitive.
- **Durable Objects are SQLite-backed by default.** New DO classes get a per-DO SQLite database, not the legacy KV-style storage. Transactions, full SQL, alarms, and ~10GB per DO are standard. Old DO storage API (`this.state.storage.put/get`) still works but new code should use SQL.
- **D1 supports global read replication and the Sessions API.** Multi-region read replicas as of 2025; the Sessions API ensures read-your-writes consistency across replicas. Don't build D1 apps that assume a single primary location anymore.
- **Hyperdrive supports MySQL** in addition to Postgres, and can target private databases over Cloudflare Tunnel. It is now the standard way to put a relational DB behind Workers — connection pooling + query caching + private connectivity in one binding.
- **Vectorize V2** is the current generation: up to 1536-dim (and larger for some plans), metadata indexes for filtered search, multi-million-vector indexes per account, namespace partitioning. v1 indexes still exist but new builds should target V2.
- **Workflows GA'd in 2025.** Durable-execution primitive (think Temporal-as-a-binding). Long-running, retry-aware, sleepable. New mental model for orchestrating async work — don't reach for Queues + state-in-DO when Workflows fit.
- **Pages is in maintenance mode.** New projects should use **Workers Static Assets** with the `assets` binding. Pages keeps working; new platform features land in Workers Static Assets first.
- **AutoRAG was renamed to Cloudflare AI Search** in 2025. Same product (managed RAG pipeline on R2 + Vectorize + Workers AI).
- **Realtime (TURN + SFU + Realtime API) is GA.** Replaces the older "Cloudflare Calls" naming. Real-time audio/video apps on Workers without managing your own SFU.
- **Containers on Workers (beta through 2025)** lets a Worker spawn a long-running container for heavy or stateful workloads — bridges the gap to Node/Python apps that don't fit the V8-isolate model.
- **Wrangler v4** is current. `wrangler deploy` (not `publish`), `wrangler dev` (with --remote), `wrangler tail`, `wrangler types`, `wrangler secret bulk`. Old `wrangler publish` and Wrangler v1/v2 syntax must be flagged and replaced.
- **`compatibility_date` + `compatibility_flags` are mandatory.** Without them the runtime falls back to old behavior. New projects should pin `compatibility_date` near current and set `nodejs_compat` or `nodejs_compat_v2` if needed.

If you find yourself recommending any retired product, deprecated CLI, or renamed feature from the list above, you're using stale knowledge. Read the relevant sibling file in this folder before continuing.

## Standing instructions for every role on a Cloudflare engagement

1. **Anchor to currency.** Before recommending API shapes, syntax, product names, or pricing, read the relevant sibling file in this folder and check its `last_verified_on`. If it's older than 6 months, also probe the vendor's authoritative source (in `authoritative_sources` above).

2. **Defer to verticals on domain compliance.** This pack covers platform mechanics. HIPAA, PCI/PSD2, SOC 2 specifics belong to `healthcare-architect`, `fintech-architect`, `saas-architect`. Route to the vertical; don't restate compliance content from this pack.

3. **Respect platform-specific limits.** Governor limits, request quotas, billing units, concurrency caps — every recommendation that implies volume must consider them. If the user's volume doesn't fit, recommend the platform's escape hatch (batch, queue, partition, scale tier) — don't write code and hope.

4. **Use Workers RPC over Service-binding fetch for new inter-worker calls.** Bindings (D1, R2, KV, DO, Vectorize, RPC) are free, secure, and faster than `fetch()` over the public internet. The bindings list in `wrangler.toml` is the architecture diagram.

## When to escalate out of this pack

| Situation | Escalate to |
|-----------|-------------|
| Compliance specifics (HIPAA, PCI, SOC 2) | `healthcare-architect` / `fintech-architect` / `saas-architect` |
| Multi-stack architecture spanning vendors | `system-architect` (without the pack overlay) |
| Vendor-agnostic work that happens to touch Cloudflare | the relevant specialist (without the pack overlay) |

## Stack composition

If the user is running Cloudflare alongside another stack that has its own pack registered, both overlays load. Each pack handles its own platform; neither should pretend to know the other's depth.
