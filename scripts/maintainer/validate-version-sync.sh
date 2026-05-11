#!/usr/bin/env bash
#
# Verify that every version string in the repo equals VERSION.
#
# As of v3.0.0 the repo uses a single-version policy: the bundle version is
# the only version that exists. Every skill, every stack, every artifact
# tracks it on every release. No per-skill or per-stack drift is allowed.
#
# This script checks:
#
#   Bundle (5 files):
#     VERSION
#     package.json                       .version
#     manifest.json                      .bundle.version
#     .claude-plugin/marketplace.json    .metadata.version
#     .claude-plugin/plugin.json         .version
#
#   Per-skill manifest entries:
#     manifest.json .skills.* (every value must equal VERSION)
#
#   Per-stack manifest entries:
#     manifest.json .stacks.*.version (every value must equal VERSION)
#
#   Per-SKILL.md frontmatter:
#     skills/*/SKILL.md  metadata.version  (every value must equal VERSION)
#     stacks/*/SKILL.md  metadata.version  (every value must equal VERSION)

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

# --- 1. The 5 bundle files (the historical check) ---

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

# --- 2. Per-skill + per-stack manifest entries + per-SKILL.md frontmatter ---
# Single-version policy. Drift in any one of these fails the release.

drift="$(
python3 - "$canonical" <<'PY'
import json, re, sys
from pathlib import Path

canonical = sys.argv[1]
problems = []

# Per-skill manifest entries
mf = json.loads(Path("manifest.json").read_text())
for name, ver in mf.get("skills", {}).items():
    if ver != canonical:
        problems.append(f"manifest.json .skills.{name} = '{ver}', expected '{canonical}'")

# Per-stack manifest entries
for name, entry in mf.get("stacks", {}).items():
    ver = entry.get("version")
    if ver != canonical:
        problems.append(f"manifest.json .stacks.{name}.version = '{ver}', expected '{canonical}'")

# Per-SKILL.md frontmatter — scan skills/ and stacks/
for p in sorted(Path("skills").glob("*/SKILL.md")) + sorted(Path("stacks").glob("*/SKILL.md")):
    text = p.read_text()
    m = re.search(r'^\s*version:\s*"([^"]+)"', text, re.MULTILINE)
    if not m:
        problems.append(f"{p}: no version: line in frontmatter")
        continue
    if m.group(1) != canonical:
        problems.append(f"{p} = '{m.group(1)}', expected '{canonical}'")

for line in problems:
    print(line)
PY
)"

if [[ -n "$drift" ]]; then
  while IFS= read -r line; do
    mismatches+=("$line")
  done <<< "$drift"
fi

# --- Report ---

if [[ ${#mismatches[@]} -gt 0 ]]; then
  {
    echo "✗ validate-version-sync: VERSION='$canonical' but found drift in ${#mismatches[@]} location(s):"
    for m in "${mismatches[@]}"; do
      echo "  $m"
    done
    echo ""
    echo "Single-version policy (since v3.0.0): every skill, every stack, every"
    echo "frontmatter metadata.version, and every bundle file tracks VERSION."
    echo "Bump them all together when you release."
  } >&2
  exit 1
fi

echo "✓ validate-version-sync: VERSION=$canonical aligned across bundle (5), skills ($(jq -r '.skills | length' manifest.json)), stacks ($(jq -r '.stacks | length' manifest.json)), and all SKILL.md frontmatter"
