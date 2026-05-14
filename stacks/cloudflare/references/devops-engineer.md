---
role: devops-engineer
stack: cloudflare
last_verified_on: "2026-05-14"
---

# Cloudflare overlay for `devops-engineer`

You own the build-deploy-release pipeline for Workers and Cloudflare-side infrastructure. That means Wrangler, CI configs, multi-env layouts, secret management, gradual rollouts, observability (Workers Logs + Logpush + Analytics Engine), and IaC (Cloudflare Terraform / Pulumi providers). The original `devops-engineer` reference covers the general DevOps decision framework — this overlay specializes it to the Cloudflare edge.

## Role briefing — DevOps on Cloudflare

Cloudflare deployment isn't a traditional CI/CD problem. There are no clusters to size, no nodes to patch, no autoscalers to tune. What you do own:

- **Wrangler discipline:** `wrangler.toml`/`wrangler.jsonc` is the manifest; `compatibility_date` is the runtime version; secrets live outside the file.
- **Multi-environment topology:** dev/staging/prod via `--env` flags, separate Workers, separate D1/KV/R2 instances per env.
- **Deploy gating:** dry-runs, types check, tests, then gradual rollout via Versions + traffic splits.
- **Secrets and config:** what's a `var` (non-secret), what's a Wrangler secret, what's a binding, what's pulled from a secrets manager.
- **Observability glue:** Workers Logs (queryable), tail, Logpush (to S3/Datadog/Splunk), Workers Trace (linked traces), Analytics Engine for custom metrics, Cloudflare Notifications for alerts.
- **Infrastructure as code:** Terraform `cloudflare/cloudflare` provider for everything that has a Cloudflare API — zones, DNS, Workers, KV/R2/D1, Access policies, WAF, Tunnels, Hyperdrive configs.
- **Custom domains and routing:** routes, custom domains, zone vs sub-zone, workers.dev preview URLs.

What you don't own here (defer):
- Worker code logic → `backend-architect` overlay.
- Schema and query design → `database-architect`.
- WAF rule semantics, Access policy semantics → `security-engineer`.

## Decision frameworks

### Where do I run the build?

