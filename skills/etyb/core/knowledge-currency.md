# Knowledge Currency — When Baked Knowledge Is Stale

You are an LLM. Your training has a cutoff. The repo's internal references have a cutoff too — whenever the maintainer last reviewed them. Vendors rename products, retire APIs, change pricing, shift deprecation deadlines. **Without a currency discipline, you will give confidently-wrong answers about platforms that moved on.**

This module defines how to detect and handle that drift.

## Two-layer Stack architecture

Vendor knowledge is split across two surfaces:

1. **Local slim pointer** — `stacks/<vendor>/SKILL.md` in this repo. Tiny by design: trigger keywords, `applies_to_roles`, `delegate_to_skills`, `products_covered` list, and the top 5-10 platform gotchas. Used for detection and delegation probing. Loaded automatically when the user's request hits a Stack's signals.

2. **Canonical docs at [docs.etyb.ai](https://docs.etyb.ai/stacks/)** — currency-stamped per-product and per-role pages. Each page carries its own `last_verified_on`, `drift_risk`, `authoritative_url`. Fetched at runtime via WebFetch when the work needs depth that the slim pointer doesn't carry.

This is the architecture: **detection local, knowledge remote.** The install stays small (no vendor content sitting on disk going stale); knowledge updates ship without re-installing.

## Where currency metadata lives

**Specialists, protocols, and verticals are principle-based and largely time-invariant** — TDD doesn't drift, REST API patterns don't drift, double-entry bookkeeping doesn't drift. What drifts is *vendor specifics*: which Salesforce features ship in which release, what Wrangler flag changed, which Vercel primitive replaced the old one.

Local Stack frontmatter (`stacks/<vendor>/SKILL.md`) declares the detection signal + delegation:

```yaml
metadata:
  last_verified_on: "YYYY-MM-DD"        # when this slim briefing was last reviewed
  applies_to_roles: [...]               # which specialist references this Stack overlays
authoritative_sources:
  primary:
    - { name: "...", url: "...", type: official_docs|cli_reference|api_reference|changelog }
delegate_to_skills:                     # vendor-provided skills/MCPs ETYB defers to when installed
  - { skill: "<skill-or-mcp-id>", covers: [product1, product2, ...] }
products_covered:                       # the distinct products inside the vendor + per-product drift risk
  - { name: <Product>, drift_risk: high|medium|low, notes: "..." }
```

The fetched docs.etyb.ai page (the canonical surface) carries its own currency stamp in its YAML frontmatter:

```yaml
---
title: <Product>
product:
  name: <Product>
  stack: <vendor>
  drift_risk: high|medium|low
  last_verified_on: "YYYY-MM-DD"
  authoritative_url: https://<vendor>/docs/<product>/
---
```

The fetched page's stamp is what governs the drift-check protocol below. The local slim pointer's stamp is only a fallback when the fetch isn't possible (offline, WebFetch disabled, page 404).

## The drift-check protocol (tiered)

Before committing to any time-sensitive claim sourced from a Stack:

```
1. Identify the Stack and the specific product(s) the claim covers.
2. Pick the most-specific URL that exists (fetch order):
     https://docs.etyb.ai/stacks/<vendor>/<product>/   (canonical product page)
     https://docs.etyb.ai/stacks/<vendor>/<role>/      (composed role view)
     https://docs.etyb.ai/stacks/<vendor>/             (stack index)
3. WebFetch the page. Read its frontmatter — `last_verified_on`, `drift_risk`,
   `authoritative_url`.
4. Identify the claim category:
   - GENERAL — patterns, architecture guidance, "how do I think about X"
   - SPECIFIC — version numbers, API signatures, CLI flags, pricing, dates
   - HIGH-STAKES — compliance deadlines, payment-flow specifics,
                   security primitives, regulatory enforcement dates
5. Pick the path:
```

### Soft path (default)

Applies when ALL of:
- claim category is GENERAL or SPECIFIC (not HIGH-STAKES)
- product `drift_risk` is `low` or `medium`, OR
- product `drift_risk` is `high` but `last_verified_on` is within 90 days

Behavior: Answer from the fetched docs.etyb.ai page. Append a one-line currency disclosure:

> *Stack knowledge as of `<last_verified_on>`. For verified-current behavior, see `<authoritative_url>`.*

### Strict path

Applies when ANY of:
- claim category is HIGH-STAKES
- product `drift_risk` is `high` AND `last_verified_on` is more than 90 days old
- the user is making an irreversible decision (signing a contract, picking a vendor for a 3-year commitment, configuring production security)

Behavior: **Do not commit to specifics from the docs.etyb.ai page alone.** Either:
- **(a)** If a `delegate_to_skills` entry covering this product is installed in the user's environment → invoke that skill rather than answering from baked or fetched content. The vendor's own skill knows current state better than any curated docs.
- **(b)** Otherwise → WebFetch the page's `authoritative_url` (vendor's own docs/changelog/CLI reference), ground the answer in the fetched content, cite both URLs in your reply.

