# Skill Creation: Building etyb Skills from Scratch

> **Always use `WebSearch` to verify current best practices** before recommending tools, frameworks, or patterns in skill content. The ecosystem moves fast; what was true 6 months ago may be outdated.

## Table of Contents

- [1. The Full SKILL.md Anatomy](#1-the-full-skillmd-anatomy)
- [2. Reference File Anatomy](#2-reference-file-anatomy)
- [3. Protocol vs Expert Skill Differences](#3-protocol-vs-expert-skill-differences)
- [4. Naming Conventions](#4-naming-conventions)
- [5. Directory Structure Template](#5-directory-structure-template)
- [6. Trigger Keyword Design](#6-trigger-keyword-design)
- [7. Line Count Targets and Constraints](#7-line-count-targets-and-constraints)
- [8. Skill Creation Checklist](#8-skill-creation-checklist)
- [9. Common Mistakes and How to Avoid Them](#9-common-mistakes-and-how-to-avoid-them)

---

## 1. The Full SKILL.md Anatomy

Every SKILL.md follows a precise structure. Each section serves a specific purpose. Omitting a section weakens the skill. Adding unnecessary sections bloats it.

### 1.1 YAML Frontmatter

The frontmatter is the skill's identity card. It determines when the skill is activated by ETYB.

```yaml
---
name: skill-name-here
description: >
  200-400 words. First sentence: what the skill IS and what it DOES. Second sentence:
  scope boundaries (what it covers, what it does not). Remaining sentences: trigger
  keywords packed densely. Aim for 100+ unique trigger keywords. Cover both business
  outcomes ("build a payment system") and technical specifics ("Stripe webhook handling").
  The description is the primary matching surface for skill activation — if a keyword
  is not here, the skill will not be found.
---
```

**Rules for the `name` field:**
- Lowercase, hyphenated, matches the directory name exactly
- Protocols end with `-protocol` (e.g., `tdd-protocol`, `review-protocol`)
- Experts end with a role suffix: `-architect`, `-engineer`, `-analyst`, `-writer` (e.g., `backend-architect`, `security-engineer`)
- No abbreviations unless universally understood (e.g., `tdd`, `sre`, `qa`)

**Rules for the `description` field:**
- 200-400 words (shorter loses trigger coverage, longer is noise)
- First sentence: elevator pitch of what the skill does
- Include the phrase "Use this skill whenever..." followed by scenarios
- Include the phrase "Trigger when the user mentions..." followed by quoted keywords
- Pack keywords densely but naturally — read it aloud, it should make sense as a paragraph
- Cover synonyms: "test-driven development", "TDD", "test first", "test-first"
- Cover anti-patterns: "skip tests", "no time for tests", "I'll add tests later"
- Cover related tools: framework names, library names, protocol names
- Cover both novice queries ("how do I test") and expert queries ("outside-in TDD with London school mocking")

### 1.2 Your Role Section

The opening section after the frontmatter heading. This is the skill's identity.

```markdown
# Skill Name

You are [role description — one sentence elevator pitch]. You [philosophy statement — what you believe about your domain]. You are [positioning — where you fit in the system].

## Your Role

You [primary responsibility]. Your [N] areas of expertise:

1. **Area one**: brief description
2. **Area two**: brief description
...

You are **always learning** — whenever you give advice on [domain], use `WebSearch` to verify
you have the latest information.

### What You Own

- Bullet list of responsibilities this skill owns exclusively

### What You Do NOT Own

- Bullet list of things explicitly outside scope, with which skill owns them
```

**Key principles:**
- The opening paragraph is an elevator pitch — one reader should understand the skill in 30 seconds
- "What You Own" prevents scope creep — if it is not listed, the skill does not own it
- "What You Do NOT Own" prevents overlap — explicitly name which skill handles each excluded area
- The "always learning" statement with WebSearch is required for domain experts; optional for protocols

### 1.3 Golden Rule Section

Every skill has one overriding principle that trumps all other guidance.

```markdown
## Golden Rule

**[The rule in bold — one sentence, imperative.]**

[2-3 sentences explaining WHY this rule exists and what happens when it is violated.]

[Optional: Banned phrases or behaviors that violate the rule.]

[Optional: What to do instead of violating the rule.]
```

**Examples of good golden rules:**
- "NO production code without a failing test first. No exceptions." (tdd-protocol)
- "Evaluate every review finding on its merits." (review-protocol)
- "Understand before recommending." (backend-architect)
- "No skill without a failing eval first." (skill-evolution-protocol)

**The golden rule must be:**
- Falsifiable — you can check whether it was followed
- Memorable — one sentence, stated as an imperative
- Actionable — tells you what to DO (or not do), not just what to believe

### 1.4 How to Approach Section

This is the skill's conversation algorithm. It tells the agent exactly how to handle requests.

```markdown
## How to Approach

### The [Domain] Conversation Flow

\```
1. [First step — usually listen/understand]
2. [Second step — usually ask clarifying questions]
3. [Third step — classify or determine approach]
4. [Fourth step — present options/tradeoffs]
5. [Fifth step — let user decide or enforce discipline]
6. [Sixth step — dive deep with references]
7. [Seventh step — verify/cross-check]
8. [Eighth step — commit/document]
\```

This is not a suggestion. This is the process. Every time.

### Scale-Aware Guidance

| Stage | Team Size | Guidance |
|-------|-----------|----------|
| **Startup / MVP** | 1-5 devs | [lightweight approach] |
| **Growth** | 5-20 devs | [structured approach] |
| **Scale** | 20-50 devs | [formal approach] |
| **Enterprise** | 50+ devs | [institutional approach] |
```

**Key principles:**
- The conversation flow is numbered and explicit — the agent follows these steps in order
- 6-8 steps is the sweet spot (fewer = too vague, more = too rigid)
- Scale-aware guidance with 4 tiers covers most real-world situations
- Each tier should give concrete, actionable guidance — not vague platitudes

### 1.5 When to Use Each Sub-Skill Section

One subsection per reference file. This is the routing table that tells the agent when to read which reference.

```markdown
## When to Use Each Sub-Skill

### Reference Name (`references/filename.md`)
Read this reference when:
- [Scenario 1 — specific situation that needs this reference]
- [Scenario 2]
- [Scenario 3]
- ...
- [8-15 bullet points covering all activation scenarios]
```

**Key principles:**
- Start each bullet with a gerund or condition: "Setting up...", "When the user asks about...", "Deciding between..."
- 8-15 bullets per reference — enough to cover the reference's scope without being exhaustive
- Each bullet should be a distinct scenario, not rephrased duplicates
- Order bullets from most common to least common activation scenario

### 1.6 Core Knowledge Section

The skill's essential knowledge that does not belong in a reference file. This is the knowledge the agent needs for EVERY conversation, not just deep dives.

```markdown
## Core [Domain] Knowledge

### [Topic 1]

| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Row 1    | Data     | Data     |

### [Topic 2]

[Decision framework, principles, patterns]

### [Topic 3]

[Anti-patterns, common mistakes, things to avoid]
```

**Key principles:**
- Tables are preferred over prose for decision frameworks and comparisons
- Keep it to the essentials — detailed knowledge goes in references
- This section should be scannable — an agent should find the right answer in 5 seconds
- Include anti-patterns and "when NOT to" guidance, not just positive guidance

### 1.7 Response Format Section

How the skill formats its output in different modes.

```markdown
## Response Format

### During Conversation (Default)

[Numbered list of how to structure conversational responses]

### When Asked for a Deliverable

[Template for structured output when explicitly requested]
```

**Key principles:**
- Two modes: conversational (default) and deliverable (when explicitly asked)
- Conversational format is 3-5 numbered steps — tight and focused
- Deliverable format is a markdown template with placeholders
- The agent should never produce a deliverable unless explicitly asked

### 1.8 Process Awareness Section

How the skill integrates with the broader etyb process system.

```markdown
## Process Awareness

[1-2 paragraphs on plan integration, gate responsibilities, always-on status]

### Gate Integration

| Gate | This Skill's Role |
|------|-------------------|
| **Plan** | [Role or "Not active"] |
| **Design** | [Role or "Not active"] |
| **Implement** | [Role or "Not active"] |
| **Verify** | [Role or "Not active"] |
| **Ship** | [Role or "Not active"] |
```

### 1.9 Verification Protocol Section

Domain-specific checklist for confirming work is complete.

```markdown
## Verification Protocol

Before marking any [domain work] as complete, verify:

- [ ] [Specific check 1]
- [ ] [Specific check 2]
- [ ] [Specific check 3]
...
```

**Key principles:**
- Use checkbox format for scannable verification
- Each check should be binary (pass/fail) — no ambiguous "mostly done"
- Reference ETYB's verification protocol for the general framework
- Include both technical checks and process checks

### 1.10 Debugging Protocol Section

What to do when things go wrong in the skill's domain.

```markdown
## Debugging Protocol

[Systematic approach to diagnosing problems]

### Escalation Paths

- To `skill-name` — when [specific condition]
- To `skill-name` — when [specific condition]

After 3 failed attempts, escalate with full context.
```

### 1.11 What You Are NOT Section

Explicit boundary statements. This is the skill's fence.

```markdown
## What You Are NOT

- You are not **skill-name** — [what that skill does instead]. You [what you do instead].
- You are not **skill-name** — [boundary explanation].
- You do not [common misconception] — [correction].
- You do not [thing that seems like it should be in scope] — [where it actually lives].
```

**Key principles:**
- 6-10 boundary statements
- Each statement names a specific other skill where the excluded work lives
- Use the pattern: "You are not X — Y does that. You do Z instead."
- Include misconceptions that real users would have
- End with positive statements about what the skill DOES do (not just what it does not)

---

## 2. Reference File Anatomy

Reference files are the skill's deep knowledge. Each reference is a standalone mini-book.

### 2.1 Structure

```markdown
# Reference Title: Descriptive Subtitle

> **Always use `WebSearch` to verify current best practices** before [domain-specific action].

## Table of Contents

- [1. Section One](#1-section-one)
- [2. Section Two](#2-section-two)
...

---

## 1. Section One

### 1.1 Subsection

[Deep content: prose, tables, code blocks, checklists]

### 1.2 Subsection

[More deep content]

---

## 2. Section Two

...
```

### 2.2 Content Guidelines

| Element | When to Use | Guidelines |
|---------|-------------|------------|
| **Tables** | Comparisons, decision frameworks, feature matrices | 3-7 columns, clear headers, keep rows scannable |
| **Code blocks** | Examples, templates, configuration snippets | Real-world (not toy examples), with language tags, commented |
| **Checklists** | Verification, setup steps, audit criteria | Binary (pass/fail), ordered by importance |
| **Prose** | Explanations, context, reasoning | Short paragraphs (3-5 sentences), topic sentence first |
| **Headings** | Structure and navigation | H2 for major sections, H3 for subsections, H4 sparingly |

### 2.3 Quality Criteria

A good reference file:
- Has a WebSearch reminder header (for domain experts)
- Has a table of contents with anchor links
- Has 5-10 major sections (H2 level)
- Is 200-1000 lines total
- Is self-contained — does not require reading other files to be useful
- Uses tables for any comparison or decision framework
- Includes code examples that are realistic, not toy examples
- Can be read independently of the SKILL.md

### 2.4 Anti-Patterns in References

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| **Duplicate of SKILL.md** | Reference just restates what is in the skill | Reference should go DEEPER, not wider |
| **Wall of text** | No tables, no code, no structure | Add tables for decisions, code for examples |
| **Too thin** | Under 150 lines, could fit in SKILL.md | Merge into Core Knowledge section of SKILL.md |
| **Too thick** | Over 1000 lines, covers too much | Split into two focused references |
| **Dangling references** | Links to files that do not exist | Verify all cross-references at creation time |
| **Stale content** | Outdated tool versions, deprecated patterns | WebSearch reminder at top; update during improvement cycles |

---

## 3. Protocol vs Expert Skill Differences

### 3.1 Process Protocols

Process protocols enforce a discipline or workflow. They are behavioral — they tell the agent what to DO.

**Characteristics:**
- SKILL.md: ~350-450 lines
- References: 3-4 (focused on process steps and enforcement)
- May have `hooks/` directory for git hooks or automation
- May have `rules/` directory for enforcement rules
- Golden rule is a discipline statement: "Always do X" or "Never do Y"
- Core knowledge is about the PROCESS, not domain facts
- Response format is about guiding the user through steps
- Examples: `tdd-protocol`, `review-protocol`, `git-workflow-protocol`, `plan-execution-protocol`

**Template directory:**
```
protocol-name/
  SKILL.md           # ~350-450 lines
  references/
    step-one.md      # Deep dive on first process step
    step-two.md      # Deep dive on second process step
    enforcement.md   # Rationalization counters or compliance checks
  evals/
    evals.json       # 3-4 evals testing behavioral enforcement
  hooks/             # Optional: git hooks for automation
  rules/             # Optional: enforcement rules
```

### 3.2 Domain Experts

Domain experts provide deep knowledge in a specific technical area. They are knowledge-heavy — they tell the agent what to KNOW.

**Characteristics:**
- SKILL.md: ~300-500 lines
- References: 4-8 (each covering a knowledge area or sub-domain)
- Rarely have `hooks/` or `rules/` directories
- Golden rule is a decision principle: "Understand before recommending"
- Core knowledge is about domain facts, patterns, tradeoffs
- Response format is about presenting options and letting the user decide
- Scale-aware guidance has concrete recommendations per tier
- Examples: `backend-architect`, `security-engineer`, `database-architect`, `frontend-architect`

**Template directory:**
```
expert-name/
  SKILL.md           # ~300-500 lines
  references/
    area-one.md      # Deep knowledge area 1
    area-two.md      # Deep knowledge area 2
    area-three.md    # Deep knowledge area 3
    patterns.md      # Cross-cutting patterns
    anti-patterns.md # Common mistakes (optional)
  evals/
    evals.json       # 3-5 evals testing knowledge and guidance quality
```

### 3.3 Decision: Protocol or Expert?

| Signal | Likely Protocol | Likely Expert |
|--------|----------------|---------------|
| The skill enforces a practice | Yes | No |
| The skill has deep domain knowledge | No | Yes |
| Users might try to skip or rationalize around it | Yes | No |
| Users come with "how do I" questions | Sometimes | Yes |
| Users come with "should I" questions | No | Yes |
| The skill activates during a specific gate | Yes | Sometimes |
| The skill has rationalization counters | Yes | Rarely |
| The skill presents tradeoffs and options | Rarely | Yes |
| The skill says "no exceptions" | Yes | No |

---

## 4. Naming Conventions

### 4.1 Directory and Skill Names

| Convention | Rule | Example |
|-----------|------|---------|
| Case | Lowercase only | `backend-architect`, not `Backend-Architect` |
| Separator | Hyphens | `tdd-protocol`, not `tdd_protocol` |
| Protocol suffix | `-protocol` | `review-protocol`, `git-workflow-protocol` |
| Architect suffix | `-architect` | `backend-architect`, `system-architect` |
| Engineer suffix | `-engineer` | `security-engineer`, `devops-engineer` |
| Analyst suffix | `-analyst` | `research-analyst` |
| Writer suffix | `-writer` | `technical-writer` |
| Planner suffix | `-planner` | `project-planner` |
| Special | `etyb` has no suffix | `etyb` |
| Abbreviations | Only universally understood | `tdd`, `sre`, `qa`, `ai-ml` |
| Length | 2-4 words | `e-commerce-architect`, not `enterprise-e-commerce-and-marketplace-architect` |

### 4.2 Reference File Names

| Convention | Rule | Example |
|-----------|------|---------|
| Case | Lowercase only | `api-developer.md` |
| Separator | Hyphens | `red-green-refactor.md` |
| Extension | `.md` always | Not `.txt`, not `.markdown` |
| Descriptive | Name describes content | `rationalization-counters.md`, not `ref1.md` |
| Consistent | Match the sub-skill heading | If heading says "Auth Specialist", file is `auth-specialist.md` |

### 4.3 Eval Names

| Convention | Rule | Example |
|-----------|------|---------|
| Case | Lowercase kebab-case | `implement-without-test` |
| Descriptive | Describes what is being tested | `rationalization-resistance`, not `test-2` |
| Verb-first | Start with action or scenario | `verify-red-enforcement`, `dispatch-review-request` |
| No IDs in name | The `id` field is the numeric identifier | Name is for human readability |

---

## 5. Directory Structure Template

### 5.1 Minimum Viable Skill

```
skill-name/
  SKILL.md               # Required — the skill definition
  references/             # Required — at least 1 reference
    primary-reference.md  # At least one deep-dive reference
  evals/                  # Required — at least 1 eval
    evals.json            # Eval definitions
```

### 5.2 Full Protocol Skill

```
protocol-name/
  SKILL.md               # ~350-450 lines
  references/
    step-one.md           # First process step deep dive
    step-two.md           # Second process step deep dive
    step-three.md         # Third process step deep dive
    enforcement.md        # Rationalization counters
  evals/
    evals.json            # 3-4 evals
  hooks/                  # Optional: automation hooks
    pre-commit            # Git pre-commit hook
  rules/                  # Optional: enforcement rules
    rule-one.md           # Specific rule definition
```

### 5.3 Full Expert Skill

```
expert-name/
  SKILL.md               # ~300-500 lines
  references/
    area-one.md           # Knowledge area 1
    area-two.md           # Knowledge area 2
    area-three.md         # Knowledge area 3
    area-four.md          # Knowledge area 4
    patterns.md           # Cross-cutting patterns
    anti-patterns.md      # Common mistakes
  evals/
    evals.json            # 3-5 evals
```

---

## 6. Trigger Keyword Design

The description field in YAML frontmatter is the primary matching surface for skill activation. Poor keyword coverage means the skill will not be found when it should be.

### 6.1 Keyword Categories

Cover ALL of these categories in the description:

| Category | What to Include | Example (for tdd-protocol) |
|----------|----------------|---------------------------|
| **Primary terms** | The skill's exact domain name | "TDD", "test-driven development" |
| **Synonyms** | Different ways to say the same thing | "test first", "test-first", "test-driven" |
| **Abbreviations** | Common short forms | "TDD", "RGR" (red-green-refactor) |
| **Tool names** | Specific tools in the domain | "Jest", "pytest", "Go test" |
| **Pattern names** | Named patterns | "red-green-refactor", "spike and delete" |
| **Anti-patterns** | Things users say when they need this skill | "skip tests", "no time for tests" |
| **Scenarios** | Situations that need this skill | "writing production code", "implementation phase" |
| **Business language** | Non-technical ways to describe the need | "code quality", "fewer bugs", "confidence" |
| **Related skills** | Cross-references that might route here | "qa-engineer", "test strategy" |
| **Error signals** | Things users say when the skill failed | "tests are flaky", "tests are slow" |

### 6.2 Keyword Density Target

Aim for 100+ unique trigger keywords in the description. Here is how to count:

```
"TDD" = 1 keyword
"test-driven development" = 3 keywords (test, driven, development)
"red-green-refactor" = 3 keywords (red, green, refactor)
"I'll add tests later" = 4 keywords (add, tests, later + phrase match)
```

Compound phrases count as both the phrase AND individual words. A 300-word description naturally hits 100+ keywords if written well.

### 6.3 Keyword Quality Checklist

- [ ] Would a beginner's query match? ("how do I test my code")
- [ ] Would an expert's query match? ("outside-in TDD with London school mocking")
- [ ] Would a frustrated user's query match? ("tests are too slow and I want to skip them")
- [ ] Would a manager's query match? ("improve code quality and reduce bugs")
- [ ] Would an anti-pattern query match? ("no time for tests, deadline is tomorrow")
- [ ] Are synonyms covered? (test/testing/tests, build/construct/create)
- [ ] Are tool names included? (Jest, pytest, JUnit, Go test)
- [ ] Are related concepts included? (coverage, assertions, mocking, fixtures)

---

## 7. Line Count Targets and Constraints

### 7.1 SKILL.md

| Type | Target | Hard Limit | If Over Limit |
|------|--------|-----------|---------------|
| Protocol | 350-450 lines | 500 lines | Move knowledge to references |
| Expert | 300-500 lines | 500 lines | Move knowledge to references |

**What goes in SKILL.md vs references:**
- SKILL.md: Identity, golden rule, conversation flow, scale-aware table, sub-skill routing, core decision frameworks, response format, process awareness, verification checklist, boundaries
- References: Deep knowledge, detailed examples, code samples, comprehensive tables, tool-specific guidance

### 7.2 Reference Files

| Metric | Target | Hard Limit | If Over Limit |
|--------|--------|-----------|---------------|
| Lines | 200-800 | 1000 lines | Split into two focused references |
| Min | 150 lines | — | If under 150, merge into SKILL.md or another reference |

### 7.3 Eval Files

| Metric | Target |
|--------|--------|
| Evals per protocol | 3-4 |
| Evals per expert | 3-5 |
| Assertions per eval | 4-6 |

---

## 8. Skill Creation Checklist

Use this checklist when creating a new skill from scratch:

### Pre-Creation

- [ ] Gap identified — what is the system missing?
- [ ] Failing eval written — an eval that proves the gap exists
- [ ] No overlap — checked existing skill triggers for conflicts
- [ ] Type decided — protocol or expert?
- [ ] Name chosen — follows naming conventions

### SKILL.md

- [ ] YAML frontmatter with name and description (200-400 words, 100+ keywords)
- [ ] Your Role section with elevator pitch, what you own, what you do NOT own
- [ ] Golden Rule section — one falsifiable, memorable, actionable rule
- [ ] How to Approach with conversation flow (6-8 steps) and scale-aware table (4 tiers)
- [ ] When to Use Each Sub-Skill — one section per reference, 8-15 bullets each
- [ ] Core Knowledge — essential decision frameworks and tables
- [ ] Response Format — conversational (default) and deliverable modes
- [ ] Process Awareness — gate integration table
- [ ] Verification Protocol — checkbox checklist
- [ ] Debugging Protocol — escalation paths
- [ ] What You Are NOT — 6-10 boundary statements

### References

- [ ] At least 3 references (protocols) or 4 references (experts)
- [ ] Each reference has WebSearch reminder, ToC, 5-10 sections
- [ ] Each reference is 200-1000 lines
- [ ] Each reference is self-contained
- [ ] No dangling cross-references

### Evals

- [ ] 3-4 evals (protocols) or 3-5 evals (experts)
- [ ] Each eval has id, name, prompt, expected_output, assertions, files
- [ ] Mix of behavioral_check, content_check, and negative_check assertions
- [ ] Evals test different scenarios (not variations of the same test)
- [ ] At least one eval tests an edge case or boundary condition

### Post-Creation

- [ ] All evals pass
- [ ] SKILL.md under 500 lines
- [ ] No trigger overlap with existing skills
- [ ] Directory structure correct

---

## 9. Common Mistakes and How to Avoid Them

| Mistake | Why It Happens | How to Fix |
|---------|----------------|------------|
| **No evals** | "I'll add evals later" | Write evals FIRST (golden rule) |
| **Vague golden rule** | Trying to be inclusive | Make it specific and falsifiable |
| **Copy-paste references** | Rushing to fill directory | Each reference must have unique, deep content |
| **Trigger keyword gaps** | Only including technical terms | Add business language, anti-patterns, error signals |
| **Scope creep** | Skill tries to cover too much | Split into two skills or trim to core |
| **Over-engineering** | Adding sections "just in case" | Follow the template exactly, no extras |
| **Weak boundaries** | "What You Are NOT" is vague | Name specific other skills for each excluded area |
| **Thin references** | Under 150 lines | Either go deeper or merge into SKILL.md |
| **Missing scale-aware** | One-size-fits-all guidance | Add 4-tier table (startup, growth, scale, enterprise) |
| **Stale WebSearch reminder** | Forgot the header | Add to every reference for domain experts |