| Option | Use when |
|--------|----------|
| **Cloudflare Workers Builds** (Cloudflare's managed CI for Workers/Pages, GA 2024-25) | Simple builds tied to a Git repo; want zero CI setup; want preview deployments per branch out of the box |
| **GitHub Actions** with `cloudflare/wrangler-action@v3` | Most teams; full control; multi-step pipelines; integrates with everything else you're already doing |
| **GitLab CI / Bitbucket / CircleCI** with Wrangler | When your repo is there; same pattern — install Node, install Wrangler, run `wrangler deploy` |
| **Cloudflare Pages Git integration** (legacy) | Existing Pages projects; new projects should be on Workers Builds or GH Actions instead |

For most ETYB engagements the answer is **GitHub Actions** unless the user is already on Workers Builds. Workers Builds is improving but has fewer escape hatches.

### How do I split environments?

**Option A — One Worker per env (recommended):**
```toml
# wrangler.toml
name = "api-dev"
main = "src/index.ts"
compatibility_date = "2026-05-01"

[[d1_databases]]
binding = "DB"
database_name = "api-dev"
database_id = "..."

[env.staging]
name = "api-staging"
[[env.staging.d1_databases]]
binding = "DB"
database_name = "api-staging"
database_id = "..."

[env.production]
name = "api-production"
[[env.production.d1_databases]]
binding = "DB"
database_name = "api-prod"
database_id = "..."
```
Deploy: `wrangler deploy --env staging` / `wrangler deploy --env production`.

**Option B — Branch-based with Wrangler "Versions" + gradual rollout:** Each push deploys a Version of the prod Worker; you promote with traffic splits. Better fit for trunk-based teams; worse for teams with long-lived environments.

**Don't** share a single Worker across environments via `if (env.ENV === "prod")` branching. The bindings differ; the deploys differ; the secrets differ. Use `--env`.

### Wrangler v4 vs v3 vs v2

- **Wrangler v4** (current, 2025-26): use this. `wrangler deploy`, `wrangler types`, `wrangler secret bulk`, full RPC binding support.
- **Wrangler v3** (2023-2024): still works for many things; `wrangler publish` was deprecated mid-v3.
- **Wrangler v2** (2022): obsolete; do not start a new project on it.
- **Wrangler v1** (2018-2021): cannot deploy modern Workers; the `wrangler-legacy` package exists for reference only.

Pin Wrangler to a known-good version in `package.json` (`"wrangler": "^4.x.x"`). Don't use `latest` in CI — Wrangler ships breaking flag changes occasionally.

### `wrangler.toml` vs `wrangler.jsonc`

Both supported. JSONC (since 2024) is preferable for:
- Teams that already lint/format JSON.
- IDE schema validation (Wrangler ships a JSON schema).
- Programmatic generation (some teams build the config from Pulumi/Terraform output).

TOML is still fine. Pick one per repo; don't mix.

### Containers on Workers, when to add them

Workers + Containers (beta through 2025) lets a Worker boot an isolated container instance for workloads that don't fit the V8-isolate model — Python ML scripts, FFmpeg, long-running stateful processes.

Use containers when:
- Your code is in a language Workers can't run (Python beyond the limited beta, Ruby, Go without Wasm, etc.).
- You need >30s wall clock or >30s CPU.
- You need persistent local disk for the duration of a job.
- You need to shell out to a binary (FFmpeg, ImageMagick, Pandoc).

Don't use containers when:
- It's a quick request handler — a Worker is cheaper and faster.
- You can do the work in Workers AI or via R2 transformations.

Beta-stage product; verify current limits and pricing on docs before designing around it.

## Critical 2025-2026 platform reset for devops-engineers

### `wrangler deploy` (not `publish`)

```bash
# OLD (deprecated, prints a warning, may stop working)
wrangler publish

# NEW
wrangler deploy
wrangler deploy --env staging
wrangler deploy --dry-run --outdir=dist   # CI: build without deploying, inspect output
wrangler deploy --keep-vars               # don't reset env vars from previous deploy
```

`wrangler deploy --dry-run --outdir=dist` is the secret weapon for CI: it builds the Worker, writes the bundle, and tells you the bundle size — without consuming a deploy quota slot. Run on every PR.

### `wrangler types` is mandatory in CI

After any `wrangler.toml` change:
```bash
wrangler types     # writes worker-configuration.d.ts
```

In CI:
```yaml
- name: Generate types
  run: npx wrangler types

- name: Type check
  run: npx tsc --noEmit
```

If `wrangler types` is out of date, your code may compile against stale binding signatures. CI should fail when generated types differ from committed types — either commit them on every change or `wrangler types` then `tsc` in the same job.

### `wrangler secret bulk` for batch secret rotation

```bash
# .secrets.json (gitignored; built from a vault)
{
  "OPENAI_API_KEY": "sk-...",
  "STRIPE_SECRET_KEY": "sk_live_...",
  "JWT_SIGNING_KEY": "..."
}

wrangler secret bulk .secrets.json --env production
```

Use this in CI for secret rotation. Don't do `wrangler secret put` per secret in a loop — slow, racy, and noisy in logs.

For larger orgs: pull from Vault / 1Password / AWS Secrets Manager / GitHub Actions secrets via a CI step, build the JSON, run `secret bulk`, delete the JSON.

### Versions and gradual rollouts

```bash
# Upload a version without taking traffic
wrangler versions upload

# List versions
wrangler versions list

# Deploy a version with traffic split (canary)
wrangler versions deploy <version-id-a>@10% <version-id-b>@90%

# Rollback by deploying old version at 100%
wrangler versions deploy <old-version-id>@100%
```

Treat **Versions** as the deploy primitive for production. The old "deploy is immediate" model still works (`wrangler deploy`), but Versions give you the rollback discipline you want for anything customer-facing.

Pattern for prod:
1. CI builds and uploads a Version (`wrangler versions upload`).
2. CI deploys it at 5% to canary, waits for X minutes, checks error rate via Workers Logs API.
3. If error rate OK, promote to 100%; else roll back to previous version.

### Workers Logs (queryable, persistent)

`observability.logs.enabled = true` in `wrangler.toml` activates Workers Logs:

```toml
[observability]
[observability.logs]
enabled = true
head_sampling_rate = 1.0   # sample 100% of invocations (or 0.1 for 10%)
invocation_logs = true
```

Now your `console.log()` / `console.error()` calls land in a queryable store, visible in the Cloudflare dashboard, filterable by:
- Time range
- Request URL
- Status code
- Worker name and version
- Custom fields you log

For volume-heavy Workers, set `head_sampling_rate` below 1.0 — sampling at the invocation level (so a sampled invocation logs everything, an unsampled one logs nothing).

This replaced the older "push every Workers log to a logging vendor" pattern for typical debugging. **Logpush is still the right answer for fan-out to Datadog/Splunk/S3/Elastic.**

### Logpush jobs

```bash
# Configure via wrangler or API; example via wrangler.toml-adjacent script
wrangler logpush create --dataset=workers_trace_events \
  --destination="s3://my-bucket/cf-logs?region=us-east-1&access-key-id=...&secret-access-key=..." \
  --enabled
```

Datasets you'll commonly push:
- `workers_trace_events` — every Worker invocation (subrequests, errors, console logs).
- `http_requests` — zone-level HTTP traffic.
- `firewall_events` — WAF, rate-limiting, custom rule hits.
- `audit_logs` — Cloudflare account audit trail (compliance must-have).
- `access_logins` — Cloudflare Access auth events.

Logpush is **paid** above modest quotas. Estimate volume before turning it on for everything.

### Analytics Engine for custom metrics

```ts
// In a Worker
env.ANALYTICS.writeDataPoint({
  indexes: ["orders"],
  doubles: [order.amount_cents],
  blobs: [order.merchant_id, order.currency]
});
```

In `wrangler.toml`:
```toml
[[analytics_engine_datasets]]
binding = "ANALYTICS"
dataset = "my-app-metrics"
```

Query via Workers Analytics Engine API (SQL-over-HTTP):
```sql
SELECT blob1 AS merchant_id, SUM(double1) / 100 AS revenue_usd
FROM my_app_metrics
WHERE timestamp > NOW() - INTERVAL '1' DAY
GROUP BY blob1
ORDER BY revenue_usd DESC LIMIT 10;
```

Analytics Engine is per-datapoint pricing — cheap, but estimate before writing one per request.

### Cloudflare's Terraform provider

```hcl
terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.40"   # check current minor for new resources
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

resource "cloudflare_workers_script" "api" {
  account_id  = var.account_id
  script_name = "api-production"
  content     = file("${path.module}/../dist/index.js")

  # As of 2025-26 the provider supports declaring bindings inline.
  # But typically you let Wrangler deploy the script itself and use TF
  # only for the surrounding infra (D1, KV, R2, routes, custom domains, WAF).
}

resource "cloudflare_d1_database" "prod" {
  account_id = var.account_id
  name       = "api-prod"
}

resource "cloudflare_kv_namespace" "sessions" {
  account_id = var.account_id
  title      = "sessions-prod"
}

resource "cloudflare_r2_bucket" "receipts" {
  account_id = var.account_id
  name       = "orders-receipts"
}

resource "cloudflare_workers_custom_domain" "api" {
  account_id  = var.account_id
  zone_id     = var.zone_id
  hostname    = "api.example.com"
  service     = cloudflare_workers_script.api.script_name
}

resource "cloudflare_ruleset" "waf_managed" {
  account_id = var.account_id
  name       = "Managed Cloudflare ruleset"
  kind       = "zone"
  phase      = "http_request_firewall_managed"
  rules { ... }
}
```

Recommended pattern: **Terraform owns the infra around Workers** (D1 instances, KV namespaces, R2 buckets, routes, custom domains, WAF rulesets, Access policies, Tunnels). **Wrangler owns the script deploys** (with `wrangler deploy` from CI).

Don't try to make Terraform deploy the Worker script. The Worker code changes every PR; the infra changes rarely. Different cadences = different tools.

### Pulumi alternative

If the team already uses Pulumi (TypeScript/Python/Go), the `@pulumi/cloudflare` provider is the official path. Same shape as Terraform; same boundary recommendation (Pulumi for infra, Wrangler for the script).

### Compatibility-date discipline

```toml
compatibility_date = "2026-05-01"
compatibility_flags = ["nodejs_compat_v2"]
```

Hard rules:
- Set this on every project. The runtime won't break if it's missing, but it'll fall back to old (pre-2022) behavior.
- Pin to a recent date for new projects.
- **Don't bump compatibility_date silently.** Runtime semantics can change (rare but real — e.g., `Headers` iteration order, `fetch` redirect behavior). Bump, run tests, deploy to staging, observe, then promote.
- `nodejs_compat_v2` is the modern flag (replaces `nodejs_compat`). Enables more Node APIs (Buffer, EventEmitter, util, crypto, async_hooks).
- Read [compatibility-dates docs](https://developers.cloudflare.com/workers/configuration/compatibility-dates/) before bumping.

In CI, fail the build if `compatibility_date` is older than X months (write a tiny check; the Cloudflare community has examples).

## Patterns and anti-patterns

### Pattern: GitHub Actions workflow for Workers

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]
  pull_request:

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - run: npm ci
      - name: Generate Workers types
        run: npx wrangler types
      - name: Type check
        run: npx tsc --noEmit
      - name: Test
        run: npm test
      - name: Build (dry-run deploy to verify bundle)
        run: npx wrangler deploy --dry-run --outdir=dist
      - name: Bundle size check
        run: |
          size=$(stat -c%s dist/index.js)
          if [ "$size" -gt 1048576 ]; then echo "Bundle >1MB"; exit 1; fi

  deploy-staging:
    needs: ci
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - name: Deploy preview
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: deploy --env=staging --name=api-pr-${{ github.event.number }}
      - name: Comment preview URL
        uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: "Preview: https://api-pr-${{ github.event.number }}.example.workers.dev"
            });

  deploy-prod:
    needs: ci
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - name: Upload version (no traffic yet)
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: versions upload --env=production
      - name: Canary 10%
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          command: versions deploy --env=production
      # Wait for error-rate check (custom script polling Workers Logs API)
      # Then promote or rollback
