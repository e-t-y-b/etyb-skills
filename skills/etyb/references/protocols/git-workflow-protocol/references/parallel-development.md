# Parallel Development

Multi-worktree coordination for teams and agents working on concurrent features. This reference covers naming, isolation, integration, and conflict management.

## When to Parallelize

Parallel development makes sense when:

1. **Multiple independent features** can be developed simultaneously without blocking each other
2. **Subagents** are working on separate, well-scoped tasks that touch different parts of the codebase
3. **Time-critical work** where waiting for sequential completion is not acceptable
4. **Team size** supports it — each worktree represents a unit of work that someone (human or agent) owns

### When NOT to Parallelize

Do NOT create parallel worktrees when:

1. **Shared database schema changes** — Migration ordering matters. Two branches adding migrations will conflict on migration sequence numbers. One branch must merge first, then the other rebases.

2. **Shared API contract changes** — If branch A changes an API response format and branch B consumes that API, they must coordinate. Breaking changes affect all consumers.

3. **Tight coupling between modules** — If the feature in worktree A depends on code being written in worktree B, they are not truly independent. Sequence them instead.

4. **When one team's work depends on another's output** — If feature B cannot start until feature A produces a result (an API, a library, a data model), do not parallelize. Either sequence them or extract the shared dependency first.

5. **Small codebase with high overlap** — If the codebase is small enough that every feature touches the same files, parallel worktrees will create merge conflicts on almost every file. Sequential work is faster in this case.

6. **Single developer, small tasks** — The overhead of managing multiple worktrees is not worth it for quick, sequential tasks by one person.

## Naming Convention

### Per Feature

```
.worktrees/
  user-auth/            # feature/user-auth (owned by: agent-1 or dev-alice)
  payment-flow/         # feature/payment-flow (owned by: agent-2 or dev-bob)
  notification-system/  # feature/notification-system (owned by: agent-3 or dev-carol)
```

### Per Agent

When agents own worktrees, include the task ID:

```
.worktrees/
  task-42/              # agent/task-42-refactor-api
  task-43/              # agent/task-43-add-caching
  task-44/              # agent/task-44-update-docs
```

### Per Team (Monorepo)

In monorepos where teams own different services:

```
.worktrees/
  team-auth-session-mgmt/     # feature/auth-team/session-management
  team-payments-stripe-v3/    # feature/payments-team/stripe-v3-migration
  team-platform-k8s-upgrade/  # feature/platform-team/k8s-1.29-upgrade
```

### Rules for Parallel Naming

1. **Names must be unique** across all active worktrees
2. **Names should indicate the domain** — not just a ticket number
3. **Owner should be identifiable** from the branch name or a tracking document
4. **Keep names short but descriptive** — you will type them often

## Shared-Nothing Development

The cardinal rule of parallel worktrees: **each worktree is independent. No shared state.**

### What This Means

- Each worktree has its own copy of all source files
- Each worktree installs its own dependencies
- Each worktree runs its own test suite independently
- No worktree should read files from or write files to another worktree
- No worktree should depend on another worktree being in a specific state

### Why Shared-Nothing

1. **Isolation** — A failure in one worktree cannot affect another
2. **Independence** — Worktrees can be created, finished, or discarded without impacting others
3. **Reproducibility** — Each worktree's state is entirely determined by its own branch
4. **Parallelism** — True parallel work requires zero coordination during development

### Practical Implications

```bash
# WRONG: Sharing node_modules between worktrees
ln -s ../../node_modules .worktrees/feature-a/node_modules  # DO NOT DO THIS

# RIGHT: Each worktree installs its own dependencies
cd .worktrees/feature-a && npm ci
cd .worktrees/feature-b && npm ci

# WRONG: One worktree importing from another
import { helper } from '../../.worktrees/feature-b/src/utils'  # DO NOT DO THIS

# RIGHT: If you need shared code, commit it to a shared branch first
```

### Shared Resources (Databases, Services)

If worktrees need to run against local databases or services:

- **Use different ports or database names** for each worktree
- **Use environment variables** to configure per-worktree resources
- **Use Docker Compose** with different project names per worktree

```bash
# Worktree A: uses port 5432 and database "myapp_feature_a"
DATABASE_URL=postgres://localhost:5432/myapp_feature_a npm test

# Worktree B: uses port 5432 and database "myapp_feature_b"
DATABASE_URL=postgres://localhost:5432/myapp_feature_b npm test
```

