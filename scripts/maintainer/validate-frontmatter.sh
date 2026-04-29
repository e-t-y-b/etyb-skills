#!/usr/bin/env bash
#
# Validate SKILL.md frontmatter across all skills against the
# agentskills.io specification used by this repo.
#
# For each skills/*/SKILL.md:
#   - Frontmatter is between the first two `---` lines
#   - Must contain: name, description, license, compatibility,
#     metadata.author, metadata.version, metadata.category
#   - description must contain a `Triggers:` line
#   - metadata.version must be semver (MAJOR.MINOR.PATCH)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

SEMVER_RE='^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$'

fail() {
  echo "✗ validate-frontmatter: $1" >&2
  exit 1
}

extract_frontmatter() {
  awk '
    BEGIN { in_fm=0; seen=0 }
    /^---[[:space:]]*$/ {
      if (in_fm) { exit }
      if (!seen) { in_fm=1; seen=1; next }
    }
    in_fm { print }
  ' "$1"
}

checked=0
while IFS= read -r skill_dir; do
  skill_md="$skill_dir/SKILL.md"
  [[ -f "$skill_md" ]] || fail "missing SKILL.md: $skill_md"

  fm="$(extract_frontmatter "$skill_md")"
  [[ -n "$fm" ]] || fail "no frontmatter found in $skill_md"

  for field in name description license compatibility; do
    grep -qE "^${field}:" <<<"$fm" \
      || fail "$skill_md: missing top-level field '${field}'"
  done

  grep -qE "^metadata:" <<<"$fm" \
    || fail "$skill_md: missing 'metadata:' block"

  for sub in author version category; do
    grep -qE "^[[:space:]]+${sub}:" <<<"$fm" \
      || fail "$skill_md: missing 'metadata.${sub}'"
  done

  grep -qE 'Triggers:' <<<"$fm" \
    || fail "$skill_md: description must contain a 'Triggers:' line"

  version="$(awk '
    /^metadata:/ { in_meta=1; next }
    in_meta && /^[^[:space:]]/ { in_meta=0 }
    in_meta && /^[[:space:]]+version:/ {
      sub(/^[[:space:]]+version:[[:space:]]*/, "")
      gsub(/^["'\'']|["'\'']$/, "")
      print
      exit
    }
  ' <<<"$fm")"

  [[ -n "$version" ]] || fail "$skill_md: could not read metadata.version"
  [[ "$version" =~ $SEMVER_RE ]] \
    || fail "$skill_md: metadata.version '$version' is not semver"

  checked=$((checked + 1))
done < <(find skills -mindepth 1 -maxdepth 1 -type d | sort)

echo "✓ validate-frontmatter: $checked SKILL.md files valid"
