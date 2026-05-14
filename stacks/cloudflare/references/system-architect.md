---
role: system-architect
stack: cloudflare
last_verified_on: "2026-05-14"
---

# Cloudflare overlay for `system-architect`

You make topology calls. Workers vs containers vs external compute. D1 vs Hyperdrive vs external Postgres. Queues vs Workflows vs DO alarms. One Worker vs many. Smart Placement vs default routing. Cloudflare-only vs Cloudflare-fronting-AWS/GCP. This overlay teaches you what shape decisions look like on Cloudflare in 2026.

## Role briefing — architecture on Cloudflare

Cloudflare's distinctive property: **the platform runs everywhere, by default, for free, with low latency.** You don't choose regions. You don't size clusters. You don't manage capacity. You design for:

- **Distribution as the default state, not a goal you reach.** Your Worker is in 300+ locations the moment you deploy.
- **State that is intentionally placed, not distributed by hope.** D1 has a primary region + read replicas. DO instances have a home region. R2 buckets are multi-region but with a preferred placement. KV is global but eventually consistent.
- **The bindings list as the architecture diagram.** What state, what services, what AI, what queues — declared per Worker.
- **A hard wall between V8-isolate compute (cheap, fast, distributed) and container/external compute (when you outgrow the isolate model).**
- **The edge as a meaningful tier.** WAF, Access, Tunnel, Turnstile, AI Gateway all sit at the edge — between user and origin (or between Worker and external API).

Cloudflare is not a generic "cloud" — it's a CDN-plus-runtime. Architecting on it well means leaning into the edge primitives, not trying to replicate AWS patterns.

## Decision frameworks

### Workers vs Containers vs External compute

| Workload | First choice | Fallback | Why |
|----------|--------------|----------|-----|
| HTTP API, <30s per request, V8-runnable code | **Workers** | Containers on Workers | Cheap, distributed, zero ops |
| Long-running job (>30s), still V8-runnable | **Workflows** (durable execution) | Container | Steps can sleep, retry, survive restarts |
| Python ML scripts, FFmpeg, Pandoc, Ruby, etc. | **Containers on Workers** (beta) | External (AWS Lambda, ECS Fargate, Cloud Run) | V8 isolate doesn't fit |
| Heavy CPU (>30s CPU), batch | External compute (AWS Batch, GCP Batch) | Container on Workers if it fits | CPU ceilings on Workers |
| Stateful service requiring local disk | External (ECS, GCE) | Container on Workers if ephemeral disk OK | Workers have no persistent disk |
| Real-time SFU / TURN (WebRTC infra) | **Cloudflare Realtime** | External SFU (LiveKit, Daily, Twilio) | Realtime is the managed path |
| Inbound email processing | **Email Routing + Email Workers** | External (SES, Mailgun) | Already at the edge |
| Outbound email | External (Resend, Postmark, MailChannels, SES) | Email Worker forwarding only | Cloudflare doesn't send outbound from your domain by default |

### D1 vs Hyperdrive vs external Postgres/MySQL

| Need | Use |
|------|-----|
| New app, mostly KV-style + simple relational, <10GB | **D1** |
| New app, complex relational, multi-region reads, <100GB | **D1 with replication + Sessions API** |
| Existing Postgres/MySQL you don't want to migrate | **Hyperdrive in front of your DB** |
| Postgres with strict requirements (extensions, custom types, replication beyond CF support) | **External Postgres (Neon, Supabase, RDS, Aurora) + Hyperdrive** |
| Strict per-tenant isolation, <10GB per tenant, transactional | **Durable Object SQLite per tenant** |
| Analytics / time-series / append-only | **Analytics Engine** for online; **R2 + R2 SQL** for offline; never D1 for high-write |

D1's primary limitation as of 2025-26 is per-database size (check current limits before designing). It is genuinely globally-replicable now and feels real-relational — `JOIN`, `GROUP BY`, indexes, foreign keys. But if you're already on Aurora at scale, Hyperdrive-in-front is the lower-risk path.

