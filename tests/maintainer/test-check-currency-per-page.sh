#!/usr/bin/env bash
# Tests for the M3-T3 extensions to scripts/maintainer/check-currency.sh:
#
#   1. default mode: a stale page is a WARNING and the script exits 0
#      (warn-first CI rollout)
#   2. strict mode (CHECK_CURRENCY_STRICT=1): the same stale page is a
#      FAILURE and the script exits 1
#   3. batch-re-stamp detector: >100 pages sharing one last_verified_on
#      that is >7 days newer than their median git last-modified date is
#      flagged "batch re-stamp suspected" (warning in default mode,
#      failure in strict mode)
#   4. detector guard: with no usable git history the detector is skipped
#      with a warning instead of failing
#
# Fixtures are built in a throwaway git repo and pointed at via the
# CHECK_CURRENCY_ROOT test hook.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$REPO_ROOT/scripts/maintainer/check-currency.sh"

[[ -f "$SCRIPT" ]] || { echo "FAIL: script not found at $SCRIPT" >&2; exit 1; }

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

TODAY=$(python3 -c 'import datetime; print(datetime.date.today())')
STALE_DATE=$(python3 -c 'import datetime; print(datetime.date.today() - datetime.timedelta(days=200))')
OLD_COMMIT_DATE=$(python3 -c 'import datetime; print(datetime.date.today() - datetime.timedelta(days=60))')

fixture_commit() {
  # $1 = repo dir, $2 = committer date (YYYY-MM-DD)
  git -C "$1" add -A
  GIT_COMMITTER_DATE="${2}T12:00:00" GIT_AUTHOR_DATE="${2}T12:00:00" \
    git -C "$1" -c user.email=test@example.com -c user.name=test \
    commit -qm fixture
}

write_page() {
  # $1 = file, $2 = last_verified_on
  cat > "$1" <<EOF
---
title: Fixture page
product:
  name: Fixture
  drift_risk: high
  last_verified_on: "$2"
---
body
EOF
}

write_stack_skill() {
  # $1 = stack dir — SKILL.md fresh enough that the legacy stack check passes
  cat > "$1/SKILL.md" <<EOF
---
name: demo
stack:
  last_verified_on: "$TODAY"
products_covered:
  - { name: "Fixture", drift_risk: high }
---
demo stack
EOF
}

run_script() {
  # $1 = fixture root, $2 = strict (0/1); sets RC and OUT
  set +e
  OUT=$(CHECK_CURRENCY_ROOT="$1" CHECK_CURRENCY_STRICT="$2" bash "$SCRIPT" 2>&1)
  RC=$?
  set -e
}

# ---------- fixture A: one stale high-risk page ----------
FIX_A="$TMPDIR/a"
mkdir -p "$FIX_A/stacks/demo"
git -C "$FIX_A" init -q
write_stack_skill "$FIX_A/stacks/demo"
write_page "$FIX_A/stacks/demo/index.md" "$TODAY"
write_page "$FIX_A/stacks/demo/fresh.md" "$TODAY"
write_page "$FIX_A/stacks/demo/stale.md" "$STALE_DATE"
cat > "$FIX_A/manifest.json" <<EOF
{
  "stacks_pages": [
    {"path": "stacks/demo/SKILL.md", "last_verified_on": "$TODAY", "drift_risk": "high"},
    {"path": "stacks/demo/index.md", "last_verified_on": "$TODAY", "drift_risk": "high"},
    {"path": "stacks/demo/fresh.md", "last_verified_on": "$TODAY", "drift_risk": "high"},
    {"path": "stacks/demo/stale.md", "last_verified_on": "$STALE_DATE", "drift_risk": "high"}
  ]
}
EOF
fixture_commit "$FIX_A" "$TODAY"

# Test 1: default mode — stale page warns, exit 0
run_script "$FIX_A" 0
[[ $RC -eq 0 ]] || { echo "FAIL(1): default mode exited $RC, expected 0"; echo "$OUT"; exit 1; }
grep -q "⚠ page stacks/demo/stale.md: last_verified_on=$STALE_DATE" <<<"$OUT" \
  || { echo "FAIL(1): missing stale-page warning"; echo "$OUT"; exit 1; }
echo "PASS(1): default mode warns on stale page, exit 0"

# Test 2: strict mode — same stale page fails, exit 1
run_script "$FIX_A" 1
[[ $RC -eq 1 ]] || { echo "FAIL(2): strict mode exited $RC, expected 1"; echo "$OUT"; exit 1; }
grep -q "✗ page stacks/demo/stale.md: last_verified_on=$STALE_DATE" <<<"$OUT" \
  || { echo "FAIL(2): missing stale-page failure"; echo "$OUT"; exit 1; }
echo "PASS(2): strict mode fails on stale page, exit 1"

# ---------- fixture B: 150 pages batch-stamped today, committed 60 days ago ----------
FIX_B="$TMPDIR/b"
mkdir -p "$FIX_B/stacks/demo"
git -C "$FIX_B" init -q
write_stack_skill "$FIX_B/stacks/demo"
{
  echo '{'
  echo '  "stacks_pages": ['
  echo "    {\"path\": \"stacks/demo/SKILL.md\", \"last_verified_on\": \"$TODAY\", \"drift_risk\": \"high\"},"
  for i in $(seq 1 150); do
    write_page "$FIX_B/stacks/demo/page-$i.md" "$TODAY"
    sep=','; [[ $i -eq 150 ]] && sep=''
    echo "    {\"path\": \"stacks/demo/page-$i.md\", \"last_verified_on\": \"$TODAY\", \"drift_risk\": \"high\"}$sep"
  done
  echo '  ]'
  echo '}'
} > "$FIX_B/manifest.json"

# Test 4 (before committing): no git history -> detector skipped with warning
run_script "$FIX_B" 0
[[ $RC -eq 0 ]] || { echo "FAIL(4): no-history default mode exited $RC, expected 0"; echo "$OUT"; exit 1; }
grep -q "batch-re-stamp detector skipped" <<<"$OUT" \
  || { echo "FAIL(4): missing detector-skipped warning"; echo "$OUT"; exit 1; }
echo "PASS(4): detector skipped with warning when git log returns nothing"

fixture_commit "$FIX_B" "$OLD_COMMIT_DATE"

# Test 3a: default mode — batch re-stamp warns, exit 0
run_script "$FIX_B" 0
[[ $RC -eq 0 ]] || { echo "FAIL(3a): default mode exited $RC, expected 0"; echo "$OUT"; exit 1; }
# 151 = 150 product pages + the stack SKILL.md (also stamped $TODAY)
grep -q "⚠ batch re-stamp suspected: 151 pages share last_verified_on=$TODAY" <<<"$OUT" \
  || { echo "FAIL(3a): missing batch re-stamp warning"; echo "$OUT"; exit 1; }
echo "PASS(3a): default mode warns on batch re-stamp, exit 0"

# Test 3b: strict mode — batch re-stamp fails, exit 1
run_script "$FIX_B" 1
[[ $RC -eq 1 ]] || { echo "FAIL(3b): strict mode exited $RC, expected 1"; echo "$OUT"; exit 1; }
grep -q "✗ batch re-stamp suspected: 151 pages share last_verified_on=$TODAY" <<<"$OUT" \
  || { echo "FAIL(3b): missing batch re-stamp failure"; echo "$OUT"; exit 1; }
echo "PASS(3b): strict mode fails on batch re-stamp, exit 1"

echo "PASS: check-currency per-page + batch-stamp checks"
