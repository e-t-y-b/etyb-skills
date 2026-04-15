# `agents/openai.yaml` — Codex-Specific Metadata

Codex supports an optional `agents/openai.yaml` file inside a skill for Codex-specific metadata: display info, invocation policy, and tool dependencies. This is documented at <https://developers.openai.com/codex/skills/>.

ETYB does not require this file to work on Codex — the portable SKILL.md is sufficient. Adding `agents/openai.yaml` gives you a nicer Codex-native surface (better display in the skill picker, control over implicit invocation, explicit tool declarations).

## Reference — ETYB Skill

Drop this at `skills/etyb/agents/openai.yaml` (or `.agents/skills/etyb/agents/openai.yaml` once installed) if you want Codex-specific polish:

```yaml
interface:
  display_name: ETYB — Virtual Engineering Team
  short_description: CTO-level orchestrator routing work to 20 specialists with 9 always-on engineering disciplines and 5 gated phases.
  brand_color: "#0B1020"
  default_prompt: "Help me plan and ship this."

policy:
  # Default true. Set to false if you want ETYB to only activate on explicit
  # invocation rather than implicit triggering from description keywords.
  allow_implicit_invocation: true

# Optional — declare MCP or other tool dependencies the skill expects to have
# available. Leave empty if ETYB should work against whatever the user's
# environment provides.
dependencies:
  tools: []
```

## Reference — Specialist Skill (pattern)

Each of the 20 specialists can have its own `agents/openai.yaml` if desired. Pattern:

```yaml
interface:
  display_name: Backend Architect
  short_description: Backend engineering specialist — Java, TypeScript, Go, Python, Rust, API design, microservices, auth patterns.

policy:
  allow_implicit_invocation: true
```

## Fields Explained

| Field | Purpose |
|-------|---------|
| `interface.display_name` | Human-readable name shown in Codex's skill picker |
| `interface.short_description` | Sub-title in the picker |
| `interface.icon_small` / `icon_large` | Optional icons (path relative to the skill) |
| `interface.brand_color` | Hex color for UI accent |
| `interface.default_prompt` | A default message to seed a conversation that invokes this skill |
| `policy.allow_implicit_invocation` | `true` (default) lets Codex trigger the skill based on description match; `false` requires explicit invocation. For ETYB, true is correct — you *want* CTO-level routing to activate on "help me build…" style prompts. |
| `dependencies.tools` | List of tool declarations (MCP servers, built-ins) the skill needs. Only needed if the skill's instructions assume a specific tool is available. |

## When To Set `allow_implicit_invocation: false`

Consider `false` for specialists that should not activate without the user explicitly asking — e.g., a specialist that produces side effects on invocation, or one the user wants to gate behind a deliberate call. For most ETYB specialists, keep it `true` so ETYB's routing can pull them in.

## Do Not Duplicate SKILL.md Frontmatter

The portable SKILL.md frontmatter (`name`, `description`, `license`, `compatibility`, `metadata`) is the source of truth. `agents/openai.yaml` is *additive* Codex-specific metadata. Don't restate what SKILL.md already says — that leads to drift.
