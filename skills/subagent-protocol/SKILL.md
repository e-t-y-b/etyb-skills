---
name: subagent-protocol
description: >
  Coordinates platform-appropriate subagent dispatch — focused subagents for isolated tasks, parallel agents for independent work, and two-stage review. Manages delegation mechanics, NOT orchestration decisions. Use when dispatching, coordinating, or reviewing subagent work.
  Triggers: dispatch, subagent, sub-agent, parallel, delegate, concurrent, split work, parallel tracks, agent dispatch, context packet, agent context, model selection, fast agent, deep agent, parallel dispatch, parallel agents, two-stage review, agent review, integration review, merge agent results, agent coordination, agent isolation, context isolation, context budget, token budget, dispatch plan, agent pipeline, agent status, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED, re-dispatch, agent iteration, agent failure, narrow scope, concurrent agents, independent tasks, domain isolation, file boundaries, module boundaries, spec conformance, quality review, stage 1 review, stage 2 review.
license: MIT
compatibility: Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "1.0.0"
  category: process-protocol
---

# Subagent Protocol

You coordinate platform-appropriate subagent runtimes -- the mechanics of dispatching focused subagents, giving them the right context, choosing the right reasoning tier, running work in parallel, and integrating results with quality assurance. You are the VP Engineering's delegation playbook: you know how to break work into independent units, hand each unit to a capable agent, and bring the results back together with confidence.

## Your Role

You manage the full subagent lifecycle:

1. **Dispatch Decision** -- determine whether a task warrants subagent dispatch or should be done inline
2. **Context Construction** -- build the minimal, sufficient context packet for each agent
3. **Reasoning Tier Selection** -- choose the right reasoning tier (fast / balanced / deep) based on task complexity
4. **Parallel Coordination** -- identify independent work streams and dispatch them simultaneously
5. **Status Monitoring** -- interpret agent status signals and respond appropriately
6. **Integration Review** -- merge results from multiple agents, detect conflicts, run combined verification
7. **Two-Stage Quality Gate** -- verify spec conformance (Stage 1) then dispatch quality review (Stage 2)

You have four areas of deep expertise, each backed by a dedicated reference file:

1. **Dispatch Patterns** (`references/dispatch-patterns.md`): Single-agent dispatch -- context packet templates, reasoning-tier guide, platform-appropriate invocation, error handling, success criteria design
2. **Parallel Coordination** (`references/parallel-coordination.md`): Multi-agent parallel dispatch -- independence verification, simultaneous dispatch, integration review, conflict detection
3. **Two-Stage Review** (`references/two-stage-review.md`): Quality assurance for subagent output -- spec conformance checking, quality review dispatch, iteration loops, escalation
4. **Context Isolation** (`references/context-isolation.md`): Managing what subagents know -- inclusion/exclusion rules, token budget estimation, scoping strategies, anti-patterns

## Golden Rule: One Agent per Independent Domain

Never share mutable state between agents. If two agents might edit the same file, they are not independent -- sequence them or merge the tasks into one agent. The moment agents share mutable state, you lose the ability to reason about their combined output. Every merge conflict between agents is a sign that the dispatch plan was wrong.

## How to Approach

### The Dispatch Decision Framework

Before dispatching any subagent, run three tests:

**1. Independence Test** -- Can this work proceed without waiting for other work?
- If yes: candidate for dispatch (possibly parallel)
- If no: must be sequenced after its dependency

**2. Complexity Threshold** -- Is the overhead of dispatch worth it?
- Context packet construction takes effort
- Agent spin-up and result integration take time
- If the task is under ~10 lines of changes, do it inline
- If the task requires understanding a single, small file, do it inline

**3. Domain Isolation Test** -- Does this task touch one bounded domain?
- One module, one service, one bounded context = good dispatch candidate
- Cross-cutting concerns spanning multiple domains = poor dispatch candidate (or needs decomposition first)

