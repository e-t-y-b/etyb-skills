#!/usr/bin/env bash
#
# etyb-skills install script (v4 — single skill, tiered references)
#
# Usage:
#   ./scripts/install.sh                          # install Pro tier (everything), auto-detect target
#   ./scripts/install.sh --tier lite              # ETYB + 9 protocols + 3 essential specialists
#   ./scripts/install.sh --tier core              # ETYB + 9 protocols + 14 specialists
#   ./scripts/install.sh --tier pro               # everything (default)
#   ./scripts/install.sh --list-tiers             # print available tiers and exit
#   ./scripts/install.sh --dry-run                # show what would happen, change nothing
#   ./scripts/install.sh --target DIR             # install into DIR instead of auto-detect
#   ./scripts/install.sh --force                  # replace existing skills without prompting
#   ./scripts/install.sh --on-conflict MODE       # prompt | replace | keep | skip (default: prompt)
#
# How v4 install works:
#   The /etyb slash command is the only triggering surface. All 20 specialists,
#   9 protocols, and 6 verticals live INSIDE skills/etyb/references/ as internal
#   reference files. A tier install copies skills/etyb/ to the target, then
#   prunes the references not included in the chosen tier — Lite users get a
#   smaller install, Pro users get everything.
#
# Auto-detected target directories (first match wins):
#   ./.claude/skills/          # Claude Code project-scoped
#   ./.agents/skills/          # OpenAI Codex convention
#   ./.agent/skills/           # Google Antigravity convention (note: singular)
#   ./skills/                  # generic
#
# Handles v3.x → v4.x migration:
#   - Detects sibling skill directories from v3.x (research-analyst/,
#     tdd-protocol/, etc.) and offers to remove them — those are now internal
#     references inside skills/etyb/.
#   - v1.x → v2.x orchestrator/ migration still handled.
#
# Never silently overwrites; never touches .etyb/plans/, .claude/plans/, or
# .claude/settings.local.json.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_SKILL="$REPO_ROOT/skills/etyb"
MANIFEST="$REPO_ROOT/manifest.json"

TIER="pro"
SOURCE_DIR=""
TARGET_DIR=""
DRY_RUN=false
FORCE=false
ON_CONFLICT="prompt"
LIST_TIERS=false

LITE_SPECIALISTS=(system-architect backend-architect frontend-architect)
CORE_SPECIALISTS=(research-analyst system-architect frontend-architect backend-architect database-architect mobile-architect qa-engineer devops-engineer security-engineer sre-engineer ai-ml-engineer technical-writer project-planner code-reviewer)
ALL_PROTOCOLS=(tdd-protocol brainstorm-protocol review-protocol subagent-protocol git-workflow-protocol plan-execution-protocol skill-evolution-protocol verification-protocol debugging-protocol)
ALL_VERTICALS=(social-platform-architect e-commerce-architect fintech-architect saas-architect real-time-architect healthcare-architect)

# -------- argument parsing --------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --tier) TIER="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --force) FORCE=true; ON_CONFLICT="replace"; shift ;;
    --target) TARGET_DIR="$2"; shift 2 ;;
    --source) SOURCE_DIR="$2"; shift 2 ;;
    --on-conflict) ON_CONFLICT="$2"; shift 2 ;;
    --list-tiers) LIST_TIERS=true; shift ;;
    -h|--help)
      sed -n '2,34p' "$0"
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

case "$TIER" in
  lite|core|pro) ;;
  *) echo "error: --tier must be one of: lite, core, pro" >&2; exit 1 ;;
esac

case "$ON_CONFLICT" in
  prompt|replace|keep|skip) ;;
  *) echo "error: --on-conflict must be one of: prompt, replace, keep, skip" >&2; exit 1 ;;
esac

