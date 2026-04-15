#!/usr/bin/env bash
#
# etyb-skills install script
# Installs ETYB skills into a target directory with collision detection.
#
# Usage:
#   ./scripts/install.sh                    # auto-detect target, interactive
#   ./scripts/install.sh --dry-run          # show what would happen, change nothing
#   ./scripts/install.sh --target DIR       # install into DIR instead of auto-detect
#   ./scripts/install.sh --force            # replace existing skills without prompting
#   ./scripts/install.sh --on-conflict MODE # prompt | replace | keep | skip (default: prompt)
#
# Auto-detected target directories (first match wins):
#   ./.claude/skills/          # Claude Code project-scoped (legacy, uncommon)
#   ./.agents/skills/          # OpenAI Codex convention
#   ./.agent/skills/           # Google Antigravity convention (note: singular)
#   ./skills/                  # this repo's own layout
#
# Handles v1.x → v2.x migration:
#   - Detects existing `orchestrator/` folder from v1.x and prompts to remove it
#     (skill was renamed to `etyb` in 2.0.0)
#
# Never silently overwrites; never touches .etyb/plans/, .claude/plans/, or
# .claude/settings.local.json.

set -euo pipefail

SOURCE_DIR=""
TARGET_DIR=""
DRY_RUN=false
FORCE=false
ON_CONFLICT="prompt"

# -------- argument parsing --------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --force) FORCE=true; ON_CONFLICT="replace"; shift ;;
    --target) TARGET_DIR="$2"; shift 2 ;;
    --source) SOURCE_DIR="$2"; shift 2 ;;
    --on-conflict) ON_CONFLICT="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,25p' "$0"
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

case "$ON_CONFLICT" in
  prompt|replace|keep|skip) ;;
  *) echo "error: --on-conflict must be one of: prompt, replace, keep, skip" >&2; exit 1 ;;
esac

# -------- preflight --------
if [[ -z "$SOURCE_DIR" ]]; then
  SOURCE_DIR="$(cd "$(dirname "$0")/.." && pwd)/skills"
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "error: source dir not found: $SOURCE_DIR" >&2
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

echo "source:  $SOURCE_DIR"
echo "target:  $TARGET_DIR"
echo "mode:    $($DRY_RUN && echo DRY-RUN || echo APPLY) / on-conflict=$ON_CONFLICT"
echo ""

mkdir -p "$TARGET_DIR"

# -------- v1.x migration check: orchestrator → etyb --------
if [[ -d "$TARGET_DIR/orchestrator" ]]; then
  echo "⚠ found legacy 'orchestrator/' skill from v1.x"
  echo "  in 2.0.0 it was renamed to 'etyb'"
  if $FORCE; then
    REPLY="y"
  elif [[ "$ON_CONFLICT" == "keep" ]]; then
    echo "  keeping legacy folder (on-conflict=keep)"
    REPLY="n"
  elif [[ "$ON_CONFLICT" == "skip" ]]; then
    echo "  keeping legacy folder (on-conflict=skip)"
    REPLY="n"
  elif [[ "$ON_CONFLICT" == "replace" ]]; then
    REPLY="y"
  else
    read -r -p "  remove $TARGET_DIR/orchestrator/ ? [y/N] " REPLY
  fi
  if [[ "$REPLY" =~ ^[Yy]$ ]]; then
    if $DRY_RUN; then
      echo "  [DRY-RUN] would remove $TARGET_DIR/orchestrator/"
    else
      BACKUP="$TARGET_DIR/orchestrator.bak.$(date +%s)"
      mv "$TARGET_DIR/orchestrator" "$BACKUP"
      echo "  moved to $BACKUP (not deleted)"
    fi
  fi
  echo ""
fi

# -------- install each skill --------
INSTALLED=0
SKIPPED=0
REPLACED=0
KEPT=0

for src in "$SOURCE_DIR"/*/; do
  name=$(basename "$src")
  dst="$TARGET_DIR/$name"

  if [[ -e "$dst" ]]; then
    # conflict
    CHOICE=""
    case "$ON_CONFLICT" in
      replace) CHOICE="r" ;;
      keep)    CHOICE="k" ;;
      skip)    CHOICE="s" ;;
      prompt)
        echo "⚠ conflict: $dst already exists"
        echo "  [r] replace (backup to $dst.bak.TIMESTAMP)"
        echo "  [k] keep as $name.etyb (install side-by-side)"
        echo "  [s] skip this skill"
        read -r -p "  choice? [r/k/s] " CHOICE
        ;;
    esac

    case "$CHOICE" in
      r|R)
        if $DRY_RUN; then
          echo "  [DRY-RUN] would backup $dst and install fresh"
        else
          mv "$dst" "$dst.bak.$(date +%s)"
          cp -R "$src" "$dst"
          echo "  ✓ replaced $name (backup preserved)"
        fi
        REPLACED=$((REPLACED + 1))
        ;;
      k|K)
        alt="$TARGET_DIR/$name.etyb"
        if $DRY_RUN; then
          echo "  [DRY-RUN] would install as $alt (side-by-side)"
        else
          cp -R "$src" "$alt"
          echo "  ✓ installed side-by-side as $name.etyb"
        fi
        KEPT=$((KEPT + 1))
        ;;
      s|S|*)
        echo "  — skipped $name"
        SKIPPED=$((SKIPPED + 1))
        ;;
    esac
  else
    # no conflict
    if $DRY_RUN; then
      echo "  [DRY-RUN] would install $name"
    else
      cp -R "$src" "$dst"
      echo "  ✓ installed $name"
    fi
    INSTALLED=$((INSTALLED + 1))
  fi
done

# -------- summary --------
echo ""
echo "installed:  $INSTALLED"
echo "replaced:   $REPLACED"
echo "kept:       $KEPT (installed side-by-side as *.etyb)"
echo "skipped:    $SKIPPED"

if $DRY_RUN; then
  echo ""
  echo "dry-run complete. Run without --dry-run to apply."
fi
