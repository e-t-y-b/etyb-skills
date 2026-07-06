# etyb-skills

ETYB is an engineering co-pilot packaged as a single agent skill (`/etyb`). It acts as a
senior engineering leader for any software situation — code, architecture, debugging,
review, infra, testing, security, performance — by routing internally to specialist roles,
enforcing engineering discipline, and reading currency-stamped vendor knowledge from disk.
Users never invoke a specialist directly; everything routes through the one skill.

## Invocation

Invoke explicitly with `/etyb`, or let it auto-trigger: the skill's description matches
engineering situations (a bug, an architecture question, an X-vs-Y tradeoff, a platform
name in conversation), so agents load it whenever the request has software content.

## Tier model

- **Tier 0** — trivial: just do it, no ceremony.
- **Tier 1** — single-domain: act as one specialist, read that one reference.
- **Tier 2** — incident: skip ceremony, triage immediately.
- **Tier 3-4** — multi-domain or high-stakes: written plan plus gate sequence.

## Repo layout

- `skills/etyb/` — the skill itself; `SKILL.md` is the only trigger surface.
- `skills/etyb/core/` — orchestration modules (tiering, gates, routing, knowledge currency).
- `skills/etyb/references/specialists/` — specialist role references (time-invariant principles).
- `skills/etyb/references/protocols/` — always-on engineering protocols.
- `skills/etyb/references/verticals/` — business-domain architect references.
- `stacks/<vendor>/` — currency-stamped vendor pages; detection via each stack's `SKILL.md`,
  depth from sibling product/role pages with `last_verified_on` stamps.
- `docs/plan/` — execution plans; `docs/` — RFCs and architecture docs.

## Conventions

- **TDD** — no production code without a failing test first.
- **Verification before claims** — evidence, not assertion; verify each step before advancing.
- **At most 3 clarifying questions**, and only when the answer changes the work.
- **Signature footer** — every Tier 1-4 response ends with the ETYB signature block.

## Sub-agent model tiering

The heavy lifting runs in sub-agents (`agents/`), never inline in the user's session.
Each agent declares the model tier its work needs, under one rule: **a pin may only ever
go down — the user's session model is the ceiling, never exceeded.**

- **Light work pins to the smallest tier** (`model: haiku`): `etyb-explorer`
  (search-and-cite) and `etyb-stack-researcher` (fetch-and-distill vendor docs).
- **Extensive-reasoning work inherits the session model** (`model: inherit`):
  `etyb-planner`, `etyb-reviewer`, `etyb-cartographer`.
- **Unknown or unsupported resolves to the user's model**: any harness that cannot
  interpret the `model` field ignores it and runs the agent on the session model —
  the user-selected default, by construction.

## Status: v5 shipped

The plugin-shaped v5 architecture is complete: portable SKILL.md, plugin manifest,
five agent definitions under `agents/`, and advisory hook wiring via `hooks/hooks.json`
(Claude Code plugin path only). Design rationale: `docs/rfc-v5-plugin-architecture.md`.
Task-by-task history and release ledger: `docs/plan/skills-5.0-plan.md`.
