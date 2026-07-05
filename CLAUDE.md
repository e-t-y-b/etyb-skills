@AGENTS.md

# Claude Code notes

- **Install path**: the plugin manifest at `.claude-plugin/plugin.json` is how Claude Code
  installs this repo (plugin name `etyb`).
- **Hooks are not wired yet**: deterministic hook enforcement (TDD pre-edit check,
  pre-merge verify, pre-commit review check) ships in milestone M2 via plugin `hooks.json`.
  Until then, no hooks fire from this repo — do not claim otherwise.
- **Consolidated core module**: the former `signature.md`, `response-formats.md`,
  `scale-calibration.md`, and `always-on-protocols.md` are merged into
  `skills/etyb/core/session.md`. Grep hits for the old filenames are stale references —
  read `session.md` instead.