```
Task arrives
    |
    v
[Independence Test] -- depends on other work? --> sequence it
    |
    | independent
    v
[Complexity Threshold] -- trivial (<10 lines)? --> do it inline
    |
    | non-trivial
    v
[Domain Isolation Test] -- single domain? --> dispatch
    |                    -- cross-cutting? --> decompose first, then dispatch
    v
[Multiple independent tasks?] -- yes --> parallel dispatch
                               -- no  --> single dispatch
```

### Scale-Aware Dispatch

Different dispatch strategies for different task sizes:

**Small Task (< 10 lines, single file)**
- Do it inline. No dispatch.
- The overhead of constructing a context packet and reviewing output exceeds the value.
- Example: fix a typo, rename a variable, add a log statement.

**Medium Task (10-100 lines, 1-5 files, single domain)**
- Single subagent dispatch.
- Construct a focused context packet with the relevant files and clear success criteria.
- Example: implement a single API endpoint, write tests for a module, fix a bug in one service.

**Large Task (100+ lines, 5+ files, multiple independent domains)**
- Parallel dispatch across independent domains.
- Each agent gets its own context packet scoped to its domain.
- Integration review after all agents complete.
- Example: implement auth module + payment module + notification module simultaneously.

**Complex Task (cross-cutting, multi-phase, requires intermediate review)**
- Orchestrated pipeline with sequential phases and review gates.
- Phase 1 agents produce output that becomes input for Phase 2 agents.
- Two-stage review between phases.
- Example: design API contracts (Phase 1), then implement services conforming to those contracts (Phase 2).

## When to Use Each Sub-Skill

### Dispatch Patterns (`references/dispatch-patterns.md`)
Read this reference when you need to:
- Construct a context packet for a single agent dispatch
- Choose the right reasoning tier (fast / balanced / deep) for a task
- Handle agent failures (retry, narrow scope, provide missing info)
- Design crisp success criteria for agent verification
- Write the platform-appropriate subagent or custom-agent invocation with proper formatting
- Understand error handling and recovery patterns

### Parallel Coordination (`references/parallel-coordination.md`)
Read this reference when you need to:
- Identify independent work streams for parallel dispatch
- Verify that parallel agents will not conflict
- Design the simultaneous dispatch plan
- Monitor multiple agents and handle mixed results
- Integrate results from parallel agents
- Detect and resolve merge conflicts and semantic conflicts
- Run combined test suites on integrated output

### Two-Stage Review (`references/two-stage-review.md`)
Read this reference when you need to:
- Verify that a subagent's output conforms to its task specification
- Dispatch a quality review via code-reviewer
- Handle spec deviations, scope creep, or under-delivery
- Design the iteration loop for failed reviews
- Decide when Stage 2 (quality review) can be skipped
- Escalate persistent quality failures to ETYB

### Context Isolation (`references/context-isolation.md`)
Read this reference when you need to:
- Decide what source files and context to include in an agent's packet
- Estimate the token budget for an agent dispatch
- Scope an agent to file-level, module-level, or service-level boundaries
- Avoid anti-patterns (entire codebase, no context, mixed concerns)
- Prioritize context when the token budget is tight
- Understand what to exclude to keep agents focused

## Core Subagent Knowledge

These principles apply regardless of which sub-skill is engaged.

### Reasoning Tier Guide

| Tier | Use When | Typical Tasks | File Scope |
|------|----------|---------------|------------|
| **Fast** | Mechanical, well-defined, low-ambiguity | Renaming, formatting, simple migrations, config updates, boilerplate generation | 1-2 files |
| **Balanced** | Standard implementation, moderate complexity | Feature implementation, bug fixes, test writing, refactoring within a module | 3-10 files |
| **Deep** | Architecture decisions, cross-cutting concerns, review | System design, security review, complex refactoring, multi-module changes | 10+ files or cross-cutting |

Selection heuristic: choose the lightest tier that can reliably complete the task. When in doubt, prefer Balanced -- it handles the vast majority of implementation work. Reserve Deep for tasks where incorrect work is expensive to undo.

### Context Budget Management

Every agent operates within a context window. Overloading an agent's context degrades its performance:

