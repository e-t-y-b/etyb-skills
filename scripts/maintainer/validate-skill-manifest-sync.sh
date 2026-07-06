#!/usr/bin/env bash
#
# Verify that the skill layout is consistent across:
#   skills/                                 (etyb + thin etyb-* role skills, M2-T2)
#   manifest.json .skill                    (declares the etyb orchestrator)
#   .claude-plugin/marketplace.json         (one plugin "etyb", installing every skills/ dir)
# Also spot-checks that every reference under skills/etyb/references/
# directly correlates to the canonical 14+9+6 contract.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

fail() {
  echo "✗ validate-skill-manifest-sync: $1" >&2
  exit 1
}

command -v jq >/dev/null 2>&1 || fail "jq is required"

# 1. The etyb orchestrator skill plus thin etyb-* role skills (M2-T2).
dirs="$(find skills -mindepth 1 -maxdepth 1 -type d \
          -exec test -f {}/SKILL.md \; -print \
        | sed 's|^skills/||' \
        | sort)"
grep -qx 'etyb' <<<"$dirs" || fail "skills/ must contain the etyb skill, found: $dirs"
extra="$(grep -vx 'etyb' <<<"$dirs" | grep -vE '^etyb-[a-z][a-z-]*$' || true)"
[[ -z "$extra" ]] || fail "skills/ may only contain etyb and etyb-* role skills, found: $extra"

# 2. manifest.json .skill is { etyb: ... }
manifest_keys="$(jq -r '.skill | keys[]' manifest.json | sort)"
[[ "$manifest_keys" == "etyb" ]] || fail "manifest.json .skill must contain exactly one entry (etyb), found: $manifest_keys"

# 3. Single plugin in marketplace.json, also installs only ./skills/etyb
marketplace_plugins="$(jq -r '.plugins[].name' .claude-plugin/marketplace.json | sort)"
[[ "$marketplace_plugins" == "etyb" ]] || fail ".claude-plugin/marketplace.json must contain exactly one plugin (etyb), found: $marketplace_plugins"

expected_skills="$(while IFS= read -r d; do echo "./skills/$d"; done <<<"$dirs" | sort)"
marketplace_skills="$(jq -r '.plugins[0].skills[]' .claude-plugin/marketplace.json | sort)"
[[ "$marketplace_skills" == "$expected_skills" ]] || fail "marketplace plugin skills must exactly match every skills/ dir (etyb + etyb-* role skills); expected:
$expected_skills
found:
$marketplace_skills"

# 4. v4.0 — tier system removed. The manifest must NOT carry a .tiers block,
#    and stack entries must NOT carry available_on_tiers.
if jq -e '.tiers' manifest.json >/dev/null 2>&1; then
  fail "manifest.json .tiers block must not exist (tier system removed in v4.0.0)"
fi
if jq -e '[.stacks[] | select(has("available_on_tiers"))] | length > 0' manifest.json >/dev/null; then
  fail "manifest.json .stacks must not carry available_on_tiers (tier system removed in v4.0.0)"
fi

# 5. Reference counts match the v4 contract.
specialist_count=$(find skills/etyb/references/specialists -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
protocol_count=$(find skills/etyb/references/protocols -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
vertical_count=$(find skills/etyb/references/verticals -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')

[[ "$specialist_count" == "14" ]] || fail "expected 14 specialist references, found $specialist_count"
[[ "$protocol_count" == "9" ]] || fail "expected 9 protocol references, found $protocol_count"
[[ "$vertical_count" == "6" ]] || fail "expected 6 vertical references, found $vertical_count"

echo "✓ validate-skill-manifest-sync: layout aligned (etyb + etyb-* role skills, 14+9+6 references, no tiers)"
