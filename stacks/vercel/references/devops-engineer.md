---
role: devops-engineer
stack: vercel
last_verified_on: "2026-05-14"
---

# Vercel Overlay — devops-engineer

You are devops-engineer on a Vercel engagement. "DevOps" on Vercel is mostly **deployment automation, environment hygiene, observability, monorepo tooling, and cost control** — Vercel runs the underlying infrastructure (which is AWS regions + Vercel's edge network), so the role shifts from "provision infra" to "shape the deployment loop." On a typical Vercel project, devops-engineer owns:

1. **The Git → Vercel pipeline** (branch protection, required checks, Preview Deployments).
2. **Environment variable + secret management** (per-environment scoping, Marketplace-wired vs manual, rotation).
3. **`vercel.json` configuration** (regions, function tiers, cron, headers, rewrites).
4. **Monorepo build optimization** (Turborepo + Remote Cache).
5. **Observability wiring** (Log Drains, Speed Insights, Web Analytics, OpenTelemetry).
6. **Marketplace integration governance** (which add-ons are installed, how they bill, who owns each).
7. **Cost monitoring + budget alerts** (Fluid Compute active CPU, Image Optimization transforms, KV/Blob/Postgres usage).
8. **Rollback + incident workflow** (instant rollback on Vercel; runbooks for partial outages).

**Currency:** Fluid Compute GA 2025 changed the cost model fundamentally; Turbopack stable for dev; Turbopack build rolling out; Marketplace consolidated vendor integrations in 2025; Speed Insights GA; Vercel REST API + CLI stable and actively iterated. Verify [vercel.com/changelog](https://vercel.com/changelog) and [vercel.com/docs/cli](https://vercel.com/docs/cli) for current details.

**Delegate first.** When the user's environment loads `vercel:vercel-cli`, `vercel:deployments-cicd`, `vercel:env-vars`, `vercel:turbopack`, or `deploy-to-vercel`, defer to them on product depth. This overlay is the cross-cutting devops framing.

## What's actually current in 2026

| Feature | Status | What it changes |
|---------|--------|-----------------|
| **Fluid Compute** | GA 2025 | Pricing model shifted to active CPU + in-instance concurrency; old GB-second math is wrong. |
| **Vercel REST API** | Stable | Programmatic deployments, env vars, project config, integrations. |
| **Marketplace** | Consolidated 2025 | Single install + billing pass-through for Stripe, Sentry, Datadog, Neon, Upstash, Resend, Inngest, etc. |
| **Speed Insights** | GA (out of beta) | RUM Core Web Vitals; INP is the headline metric. |
| **Log Drains** | Stable | Route logs to Datadog, Axiom, Better Stack, Logtail. |
| **`@vercel/otel`** | Stable | OpenTelemetry auto-instrumentation. |
| **Turbopack (dev)** | Default in Next.js 15+ | Fast HMR. |
| **Turbopack (build)** | Rolling out | `next build --turbopack`; verify before flipping prod. |
| **Turborepo + Remote Cache** | Stable | Monorepo build acceleration; remote cache shared across team + CI. |
| **Vercel for Git** | Stable | GitHub, GitLab, Bitbucket integrations; auto Preview Deployment per PR. |
| **Branch Protection (Vercel side)** | Stable | Preview password protection, deployment protection rules. |
| **Custom Domains** | Stable | Auto SSL, multi-domain per project, redirect chains. |
| **Deployment Comments** | Stable | Inline review on Preview URLs. |
| **`vercel.json` schema** | Stable | Rewrites/redirects/headers/cron/regions/functions. |
| **Production rollback** | Instant | One-click revert to previous deployment. |

## The deployment loop — what good looks like

```
Developer pushes → GitHub PR
        │
        ▼
   Vercel detects push → builds → Preview Deployment URL
        │
        ▼
   CI required checks run:
        - Lint + typecheck (pnpm lint, tsc --noEmit)
        - Unit tests (Vitest)
        - E2E against Preview URL (Playwright BASE_URL=<preview>)
        - Visual regression (Chromatic / Argos against previous deployment)
        - a11y check (axe in Playwright)
        - Speed Insights threshold check (if baseline is set)
        │
        ▼
   PR review: code review + Preview URL walkthrough + Comments
        │
        ▼
   Merge to main → production deploy (Vercel Git integration)
        │
        ▼
   Smoke test on production URL (Playwright @smoke tag)
        │
        ▼
   Speed Insights + Web Analytics watch first 24h; rollback gate
```

Configure this once; let it run for every PR.

## Branch protection + required checks

On the Git provider side (GitHub example):

- Require PR from feature branch → main.
- Require status checks to pass: `Vercel`, `lint`, `test`, `e2e`, `a11y`.
- Require at least 1 review approval.
- Dismiss stale approvals on new commits.
- Block force push to main.

On the Vercel side:

- **Deployment Protection** for Preview URLs: require Vercel auth or password for staging-sensitive previews. Default open for marketing; password for product. Vercel Auth (SSO via Vercel team membership) is the right choice for internal teams.
- **Production Branch:** `main` (or whatever the team uses). Only this branch deploys to production.
- **Skew protection:** Vercel can pin client → server versions so a client running on an older deployment doesn't call newer Server Actions; enable for high-traffic apps.

## Environment variables — the discipline

Vercel env vars come in **Production**, **Preview**, **Development** scopes:

- **Production**: only the prod deployment sees these.
- **Preview**: every PR/branch Preview Deployment.
- **Development**: pulled by `vercel env pull` into `.env.local` for local dev.

### Rules

1. **Never paste a production DB URL into Preview**. Either point Preview at a Preview-specific DB (Neon branching is the right answer), or accept that Preview has different data semantics.
2. **`NEXT_PUBLIC_*` is shipped to the browser.** Don't put secrets there.
3. **Sensitive vars (DB URLs, API keys) should be encrypted at rest**. They are by default; don't print them in logs.
4. **Document which vars are Marketplace-wired**. Stripe Marketplace creates `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, etc. — manually editing those breaks the integration's auto-rotation.
5. **Pin `NEXT_SERVER_ACTIONS_ENCRYPTION_KEY`** in prod (and Preview if you want stable Server Action IDs across deploys). Rotate intentionally.
6. **Rotation cadence**: API keys for non-Marketplace vendors should rotate every 90 days. Marketplace integrations handle this automatically.
7. **Backup the env config**: `vercel env pull --environment=production > prod.env` (then encrypt and store in 1Password / Vault) — protects against accidental deletion via dashboard.

### Per-environment patterns

```bash
# Local dev
vercel env pull .env.local
pnpm dev

# Add a new var
vercel env add MY_API_KEY production
vercel env add MY_API_KEY preview
vercel env add MY_API_KEY development

# Sensitive: encrypt before committing example env
vercel env pull .env.preview --environment=preview
```

### Marketplace env wiring

When you install Stripe Marketplace → Vercel auto-creates the keys + sets up the webhook. Don't edit the values; manage them through the Marketplace dashboard. If you remove the integration, the env vars get removed too.

Delegate to `vercel:env-vars` for current best practices.

## `vercel.json` — the production knobs

```jsonc
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "buildCommand": "pnpm build",
  "installCommand": "pnpm install --frozen-lockfile",
  "framework": "nextjs",
  "regions": ["iad1", "fra1", "syd1"],
  "functions": {
    "app/api/long-task/route.ts":   { "maxDuration": 300, "memory": 1024 },
    "app/api/ai/**/*.ts":           { "maxDuration": 60 },
    "app/api/webhooks/**/*.ts":     { "maxDuration": 30, "memory": 512 },
    "app/api/cron/**/*.ts":         { "maxDuration": 600 }
  },
  "crons": [
    { "path": "/api/cron/refresh-cache",  "schedule": "0 * * * *" },
    { "path": "/api/cron/nightly-report", "schedule": "0 3 * * *" }
  ],
  "rewrites": [
    { "source": "/api/legacy/:path*", "destination": "https://legacy.example.com/:path*" }
  ],
  "redirects": [
    { "source": "/old-blog/:slug", "destination": "/blog/:slug", "permanent": true }
  ],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Content-Type-Options",     "value": "nosniff" },
        { "key": "Referrer-Policy",            "value": "strict-origin-when-cross-origin" },
        { "key": "Permissions-Policy",         "value": "camera=(), microphone=(), geolocation=()" },
        { "key": "Strict-Transport-Security",  "value": "max-age=63072000; includeSubDomains; preload" }
      ]
    },
    {
      "source": "/api/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "no-store" }
      ]
    }
  ]
}
```

Devops-engineer essentials:

- **`regions`** is a deploy-time decision — pick regions close to your users *and* close to your storage. Multi-region with single-region Postgres is a latency trap.
- **`functions.<path>`** tunes per-route memory + duration. Don't blanket-set 800s on every route; it inflates worst-case cost and masks bad design.
- **`crons`** — keep the path namespace tidy (`/api/cron/*`); verify `CRON_SECRET` in every cron endpoint.
- **`rewrites`** run at the Edge Network — faster than middleware for static path mappings.
- **`headers`** — security headers (CSP, HSTS, X-Content-Type-Options, Permissions-Policy, Referrer-Policy) belong here.

CSP is its own discipline; if you have CSP-sensitive content, draft it iteratively from `report-only` first.

## Custom domains + SSL

- **Add domains via dashboard or CLI** (`vercel domains add example.com`).
- **SSL auto-issued** via Let's Encrypt; renews automatically.
- **DNS**: point CNAME or A record per Vercel docs. Use Vercel's nameservers for full DNS management, or your existing DNS provider with manual records.
- **Apex + www handling**: configure both with a permanent redirect to the canonical (usually apex → www or www → apex).
- **Subdomains**: support unlimited; each can map to a separate project or branch.
- **Wildcard SSL** for multi-tenant `*.example.com` apps; supported with DNS challenge.
- **Branch domains**: `staging.example.com` → branch `staging` mapping. One-time setup.

## Monorepo + Turborepo

Vercel auto-detects Turborepo projects. The pattern that scales:

```
my-monorepo/
├── apps/
│   ├── web/                  ← Next.js (deployed to Vercel)
│   ├── admin/                ← Next.js (deployed to Vercel)
│   └── docs/                 ← Next.js (deployed to Vercel)
├── packages/
│   ├── ui/                   ← shadcn components
│   ├── db/                   ← Drizzle schema + client
│   ├── auth/                 ← Auth.js config
│   ├── ai/                   ← AI SDK helpers
│   └── tsconfig/             ← Shared tsconfig presets
├── turbo.json
├── package.json
└── pnpm-workspace.yaml
```

### `turbo.json`

```jsonc
{
  "$schema": "https://turbo.build/schema.json",
  "globalDependencies": ["**/.env.*local"],
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "!.next/cache/**"]
    },
    "lint": {},
    "test": { "dependsOn": ["^build"], "outputs": ["coverage/**"] },
    "dev": { "cache": false, "persistent": true }
  }
}
```

### Remote Cache

Turborepo Remote Cache (free on Vercel) shares build artifacts across team + CI:

```bash
turbo link               # Link to Vercel for Remote Cache
turbo run build          # Local build hits cache from CI
```

This is *the* big win on monorepos. A CI build that took 5 minutes can drop to 30 seconds for an unchanged package.

### Per-app Vercel project

Each `apps/<x>` is a separate Vercel project. In Vercel dashboard → Project Settings:

- **Root Directory**: `apps/web` (or whichever).
- **Build Command**: `cd ../.. && turbo run build --filter=web`.
- **Install Command**: `pnpm install --frozen-lockfile`.
- **Output Directory**: `apps/web/.next`.
- **Ignored Build Step**: `npx turbo-ignore` — only deploys if the app or its deps changed.

### Monorepo Preview semantics

- Each app gets its own Preview URL per PR.
- Preview deploys all apps that changed (Ignored Build Step filters).
- Cross-app cookies/domains need explicit handling — `*.example.com` SSO; separate domains need separate auth.

## Build performance

The build-time levers, in order of impact:

1. **Turborepo Remote Cache** — huge on monorepos; modest on single-app.
2. **`turbo-ignore`** — skip builds for unchanged apps.
3. **Turbopack build** (when stable for your Next.js version) — `next build --turbopack`; verify before flipping prod.
4. **Reduce client bundle** — every dep that ships to the browser slows the cold load; audit with `@next/bundle-analyzer`.
5. **Server-only deps** — use `import 'server-only'` to ensure they don't leak into the client bundle.
6. **Static asset caching** — if you serve large static files, host on Blob with long Cache-Control; skip `next/image` for things that don't need transforms.
7. **Skip unused locales** — `next-intl` + only-needed-locales config drops bundle size.
8. **Skip dev-only deps in prod** — `peerDependencies` and `devDependencies` correctly classified.

## Observability — wiring it up

### Log Drains

Vercel dashboard → Project → Settings → Log Drains → Add. Destinations:

- **Datadog** (via Marketplace) — auto-wires.
- **Axiom** — popular for Next.js; cheap; SQL-style query.
- **Better Stack / Logtail** — friendly UI.
- **AWS CloudWatch / S3** — for compliance / long retention.
- **Splunk** — enterprise.

Log Drain payload includes runtime + build logs. Set up filtering on the destination side (don't ship every console.log to Datadog).

### OpenTelemetry

```ts
// instrumentation.ts (project root)
import { registerOTel } from '@vercel/otel';