if $LIST_TIERS; then
  echo "available tiers:"
  echo ""
  echo "  lite   ETYB + 9 protocols + 3 essential specialists (~12 references)"
  echo "         For solo devs, students, exploring."
  echo ""
  echo "  core   ETYB + 9 protocols + 14 specialists (~23 references)"
  echo "         For most teams shipping production software."
  echo ""
  echo "  pro    Everything: protocols + 14 specialists + 6 verticals (~29 references)"
  echo "         For domain-specific shops and platforms."
  echo ""
  echo "pass with --tier NAME. Default is pro."
  exit 0
fi

# -------- preflight --------
if [[ ! -d "$SOURCE_SKILL" ]]; then
  echo "error: source skill not found: $SOURCE_SKILL" >&2
  exit 1
fi

# -------- detect target dir --------
if [[ -z "$TARGET_DIR" ]]; then
  for candidate in .claude/skills .agents/skills .agent/skills skills; do
    if [[ -d "$candidate" ]]; then
      TARGET_DIR="$candidate"
      break
    fi
  done
fi

if [[ -z "$TARGET_DIR" ]]; then
  echo "no target dir detected. Specify with --target DIR"
  echo "common choices:"
  echo "  .claude/skills   (Claude Code project-scoped)"
  echo "  .agents/skills   (OpenAI Codex)"
  echo "  .agent/skills    (Google Antigravity)"
  echo "  skills           (generic)"
  exit 1
fi

DST_SKILL="$TARGET_DIR/etyb"

echo "source: $SOURCE_SKILL"
echo "target: $DST_SKILL"
echo "tier:   $TIER"
echo "mode:   $($DRY_RUN && echo DRY-RUN || echo APPLY) / on-conflict=$ON_CONFLICT"
echo ""

mkdir -p "$TARGET_DIR"

# -------- v1.x → v2.x migration: orchestrator → etyb --------
if [[ -d "$TARGET_DIR/orchestrator" ]]; then
  echo "⚠ found legacy 'orchestrator/' skill from v1.x"
  echo "  in 2.0.0 it was renamed to 'etyb'"
  REPLY="n"
  if $FORCE || [[ "$ON_CONFLICT" == "replace" ]]; then
    REPLY="y"
  elif [[ "$ON_CONFLICT" != "keep" && "$ON_CONFLICT" != "skip" ]]; then
    read -r -p "  remove $TARGET_DIR/orchestrator/ ? [y/N] " REPLY
  fi
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    if $DRY_RUN; then
      echo "  [DRY-RUN] would back up $TARGET_DIR/orchestrator/"
    else
      mv "$TARGET_DIR/orchestrator" "$TARGET_DIR/orchestrator.bak.$(date +%s)"
      echo "  moved to backup (not deleted)"
    fi
  fi
  echo ""
fi

# -------- v3.x → v4.x migration: sibling skills → references --------
V3_SIBLINGS=()
for s in "${CORE_SPECIALISTS[@]}" "${ALL_PROTOCOLS[@]}" "${ALL_VERTICALS[@]}"; do
  [[ -d "$TARGET_DIR/$s" ]] && V3_SIBLINGS+=("$s")
done

