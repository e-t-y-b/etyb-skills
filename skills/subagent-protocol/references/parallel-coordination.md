# Parallel Coordination: Multi-Agent Dispatch

This reference covers dispatching multiple subagents simultaneously for independent work streams, verifying their independence, integrating their results, and handling conflicts.

## When to Parallelize

Parallel dispatch is appropriate when you have multiple independent tasks that would otherwise be executed sequentially. The time savings can be substantial -- three agents running simultaneously complete in the time of the slowest one, not the sum of all three.

### Conditions for Parallel Dispatch

All of the following must be true:

1. **3+ independent tasks** -- with only 2 tasks, the overhead of parallel coordination often exceeds the time savings. With 3+, the benefit is clear.
2. **Different code domains** -- each agent works in a different directory, module, or service. No file overlap.
3. **No shared mutable state** -- no agent's output is another agent's input. No shared database migration files, no shared configuration being modified.
4. **Independent test suites** -- each agent's work can be tested without the other agents' changes being present.
5. **Clear domain boundaries** -- you can draw a line around each agent's scope and that line doesn't overlap with any other agent's scope.

### Indicators That Parallel Dispatch Will Work Well

| Indicator | Why It Works |
|-----------|-------------|
| Tasks touch different directories | Physical file isolation |
| Tasks have different test files | Independent verification |
| Tasks implement different features | No logical dependency |
| Tasks work on different services in a microservice architecture | Service boundary isolation |
| Tasks modify different layers (frontend, backend, database) | Layer isolation -- but verify no shared contracts |
| Tasks have no ordering requirement | True independence |

## When NOT to Parallelize

### Hard Blockers

These situations make parallel dispatch dangerous -- sequence the work instead:

**Shared database schema changes**
- Two agents both need to modify the same migration file
- Two agents add columns to the same table
- One agent's schema change affects another agent's queries
- Resolution: sequence schema changes, parallelize the code that uses them

**Shared API contract changes**
- One agent modifies an API response format that another agent consumes
- Two agents both extend the same API endpoint
- Resolution: finalize the API contract first (Phase 1), then implement in parallel (Phase 2)

**One task's output is another's input**
- Agent A produces a library that Agent B imports
- Agent A generates types that Agent B uses
- Resolution: sequence with A before B, include A's output in B's context

**Tight coupling between modules**
- Two modules share global state, singletons, or event buses
- Changes in one module's behavior affect the other's correctness
- Resolution: refactor to decouple first, or handle as a single agent task

**Shared configuration files**
- Both agents need to modify `package.json`, `tsconfig.json`, or environment configs
- Resolution: have one agent handle all config changes, or handle config manually after integration

### Soft Warnings

These situations can work with parallel dispatch but require extra care:

| Situation | Risk | Mitigation |
|-----------|------|-----------|
| Shared read-only files (types, interfaces) | Agent may need to extend them | Freeze interfaces before dispatch; any extensions go to a dedicated agent |
| Shared test utilities | Both agents may add helpers | Define a naming convention to avoid collisions |
| Same programming language patterns | Stylistic inconsistency | Include style guide in both context packets |
| Shared CI pipeline | Both changes must pass the same pipeline | Run combined CI after integration |

## The Parallel Dispatch Protocol

### Step 1: Identify Independent Domains

Analyze the work and draw domain boundaries. Each domain should map to one agent:

```markdown
## Domain Analysis

### Domain A: {name}
- **Files**: {list of files in this domain}
- **Tests**: {test files for this domain}
- **Dependencies**: {read-only files this domain uses}
- **Produces**: {what this domain's agent will output}

### Domain B: {name}
- **Files**: {list of files in this domain}
- **Tests**: {test files for this domain}
- **Dependencies**: {read-only files this domain uses}
- **Produces**: {what this domain's agent will output}

### Shared (read-only)
- {Files both domains read but neither modifies}
```

Domain boundaries typically align with:
- **Directory boundaries** -- `/src/auth/` vs `/src/payments/` vs `/src/notifications/`
- **Module boundaries** -- `auth-module` vs `billing-module` vs `user-module`
- **Service boundaries** -- `auth-service` vs `order-service` vs `notification-service`
- **Layer boundaries** -- frontend vs backend vs infrastructure (use with caution -- layers often share contracts)

### Step 2: Create Task Specs

Create a complete context packet for each agent (see `dispatch-patterns.md` for the template). Each packet should be self-contained -- an agent should be able to complete its work without knowledge of what other agents are doing.

