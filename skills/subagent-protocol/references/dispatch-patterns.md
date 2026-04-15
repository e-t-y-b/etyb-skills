# Dispatch Patterns: Single-Agent Dispatch

This reference covers the mechanics of dispatching a single focused subagent -- constructing the context packet, choosing the model, handling failures, and verifying success.

## Context Packet Template

Every subagent needs a context packet. This is the information bundle that enables the agent to do its work without asking questions or making assumptions. A good context packet makes the agent self-sufficient; a bad one produces wrong output that wastes more time than doing the work inline.

### What Every Context Packet Must Contain

```markdown
## Task Specification
**Objective**: {What to do -- one clear sentence}
**Done when**: {Falsifiable success criteria -- things you can check}
**Constraints**: {What NOT to do, boundaries, limitations}

## Source Files
{List of files the agent will read and/or modify}
- `/src/auth/login.ts` -- modify (implement login endpoint)
- `/src/auth/types.ts` -- read-only (use these type definitions)
- `/src/auth/auth.test.ts` -- modify (add tests for login)

## Interface Contracts
{APIs, types, schemas the agent's work must conform to}
- API contract: `POST /api/auth/login` accepts `{ email, password }`, returns `{ token, user }`
- Type definitions: `User`, `AuthToken` from `/src/auth/types.ts`
- Error responses: follow the project's `ApiError` format in `/src/shared/errors.ts`

## Test Strategy
{What tests to write, extracted from qa-engineer's plan-time strategy}
- Unit tests for login logic (happy path, invalid credentials, locked account)
- Integration test for the full login flow with test database
- Follow TDD: write tests first, then implement

## Constraints
- Do not modify files outside `/src/auth/`
- Do not add new dependencies without documenting why
- Do not change the existing `User` type -- extend it if needed
- Use the project's existing error handling pattern

## Expected Output
- Summary of changes made (files modified, lines changed)
- Test results (all tests passing)
- Any concerns or risks identified
- Status signal: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
```

### Context Packet Quality Checklist

Before dispatching, verify the context packet against this checklist:

| Check | Question | If Missing |
|-------|----------|-----------|
| **Objective clarity** | Can you verify completion without asking the agent what it did? | Rewrite the objective to be falsifiable |
| **File completeness** | Does the agent have every file it needs to read? | Add missing files -- agents cannot search the codebase |
| **Interface contracts** | Does the agent know the shapes it must conform to? | Include type files, API specs, schema definitions |
| **Boundary clarity** | Does the agent know what it must NOT touch? | Add explicit constraints ("do not modify X") |
| **Test expectations** | Does the agent know what tests to write or run? | Include test strategy excerpt from qa-engineer |
| **Output format** | Does the agent know what to report back? | Add expected output section |

## Agent Tool Invocation Template

When using Claude Code's Agent tool, structure the invocation as follows:

```
Use the Agent tool to dispatch a subagent with the following context:

Task: {objective}

You are working on {project name}. Your task is to {detailed objective}.

Files you will work with:
- {file path} -- {read/modify} -- {purpose}
- {file path} -- {read/modify} -- {purpose}

Interfaces you must conform to:
- {interface description}
- {type/schema reference}

Done when:
1. {Success criterion 1 -- falsifiable}
2. {Success criterion 2 -- falsifiable}
3. {All tests pass}

Constraints:
- {Constraint 1}
- {Constraint 2}

When complete, report:
- Files changed and summary of changes
- Test results
- Any concerns or risks
- Status: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
```

### Invocation Tips

- **Be explicit about file paths** -- agents cannot search the codebase. If they need a file, include the path.
- **Include file contents when small** -- for files under ~100 lines, include the content directly in the context packet rather than just the path. This reduces agent overhead.
- **State the negative** -- "Do NOT modify the database schema" is as important as "implement the endpoint." Agents optimize for completion and may change more than intended.
- **One task per agent** -- if you find yourself writing "also do X" in the context packet, consider whether X should be a separate dispatch.

## Model Selection Guide

### Haiku: Mechanical Tasks (1-2 files)

Use Haiku for tasks that are well-defined, low-ambiguity, and require no architectural judgment:

**Good Haiku tasks:**
- Rename a function or variable across a file
- Apply a consistent formatting change
- Update import paths after a module is moved
- Generate boilerplate from a template (e.g., CRUD endpoint from a type definition)
- Simple find-and-replace with context awareness
- Update configuration values
- Add JSDoc/docstring comments to existing functions
- Simple type narrowing or type annotation additions

