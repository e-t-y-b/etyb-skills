# Stacks — Vendor Knowledge Registry

ETYB is organized by **engineering role + business domain** (20 specialists + 9 protocols + 6 verticals). Vendor-specific knowledge — what Cloudflare's Wrangler CLI does today, what Salesforce Agentforce features ship in Spring '26, what Vercel AI Gateway supports — lives in **Stacks**. Each Stack is the vendor knowledge registry for one platform: timestamped, sourced, delegation-aware.

Stacks are not new roles. They are context overlays applied across the existing references. The trigger surface stays at `/etyb`; the knowledge surface grows by adding Stack folders here AND publishing canonical pages on [docs.etyb.ai](https://docs.etyb.ai/stacks/).

## Two-layer architecture (v4.0.0)

Vendor knowledge is split across two surfaces:

1. **Local slim pointer** — `stacks/<vendor>/SKILL.md` in this repo. Tiny by design (~125-200 lines): trigger keywords, `applies_to_roles`, `delegate_to_skills`, `products_covered` list, top 5-10 platform gotchas. Loaded automatically when the user's request hits a Stack's signals. **This is what ships in the install.**

2. **Canonical docs at [docs.etyb.ai](https://docs.etyb.ai/stacks/)** — currency-stamped per-product and per-role pages, source repo at [`e-t-y-b/etyb-dot-ai`](https://github.com/e-t-y-b/etyb-dot-ai). Each page carries its own `last_verified_on`, `drift_risk`, `authoritative_url`. Fetched at runtime via WebFetch when work needs depth that the slim pointer doesn't carry.

**Detection local, knowledge remote.** The install stays small (no vendor content sitting on disk going stale); knowledge updates ship without re-installing.

## How Stacks work

1. **Detection.** ETYB's router (`skills/etyb/core/stack-registry.md`) watches the user's request for stack signals — keywords, product names, file extensions, CLIs, error messages. The matching slim local `stacks/<vendor>/SKILL.md` loads via the standard skill-trigger flow.
2. **Delegation check.** ETYB checks the slim pointer's `delegate_to_skills`. If a listed vendor MCP or skill is installed in the user's environment, ETYB defers to it for matching products. The vendor's own surface knows current state better than any curated docs.
3. **WebFetch the canonical page.** For depth, ETYB picks the most-specific URL that exists and fetches it:
   - `https://docs.etyb.ai/stacks/<vendor>/<product>/` — canonical product page
   - `https://docs.etyb.ai/stacks/<vendor>/<role>/` — composed role view
   - `https://docs.etyb.ai/stacks/<vendor>/` — Stack index (broadest)
4. **Drift-check protocol.** Before committing to vendor-specific specifics (versions, API signatures, CLI flags, compliance deadlines), ETYB applies the protocol from `skills/etyb/core/knowledge-currency.md` keyed off the *fetched page's* frontmatter — soft path (disclose currency + cite source) by default, strict path (defer to a delegate or fetch the page's `authoritative_url`) for high-stakes or stale-high-drift claims.
5. **Composition.** Stacks don't replace the 9 always-on protocols (TDD, verification, debugging, etc.) — those apply unchanged. They defer to business-domain verticals (fintech, healthcare, etc.) for compliance and domain expertise; the Stack covers the *platform-specific* slice.

Signature note: when a Stack overlay is in play, ETYB signs responses as `ETYB · <role> · <stack>` (e.g., `ETYB · backend-architect · cloudflare`) so the user knows which platform context shaped the answer. The signature also surfaces the fetched page's `last_verified_on` date and the docs.etyb.ai URL it grounded in.

## Available Stacks

| Stack | Version | Last Verified | Drift Risk | Status |
|-------|---------|---------------|------------|--------|
| [Salesforce](stacks/salesforce/SKILL.md) → [docs.etyb.ai](https://docs.etyb.ai/stacks/salesforce/) | 4.0.0 | Spring '26 (2026-05-12) | High on Agentforce/Data 360; low on Hyperforce/Health Cloud | Active |
| [AWS](stacks/aws/SKILL.md) → [docs.etyb.ai](https://docs.etyb.ai/stacks/aws/) | 4.0.0 | 2026-05-14 | High on Bedrock; medium on Lambda/ECS/Aurora | New in v4.0.0 |
| [GCP](stacks/gcp/SKILL.md) → [docs.etyb.ai](https://docs.etyb.ai/stacks/gcp/) | 4.0.0 | 2026-05-14 | High on Vertex AI; medium on Cloud Run/BigQuery | New in v4.0.0 |
| [Azure](stacks/azure/SKILL.md) → [docs.etyb.ai](https://docs.etyb.ai/stacks/azure/) | 4.0.0 | 2026-05-14 | High on Azure OpenAI; medium on AKS/Entra | New in v4.0.0 |
| [Anthropic Claude](stacks/anthropic-claude/SKILL.md) → [docs.etyb.ai](https://docs.etyb.ai/stacks/anthropic-claude/) | 4.0.0 | 2026-05-14 | High on Agent SDK + Claude API features | New in v4.0.0 |
| [OpenAI](stacks/openai/SKILL.md) → [docs.etyb.ai](https://docs.etyb.ai/stacks/openai/) | 4.0.0 | 2026-05-14 | High across Assistants + Responses API | New in v4.0.0 |
| [Cloudflare](stacks/cloudflare/SKILL.md) → [docs.etyb.ai](https://docs.etyb.ai/stacks/cloudflare/) | 4.0.0 | 2026-05-14 | High on Workers/Vectorize/AI Gateway; low on KV | New in v4.0.0 |
| [Vercel](stacks/vercel/SKILL.md) → [docs.etyb.ai](https://docs.etyb.ai/stacks/vercel/) | 4.0.0 | 2026-05-14 | High on AI Gateway + Next.js | New in v4.0.0 |
| [Supabase](stacks/supabase/SKILL.md) → [docs.etyb.ai](https://docs.etyb.ai/stacks/supabase/) | 4.0.0 | 2026-05-14 | Medium across products | New in v4.0.0 |
| [Firebase](stacks/firebase/SKILL.md) → [docs.etyb.ai](https://docs.etyb.ai/stacks/firebase/) | 4.0.0 | 2026-05-14 | High on Genkit + AI Logic; medium elsewhere | New in v4.0.0 |
| [Expo](stacks/expo/SKILL.md) → [docs.etyb.ai](https://docs.etyb.ai/stacks/expo/) | 4.0.0 | 2026-05-14 | High on EAS + New Architecture | New in v4.0.0 |
| [Stripe](stacks/stripe/SKILL.md) → [docs.etyb.ai](https://docs.etyb.ai/stacks/stripe/) | 4.0.0 | 2026-05-14 | Medium across products | New in v4.0.0 |
| [Observability](stacks/observability/SKILL.md) → [docs.etyb.ai](https://docs.etyb.ai/stacks/observability/) | 4.0.0 | 2026-05-14 | Medium per-vendor | New in v4.0.0 (multi-vendor: Datadog, New Relic, Grafana, Prometheus, Splunk) |

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

The order matters. **Publish on docs.etyb.ai first; register the slim pointer locally second.** A slim pointer that links into an unpublished docs.etyb.ai URL ships at 404 destinations.

1. **Publish on docs.etyb.ai** — open a PR on [`e-t-y-b/etyb-dot-ai`](https://github.com/e-t-y-b/etyb-dot-ai) under `src/content/docs/stacks/<vendor>/`:
   - `index.md` (Stack briefing + frontmatter validating against the `stack:` schema in `src/content.config.ts`)
   - One canonical `<product>.md` per entry in `products_covered` (validates against the `product:` schema)
   - One composed `<role>.md` per role in `applies_to_roles` (validates against the `role_overlay:` schema)
   See the Salesforce Stack as the reference implementation.

2. **Land the local slim pointer** at `stacks/<vendor>/SKILL.md` once docs.etyb.ai is live. Frontmatter must declare:
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
   Body: top 5-10 platform gotchas + standing instructions + escalation map (template in any existing Stack's body — they all share a structure).

3. **Add the stack to `manifest.json`** under the `stacks` section with `version`, `last_verified_on`, `applies_to_roles`, `deferred_roles`.

4. **Add a router entry** to `skills/etyb/core/stack-registry.md` with the stack's detection signals (positive + negative).

5. **Add a row** to the **Available Stacks** table above.

6. **Open the etyb-skills PR** — maintainer review runs `validate-pr.sh` (includes `check-currency.sh`). Run `CHECK_CURRENCY_FETCH=1 scripts/maintainer/check-currency.sh` locally before opening the PR; the v4 invariant is that every local pointer has a published canonical page. A 404 on the docs.etyb.ai URL is a release blocker.

## Conventions

- **Slim pointer = trigger surface.** It doesn't try to be exhaustive; it carries detection + delegation + the highest-LLM-value gotchas. Depth lives on docs.etyb.ai.
- **`last_verified_on` is mandatory** on both layers. Local pointer's date moves when the slim briefing is reviewed; each docs.etyb.ai page's date moves on its own cadence (per-page review). The validator `check-currency.sh` flags Stacks whose products are stale relative to their drift risk.
- **Cite primary sources by URL** — every Stack page (local + remote) grounds claims in `authoritative_sources.primary` entries. Don't copy vendor docs verbatim; capture the opinionated knowledge a specialist needs to ship production-grade work on the platform.
- **Defer to business verticals for compliance** — Stacks cover the platform surface, not domain regulation (HIPAA, PCI, PSD2, SOC 2 framework details belong to the vertical references).
- **Defer to vendor skills/MCPs when installed** — if `delegate_to_skills` covers the question, ETYB skips both the slim pointer and the docs.etyb.ai fetch and lets the vendor's own surface answer.
- **Cross-link generously** between docs.etyb.ai pages — within a Stack (product → role) and across Stacks where they touch (e.g., Vercel ↔ Cloudflare for edge workloads; Anthropic Claude ↔ AWS Bedrock).

## Maintainer responsibilities

For each Stack you author or refresh:

**Local slim pointer:**
- Set `last_verified_on` to today on the slim briefing if you reviewed it.
- Verify every `authoritative_sources.primary` URL still returns 200.
- Keep the `delegate_to_skills` list current — add entries when vendors ship MCPs/skills.
- Note the verification basis in the commit message.

**docs.etyb.ai canonical pages:**
- Bump each page's `last_verified_on` when you review it.
- Update product pages if products were added/removed/renamed.
- Update each page's `authoritative_url` if it moved.
- The currency-refresh PR lands on `e-t-y-b/etyb-dot-ai`, separately from etyb-skills.

The `check-currency.sh` validator flags:
- High-drift products whose Stack `last_verified_on` is more than **90 days** old.
- Medium-drift products older than **180 days**.
- Low-drift products older than **365 days**.
- Under `CHECK_CURRENCY_FETCH=1`: docs.etyb.ai canonical pages that 404, and `authoritative_sources.primary` URLs that fail.

Run before every release. Stale Stacks get a refresh PR before they're allowed back into a tagged release.
