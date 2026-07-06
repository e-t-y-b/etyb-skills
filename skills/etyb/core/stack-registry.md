# Stack Registry — Tech Stack Detection

This is the router's view of **Stack Packs** — knowledge overlays that load when work involves a specific tech stack. Read this after `team-registry.md` when routing. Stack Packs are context overlays applied across the existing internal references, not new specialists. The public registry is `STACKS.md` at repo root; content layout, currency stamps, and the drift-check protocol live in `core/knowledge-currency.md`.

## Detection workflow

1. After classifying the tier and identifying specialists, scan the request for the stack signals below.
2. On a match, the slim `stacks/<vendor>/SKILL.md` loads — team briefing + top gotchas, enough for many soft-path answers.
3. Check its `delegate_to_skills` frontmatter: if a listed vendor skill/MCP is in `<available_skills>`, prefer it for that product — the vendor's own surface knows current state best.
4. For depth, read the most-specific in-repo file: `stacks/<vendor>/<product>.md` → `<role>.md` → `index.md`; apply the drift-check protocol per `core/knowledge-currency.md`. If a file is missing, fall back to the next-broadest, tell the user, and mark the answer cache-only — don't fabricate depth.
5. Multiple stacks may match; their briefings compose — each handles its own platform side.

**Composition rules:** Stack Packs never relax the 9 always-on disciplines (`core/session.md`) — they shape *how* those apply per platform (TDD on Apex = Apex test classes; on Workers = Miniflare). Stack Packs defer to business verticals for compliance and domain depth (Salesforce Health Cloud → the pack covers platform, `healthcare-architect` covers HIPAA/FHIR).

## Active Stack Packs — detection signals

All packs track the bundle version (single-version policy — see `VERSION`). When a signal is ambiguous, **ask** before loading — injecting a wrong stack's guidance distorts the response.

### Salesforce (`stacks/salesforce/`) — verified 2026-05-12 (Spring '26)
Roles: system/backend/frontend/database/devops/security/qa/ai-ml + saas/healthcare/fintech. Delegates: none yet (recheck as Salesforce-hosted MCPs ship).
Signals: salesforce, sfdc, sales/service/marketing/commerce/experience/health/financial-services/manufacturing cloud, public sector solutions, data 360/data cloud, agentforce, einstein, trust layer, prompt builder, hyperforce; apex, lwc, lightning, visualforce, aura, flow builder/orchestration, omnistudio, omniscript, dataraptor; soql, sosl, sobject, big object, salesforce connect, zero copy; pub/sub api, platform event, cdc, named/external credential, connected app, mulesoft; sf cli, sfdx, scratch org, sandbox, unlocked/managed package, devops center, copado, gearset, code analyzer, apexguru, lwc jest; appexchange, agentexchange, trailhead, dreamforce; salesforce admin/architect/CTA certs. Tableau/Slack/Heroku only when Salesforce-adjacent.
Negative: "salesforce" as generic CRM synonym; non-SF lightning/flow/apex (Bitcoin Lightning, Apex Legends); pure Slack/Tableau questions.

### AWS (`stacks/aws/`) — verified 2026-05-14
Roles: system/backend/database/devops/security/sre/ai-ml + saas/fintech. Delegates: none yet.
Signals: aws, amazon web services; ec2, ecs, eks, fargate, lambda, graviton, app runner, batch, lightsail, beanstalk; s3, ebs, efs, fsx, glacier, rds, aurora (incl. dsql), dynamodb, elasticache, redshift, athena, glue, lake formation, opensearch; bedrock, agentcore, strands agents, sagemaker, trainium, inferentia; vpc, route53, cloudfront, api gateway, appsync, transit gateway, vpc lattice, privatelink, direct connect; iam, sts, scp, permission boundary, kms, secrets manager, guardduty, security hub, cognito, waf, shield; cdk, cloudformation, sam, codebuild/codepipeline/codedeploy; cloudwatch, x-ray, cloudtrail, application signals, fis; well-architected, control tower, organizations, karpenter (AWS-context).
Negative: "aws"/"amazon" outside cloud context; Amazon retail/Prime.

