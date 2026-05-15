# Branch Finishing Protocol

The 4-option protocol for completing work on a branch. Every branch must end with one of these options. No branch should live forever without a decision.

## Pre-Finish Gate (MANDATORY)

Before ANY finishing option, this gate MUST pass. No exceptions.

### Step 1: Run Full Test Suite

```bash
# Run the same test command used for the baseline
<test_command> 2>&1 | tee .worktree-finish-results.log
```

Capture:
- Total tests run
- Tests passing
- Tests failing
- Tests skipped
- Duration

### Step 2: Compare Against Baseline

Load the baseline from `.worktree-baseline.json` (or `.worktree-baseline.log`) and compare:

```
PRE-FINISH GATE CHECK
  Baseline:  <X> total, <Y> passing, <Z> failing
  Current:   <X> total, <Y> passing, <Z> failing
  New Tests: <count of tests added>
  Regressions: <count of tests that were passing and now fail>
  Fixed: <count of tests that were failing and now pass>
```

### Step 3: Evaluate Results

**GREEN — No Regressions**
- All baseline-passing tests still pass
- New tests (if any) also pass
- Result: Proceed to finishing options 1-4

**YELLOW — Pre-existing Failures Only**
- All baseline-passing tests still pass
- Pre-existing failures remain (not your fault)
- New tests (if any) also pass
- Result: Proceed, but document the pre-existing failures

**RED — Regressions Detected**
- One or more tests that were passing in baseline are now failing
- Result: **STOP. Do not proceed. Fix the regressions first.**

```
GATE BLOCKED — REGRESSIONS DETECTED
  The following tests were passing in baseline but are now failing:
    - <test name>: <failure message>
    - <test name>: <failure message>

  Action Required:
    1. Fix the regressions
    2. Run tests again
    3. Re-run the pre-finish gate
    4. Do NOT proceed to any finishing option until gate is GREEN
```

### Step 4: Proceed to Options

Once the gate is GREEN (or YELLOW with documented pre-existing failures), choose a finishing option:

| Condition | Recommended Option |
|-----------|-------------------|
| Tests pass + review done + ready to ship | **Option 1: MERGE** |
| Tests pass + needs human or team review | **Option 2: PR** |
| Work in progress + not ready | **Option 3: KEEP** |
| Experiment failed + not worth keeping | **Option 4: DISCARD** |

---

## Option 1: MERGE

**When to use**: All tests pass, code review is complete (or not required), and the work is ready to integrate into the target branch.

### Decision Criteria

- [ ] Pre-finish gate is GREEN
- [ ] Code has been reviewed (or review is not required for this change)
- [ ] No open concerns or TODOs that block integration
- [ ] The target branch is up to date

### Steps

```bash
# 1. Ensure you are in the main project directory (not the worktree)
cd /path/to/project

# 2. Checkout the target branch
git checkout main

# 3. Pull latest changes
git pull origin main

# 4. Merge the feature branch
git merge feature/user-auth

# 5. If merge conflicts arise:
#    - Resolve conflicts manually
#    - Stage resolved files: git add <file>
#    - Complete merge: git commit

# 6. Run tests AGAIN on the merged code
#    This catches integration issues that weren't visible on the branch
<test_command>

# 7. If tests pass: push
git push origin main

# 8. Clean up worktree
git worktree remove .worktrees/user-auth

# 9. Delete the local branch
git branch -d feature/user-auth

# 10. Delete the remote branch (if it was pushed)
git push origin --delete feature/user-auth
```

### Why Merge Over Rebase

This protocol prefers `git merge` over `git rebase` for integration because:

1. **Traceability** — Merge commits show when and where integration happened
2. **Safety** — Merge doesn't rewrite history; rebase does
3. **Bisectability** — Merge preserves the original commit sequence for `git bisect`
4. **Collaboration** — Rebasing published branches causes problems for collaborators

Exception: For small, single-commit branches with no collaboration, rebase is acceptable if the team prefers linear history.

### Post-Merge Verification

```bash
# Verify the merge
git log --oneline -5
# Should show the merge commit

# Verify tests still pass
<test_command>

# Verify worktree is removed
git worktree list
# Should not show the feature worktree

# Verify branch is deleted
git branch --list 'feature/user-auth'
# Should return nothing
```

### Merge Report

```
BRANCH FINISHING — OPTION 1: MERGE
  Branch: feature/user-auth
  Target: main
  Test Results: 142 total, 142 passing, 0 failing
  Baseline Comparison: GREEN — no regressions
  Merge Conflicts: none
  Post-Merge Tests: 142 total, 142 passing, 0 failing
  Worktree: removed (.worktrees/user-auth)
  Branch: deleted (local + remote)
  Status: COMPLETE
```

