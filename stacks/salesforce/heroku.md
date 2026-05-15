---
title: Heroku
description: Salesforce-owned PaaS. End-of-new-enterprise-sales February 2026. Recommend off-platform compute for net-new architecture.
product:
  name: Heroku
  stack: salesforce
  drift_risk: high
  last_verified_on: "2026-05-12"
  applies_to_roles: [system-architect, devops-engineer]
  authoritative_url: https://www.heroku.com/
  notes: "End-of-new-enterprise-sales Feb 2026; existing Heroku apps continue to function but new architecture should not bet on it."
---

<div class="etyb-currency-banner">Last verified: 2026-05-12 against Salesforce / Heroku 2026 announcements.</div>

## What it is

Heroku is the PaaS Salesforce acquired in 2010. As of **February 2026**, Salesforce ended new enterprise sales of Heroku. Existing Heroku apps continue to function; the product is not "shut down." But new architecture should not bet on Heroku.

Canonical reference: [Heroku](https://www.heroku.com/).

## When to use it (or rather, not)

**Do NOT recommend Heroku for:**

- New compute alongside Salesforce
- Net-new architecture that needs an "off-platform service" target
- Any 2026+ greenfield build

**Existing Heroku deployments:**

- Continue to function
- Are technical debt to plan migration away from
- Should be flagged whenever they appear in architecture reviews

**Use instead:**

- AWS Lambda / API Gateway
- GCP Cloud Run
- Azure Functions
- Or whichever cloud-native compute target fits the customer's existing stack

Called from Salesforce via [Named Credentials + External Credentials](/stacks/salesforce/external-client-apps/), or via [Salesforce-Hosted MCP](/stacks/salesforce/salesforce-hosted-mcp/) for agent-driven boundary crossing.

## 2025-2026 currency anchors

- **Heroku ended new enterprise sales February 2026.**
- Existing customers still supported; no announced shutdown date.
- The strategic platform recommendation for off-Salesforce compute is now **AWS / GCP / Azure**, called via Named Credentials.

## Patterns

If you inherit a Heroku deployment:

- **Audit the integration surface** — what Salesforce calls into Heroku, what Heroku calls back
- **Document the migration target** — typically Lambda / Cloud Run / Functions
- **Plan migration into the architecture roadmap**, not "we'll deal with it later"
- **Outbound LLM calls from Heroku apps are not Trust-Layer-covered** — flag as compliance gap. See [Einstein Trust Layer](/stacks/salesforce/einstein-trust-layer/).

## Anti-patterns

- **Recommending Heroku for net-new architecture.** Stale knowledge — end-of-new-enterprise-sales Feb 2026.
- **Building new integration patterns assuming Heroku continuity.**
- **Treating Heroku outbound LLM calls as Trust-Layer-covered.** They are not — Heroku apps are not Salesforce-resident.

## Gotchas

- **Heroku is still "Salesforce-owned"** but is no longer the strategic compute path. Don't confuse ownership with strategic position.
- **Salesforce Functions was retired** Jan 2025 — separate product, but the same "off-platform compute" gap. Stop proposing either for net-new. See [Salesforce Functions](/stacks/salesforce/salesforce-functions/).
- **Existing Heroku Postgres** databases tied to Heroku apps need a migration plan if you're moving the app.

## Cross-references

- Off-platform compute recommendation: [system-architect on Salesforce](/stacks/salesforce/system-architect/)
- Apex callouts to external compute via Named Credentials: [Apex](/stacks/salesforce/apex/), [External Client Apps](/stacks/salesforce/external-client-apps/)
- Retired sibling product: [Salesforce Functions](/stacks/salesforce/salesforce-functions/)
- Authoritative: [Heroku](https://www.heroku.com/)
