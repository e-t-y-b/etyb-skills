# Knowledge Currency — When Baked Knowledge Is Stale

You are an LLM. Your training has a cutoff. The repo's internal references have a cutoff too — whenever the maintainer last reviewed them. Vendors rename products, retire APIs, change pricing, shift deprecation deadlines. **Without a currency discipline, you will give confidently-wrong answers about platforms that moved on.**

This module defines how to detect and handle that drift.

## Stack content is local, in this repo

Vendor knowledge lives **in this repo** under `stacks/<vendor>/`:

```
stacks/cloudflare/
  SKILL.md                  ← trigger surface + slim briefing (loaded by ETYB router on detection)
  index.md                  ← Stack-wide briefing
  workers.md                ← per-product canonical page
  d1.md
  r2.md
  ...
  backend-architect.md      ← per-role composed view
  system-architect.md
  ...
```

When ETYB is installed locally, it reads these files directly from disk — no network fetch needed. For third-party agents that don't have the install but want to consume the content, the same files are reachable as raw markdown at `https://raw.githubusercontent.com/e-t-y-b/etyb-skills/main/stacks/<vendor>/<page>.md`.

## Where currency metadata lives

**Specialists, protocols, and verticals are principle-based and largely time-invariant** — TDD doesn't drift, REST API patterns don't drift, double-entry bookkeeping doesn't drift. What drifts is *vendor specifics*: which Salesforce features ship in which release, what Wrangler flag changed, which Vercel primitive replaced the old one.

The slim `stacks/<vendor>/SKILL.md` carries the trigger surface + delegation map + top gotchas:

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

Each per-product / per-role page (e.g., `stacks/cloudflare/workers.md`) carries its own currency stamp in its YAML frontmatter:

```yaml
---
title: Workers
product:
  name: Workers
  stack: cloudflare
  drift_risk: high
  last_verified_on: "YYYY-MM-DD"
  authoritative_url: https://developers.cloudflare.com/workers/
---
```

That per-page stamp is what governs the drift-check protocol below.

## Protocol owner: the etyb-stack-researcher agent

