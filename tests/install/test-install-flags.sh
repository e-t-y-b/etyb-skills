#!/usr/bin/env bash
# Tests for scripts/install.sh bundle/skill selection flags.
#
# Exercises --bundle (short + long name), --skills, --list-bundles, default
# behaviour, and the error paths (unknown bundle, unknown skill, mutually
# exclusive flags). Uses --dry-run against a throwaway target, so nothing
# touches the repo working tree.

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

# -------- --list-bundles prints every bundle --------
out=$("$INSTALL" --list-bundles)
for name in etyb-full etyb-process-protocols etyb-core-team etyb-verticals; do
  grep -q "$name" <<< "$out" || fail "--list-bundles omitted $name"
done

# -------- default install selects every skill on disk --------
out=$("$INSTALL" --target "$TARGET" --dry-run)
default_count=$(grep -c "would install " <<< "$out")
source_count=$(find "$REPO_ROOT/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
[[ "$default_count" == "$source_count" ]] \
  || fail "default install planned $default_count skills, expected $source_count"

# -------- --bundle process-protocols selects 10 skills including etyb --------
out=$("$INSTALL" --bundle process-protocols --target "$TARGET" --dry-run)
count=$(grep -c "would install " <<< "$out")
[[ "$count" == "10" ]] || fail "process-protocols planned $count skills, expected 10"
grep -q "would install etyb" <<< "$out" || fail "process-protocols missing etyb"
grep -q "would install tdd-protocol" <<< "$out" || fail "process-protocols missing tdd-protocol"
grep -q "would install fintech-architect" <<< "$out" \
  && fail "process-protocols should not include fintech-architect"

# -------- long bundle name (etyb- prefix) also resolves --------
out=$("$INSTALL" --bundle etyb-verticals --target "$TARGET" --dry-run)
count=$(grep -c "would install " <<< "$out")
[[ "$count" == "6" ]] || fail "etyb-verticals planned $count skills, expected 6"

# -------- --skills installs only named skills --------
out=$("$INSTALL" --skills "tdd-protocol,code-reviewer" --target "$TARGET" --dry-run)
count=$(grep -c "would install " <<< "$out")
[[ "$count" == "2" ]] || fail "--skills planned $count, expected 2"
grep -q "would install tdd-protocol" <<< "$out" || fail "--skills missing tdd-protocol"
grep -q "would install code-reviewer" <<< "$out" || fail "--skills missing code-reviewer"

# -------- unknown bundle exits non-zero --------
if "$INSTALL" --bundle does-not-exist --target "$TARGET" --dry-run >/dev/null 2>&1; then
  fail "unknown bundle should have exited non-zero"
fi

# -------- unknown skill exits non-zero --------
if "$INSTALL" --skills "not-a-real-skill" --target "$TARGET" --dry-run >/dev/null 2>&1; then
  fail "unknown skill should have exited non-zero"
fi

# -------- --bundle and --skills are mutually exclusive --------
if "$INSTALL" --bundle full --skills tdd-protocol --target "$TARGET" --dry-run >/dev/null 2>&1; then
  fail "--bundle + --skills should have exited non-zero"
fi

# -------- an actual (non-dry-run) bundle install copies exactly those skills --------
LIVE_TARGET="$TMPDIR/live"
mkdir -p "$LIVE_TARGET"
"$INSTALL" --bundle verticals --target "$LIVE_TARGET" >/dev/null
installed=$(find "$LIVE_TARGET" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
[[ "$installed" == "6" ]] || fail "live install copied $installed skills, expected 6"
[[ -d "$LIVE_TARGET/fintech-architect" ]] || fail "live install missing fintech-architect"
[[ -d "$LIVE_TARGET/tdd-protocol" ]] && fail "live install leaked tdd-protocol into verticals"

echo "PASS: install.sh bundle/skill selection flags"
