# Worktree Management

Complete lifecycle management for git worktrees — from creation through cleanup.

## When to Create a Worktree

Not every branch needs a worktree. Use this decision framework:

### Create a Worktree When

1. **Subagent needs an isolated workspace** — An agent task requires its own working directory that won't interfere with the main checkout. Agent worktrees use the `agent/<task-id>` branch prefix.

2. **Working on multiple features in parallel** — You need to switch between features without stashing or committing half-done work. Each feature gets its own worktree with a clean state.

3. **Risky experiment that might need to be discarded** — Spikes, proof-of-concepts, or exploratory work that has a good chance of being thrown away. Worktrees make discard clean — just delete the directory and branch.

4. **Spike or prototype that should not pollute main** — Throwaway code that exists only to answer a question. Once the question is answered, the worktree is discarded.

5. **Bug fix while mid-feature** — You are deep in a feature branch and an urgent fix comes in. Instead of stashing or committing incomplete work, create a worktree for the fix.

6. **Code review requiring a running environment** — You need to run someone else's branch to review it, but you don't want to switch away from your current work.

### Do NOT Create a Worktree When

- The change is small and can be done on the current branch
- You are the only person working on the project and can simply switch branches
- The task doesn't require running code (e.g., documentation-only changes)
- You are already in a worktree for a different reason — avoid worktrees-of-worktrees

## Creation Protocol

### Step 1: Choose Base Branch and Create Worktree

```bash
# Standard feature worktree based on main
git worktree add .worktrees/user-auth -b feature/user-auth main

# Fix worktree based on main
git worktree add .worktrees/login-bug -b fix/login-redirect main

# Spike worktree based on main
git worktree add .worktrees/graphql-spike -b spike/graphql-migration main

# Agent worktree based on main
git worktree add .worktrees/task-42 -b agent/task-42-refactor main

# Worktree based on a specific branch (not main)
git worktree add .worktrees/hotfix -b fix/critical-patch release/v2.1
```

### Step 2: Naming Convention

Branch names follow the pattern `<prefix>/<descriptive-name>`:

| Prefix | Purpose | Lifecycle | Example |
|--------|---------|-----------|---------|
| `feature/` | New feature | Medium-long (days to weeks) | `feature/user-authentication` |
| `fix/` | Bug fix | Short (hours to days) | `fix/null-pointer-cart` |
| `spike/` | Exploratory | Short (hours) — discard expected | `spike/redis-caching` |
| `agent/` | Subagent task | Short (single session) | `agent/task-42-refactor-api` |

Rules for branch names:
- Use lowercase with hyphens: `feature/user-auth`, not `feature/UserAuth`
- Be descriptive but concise: `fix/cart-total-rounding`, not `fix/bug`
- Include ticket/task ID when available: `feature/PROJ-123-user-auth`
- No spaces, no special characters except hyphens and forward slashes

### Step 3: Verify .gitignore

Before proceeding, confirm that `.worktrees/` is in `.gitignore`:

```bash
# Check if .worktrees/ is already ignored
grep -q "\.worktrees" .gitignore 2>/dev/null
if [ $? -ne 0 ]; then
  echo ".worktrees/" >> .gitignore
  echo "Added .worktrees/ to .gitignore"
fi
```

This is critical. Without it, worktree directories will show up as untracked files in the main checkout and could accidentally be committed.

### Step 4: Enter Worktree Directory

```bash
cd .worktrees/user-auth
```

You are now in an independent working directory with its own checkout of the codebase on the new branch.

## Dependency Bootstrapping

Every worktree is a fresh checkout. Dependencies must be installed before any work or testing can happen.

### Package Manager Detection

Detect the package manager by checking for lock files:

```bash
detect_package_manager() {
  if [ -f "package-lock.json" ]; then
    echo "npm"
  elif [ -f "yarn.lock" ]; then
    echo "yarn"
  elif [ -f "pnpm-lock.yaml" ]; then
    echo "pnpm"
  elif [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
    echo "bun"
  elif [ -f "Pipfile.lock" ]; then
    echo "pipenv"
  elif [ -f "poetry.lock" ]; then
    echo "poetry"
  elif [ -f "requirements.txt" ]; then
    echo "pip"
  elif [ -f "go.sum" ]; then
    echo "go"
  elif [ -f "Cargo.lock" ]; then
    echo "cargo"
  elif [ -f "Gemfile.lock" ]; then
    echo "bundler"
  elif [ -f "composer.lock" ]; then
    echo "composer"
  elif [ -f "mix.lock" ]; then
    echo "mix"
  else
    echo "unknown"
  fi
}
```

