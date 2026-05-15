# Stacks — Vendor Knowledge Registry

ETYB is organized by **engineering role + business domain** (20 specialists + 9 protocols + 6 verticals). Vendor-specific knowledge — what Cloudflare's Wrangler CLI does today, what Salesforce Agentforce features ship in Spring '26, what Vercel AI Gateway supports — lives in **Stacks** at `stacks/<vendor>/` in this repo. Each Stack is the vendor knowledge registry for one platform: timestamped, sourced, delegation-aware.

Stacks are not new roles. They are context overlays applied across the existing references. The trigger surface stays at `/etyb`; the knowledge surface grows by adding folders under `stacks/`.

## Architecture (v4.0.0)

Each Stack folder ships everything the team needs in one place:

```
stacks/cloudflare/
├── SKILL.md                  ← slim trigger pointer + top platform gotchas
├── index.md                  ← Stack-wide briefing (currency-stamped)
├── workers.md                ← canonical per-product page (currency-stamped)
├── d1.md
├── r2.md
├── ...                       ← one per entry in products_covered
├── backend-architect.md      ← composed per-role view
├── system-architect.md
└── ...                       ← one per entry in applies_to_roles
```

When ETYB is installed, it reads these files directly from disk. For third-party agents that want to consume the content without installing, the same files are reachable as raw markdown at `https://raw.githubusercontent.com/e-t-y-b/etyb-skills/main/stacks/<vendor>/<page>.md`.

## How Stacks work

1. **Detection.** ETYB's router (`skills/etyb/core/stack-registry.md`) watches the user's request for stack signals — keywords, product names, file extensions, CLIs, error messages. The matching slim `stacks/<vendor>/SKILL.md` loads via the standard skill-trigger flow.
2. **Delegation check.** ETYB checks the slim pointer's `delegate_to_skills`. If a listed vendor MCP or skill is installed in the user's environment, ETYB defers to it for matching products. The vendor's own surface knows current state better than any curated docs.
3. **Read the right page.** For depth, ETYB reads the most-specific in-repo file:
   - `stacks/<vendor>/<product>.md` — canonical product page
   - `stacks/<vendor>/<role>.md` — composed role view
   - `stacks/<vendor>/index.md` — Stack briefing (broadest)
4. **Drift-check protocol.** Before committing to vendor-specific specifics (versions, API signatures, CLI flags, compliance deadlines), ETYB applies the protocol from `skills/etyb/core/knowledge-currency.md` keyed off the *read page's* frontmatter — soft path (disclose currency + cite source) by default, strict path (defer to a delegate or fetch the page's `authoritative_url`) for high-stakes or stale-high-drift claims.
5. **Composition.** Stacks don't replace the 9 always-on protocols (TDD, verification, debugging, etc.) — those apply unchanged. They defer to business-domain verticals (fintech, healthcare, etc.) for compliance and domain expertise; the Stack covers the *platform-specific* slice.

Signature note: when a Stack overlay is in play, ETYB signs responses as `ETYB · <role> · <stack>` (e.g., `ETYB · backend-architect · cloudflare`) so the user knows which platform context shaped the answer. The signature also surfaces the page's `last_verified_on` date and the file path it grounded in.

## Available Stacks

| Stack | Version | Last Verified | Drift Risk | Status |
|-------|---------|---------------|------------|--------|
| [Salesforce](stacks/salesforce/) | 4.0.0 | Spring '26 (2026-05-12) | High on Agentforce/Data 360; low on Hyperforce/Health Cloud | Active |
| [AWS](stacks/aws/) | 4.0.0 | 2026-05-14 | High on Bedrock; medium on Lambda/ECS/Aurora | New in v4.0.0 |
| [GCP](stacks/gcp/) | 4.0.0 | 2026-05-14 | High on Vertex AI; medium on Cloud Run/BigQuery | New in v4.0.0 |
| [Azure](stacks/azure/) | 4.0.0 | 2026-05-14 | High on Azure OpenAI; medium on AKS/Entra | New in v4.0.0 |
| [Anthropic Claude](stacks/anthropic-claude/) | 4.0.0 | 2026-05-14 | High on Agent SDK + Claude API features | New in v4.0.0 |
| [OpenAI](stacks/openai/) | 4.0.0 | 2026-05-14 | High across Assistants + Responses API | New in v4.0.0 |
| [Cloudflare](stacks/cloudflare/) | 4.0.0 | 2026-05-14 | High on Workers/Vectorize/AI Gateway; low on KV | New in v4.0.0 |
| [Vercel](stacks/vercel/) | 4.0.0 | 2026-05-14 | High on AI Gateway + Next.js | New in v4.0.0 |
| [Supabase](stacks/supabase/) | 4.0.0 | 2026-05-14 | Medium across products | New in v4.0.0 |
| [Firebase](stacks/firebase/) | 4.0.0 | 2026-05-14 | High on Genkit + AI Logic; medium elsewhere | New in v4.0.0 |
| [Expo](stacks/expo/) | 4.0.0 | 2026-05-14 | High on EAS + New Architecture | New in v4.0.0 |
| [Stripe](stacks/stripe/) | 4.0.0 | 2026-05-14 | Medium across products | New in v4.0.0 |
| [Observability](stacks/observability/) | 4.0.0 | 2026-05-14 | Medium per-vendor | New in v4.0.0 (multi-vendor: Datadog, New Relic, Grafana, Prometheus, Splunk) |

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

