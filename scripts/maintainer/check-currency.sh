#!/usr/bin/env bash
#
# Knowledge-currency validator — flags Stacks whose `last_verified_on` is
# stale relative to their per-product `drift_risk`, AND probes the canonical
# docs.etyb.ai pages for reachability.
#
# Drift-risk thresholds (slim local pointer):
#   high   — flagged when last_verified_on > 90 days old
#   medium — flagged when last_verified_on > 180 days old
#   low    — flagged when last_verified_on > 365 days old
#
# Exit code:
#   0  every Stack is fresh AND every probed docs.etyb.ai URL is reachable
#   1  one or more Stacks have stale high-/medium-drift content, OR a
#      docs.etyb.ai/stacks/<vendor>/ index URL returns non-2xx
#
# Network probes (CHECK_CURRENCY_FETCH=1):
#   - Probes https://docs.etyb.ai/stacks/<vendor>/ for every local slim
#     pointer. v4 invariant: every local stacks/<vendor>/SKILL.md MUST
#     have a published canonical surface on docs.etyb.ai.
#   - Smoke-checks authoritative_sources.primary URLs from frontmatter
#     (the same vendor-side check as before).
#   - Network probes are opt-in because they touch the internet.
#
# DOCS_BASE_URL env var overrides the default docs.etyb.ai base (useful
# for testing against a local Starlight preview server).

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

DOCS_BASE_URL="${DOCS_BASE_URL:-https://docs.etyb.ai}"

errors=0
warnings=0
fetched=0
docs_probed=0

for stack_path in "$stacks_dir"/*/SKILL.md; do
  [[ -f "$stack_path" ]] || continue
  stack_name=$(basename "$(dirname "$stack_path")")

  # Parse last_verified_on from YAML frontmatter
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
    echo "⚠ stack/$stack_name: no last_verified_on in frontmatter" >&2
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
  # Each product line looks like: - { name: ..., drift_risk: high, ... }
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

  # Optionally probe network surfaces:
  #   1. Canonical docs.etyb.ai page for this Stack (v4 invariant).
  #   2. authoritative_sources.primary URLs from frontmatter (vendor-side).
  if [[ "${CHECK_CURRENCY_FETCH:-0}" == "1" ]]; then
    docs_url="$DOCS_BASE_URL/stacks/$stack_name/"
    docs_probed=$((docs_probed + 1))
    # Use GET-with-discard rather than HEAD — Starlight serves a redirect/
    # 200-only response some HEAD probes mishandle. -L follows redirects;
    # -o /dev/null discards the body; --fail returns non-zero on >=400.
    if ! curl --max-time 10 --silent --location --fail --output /dev/null "$docs_url"; then
      echo "✗ stack/$stack_name: canonical docs URL unreachable: $docs_url" >&2
      echo "  v4 invariant: every local stacks/<vendor>/ pointer MUST have a published page on docs.etyb.ai." >&2
      errors=$((errors + 1))
    fi

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
  echo "✗ check-currency: $errors stale or unreachable stack issue(s) found" >&2
  echo "  Run a Stack refresh PR — see scripts/maintainer/release-runbook conventions" >&2
  exit 1
fi

if [[ "${CHECK_CURRENCY_FETCH:-0}" == "1" ]]; then
  echo "✓ check-currency: all stacks fresh, $docs_probed docs.etyb.ai page(s) reachable, $fetched authoritative_sources URL(s) probed, $warnings warning(s)"
else
  echo "✓ check-currency: all stacks fresh ($warnings warnings) — set CHECK_CURRENCY_FETCH=1 to also probe docs.etyb.ai pages and authoritative_sources URLs"
fi
