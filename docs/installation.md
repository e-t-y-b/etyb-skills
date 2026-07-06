# Installation Guide

ETYB is distributed as [agent skills](https://agentskills.io) — plain folders of markdown that any compliant coding agent can discover. One install command covers Claude Code, OpenAI Codex, Cursor, Kiro, Trae, Google Antigravity, and anything else that reads a skills directory.

## What each install path gets you

| | skills CLI (`npx skills add`) — any harness | Claude Code plugin |
|---|---|---|
| `/etyb` skill (the single trigger surface) | ✅ | ✅ |
| Sub-agent definitions (explorer, planner, reviewer, stack-researcher, cartographer) | ❌ — role work runs inline, instruction-guided | ✅ — dispatched into their own contexts, model-tiered (light work on the smallest model, never above your session model) |
| Advisory hooks (TDD warning, review-evidence check, merge-verify, edit/test logging) | ❌ | ✅ — warn, never block |
| Vendor stacks (13, currency-stamped) | ✅ read from the repo / GitHub raw | ✅ same |

Either way, **`/etyb` is the only skill you ever invoke** — say the situation ("this query is slow", "review this diff") or call `/etyb` explicitly. There are no peer commands; the specialists, protocols, and sub-agents are internal.

## Primary Install (any agent)

```bash
npx skills add e-t-y-b/etyb-skills
```

The [`skills` CLI](https://github.com/vercel-labs/skills) detects every agent configured in your project (and machine) and installs into each agent's skills directory. Useful variants:

```bash
npx skills add e-t-y-b/etyb-skills -g          # global (user-level) instead of project-level
npx skills add e-t-y-b/etyb-skills --list      # list available skills without installing
npx skills add e-t-y-b/etyb-skills --all       # all skills, all detected agents, no prompts
npx skills ls                                  # show what is installed where
```

### Teams: pin with skills-lock.json

Project-level installs record what was installed in `skills-lock.json`. Commit it. Teammates (and CI) restore the exact same skill set with:

```bash
npx skills experimental_install
```

## Claude Code Alternative (plugin)

This repo ships a plugin manifest at `.claude-plugin/plugin.json`, so Claude Code can install ETYB natively instead of via the skills CLI. Inside a Claude Code session:

```
/plugin marketplace add e-t-y-b/etyb-skills
/plugin install etyb@etyb-skills
```

**Nothing to download or clone.** The marketplace `add` takes the GitHub repo reference directly — Claude Code fetches the repo itself and installs everything in one step: the `/etyb` skill, the five sub-agent definitions, the advisory hooks, and the vendor stacks. Updates arrive the same way (`/plugin` menu → update, or `claude plugin update etyb@etyb-skills`).

Pick one path — skills CLI **or** plugin — not both, or the `/etyb` skill will be discovered twice.

## Where Skills Land (per harness)

If you prefer a manual install, clone the repo and copy `skills/etyb/` (and any `stacks/<vendor>/` folders you want) into the directory your harness reads:

| Harness | Discovery directory |
|---------|---------------------|
| Claude Code | `.claude/skills/` (project) or `~/.claude/skills/` (global) — or the plugin, above |
| OpenAI Codex | `.agents/skills/` |
| Google Antigravity | `.agents/skills/` |
| Trae | `.agents/skills/` |
| Kiro | `.kiro/skills/` |
| Cursor | `.cursor/skills/` |

The skill folder name must match the `name:` in its `SKILL.md` frontmatter (`etyb`), and it must sit directly inside the skills directory — not nested deeper.

## Verifying the Install

Check that the skill landed where your harness looks (adjust the path per the table above):

```bash
ls .claude/skills/etyb/SKILL.md      # Claude Code (project install)
ls .agents/skills/etyb/SKILL.md      # Codex / Antigravity / Trae
head -5 .claude/skills/etyb/SKILL.md # frontmatter should show "name: etyb"
```

If you installed with the skills CLI:

```bash
npx skills ls
```

Then start a session and ask the agent something engineering-shaped ("review this function", "why is this query slow"). The response should engage ETYB and end with its `ETYB · <role-engaged>` signature.

## Enforcement Status (honest note)

ETYB's disciplines — TDD-first, verification-before-claims, two-stage review — are primarily **model-trusted**: the skill instructs the agent to follow them. On the Claude Code plugin path only, five advisory hooks (`hooks/hooks.json`) add a deterministic layer on top: they observe Edit/Write/Bash/Stop/SessionStart events and surface `systemMessage` warnings (e.g. "no test file found", "no review evidence before commit") — they never block the action. Skills-CLI installs (Codex, Cursor, Kiro, etc.) do not get hook enforcement; the disciplines there remain instruction-only.

## Updating

```bash
npx skills update
```

For the Claude Code plugin path, update the marketplace and reinstall from the `/plugin` menu.

## Uninstalling

```bash
npx skills remove etyb
```

Or delete the skill folder from your harness's skills directory (e.g. `rm -rf .claude/skills/etyb`). On the plugin path: `/plugin uninstall etyb@etyb-skills`.

## Troubleshooting

**Skill doesn't activate**
Confirm the directory is exactly `<skills-dir>/etyb/SKILL.md` for your harness (see the table above) and that the folder name matches the frontmatter `name:`.

**Installed twice**
If you used both the skills CLI and the Claude Code plugin, remove one — duplicate discovery causes trigger competition.

**`npx skills` prompts hang in CI**
Pass `-y` (skip confirmations) or use `npx skills experimental_install` against a committed `skills-lock.json`.