---

## Option 2: PR (Pull Request)

**When to use**: Tests pass, but the work needs human review, team discussion, or CI validation before merging.

### Decision Criteria

- [ ] Pre-finish gate is GREEN
- [ ] Work is complete (not a WIP)
- [ ] Changes should be reviewed before integration
- [ ] Team uses PR-based workflow

### Steps

```bash
# 1. Ensure all changes are committed
git status
# If there are uncommitted changes:
git add <files>
git commit -m "feat: <description>"

# 2. Push the branch to remote
git push -u origin feature/user-auth

# 3. Create the pull request
gh pr create \
  --title "feat: add user authentication" \
  --body "## Summary
- Implemented JWT-based user authentication
- Added login, logout, and session refresh endpoints
- Includes 24 new tests, all passing

## Test Results
- Baseline: 118 total, 118 passing
- Current: 142 total, 142 passing
- Regressions: 0
- New tests: 24

## Checklist
- [x] Tests pass
- [x] No regressions from baseline
- [x] Code follows project conventions
- [ ] Reviewed by team"

# 4. Note the PR URL for tracking
echo "PR created: <url>"
```

### While PR is Open

The worktree stays alive while the PR is open. This allows:

- Responding to review feedback
- Making requested changes
- Running tests after changes

```bash
# After making changes based on review feedback:
cd .worktrees/user-auth
# Make changes...
git add <files>
git commit -m "fix: address review feedback — rename handler, add validation"
git push

# Re-run tests to verify
<test_command>
```

### After PR Merges

Once the PR is merged on the remote:

```bash
# 1. Return to main project directory
cd /path/to/project

# 2. Update main
git checkout main
git pull origin main

# 3. Remove the worktree
git worktree remove .worktrees/user-auth

# 4. Delete the local branch
git branch -d feature/user-auth

# 5. Remote branch is usually auto-deleted by the PR merge
# If not:
git push origin --delete feature/user-auth
```

### PR Report

```
BRANCH FINISHING — OPTION 2: PR
  Branch: feature/user-auth
  Target: main
  Test Results: 142 total, 142 passing, 0 failing
  Baseline Comparison: GREEN — no regressions
  PR: #<number> — <url>
  Worktree: kept (pending PR review)
  Status: PENDING REVIEW
```

---

## Option 3: KEEP

**When to use**: Work is in progress. Not ready for merge or review, but progress should be saved.

### Decision Criteria

- Work is partially complete
- More development needed
- Want to save progress and optionally back up to remote
- May need to context-switch and come back later

### Steps

```bash
# 1. Commit all current work (even if incomplete)
git add -A
git commit -m "wip: <description of current state>

Work in progress. Remaining:
- <task 1>
- <task 2>
- <task 3>"

# 2. Push to remote for backup
git push -u origin feature/user-auth

# 3. Leave the worktree in place
echo "Worktree kept at .worktrees/user-auth"
echo "Branch: feature/user-auth"
echo "Resume work by: cd .worktrees/user-auth"
```

### Returning to Kept Work

When resuming work on a kept worktree:

```bash
# 1. Enter the worktree
cd .worktrees/user-auth

# 2. Pull any changes (if collaborating)
git pull origin feature/user-auth

# 3. Check current state
git status
git log --oneline -5

# 4. Continue working
# When ready to finish, run the pre-finish gate again
```

### Keep Report

```
BRANCH FINISHING — OPTION 3: KEEP
  Branch: feature/user-auth
  Committed: yes — "wip: implement login endpoint"
  Pushed: yes — origin/feature/user-auth
  Worktree: kept (.worktrees/user-auth)
  Remaining Work:
    - Complete session refresh endpoint
    - Add integration tests
    - Update API documentation
  Status: IN PROGRESS
```

---

## Option 4: DISCARD

**When to use**: The experiment, spike, or work did not produce useful results and should be thrown away.

### Decision Criteria

- Spike or experiment that didn't pan out
- Approach was wrong — starting over would be better
- Code has no value worth preserving

### CRITICAL: User Confirmation Required

**NEVER discard without explicit user confirmation.** Discarding is destructive and irreversible.

```
WARNING: DISCARD will permanently delete all work on this branch.

Branch: spike/graphql-migration
Uncommitted changes: 4 files modified, 2 files added
Commits on branch: 3 (not on main)

Are you sure you want to discard all work on spike/graphql-migration?
This action CANNOT be undone.

Type 'yes' to confirm discard, or choose a different option:
  - KEEP: Save progress and come back later
  - PR: Submit for review even if uncertain
```

### Steps (After User Confirmation)

