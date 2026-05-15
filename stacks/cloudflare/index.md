---
title: Cloudflare
description: Cloudflare platform knowledge overlay — Workers, Durable Objects, D1, R2, KV, Hyperdrive, Queues, Workflows, Vectorize, AI Gateway, Workers AI, AI Search, Access, Tunnel, WAF. Current to 2026-Q2.
stack:
  vendor: cloudflare
  last_verified_on: "2026-05-14"
  drift_risk_default: medium
  applies_to_roles:
    - backend-architect
    - system-architect
    - devops-engineer
    - ai-ml-engineer
    - database-architect
    - security-engineer
  authoritative_sources:
    - { name: "Cloudflare Developer Docs",            url: "https://developers.cloudflare.com/",                                          type: official_docs }
    - { name: "Workers Documentation",                url: "https://developers.cloudflare.com/workers/",                                  type: official_docs }
    - { name: "Wrangler CLI Reference",               url: "https://developers.cloudflare.com/workers/wrangler/commands/",                type: cli_reference }
    - { name: "Workers Changelog",                    url: "https://developers.cloudflare.com/workers/platform/changelog/",               type: changelog }
    - { name: "Cloudflare REST API",                  url: "https://developers.cloudflare.com/api/",                                      type: api_reference }
    - { name: "Cloudflare Blog (product launches)",   url: "https://blog.cloudflare.com/",                                                type: changelog }
    - { name: "Cloudflare Status",                    url: "https://www.cloudflarestatus.com/",                                           type: community }
    - { name: "Cloudflare Compatibility Dates",       url: "https://developers.cloudflare.com/workers/configuration/compatibility-dates/", type: official_docs }
  delegate_to_skills:
    - { skill: "cloudflare:cloudflare-mcp", covers: ["workers", "d1", "r2", "kv", "hyperdrive", "pages"] }
---

import { Aside } from '@astrojs/starlight/components';

<Aside type="note" title="Migration in progress">
This Stack's body was authored from the etyb-skills v4 source on 2026-05-14. The frontmatter is canonical; per-product pages and composed role views under `/stacks/cloudflare/<product>/` and `/stacks/cloudflare/<role>/` are linked below.
</Aside>

## Currency

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Cloudflare Developer Docs, Workers Changelog, and Cloudflare Blog through 2026-Q2.</div>

Workers and bindings ship changes weekly — faster than almost any platform in this repo. If today's date is more than 90 days past the last_verified_on above, treat any `high` drift-risk product as needing verification. The drift-check protocol at [/conventions/knowledge-currency/](/conventions/knowledge-currency/) governs how agents handle staleness on this Stack.

## What changed in 2025-2026 that older training data misses

An LLM with a 2024 cutoff will be wrong about most of this. Read carefully before recommending anything specific:

