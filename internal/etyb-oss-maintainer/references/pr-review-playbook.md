# PR review playbook

Run `scripts/maintainer/validate-pr.sh` first. The deterministic checks catch the cheap stuff. Then apply this playbook for the judgment layer.

## Order of operations

1. Read the PR description. If the change is non-trivial and the description does not say what or why, ask before reviewing.
2. Run `validate-pr.sh`. Anything red is a hard fail — quote it back to the contributor verbatim.
3. Skim the diff against the checklist below.
4. Reply with two sections: **Hard fails** (CI findings) and **Soft notes** (judgment items).

## Skill-content checklist

- Frontmatter passes the spec (`frontmatter-spec.md`).
- `description` triggers list is comprehensive without becoming noise.
- House style: bullets are `-`, not `*`.
- No emoji added to files the change did not need to touch.
- No "Never / Always" absolutes without a reason given.
- No paragraph that just restates the bullets above it as MUST/MUST-NOT lists.
- TOC anchors resolve to real headings (the validator catches this for you, but spot-check the new section if the contributor renumbered).
- Specialists do not hard-depend on `skills/etyb/` — references go by name and capability.

## Common issues seen on real PRs

These are seeded from [PR #5](https://github.com/e-t-y-b/etyb-skills/pull/5), which renumbered sections in `frontend-architect/references/angular-stack.md` and broke the TOC in seven places.

### TOC anchor drift on renumber

**Symptom.** A contributor renumbers `## N. Foo` → `## N+1. Foo` (e.g. inserts a new section) but does not update the TOC entries below. Anchors point to non-existent slugs.

**How to spot.** `validate-toc.py` flags it. Manually: any TOC entry whose number does not match the heading number it points at.

**Ask for.** Either reorder the headings to keep TOC numbers stable, or update every TOC entry to match the new headings.

### Duplicate `## N.` headings

**Symptom.** Two top-level sections share a number — usually because the contributor copy-pasted a section as a starting point and forgot to renumber.

**How to spot.** `grep -nE '^## [0-9]+\.' file.md` and look for repeats. The TOC validator does not catch this directly, only the downstream anchor mismatch.

**Ask for.** Renumber.

### Absolute "Never / Always" rules without justification

**Symptom.** Bullet says `Never use X.` with no surrounding context.

**Ask for.** Either soften (`Prefer Y over X for ...`) or add the reason inline. Absolutes age badly when the underlying tradeoff shifts.

### Redundant MUST/MUST-NOT lists

**Symptom.** A section ends with `## Must` and `## Must Not` lists that just restate every bullet from the section above.

**Ask for.** Remove. The bullets above already say it.

### Bullet character drift (`*` → `-`)

**Symptom.** A new file or new section uses `* ` while the surrounding repo uses `- `.

**Ask for.** Convert. This repo uses `-`.

### Trailing doubled `---` separators

**Symptom.** A doc ends with two or three `---` lines.

**Ask for.** Trim to one (or zero — the closing `---` is rarely needed).

### Emoji creep

**Symptom.** A change to fix a typo also adds 🚀 or ✅ to a doc that did not have them.

**Ask for.** Drop the emoji unless the change was specifically about formatting.

### Vague PR description

**Symptom.** Title is `update angular doc` and the description is empty.

**Ask for.** What changed and why. Especially for skill content where the diff alone does not explain motivation.
