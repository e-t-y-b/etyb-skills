# Installation Guide

ETYB-Skills is distributed as a bundle of 31 coordinated skills. This guide covers how to install, update, and resolve conflicts across Claude Code, OpenAI Codex, and Google Antigravity.

## Picking Your Install Method

| You are using… | Recommended install |
|----------------|---------------------|
| Claude Code | `/plugin marketplace add` (native, handles discovery + install) |
| OpenAI Codex | Clone + `scripts/install.sh --target .agents/skills` |
| Google Antigravity | Clone + `scripts/install.sh --target .agent/skills` |
| Generic (any agentskills.io-compliant agent) | `npx skills add e-t-y-b/etyb-skills` or manual clone |
| Developing ETYB itself | Clone + work in `skills/` directly |

## Claude Code (Plugin System)

```bash
/plugin marketplace add e-t-y-b/etyb-skills
/plugin install etyb-full@etyb-skills             # all 31 skills
# or pick a subset:
/plugin install etyb-process-protocols@etyb-skills  # 9 protocols + etyb
/plugin install etyb-core-team@etyb-skills          # 14 core teams + etyb
/plugin install etyb-verticals@etyb-skills          # 6 domain specialists
```

Plugin bundles are defined in `.claude-plugin/marketplace.json`.

## OpenAI Codex

Codex discovers skills from `.agents/skills/` at the workspace root and up to the git repo root, plus `~/.agents/skills/` globally.

```bash
git clone https://github.com/e-t-y-b/etyb-skills.git
cd etyb-skills
./scripts/install.sh --target /path/to/your-project/.agents/skills
```

The script handles conflicts interactively. See [Conflict Resolution](#conflict-resolution) below.

See also: [`skills/etyb/adapters/codex/ADAPTER.md`](../skills/etyb/adapters/codex/ADAPTER.md) for enforcement model and `agents/openai.yaml` options.

## Google Antigravity

Antigravity discovers skills from `.agent/skills/` (singular — distinct from Codex's `.agents/`) at the workspace root, plus `~/.gemini/antigravity/skills/` globally.

```bash
git clone https://github.com/e-t-y-b/etyb-skills.git
cd etyb-skills
./scripts/install.sh --target /path/to/your-workspace/.agent/skills
```

For elevation to ADK-backed skill with live sub-agent dispatch, see [`skills/etyb/adapters/antigravity/adk-integration.md`](../skills/etyb/adapters/antigravity/adk-integration.md).

## Generic / Manual Install

```bash
git clone https://github.com/e-t-y-b/etyb-skills.git
cd etyb-skills
./scripts/install.sh                  # auto-detects target dir
./scripts/install.sh --dry-run        # show what would happen
./scripts/install.sh --target DIR     # explicit target
```

`scripts/install.sh` supports:
- `--dry-run` — preview changes, modify nothing
- `--force` — accept all conflicts with "replace" (no prompts)
- `--on-conflict prompt|replace|keep|skip` — conflict policy
- `--target DIR` — explicit destination
- `--source DIR` — override source (defaults to `skills/` relative to script)

## Conflict Resolution

When `install.sh` encounters an existing skill at the target path, it presents four options:

| Option | Effect |
|--------|--------|
| **replace** | Back up existing skill to `<name>.bak.<timestamp>`, install ETYB's version |
| **keep** | Install ETYB's version side-by-side as `<name>.etyb/` (no overwrite) |
| **skip** | Leave existing skill in place, do not install ETYB's |
| **prompt** (default) | Ask per skill |

Use `--on-conflict` to apply one policy to the whole install.

### v1.x Migration (`orchestrator` → `etyb`)

In 2.0.0 the orchestrator skill was renamed from `orchestrator` to `etyb`. On install, the script detects any legacy `orchestrator/` folder in the target and offers to move it aside (to `orchestrator.bak.<timestamp>`) before installing fresh. The legacy folder is **moved, never deleted** — you can inspect or restore it manually if needed.

### Data Never Touched

Regardless of conflict policy, the install and update scripts NEVER modify:
- `.etyb/plans/` — your plan artifacts
- `.claude/plans/` — Claude Code native plan mode
- `.claude/settings.local.json` — your local Claude Code settings
- Any `*.bak.*` backups created by previous runs

## Updating

```bash
./scripts/update.sh --check    # report whether an update is available
./scripts/update.sh            # interactive update
./scripts/update.sh --force    # skip confirmation prompts
```

See [Updating section in README](../README.md#updating) and [CHANGELOG.md](../CHANGELOG.md).

## Verifying the Install

After installation:

```bash
ls <target>/                 # should list 31 skills including etyb/
cat <target>/etyb/VERSION    # if VERSION was shipped
```

On Claude Code, verify hooks are wired:
```bash
cat .claude/settings.json | grep -c "hook"    # should be 5
```

On Codex or Antigravity, verify SKILL.md discovery by asking the agent to list available skills — ETYB and specialists should appear.

## Uninstalling

```bash
# Remove all ETYB skills from a target dir (preserves .bak.* backups and user data)
for name in $(jq -r '.skills | keys[]' manifest.json); do
  rm -rf "<target>/$name"
done
```

Or on Claude Code: `/plugin uninstall etyb-full@etyb-skills`.

## Troubleshooting

**"No target dir detected"**
Specify `--target` explicitly. The script looks for `.claude/skills/`, `.agents/skills/`, `.agent/skills/`, or `skills/` in that order.

**"fast-forward failed" on update**
Your local branch has diverged from `origin/main`. Either `git stash` your changes, or merge manually with `git pull --rebase`.

**"could not fetch remote manifest"**
The repo may be private or the network may be blocking raw.githubusercontent.com. Set `GITHUB_TOKEN` or `git pull` directly.

**Skill doesn't activate on Codex/Antigravity**
Check that the skill directory is at `.agents/skills/<name>/` (Codex) or `.agent/skills/<name>/` (Antigravity) — not nested deeper. The `name:` in SKILL.md frontmatter must match the parent directory name exactly.
