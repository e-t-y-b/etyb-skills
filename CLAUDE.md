# ETYB Skills — Virtual Engineering Company

This is a collection of 29 AI agent skills organized as a virtual engineering team.

## Entry Point

The **orchestrator** (`orchestrator/SKILL.md`) is the main skill. It routes requests to the right domain experts and activates process protocols. Start here for any engineering work.

## Architecture

- **Orchestrator** (1) — CTO-level routing, gate enforcement, plan management
- **Domain Experts** (20) — 14 core teams + 6 vertical specialists (WHO/WHAT)
- **Process Protocols** (7) — Always-on engineering disciplines (HOW)
- **Orchestrator References** (3) — Verification, debugging, process architecture (WHEN/WHERE)

## Always-On Engineering Culture

These disciplines are embedded in the orchestrator and enforced by hooks:

1. **TDD** — No code without a failing test first
2. **Verification** — Evidence before claims, always
3. **Review** — No performative agreement, push back with evidence
4. **Plan Execution** — One task at a time, verify before advancing
5. **Brainstorm-First** — Explore before solving (for ambiguous requests)
6. **Branch Safety** — Never merge without green tests
7. **Subagent Coordination** — One agent per domain, two-stage review
8. **Self-Improvement** — No skill change without failing eval
9. **Debugging** — Root cause first, one variable at a time

## Hook Enforcement

Hooks in `.claude/settings.json` fire deterministically, outside the LLM:
- `pre-edit-check` — Warns if editing source without test file
- `pre-merge-verify` — Blocks merge if tests fail
- `pre-commit-review-check` — Warns if no review evidence before commit
