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

# One orchestrator skill (etyb) plus thin etyb-* role skills (v5 M2-T2).
# Specialists, protocols, and verticals live as internal references under etyb.
skill_dirs=$(
  find skills -mindepth 1 -maxdepth 1 -type d -exec test -f "{}/SKILL.md" \; -print \
    | sed 's|^skills/||' \
    | sort
)

manifest_skill_count=$(
  awk '
    /"skill":[[:space:]]*\{/ { in_skill=1; next }
    in_skill && /^[[:space:]]*\}/ { print count; exit }
    in_skill && /"[[:alnum:]-]+":[[:space:]]*"/ { count++ }
  ' manifest.json
)

grep -qx 'etyb' <<<"$skill_dirs" || fail "skills/etyb (the orchestrator skill) is missing"
if grep -vx 'etyb' <<<"$skill_dirs" | grep -qvE '^etyb-[a-z][a-z-]*$'; then
  fail "skills/ may only contain etyb and etyb-* role skills, found: $skill_dirs"
fi
[[ "$manifest_skill_count" == "1" ]] || fail "manifest.json .skill must contain exactly one entry, found $manifest_skill_count"

# Role skills stay portable in the shared tree: Claude-only frontmatter
# (context: fork, agent: ...) lives in adapters/claude/overlays/ and is
# merged only into emitted plugin copies by the adapter generator (M2-T5).
while IFS= read -r role_dir; do
  if rg -n "^(context|agent):" "$role_dir/SKILL.md" >/dev/null; then
    fail "$role_dir/SKILL.md carries Claude-only frontmatter (context:/agent:) — move it to skills/etyb/adapters/claude/overlays/"
  fi
  require_file "skills/etyb/adapters/claude/overlays/$(basename "$role_dir").yaml"
done < <(find skills -mindepth 1 -maxdepth 1 -type d -name 'etyb-*' | sort)

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
require_file ".codex/agents/etyb_stack_researcher.toml" ".codex/agents/etyb_cartographer.toml"

[[ -x "scripts/lint-portability.sh" ]] || fail "scripts/lint-portability.sh must be executable"

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
# Carve-outs: historical CHANGELOG entries (v2/v3-era release notes may say
# "30 skills" legitimately) and docs/plan/ (specs that quote stale claims in
# order to schedule their removal).
if rg -n "30 coordinated skills|30 skills|all 30 skills|should list 30 skills|30 total skills|31 coordinated skills|31 skills|all 31 skills|31 total skills" \
  --glob '!docs/plan/**' \
  README.md package.json CHANGELOG.md docs 2>/dev/null \
  | rg -v "^.*\.md:.*v3\.0\.0|was: 30 skills|alongside the existing 30 skills|All 30 skills now ship" >/dev/null; then
  fail "repo docs still claim 30/31 installable skills (v4 ships 1 skill with internal references)"
fi

grep -q "partial runtime-enforced" manifest.json || fail "manifest.json missing Codex partial runtime-enforced wording"
grep -q "markdown-first" manifest.json || fail "manifest.json missing Antigravity markdown-first wording"

# v4.0 — tier system removed. Manifest must NOT carry tiers.
if grep -q '"tiers"' manifest.json; then
  fail "manifest.json still has v4-pre tiers block (removed in v4.0.0 final)"
fi
if grep -q "available_on_tiers" manifest.json; then
  fail "manifest.json stack entries still carry available_on_tiers (removed in v4.0.0 final)"
fi

# The five hook scripts must exist. Wiring is NOT checked here: the v4
# .claude/settings.json wiring never shipped, so that check could never pass.
# M2-T4 ships plugin hooks/hooks.json — when it lands, re-add per-hook:
#   grep -q "$hook" hooks/hooks.json || fail "hooks.json does not wire $hook"
hook_paths=(
  "skills/etyb/references/protocols/tdd-protocol/hooks/pre-edit-check.sh"
  "skills/etyb/references/protocols/tdd-protocol/hooks/post-test-log.sh"
  "skills/etyb/references/protocols/git-workflow-protocol/hooks/pre-merge-verify.sh"
  "skills/etyb/references/protocols/review-protocol/hooks/pre-commit-review-check.sh"
  "skills/etyb/references/protocols/plan-execution-protocol/hooks/post-edit-log.sh"
)
for hook in "${hook_paths[@]}"; do
  require_file "$hook"
done

echo "✓ portability lint passed"
