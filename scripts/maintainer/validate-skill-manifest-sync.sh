#!/usr/bin/env bash
#
# Verify that the skill list is consistent across:
#   skills/*/                            (directory layout)
#   manifest.json .skills                (published manifest)
#   .claude-plugin/marketplace.json      (plugin "etyb-full" skills list)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

fail() {
  echo "✗ validate-skill-manifest-sync: $1" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || fail "jq is required"

dirs="$(find skills -mindepth 1 -maxdepth 1 -type d \
          -exec test -f {}/SKILL.md \; -print \
        | sed 's|^skills/||' \
        | sort)"

manifest="$(jq -r '.skills | keys[]' manifest.json | sort)"

marketplace_full="$(
  jq -r '
    (.plugins[] | select(.name == "etyb-full") | .skills[])
  ' .claude-plugin/marketplace.json \
    | sed 's|^\./skills/||' \
    | sort
)"

if [[ "$dirs" != "$manifest" ]]; then
  {
    echo "✗ validate-skill-manifest-sync: skills/ vs manifest.json drift"
    diff <(echo "$dirs") <(echo "$manifest") || true
  } >&2
  exit 1
fi

if [[ "$dirs" != "$marketplace_full" ]]; then
  {
    echo "✗ validate-skill-manifest-sync: skills/ vs marketplace.json (etyb-full) drift"
    diff <(echo "$dirs") <(echo "$marketplace_full") || true
  } >&2
  exit 1
fi

count="$(wc -l <<<"$dirs" | tr -d ' ')"
echo "✓ validate-skill-manifest-sync: $count skills aligned across skills/, manifest.json, marketplace.json"
