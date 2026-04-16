#!/usr/bin/env bash
#
# Cross-platform portability checks for ETYB skills.

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

skill_count=$(
  find skills -mindepth 1 -maxdepth 1 -type d -exec test -f "{}/SKILL.md" \; -print \
    | wc -l \
    | tr -d ' '
)

manifest_count=$(
  awk '
    /"skills":[[:space:]]*\{/ { in_skills=1; next }
    in_skills && /^[[:space:]]*\}/ { print count; exit }
    in_skills && /"[[:alnum:]-]+":[[:space:]]*"/ { count++ }
  ' manifest.json
)

metadata_count=$(
  find skills -mindepth 3 -maxdepth 3 -type f -path "*/agents/openai.yaml" \
    | wc -l \
    | tr -d ' '
)

[[ "$skill_count" == "30" ]] || fail "expected 30 installable skills, found $skill_count"
[[ "$manifest_count" == "$skill_count" ]] || fail "manifest skill count ($manifest_count) does not match repo skill count ($skill_count)"
[[ "$metadata_count" == "$skill_count" ]] || fail "openai.yaml count ($metadata_count) does not match repo skill count ($skill_count)"

while IFS= read -r skill_dir; do
  metadata_file="$skill_dir/agents/openai.yaml"
  require_file "$metadata_file"
  grep -q "^interface:" "$metadata_file" || fail "missing interface block in $metadata_file"
  grep -q "allow_implicit_invocation: true" "$metadata_file" || fail "missing allow_implicit_invocation=true in $metadata_file"
done < <(find skills -mindepth 1 -maxdepth 1 -type d -exec test -f "{}/SKILL.md" \; -print | sort)

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
require_file "skills/etyb/evals/codex-runtime-evals.json"
require_file "skills/etyb/evals/antigravity-runtime-evals.json"

[[ -x "scripts/install-codex-runtime.sh" ]] || fail "scripts/install-codex-runtime.sh must be executable"
[[ -x "scripts/lint-portability.sh" ]] || fail "scripts/lint-portability.sh must be executable"

protocol_files=(
  "skills/subagent-protocol/SKILL.md"
  "skills/plan-execution-protocol/SKILL.md"
  "skills/review-protocol/SKILL.md"
  "skills/git-workflow-protocol/SKILL.md"
)

if rg -n "\\.claude/plans/" "${protocol_files[@]}" >/dev/null; then
  fail "generic protocol skills still hardcode .claude/plans/"
fi

if rg -n "active Claude plan" skills/*/SKILL.md >/dev/null; then
  fail "top-level skill docs still treat Claude-native plans as the generic default"
fi

if rg -n "Claude Code Agent tool|Claude Code's Agent tool|DISPATCH via Agent tool|When using Claude Code's Agent tool" \
  "skills/subagent-protocol/SKILL.md" \
  "skills/subagent-protocol/references/dispatch-patterns.md" >/dev/null; then
  fail "generic subagent protocol still hardcodes Claude Agent-tool mechanics"
fi

if rg -n "compatibility: Designed for Claude Code and compatible AI coding agents" skills/*/SKILL.md >/dev/null; then
  fail "top-level skills still use the old compatibility string"
fi

if rg -n "model-trusted only" README.md docs skills/etyb manifest.json CHANGELOG.md >/dev/null; then
  fail "Codex is still described as model-trusted only"
fi

if rg -n "31 coordinated skills|31 skills|all 31 skills|should list 31 skills|31 total skills|Total skill count: 29 → 31|31 total skills" \
  README.md docs package.json CHANGELOG.md >/dev/null; then
  fail "repo docs still claim 31 installable skills"
fi

grep -q "partial runtime-enforced" manifest.json || fail "manifest.json missing Codex partial runtime-enforced wording"
grep -q "markdown-first" manifest.json || fail "manifest.json missing Antigravity markdown-first wording"

echo "✓ portability lint passed"
