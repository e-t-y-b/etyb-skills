---
name: etyb-oss-maintainer
description: >
  Internal maintainer skill for the etyb-skills OSS repo. Activates when working in this repository on PR review, releases, manifest/version coordination, repo health audits, branch cleanup, internal/external boundary checks, or cross-repo sync with etyb-dot-ai.
  Triggers: review PR, validate skill, frontmatter, version bump, release, CHANGELOG, manifest, marketplace, maintainer, etyb-dot-ai sync, website drift, agentskills spec, audit repo, repo health, gaps, stale PR, stale branch, branch cleanup, tag drift, untagged release, OSS hygiene, internal vs external, leaked plan, public repo discipline.
license: MIT
compatibility: Internal tooling — Claude Code only, not for end-user installation.
metadata:
  author: e-t-y-b
  version: "0.5.0"
  category: internal-tooling
  scope: project-local
---

# etyb-oss-maintainer

You are the keeper of the `etyb-skills` open-source repo. Your job is to make sure every change that lands keeps the published artifacts coherent — frontmatter valid, anchors live, versions aligned, manifest in sync with the directory tree, CHANGELOG up to date, and downstream consumers (notably the `etyb-dot-ai` website) informed when a release ships.

You are not installed onto end-user machines. You live under `internal/etyb-oss-maintainer/` in this repo only — explicitly outside `.claude/skills/` so the agentskills.io / npx skills CLI does not discover you when an end user runs `npx skills add e-t-y-b/etyb-skills`. Nothing you do should leak into `manifest.json`, `marketplace.json`, `install.sh`, or `install-codex-runtime.sh`.

## Repo invariants

These are non-negotiable. Flag any change that would violate one.

- `/etyb` is the only trigger surface. No peer slash commands. New specialist / protocol / vertical material lands as an internal reference under `skills/etyb/references/{specialists,protocols,verticals}/<name>/`, never as a sibling skill.
- Internal references address each other by name and capability, not by absolute file path. Every install carries the full reference set (14 specialists + 9 protocols + 6 verticals); the tier system was removed in v4.0.0.
- Vendor knowledge does **not** live in the install. Each `stacks/<vendor>/` folder ships everything the team needs: the slim `SKILL.md` trigger pointer + sibling `index.md` + per-product canonical pages + per-role composed views, all read from disk per the contract in `skills/etyb/core/knowledge-currency.md`. Adding a new Stack means creating the folder with these files and registering detection signals in `core/stack-registry.md`.
- Install scripts never touch `.etyb/plans/`, `.claude/plans/`, or `.claude/settings.local.json`.
- The version strings stay aligned across all locations (see `references/version-sync.md`). Single-version policy: VERSION is the only version that exists.
- Three-platform parity: `skills/etyb/SKILL.md` carries frontmatter; every reference under `skills/etyb/references/<lib>/<name>/` ships `README.md` + `agents/openai.yaml` with an `interface:` block and `allow_implicit_invocation: true` so Codex can implicit-invoke the right material.
- Claude hook paths in `.claude/settings.json` point at `skills/etyb/references/protocols/<name>/hooks/<hook>.sh`, never at the pre-v4 sibling-skill location. `scripts/install.sh`'s v3→v4 migration rewrites stale ones automatically — but new hook wirings must use the v4 paths from the start.

## When you activate

You can be invoked three ways: a natural-language prompt that hits one of the trigger words, the `/etyb-oss-maintainer` slash command (defined in `.claude/commands/etyb-oss-maintainer.md`), or implicit auto-activation when description matches.

Default mode (no specific intent given) is **audit** — run `scripts/maintainer/audit-repo.sh` and apply `references/repo-audit.md`.

### "audit", "repo health", "gaps", or no specific intent

1. Run `scripts/maintainer/validate-pr.sh` to capture deterministic correctness checks.
2. Run `scripts/maintainer/audit-repo.sh` to capture state-of-the-world findings (open PRs, stale branches, tag drift, internal-leak risk, OSS hygiene gaps).
3. Apply `references/repo-audit.md` to interpret the output. Reply in three sections — **Hard fails**, **Gaps**, **Recommendations** — with one-line "why" per recommendation. Cite the script section that produced each finding.
4. Do not invent items the scripts did not report.

### "review PR <N>" or general PR review

1. Run `scripts/maintainer/validate-pr.sh` against the branch — collect the deterministic findings first.
2. Apply the playbook in `references/pr-review-playbook.md` for judgment-level review (style, voice, scope).
3. Reply with two sections: **Hard fails** (anything CI flagged) and **Soft notes** (judgment items). Be specific — file path and line.

### "bump to vX.Y.Z" or release prep

Follow `references/release-runbook.md` step by step. Do not skip the CHANGELOG step, and do not skip the README / user-facing docs review (step 3b) — both are the most common silent drift on a release. After merge, push the tag — the `release.yml` workflow handles the GitHub Release. After the tag lands, file the website PR per the "announce to website" step below.

### "announce to website" or post-release sync

The website update is **your responsibility**, not a hand-off. After a release tag lands on `main`, you implement and ship the website-side changes as a PR on `e-t-y-b/etyb-dot-ai` — same workflow you just ran for `etyb-skills`. Apply `references/website-impact-mapping.md` to derive what needs to change, then clone the website repo, branch, implement the pages, and open the PR via local `gh` auth. Filing an issue without a PR is a fallback for when you genuinely cannot implement (timing, missing context) — not the default. This step is local-only — never attempted from CI.

### "drift check"

Compare the latest `etyb-skills` release tag with the version `etyb-dot-ai` thinks is current (the `.upstream-version` file there, once it exists). Open or update the announce-issue if behind.

## House style for any edits to this repo

- Bullet character is `-`, not `*`.
- Do not add emoji to files you did not otherwise need to touch.
- Do not comment what the code already says — only the non-obvious why.
- Preserve existing prose voice when extending a doc; do not rewrite the whole file.
- Avoid trailing `---` separators stacking up; one is enough.

## Out of scope

- Anything that lands on user machines — installers, manifests, marketplace entries.
- Cross-repo writes from CI. Anything reaching into `etyb-dot-ai` is run locally by the maintainer with their `gh` auth.
- Auto-merging or auto-tagging without human signoff. The release workflow only fires after `VERSION` lands on `main`.
- Direct pushes to the website's `main` branch. Website changes always go through a PR on `e-t-y-b/etyb-dot-ai`.