```

### Pattern: secrets via OIDC, not long-lived tokens

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - name: Configure AWS credentials (for secrets manager)
    uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::123:role/gh-actions-cloudflare
      aws-region: us-east-1
  - name: Fetch secrets and load
    run: |
      aws secretsmanager get-secret-value --secret-id prod/cloudflare-worker --query SecretString --output text > .secrets.json
      npx wrangler secret bulk .secrets.json --env=production
      rm .secrets.json
```

Anti-pattern: storing `CLOUDFLARE_API_TOKEN` in GitHub Secrets with `Write Workers Scripts` on every account. Scope tokens narrowly — use the Cloudflare API token creator with the smallest possible permission set (per-account, per-zone, per-resource).

### Pattern: PR previews via deterministic naming

Per-PR Worker: `api-pr-${{ github.event.number }}.example.workers.dev`. Delete on PR close:

```yaml
on:
  pull_request:
    types: [closed]

jobs:
  cleanup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci
      - run: npx wrangler delete --name=api-pr-${{ github.event.number }} --force
```

### Pattern: separate Cloudflare accounts per environment for blast-radius isolation

For mature orgs: **separate Cloudflare accounts for dev/staging/prod.** The API token for prod can't touch staging. Misconfigured infra in staging can't cascade. Comes with cost (account-level fees, separate billing) — only worth it past a certain scale.

