---
title: sf CLI
description: Salesforce's current command-line interface. Replaces deprecated sfdx alias; smart test selection added Spring '26.
product:
  name: sf CLI
  stack: salesforce
  drift_risk: medium
  last_verified_on: "2026-05-12"
  applies_to_roles: [devops-engineer, backend-architect, qa-engineer, saas-architect]
  authoritative_url: https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/
  notes: "sfdx is deprecated alias; new commands ship under sf only; topic/verb grammar changed."
---

<div class="etyb-currency-banner">Last verified: 2026-05-12 against Salesforce Spring '26.</div>

## What it is

`sf` is Salesforce's current command-line interface, used for deploying metadata, retrieving from orgs, running tests, managing scratch orgs, building packages, authenticating, querying, and analyzing code. `sfdx` is a deprecated alias — still functional, but new commands ship under `sf` only and the topic/verb grammar changed in 2024-2025 (`sf project deploy start`, not `sfdx force:source:deploy`).

Canonical reference: [sf CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/).

## When to use it

For any local-dev / CI / scripted Salesforce operation. The CLI is the headless backbone — DevOps Center and Gearset/Copado/AutoRABIT wrap it.

## 2025-2026 currency anchors

- **`sf` is the CLI; `sfdx` is a deprecated alias.** Topic/verb grammar changed.
- **Smart test selection on deploys** (Spring '26, GA) — Salesforce auto-selects Apex tests by the deployed components' dependency graph.
- **Salesforce Code Analyzer v5** (`sf scanner run`, `sf scanner run dfa`) bundles PMD, ESLint, RetireJS, Graph Engine, plus new flow-scanner rules.
- **Source format is the only sane choice.** MDAPI format and change sets are legacy.

## Plugins

| Plugin | Topic | Gives you |
|--------|-------|-----------|
| `@salesforce/plugin-deploy-retrieve` | `project deploy`, `project retrieve` | Source format push/pull, deploy validation |
| `@salesforce/plugin-packaging` | `package` | 2GP packaging — create, version, install, promote |
| `@salesforce/plugin-data` | `data` | Bulk import/export, query, tree, search |
| `@salesforce/plugin-org` | `org` | Org create (scratch), open, list, delete, login |
| `@salesforce/plugin-schema` | `schema` | Describe objects, list fields |
| `@salesforce/plugin-data-cloud` | `data-cloud` | Data 360 lakehouse ops |
| `@salesforce/sfdx-scanner` | `scanner` | Code Analyzer — PMD, ESLint, RetireJS, Graph Engine |
| `@salesforce/plugin-lightning-dev` | `lightning dev` | Local LWC/Aura preview |

Third-party that earns its keep: `@dxatscale/sfpowerscripts` (CI plumbing), `texei-sfdx-plugin` (data migration), `sfdx-hardis` (audit + release helpers). **Pin versions in CI.**

## Authentication flows

| Flow | Use it for | Headless? |
|------|------------|-----------|
| `sf org login web` | Developer laptops | No |
| `sf org login jwt` | CI/CD service accounts | Yes |
| `sf org login device` | Restricted machines, demos | Semi |
| `sf org login sfdx-url` | Bootstrap CI from a one-time URL | Yes |
| `sf org login access-token` | Short-lived, scoped automation | Yes |

CI uses JWT bearer against an [External Client App](/stacks/salesforce/external-client-apps/). Store the private key in your CI secrets manager; never commit the `.key` file.

## Core commands

| Command | What it does |
|---------|--------------|
| `sf project deploy start` | Push source to target org |
| `sf project deploy validate` | Validate-only deploy (no commit) — produces a Job ID for later quick-deploy |
| `sf project deploy quick` | Promote a previously validated job to a real deploy without re-running tests |
| `sf project retrieve start` | Pull from org back to source |
| `sf project deploy preview` | Show what would change without doing it |
| `sf project deploy report` | Query an in-flight deploy by Job ID |
| `sf project deploy resume` | Reconnect to a deploy that lost CLI session |
| `sf apex run test` | Run Apex tests |
| `sf scanner run` / `sf scanner run dfa` | Code Analyzer (PMD/ESLint/RetireJS) and Graph Engine DFA |
| `sf package version create` / `... promote` | 2GP packaging |
| `sf org create scratch` | Create a scratch org |
| `sf org list limits` | Query org limits API |

Source tracking lives under `.sf/orgs/<orgId>/` — **never commit `.sf/`**.

## Patterns

### Validate-then-quick-deploy (production)

```bash
# Stage 1 (pre-merge in CI): full validation against prod
JOB_ID=$(sf project deploy validate \
  --target-org prod \
  --test-level RunLocalTests \
  --json | jq -r '.result.id')

# Stage 2 (post-merge, manually approved): promote without re-running tests
sf project deploy quick --job-id "$JOB_ID" --target-org prod
```

Gives you a tested, repeatable promotion without a 90-minute re-test at the worst possible moment.

### Smart test selection (Spring '26)

```bash
# Let the platform pick by deploy contents
sf project deploy start \
  --target-org integration \
  --test-level RunLocalTests
```

Spring '26 inspects the deployed Apex classes' dependency graph and runs the minimal correct test set when smart selection is enabled. A 90-minute full suite collapses to 8 minutes on a 4-class change.

**Rules:**
- Smart selection on PR validation and incremental non-prod deploys.
- `RunLocalTests` on release candidates and prod deploys.
- `RunAllTestsInOrg` before major package version promotion.

### CI JWT auth

```bash
echo "$SF_JWT_KEY_BASE64" | base64 -d > server.key
sf org login jwt \
  --client-id "$SF_CLIENT_ID" \
  --jwt-key-file server.key \
  --username "$SF_USERNAME" \
  --instance-url "$SF_INSTANCE_URL" \
  --alias ci-target
```

### Scratch org create

```bash
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias feature-abc \
  --duration-days 14 \
  --set-default
```

### Org-limit health probe

```bash
sf org list limits --target-org prod --json \
  | jq '.result[] | select(.remaining * 1.0 / .max < 0.2) | {name, remaining, max}'
```

## Anti-patterns

- **`sfdx force:*` in new pipelines.** Deprecated alias with old verb grammar.
- **`sf project deploy start` against production from a laptop.** Production deploys go through CI artifact + quick-deploy.
- **Unpinned `sf` CLI in CI.** A floating `npm install --global @salesforce/cli` silently rolls over a breaking minor.
- **Connected App for new CI auth.** Use [External Client Apps](/stacks/salesforce/external-client-apps/) — Connected App creation blocked after May 11, 2026.
- **Change sets in 2026.** No diff, no audit, no version control.
- **Mixing source format and MDAPI format** in the same repo. Pick source format.
- **`sfdx force:mdapi:deploy`** for new pipelines.

## Gotchas

- **`.sf/` is local source-tracking state** — never commit.
- **JWT bearer requires an ECA-aligned setup** — server certificate, named principal, scoped permissions.
- **Smart test selection requires platform configuration:** Production needs Apex Settings → "Run Specified Tests with Smart Selection" toggled on.
- **Scratch org quotas are the bottleneck** in PR CI, not parallel time.

## Cross-references

- DevOps patterns: [devops-engineer on Salesforce](/stacks/salesforce/devops-engineer/)
- Auth surface: [External Client Apps](/stacks/salesforce/external-client-apps/)
- Test orchestration: [qa-engineer on Salesforce](/stacks/salesforce/qa-engineer/)
- Packaging: [AppExchange + Marketplace](/stacks/salesforce/appexchange-marketplace/), [saas-architect on Salesforce](/stacks/salesforce/saas-architect/)
- Authoritative: [sf CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/)