## Integration Protocol

After parallel work completes, all branches need to be integrated. This is the most critical phase of parallel development.

### The Integration Sequence

```
Step 1: All worktrees complete their work
         (each passes their own pre-finish gate)
            |
Step 2: Create an integration branch from main
            |
Step 3: Merge feature branches one at a time
         (run tests after each merge)
            |
Step 4: Run full test suite on the integration branch
            |
Step 5: If all green: merge integration branch to main
         If conflicts or failures: resolve and re-test
```

### Step-by-Step Integration

```bash
# Step 1: Verify all branches pass their pre-finish gate
# (Each branch should have already passed independently)

# Step 2: Create integration branch
git checkout main
git pull origin main
git checkout -b integration/sprint-42

# Step 3: Merge branches one at a time
git merge feature/user-auth
<test_command>  # Run tests after first merge

git merge feature/payment-flow
<test_command>  # Run tests after second merge

git merge feature/notification-system
<test_command>  # Run tests after third merge

# Step 4: Full test suite on combined code
<test_command>
# Verify: total tests >= sum of all new tests + baseline
# Verify: 0 regressions

# Step 5: If all green, merge to main
git checkout main
git merge integration/sprint-42
<test_command>  # Final verification
git push origin main

# Cleanup
git branch -d integration/sprint-42
```

### Merge Order Matters

When integrating multiple branches, the order can affect conflict resolution:

1. **Merge the largest/most impactful branch first** — it will have the fewest conflicts since it is closest to main
2. **Merge branches that modify shared files last** — so you can see the accumulated changes before resolving
3. **If two branches modify the same file**, merge the one with fewer changes to that file first

### Integration Failures

If the integration branch has test failures:

1. **Identify which merge introduced the failure** — you ran tests after each merge, so you know
2. **Fix the issue on the integration branch** — this is an integration fix, not a feature fix
3. **Re-run the full test suite** after the fix
4. **Do not push fixes back to feature branches** — the feature branches are done; integration fixes live on the integration branch

## Conflict Detection

Detect conflicts BEFORE full integration to catch problems early and plan resolution.

### Early Detection with merge-tree

```bash
# Preview conflicts between two branches without actually merging
git merge-tree $(git merge-base main feature/user-auth) main feature/user-auth

# If the output shows conflict markers (<<<<<<< / ======= / >>>>>>>),
# these branches will conflict when merged

# Check pairwise conflicts between parallel branches
git merge-tree \
  $(git merge-base feature/user-auth feature/payment-flow) \
  feature/user-auth \
  feature/payment-flow
```

### Automated Conflict Check Script

```bash
#!/bin/bash
# Check all active feature branches for pairwise conflicts

branches=($(git branch --list 'feature/*' | sed 's/^[* ]*//' ))

echo "Checking ${#branches[@]} branches for conflicts..."

for ((i=0; i<${#branches[@]}; i++)); do
  for ((j=i+1; j<${#branches[@]}; j++)); do
    a="${branches[$i]}"
    b="${branches[$j]}"
    base=$(git merge-base "$a" "$b")
    output=$(git merge-tree "$base" "$a" "$b" 2>&1)

    if echo "$output" | grep -q "^<<<<<<"; then
      echo "CONFLICT: $a <-> $b"
    else
      echo "  clean: $a <-> $b"
    fi
  done
done
```

### Common Conflict Types

| Type | Cause | Resolution Strategy |
|------|-------|---------------------|
| **Same file, different sections** | Two branches add code to the same file in different places | Usually auto-resolves; review to ensure logical consistency |
| **Same file, same section** | Two branches modify the same lines | Manual resolution; understand both changes and combine intent |
| **Import/dependency changes** | Both branches add different dependencies | Combine both additions; check for version conflicts |
| **Configuration changes** | Both branches modify config files | Merge both config changes; test for compatibility |
| **File rename + modification** | One branch renames a file, another modifies it | Git may not auto-detect; manually apply modifications to renamed file |
| **Deleted + modified** | One branch deletes a file, another modifies it | Decide: is the file needed? If yes, keep modifications. If no, delete. |

### Conflict Prevention

Best practices to minimize conflicts during parallel development:

