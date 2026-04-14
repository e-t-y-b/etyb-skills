# Code Quality — Deep Reference

**Always use `WebSearch` to verify current tool versions, linter rule sets, and framework updates before giving code quality advice. The linting and static analysis ecosystem evolves rapidly — especially the Rust-based tool revolution in JavaScript and Python.**

## Table of Contents
1. [Code Smells and Detection](#1-code-smells-and-detection)
2. [SOLID Principles in Code Review](#2-solid-principles-in-code-review)
3. [DRY, KISS, YAGNI in Practice](#3-dry-kiss-yagni-in-practice)
4. [Complexity Metrics](#4-complexity-metrics)
5. [Naming and Readability](#5-naming-and-readability)
6. [Error Handling Patterns](#6-error-handling-patterns)
7. [Static Analysis Tools by Language](#7-static-analysis-tools-by-language)
8. [Code Coverage Analysis](#8-code-coverage-analysis)
9. [Technical Debt Quantification](#9-technical-debt-quantification)
10. [Refactoring Recommendations](#10-refactoring-recommendations)
11. [AI-Assisted Code Review Tools](#11-ai-assisted-code-review-tools)
12. [Code Quality Gates and CI Integration](#12-code-quality-gates-and-ci-integration)
13. [Language-Specific Quality Patterns](#13-language-specific-quality-patterns)
14. [Code Quality Review Checklist](#14-code-quality-review-checklist)

---

## 1. Code Smells and Detection

Code smells are surface indicators of deeper problems. They aren't bugs — the code works — but they signal maintainability, readability, or design issues that will compound over time.

### Common Code Smells by Category

**Bloaters** — code that has grown too large to manage:

| Smell | Signal | Impact | Fix |
|-------|--------|--------|-----|
| Long Method | Method > 20-30 lines | Hard to understand, test, reuse | Extract Method |
| Large Class | Class with too many responsibilities | Violates SRP, hard to modify | Extract Class |
| Long Parameter List | Function with > 3-4 parameters | Hard to call correctly, fragile | Introduce Parameter Object |
| Primitive Obsession | Using primitives instead of small objects | Missing domain concepts, validation scattered | Replace with Value Objects |
| Data Clumps | Same group of variables appears together repeatedly | Duplicated concepts | Extract into a class/type |

**Object-Orientation Abusers** — misuse of OOP mechanisms:

| Smell | Signal | Impact | Fix |
|-------|--------|--------|-----|
| Switch Statements | Repeated switch/if-else on type | Violated OCP, forgotten cases | Replace with polymorphism or strategy pattern |
| Refused Bequest | Subclass ignores inherited methods | Wrong abstraction hierarchy | Replace inheritance with composition |
| Temporary Field | Fields only used in some paths | Confusing, null checks everywhere | Extract class or use Optional/Maybe |
| Alternative Classes | Different classes, same interface | Missed abstraction | Unify interface, use strategy |

**Change Preventers** — code that makes changes risky and expensive:

| Smell | Signal | Impact | Fix |
|-------|--------|--------|-----|
| Divergent Change | One class modified for many unrelated reasons | SRP violation, merge conflicts | Split by responsibility |
| Shotgun Surgery | One change requires touching many classes | High coupling, risk of missing something | Move related code together |
| Parallel Inheritance | Adding a subclass requires adding another elsewhere | Tight hierarchical coupling | Flatten hierarchy, use composition |

**Dispensables** — code that could be removed without loss:

| Smell | Signal | Impact | Fix |
|-------|--------|--------|-----|
| Dead Code | Unreachable code, unused variables/imports | Confusion, maintenance burden | Delete it (git has history) |
| Speculative Generality | Interfaces/abstractions for one implementation | Premature abstraction, over-engineering | Inline/remove until needed |
| Comments Explaining What | Comments describing obvious code | Code isn't self-documenting | Rename to make intent clear, remove comment |
| Duplicate Code | Same logic in multiple places | Bug fixes missed in one copy | Extract shared function/method |

**Couplers** — excessive coupling between classes:

| Smell | Signal | Impact | Fix |
|-------|--------|--------|-----|
| Feature Envy | Method uses another class's data more than its own | Misplaced responsibility | Move method to the class it envies |
| Inappropriate Intimacy | Classes accessing each other's private details | Tight coupling, breaks encapsulation | Move methods, extract interface |
| Message Chains | `a.getB().getC().getD().doThing()` | Fragile chain, Law of Demeter violation | Hide delegate, introduce intermediary |
| Middle Man | Class that only delegates to another | Unnecessary indirection | Remove middle man, call directly |

### Detection Tools

| Tool | Languages | What It Detects | Integration |
|------|-----------|----------------|-------------|
| **SonarQube** | 27+ languages | 5000+ rules for smells, bugs, vulnerabilities, duplications | CI/CD, IDE (SonarLint) |
| **DeepSource** | Python, Go, JS/TS, Java, Ruby, Rust | Anti-patterns, complexity, style, security | GitHub/GitLab/Bitbucket |
| **CodeClimate** | 10+ languages | Duplication, complexity, style, churn | GitHub, CI |
| **CodeScene** | Most languages | Code health (behavioral + structural), hotspots, team coupling | CI, PR review |
| **PMD** | Java, Apex, XML, Velocity | Design flaws, dead code, suboptimal code | Maven/Gradle, CI |

---

## 2. SOLID Principles in Code Review

### What to Look For During Review

**Single Responsibility Principle (SRP)**
- A class or module should have one reason to change
- Review signal: Class modified in PRs for unrelated features
- Red flag: Class with methods spanning different domains (e.g., `UserService` that handles authentication AND email AND billing)
- Fix: Extract separate classes per responsibility

**Open/Closed Principle (OCP)**
- Open for extension, closed for modification
- Review signal: Every new feature requires modifying existing switch/if-else chains
- Red flag: Adding a new payment method requires editing `PaymentProcessor.process()`
- Fix: Strategy pattern, plugin architecture, or polymorphism

**Liskov Substitution Principle (LSP)**
- Subtypes must be substitutable for their base types
- Review signal: `instanceof` checks or type-specific branching after receiving a base type
- Red flag: `Square extends Rectangle` where `setWidth()` breaks `Rectangle` expectations
- Fix: Prefer composition over inheritance, redesign hierarchy

**Interface Segregation Principle (ISP)**
- Clients shouldn't depend on interfaces they don't use
- Review signal: Classes implementing interfaces with many no-op or `throw NotImplementedError` methods
- Red flag: `Printable` interface with `fax()`, `staple()`, `scan()` when most implementors only need `print()`
- Fix: Split into focused interfaces

**Dependency Inversion Principle (DIP)**
- Depend on abstractions, not concretions
- Review signal: High-level modules directly instantiating low-level modules (`new MySQLDatabase()` in business logic)
- Red flag: Business logic importing specific infrastructure packages
- Fix: Inject dependencies via constructor, use interfaces/protocols

### SOLID Tradeoffs

SOLID principles are guidelines, not laws. Over-application creates its own problems:

- **Over-SRP**: Too many tiny classes that are hard to navigate. If splitting doesn't reduce complexity, don't split.
- **Over-OCP**: Premature abstraction for extension points that never get used. Extend when you have 2+ variants, not before.
- **Over-ISP**: Interface explosion. One method per interface is usually too fine-grained.
- **Over-DIP**: Everything injected and abstracted even when there's only one implementation. Concrete is fine for internal code with no substitution need.

The question is always: does this make the code *easier to change correctly* for the changes we actually expect?

---

## 3. DRY, KISS, YAGNI in Practice

### DRY (Don't Repeat Yourself)

**What to look for**: Identical or near-identical logic in multiple places — if you fix a bug, would you need to remember to fix it in 3 places?

**When NOT to DRY**: Duplication is sometimes the right call:
- Two similar-looking pieces of code that represent different business concepts and will evolve independently
- Test code — test readability trumps DRY; duplicate setup is often clearer than shared fixtures
- Early-stage code — extract abstractions only after 3+ instances and you understand the commonality

**The Rule of Three**: Don't abstract at the first duplication. Wait until you see the pattern three times, and you understand what varies versus what's stable.

### KISS (Keep It Simple, Stupid)

**What to look for**: Over-engineered solutions. Metaprogramming, dynamic dispatch, or clever tricks where straightforward code would work.

**Review heuristic**: Could you explain this code to a new team member in under 2 minutes? If not, it might be too clever.

**Common KISS violations in review**:
- Using generics/templates when a concrete type is fine
- Custom event systems when simple function calls work
- Observable/reactive patterns for synchronous operations
- Abstract factory when a constructor call is sufficient
- Reflection/metaprogramming for problems solvable with regular code

### YAGNI (You Aren't Gonna Need It)

**What to look for**: Features, extension points, or configurability that no current requirement demands.

**Review signals**:
- "We might need this later" comments
- Configuration for things that have exactly one value
- Interfaces with a single implementation and no near-term need for alternatives
- Generic solutions to specific problems
- Feature flags for features nobody has requested

---

## 4. Complexity Metrics

### Cyclomatic Complexity

Counts the number of linearly independent paths through code. A function with complexity N needs at least N test cases for full branch coverage.

| Score | Rating | Action |
|-------|--------|--------|
| 1-5 | Simple | No action needed |
| 6-10 | Moderate | Consider simplifying if readability suffers |
| 11-20 | Complex | Should be refactored — hard to test and maintain |
| 21+ | Very complex | Must be refactored — untestable, high bug risk |

**How it's calculated**: Start at 1, add 1 for each `if`, `else if`, `for`, `while`, `case`, `catch`, `&&`, `||`, ternary operator.

### Cognitive Complexity (SonarSource)

Measures human comprehension difficulty. Unlike cyclomatic complexity, it penalizes *nesting* — an `if` inside a `for` inside a `try` is harder to understand than three sequential `if` statements, even though cyclomatic complexity scores them the same.

**Rules**:
- +1 for each control flow break (`if`, `for`, `while`, `switch`, `catch`, ternary, logical operators)
- +1 nesting penalty for each level of nesting when a break is inside another
- No increment for `else` or `else if` (they don't add comprehension difficulty)
- Recursion adds +1

**Example**:
```
function process(items) {        // 0
  for (item of items) {          // +1 (for)
    if (item.isValid()) {        // +2 (if + nesting)
      if (item.hasDiscount()) {  // +3 (if + nesting x2)
        applyDiscount(item);
      }
    }
  }
}                                // Total: 6
```

### Measurement Tools

| Language | Tool | Measures | Integration |
|----------|------|----------|-------------|
| All | SonarQube | Both cyclomatic and cognitive | CI, IDE |
| JS/TS | ESLint `complexity` rule | Cyclomatic | CI, IDE |
| JS/TS | Biome `noExcessiveCognitiveComplexity` | Cognitive | CI, IDE |
| Python | Ruff `C901` | Cyclomatic (McCabe) | CI, IDE |
| Python | `radon` | Cyclomatic, maintainability index | CLI, CI |
| Go | `gocyclo` (via golangci-lint) | Cyclomatic | CI |
| Go | `gocognit` (via golangci-lint) | Cognitive | CI |
| Java | PMD, Checkstyle | Cyclomatic | Maven/Gradle |
| Rust | `clippy::cognitive_complexity` | Cognitive | CI |

---

## 5. Naming and Readability

### Naming Review Checklist

- **Variables**: Noun or noun phrase describing what they hold. Avoid single-letter names except `i`, `j`, `k` for indices and `e`, `err` for errors. Avoid `data`, `info`, `temp`, `result` as primary names — they're meaningless.
- **Functions**: Verb or verb phrase describing what they do. `getUserById()` not `user()`. Boolean-returning functions: `isValid()`, `hasPermission()`, `canDelete()`.
- **Classes**: Noun describing the entity. Avoid `Manager`, `Helper`, `Utility`, `Handler` suffixes — they're smell words indicating unclear responsibility.
- **Constants**: UPPER_SNAKE_CASE in most languages. The name should express the *meaning*, not the value: `MAX_RETRY_ATTEMPTS = 3` not `THREE = 3`.
- **Type parameters**: Single uppercase letter is fine for simple generics (`T`, `K`, `V`). Use descriptive names for complex generics: `TResponse`, `TEntity`.

### Readability Patterns

**Prefer explicit over implicit**: `isUserActive(user)` is clearer than `!!user.lastLogin && user.status !== 'banned'` inline.

**Guard clauses**: Return early for invalid cases instead of wrapping the entire function body in an if block. Reduces nesting, improves scanning.

**Avoid boolean parameters**: `createUser(name, true, false)` is unreadable at the call site. Use named options: `createUser(name, { sendEmail: true, isAdmin: false })`.

**Limit function arguments**: 3 is comfortable. 4+ deserves an options object. 6+ is a code smell.

**Avoid negated conditions in branching**: `if (!isNotValid)` is confusing. Invert the name: `if (isValid)`.

---

## 6. Error Handling Patterns

### What to Look For in Review

**Missing error handling**:
- Promises without `.catch()` or try/catch around `await`
- API calls with no error response handling
- File operations without existence/permission checks
- Database queries without connection error handling
- JSON parsing without try/catch

**Swallowed errors**:
- Empty catch blocks (`catch(e) {}`)
- Catch blocks that only log but don't propagate or recover
- Generic catch-all that hides specific failures

**Inappropriate error handling**:
- Catching errors too early (before the caller can react)
- Catching too broadly (`catch(Exception e)` when only `IOException` is expected)
- Using exceptions for control flow (expected cases shouldn't throw)
- Returning null/undefined instead of throwing for unexpected failures

### Language-Specific Error Patterns

**JavaScript/TypeScript**:
- Unhandled promise rejections (Node.js will terminate on these)
- Missing error boundaries in React components
- `JSON.parse()` without try/catch
- Assuming `fetch()` throws on HTTP errors (it doesn't — check `response.ok`)

**Python**:
- Bare `except:` catching everything including `KeyboardInterrupt` and `SystemExit`
- Over-broad `except Exception`
- Not using `with` for resource management (files, connections)
- Silently ignoring exceptions with `pass`

**Go**:
- Ignoring error returns: `result, _ := doSomething()`
- Not wrapping errors with context: use `fmt.Errorf("doing X: %w", err)`
- Checking `err != nil` but not all error paths
- Using `panic` for non-fatal errors

**Java**:
- Catching `Exception` instead of specific exceptions
- Empty catch blocks
- Not closing resources (use try-with-resources)
- Checked exception abuse — wrapping everything in RuntimeException

**Rust**:
- Excessive `.unwrap()` or `.expect()` instead of proper `?` propagation
- Using `panic!` for recoverable errors
- Not providing context with `.context()` (anyhow) or custom error types

---

## 7. Static Analysis Tools by Language

### JavaScript/TypeScript

| Tool | Speed | Rules | Formatter | Best For |
|------|-------|-------|-----------|----------|
| **ESLint v9** | Baseline | 700+ core, 4000+ via plugins | No (pair with Prettier) | Existing projects, plugin ecosystem |
| **Biome v2** | 10-100x ESLint | 423+ rules, type-aware | Built-in (replaces Prettier) | New projects, all-in-one |
| **oxlint** | 50-100x ESLint | ~300 rules | No | Fast CI pre-pass alongside ESLint |

**Decision framework**:
- New project, want speed and simplicity → Biome
- Existing project with ESLint plugins you need → ESLint v9 + Prettier
- Large repo CI where lint speed matters → oxlint first pass + ESLint for deeper checks

### Python

| Tool | Speed | Rules | Formatter | Best For |
|------|-------|-------|-----------|----------|
| **Ruff** | 100x+ Pylint | 800+ rules (replaces Flake8 + dozens of plugins) | Built-in (replaces Black + isort) | Everything — default choice |
| **Pylint** | Slow | ~409 rules, deep semantic analysis | No | OOP analysis, control flow, when Ruff isn't enough |
| **mypy/pyright** | Moderate | Type checking | No | Type safety (pair with Ruff) |

**Decision framework**: Ruff as primary linter + formatter. Add mypy or pyright for type checking. Use Pylint only for its unique semantic analysis (OOP validation, control flow).

### Go

| Tool | Best For |
|------|----------|
| **golangci-lint v2** | Default — runs 100+ linters in parallel with caching |
| **staticcheck** | Integrated in golangci-lint — advanced Go-specific analysis |
| **govulncheck** | Vulnerability scanning of Go dependencies |

**Default configuration**: `golangci-lint v2` with `linters.default: standard` baseline. Add `gocritic`, `gocognit`, `exhaustive` for review-quality analysis.

### Java

| Tool | Best For |
|------|----------|
| **SonarQube** | Comprehensive quality + security (CI/CD, quality gates) |
| **PMD** | Design flaws, dead code detection |
| **Checkstyle** | Style enforcement |
| **SpotBugs** | Bug pattern detection (successor to FindBugs) |
| **Error Prone** | Compile-time bug detection by Google |

### Rust

| Tool | Best For |
|------|----------|
| **Clippy** | Default — hundreds of lints for correctness, style, performance |
| **cargo-audit** | Dependency vulnerability scanning |
| **Rudra** | Experimental — undefined behavior detection |

---

## 8. Code Coverage Analysis

### Coverage Types

| Type | What It Measures | Usefulness |
|------|-----------------|------------|
| **Line/Statement** | Was this line executed? | Basic, misses branching |
| **Branch** | Was each branch of if/else taken? | Better — catches untested paths |
| **Condition** | Was each boolean sub-expression tested true and false? | Most thorough for conditionals |
| **Function** | Was this function called? | Good for finding dead code |
| **MC/DC** | Modified Condition/Decision — each condition independently affects the outcome | Required for safety-critical (aviation, automotive) |

### Coverage Tools

| Language | Tool | Integration |
|----------|------|-------------|
| JS/TS | Istanbul/nyc, @vitest/coverage-v8 | Jest, Vitest, CI |
| Python | coverage.py | pytest, CI |
| Go | `go test -cover` | Built-in |
| Java | JaCoCo | Maven/Gradle |
| Rust | cargo-tarpaulin, llvm-cov | Cargo |

### Coverage Targets (Pragmatic Guidance)

Don't chase 100% — it leads to tests that test the wrong things (testing getters/setters, mocking everything).

| Code Type | Target | Rationale |
|-----------|--------|-----------|
| Core business logic | 80-90% | High value, high risk, worth thorough testing |
| API handlers/controllers | 70-80% | Important paths, but frameworks handle a lot |
| Utility/helper functions | 80-90% | Usually easy to test, high reuse |
| UI components | 60-70% | Integration/E2E tests cover interaction better |
| Configuration/setup | 30-50% | Low value, changes rarely |
| Generated code | 0% | Don't test generated code |

**What matters more than the number**: Are the *critical paths* covered? Coverage of the happy path only gives false confidence.

---

## 9. Technical Debt Quantification

### Tools for Measuring Debt

| Tool | What It Measures | Unique Value |
|------|-----------------|-------------|
| **SonarQube** | Technical debt ratio, remediation time estimates | Quantifies debt in developer-days, quality gates |
| **CodeScene** | Code health, hotspot analysis, team coupling | Behavioral analysis — prioritizes debt by development activity patterns, not just code metrics |
| **CodeClimate** | Maintainability grade (A-F), issue density | Simple scoring, GitHub integration |

### Debt Categories to Identify in Review

| Category | Examples | Impact |
|----------|----------|--------|
| **Design debt** | Missing abstractions, wrong patterns, tight coupling | Hard to extend, high change cost |
| **Code debt** | Complexity, smells, duplication, poor naming | Slow comprehension, bug-prone |
| **Test debt** | Low coverage, flaky tests, missing edge cases | Slow release, fear of refactoring |
| **Documentation debt** | Missing API docs, outdated READMEs, no ADRs | Slow onboarding, knowledge silos |
| **Dependency debt** | Outdated packages, deprecated APIs, EOL frameworks | Security risk, increasing migration cost |
| **Infrastructure debt** | Manual deployments, no IaC, snowflake servers | Unreliable releases, hard to reproduce |

### Prioritizing Debt During Review

Use the **Interest Rate** heuristic: How much is this debt costing per week?

- **High interest**: Debt in code that changes frequently (hotspots). Fix this first — the cost compounds with every change.
- **Low interest**: Debt in stable code that rarely changes. Acknowledge but don't block on it.

CodeScene's hotspot analysis helps identify high-interest debt — code that is both complex AND changes often.

---

## 10. Refactoring Recommendations

### Safe Refactoring Patterns

When recommending refactoring in review, suggest patterns that minimize risk:

| Refactoring | When to Suggest | Risk Level |
|-------------|----------------|------------|
| **Rename** (variable, function, class) | Misleading or unclear names | Very low |
| **Extract Method** | Long function, duplicated code | Low |
| **Extract Variable** | Complex expression used multiple times | Very low |
| **Inline** | Unnecessary indirection, trivial methods | Low |
| **Move Method/Function** | Feature envy, misplaced responsibility | Medium |
| **Replace Conditional with Polymorphism** | Repeated type-checking switch/if chains | Medium |
| **Introduce Parameter Object** | Long parameter lists | Low |
| **Replace Magic Number with Named Constant** | Unexplained literals in code | Very low |
| **Extract Class** | Large class with multiple responsibilities | Medium-High |
| **Replace Inheritance with Composition** | Wrong abstraction hierarchy | High |

### When to Suggest Refactoring in a PR vs. Follow-Up

**In the PR**: Only if the refactoring is small (< 30 minutes), directly related to the change, and reduces the risk of the change being incorrect. Don't scope-creep.

**As a follow-up ticket**: For larger refactoring that would make the PR harder to review or delay the change. Create a specific, actionable ticket — "Refactor UserService to extract EmailService" not "clean up UserService."

---

## 11. AI-Assisted Code Review Tools

### Current Landscape (2025-2026)

| Tool | Strength | Weakness | Cost |
|------|----------|----------|------|
| **Qodo 2.0** | Multi-agent architecture, highest F1 score (60.1%), merge gating | Higher cost | $30/user/month |
| **CodeRabbit** | Fast inline PR comments, widest platform support, security tool integrations | No merge gating | $12-24/user/month |
| **GitHub Copilot Code Review** | Native GitHub integration, auto-assigned as PR reviewer | Limited depth | Included in Copilot Enterprise |
| **Amazon CodeGuru** | AWS-native, performance/security focus | AWS-centric | Pay per lines scanned |

### How AI Review Complements Human Review

AI is good at: Finding known patterns (N+1 queries, missing null checks, unused variables), suggesting test cases, catching inconsistencies, summarizing large PRs.

AI is bad at: Business logic correctness, architectural fitness, naming quality, understanding intent, evaluating tradeoffs, domain-specific patterns.

**Recommended workflow**: Let AI handle the first pass (patterns, style, known issues), then human reviewers focus on logic, architecture, and tradeoffs.

---

## 12. Code Quality Gates and CI Integration

### Recommended CI Pipeline for Quality

```
Stage 1 (Fast — < 30s):
  ├── Formatter check (Biome/Prettier/Black/gofmt)
  ├── Linter (Ruff/ESLint/golangci-lint/Clippy)
  └── Secrets detection (Gitleaks)

Stage 2 (Medium — 1-5 min):
  ├── Unit tests + coverage report
  ├── Type checking (mypy/tsc/pyright)
  └── SAST fast scan (Semgrep)

Stage 3 (Slow — 5-15 min):
  ├── Integration tests
  ├── Architecture tests (ArchUnit/dependency-cruiser)
  └── Bundle size check (frontend)

Scheduled (nightly/weekly):
  ├── Deep SAST (CodeQL)
  ├── Dependency vulnerability scan (Snyk/Dependabot)
  └── SonarQube full analysis
```

### Quality Gate Thresholds

| Metric | Gate Threshold | Rationale |
|--------|---------------|-----------|
| New code coverage | > 80% | New code should be well-tested |
| Overall coverage | > 60% (no decrease) | Prevent regression |
| Complexity per function | < 15 cyclomatic | Keep functions testable |
| Duplicated lines | < 3% on new code | Catch copy-paste |
| Critical issues | 0 | Never merge with critical issues |
| Major issues | < 5 on new code | Keep quality trending up |
| Security hotspots | All reviewed | Awareness, not perfection |

---

## 13. Language-Specific Quality Patterns

### JavaScript/TypeScript

**Common review findings**:
- Missing `strict` mode in tsconfig
- `any` type usage that defeats type safety
- Mutable default parameters
- Implicit type coercion (`==` instead of `===`)
- Callback hell instead of async/await
- Missing `AbortController` for cancellable fetch requests
- Event listener leaks (no cleanup in React useEffect)
- `console.log` left in production code

### Python

**Common review findings**:
- Mutable default arguments (`def f(items=[])` — the list is shared across calls)
- Not using context managers for resources (`with open(...)`)
- Bare `except:` swallowing all exceptions
- String concatenation in loops (use `join()` or f-strings)
- Not using `pathlib` for file paths
- Missing type annotations on public functions
- Circular imports
- God classes in Django views/models

### Go

**Common review findings**:
- Ignoring error returns (`result, _ := ...`)
- Not wrapping errors with context
- Goroutine leaks (no cancellation context)
- Race conditions (missing mutex, not using `-race` flag)
- Unnecessary pointer use (Go values are often fine)
- Stuttering in naming (`package user` with type `UserService` → just `Service`)
- Not using `defer` for cleanup
- Over-use of `interface{}` / `any`

### Java

**Common review findings**:
- Not using try-with-resources for `AutoCloseable`
- Mutable collections returned from methods (return unmodifiable views)
- `null` instead of `Optional`
- Excessive checked exceptions
- Not using `var` for local variable type inference (Java 10+)
- `StringBuilder` in non-loop contexts (compiler handles simple concatenation)
- Missing `@Override` annotations

### Rust

**Common review findings**:
- Unnecessary `.clone()` calls
- `.unwrap()` instead of proper error handling with `?`
- Not using `clippy::pedantic` for library code
- Over-use of `Arc<Mutex<>>` when simpler ownership works
- `String` parameters that should be `&str`
- Not implementing `Display` for custom error types
- Missing `#[must_use]` on functions returning important values

---

## 14. Code Quality Review Checklist

Quick-reference checklist for systematic quality review:

### Readability
- [ ] Clear, intention-revealing names for variables, functions, types
- [ ] Functions do one thing and do it well
- [ ] No excessive nesting (< 3 levels preferred)
- [ ] Guard clauses used to reduce nesting
- [ ] Comments explain *why*, not *what* (the code explains what)
- [ ] No magic numbers — named constants with meaningful names
- [ ] Consistent code style (or enforced by formatter)

### Design
- [ ] No obvious SRP violations (class/module with multiple reasons to change)
- [ ] No feature envy (method using another class's data excessively)
- [ ] No inappropriate coupling between unrelated modules
- [ ] Abstractions exist at the right level (not too early, not too late)
- [ ] No premature optimization or speculative generality

### Error Handling
- [ ] All error paths handled (no swallowed errors)
- [ ] Errors provide useful context (not just "something went wrong")
- [ ] Resources properly cleaned up (defer, try-with-resources, context managers)
- [ ] External input validated at system boundaries

### Testing
- [ ] New code has tests
- [ ] Tests cover the important paths (not just happy path)
- [ ] Tests are readable and maintainable
- [ ] No test-only changes to production code (no boolean parameters to skip logic)