For smaller orgs: one account, but use **API token scoping per environment** (token-A can deploy `*-staging` Workers; token-B can deploy `*-production`). Less isolated but free.

### Pattern: Workers Logs sampling for high-volume Workers

```toml
[observability.logs]
enabled = true
head_sampling_rate = 0.1   # 10% of invocations
invocation_logs = true
```

At 1000 req/sec, full-sampling Workers Logs adds up. Sample. For errors specifically, you can `console.error()` from a guard that always logs failures + sample successes:

```ts
try {
  // ...
  if (Math.random() < 0.1) console.log({ event: "ok", ...stuff });
} catch (e) {
  console.error({ event: "fail", error: e });
  throw e;
}
```

The runtime samples at the **invocation** level too — `head_sampling_rate=0.1` means 10% of invocations are sampled and log everything; the other 90% log nothing. Whichever sampling approach you use, document it so the on-call doesn't chase phantom "missing logs."

### Pattern: tail Workers for tenant log access (Workers for Platforms)

```ts
// Tail Worker — runs once per invocation of any worker in the dispatch namespace
export default {
  async tail(events, env) {
    for (const event of events) {
      await env.TENANT_LOG_QUEUE.send({
        tenantId: event.scriptName.replace("tenant-", ""),
        logs: event.logs,
        outcome: event.outcome,
        timestamp: event.eventTimestamp
      });
    }
  }
}
```

This is the pattern when running other people's code (Workers for Platforms): you want to surface their logs back to them, not flood your global Workers Logs.

### Anti-pattern: `wrangler dev` then `wrangler deploy` without testing

`wrangler dev` uses Miniflare; `wrangler dev --remote` uses production bindings; `wrangler deploy` runs against production. They have different behaviors for KV (local KV is fast and synchronous), D1 (local is SQLite, prod is distributed), and AI (local must call out to production AI). **Run the integration suite via `wrangler dev --remote` in CI before deploying to prod.**

### Anti-pattern: storing config in `vars` and rotating via redeploy

```toml
[vars]
STRIPE_PUBLIC_KEY = "pk_live_..."     # OK — public key, OK to be in repo
STRIPE_SECRET_KEY = "sk_live_..."     # WRONG — secret in repo
```

Rule: anything that grants capability is a `wrangler secret`, not a `var`. Vars are visible in the dashboard, in deploy logs, sometimes in API responses. Secrets are encrypted at rest, only visible to the Worker at runtime.

### Anti-pattern: account-level API token shared across all CI

