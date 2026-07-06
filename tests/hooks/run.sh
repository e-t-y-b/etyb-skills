#!/usr/bin/env bash
# Test harness for the protocol hook scripts (M2-T3).
#
# Feeds fixture JSON payloads (tests/hooks/fixtures/*.json) to each hook
# on stdin — the Claude Code hook contract — and asserts:
#   * exit code is 0 on both the warning path and the clean path
#   * stdout contains {"systemMessage": ...} on the warning path
#   * stdout is free of systemMessage on the clean path
#   * loggers append valid JSON lines to .etyb/ logs
#   * every hook no-ops silently (exit 0, no output) when jq is missing
#
# Fixtures use the placeholder __CWD__, substituted at run time with a
# per-case sandbox directory.
#
# Usage: bash tests/hooks/run.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIXTURES="${REPO_ROOT}/tests/hooks/fixtures"
PROTOCOLS="${REPO_ROOT}/skills/etyb/references/protocols"

PRE_EDIT_CHECK="${PROTOCOLS}/tdd-protocol/hooks/pre-edit-check.sh"
POST_TEST_LOG="${PROTOCOLS}/tdd-protocol/hooks/post-test-log.sh"
PRE_COMMIT_REVIEW="${PROTOCOLS}/review-protocol/hooks/pre-commit-review-check.sh"
PRE_MERGE_VERIFY="${PROTOCOLS}/git-workflow-protocol/hooks/pre-merge-verify.sh"
POST_EDIT_LOG="${PROTOCOLS}/plan-execution-protocol/hooks/post-edit-log.sh"

command -v jq >/dev/null 2>&1 || { echo "SKIP: jq not installed — cannot run hook tests" >&2; exit 0; }

TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT

PASS=0
FAIL=0

ok()   { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

new_sandbox() {
  mktemp -d "${TMP_ROOT}/case-XXXXXX"
}

new_git_sandbox() {
  local sb
  sb=$(new_sandbox)
  git -C "$sb" init -q -b main
  git -C "$sb" -c user.email=etyb@test -c user.name=etyb \
    commit -qm "initial scaffolding" --allow-empty
  echo "$sb"
}

# run_case <label> <hook> <fixture> <sandbox> <warn|clean>
# Asserts exit 0 always, and systemMessage presence/absence on stdout.
run_case() {
  local label=$1 hook=$2 fixture=$3 sandbox=$4 expectation=$5
  local out code
  out=$(sed "s|__CWD__|${sandbox}|g" "${FIXTURES}/${fixture}" | bash "$hook")
  code=$?
  if [ "$code" -ne 0 ]; then
    fail "${label}: exit code ${code} (want 0)"
    return
  fi
  case "$expectation" in
    warn)
      if printf '%s' "$out" | grep -q '"systemMessage"'; then
        ok "$label"
      else
        fail "${label}: expected systemMessage on stdout, got: '${out}'"
      fi
      ;;
    clean)
      if printf '%s' "$out" | grep -q '"systemMessage"'; then
        fail "${label}: unexpected systemMessage on stdout: '${out}'"
      else
        ok "$label"
      fi
      ;;
  esac
}

# assert_valid_log <label> <log_file> <expected_line_count>
assert_valid_log() {
  local label=$1 log_file=$2 expected=$3
  if [ ! -f "$log_file" ]; then
    fail "${label}: log file ${log_file} not written"
    return
  fi
  local lines
  lines=$(wc -l < "$log_file" | tr -d ' ')
  if [ "$lines" != "$expected" ]; then
    fail "${label}: expected ${expected} log line(s), found ${lines}"
    return
  fi
  if jq -e . "$log_file" >/dev/null 2>&1; then
    ok "$label"
  else
    fail "${label}: log contains invalid JSON"
  fi
}

# ---------------------------------------------------------------- pre-edit-check
sb=$(new_sandbox)
mkdir -p "${sb}/src"
touch "${sb}/src/widget.ts"
run_case "pre-edit-check: source without test warns" \
  "$PRE_EDIT_CHECK" pre-edit-check-warn.json "$sb" warn

sb=$(new_sandbox)
mkdir -p "${sb}/src"
touch "${sb}/src/gadget.ts" "${sb}/src/gadget.test.ts"
run_case "pre-edit-check: source with sibling test is clean" \
  "$PRE_EDIT_CHECK" pre-edit-check-clean.json "$sb" clean

