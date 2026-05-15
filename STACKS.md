# Stack Packs — Vendor Knowledge Registry

ETYB is organized by **engineering role + business domain** (20 specialists + 9 protocols + 6 verticals). Vendor-specific knowledge — what Cloudflare's Wrangler CLI does today, what Salesforce Agentforce features ship in Spring '26, what Vercel AI Gateway supports — lives in **Stack Packs**. Each Stack is the vendor knowledge registry for one platform: timestamped, sourced, delegation-aware.

Stack Packs are not new roles. They are context overlays applied across the existing references. The trigger surface stays at `/etyb`; the knowledge surface grows by adding Stack folders.

## How Stack Packs work (v2 schema, v4.0.0)

1. **Detection.** ETYB's router (`skills/etyb/core/stack-registry.md`) watches the user's request for stack signals — keywords, product names, file extensions, CLIs, error messages.
2. **Load briefing.** On a match, ETYB loads the Stack's `SKILL.md` — a short orchestrator briefing for the whole team plus the v2 metadata block (currency timestamp, authoritative sources, products covered, vendor-skill delegation).
3. **Delegation check.** If the Stack's `delegate_to_skills` lists a vendor MCP or skill that's installed in the user's environment, ETYB defers to it for matching products. The vendor's own surface knows current state better than the Stack overlay.
4. **Role overlay.** When ETYB routes to a specific role, it also loads `stacks/<stack>/references/<role>.md` if one exists. The role uses the overlay *in addition to* its own README, not in place of it.
5. **Drift-check protocol.** Before committing to vendor-specific specifics (versions, API signatures, CLI flags, compliance deadlines), ETYB applies the drift-check protocol from `skills/etyb/core/knowledge-currency.md` — soft path (disclose currency + cite source) by default, strict path (refuse without fresh fetch or delegate) for high-stakes or stale-high-drift claims.
6. **Composition.** Stack Packs don't replace the 9 always-on protocols (TDD, verification, debugging, etc.) — those apply unchanged. They defer to business-domain verticals (fintech, healthcare, etc.) for compliance and domain expertise; the pack covers the *platform-specific* slice.

Signature note: when a Stack Pack overlay is in play, ETYB signs responses as `ETYB · <role> · <stack>` (e.g., `ETYB · backend-architect · cloudflare`) so the user knows which platform context shaped the answer. The signature block also surfaces the Stack's `last_verified_on` date.

## Available Stack Packs

| Stack | Version | Last Verified | Drift Risk | Status |
|-------|---------|---------------|------------|--------|
| [Salesforce](stacks/salesforce/SKILL.md) | 4.0.0 | Spring '26 (2026-05-12) | High on Agentforce/Data 360; low on Hyperforce/Health Cloud | Active |
| [AWS](stacks/aws/SKILL.md) | 4.0.0 | 2026-05-14 | High on Bedrock; medium on Lambda/ECS/Aurora | New in v4.0.0 |
| [GCP](stacks/gcp/SKILL.md) | 4.0.0 | 2026-05-14 | High on Vertex AI; medium on Cloud Run/BigQuery | New in v4.0.0 |
| [Azure](stacks/azure/SKILL.md) | 4.0.0 | 2026-05-14 | High on Azure OpenAI; medium on AKS/Entra | New in v4.0.0 |
| [Anthropic Claude](stacks/anthropic-claude/SKILL.md) | 4.0.0 | 2026-05-14 | High on Agent SDK + Claude API features | New in v4.0.0 |
| [OpenAI](stacks/openai/SKILL.md) | 4.0.0 | 2026-05-14 | High across Assistants + Responses API | New in v4.0.0 |
| [Cloudflare](stacks/cloudflare/SKILL.md) | 4.0.0 | 2026-05-14 | High on Workers/Vectorize/AI Gateway; low on KV | New in v4.0.0 |
| [Vercel](stacks/vercel/SKILL.md) | 4.0.0 | 2026-05-14 | High on AI Gateway + Next.js | New in v4.0.0 |
| [Supabase](stacks/supabase/SKILL.md) | 4.0.0 | 2026-05-14 | Medium across products | New in v4.0.0 |
| [Firebase](stacks/firebase/SKILL.md) | 4.0.0 | 2026-05-14 | High on Genkit + AI Logic; medium elsewhere | New in v4.0.0 |
| [Expo](stacks/expo/SKILL.md) | 4.0.0 | 2026-05-14 | High on EAS + New Architecture | New in v4.0.0 |
| [Stripe](stacks/stripe/SKILL.md) | 4.0.0 | 2026-05-14 | Medium across products | New in v4.0.0 |
| [Observability](stacks/observability/SKILL.md) | 4.0.0 | 2026-05-14 | Medium per-vendor | New in v4.0.0 (multi-vendor: Datadog, New Relic, Grafana, Prometheus, Splunk) |

