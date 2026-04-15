# Contributing to ETYB-Skills

Thanks for considering a contribution. This doc describes how we accept changes.

## The Short Version

1. Fork the repo
2. Create a branch from `main`
3. Make changes, keeping commits focused
4. Open a PR against `e-t-y-b/etyb-skills:main`
5. Fill out the PR template
6. Wait for review from [@re-manish](https://github.com/re-manish) (sole approver)
7. Address feedback; maintainer merges when ready

Direct pushes to `main` are blocked by branch protection. All changes go through PR.

## What We Accept

- **Bug fixes** — scripts, docs, skill behavior, frontmatter spec compliance
- **Content improvements** — clearer prose, better examples, up-to-date references in specialist skills
- **New specialist skills** — must follow the existing skill structure (SKILL.md + references/) and the [agentskills.io spec](https://agentskills.io/specification). Propose via issue first.
- **New process protocols** — same guidance as new specialists. Higher bar — the protocol must be genuinely always-on, not situational.
- **Adapter improvements** — better platform integration for Claude Code, Codex, or Antigravity. New adapters for other agentskills.io-compliant platforms welcome.

## What We Don't Accept

- Changes that break the "uninstall ETYB → specialists still work" invariant
- New hard dependencies between specialists (reference by name/capability, not path)
- Silent data-touching changes to install/update scripts (they must never modify `.etyb/plans/`, `.claude/plans/`, or `.claude/settings.local.json`)
- Large refactors without a prior issue discussion
- Adding emoji, docstrings, or comments to code you didn't otherwise touch

## Required for Every PR

- `CHANGELOG.md` updated if user-visible behavior changes
- `manifest.json` updated if you added/removed a skill or bumped versions
- Frontmatter compliance — run the check described in [docs/installation.md](docs/installation.md) troubleshooting section if unsure
- No internal working docs committed (they live in `.gitignore`)

## Commit Messages

Keep them descriptive. A good commit message states *what* changed and *why*. See recent commits for the style.

Co-author tags are welcome but not required.

## Versioning

This project uses [SemVer](https://semver.org/). Contributors don't decide version bumps — the maintainer does that at release time — but flag in your PR if you think your change is major, minor, or patch.

- **Major** — breaking changes (skill renames, removed fields, incompatible path changes)
- **Minor** — new skills, new features, backward-compatible additions
- **Patch** — bug fixes, doc corrections, content improvements

## Questions

Open an issue or start a [discussion](https://github.com/e-t-y-b/etyb-skills/discussions) (once enabled).
