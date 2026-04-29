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

## 4. Run the full validator

```
scripts/maintainer/validate-pr.sh
```

Everything must be green before you push.

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