```bash
# 1. Return to main project directory
cd /path/to/project

# 2. Checkout main (or any branch that is not the one being deleted)
git checkout main

# 3. Force-remove the worktree (--force because there may be uncommitted changes)
git worktree remove --force .worktrees/graphql-spike

# 4. Force-delete the branch (capital -D because it was never merged)
git branch -D spike/graphql-migration

# 5. Delete remote branch if it was pushed
git push origin --delete spike/graphql-migration 2>/dev/null || true
```

### Post-Discard Verification

```bash
# Verify worktree is gone
git worktree list
# Should not show the spike worktree

# Verify branch is gone
git branch --list 'spike/graphql-migration'
# Should return nothing

# Prune any stale references
git worktree prune
```

### Discard Report

```
BRANCH FINISHING — OPTION 4: DISCARD
  Branch: spike/graphql-migration
  User Confirmation: received
  Reason: GraphQL migration approach too complex for current architecture
  Uncommitted Changes: discarded (4 files modified, 2 files added)
  Commits Discarded: 3
  Worktree: force-removed (.worktrees/graphql-spike)
  Branch: force-deleted (local + remote)
  Status: DISCARDED
```

---

## Decision Matrix

Quick reference for choosing the right finishing option:

```
                      Tests Pass?
                     /           \
                   YES            NO
                  /                \
         Ready to integrate?     FIX TESTS FIRST
        /         |        \      (do not proceed)
      YES      NEED       NO
       |      REVIEW       |
       |         |         |
  Review done?   |    Worth keeping?
   /      \      |     /        \
 YES      NO     |   YES        NO
  |        |     |    |          |
MERGE    PR     PR   KEEP    DISCARD
                              (confirm!)
```

### Option Comparison Table

| Aspect | MERGE | PR | KEEP | DISCARD |
|--------|-------|----|------|---------|
| Tests must pass | Yes | Yes | No | No |
| Review required | Already done | Requested | No | No |
| Work complete | Yes | Yes | No | N/A |
| User confirmation | No | No | No | **YES** |
| Worktree removed | Yes | After PR merges | No | Yes (force) |
| Branch deleted | Yes | After PR merges | No | Yes (force) |
| Remote cleanup | If pushed | Auto on merge | No | If pushed |
| Reversible | Via git (revert) | Via PR close | Always | **NO** |

---

## Edge Cases

### Merge Conflicts During Merge (Option 1)

If `git merge` produces conflicts:

1. **Do not panic.** Conflicts are normal.
2. Review each conflicted file: `git status`
3. Resolve conflicts manually in each file
4. Stage resolved files: `git add <file>`
5. Complete the merge: `git commit`
6. **Run tests again** after resolving conflicts
7. If tests fail after conflict resolution: you introduced a regression during resolution. Fix it before pushing.

### PR with Merge Conflicts (Option 2)

If the PR shows merge conflicts on the remote:

```bash
# Update the feature branch with latest main
cd .worktrees/user-auth
git fetch origin main
git merge origin/main

# Resolve conflicts
# Stage and commit
git add <files>
git commit -m "merge: resolve conflicts with main"

# Run tests
<test_command>

# Push updated branch
git push
```

### Partially Merged Work

If some commits from the branch have already been cherry-picked to main:

1. Check which commits are already on main: `git log main..<branch>`
2. Only the remaining commits need to be merged
3. Consider using `git merge` anyway — git is smart about already-merged commits

### Abandoned Worktrees

If a worktree was kept but never returned to:

1. Check if the branch has any unique commits: `git log main..<branch>`
2. If yes: decide whether to MERGE, PR, or DISCARD
3. If no unique commits: safe to remove without data loss
4. Run the finishing protocol for the chosen option

### Multiple People Working on Same Branch

If the branch has been shared:

1. Coordinate with collaborators before finishing
2. Ensure all collaborators have pushed their work
3. Pull latest: `git pull origin <branch>`
4. Then proceed with the finishing protocol

---

## Anti-Patterns

### Never Do These

1. **Never merge with failing tests.** The pre-finish gate exists for a reason. No test failures, no exceptions, no "I'll fix it after merge."

2. **Never skip the baseline comparison.** "All tests pass" means nothing without knowing the baseline. You might have deleted tests that were failing.

3. **Never force-push to main.** If you need to fix something on main, create a new commit. Force-push to main destroys history and can break collaborators.

4. **Never leave worktrees orphaned.** Every branch finishing operation includes cleanup. No exceptions.

5. **Never discard without confirmation.** Even if you are sure. Even if it is a spike. Always confirm with the user.

6. **Never merge a branch that has not been tested in its final state.** If you resolved merge conflicts, run tests again. If you rebased, run tests again. Any change to the code requires a new test run.
