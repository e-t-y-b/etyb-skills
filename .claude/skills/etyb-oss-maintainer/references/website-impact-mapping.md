# Website impact mapping

When `etyb-skills` ships a release, the [`etyb-dot-ai`](https://github.com/e-t-y-b/etyb-dot-ai) website often needs a parallel update. This file is the rulebook that translates a CHANGELOG section into a website-side checklist.

The skill applies the rules greedily — false positives are easier to prune than false negatives.

## Rules

| CHANGELOG signal | Website checklist item |
|---|---|
| `Added: new skill <name>` | Add `<name>` to skills page; bump skill count on homepage |
| `Removed: skill <name>` | Remove from skills page; bump skill count down |
| `Added: ... platform support` | Update platform badges + install docs page |
| `Changed: install ...` | Refresh install instructions on getting-started page |
| `Changed: bundle name`, `Changed: brand` | Audit homepage, README, navigation copy |
| Anything tagged `Breaking` or `### Breaking` | Flag with ⚠️ at top of issue; cross-link migration notes |
| `Fixed: install ... script` | (silent — no website item) |
| `Fixed: hook ...` | (silent) |
| `Fixed: typo` / doc-only fix | (silent) |
| Anything else | Add as "review for impact" |

## Issue template

```
# Upstream etyb-skills → vX.Y.Z

Released: YYYY-MM-DD
Tag: https://github.com/e-t-y-b/etyb-skills/releases/tag/vX.Y.Z
CHANGELOG section: <paste verbatim>

## Website-side TODO

- [ ] <item>
- [ ] <item>

## Notes

<one-paragraph context, if anything is non-obvious>
```

## Out of scope

- Auto-applying the changes to the website. That stays with the website maintainer.
- Reaching cross-repo from CI. The issue is created locally with `gh`.
