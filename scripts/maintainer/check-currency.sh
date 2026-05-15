#!/usr/bin/env bash
#
# Knowledge-currency validator — flags Stacks whose `last_verified_on` is
# stale relative to their per-product `drift_risk`, AND (optionally) probes
# the per-page `authoritative_url` references against the live vendor docs.
#
# Drift-risk thresholds (slim local pointer + each in-repo product/role file):
#   high   — flagged when last_verified_on > 90 days old
#   medium — flagged when last_verified_on > 180 days old
#   low    — flagged when last_verified_on > 365 days old
#
# Exit code:
#   0  every Stack is fresh and (when CHECK_CURRENCY_FETCH=1) every probed
#      vendor authoritative_url is reachable
#   1  one or more Stacks have stale high-/medium-drift content
#
# Network probes (CHECK_CURRENCY_FETCH=1):
#   - Smoke-checks the per-page `authoritative_url` and the slim
#     SKILL.md's `authoritative_sources.primary` URLs (vendor-side).
#   - Network probes are opt-in because they touch the internet and several
#     vendor docs sites (OpenAI, Splunk, some Google pages) block HEAD
#     requests; those are reported as warnings, not errors.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

fail() {
  echo "✗ check-currency: $1" >&2
  exit 1
}

today_epoch=$(date +%s)
days_since() {
  # $1 = YYYY-MM-DD
  local stamp_epoch
  # macOS BSD date vs GNU date compatibility
  if stamp_epoch=$(date -j -f "%Y-%m-%d" "$1" "+%s" 2>/dev/null); then
    : # macOS path
  elif stamp_epoch=$(date -d "$1" "+%s" 2>/dev/null); then
    : # GNU path
  else
    echo "-1"
    return
  fi
  echo $(( (today_epoch - stamp_epoch) / 86400 ))
}

# -------- threshold mapping --------
threshold_for_risk() {
  case "$1" in
    high)   echo 90 ;;
    medium) echo 180 ;;
    low)    echo 365 ;;
    *)      echo 365 ;;
  esac
}

stacks_dir="$ROOT/stacks"
[[ -d "$stacks_dir" ]] || fail "stacks/ directory not found"

errors=0
warnings=0
fetched=0
stack_pages=0

for stack_path in "$stacks_dir"/*/SKILL.md; do
  [[ -f "$stack_path" ]] || continue
  stack_name=$(basename "$(dirname "$stack_path")")
  stack_pages=$((stack_pages + 1))

  # Parse last_verified_on from SKILL.md frontmatter
  verified_on=$(awk '
    /^---[[:space:]]*$/ { fm++; next }
    fm == 1 && /^[[:space:]]+last_verified_on:/ {
      sub(/.*last_verified_on:[[:space:]]*/, "")
      gsub(/"/, "")
      print
      exit
    }
  ' "$stack_path")

  if [[ -z "$verified_on" ]]; then
    echo "⚠ stack/$stack_name: no last_verified_on in SKILL.md frontmatter" >&2
    warnings=$((warnings + 1))
    continue
  fi

  age=$(days_since "$verified_on")
  if [[ "$age" -lt 0 ]]; then
    echo "⚠ stack/$stack_name: could not parse last_verified_on='$verified_on'" >&2
    warnings=$((warnings + 1))
    continue
  fi

  # Parse products_covered drift_risks
  while IFS= read -r drift_risk; do
    [[ -z "$drift_risk" ]] && continue
    threshold=$(threshold_for_risk "$drift_risk")
    if [[ "$age" -gt "$threshold" ]]; then
      echo "✗ stack/$stack_name: last_verified_on=$verified_on ($age days ago) exceeds $threshold-day threshold for drift_risk=$drift_risk" >&2
      errors=$((errors + 1))
    fi
  done < <(awk '
    /^---[[:space:]]*$/ { fm++; next }
    fm == 1 && /^[[:space:]]+- \{.*drift_risk:/ {
      match($0, /drift_risk:[[:space:]]*[a-z]+/)
      if (RSTART > 0) {
        s = substr($0, RSTART, RLENGTH)
        sub(/drift_risk:[[:space:]]*/, "", s)
        print s
      }
    }
  ' "$stack_path")

  # Verify the Stack folder has at least one product/role file beyond SKILL.md.
  # Empty Stack folders are a v4 contract violation — slim pointer with no
  # depth behind it means ETYB can't deliver substance.
  sibling_count=$(find "$stacks_dir/$stack_name" -maxdepth 1 -name '*.md' -not -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$sibling_count" -lt 2 ]]; then
    echo "⚠ stack/$stack_name: only $sibling_count product/role page(s) alongside SKILL.md (expected at least 2 — an index and one product)" >&2
    warnings=$((warnings + 1))
  fi

  # Optionally probe vendor authoritative_sources URLs.
  if [[ "${CHECK_CURRENCY_FETCH:-0}" == "1" ]]; then
    while IFS= read -r url; do
      [[ -z "$url" ]] && continue
      fetched=$((fetched + 1))
      if ! curl --max-time 10 --silent --head --fail "$url" >/dev/null 2>&1; then
        echo "⚠ stack/$stack_name: authoritative_sources URL unreachable: $url" >&2
        warnings=$((warnings + 1))
      fi
    done < <(awk '
      /^---[[:space:]]*$/ { fm++; next }
      fm == 1 && /url:[[:space:]]*"https?:/ {
        match($0, /url:[[:space:]]*"[^"]+/)
        if (RSTART > 0) {
          s = substr($0, RSTART, RLENGTH)
          sub(/url:[[:space:]]*"/, "", s)
          print s
        }
      }
    ' "$stack_path")
  fi
done

echo ""
if [[ "$errors" -gt 0 ]]; then
  echo "✗ check-currency: $errors stale stack issue(s) found" >&2
  echo "  Run a Stack refresh PR — see scripts/maintainer/release-runbook conventions" >&2
  exit 1
fi

if [[ "${CHECK_CURRENCY_FETCH:-0}" == "1" ]]; then
  echo "✓ check-currency: all $stack_pages stacks fresh, $fetched authoritative_sources URL(s) probed, $warnings warning(s)"
else
  echo "✓ check-currency: all $stack_pages stacks fresh ($warnings warnings) — set CHECK_CURRENCY_FETCH=1 to also probe authoritative_sources URLs"
fi