- **Workers RPC is the canonical inter-worker pattern.** `WorkerEntrypoint` classes with method calls (`await env.OTHER.someMethod(args)`) replace `env.OTHER.fetch(request)` style service bindings for new code.
- **Durable Objects are SQLite-backed by default.** New DO classes get a per-DO SQLite database with full SQL, transactions, ~10GB per instance. Use `new_sqlite_classes` in migrations, not `new_classes`.
- **D1 GA'd in 2024, gained global read replication + Sessions API in 2025.** Multi-region reads with read-your-writes consistency. Don't build apps that assume a single primary location anymore.
- **Hyperdrive now supports MySQL and private DBs over Tunnel.** Connection pooling + query caching + private connectivity in one binding.
- **Vectorize V2** is the current generation — up to 1536-dim, metadata indexes for filtered search, namespace partitioning, multi-million-vector indexes.
- **Workflows GA'd in 2025.** Durable-execution primitive (Temporal-as-a-binding). Replaces the older Queues + DO state + cron pattern for orchestration.
- **Pages is in maintenance mode.** New projects should use **Workers Static Assets** with the `assets` binding. Pages keeps working; new platform features land in Workers Static Assets first.
- **AutoRAG was renamed to AI Search** in 2025. Same product (managed RAG pipeline on R2 + Vectorize + Workers AI). Docs/console use AI Search.
- **Realtime (TURN + SFU + Realtime API) is GA.** Replaces the older "Cloudflare Calls" naming.
- **Workers Logs** (queryable, persistent, no Logpush needed) replaced the older pattern of pushing every Worker invocation to external sinks for casual debugging.
- **Containers on Workers** (beta through 2025) lets a Worker spawn long-running containers for heavy or stateful workloads — bridges to Node/Python apps that don't fit V8.
- **Workers AI catalog expanded substantially.** Llama 4 family, DeepSeek-R1/V3, Mistral, Whisper-large-v3-turbo, Stable Diffusion XL, BGE embeddings. Per-neuron pricing model.
- **AI Gateway** is the universal model proxy — cache, fallback, rate limiting, guardrails, BYOK, unified analytics across OpenAI/Anthropic/Workers AI. If you call models from Workers, call them through AI Gateway.
- **Wrangler v4** is current. `wrangler deploy` (not `publish`), `wrangler types`, `wrangler secret bulk`. Old v1/v2 syntax must be flagged and replaced.
- **`compatibility_date` + `compatibility_flags` are mandatory.** Without them the runtime falls back to old behavior. New projects pin near current; set `nodejs_compat_v2` if needed.
- **Smart Placement** is broadly recommended for Workers talking to a single backend region — runs the Worker close to the backend instead of the user.
- **Workers for Platforms** matured: Dispatch Namespaces, Outbound Workers, Tail Workers — the SaaS-platform pattern for running customer code.

If you find yourself recommending `wrangler publish`, raw service bindings with `.fetch()`, KV-style DO storage for new code, Pages for net-new projects, AutoRAG, or "Cloudflare Calls" — you're working from stale knowledge. Refresh from the products list below.

## Products covered

Per-product pages under `/stacks/cloudflare/<product>/`. Drift-risk badges flag which products move fastest:

### Compute and runtime

