# Context Isolation: Managing What Subagents Know

This reference covers the art of curating agent context -- what to include, what to exclude, how to estimate token budgets, and how to scope agent work to appropriate boundaries. Context isolation is the single biggest lever for subagent quality: too much context and the agent drowns in irrelevant information; too little and it makes incorrect assumptions.

## The Context Isolation Principle

Every subagent should know exactly what it needs to do its job -- no more, no less. This is not about secrecy; it's about focus. An agent with the entire codebase in its context will spend tokens reasoning about irrelevant modules. An agent with no context will guess at interfaces and produce incompatible code.

The goal: **minimal sufficient context** -- the smallest set of information that enables the agent to produce correct output without asking questions.

## What to INCLUDE

### Tier 1: Always Include (Non-Negotiable)

These items must be in every context packet:

**Source files the agent will modify**
- Read these files and include their full content (or relevant sections for very large files)
- The agent cannot modify what it cannot see
- Include the current state, not a summary -- the agent needs exact line numbers and existing code

**Task specification**
- Objective, success criteria, constraints (see `dispatch-patterns.md` for template)
- This is the agent's primary directive -- it must be clear and complete

**Interface files the agent must conform to**
- Type definitions, API contracts, schema files
- If the agent is implementing an interface, it needs the interface definition
- If the agent is calling an API, it needs the API contract
- Include: TypeScript type files, OpenAPI specs, GraphQL schemas, Protobuf definitions, database schema files

### Tier 2: Include When Relevant

These items should be included when they directly affect the agent's work:

**Test files the agent should modify or run**
- Existing tests for the code being changed (agent needs to maintain backward compatibility)
- Test files the agent should add to (e.g., "add tests to `/src/auth/__tests__/login.test.ts`")
- Test utility files and fixtures the agent should use

**Test strategy excerpt from qa-engineer**
- When TDD is required: include the specific test types, coverage targets, and acceptance criteria from the plan-time test strategy
- When tests are expected: include the testing shape (pyramid, trophy, diamond) and what test types are mandatory

**Configuration files**
- `.env.example` (never `.env` with real values) for environment variable expectations
- `tsconfig.json` / `jest.config.ts` / etc. for project-specific settings the agent must follow
- Linting configuration if the agent should produce compliant code

**Architectural constraints from the plan**
- Relevant excerpts from the plan artifact (`.etyb/plans/`)
- Design decisions that constrain the agent's approach (e.g., "we chose PostgreSQL, not MongoDB")
- Patterns the agent must follow (e.g., "all API handlers use the Result pattern")

**Related module interfaces**
- If the agent's code calls other modules, include the public interface (not implementation) of those modules
- If other modules call the agent's code, include how they call it so the agent maintains compatibility

### Tier 3: Include If Room in Budget

These items are helpful but can be cut when the token budget is tight:

**Style guide excerpts**
- Naming conventions, file organization patterns, code style preferences
- Only relevant sections, not the entire style guide

**Architecture documentation**
- High-level system overview if the agent needs to understand where its work fits
- C4 context or container diagrams (as text) for orientation

**Example implementations**
- An existing, well-written module that follows the patterns the agent should use
- "Implement `/src/payments/checkout.ts` following the same pattern as `/src/orders/create.ts`"

**Error handling patterns**
- Project-specific error types and handling conventions
- How the project structures error responses

## What to EXCLUDE

### Always Exclude

**Full project history**
- Git log, old PRs, commit messages
- The agent doesn't need history; it needs current state
- Exception: if debugging a regression, include the specific commit that introduced the issue

**Unrelated modules or services**
- If the agent is working on auth, it doesn't need the analytics module
- If the agent is working on the backend, it doesn't need the iOS codebase
- Including unrelated code wastes tokens and can confuse the agent into making connections that don't exist

**Other agents' work-in-progress**
- Parallel agents should not know about each other's work
- This prevents agents from making assumptions about changes that haven't been integrated yet
- Exception: when orchestrating a pipeline, Phase 2 agents may need Phase 1 agents' output

**Performance data (unless performance is the task)**
- Profiling results, load test data, monitoring dashboards
- Only include when the agent's task is specifically about performance optimization

**Full SKILL.md files**
- Subagents don't need the full expertise of a skill unless they're being dispatched to use that skill's patterns
- Exception: when dispatching a review agent, include the relevant review protocol

**Sensitive data**
- Real `.env` files with production credentials
- Database connection strings with real passwords
- API keys, tokens, or secrets
- Use `.env.example` with placeholder values instead

