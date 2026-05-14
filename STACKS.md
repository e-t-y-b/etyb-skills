# Stack Packs — Tech Stack Knowledge Overlays

ETYB is organized by **engineering role + business domain** (the 20 specialists + 9 protocols). Tech stacks like Salesforce, AWS, or SAP are not new roles — they are **knowledge overlays** that each role draws from when work involves that platform. This file is the registry of available Stack Packs.

## How Stack Packs work

1. **Detection.** ETYB's router (`skills/etyb/core/stack-registry.md`) watches the user's request for stack signals — keywords, product names, file extensions, error messages.
2. **Load briefing.** On a match, ETYB loads the stack's `SKILL.md` — a short orchestrator briefing for the whole team.
3. **Load role overlay.** When ETYB routes to a specific role (under `skills/etyb/references/specialists/<role>/` or `references/verticals/<role>/`), it also loads `stacks/<stack>/references/<role>.md` if one exists for that role.
4. **Compose with protocols and verticals.** Stack Packs do not replace the 9 always-on protocols (TDD, verification, debugging, etc.) — those still apply unchanged. They also defer to business-domain verticals (fintech, healthcare, etc.) for compliance and domain expertise; the pack only adds the *platform-specific* slice.

This means adding a new tech stack to ETYB does not bloat the roster — and never adds a new slash command. The trigger surface stays at `/etyb`; the knowledge surface grows by adding overlay folders.

Signature note: when a Stack Pack overlay is in play, ETYB signs responses as `ETYB · <role> · <stack>` (e.g., `ETYB · backend-architect · salesforce`) so the user knows which platform context shaped the answer.

## Available Stack Packs

| Stack | Version | Last Verified Release | Verified On | Tiers | Status |
|-------|---------|-----------------------|-------------|-------|--------|
| [Salesforce](stacks/salesforce/SKILL.md) | 4.0.0 | Spring '26 | 2026-05-12 | Core, Pro | Active — full coverage across all 11 roles (system / backend / frontend / ai-ml / database / devops / security / qa / saas / healthcare / fintech) |

## Roadmap (not yet shipped)

Candidate stacks for future iterations, in rough priority order based on common ETYB use cases:

- **AWS** — Bedrock, Lambda, EventBridge, ECS, IAM, S3, RDS/Aurora
- **GCP** — Vertex AI, Cloud Run, Pub/Sub, Firestore, BigQuery
- **Azure** — OpenAI Service, Functions, AKS, Entra ID, Cosmos DB
- **Vercel** — Next.js patterns, Edge Functions, Vercel AI SDK
- **Supabase** — Postgres + Auth + Realtime + Storage + Edge Functions
- **Snowflake** — Warehouse architecture, Native Apps, Cortex
- **Databricks** — Lakehouse, Mosaic AI, Delta Live Tables
- **Stripe** — Payment intents, Billing, Connect, fraud
- **Shopify** — Storefront API, Hydrogen, app development
- **SAP S/4HANA** — Integration patterns, BTP
- **ServiceNow** — Now Platform, Flow Designer, integration patterns

Stack Pack candidacy criterion: enough surface area + 2026-currency relevance that role-by-role overlays meaningfully change recommendations vs general-purpose knowledge. Niche or stable stacks may not warrant a Pack — a single reference file inside an existing role can suffice.

## Authoring a new Stack Pack

The Salesforce pack is the reference implementation. To add a new stack:

1. Create `stacks/<stack-name>/` at repo root with `SKILL.md` and `references/<role>.md` files per role the stack meaningfully changes.
2. Add the stack to `manifest.json` under the `stacks` section with version, `last_verified_release`, `verified_on`, `applies_to_roles`, `deferred_roles`.
3. Add a router entry to `skills/etyb/core/stack-registry.md` with the stack's detection signals.
4. Add a row to the **Available Stack Packs** table above.
5. Add a Stack Pack section to `MARKETPLACE.md` with a short pitch.
6. Open a PR — the maintainer review checks coverage, currency, and that always-on protocols + verticals are respected.

Conventions:
- Reference files match role names exactly (`backend-architect.md`, `ai-ml-engineer.md`, etc.) for predictable router-side loading.
- SKILL.md should declare `last_verified_release` and `verified_on` in YAML frontmatter; bump these on each release-currency review.
- Defer to business verticals for compliance — Stack Packs cover the platform surface, not domain regulation.
- Cross-link generously between role overlays so a reader landing in one finds the others.
