@AGENTS.md

# Claude Code notes

- **Install path**: the plugin manifest at `.claude-plugin/plugin.json` is how Claude Code
  installs this repo (plugin name `etyb`).
- **Hooks are wired via the plugin (since v5.0.0)**: `hooks/hooks.json` registers five
  advisory hooks — TDD pre-edit check, pre-merge verify, post-edit log, post-test log,
  pre-commit review check — plus a SessionStart stub. They warn via `systemMessage` and
  never block. Skills-CLI installs on other harnesses get no hooks; disciplines there
  are instruction-only.
- **Consolidated core module**: the former `signature.md`, `response-formats.md`,
  `scale-calibration.md`, and `always-on-protocols.md` are merged into
  `skills/etyb/core/session.md`. Grep hits for the old filenames are stale references —
  read `session.md` instead.
