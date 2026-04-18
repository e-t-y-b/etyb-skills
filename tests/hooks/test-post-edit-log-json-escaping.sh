#!/usr/bin/env bash
# Regression test for post-edit-log.sh JSON injection fix.
#
# The hook previously splatted attacker-controllable fields (file path,
# task ID, plan name) straight into a JSON heredoc with no escaping. A
# filename containing a double quote, backslash, or newline would corrupt
# the log or forge extra entries.
#
# This test runs the hook with hostile inputs and asserts that each line
# of the resulting edit-log.jsonl parses as well-formed JSON and that no
# injected fields leaked through.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK="$REPO_ROOT/skills/plan-execution-protocol/hooks/post-edit-log.sh"

if [[ ! -x "$HOOK" ]]; then
  echo "FAIL: hook script not executable at $HOOK" >&2
  exit 1
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cd "$TMPDIR"
git init -q

# Attack payloads: break out of the JSON string and attempt to forge fields.
EVIL_FILE='evil","injected":"true'
EVIL_TASK='task"with"quotes'
EVIL_PLAN=$'plan\nnewline-attack'

"$HOOK" "$EVIL_FILE" "$EVIL_TASK" "$EVIL_PLAN" >/dev/null

LOG=".plan-execution/edit-log.jsonl"
if [[ ! -f "$LOG" ]]; then
  echo "FAIL: hook did not write log file at $LOG" >&2
  exit 1
fi

# Every line must be valid JSON and must NOT contain an injected field.
python3 - "$LOG" <<'PY'
import json, sys
path = sys.argv[1]
with open(path) as f:
    for i, line in enumerate(f, 1):
        line = line.rstrip("\n")
        try:
            obj = json.loads(line)
        except json.JSONDecodeError as e:
            print(f"FAIL: line {i} not valid JSON: {e}", file=sys.stderr)
            print(f"  line: {line!r}", file=sys.stderr)
            sys.exit(1)
        # The raw attack payload "injected" must not appear as a real field.
        if "injected" in obj:
            print(f"FAIL: injected field leaked through: {obj!r}", file=sys.stderr)
            sys.exit(1)
        expected = {"timestamp", "file", "task", "plan"}
        if set(obj.keys()) != expected:
            print(f"FAIL: unexpected field set {set(obj.keys())} on line {i}", file=sys.stderr)
            sys.exit(1)
PY

echo "PASS: post-edit-log.sh rejects JSON injection"
