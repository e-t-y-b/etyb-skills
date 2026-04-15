# Institutional Memory: Cross-Session Learning and Knowledge Accumulation

> **The skill system is a living organism.** It grows by absorbing patterns that repeat across projects and sessions. But it must be selective — absorbing everything creates bloat, absorbing nothing creates stagnation.

## Table of Contents

- [1. Memory vs Skills](#1-memory-vs-skills)
- [2. When a Skill Should Absorb Memory](#2-when-a-skill-should-absorb-memory)
- [3. Cross-Session Learning Patterns](#3-cross-session-learning-patterns)
- [4. Feedback Loops](#4-feedback-loops)
- [5. Knowledge Accumulation](#5-knowledge-accumulation)
- [6. The Three-Strike Rule](#6-the-three-strike-rule)
- [7. Anti-Patterns](#7-anti-patterns)
- [8. Memory Hygiene](#8-memory-hygiene)

---

## 1. Memory vs Skills

### 1.1 The Fundamental Distinction

| Dimension | Memory | Skills |
|-----------|--------|--------|
| **Scope** | Per-project, per-user | Universal, all projects, all users |
| **Lifespan** | Ephemeral — lives in session/project context | Permanent — lives in the skill directory |
| **Content** | Preferences, past decisions, ongoing work | How to do things, patterns, frameworks, disciplines |
| **Trigger** | Specific context (this project, this user) | General context (anyone asking about this topic) |
| **Example** | "This project uses PostgreSQL 16 with Prisma ORM" | "How to design a database schema for multi-tenancy" |
| **Storage** | `.claude/` project memory, CLAUDE.md | `etyb-skills/skill-name/` directory |

### 1.2 The Decision Rule

**If it applies to one project, it is memory. If it applies to all projects, it is a skill.**

More specifically:

| Signal | Memory | Skill |
|--------|--------|-------|
| "This project uses X" | Yes | No |
| "When building Y, always consider Z" | No | Yes |
| "The user prefers tabs over spaces" | Yes | No |
| "TypeScript projects should use strict mode" | No | Yes |
| "We decided to use Redis for caching in Sprint 3" | Yes | No |
| "When to use Redis vs Memcached for caching" | No | Yes |
| "John prefers detailed commit messages" | Yes | No |
| "How to write good commit messages" | No | Yes |

### 1.3 Gray Areas

Some knowledge sits at the boundary. These require judgment:

| Example | Analysis | Decision |
|---------|----------|----------|
| "Always use Zod for validation in TypeScript" | Opinionated but broadly applicable | Could be skill content in backend-architect's TypeScript reference |
| "This team does not use ORMs" | Project-specific decision | Memory. Unless it becomes "when to skip ORMs" guidance in a skill |
| "Always run security scans before deploy" | Universal best practice | Should already be in security-engineer or devops-engineer |
| "We use trunk-based development" | Team-specific workflow choice | Memory. The skill covers multiple branching strategies |

**When in doubt:** Keep it in memory. Wait for the three-strike pattern before promoting to a skill.

---

## 2. When a Skill Should Absorb Memory

### 2.1 Promotion Criteria

Memory should be promoted to skill content when ALL of these are true:

| Criterion | Test | Example |
|-----------|------|---------|
| **Repeated** | Same guidance given 3+ times across different projects | "You should use database connection pooling" said in 3 different project contexts |
| **Universal** | Applies regardless of project specifics | Not tied to a specific tech stack, team, or timeline |
| **Actionable** | Can be turned into specific guidance with examples | Not just "be careful with X" but "here's how to handle X" |
| **Verifiable** | Can write an eval that tests the knowledge | If you cannot write an eval, the knowledge is too vague |
| **Not already covered** | No existing skill addresses this | Check all related skills before creating new content |

### 2.2 Promotion Process

```
1. Identify the pattern — same guidance 3+ times across sessions
2. Check existing skills — is this already covered somewhere?
3. If not covered: follow the improvement loop
   a. Write a failing eval that tests for this knowledge
   b. Add the knowledge to the appropriate skill's reference
   c. Verify the eval passes
   d. Verify no regressions
4. If partially covered: strengthen the existing content
5. If covered but hard to find: improve trigger keywords
```

### 2.3 Where to Put Promoted Knowledge

| Knowledge Type | Destination |
|---------------|-------------|
| New domain knowledge | Reference file in the relevant domain expert skill |
| New process pattern | Reference file in the relevant protocol skill |
| New discipline guidance | Rationalization table in the relevant protocol |
| Cross-cutting pattern | Consider: does it belong in system-architect or a new skill? |
| Tool-specific knowledge | Reference file for the tool's domain (e.g., Go specifics go in backend-architect's Go reference) |

---

## 3. Cross-Session Learning Patterns

### 3.1 Architectural Decisions

When a user makes an architectural choice, the decision context is more valuable than the decision itself.

| What to Capture | What NOT to Capture | Why |
|----------------|--------------------|----|
| "We chose event sourcing because we need audit trails and replay capability" | "We use event sourcing" | The reasoning is reusable; the decision is project-specific |
| "We rejected microservices at this stage because we have 4 engineers" | "We use a monolith" | The reasoning helps future teams at similar scale |
| "We chose PostgreSQL over MongoDB because our data is highly relational" | "We use PostgreSQL" | The decision framework helps others choose |

**Memory captures:** "This project uses event sourcing with PostgreSQL"
**Skills capture:** "When to choose event sourcing: audit trail requirements, replay capability, temporal queries"

### 3.2 User Preferences

Preferences are almost always memory, not skills. But patterns of preferences can inform skill defaults.

| Preference | Memory or Skill? | Reasoning |
|-----------|-----------------|-----------|
| "I prefer functional over OOP" | Memory | Personal style choice |
| "Always use TypeScript strict mode" | Borderline | If 80%+ of users want this, consider making it a skill default |
| "Show me code examples, not just descriptions" | Memory | Communication preference |
| "I want tradeoff tables for every decision" | Memory | But skills already use tables; this validates the pattern |

### 3.3 Project-Specific Constraints

Constraints are always memory. But the TYPES of constraints can inform skill guidance.

| Constraint | What Memory Captures | What Skills Capture |
|-----------|--------------------|--------------------|
| "We must be HIPAA compliant" | This project has HIPAA requirements | How to design systems for HIPAA compliance (security-engineer, healthcare-architect) |
| "We can only use AWS services" | This project is AWS-only | AWS service patterns and tradeoffs (devops-engineer, backend-architect) |
| "Our API must support 10,000 requests/second" | This project's performance requirement | How to design high-throughput APIs (backend-architect) |
| "We have a 3-month deadline" | This project's timeline | How team size and timeline affect architecture decisions (system-architect) |

### 3.4 Error Patterns

When users hit the same error repeatedly, that is a strong signal:

| Error Pattern | If Seen Once | If Seen 3+ Times |
|--------------|-------------|-------------------|
| "CORS error with my API" | Memory: help this user fix CORS | Skill: add CORS configuration section to backend-architect |
| "Docker build takes 20 minutes" | Memory: optimize this Dockerfile | Skill: add Docker optimization patterns to devops-engineer |
| "Tests are flaky on CI but pass locally" | Memory: debug this specific flakiness | Skill: add CI flakiness debugging to qa-engineer |

---

## 4. Feedback Loops

### 4.1 Processing User Feedback

When a user corrects the skill or provides feedback:

```
1. Is the feedback correct?
   - If yes: proceed
   - If no: explain why (with evidence)
   - If unclear: ask for clarification

2. Is it a skill gap or a one-off?
   - Skill gap: affects all users/projects
   - One-off: specific to this user/project/context

3. If skill gap:
   a. Write a failing eval that captures the gap
   b. Improve the skill (improvement loop)
   
4. If one-off:
   a. Note in project memory
   b. Do NOT change the skill
   c. Mark it for pattern tracking

5. If ambiguous:
   a. Note it with context
   b. Wait for pattern (3+ occurrences)
   c. Re-evaluate after the third occurrence
```

### 4.2 The Feedback Classification Matrix

| Feedback Type | Example | Action |
|--------------|---------|--------|
| **Correction** | "That's wrong — bcrypt salt rounds should be 12, not 10" | Verify. If correct, check if it is in the skill. If not, improvement loop. |
| **Addition** | "You should also mention rate limiting for public APIs" | Check if this is already covered. If not, evaluate for promotion. |
| **Removal** | "Stop recommending X — it is deprecated" | WebSearch to verify. If confirmed, update the skill immediately. |
| **Style** | "I prefer shorter responses" | Memory. Style is per-user, not universal. |
| **Scope** | "You should also cover Y" | Evaluate: does Y belong in this skill? If not, which skill? |

### 4.3 Feedback That Should NOT Change Skills

| Feedback | Why Not | What to Do Instead |
|----------|---------|-------------------|
| "I don't like this approach" | Preference, not correctness | Note in memory |
| "My team uses X instead" | Team-specific, not universal | Note in memory |
| "This is too detailed" | Communication preference | Note in memory; skill keeps depth |
| "Can you be more opinionated?" | Some users want options, others want answers | Memory; skill presents tradeoffs |
| "Skip the questions, just tell me" | Some users want discussion, others want answers | Memory; skill follows its conversation flow |

---

## 5. Knowledge Accumulation

### 5.1 How Skills Grow

Skills accumulate knowledge through two channels:

| Channel | Mechanism | Rate |
|---------|-----------|------|
| **Improvement loop** | Failing eval triggers content addition | Reactive — responds to gaps |
| **Proactive review** | Periodic WebSearch for new patterns/tools | Proactive — catches drift before it hurts |

### 5.2 Reference File Growth Guidelines

| Reference Size | Status | Action |
|---------------|--------|--------|
| < 150 lines | Too thin | Consider merging into SKILL.md or another reference |
| 150-500 lines | Healthy | Normal growth target |
| 500-800 lines | Getting large | Watch for bloat; consider splitting |
| 800-1000 lines | At limit | Split into two focused references |
| > 1000 lines | Over limit | Must split — too much for one reference |

### 5.3 Quality Over Quantity

**One excellent reference > three mediocre references.**

Quality indicators:
- Tables for every comparison or decision framework
- Code examples that are realistic (not toy examples)
- Checklists for every process or verification step
- Specific numbers and thresholds (not "consider" or "think about")
- Anti-patterns alongside patterns (what NOT to do)

Quantity indicators (bad):
- Long prose paragraphs with no structure
- Generic advice ("it depends", "consider your requirements")
- Redundant content across sections
- Examples that do not illustrate the point
- Lists of tools without guidance on when to use each

### 5.4 Knowledge Pruning

Growth must be balanced with pruning:

| Prune When | What to Remove | How to Verify |
|-----------|---------------|---------------|
| Tool is deprecated | All references to the tool | WebSearch to confirm deprecation |
| Pattern is superseded | Old pattern, keep new one | Verify new pattern covers the same cases |
| Content is redundant | Duplicated guidance | Check that the remaining copy is complete |
| Guidance is wrong | Incorrect information | WebSearch to verify; update evals |
| Section is bloat | Content no one activates | Check eval coverage — if no eval tests it, it may be unnecessary |

---

## 6. The Three-Strike Rule

The three-strike rule prevents premature skill changes based on insufficient evidence.

### 6.1 How It Works

```
Strike 1: First occurrence of a pattern
  - Note it in the session context
  - Do NOT change any skill
  - Tag: "potential pattern — 1/3"

Strike 2: Second occurrence (different project/context)
  - Note it again
  - Still do NOT change any skill
  - Tag: "emerging pattern — 2/3"

Strike 3: Third occurrence (different project/context again)
  - This is now a confirmed pattern
  - Write a failing eval
  - Follow the improvement loop
  - The pattern becomes skill knowledge
```

### 6.2 Exceptions to Three-Strike

| Situation | Override Rule |
|-----------|-------------|
| **Factual error** | Fix immediately. Wrong information harms users. |
| **Security issue** | Fix immediately. Security gaps are critical. |
| **Deprecated tool** | Fix immediately. Recommending deprecated tools is harmful. |
| **User explicitly reports a bug** | Investigate immediately. May still apply three-strike if it is a preference, not a bug. |

### 6.3 Strike Tracking

When tracking strikes, record:
- The specific guidance or pattern
- The project context where it occurred
- Whether the user corrected the skill or the skill was silent
- The date and approximate session

This tracking is informal — it lives in the practitioner's awareness across sessions. If a formal tracking system exists (e.g., a gap log), use it.

---

## 7. Anti-Patterns

### 7.1 Information Hoarding

**Symptom:** Saving every piece of feedback, every user preference, every one-off correction into skill content.

**Problem:** Skills become bloated with project-specific knowledge. Signal drowns in noise. Reference files exceed line limits.

**Fix:** Apply the three-strike rule ruthlessly. Memory captures the one-off. Skills capture the universal.

### 7.2 Never Updating (Stale Skills)

**Symptom:** Skills have not changed in months. No new evals added. No references updated. But users keep reporting issues.

**Problem:** The ecosystem evolves. Tools change. Best practices shift. A skill that was correct 6 months ago may be wrong today.

**Fix:** Periodic review cycle. For each skill:
- WebSearch key tools and frameworks for updates
- Check if evals still have realistic prompts
- Look for gap reports that were never addressed
- Ask: "If I wrote this skill today, what would be different?"

### 7.3 Over-Fitting to One User or Project

**Symptom:** Skill advice is perfect for one type of project but wrong for others. Examples all use one tech stack. Guidance assumes one team size.

**Problem:** Skill has absorbed too much project-specific memory. It has lost universality.

**Fix:** Check scale-aware guidance: does each tier have appropriate recommendations? Check examples: do they cover multiple stacks/contexts? Check evals: do they test different scenarios?

### 7.4 Under-Fitting by Being Too Generic

**Symptom:** Skill gives advice like "it depends" and "consider your requirements" without specific guidance. Users leave without actionable next steps.

**Problem:** Skill is too cautious. It avoids specificity to avoid being wrong.

**Fix:** Add specific decision frameworks with concrete thresholds. "If team < 10 engineers, start with monolith." "If p99 latency must be < 5ms, consider Rust or Go." Replace "consider" with "do this when X, do that when Y."

### 7.5 Cargo Culting Structure

**Symptom:** New skills mechanically follow the template but the content is empty or superficial. All required sections exist but say nothing meaningful.

**Problem:** Form without substance. The template is a tool, not a goal.

**Fix:** Every section must earn its place. If the verification protocol has nothing to verify, the skill does not need one (or the skill is too thin to exist). If scale-aware guidance is the same across all tiers, it is not actually scale-aware.

### 7.6 Improvement Without Measurement

**Symptom:** Skills are constantly edited but there is no way to know if they are getting better. Changes are made "because it felt right."

**Problem:** Without evals, improvement is guessing. You might be making the skill worse.

**Fix:** The golden rule. No change without a failing eval first. The eval is the measurement.

---

## 8. Memory Hygiene

### 8.1 Regular Maintenance Practices

| Practice | Frequency | Action |
|----------|-----------|--------|
| Review project memory | Each session start | Check if any memory items are now universal patterns |
| Check for three-strikes | When adding to memory | Has this pattern reached 3 occurrences? |
| Prune stale memory | Monthly | Remove project-specific items for completed projects |
| Cross-reference with skills | When updating memory | Does this memory item overlap with existing skill content? |

### 8.2 Memory-to-Skill Promotion Checklist

Before promoting memory to skill content:

- [ ] Pattern confirmed (3+ occurrences across different contexts)
- [ ] Not project-specific (applies universally)
- [ ] Not user-preference (applies regardless of communication style)
- [ ] Actionable (can be turned into specific guidance with examples)
- [ ] Verifiable (can write an eval that tests for it)
- [ ] Not already covered (checked all related skills)
- [ ] Destination identified (which skill and which reference file)
- [ ] Failing eval written
- [ ] Improvement loop completed
