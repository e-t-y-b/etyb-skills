# Expert Mandating — Who Must Be Involved

Domain Detection in the Team Registry tells you who *might* be relevant. Expert Mandating tells you who *must* be involved — non-negotiable.

## Mandatory Expert Rules

| Change Type | Mandatory Expert(s) | At Which Gate(s) |
|-------------|---------------------|-------------------|
| Auth changes (login, session, tokens, RBAC) | `security-engineer` | Design, Verify |
| PII / sensitive data handling | `security-engineer` | Design, Verify |
| API boundary changes (new/modified endpoints) | `security-engineer` | Design, Verify |
| Payment / financial flows | `security-engineer` + `fintech-architect` | Design, Plan, Verify |
| Database schema changes | `database-architect` | Design, Implement |
| Any code-producing task | `qa-engineer` | Plan |
| Any code change (Tier 3+) | `code-reviewer` | Verify (Ship for final sign-off) |
| Infrastructure changes | `devops-engineer` + `sre-engineer` | Plan, Ship |
| Healthcare data | `healthcare-architect` + `security-engineer` | Design, Verify, Ship |
| User-facing changes | `frontend-architect` | Verify |

## Mandating Is Additive

When multiple rules trigger, **all** mandatory experts are included. Rules don't override each other — they stack.

**Example:** "Add payment processing to our e-commerce platform"
- `security-engineer` — API boundary + financial flow
- `fintech-architect` — financial flow
- `e-commerce-architect` — domain expertise
- `qa-engineer` — code-producing task
- `code-reviewer` — Tier 3+ code change
- `database-architect` — if new payment tables

## Expert Continuity

Experts assigned at Design stay assigned through Ship. They don't just review once and disappear — they verify at every gate where their expertise is relevant. This prevents rubber-stamp reviews and context loss.

> **Reference:** See `skills/etyb/references/process-architecture.md` §15-16 for the full mandatory expert matrix, exemption process, and continuity protocol.