## Roadmap (not yet shipped)

Candidate stacks for future iterations:

- **Snowflake** — Warehouse architecture, Native Apps, Cortex
- **Databricks** — Lakehouse, Mosaic AI, Delta Live Tables
- **dbt** — Modeling, tests, semantic layer
- **Shopify** — Storefront API, Hydrogen, app development
- **SAP S/4HANA** — Integration patterns, BTP
- **ServiceNow** — Now Platform, Flow Designer, integration patterns
- **Twilio** — Voice, SMS, Verify, Segment
- **Auth providers** — Auth0, Okta, Clerk, WorkOS as separate Stacks (currently covered in `security-engineer/references/iam-specialist.md`)

Stack Pack candidacy criterion: enough surface area + 2026-currency relevance that role-by-role overlays meaningfully change recommendations vs general-purpose knowledge. Niche or stable stacks may not warrant a Pack — a single reference file inside an existing specialist can suffice.

## Authoring a new Stack Pack (v2 schema)

The Salesforce, AWS, and Cloudflare packs are the reference implementations. To add a new stack:

1. **Create `stacks/<stack-name>/`** at repo root with `SKILL.md` and `references/<role>.md` files per role the stack meaningfully changes.

2. **Frontmatter must declare** (v2 schema):
   ```yaml
   metadata:
     last_verified_on: "YYYY-MM-DD"        # the day this content was last reviewed against vendor sources
     applies_to_roles: [...]               # specialist + vertical role names this Stack overlays
   authoritative_sources:
     primary:                              # official docs, CLIs, API refs, changelogs — to WebFetch when verifying
       - { name: "...", url: "...", type: official_docs|cli_reference|api_reference|changelog }
   delegate_to_skills:                     # vendor-provided skills/MCPs to defer to when installed
     - { skill: "<skill-or-mcp-id>", covers: [product1, product2, ...] }
   products_covered:                       # distinct products inside the vendor + per-product drift risk
     - { name: <Product>, drift_risk: high|medium|low, notes: "..." }
   ```

3. **Add the stack to `manifest.json`** under the `stacks` section with `version`, `last_verified_on`, `applies_to_roles`, `deferred_roles`.

4. **Add a router entry** to `skills/etyb/core/stack-registry.md` with the stack's detection signals (positive + negative).

5. **Add a row** to the **Available Stack Packs** table above.

6. **Open a PR** — maintainer review checks `validate-pr.sh` (which includes `check-currency.sh`) plus coverage, currency, and that always-on protocols + verticals are respected.

## Conventions

- **Reference files match role names exactly** (`backend-architect.md`, `ai-ml-engineer.md`, etc.) for predictable router-side loading.
- **`last_verified_on` is mandatory** — moves on every Stack review, not on every bundle release. The script `scripts/maintainer/check-currency.sh` flags Stacks whose products are stale relative to their drift risk.
- **Cite primary sources by URL** — every Stack overlay grounds claims in `authoritative_sources.primary` entries. Don't copy vendor docs verbatim; capture the opinionated knowledge a specialist needs to ship production-grade work on the platform.
- **Defer to business verticals for compliance** — Stack Packs cover the platform surface, not domain regulation (HIPAA, PCI, PSD2, SOC 2 framework details belong to the vertical references).
- **Defer to vendor skills/MCPs when installed** — if `delegate_to_skills` covers the question, the Stack overlay backs off and lets the vendor's own surface answer.
- **Cross-link generously** — between role overlays inside a Stack, and between Stacks where they touch (e.g., Vercel ↔ Cloudflare for edge workloads; Anthropic Claude ↔ AWS Bedrock).

## Maintainer responsibilities

For each Stack you author or update:

- Set `last_verified_on` to today.
- Verify every `authoritative_sources.primary` URL returns 200.
- Assign `drift_risk` per product with rationale captured in the Stack README.
- Note the verification basis in the commit message ("verified against Cloudflare changelog through 2026-05-14").

The `check-currency.sh` validator flags:
- High-drift products whose Stack `last_verified_on` is more than **90 days** old.
- Medium-drift products older than **180 days**.
- Low-drift products older than **365 days**.
- Stacks whose `authoritative_sources.primary` URLs fail.

Run before every release. Stale Stacks get a refresh PR before they're allowed back into a tagged release.
