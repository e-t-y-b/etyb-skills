#!/bin/bash
# Pre-merge hook: verify tests pass before allowing merge
#
# This hook runs the project's test suite and blocks the merge if any tests fail.
# Install by copying to .git/hooks/pre-merge-commit or by configuring core.hooksPath.
#
# Usage:
#   cp hooks/pre-merge-verify.sh .git/hooks/pre-merge-commit
#   chmod +x .git/hooks/pre-merge-commit

set -euo pipefail

echo "========================================"
echo "  PRE-MERGE VERIFICATION"
echo "  Running test suite before merge..."
echo "========================================"
echo ""

# Detect test runner
detect_test_command() {
  if [ -f "package.json" ]; then
    if command -v pnpm &>/dev/null && [ -f "pnpm-lock.yaml" ]; then
      echo "pnpm test"
    elif command -v yarn &>/dev/null && [ -f "yarn.lock" ]; then
      echo "yarn test"
    elif command -v bun &>/dev/null && [ -f "bun.lockb" ]; then
      echo "bun test"
    else
      echo "npm test"
    fi
  elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || [ -f "setup.cfg" ]; then
    echo "pytest"
  elif [ -f "Cargo.toml" ]; then
    echo "cargo test"
  elif [ -f "go.mod" ]; then
    echo "go test ./..."
  elif [ -f "Gemfile" ]; then
    echo "bundle exec rspec"
  elif [ -f "mix.exs" ]; then
    echo "mix test"
  elif [ -f "Makefile" ] && grep -q "^test:" Makefile; then
    echo "make test"
  else
    echo ""
  fi
}

TEST_CMD=$(detect_test_command)

if [ -z "$TEST_CMD" ]; then
  echo "WARNING: Could not detect test runner."
  echo "No test command found. Skipping pre-merge verification."
  echo "To enforce testing, set a 'test' script in your package.json or project config."
  exit 0
fi

echo "Test command: $TEST_CMD"
echo ""

# Run tests
if eval "$TEST_CMD"; then
  echo ""
  echo "========================================"
  echo "  TESTS PASSED — merge allowed"
  echo "========================================"
  exit 0
else
  echo ""
  echo "========================================"
  echo "  ERROR: TESTS FAILED — merge blocked"
  echo "========================================"
  echo ""
  echo "Fix failing tests before merging."
  echo "Run '$TEST_CMD' to see failures."
  echo ""
  echo "To bypass this hook (NOT RECOMMENDED):"
  echo "  git merge --no-verify"
  echo ""
  exit 1
fi
