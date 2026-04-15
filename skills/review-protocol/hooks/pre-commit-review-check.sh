#!/usr/bin/env bash
# pre-commit-review-check.sh
# Fires before git commit to warn if no review evidence exists in the current session.
# This is a WARNING, not a blocker -- Tier 0-1 changes may legitimately skip review.

set -euo pipefail

# Colors for output
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Review evidence markers -- files or patterns that indicate a review was completed
REVIEW_MARKERS=(
    ".etyb/review-completion-*.md"
    ".etyb/review-response-*.md"
    "review-completion.md"
    "REVIEW.md"
)

# Check for review artifacts in the staging area or working directory
review_found=false

for marker in "${REVIEW_MARKERS[@]}"; do
    # Check if any matching files exist
    if compgen -G "$marker" > /dev/null 2>&1; then
        review_found=true
        break
    fi
done

# Also check if any staged files contain review completion markers
if ! $review_found; then
    staged_files=$(git diff --cached --name-only 2>/dev/null || true)
    if echo "$staged_files" | grep -qi "review\|review-completion\|review-response" 2>/dev/null; then
        review_found=true
    fi
done

# Also check recent git log messages for review evidence
if ! $review_found; then
    recent_messages=$(git log --oneline -5 --format="%s" 2>/dev/null || true)
    if echo "$recent_messages" | grep -qi "review\|reviewed\|code review\|review complete" 2>/dev/null; then
        review_found=true
    fi
done

if $review_found; then
    echo -e "${GREEN}[review-protocol]${NC} Review evidence found. Proceeding with commit."
else
    echo -e "${YELLOW}[review-protocol] WARNING: No review evidence detected.${NC}"
    echo ""
    echo "  Code review is mandatory for Tier 2+ changes at the Verify gate."
    echo "  If this is a Tier 0-1 change, this warning can be safely ignored."
    echo ""
    echo "  To request a review, use the review-protocol skill to dispatch"
    echo "  code-reviewer with focused context before committing."
    echo ""
    echo "  Proceeding with commit (this is a warning, not a block)."
fi

# Always allow the commit -- this is advisory, not blocking
exit 0
