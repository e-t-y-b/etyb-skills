# Repo audit playbook

Periodically — and at the start of every release window — run a health check on the repo and surface gaps to the maintainer. This is the judgment layer on top of `scripts/maintainer/audit-repo.sh`.

## How to run

```
scripts/maintainer/audit-repo.sh
```

The script is read-only. It calls `gh` and `git` directly, and skips any section whose tool is missing. Output is grouped by category; warnings are prefixed with ⚠.

## What to look at, in order

### 1. Open PRs

For each open PR the script lists, decide:

- **Stale (> 14d old, no recent activity)** — ping the author, escalate, or close if abandoned.
- **`CHANGES_REQUESTED`** — author hasn't responded to feedback. Same options.
- **`PENDING` review on a non-draft PR** — assign yourself or a CODEOWNER.
- **`mergeable=CONFLICTING`** — ask author to rebase.
- **No CI status** — investigate whether the workflow ran at all.

If a PR has been sitting on `CHANGES_REQUESTED` longer than the stale threshold, recommend closing with a polite explanation and an invitation to reopen once addressed.

### 2. Release tags vs CHANGELOG vs VERSION

The script flags drift across these three. Patterns:

- **`VERSION` ahead of latest tag**: a release was prepared but never tagged. Run step 6 of `release-runbook.md` (tag, push, let `release.yml` cut the GitHub Release).
- **Tag exists but no GitHub Release**: the `release.yml` workflow may have failed for that tag — check `gh run list --workflow=release.yml`. If the CHANGELOG section is missing for that version, that's the likely cause; fix and re-trigger by pushing a no-op to `main` after restoring the section, or run `gh release create` manually.
- **CHANGELOG section missing for current `VERSION`**: do not tag yet. Add the section first.

Recommend: if more than one minor version is missing tags, batch them — write the CHANGELOG sections, then tag in chronological order.

### 3. Branches

The script surfaces:

- **Remote branches already merged into main**: deletable. Recommend `git push origin --delete <name>` after confirming with the author.
- **Stale remote branches (> 30d no commits)**: ask author whether the work is still active. If not, close any associated PR and delete.

The repo has no protection on branch deletion, so cleanup is cheap. The discipline is: do not let the branch list grow past ~5 active feature branches without reason.

### 4. Internal vs external boundary on git

`.gitignore` separates two classes of file:

- **Public** — everything not ignored.
- **Internal** — `MARKETPLACE.md`, `.internal/`, `.etyb/`, `.claude/plans/*`, `docs/plan-*.md`, `.claude/settings.local.json`. Never to be tracked.
- **Internal-but-committed exception** — `.claude/skills/etyb-oss-maintainer/` and `.claude/commands/etyb-oss-maintainer.md` (this skill). Allowed via explicit `!` negation in `.gitignore`. Must not be referenced from `manifest.json`, `marketplace.json`, or any installer.

If the audit reports an internal item leaking into git, treat it as a security concern — strategy notes, draft pitches, customer names, or plan documents may contain non-public detail. Recommend: `git rm --cached <path>` and ensure the gitignore rule is correct. If the leak has already been pushed, weigh whether to history-rewrite (rare, disruptive) or simply remove going forward.

If the audit reports the maintainer skill being referenced in any installer or published manifest, that's a regression — remove the reference, the skill is project-internal only.

### 5. OSS hygiene files

The repo expects:

- `LICENSE` — MIT.
- `README.md` — public-facing, with install + usage.
- `CONTRIBUTING.md` — how to propose a change, SemVer rubric, code style.
- `CODE_OF_CONDUCT.md` — Contributor Covenant or equivalent.
- `SECURITY.md` — disclosure address + supported versions.
- `CHANGELOG.md` — Keep-a-Changelog style, dated sections.
- `.github/CODEOWNERS` — at least one owner for everything.
- `.github/pull_request_template.md` — sets contributor expectations.
- `.github/ISSUE_TEMPLATE/` — at least one template, more for non-trivial repos.

Missing entries are the most common gap when a repo goes public. If anything is missing, recommend a follow-up PR adding the file. Do not block normal review on it, but track it.

### 6. Working tree

Uncommitted or untracked paths in the working tree do not break anything but skew the audit. If untracked paths look like internal artifacts (e.g. an editor scratch file, a copied-in customer doc), recommend `.gitignore` updates — never silently `git add` them.

## Output format the skill should produce

Reply with three sections, in this order:

```
## Hard fails

(items the validators flagged — version drift, manifest drift, frontmatter
errors, new TOC drift, anything blocking a release)

## Gaps

(items the audit script flagged — stale PRs, tag drift, deletable branches,
missing OSS hygiene files, internal leaks)

## Recommendations

(prioritized, smallest-effort-first list of follow-up actions, each with a
one-line "why")
```

Cite the script section that produced each finding. Do not invent items the scripts did not report.