# ---------------------------------------------------------------- post-test-log
sb=$(new_sandbox)
run_case "post-test-log: failing test run warns" \
  "$POST_TEST_LOG" post-test-log-warn.json "$sb" warn
assert_valid_log "post-test-log: failing run appended to .etyb/test-log.jsonl" \
  "${sb}/.etyb/test-log.jsonl" 1

sb=$(new_sandbox)
run_case "post-test-log: passing test run is clean" \
  "$POST_TEST_LOG" post-test-log-clean.json "$sb" clean
assert_valid_log "post-test-log: passing run appended to .etyb/test-log.jsonl" \
  "${sb}/.etyb/test-log.jsonl" 1

# ------------------------------------------------------- pre-commit-review-check
sb=$(new_git_sandbox)
echo "feature" > "${sb}/feature.txt"
git -C "$sb" add feature.txt
run_case "pre-commit-review-check: staged commit without review evidence warns" \
  "$PRE_COMMIT_REVIEW" pre-commit-review-check-warn.json "$sb" warn

sb=$(new_git_sandbox)
echo "feature" > "${sb}/feature.txt"
git -C "$sb" add feature.txt
mkdir -p "${sb}/.etyb"
echo "review completed" > "${sb}/.etyb/review-completion-001.md"
run_case "pre-commit-review-check: review marker present is clean (Stop event)" \
  "$PRE_COMMIT_REVIEW" pre-commit-review-check-clean.json "$sb" clean

# ---------------------------------------------------------------- pre-merge-verify
sb=$(new_git_sandbox)
run_case "pre-merge-verify: merge into main without verify evidence warns" \
  "$PRE_MERGE_VERIFY" pre-merge-verify-warn.json "$sb" warn

sb=$(new_git_sandbox)
mkdir -p "${sb}/.etyb"
echo '{"timestamp":"2026-07-05T00:00:00Z","result":"pass","exit_code":"0","command":"npm test"}' \
  > "${sb}/.etyb/test-log.jsonl"
run_case "pre-merge-verify: merge into main with passing test log is clean" \
  "$PRE_MERGE_VERIFY" pre-merge-verify-clean.json "$sb" clean

# ---------------------------------------------------------------- post-edit-log
sb=$(new_sandbox)
run_case "post-edit-log: edit with file_path logs silently" \
  "$POST_EDIT_LOG" post-edit-log-clean.json "$sb" clean
assert_valid_log "post-edit-log: edit appended to .etyb/edit-log.jsonl" \
  "${sb}/.etyb/edit-log.jsonl" 1

sb=$(new_sandbox)
run_case "post-edit-log: payload without file_path warns" \
  "$POST_EDIT_LOG" post-edit-log-warn.json "$sb" warn

# JSON-injection regression: hostile filename must not corrupt the log.
sb=$(new_sandbox)
run_case "post-edit-log: hostile filename accepted silently" \
  "$POST_EDIT_LOG" post-edit-log-inject.json "$sb" clean
inject_log="${sb}/.etyb/edit-log.jsonl"
assert_valid_log "post-edit-log: hostile filename still yields valid JSON" \
  "$inject_log" 1
if [ -f "$inject_log" ] && jq -e 'has("injected")' "$inject_log" >/dev/null 2>&1; then
  fail "post-edit-log: injected field forged into the log"
else
  ok "post-edit-log: no forged fields in the log"
fi

# ---------------------------------------------------- graceful degradation: no jq
for hook in "$PRE_EDIT_CHECK" "$POST_TEST_LOG" "$PRE_COMMIT_REVIEW" \
            "$PRE_MERGE_VERIFY" "$POST_EDIT_LOG"; do
  # PATH is emptied so `command -v jq` fails inside the hook; invoke bash
  # by absolute path since the empty PATH hides it too.
  out=$(printf '{}' | PATH="/nonexistent" "$BASH" "$hook")
  code=$?
  if [ "$code" -eq 0 ] && [ -z "$out" ]; then
    ok "missing jq: $(basename "$hook") no-ops silently"
  else
    fail "missing jq: $(basename "$hook") exit=${code} out='${out}' (want exit 0, no output)"
  fi
done

# ------------------------------------------------------------------------ summary
echo ""
echo "hooks tests: ${PASS} passed, ${FAIL} failed"
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