### Install Commands

| Package Manager | Install Command | Notes |
|----------------|-----------------|-------|
| npm | `npm ci` | Uses lockfile for deterministic installs |
| yarn | `yarn install --frozen-lockfile` | Prevents lockfile updates |
| pnpm | `pnpm install --frozen-lockfile` | Prevents lockfile updates |
| bun | `bun install --frozen-lockfile` | Fast, lockfile-pinned |
| pipenv | `pipenv install --dev` | Includes dev dependencies |
| poetry | `poetry install` | Uses poetry.lock |
| pip | `pip install -r requirements.txt` | Consider using a virtualenv |
| go | `go mod download` | Downloads all modules |
| cargo | `cargo fetch` | Downloads dependencies without building |
| bundler | `bundle install` | Uses Gemfile.lock |
| composer | `composer install` | PHP dependencies |
| mix | `mix deps.get` | Elixir dependencies |

### Verification

After installation, verify it succeeded:

```bash
# Check exit code
if [ $? -ne 0 ]; then
  echo "ERROR: Dependency installation failed"
  echo "Check the output above for details"
  echo "Common issues:"
  echo "  - Missing system dependencies"
  echo "  - Network connectivity"
  echo "  - Incompatible Node/Python/Go version"
  exit 1
fi

echo "Dependencies installed successfully"
```

### Environment-Specific Setup

Some projects require additional setup beyond dependency installation:

```bash
# Database setup (if applicable)
# Check for migration files or database config
if [ -f "prisma/schema.prisma" ]; then
  npx prisma generate
elif [ -f "db/migrate" ]; then
  bundle exec rails db:setup
fi

# Environment variables
if [ -f ".env.example" ] && [ ! -f ".env" ]; then
  cp .env.example .env
  echo "WARNING: Copied .env.example to .env — review and update values"
fi

# Build step (if needed for tests)
if grep -q '"build"' package.json 2>/dev/null; then
  npm run build
fi
```

## Baseline Testing

This is the most critical step. The baseline is your anchor for detecting regressions.

### Why Baseline Matters

Without a baseline, you cannot answer the question: "Did my changes break something, or was it already broken?" The baseline gives you:

- A count of passing tests before your changes
- A count of failing tests before your changes (pre-existing failures)
- A reference point for comparison after your changes

### Running the Baseline

```bash
# Detect test runner
detect_test_runner() {
  if [ -f "package.json" ]; then
    if grep -q '"test"' package.json; then
      echo "npm test"
    elif grep -q '"vitest"' package.json; then
      echo "npx vitest run"
    elif grep -q '"jest"' package.json; then
      echo "npx jest"
    fi
  elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || [ -f "setup.cfg" ]; then
    echo "pytest"
  elif [ -f "Cargo.toml" ]; then
    echo "cargo test"
  elif [ -f "go.mod" ]; then
    echo "go test ./..."
  elif [ -f "Gemfile" ]; then
    echo "bundle exec rspec"
  elif [ -f "mix.exs" ]; then
    echo "mix test"
  else
    echo "unknown"
  fi
}

# Run baseline
echo "=== BASELINE TEST RUN ==="
echo "Running tests BEFORE any changes..."
<test_command> 2>&1 | tee .worktree-baseline.log
echo "=== BASELINE COMPLETE ==="
```

### Recording the Baseline

Capture and record these metrics:

```
BASELINE RECORD
  Date: <timestamp>
  Branch: <branch-name>
  Base: <base-branch>
  Test Command: <command used>
  Total Tests: <count>
  Passing: <count>
  Failing: <count>
  Skipped: <count>
  Pre-existing Failures:
    - <test name>: <reason if known>
    - <test name>: <reason if known>
  Duration: <time>
```

Save this to a file in the worktree for later comparison:

```bash
# Save baseline results (example for a JSON-output test runner)
cat > .worktree-baseline.json << 'BASELINE'
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "branch": "$(git branch --show-current)",
  "base": "main",
  "total": <N>,
  "passing": <N>,
  "failing": <N>,
  "skipped": <N>,
  "pre_existing_failures": []
}
BASELINE
```

### Handling Pre-existing Failures

If the baseline has failing tests:

1. **Document them** — Note the test names and failure messages
2. **Do not fix them** — They are not your responsibility in this worktree
3. **Track them** — So you can distinguish them from regressions you introduce
4. **Report them** — Flag pre-existing failures in your branch finishing report

```bash
# If baseline has failures
echo "WARNING: Baseline has <N> pre-existing failures"
echo "These will be tracked separately from regressions"
echo "Do NOT attempt to fix pre-existing failures in this worktree"
echo "Pre-existing failures:"
# List them
```