One token, all permissions, in every CI job, never rotated. When (not if) it leaks, your whole Cloudflare estate is at risk. Use:
- Per-purpose tokens (one for Workers deploys, one for DNS, one for cache purges, etc.).
- Per-environment tokens (one for staging deploys, one for prod deploys).
- Rotation schedule (every 90 days minimum for production).

### Anti-pattern: deploying without a rollback plan

```bash
wrangler deploy   # gone, no easy rollback
```

Use Versions for prod:
```bash
wrangler versions upload         # builds and uploads, no traffic
wrangler versions deploy <id>@100%   # deploys this version
# To roll back:
wrangler versions list
wrangler versions deploy <previous-id>@100%
```

Document the rollback command in your runbook. On-call should be able to roll back without thinking.

## Tooling specifics

### `wrangler` daily-use cheat sheet

```bash
# Dev
wrangler dev                            # Miniflare local
wrangler dev --remote                   # local code, remote bindings
wrangler dev --env staging              # use staging config
wrangler dev --port 8788                # custom port
wrangler dev --inspect                  # Chrome DevTools support

# Build / Deploy
wrangler deploy
wrangler deploy --env production
wrangler deploy --dry-run --outdir=dist
wrangler deploy --keep-vars             # preserve env vars from prior deploy
wrangler delete --name=worker-name

# Versions
wrangler versions upload
wrangler versions list
wrangler versions deploy <id>@100%
wrangler versions view <id>

# Secrets
wrangler secret put NAME [--env=staging]
wrangler secret delete NAME
wrangler secret list
wrangler secret bulk file.json [--env=staging]

# Types
wrangler types
wrangler types --x-include-runtime  # include runtime types in output

# Logs
wrangler tail                           # live tail
wrangler tail --format=pretty
wrangler tail --status=error
wrangler tail --search="user_id=42"

# D1
wrangler d1 create NAME
wrangler d1 list
wrangler d1 execute NAME --command="SQL" [--remote]
wrangler d1 execute NAME --file=migration.sql [--remote]
wrangler d1 migrations create NAME description
wrangler d1 migrations apply NAME [--remote]
wrangler d1 export NAME --output=backup.sql
wrangler d1 backup ...
wrangler d1 time-travel restore NAME --timestamp=...

# KV
wrangler kv namespace create NAME
wrangler kv namespace list
wrangler kv key put --binding=BINDING key value [--remote]
wrangler kv key list --binding=BINDING [--remote]
wrangler kv bulk put --binding=BINDING ./kv.json

# R2
wrangler r2 bucket create NAME
wrangler r2 bucket list
wrangler r2 object put NAME/key --file=./local
wrangler r2 object get NAME/key --file=./local
wrangler r2 object delete NAME/key

# Queues
wrangler queues create NAME
wrangler queues list
wrangler queues consumer add NAME WORKER
wrangler queues consumer remove NAME WORKER

# Vectorize
wrangler vectorize create NAME --dimensions=1024 --metric=cosine
wrangler vectorize list
wrangler vectorize insert NAME --file=vectors.ndjson
wrangler vectorize query NAME --vector-file=q.json --top-k=5
wrangler vectorize create-metadata-index NAME --property-name=tenant --type=string

# Hyperdrive
wrangler hyperdrive create NAME --connection-string="postgres://..."
wrangler hyperdrive list
wrangler hyperdrive update NAME --caching-disabled
wrangler hyperdrive delete NAME

# DO
wrangler durable-objects list

# Pages (maintenance mode but still works)
wrangler pages deploy ./dist --project-name=NAME
wrangler pages deployment list --project-name=NAME

# Workers Static Assets (preferred over Pages for new builds)
# Configured via wrangler.toml [[assets]], deployed with `wrangler deploy`
```

### `wrangler.toml` skeleton with everything

