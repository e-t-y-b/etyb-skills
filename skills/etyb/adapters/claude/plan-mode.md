# Claude Plan Mode Integration

Claude Code has a built-in plan mode that creates plan files in `.claude/plans/`. When active, ETYB annotates Claude's plan rather than duplicating into `.etyb/plans/`.

## Detection

Check these signals in order:
1. Claude explicitly states it is in plan mode
2. The conversation context shows plan mode was entered
3. A plan file exists in `.claude/plans/`

## When Claude Plan Mode Is Active

Annotate the Claude plan with process architecture sections from `core/gates.md`:

- **Gate Status** — current gate and status for each phase gate
- **Expert Assignments** — mandatory and optional experts with their roles at each gate
- **Verification Checkpoints** — what needs to be verified before each gate passes
- **Decision Log** — architectural decisions with rationale
- **Risk Register** — identified risks with mitigations

All of these come from `core/gates.md` and `core/expert-mandating.md`. The adapter's job here is purely to say "put those inside Claude's plan file rather than creating `.etyb/plans/`."

## When Claude Plan Mode Is Not Active

Create a standalone plan artifact at `.etyb/plans/{plan-name}.md` using the full template from `references/process-architecture.md`.

## Dual Plan Resolution

If both a Claude plan and `.etyb/plans/` artifact exist:

| Situation | Action |
|-----------|--------|
| Claude plan is canonical | Merge `.etyb/plans/` into Claude plan annotations, remove the duplicate |
| `.etyb/plans/` was created first | Migrate to Claude plan annotations if plan mode is later activated |
| User explicitly wants `.etyb/plans/` | Honor preference, add a cross-reference in the Claude plan |

> **Reference:** See `skills/etyb/references/process-architecture.md` §8 for the full Claude plan mode integration protocol.

## Where Plans Live — Decision Tree

```
Is Claude plan mode active?
├── Yes → Annotate the Claude plan in .claude/plans/
└── No  → Does .etyb/plans/{name}.md exist?
         ├── Yes → Update it
         └── No  → Create .etyb/plans/{name}.md using the template
```

This decision tree is Claude-specific. On other platforms, plans always live at `.etyb/plans/{name}.md` (see respective adapter for any platform-specific variations).