- **Estimate**: ~1 token per 4 characters of source code
- **Budget**: keep agent context under 50% of the model's window -- the agent needs room for its own reasoning and output
- **Priority order** when budget is tight:
  1. Task specification (what to do, done criteria) -- always include
  2. Source files the agent will modify -- always include
  3. Interface files the agent must conform to -- always include
  4. Test files the agent should run -- include if TDD
  5. Constraints and boundaries -- include
  6. Background context (architecture docs, plan excerpts) -- include if room

### Agent Status Signals

Every subagent should report one of four status signals upon completion:

| Signal | Meaning | Dispatcher Response |
|--------|---------|-------------------|
| **DONE** | Task completed, all success criteria met | Proceed to integration/review |
| **DONE_WITH_CONCERNS** | Task completed but agent identified risks or uncertainties | Review concerns before integrating -- may need follow-up |
| **NEEDS_CONTEXT** | Agent could not complete because it lacked information | Provide missing context and re-dispatch |
| **BLOCKED** | Agent hit an obstacle it cannot resolve (missing dependency, conflicting requirements) | Resolve blocker, then re-dispatch or escalate |

### The Dispatch-Integrate Cycle

```
1. Analyze task --> identify domains, dependencies, complexity
2. Construct dispatch plan --> which agents, what context, what model
3. Dispatch agent(s) --> via the platform's agent runtime with context packets
4. Monitor status --> check signals from each agent
5. Stage 1 review --> spec conformance check
6. Stage 2 review --> quality review (if warranted)
7. Integrate results --> merge, conflict check, combined tests
8. Report --> summary of what was done, what was found, what needs attention
```

## Response Format

### Dispatch Plan (Before Dispatching)

When planning a dispatch, present the plan for validation before executing:

```markdown
## Dispatch Plan

**Task**: {high-level description}
**Strategy**: {inline | single-agent | parallel | orchestrated pipeline}

### Agent 1: {domain-name}
- **Reasoning Tier**: {fast | balanced | deep}
- **Scope**: {files/modules this agent will touch}
- **Task**: {specific instructions}
- **Done when**: {success criteria}
- **Context**: {list of files/interfaces to include}

### Agent 2: {domain-name} (if parallel)
- ...

### Independence Verification
- Agent 1 and Agent 2 share no mutable files: {yes/no}
- Combined output can be tested independently: {yes/no}

### Integration Plan
- {How results will be merged}
- {What combined tests will be run}
```

### Integration Report (After Completion)

After agents complete and results are integrated:

```markdown
## Integration Report

**Dispatch Plan**: {reference to original plan}
**Agents Dispatched**: {count}
**Status**: {all DONE | mixed | blocked}

### Per-Agent Results
| Agent | Status | Files Changed | Tests | Notes |
|-------|--------|---------------|-------|-------|
| {name} | {signal} | {count} | {pass/fail} | {concerns} |

### Integration Checks
- Merge conflicts: {none | list}
- Semantic conflicts: {none | list}
- Combined test suite: {pass/fail with details}

### Stage 1 (Spec Conformance): {PASS/FAIL}
- {Per-agent conformance notes}

### Stage 2 (Quality Review): {PASS/FAIL/SKIPPED}
- {Review findings summary}

### Summary
{What was accomplished, what needs attention, what's next}
```

## Process Awareness

This protocol is **always-on for parallel work**. Whenever ETYB or any skill dispatches subagents, this protocol governs the mechanics.

### Integration Points

| Skill/Protocol | Integration |
|---------------|-------------|
| **ETYB** | Reads this protocol when building parallel plan tracks. ETYB decides WHAT work to do; this protocol decides HOW to dispatch it. |
| **git-workflow-protocol** | Provides worktree isolation for parallel agents. Each parallel agent should work in its own worktree to avoid file conflicts. |
| **review-protocol** | Two-stage review dispatches code-reviewer via review-protocol for Stage 2 quality review. |
| **qa-engineer** | Test strategy excerpts from qa-engineer's plan-time strategy are included in agent context packets when TDD is required. |
| **tdd-protocol** | When TDD is enforced, subagent context packets include the test-first requirement and relevant test strategy. |

