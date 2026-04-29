#!/usr/bin/env bash
#
# Heuristic check: if a PR touches user-visible surfaces (skills/ or
# top-level docs) but does not also update CHANGELOG.md, fail.
#
# Pure tooling/CI/test diffs are exempted (warned, not failed).
#
# Diff base defaults to origin/main and can be overridden:
#   BASE=origin/main ./scripts/maintainer/validate-changelog.sh
#
# Skipped entirely when there is no diff base reachable (e.g. a
# checkout without origin), to avoid breaking local runs on a
# detached state.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

BASE="${BASE:-origin/main}"

if ! git rev-parse --verify "$BASE" >/dev/null 2>&1; then
  echo "⚠ validate-changelog: base '$BASE' not reachable, skipping"
  exit 0
fi

merge_base="$(git merge-base "$BASE" HEAD 2>/dev/null || true)"
if [[ -z "$merge_base" ]]; then
  echo "⚠ validate-changelog: no merge-base with '$BASE', skipping"
  exit 0
fi

changed="$(git diff --name-only "$merge_base"...HEAD || true)"
if [[ -z "$changed" ]]; then
  echo "✓ validate-changelog: no diff vs $BASE"
  exit 0
fi

user_visible=0
tooling_only=1
while IFS= read -r path; do
  case "$path" in
    skills/*|README.md|manifest.json|.claude-plugin/*|VERSION|package.json)
      user_visible=1
      tooling_only=0
      ;;
    scripts/*|tests/*|.github/*|.gitignore|CLAUDE.md|CONTRIBUTING.md|CODE_OF_CONDUCT.md|SECURITY.md|MARKETPLACE.md|docs/*|.claude/*|.codex/*)
      ;;
    *)
      tooling_only=0
      ;;
  esac
done <<<"$changed"

if [[ $user_visible -eq 0 ]]; then
  if [[ $tooling_only -eq 1 ]]; then
    echo "✓ validate-changelog: tooling-only diff, CHANGELOG entry not required"
  else
    echo "✓ validate-changelog: no user-visible surfaces touched"
  fi
  exit 0
fi

if grep -qx "CHANGELOG.md" <<<"$changed"; then
  echo "✓ validate-changelog: CHANGELOG.md updated alongside user-visible changes"
  exit 0
fi

{
  echo "✗ validate-changelog: user-visible files changed but CHANGELOG.md was not updated."
  echo "  Touched paths that triggered this:"
  while IFS= read -r path; do
    case "$path" in
      skills/*|README.md|manifest.json|.claude-plugin/*|VERSION|package.json)
        echo "    $path"
        ;;
    esac
  done <<<"$changed"
  echo "  Add a section under '## [Unreleased]' or the next version in CHANGELOG.md."
} >&2
exit 1