export function register() {
  registerOTel({
    serviceName: 'web',
    // exporter via env: OTEL_EXPORTER_OTLP_ENDPOINT, OTEL_EXPORTER_OTLP_HEADERS
  });
}
```

Auto-instruments Server Actions, Route Handlers, fetch calls. Add Postgres/Redis client instrumentation manually if needed. Export to Datadog/Honeycomb/New Relic/Tempo.

### Speed Insights

```tsx
// app/layout.tsx
import { SpeedInsights } from '@vercel/speed-insights/next';
// ...
<SpeedInsights />
```

Real-user Core Web Vitals (LCP, INP, CLS, TTFB, FCP). Free tier limited; Pro removes cap. Surface in dashboard + via REST API for CI gating.

### Web Analytics

```tsx
import { Analytics } from '@vercel/analytics/next';
// ...
<Analytics />
```

Privacy-first first-party page views, referrers, devices. Not a product analytics replacement (PostHog, Amplitude, Mixpanel); good for traffic intuition.

### Alerting

- **Datadog Monitors** (Marketplace) — alert on log patterns, traces, custom metrics.
- **Better Stack Heartbeats** — uptime + cron heartbeats.
- **PagerDuty** (Marketplace) — escalation policy.
- **Vercel Notifications** (built-in) — deployment failures, threshold-based deployment alerts.

## Cost monitoring

Fluid Compute changed cost reasoning. The line items to watch in 2026:

1. **Function Invocations** — count of function executions.
2. **Function Active CPU** — actual CPU time (the new bill driver post-Fluid).
3. **Function Provisioned Memory** — memory tier × duration, sub-billed to active CPU.
4. **Edge Requests** — every HTTP request through the Edge Network.
5. **Edge Middleware Invocations** — separately tracked from function calls.
6. **Image Optimization Transforms** — per-source-image per-output-size; easy to blow.
7. **Cache Components storage + reads** — the new caching tier's own line.
8. **Data Transfer** — egress from Vercel to user (CDN + origin).
9. **Build Minutes** — CI build time billed when concurrent build limits exceeded.
10. **Marketplace pass-through** — Stripe, Sentry, Datadog, etc., bill via Vercel; Vercel's margin is implicit.

### Where teams overspend

- **Image Optimization explosions** — user-uploaded avatars at 4 sizes × 100 users = quickly into thousands of transforms.
- **Middleware bloat** — middleware runs on *every* matched request, including cached ones; expensive middleware × high traffic = surprise bill.
- **Bot traffic** — uncached pages getting hammered by scrapers; cache them or block via middleware.
- **Workflow loops** — a workflow that loops forever burns durable function time; add explicit max-iterations.
- **AI Gateway over-spend** — wrong model choice (Opus when Haiku would do); add per-prompt-cost monitoring.

### Cost defenses

- **Set spend caps** at the team level in Vercel dashboard.
- **Per-product budget alerts** via Vercel Notifications.
- **Bot mitigation**: Vercel offers WAF Pro tier; or use Cloudflare in front (composition).
- **Cache aggressively** with Cache Components + Edge Network; less compute = less bill.
- **Image budget**: tune `deviceSizes` + `imageSizes` in `next.config.ts`; consider Cloudflare Images for high-volume.
- **Track per-route active CPU**: spot N+1 queries before they scale.

## Marketplace integration governance

Marketplace consolidates vendor billing. Devops-engineer's job:

- **Audit which integrations are installed** quarterly. Uninstall what's unused.
- **Document each integration's purpose + owner** in the repo (e.g., `INTEGRATIONS.md`).
- **Know which env vars are auto-wired** vs manual.
- **Watch the consolidated bill** — Marketplace pass-through with Vercel's margin can hide cost growth.
- **For mature/large teams**, evaluate moving high-volume integrations to direct vendor billing (Datadog at enterprise scale is cheaper direct; Stripe is the same price; depends).
- **Marketplace + multi-environment**: confirm the integration supports separate dev/preview/prod credentials (most do).

Common installs:

| Integration | What it does | Watch for |
|-------------|--------------|-----------|
| **Stripe** | Auto-wires keys + webhook URLs | Single Stripe account per Vercel project; multi-env needs Stripe restricted keys per env |
| **Neon Postgres** | Provisions Postgres with branching per Preview | Bill at-rest + per-compute-second; tune autosuspend |
| **Upstash Redis (KV)** | Provisions Redis | Per-command pricing; cache hit rate matters |
| **Sentry** | Error tracking | Auto-source-map upload; sample rate controls cost |
| **Datadog** | Logs + traces + metrics | Volume-based; aggressive filtering at source |
| **Resend** | Transactional email | Domain verification per-environment |
| **Inngest** | Event-driven workflows | Alternative to Vercel Workflow for some use cases |
| **Pinecone / Upstash Vector** | Vector DB for RAG | Index dimensions + size; pre-plan |
| **PostHog / LogSnag** | Product analytics | Event-based pricing |
| **Better Stack** | Uptime + status pages | Heartbeats for crons |
| **Statsig / LaunchDarkly** | Feature flags (mirrored to Edge Config) | Reads from Edge Config are sub-15ms globally |
| **WorkOS** | Enterprise SSO/SCIM | Auto auth config |

## Preview Deployment patterns

### Comments + Toolbar

Preview URLs ship with Vercel Toolbar (when authenticated to the team):

- **Comments** — leave inline feedback on specific page elements. Threaded discussions per element. Resolved/unresolved status.
- **Inspect** — see Speed Insights real-user data (if anyone's hit the Preview).
- **Edit Mode** — for marketing pages, quick text edits inline.
- **Open in v0** — send the page to v0 for AI-iteration.

Train designers + PMs to use Comments; it's massively faster than Loom/email/Figma roundtrips.

### Preview-specific env

Common patterns:

- **Preview DB**: Neon branching gives every Preview its own DB branch (rebased from main on creation). Configure via Neon Vercel integration.
- **Preview auth**: shorter session cookies; OAuth callback URLs include the Preview URL pattern (Vercel auto-substitutes `VERCEL_URL` in env vars when configured).
- **Preview feature flags**: Statsig/LaunchDarkly support per-env flag values.

### Preview password protection

For client-review previews that need to be private but not behind SSO:

- **Vercel Auth**: require Vercel team login (free with team).
- **Password Protection**: single shared password per project (Pro+).
- **Sharable Preview URLs**: time-limited, password-less; useful for external stakeholders.

## Rollback + incident workflow

Vercel rollback is one-click — promote a previous deployment to production from the dashboard or `vercel promote <url> --prod`. Use it.

### Runbook template

1. **Detection**: alert fires (error rate spike, latency spike, deployment failure).
2. **Triage**: confirm scope — single function? all functions? cache layer? upstream (Stripe, Anthropic, Neon)?
3. **Rollback (if recent deploy correlates)**: promote the last green production deployment immediately. Don't debug forward.
4. **Communicate**: status page (Better Stack or your own); customer comms if public-facing.
5. **Diagnose**: function logs, traces, Speed Insights, third-party status (Vercel, Neon, Stripe, Anthropic).
6. **Fix-forward**: PR with the fix; Preview; merge.
7. **Postmortem**: 24-72h timeline; root cause; preventive measures; share with team.

### Vercel-side incidents

- **[vercel-status.com](https://www.vercel-status.com/)** — platform health.
- **Subscribe to status updates** via email/Slack.
- **Have a contingency for full Vercel outage**: rare, but a global edge incident in 2025 reminded everyone that single-vendor frontend = single point. Keep DNS at a different provider (Cloudflare); have a "emergency static fallback" page that can be served from Cloudflare R2 / S3 if needed.

## Security baseline

Devops-engineer ships these in every project:

- [ ] Security headers in `vercel.json` (CSP, HSTS, X-Content-Type-Options, Permissions-Policy, Referrer-Policy).
- [ ] HTTPS everywhere (Vercel default; verify no http:// links in code).
- [ ] CSP starts as `report-only`; tighten over time.
- [ ] Env vars are scoped per environment.
- [ ] Production secrets are Marketplace-wired or rotated quarterly.
- [ ] Server Action encryption key is pinned in production.
- [ ] CRON endpoints verify `Authorization: Bearer ${CRON_SECRET}`.
- [ ] No `.env*` files committed.
- [ ] Dependabot / Renovate enabled.
- [ ] WAF Pro tier or Cloudflare in front for bot mitigation.
- [ ] Preview deployments are password-protected for product/admin apps.
- [ ] SOC 2 / GDPR (if applicable) — verify Vercel's compliance status + region pinning.
- [ ] Log redaction rules at the Log Drain destination for PII.

## Patterns and anti-patterns

### Pattern: GitHub Actions for CI, Vercel for deploy

Vercel handles the build + deploy. GitHub Actions runs the *quality gates*: lint, typecheck, unit tests, E2E against Preview URL, visual regression, a11y. The deploy is gated on CI passing (branch protection requires it).

```yaml
# .github/workflows/ci.yml
name: CI
on: [pull_request]
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v3
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'pnpm' }
      - run: pnpm install --frozen-lockfile
      - run: pnpm lint
      - run: pnpm typecheck
      - run: pnpm test
      - name: Wait for Preview
        id: vercel
        uses: patrickedqvist/wait-for-vercel-preview@v1.3.1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          max_timeout: 300
      - name: E2E
        run: pnpm exec playwright test
        env:
          BASE_URL: ${{ steps.vercel.outputs.url }}
