# Changelog

All notable changes to ETYB Skills are documented here. Format is loosely based on [Keep a Changelog](https://keepachangelog.com/). Versions follow [SemVer](https://semver.org/).

## [2.1.0] — 2026-04-16

The Codex runtime release. ETYB now ships with full OpenAI Codex runtime support — lifecycle hooks, custom agents, and per-skill metadata — upgrading Codex from model-trusted to partial runtime-enforced.

### Added

- **Codex lifecycle hooks** (`.codex/hooks/`). 4 Python hooks — `UserPromptSubmit` (blocks gate-skipping prompts), `PreToolUse` (guards merge/commit without tests), `PostToolUse` (captures test pass/fail signals), `Stop` (blocks completion claims without verification evidence).
- **Codex custom agents** (`.codex/agents/`). 4 TOML-defined agents — explorer, planner, reviewer, docs researcher — providing Codex-native parallel dispatch.
- **Per-skill Codex metadata** (`agents/openai.yaml`). All 30 skills now ship with `interface` + `policy` metadata for Codex skill discovery.
- **Codex runtime installer** (`scripts/install-codex-runtime.sh`). Installs `.codex/` config, hooks, and agents into any project with conflict detection and backup.
- **Codex runtime evals** (`skills/etyb/evals/codex-runtime-evals.json`). Eval suite for verifying hook behavior on a real Codex instance.
- **Portability linter** (`scripts/lint-portability.sh`). Cross-platform compliance checker — validates skill count, Codex metadata, plan path portability, and doc consistency.

### Changed

- **Codex enforcement upgraded.** Platform status changed from "model-trusted" to "partial runtime-enforced + model-trusted gaps." Edit-before-test remains model-trusted; all other gates now have hook support.
- **README overhauled.** OG image banner, platform badges, dedicated platform support table, restructured install section with Codex runtime details.
- **`.gitignore` updated.** Added `.etyb/` (runtime plan artifacts) and `__pycache__/` (Codex hook bytecode).

## [2.0.0] — 2026-04-15

The portability release. ETYB is now a cross-platform virtual engineering team with adapters for Claude Code, OpenAI Codex, and Google Antigravity. Skills are reorganized for independent use on any agentskills.io-compliant platform.

### Breaking

- **`orchestrator` skill renamed to `etyb`.** The folder moved from `skills/orchestrator/` to `skills/etyb/`. Any code or prompts invoking the old name must be updated. Motivation: the skill IS the product brand — one name across marketplace, repo, invocation.
- **`etyb/references/verification-protocol.md` → `skills/verification-protocol/`.** Verification is now its own peer skill. Specialists that referenced the old path have been updated; external references need to update to `skills/verification-protocol/references/verification-methodology.md`.
- **`etyb/references/debugging-protocol.md` → `skills/debugging-protocol/`.** Same pattern as verification.
- **Installable skill count: 28 → 30.** Two new peer protocol skills (verification-protocol, debugging-protocol) extracted from etyb's references.

### Added

- **Portable core architecture.** `skills/etyb/SKILL.md` is now a 65-line thin entry point pointing at eight focused core modules (`core/charter.md`, `team-registry.md`, `gates.md`, `expert-mandating.md`, `coordination-patterns.md`, `response-formats.md`, `scale-calibration.md`, `always-on-protocols.md`). Core modules are platform-neutral and loadable on demand.
- **Claude Code adapter** (`skills/etyb/adapters/claude/`) — ADAPTER.md, hooks.md, plan-mode.md, subagents.md. Deterministic hook enforcement; flagship experience.
- **OpenAI Codex adapter** (`skills/etyb/adapters/codex/`) — ADAPTER.md, enforcement-notes.md, openai-yaml-example.md. Grounded in the current Codex skill model.
- **Google Antigravity adapter** (`skills/etyb/adapters/antigravity/`) — ADAPTER.md, enforcement-notes.md, adk-integration.md. Markdown-first, model-trusted, with ADK documented as a future path.
- **`verification-protocol` skill** — the Five Verification Questions, universal completion report, done criteria per gate, evidence standards. Independently installable.
- **`debugging-protocol` skill** — root-cause-first methodology, hypothesis-driven debugging, one-variable rule, three-failure escalation. Independently installable.
- **`VERSION` file, `manifest.json`, `CHANGELOG.md`** at repo root for versioning and update-mechanism infrastructure.

### Changed

- **Bundle name/brand alignment.** Plugin descriptions, marketplace configs, README, CLAUDE.md, architecture.md, and all cross-references now use "ETYB" as the brand name.
- **Frontmatter compliance.** All 30 SKILL.md files validated against the agentskills.io specification — name (lowercase+hyphens, matches parent dir), description (≤1024 chars), compatibility (≤500 chars where present).
- **Specialists are standalone.** Every specialist now works without etyb installed. References to etyb are supplemental cross-references, not hard dependencies. The invariant "uninstall etyb → specialists still function" holds.
- **Counts updated across docs.** 30 total installable skills, 9 process protocols (was 7), 1 reference remaining in etyb (was 3 — two extracted as peer skills).

### Migration Notes

If you had `skills/orchestrator/` installed:
1. `git pull` (or reinstall via your marketplace tool of choice) — the rename is a `git mv` so history is preserved.
2. Update any prompts or scripts invoking `orchestrator` to use `etyb` instead.
3. If you had custom references to `skills/etyb/references/verification-protocol.md` or `skills/etyb/references/debugging-protocol.md`, update them to `skills/verification-protocol/references/verification-methodology.md` and `skills/debugging-protocol/references/debugging-methodology.md`.

## [1.0.0] — 2026-04-14

### Added

- Initial release: 28 installable AI agent skills organized as a virtual engineering company — 1 orchestrator, 14 core teams, 6 domain specialists, 7 process protocols, plus 3 orchestrator references.
