#!/usr/bin/env bash
#
# Umbrella validator for etyb-skills PRs.
#
# Run before opening a PR:
#   ./scripts/maintainer/validate-pr.sh
# Or against a specific base:
#   BASE=origin/main ./scripts/maintainer/validate-pr.sh
#
# CI runs the same script in .github/workflows/ci.yml (maintainer-checks).

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 1

CHECKS=(
  "scripts/maintainer/validate-frontmatter.sh"
  "scripts/maintainer/validate-toc.py"
  "scripts/maintainer/validate-version-sync.sh"
  "scripts/maintainer/validate-skill-manifest-sync.sh"
  "scripts/maintainer/validate-changelog.sh"
)

failed=0
for check in "${CHECKS[@]}"; do
  echo "── $check"
  if [[ "$check" == *.py ]]; then
    if ! python3 "$check"; then
      failed=$((failed + 1))
    fi
  else
    if ! bash "$check"; then
      failed=$((failed + 1))
    fi
  fi
done

echo
if [[ $failed -gt 0 ]]; then
  echo "✗ $failed maintainer check(s) failed" >&2
  exit 1
fi
echo "✓ all maintainer checks passed"
