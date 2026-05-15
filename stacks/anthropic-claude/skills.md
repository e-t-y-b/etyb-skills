---
title: Skills
description: "First-class Claude capability — `SKILL.md` + frontmatter, description-triggered auto-load. This ETYB pack ships as a Skill. Pay attention to your `description:` triggers — that's the contract."
product:
  name: Skills
  stack: anthropic-claude
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, system-architect]
  authoritative_url: https://docs.anthropic.com/en/docs/claude-code/skills
  notes: "First-class capability 2025-2026; this very ETYB pack ships as a Skill; trigger surface is the description frontmatter."
---

## What it is

A Skill is a `SKILL.md` file with YAML frontmatter (name, description, license, metadata) + body content + optional `references/` and `assets/` directories. Skills are **auto-loaded by description-trigger matching** — when the user's message or context matches the Skill's `description` text, [Claude Code](/stacks/anthropic-claude/claude-code/) and other Anthropic harnesses load the Skill into context.

**This ETYB pack is a Skill.** You're reading proof that the system works. See [Claude Code Skills docs](https://docs.anthropic.com/en/docs/claude-code/skills) for the canonical spec.

```yaml
---
name: my-skill
description: >
  Triggers on X, Y, Z. Use this Skill when ...
license: MIT
metadata:
  version: "1.0.0"
  category: ...
---

# Skill body — the actual instructions
```

## When to use

Author a Skill when:

- **Codifying team conventions** — "the way we do things here" expressed as auto-loaded context.
- **Domain expertise** that applies on specific keywords — Salesforce specialist, AWS specialist, security review specialist.
- **Workflows** that benefit from auto-loaded instructions — review protocols, debugging protocols, deployment checklists.
- **Slash commands** — Skills can be invoked explicitly via `/<name>` in Claude Code.

Don't author a Skill for:

- **One-off prompts.** Just include them in a system prompt or paste them in chat.
- **Generic engineering advice** that should apply always. Use system-prompt-level context for those.
- **Content that needs to load on every conversation regardless of topic.** Skills are conditional on trigger match.

## 2025-2026 currency anchors

- **First-class capability since 2025.** Skill format stabilized in 2025; conventions still settling in 2026 (frontmatter schema, references/assets layout).
- **Description-triggered auto-load.** The `description:` field is the trigger surface. Sloppy descriptions = Skill doesn't load when needed; over-broad = Skill loads when it shouldn't and pollutes context.
- **`.claude/skills/<name>/SKILL.md`** is the canonical layout. Supporting files go in `references/` (load on demand) and `assets/` (templates, scripts, data).
- **ETYB itself** is shipped this way — `skills/etyb/SKILL.md` plus `skills/etyb/core/`, `skills/etyb/references/`, `skills/etyb/adapters/`.
- **Slash commands via Skills** — Skills with appropriate frontmatter become user-invokable as `/<name>`.

## Patterns + anti-patterns

### Pattern — write the `description:` as the trigger surface, not as marketing

The `description` field is what Claude reads to decide whether to load the Skill. List the keywords and phrases that should activate it:

```yaml
description: >
  Triggers: salesforce, apex, lwc, flow, agentforce, data 360, einstein,
  trailhead, sfdx, sf cli, dx, omnistudio, hyperforce, sandbox, scratch org,
  metadata api, tooling api, soql, sosl, governor limits...
```

Not:

```yaml
description: The ultimate Salesforce expert.  # tells Claude nothing about when to load
```

### Pattern — one Skill, one purpose

A Skill that "does engineering work" is too broad. A Skill that "reviews Apex code for governor-limit violations" is the right scope. Keep Skills focused; let many specific Skills exist alongside each other.

### Pattern — trigger surface broader than action surface

The `description` should list every phrasing the user might say (keywords, synonyms, related terms); the body narrows down what the Skill actually does. **Over-trigger and under-act**, not the reverse.

### Pattern — defer heavy content to `references/`

A 5,000-line `SKILL.md` is unwieldy. Put the briefing in `SKILL.md`; put deep dives in `references/`. The Skill loads the briefing on trigger match; the body explicitly instructs to read references on demand.

### Pattern — version Skills in source control

Skills are code-shaped. Commit them. Review them in PRs. Run validators (frontmatter schema, link checks). Don't let Skills drift across the team.

### Anti-pattern — vague trigger descriptions

"Use this for engineering work" matches nothing reliably. Triggers must be specific enough to fire on the right contexts.

### Anti-pattern — trigger descriptions in marketing voice

"The ultimate AI engineering powerhouse" doesn't help Claude know when to load the Skill. Write the description for the routing model, not for a landing page.

### Anti-pattern — Skills that try to override Claude's safety

Anthropic's safety layers run regardless of Skill content. Trying to "jailbreak via Skill" doesn't work and just makes the Skill useless. Don't try.

### Anti-pattern — Skills with no eval

Like any prompt, a Skill should be eval'd. Does it load when it should? Does it produce the right behavior when loaded? Run an eval suite; treat Skill changes like prompt changes.

### Anti-pattern — Skills referencing dynamic state

Skills are static files. Don't write them as if they could query a database or fetch live data. For dynamic context, use [MCP](/stacks/anthropic-claude/mcp/) resources or tools.

## Gotchas

- **Trigger collision.** Two Skills with overlapping triggers can both load and conflict in voice/instructions. Test trigger specificity.
- **Skill description fits inside the model's context.** Very long descriptions get truncated — be specific but concise.
- **References load explicitly.** The Skill body must instruct "read `references/X.md` when working on Y" — they don't auto-load with the Skill.
- **Marketplace Skills are external code.** Treat installed Skills like installed software — review source, pin versions. See [security-engineer overlay](/stacks/anthropic-claude/security-engineer/#skills-and-sub-agents--security-implications).
- **The `name:` must be unique** in the user's environment. Namespace conflicts are a real source of bugs.

## Cross-references

- [Claude Code](/stacks/anthropic-claude/claude-code/) — Skills live in `.claude/skills/`
- [Sub-agents](/stacks/anthropic-claude/sub-agents/) — pair Skills with sub-agents for specialization
- [MCP](/stacks/anthropic-claude/mcp/) — for dynamic data, not Skills
- [ai-ml-engineer overlay](/stacks/anthropic-claude/ai-ml-engineer/) — designing Skills
- [security-engineer overlay](/stacks/anthropic-claude/security-engineer/) — Skills as code; review like code
- [Claude Code Skills docs](https://docs.anthropic.com/en/docs/claude-code/skills)
