# Plan 3 — Portability, Distribution & Orchestrator-as-Product

**Status:** Draft
**Branch:** `plan-3-portability-distribution`
**Preceded by:** Plan 2 (Process Enhancement)

---

## Thesis

ETYB's wedge is **"install a virtual engineering company"** — teams who want a CTO-level orchestrator that routes work methodically, with 20 specialists and 7 always-on protocols backing it up.

The orchestrator is the flagship. Individual skills are discovery funnels.

This plan makes ETYB:
1. Distributable across skills.sh, SkillsMP, and other marketplaces
2. Portable across Claude Code (flagship), OpenAI Codex, and Google Antigravity
3. Updatable after install without silent changes
4. Installable without breaking the user's existing skills

---

## Product Shape — Two Entry Points, One Package

**Mode A — "Install the team"**
User invokes the orchestrator (`/etyb` or by name). Orchestrator takes over, routes to specialists, enforces gates, manages the plan. CTO mode.

**Mode B — "Call a specialist"**
User invokes any skill directly (`/code-review`, `/debug`, etc.). Specialist runs standalone. Orchestrator stays out of the way.

**Rule:** orchestrator is **opt-in activation, always-available when activated**. Never silently intercepts direct specialist calls.

---

## Architecture — The Trident

**Layer 1 — Atomic Skills (portable, standalone)**
- All 20 specialists + 7 protocols
- Zero hard dependencies on the orchestrator or each other
- Each has a valid SKILL.md per the agentskills.io spec
- Each works on any platform that reads the spec

**Layer 2 — Orchestrator Core (portable instructions)**
- Team charter: who the specialists are, when to call them, how they hand off
- Protocol playbooks: TDD, verification, review, debugging as instructions
- Pure markdown — no platform-specific primitives

**Layer 3 — Platform Adapters (thin, per-platform)**
- `orchestrator-claude` — hooks for deterministic gates, subagents for parallel review
- `orchestrator-codex` — Codex-native agent primitives, model-trusted gates
- `orchestrator-antigravity` — ADK sub-agents, MCP bridges where relevant
- Each adapter is small; intelligence lives in Layer 2

**Invariant:** a user can uninstall the orchestrator and every specialist still works.

---

## Workstreams

### Workstream 1 — Orchestrator refactor (Claude Code, flagship)

**Goal:** split the orchestrator into portable core + Claude adapter.

- Extract team charter and protocol playbooks into platform-neutral markdown
- Move hooks and subagent coordination into a Claude-specific adapter layer
- Verify: user can invoke orchestrator and full flow still works end-to-end
- Verify: user can invoke any specialist directly without orchestrator involvement

### Workstream 2 — Skill independence audit

**Goal:** prove every specialist stands alone.

- Audit each of the 20 specialists + 7 protocols for hard references to other skills or orchestrator-only primitives
- Remove or soften coupling (reference by name/capability, not path)
- Each SKILL.md verified against agentskills.io spec frontmatter
- Add namespacing convention: canonical name `etyb:<skill>` (short name usable when unambiguous)

### Workstream 3 — Versioning & update mechanism

**Goal:** users stay in sync without silent changes.

- Semver on the bundle (major = breaking orchestrator routing change)
- Per-skill versions for marketplace installs
- Manifest file (URL-accessible) with current versions
- Orchestrator self-checks manifest on session start, surfaces update notice
- `etyb update` script pulls latest from GitHub
- Human-readable CHANGELOG.md

### Workstream 4 — Install conflict resolution

**Goal:** don't break users who already have skills installed.

- Install script scans for name collisions
- Prompts user: replace / namespace / skip, per conflict
- Update script applies the same logic on upgrade
- Never silently overwrite

### Workstream 5 — Distribution & listings

**Goal:** discoverable everywhere, flagship positioning.

- Public repo polish: README with one-line install, clear pitch, architecture diagram
- Flagship listing: "ETYB: Your Virtual Engineering Company" on skills.sh, SkillsMP, others
- Individual specialist listings — each description references ETYB and teases the full team
- Seed first installs via `npx skills add` to appear on leaderboards

### Workstream 6 — Codex port

**Goal:** full orchestrator experience on OpenAI Codex.

- Build `orchestrator-codex` adapter
- Add `agents/openai.yaml` per skill where useful
- Honestly document the enforcement trade-off (model-trusted vs. hook-enforced)
- Verify: team flow works end-to-end on Codex

### Workstream 7 — Antigravity port

**Goal:** full orchestrator experience on Google Antigravity.

- Build `orchestrator-antigravity` adapter using ADK agent primitives
- Bridge MCP servers where relevant
- Verify: team flow works end-to-end on Antigravity

---

## Sequencing

Priorities, not timelines:

1. **Workstream 1 + 2** — Claude flagship solid first (refactor + audit)
2. **Workstream 3** — Versioning in place before user growth
3. **Workstream 4** — Conflict resolution ready before wider distribution
4. **Workstream 5** — Public launch and listings
5. **Workstream 6** — Codex port after Claude experience is undeniable
6. **Workstream 7** — Antigravity port

Do not port to Codex/Antigravity until Claude Code experience is polished. **Portability second, quality first.**

---

## Positioning (one-liner for every listing)

> Install a virtual engineering company. One CTO-level orchestrator, 20 specialists, 7 always-on protocols. Ship features, fix incidents, and run projects with a team that already knows how to work together.

---

## Open Questions

- Canonical short name for the orchestrator invocation — `/etyb`, `/cto`, `/team`?
- Do we publish Layer 2 (orchestrator core) as its own installable, or bundle with each platform adapter?
- Where does the manifest live — GitHub raw, or a dedicated domain?
- Does the self-check on session start feel intrusive? Maybe throttle to once/day.

---

## Non-Goals (for this plan)

- Curated combos (e.g., "feature-delivery", "incident-triage"). Orchestrator IS the combo engine; skip until users ask.
- Porting Claude-only primitives (hooks) to platforms that don't support them. Accept the trade-off; lean on model compliance elsewhere.
- GUI / dashboard / web UI. CLI and in-editor only.