### GCP (`stacks/gcp/`) — verified 2026-05-14
Roles: system/backend/database/devops/security/sre/ai-ml + saas. Delegates: none yet.
Signals: gcp, google cloud; gke (incl. autopilot), cloud run (+ functions), app engine, compute engine, anthos; cloud sql, alloydb, spanner, firestore (GCP-context), bigtable, memorystore, bigquery, looker, dataflow, dataproc, dataform, biglake, cloud storage; vertex ai, gemini (GCP-context), agent builder, agentspace, imagen, veo, model garden, tpu; vpc-sc, cloud load balancing/cdn/armor/dns; workload identity federation, cloud iam/kms, secret manager, security command center; terraform google provider, config connector, infrastructure manager; cloud monitoring/logging/trace/profiler, managed prometheus/otel; gcloud, gsutil, bq.
Negative: generic "google" without cloud verbs; Google Search/Workspace.

### Azure (`stacks/azure/`) — verified 2026-05-14
Roles: system/backend/database/devops/security/sre/ai-ml + saas/healthcare. Delegates: none yet.
Signals: azure, microsoft azure; aks, container apps/instances, azure functions, app service, static web apps; cosmos db, azure sql (incl. hyperscale), postgresql flexible server, azure managed redis, blob storage; ai foundry, foundry agents, azure openai, ai search, azure ml, copilot studio, microsoft fabric, synapse, entra agent id; front door, application gateway, private link, azure firewall; entra id (+ external id), pim, managed identity, key vault, managed hsm, defender for cloud, sentinel, purview, azure policy; bicep, avm, deployment stacks, terraform azurerm, azd, azure devops; azure monitor, log analytics, application insights; azure arc/local/vmware.
Negative: generic "microsoft"; M365/Office.

### Anthropic Claude (`stacks/anthropic-claude/`) — verified 2026-05-14
Roles: backend/ai-ml/system/security. Delegates: `claude-api`.
Signals: anthropic, claude; claude api, messages api, claude code, claude agent sdk, opus/sonnet/haiku, anthropic sdk; prompt caching, tool use, extended/interleaved thinking, computer use, claude memory, citations api; mcp, model context protocol, anthropic console, claude code skills/hooks.
Negative: "claude" as a personal name; consumer Claude.ai chat (this Stack covers the developer surface).

### OpenAI (`stacks/openai/`) — verified 2026-05-14
Roles: ai-ml/backend/system/security. Delegates: none yet.
Signals: openai, gpt; gpt-5, gpt-4.1, gpt-4o, o3/o4, gpt-image-1, dall-e, whisper; responses api, assistants api (legacy), chat completions, realtime api, batch api, embeddings (text-embedding-3-*), moderation api; structured outputs, function calling, operator/computer use, agents sdk, codex; openai-python/node/cli/platform.
Negative: "gpt" in unrelated contexts (GPT disk partitions); non-OpenAI GPT-style models.

### Cloudflare (`stacks/cloudflare/`) — verified 2026-05-14
Roles: backend/system/devops/database/security/ai-ml. Delegates: `cloudflare:cloudflare-mcp` (Workers, D1, R2, KV, Hyperdrive, Pages).
Signals: cloudflare; workers, durable objects, workers for platforms; wrangler, miniflare, compatibility-date; d1, r2, kv, hyperdrive, vectorize; cloudflare tunnel/access, zero trust, magic transit/wan, argo; cloudflare waf/ddos, turnstile; workers ai, ai gateway, ai search, browser rendering; stream, images, realtime, email routing/workers; pages, workflows, queues, cron triggers (CF-context).
Negative: generic "edge"; "workers" in non-CF context (Web Workers, K8s workers).

