#!/usr/bin/env bash
#
# etyb-skills Codex runtime installer
# Installs the project-scoped .codex runtime assets into a target workspace.
#
# Usage:
#   ./scripts/install-codex-runtime.sh --target /path/to/project
#   ./scripts/install-codex-runtime.sh --target /path/to/project --dry-run
#   ./scripts/install-codex-runtime.sh --target /path/to/project --force
#
# This installs:
#   - .codex/config.toml
#   - .codex/hooks.json
#   - .codex/hooks/*
#   - .codex/agents/*
#
# It NEVER modifies:
#   - .etyb/plans/
#   - .claude/plans/
#   - existing backups (*.bak.TIMESTAMP)

set -euo pipefail

TARGET_ROOT=""
DRY_RUN=false
ON_CONFLICT="prompt"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET_ROOT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --force) ON_CONFLICT="replace"; shift ;;
    --on-conflict) ON_CONFLICT="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,20p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

case "$ON_CONFLICT" in
  prompt|replace|skip) ;;
  *)
    echo "error: --on-conflict must be one of: prompt, replace, skip" >&2
    exit 1
    ;;
esac

if [[ -z "$TARGET_ROOT" ]]; then
  echo "error: --target /path/to/project is required" >&2
  exit 1
fi

SOURCE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="$SOURCE_ROOT/.codex"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "error: source Codex runtime not found: $SOURCE_DIR" >&2
  exit 1
fi

mkdir -p "$TARGET_ROOT"
TARGET_DIR="$TARGET_ROOT/.codex"

echo "source:  $SOURCE_DIR"
echo "target:  $TARGET_DIR"
echo "mode:    $($DRY_RUN && echo DRY-RUN || echo APPLY) / on-conflict=$ON_CONFLICT"
echo ""

if [[ -e "$TARGET_DIR" ]]; then
  CHOICE=""
  case "$ON_CONFLICT" in
    replace) CHOICE="r" ;;
    skip) CHOICE="s" ;;
    prompt)
      echo "⚠ conflict: $TARGET_DIR already exists"
      echo "  [r] replace (backup to .codex.bak.TIMESTAMP)"
      echo "  [s] skip runtime install"
      read -r -p "  choice? [r/s] " CHOICE
      ;;
  esac

  case "$CHOICE" in
    r|R)
      if $DRY_RUN; then
        echo "[DRY-RUN] would back up $TARGET_DIR and install fresh"
      else
        mv "$TARGET_DIR" "$TARGET_ROOT/.codex.bak.$(date +%s)"
        cp -R "$SOURCE_DIR" "$TARGET_DIR"
        echo "✓ replaced project-scoped Codex runtime"
      fi
      ;;
    s|S|*)
      echo "— skipped Codex runtime install"
      exit 0
      ;;
  esac
else
  if $DRY_RUN; then
    echo "[DRY-RUN] would install project-scoped Codex runtime"
  else
    cp -R "$SOURCE_DIR" "$TARGET_DIR"
    echo "✓ installed project-scoped Codex runtime"
  fi
fi

echo ""
echo "runtime assets:"
echo "  - $TARGET_DIR/config.toml"
echo "  - $TARGET_DIR/hooks.json"
echo "  - $TARGET_DIR/hooks/"
echo "  - $TARGET_DIR/agents/"