```

### Pattern: Ephemeral per-PR DB

Neon's Vercel integration creates a DB branch per Preview Deployment. Set in Neon: "Create branch on Preview". The branch inherits the schema and (optionally) some seed data. Cleans up on PR close. This makes Preview environments *actually* useful — they can test migrations safely.

### Pattern: Smoke tests on production after deploy

After production deploy, run a Playwright `@smoke` tag against the production URL — critical-path flows only (login, key user action, payment). Alert + rollback if smoke fails.

```yaml
# .github/workflows/post-deploy.yml
on:
  deployment_status:
jobs:
  smoke:
    if: github.event.deployment_status.state == 'success' && github.event.deployment.environment == 'production'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pnpm install --frozen-lockfile
      - run: pnpm exec playwright test --grep @smoke
        env:
          BASE_URL: https://example.com
```

### Anti-pattern: Single shared "staging" with production data

Vercel's Preview model assumes ephemeral. Maintaining a long-lived `staging.example.com` with prod data is doable but fights the platform. Prefer: ephemeral Previews + a thin `staging` environment with synthetic data for QA.

### Anti-pattern: Deploying main without CI gates

"Vercel deployed; therefore it's good" is wrong. Vercel deploys *what compiles*. CI is what proves it *works*. Branch protection + required checks are mandatory.

### Anti-pattern: Marketplace install without ownership

If no one owns a Marketplace integration, it accumulates cost and breaks silently. Document ownership in `INTEGRATIONS.md`.

### Anti-pattern: Production prod-env in `.env.local`

`vercel env pull` to local dev pulls **Development** env by default. If you `--environment=production` to debug, *delete the file after*. Don't commit, don't leave around.

### Anti-pattern: One Vercel project for many apps

In a monorepo, every app should be a separate Vercel project. Sharing one project across `apps/web` + `apps/admin` makes builds, env vars, and rollbacks miserable.

### Anti-pattern: Custom domains pointing at multiple projects

A domain can only resolve to one Vercel project at a time. Trying to "share" `app.example.com` across staging + prod projects breaks both. Use `staging.example.com` for staging.

## Tooling specifics

| Tool | Use |
|------|-----|
| `vercel` CLI | Deployments, env vars, logs, secrets, project linking. |
| `vercel dev` | Local emulator. |
| `vercel deploy` | Manual deploy (CI integration is preferred). |
| `vercel logs <deployment-url>` | Live function logs. |
| `vercel env pull/add/rm` | Env var management. |
| `vercel link` | Link local repo to Vercel project. |
| `vercel promote <url> --prod` | Promote deployment to production (rollback or roll forward). |
| `vercel rollback` | Roll back to previous production. |
| `turbo` | Monorepo task runner. |
| `turbo-ignore` | Per-app Vercel build skip. |
| `pnpm` / `bun` | Recommended package managers. |
| `@vercel/otel` | OpenTelemetry. |
| `@vercel/speed-insights` | RUM. |
| `@vercel/analytics` | First-party analytics. |
| `@next/bundle-analyzer` | Bundle size audit. |
| `lighthouse` / `unlighthouse` | Synthetic CWV; pair with RUM for full picture. |
| `playwright` | E2E + smoke. |
| `chromatic` / `argos` | Visual regression. |
| `dependabot` / `renovate` | Dep updates. |
| `gh` CLI | GitHub workflow scripting. |
| `vercel-secrets-rotator` or similar | Periodic rotation of non-Marketplace keys. |

## Cross-references

- **`vercel:vercel-cli`** — CLI command depth; delegate.
- **`vercel:deployments-cicd`** — CI/CD patterns; delegate.
- **`vercel:env-vars`** — env var patterns; delegate.
- **`vercel:turbopack`** — Turbopack config; delegate.
- **`deploy-to-vercel`** — one-shot deploy; delegate when active.
- **`references/system-architect.md`** — when Vercel is the whole platform vs not.
- **`references/backend-architect.md`** — Function tiering, Workflow, Queues, env-var usage in app code.
- **`references/ai-ml-engineer.md`** — AI Gateway env vars, AI SDK observability.

## Integration with always-on protocols

- **TDD on the devops layer:** infrastructure-as-config-as-code means `vercel.json` and CI workflows are reviewable, diffable, testable artifacts. Treat changes to them like code changes — PR, review, Preview test.
- **Verification:** before claiming a deploy/infra change works, verify (a) Preview URL builds + runs, (b) CI passes, (c) post-deploy smoke runs green, (d) Speed Insights doesn't regress, (e) cost dashboards don't show anomaly post-merge.
- **Debugging:** the debug stack — Vercel function logs → Speed Insights metrics → Log Drain (Datadog/Axiom) → OTel traces → external service status pages (vercel-status, Neon status, Stripe status). Always check Vercel status first; many "our app is broken" issues are platform-side.
- **Plan execution:** for infra migration (e.g., flipping to Turbopack build, adding a new Marketplace integration, region change): plan → Preview deploy → smoke → measure → merge → monitor 24h. Don't roll an infra change to prod on a Friday.
- **Branch safety:** required checks on PR, Vercel skew protection on, prod-branch-only deploy. Rollback is one click; have the muscle memory.
- **Review:** every `vercel.json` change, every CI workflow change, every Marketplace install/uninstall gets PR review — not "I'll just tweak it in the dashboard." Configuration drift between dashboard and repo is a real source of incidents.

## Quick reference: the 2026 devops-engineer checklist

Every Vercel project should have these in place:

- [ ] Vercel project linked to Git repo with auto Preview Deployments.
- [ ] Branch protection on main with required CI checks.
- [ ] Production branch set explicitly; only main deploys to prod.
- [ ] Env vars scoped per environment; sensitive ones encrypted/Marketplace-wired.
- [ ] `vercel.json` with regions, function tiers, cron, security headers.
- [ ] Per-route `maxDuration` + `memory` set for known-long routes.
- [ ] Security headers (CSP, HSTS, X-Content-Type-Options, Permissions-Policy, Referrer-Policy).
- [ ] OTel registered in `instrumentation.ts`.
- [ ] Log Drain configured to a long-retention destination.
- [ ] Speed Insights + Web Analytics components in root layout.
- [ ] Marketplace integrations documented in `INTEGRATIONS.md` with owners.
- [ ] Cost alerts set at team level.
- [ ] Bot mitigation (Vercel WAF Pro or Cloudflare in front).
- [ ] Preview password protection or Vercel Auth for sensitive Previews.
- [ ] Smoke test workflow on post-deploy.
- [ ] Rollback runbook documented; team has practiced it.
- [ ] Dependabot/Renovate active.
- [ ] Status page (Better Stack or similar) for customer visibility.
- [ ] Quarterly review of installed Marketplace integrations + cost trends.
- [ ] DNS hosted at a separate provider from Vercel (or have explicit "Vercel outage" contingency).
