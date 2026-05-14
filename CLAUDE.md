# ETYB Skills — Virtual Engineering Company (v4)

This is **one coordinated skill** (`/etyb`) backed by 29 internal references that capture the expertise of a 20-specialist + 9-protocol + 6-vertical engineering team. The user only ever invokes `/etyb` — there are no peer slash commands.

## Entry Point

**ETYB** (`skills/etyb/SKILL.md`) is the only skill. Every conversation that touches engineering work routes through it. ETYB reads internal references on demand to operate as the right specialist for the current request.

## Architecture (v4)

```
skills/etyb/
├── SKILL.md                          ← the only trigger surface (/etyb)
├── core/                             ← orchestration modules
│   ├── charter.md                    ← Tier 0-4 classification, CTO identity
│   ├── team-registry.md              ← 20 specialists, domain detection
│   ├── always-on-protocols.md        ← 9 engineering disciplines
│   ├── stack-registry.md             ← Stack Pack overlays (Salesforce, etc.)
│   ├── gates.md                      ← 5-gate sequence, plan lifecycle
│   ├── expert-mandating.md           ← mandatory expert matrix
│   ├── coordination-patterns.md      ← multi-team patterns
│   ├── response-formats.md           ← Tier 1-4 output templates
│   ├── scale-calibration.md          ← startup → enterprise sizing
│   ├── version-awareness.md          ← version & update guidance
│   └── signature.md                  ← ETYB signature + changelog banner
├── references/
│   ├── specialists/                  ← 14 core team READMEs
│   ├── protocols/                    ← 9 always-on protocols
│   ├── verticals/                    ← 6 business-domain architects
│   └── process-architecture.md       ← plan artifact format
├── adapters/                         ← claude / codex / antigravity
└── ...
```

## Always-On Engineering Culture

These disciplines apply to ALL work, ALL tiers, ALL gates:

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

The hooks live at `skills/etyb/references/protocols/<protocol>/hooks/` (e.g., `tdd-protocol/hooks/pre-edit-check.sh`). Claude Code's adapter (`skills/etyb/adapters/claude/`) wires them in.

## Install Tiers

| Tier | Contents | Audience |
|------|----------|----------|
| `lite` | ETYB + 9 protocols + 3 essential specialists | Solo devs, students |
| `core` | + 11 more specialists (14 total) | Most teams |
| `pro` | + 6 verticals | Domain-specific shops |

Install with `scripts/install.sh --tier lite|core|pro`. Default is `pro`.

## Signature

Every Tier 1-4 response ends with:
```
─────
ETYB · <role-engaged>
What's new — etyb.ai/changelog
```

Spec: `skills/etyb/core/signature.md`.
