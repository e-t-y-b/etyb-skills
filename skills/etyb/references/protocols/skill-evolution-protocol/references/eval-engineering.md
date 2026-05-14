# Eval Engineering: Writing, Running, and Maintaining Skill Evals

> **Evals are the tests for documentation.** Without evals, you cannot know if a skill is working. Without failing evals first, you cannot know if a skill change was meaningful.

## Table of Contents

- [1. Eval JSON Format](#1-eval-json-format)
- [2. Assertion Types](#2-assertion-types)
- [3. Writing Good Evals](#3-writing-good-evals)
- [4. How Many Evals](#4-how-many-evals)
- [5. Running Evals](#5-running-evals)
- [6. Interpreting Results](#6-interpreting-results)
- [7. Eval Maintenance](#7-eval-maintenance)
- [8. Eval Anti-Patterns](#8-eval-anti-patterns)
- [9. Real-World Eval Examples](#9-real-world-eval-examples)

---

## 1. Eval JSON Format

Every skill has an `evals/evals.json` file. The format is strict — no optional fields, no variations.

### 1.1 Full Schema

```json
{
  "skill_name": "exact-skill-directory-name",
  "evals": [
    {
      "id": 0,
      "name": "descriptive-kebab-case-name",
      "prompt": "The user's request that tests the skill. This is the exact text that would be sent to the agent as a user message. It should be realistic — something a real user would actually say.",
      "expected_output": "A human-readable description of what a good response looks like. This is NOT the expected verbatim response — it describes the qualities and content the response should have.",
      "assertions": [
        {
          "text": "Specific, falsifiable assertion about the response",
          "type": "behavioral_check"
        },
        {
          "text": "Another specific assertion",
          "type": "content_check"
        }
      ],
      "files": []
    }
  ]
}
```

### 1.2 Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `skill_name` | string | Yes | Must match the skill directory name exactly |
| `evals` | array | Yes | Array of eval objects |
| `evals[].id` | integer | Yes | Unique within this file, sequential starting from 0 |
| `evals[].name` | string | Yes | Kebab-case, descriptive, unique within this file |
| `evals[].prompt` | string | Yes | The user message that triggers the skill |
| `evals[].expected_output` | string | Yes | Human-readable description of ideal response |
| `evals[].assertions` | array | Yes | 4-6 specific, falsifiable checks |
| `evals[].assertions[].text` | string | Yes | The assertion statement |
| `evals[].assertions[].type` | string | Yes | One of: `behavioral_check`, `content_check`, `negative_check` |
| `evals[].files` | array | Yes | File paths for context (usually empty `[]`) |

### 1.3 The `files` Field

The `files` array provides additional context files that should be loaded when running the eval. Most evals do not need this — the prompt alone is sufficient.

Use `files` when:
- The eval tests behavior that depends on reading a specific codebase
- The eval simulates a scenario where the agent has project context
- The eval needs a specific file structure to be meaningful

Example:
```json
{
  "files": [
    "src/auth/middleware.ts",
    "tests/auth/middleware.test.ts"
  ]
}
```

---

## 2. Assertion Types

### 2.1 behavioral_check

Tests what the skill DOES — its actions, decisions, and process.

**What it checks:**
- Does the skill ask the right questions?
- Does the skill enforce constraints or push back?
- Does the skill present tradeoffs before recommending?
- Does the skill follow its conversation flow?
- Does the skill apply its golden rule?

**Examples:**
```json
{"text": "Asks clarifying questions before making a recommendation", "type": "behavioral_check"}
{"text": "Insists on writing a failing test BEFORE any production code", "type": "behavioral_check"}
{"text": "Pushes back on the request to skip review with evidence", "type": "behavioral_check"}
{"text": "Presents 2-3 options with tradeoffs instead of a single prescription", "type": "behavioral_check"}
{"text": "Does NOT simply comply with the request to skip the process", "type": "behavioral_check"}
```

**When to use:** For process protocols especially. Behavioral checks verify the skill enforces its discipline. Also useful for domain experts to verify they follow their conversation flow (ask questions, present tradeoffs, let user decide).

### 2.2 content_check

Tests what the skill SAYS — the specific knowledge, tools, patterns, and warnings it includes.

**What it checks:**
- Does the response mention the right tools or frameworks?
- Does the response include specific technical guidance?
- Does the response reference the correct patterns or anti-patterns?
- Does the response include warnings about common pitfalls?
- Does the response use the correct terminology?

**Examples:**
```json
{"text": "Mentions OpenAPI 3.1 for API specification", "type": "content_check"}
{"text": "Recommends token bucket algorithm for rate limiting", "type": "content_check"}
{"text": "Includes the red-green-refactor cycle steps", "type": "content_check"}
{"text": "References the design decision DL-015 when pushing back", "type": "content_check"}
{"text": "Suggests monolith over microservices for a 4-person startup", "type": "content_check"}
```

**When to use:** For domain experts especially. Content checks verify the skill has the right knowledge. Also useful for protocols to verify they reference the right steps and tools.

### 2.3 negative_check

Tests what the skill does NOT do — behaviors and content that should be absent.

**What it checks:**
- Does the skill avoid giving wrong advice?
- Does the skill NOT recommend inappropriate technologies?
- Does the skill NOT skip required steps?
- Does the skill NOT use banned phrases or patterns?
- Does the skill NOT agree to requests that violate its golden rule?

**Examples:**
```json
{"text": "Does NOT recommend Kubernetes for a 3-person startup", "type": "negative_check"}
{"text": "Does NOT produce implementation code before a test exists", "type": "negative_check"}
{"text": "Does NOT use performative agreement phrases like 'Great catch!'", "type": "negative_check"}
{"text": "Does NOT suggest deferring the critical security finding", "type": "negative_check"}
{"text": "Does NOT agree to skip the review under any framing", "type": "negative_check"}
```

**When to use:** Essential for every eval. Negative checks catch the most dangerous failure mode: a skill that sounds confident while giving wrong guidance. Include at least 1 negative check per eval.

### 2.4 Assertion Type Distribution

| Eval Type | behavioral_check | content_check | negative_check |
|-----------|-----------------|---------------|----------------|
| Protocol eval | 2-3 | 1-2 | 1-2 |
| Expert eval | 1-2 | 2-3 | 1 |
| Edge case eval | 1-2 | 1-2 | 2-3 |

---

## 3. Writing Good Evals

### 3.1 One Concern Per Eval

Each eval tests ONE thing. Do not write an eval that tests scale-aware guidance AND tool recommendations AND boundary enforcement all at once.

**Bad eval — tests everything:**
```json
{
  "prompt": "Help me build a backend for my SaaS startup. We have 3 developers, need REST APIs, GraphQL for mobile, authentication, and microservices. What do you recommend?",
  "assertions": [
    {"text": "Recommends monolith for small team", "type": "content_check"},
    {"text": "Suggests TypeScript or Python", "type": "content_check"},
    {"text": "Discusses OAuth2 for auth", "type": "content_check"},
    {"text": "Warns against microservices", "type": "content_check"},
    {"text": "Asks clarifying questions", "type": "behavioral_check"},
    {"text": "Presents tradeoffs", "type": "behavioral_check"},
    {"text": "Covers deployment", "type": "content_check"},
    {"text": "Mentions testing", "type": "content_check"}
  ]
}
```

**Good eval — tests one thing (scale-aware recommendation):**
```json
{
  "prompt": "We're a 4-person startup building a SaaS project management tool. Our team knows TypeScript and Python. We need to pick a backend stack. We're expecting maybe 1000 users in 6 months. What do you recommend?",
  "assertions": [
    {"text": "Asks clarifying questions before recommending", "type": "behavioral_check"},
    {"text": "Suggests monolith over microservices for this team size", "type": "content_check"},
    {"text": "Recommends a stack the team knows (TypeScript or Python)", "type": "content_check"},
    {"text": "Does NOT recommend Java, Rust, or Go for this scenario", "type": "negative_check"},
    {"text": "Presents options with tradeoffs rather than a single prescription", "type": "behavioral_check"}
  ]
}
```

### 3.2 Falsifiable Assertions

Every assertion must be clearly true or false when evaluating a response. No ambiguity.

| Bad Assertion | Why Bad | Good Assertion |
|--------------|---------|----------------|
| "Gives good advice" | Subjective | "Recommends monolith for team under 10 engineers" |
| "Is helpful" | Unmeasurable | "Asks 2-3 clarifying questions before recommending" |
| "Considers security" | Too vague | "Mentions OAuth2 or OIDC for authentication" |
| "Pushes back appropriately" | Subjective | "Refuses to skip the review and cites the Verify gate requirement" |
| "Doesn't make mistakes" | Unfalsifiable | "Does NOT recommend microservices for a 3-person team" |

### 3.3 Scenario-Based Prompts

Eval prompts should be realistic user messages. They should include enough context for the skill to activate and respond meaningfully.

**Components of a good eval prompt:**

| Component | Purpose | Example |
|-----------|---------|---------|
| **Context** | What the user is building | "We're building a payment processing service" |
| **Constraints** | Limits that shape the answer | "4-person team, TypeScript expertise, 6-month runway" |
| **Specific question** | What the user wants to know | "Should we use microservices or a monolith?" |
| **Optional: pressure** | Tests discipline enforcement | "Can we skip tests? We have a demo tomorrow" |
| **Optional: code** | Tests response to specific code | Code blocks with specific issues to catch |

### 3.4 Edge Case Evals

Every skill should have at least one eval that tests a boundary condition:

| Edge Case Type | What It Tests | Example |
|---------------|---------------|---------|
| **Scope boundary** | Skill correctly defers to another skill | User asks backend-architect about CSS styling |
| **Discipline resistance** | Skill resists requests to skip its golden rule | User asks tdd-protocol to skip tests |
| **Conflicting requirements** | Skill handles contradictions gracefully | User wants both maximum performance and minimum cost |
| **Missing context** | Skill asks for missing information | User asks "what database should I use?" with no context |
| **Overlap with other skill** | Skill stays in its lane | User asks review-protocol to perform the actual review |

### 3.5 Prompt Length Guidelines

| Eval Type | Prompt Length | Why |
|-----------|-------------|-----|
| Simple behavioral | 1-3 sentences | Tests a specific behavior trigger |
| Scenario-based | 3-6 sentences | Provides enough context for meaningful response |
| Code-based | Prompt + code block | Tests response to specific code |
| Edge case | 2-4 sentences | Minimal context to test boundary behavior |

---

## 4. How Many Evals

### 4.1 By Skill Type

| Skill Type | Eval Count | Rationale |
|-----------|-----------|-----------|
| Process protocol | 3-4 | Test discipline enforcement, rationalization resistance, edge case |
| Domain expert | 3-5 | Test knowledge accuracy, scale-awareness, boundary respect, edge cases |
| Meta-protocol | 3 | Test core workflow, improvement loop, scope management |

### 4.2 What Each Eval Should Cover

**For a process protocol (3-4 evals):**
1. Happy path — user follows the process correctly (does the skill guide well?)
2. Discipline resistance — user tries to skip the process (does the skill push back?)
3. Edge case — unusual situation that still needs the process (does the skill adapt?)
4. Optional: Integration — skill working with other skills in a multi-step workflow

**For a domain expert (3-5 evals):**
1. Core recommendation — user needs guidance in the primary domain area
2. Scale-aware — user at a specific scale gets appropriate recommendations
3. Boundary — user asks about something outside the skill's scope
4. Tradeoff presentation — user needs to choose between options
5. Optional: Deep dive — user asks about a specific sub-domain in detail

### 4.3 Quality Over Quantity

**Three excellent evals > ten mediocre evals.**

An excellent eval:
- Tests one thing clearly
- Has a realistic prompt
- Has 4-6 falsifiable assertions
- Includes at least one negative check
- Would actually fail if the skill broke

A mediocre eval:
- Tests multiple things vaguely
- Has a contrived prompt
- Has 1-2 assertions that are always true
- No negative checks
- Would pass even if the skill gave garbage

---

## 5. Running Evals

### 5.1 Manual Walkthrough

The simplest way to run an eval:

1. Open the skill's `evals/evals.json`
2. Copy the `prompt` from an eval
3. Invoke the skill with that prompt (activate the skill, send the prompt)
4. Read the response
5. Check each assertion: is it true for this response?
6. Record: PASS (all assertions true) or FAIL (any assertion false)

**Manual walkthrough checklist:**
```
For each eval:
  [ ] Prompt sent to the skill
  [ ] Response received
  [ ] Assertion 1: PASS / FAIL
  [ ] Assertion 2: PASS / FAIL
  [ ] Assertion 3: PASS / FAIL
  [ ] ...
  [ ] Overall: PASS / FAIL
  [ ] If FAIL: which assertion(s) failed and why?
```

### 5.2 Systematic Eval Run

When running all evals for a skill (e.g., after a skill change):

```
1. Read evals/evals.json for the skill
2. For each eval (in order by id):
   a. Send the prompt to the skill
   b. Evaluate each assertion against the response
   c. Record results
3. Compile summary:
   - Total evals: N
   - Passed: X
   - Failed: Y
   - Failed eval names and which assertions failed
4. If any fail: investigate before declaring the skill change complete
```

### 5.3 Regression Run

After any skill change, run ALL evals for that skill — not just the new one:

```
1. Run the new eval(s) first — verify they pass with the change
2. Run ALL existing evals — verify none regressed
3. If a regression is found:
   a. DO NOT remove the failing eval
   b. Adjust the skill change to pass BOTH the new and existing evals
   c. If impossible: the change conflicts with existing behavior — redesign
```

---

## 6. Interpreting Results

### 6.1 Result Patterns

| Pattern | Meaning | Action |
|---------|---------|--------|
| All pass | Skill is working correctly | No action needed |
| New eval fails, existing pass | The gap is real; skill needs the change | Make the change |
| New eval passes without change | The gap is not real, or eval does not test the right thing | Rewrite the eval |
| Existing eval fails after change | Regression introduced | Fix the change to pass both |
| Multiple evals fail | Skill needs significant rework | Consider redesign, not patches |
| Assertion flaky (sometimes pass, sometimes fail) | Assertion is ambiguous | Rewrite the assertion to be clearly falsifiable |

### 6.2 Debugging Failed Evals

When an eval fails, diagnose which component is wrong:

| Component | Diagnostic Question | If This Is Wrong |
|-----------|-------------------|-----------------|
| **Prompt** | Is the prompt realistic? Does it trigger the right skill? | Rewrite the prompt |
| **Expected output** | Does expected_output describe what a good response should be? | Rewrite expected_output |
| **Assertion** | Is the assertion falsifiable? Is it testing the right thing? | Rewrite the assertion |
| **Skill** | Does the skill have the knowledge/behavior needed? | Improve the skill |
| **Reference** | Is the relevant reference file complete? | Improve the reference |

### 6.3 Eval Confidence Levels

| Confidence | Criteria | Action |
|-----------|----------|--------|
| **High** | All assertions clearly pass or fail; no ambiguity | Trust the result |
| **Medium** | 1-2 assertions are borderline | Review those assertions; consider rewriting |
| **Low** | Multiple assertions are ambiguous | Rewrite the eval before trusting the result |

---

## 7. Eval Maintenance

### 7.1 When to Update Evals

| Trigger | Action |
|---------|--------|
| Skill scope changes | Add evals for new scope, remove evals for dropped scope |
| Skill is merged with another | Merge eval files; remove duplicates |
| Skill is split | Distribute evals to the correct new skill |
| Skill is deprecated | Move evals to replacement skill or delete |
| Tool/framework version changes | Update prompts and assertions that reference specific versions |
| User feedback reveals a gap | Add a new eval that captures the gap (TDD) |

### 7.2 Eval Hygiene

**Regular maintenance tasks:**
- Remove evals for deprecated features
- Update evals when skill scope changes
- Verify all evals still have realistic prompts
- Check that assertion types are distributed well (behavioral + content + negative)
- Ensure eval names are still descriptive after scope changes

### 7.3 The TDD-for-Docs Cycle with Evals

```
1. Identify gap → User reports a bad answer or missing guidance
2. Write failing eval → New eval with prompt that triggers the gap
3. Verify it fails → Run the eval against the current skill
4. Fix the skill → Minimal change to pass the new eval
5. Verify it passes → Run the new eval
6. Verify no regressions → Run ALL evals
7. Commit → Skill change + new eval in one commit
```

This cycle is the golden rule in action. No skill change without a failing eval first.

---

## 8. Eval Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| **Tautological assertions** | "Response is relevant to the prompt" — always true | Make assertions specific and falsifiable |
| **Over-testing** | 10+ assertions per eval | 4-6 assertions, one concern per eval |
| **Under-testing** | 1-2 vague assertions | Add specific behavioral, content, and negative checks |
| **Copy-paste prompts** | All evals have similar prompts | Each eval should test a different scenario |
| **Missing negative checks** | No assertions about what should NOT happen | Add at least 1 negative check per eval |
| **Unrealistic prompts** | "Test the skill's ability to handle X" | Write prompts as actual user messages |
| **Testing the format** | "Response uses markdown headers" | Test behavior and content, not formatting |
| **Stale evals** | Evals reference deprecated features or old tool versions | Update during maintenance cycles |
| **God eval** | One eval tests everything | Split into focused evals with one concern each |
| **Eval without expected_output** | Empty or vague expected_output field | Write a clear description of what good looks like |

---

## 9. Real-World Eval Examples

### 9.1 Protocol Eval: Discipline Enforcement

This eval tests whether `tdd-protocol` resists the rationalization to skip tests:

```json
{
  "id": 1,
  "name": "rationalization-resistance",
  "prompt": "I know I should write tests but we have a demo tomorrow and the PM is breathing down my neck. Can you just help me implement the user authentication flow? I'll add tests next sprint, I promise.",
  "expected_output": "Should acknowledge the time pressure but counter the rationalization with evidence. Should explain that TDD is faster for anything beyond trivial code. Should offer a pragmatic approach: TDD the critical path (auth is critical), spike-then-delete if needed. Should NOT just comply and skip tests.",
  "assertions": [
    {"text": "Does NOT simply comply with skipping tests", "type": "behavioral_check"},
    {"text": "Acknowledges the time pressure without being dismissive", "type": "behavioral_check"},
    {"text": "Provides evidence for why TDD is faster (reduced debugging, fewer regressions)", "type": "content_check"},
    {"text": "Offers a pragmatic path forward that maintains TDD discipline", "type": "content_check"},
    {"text": "Points out that 'tests next sprint' never happens based on evidence", "type": "content_check"}
  ],
  "files": []
}
```

**Why this is a good eval:**
- Realistic prompt with real-world pressure
- Tests behavioral discipline (push back)
- Includes evidence requirement (not just "say no")
- Offers pragmatic alternative (not just blocking)
- Has both behavioral and content checks

### 9.2 Expert Eval: Scale-Aware Recommendation

This eval tests whether `backend-architect` gives appropriate guidance for a specific scale:

```json
{
  "id": 1,
  "name": "startup-stack-recommendation",
  "prompt": "We're a 4-person startup building a SaaS project management tool. Our team knows TypeScript and Python. We need to pick a backend stack. We're expecting maybe 1000 users in 6 months. What do you recommend?",
  "expected_output": "Should recommend TypeScript/Node given team expertise. Should suggest monolith over microservices. Should ask clarifying questions about frontend stack and deployment target. Should NOT recommend Rust or Java.",
  "assertions": [
    {"text": "Asks clarifying questions before recommending", "type": "behavioral_check"},
    {"text": "Suggests monolith over microservices for this team size", "type": "content_check"},
    {"text": "Recommends a stack the team knows (TypeScript or Python)", "type": "content_check"},
    {"text": "Does NOT recommend Java, Rust, or Go for this scenario", "type": "negative_check"},
    {"text": "Presents options with tradeoffs rather than a single prescription", "type": "behavioral_check"}
  ],
  "files": []
}
```

### 9.3 Edge Case Eval: Scope Boundary

This eval tests whether a skill correctly defers when asked about something outside its scope:

```json
{
  "id": 3,
  "name": "scope-boundary-frontend-question",
  "prompt": "Should I use server-side rendering or client-side rendering for my React dashboard? I want good SEO and fast initial page loads.",
  "expected_output": "Should recognize this is a frontend architecture question and defer to frontend-architect. May provide brief context on how SSR affects the backend (API design, caching) but should not make the frontend architecture decision.",
  "assertions": [
    {"text": "Defers the frontend architecture decision to frontend-architect", "type": "behavioral_check"},
    {"text": "Does NOT prescribe SSR vs CSR as a backend decision", "type": "negative_check"},
    {"text": "May mention backend implications (API design, caching) without taking ownership", "type": "content_check"},
    {"text": "Maintains helpful tone while respecting scope boundary", "type": "behavioral_check"}
  ],
  "files": []
}
```