## Directory Management

### Convention: .worktrees/ at Project Root

All worktrees live under `.worktrees/` at the project root:

```
project/
  .worktrees/
    user-auth/          # feature/user-auth
    login-bug/          # fix/login-redirect
    graphql-spike/      # spike/graphql-migration
    task-42/            # agent/task-42-refactor
  src/
  tests/
  package.json
  .gitignore            # Must include .worktrees/
```

### .gitignore Verification

The `.worktrees/` directory MUST be in `.gitignore`. Verify this at worktree creation time:

```bash
# Verify .worktrees/ is gitignored
if ! git check-ignore -q .worktrees/ 2>/dev/null; then
  echo "ERROR: .worktrees/ is not in .gitignore"
  echo "Adding it now..."
  echo ".worktrees/" >> .gitignore
  git add .gitignore
  git commit -m "chore: add .worktrees/ to .gitignore"
fi
```

### Listing Active Worktrees

```bash
# List all worktrees with their branches
git worktree list

# Example output:
# /path/to/project              abc1234 [main]
# /path/to/project/.worktrees/user-auth  def5678 [feature/user-auth]
# /path/to/project/.worktrees/login-bug  ghi9012 [fix/login-redirect]
```

### Worktree Health Check

Periodically check for stale or orphaned worktrees:

```bash
# Check for worktrees that no longer exist on disk
git worktree prune --dry-run

# If stale worktrees are found:
git worktree prune
echo "Pruned stale worktree references"

# List and review remaining worktrees
git worktree list --porcelain | while read line; do
  case "$line" in
    worktree\ *)
      path="${line#worktree }"
      if [ ! -d "$path" ]; then
        echo "WARNING: Worktree path does not exist: $path"
      fi
      ;;
  esac
done
```

## Cleanup

Cleanup happens after branch finishing. The specific cleanup depends on the finishing option chosen.

### After MERGE or DISCARD

```bash
# Remove the worktree directory
git worktree remove .worktrees/<name>

# If the worktree has uncommitted changes and you confirmed discard:
git worktree remove --force .worktrees/<name>

# Delete the local branch (safe delete — only if fully merged)
git branch -d <branch-name>

# Force delete (for discarded branches that were never merged)
git branch -D <branch-name>

# Clean up remote branch if it was pushed
git push origin --delete <branch-name>
```

### After PR Merges

```bash
# After the PR is merged on the remote:
git checkout main
git pull origin main

# Remove the worktree
git worktree remove .worktrees/<name>

# Delete the local branch
git branch -d <branch-name>
```

### After KEEP

No cleanup. The worktree stays alive for continued work. But do:

```bash
# Commit work in progress
git add -A
git commit -m "wip: <description of current state>"

# Push for backup
git push -u origin <branch-name>
```

### Cleanup Verification

After any cleanup, verify no orphaned worktrees remain:

```bash
# Verify cleanup
git worktree list
# Should only show the main worktree (and any intentionally kept worktrees)

# Prune any stale references
git worktree prune

# Verify no dangling branches
git branch --list 'feature/*' 'fix/*' 'spike/*' 'agent/*'
# Cross-reference with active worktrees — any branch without a worktree
# should either be merged or explicitly kept
```

### Never Leave Worktrees Hanging

This is a core principle. After every branch finishing operation, check:

1. Is the worktree removed (unless KEEP was chosen)?
2. Is the branch deleted (unless KEEP or PR-pending was chosen)?
3. Are stale references pruned?
4. Is the `.worktrees/` directory clean?

Orphaned worktrees waste disk space, create confusion about what work is active, and can cause git lock conflicts. Clean up immediately after finishing.

## Troubleshooting

### Common Issues

**"fatal: '<path>' is already checked out"**
- Another worktree already has this branch checked out
- Solution: `git worktree list` to find which worktree has it, then decide whether to remove that worktree or use a different branch name

**"fatal: '<branch>' already exists"**
- The branch name is already taken
- Solution: Use a different name or delete the existing branch if it is stale

**Lock file conflicts**
- Git uses lock files to prevent concurrent operations on the same repo
- Solution: Wait for the other operation to complete, or if it is stale: `git worktree unlock <path>`

**Dependencies differ between worktrees**
- Different branches may have different dependency versions
- Solution: Always run the install command after creating or switching to a worktree

**Tests behave differently in worktree vs main checkout**
- Usually caused by missing environment setup or cached state
- Solution: Verify all environment variables are set, clear test caches, re-run dependency install