### KV vs DO storage vs D1

| Need | Use |
|------|-----|
| Read-heavy config, ~60s staleness OK, key-value access | **KV** |
| Session tokens (per-user, lookups every request, OK to expire) | **KV with TTL** |
| Per-user state with read-your-writes | **DO SQLite** keyed on user ID, **or** D1 + Sessions API |
| Many users with mostly-isolated state | **DO per user** (sharded by user ID) |
| Shared queryable state across users | **D1** |
| Document store, large blobs | **R2** |
| High-throughput counter | **DO** (sharded) or **Rate Limiting binding** or **Analytics Engine** |

### Queues vs Workflows vs DO alarms

| Need | Use |
|------|-----|
| Decouple producer from consumer, batch processing, retries | **Queues** |
| Multi-step business process with sleeps, conditionals, durability | **Workflows** |
| Per-entity scheduled work ("remind user X in 1 hour") | **DO alarm** |
| Periodic batch ("every 5 minutes do X") | **Cron Trigger** (`scheduled` handler) |
| Stream processing high-volume events → R2 | **Pipelines** |

Common mistake: building a "workflow" out of Queues + DO state + cron. Workflows GA'd specifically to replace that pattern. **If your flow has more than 2 steps with dependencies, reach for Workflows first.**

### Single Worker vs many Workers

| Situation | Topology |
|-----------|----------|
| Small app, <5 routes, one team owns it | **One Worker, multiple routes** (Hono router) |
| Different deploy cadences for different domains (api vs admin vs auth) | **One Worker per domain**, linked via RPC bindings |
| Different teams own different Workers | **One Worker per team's surface**, RPC for inter-team contracts |
| You want per-piece independent rollback / canary | **Separate Workers** |
| Your code is so large the bundle approaches the limit | **Split** (one Worker per bounded context) |

Default is one Worker per bounded context, linked by RPC. Not one Worker per microservice on principle — that's microservice cargo culting at the edge.

### Workers for Platforms vs Many Workers

If you're running customer code (SaaS that lets users write JS that runs on your edge):

- **Workers for Platforms (Dispatch Namespaces).** Every tenant gets their own Worker; you dispatch to it from a router Worker. Outbound Workers control what their code can call out to. Tail Workers capture their logs. This is the **only** sensible pattern at any non-trivial scale. Premium SKU; talk to Cloudflare.

If you're running your own multi-tenant logic:

- **Single Worker with tenant-aware bindings.** The Worker is yours; tenants are data. Cheaper, simpler, less flexible.

If a customer asks "can I run my own JS on your platform" — that's Workers for Platforms territory, full stop.

### Smart Placement: on or off?

`placement.mode = "smart"` runs the Worker close to its backend instead of close to the user. Win conditions:

