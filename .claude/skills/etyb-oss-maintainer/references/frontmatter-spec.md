# Frontmatter spec

Every `skills/<name>/SKILL.md` opens with YAML frontmatter between two `---` lines. This is the shape `etyb-skills` ships, derived from the [agentskills.io specification](https://agentskills.io/specification) and our own conventions.

## Required fields

| Field | Type | Notes |
|---|---|---|
| `name` | string | Lowercase + hyphens. Must match the parent directory exactly. |
| `description` | YAML scalar (`>`) | Multi-line. First sentence is the elevator pitch; second line starts with `Triggers:` and lists every word/phrase that should activate the skill. ≤1024 chars total. |
| `license` | string | `MIT` for everything in this repo. |
| `compatibility` | string | One line, ≤500 chars. Describes runtime targets — typically `Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents`. |
| `metadata.author` | string | `e-t-y-b`. |
| `metadata.version` | string | Semver `MAJOR.MINOR.PATCH`. Quoted (`"1.0.0"`) so YAML keeps it as a string. |
| `metadata.category` | string | One of: `etyb`, `core-team`, `vertical`, `process-protocol`, `internal-tooling`. |

## Optional fields

| Field | Notes |
|---|---|
| `metadata.scope` | `project-local` for skills that ship under `.claude/skills/` rather than the published `skills/`. |

## Annotated example

```yaml
---
name: code-reviewer
description: >
  Code review expert analyzing PRs across quality, performance, security, and architecture dimensions with actionable feedback. Use when reviewing code, PRs, diffs, or auditing code quality.
  Triggers: review this code, review my PR, code review, pull request review, merge request review, ...
license: MIT
compatibility: Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "1.0.0"
  category: core-team
---
```

## What `validate-frontmatter.sh` checks

- All required top-level fields present
- `metadata` block exists with `author`, `version`, `category`
- `description` contains a `Triggers:` line
- `metadata.version` matches `^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$`

What it does not check (deliberately): tone, completeness of triggers, accuracy of compatibility — those are judgment calls handled in PR review.
