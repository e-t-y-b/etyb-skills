---
title: Vercel CLI
description: "`vercel` — deployments, env vars, logs, secrets, project linking. The local-to-platform interface for the deployment loop."
product:
  name: Vercel CLI
  stack: vercel
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer, frontend-architect, backend-architect]
  authoritative_url: https://vercel.com/docs/cli
  notes: "Stable. Commands evolve modestly. The `vercel` CLI is the workhorse; `v0` CLI is a separate, newer tool covered separately."
---

## What it is

The Vercel CLI is the command-line interface for the platform: deploy projects, manage env vars, stream logs, link local repos to projects, promote/rollback deployments. See [vercel.com/docs/cli](https://vercel.com/docs/cli).

## When to use

- **Local development emulation** — `vercel dev` runs the platform emulator (Functions, `vercel.json` rewrites/headers, cron).
- **Env var sync** — `vercel env pull` pulls remote env into `.env.local`; `vercel env add` adds new.
- **Manual deploys** — `vercel deploy` for one-offs; CI integration via Git is the usual path.
- **Log streaming** — `vercel logs <deployment-url>` for live function logs.
- **Project linking** — `vercel link` connects a local repo to a Vercel project.
- **Rollback** — `vercel promote <url> --prod` or `vercel rollback`.

CI/CD deployment usually flows through the Git integration (push → Preview, merge → prod) — the CLI is for the surrounding workflow.

## 2025-2026 currency anchors

- **Stable surface.** Commands evolve modestly; current syntax in [vercel.com/docs/cli](https://vercel.com/docs/cli) is the reference.
- **`vercel dev`** runs the full local emulator — useful for testing `vercel.json` rewrites and Functions outside Next.js.
- **`vercel env pull`** pulls Development env by default; `--environment=production` for prod (use carefully — don't commit, don't leave around).
- **`vercel promote`** promotes any past deployment to production — instant rollback or roll-forward.

## Key commands

| Command | Use |
|---------|-----|
| `vercel` (alias `vc`) | Deploy current directory (creates a Preview by default). |
| `vercel --prod` | Deploy directly to production (CI Git integration is preferred). |
| `vercel link` | Link the current dir to a Vercel project. |
| `vercel dev` | Local emulator. |
| `vercel env pull [file]` | Sync env into local file. |
| `vercel env add <name> <env>` | Add a new env var (production/preview/development). |
| `vercel env rm <name> <env>` | Remove an env var. |
| `vercel logs <deployment>` | Live function logs. |
| `vercel promote <url> --prod` | Promote a deployment to production. |
| `vercel rollback` | Roll back to previous production. |
| `vercel domains` | Manage custom domains. |
| `vercel teams` | Team management. |
| `vercel projects` | Project listing + config. |

## Patterns + anti-patterns

**Pattern: `vercel env pull` after Marketplace install.** When you install Stripe / Neon / Upstash via Marketplace, the env vars are created on Vercel — pull them into `.env.local` to dev against the same values.

**Pattern: `vercel link` immediately after cloning a repo.** Connects your local checkout to the project so subsequent `vercel` commands target the right deployment context.

**Pattern: `vercel promote` for instant rollback.** Identify the last green deployment URL; promote it. No "redeploy old commit" round-trip.

**Anti-pattern: `vercel --prod` from a developer's laptop.** Production deploys should flow through the Git integration with required CI checks. Manual prod deploys bypass branch protection.

**Anti-pattern: Committing `.env.local` after `vercel env pull --environment=production`.** Sensitive data. Delete the file after debugging.

**Anti-pattern: `vercel logs` as the only observability.** Live logs are great for debugging; persist them via Log Drains for retention + searchability.

## Gotchas

- **`vercel dev` is not identical to production.** It's the closest emulator; certain edge behaviors only manifest in actual deploys (especially Edge runtime).
- **Token-based auth** — `vercel login` writes credentials; in CI, use a Vercel token + `--token` flag.
- **Default `vercel deploy` is Preview** — needs `--prod` for production (when bypassing the Git flow).
- **`vercel env pull --environment=production` outputs sensitive data** to disk; treat the file like a secret.

## Cross-references

- [Vercel Functions](/stacks/vercel/vercel-functions/) — what `vercel dev` emulates
- [Marketplace](/stacks/vercel/marketplace/) — env vars Marketplace-wires
- [v0](/stacks/vercel/v0/) — separate CLI
- [devops-engineer on Vercel](/stacks/vercel/devops-engineer/) — full deployment loop
- Authoritative: [CLI docs](https://vercel.com/docs/cli)
- Delegate: `vercel:vercel-cli`, `deploy-to-vercel`, `vercel:env-vars`