### Vercel (`stacks/vercel/`) — verified 2026-05-14
Roles: frontend/backend/devops/ai-ml/system. Delegates: heavy — 18 `vercel:*` skills, see the pack's frontmatter.
Signals: vercel, vercel.app; next.js, app router, server components/actions, partial prerendering, cache components, `'use cache'`; vercel functions/edge functions, fluid compute, vercel cron/queues/workflow/kv/postgres/blob/edge config/sandbox; vercel ai sdk, chat sdk, ai gateway, vercel agent, ai elements; vercel cli, vercel.json, turbopack, v0; preview urls, speed insights.
Negative: self-hosted Next.js → partial trigger, bias toward platform-neutral specialist guidance.

### Supabase (`stacks/supabase/`) — verified 2026-05-14
Roles: backend/database/frontend/security/ai-ml + saas. Delegates: `supabase:supabase`, `supabase:supabase-postgres-best-practices`.
Signals: supabase; supabase auth/storage/realtime/queues/cron/studio/branching, edge functions (supabase); rls, supavisor, pgbouncer (supabase-context), `@supabase/ssr`, supabase-js; pgvector, pg_graphql, pg_cron, pg_net, pgsodium, pgmq (supabase-context); `supabase` cli, supabase mcp.
Negative: RLS in plain Postgres without Supabase → database-architect alone.

### Firebase (`stacks/firebase/`) — verified 2026-05-14
Roles: backend/frontend/mobile/ai-ml/security. Delegates: heavy — 12 `firebase:*` skills, see the pack's frontmatter.
Signals: firebase; firebase auth, identity platform, firestore, rtdb, firebase storage/hosting/app hosting, cloud functions for firebase, fcm, remote config, crashlytics, app distribution, test lab, app check, firebase studio; firebase ai logic, genkit, `@firebase/ai`; firebase cli, emulator suite, security rules, data connect.
Negative: "firebase" in non-Google contexts.

### Expo (`stacks/expo/`) — verified 2026-05-14
Roles: mobile/frontend/devops/qa. Delegates: heavy — 10 `expo-*` and related skills, see the pack's frontmatter.
Signals: expo (mobile/RN context), expo.dev; expo sdk/router/go, eas (build/update/submit/workflows/hosting), custom dev client, expo modules, expo-* npm packages; continuous native generation, cng, prebuild, config plugins, dom components; `expo` cli, expo-doctor, snack.
Negative: "expo" as tradeshow or non-RN product.

### Stripe (`stacks/stripe/`) — verified 2026-05-14
Roles: backend/security + saas/e-commerce/fintech. Delegates: none yet (add Stripe MCP when installed).
Signals: stripe; payment/setup intents, checkout, elements (payment/express checkout), billing, connect, treasury, issuing, identity, tax, radar, terminal, sigma, atlas, apps; webhook, idempotency-key, restricted api keys, api version, meter api, adaptive pricing, link, tap to pay (stripe-context); stripe cli, workbench, stripe-node/python/.js, react native sdk.
Negative: "stripe" in non-payment contexts (design stripes, DNA).

### Observability (`stacks/observability/`) — multi-vendor — verified 2026-05-14
Roles: sre/devops/backend/security. Delegates: none yet.
Signals: datadog (dd-agent, dd-trace, watchdog, bits ai, llm observability), new relic (nrql, nrdb, pixie, errors inbox), grafana stack (mimir, loki, tempo, pyroscope, faro, beyla, alloy, k6), prometheus (alertmanager, promql, remote_write, thanos, victoriametrics), splunk (spl, observability cloud, itsi), honeycomb (refinery, bubbleup), sentry (debug ids, release health, session replay), dynatrace (oneagent, davis ai, purepath, grail, dql), opentelemetry (otel, otlp, collector, semantic conventions).
Negative: generic "logging"/"monitoring" without a vendor signal → sre-engineer specialist alone.

## Authoring a new entry

1. Create `stacks/<vendor>/` with `SKILL.md` (slim trigger surface), `index.md`, one `<product>.md` per covered product, one `<role>.md` per overlaid role — currency stamps per `core/knowledge-currency.md`.
2. Register in `manifest.json` under `.stacks`; add a signals section above; add a row to `STACKS.md`.

`manifest.json` is the source of truth for installed stacks; this file is the router's runtime view.
