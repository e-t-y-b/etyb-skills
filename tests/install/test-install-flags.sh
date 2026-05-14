#!/usr/bin/env bash
# Tests for scripts/install.sh tier selection (v4).
#
# Exercises --tier (lite/core/pro), --list-tiers, default behaviour, and the
# error paths (unknown tier). Uses --dry-run against a throwaway target so
# nothing touches the repo working tree.

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

# -------- --list-tiers prints every tier --------
out=$("$INSTALL" --list-tiers)
for tier in lite core pro; do
  grep -qE "^  $tier" <<< "$out" || fail "--list-tiers omitted $tier"
done

# -------- default install (no --tier) selects pro --------
out=$("$INSTALL" --target "$TARGET" --dry-run)
grep -q "tier:   pro" <<< "$out" || fail "default tier should be pro"
grep -q "would install skills/etyb/" <<< "$out" || fail "default should install skills/etyb/"

# -------- --tier lite: would prune verticals + 11 specialists --------
rm -rf "$TARGET" && mkdir -p "$TARGET"
out=$("$INSTALL" --tier lite --target "$TARGET" --dry-run)
grep -q "tier:   lite" <<< "$out" || fail "tier should be lite"
# Lite keeps 3 specialists, prunes 11
pruned_specialists=$(grep -c "would remove specialists/" <<< "$out" || true)
[[ "$pruned_specialists" == "11" ]] || fail "lite should prune 11 specialists (got $pruned_specialists)"
pruned_verticals=$(grep -c "would remove verticals/" <<< "$out" || true)
[[ "$pruned_verticals" == "6" ]] || fail "lite should prune 6 verticals (got $pruned_verticals)"

# -------- --tier core: prunes verticals only --------
rm -rf "$TARGET" && mkdir -p "$TARGET"
out=$("$INSTALL" --tier core --target "$TARGET" --dry-run)
grep -q "tier:   core" <<< "$out" || fail "tier should be core"
pruned_specialists=$(grep -c "would remove specialists/" <<< "$out" || true)
[[ "$pruned_specialists" == "0" ]] || fail "core should not prune specialists (got $pruned_specialists)"
pruned_verticals=$(grep -c "would remove verticals/" <<< "$out" || true)
[[ "$pruned_verticals" == "6" ]] || fail "core should prune 6 verticals (got $pruned_verticals)"

# -------- --tier pro: prunes nothing --------
rm -rf "$TARGET" && mkdir -p "$TARGET"
out=$("$INSTALL" --tier pro --target "$TARGET" --dry-run)
pruned=$(grep -c "would remove" <<< "$out" || true)
[[ "$pruned" == "0" ]] || fail "pro should prune nothing (got $pruned)"

# -------- unknown tier rejected --------
if "$INSTALL" --tier bogus --target "$TARGET" --dry-run >/dev/null 2>&1; then
  fail "should reject --tier bogus"
fi

echo "PASS: $(basename "$0")"
