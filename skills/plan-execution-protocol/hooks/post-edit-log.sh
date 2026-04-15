#!/bin/bash
# Post-edit hook: log file edits for plan task traceability
# This fires after any Edit tool use
#
# Purpose: Capture which files were edited, when, and in what context.
# Creates a traceability trail from plan task to code change, so you can
# always answer "which task caused this edit?"
#
# Usage: post-edit-log.sh <file_path> [task_id] [plan_name]
#
# The log is written to .plan-execution/edit-log.jsonl in the project root.
# Each line is a JSON object with timestamp, file, task, and plan.
#
# Exit codes:
#   0 — always (logging should never block the workflow)

set -uo pipefail

FILE_PATH="${1:-unknown}"
TASK_ID="${2:-unknown}"
PLAN_NAME="${3:-unknown}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

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
LOG_DIR="${PROJECT_ROOT}/.plan-execution"
LOG_FILE="${LOG_DIR}/edit-log.jsonl"

mkdir -p "$LOG_DIR" 2>/dev/null || true

# Make file path relative to project root for cleaner logs
RELATIVE_PATH="${FILE_PATH}"
if [[ "$FILE_PATH" == "$PROJECT_ROOT"* ]]; then
  RELATIVE_PATH="${FILE_PATH#$PROJECT_ROOT/}"
fi

# Append log entry (JSON Lines format)
cat >> "$LOG_FILE" 2>/dev/null <<EOF
{"timestamp":"${TIMESTAMP}","file":"${RELATIVE_PATH}","task":"${TASK_ID}","plan":"${PLAN_NAME}"}
EOF

# Print confirmation to stdout
echo "[Plan Execution] Edit logged: ${RELATIVE_PATH} (task: ${TASK_ID}, plan: ${PLAN_NAME}) at ${TIMESTAMP}"

# Print session stats if log has entries
if [ -f "$LOG_FILE" ]; then
  TOTAL=$(wc -l < "$LOG_FILE" | tr -d ' ')
  UNIQUE_FILES=$(cut -d'"' -f4 "$LOG_FILE" 2>/dev/null | sort -u | wc -l | tr -d ' ')
  echo "[Plan Execution] Session stats: ${TOTAL} edits across ${UNIQUE_FILES} unique files"
fi

exit 0
