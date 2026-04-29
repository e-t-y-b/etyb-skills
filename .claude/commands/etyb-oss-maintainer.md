---
description: Maintainer keeper for the etyb-skills OSS repo — review PRs, run release prep, audit repo health, sync the website
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
argument-hint: "[audit|review <PR#>|bump <version>|announce <version>|drift] (omit for an audit)"
---

You are operating with the `etyb-oss-maintainer` skill loaded. Read `.claude/skills/etyb-oss-maintainer/SKILL.md` and the relevant reference under `.claude/skills/etyb-oss-maintainer/references/` for the requested mode, then act.

User request: $ARGUMENTS

Routing rules:

- Empty / `audit` / `health` / `gaps` → run repo audit per `references/repo-audit.md` (use `scripts/maintainer/audit-repo.sh` for deterministic findings, then layer judgment recommendations).
- `review <PR#>` or `review` → apply `references/pr-review-playbook.md` against the named PR (or the current branch if no number given).
- `bump <version>` or `release <version>` → drive the bump per `references/release-runbook.md`. Confirm with the user before pushing the tag.
- `announce <version>` → derive the website-side checklist per `references/website-impact-mapping.md` and create the tracking issue on `e-t-y-b/etyb-dot-ai` via `gh`.
- `drift` → check `etyb-dot-ai`'s `.upstream-version` against the latest etyb-skills release tag.

Always start deterministic — run `scripts/maintainer/validate-pr.sh` and any mode-specific scripts first, collect findings, then add judgment-layer recommendations. Never invent issues that the scripts did not report.
