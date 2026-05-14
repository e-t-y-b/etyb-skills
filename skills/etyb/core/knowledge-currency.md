# Knowledge Currency — When Baked Knowledge Is Stale

You are an LLM. Your training has a cutoff. The repo's internal references have a cutoff too — whenever the maintainer last reviewed them. Vendors rename products, retire APIs, change pricing, shift deprecation deadlines. **Without a currency discipline, you will give confidently-wrong answers about platforms that moved on.**

This module defines how to detect and handle that drift.

## Where currency metadata lives

**Stacks own vendor currency.** Specialists, protocols, and verticals are principle-based and largely time-invariant — TDD doesn't drift, REST API patterns don't drift, double-entry bookkeeping doesn't drift. What drifts is *vendor specifics*: which Salesforce features ship in which release, what Wrangler flag changed, which Vercel primitive replaced the old one.

Every Stack at `stacks/<vendor>/SKILL.md` declares (v2 schema):

```yaml
metadata:
  last_verified_on: "YYYY-MM-DD"        # when content was last reviewed against vendor sources
  applies_to_roles: [...]               # which specialist references this Stack overlays
authoritative_sources:
  primary:                              # official docs, CLIs, API refs, changelogs — to WebFetch when verifying
    - { name: "...", url: "...", type: official_docs|cli_reference|api_reference|changelog }
delegate_to_skills:                     # vendor-provided skills/MCPs ETYB should defer to when installed
  - { skill: "<skill-or-mcp-id>", covers: [product1, product2, ...] }
products_covered:                       # the distinct products inside the vendor + per-product drift risk
  - { name: <Product>, drift_risk: high|medium|low }
```

`drift_risk` is *per product*, not per Stack — Cloudflare Workers ships changes weekly; KV is stable for years. The protocol below uses the highest-relevant product's `drift_risk` to pick its path.

## The drift-check protocol (tiered)

Before committing to any time-sensitive claim sourced from a Stack:

```
1. Identify which Stack and which product the claim covers.
2. Read the Stack's last_verified_on and the product's drift_risk.
3. Identify the claim category:
   - GENERAL — patterns, architecture guidance, "how do I think about X"
   - SPECIFIC — version numbers, API signatures, CLI flags, pricing, dates
   - HIGH-STAKES — compliance deadlines, payment-flow specifics,
                   security primitives, regulatory enforcement dates
4. Pick the path:
```

### Soft path (default)

Applies when ALL of:
- claim category is GENERAL or SPECIFIC (not HIGH-STAKES)
- product drift_risk is low/medium, OR
- product drift_risk is high but last_verified_on is within 90 days

Behavior: Answer from the Stack overlay. Append a one-line currency disclosure:

> *Stack knowledge as of `<last_verified_on>`. For verified-current behavior, see `<primary_source_url>`.*

### Strict path

Applies when ANY of:
- claim category is HIGH-STAKES
- product drift_risk is high AND last_verified_on is more than 90 days old
- the user is making an irreversible decision (signing a contract, picking a vendor for a 3-year commitment, configuring production security)

Behavior: **Do not commit to specifics from baked knowledge.** Either:
- **(a)** If a `delegate_to_skills` entry covering this product is installed in the user's environment → invoke that skill rather than answering from the Stack overlay. The vendor's own skill knows current state better than you do.
- **(b)** Otherwise → WebFetch the relevant `authoritative_sources.primary` URL, ground the answer in the fetched content, and cite the URL in your reply.

When strict-path is needed and neither (a) nor (b) is available (offline / WebFetch disabled), state plainly: "I have Stack knowledge as of `<date>` but this is a high-stakes claim — verify against `<URL>` before acting."

## How ETYB detects which Stack applies

`core/stack-registry.md` carries the detection signals — keywords, product names, file extensions, CLI invocations the user mentions. When the user's request matches signals for a Stack, ETYB:

1. **Loads the Stack briefing** (`stacks/<vendor>/SKILL.md`) — minimum cost; gives the team overview.
2. **Probes the environment for `delegate_to_skills`** — checks which named skills/MCPs are actually available in this Claude session. Done by inspecting the `<available_skills>` list passed to the model.
3. **Routes the work:**
   - If a `delegate_to_skills` entry covers the specific product being asked about → ETYB invokes that skill and treats its response as authoritative.
   - Otherwise → ETYB reads `stacks/<vendor>/references/<role>.md` for the engaged role, applies the drift-check protocol per the rules above.

## How ETYB surfaces currency to the user

Inside Stack-sourced responses, the signature block gets an extra line on Tier 1-4 responses:

```
─────
ETYB · <role> · <stack>
Stack knowledge as of <YYYY-MM-DD>
What's new — etyb.ai/changelog
```

For strict-path responses where ETYB grounded in fetched sources, also cite the URL inline (not just in the signature) — the user should see the source for the specific claim, not have to hunt.

## What does NOT need currency discipline

- Specialist references (`references/specialists/<name>/*`) — these are engineering principles. They have no `last_verified_on`. If a specialist file embeds a vendor-specific claim, that's a signal the content should migrate to a Stack.
- Protocol references (`references/protocols/<name>/*`) — TDD, debugging, review, brainstorming, planning, branch safety, subagents, self-improvement, verification. These are timeless practices.
- Vertical references (`references/verticals/<name>/*`) — mostly timeless except for regulatory-adjacent content (HIPAA enforcement dates, PCI scope changes, SOC 2 framework versions). For those *narrow* sections, embed a Stack-style currency line manually.

## Maintainer responsibilities

The script `scripts/maintainer/check-currency.sh` audits every Stack against its `last_verified_on` and flags:
- High-drift products older than 90 days
- Medium-drift products older than 180 days
- Low-drift products older than 365 days
- Stacks whose `authoritative_sources.primary` URLs return 404

It runs as part of `validate-pr.sh` and on a periodic cron (configured externally — the script is the building block, not the scheduler).

When you ship a new Stack:
- `last_verified_on` is today
- Every product has a `drift_risk` assigned with rationale in the Stack's README
- Every `primary` URL was reachable when you wrote it
- If a vendor MCP/skill exists, it is listed in `delegate_to_skills`

When you update an existing Stack:
- Bump `last_verified_on` to today
- Update `products_covered` if products were added/removed/renamed by the vendor
- Update `authoritative_sources` if URLs moved
- Note the verification basis in the commit message ("verified against Cloudflare changelog through 2026-05-14")

## Anti-patterns to refuse

- Answering "what's the latest [vendor] feature in [product]?" from baked knowledge alone when a vendor MCP/skill is installed. Always defer.
- Quoting specific version numbers, API signatures, CLI flags, or pricing from baked knowledge without applying the drift-check protocol.
- Treating a Stack's `last_verified_on` as a guarantee of accuracy. It's a timestamp of last review, not a promise of current truth.
- Forgetting to surface the currency disclosure to the user. Silent stale knowledge is worse than stated stale knowledge.
- Copying vendor docs verbatim into a Stack. The Stack's job is *opinionated knowledge a specialist needs* — when, why, tradeoffs, integration patterns, gotchas. The official docs are the source of truth for specifics; the Stack tells the team how to think about them.