When strict-path is needed and neither (a) nor (b) is available (offline / WebFetch disabled), state plainly: "I have Stack knowledge as of `<date>` from `<docs.etyb.ai URL>` but this is a high-stakes claim — verify against `<authoritative_url>` before acting."

### Degraded modes

- **404 on a docs.etyb.ai page** → fall back to the broader URL (product → role → stack index). If even the stack index is 404, the Stack is unpublished; warn the user and proceed with general knowledge plus a flag.
- **WebFetch fails** (network, rate limit) → use the local slim pointer's gotchas list + standing instructions. Tell the user the fetch failed and you're operating on the cached briefing only.
- **Page exists but `last_verified_on` is older than the threshold** → treat as strict-path even if claim category looked GENERAL. Stale high-risk content is the dangerous case.

## How ETYB detects which Stack applies

`core/stack-registry.md` carries the detection signals — keywords, product names, file extensions, CLI invocations the user mentions. When the user's request matches signals for a Stack, ETYB:

1. **Loads the slim local Stack briefing** (`stacks/<vendor>/SKILL.md`) — minimum cost; gives the team overview and the top platform gotchas. This is the detection/routing layer; depth is remote.
2. **Probes the environment for `delegate_to_skills`** — checks which named skills/MCPs are actually available in this Claude session by inspecting `<available_skills>`.
3. **Routes the work:**
   - If a `delegate_to_skills` entry covers the specific product being asked about → ETYB invokes that skill and treats its response as authoritative. No docs.etyb.ai fetch needed.
   - Otherwise → ETYB picks the most-specific docs.etyb.ai URL (product > role > stack) and WebFetches it. The drift-check protocol governs the rest.

## How ETYB surfaces currency to the user

Inside Stack-sourced responses, the signature block gets extra lines on Tier 1-4 responses:

```
─────
ETYB · <role> · <stack>
Stack knowledge as of <YYYY-MM-DD from fetched page> · docs.etyb.ai/stacks/<vendor>/<product>/
What's new — etyb.ai/changelog
```

For strict-path responses where ETYB grounded in fetched authoritative sources, also cite the `authoritative_url` inline (not just in the signature) — the user should see the source for the specific claim, not have to hunt.

## What does NOT need currency discipline

- Specialist references (`references/specialists/<name>/*`) — these are engineering principles. They have no `last_verified_on`. If a specialist file embeds a vendor-specific claim, that's a signal the content should migrate to a Stack page on docs.etyb.ai.
- Protocol references (`references/protocols/<name>/*`) — TDD, debugging, review, brainstorming, planning, branch safety, subagents, self-improvement, verification. These are timeless practices.
- Vertical references (`references/verticals/<name>/*`) — mostly timeless except for regulatory-adjacent content (HIPAA enforcement dates, PCI scope changes, SOC 2 framework versions). For those *narrow* sections, embed a Stack-style currency line manually.

## Maintainer responsibilities

The script `scripts/maintainer/check-currency.sh` audits both layers:
- The local slim Stack pointers — flags `last_verified_on` older than the drift-risk threshold.
- The docs.etyb.ai pages — probes the canonical product URLs and the per-page `authoritative_url` for 404s and stale `last_verified_on` stamps.

It runs as part of `validate-pr.sh` and on a periodic cron (configured externally — the script is the building block, not the scheduler).

When you publish a new Stack page on docs.etyb.ai:
- `last_verified_on` is today
- Every product page has a `drift_risk` with rationale in `notes`
- `authoritative_url` is reachable
- If a vendor MCP/skill exists, it is listed in `delegate_to_skills` on the Stack index

When you refresh an existing Stack:
- Bump `last_verified_on` to today on every page you reviewed
- Update product pages if products were added/removed/renamed by the vendor
- Update `authoritative_url` if it moved
- Note the verification basis in the commit message ("verified against Cloudflare changelog through 2026-05-14")

## Anti-patterns to refuse

- Answering "what's the latest [vendor] feature in [product]?" from baked knowledge alone when a vendor MCP/skill is installed. Always defer.
- Treating the local slim `stacks/<vendor>/SKILL.md` as the source of truth for specifics. The slim pointer carries gotchas + detection signals only. Depth lives on docs.etyb.ai.
- Quoting specific version numbers, API signatures, CLI flags, or pricing without applying the drift-check protocol.
- Treating any `last_verified_on` as a guarantee of accuracy. It's a timestamp of last review, not a promise of current truth.
- Forgetting to surface the currency disclosure to the user. Silent stale knowledge is worse than stated stale knowledge.
- Copying vendor docs verbatim into a docs.etyb.ai page. The page's job is *opinionated knowledge a specialist needs* — when, why, tradeoffs, integration patterns, gotchas. The official docs are the source of truth for specifics; docs.etyb.ai tells the team how to think about them.