**Critical additions for parallel agents:**
- Explicitly state which files are read-only ("Do NOT modify `/src/shared/types.ts`")
- Include the current state of any shared interfaces the agent must conform to
- State that other agents are working in parallel but on different domains
- Include the combined test command so the agent can verify its work in isolation

### Step 3: Verify Independence

Before dispatching, run the independence verification:

```markdown
## Independence Matrix

| | Agent A Files | Agent B Files | Agent C Files |
|---|---|---|---|
| **Agent A Files** | - | No overlap | No overlap |
| **Agent B Files** | No overlap | - | No overlap |
| **Agent C Files** | No overlap | No overlap | - |

## Independence Questions
1. If Agent A's changes were applied without Agent B's, would Agent A's tests pass? YES/NO
2. If Agent B's changes were applied without Agent A's, would Agent B's tests pass? YES/NO
3. If Agent C's changes were applied without A's and B's, would Agent C's tests pass? YES/NO
4. Do any agents modify the same file? YES (STOP) / NO
5. Do any agents modify files that other agents read? YES (CAUTION) / NO

## Verdict: SAFE TO PARALLELIZE / MUST SEQUENCE / NEEDS RESTRUCTURING
```

If the independence matrix shows any file overlap in the "modify" category, you must either:
- Restructure the tasks to eliminate the overlap
- Sequence the overlapping agents (dispatch the rest in parallel)
- Merge the overlapping tasks into a single agent

### Step 4: Dispatch All Agents Simultaneously

Dispatch all agents at the same time. Use domain-specific names for clarity:

```
## Parallel Dispatch

Dispatching 3 agents simultaneously:

### Agent: auth-implementation
Model: Sonnet
Task: Implement authentication module
[Full context packet]

### Agent: payment-implementation
Model: Sonnet
Task: Implement payment processing module
[Full context packet]

### Agent: notification-implementation
Model: Haiku
Task: Implement notification templates
[Full context packet]

Dispatched at: {timestamp}
Expected completion: {estimate based on task complexity}
```

### Step 5: Monitor Agent Status

As agents complete, track their status:

```markdown
## Agent Status Board

| Agent | Status | Completion Time | Notes |
|-------|--------|----------------|-------|
| auth-implementation | DONE | 3m 42s | All tests pass |
| payment-implementation | DONE_WITH_CONCERNS | 5m 18s | Flagged rate limiting gap |
| notification-implementation | DONE | 1m 15s | All tests pass |
```

**Handling mixed results:**
- If all DONE: proceed to integration
- If any DONE_WITH_CONCERNS: evaluate concerns before integration
- If any NEEDS_CONTEXT: provide context and re-dispatch that agent (others continue)
- If any BLOCKED: resolve blocker, re-dispatch (others continue)
- Do NOT wait for all agents if some are blocked -- integrate what's ready, handle blockers separately

### Step 6: Integrate Results

Integration is the most critical step. This is where parallel dispatch can go wrong if independence was not verified correctly.

#### 6a: Merge Conflict Detection

Check whether agents modified the same files:

```
## File Modification Matrix

| File | Agent A | Agent B | Agent C | Conflict? |
|------|---------|---------|---------|-----------|
| /src/auth/login.ts | Modified | - | - | No |
| /src/payments/checkout.ts | - | Modified | - | No |
| /src/notifications/email.ts | - | - | Modified | No |
| /src/shared/types.ts | - | - | - | No (read-only) |
| package.json | Modified | Modified | - | YES |
```

If merge conflicts exist:
- For trivial conflicts (both agents added different dependencies to `package.json`): merge manually
- For non-trivial conflicts (both agents changed the same function): this indicates the independence verification failed. Resolve manually; do not re-dispatch.

#### 6b: Semantic Conflict Detection

Even without file conflicts, agents can produce semantically contradictory changes:

| Semantic Conflict Type | How to Detect | Example |
|----------------------|---------------|---------|
| **Contradictory behavior** | Run combined tests | Agent A expects 200 response, Agent B changed it to return 201 |
| **Incompatible types** | Type-check combined output | Agent A adds field `userId: string`, Agent B expects `userId: number` |
| **Duplicate functionality** | Code review | Both agents implemented a helper function with the same purpose |
| **Conflicting error handling** | Code review | Agent A throws on invalid input, Agent B returns null |
| **Resource contention** | Integration testing | Both agents create the same database index |

