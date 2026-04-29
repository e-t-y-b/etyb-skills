#!/usr/bin/env bash
#
# Local-only audit pass over the etyb-skills repo. Surfaces gaps in
# OSS hygiene, branch state, release coverage, and the public/private
# boundary on git. Read-only — never writes, never pushes.
#
# Usage:
#   scripts/maintainer/audit-repo.sh
#
# Skips sections gracefully when their tools are missing (gh, git
# remote unreachable, etc.) so it stays useful in restricted
# environments. The skill layers judgment on top of these findings.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT" || exit 1

OWNER_REPO="e-t-y-b/etyb-skills"
STALE_PR_DAYS="${STALE_PR_DAYS:-14}"
STALE_BRANCH_DAYS="${STALE_BRANCH_DAYS:-30}"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
section() { echo; bold "── $1"; }
note() { echo "  $1"; }
warn() { echo "  ⚠ $1"; }

have_gh=0
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  have_gh=1
fi

# ---------------------------------------------------------------------------
section "Open PRs"
if [[ $have_gh -eq 1 ]]; then
  count="$(gh pr list --repo "$OWNER_REPO" --state open --json number --jq 'length')"
  if [[ "$count" -eq 0 ]]; then
    note "no open PRs"
  else
    note "$count open PR(s):"
    gh pr list --repo "$OWNER_REPO" --state open \
      --json number,title,author,createdAt,isDraft,reviewDecision,mergeable \
      --jq '.[] | "    #\(.number) [\(.author.login)] \(.title)  draft=\(.isDraft) review=\(.reviewDecision // "PENDING") mergeable=\(.mergeable) created=\(.createdAt[0:10])"'
    cutoff="$(date -u -v-"${STALE_PR_DAYS}"d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
      || date -u -d "${STALE_PR_DAYS} days ago" +%Y-%m-%dT%H:%M:%SZ)"
    stale="$(gh pr list --repo "$OWNER_REPO" --state open \
      --json number,title,createdAt \
      --jq ".[] | select(.createdAt < \"${cutoff}\") | \"#\(.number) \(.title)\"")"
    if [[ -n "$stale" ]]; then
      warn "stale PRs (>${STALE_PR_DAYS}d old):"
      printf '    %s\n' "${stale//$'\n'/$'\n    '}"
    fi
  fi
else
  warn "gh CLI not authed — skipping open-PR audit"
fi

# ---------------------------------------------------------------------------
section "Release tags vs CHANGELOG vs VERSION"
current_version="$(tr -d '[:space:]' < VERSION 2>/dev/null || true)"
note "VERSION = $current_version"

# Tags from local refs (cheap, no network).
git fetch --tags --quiet 2>/dev/null || true
last_tag="$(git tag --sort=-v:refname | head -1 || true)"
note "latest local tag = ${last_tag:-(none)}"

if [[ -n "$current_version" && "$last_tag" != "v$current_version" ]]; then
  warn "tag drift: VERSION says $current_version but latest tag is ${last_tag:-(none)} — run release runbook step 6"
fi

# CHANGELOG sections present?
if [[ -f CHANGELOG.md ]]; then
  if [[ -n "$current_version" ]] \
     && ! grep -qE "^## \[${current_version}\]" CHANGELOG.md; then
    warn "no CHANGELOG section for [$current_version]"
  fi
fi

