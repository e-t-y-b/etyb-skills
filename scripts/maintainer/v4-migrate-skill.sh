#!/usr/bin/env bash
# v4 migration helper: move a sibling skill under skills/etyb/references/<category>/
#
# Usage: ./v4-migrate-skill.sh <category> <skill-name>
#   category ∈ {specialists, protocols, verticals}
#
# What it does:
#   1. git mv skills/<name>/ skills/etyb/references/<category>/<name>/
#   2. Rename SKILL.md → README.md and strip YAML frontmatter
#   3. Remove evals/ (per-skill eval sets don't apply to internal references)
#
# Idempotent for already-migrated skills (no-op + warning).

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <category> <skill-name>" >&2
  exit 1
fi

category="$1"
name="$2"
src="skills/$name"
dst="skills/etyb/references/$category/$name"

if [[ ! -d "$src" ]]; then
  echo "WARN: $src does not exist (already migrated?). Skipping." >&2
  exit 0
fi

if [[ -d "$dst" ]]; then
  echo "ERROR: $dst already exists. Aborting to avoid clobber." >&2
  exit 1
fi

# Step 1: git mv the whole directory
git mv "$src" "$dst"

# Step 2: SKILL.md → README.md with frontmatter stripped
if [[ -f "$dst/SKILL.md" ]]; then
  awk '
    BEGIN { in_fm = 0; seen_fm_end = 0 }
    /^---$/ {
      if (NR == 1) { in_fm = 1; next }
      if (in_fm && !seen_fm_end) { seen_fm_end = 1; in_fm = 0; next }
    }
    !in_fm && seen_fm_end { print }
    !in_fm && !seen_fm_end && NR > 1 { print }
  ' "$dst/SKILL.md" | sed '/./,$!d' > "$dst/README.md"
  git rm -qf "$dst/SKILL.md"
  git add "$dst/README.md"
fi

# Step 3: drop evals/ (these were for the deleted sibling skill, not the new reference)
if [[ -d "$dst/evals" ]]; then
  git rm -qrf "$dst/evals"
fi

echo "✓ Migrated: $src → $dst"