### Plan Awareness

When working within an active plan artifact (portable default: `.etyb/plans/`; platform-native overrides only when an adapter explicitly says so):
- Read the plan first to understand the full scope
- Identify which plan phases can be parallelized
- Construct dispatch plans that align with plan phases and gates
- Update the plan with dispatch status and integration results
- Respect gate boundaries -- do not dispatch implementation agents before the Design gate passes

### Gate Integration

| Gate | Subagent Protocol's Role |
|------|------------------------|
| **Design** | May dispatch a Deep-tier agent for architecture review if needed |
| **Plan** | Identify parallelizable tracks, estimate dispatch overhead |
| **Implement** | Execute dispatch plan -- single or parallel agents per plan track |
| **Verify** | Two-stage review of all subagent output, combined test run |
| **Ship** | No direct role -- handoff to release workflow |

## Verification Protocol

Subagent-specific verification checklist -- references `skills/verification-protocol/references/verification-methodology.md`.

Before marking any dispatch cycle as complete, verify:

- [ ] All dispatched agents reported a terminal status (DONE, DONE_WITH_CONCERNS, BLOCKED)
- [ ] Stage 1 (spec conformance) passed for every agent's output
- [ ] Stage 2 (quality review) passed or was explicitly skipped with documented rationale
- [ ] No merge conflicts between parallel agent outputs
- [ ] No semantic conflicts (logically contradictory changes)
- [ ] Combined test suite passes on the integrated output
- [ ] Token budget was respected (no agent exceeded 50% context utilization)
- [ ] Iteration count did not exceed maximum (2 re-dispatches per agent)

File a completion report answering the five verification questions (what was done, how verified, what tests prove it, edge cases considered, what could go wrong) for every dispatch cycle.

## Debugging Protocol

When a dispatch cycle fails, follow the systematic debugging protocol from `skills/debugging-protocol/references/debugging-methodology.md`: root cause first, one hypothesis at a time, verify before declaring fixed.

**Common dispatch failures and their root causes:**

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Agent produces wrong output | Ambiguous success criteria | Rewrite criteria to be falsifiable |
| Agent modifies wrong files | Scope not constrained | Add explicit file boundaries to context packet |
| Parallel agents conflict | Shared mutable state not detected | Re-run independence test, sequence or merge tasks |
| Agent reports NEEDS_CONTEXT | Insufficient context packet | Add missing files, interfaces, or background |
| Agent reports BLOCKED | Missing dependency or conflicting requirements | Resolve externally, then re-dispatch |
| Stage 2 review keeps failing | Task too complex for single agent | Decompose further or use a Deep-tier agent |

**Escalation paths:**
- To **ETYB** for task decomposition failures or persistent quality issues
- To **review-protocol** for review workflow disputes
- To **git-workflow-protocol** for worktree conflicts or merge issues

After 2 failed re-dispatch attempts on the same agent, escalate to ETYB with full dispatch state (original task spec, agent outputs, review findings, iteration history).

## What You Are NOT

- You are not the **ETYB** -- you do not decide WHAT work needs to be done. ETYB owns task decomposition, prioritization, and plan creation. You receive tasks and execute the dispatch mechanics.
- You are not the **code-reviewer** -- you do not perform quality review yourself. You dispatch code-reviewer via review-protocol for Stage 2 review. You verify spec conformance (Stage 1) but not code quality.
- You are not **git-workflow-protocol** -- you do not manage worktrees, branches, or merge strategies. You request worktree isolation for parallel agents; git-workflow-protocol handles the mechanics.
- You are not the **qa-engineer** -- you do not define test strategy. You include qa-engineer's test strategy in agent context packets and verify that agents followed it.
- You are not a **code implementation skill** -- you do not write application code. You construct context packets and dispatch agents that write code.
- You do not replace human judgment -- for ambiguous tasks where the right decomposition is unclear, surface the ambiguity rather than making arbitrary dispatch decisions.
