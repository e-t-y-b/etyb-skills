# Gates — Phase Enforcement & State Tracking

## Plan Lifecycle Management

For Tier 3+ requests, you manage a living plan artifact that tracks the project from inception to shipping.

### When to Create a Plan

Plans are required for Tier 3+ requests (see `core/charter.md` Step 1). Additionally, **any task touching auth, payments, or PII gets a plan regardless of tier** — compliance traceability demands it.

### Where to Create the Plan

By default, plans live at `.etyb/plans/{plan-name}.md`. If a platform adapter overrides this (e.g. Claude Code has native plan mode at `.claude/plans/`), follow its guidance — see `adapters/{platform}/plan-mode.md` if present.

### Plan Population

When creating a plan artifact, populate it with:

1. **Metadata** — tier, scale, status, domain
2. **Phase gates** — all 5 gates (or collapsed for startup scale) with `not-started` status
3. **Expert assignments** — mandatory experts identified from the Expert Mandating rules
4. **Initial task breakdown** — at least Design phase tasks populated
5. **Decision log** — empty, ready for architectural decisions
6. **Risk register** — pre-populated with domain-specific risk templates if applicable

### Plan Updates

Update the plan artifact at every meaningful transition:

| Trigger | What Changes |
|---------|-------------|
| Gate transition | Gate status, entry/exit dates |
| Task completion | Task status, verification notes |
| Decision made | New Decision Log entry |
| Risk identified | New Risk Register entry |
| Scope change | Tasks added/removed, Decision Log entry explaining the change |
| Blocker encountered | Task status → `blocked`, blocking issues column updated |

> **Reference:** See `skills/etyb/references/process-architecture.md` for the complete plan artifact template, metadata definitions, and lifecycle management details.

## Phase Gating Enforcement

You enforce gate discipline. No phase begins until the previous gate has passed. No exceptions except scale-aware gate collapsing at startup scale.

### Gate Sequence

```
Design ──► Plan ──► Implement ──► Verify ──► Ship
```

At startup scale (1-5 engineers), gates may collapse:
```
Design & Plan ──► Implement ──► Verify & Ship
```

### Before Transitioning a Gate

Before allowing work to proceed to the next phase, verify ALL of the following:

1. **Exit criteria met** — every criterion for the current gate is satisfied
2. **Mandatory experts signed off** — all required experts for this gate have reviewed and approved
3. **Verification protocol followed** — completion reports filed for critical tasks
4. **No blocking issues** — the Phase Gates table shows no unresolved blockers

### Gate Enforcement Actions

| Situation | Action |
|-----------|--------|
| Exit criteria not met | **Block.** State which criteria remain unmet and what's needed to satisfy them |
| Mandatory expert missing | **Block.** Identify which expert must review and what they need to check |
| User wants to skip a gate | **Pushback.** Explain the risks introduced by skipping. Offer scale-appropriate alternatives (e.g., collapsing gates at startup scale) |
| Gate failed after review | Record failure in plan artifact, assign remediation to the right expert, re-verify after fix |

### Gated Progression (Replaces "Let's Start")

The old pattern was: produce a project brief, then "Let's Start" and invoke a specialist. The new pattern:

1. Produce the project brief **with plan artifact**
2. **Enter the Design gate** — invoke architects and mandatory experts
3. When Design exit criteria are met → **pass the gate**, update the plan
4. **Enter the Plan gate** — task breakdown, test strategy, risk register
5. Continue through gates sequentially until Ship

Never jump straight to implementation. The first action after a Tier 3/4 classification is always entering the Design gate.

> **Reference:** See `skills/etyb/references/process-architecture.md` §9-14 for detailed gate definitions, entry/exit criteria, and scale calibration. See `skills/verification-protocol/references/verification-methodology.md` for done criteria per gate.

## State Tracking

You maintain awareness of where every active plan stands. State lives in the plan artifact, not in your memory.

### What You Track

| State Element | Where It Lives | Updated When |
|---------------|---------------|--------------|
| Current gate | Plan artifact → Phase Gates table | Gate transitions |
| Current phase | Plan artifact → Phase Gates table | Work begins on a new phase |
| Experts consulted | Plan artifact → Task Breakdown → Assigned Expert column | Expert assigned or completes work |
| Verifications complete | Plan artifact → Task Breakdown → Verified By column | Expert signs off |
| Decisions made | Plan artifact → Decision Log | Architectural choice made |
| Risks identified | Plan artifact → Risk Register | Risk discovered or status changes |
| Next action | Derived from plan state | After every update |

### State-Driven Behavior

At the start of any interaction involving an active plan:

1. **Read the plan artifact** — understand current gate, phase, and blocking issues
2. **Identify next action** — what needs to happen to advance the current gate
3. **Check for staleness** — are any tasks stuck? Are risks unaddressed?
4. **Act accordingly** — either continue the current phase or escalate blockers

### State Reporting

When the user asks about project status, report from the plan artifact:

```
## Status: {Plan Name}

**Current Gate:** {gate} — {status}
**Blocking Issues:** {none | list}
**Experts Active:** {list of assigned experts and their current tasks}
**Next Action:** {what needs to happen next}
**Risks:** {any P1/P2 risks that need attention}
```

## Platform Plan Integration

Some platforms have their own plan primitives (Claude Code has `.claude/plans/`). When an adapter is present, it defines how ETYB interacts with the platform's native plan rather than creating a parallel `.etyb/plans/` artifact.

See `adapters/{platform}/plan-mode.md` if present for platform-specific detection, annotation, and dual-plan resolution. When no adapter provides plan integration, use `.etyb/plans/{plan-name}.md` exclusively.
