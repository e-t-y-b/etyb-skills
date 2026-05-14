#!/bin/bash
# Pre-edit hook: warn if editing source without corresponding test file
# This fires before any Edit tool use
#
# Purpose: Provide a soft warning when a source file is being edited
# but no corresponding test file exists. The LLM instructions do the
# actual TDD enforcement — this hook provides visibility.
#
# Exit codes:
#   0 — always (this is a warning, not a blocker)

set -euo pipefail

FILE_PATH="${1:-}"

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Get the filename and directory
FILENAME=$(basename "$FILE_PATH")
DIRNAME=$(dirname "$FILE_PATH")
EXTENSION="${FILENAME##*.}"
BASENAME="${FILENAME%.*}"

# Skip if this IS a test file
case "$FILENAME" in
  *.test.* | *.spec.* | *_test.* | *_spec.* | test_* | *Test.* | *Tests.*)
    exit 0
    ;;
esac

# Skip non-source files (config, docs, assets, etc.)
case "$EXTENSION" in
  md|json|yaml|yml|toml|xml|html|css|scss|svg|png|jpg|gif|ico|lock|env|sh)
    exit 0
    ;;
esac

# Skip common non-source paths
case "$FILE_PATH" in
  *node_modules* | *vendor* | *dist* | *build* | *coverage* | *.git/*)
    exit 0
    ;;
  *__pycache__* | *.egg-info* | *target/debug* | *target/release*)
    exit 0
    ;;
esac

# Skip config/setup files. Patterns collapsed into one arm because every
# arm exits 0 — earlier glob entries (like *.config.*) were silently
# shadowing later explicit entries (jest.config.*, vitest.config.*).
case "$FILENAME" in
  *.config.* | *.setup.* | *.d.ts | Dockerfile* | Makefile \
  | package.json | tsconfig.json | .eslintrc* \
  | conftest.py | setup.py | setup.cfg | pyproject.toml \
  | *.mod | *.sum \
  | Cargo.toml | Cargo.lock | pom.xml | build.gradle* | settings.gradle*)
    exit 0
    ;;
esac

# Determine likely test file patterns based on language
TEST_EXISTS=false

case "$EXTENSION" in
  ts|tsx|js|jsx)
    # JavaScript/TypeScript: look for .test.ts, .spec.ts, __tests__/
    for TEST_PATTERN in \
      "${DIRNAME}/${BASENAME}.test.${EXTENSION}" \
      "${DIRNAME}/${BASENAME}.spec.${EXTENSION}" \
      "${DIRNAME}/__tests__/${BASENAME}.test.${EXTENSION}" \
      "${DIRNAME}/__tests__/${BASENAME}.spec.${EXTENSION}" \
      "${DIRNAME}/../__tests__/${BASENAME}.test.${EXTENSION}"; do
      if [ -f "$TEST_PATTERN" ]; then
        TEST_EXISTS=true
        break
      fi
    done
    ;;
  py)
    # Python: look for test_*.py, *_test.py, tests/test_*.py
    for TEST_PATTERN in \
      "${DIRNAME}/test_${BASENAME}.py" \
      "${DIRNAME}/${BASENAME}_test.py" \
      "${DIRNAME}/tests/test_${BASENAME}.py" \
      "${DIRNAME}/../tests/test_${BASENAME}.py"; do
      if [ -f "$TEST_PATTERN" ]; then
        TEST_EXISTS=true
        break
      fi
    done
    ;;
  go)
    # Go: look for *_test.go in same directory
    TEST_FILE="${DIRNAME}/${BASENAME}_test.go"
    if [ -f "$TEST_FILE" ]; then
      TEST_EXISTS=true
    fi
    ;;
  java|kt)
    # Java/Kotlin: look for *Test.java in parallel test directory
    # src/main/java/... -> src/test/java/...
    TEST_PATH="${FILE_PATH//src\/main\//src\/test\/}"
    TEST_FILE="${TEST_PATH/${BASENAME}.${EXTENSION}/${BASENAME}Test.${EXTENSION}}"
    if [ -f "$TEST_FILE" ]; then
      TEST_EXISTS=true
    fi
    ;;
  rs)
    # Rust: check for #[cfg(test)] in the same file, or tests/ directory
    if grep -q '#\[cfg(test)\]' "$FILE_PATH" 2>/dev/null; then
      TEST_EXISTS=true
    fi
    # Also check tests/ directory for integration tests
    PROJECT_ROOT="${FILE_PATH%%/src/*}"
    if [ -d "${PROJECT_ROOT}/tests" ]; then
      TEST_EXISTS=true
    fi
    ;;
esac

if [ "$TEST_EXISTS" = false ]; then
  echo "=========================================="
  echo "TDD WARNING: No test file found for:"
  echo "  $FILE_PATH"
  echo ""
  echo "TDD Protocol requires a failing test BEFORE"
  echo "writing production code. Consider:"
  echo "  1. Write a failing test first"
  echo "  2. Then edit this source file"
  echo "=========================================="
fi

exit 0
