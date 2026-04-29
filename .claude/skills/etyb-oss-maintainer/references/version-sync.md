# Version sync

The repo carries the same version string in five different files. They must all agree before release.

| File | JSON path | Notes |
|---|---|---|
| `VERSION` | (text) | Source of truth — single line, plain text. |
| `package.json` | `.version` | npm metadata. |
| `manifest.json` | `.bundle.version` | The published agentskills manifest. |
| `.claude-plugin/marketplace.json` | `.metadata.version` | Claude Code marketplace listing. |
| `.claude-plugin/plugin.json` | `.version` | Claude Code plugin manifest. |

Plus one structural rule:

- `manifest.json .skills` keys must match `skills/*/` directory names exactly — same set, same count.
- `marketplace.json` plugin `etyb-full` must list every `./skills/<name>` exactly once.

## Bumping a version

`scripts/maintainer/validate-version-sync.sh` checks the four JSON files against `VERSION`. The release runbook (`release-runbook.md`) walks through the bump itself.

A common mistake: editing `VERSION` and `package.json` while forgetting `marketplace.json` and `plugin.json`. The validator catches that.

## Per-skill versions

Each skill also carries its own `metadata.version` in its `SKILL.md`. Those move independently of the bundle version — bump only the skills you actually changed in a release. The bundle version itself sits in `VERSION` / `package.json` / `manifest.json .bundle.version`, not in any individual skill's frontmatter.

The `manifest.json .skills` map records the per-skill version each skill is published at; bump it whenever the skill's own `metadata.version` changes.
