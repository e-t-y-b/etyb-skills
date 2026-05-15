# Stack Registry — Tech Stack Detection

This is the routing layer for **Stack Packs** — knowledge overlays that load when work involves a specific tech stack (Salesforce, AWS, Cloudflare, Vercel, etc.). Read this after `team-registry.md` whenever you're routing a request.

Stack Packs are not new specialists. They are context overlays applied across the existing 20 internal references. See `STACKS.md` at the repo root for the public registry of available stacks; see `core/knowledge-currency.md` for the drift-check protocol that governs how Stack knowledge gets used.

## v4 architecture — local detection, remote knowledge

The shape changed in v4.0.0. **The install no longer carries vendor content.** Each `stacks/<vendor>/SKILL.md` is a slim pointer (~125-200 lines) holding:

- Frontmatter trigger description + keyword list (Claude / Codex / Antigravity load this for detection)
- `applies_to_roles`, `delegate_to_skills`, `products_covered` (routing + delegation metadata)
- Top 5-10 platform gotchas (so the team has the highest-LLM-value currency anchors at hand without a fetch)
- A standing-instructions block + escalation map

The depth — per-product canonical pages and per-role composed views — lives at **[docs.etyb.ai/stacks/<vendor>/](https://docs.etyb.ai/stacks/)**, each page currency-stamped with its own `last_verified_on`, `drift_risk`, and `authoritative_url`. ETYB fetches these at runtime when work needs depth that the slim pointer doesn't carry.

## Detection workflow

1. **After classifying the request tier** (per `charter.md`) and identifying which specialist(s) to route to (per `team-registry.md`), scan the user's request for stack signals using the tables below.

2. **On a match,** the slim local `stacks/<vendor>/SKILL.md` is already loaded (its frontmatter description matched). It carries the team briefing + top gotchas — that's enough for many soft-path responses without a fetch.

3. **Check `delegate_to_skills`** in the local Stack's frontmatter. If a listed vendor skill or MCP is available in the user's environment (visible in `<available_skills>`), prefer it for the matching product. The vendor's own surface knows current state better than the curated docs.

4. **For depth beyond the slim briefing, WebFetch the most-specific docs.etyb.ai URL** that matches the work:
   - Product-specific question → `https://docs.etyb.ai/stacks/<vendor>/<product>/`
   - Role-shaped question → `https://docs.etyb.ai/stacks/<vendor>/<role>/` (composed view that stitches the products that role touches)
   - Stack-wide overview → `https://docs.etyb.ai/stacks/<vendor>/` (index)

   If the most-specific URL 404s, fall back to the next-broadest. Don't load the entire Stack unless the user really needs the breadth.

5. **Apply the drift-check protocol** (per `core/knowledge-currency.md`) using the fetched page's frontmatter (`last_verified_on`, `drift_risk`, `authoritative_url`). High-stakes claims and stale high-drift products must either defer to a delegate or WebFetch the page's `authoritative_url` directly.

6. **Multiple stacks may match.** Their slim briefings load in parallel; fetch from each Stack's docs.etyb.ai surface independently. They compose — each pack handles its own platform-side, neither pretends to know the other.

7. **If the docs.etyb.ai page is unreachable** (network failure, 404 on the entire Stack tree), tell the user explicitly, proceed with the slim briefing's gotchas + the specialist's general knowledge, and mark the answer as cache-only. Don't fabricate depth.

## Composition with protocols and verticals

Stack Packs do **not** relax the 9 always-on protocols. TDD, verification, debugging, review, plan execution, brainstorm-first, branch safety, subagent coordination, self-improvement — all apply unchanged. Stack Packs shape *how* the protocols are applied on a specific platform (e.g., TDD on Apex uses Apex test classes; TDD on LWC uses Jest; TDD on Cloudflare Workers uses Miniflare).

Stack Packs **defer to business-domain verticals** for compliance and domain expertise. When Salesforce Health Cloud work appears, the Salesforce pack covers the platform surface; `healthcare-architect` covers HIPAA, FHIR, audit-trail discipline. Don't restate domain compliance from a Stack Pack.

## Vendor-skill delegation — how it works

Several Stacks declare `delegate_to_skills` entries that point at vendor-provided skills or MCP servers. When those are installed in the user's environment, ETYB defers rather than fetching from docs.etyb.ai or answering from the slim briefing. Detection is done by inspecting the `<available_skills>` list:

| Stack | Delegate candidates (when installed) |
|-------|--------------------------------------|
| Cloudflare | `cloudflare:*` MCP tools (d1, hyperdrive, kv, r2, workers, etc.) |
| Vercel | `vercel:*` skill suite (nextjs, ai-sdk, chat-sdk, ai-gateway, vercel-cli, etc.) |
| Supabase | `supabase:supabase`, `supabase:supabase-postgres-best-practices`, Supabase MCP |
| Firebase | `firebase:*` skill suite (auth, hosting, firestore, app-hosting, genkit-*) |
| Anthropic Claude | `claude-api`, Anthropic SDK tooling |
| Expo / React Native | `expo-*` skill suite, `vercel-react-native-skills`, `building-native-ui` |
| Salesforce | (no first-party MCP GA yet; check delegate_to_skills periodically) |
| AWS / GCP / Azure | (no first-party MCPs yet; built-in cloud CLIs covered in the Stack) |
| Stripe | Stripe MCP (when installed) |

This list is informational. The authoritative declaration of which delegates a Stack prefers lives in that Stack's local slim `SKILL.md` frontmatter `delegate_to_skills:` block.

## Active Stack Packs

### Salesforce (`stacks/salesforce/`)

**Slim local pointer:** [`stacks/salesforce/SKILL.md`](../../../stacks/salesforce/SKILL.md)
**Canonical docs:** <https://docs.etyb.ai/stacks/salesforce/>
**Version:** 4.0.0 • **Last verified release:** Spring '26 • **Last verified on:** 2026-05-12
**Delegate skills:** none yet (Salesforce-Hosted MCP Servers GA'd April 2026; add when an MCP surface ships in users' environments)
**Roles overlaid:** system-architect, backend-architect, frontend-architect, ai-ml-engineer, database-architect, devops-engineer, security-engineer, qa-engineer, saas-architect, healthcare-architect, fintech-architect

**Detection signals** (case-insensitive; match anywhere in user's message):

| Signal type | Keywords / patterns |
|-------------|---------------------|
| Product names | salesforce, sfdc, sales cloud, service cloud, marketing cloud, commerce cloud, experience cloud, health cloud, financial services cloud, fsc, manufacturing cloud, public sector solutions, data 360, data cloud, tableau (when adjacent to Salesforce/Data 360 context), slack (when adjacent to Salesforce context) |
| Platform features | agentforce, einstein, atlas reasoning, trust layer, einstein trust layer, model gateway, prompt builder, agent script, agentforce vibes, agentforce builder, hyperforce |
| Development surfaces | apex, lwc, lightning web component, lightning, visualforce, aura, flow builder, flow orchestration, omnistudio, omniscript, integration procedure, data mapper, dataraptor |
| Data layer | soql, sosl, sobject, custom object, picklist, lookup, master-detail, big object, salesforce connect, external object, zero copy |
| Integration | pub/sub api, platform event, change data capture, cdc, named credential, external credential, external client app, eca, connected app, mulesoft, anypoint |
| Tooling | sf cli, sfdx, salesforce cli, scratch org, sandbox, unlocked package, 2gp, managed package, devops center, copado, gearset, autorabit, code analyzer, apex guru, apexguru, lwc jest, salesforce code analyzer |
| Compute (legacy) | heroku (when adjacent to Salesforce context), salesforce functions |
| Ecosystem | appexchange, agentexchange, trailhead, trailblazer, dreamforce, tdx, trailblazerdx |
| Roles / certs | salesforce admin, salesforce architect, ctas, certified technical architect, agentforce specialist, platform developer (when adjacent to Salesforce) |

**Negative signals** — DO NOT activate the pack when these dominate without Salesforce context:
- "Salesforce" used as a generic synonym for "CRM" without specific platform mention
- Generic "lightning" references not about Salesforce (Bitcoin Lightning Network, Lightning McQueen, etc.)
- Generic "flow" without "builder" / "orchestration" / Salesforce neighborhood
- "Apex" used in non-Salesforce context (Apex Legends, Apex programming language references in academic context)
- Pure Slack / Tableau questions with no Salesforce platform involvement

When the signal is ambiguous, **ask** before fetching — fetching docs.etyb.ai/stacks/salesforce/ on a non-Salesforce request injects Salesforce-specific guidance that distorts your response.

### AWS (`stacks/aws/`)

**Slim local pointer:** `stacks/aws/SKILL.md` • **Canonical docs:** <https://docs.etyb.ai/stacks/aws/>
**Version:** 4.0.0 • **Last verified on:** 2026-05-14
**Delegates:** none yet (no first-party AWS MCP GA; revisit when Amazon Q Developer / AWS-hosted MCPs ship installable surfaces)
**Roles overlaid:** system-architect, backend-architect, database-architect, devops-engineer, security-engineer, sre-engineer, ai-ml-engineer, saas-architect, fintech-architect

**Detection signals:**
- AWS naming: aws, amazon web services, amazon (in cloud context)
- Compute: ec2, ecs, eks, fargate, lambda, lambda@edge, graviton, app runner, batch, lightsail, beanstalk, cloud9
- Storage/data: s3, ebs, efs, fsx, glacier, rds, aurora, aurora dsql, dynamodb, elasticache (when AWS-context), redshift, athena, glue, lake formation, opensearch
- AI/ML: bedrock, agentcore, strands agents, sagemaker, comprehend, rekognition, polly, transcribe, textract, trainium, inferentia
- Networking: vpc, route53, cloudfront, api gateway, app sync, transit gateway, vpc lattice, privatelink, direct connect, global accelerator
- Security/IAM: iam, sts, scp, permission boundary, kms, secrets manager, certificate manager, guardduty, security hub, cognito, waf (when AWS-context), shield
- IaC/CI/CD: cdk, cloudformation, sam, codebuild, codepipeline, codedeploy, copilot cli (AWS), eb cli
- Observability: cloudwatch, x-ray, cloudtrail, application signals, fis (fault injection)
- Misc: well-architected, control tower, organizations, sso (when AWS-context), karpenter (when AWS-context)

**Negative signals:** generic "aws" in non-cloud context, "amazon" without cloud verbs/products, Amazon retail/Prime references.

### GCP (`stacks/gcp/`)

**Slim local pointer:** `stacks/gcp/SKILL.md` • **Canonical docs:** <https://docs.etyb.ai/stacks/gcp/>
**Version:** 4.0.0 • **Last verified on:** 2026-05-14
**Delegates:** none yet (revisit when GCP MCP server installable surface ships)
**Roles overlaid:** system-architect, backend-architect, database-architect, devops-engineer, security-engineer, sre-engineer, ai-ml-engineer, saas-architect

**Detection signals:**
- GCP naming: gcp, google cloud, google cloud platform
- Compute: gke, gke autopilot, cloud run, cloud functions, cloud run functions, app engine, compute engine, gce, anthos
- Storage/data: cloud sql, alloydb, alloydb ai, spanner, firestore (when GCP-context, not Firebase), bigtable, memorystore, bigquery, bigquery ml, looker, looker studio, dataflow, dataproc, dataform, biglake, cloud storage
- AI/ML: vertex ai, gemini (when GCP-context, not consumer), gemini code assist, agent builder (vertex), agentspace, imagen, veo, model garden, tpu, ironwood
- Networking: vpc-sc, cloud load balancing, cloud cdn, cloud armor, cloud dns, network connectivity center
- Security/IAM: workload identity federation, wif (when GCP), cloud iam, cloud kms, secret manager (when GCP-context), security command center, scc
- IaC: terraform google provider, config connector, infrastructure manager, deployment manager (deprecated)
- Observability: cloud monitoring, cloud logging, cloud trace, cloud profiler, ops agent, managed prometheus, managed otel
- Tooling: gcloud cli, gsutil, bq cli

**Negative signals:** generic "google" without cloud verbs, "google search", Google Workspace references.

### Azure (`stacks/azure/`)

**Slim local pointer:** `stacks/azure/SKILL.md` • **Canonical docs:** <https://docs.etyb.ai/stacks/azure/>
**Version:** 4.0.0 • **Last verified on:** 2026-05-14
**Delegates:** none yet
**Roles overlaid:** system-architect, backend-architect, database-architect, devops-engineer, security-engineer, sre-engineer, ai-ml-engineer, saas-architect, healthcare-architect

**Detection signals:**
- Azure naming: azure, microsoft azure
- Compute: aks, container apps, container instances, azure functions, app service, app service environment, static web apps, virtual machines (when Azure-context)
- Storage/data: cosmos db, cosmos diskann, azure sql, azure sql hyperscale, postgresql flexible server (azure), azure managed redis, azure cache for redis, blob storage, files (azure), queues (azure), tables (azure)
- AI/ML: ai foundry, foundry agents, azure openai, ai search (azure), cognitive search (legacy), azure ml, copilot studio, microsoft fabric, synapse analytics, entra agent id, maia 100
- Networking: front door, application gateway, vwan, private link, azure firewall
- Security/IAM: entra id, entra external id, azure ad (legacy → entra), azure ad b2c (legacy → entra external id), pim, managed identity, workload identity federation (azure), key vault, managed hsm, defender for cloud, sentinel, microsoft purview, azure policy
- IaC/CI/CD: bicep, avm, deployment stacks, azure verified modules, terraform azurerm, azd, azure developer cli, azure devops, github actions on azure
- Observability: azure monitor, log analytics, application insights, managed grafana (azure)
- Misc: azure arc, azure local, azure vmware solution

**Negative signals:** generic "microsoft" without Azure context, M365 / Office references.

### Anthropic Claude (`stacks/anthropic-claude/`)

**Slim local pointer:** `stacks/anthropic-claude/SKILL.md` • **Canonical docs:** <https://docs.etyb.ai/stacks/anthropic-claude/>
**Version:** 4.0.0 • **Last verified on:** 2026-05-14
**Delegates:** `claude-api` (Anthropic SDK / API helper skill)
**Roles overlaid:** backend-architect, ai-ml-engineer, system-architect, security-engineer

**Detection signals:**
- Vendor: anthropic, claude
- Products: claude api, messages api (when anthropic-context), claude code, claude agent sdk, claude opus, claude sonnet, claude haiku, anthropic sdk
- Features: prompt caching, tool use (anthropic-context), extended thinking, interleaved thinking, computer use (anthropic-context), claude memory, citations api
- Ecosystem: mcp, model context protocol, mcp servers, anthropic console, workbench (anthropic), claude code skills, claude code hooks

**Negative signals:** "claude" used as a personal name in non-AI context; references to consumer Claude.ai chat (the consumer product is informed by but distinct from this Stack — this Stack covers the developer surface).

### OpenAI (`stacks/openai/`)

**Slim local pointer:** `stacks/openai/SKILL.md` • **Canonical docs:** <https://docs.etyb.ai/stacks/openai/>
**Version:** 4.0.0 • **Last verified on:** 2026-05-14
**Delegates:** none yet (OpenAI ecosystem is API-first; revisit if OpenAI ships an official MCP)
**Roles overlaid:** ai-ml-engineer, backend-architect, system-architect, security-engineer

**Detection signals:**
- Vendor: openai, gpt
- Models: gpt-5, gpt-4.1, gpt-4o, o3, o4 (when openai-context), gpt-image-1, dall-e, whisper, tts (when openai-context)
- APIs: responses api (openai), assistants api (legacy), chat completions, realtime api (openai), batch api (openai), embeddings (text-embedding-3-large/small), moderation api, files api
- Features: structured outputs (openai-context), function calling (openai-context), computer use (openai operator), agents sdk (openai, formerly swarm), realtime agents, codex (openai 2025 agent)
- Tooling: openai-python, openai-node, openai cli, openai platform

**Negative signals:** "gpt" used in unrelated contexts (e.g., disk partitions: "gpt partition"); references to non-OpenAI GPT-style models.

### Cloudflare (`stacks/cloudflare/`)

**Slim local pointer:** `stacks/cloudflare/SKILL.md` • **Canonical docs:** <https://docs.etyb.ai/stacks/cloudflare/>
**Version:** 4.0.0 • **Last verified on:** 2026-05-14
**Delegates:** `cloudflare:cloudflare-mcp` (Cloudflare MCP — covers Workers, D1, R2, KV, Hyperdrive, Pages, accounts)
**Roles overlaid:** backend-architect, system-architect, devops-engineer, ai-ml-engineer, database-architect, security-engineer

**Detection signals:**
- Vendor: cloudflare
- Compute: workers, cloudflare workers, durable objects, workers for platforms
- Tooling: wrangler, miniflare, `wrangler deploy`, compatibility-date
- Storage/data: d1, r2, kv (when cloudflare-context), hyperdrive, vectorize
- Networking: cloudflare tunnel, cloudflare access, zero trust (cloudflare-context), magic transit, magic wan, argo, cloudflare cdn, page rules (legacy)
- Security: cloudflare waf, rate limiting (cloudflare), cloudflare ddos, turnstile, cloudflare casb
- AI: workers ai, ai gateway (cloudflare), ai search (formerly autorag), browser rendering
- Media/comms: stream (cloudflare), images (cloudflare), realtime (cloudflare turn/sfu), email routing, email workers
- Other: pages (cloudflare → migrating to workers static assets), workflows (cloudflare durable execution), queues (cloudflare), cron triggers (cloudflare)

**Negative signals:** generic "edge" without cloudflare context; "workers" in non-CF context (Web Workers in browser, K8s workers).

### Vercel (`stacks/vercel/`)

**Slim local pointer:** `stacks/vercel/SKILL.md` • **Canonical docs:** <https://docs.etyb.ai/stacks/vercel/>
**Version:** 4.0.0 • **Last verified on:** 2026-05-14
**Delegates:** heavy — see `stacks/vercel/SKILL.md` frontmatter for the 18 vercel:* delegates
**Roles overlaid:** frontend-architect, backend-architect, devops-engineer, ai-ml-engineer, system-architect

**Detection signals:**
- Vendor: vercel, vercel.app, vercel.com
- Framework (Vercel-deployed): next.js, nextjs, app router, server components, server actions, partial prerendering, ppr, cache components, `'use cache'`, after()
- Vercel products: vercel functions, vercel edge functions, fluid compute, vercel cron, vercel queues, vercel workflow, vercel kv, vercel postgres (now neon-backed), vercel blob, vercel edge config, vercel sandbox
- AI: vercel ai sdk, ai sdk (when vercel-context), chat sdk, vercel ai gateway, vercel agent, ai elements
- Tooling: vercel cli, vercel.json, turbopack, v0, v0.app
- Deployment: preview urls, vercel deployments, fluid compute, speed insights, web analytics (vercel)

**Negative signals:** Next.js used outside Vercel context (self-hosted Next.js → still partial trigger but bias toward platform-neutral specialist guidance).

### Supabase (`stacks/supabase/`)

**Slim local pointer:** `stacks/supabase/SKILL.md` • **Canonical docs:** <https://docs.etyb.ai/stacks/supabase/>
**Version:** 4.0.0 • **Last verified on:** 2026-05-14
**Delegates:** `supabase:supabase` and `supabase:supabase-postgres-best-practices`
**Roles overlaid:** backend-architect, database-architect, frontend-architect, security-engineer, ai-ml-engineer, saas-architect

**Detection signals:**
- Vendor: supabase
- Products: supabase auth, supabase storage, supabase realtime, edge functions (supabase), supabase queues, supabase cron, supabase studio, supabase branching
- Postgres-on-Supabase: supabase postgres, rls (when supabase-context), supavisor, pgbouncer (when supabase-context), `@supabase/ssr`, supabase-js
- Extensions context: pgvector (when supabase-context), pg_graphql, pg_cron (when supabase), pg_net, pgsodium, pgmq, foreign data wrappers (supabase)
- Tooling: `supabase` cli, supabase mcp

**Negative signals:** RLS in Postgres without Supabase context (still applies — load database-architect).

### Firebase (`stacks/firebase/`)

**Slim local pointer:** `stacks/firebase/SKILL.md` • **Canonical docs:** <https://docs.etyb.ai/stacks/firebase/>
**Version:** 4.0.0 • **Last verified on:** 2026-05-14
**Delegates:** heavy — see `stacks/firebase/SKILL.md` frontmatter for the 12 firebase:* delegates
**Roles overlaid:** backend-architect, frontend-architect, mobile-architect, ai-ml-engineer, security-engineer

**Detection signals:**
- Vendor: firebase
- Products: firebase auth, identity platform (when firebase-context), firestore, realtime database (firebase rtdb), firebase storage, cloud functions for firebase, firebase hosting, firebase app hosting, fcm, cloud messaging (when firebase), remote config, crashlytics, app distribution, firebase analytics, test lab (firebase), app check, firebase studio (formerly project idx)
- AI: firebase ai logic (formerly vertex ai in firebase), genkit, `@firebase/ai`
- Tooling: firebase cli, firebase emulator suite, security rules (when firebase-context), firebase data connect

**Negative signals:** "firebase" in non-Google context (legacy uses).

### Expo (`stacks/expo/`)

**Slim local pointer:** `stacks/expo/SKILL.md` • **Canonical docs:** <https://docs.etyb.ai/stacks/expo/>
**Version:** 4.0.0 • **Last verified on:** 2026-05-14
**Delegates:** heavy — see `stacks/expo/SKILL.md` frontmatter for the 10 expo-* and related delegates
**Roles overlaid:** mobile-architect, frontend-architect, devops-engineer, qa-engineer

**Detection signals:**
- Vendor: expo (when mobile/RN context), expo.dev
- Products: expo sdk, expo router, expo go, eas, eas build, eas update, eas submit, eas workflows, eas hosting, custom dev client, expo modules, expo-* npm packages (expo-router, expo-image, expo-secure-store, etc.)
- Architecture: continuous native generation, cng, prebuild (expo), `app.json` (expo-context), config plugins, expo dom components
- Tooling: `expo` cli, expo-doctor, snack, expo prebuild

**Negative signals:** "expo" in non-RN context (a tradeshow, Microsoft Expo product if any).

### Stripe (`stacks/stripe/`)

**Slim local pointer:** `stacks/stripe/SKILL.md` • **Canonical docs:** <https://docs.etyb.ai/stacks/stripe/>
**Version:** 4.0.0 • **Last verified on:** 2026-05-14
**Delegates:** none yet (Stripe ships an MCP server; add when installed in user environments)
**Roles overlaid:** backend-architect, security-engineer, saas-architect, e-commerce-architect, fintech-architect

**Detection signals:**
- Vendor: stripe
- Products: stripe payments, payment intents, setup intents, stripe checkout, stripe elements, payment element, express checkout element, stripe billing, stripe connect, stripe treasury, stripe issuing, stripe identity, stripe tax, stripe radar, stripe terminal, stripe sigma, stripe data pipeline, stripe atlas, stripe climate, stripe apps, stripe capital
- Concepts: webhook (stripe-context), idempotency-key (stripe-context), restricted api keys (stripe), api version (stripe), meter api, optimized checkout suite, adaptive pricing, stripe link, tap to pay (stripe)
- Tooling: stripe cli, stripe workbench, stripe-node, stripe-python, stripe.js, stripe react native sdk

**Negative signals:** "stripe" in non-payment context (Stripe colors, design "stripe", DNA stripe).

### Observability (`stacks/observability/`) — multi-vendor

**Slim local pointer:** `stacks/observability/SKILL.md` • **Canonical docs:** <https://docs.etyb.ai/stacks/observability/>
**Version:** 4.0.0 • **Last verified on:** 2026-05-14
**Delegates:** none yet (Datadog, New Relic, Splunk MCPs in development)
**Roles overlaid:** sre-engineer, devops-engineer, backend-architect, security-engineer

**Detection signals:**
- Vendors: datadog, new relic, newrelic, grafana, prometheus, splunk, honeycomb, sentry, dynatrace
- Datadog: dd-agent, dd-trace, datadog sds, watchdog ai, bits ai, datadog cspm, datadog ci visibility, datadog llm observability
- New Relic: nrql, nrdb, pixie, errors inbox, new relic ai monitoring
- Grafana stack: mimir, loki, tempo, pyroscope, faro, beyla, alloy (grafana), grafana cloud, grafana enterprise, k6 (load testing)
- Prometheus: alertmanager, promql, recording rules, remote_write, prometheus exporters, thanos, victoriametrics
- Splunk: spl (splunk query), splunk cloud, splunk observability cloud (formerly signalfx), splunk itsi
- Honeycomb: refinery, beelines, bubbleup, triggers (honeycomb)
- Sentry: sentry sdk, debug ids (sentry), release health (sentry), session replay (sentry)
- Dynatrace: oneagent, davis ai, smartscape, purepath, grail (dynatrace), dql
- OpenTelemetry: otel, opentelemetry, otlp, otel collector, otel auto-instrumentation, otel genai, semantic conventions

**Negative signals:** generic "logging" / "monitoring" without vendor signal (load sre-engineer specialist alone for principles).

## Authoring a new entry

When a new Stack ships, the order of operations is:

1. **Publish on docs.etyb.ai first.** Create the Stack index page, per-product canonical pages, and per-role composed views in `e-t-y-b/etyb-dot-ai` under `src/content/docs/stacks/<vendor>/`. The publish must precede the slim pointer because the slim pointer's `## Where the full briefing lives` section links into docs.etyb.ai URLs.
2. **Add the slim local pointer** `stacks/<vendor>/SKILL.md` with the standard template (frontmatter detection signals + delegate_to_skills + products_covered + top gotchas).
3. **Register the Stack in `manifest.json`** under `.stacks` with `version`, `last_verified_on`, `applies_to_roles`, `deferred_roles`.
4. **Add a section under "Active Stack Packs" above** with detection signals + negative signals.
5. **Add a row to `STACKS.md`** at repo root.

Stack registration in `manifest.json` is the source of truth for installed stacks; this file is the *router's view* of how to load and detect them at runtime.