```toml
name = "my-worker"
main = "src/index.ts"
compatibility_date = "2026-05-01"
compatibility_flags = ["nodejs_compat_v2"]

# Smart Placement — runs Worker near backend if backend roundtrips dominate
[placement]
mode = "smart"

# Workers Static Assets (replaces Pages)
[assets]
directory = "./public"
binding = "ASSETS"
not_found_handling = "single-page-application"   # for SPA
run_worker_first = ["/api/*"]   # routes that always hit the Worker

# Observability
[observability]
[observability.logs]
enabled = true
head_sampling_rate = 1.0
invocation_logs = true

# Triggers
[[triggers.crons]]
cron = "*/5 * * * *"

# Routes
routes = [
  { pattern = "api.example.com/*", custom_domain = true }
]

# Bindings — env vars (non-secret)
[vars]
ENV = "production"
LOG_LEVEL = "info"

# Bindings — D1
[[d1_databases]]
binding = "DB"
database_name = "prod"
database_id = "..."

# Bindings — KV
[[kv_namespaces]]
binding = "SESSIONS"
id = "..."

# Bindings — R2
[[r2_buckets]]
binding = "ASSETS"
bucket_name = "prod-assets"

# Bindings — Queues
[[queues.producers]]
binding = "TASKS"
queue = "tasks-prod"

[[queues.consumers]]
queue = "tasks-prod"
max_batch_size = 25
max_batch_timeout = 5
max_retries = 3
dead_letter_queue = "tasks-prod-dlq"

# Bindings — DO
[[durable_objects.bindings]]
name = "ROOM"
class_name = "Room"
[[migrations]]
tag = "v1"
new_sqlite_classes = ["Room"]

# Bindings — service (RPC)
[[services]]
binding = "AUTH"
service = "auth-worker"
entrypoint = "AuthService"

# Bindings — Workers AI
[ai]
binding = "AI"

# Bindings — Vectorize
[[vectorize]]
binding = "VECTOR_INDEX"
index_name = "embeddings-prod"

# Bindings — Hyperdrive
[[hyperdrive]]
binding = "ANALYTICS_PG"
id = "..."

# Bindings — Analytics Engine
[[analytics_engine_datasets]]
binding = "ANALYTICS"
dataset = "app-events"

# Bindings — mTLS cert (for outbound mTLS calls)
[[mtls_certificates]]
binding = "CERT"
certificate_id = "..."

# Environments
[env.staging]
name = "my-worker-staging"
vars = { ENV = "staging", LOG_LEVEL = "debug" }
[[env.staging.d1_databases]]
binding = "DB"
database_name = "staging"
database_id = "..."
```

### `.dev.vars` for local secrets

```
# .dev.vars (gitignored)
OPENAI_API_KEY=sk-local-test-key
STRIPE_SECRET_KEY=sk_test_...
```

`wrangler dev` reads `.dev.vars` and exposes them as `env.OPENAI_API_KEY` etc. **Never commit `.dev.vars`.** Add to `.gitignore`.

### Multi-Worker monorepo layout

```
repo/
├── workers/
│   ├── api/
│   │   ├── src/
│   │   ├── wrangler.toml
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── auth/
│   │   └── ...
│   └── billing/
│       └── ...
├── packages/
│   ├── shared/                  # shared TypeScript code, published or pnpm-workspace'd
│   └── repos/                   # shared D1 repo classes
├── infra/
│   └── terraform/
└── .github/
    └── workflows/
        ├── api.yml
        ├── auth.yml
        └── billing.yml
```

Per-worker CI; shared types/code via workspace packages. Don't try to deploy multiple Workers from one giant `wrangler.toml` — Wrangler supports it via `--config` flags but it's painful.

### Cloudflare Workers Builds (managed CI)

If the user wants zero CI setup:
1. Connect repo in Cloudflare dashboard.
2. Cloudflare auto-detects framework (or you specify build command and deploy command).
3. Every push to main deploys; every PR gets a preview URL.

Limitations:
- Less flexible than GitHub Actions (no custom multi-step pipelines, no parallel jobs).
- Build env has Node, Wrangler, common tools — but installing custom system packages is harder.
- Logs are in the Cloudflare dashboard, not GitHub PR comments.

For trivial Workers (no integration tests, no secret rotation logic), Workers Builds is fine. For anything load-bearing, use GH Actions.

## Cross-references to products_covered

