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

## 3d. Stack content completeness gate (v4+)

Since v4, vendor depth lives in this repo at `stacks/<vendor>/` (slim `SKILL.md` trigger pointer + per-product canonical pages + per-role composed views). Every Stack folder ships everything in one place — no separate docs site.

The `check-currency.sh` validator already enforces folder-level completeness:
- Every `stacks/<vendor>/SKILL.md` must have `last_verified_on` in frontmatter
- Every Stack folder must have at least 2 sibling files alongside SKILL.md (warning otherwise — likely incomplete)
- Per-product `drift_risk` thresholds must be respected (high=90d, medium=180d, low=365d)

Optionally probe vendor `authoritative_url` reachability:

```
CHECK_CURRENCY_FETCH=1 scripts/maintainer/check-currency.sh
```

Vendor doc 404s are warnings, not errors — vendor sites move and we don't want them to block our releases. They get reviewed in the next currency-refresh PR.

## 3e. Trigger-recall gate (v4+)

`/etyb` is the **only** trigger surface in v4 — there are no peer slash commands to catch work if ETYB fails to activate. A description that scores low on recall (true-positives that don't fire) silently degrades the whole product. Before tagging, the description must be empirically validated.

The eval set lives at `skills/etyb/evals/trigger-eval-v4.json` — currently 33 queries (23 should-trigger across all the specialist + vertical lanes, 10 should-not-trigger near-misses). Run the optimization loop against it:

```
python -m scripts.run_loop \
  --eval-set skills/etyb/evals/trigger-eval-v4.json \
  --skill-path skills/etyb \
  --model <model-id-from-current-session> \
  --max-iterations 5 \
  --verbose
```

The loop is in the skill-creator skill's `scripts/` directory; run from there. It uses `claude -p` as a subprocess, so the running user must have valid Claude credentials. A previous attempt (`.eval-workspace/run.log`) crashed at iteration 1→2 because `claude -p` returned a 401 — diagnose credentials before retrying.

**Pass bar:** test-set recall ≥ 70% on should-trigger queries while keeping should-not-trigger queries at ≥ 90%. The loop reports `best_description` (test-score-optimized, anti-overfit). Replace SKILL.md's `description:` with that value, re-run the umbrella validator, and only then cut the tag.

If the loop cannot run for environmental reasons, run the **subagent-based fallback**: spawn 3 parallel subagents, give each one the description text from `skills/etyb/SKILL.md` and a third of the eval queries, ask each to decide yes/no per query as Claude would at trigger time, and aggregate. This is an optimistic upper bound on production recall (subagents reason deliberately; real trigger decisions happen mid-conversation with less deliberation) but is sufficient as a smoke test. Save the aggregate to `.eval-workspace/iteration-N-subagent-eval/results.json`. The v4.0.0 description was validated this way (23 TP / 10 TN / 0 FP / 0 FN against 33-query eval set) after `claude -p` returned 401 for the canonical loop.

The shipped v4 description was hand-tuned from the iteration-1 failure pattern (188 → 405 words, situational framing rather than identity framing); record any further tuning in the commit message.

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
