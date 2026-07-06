#!/usr/bin/env bash
# session-start-memory.sh — SessionStart hook stub.
# Claude Code hook contract: SessionStart (no matcher).
#
# STUB: exits 0 immediately with no output. M4-T2 replaces this with
# memory-summary injection (reads the repo decision-memory summary via
# memory_summary(300) and emits it as additionalContext). It is wired
# into hooks/hooks.json now so the SessionStart plumbing is proven
# before the payload exists.
#
# Reads and discards stdin per the hook contract (hooks receive a JSON
# payload on stdin; leaving it unread can surface as a broken pipe).
#
# Exit codes:
#   0 — always (stub; must never affect session startup)

set -uo pipefail

cat >/dev/null 2>&1 || true

exit 0
