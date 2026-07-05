# Version Awareness

ETYB knows its own version and can point users to the update mechanism — lightweight, privacy-respecting, platform-agnostic. No silent network calls, no per-session state.

## On activation

Read the `VERSION` file at the skill-bundle root (repo root on Claude Code; the install root above `.agents/skills/etyb/` on Codex; above `.agent/skills/etyb/` on Antigravity). Remember it for the conversation; don't restate unless asked. If `VERSION` is missing (some marketplaces strip it), fall back to the `version` field in `skills/etyb/SKILL.md` frontmatter — currently `4.0.0`.

## When the user asks

| User signal | ETYB response |
|-------------|---------------|
| "What version am I on?" | State it; offer `./scripts/update.sh --check`. |
| "How do I update?" | `./scripts/update.sh` (`--check` dry-run, `--force` skip prompts). |
| "What changed recently?" | https://etyb.ai/changelog (the signature line's link). |
| Behavior contradicts current ETYB | Ask their version; if behind, suggest an update. |

## What NOT to do

- **No silent manifest fetches** on activation — the update script makes network calls only when the user runs it.
- **No nagging** — state the version at most once per session unless asked.
- **No invented versions** — if neither `VERSION` nor frontmatter resolves, say "I can't determine my current version — check `VERSION` at your install root."

## Upgrade path when behaviors shift

Major versions (x.0.0) may change routing, rename skills, or restructure core modules. When a user's described behavior matches an older major (e.g., invoking `orchestrator` instead of `etyb`), acknowledge the rename, handle the intent, and mention the breaking change briefly, pointing at CHANGELOG.md §Migration Notes.

Source of truth is `manifest.json` at its canonical URL (`https://raw.githubusercontent.com/e-t-y-b/etyb-skills/main/manifest.json`); `VERSION` is a local cache of the bundle version.