Detection method: after merging all agent outputs, run:
1. Full type check / compilation
2. Full test suite (all agents' tests combined)
3. Quick manual review of any shared interfaces or contracts

#### 6c: Combined Test Suite

Run ALL tests on the combined output -- not just each agent's tests individually:

```bash
# Run the full test suite, not just individual agent tests
npm test           # or equivalent for the project
npm run typecheck  # verify no type conflicts
npm run lint       # verify no style conflicts
```

If combined tests fail:
- Identify which agent's changes caused the failure
- If it's a genuine conflict: resolve manually (do not re-dispatch)
- If it's an independent failure: re-dispatch the failing agent with test output as context

## Naming Convention for Parallel Agents

Use domain-specific names that make it clear what each agent is responsible for:

### Naming Pattern

`{domain}-{action}`

**Good names:**
- `auth-implementation` -- implementing the auth module
- `payment-refactor` -- refactoring payment processing
- `notification-tests` -- writing tests for notifications
- `api-contract-design` -- designing API contracts
- `frontend-auth-ui` -- building the auth UI components
- `backend-order-service` -- implementing the order service

**Bad names:**
- `agent-1`, `agent-2`, `agent-3` -- no domain context
- `task-a`, `task-b` -- no semantic meaning
- `fast-agent`, `main-agent` -- describes behavior, not domain

### When Multiple Agents Work in the Same Domain

If you must dispatch multiple agents within the same domain (rare -- usually indicates the domain should be split further):

`{domain}-{subdomain}-{action}`

Examples:
- `auth-login-implementation` and `auth-registration-implementation`
- `payment-checkout-flow` and `payment-subscription-flow`

## Integration Review Checklist

After merging all agent outputs, before marking the parallel dispatch as complete:

- [ ] All agents reported terminal status (DONE or DONE_WITH_CONCERNS)
- [ ] No file merge conflicts (or all conflicts resolved manually)
- [ ] No semantic conflicts detected (types, behavior, error handling)
- [ ] Combined test suite passes (all agents' tests + existing tests)
- [ ] Type check / compilation succeeds on combined output
- [ ] Linting passes on combined output
- [ ] Any DONE_WITH_CONCERNS findings have been evaluated and addressed
- [ ] Integration report written (see SKILL.md response format)

## Common Parallel Dispatch Patterns

### Pattern: Feature Decomposition

Split a large feature into independent sub-features:

```
Feature: User Dashboard
  |
  |-- Agent: dashboard-auth (verify user permissions)
  |-- Agent: dashboard-analytics (fetch and display metrics)
  |-- Agent: dashboard-notifications (notification feed widget)
  |
  Integration: combine into single dashboard page
```

### Pattern: Service Implementation

Implement multiple independent services simultaneously:

```
System: Order Processing
  |
  |-- Agent: order-service (CRUD operations, validation)
  |-- Agent: inventory-service (stock checking, reservation)
  |-- Agent: notification-service (order confirmation emails)
  |
  Integration: verify service contracts align, run integration tests
```

### Pattern: Test Suite Expansion

Write tests for multiple modules simultaneously:

```
Test Coverage Push
  |
  |-- Agent: auth-tests (unit + integration for auth module)
  |-- Agent: payment-tests (unit + integration for payment module)
  |-- Agent: user-tests (unit + integration for user module)
  |
  Integration: run full test suite, check for test isolation issues
```

### Pattern: Cross-Platform Implementation

Implement the same feature on different platforms:

```
Feature: Push Notifications
  |
  |-- Agent: ios-notifications (Swift, APNs integration)
  |-- Agent: android-notifications (Kotlin, FCM integration)
  |-- Agent: backend-notifications (Node.js, notification dispatch service)
  |
  Integration: verify API contracts match across all platforms
```

## Failure Modes in Parallel Dispatch

| Failure Mode | Root Cause | Prevention | Recovery |
|-------------|-----------|-----------|----------|
| Merge conflicts | Incomplete independence analysis | Strict file overlap check | Manual merge, update independence matrix |
| Semantic conflicts | Shared contracts not frozen | Freeze interfaces before dispatch | Manual resolution, re-run combined tests |
| One agent blocks others | Hidden dependency | Better dependency analysis | Continue with independent agents, handle blocker separately |
| All agents fail | Ambiguous shared context | Better context packets | Decompose differently, dispatch sequentially |
| Integration test failure | Agents made incompatible assumptions | Include shared contracts in all packets | Identify root assumption conflict, fix, re-test |
| Inconsistent patterns | No style guide in context | Include style guide in all packets | Post-integration refactor (single agent) |
