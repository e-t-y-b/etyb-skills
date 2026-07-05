#!/usr/bin/env bash
# Post-test hook: log test execution results
# Claude Code hook contract: PostToolUse (matcher Bash).
#
# Reads the hook payload JSON from stdin and extracts:
#   .tool_input.command          — the Bash command that just ran
#   .tool_response.exit_code     — exit code, when the harness provides it
#   .tool_response.success       — boolean fallback when no exit code
#   .cwd                         — project directory for the log root
#
# Purpose: Capture test pass/fail results with timestamps to provide
# verification evidence that TDD cycles were followed. Non-test commands
# are ignored. The log is written to .etyb/test-log.jsonl under the
# session cwd; each line is a JSON object with timestamp, result,
# exit code, and command.
#
# Output: {"systemMessage": "..."} on stdout when a test run failed;
# nothing otherwise (advisory, non-blocking feedback shape).
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

COMMAND=$(jq -r '.tool_input.command // empty' <<<"$payload" 2>/dev/null) || COMMAND=""

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Only act on test-runner invocations; every other Bash command is a no-op.
# Note: *"npm test"* also covers "pnpm test", and *"go test"* also covers
# "cargo test" — the substring match subsumes them (SC2221/SC2222).
case "$COMMAND" in
  *pytest* | *"npm test"* | *"npm run test"* | *"yarn test"* \
  | *"bun test"* | *"go test"* \
  | *jest* | *vitest* | *rspec* | *"mix test"* | *"make test"* \
  | *phpunit* | *"gradlew test"* | *"bash tests/"*)
    ;;
  *)
    exit 0
    ;;
esac

# Exit code: prefer an explicit exit code field, fall back to the
# boolean success flag some tool_response shapes carry instead.
EXIT_CODE=$(jq -r '.tool_response.exit_code // .tool_response.exitCode // empty' <<<"$payload" 2>/dev/null) || EXIT_CODE=""
if [ -z "$EXIT_CODE" ]; then
  SUCCESS=$(jq -r '.tool_response.success // empty' <<<"$payload" 2>/dev/null) || SUCCESS=""
  case "$SUCCESS" in
    true)  EXIT_CODE=0 ;;
    false) EXIT_CODE=1 ;;
  esac
fi

if [ "$EXIT_CODE" = "0" ]; then
  RESULT="pass"
elif [ -n "$EXIT_CODE" ]; then
  RESULT="fail"
else
  RESULT="unknown"
fi

# Log root: the session cwd from the payload, falling back to $PWD.
CWD=$(jq -r '.cwd // empty' <<<"$payload" 2>/dev/null) || CWD=""
if [ -z "$CWD" ] || [ ! -d "$CWD" ]; then
  CWD=$PWD
fi

LOG_DIR="${CWD}/.etyb"
LOG_FILE="${LOG_DIR}/test-log.jsonl"

mkdir -p "$LOG_DIR" 2>/dev/null || exit 0

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Append log entry (JSON Lines format); jq handles all string escaping.
jq -cn \
  --arg ts "$TIMESTAMP" \
  --arg result "$RESULT" \
  --arg code "${EXIT_CODE:-unknown}" \
  --arg cmd "$COMMAND" \
  '{timestamp: $ts, result: $result, exit_code: $code, command: $cmd}' \
  >> "$LOG_FILE" 2>/dev/null

if [ "$RESULT" = "fail" ]; then
  emit_warning "[TDD] Test command failed (exit ${EXIT_CODE}) at ${TIMESTAMP}: ${COMMAND}. Red is expected mid-cycle — get back to green before claiming the step is done. Logged to .etyb/test-log.jsonl."
fi

exit 0
