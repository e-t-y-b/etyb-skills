# Version Awareness

ETYB knows its own version and can point users to the update mechanism. This is lightweight, privacy-respecting, and platform-agnostic — no silent network calls, no per-session state to manage.

## On Activation

When ETYB activates, read the `VERSION` file at the skill-bundle root (typically `<install-root>/VERSION`, which on Claude Code is `VERSION` at the repo root, on Codex is under `.agents/skills/etyb/../../../VERSION`, on Antigravity is under `.agent/skills/etyb/../../../VERSION`). If found, remember the version for this conversation — it does not need to be restated unless the user asks.

If the `VERSION` file is missing, assume the skill was installed via a mechanism that doesn't ship `VERSION` (some marketplaces may strip it). In that case, use the `version` field in `skills/etyb/SKILL.md` frontmatter as a fallback — currently `2.0.0`.

## When The User Asks

Situations where version information is relevant:

| User signal | ETYB response |
|-------------|---------------|
| "What version of ETYB am I on?" | State the version. Offer `./scripts/update.sh --check` if they want to see if newer is available. |
| "How do I update?" | Point at `./scripts/update.sh`. Mention `--check` for dry-run, `--force` to skip prompts. |
| "What changed recently?" | Link to CHANGELOG.md at the repo root or on GitHub. |
| User mentions behavior that contradicts current ETYB | Ask what version they're on. If it's behind, suggest an update. |

## What NOT To Do

- **Do not fetch the manifest silently** on every activation. Users object to unannounced network calls. The update script makes calls only when the user runs it.
- **Do not nag.** If you state the version once in a session, don't repeat it unless asked again.
- **Do not invent versions.** If you cannot read `VERSION` and the frontmatter doesn't have it, say "I can't determine my current version — check `VERSION` at your install root."

## Upgrade Path When Behaviors Shift

Major versions (x.0.0) may change orchestrator routing, rename skills, or restructure core modules. When the user describes behavior that matches an older major version (e.g., they invoke `orchestrator` instead of `etyb`), acknowledge the rename, handle the intent, and mention the breaking change briefly:

> I handle this under the name `etyb` now — the skill was renamed in 2.0.0. Same behavior, new identity. If you want to update other references, see CHANGELOG.md §Migration Notes.

## Relationship To Platform Adapters

- **Claude Code** — `VERSION` lives at the repo root in a clone. Users typically clone+install and `./scripts/update.sh` works directly.
- **Codex** — installed via `.agents/skills/`; the script's `cd "$(dirname "$0")/.."` navigates out. VERSION may be stripped by some installers; fall back to frontmatter.
- **Antigravity** — `.agent/skills/` layout; same fallback applies.

The source of truth is always `manifest.json` at the canonical URL in the manifest itself (`https://raw.githubusercontent.com/e-t-y-b/etyb-skills/main/manifest.json`). `VERSION` is a local cache of the bundle version.
