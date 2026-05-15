# Knowledge currency — maintainer responsibilities

As of v4.0.0, every Stack Pack carries currency metadata in YAML frontmatter (`last_verified_on`, `authoritative_sources`, `delegate_to_skills`, `products_covered` with per-product `drift_risk`). The protocol that uses this metadata lives in `skills/etyb/core/knowledge-currency.md`; this file is the maintainer-side view of how to keep it healthy.

## What a healthy Stack looks like

Every `stacks/<vendor>/SKILL.md` frontmatter must have:

```yaml
metadata:
  last_verified_on: "YYYY-MM-DD"        # today, on every Stack-touching commit
  applies_to_roles: [...]               # which specialists this overlay supports
authoritative_sources:
  primary:                              # at minimum: official docs + CLI + changelog
    - { name: "...", url: "...", type: official_docs|cli_reference|api_reference|changelog }
delegate_to_skills:                     # vendor MCPs/skills to defer to when installed
  - { skill: "<id>", covers: [product1, product2] }
products_covered:                       # complete product list with drift risk
  - { name: <Product>, drift_risk: high|medium|low, notes: "..." }
```

## Drift-risk thresholds (enforced by `check-currency.sh`)

| Drift risk | Refresh threshold | Examples |
|---|---|---|
| **high** | 90 days | LLM provider APIs, AI Gateways, vendor SDKs in active redesign, compliance enforcement dates, payment-flow specifics |
| **medium** | 180 days | Mature managed services with quarterly feature drops (Lambda, Cloud Run, AKS), framework releases (Next.js minor versions) |
| **low** | 365 days | Stable primitives (Cloudflare KV semantics, S3 base API, Postgres core), long-standing CLIs |

When a Stack contains a product whose risk has elevated (e.g., Cloudflare AI Gateway moves from medium to high after major reshuffling), bump `drift_risk` on that product and refresh content before the new threshold kicks in.

## Validator: `scripts/maintainer/check-currency.sh`

- Walks every Stack's frontmatter
- Computes `today - last_verified_on` in days
- Flags any Stack where the age exceeds the threshold for any of its products' `drift_risk`
- Optional URL probe: `CHECK_CURRENCY_FETCH=1 ./scripts/maintainer/check-currency.sh` does a HEAD on every `authoritative_sources.primary` URL to catch 404s
- Plugs into `validate-pr.sh` (always runs in PR validation; URL probe is opt-in to avoid CI flakiness from upstream rate limits)

Run before every release. Stale Stacks block the release until they're refreshed.

## Stack refresh PR flow

When `check-currency.sh` flags a Stack:

1. Open a branch `currency/<stack>-refresh-YYYY-MM` (or `currency/<stack>-<product>-refresh` for product-specific drift).
2. Visit each `authoritative_sources.primary` URL listed in the Stack's frontmatter. Read the changelog / release notes since `last_verified_on`.
3. Update Stack content where vendor changes shift recommendations (product renames, deprecated features, new defaults, pricing-model changes, regulatory enforcement dates).
4. Bump `last_verified_on` to today.
5. If products were added/removed/renamed by the vendor, update `products_covered` accordingly.
6. Note the verification basis in the commit message — what changelog ranges you read, what specifically changed in the Stack content.
7. Run `CHECK_CURRENCY_FETCH=1 ./scripts/maintainer/check-currency.sh` to confirm sources still reachable.
8. Open PR. Maintainer review confirms the refresh was real (not just a timestamp bump).

## Cross-skill delegation maintenance

A Stack's `delegate_to_skills` block points at vendor-provided skills/MCPs. Maintain this list when:

- A vendor ships a new MCP server (e.g., when Salesforce-Hosted MCP Servers ship and an installable MCP surface lands in users' environments → add to Salesforce Stack's `delegate_to_skills`)
- A vendor retires an MCP — remove from `delegate_to_skills`
- A vendor renames a skill collection — update the `skill:` identifiers
- The `covers:` list shifts because a vendor moved products between SDKs

The `covers:` array is the routing key — when ETYB sees a query about Product X, it checks every Stack's `delegate_to_skills` for `covers: [..., Product X, ...]` and invokes the matching skill before reading the Stack overlay.

## When a Stack adds or splits

**Adding a new vendor (e.g., shipping a Shopify Stack):**
- Follow STACKS.md "Authoring a new Stack Pack" section
- New Stack starts at v4.x.0 matching current bundle version
- Detection signals go into `core/stack-registry.md`
- Row added to STACKS.md table
- `manifest.json` stacks block extended
- `check-currency.sh` will pick it up automatically

**Splitting a Stack** (e.g., AWS Stack splits into AWS-Compute + AWS-Data + AWS-AI as it grows):
- Create the new sub-stacks
- Original Stack becomes a pointer or remains as the orchestration briefing
- Detection signals in `core/stack-registry.md` redistribute
- Verticals/specialists that referenced the old Stack get updated pointers
- Bumps the bundle to the next minor version (e.g., 4.0.0 → 4.1.0) because the Stack shape changed for users

**Merging Stacks** (rare, usually only when a vendor acquires another):
- Combine contents into one Stack; mark deprecated; add a redirect note in STACKS.md
- Update detection signals
- Note in CHANGELOG

## Anti-patterns to refuse during review

- A Stack PR with no `last_verified_on` bump and no actual content changes (timestamp-only bumps that don't reflect real review work)
- `authoritative_sources` URLs that point at the vendor's homepage rather than specific docs/CLI/changelog pages
- `delegate_to_skills` entries with no `covers:` array — routing can't function without knowing what products a delegate covers
- `products_covered` with everything marked `drift_risk: low` to game the refresh threshold (rarely justified; products in active vendor development are not low-drift)
- Stack content that copies vendor docs verbatim instead of capturing the opinionated knowledge a specialist needs (when/why/tradeoffs/gotchas)
- A new Stack with no detection signals in `core/stack-registry.md` (orphaned — ETYB can't find it)
