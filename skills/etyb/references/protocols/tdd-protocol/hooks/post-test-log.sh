#!/bin/bash
# Post-test hook: log test execution results
# This fires after any test command runs
#
# Purpose: Capture test pass/fail results with timestamps to provide
# verification evidence that TDD cycles were followed.
#
# Usage: post-test-log.sh <exit_code> [test_command]
#
# The log is written to .tdd-protocol/test-log.jsonl in the project root.
# Each line is a JSON object with timestamp, result, and command.
#
# Exit codes:
#   0 — always (logging should never block the workflow)

set -uo pipefail

EXIT_CODE="${1:-unknown}"
TEST_COMMAND="${2:-unknown}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Determine result
if [ "$EXIT_CODE" = "0" ]; then
  RESULT="pass"
else
  RESULT="fail"
fi

# Find project root (look for .git directory)
PROJECT_ROOT="."
CURRENT_DIR=$(pwd)
while [ "$CURRENT_DIR" != "/" ]; do
  if [ -d "${CURRENT_DIR}/.git" ]; then
    PROJECT_ROOT="$CURRENT_DIR"
    break
  fi
  CURRENT_DIR=$(dirname "$CURRENT_DIR")
done

# Create log directory
LOG_DIR="${PROJECT_ROOT}/.tdd-protocol"
LOG_FILE="${LOG_DIR}/test-log.jsonl"

mkdir -p "$LOG_DIR" 2>/dev/null || true

# Append log entry (JSON Lines format)
cat >> "$LOG_FILE" 2>/dev/null <<EOF
{"timestamp":"${TIMESTAMP}","result":"${RESULT}","exit_code":${EXIT_CODE},"command":"${TEST_COMMAND}"}
EOF

# Print summary to stdout
if [ "$RESULT" = "pass" ]; then
  echo "[TDD] Tests PASSED at ${TIMESTAMP}"
else
  echo "[TDD] Tests FAILED at ${TIMESTAMP} (exit code: ${EXIT_CODE})"
fi

# Print cycle stats if log has entries
if [ -f "$LOG_FILE" ]; then
  TOTAL=$(wc -l < "$LOG_FILE" | tr -d ' ')
  PASSES=$(grep -c '"result":"pass"' "$LOG_FILE" 2>/dev/null || echo 0)
  FAILS=$(grep -c '"result":"fail"' "$LOG_FILE" 2>/dev/null || echo 0)
  echo "[TDD] Session stats: ${TOTAL} runs (${PASSES} pass, ${FAILS} fail)"
fi

exit 0
