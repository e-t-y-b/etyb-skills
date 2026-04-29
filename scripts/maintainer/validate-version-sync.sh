#!/usr/bin/env bash
#
# Verify that the five version strings stay aligned:
#   VERSION
#   package.json                       .version
#   manifest.json                      .bundle.version
#   .claude-plugin/marketplace.json    .metadata.version
#   .claude-plugin/plugin.json         .version

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

fail() {
  echo "✗ validate-version-sync: $1" >&2
  exit 1
}

read_json_field() {
  # $1 = file, $2 = jq filter (e.g. '.bundle.version')
  if command -v jq >/dev/null 2>&1; then
    jq -r "$2" "$1"
  else
    python3 - "$1" "$2" <<'PY'
import json, sys
path = sys.argv[1]
keys = sys.argv[2].lstrip('.').split('.')
with open(path) as f:
    data = json.load(f)
for k in keys:
    data = data[k]
print(data)
PY
  fi
}

[[ -f VERSION ]] || fail "VERSION file missing"
canonical="$(tr -d '[:space:]' < VERSION)"
[[ -n "$canonical" ]] || fail "VERSION file is empty"

# Pairs of "file::filter".
sources=(
  "package.json::.version"
  "manifest.json::.bundle.version"
  ".claude-plugin/marketplace.json::.metadata.version"
  ".claude-plugin/plugin.json::.version"
)

mismatches=()
for entry in "${sources[@]}"; do
  file="${entry%%::*}"
  filter="${entry##*::}"
  [[ -f "$file" ]] || fail "missing version source file: $file"
  found="$(read_json_field "$file" "$filter")"
  if [[ "$found" != "$canonical" ]]; then
    mismatches+=("$file ($filter) = '$found', expected '$canonical'")
  fi
done

if [[ ${#mismatches[@]} -gt 0 ]]; then
  {
    echo "✗ validate-version-sync: VERSION='$canonical' but found drift:"
    for m in "${mismatches[@]}"; do
      echo "  $m"
    done
  } >&2
  exit 1
fi

echo "✓ validate-version-sync: all 5 sources match VERSION=$canonical"
