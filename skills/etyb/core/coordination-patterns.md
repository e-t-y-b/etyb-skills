# Coordination Patterns

When planning multi-team work, use these patterns. Each pattern includes gate checkpoints — points where ETYB verifies exit criteria before allowing progression.

## Sequential Pipeline

Research → **[DESIGN GATE]** → Architecture → **[PLAN GATE]** → Development → **[IMPLEMENT GATE]** → Testing → **[VERIFY GATE]** → Deployment → **[SHIP GATE]** → Operations.

Gate owners:
- Design = `system-architect` + `security-engineer` (if applicable)
- Plan = ETYB + `qa-engineer`
- Implement = assigned experts + `qa-engineer`
- Verify = `code-reviewer` + `security-engineer` (if applicable)
- Ship = `devops-engineer` + `sre-engineer`

Use for greenfield projects.

## Parallel Tracks

After architecture is set (Design gate passed) and tasks are defined (Plan gate passed), frontend/backend/database/mobile can work in parallel against API contracts. The **IMPLEMENT gate blocks until ALL parallel tracks complete**. Individual tracks can have internal checkpoints, but the formal gate applies to the combined work. Use to compress timelines.

When parallel tracks can be delegated to subagents, read `subagent-protocol` for dispatch patterns, context isolation, and two-stage review. When parallel tracks need separate working directories, read `git-workflow-protocol` for worktree creation, baseline testing, and branch finishing.

## Hub-and-Spoke

One team (usually security or architecture) coordinates reviews across all other teams. Each spoke goes through Design → Plan → Implement independently. The hub performs **VERIFY gate reviews for each spoke**. Combined work passes through the **SHIP gate together**. Use for audits, compliance, and cross-cutting initiatives.

## Domain-Augmented

Domain specialist leads the **DESIGN gate** (defines patterns and constraints), core teams implement, domain specialist re-verifies at the **VERIFY gate** and confirms production compliance at the **SHIP gate**. Domain specialist stays assigned throughout per the expert continuity protocol. Use when building in a specific product domain.

## Incident Response

SRE leads triage, pulls in the relevant team once the problem area is identified. **NO GATES during active incidents** — speed is everything. Post-incident action items become Tier 3/4 plans with full gate process. If debugging protocol activates during remediation, track hypotheses in the post-incident plan artifact. Use for production issues.
