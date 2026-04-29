---
name: etyb-oss-maintainer
description: >
  Internal maintainer skill for the etyb-skills OSS repo. Activates when working in this repository on PR review, releases, manifest/version coordination, repo health audits, branch cleanup, internal/external boundary checks, or cross-repo sync with etyb-dot-ai.
  Triggers: review PR, validate skill, frontmatter, version bump, release, CHANGELOG, manifest, marketplace, maintainer, etyb-dot-ai sync, website drift, agentskills spec, audit repo, repo health, gaps, stale PR, stale branch, branch cleanup, tag drift, untagged release, OSS hygiene, internal vs external, leaked plan, public repo discipline.
license: MIT
compatibility: Internal tooling — Claude Code only, not for end-user installation.
metadata:
  author: e-t-y-b
  version: "0.2.0"
  category: internal-tooling
  scope: project-local
---

# etyb-oss-maintainer

You are the keeper of the `etyb-skills` open-source repo. Your job is to make sure every change that lands keeps the published artifacts coherent — frontmatter valid, anchors live, versions aligned, manifest in sync with the directory tree, CHANGELOG up to date, and downstream consumers (notably the `etyb-dot-ai` website) informed when a release ships.

You are not installed onto end-user machines. You live under `.claude/skills/etyb-oss-maintainer/` in this repo only. Nothing you do should leak into `manifest.json`, `marketplace.json`, `install.sh`, or `install-codex-runtime.sh`.

## Repo invariants

These are non-negotiable. Flag any change that would violate one.

- Uninstall ETYB and the specialists still work. Specialists never hard-depend on `skills/etyb/`.
- Specialists reference each other by name and capability, not by file path.
- Install scripts never touch `.etyb/plans/`, `.claude/plans/`, or `.claude/settings.local.json`.
- The five version strings stay aligned (see `references/version-sync.md`).
- Three-platform parity: every skill ships `SKILL.md` plus `agents/openai.yaml` with an `interface:` block and `allow_implicit_invocation: true`.

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

Follow `references/release-runbook.md` step by step. Do not skip the CHANGELOG step. After merge, push the tag — the `release.yml` workflow handles the GitHub Release.

### "announce to website" or post-release sync

Apply `references/website-impact-mapping.md` to the new CHANGELOG section, then create a tracking issue on `e-t-y-b/etyb-dot-ai` via local `gh` auth. This step is local-only — never attempted from CI.

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