Stack candidacy criterion: enough surface area + 2026-currency relevance that role-by-role overlays meaningfully change recommendations vs general-purpose knowledge. Niche or stable stacks may not warrant a Stack — a single reference file inside an existing specialist can suffice.

## Authoring a new Stack

1. **Create `stacks/<vendor>/`** with:
   - `SKILL.md` — slim trigger surface (frontmatter + top gotchas + standing instructions, ~125-200 lines). The trigger description matches user signals; the body holds the highest-LLM-value gotchas and the delegation map.
   - `index.md` — Stack briefing (currency-stamped overview, frontmatter validates against the `stack:` schema)
   - One canonical `<product>.md` per entry in `products_covered` (currency-stamped, includes `authoritative_url`)
   - One composed `<role>.md` per role in `applies_to_roles`

2. **Frontmatter must declare** on the SKILL.md:
   ```yaml
   metadata:
     last_verified_on: "YYYY-MM-DD"        # day this slim briefing was last reviewed
     applies_to_roles: [...]               # specialist + vertical role names this Stack overlays
   authoritative_sources:
     primary:                              # official docs, CLIs, API refs, changelogs
       - { name: "...", url: "...", type: official_docs|cli_reference|api_reference|changelog }
   delegate_to_skills:                     # vendor-provided skills/MCPs to defer to when installed
     - { skill: "<skill-or-mcp-id>", covers: [product1, product2, ...] }
   products_covered:                       # distinct products + per-product drift risk
     - { name: <Product>, drift_risk: high|medium|low, notes: "..." }
   ```

3. **Each per-product / per-role page** gets its own frontmatter with `last_verified_on`, `drift_risk`, `authoritative_url`. Body is opinionated, decision-framework-style content — not a vendor-docs duplicate.

4. **Add the stack to `manifest.json`** under `.stacks` with `version`, `last_verified_on`, `applies_to_roles`, `deferred_roles`.

5. **Add a router entry** to `skills/etyb/core/stack-registry.md` with the stack's detection signals (positive + negative).

6. **Add a row** to the **Available Stacks** table above.

7. **Open the PR** — `validate-pr.sh` runs `check-currency.sh` over the new content. CI catches stale `last_verified_on`, missing schemas, and (under `CHECK_CURRENCY_FETCH=1`) unreachable `authoritative_url` references.

## Conventions

- **SKILL.md is the trigger surface.** It carries detection signals + top gotchas + delegation map. Depth lives in sibling files.
- **`last_verified_on` is mandatory** on the SKILL.md AND on every per-product / per-role page. Each moves on its own cadence (per-page review). The validator `check-currency.sh` flags Stacks whose products are stale relative to their drift risk.
- **Cite primary sources by URL** — every page grounds claims in `authoritative_url`. Don't copy vendor docs verbatim; capture the opinionated knowledge a specialist needs to ship production-grade work on the platform.
- **Defer to business verticals for compliance** — Stacks cover the platform surface, not domain regulation (HIPAA, PCI, PSD2, SOC 2 framework details belong to the vertical references).
- **Defer to vendor skills/MCPs when installed** — if `delegate_to_skills` covers the question, ETYB skips the in-repo content and lets the vendor's own surface answer.
- **Cross-link generously** between sibling files — within a Stack (product → role) and across Stacks where they touch (e.g., Vercel ↔ Cloudflare for edge workloads; Anthropic Claude ↔ AWS Bedrock).

## Maintainer responsibilities

For each Stack you author or refresh:

- Set `last_verified_on` to today on every page you reviewed (SKILL.md + each product/role file)
- Update product pages if products were added/removed/renamed
- Update each page's `authoritative_url` if it moved
- Verify every `authoritative_sources.primary` URL still returns 200
- Keep the `delegate_to_skills` list current — add entries when vendors ship MCPs/skills
- Note the verification basis in the commit message ("verified against Cloudflare changelog through 2026-05-14")

The `check-currency.sh` validator flags:
- High-drift products whose `last_verified_on` is more than **90 days** old
- Medium-drift products older than **180 days**
- Low-drift products older than **365 days**
- Stack folders with fewer than 2 sibling files alongside SKILL.md (warning — likely incomplete)
- Under `CHECK_CURRENCY_FETCH=1`: `authoritative_sources.primary` URLs that fail (warnings only — vendor sites move; don't block the release)

Run before every release. Stale Stacks get a refresh PR before they're allowed back into a tagged release.
