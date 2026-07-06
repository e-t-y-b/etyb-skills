#!/usr/bin/env bash
# pre-commit-review-check.sh
# Claude Code hook contract: PreToolUse (matcher Bash, git commit commands)
# or Stop (end-of-turn sweep with staged changes).
#
# Reads the hook payload JSON from stdin and extracts:
#   .hook_event_name    — "Stop" runs the check unconditionally
#   .tool_input.command — otherwise only "git commit" commands are checked
#   .cwd                — repository directory to inspect
#
# Warns if no review evidence exists before a commit. This is a WARNING,
# not a blocker — Tier 0-1 changes may legitimately skip review.
#
# Output: {"systemMessage": "..."} on stdout when the warning fires;
# nothing otherwise (advisory, non-blocking feedback shape).
#
# Exit codes:
#   0 — always (advisory, never blocks the commit)

set -uo pipefail

# Graceful degradation: without jq the payload cannot be parsed.
# Advisory hooks must never break the session — exit 0 silently.
command -v jq >/dev/null 2>&1 || exit 0

payload=$(cat)

emit_warning() {
  jq -n --arg msg "$1" '{systemMessage: $msg}'
}

EVENT=$(jq -r '.hook_event_name // empty' <<<"$payload" 2>/dev/null) || EVENT=""
COMMAND=$(jq -r '.tool_input.command // empty' <<<"$payload" 2>/dev/null) || COMMAND=""

# On Stop the check always runs; on PreToolUse only for git commit commands.
if [ "$EVENT" != "Stop" ]; then
  case "$COMMAND" in
    *"git commit"*) ;;
    *) exit 0 ;;
  esac
fi

CWD=$(jq -r '.cwd // empty' <<<"$payload" 2>/dev/null) || CWD=""
if [ -z "$CWD" ] || [ ! -d "$CWD" ]; then
  CWD=$PWD
fi
cd "$CWD" 2>/dev/null || exit 0

# Outside a git repo, or nothing staged: nothing to review-gate.
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
if git diff --cached --quiet 2>/dev/null; then
  exit 0
fi

# Review evidence markers — files or patterns that indicate a review was
# completed.
REVIEW_MARKERS=(
  ".etyb/review-completion-*.md"
  ".etyb/review-response-*.md"
  "review-completion.md"
  "REVIEW.md"
)

review_found=false

for marker in "${REVIEW_MARKERS[@]}"; do
  # Check if any matching files exist
  if compgen -G "$marker" > /dev/null 2>&1; then
    review_found=true
    break
  fi
done

# Also check if any staged files contain review completion markers
if ! $review_found; then
  staged_files=$(git diff --cached --name-only 2>/dev/null || true)
  if printf '%s\n' "$staged_files" | grep -qiE "review|review-completion|review-response" 2>/dev/null; then
    review_found=true
  fi
fi

# Also check recent git log messages for review evidence
if ! $review_found; then
  recent_messages=$(git log -5 --format="%s" 2>/dev/null || true)
  if printf '%s\n' "$recent_messages" | grep -qiE "review|reviewed|code review|review complete" 2>/dev/null; then
    review_found=true
  fi
fi

if ! $review_found; then
  emit_warning "[review-protocol] No review evidence detected before commit. Code review is mandatory for Tier 2+ changes at the Verify gate; a Tier 0-1 change may ignore this. To request one, use the review-protocol skill to dispatch code-reviewer with focused context before committing. Proceeding — this is a warning, not a block."
fi

# Always allow the commit — this is advisory, not blocking
exit 0