**Haiku context packet characteristics:**
- Very specific instructions ("rename `getUserById` to `findUserById` in `/src/users/service.ts`")
- 1-2 files in scope
- No ambiguity in what "done" looks like
- No architectural decisions required

**Haiku limitations:**
- Poor at tasks requiring understanding of broader system context
- May not correctly handle edge cases in complex refactoring
- Should not be used for tasks where a wrong answer is expensive to fix

### Sonnet: Standard Implementation (3-10 files)

Use Sonnet for the majority of implementation work -- feature development, bug fixes, test writing, and module-scoped refactoring:

**Good Sonnet tasks:**
- Implement a new API endpoint with validation, business logic, and error handling
- Write a comprehensive test suite for an existing module
- Fix a bug that requires understanding call chains across several files
- Refactor a module to use a different pattern (e.g., callbacks to async/await)
- Implement a new service that conforms to an existing interface
- Add error handling and edge case coverage to existing code
- Migrate a module from one dependency to another

**Sonnet context packet characteristics:**
- Clear objective with 3-5 success criteria
- 3-10 files in scope (source + tests + interfaces)
- Some judgment required but within a bounded domain
- Test strategy included for TDD-enforced work

**Sonnet limitations:**
- May struggle with tasks requiring understanding of the full system architecture
- Not ideal for security-sensitive review where subtle vulnerabilities matter
- Should not make architectural decisions that affect other modules

### Opus: Architecture and Review (10+ files or cross-cutting)

Use Opus for tasks that require deep reasoning, cross-cutting understanding, or where mistakes are expensive:

**Good Opus tasks:**
- Review a proposed architecture change for risks and tradeoffs
- Security review of authentication/authorization code
- Complex refactoring that changes patterns across multiple modules
- Design an API contract that multiple services will depend on
- Debug a subtle issue that spans multiple layers (frontend, API, database)
- Evaluate whether a proposed design meets non-functional requirements
- Code review of critical-path changes (payments, auth, data integrity)

**Opus context packet characteristics:**
- High-level objective with nuanced success criteria
- 10+ files or cross-cutting concerns
- Requires weighing tradeoffs and making judgment calls
- Output is analysis/recommendations, not just code changes

**Opus limitations:**
- Higher cost and latency -- do not use for tasks Sonnet can handle
- Overkill for mechanical changes or well-defined implementation tasks

### Model Selection Decision Tree

```
Is the task mechanical with no ambiguity?
  |
  yes --> Is it 1-2 files? --> Haiku
  |       Is it 3+ files? --> Sonnet (mechanical but broad)
  |
  no --> Does it require architectural judgment?
           |
           yes --> Opus
           |
           no --> Does it touch 10+ files or cross-cutting concerns?
                    |
                    yes --> Opus
                    |
                    no --> Sonnet
```

### Cost-Awareness Heuristic

When choosing between models, consider the cost of getting it wrong:

| Risk Level | Model Choice | Reasoning |
|------------|-------------|-----------|
| **Low** (formatting, renames, config) | Haiku | Wrong output is trivially detectable and fixable |
| **Medium** (feature implementation, tests) | Sonnet | Wrong output caught by tests and Stage 1 review |
| **High** (security, architecture, data integrity) | Opus | Wrong output is expensive to detect and fix |

## Error Handling

Subagents can fail in several ways. Each failure mode has a specific recovery strategy.

### Agent Fails to Complete

**Symptom**: Agent reports BLOCKED or NEEDS_CONTEXT.

**Recovery**:
1. Read the agent's output carefully -- it should explain what's missing
2. If NEEDS_CONTEXT: add the missing files, types, or context to the packet and re-dispatch
3. If BLOCKED: resolve the blocker externally (e.g., get a decision from ETYB, fix a broken dependency) then re-dispatch
4. On re-dispatch, include the agent's previous output as additional context ("You previously attempted this task and reported: {previous output}. The missing context is now provided below.")

### Agent Diverges from Spec

**Symptom**: Agent completed work but modified files outside scope, added unrequested features, or took a different approach than specified.

**Recovery**:
1. Identify the specific divergence (Stage 1 review catches this)
2. If the divergence is an improvement: evaluate whether to accept it. If yes, update the spec to match. If no, re-dispatch with narrower scope.
3. If the divergence is scope creep: re-dispatch with explicit "ONLY do X, do NOT do Y" constraints
4. If the divergence is a misunderstanding: clarify the context packet and re-dispatch
5. Include the divergent output as a negative example: "You previously produced {X}. This is incorrect because {reason}. Instead, do {Y}."

