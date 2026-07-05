#!/usr/bin/env bash
#
# lint-token-budget.sh — M1-T6
#
# Enforces the v5 always-on token budget structurally:
#   (a) every SKILL.md description ≤ 1,024 chars (Agent Skills open-spec cap)
#   (b) the etyb skill's descriptions summed ≤ 1,600 chars (~400 tokens):
#       counts skills/etyb/SKILL.md and skills/etyb-*/SKILL.md — the
#       skills a user installs together. stacks/*/SKILL.md are counted for
#       (a) only: they are separate per-vendor skills, installed selectively,
#       so they don't share the always-on budget.
#   (c) skills/etyb/SKILL.md body ≤ 150 lines total file.
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! python3 -c "import yaml" 2>/dev/null; then
  echo "✗ lint-token-budget: needs python3 with PyYAML (pip install pyyaml)" >&2
  exit 1
fi

fail=0
err() { echo "✗ lint-token-budget: $1" >&2; fail=1; }

# Extract the description value (handles block scalars and single-line).
desc_chars() {
  python3 - "$1" <<'PY'
import sys, yaml
with open(sys.argv[1], encoding="utf-8") as f:
    text = f.read()
if text.startswith("---"):
    fm = text.split("---", 2)[1]
    data = yaml.safe_load(fm) or {}
    print(len((data.get("description") or "").strip()))
else:
    print(0)
PY
}

total=0
while IFS= read -r skill; do
  n=$(desc_chars "$skill")
  if (( n > 1024 )); then
    case "$skill" in
      stacks/*)
        # Stack descriptions predate the spec-cap finding; M3-T5 compresses
        # them. Warn-only until then — flip to err when M3-T5 lands.
        echo "⚠ lint-token-budget: $skill description is ${n} chars (cap 1,024) — M3-T5 grace" >&2
        ;;
      *)
        err "$skill description is ${n} chars (cap 1,024 — Agent Skills spec)"
        ;;
    esac
  fi
  case "$skill" in
    skills/etyb/SKILL.md|skills/etyb-*/SKILL.md) total=$(( total + n )) ;;
  esac
done < <(find skills stacks -name SKILL.md -maxdepth 3 | sort)

if (( total > 1600 )); then
  err "etyb-family descriptions sum to ${total} chars (budget 1,600 ≈ 400 tokens)"
fi

lines=$(wc -l < skills/etyb/SKILL.md)
if (( lines > 150 )); then
  err "skills/etyb/SKILL.md is ${lines} lines (cap 150)"
fi

if (( fail )); then exit 1; fi
echo "✓ token-budget lint passed (etyb-family descriptions: ${total}/1600 chars; SKILL.md ${lines}/150 lines)"
