# Release runbook

End-to-end version bump for `etyb-skills`. Follow it in order.

## 1. Decide the bump

Per `CONTRIBUTING.md` SemVer rubric:

- **Patch** (`X.Y.Z+1`): bug fixes, doc clarifications, internal refactors that do not change skill behavior.
- **Minor** (`X.Y+1.0`): new skill added, new section in an existing skill, new platform support, additive change to a manifest.
- **Major** (`X+1.0.0`): skill removed, skill renamed, breaking change to manifest shape, anything that requires user-side migration.

When in doubt, ship as minor. Do not bump major silently.

## 2. Edit the five version files

Update all of these to the new version:

- `VERSION`
- `package.json` → `.version`
- `manifest.json` → `.bundle.version`
- `.claude-plugin/marketplace.json` → `.metadata.version`
- `.claude-plugin/plugin.json` → `.version`

Then run:

```
scripts/maintainer/validate-version-sync.sh
```

Should print `✓ all 5 sources match VERSION=X.Y.Z`.

## 3. Update CHANGELOG.md

Add a section at the top, dated today:

```
## [X.Y.Z] — YYYY-MM-DD

One-paragraph framing of the release.

### Added
- ...

### Fixed
- ...

### Changed
- ...

### Removed
- ...
```

Drop sections that have nothing in them. Do not list internal-tooling changes (e.g. updates to `.claude/skills/etyb-oss-maintainer/`) — they are not user-visible.

## 3b. Update README.md and other user-facing docs

The CHANGELOG records what changed. The README tells a first-time visitor what `etyb-skills` *is*. They drift apart silently — every release, walk the user-facing docs and update what's stale.

Mandatory check for every release:

- **Top banner version link** (`<a href="...releases/tag/vX.Y.Z">vX.Y.Z</a>`) — bump.
- **Badges** — skill count, platform support, any new "Stack Packs: X" or similar marker.
- **Latest release link** at the bottom of README.
- **Intro paragraph** — does it still describe the system accurately? New artifact types (Stack Packs, new vertical, new platform support) usually want a line.
- **Architecture diagram** — does it reflect the current layer count? Add new layers when they ship.
- **Skills tables / Stacks tables** — add new rows; update counts.
- **"What You Get"** bullets — major capability adds get a bullet.

Mandatory check, also:

- **`docs/installation.md`** if install steps changed.
- **`docs/architecture.md`** if the layer model changed.

Run a final scan: `grep -rn "v<previous-version>" README.md docs/ STACKS.md MARKETPLACE.md 2>/dev/null` — anything still pointing at the old version is drift.

## 3c. Stack currency review

`scripts/maintainer/validate-pr.sh` runs `check-currency.sh` automatically. If any Stack is flagged as stale, that's a release blocker. Options:

- **Refresh the flagged Stack** — open a `currency/<stack>-refresh-YYYY-MM` branch, verify against the Stack's `authoritative_sources.primary` URLs, update content where vendor changes shift recommendations, bump `last_verified_on`. See `references/currency-spec.md` for the full workflow.
- **Defer the release** — if a refresh PR is in flight but not yet merged, defer the bundle release until the Stack ships fresh.

## 3d. docs.etyb.ai deploy gate (v4+)

Since v4, vendor depth lives at docs.etyb.ai, not on disk. The slim local Stack pointers reference `https://docs.etyb.ai/stacks/<vendor>/...` URLs. **Cutting a release tag before the docs site is live ships pointers at 404 destinations.** Order of operations:

1. **Land the docs.etyb.ai PR first.** Any Stack content (new pages, refreshes, schema fixes) that is referenced by this release ships in `e-t-y-b/etyb-dot-ai` and goes live on production docs.etyb.ai.
2. **Run the live probe locally** before opening the etyb-skills release PR:
   ```
   CHECK_CURRENCY_FETCH=1 scripts/maintainer/check-currency.sh
   ```
   Every `https://docs.etyb.ai/stacks/<vendor>/` URL must return 2xx. A single 404 on a Stack the local pointer references is a release-blocker — fix the docs deploy first, then re-run.
3. **Only then cut the etyb-skills release tag.** The website-impact PR (post-release) updates the website's `.upstream-version` marker; the docs themselves are already live.

If you're shipping an etyb-skills release that adds a new Stack pointer, the docs.etyb.ai PR for that Stack's content ships in the same maintainer session — it's the precondition, not a follow-up.

## 4. Run the full validator

```
scripts/maintainer/validate-pr.sh
```

Everything must be green before you push. The umbrella validator includes:

- `validate-frontmatter.sh` — SKILL.md frontmatter shape
- `validate-toc.py` — markdown TOC freshness
- `validate-version-sync.sh` — VERSION aligned across the 5 bundle files + frontmatter
- `validate-skill-manifest-sync.sh` — v4 single-skill layout (1 skill + 14/9/6 references)
- `validate-changelog.sh` — CHANGELOG.md updated for user-visible changes
- `check-currency.sh` — Stacks within drift-risk thresholds

## 5. Open the PR

Title: `Release vX.Y.Z`. Body: paste the new CHANGELOG section. CI will rerun the maintainer checks. Merge when green.

## 6. Tag and let the workflow take over

After the merge lands on `main`:

```
git checkout main && git pull
git tag vX.Y.Z
git push origin vX.Y.Z
```

The `release.yml` workflow notices `VERSION` changed on `main` and creates the GitHub Release with the matching CHANGELOG section as the body. If the tag already exists, the workflow no-ops.

## 7. Cross-repo announce (local-only)

Apply `website-impact-mapping.md` to the new CHANGELOG section to derive the website-side checklist, then:

```
gh issue create \
  --repo e-t-y-b/etyb-dot-ai \
  --title "Upstream etyb-skills → vX.Y.Z" \
  --body "$(<derived-body.md)"
```

This step is run by the maintainer locally with their `gh` auth — never from CI.

## Rollback

If something goes wrong after the release tag is pushed:

1. Open a follow-up patch release. Do not delete the tag.
2. If the tag is on a broken commit, ship `vX.Y.(Z+1)` reverting the bad change. The release workflow handles the new tag the same way.
