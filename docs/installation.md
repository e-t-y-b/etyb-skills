# Installation Guide

ETYB is distributed as [agent skills](https://agentskills.io) — plain folders of markdown that any compliant coding agent can discover. One install command covers Claude Code, OpenAI Codex, Cursor, Kiro, Trae, Google Antigravity, and anything else that reads a skills directory.

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

In the current v5 milestone, ETYB's disciplines — TDD-first, verification-before-claims, two-stage review — are **model-trusted**: they are enforced by instruction, not by runtime hooks. Deterministic hook enforcement and the specialist agent definitions ship in milestone M2 (see `docs/plan/skills-5.0-plan.md`). Until then, no hook wiring is installed and none needs verifying.

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
