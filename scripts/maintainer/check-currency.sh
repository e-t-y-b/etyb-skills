#!/usr/bin/env bash
#
# Knowledge-currency validator — flags Stacks whose `last_verified_on` is
# stale relative to their per-product `drift_risk`, checks EVERY page under
# stacks/**/*.md against per-page drift thresholds (M3-T3), runs a
# batch-re-stamp detector, and (optionally) probes the per-page
# `authoritative_url` references against the live vendor docs.
#
# Drift-risk thresholds (stack SKILL.md and each in-repo product/role page):
#   high   — flagged when last_verified_on > 90 days old
#   medium — flagged when last_verified_on > 180 days old
#   low    — flagged when last_verified_on > 365 days old
#
# Per-page drift_risk resolution (M3-T3 design choice):
#   scripts/build-manifest.sh already resolves each page's drift_risk
#   (page frontmatter → stack SKILL.md products_covered → index.md
#   stack default) and writes the result into manifest.json's
#   "stacks_pages" array. Rather than re-implement that resolution here,
#   this script reads drift_risk from manifest.json. last_verified_on,
#   by contrast, is ALWAYS read live from the page on disk, so an
#   in-flight stack refresh is honored even before the manifest is
#   regenerated. A page missing from manifest.json falls back to
#   drift_risk=medium with a warning to re-run build-manifest.sh.
#
# Batch-re-stamp detector:
#   If >100 pages share a single last_verified_on date AND that date is
#   more than 7 days NEWER than the median git-log last-modified date of
#   those same files, the stamp was almost certainly applied in bulk
#   without real re-verification → "batch re-stamp suspected". Skipped
#   with a warning on shallow clones or when git history is unavailable
#   (git dates would be meaningless).
#
# Modes (M3 warn-first rollout):
#   default (CHECK_CURRENCY_STRICT unset) — stale pages and suspected
#     batch re-stamps are WARNINGS only; exit 0. This is the CI wiring
#     until M3-T4/T5 land:
#       bash scripts/maintainer/check-currency.sh
#   strict (CHECK_CURRENCY_STRICT=1) — stale pages and suspected batch
#     re-stamps are FAILURES; exit 1. CI flips to this after M3-T4/T5:
#       CHECK_CURRENCY_STRICT=1 bash scripts/maintainer/check-currency.sh
#   The original per-stack SKILL.md staleness check keeps its historical
#   behavior: it fails the script in BOTH modes (it predates M3-T3 and
#   was already enforced).
#
# Exit code:
#   0  no stack-level staleness; in strict mode additionally no stale
#      pages and no suspected batch re-stamp; when CHECK_CURRENCY_FETCH=1
#      every probed vendor authoritative_url is reachable
#   1  one or more Stacks have stale high-/medium-drift content, or (in
#      strict mode) stale pages / suspected batch re-stamp
#
# Network probes (CHECK_CURRENCY_FETCH=1):
#   - Smoke-checks the per-page `authoritative_url` and the slim
#     SKILL.md's `authoritative_sources.primary` URLs (vendor-side).
#   - Network probes are opt-in because they touch the internet and several
#     vendor docs sites (OpenAI, Splunk, some Google pages) block HEAD
#     requests; those are reported as warnings, not errors.
#
# Env:
#   CHECK_CURRENCY_STRICT=1  — strict mode (see above)
#   CHECK_CURRENCY_FETCH=1   — probe authoritative_sources URLs
#   CHECK_CURRENCY_ROOT      — repo root override (test hook; defaults to
#                              this script's ../..)
#
# Dependencies: bash, git, python3 (stdlib only — used for the per-page
#   check and batch-stamp detector; date math and medians are miserable
#   in portable shell).

set -euo pipefail

ROOT="${CHECK_CURRENCY_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
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

# -------- per-page currency + batch-re-stamp detector (M3-T3) --------
#
# Implemented in embedded python3 (stdlib only) — the repo already depends
# on python3 in scripts/ (build-manifest.sh, validate-toc.py), and date
# arithmetic, medians, and grouping are error-prone in portable shell.
# All human-readable findings go to stderr; the single stdout line is a
# machine-readable count summary consumed by the bash wrapper below.

command -v python3 >/dev/null 2>&1 || fail "python3 is required for the per-page currency check"

strict_mode="${CHECK_CURRENCY_STRICT:-0}"