- The Worker makes >1 roundtrip to a single backend (D1, Hyperdrive'd Postgres, external API).
- The backend has a single home region (not distributed).
- The end-to-end roundtrip with default placement >> the end-to-end with smart placement.

Off conditions:
- Worker is essentially stateless and edge-only (just transforms, no backend).
- Worker fans out to multiple geographically distributed backends.
- You want predictably global low-latency without backend reach (e.g., serving cached responses).

Default: **on for any Worker that does substantial backend I/O.** Off for pure edge transformations.

### Single Cloudflare account vs many

| Scenario | Recommendation |
|----------|----------------|
| Startup, single product | One account |
| Multiple environments, careful blast-radius isolation | Account per environment (prod separate from staging/dev) |
| Multiple products, separate billing | Account per product |
| Customer-facing isolation (you host workers on behalf of customers) | Workers for Platforms (one account, dispatch namespaces) |
| Acquired company with their own Cloudflare estate | Keep separate until integration plan justifies merge |

Cost: separate accounts mean separate Workers Paid plans ($5/mo each), separate R2 charges, etc. Modest absolute cost but real if you have 30 envs.

### Cross-region with Cloudflare

Cloudflare's default is "Region: Earth" — Workers run everywhere, no region selection. But:

- **D1** has a primary region (where writes go) + replicas.
- **Durable Objects** have a home location (initially placed by access pattern).
- **R2** has bucket-level location hints (auto, EU, ENAM, FedRAMP regions for relevant plans).
- **Hyperdrive** points at a specific backend — that's your home region for that data.
- **Data Residency / Region: Earth Restrictions** — you can constrain processing/storage to EU or US-only regions on Enterprise plans.

For a typical app: pick a primary region for D1 and your backend (the region you'd pick if you were AWS-only), and let Workers + replicas serve reads globally.

For HIPAA / GDPR data-residency mandates: read the [Cloudflare data localization](https://developers.cloudflare.com/data-localization/) docs; relevant Enterprise SKUs constrain processing.

### Cloudflare for SaaS (custom hostnames)

If you sell a SaaS where customers point their own domain at you:

- **Cloudflare for SaaS** is the product — you charge customers, they CNAME their hostname to yours, Cloudflare handles their certs and routes traffic to your Workers.
- Custom hostnames are first-class; you don't need a zone per customer.
- The Cloudflare API gives you per-hostname configuration (certs, custom rules) and per-hostname analytics.

This composes with `saas-architect`. Cloudflare for SaaS is the **platform mechanism**; the SaaS architecture (per-tenant data isolation, billing, etc.) is `saas-architect`'s territory.

## Critical 2025-2026 platform reset for system-architects

What changed since your last Cloudflare-shaped architecture:

### Workflows is now a first-class primitive

Pre-2025, the multi-step orchestration story on Cloudflare was "Queues + Durable Objects + cron, build the state machine yourself." Workflows replaces that. **For any new long-running orchestration, your default should be Workflows.** Queues are for fan-out/decoupling, DOs are for per-entity serialized state.

Implications:
- Old architecture diagrams with "DO state machine" boxes should be re-evaluated.
- "Saga" pattern across services is a Workflow in 99% of cases now.
- Step-level retries, conditional branches, sleeps without burning compute — Workflows give you these as primitives.

### D1 is genuinely usable for relational apps now

D1 GA'd in 2024, added global read replication and Sessions API in 2025. Per-database size limits have grown. Index/query plan tooling exists. **Default to D1 for new relational apps under medium scale.** Reach for external Postgres only when you have a specific reason: extensions, very-large dataset, custom replication topology, existing Postgres skills/tooling investment.

### Containers on Workers changes "what's runnable on Cloudflare"

Until containers shipped (beta through 2025), "Cloudflare can run X" meant "X compiles to JS or Wasm or runs in V8." Now it means "X can be containerized." The architectural envelope is bigger: Python data jobs, FFmpeg, Pandoc, custom binaries, all viable on Workers when they wouldn't have been.

Use case: a Worker handles the request, kicks off a container for heavy work, the container writes back to R2/D1, the Worker polls or gets notified.

This doesn't mean replace all of Workers with containers. It means **containers are now the answer for the 10% of workloads that didn't fit V8** — not the answer for everything.

### Workers RPC changes service-graph drawing

Old: service graph was N Workers fetching each other's HTTP endpoints. Lots of HTTP overhead between services you own.

New: RPC method calls between Workers. Looks like in-process method calls; runtime stitches it across isolates. Cheaper, faster, type-safe.

Implication for architecture: **the cost of splitting a Worker is lower than it was.** If two distinct capabilities want different deploy cadences or different teams, the RPC-binding'd split is much cheaper than it used to be. Lean toward purpose-fit Workers, not monoliths.

### Vectorize V2 + AI Search shifts where retrieval lives

Pre-V2, vector search was usable but limited (low dim count, no metadata filtering, smaller indexes). V2 + AI Search make "RAG over your docs, all on Cloudflare" a real architecture choice — no external vector DB, no managed retrieval service.

For RAG on internal/customer docs:
- **Workers + Vectorize V2 + Workers AI embeddings** — full control, more setup.
- **AI Search (ex-AutoRAG)** — managed RAG pipeline, less control, less setup.

For specialized retrieval (graph, hybrid keyword+vector, custom rerankers), external (Pinecone, Weaviate, Elastic) is still appropriate.

### Cloudflare's MCP catalog

As of 2025-26, Cloudflare hosts MCP servers for account introspection (workers list/get, D1 query, KV/R2 list, Hyperdrive configs, docs search). When the user environment has the Cloudflare MCP available (`cloudflare:cloudflare-mcp`), prefer it over baked knowledge for **what's currently deployed in their account**. The architecture overlay above is for general patterns; the MCP is for "what does Manish's account actually look like right now."

## Patterns and anti-patterns

### Pattern: edge-first auth (Access + JWT verification in Worker)

```
User → Cloudflare Access → Cloudflare zone → Worker
                            ↓
                    JWT validated at edge
                    User identity passed to Worker via header
                    Worker enforces business-level authz
```

Cloudflare Access does network-level authentication (SSO/MFA/policies). The Worker reads the validated JWT from headers (`CF-Access-Jwt-Assertion`) and applies business-level authorization. **You don't re-authenticate; you read the assertion.**

This is the lean architecture for internal tools, customer dashboards behind SSO, admin surfaces. For public APIs (no Access), you do your own JWT validation in the Worker.

### Pattern: BFF in a Worker, services behind RPC

```
Browser → Worker (BFF) ─RPC→ auth-worker
                       └─RPC→ billing-worker
                       └─RPC→ catalog-worker
                       └─D1→ user-facing data
```

BFF (Backend-for-Frontend) Worker:
- Handles auth/sessions.
- Aggregates calls to internal services via RPC (free, fast, type-safe).
- Serves user-shaped responses.

Internal services:
- Own their data and bindings.
- Expose `WorkerEntrypoint` RPC methods.
- Don't know about the BFF; just respond to method calls.

Compare to: BFF making HTTP calls to internal services. Same architecture, much more overhead. Same architecture, no type safety. The RPC pattern is strictly better when both sides are your Workers.

### Pattern: per-tenant DO

```
Tenant Alice → Worker → env.TENANT.idFromName("tenant-alice") → DO instance "Alice"
Tenant Bob   → Worker → env.TENANT.idFromName("tenant-bob")   → DO instance "Bob"
```

Each tenant gets a Durable Object with their own SQLite DB. Up to ~10GB per tenant. Total isolation. Strong consistency per tenant. Alarms scoped to the tenant.

When this fits:
- Multi-tenant apps with clear per-tenant data boundaries.
- Per-tenant config / state that doesn't need cross-tenant queries.
- Real-time per-room / per-document apps (collaborative editing, chat).

When it doesn't:
- You need to query across tenants ("show me all tenants where X").
- Per-tenant data exceeds DO limits.
- A single tenant has hot enough write traffic to bottleneck on the DO instance.

For mixed needs: per-tenant DO for hot state, D1 for cross-tenant queries (materialized via Queues from DO events).

### Pattern: Cloudflare-fronting-AWS

```
Browser → Cloudflare WAF → Worker (auth, cache, transform) → AWS API Gateway / ALB → ECS/Lambda
                                          ↓
                                  Hyperdrive → RDS Postgres
```

Cloudflare handles: TLS, WAF, rate limiting, Bot Management, Access for protected routes, caching, edge transforms (rewrites, geolocation, A/B), AI Gateway for model calls.

AWS handles: the actual application backend, RDS, S3, etc.

When this is the right move:
- Existing significant AWS investment, can't replatform.
- Application requires AWS services (SageMaker, specific RDS extensions, Aurora features).
- Compliance pinned to AWS regions.

The Worker tier is where Cloudflare earns its keep — WAF, Bot Management, caching, auth, Turnstile — even when the app itself runs in AWS.

### Pattern: Pipelines → R2 → R2 SQL

```
Devices → POST /events → Pipelines binding → R2 (Parquet)
                                              ↓
                                       R2 SQL queries
                                              ↓
                                  Dashboards / analytics
```

Pipelines is the data-ingest primitive: HTTP in, buffered and batched, written to R2 in Parquet/JSON. R2 SQL lets you query the resulting data. **This is the Cloudflare-native "fire-hose into analytics" path** — competes with Kinesis + S3 + Athena on AWS.

When this fits: high-volume events you want to retain for offline analytics + occasional ad-hoc queries.

When it doesn't: low-latency operational queries (use Analytics Engine instead) or transactional data (use D1).

### Anti-pattern: spreading state across primitives without ownership

```
User profile in KV
User sessions in DO
User preferences in D1
User uploads in R2
User events in Analytics Engine
```

This isn't wrong, but if there's no clear ownership ("which primitive owns the user?") you'll end up with consistency bugs. Pick a primary store per entity. Cache/project to other primitives if needed; treat them as derived.

### Anti-pattern: trying to replicate AWS-style "region picker" UX

Cloudflare doesn't have a region picker for Workers. You can pin D1 / DO / R2 / Hyperdrive endpoints to regions, but you don't pick where your Workers run — they run everywhere. If your team is asking "what region should this Worker be in?" — they're working from an AWS mental model. The answer is "all of them, but the data is in region X, so think about reads vs writes."

### Anti-pattern: assuming "edge" means "fast"

Edge is fast for **cached** responses and **stateless** transforms. Edge is **not faster** for requests that ultimately hit a backend in us-east-1 — in fact, default placement makes them slower than running compute in us-east-1 directly. Smart Placement fixes this for backend-bound Workers, but you have to think about it.

### Anti-pattern: putting transactional data in KV "because it's fast"

KV is read-heavy, eventually consistent. Writes are slow (~1/sec/key). Reads can be stale up to ~60s globally. Cardholder data, in-flight payment state, account-level capability flags — all wrong fits for KV.

### Anti-pattern: one giant Worker that does everything

The "monolith Worker" pattern (one Worker, 50 routes, 5000 lines, multiple teams) doesn't scale operationally:
- Every deploy carries every team's risk.
- Bundle size grows to limits.
- CPU budget per request becomes contentious.
- Logs are noisy across responsibilities.

Split by **bounded context** (auth, billing, catalog, ai), linked by RPC bindings. Per-team or per-domain Workers.

## Tooling specifics — for architects

You'll spend less time in Wrangler than backend/devops will. What you do touch:

- **Cloudflare dashboard** for current state of an account (zones, Workers, D1 databases, KV namespaces, R2 buckets, Vectorize indexes, Access policies, WAF rules). Use this to draw the existing architecture before proposing changes.
- **`cloudflare:cloudflare-mcp` plugin** when present — gives an architect's read view of an account from inside the agent. Faster than dashboard browsing.
- **Cloudflare Radar** for traffic patterns, threat trends, geographic distribution.
- **Cloudflare blog + changelog** for product launches; subscribe.
- **Terraform/Pulumi state** as architecture-as-code; review the IaC, not just the dashboard.
- **`wrangler.toml`** files across the repo as the bindings inventory.

For diagrams: Mermaid is fine. The bindings list maps cleanly to architecture diagrams:

```
[Worker: api]
  ├── D1: orders-prod
  ├── KV: sessions
  ├── R2: receipts
  ├── DO: Order (per-order state)
  ├── Queue: fulfillment (producer)
  ├── Service: auth-worker (RPC)
  ├── AI: Workers AI
  ├── Hyperdrive: analytics-pg

[Worker: fulfillment-consumer]
  ├── Queue: fulfillment (consumer)
  ├── D1: orders-prod
  ├── Workflow: ShipOrder

[Worker: auth-worker]
  ├── KV: sessions
  ├── D1: users-prod
```

## Cross-references to products_covered

- **Workers Runtime** → "Workers vs Containers vs External compute" + "Single Worker vs many"; runtime details in `backend-architect.md`.
- **Durable Objects** → "Per-tenant DO" pattern; runtime details in `backend-architect.md`.
- **D1 / Hyperdrive / external DBs** → "D1 vs Hyperdrive vs external Postgres/MySQL"; depth in `database-architect.md`.
- **Workflows / Queues / Cron / DO alarms** → "Queues vs Workflows vs DO alarms"; runtime details in `backend-architect.md`.
- **Workers for Platforms** → "Workers for Platforms vs Many Workers".
- **Smart Placement** → "Smart Placement: on or off?".
- **Cloudflare for SaaS** → "Cloudflare for SaaS (custom hostnames)".
- **Realtime, Stream, Images, Browser Rendering** → composition examples below.
- **Edge security (Access, Tunnel, WAF, Turnstile)** → depth in `security-engineer.md`; architecture composition examples here.

## Composition patterns — common end-to-end architectures

### "Web app + API + AI assistant"

```
[Browser]
   ↓
[Cloudflare zone with WAF + DDoS]
   ↓
[Worker: web]            (Workers Static Assets serving the SPA)
   ↓ [RPC binding]
[Worker: api]            (BFF + business logic)
   ├── D1                (catalog, users, orders)
   ├── KV                (sessions)
   ├── R2                (user uploads, receipts)
   ├── Queue             (background tasks)
   ├── Workflow          (multi-step processes)
   ├── Service: auth     (RPC to auth Worker)
   └── AI Gateway        (LLM calls, cached)
        ↓
   [Workers AI] / [OpenAI] / [Anthropic]
        ↓
   [Vectorize index for RAG over docs]
```

### "Real-time collaboration"

```
[Browsers]
   ↓ (WebSocket upgrade)
[Worker: room-router]    (looks up room ID, forwards to DO)
   ↓ (DO binding)
[DO: Room]                (per-room SQLite + Hibernation API for many connections)
   ├── sql               (messages, presence, document state)
   ├── alarms            (timeouts, scheduled events)
   └── Queue             (persist to D1 for history)
        ↓
   [D1: rooms-prod]      (audit trail, search)
```

### "Multi-tenant SaaS with custom hostnames"

```
[Customer browsers] → CNAME tenant.example.com → Cloudflare for SaaS
                            ↓
[Cloudflare zone, custom hostname]  (Cloudflare-managed TLS)
                            ↓
[Worker: router]            (extracts tenant from hostname or header)
                            ↓ (DO binding)
[DO: Tenant<tenantId>]      (per-tenant SQLite)
                            ↓
[D1: cross-tenant queries]  (admin, billing, analytics)
[R2: tenant uploads]        (prefixed by tenant ID)
```

### "AI Search-backed RAG chatbot"

```
[Browser]
   ↓
[Worker: chat]
   ├── AI Gateway → Workers AI / Anthropic (LLM)
   ├── AI Search (managed RAG over R2 docs)
   │       ↓
   │  [R2: docs bucket] + [Vectorize: docs-index] + [Workers AI: embeddings]
   ├── DO: conversation history
   └── D1: chat metadata
```

### "Cloudflare-fronting-AWS for existing app"

```
[Browser]
   ↓
[Cloudflare zone with WAF + Bot Management + Turnstile + Access for /admin]
   ↓
[Worker: edge]              (cache, transform, rate-limit, A/B, geolocation)
   ↓ (fetch over HTTPS or Tunnel)
[AWS ALB → ECS/Lambda]
   ↓
[RDS Postgres / DynamoDB / S3]
```

### "Webhook ingester with Workflow per webhook"

```
[Webhook source: Stripe / GitHub / Linear]
   ↓ (POST)
[Worker: webhook-receiver]
   ├── Verify signature
   ├── Enqueue → Workflow
   └── Return 200 immediately
        ↓
[Workflow: ProcessWebhook]
   ├── step.do: load context
   ├── step.do: apply business rules (with retries)
   ├── step.sleep: wait for related event (idempotent)
   └── step.do: write final state to D1
```

### "Realtime audio/video"

```
[Browser/App]
   ↓ (WebRTC: TURN + signaling)
[Cloudflare Realtime: TURN + SFU]
   ↓ (signaling over WS via DO)
[DO: SignalRoom]
   ↓ (calls Realtime API)
[Realtime API for SFU operations]
```

### "Inbound email automation"

```
[Inbound email to support@example.com]
   ↓
[Cloudflare Email Routing]
   ↓
[Email Worker]
   ├── Parse + classify (Workers AI)
   ├── Forward to human if high-priority (Email Routing forward)
   └── Auto-respond + ticket via Queue → CRM API
```

## Integration with always-on protocols

### Brainstorm-first for Cloudflare architectures

Cloudflare has unusual primitives. Before settling on a design, force the brainstorm step:

- "What if this DO became a Workflow?" (Often a better fit.)
- "What if we serve from cache instead of from Worker?" (Often free.)
- "What if Smart Placement makes this trivially faster?" (Often yes.)
- "What if we put the AI call through AI Gateway?" (Always yes.)
- "What if we move the heavy compute to a Container?" (When V8 doesn't fit.)
- "What if RPC replaces this HTTP call?" (When both sides are our Workers.)

Don't lock in the AWS-shaped diagram and translate it. Re-derive on the platform's primitives.

### Verification for system-architect on Cloudflare

Before declaring an architecture decision finalized:

- [ ] State placement is explicit per data entity (which primitive owns it).
- [ ] Bindings list is drawn (per Worker — what it depends on).
- [ ] Cross-Worker calls are explicitly RPC, service binding, or HTTP — and the rationale for each.
- [ ] CPU and subrequest budgets are sketched for the hot path.
- [ ] Workflow boundaries are drawn for any multi-step async process.
- [ ] Failure modes are listed (DO overloaded → ?; D1 region down → ?; AI Gateway failover policy?).
- [ ] Data residency requirements are met (Region: Earth + appropriate restrictions).
- [ ] Rollback strategy is in the design (Versions, traffic splits).
- [ ] Compliance composition is named (which vertical informs which slice).
- [ ] Cost model is sketched at expected scale (Workers, D1, R2 egress, AI inference, Vectorize, AI Gateway).

### Debugging architecture decisions

When a Cloudflare-based system underperforms or misbehaves:

1. **Identify the failing primitive.** Is it the Worker (CPU/subrequest)? D1 (query plan)? DO (hot key)? AI inference (cost/latency)?
2. **Reproduce in isolation.** Workers Logs + Analytics Engine should make this fast if you wired observability up front.
3. **Check the bindings graph.** Are there free RPC alternatives to HTTP calls you're making? Is Smart Placement on?
4. **Right-size the primitive.** Hot DO → shard. KV-as-counter → DO or Rate Limit. Wrong-tier DB → migrate.
5. **Document the lesson in the architecture doc.** Don't lose the why-we-changed.

### Escalation paths

- **Worker implementation patterns** → `backend-architect` overlay.
- **CI/CD, multi-env, observability glue** → `devops-engineer` overlay.
- **Schema design, indexes, migrations, Hyperdrive sizing** → `database-architect` overlay.
- **Model selection, RAG, AI Gateway tuning** → `ai-ml-engineer` overlay.
- **WAF, Access, Tunnel, mTLS, edge auth** → `security-engineer` overlay.
- **Vertical-specific patterns** → vertical specialist (saas-architect, real-time-architect, fintech-architect, e-commerce-architect, healthcare-architect) — Cloudflare overlay provides the platform composition; vertical owns the domain.

## ADR templates for Cloudflare decisions

Common architecture decisions deserve named ADRs. Templates:

### ADR: "Store-of-record for entity X"

- **Context:** What is entity X (user, order, message, document). Access pattern (read-heavy, write-heavy, strong consistency required).
- **Options considered:** D1, DO SQLite, KV, R2, Hyperdrive'd external DB, external DB.
- **Decision:** Which one and why.
- **Consequences:** Read latency profile, write throughput limits, cross-entity query capability, migration cost.

### ADR: "Inter-Worker communication for capability Y"

- **Context:** Which Workers, which calling direction, frequency, payload shape.
- **Options:** RPC (service binding), HTTP `fetch()`, Queue.
- **Decision:** RPC unless [reason].
- **Consequences:** Type safety, latency, observability, error handling.

### ADR: "Async work pattern for flow Z"

- **Context:** What flow, how long, dependencies, retry tolerance.
- **Options:** `ctx.waitUntil` (in-request), Queues (decoupled), Workflows (durable multi-step), DO alarms (per-entity scheduled), cron.
- **Decision:** Which primitive.
- **Consequences:** Latency, durability, retry semantics, cost.

### ADR: "Edge vs origin placement"

- **Context:** Where does compute happen — Worker, container, external.
- **Options:** Default Workers placement (everywhere), Smart Placement (near backend), Containers on Workers, external compute.
- **Decision:** Which placement.
- **Consequences:** End-to-end latency, cost, runtime constraints.

### ADR: "Multi-tenancy approach"

- **Context:** Who are the tenants, what's the isolation requirement.
- **Options:** Single Worker tenant-aware data, per-tenant DO, per-tenant zone (subdomain), Workers for Platforms (per-tenant Worker).
- **Decision:** Which model.
- **Consequences:** Blast radius, operational complexity, cost, per-tenant customization capability.

### ADR: "Data residency / Region: Earth restriction"

- **Context:** Which data, which jurisdictions, which compliance regime.
- **Options:** Cloudflare default global, Cloudflare regional restrictions (EU-only, US-only, FedRAMP), separate accounts per region.
- **Decision:** Which.
- **Consequences:** Compliance posture, latency impact, customer trust.

ETYB should produce ADRs as part of architecture work, not as an afterthought. The reasoning is the deliverable — the diagram is just a summary.

## Standing rules for system-architect on a Cloudflare engagement

1. **Design from Cloudflare's primitives, not from an AWS-translation.** RPC over HTTP, Workflows over DIY orchestration, D1 with Sessions over external Postgres for new apps.
2. **Bindings list is the architecture diagram.** Make it visible; review it like a UML diagram.
3. **State has an owner.** Each entity lives in exactly one primary primitive; everything else is derived.
4. **Compute fits the budget.** CPU, subrequest, wall-clock — match the workload to the right primitive (Worker, Workflow, Container).
5. **Edge security is part of the architecture, not a checklist.** WAF, Access, Tunnel, Turnstile, AI Gateway are tiers — name them in the diagram.
6. **Workers for Platforms is the only sensible pattern for running customer code.** Don't recommend a single-Worker tenant-switch approach for customer-authored logic.
7. **Smart Placement is on by default for backend-bound Workers.**
8. **Pages is in maintenance.** New static-asset projects use Workers Static Assets.
9. **AI calls go through AI Gateway** — caching, fallback, eval, BYOK. Don't bypass.
10. **Verify currency before committing.** Cloudflare's catalog moves weekly; what was the right primitive 6 months ago may have a better successor today.
