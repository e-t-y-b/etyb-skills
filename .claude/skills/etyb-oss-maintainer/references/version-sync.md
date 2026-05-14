# Version sync

As of v3.0.0 the repo uses a **single-version policy**: the bundle version is the only version that exists. Every skill, every stack, every artifact tracks it. They move on every release, period. No per-skill or per-stack version drift is allowed.

This avoids the bookkeeping debt where a skill's `metadata.version` and its manifest entry diverged (we saw 2.0.0 vs 2.1.0 drift on the etyb skill before v3.0.0). It also drops a category of error that delivered no actual signal — ETYB ships as a bundle, no one installs a single specialist.

In v4.0.0 the bundle shape collapsed from 30 sibling skills to one coordinated skill (`etyb`) with 29 internal references. The single-version policy still applies — it now has fewer places to bookkeep.

## What carries the version

| Location | Field | Notes |
|---|---|---|
| `VERSION` | (text) | Source of truth — single line, plain text. |
| `package.json` | `.version` | npm metadata. |
| `manifest.json` | `.bundle.version` | The published agentskills manifest. |
| `manifest.json` | `.skill.etyb` | v4: single-skill block (was `.skills.*` pre-v4). |
| `manifest.json` | `.stacks.*.version` (every entry) | Every stack tracks the bundle. |
| `.claude-plugin/marketplace.json` | `.metadata.version` | Claude Code marketplace listing. |
| `.claude-plugin/plugin.json` | `.version` | Claude Code plugin manifest. |
| `skills/etyb/SKILL.md` | frontmatter `metadata.version` | The single skill's frontmatter. |
| `stacks/*/SKILL.md` | frontmatter `metadata.version` | Every stack frontmatter tracks the bundle. |

The 29 internal references under `skills/etyb/references/` do **not** carry frontmatter — they are README.md files, not SKILL.md files. They are not separately versioned.

Plus structural rules:

- `manifest.json .skill` must contain exactly one key (`etyb`) — v4 ships one installable skill.
- `manifest.json .stacks` keys must match `stacks/*/` directory names exactly.
- `marketplace.json` must contain exactly one plugin (`etyb`) listing only `./skills/etyb`.
- `manifest.json .tiers` must contain `lite`, `core`, `pro`.

## What does NOT count as a version

The Salesforce stack pack carries `metadata.last_verified_release: "Spring '26"` and `verified_on: "2026-05-12"` in its frontmatter. Those are *currency stamps* — which platform release the content has been validated against, and when. They are separate from the artifact version and move on a different cadence (per-platform-release, not per-bundle-release).

## Bumping a version

`scripts/maintainer/validate-version-sync.sh` enforces the single-version policy across all locations above. The release runbook (`release-runbook.md`) walks through the bump itself, which is a single sweep:

```bash
# Set the new version in 5 bundle files, manifest .skill.etyb,
# manifest .stacks.*.version, and skills/etyb/SKILL.md + stacks/*/SKILL.md frontmatter.
# Run the validator to confirm.
scripts/maintainer/validate-version-sync.sh
```

A common mistake: editing `VERSION` and `package.json` while forgetting `marketplace.json` and `plugin.json`. The validator catches that plus every per-stack / per-frontmatter location.

## Historical notes

- **Pre-v3.0.0**: per-skill versions moved independently of the bundle, producing silent drift. Retired in v3.0.0.
- **v3.0.0 → v4.0.0**: `manifest.json .skills` (30 entries) collapsed to `manifest.json .skill` (1 entry). The validator was updated to check `.skill` rather than `.skills`; legacy `.skills` is still readable as a fallback for any artifact pinned to an older shape.
