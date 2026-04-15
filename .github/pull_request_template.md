# Summary

<!-- What does this PR change and why? Link related issues. -->

## Type

- [ ] Bug fix
- [ ] New skill or enhancement to an existing skill
- [ ] Documentation
- [ ] Infrastructure (scripts, CI, configs)
- [ ] Breaking change (requires major version bump)

## Affected skills / files

<!-- e.g. skills/backend-architect/, scripts/update.sh, docs/installation.md -->

## Verification

<!-- Evidence that this change works. For skill content, quote the behavior you observed or the prompt you tested. For scripts, paste the test command + output. -->

## Checklist

- [ ] Changes follow the [agentskills.io spec](https://agentskills.io/specification) (SKILL.md frontmatter valid)
- [ ] No skill references paths that would break if ETYB is uninstalled (specialists remain standalone)
- [ ] `CHANGELOG.md` updated if user-visible behavior changes
- [ ] `manifest.json` updated if skill list or versions change
- [ ] No internal working docs (plans, pitch copy, etc.) accidentally committed — see `.gitignore`
- [ ] No secrets or credentials in the diff

## Breaking change migration

<!-- If this is a breaking change, describe the migration path users need. -->
