# The Improvement Loop: TDD for Documentation

> **Every bad answer is a gift.** It tells you exactly where the skill system is weak. The improvement loop turns that signal into a better skill, verified by an eval that will catch the same gap forever.

## Table of Contents

- [1. Step 1: Identify the Gap](#1-step-1-identify-the-gap)
- [2. Step 2: Write the Failing Eval](#2-step-2-write-the-failing-eval)
- [3. Step 3: Update the Skill](#3-step-3-update-the-skill)
- [4. Step 4: Verify](#4-step-4-verify)
- [5. Step 5: Document](#5-step-5-document)
- [6. Rationalization Tables for Discipline Skills](#6-rationalization-tables-for-discipline-skills)
- [7. When to Split a Skill](#7-when-to-split-a-skill)
- [8. When to Merge Skills](#8-when-to-merge-skills)
- [9. Deprecation Protocol](#9-deprecation-protocol)
- [10. Improvement Loop Anti-Patterns](#10-improvement-loop-anti-patterns)

---

## 1. Step 1: Identify the Gap

The improvement loop starts with a signal that something is wrong or missing.

### 1.1 Gap Sources

| Source | Signal | Example |
|--------|--------|---------|
| **Bad answer** | User gets incorrect or unhelpful guidance | backend-architect recommends microservices for a 3-person team |
| **Missing edge case** | Skill does not handle a specific situation | tdd-protocol has no guidance for legacy code with no tests |
| **User feedback** | User corrects the skill or says "that's wrong" | "No, we should not use JWT for session management here" |
| **Repeated manual guidance** | Same guidance given 3+ times across sessions | Keep explaining how to set up CI caching — no skill covers it |
| **Skill conflict** | Two skills give contradictory advice | security-engineer says "use bcrypt" while backend-architect says "use argon2id" |
| **Scope creep** | Skill is answering questions outside its domain | database-architect giving frontend state management advice |
| **New technology** | A new tool/framework changes best practices | A major framework release changes recommended patterns |

### 1.2 Gap Classification

Once identified, classify the gap to determine the response:

| Classification | Description | Response |
|---------------|-------------|----------|
| **Missing knowledge** | Skill lacks information about a topic | Add content to reference file |
| **Wrong knowledge** | Skill has incorrect information | Fix the reference file |
| **Missing behavior** | Skill does not enforce a discipline it should | Update SKILL.md conversation flow or golden rule |
| **Wrong behavior** | Skill behaves incorrectly (e.g., does not push back) | Update SKILL.md approach or golden rule |
| **Missing scope** | No skill covers this area at all | Create a new skill |
| **Overlapping scope** | Multiple skills cover the same area | Merge or clarify boundaries |
| **Outdated content** | Tool versions, deprecated patterns | Update references with WebSearch verification |

### 1.3 Gap Documentation

Before proceeding, document the gap:

```markdown
## Gap Report

**Skill affected:** [skill-name]
**Gap type:** [missing knowledge / wrong knowledge / missing behavior / wrong behavior / missing scope / overlapping scope / outdated]
**Signal:** [What triggered the identification — user feedback, bad answer, repeated guidance]
**Description:** [What the system is missing or getting wrong]
**Impact:** [How this affects users — bad advice, no advice, confusing advice]
**Proposed fix:** [High-level description of what needs to change]
```

---

## 2. Step 2: Write the Failing Eval

**This step is mandatory.** The golden rule: no skill change without a failing eval first.

### 2.1 Creating the Eval

Based on the gap, write an eval that:
1. Has a prompt that triggers the exact situation where the gap manifests
2. Has assertions that describe the correct behavior/content
3. FAILS with the current skill (because the gap exists)

### 2.2 Verifying the Eval Fails

Run the eval against the current skill. Three possible outcomes:

| Outcome | Meaning | Action |
|---------|---------|--------|
| **Eval fails** | Gap is real, eval captures it | Proceed to Step 3 |
| **Eval passes** | Gap is not real, or eval does not test it | Re-examine the gap; rewrite the eval |
| **Eval is ambiguous** | Some assertions pass, some are unclear | Tighten the assertions until they are clearly falsifiable |

### 2.3 Common Eval-Writing Mistakes at This Step

| Mistake | Problem | Fix |
|---------|---------|-----|
| Eval tests the wrong thing | Eval passes even though gap is real | Rewrite prompt to trigger the exact gap scenario |
| Eval too broad | Tests multiple gaps at once | Focus on one gap per eval |
| Assertions too vague | Cannot tell if they pass or fail | Make each assertion specific and falsifiable |
| Prompt too artificial | Does not represent real usage | Rewrite as a realistic user message |

---

## 3. Step 3: Update the Skill

Make the **minimal change** to pass the eval. Do not over-fix.

### 3.1 Types of Changes

| Gap Type | Typical Fix | Where to Change |
|----------|------------|-----------------|
| Missing knowledge | Add a section, table, or example | Reference file |
| Wrong knowledge | Correct the information | Reference file |
| Missing behavior | Add to conversation flow or golden rule | SKILL.md |
| Wrong behavior | Update approach section or add boundary | SKILL.md |
| Missing scope | Create new skill (full lifecycle) | New directory |
| Overlapping scope | Clarify boundaries, update "What You Are NOT" | Both skills' SKILL.md |
| Outdated content | Update with WebSearch-verified current info | Reference file |

### 3.2 The Minimal Change Principle

**Just pass the eval. Nothing more.**

| Temptation | Why to Resist | What to Do Instead |
|-----------|---------------|-------------------|
| "While I'm here, I'll also fix..." | Unrelated changes may introduce regressions | File a separate gap report for the other issue |
| "This section could be better overall" | Improvement without a failing eval is guessing | Write an eval for the improvement first |
| "Let me restructure the whole reference" | Major restructures break existing evals | Restructure only if multiple evals require it |
| "I'll add extra examples just in case" | Bloat without verification | Add examples only if an eval requires them |

### 3.3 Change Scope Guidelines

| Change Size | Acceptable Scope | Too Much |
|------------|-----------------|----------|
| **Small** | Add 1 paragraph, update 1 table row, fix 1 example | Rewrite a section |
| **Medium** | Add 1 section (20-50 lines), update multiple related items | Add a new reference file |
| **Large** | Add a reference file, restructure a section | Rewrite the entire SKILL.md |
| **Meta** | Change skill structure, add required section | Change all skills at once |

---

## 4. Step 4: Verify

Verification is two-part: the new eval passes AND no regressions.

### 4.1 Verification Checklist

```
Step 4a: New eval passes
  [ ] Run the new eval against the updated skill
  [ ] All assertions pass
  [ ] If any fail: go back to Step 3

Step 4b: No regressions
  [ ] Run ALL existing evals for this skill
  [ ] All existing assertions pass
  [ ] If any fail: adjust the change to pass both new and existing evals

Step 4c: Constraints respected
  [ ] SKILL.md is under 500 lines
  [ ] Reference files are under 1000 lines each
  [ ] No new trigger keyword overlap with other skills
  [ ] All sections still present in SKILL.md
```

### 4.2 Handling Regression Conflicts

When a change makes the new eval pass but breaks an existing eval:

| Situation | Action |
|-----------|--------|
| New and old evals test the same scenario differently | Reconcile: update the old eval if it is outdated, or find a change that satisfies both |
| New behavior contradicts old behavior | This is a design decision. Document the tradeoff. Update the old eval to reflect the new expected behavior. |
| Change is too broad and affects unrelated evals | Narrow the change. Make it more targeted. |

---

## 5. Step 5: Document

After the change passes all evals:

### 5.1 Commit Message Format

```
[skill-name] Fix: [short description of what was fixed]

Gap: [description of the gap that was identified]
Eval: [name of the new eval that was added]
Change: [what was modified — file and section]
Verified: new eval passes, all existing evals pass
```

### 5.2 Improvement Log Entry

For significant changes, add an entry to the improvement log:

```markdown
### [Date] — [skill-name]: [Short description]

**Gap:** [What was wrong]
**Signal:** [How it was discovered]
**Eval added:** [eval name]
**Change:** [What was modified]
**Impact:** [How this improves the skill]
```

---

## 6. Rationalization Tables for Discipline Skills

### 6.1 What They Are

Rationalization tables are structured collections of excuses that users (or agents) make to skip a discipline, paired with evidence-based counters. They are the skill's immune system against erosion.

### 6.2 When to Build Them

Build a rationalization table for any skill that:
- Enforces a discipline (TDD, code review, verification, security practices)
- Has a golden rule that users might try to circumvent
- Deals with time pressure or deadline-driven decisions
- Requires saying "no" to expedient but harmful shortcuts

### 6.3 Rationalization Table Structure

```markdown
## [N]. "[The Excuse]"

**The Excuse**: "[Extended version of what the user says]"

**Why It's Wrong**

[2-3 paragraphs explaining why this rationalization is incorrect, with specific evidence]

**Evidence**

[Research citations, real-world examples, data points that disprove the excuse]

**What To Do Instead**

[Pragmatic alternative that maintains the discipline while acknowledging the constraint]

[Optional: code example showing the correct approach]
```

### 6.4 How to Populate

| Source | What to Collect | Example |
|--------|----------------|---------|
| User sessions | Direct quotes when users resist | "We don't have time for tests" |
| Agent behavior | When the agent itself rationalizes skipping | "This is too simple to need a test" |
| Industry literature | Common excuses documented in books/articles | "We'll refactor later" |
| Post-mortems | Root causes that trace back to skipped discipline | "We skipped the security review because of the deadline" |

### 6.5 How to Maintain

- Add new rationalizations as they are encountered (Step 1 of the improvement loop)
- Update evidence when new research or examples become available
- Remove rationalizations that are no longer relevant (tool/practice deprecated)
- Cross-reference between skills: if tdd-protocol gets a new rationalization about testing, check if qa-engineer needs a corresponding update

### 6.6 Existing Rationalization Tables

| Skill | Reference File | Rationalizations Covered |
|-------|---------------|-------------------------|
| `tdd-protocol` | `references/rationalization-counters.md` | "Too simple to test", "I'll add tests after", "Time pressure", and more |
| `review-protocol` | `references/feedback-evaluation.md` | Performative agreement, skip review under deadline |

---

## 7. When to Split a Skill

### 7.1 Signals That a Skill Needs Splitting

| Signal | Threshold | Example |
|--------|-----------|---------|
| SKILL.md approaching line limit | >450 lines with mixed concerns | A skill covering both frontend and backend patterns |
| Multiple distinct domains | >2 separate knowledge areas | A skill covering both database design AND API design |
| Sub-skills could stand alone | A reference has its own golden rule | Auth reference in backend-architect is deep enough to be its own skill |
| Scale-aware guidance diverges | Different tiers need fundamentally different skills | Security for startups vs security for enterprises |
| Evals test unrelated things | Eval set covers disconnected scenarios | One eval tests API design, another tests database optimization |

### 7.2 How to Split

1. **Identify the split boundary** — What are the two (or more) distinct domains?
2. **Write evals for each new skill** — Before splitting, define what each new skill should do
3. **Create new directories** — One per new skill, following naming conventions
4. **Distribute content** — Move sections to the appropriate new skill
5. **Update cross-references** — Both new skills should reference each other in "What You Are NOT"
6. **Update the old skill** — Either deprecate it or reduce it to the retained scope
7. **Run all evals** — New skills' evals pass, old skill's evals still pass (or are redistributed)

### 7.3 Split Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Splitting too early | Skill is small and coherent; splitting creates two thin skills | Wait until the skill is actually straining its boundaries |
| Splitting without evals | New skills have no way to verify they work | Write evals for both new skills before splitting |
| Splitting without boundary updates | Old skill still triggers for split-out content | Update triggers and "What You Are NOT" for all affected skills |
| Uneven split | One new skill gets 90% of the content | Reconsider the boundary; maybe only one part needs extraction |

---

## 8. When to Merge Skills

### 8.1 Signals That Skills Should Merge

| Signal | Threshold | Example |
|--------|-----------|---------|
| Skill is too thin | <150 lines in SKILL.md | A skill that only covers one narrow tool |
| Always used together | Users always need both skills for any task | A "testing-frameworks" skill always used with "test-strategy" skill |
| Overlapping triggers | >30% of trigger keywords are shared | Two skills that both trigger on "database" queries |
| Overlapping content | Same guidance appears in both skills | Both skills explain the same pattern |
| One skill defers to the other constantly | 50%+ of responses say "defer to X" | Skill rarely gives its own guidance |

### 8.2 How to Merge

1. **Identify the merged scope** — What is the combined skill responsible for?
2. **Choose the surviving skill** — The larger/more established skill absorbs the smaller one
3. **Merge evals** — Combine eval files, remove duplicates, renumber IDs
4. **Merge content** — Integrate references, update SKILL.md, remove redundancy
5. **Deprecate the absorbed skill** — Follow the deprecation protocol (Section 9)
6. **Update cross-references** — All skills that referenced the absorbed skill now point to the survivor
7. **Run all evals** — Merged skill passes all combined evals

### 8.3 Merge Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Merging too much | Combined skill covers too many domains | Keep separate; clarify boundaries instead |
| Losing knowledge | Content dropped during merge | Verify all evals pass after merge |
| Forgetting cross-references | Other skills still reference the deprecated skill | Search all SKILL.md files for references to the deprecated name |
| Merging without eval reconciliation | Duplicate or conflicting evals | Review and reconcile all evals before merging |

---

## 9. Deprecation Protocol

### 9.1 When to Deprecate

- Skill has been merged into another skill
- Skill covers a technology/practice that is no longer relevant
- Skill has been replaced by a better-scoped skill
- Skill has zero eval passes and no user activation in 3+ months

### 9.2 Deprecation Steps

1. **Mark as deprecated** in the SKILL.md frontmatter:
   ```yaml
   ---
   name: old-skill-name
   deprecated: true
   replacement: new-skill-name
   description: >
     DEPRECATED — use new-skill-name instead. [Original description for backward compatibility]
   ---
   ```

2. **Add a deprecation notice** at the top of SKILL.md:
   ```markdown
   > **DEPRECATED**: This skill has been superseded by `new-skill-name`.
   > All functionality is now available in the replacement skill.
   > This skill will be removed in a future update.
   ```

3. **Redirect** — When the deprecated skill is activated, it should redirect to the replacement

4. **Keep for backward compatibility** — Do not delete immediately. Keep the directory for at least 2 review cycles.

5. **Delete** — After 2 review cycles with no activation, remove the directory

### 9.3 Deprecation Checklist

- [ ] Replacement skill exists and covers all the deprecated skill's evals
- [ ] SKILL.md frontmatter updated with `deprecated: true` and `replacement`
- [ ] Deprecation notice added to top of SKILL.md
- [ ] All other skills' cross-references updated
- [ ] ETYB routing updated (if applicable)
- [ ] Evals migrated to replacement skill (or archived)

---

## 10. Improvement Loop Anti-Patterns

| Anti-Pattern | Description | How to Avoid |
|-------------|-------------|-------------|
| **Fixing without an eval** | Changing a skill without a failing eval first | Always write the eval first. If you cannot write an eval, you do not understand the gap. |
| **Over-fixing** | Making changes beyond what the eval requires | Minimal change principle. Just pass the eval. |
| **Eval-chasing** | Writing evals that are easy to pass rather than meaningful | Evals should test real user scenarios, not artificial benchmarks. |
| **Ignoring regressions** | Not running existing evals after a change | Always run all evals after any change. |
| **Premature optimization** | Restructuring a skill that is working fine | If all evals pass and users are happy, leave it alone. |
| **Improvement hoarding** | Collecting gap reports but never acting on them | Process gaps in priority order. If a gap is not worth fixing, delete the report. |
| **Scope inflation** | Each improvement makes the skill bigger without trimming | After adding content, check: is anything now redundant? Can something be removed? |
| **Blind consensus** | Accepting all user feedback as valid without evaluation | Some feedback is one-off preference. Wait for the pattern (3+ occurrences). |
| **Death by committee** | Multiple conflicting improvement proposals for one skill | One improvement at a time. Verify. Then the next. |
