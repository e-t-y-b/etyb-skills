#!/usr/bin/env bash
#
# etyb-skills install script
# Installs ETYB skills into a target directory with collision detection.
#
# Usage:
#   ./scripts/install.sh                         # install everything, auto-detect target
#   ./scripts/install.sh --bundle NAME           # install a named bundle (see --list-bundles)
#   ./scripts/install.sh --skills a,b,c          # install specific skills by name
#   ./scripts/install.sh --list-bundles          # print available bundles and exit
#   ./scripts/install.sh --dry-run               # show what would happen, change nothing
#   ./scripts/install.sh --target DIR            # install into DIR instead of auto-detect
#   ./scripts/install.sh --force                 # replace existing skills without prompting
#   ./scripts/install.sh --on-conflict MODE      # prompt | replace | keep | skip (default: prompt)
#
# Bundle names (short forms work without the etyb- prefix):
#   full                  # all 30 skills (default)
#   process-protocols     # ETYB + 9 always-on protocols
#   core-team             # ETYB + 14 core engineering teams
#   verticals             # 6 domain specialists
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

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_DIR="$REPO_ROOT/bundles"

SOURCE_DIR=""
TARGET_DIR=""
DRY_RUN=false
FORCE=false
ON_CONFLICT="prompt"
BUNDLE=""
SKILL_LIST=""
LIST_BUNDLES=false

# -------- argument parsing --------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --force) FORCE=true; ON_CONFLICT="replace"; shift ;;
    --target) TARGET_DIR="$2"; shift 2 ;;
    --source) SOURCE_DIR="$2"; shift 2 ;;
    --on-conflict) ON_CONFLICT="$2"; shift 2 ;;
    --bundle) BUNDLE="$2"; shift 2 ;;
    --skills) SKILL_LIST="$2"; shift 2 ;;
    --list-bundles) LIST_BUNDLES=true; shift ;;
    -h|--help)
      sed -n '2,33p' "$0"
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

case "$ON_CONFLICT" in
  prompt|replace|keep|skip) ;;
  *) echo "error: --on-conflict must be one of: prompt, replace, keep, skip" >&2; exit 1 ;;
esac

if [[ -n "$BUNDLE" && -n "$SKILL_LIST" ]]; then
  echo "error: --bundle and --skills are mutually exclusive" >&2
  exit 1
fi

# -------- bundle helpers --------
# Resolve a user-supplied bundle name to an existing bundle manifest. Accepts
# both short ("process-protocols") and full ("etyb-process-protocols") names.
resolve_bundle_path() {
  local name=$1
  local path="$BUNDLE_DIR/$name.txt"
  if [[ -f "$path" ]]; then
    printf '%s' "$path"
    return 0
  fi
  local prefixed="$BUNDLE_DIR/etyb-$name.txt"
  if [[ -f "$prefixed" ]]; then
    printf '%s' "$prefixed"
    return 0
  fi
  return 1
}

list_bundles() {
  if [[ ! -d "$BUNDLE_DIR" ]]; then
    echo "error: bundles/ not found — run scripts/generate-bundles.py first" >&2
    exit 1
  fi
  echo "available bundles:"
  echo ""
  local path name count
  for path in "$BUNDLE_DIR"/*.txt; do
    [[ -f "$path" ]] || continue
    name=$(basename "$path" .txt)
    count=$(grep -c . "$path" || true)
    printf "  %-28s %d skills\n" "$name" "$count"
  done
  echo ""
  echo "pass with --bundle NAME (the etyb- prefix is optional)."
}

if $LIST_BUNDLES; then
  list_bundles
  exit 0
fi

# -------- preflight --------
if [[ -z "$SOURCE_DIR" ]]; then
  SOURCE_DIR="$REPO_ROOT/skills"
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "error: source dir not found: $SOURCE_DIR" >&2
  exit 1
fi

# -------- build skill selection --------
# SKILLS is the ordered list of skill directory names to install.
declare -a SKILLS=()

if [[ -n "$BUNDLE" ]]; then
  if ! bundle_path=$(resolve_bundle_path "$BUNDLE"); then
    echo "error: unknown bundle '$BUNDLE'" >&2
    echo "" >&2
    list_bundles >&2
    exit 1
  fi
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    SKILLS+=("$line")
  done < "$bundle_path"
  SELECTION_LABEL="bundle=$(basename "$bundle_path" .txt)"
elif [[ -n "$SKILL_LIST" ]]; then
  IFS=',' read -r -a requested <<< "$SKILL_LIST"
  for name in "${requested[@]}"; do
    name="${name// /}"
    [[ -n "$name" ]] || continue
    if [[ ! -d "$SOURCE_DIR/$name" ]]; then
      echo "error: unknown skill '$name' (no such directory: $SOURCE_DIR/$name)" >&2
      exit 1
    fi
    SKILLS+=("$name")
  done
  SELECTION_LABEL="skills=$SKILL_LIST"
else
  # No selection flag: install every skill present on disk (current default).
  for src in "$SOURCE_DIR"/*/; do
    SKILLS+=("$(basename "$src")")
  done
  SELECTION_LABEL="all (${#SKILLS[@]} skills)"
fi

if [[ ${#SKILLS[@]} -eq 0 ]]; then
  echo "error: no skills selected" >&2
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

echo "source:    $SOURCE_DIR"
echo "target:    $TARGET_DIR"
echo "selection: $SELECTION_LABEL"
echo "mode:      $($DRY_RUN && echo DRY-RUN || echo APPLY) / on-conflict=$ON_CONFLICT"
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

# -------- install each selected skill --------
INSTALLED=0
SKIPPED=0
REPLACED=0
KEPT=0

for name in "${SKILLS[@]}"; do
  src="$SOURCE_DIR/$name"
  dst="$TARGET_DIR/$name"

  if [[ ! -d "$src" ]]; then
    echo "  — missing source for $name (skipping)"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

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