The `etyb-stack-researcher` agent (`agents/etyb-stack-researcher.md`) owns this
protocol end-to-end — manifest lookup, page resolution, the drift-check paths below,
and any `authoritative_url` fetch. The orchestrator and every other agent request
stack facts by delegating to the researcher; they do not fetch stack pages or vendor
docs themselves. This keeps heavy fetches and raw doc content out of the user
session — the researcher returns a ≤400-token cited distillation instead. One
exception stays with the orchestrator: loading the slim local
`stacks/<vendor>/SKILL.md` briefing at detection time (see "How ETYB detects which
Stack applies") is routing, not research.

## The drift-check protocol (tiered)

Before committing to any time-sensitive claim sourced from a Stack:

```
1. Identify the Stack and the specific product(s) the claim covers.
2. Read the most-specific in-repo file that exists:
     stacks/<vendor>/<product>.md   (canonical product page)
     stacks/<vendor>/<role>.md      (composed role view)
     stacks/<vendor>/index.md       (stack briefing)
3. Read its frontmatter — `last_verified_on`, `drift_risk`, `authoritative_url`.
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

Behavior: Answer from the in-repo Stack page. Append a one-line currency disclosure:

> *Stack knowledge as of `<last_verified_on>`. For verified-current behavior, see `<authoritative_url>`.*

### Strict path

Applies when ANY of:
- claim category is HIGH-STAKES
- product `drift_risk` is `high` AND `last_verified_on` is more than 90 days old
- the user is making an irreversible decision (signing a contract, picking a vendor for a 3-year commitment, configuring production security)

Behavior: **Do not commit to specifics from the in-repo page alone.** Either:
- **(a)** If a `delegate_to_skills` entry covering this product is installed in the user's environment → invoke that skill rather than answering from the repo's curated content. The vendor's own skill knows current state better than any curated docs.
- **(b)** Otherwise → WebFetch the page's `authoritative_url` (vendor's own docs/changelog/CLI reference), ground the answer in the fetched content, cite both the in-repo page and the vendor URL in your reply.

When strict-path is needed and neither (a) nor (b) is available (offline / WebFetch disabled), state plainly: "I have Stack knowledge as of `<date>` from `stacks/<vendor>/<page>.md` but this is a high-stakes claim — verify against `<authoritative_url>` before acting."

### Degraded modes

- **File doesn't exist** (e.g., `stacks/cloudflare/some-new-product.md` not yet authored) → fall back to the broader file (product → role → stack index). If the in-repo tree still doesn't answer the question, go to the vendor's official documentation directly (WebFetch the nearest page's `authoritative_url`, the index's `authoritative_sources`, or the vendor's primary docs domain) and ground the answer in the fetched content, cited. General knowledge alone is the last resort — only when the fetch itself is unavailable — and must be flagged as such.
- **Operating without the local install** (third-party agent fetching from GitHub raw) → same protocol but fetches happen over the network. Treat fetch failures as the in-repo equivalent of "file doesn't exist" above.
- **Page exists but `last_verified_on` is older than the threshold** → treat as strict-path even if claim category looked GENERAL. Stale high-risk content is the dangerous case.

## How ETYB detects which Stack applies

`core/stack-registry.md` carries the detection signals — keywords, product names, file extensions, CLI invocations the user mentions. When the user's request matches signals for a Stack, ETYB:

1. **Loads the slim local Stack briefing** (`stacks/<vendor>/SKILL.md`) — this is the trigger surface; it gives the team overview and the top platform gotchas at activation time.
2. **Probes the environment for `delegate_to_skills`** — checks which named skills/MCPs are actually available in this Claude session by inspecting `<available_skills>`.
3. **Routes the work:**
   - If a `delegate_to_skills` entry covers the specific product being asked about → ETYB invokes that skill and treats its response as authoritative. No in-repo page read needed.
   - Otherwise → ETYB reads the most-specific in-repo Stack file (product > role > stack index). The drift-check protocol governs the rest.

## How ETYB surfaces currency to the user

Inside Stack-sourced responses, the signature block gets extra lines on Tier 1-4 responses:

```
─────
ETYB · <role> · <stack>
Stack knowledge as of <YYYY-MM-DD from in-repo page> · stacks/<vendor>/<page>.md
What's new — etyb.ai/changelog
```

For strict-path responses where ETYB grounded in fetched authoritative sources, also cite the `authoritative_url` inline (not just in the signature) — the user should see the source for the specific claim, not have to hunt.

## What does NOT need currency discipline

- Specialist references (`references/specialists/<name>/*`) — these are engineering principles. They have no `last_verified_on`. If a specialist file embeds a vendor-specific claim, that's a signal the content should migrate to a Stack page under `stacks/<vendor>/`.
- Protocol references (`references/protocols/<name>/*`) — TDD, debugging, review, brainstorming, planning, branch safety, subagents, self-improvement, verification. These are timeless practices.
- Vertical references (`references/verticals/<name>/*`) — mostly timeless except for regulatory-adjacent content (HIPAA enforcement dates, PCI scope changes, SOC 2 framework versions). For those *narrow* sections, embed a Stack-style currency line manually.

## Maintainer responsibilities

The script `scripts/maintainer/check-currency.sh` audits the in-repo Stack content:
- Walks every `stacks/<vendor>/SKILL.md` and every sibling product/role file
- Flags `last_verified_on` older than the drift-risk threshold (high=90d, medium=180d, low=365d)
- Optionally probes `authoritative_url` reachability with `CHECK_CURRENCY_FETCH=1`

It runs as part of `validate-pr.sh` and on a periodic cron (configured externally — the script is the building block, not the scheduler).

When you author a new Stack page:
- `last_verified_on` is today
- `drift_risk` with rationale in `notes`
- `authoritative_url` is reachable
- If a vendor MCP/skill exists, it is listed in `delegate_to_skills` on the Stack's `SKILL.md`

When you refresh an existing Stack:
- Bump `last_verified_on` to today on every page you reviewed
- Update product pages if products were added/removed/renamed by the vendor
- Update `authoritative_url` if it moved
- Note the verification basis in the commit message ("verified against Cloudflare changelog through 2026-05-14")

## Anti-patterns to refuse

- Answering "what's the latest [vendor] feature in [product]?" from baked knowledge alone when a vendor MCP/skill is installed. Always defer.
- Treating the slim `stacks/<vendor>/SKILL.md` as the source of truth for product specifics. The slim pointer carries gotchas + detection signals; depth lives in the sibling product/role files.
- Quoting specific version numbers, API signatures, CLI flags, or pricing without applying the drift-check protocol.
- Treating any `last_verified_on` as a guarantee of accuracy. It's a timestamp of last review, not a promise of current truth.
- Forgetting to surface the currency disclosure to the user. Silent stale knowledge is worse than stated stale knowledge.
- Copying vendor docs verbatim into an in-repo page. The page's job is *opinionated knowledge a specialist needs* — when, why, tradeoffs, integration patterns, gotchas. The official docs are the source of truth for specifics; the in-repo page tells the team how to think about them.
