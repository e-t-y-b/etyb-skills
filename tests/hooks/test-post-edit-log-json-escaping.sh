#!/usr/bin/env bash
# Regression test for post-edit-log.sh JSON injection fix.
#
# The argv-era hook once splatted attacker-controllable fields straight
# into a JSON heredoc with no escaping; a filename containing a double
# quote, backslash, or newline would corrupt the log or forge entries.
# The stdin-payload rewrite (M2-T3) builds log entries with jq, which
# must keep that guarantee.
#
# This test feeds the hook a Claude Code stdin payload with a hostile
# file path and asserts that every line of the resulting
# .etyb/edit-log.jsonl parses as well-formed JSON with exactly the
# expected fields and no injected ones.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/skills/etyb/references/protocols/plan-execution-protocol/hooks/post-edit-log.sh"

if [[ ! -x "$HOOK" ]]; then
  echo "FAIL: hook script not executable at $HOOK" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: jq not installed" >&2
  exit 0
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Attack payloads: break out of the JSON string and attempt to forge fields.
EVIL_FILE="$TMPDIR"'/evil","injected":"true'
EVIL_TASK='task"with"quotes'
EVIL_PLAN=$'plan\nnewline-attack'

jq -n --arg fp "$EVIL_FILE" --arg cwd "$TMPDIR" \
  '{hook_event_name: "PostToolUse", tool_name: "Write",
    tool_input: {file_path: $fp}, cwd: $cwd}' \
  | ETYB_TASK_ID="$EVIL_TASK" ETYB_PLAN_NAME="$EVIL_PLAN" bash "$HOOK" >/dev/null

LOG="$TMPDIR/.etyb/edit-log.jsonl"
if [[ ! -f "$LOG" ]]; then
  echo "FAIL: hook did not write log file at $LOG" >&2
  exit 1
fi

# Every line must be valid JSON, carry exactly the expected field set,
# and must NOT contain an injected field.
if ! jq -e . "$LOG" >/dev/null 2>&1; then
  echo "FAIL: log contains a line that is not valid JSON" >&2
  cat "$LOG" >&2
  exit 1
fi

if ! jq -e '(keys | sort) == ["file", "plan", "task", "timestamp"]' "$LOG" >/dev/null 2>&1; then
  echo "FAIL: unexpected field set in log entry" >&2
  cat "$LOG" >&2
  exit 1
fi

if jq -e 'has("injected")' "$LOG" >/dev/null 2>&1; then
  echo "FAIL: injected field leaked through" >&2
  cat "$LOG" >&2
  exit 1
fi

echo "PASS: post-edit-log.sh rejects JSON injection"
