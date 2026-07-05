#!/usr/bin/env bash
# Post-edit hook: log file edits for plan task traceability
# Claude Code hook contract: PostToolUse (matcher Edit|Write).
#
# Reads the hook payload JSON from stdin and extracts:
#   .tool_input.file_path — the file that was edited/written
#   .cwd                  — project directory for the log root
#
# Purpose: Capture which files were edited, when, and in what context.
# Creates a traceability trail from plan task to code change, so you can
# always answer "which task caused this edit?". Task/plan context comes
# from the ETYB_TASK_ID / ETYB_PLAN_NAME environment variables when set.
#
# The log is written to .etyb/edit-log.jsonl under the session cwd.
# Each line is a JSON object with timestamp, file, task, and plan —
# built with jq, so hostile file names cannot corrupt the log or forge
# entries (JSON-injection fix preserved from the argv-era script).
#
# Output: {"systemMessage": "..."} on stdout only when the payload is
# malformed (no file_path) and the edit could not be logged; nothing
# otherwise (advisory, non-blocking feedback shape).
#
# Exit codes:
#   0 — always (logging should never block the workflow)

set -uo pipefail

# Graceful degradation: without jq the payload cannot be parsed.
# Advisory hooks must never break the session — exit 0 silently.
command -v jq >/dev/null 2>&1 || exit 0

payload=$(cat)

emit_warning() {
  jq -n --arg msg "$1" '{systemMessage: $msg}'
}

FILE_PATH=$(jq -r '.tool_input.file_path // empty' <<<"$payload" 2>/dev/null) || FILE_PATH=""

if [ -z "$FILE_PATH" ]; then
  emit_warning "[plan-execution] post-edit-log fired but the payload carried no tool_input.file_path — this edit was not logged, so the plan traceability trail has a gap."
  exit 0
fi

TASK_ID="${ETYB_TASK_ID:-unknown}"
PLAN_NAME="${ETYB_PLAN_NAME:-unknown}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Log root: the session cwd from the payload, falling back to $PWD.
CWD=$(jq -r '.cwd // empty' <<<"$payload" 2>/dev/null) || CWD=""
if [ -z "$CWD" ] || [ ! -d "$CWD" ]; then
  CWD=$PWD
fi

LOG_DIR="${CWD}/.etyb"
LOG_FILE="${LOG_DIR}/edit-log.jsonl"

mkdir -p "$LOG_DIR" 2>/dev/null || exit 0

# Make file path relative to the log root for cleaner logs
RELATIVE_PATH="$FILE_PATH"
case "$FILE_PATH" in
  "$CWD"/*)
    RELATIVE_PATH="${FILE_PATH#"$CWD"/}"
    ;;
esac

# Append log entry (JSON Lines format); jq handles all string escaping,
# so filenames containing quotes, newlines, or backslashes cannot corrupt
# the log or forge additional entries.
jq -cn \
  --arg ts "$TIMESTAMP" \
  --arg file "$RELATIVE_PATH" \
  --arg task "$TASK_ID" \
  --arg plan "$PLAN_NAME" \
  '{timestamp: $ts, file: $file, task: $task, plan: $plan}' \
  >> "$LOG_FILE" 2>/dev/null

exit 0
