# Version sync

As of v3.0.0 the repo uses a **single-version policy**: the bundle version is the only version that exists. Every skill, every stack, every artifact tracks it. They move on every release, period. No per-skill or per-stack version drift is allowed.

This avoids the bookkeeping debt where a skill's `metadata.version` and its `manifest.json .skills.<name>` entry diverged (we saw 2.0.0 vs 2.1.0 drift on the etyb skill before v3.0.0). It also drops a category of error that delivered no actual signal — ETYB ships as a bundle, no one installs a single specialist.

## What carries the version

| Location | Field | Notes |
|---|---|---|
| `VERSION` | (text) | Source of truth — single line, plain text. |
| `package.json` | `.version` | npm metadata. |
| `manifest.json` | `.bundle.version` | The published agentskills manifest. |
| `manifest.json` | `.skills.*` (every entry) | Every skill in the manifest tracks the bundle. |
| `manifest.json` | `.stacks.*.version` (every entry) | Every stack tracks the bundle. |
| `.claude-plugin/marketplace.json` | `.metadata.version` | Claude Code marketplace listing. |
| `.claude-plugin/plugin.json` | `.version` | Claude Code plugin manifest. |
| `skills/*/SKILL.md` | frontmatter `metadata.version` | Every skill frontmatter tracks the bundle. |
| `stacks/*/SKILL.md` | frontmatter `metadata.version` | Every stack frontmatter tracks the bundle. |

Plus structural rules that have not changed:

- `manifest.json .skills` keys must match `skills/*/` directory names exactly — same set, same count.
- `manifest.json .stacks` keys must match `stacks/*/` directory names exactly.
- `marketplace.json` plugin `etyb-full` must list every `./skills/<name>` exactly once.

## What does NOT count as a version

The Salesforce stack pack carries `metadata.last_verified_release: "Spring '26"` and `verified_on: "2026-05-12"` in its frontmatter. Those are *currency stamps* — which platform release the content has been validated against, and when. They are separate from the artifact version and move on a different cadence (per-platform-release, not per-bundle-release).

## Bumping a version

`scripts/maintainer/validate-version-sync.sh` enforces the single-version policy across all locations above. The release runbook (`release-runbook.md`) walks through the bump itself, which is now a single sweep:

```bash
# Set the new version in 5 bundle files, all manifest .skills.*,
# all manifest .stacks.*.version, and all SKILL.md frontmatter.
# Run the validator to confirm.
scripts/maintainer/validate-version-sync.sh
```

A common mistake before v3.0.0: editing `VERSION` and `package.json` while forgetting `marketplace.json` and `plugin.json`. The new validator catches that plus every per-skill / per-stack / per-frontmatter location.

## Historical note (pre-v3.0.0)

Earlier releases allowed per-skill versions to move independently of the bundle. That policy was retired in v3.0.0 because:

- It produced silent drift (etyb at 2.0.0 in SKILL.md vs 2.1.0 in manifest, masked for releases).
- It delivered no consumer-side signal — there is no per-skill install path.
- It complicated the CHANGELOG (which already enumerates what changed).

Any repo state from before v3.0.0 will have mixed versions across SKILL.md and manifest. That drift was wiped to the new bundle version in the v3.0.0 release.
