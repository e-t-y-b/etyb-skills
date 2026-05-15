---
title: Wrangler CLI
description: "Cloudflare's CLI for Worker dev, deploy, types, secrets, tail, and binding management — v4 is current, `wrangler deploy` is canonical (not `publish`)."
product:
  name: Wrangler CLI
  stack: cloudflare
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, backend-architect]
  authoritative_url: https://developers.cloudflare.com/workers/wrangler/commands/
  notes: "Major v4 line; flag/command names mutate per minor release; deploys, dev modes, secret bulk, observability commands all changed in 2025."
---

## What it is

Wrangler is the official CLI for Cloudflare Workers — local dev (via [Miniflare](https://developers.cloudflare.com/workers/testing/miniflare/) under the hood), bundle, deploy, type generation, secret management, log tailing, and binding-level CRUD for [D1](/stacks/cloudflare/d1/), [KV](/stacks/cloudflare/kv/), [R2](/stacks/cloudflare/r2/), [Queues](/stacks/cloudflare/queues/), [Vectorize](/stacks/cloudflare/vectorize/), and [Hyperdrive](/stacks/cloudflare/hyperdrive/). Configuration lives in `wrangler.toml` (or `wrangler.jsonc`).

Authoritative reference: [developers.cloudflare.com/workers/wrangler/commands](https://developers.cloudflare.com/workers/wrangler/commands/).

## When to use

- All Worker dev/deploy operations. Pin Wrangler to a known-good version in `package.json` (`"wrangler": "^4.x.x"`); **don't install globally**.
- Manage bindings (D1, KV, R2, Queues, Vectorize, Hyperdrive) from the CLI rather than dashboard for repeatability.
- Generate TypeScript types from your bindings (`wrangler types`).
- Tail logs in real time (`wrangler tail`).

Don't use Wrangler for infrastructure beyond the script — for zones, custom domains, WAF rulesets, Access policies, use Terraform / Pulumi (different cadences = different tools).

## 2025-2026 currency anchors

- **`wrangler deploy`** replaced **`wrangler publish`** mid-v3; `publish` prints a deprecation warning and may stop working. If you see code recommending `publish`, it's stale.
- **`wrangler types`** generates `worker-configuration.d.ts` with the full `Env` interface — run after every `wrangler.toml` change.
- **`wrangler secret bulk`** for batch rotation; don't loop `secret put`.
- **`wrangler versions upload` / `versions deploy`** is the canonical primitive for prod deploys with gradual rollout.
- **`wrangler.jsonc`** has been supported since 2024 — preferable for teams that already lint/format JSON or want IDE schema validation.
- **Wrangler v2** is obsolete; **v1** can't deploy modern Workers. Reject any project starting fresh on these.

## Wrangler v4 daily-use commands

### Dev

```bash
wrangler dev                            # Miniflare local
wrangler dev --remote                   # local code, remote bindings
wrangler dev --env staging              # use staging config
wrangler dev --inspect                  # Chrome DevTools support
```

### Deploy

```bash
wrangler deploy
wrangler deploy --env production
wrangler deploy --dry-run --outdir=dist  # CI: build without deploying
wrangler deploy --keep-vars              # preserve env vars from prior deploy
wrangler delete --name=worker-name
```

### Versions and gradual rollouts

```bash
wrangler versions upload                  # builds and uploads, no traffic
wrangler versions list
wrangler versions deploy <id>@100%         # deploy this version
wrangler versions deploy <a>@10% <b>@90%   # canary split
```

Treat **Versions** as the deploy primitive for production. Rollback by `versions deploy <previous-id>@100%`.

### Secrets

```bash
wrangler secret put NAME [--env=staging]
wrangler secret bulk file.json [--env=staging]
wrangler secret list
wrangler secret delete NAME
```

### Types

```bash
wrangler types                            # writes worker-configuration.d.ts
wrangler types --x-include-runtime         # include runtime types
```

### Logs

```bash
wrangler tail                              # live tail
wrangler tail --format=pretty
wrangler tail --status=error
wrangler tail --search="user_id=42"
```

### D1

```bash
wrangler d1 create NAME
wrangler d1 execute NAME --command="SELECT 1" [--remote]
wrangler d1 migrations create NAME description
wrangler d1 migrations apply NAME [--remote]
wrangler d1 export NAME --output=backup.sql
wrangler d1 time-travel restore NAME --timestamp=...
```

### R2 / KV / Queues / Vectorize / Hyperdrive

```bash
# R2
wrangler r2 bucket create NAME
wrangler r2 object put NAME/key --file=./local

# KV
wrangler kv namespace create NAME
wrangler kv key put --binding=BINDING my-key "value"

# Queues
wrangler queues create NAME
wrangler queues consumer add NAME WORKER

# Vectorize
wrangler vectorize create NAME --dimensions=1024 --metric=cosine
wrangler vectorize create-metadata-index NAME --property-name=tenant --type=string

# Hyperdrive
wrangler hyperdrive create NAME --connection-string="postgres://..."
```

## `wrangler.toml` vs `wrangler.jsonc`

Both supported. JSONC (since 2024) is preferable for teams already linting/formatting JSON and wanting IDE schema validation. TOML is fine. Pick one per repo; don't mix.

## Patterns

### Project bootstrap

```bash
npm create cloudflare@latest -- my-worker --type=hello-world --ts --git --deploy=false
npm create cloudflare@latest -- my-api --framework=hono
npm create cloudflare@latest -- my-site --framework=astro
```

C3 (create-cloudflare) is the official bootstrap.

### CI gates

```yaml
- name: Generate Workers types
  run: npx wrangler types
- name: Type check
  run: npx tsc --noEmit
- name: Test
  run: npm test
- name: Build (dry-run)
  run: npx wrangler deploy --dry-run --outdir=dist
```

`wrangler deploy --dry-run --outdir=dist` is the secret weapon for CI — builds the Worker, writes the bundle, surfaces bundle size, no deploy-quota slot consumed. Run on every PR.

### Multi-env via `--env`

Use `--env staging` / `--env production`. Don't share a Worker across environments via `if (env.ENV === "prod")` branching — bindings differ, deploys differ, secrets differ.

## Anti-patterns

- **`wrangler publish`** — deprecated; use `deploy`.
- **`wrangler` installed globally** — version drift across projects, breaking-flag changes hit you silently. Pin per project.
- **`latest` in CI** for Wrangler — Wrangler ships breaking flag changes occasionally. Pin to `^4.x.x`.
- **Secrets in `[vars]`** — visible in dashboard and deploy logs. Use `wrangler secret`.
- **Manually committing `worker-configuration.d.ts` only on some PRs** — either commit consistently or `wrangler types && tsc` in CI on every job.

## Gotchas

1. **`wrangler dev` ≠ `wrangler dev --remote`.** Local uses Miniflare (SQLite for D1, in-memory KV); remote uses production bindings. Both produce the same Worker but with different binding fidelity.
2. **`wrangler types` is mandatory after every `wrangler.toml` change.** Stale types lie about bindings.
3. **`wrangler.toml` config errors are caught at deploy time, not edit time.** Run `wrangler deploy --dry-run` to surface them in CI.
4. **API tokens** scope-narrowly: don't share one token across all CI. Per-purpose, per-env, 90-day rotation.

## Cross-references

- [Workers](/stacks/cloudflare/workers/) — runtime context Wrangler deploys to
- [D1](/stacks/cloudflare/d1/), [KV](/stacks/cloudflare/kv/), [R2](/stacks/cloudflare/r2/), [Queues](/stacks/cloudflare/queues/), [Vectorize](/stacks/cloudflare/vectorize/), [Hyperdrive](/stacks/cloudflare/hyperdrive/) — bindings managed via Wrangler
- [Workers Logs](/stacks/cloudflare/workers-logs/) — `wrangler tail` is the live view; Logs is the queryable persistent view
- Role overlay: [devops-engineer on Cloudflare](/stacks/cloudflare/devops-engineer/)
- Authoritative: [developers.cloudflare.com/workers/wrangler/commands](https://developers.cloudflare.com/workers/wrangler/commands/), [compatibility dates](https://developers.cloudflare.com/workers/configuration/compatibility-dates/)
