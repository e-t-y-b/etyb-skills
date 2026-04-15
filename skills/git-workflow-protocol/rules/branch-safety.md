# Branch Safety Rules

Hard constraints for git workflow discipline. These are non-negotiable during any branch operation.

## Absolute Rules

1. **NEVER merge with failing tests.** If the test suite has regressions compared to baseline, the merge is blocked. Fix the tests first. No exceptions, no "I'll fix it after merge," no "it's just a flaky test."

2. **NEVER skip the baseline test run when creating a worktree.** The baseline is the anchor for detecting regressions. Without it, you cannot know if your changes broke something or if it was already broken. Run tests before making any changes.

3. **NEVER force-push to main/master without explicit user approval.** Force-pushing to protected branches rewrites history and can destroy collaborators' work. If you believe force-push is necessary, present the justification and wait for explicit "yes" from the user.

4. **ALWAYS compare test results against baseline before finishing a branch.** "All tests pass" is meaningless without context. The pre-finish gate compares current results against the recorded baseline. Only zero regressions is acceptable.

5. **ALWAYS confirm with the user before discarding a branch with uncommitted changes.** Discard is destructive and irreversible. Present what will be lost (uncommitted changes, unmerged commits) and require explicit confirmation before proceeding.

6. **ALWAYS clean up worktrees after branch finishing.** No orphaned worktrees. After a merge or discard, the worktree directory is removed, the branch is deleted, and stale references are pruned. The only exception is KEEP, where the worktree is intentionally preserved.

## Process Rules

7. **Run tests AGAIN after resolving merge conflicts.** Conflict resolution can introduce regressions that did not exist on either branch. A post-merge test run is mandatory.

8. **Never delete a branch that has unmerged commits without user confirmation.** Use `git branch -d` (safe delete) by default. Only use `git branch -D` (force delete) after explicit discard confirmation.

9. **Document pre-existing test failures at baseline time.** Pre-existing failures are not your responsibility, but they must be tracked so they are not confused with regressions you introduce.

10. **Verify .worktrees/ is in .gitignore before creating any worktree.** Worktree directories must never be committed to the repository.