**Large generated files**
- `package-lock.json`, `yarn.lock` (enormous, not useful for agents)
- Generated code, compiled output, build artifacts
- Migration history beyond the current relevant migration

### Exclude with Caution

These items are sometimes needed but should be excluded by default:

| Item | Default | Include When |
|------|---------|-------------|
| **Full test suites** | Exclude | Agent is refactoring test infrastructure |
| **CI/CD configuration** | Exclude | Agent is modifying the build/deploy process |
| **Database migrations (all)** | Exclude | Agent is writing a new migration (include the latest 2-3 for context) |
| **Third-party library source** | Exclude | Agent is debugging a library issue (include relevant types only) |
| **Documentation files** | Exclude | Agent is updating documentation |
| **Deployment configuration** | Exclude | Agent is modifying deployment behavior |

## Token Budget Estimation

### Estimation Method

```
Token estimate = character_count / 4

Where character_count includes:
- All source file content included in the context packet
- The task specification text
- Interface definitions
- Test files
- Constraints and background text
```

This is a rough estimate. Actual tokenization varies by model and content (code typically has a slightly higher character-to-token ratio than prose due to punctuation and indentation).

### Budget Allocation

**Target: keep agent context under 50% of the model's context window.**

The agent needs the remaining 50% for:
- Its own chain-of-thought reasoning
- The code it generates
- Tool calls (reading files, running commands)
- The response it produces

| Model | Context Window | Budget (50%) | Approximate Characters |
|-------|---------------|-------------|----------------------|
| Haiku | 200K tokens | 100K tokens | ~400K characters |
| Sonnet | 200K tokens | 100K tokens | ~400K characters |
| Opus | 200K tokens | 100K tokens | ~400K characters |

### Budget Prioritization

When the total context exceeds the budget, cut in this order (last item cut first):

| Priority | Content Type | Cut Strategy |
|----------|-------------|-------------|
| 1 (never cut) | Task specification | N/A -- always fits |
| 2 (never cut) | Source files being modified | If too large, scope the task to fewer files |
| 3 (cut last) | Interface contracts | Include type signatures only, not implementations |
| 4 | Test files | Include test file names and describe expected tests in prose |
| 5 | Constraints and boundaries | Summarize into bullet points |
| 6 | Configuration files | Include only relevant sections |
| 7 (cut first) | Background context | Summarize or omit |

### Practical Token Estimation Examples

| Content | Estimated Tokens | Typical Size |
|---------|-----------------|-------------|
| Small TypeScript file (100 lines) | ~500-800 tokens | 2-3 KB |
| Medium TypeScript file (300 lines) | ~1,500-2,500 tokens | 8-12 KB |
| Large TypeScript file (1000 lines) | ~5,000-8,000 tokens | 25-40 KB |
| OpenAPI spec (50 endpoints) | ~3,000-5,000 tokens | 12-20 KB |
| Task specification | ~200-500 tokens | 1-2 KB |
| Test file (200 lines) | ~1,000-1,500 tokens | 5-8 KB |

### When Budget Is Exceeded

If the context packet exceeds the budget after cutting Tier 3 content:

1. **Scope reduction** -- narrow the agent's task to fewer files
2. **File sectioning** -- include only the relevant functions/classes from large files, not the entire file
3. **Interface-only inclusion** -- for dependency files, include only the type signatures (interfaces, types, function signatures) not implementations
4. **Task decomposition** -- split the task into smaller tasks that each fit within budget

Do NOT solve budget problems by:
- Summarizing source code in prose (agents need exact code)
- Omitting the task specification (agents need to know what to do)
- Removing interface contracts (agents will guess and produce incompatible code)

## Scoping Strategies

Different scoping levels for different task sizes:

### File-Level Scoping

**When**: Agent works on 1-3 specific files within a module.

```
Scope: File-level
Files in scope:
  - /src/auth/login.ts (modify)
  - /src/auth/types.ts (read-only)
  - /src/auth/login.test.ts (modify)
Files out of scope:
  - Everything else in /src/auth/
  - Everything outside /src/auth/
```

**Best for**: Bug fixes, small features, adding tests to existing code.
**Context cost**: Low (~2,000-5,000 tokens typically).
**Risk**: Agent may not understand module-level context.

### Module-Level Scoping

**When**: Agent works within a single module/package, modifying multiple files.

