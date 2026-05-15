# Website impact mapping

When `etyb-skills` ships a release, the [`etyb-dot-ai`](https://github.com/e-t-y-b/etyb-dot-ai) website usually needs a parallel update. **You implement and ship it** — same maintainer, two repos. This file is the rulebook for translating a CHANGELOG section into the actual website work.

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

## Workflow

The default is a PR on `e-t-y-b/etyb-dot-ai`, not an issue. Steps:

1. `cd /tmp && gh repo clone e-t-y-b/etyb-dot-ai && cd etyb-dot-ai`
2. `git checkout -b website-vX.Y.Z` (match the upstream release tag)
3. Apply the rules table above to the new CHANGELOG section to derive the page-level work.
4. Survey the existing site shape first — read `src/pages/*.astro`, `src/components/Nav.astro`, the Layout and the existing pages — so the new pages match the voice, styling, and routing conventions already in place. Same matrix-green accent, same JetBrains-Mono headers, same dark theme. Do not rewrite the design system.
5. Implement the changes from the rules table. New pages go under `src/pages/`. Update `src/components/Nav.astro` if a new top-level link is needed. Update homepage stat cards / hero copy when totals or framing shift.
6. Build locally if the change is non-trivial: `npm install && npm run build`. Astro will catch broken imports, dead refs, or schema issues.
7. `git add` the changed files, commit with a `Co-Authored-By: Claude` trailer, and push.
8. `gh pr create` with a body that links the upstream release tag and itemizes the page-level changes. The website maintainer (you) then reviews and merges.

## PR template

```
## Summary

Website update for upstream `etyb-skills` vX.Y.Z. Lands the parallel changes on the marketing site.

**Upstream release:** https://github.com/e-t-y-b/etyb-skills/releases/tag/vX.Y.Z

## Page-level changes

- [ ] <item>
- [ ] <item>

## Notes

<one-paragraph context, if anything is non-obvious>

## Test plan

- [ ] Local Astro build clean (`npm run build`)
- [ ] Manual spot-check of new / changed routes
- [ ] Nav reflects new top-level links
```

## When an issue is the right tool (fallback)

File an issue on `e-t-y-b/etyb-dot-ai` instead of opening a PR only when you genuinely cannot implement right now — usually because you lack context (design call needed) or time. The issue body uses the same structure as the PR body, with a clear "blocked on: <reason>" line at the top so a future maintainer knows what's missing.

## Out of scope

- Reaching cross-repo from CI. The PR / issue is created locally with `gh`.
- Direct pushes to `main` on `etyb-dot-ai`. Always go through a PR.
- Rewriting the website's design system. Match existing patterns; do not redesign as a side-effect of a release update.
