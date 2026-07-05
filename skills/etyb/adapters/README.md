# Platform adapters

The portable core (SKILL.md + core/ + references/) runs on any harness that
supports the Agent Skills open standard. Adapters layer platform-specific
enforcement on top — hooks, native subagents, plan-mode integration. If no
adapter exists for your platform, the core still works in model-trusted
mode.

| Platform | Path | Enforcement surface |
|----------|------|---------------------|
| Claude Code | [`claude/`](claude/) | Plugin hooks + custom agents (ships in M2; model-trusted until then) |
| OpenAI Codex | [`codex/`](codex/) | `.codex/` agents + Python hooks (see repo root `.codex/`) |
| Google Antigravity | [`antigravity/`](antigravity/) | Markdown-first, model-trusted |

From v5 M2 onward, adapter outputs are GENERATED from the shared agent
definitions by `scripts/build-adapters.sh` — edit the source definitions,
not the emitted files. See `docs/plan/skills-5.0-plan.md` (M2-T5).