```
Scope: Module-level
Module: /src/auth/
Files in scope:
  - All files in /src/auth/ (modify as needed)
  - /src/shared/types.ts (read-only)
  - /src/shared/errors.ts (read-only)
Files out of scope:
  - /src/payments/, /src/users/, /src/notifications/
  - /src/shared/ (except types.ts and errors.ts)
```

**Best for**: Feature implementation within a module, module-wide refactoring.
**Context cost**: Medium (~5,000-20,000 tokens typically).
**Risk**: Agent may not understand cross-module interactions.

### Service-Level Scoping

**When**: Agent works within a service boundary in a microservice architecture.

```
Scope: Service-level
Service: auth-service
Files in scope:
  - All files in /services/auth-service/src/ (modify)
  - /services/auth-service/tests/ (modify)
  - /shared/contracts/auth-service.ts (read-only -- API contract)
Files out of scope:
  - All other services
  - Shared libraries (except contracts)
  - Infrastructure code
```

**Best for**: Implementing or modifying a complete service.
**Context cost**: High (~15,000-50,000 tokens typically).
**Risk**: Large context may dilute agent focus.

### Cross-Module Scoping (Use Sparingly)

**When**: Agent must modify files across multiple modules (typically Opus tasks).

```
Scope: Cross-module
Modules involved:
  - /src/auth/ (modify -- add session management)
  - /src/middleware/ (modify -- add session middleware)
  - /src/shared/types.ts (modify -- add Session type)
  - /src/users/ (read-only -- understand user model)
Files explicitly out of scope:
  - /src/payments/, /src/notifications/, /src/analytics/
  - Tests in unrelated modules
```

**Best for**: Architecture-level changes, cross-cutting concerns.
**Context cost**: Very high (~30,000-80,000 tokens).
**Risk**: High complexity, likely needs Opus. Consider decomposing.

## Anti-Patterns

### Anti-Pattern: The Kitchen Sink

**What it looks like**: Including every file in the project in the agent's context.
**Why it's bad**: Agent wastes tokens reasoning about irrelevant code. May modify files it shouldn't. Slower to produce output. More likely to produce confused results.
**Fix**: Scope to the specific files relevant to the task. Use the budget prioritization table.

### Anti-Pattern: The Blind Dispatch

**What it looks like**: Dispatching an agent with only a task description and no source files.
**Why it's bad**: Agent has to search the codebase (if it can), guess at file locations, and make assumptions about existing code structure. Output is unlikely to be compatible with the project.
**Fix**: Always include the source files the agent will modify and the interfaces it must conform to.

### Anti-Pattern: The Mixed Concern

**What it looks like**: Dispatching one agent to handle both frontend and backend changes for a feature.
**Why it's bad**: Frontend and backend are different domains with different patterns, different test strategies, and different skill requirements. The agent's context becomes unfocused.
**Fix**: Dispatch separate agents for frontend and backend. Include the shared API contract in both context packets.

### Anti-Pattern: The Stale Context

**What it looks like**: Including file contents that were read at the start of a session but have since been modified by other agents or manual changes.
**Why it's bad**: Agent works against an outdated version of the code. Its output may conflict with the current state.
**Fix**: Re-read files immediately before dispatch. For parallel agents, this is especially important -- dispatch only after all context packets are constructed from the same snapshot.

### Anti-Pattern: The Implicit Contract

**What it looks like**: Assuming the agent will figure out the API contract, coding style, or error handling pattern from the code it reads.
**Why it's bad**: The agent may figure it out -- or it may not. Implicit contracts lead to inconsistent output.
**Fix**: Make contracts explicit. Include type files, API specs, and pattern examples. State the conventions in the constraints section.

### Anti-Pattern: The Over-Scoped Agent

**What it looks like**: Scoping an agent at the service level when it only needs to modify one file.
**Why it's bad**: Wastes token budget on irrelevant files. Agent may make unnecessary changes to files within scope.
**Fix**: Match scoping level to actual task size. Use file-level scoping for small tasks, module-level for medium tasks.

## Context Isolation Checklist

Before dispatching any agent, verify:

- [ ] Task specification is clear and complete (objective, criteria, constraints)
- [ ] All files the agent will modify are included
- [ ] All interface files the agent must conform to are included
- [ ] Scope boundaries are explicit (what's in, what's out)
- [ ] Token budget is estimated and under 50% of model window
- [ ] No sensitive data (real credentials, API keys) in the context
- [ ] No stale file contents (re-read files immediately before dispatch)
- [ ] No unrelated modules cluttering the context
- [ ] Shared read-only files are marked as read-only
- [ ] Test strategy is included (if TDD is required)
