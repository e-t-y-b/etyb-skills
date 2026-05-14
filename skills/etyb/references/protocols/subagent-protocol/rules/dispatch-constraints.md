# Dispatch Constraints: Hard Rules

These rules are non-negotiable. They apply to every subagent dispatch regardless of task urgency, model selection, or dispatch strategy.

## Mutable State Isolation

- NEVER dispatch agents that share mutable state (same files being edited by multiple agents)
- NEVER allow parallel agents to modify the same file -- if two agents need the same file, sequence them or merge into one agent
- ALWAYS verify the independence matrix before parallel dispatch -- file overlap in the "modify" column is a hard stop

## Dispatch Overhead Threshold

- NEVER dispatch a subagent for trivial tasks where the overhead exceeds the value (under ~10 lines of changes across 1-2 files)
- ALWAYS do trivial work inline rather than constructing a context packet, dispatching, and reviewing
- The minimum bar for dispatch: the task requires focused work across 3+ files OR complex logic in 1-2 files

## Success Criteria Mandate

- ALWAYS include falsifiable success criteria in every dispatch -- the agent must know what "done" looks like
- NEVER dispatch with vague objectives ("make it work", "clean up the code", "improve performance")
- Every criterion must be verifiable by examining output (files, tests, logs) without asking the agent

## Post-Integration Testing

- ALWAYS run combined tests after integrating parallel agent results -- individual agent tests passing is not sufficient
- ALWAYS run type checking / compilation on the combined output
- NEVER integrate agent output without at least Stage 1 (spec conformance) review

## Concurrency Limits

- Maximum 5 concurrent agents -- more than that indicates the task needs better decomposition, not more parallelism
- Each agent must have a domain-specific name (no "agent-1", "agent-2" naming)

## Two-Stage Review Mandate

- Two-stage review is MANDATORY for any agent work going to production code
- Stage 2 (quality review) may only be skipped for mechanical changes, test-only changes, or configuration changes
- Stage 2 skip MUST be documented with rationale

## Iteration Limits

- Maximum 2 re-dispatches per agent (3 total attempts including the original)
- After max iterations, ESCALATE to ETYB -- do not continue re-dispatching
- Every re-dispatch MUST include the previous failure reason and specific corrections required
