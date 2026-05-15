#!/usr/bin/env bash
# Tests for scripts/install.sh flag handling (v4 — tier system removed).
#
# Exercises: default install, --dry-run, --target, --on-conflict, and the
# error paths (unknown flag, removed --tier flag returns helpful message).
# Uses --dry-run against a throwaway target so nothing touches the working tree.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
INSTALL="$REPO_ROOT/scripts/install.sh"

if [[ ! -x "$INSTALL" ]]; then
  echo "FAIL: install script not executable at $INSTALL" >&2
  exit 1
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

TARGET="$TMPDIR/target"
mkdir -p "$TARGET"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# -------- default install (no tier flag): copies skills/etyb/ verbatim --------
out=$("$INSTALL" --target "$TARGET" --dry-run)
grep -q "would install skills/etyb/" <<< "$out" || fail "default should install skills/etyb/"
grep -q "DRY-RUN" <<< "$out" || fail "dry-run mode not reported"
# v4: there is no tier, so the output must NOT contain "tier:" or "would remove"
if grep -q "^tier:" <<< "$out"; then
  fail "v4 install output should not advertise a tier"
fi
if grep -q "would remove" <<< "$out"; then
  fail "v4 install must not prune any references (tier system removed)"
fi

# -------- removed --tier flag returns a helpful error --------
if "$INSTALL" --tier lite --target "$TARGET" --dry-run >/dev/null 2>&1; then
  fail "--tier should be rejected (removed in v4.0.0)"
fi
err=$("$INSTALL" --tier lite --target "$TARGET" --dry-run 2>&1 || true)
grep -q "removed in v4" <<< "$err" || fail "--tier error should mention v4 removal, got: $err"

# -------- removed --list-tiers flag returns the same error --------
if "$INSTALL" --list-tiers >/dev/null 2>&1; then
  fail "--list-tiers should be rejected (removed in v4.0.0)"
fi

# -------- unknown flag rejected --------
if "$INSTALL" --bogus --target "$TARGET" --dry-run >/dev/null 2>&1; then
  fail "should reject unknown --bogus flag"
fi

# -------- --on-conflict accepts valid modes --------
for mode in prompt replace keep skip; do
  "$INSTALL" --target "$TARGET" --on-conflict "$mode" --dry-run >/dev/null \
    || fail "--on-conflict $mode should be accepted"
done

if "$INSTALL" --target "$TARGET" --on-conflict bogus --dry-run >/dev/null 2>&1; then
  fail "--on-conflict bogus should be rejected"
fi

echo "PASS: $(basename "$0")"