| Product | Drift risk | Why |
|---|---|---|
| [Workers](/stacks/cloudflare/workers/) | <span class="etyb-drift-badge" data-risk="high">high</span> | workerd runtime + compatibility-date model + nodejs_compat flags shift quarterly |
| [Workers RPC](/stacks/cloudflare/workers-rpc/) | <span class="etyb-drift-badge" data-risk="high">high</span> | `WorkerEntrypoint` is canonical as of 2024-25; older `fetcher.fetch` style is legacy |
| [Durable Objects](/stacks/cloudflare/durable-objects/) | <span class="etyb-drift-badge" data-risk="high">high</span> | SQLite-backed GA'd 2024, became default class type in 2025; alarms + transaction semantics shifted |
| [Wrangler CLI](/stacks/cloudflare/wrangler/) | <span class="etyb-drift-badge" data-risk="high">high</span> | v4 line; flag/command names mutate per minor release |
| [Smart Placement](/stacks/cloudflare/smart-placement/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Config flag; broadly recommended for backend-bound Workers |
| [Workers for Platforms](/stacks/cloudflare/workers-for-platforms/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Dispatch Namespaces + Outbound Workers + Tail Workers; SaaS-platform pattern, premium SKU |

### Storage and data

| Product | Drift risk | Why |
|---|---|---|
| [D1](/stacks/cloudflare/d1/) | <span class="etyb-drift-badge" data-risk="high">high</span> | GA 2024; global read replication + Sessions API + larger DB sizes landed 2024-2025 |
| [R2](/stacks/cloudflare/r2/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | S3-compatible, stable surface; event notifications, R2 SQL, lifecycle features expanded |
| [KV](/stacks/cloudflare/kv/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Eventually-consistent semantics stable for years; pricing tier shifted 2024 |
| [Hyperdrive](/stacks/cloudflare/hyperdrive/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Postgres + MySQL; query plan + connection pooling behavior evolves; supports private DBs over Tunnel |

### Async + scheduling

| Product | Drift risk | Why |
|---|---|---|
| [Queues](/stacks/cloudflare/queues/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | GA; pull consumers, message delays, dead-letter, batch retry semantics added through 2025 |
| [Cron Triggers](/stacks/cloudflare/cron-triggers/) | <span class="etyb-drift-badge" data-risk="low">low</span> | `scheduled` handler stable; UTC only, 1-min granularity |
| [Workflows](/stacks/cloudflare/workflows/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Durable-execution primitive, GA 2025; new pattern most teams haven't seen |
| [Pipelines](/stacks/cloudflare/pipelines/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Data-ingest product (HTTP → R2 + transform); newer surface, naming and limits in flux |

### AI / ML

| Product | Drift risk | Why |
|---|---|---|
| [Vectorize](/stacks/cloudflare/vectorize/) | <span class="etyb-drift-badge" data-risk="high">high</span> | V2: increased dimensions, metadata indexes, larger index sizes; v1 has migration path |
| [AI Gateway](/stacks/cloudflare/ai-gateway/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Provider catalog + features (cache, fallback, guardrails, BYOK) ship continuously |
| [Workers AI](/stacks/cloudflare/workers-ai/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Model catalog churns weekly; Llama 4, DeepSeek, Mistral, Whisper, SDXL, BGE |
| [AI Search](/stacks/cloudflare/ai-search/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Renamed from AutoRAG in 2025; managed RAG on R2 + Vectorize + Workers AI |

### Media + realtime

| Product | Drift risk | Why |
|---|---|---|
| [Realtime](/stacks/cloudflare/realtime/) | <span class="etyb-drift-badge" data-risk="high">high</span> | TURN + SFU + Realtime API; GA 2025; replaces "Cloudflare Calls" naming |
| [Stream](/stacks/cloudflare/stream/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Video ingest/playback; Live Input + Stream Connect stable |
| [Images](/stacks/cloudflare/images/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Polish + Resizing + Images delivery; transforms URL grammar stable |
| [Browser Rendering](/stacks/cloudflare/browser-rendering/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Puppeteer-compatible API served from Workers; pricing per browser-hour |

### Static assets + sites

| Product | Drift risk | Why |
|---|---|---|
| [Pages](/stacks/cloudflare/pages/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Maintenance mode; new builds should use Workers Static Assets; migration guide published 2024 |
| [Workers Static Assets](/stacks/cloudflare/workers-static-assets/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Replaces Pages for new projects; assets binding + _headers + _routes.json semantics evolving |

### Email + tag management

| Product | Drift risk | Why |
|---|---|---|
| [Email Routing](/stacks/cloudflare/email-routing/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Inbound-only; outbound via MailChannels or SMTP providers |
| [Email Workers](/stacks/cloudflare/email-workers/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Programmable inbound handlers; ties into Email Routing |
| [Zaraz](/stacks/cloudflare/zaraz/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Server-side tag manager; Worker-emitted server-side events |

### Security + zero trust

| Product | Drift risk | Why |
|---|---|---|
| [Turnstile](/stacks/cloudflare/turnstile/) | <span class="etyb-drift-badge" data-risk="low">low</span> | CAPTCHA alternative; widget + server validation API stable |
| [Access (ZTNA)](/stacks/cloudflare/access/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Identity-aware proxy; integrates with IdPs and Tunnel; Service Auth + JWT patterns stable |
| [Cloudflare Tunnel](/stacks/cloudflare/tunnel/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | cloudflared replaces VPN ingress; preferred path to expose private origins |
| [WAF + Managed Rulesets](/stacks/cloudflare/waf/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | OWASP and Cloudflare-managed rules; custom rule engine syntax stable |
| [Rate Limiting](/stacks/cloudflare/rate-limiting/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Two products: rules-engine (per-zone) and Workers Rate Limiting binding (in-Worker) |
| [DDoS Protection](/stacks/cloudflare/ddos/) | <span class="etyb-drift-badge" data-risk="low">low</span> | L3-L7 protection always-on; managed ruleset + Spectrum for non-HTTP |
| [Magic Transit](/stacks/cloudflare/magic-transit/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | L3 protection + SD-WAN replacement for enterprise networking |
| [Argo](/stacks/cloudflare/argo/) | <span class="etyb-drift-badge" data-risk="low">low</span> | Tiered cache + smart routing; cost-add for HTTP zones |

### Observability

| Product | Drift risk | Why |
|---|---|---|
| [Logpush](/stacks/cloudflare/logpush/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Streaming logs to S3/R2/GCS/Datadog/Splunk; per-dataset configs stable |
| [Analytics Engine](/stacks/cloudflare/analytics-engine/) | <span class="etyb-drift-badge" data-risk="medium">medium</span> | Time-series datapoints with SQL queries; pricing per million datapoints |
| [Workers Logs](/stacks/cloudflare/workers-logs/) | <span class="etyb-drift-badge" data-risk="high">high</span> | Queryable persistent logs; replaced legacy Logpush-for-Workers in 2024-25 |

## Role overlays

Composed views under `/stacks/cloudflare/<role>/`. Each one stitches together the products that role's work touches, with links into the product pages above.

- [`/stacks/cloudflare/backend-architect/`](/stacks/cloudflare/backend-architect/) — Worker code, handlers, bindings graph, RPC, DO patterns, Workflows, Queues
- [`/stacks/cloudflare/system-architect/`](/stacks/cloudflare/system-architect/) — Topology decisions, primitive selection, Workers vs containers vs external, cross-region patterns
- [`/stacks/cloudflare/devops-engineer/`](/stacks/cloudflare/devops-engineer/) — Wrangler discipline, CI/CD, secrets, gradual rollouts, observability, IaC
- [`/stacks/cloudflare/ai-ml-engineer/`](/stacks/cloudflare/ai-ml-engineer/) — Workers AI catalog, AI Gateway, Vectorize design, AI Search, RAG, agents on Workflows
- [`/stacks/cloudflare/database-architect/`](/stacks/cloudflare/database-architect/) — D1 schema, indexes, Sessions API, R2 layout, KV semantics, Hyperdrive sizing, Vectorize indexes
- [`/stacks/cloudflare/security-engineer/`](/stacks/cloudflare/security-engineer/) — WAF, rate limiting, Turnstile, Access, Tunnel, mTLS, API Shield, secrets, prompt-injection defenses

## Authoritative sources

For verified-current behavior, see the official Cloudflare surfaces:

- **[Cloudflare Developer Docs](https://developers.cloudflare.com/)** — canonical reference
- **[Workers Documentation](https://developers.cloudflare.com/workers/)** — runtime, bindings, configuration
- **[Workers Changelog](https://developers.cloudflare.com/workers/platform/changelog/)** — refresh anchor for time-sensitive claims
- **[Wrangler CLI Reference](https://developers.cloudflare.com/workers/wrangler/commands/)** — current command surface
- **[Cloudflare REST API](https://developers.cloudflare.com/api/)** — account-level operations
- **[Cloudflare Blog](https://blog.cloudflare.com/)** — product launches, renames, deprecations
- **[Cloudflare Status](https://www.cloudflarestatus.com/)** — live incident status
- **[Compatibility Dates](https://developers.cloudflare.com/workers/configuration/compatibility-dates/)** — runtime version pinning

## Delegate skills

When the user environment has `cloudflare:cloudflare-mcp` installed, **prefer the MCP** for live account introspection — current Worker code, D1 schema, KV/R2 listings, Hyperdrive configs, documentation search. This site is the *fallback* — opinionated, curated, but secondary when first-party tooling is available.

Specifically, the Cloudflare MCP covers `workers`, `d1`, `r2`, `kv`, `hyperdrive`, and `pages`. For any of those products in the strict-path category (HIGH-STAKES claims, or `drift_risk: high` with `last_verified_on > 90 days`), ETYB will defer to the MCP rather than answer from this Stack's baked content.