if [[ $have_gh -eq 1 ]]; then
  releases="$(gh release list --repo "$OWNER_REPO" --limit 5 --json tagName,publishedAt \
    --jq '.[] | "    \(.tagName)  \(.publishedAt[0:10])"' 2>/dev/null || true)"
  if [[ -n "$releases" ]]; then
    note "recent GitHub releases:"
    echo "$releases"
  fi

  # Tags that exist locally but have no GitHub Release.
  released="$(gh release list --repo "$OWNER_REPO" --limit 100 --json tagName --jq '.[].tagName' 2>/dev/null || true)"
  unreleased=()
  while IFS= read -r tag; do
    [[ -z "$tag" ]] && continue
    grep -qx "$tag" <<<"$released" || unreleased+=("$tag")
  done < <(git tag --sort=-v:refname | head -10)
  if [[ ${#unreleased[@]} -gt 0 ]]; then
    warn "tags without a GitHub Release:"
    printf '    %s\n' "${unreleased[@]}"
  fi
fi

# ---------------------------------------------------------------------------
section "Branches"
if git remote get-url origin >/dev/null 2>&1; then
  git fetch --prune --quiet origin 2>/dev/null || true

  merged="$(git branch -r --merged origin/main 2>/dev/null \
    | grep -vE 'origin/HEAD|origin/main' | sed 's|^[[:space:]]*origin/||' || true)"
  if [[ -n "$merged" ]]; then
    warn "remote branches already merged into main (candidates for delete):"
    printf '    %s\n' "${merged//$'\n'/$'\n    '}"
  else
    note "no merged-but-undeleted remote branches"
  fi

  # Stale unmerged branches.
  cutoff_epoch="$(date -u -v-"${STALE_BRANCH_DAYS}"d +%s 2>/dev/null \
    || date -u -d "${STALE_BRANCH_DAYS} days ago" +%s)"
  stale_branches=()
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    ts="${line%% *}"
    name="${line#* }"
    [[ "$name" == "origin/HEAD" || "$name" == "origin/main" ]] && continue
    if [[ "$ts" -lt "$cutoff_epoch" ]]; then
      stale_branches+=("$(date -r "$ts" +%Y-%m-%d 2>/dev/null || date -d "@$ts" +%Y-%m-%d) $name")
    fi
  done < <(
    git for-each-ref --format='%(committerdate:unix) %(refname:short)' refs/remotes/origin 2>/dev/null
  )
  if [[ ${#stale_branches[@]} -gt 0 ]]; then
    warn "remote branches with no commits in >${STALE_BRANCH_DAYS}d:"
    printf '    %s\n' "${stale_branches[@]}"
  fi
else
  warn "no origin remote — skipping branch audit"
fi

# ---------------------------------------------------------------------------
section "Internal vs external boundary on git"
# Files .gitignore says are internal-only — confirm they are absent
# from the working tree at unexpected paths.
internal_paths=("MARKETPLACE.md" ".internal" ".etyb" ".claude/plans" ".claude/settings.local.json")
unexpected=()
for p in "${internal_paths[@]}"; do
  if [[ -e "$p" ]] && git ls-files --error-unmatch "$p" >/dev/null 2>&1; then
    unexpected+=("$p (tracked but listed as internal in .gitignore)")
  fi
done
# docs/plan-*.md are also gitignored; flag any that are tracked.
while IFS= read -r tracked; do
  [[ -z "$tracked" ]] && continue
  unexpected+=("$tracked (tracked but matches docs/plan-*.md ignore)")
done < <(git ls-files 'docs/plan-*.md' 2>/dev/null || true)

if [[ ${#unexpected[@]} -gt 0 ]]; then
  warn "internal items leaking into git:"
  printf '    %s\n' "${unexpected[@]}"
else
  note "no internal items tracked in git"
fi

# Skill that is committed but not published — confirm it stays out of
# manifest / marketplace / install scripts.
maintainer_skill_dir=".claude/skills/etyb-oss-maintainer"
if [[ -d "$maintainer_skill_dir" ]]; then
  for file in manifest.json .claude-plugin/marketplace.json scripts/install.sh scripts/install-codex-runtime.sh; do
    if [[ -f "$file" ]] && grep -q "etyb-oss-maintainer" "$file"; then
      warn "$file references etyb-oss-maintainer — internal skill should not be published"
    fi
  done
fi

# ---------------------------------------------------------------------------
section "OSS hygiene files"
required=(LICENSE README.md CONTRIBUTING.md CODE_OF_CONDUCT.md SECURITY.md CHANGELOG.md .github/CODEOWNERS .github/pull_request_template.md)
for f in "${required[@]}"; do
  if [[ -f "$f" ]]; then
    note "✓ $f"
  else
    warn "missing $f"
  fi
done

issue_templates="$(find .github/ISSUE_TEMPLATE -type f 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$issue_templates" -gt 0 ]]; then
  note "✓ .github/ISSUE_TEMPLATE/ ($issue_templates template(s))"
else
  warn "no issue templates under .github/ISSUE_TEMPLATE/"
fi

# ---------------------------------------------------------------------------
section "Working tree cleanliness"
if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
  warn "uncommitted changes present — audit reflects working tree, not last committed state"
fi

untracked="$(git status --porcelain 2>/dev/null | grep -c '^??' || true)"
if [[ "$untracked" -gt 0 ]]; then
  warn "$untracked untracked path(s) — review before publishing anything"
fi

echo
bold "Audit complete. Recommendations come from the skill, not this script."
