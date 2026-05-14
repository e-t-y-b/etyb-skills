#!/usr/bin/env bash
#
# Cross-platform portability checks for ETYB skills (v4 — single-skill shape).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() {
  echo "✗ $1" >&2
  exit 1
}

require_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

# In v4 there is exactly one installable skill: etyb. The 20 specialists,
# 9 protocols, and 6 verticals live as internal references under it.
skill_count=$(
  find skills -mindepth 1 -maxdepth 1 -type d -exec test -f "{}/SKILL.md" \; -print \
    | wc -l \
    | tr -d ' '
)

manifest_skill_count=$(
  awk '
    /"skill":[[:space:]]*\{/ { in_skill=1; next }
    in_skill && /^[[:space:]]*\}/ { print count; exit }
    in_skill && /"[[:alnum:]-]+":[[:space:]]*"/ { count++ }
  ' manifest.json
)

[[ "$skill_count" == "1" ]] || fail "expected 1 installable skill (etyb), found $skill_count"
[[ "$manifest_skill_count" == "1" ]] || fail "manifest.json .skill must contain exactly one entry, found $manifest_skill_count"

# Internal reference libraries — verify each has the expected count.
specialist_count=$(find skills/etyb/references/specialists -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
protocol_count=$(find skills/etyb/references/protocols -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
vertical_count=$(find skills/etyb/references/verticals -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')

[[ "$specialist_count" == "14" ]] || fail "expected 14 specialist references, found $specialist_count"
[[ "$protocol_count" == "9" ]] || fail "expected 9 protocol references, found $protocol_count"
[[ "$vertical_count" == "6" ]] || fail "expected 6 vertical references, found $vertical_count"

# Every reference must have a README.md (the v4 equivalent of SKILL.md body).
while IFS= read -r ref_dir; do
  require_file "$ref_dir/README.md"
done < <(find skills/etyb/references/specialists skills/etyb/references/protocols skills/etyb/references/verticals -mindepth 1 -maxdepth 1 -type d | sort)

# Every reference should also have an openai.yaml under agents/ for Codex.
metadata_count=$(
  find skills/etyb/references -type f -path "*/agents/openai.yaml" \
    | wc -l \
    | tr -d ' '
)
expected_metadata=$((specialist_count + protocol_count + vertical_count))
[[ "$metadata_count" == "$expected_metadata" ]] \
  || fail "openai.yaml count ($metadata_count) does not match reference count ($expected_metadata)"

while IFS= read -r metadata_file; do
  grep -q "^interface:" "$metadata_file" || fail "missing interface block in $metadata_file"
  grep -q "allow_implicit_invocation: true" "$metadata_file" || fail "missing allow_implicit_invocation=true in $metadata_file"
done < <(find skills/etyb/references -type f -path "*/agents/openai.yaml" | sort)

# Codex runtime assets.
require_file ".codex/config.toml"
require_file ".codex/hooks.json"
require_file ".codex/hooks/common.py"
require_file ".codex/hooks/user_prompt_submit.py"
require_file ".codex/hooks/pre_tool_use.py"
require_file ".codex/hooks/post_tool_use.py"
require_file ".codex/hooks/stop.py"
require_file ".codex/agents/etyb_explorer.toml"
require_file ".codex/agents/etyb_planner.toml"
require_file ".codex/agents/etyb_reviewer.toml"
require_file ".codex/agents/etyb_docs_researcher.toml"

[[ -x "scripts/install-codex-runtime.sh" ]] || fail "scripts/install-codex-runtime.sh must be executable"
[[ -x "scripts/lint-portability.sh" ]] || fail "scripts/lint-portability.sh must be executable"
[[ -x "scripts/install.sh" ]] || fail "scripts/install.sh must be executable"

# Generic protocol references must not hardcode platform-specific paths.
protocol_files=(
  "skills/etyb/references/protocols/subagent-protocol/README.md"
  "skills/etyb/references/protocols/plan-execution-protocol/README.md"
  "skills/etyb/references/protocols/review-protocol/README.md"
  "skills/etyb/references/protocols/git-workflow-protocol/README.md"
)

if rg -n "\\.claude/plans/" "${protocol_files[@]}" >/dev/null; then
  fail "generic protocol references still hardcode .claude/plans/"
fi

if rg -n "active Claude plan" skills/etyb/references >/dev/null; then
  fail "internal references still treat Claude-native plans as the generic default"
fi

if rg -n "Claude Code Agent tool|Claude Code's Agent tool|DISPATCH via Agent tool|When using Claude Code's Agent tool" \
  "skills/etyb/references/protocols/subagent-protocol/README.md" \
  "skills/etyb/references/protocols/subagent-protocol/references/dispatch-patterns.md" >/dev/null; then
  fail "generic subagent protocol still hardcodes Claude Agent-tool mechanics"
fi

if rg -n "compatibility: Designed for Claude Code and compatible AI coding agents" skills/etyb/SKILL.md >/dev/null; then
  fail "etyb SKILL.md still uses the old compatibility string"
fi

if rg -n "model-trusted only" README.md docs skills/etyb manifest.json CHANGELOG.md >/dev/null; then
  fail "Codex is still described as model-trusted only"
fi

# v3-era skill-count claims must not survive into v4 docs.
if rg -n "30 coordinated skills|30 skills|all 30 skills|should list 30 skills|30 total skills|31 coordinated skills|31 skills|all 31 skills|31 total skills" \
  README.md package.json CHANGELOG.md docs 2>/dev/null | rg -v "^.*\.md:.*v3\.0\.0|was: 30 skills" >/dev/null; then
  fail "repo docs still claim 30/31 installable skills (v4 ships 1 skill with internal references)"
fi

grep -q "partial runtime-enforced" manifest.json || fail "manifest.json missing Codex partial runtime-enforced wording"
grep -q "markdown-first" manifest.json || fail "manifest.json missing Antigravity markdown-first wording"

# v4 tier system must be declared in manifest.
grep -q '"tiers"' manifest.json || fail "manifest.json missing v4 tiers block"
for tier in lite core pro; do
  grep -q "\"$tier\"" manifest.json || fail "manifest.json missing tier: $tier"
done

# The five Claude hooks must point at the v4 reference paths.
hook_paths=(
  "skills/etyb/references/protocols/tdd-protocol/hooks/pre-edit-check.sh"
  "skills/etyb/references/protocols/tdd-protocol/hooks/post-test-log.sh"
  "skills/etyb/references/protocols/git-workflow-protocol/hooks/pre-merge-verify.sh"
  "skills/etyb/references/protocols/review-protocol/hooks/pre-commit-review-check.sh"
  "skills/etyb/references/protocols/plan-execution-protocol/hooks/post-edit-log.sh"
)
for hook in "${hook_paths[@]}"; do
  require_file "$hook"
  grep -q "$hook" .claude/settings.json || fail ".claude/settings.json does not wire up $hook"
done

echo "✓ portability lint passed"