- **Wrangler CLI** → "Wrangler v4 essentials" + "wrangler daily-use cheat sheet"; [Wrangler reference](https://developers.cloudflare.com/workers/wrangler/commands/).
- **Workers Logs / Logpush / Analytics Engine** → "Workers Logs (queryable, persistent)" + "Logpush jobs" + "Analytics Engine for custom metrics".
- **Smart Placement** → mentioned in `wrangler.toml` skeleton; only worth turning on when backend roundtrips dominate user-facing latency.
- **Workers Static Assets / Pages** → "Pages is in maintenance mode" (in SKILL.md briefing); migration is a devops concern.
- **Compatibility-date / flags** → "Compatibility-date discipline"; [compatibility-dates docs](https://developers.cloudflare.com/workers/configuration/compatibility-dates/).
- **Versions / Gradual rollouts** → "Versions and gradual rollouts"; pattern in GitHub Actions example.
- **Cloudflare Terraform provider** → "Cloudflare's Terraform provider".
- **Workers for Platforms** → tail Worker pattern; depth in `system-architect.md`.
- **Containers on Workers** → decision framework; beta-stage.

## Integration with always-on protocols

### CI as the verification gate

Every Cloudflare-side PR should pass:
1. `npm ci` clean install.
2. `npx wrangler types` (and check no diff vs committed types).
3. `npx tsc --noEmit` strict TypeScript.
4. `npm test` (Vitest + `vitest-pool-workers`).
5. `npx wrangler deploy --dry-run --outdir=dist`.
6. Bundle size check (fail if >1MB compressed by default; Workers free tier limit is 3MB after compression, paid is higher; you want to be well under).
7. Lint (`eslint`, `biome`, or `oxlint`).
8. Optional: smoke test against deployed preview URL (when PR deploys).

### Branch safety

When trying out Cloudflare changes in worktrees: each branch gets a preview Worker (`api-pr-<n>`) and a preview Pages/Static Assets deploy. The preview Worker has read access to staging bindings, never to prod. **Production secrets and prod bindings live only in the `production` env.** PRs cannot accidentally read prod data.

### Verification checklist for devops on Cloudflare

Before marking a deploy gate passed:

- [ ] `wrangler deploy --dry-run` succeeds locally and in CI.
- [ ] `wrangler types` is up to date and committed.
- [ ] All bindings in `wrangler.toml` exist in the target account (D1/KV/R2/Queue/DO names match real resources).
- [ ] Secrets are present in the target env (`wrangler secret list --env=production`).
- [ ] Compatibility date is within the last 90 days, or pinned with a rationale comment.
- [ ] Workers Logs is enabled (or there's a documented reason it's off).
- [ ] At least one custom domain or workers.dev route is configured.
- [ ] Rollback procedure is documented in the runbook (`wrangler versions list` + `wrangler versions deploy <prev>@100%`).
- [ ] Bundle size is under team threshold (default 1MB; the Workers limit is ~3MB after compression, but bundles much smaller than that perform better).
- [ ] Smoke test of the deployed Worker (`curl https://api.example.com/health`) returns 200.
- [ ] Logpush job (if any) is enabled and writing to the destination.
- [ ] WAF rules around this Worker's routes are reviewed (with `security-engineer`).

### Debugging Cloudflare deploys

When a deploy fails or behaves unexpectedly:

1. **`wrangler deploy --dry-run --outdir=dist`** locally — does it build?
2. **`wrangler tail --status=error`** after the deploy — what's the runtime error?
3. **Workers Logs** in the dashboard — filter by status code, search by request ID.
4. **Check the version that's actually live** — `wrangler versions list`, confirm which version got 100% of traffic.
5. **Rollback first, investigate after.** Don't debug live in production; `wrangler versions deploy <previous>@100%` and then debug the bad version against staging.

### Escalation paths from devops-engineer on Cloudflare

- **Worker code logic errors** → `backend-architect` overlay.
- **D1 schema or migration issues** → `database-architect` overlay.
- **WAF rule false positives / Access policy issues** → `security-engineer` overlay.
- **AI model failures or AI Gateway misbehavior** → `ai-ml-engineer` overlay.
- **Architecture-level "should this be 1 Worker or 3?"** → `system-architect` overlay.
- **Production SLO definition, alert thresholds, incident response process** → `sre-engineer` (not yet a Cloudflare overlay; lean on protocol references).

## Advanced topics

### Workers Trace Events vs Workers Logs vs `wrangler tail`

| Tool | When |
|------|------|
| **`wrangler tail`** | Live, immediate; debugging a specific issue in real time |
| **Workers Logs (dashboard)** | After-the-fact, queryable, with retention; default for routine debugging |
| **Logpush `workers_trace_events`** | Streaming to external SIEM; required for long retention / compliance |

Workers Trace Events is the raw stream — every Worker invocation, every subrequest, every console log, every error. Logpush this dataset to S3 + Athena (or BigQuery, or Snowflake) when you need long retention or custom analytics.

### Workers Health Checks and notifications

Cloudflare Health Checks (zone-level) can be wired to Cloudflare Notifications, which can webhook out to PagerDuty / Slack / email. For Worker-specific alerts:

1. Define an "error rate" KPI via Analytics Engine (count of 5xx / count of all).
2. Set up a custom metric in Cloudflare or push to Datadog via Logpush.
3. Alarm threshold via dashboard or external monitoring.

There's no first-class "alert me when my Worker is throwing errors" UI in Cloudflare as of 2026-Q2 — you compose Health Checks + Notifications + Logpush + your SIEM.

### Deploys across multiple Cloudflare accounts

```yaml
# GitHub Actions matrix to deploy to multiple accounts
strategy:
  matrix:
    target:
      - { account: STAGING_ACCOUNT_ID, token: STAGING_TOKEN, env: staging }
      - { account: PROD_ACCOUNT_ID,    token: PROD_TOKEN,    env: production }
steps:
  - uses: cloudflare/wrangler-action@v3
    with:
      apiToken: ${{ secrets[matrix.target.token] }}
      accountId: ${{ secrets[matrix.target.account] }}
      command: deploy --env=${{ matrix.target.env }}
```

Don't try to "promote" by re-running the same job with different env vars — separate the jobs explicitly so audit trails are clear.

### Wrangler in a Devcontainer / Codespaces

Workers dev experience is well-suited to Codespaces:
- `wrangler dev` runs locally with Miniflare.
- `.dev.vars` loaded automatically.
- Port forwarding exposes local Worker to test from a browser.

Dockerfile snippet:
```dockerfile
FROM node:20-bullseye
RUN curl -fsSL https://github.com/cloudflare/cloudflared/releases/download/.../cloudflared-linux-amd64.deb -o cloudflared.deb && \
    dpkg -i cloudflared.deb
WORKDIR /workspace
```

`cloudflared` in the container makes Tunnel-tested apps trivial.

### Backups and restore

- **D1 time-travel** — built-in, 30 days, free. `wrangler d1 time-travel restore my-db --timestamp=...`. Verify this is enough for your RPO.
- **D1 export** — `wrangler d1 export my-db --output=backup.sql`. Cron this to push to R2 or external storage for paranoia / long retention.
- **R2 versioning** — enable per-bucket. Lifecycle rules for old versions.
- **KV** — there's no built-in backup. Export via `wrangler kv bulk get` if you need one; usually KV data is regeneratable.
- **DO state** — there's no point-in-time restore for DO SQLite as of 2026-Q2. If DO state is critical, mirror to D1 via a Queue.
- **Vectorize** — no built-in backup; re-embed from source data if needed.

### Compliance-friendly deploy logs

For SOC 2 / compliance: every deploy needs an audit trail. Cloudflare's `audit_logs` Logpush dataset captures account-level admin actions (including `wrangler deploy` via API token). Push to immutable storage (S3 with object lock).

Pair with GitHub Actions audit logs (who triggered the workflow, which commit, when) for end-to-end traceability.

### Pages → Workers Static Assets migration recipe

For an existing Pages project:

1. Add `[assets]` block to `wrangler.toml`:
   ```toml
   [assets]
   directory = "./dist"
   binding = "ASSETS"
   not_found_handling = "single-page-application"  # or "404-page" for SSG
   ```
2. Add a top-level `src/index.ts` Worker that serves through `env.ASSETS.fetch(request)`.
3. Move Pages Functions (`functions/api/*.ts`) into the Worker as route handlers in Hono.
4. Test `wrangler dev` locally; deploy to a staging Worker.
5. Cut over DNS / route from Pages project to the new Worker.
6. Decommission Pages project.

The migration guide on Cloudflare docs has version-specific details; consult before starting.

### Cloudflare-side IaC patterns

Module layout for Terraform:

```
infra/
├── modules/
│   ├── worker-service/        # Worker + D1 + KV + R2 + Queue bindings
│   ├── access-app/            # Cloudflare Access app + policy
│   ├── waf-base/              # standard WAF managed rulesets per zone
│   └── tunnel/                # Cloudflare Tunnel + config
├── envs/
│   ├── prod/main.tf
│   ├── staging/main.tf
│   └── dev/main.tf
└── shared/
    └── account.tf             # account-level config
```

Modules encapsulate "the right way to set up X." Envs compose modules. **Don't write per-env Terraform from scratch each time** — capture the org's standard via modules.

## Standing rules for devops-engineer on a Cloudflare engagement

1. **Wrangler v4 only.** `wrangler deploy`, not `publish`. Pin the version in `package.json`.
2. **`compatibility_date` on every project.** Pinned, documented, not silently bumped.
3. **Use `--env` for environments, not `if (env === ...)` branching.** One Worker per env.
4. **Secrets via `wrangler secret`, never `vars`.** Vars are visible in the dashboard.
5. **Use Versions for prod deploys.** Gradual rollout + easy rollback are not negotiable above hobby scale.
6. **Workers Logs on by default.** With sampling if volume justifies.
7. **Terraform for infra, Wrangler for the script.** Different cadences, different tools.
8. **API tokens scoped narrowly + rotated.** Per-purpose, per-env, 90-day rotation minimum.
9. **`wrangler types` regenerated and committed (or CI-verified).** Stale types lie about bindings.
10. **Rollback documented in the runbook.** Not "we'll figure it out when it breaks."
