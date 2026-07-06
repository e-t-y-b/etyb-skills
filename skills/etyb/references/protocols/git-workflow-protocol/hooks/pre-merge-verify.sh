#!/usr/bin/env bash
# Pre-merge hook: warn on merges into protected branches without verify
# evidence.
# Claude Code hook contract: PreToolUse (matcher Bash, git merge commands).
#
# Reads the hook payload JSON from stdin and extracts:
#   .tool_input.command — only "git merge" commands are checked
#   .cwd                — repository directory to inspect
#
# Verify evidence = the most recent entry in .etyb/test-log.jsonl (written
# by the TDD protocol's post-test-log hook) records a passing test run.
# Merging into main/master/develop/release/* without that evidence draws
# a warning. The LLM instructions do the actual gate enforcement — this
# hook provides visibility.
#
# Output: {"systemMessage": "..."} on stdout when the warning fires;
# nothing otherwise (advisory, non-blocking feedback shape).
#
# Exit codes:
#   0 — always (advisory, never blocks the merge)

set -uo pipefail

# Graceful degradation: without jq the payload cannot be parsed.
# Advisory hooks must never break the session — exit 0 silently.
command -v jq >/dev/null 2>&1 || exit 0

payload=$(cat)

emit_warning() {
  jq -n --arg msg "$1" '{systemMessage: $msg}'
}

COMMAND=$(jq -r '.tool_input.command // empty' <<<"$payload" 2>/dev/null) || COMMAND=""

case "$COMMAND" in
  *"git merge"*) ;;
  *) exit 0 ;;
esac

CWD=$(jq -r '.cwd // empty' <<<"$payload" 2>/dev/null) || CWD=""
if [ -z "$CWD" ] || [ ! -d "$CWD" ]; then
  CWD=$PWD
fi
cd "$CWD" 2>/dev/null || exit 0

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# git merge merges INTO the currently checked-out branch.
BRANCH=$(git symbolic-ref --short -q HEAD 2>/dev/null) || BRANCH=""
if [ -z "$BRANCH" ]; then
  exit 0
fi

# Only guard protected branches.
case "$BRANCH" in
  main | master | develop | production | release/*) ;;
  *) exit 0 ;;
esac

# Verify evidence: the most recent logged test run must be a pass.
LOG_FILE=".etyb/test-log.jsonl"
if [ -f "$LOG_FILE" ]; then
  LAST_ENTRY=$(tail -n 1 "$LOG_FILE" 2>/dev/null) || LAST_ENTRY=""
  if [ -n "$LAST_ENTRY" ] \
    && jq -e '.result == "pass"' <<<"$LAST_ENTRY" >/dev/null 2>&1; then
    exit 0
  fi
fi

emit_warning "[git-workflow] Merging into protected branch '${BRANCH}' without verify evidence — no passing test run is recorded in .etyb/test-log.jsonl. Run the project's test suite (and let it be logged) before merging. Proceeding — this is a warning, not a block."

exit 0