page_summary=$(CHECK_CURRENCY_STRICT="$strict_mode" python3 - <<'PY'
import json
import os
import re
import statistics
import subprocess
import sys
from datetime import date, datetime
from pathlib import Path

STRICT = os.environ.get("CHECK_CURRENCY_STRICT") == "1"
THRESHOLDS = {"high": 90, "medium": 180, "low": 365}
BATCH_MIN_PAGES = 101   # ">100 pages share one date"
BATCH_MIN_DELTA = 8     # "newer than the median git date by >7 days"
TODAY = date.today()

mark = "✗" if STRICT else "⚠"
stale = batch = missing_risk = nostamp = 0

def report(msg: str) -> None:
    print(f"{mark} {msg}", file=sys.stderr)

def warn(msg: str) -> None:
    print(f"⚠ {msg}", file=sys.stderr)

def parse_date(stamp: str):
    try:
        return datetime.strptime(stamp, "%Y-%m-%d").date()
    except ValueError:
        return None

# drift_risk lookup from manifest.json (see header: build-manifest.sh owns
# the resolution; we consume its output instead of re-implementing it).
risk_by_page = {}
try:
    manifest = json.loads(Path("manifest.json").read_text(encoding="utf-8"))
    for entry in manifest.get("stacks_pages", []):
        risk_by_page[entry["path"]] = entry.get("drift_risk", "medium")
except (OSError, json.JSONDecodeError) as e:
    warn(f"manifest.json unreadable ({e}) — defaulting every page to drift_risk=medium")

# last_verified_on is read live from each page's frontmatter on disk.
stamp_re = re.compile(r"^\s+last_verified_on:\s*\"?(\d{4}-\d{2}-\d{2})\"?\s*$", re.M)
fm_re = re.compile(r"^---\n(.*?)\n---\n", re.DOTALL)

pages = sorted(Path("stacks").rglob("*.md"), key=str)
stamps = {}   # path(str) -> date
for page in pages:
    rel = str(page)
    m = fm_re.match(page.read_text(encoding="utf-8"))
    stamp_m = stamp_re.search(m.group(1)) if m else None
    if not stamp_m:
        warn(f"page {rel}: no last_verified_on in frontmatter")
        nostamp += 1
        continue
    stamp = parse_date(stamp_m.group(1))
    if stamp is None:
        warn(f"page {rel}: could not parse last_verified_on='{stamp_m.group(1)}'")
        nostamp += 1
        continue
    stamps[rel] = stamp

    risk = risk_by_page.get(rel)
    if risk is None:
        warn(f"page {rel}: not in manifest.json stacks_pages (run scripts/build-manifest.sh) — assuming drift_risk=medium")
        missing_risk += 1
        risk = "medium"
    threshold = THRESHOLDS.get(risk, 365)
    age = (TODAY - stamp).days
    if age > threshold:
        report(f"page {rel}: last_verified_on={stamp} ({age} days ago) exceeds {threshold}-day threshold for drift_risk={risk}")
        stale += 1

# --- batch-re-stamp detector ---
by_stamp = {}
for rel, stamp in stamps.items():
    by_stamp.setdefault(stamp, []).append(rel)
suspect_groups = {s: files for s, files in by_stamp.items() if len(files) >= BATCH_MIN_PAGES}

if suspect_groups:
    def git(*args):
        return subprocess.run(["git", *args], capture_output=True, text=True)

    shallow = git("rev-parse", "--is-shallow-repository")
    log = git("log", "--name-only", "--pretty=format:%cs", "--", "stacks/")
    if shallow.stdout.strip() == "true":
        warn("batch-re-stamp detector skipped: shallow clone (git dates would be truncated) — use a full checkout")
    elif log.returncode != 0 or not log.stdout.strip():
        warn("batch-re-stamp detector skipped: git log returned nothing (shallow clone or no history)")
    else:
        # Single-pass map: newest-first log, first sighting of a file is its
        # last-modified date. One git call for all 500+ pages.
        git_date = {}
        current = None
        for line in log.stdout.splitlines():
            d = parse_date(line.strip())
            if d is not None:
                current = d
            elif line.strip() and current is not None:
                git_date.setdefault(line.strip(), current)

        for stamp, files in sorted(suspect_groups.items()):
            known = sorted(git_date[f] for f in files if f in git_date)
            if not known:
                warn(f"batch-re-stamp detector skipped for {stamp}: none of its {len(files)} pages appear in git history")
                continue
            median = statistics.median_low(known)
            delta = (stamp - median).days
            if delta >= BATCH_MIN_DELTA:
                report(f"batch re-stamp suspected: {len(files)} pages share last_verified_on={stamp}, "
                       f"{delta} days newer than their median git last-modified date ({median}) — "
                       f"stamps must reflect real per-page verification")
                batch += 1

print(f"{len(stamps) + nostamp} {stale} {batch} {missing_risk + nostamp}")
PY
)

read -r page_total page_stale page_batch page_warn <<<"$page_summary"

if [[ "$strict_mode" == "1" ]]; then
  errors=$((errors + page_stale + page_batch))
else
  warnings=$((warnings + page_stale + page_batch))
fi
warnings=$((warnings + page_warn))

# -------- verdict --------
echo ""
if [[ "$errors" -gt 0 ]]; then
  echo "✗ check-currency: $errors stale/batch-stamp issue(s) found across $stack_pages stacks and $page_total pages" >&2
  echo "  Run a Stack refresh PR — see scripts/maintainer/release-runbook conventions" >&2
  exit 1
fi

mode_note="strict mode"
if [[ "$strict_mode" != "1" ]]; then
  mode_note="warn-only mode — set CHECK_CURRENCY_STRICT=1 to fail on stale pages/batch stamps"
fi

if [[ "${CHECK_CURRENCY_FETCH:-0}" == "1" ]]; then
  echo "✓ check-currency: $stack_pages stacks + $page_total pages checked, $fetched authoritative_sources URL(s) probed, $warnings warning(s) ($mode_note)"
else
  echo "✓ check-currency: $stack_pages stacks + $page_total pages checked, $warnings warning(s) ($mode_note; CHECK_CURRENCY_FETCH=1 to probe authoritative_sources URLs)"
fi