1. **Divide work by module/directory** — Each worktree owns a distinct part of the codebase
2. **Avoid modifying shared files** — If two features both need to change a shared config, coordinate or sequence that change
3. **Keep branches short-lived** — The longer a branch lives, the more main diverges, the more conflicts accumulate
4. **Rebase periodically** (on feature branches only) — Keep feature branches up to date with main to reduce final merge conflicts
5. **Communicate about shared files** — If you must modify a shared file, tell other parallel developers

```bash
# Keep a feature branch up to date with main (reduces integration conflicts)
cd .worktrees/user-auth
git fetch origin main
git merge origin/main
# Resolve any conflicts now (smaller, incremental)
<test_command>  # Verify tests still pass after merge
```

## Communication Between Worktrees

Worktrees are isolated, but sometimes parallel work produces artifacts that others need.

### Shared Artifacts Protocol

If one worktree produces something another needs (an API contract, a shared type, a schema):

1. **Commit the artifact to a shared branch** — Not to either feature branch
2. **Both feature branches merge the shared branch** — They get the artifact without depending on each other
3. **The shared branch is minimal** — Only the artifact, no feature code

```bash
# Worktree A produces a shared API type
git checkout -b shared/api-contract-v2 main
# Add only the shared type definition
git add src/types/api-contract.ts
git commit -m "chore: add v2 API contract type for auth and payment features"
git push -u origin shared/api-contract-v2

# Worktree A merges it
cd .worktrees/user-auth
git merge shared/api-contract-v2

# Worktree B merges it
cd .worktrees/payment-flow
git merge shared/api-contract-v2

# Both worktrees now have the shared artifact without depending on each other
```

### When to Use Shared Branches

- **Shared type definitions** that multiple features consume
- **Database migration ordering** that must be agreed upon before feature work
- **API contracts** that define the interface between systems
- **Configuration** that multiple features need (e.g., feature flag names)

### When NOT to Use Shared Branches

- Feature code — each feature is independent
- Test fixtures — each worktree owns its own test setup
- Documentation — can be merged during integration

## Monitoring Parallel Progress

### Status Dashboard

Track the status of all parallel worktrees:

```bash
#!/bin/bash
# Show status of all active worktrees

echo "=== PARALLEL DEVELOPMENT STATUS ==="
echo ""

git worktree list --porcelain | while read line; do
  case "$line" in
    worktree\ *)
      path="${line#worktree }"
      ;;
    branch\ *)
      branch="${line#branch refs/heads/}"
      if [ "$branch" != "main" ] && [ "$branch" != "master" ]; then
        # Count commits ahead of main
        ahead=$(git rev-list --count main.."$branch" 2>/dev/null || echo "?")
        # Check for uncommitted changes
        changes=$(cd "$path" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        echo "  Branch: $branch"
        echo "  Path: $path"
        echo "  Commits ahead of main: $ahead"
        echo "  Uncommitted changes: $changes files"
        echo ""
      fi
      ;;
  esac
done
```

### Health Checks

Periodically verify all parallel worktrees are healthy:

1. **Dependencies installed** — No missing modules or packages
2. **Tests pass independently** — Each worktree's test suite is green
3. **Branch is not stale** — Has recent commits, not abandoned
4. **No conflict with main** — Periodic merge from main succeeds cleanly

## Scaling Parallel Development

### For 2-3 Parallel Worktrees

- Manual coordination is fine
- Direct merge to main after each branch finishes
- Conflict detection optional (low probability)

### For 4-10 Parallel Worktrees

- Use an integration branch
- Run conflict detection before integration
- Assign a merge order based on dependency analysis
- Consider a "merge coordinator" role

### For 10+ Parallel Worktrees (Monorepo / Large Team)

- Divide by service or module with clear ownership
- Use CI-based integration testing (merge queue)
- Automated conflict detection on every push
- Feature flags to decouple deployment from integration
- Consider trunk-based development with short-lived branches instead

### Diminishing Returns

More parallelism is not always better. The overhead of managing worktrees, resolving conflicts, and coordinating integration grows with the number of parallel branches. The sweet spot for most teams is 3-5 parallel worktrees per repository.

Beyond that, consider:
- Breaking the monorepo into smaller repos
- Using feature flags instead of long-lived branches
- Sequencing dependent work instead of parallelizing it