if [[ ${#V3_SIBLINGS[@]} -gt 0 ]]; then
  echo "⚠ found ${#V3_SIBLINGS[@]} legacy v3.x sibling skill(s) in $TARGET_DIR/"
  echo "  in 4.0.0 these became internal references inside skills/etyb/."
  echo "  Leaving them in place will cause /etyb to compete with them at trigger time."
  REPLY="n"
  if $FORCE || [[ "$ON_CONFLICT" == "replace" ]]; then
    REPLY="y"
  elif [[ "$ON_CONFLICT" != "keep" && "$ON_CONFLICT" != "skip" ]]; then
    read -r -p "  back up and remove these v3 siblings? [y/N] " REPLY
  fi
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    ts=$(date +%s)
    for s in "${V3_SIBLINGS[@]}"; do
      if $DRY_RUN; then
        echo "  [DRY-RUN] would back up $TARGET_DIR/$s/"
      else
        mv "$TARGET_DIR/$s" "$TARGET_DIR/$s.bak.$ts"
      fi
    done
    echo "  ${#V3_SIBLINGS[@]} sibling(s) moved to *.bak.$ts"
  fi
  echo ""
fi

# -------- install skills/etyb/ --------
if [[ -e "$DST_SKILL" ]]; then
  CHOICE=""
  case "$ON_CONFLICT" in
    replace) CHOICE="r" ;;
    keep)    CHOICE="k" ;;
    skip)    CHOICE="s" ;;
    prompt)
      echo "⚠ conflict: $DST_SKILL already exists"
      echo "  [r] replace (backup to $DST_SKILL.bak.TIMESTAMP)"
      echo "  [k] keep as etyb.bak.TIMESTAMP, install fresh"
      echo "  [s] skip — abort install"
      read -r -p "  choice? [r/k/s] " CHOICE
      ;;
  esac
  case "$CHOICE" in
    r|R|k|K)
      if $DRY_RUN; then
        echo "  [DRY-RUN] would back up existing etyb/ and install fresh"
      else
        mv "$DST_SKILL" "$DST_SKILL.bak.$(date +%s)"
        cp -R "$SOURCE_SKILL" "$DST_SKILL"
        echo "  ✓ replaced etyb (backup preserved)"
      fi
      ;;
    s|S|*)
      echo "  — aborted (skill not installed)"
      exit 0
      ;;
  esac
else
  if $DRY_RUN; then
    echo "  [DRY-RUN] would install skills/etyb/"
  else
    cp -R "$SOURCE_SKILL" "$DST_SKILL"
    echo "  ✓ installed skills/etyb/"
  fi
fi

# -------- prune references based on tier --------
# When DRY_RUN, the destination has nothing to iterate (we skipped the copy),
# so iterate the source directory and report what would be removed once the
# real install happens. When not DRY_RUN, iterate the destination and actually
# delete.
prune_dir() {
  local subdir=$1; shift
  local -a keep=("$@")
  local scan_dir
  if $DRY_RUN; then
    scan_dir="$SOURCE_SKILL/references/$subdir"
  else
    scan_dir="$DST_SKILL/references/$subdir"
  fi
  [[ -d "$scan_dir" ]] || return 0
  local removed=0
  for entry in "$scan_dir"/*/; do
    [[ -d "$entry" ]] || continue
    local name
    name=$(basename "$entry")
    local found=0
    if [[ ${#keep[@]} -gt 0 ]]; then
      for k in "${keep[@]}"; do
        if [[ "$k" == "$name" ]]; then found=1; break; fi
      done
    fi
    if [[ $found -eq 0 ]]; then
      if $DRY_RUN; then
        echo "    [DRY-RUN] would remove $subdir/$name (not in $TIER tier)"
      else
        rm -rf "$DST_SKILL/references/$subdir/$name"
      fi
      removed=$((removed + 1))
    fi
  done
  if [[ $removed -gt 0 && ! $DRY_RUN ]]; then
    echo "  ✓ pruned $removed $subdir/ reference(s) not in $TIER tier"
  fi
}

case "$TIER" in
  lite)
    prune_dir specialists "${LITE_SPECIALISTS[@]}"
    # protocols: all 9 included — no prune
    prune_dir verticals  # empty keep list → removes all
    ;;
  core)
    # specialists: all 14 included — no prune
    # protocols: all 9 included — no prune
    prune_dir verticals  # removes all
    ;;
  pro)
    # full install — nothing to prune
    ;;
esac

# -------- summary --------
echo ""
echo "install complete: /etyb skill installed at $TIER tier"
echo "to upgrade tier later, re-run with --tier <higher>"
echo ""
echo "what's new: https://etyb.ai/changelog"

if $DRY_RUN; then
  echo ""
  echo "dry-run complete. Run without --dry-run to apply."
fi
