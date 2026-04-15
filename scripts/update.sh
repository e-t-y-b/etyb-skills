#!/usr/bin/env bash
#
# etyb-skills update script
# Safely updates etyb-skills to the latest published version.
#
# Usage:
#   ./scripts/update.sh              # interactive update (recommended)
#   ./scripts/update.sh --check      # check for updates, do not apply
#   ./scripts/update.sh --force      # skip confirmation prompts
#   ./scripts/update.sh --branch NAME  # update to a specific branch (default: main)
#
# Guarantees:
#   - Never modifies .etyb/plans/, .claude/plans/, or .claude/settings.local.json
#   - Warns before overwriting any local modifications to skill files
#   - Preserves git history (uses git fetch + merge, not destructive)
#   - Prints a clear before/after version summary

set -euo pipefail

REPO_URL="https://github.com/e-t-y-b/etyb-skills.git"
MANIFEST_URL="https://raw.githubusercontent.com/e-t-y-b/etyb-skills/main/manifest.json"
BRANCH="main"
CHECK_ONLY=false
FORCE=false

# -------- argument parsing --------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check) CHECK_ONLY=true; shift ;;
    --force) FORCE=true; shift ;;
    --branch) BRANCH="$2"; shift 2 ;;
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

# -------- preflight --------
if ! command -v git >/dev/null 2>&1; then
  echo "error: git not found in PATH" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl not found in PATH" >&2
  exit 1
fi

cd "$(dirname "$0")/.."

if [[ ! -d .git ]]; then
  echo "error: this script expects to run inside a git clone of etyb-skills" >&2
  echo "hint: git clone $REPO_URL" >&2
  exit 1
fi

# -------- read local version --------
LOCAL_VERSION="unknown"
if [[ -f VERSION ]]; then
  LOCAL_VERSION=$(tr -d '[:space:]' < VERSION)
fi

# -------- fetch remote manifest --------
echo "→ checking $MANIFEST_URL ..."
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  REMOTE_MANIFEST=$(curl -fsSL -H "Authorization: token $GITHUB_TOKEN" "$MANIFEST_URL" || true)
else
  REMOTE_MANIFEST=$(curl -fsSL "$MANIFEST_URL" || true)
fi
if [[ -z "$REMOTE_MANIFEST" ]]; then
  echo "error: could not fetch remote manifest from $MANIFEST_URL" >&2
  echo "" >&2
  echo "possible causes:" >&2
  echo "  - repo is private → set GITHUB_TOKEN and retry, or use 'git pull' directly" >&2
  echo "  - network / proxy blocking raw.githubusercontent.com" >&2
  echo "  - canonical URL moved → check https://github.com/e-t-y-b/etyb-skills" >&2
  exit 1
fi

REMOTE_VERSION=$(echo "$REMOTE_MANIFEST" | grep -E '"version"[[:space:]]*:' | head -1 | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
if [[ -z "$REMOTE_VERSION" ]]; then
  echo "error: could not parse remote version from manifest" >&2
  exit 1
fi

echo "  local:  $LOCAL_VERSION"
echo "  remote: $REMOTE_VERSION"

if [[ "$LOCAL_VERSION" == "$REMOTE_VERSION" ]]; then
  echo "✓ already on latest version"
  exit 0
fi

if $CHECK_ONLY; then
  echo ""
  echo "update available: $LOCAL_VERSION → $REMOTE_VERSION"
  echo "run without --check to apply"
  exit 0
fi

# -------- protect user data --------
echo ""
echo "user data that will NOT be touched:"
for p in .etyb/plans .claude/plans .claude/settings.local.json; do
  if [[ -e "$p" ]]; then
    echo "  ✓ $p (preserved)"
  fi
done

# -------- check for local modifications --------
if [[ -n "$(git status --porcelain)" ]]; then
  echo ""
  echo "⚠ you have uncommitted local changes:"
  git status --short | sed 's/^/    /'
  echo ""
  if ! $FORCE; then
    read -r -p "continue? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || { echo "aborted"; exit 1; }
  fi
fi

# -------- confirm --------
if ! $FORCE; then
  echo ""
  read -r -p "update $LOCAL_VERSION → $REMOTE_VERSION on branch '$BRANCH'? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] || { echo "aborted"; exit 0; }
fi

# -------- apply --------
echo ""
echo "→ git fetch ..."
git fetch origin "$BRANCH"

echo "→ git merge --ff-only origin/$BRANCH ..."
if ! git merge --ff-only "origin/$BRANCH"; then
  echo ""
  echo "error: fast-forward failed. Your branch has diverged from origin/$BRANCH." >&2
  echo "hint: resolve manually with 'git pull --rebase' or 'git merge origin/$BRANCH'" >&2
  exit 1
fi

# -------- verify --------
NEW_VERSION=$(tr -d '[:space:]' < VERSION)
echo ""
echo "✓ updated to $NEW_VERSION"
echo ""
echo "see CHANGELOG.md for what's new:"
echo "  https://github.com/e-t-y-b/etyb-skills/blob/main/CHANGELOG.md"