### Agent Produces Wrong Output

**Symptom**: Agent reports DONE but output is incorrect (tests fail, types don't match, logic is wrong).

**Recovery**:
1. Run tests to identify specific failures
2. Include the test failure output in the re-dispatch context
3. Narrow the scope if the original task was too broad
4. Consider upgrading the model (Haiku to Sonnet, Sonnet to Opus)
5. If still failing after 1 re-dispatch: decompose the task into smaller pieces

### Agent Produces Output with Concerns

**Symptom**: Agent reports DONE_WITH_CONCERNS.

**Recovery**:
1. Read the concerns carefully -- they often identify real risks
2. Evaluate each concern:
   - **Valid risk, already mitigated**: acknowledge and proceed
   - **Valid risk, not mitigated**: address before integrating (may need additional agent or manual fix)
   - **Invalid concern**: document why it's not a real risk and proceed
3. Do not ignore concerns -- they are the agent's way of flagging uncertainty

### Maximum Retry Policy

- **Maximum 2 re-dispatches per agent per task**
- After 2 failed attempts, the task is too complex or ambiguous for the current approach
- Escalate to ETYB with:
  - Original task specification
  - All agent outputs (including failed attempts)
  - Identified failure patterns
  - Recommendation: decompose further, change approach, or handle manually

## Success Criteria Design

The quality of a dispatch depends entirely on the quality of the success criteria. Vague criteria produce vague output.

### Principles of Good Success Criteria

1. **Falsifiable** -- you can definitively say whether each criterion is met or not
2. **Observable** -- you can check the criterion by examining output (files, tests, logs), not by asking the agent
3. **Complete** -- the criteria cover all aspects of "done" (code changes, tests, documentation, constraints)
4. **Prioritized** -- if criteria conflict, the agent knows which to prioritize

### Success Criteria Templates

**For implementation tasks:**
```
Done when:
1. {Feature} works as specified (verified by {test name or description})
2. All existing tests continue to pass
3. New tests cover {happy path, error cases, edge cases}
4. Code follows the project's {pattern/style} (no linting errors)
5. No files outside {scope boundary} are modified
```

**For bug fix tasks:**
```
Done when:
1. The bug described in {bug description} no longer reproduces
2. A regression test prevents this bug from recurring
3. The root cause is documented in a code comment
4. No existing tests are broken by the fix
5. The fix does not introduce new warnings or errors
```

**For refactoring tasks:**
```
Done when:
1. {Old pattern} is replaced with {new pattern} in all files within {scope}
2. All existing tests pass without modification (behavior preserved)
3. No new functionality is added (pure refactor)
4. Code is cleaner/simpler by {specific metric: fewer lines, fewer dependencies, clearer naming}
```

**For review tasks (Opus):**
```
Done when:
1. All files in {scope} have been reviewed
2. Findings are categorized as: critical (must-fix), important (should-fix), or minor (nice-to-have)
3. Each finding includes: location, description, severity, and recommended fix
4. An overall assessment is provided: APPROVE, APPROVE_WITH_CONCERNS, or REQUEST_CHANGES
5. Security-sensitive areas are explicitly called out
```

### Anti-Patterns in Success Criteria

| Anti-Pattern | Problem | Better Version |
|-------------|---------|---------------|
| "Make it work" | Not falsifiable | "POST /api/users returns 201 with valid input, 400 with invalid input" |
| "Write good tests" | Subjective | "Write tests covering: valid input, missing required fields, duplicate email, database error" |
| "Refactor the code" | Unbounded scope | "Replace callback-based error handling with try/catch in `/src/api/handlers/*.ts`" |
| "Fix the bug" | No verification method | "The 500 error on `/api/orders` with empty cart no longer occurs. Regression test added." |
| "Make it production-ready" | Undefined standard | "Add input validation, error handling, request logging, and rate limiting to the endpoint" |

## Dispatch Lifecycle Summary

```
1. RECEIVE task from ETYB or plan
2. EVALUATE: independence, complexity, domain isolation
3. DECIDE: inline, single dispatch, parallel, or pipeline
4. CONSTRUCT context packet (template above)
5. SELECT model (haiku/sonnet/opus decision tree)
6. VALIDATE context packet (quality checklist)
7. DISPATCH via Agent tool
8. MONITOR agent status signal
9. REVIEW output (Stage 1: spec conformance)
10. INTEGRATE or RE-DISPATCH based on review
11. REPORT results to ETYB/plan
```
