# Test Strategy Architect — Deep Reference

**Always use `WebSearch` to verify current tool versions, best practices, and emerging patterns before giving test strategy advice. Quality engineering practices evolve rapidly with new CI/CD capabilities and AI-assisted testing.**

## Table of Contents
1. [Test Strategy Fundamentals](#1-test-strategy-fundamentals)
2. [Test Pyramid and Its Variants](#2-test-pyramid-and-its-variants)
3. [Shift-Left Testing](#3-shift-left-testing)
4. [Shift-Right Testing](#4-shift-right-testing)
5. [CI/CD Test Pipeline Design](#5-cicd-test-pipeline-design)
6. [Test Data Management](#6-test-data-management)
7. [Test Environment Strategy](#7-test-environment-strategy)
8. [Risk-Based Testing](#8-risk-based-testing)
9. [Quality Metrics and Dashboards](#9-quality-metrics-and-dashboards)
10. [Test Reporting](#10-test-reporting)
11. [Test Suite Maintenance](#11-test-suite-maintenance)
12. [Testing Distributed Systems](#12-testing-distributed-systems)
13. [Testing AI/ML Applications](#13-testing-aiml-applications)
14. [Building a Quality Engineering Culture](#14-building-a-quality-engineering-culture)
15. [Feature Flag Testing](#15-feature-flag-testing)
16. [Test Strategy Templates](#16-test-strategy-templates)

---

## 1. Test Strategy Fundamentals

### What Is a Test Strategy?

A test strategy answers: **What do we test, how do we test it, and when do we test it?**

It's not a document that sits in a drawer — it's a living set of decisions that guides daily development:

| Question | Decision |
|----------|----------|
| What types of tests do we write? | Unit, integration, E2E — in what ratio? |
| When do tests run? | Pre-commit, PR, merge, deploy, nightly? |
| What blocks a deploy? | Which test failures are blocking vs. advisory? |
| Who writes tests? | Developers? QA? Both? |
| What's "good enough" coverage? | Targets by code type, not a single number |
| How do we handle flaky tests? | Quarantine policy, SLA for fixing |
| How do we manage test data? | Factories, fixtures, real data, synthetic? |
| Where do tests run? | Local, CI, staging, production? |

### The Testing Spectrum

```
                Development Time ──────────────────────► Production
                
Pre-commit    PR/CI          Staging        Production
─────────────────────────────────────────────────────────────
Unit tests    Unit tests     E2E tests      Synthetic monitoring
Lint          Integration    Performance    Real user monitoring
Type check    Contract       Security scan  Canary analysis
              E2E (smoke)    Pen test       Feature flag tests
              Schema valid.  Load test      Chaos engineering
              
◄── Shift Left                              Shift Right ──►
   (find bugs earlier)                    (verify in production)
```

---

## 2. Test Pyramid and Its Variants

### Classic Test Pyramid

```
          /  E2E  \         Few: expensive, slow, high-fidelity
         /─────────\
        /Integration\       Some: moderate cost, moderate speed
       /─────────────\
      /   Unit Tests   \    Many: cheap, fast, isolated
     /─────────────────\
```

**Ratios (classic):** 70% unit / 20% integration / 10% E2E

### Test Trophy (Kent C. Dodds)

```
         /  E2E  \          Few: full user journeys
        /─────────\
       /Integration\        Most: real behavior, real boundaries
      /─────────────\
     /  Unit Tests   \      Some: pure business logic
    /─────────────────\
   /   Static Analysis  \   Many: TypeScript, ESLint, Prettier
  /─────────────────────\
```

**Rationale:** For frontend and full-stack applications, integration tests (Testing Library + MSW) catch the most bugs per test dollar.

### Test Diamond

```
         /   E2E    \       Few: critical paths only
        /────────────\
       / Integration  \     Most: service boundaries, contracts
      /────────────────\
     /   Unit Tests     \   Some: complex algorithms, business rules
    /────────────────────\
```

**Best for:** Microservice architectures where the risk is at service boundaries.

### Choosing the Right Shape

| Application Type | Recommended Shape | Why |
|-----------------|-------------------|-----|
| Backend API service | **Pyramid** | Business logic is the core; unit tests are most valuable |
| React/Vue SPA | **Trophy** | Integration tests with Testing Library catch real user issues |
| Microservices ecosystem | **Diamond** | Service interactions are the primary risk |
| Mobile app | **Pyramid + E2E smoke** | Logic-heavy core + critical journey E2E |
| Legacy monolith | **Hourglass** | Unit test new code, E2E test critical paths, integration is hard |
| Data pipeline | **Integration-heavy** | Transformations tested with real (sampled) data |

---

## 3. Shift-Left Testing

### What Is Shift-Left?

Move testing activities earlier in the development cycle — catch bugs when they're cheapest to fix.

| Stage | Shift-Left Practice | Tools |
|-------|-------------------|-------|
| **IDE** | Type checking, linting, auto-formatting | TypeScript, ESLint, Prettier, Clippy, mypy |
| **Pre-commit** | Fast unit tests, lint, formatting | Husky, lint-staged, pre-commit (Python) |
| **PR/CI** | Full unit + integration + contract tests | CI runner + test frameworks |
| **Design** | Threat modeling, testability review | Design review checklists |
| **Requirements** | Acceptance criteria as executable specs | BDD (Cucumber, pytest-bdd) |

### Pre-Commit Hooks (Practical Setup)

```json
// .husky/pre-commit (via lint-staged)
{
  "*.{ts,tsx}": [
    "eslint --fix",
    "vitest related --run"
  ],
  "*.{ts,tsx,css,md}": "prettier --write"
}
```

**Key principle:** Pre-commit must be fast (< 10 seconds). Only run affected tests, not the entire suite.

### Static Analysis as Testing

| Tool | What It Catches | Language |
|------|----------------|----------|
| **TypeScript** | Type errors, null safety, API misuse | JS/TS |
| **mypy / pyright** | Type errors in Python | Python |
| **ESLint** | Code quality, security patterns, a11y | JS/TS |
| **Clippy** | Idiomatic Rust, common mistakes | Rust |
| **SonarQube/SonarCloud** | Code smells, security, duplications | Multi-language |
| **Semgrep** | Custom security rules, anti-patterns | Multi-language |

---

## 4. Shift-Right Testing

### Testing in Production

| Practice | What It Does | When to Use |
|----------|-------------|-------------|
| **Synthetic monitoring** | Run scripted tests against production | Always (critical paths) |
| **Canary deployments** | Route % of traffic to new version | Every deploy |
| **Feature flags** | Test features with real users, toggle on/off | New features, A/B tests |
| **Chaos engineering** | Inject failures to test resilience | After reliability baseline established |
| **Observability-driven testing** | Use production metrics to verify correctness | Complement to traditional testing |

### Synthetic Monitoring

```typescript
// Synthetic monitor — runs every 5 minutes in production
export async function healthCheck() {
  // Test critical user journey
  const loginRes = await fetch('https://api.example.com/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email: 'synthetic@test.com', password: env.SYNTHETIC_PASSWORD }),
  })
  assert(loginRes.ok, `Login failed: ${loginRes.status}`)

  const token = (await loginRes.json()).token

  const productsRes = await fetch('https://api.example.com/products', {
    headers: { Authorization: `Bearer ${token}` },
  })
  assert(productsRes.ok, `Products failed: ${productsRes.status}`)
  assert((await productsRes.json()).length > 0, 'No products returned')

  // Alert if response time exceeds threshold
  assert(productsRes.headers.get('x-response-time') < 500, 'Products API slow')
}
```

**Tools:** Datadog Synthetics, Checkly, Grafana Synthetic Monitoring, Uptime Robot, Pingdom

### Canary Deployment Testing

```
Production traffic flow:
                    ┌──────────────────┐
        95% ──────▶ │ Stable version   │
Users ──────┐       └──────────────────┘
            │       ┌──────────────────┐
        5%  └─────▶ │ Canary version   │ ◄── Monitor error rate,
                    └──────────────────┘      latency, business metrics
                    
If canary metrics OK for 30 min → gradually increase to 100%
If canary metrics degrade → automatic rollback
```

---

## 5. CI/CD Test Pipeline Design

### The Test Pipeline Stages

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Stage 1   │    │   Stage 2   │    │   Stage 3   │    │   Stage 4   │
│   < 5 min   │───▶│  < 10 min   │───▶│  < 20 min   │───▶│  Nightly    │
│             │    │             │    │             │    │             │
│ • Lint      │    │ • Unit tests│    │ • E2E tests │    │ • Full E2E  │
│ • Type check│    │ • Integ.    │    │ • Perf gates│    │ • Soak test │
│ • Build     │    │   tests     │    │ • Visual    │    │ • Security  │
│ • Dep audit │    │ • Contract  │    │   regression│    │   scan      │
│             │    │   tests     │    │ • a11y      │    │ • Full perf │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
    ▲ BLOCK PR         ▲ BLOCK PR        ▲ BLOCK deploy    ▲ Advisory
```

### GitHub Actions Example

```yaml
# .github/workflows/ci.yml
name: CI
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  # Stage 1: Fast checks (< 3 min)
  lint-and-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22' }
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm run build

  # Stage 2: Unit + Integration (< 10 min)
  tests:
    needs: lint-and-build
    runs-on: ubuntu-latest
    strategy:
      matrix:
        shard: [1, 2, 3]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22' }
      - run: npm ci
      - run: npm run test -- --shard=${{ matrix.shard }}/3
      - uses: actions/upload-artifact@v4
        with:
          name: coverage-${{ matrix.shard }}
          path: coverage/

  # Stage 3: E2E (< 15 min, only on PR)
  e2e:
    needs: tests
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    strategy:
      matrix:
        shard: [1, 2, 3, 4]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22' }
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npx playwright test --shard=${{ matrix.shard }}/4
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report-${{ matrix.shard }}
          path: playwright-report/
```

### Test Selection / Affected Tests

Instead of running all tests on every PR, run only tests affected by the changed files:

```bash
# Vitest — run tests related to changed files
vitest --changed HEAD~1

# Jest — run tests related to changed files
jest --changedSince HEAD~1

# Nx — affected tests in monorepo
nx affected --target=test
```

### CI Test Speed Targets

| Test Type | Target Duration | Strategy if Over |
|-----------|----------------|-----------------|
| Lint + Type check | < 2 min | Cache, parallel linting |
| Unit tests | < 5 min | Parallel workers, sharding |
| Integration tests | < 10 min | Testcontainers reuse, parallel |
| E2E tests | < 15 min | Shard across runners, parallel browsers |
| Full pipeline | < 20 min | Remove from PR, move to nightly |

---

## 6. Test Data Management

### Strategies

| Strategy | How It Works | Pros | Cons | Best For |
|----------|-------------|------|------|----------|
| **Factories** | Generate objects in code | Flexible, explicit, no shared state | Verbose for complex objects | Unit + integration tests |
| **Fixtures** | Static JSON/SQL files | Simple, predictable | Hard to maintain, duplicated | Simple, stable data |
| **Database snapshots** | Restore DB to known state | Fast, realistic | Large files, version drift | E2E, performance tests |
| **Synthetic generation** | AI/tool-generated realistic data | Scalable, realistic | May miss edge cases | Load testing, staging |
| **Anonymized production** | Sanitized copy of prod data | Most realistic | Privacy risk, complex pipeline | Staging, performance |

### Factory Pattern (Recommended)

```typescript
// TypeScript with Fishery
import { Factory } from 'fishery'

export const userFactory = Factory.define<User>(({ sequence, params }) => ({
  id: `user-${sequence}`,
  name: `Test User ${sequence}`,
  email: `testuser${sequence}@example.com`,
  role: params.role || 'member',
  createdAt: new Date('2025-01-01'),
}))

export const orderFactory = Factory.define<Order>(({ sequence, associations }) => ({
  id: `order-${sequence}`,
  userId: associations.user?.id || userFactory.build().id,
  items: [orderItemFactory.build()],
  status: 'pending',
  total: 0,  // calculated from items
  createdAt: new Date('2025-01-01'),
}))

// Usage
const admin = userFactory.build({ role: 'admin' })
const orderWithItems = orderFactory.build({
  items: orderItemFactory.buildList(3),
})
```

### Test Data in Different Test Types

| Test Type | Data Source | Cleanup |
|-----------|-----------|---------|
| Unit tests | In-memory factories | Garbage collected |
| Integration | Factories + Testcontainers | Transaction rollback / truncate |
| E2E | API-driven seeding | API-driven cleanup or fresh environment |
| Performance | Pre-loaded database | Snapshot restore after test |

---

## 7. Test Environment Strategy

### Environment Types

| Environment | Purpose | Data | Lifetime |
|-------------|---------|------|----------|
| **Local dev** | Developer testing | Fake/mock/minimal DB | Persistent |
| **CI** | Automated test execution | Containers, fresh per run | Minutes |
| **Preview/Ephemeral** | Per-PR full environment | Seeded from template | Hours-days |
| **Staging** | Pre-production validation | Anonymized prod-like | Persistent |
| **Production** | Real users + synthetic monitoring | Real | Permanent |

### Ephemeral Environments (Per-PR)

```
Developer pushes PR
        │
        ▼
CI creates ephemeral environment:
  ┌───────────────────────────────┐
  │  Namespace: pr-123            │
  │  App: deployed from PR branch │
  │  DB: fresh with seed data     │
  │  URL: pr-123.preview.app.com  │
  └───────────────────────────────┘
        │
        ▼
E2E tests run against ephemeral env
        │
        ▼
Team reviews in ephemeral env
        │
        ▼
PR merged → ephemeral env destroyed
```

**Tools:** Vercel Preview Deployments, Render Preview Environments, Qovery, Kubernetes namespaces

---

## 8. Risk-Based Testing

### Risk Assessment Matrix

| Factor | Low Risk | Medium Risk | High Risk |
|--------|----------|-------------|-----------|
| **User impact** | Internal tool | Customer-facing feature | Payment/financial flow |
| **Change size** | Config change | New feature | Core refactoring |
| **Complexity** | Simple CRUD | Business logic | Distributed transaction |
| **Reversibility** | Feature flag | Quick rollback | Database migration |
| **Frequency of use** | Rarely used | Daily | Every request |

### Test Investment by Risk

```
High Risk + High Frequency  → Full pyramid + performance + security
High Risk + Low Frequency   → Full pyramid + thorough E2E
Low Risk + High Frequency   → Unit + integration, light E2E
Low Risk + Low Frequency    → Unit tests, skip E2E
```

### Change-Impact Testing

When a PR modifies code, assess which tests to run:

```
Change in:           Run:
─────────────────────────────────────────────
Shared library    → All unit + integration tests
API endpoint      → API tests + affected E2E
Database schema   → Migration tests + integration + E2E
UI component      → Component tests + visual regression + affected E2E
Config/env change → Smoke tests + affected integration
Dependency update → Full suite
```

---

## 9. Quality Metrics and Dashboards

### Key Metrics to Track

| Metric | What It Measures | Target | Red Flag |
|--------|-----------------|--------|----------|
| **Code coverage (branch)** | % of code paths tested | 70-85% on critical code | < 50% or dropping |
| **Mutation score** | Test effectiveness | > 70% on business logic | < 50% |
| **Defect escape rate** | Bugs reaching production | < 5% of all bugs found | Increasing trend |
| **Mean time to detect (MTTD)** | Time from bug introduction to discovery | < 1 sprint | > 1 sprint |
| **CI pass rate** | % of CI runs that pass | > 95% | < 90% (flakiness issue) |
| **CI duration** | Time from push to green | < 15 min | > 30 min |
| **Flaky test rate** | % of tests that are flaky | < 1% | > 5% |
| **Test-to-code ratio** | Lines of test / lines of code | 1:1 to 2:1 | < 0.5:1 |
| **Bug reopen rate** | Bugs that come back | < 5% | > 15% |

### Coverage Dashboard (Practical)

```
┌──────────────────────────────────────────────────┐
│  Code Coverage — myapp/backend                    │
│  ┌──────────────────────┐  ┌──────────────────┐  │
│  │ Overall: 78.3%       │  │ Trend: ▲ +1.2%   │  │
│  │ Branch:  72.1%       │  │ (last 30 days)   │  │
│  └──────────────────────┘  └──────────────────┘  │
│                                                   │
│  By module:                                       │
│  ├─ orders/   ██████████████░░░░ 84%  ✅          │
│  ├─ payments/ █████████████░░░░░ 79%  ✅          │
│  ├─ users/    ████████████░░░░░░ 73%  ⚠️          │
│  ├─ search/   ██████████░░░░░░░░ 61%  ❌ (target: 70%) │
│  └─ admin/    ████████░░░░░░░░░░ 48%  ❌ (low priority) │
│                                                   │
│  Uncovered critical paths: 3 (see details)        │
└──────────────────────────────────────────────────┘
```

---

## 10. Test Reporting

### Reporting Tool Comparison

| Tool | Type | Features | Pricing |
|------|------|----------|---------|
| **Allure Report** | HTML report generator | Screenshots, steps, history, trends, categories | Free (open source) |
| **ReportPortal** | Test reporting platform | Real-time dashboards, ML-based analysis, flaky detection | Free (open source) + Enterprise |
| **TestRail** | Test management | Test cases, plans, runs, requirements tracing | Paid |
| **Xray** | Jira plugin | Test management inside Jira, BDD support | Paid |
| **Playwright HTML Report** | HTML report | Traces, screenshots, video, test steps | Free (built-in) |
| **Jest HTML Reporter** | HTML report | Basic test results formatting | Free |

### Allure Report Integration

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    reporters: ['default', 'allure-vitest/reporter'],
  },
})
```

```bash
# Generate Allure report
npx allure generate allure-results --clean
npx allure open
```

### Meaningful CI Annotations

```yaml
# GitHub Actions — annotate test failures as PR comments
- uses: dorny/test-reporter@v1
  if: always()
  with:
    name: Test Results
    path: test-results/*.xml
    reporter: jest-junit
```

---

## 11. Test Suite Maintenance

### Test Debt Indicators

| Indicator | Symptom | Fix |
|-----------|---------|-----|
| **Slow suite** | CI takes > 20 min | Identify slow tests, move to nightly, optimize |
| **High flake rate** | > 5% of runs fail due to flakes | Quarantine, root cause analysis, fix or delete |
| **Low signal** | Tests pass but bugs escape | Add integration/E2E for critical paths, mutation test |
| **Maintenance burden** | Tests break on every refactor | Tests are testing implementation, not behavior |
| **Duplication** | Same behavior tested in multiple places | Consolidate to the right layer |
| **Orphaned tests** | Tests for deleted features | Regular cleanup, map tests to features |

### Test Refactoring Strategies

1. **Extract helpers**: Repeated test setup → shared factory/builder
2. **Consolidate layers**: Same behavior tested at unit AND E2E → keep the one that gives best signal
3. **Replace mocks with fakes**: Over-mocked tests → in-memory implementations
4. **Delete low-value tests**: Tests that never catch bugs → delete and don't replace
5. **Parameterize**: Similar tests with different inputs → `test.each` / `@ParameterizedTest`

---

## 12. Testing Distributed Systems

### Key Challenges

| Challenge | Testing Approach |
|-----------|-----------------|
| **Network partitions** | Chaos testing (Chaos Monkey, Litmus) |
| **Service discovery** | Contract testing (Pact), integration tests |
| **Eventual consistency** | Polling assertions, event-based verification |
| **Distributed transactions** | Saga testing, compensating action verification |
| **Message ordering** | Ordered consumer tests, idempotency tests |
| **Cascading failures** | Circuit breaker tests, timeout tests |

### Testing Event-Driven Architectures

```typescript
// Test eventual consistency with polling
test('order confirmation email sent after order creation', async () => {
  // Trigger event
  await request(app).post('/api/orders').send(validOrder).expect(201)

  // Poll for side effect (email sent)
  await waitFor(async () => {
    const emails = await getTestEmails('test@example.com')
    expect(emails).toHaveLength(1)
    expect(emails[0].subject).toContain('Order Confirmed')
  }, { timeout: 10_000, interval: 500 })
})
```

---

## 13. Testing AI/ML Applications

### Challenges of Non-Deterministic Testing

| Challenge | Strategy |
|-----------|---------|
| **Non-deterministic output** | Semantic similarity, output properties, not exact match |
| **Model drift** | Regression benchmarks, golden set evaluation |
| **Prompt sensitivity** | Prompt regression tests, A/B comparison |
| **Latency variance** | Statistical thresholds (p95), not single-run checks |
| **Cost per test** | Batch evaluation, cached responses, smaller models for CI |

### LLM Application Testing

```typescript
describe('AI Summary Service', () => {
  test('summary captures key points', async () => {
    const article = loadFixture('test-article.txt')
    const summary = await summarize(article)

    // Test properties, not exact output
    expect(summary.length).toBeLessThan(article.length * 0.3)  // < 30% of original
    expect(summary.length).toBeGreaterThan(50)  // not trivially short

    // Check for key concept inclusion
    const keyTopics = ['climate change', 'renewable energy', 'policy']
    const mentionedTopics = keyTopics.filter((t) => summary.toLowerCase().includes(t))
    expect(mentionedTopics.length).toBeGreaterThanOrEqual(2)
  })

  test('handles empty input gracefully', async () => {
    const summary = await summarize('')
    expect(summary).toBe('')  // or a specific error message
  })

  test('respects max length parameter', async () => {
    const summary = await summarize(longArticle, { maxLength: 100 })
    expect(summary.split(' ').length).toBeLessThanOrEqual(120)  // some tolerance
  })
})
```

### Evaluation Frameworks for AI

| Framework | Purpose | Language |
|-----------|---------|----------|
| **promptfoo** | LLM evaluation and red-teaming | Node.js/CLI |
| **DeepEval** | LLM evaluation metrics (faithfulness, relevance, coherence) | Python |
| **Ragas** | RAG pipeline evaluation | Python |
| **Braintrust** | LLM evaluation platform | Python/TS |
| **Arize Phoenix** | LLM observability and evaluation | Python |

---

## 14. Building a Quality Engineering Culture

### Developer-Owned Testing

| Practice | What It Looks Like |
|----------|-------------------|
| **Developers write tests** | No separate QA team writing tests; developers own quality |
| **Test in code review** | "Where are the tests?" is a standard review comment |
| **TDD for bug fixes** | Every bug fix starts with a failing test |
| **Test is part of "done"** | A feature without tests is not shippable |
| **Shared test utilities** | Central test helpers, factories, custom matchers |
| **Test quality reviews** | Review test code for maintainability, not just coverage |

### Testing Standards Document

Create a lightweight testing standards document that answers:

1. **What testing framework** do we use for each language/project?
2. **What coverage targets** do we enforce (by code type)?
3. **How do we name tests?** (Convention: `should_expectedBehavior_when_condition`)
4. **What goes in each test layer?** (Decision matrix for unit vs integration vs E2E)
5. **How do we handle test data?** (Factories, not raw objects)
6. **How do we handle flaky tests?** (Quarantine within 24h, fix within 2 weeks)
7. **How do we run tests in CI?** (Pipeline stages and speed targets)

---

## 15. Feature Flag Testing

### Testing with Feature Flags

```typescript
describe('New Checkout V2', () => {
  test('shows new checkout when flag is on', async ({ page }) => {
    // Enable flag for test user
    await setFeatureFlag('checkout-v2', true, { userId: 'test-user' })

    await page.goto('/checkout')
    await expect(page.getByTestId('checkout-v2')).toBeVisible()
    await expect(page.getByTestId('checkout-v1')).not.toBeVisible()
  })

  test('shows old checkout when flag is off', async ({ page }) => {
    await setFeatureFlag('checkout-v2', false, { userId: 'test-user' })

    await page.goto('/checkout')
    await expect(page.getByTestId('checkout-v1')).toBeVisible()
    await expect(page.getByTestId('checkout-v2')).not.toBeVisible()
  })

  test('both paths complete checkout successfully', async ({ page }) => {
    for (const flagValue of [true, false]) {
      await setFeatureFlag('checkout-v2', flagValue, { userId: 'test-user' })
      await completeCheckoutFlow(page)
      await expect(page.getByText('Order Confirmed')).toBeVisible()
    }
  })
})
```

### Feature Flag Testing Checklist

1. Test both flag states (on and off)
2. Test the default state (flag not set)
3. Test gradual rollout percentages
4. Test flag removal (code works without the flag)
5. Verify analytics tracking for both states

---

## 16. Test Strategy Templates

### Test Strategy for a New Feature

```markdown
## Test Strategy: [Feature Name]

### Risk Assessment
- Business criticality: [High/Medium/Low]
- User-facing: [Yes/No]
- Complexity: [High/Medium/Low]
- Data sensitivity: [PII/Financial/None]

### Test Layers
- [ ] Unit tests: [What specific logic to test]
- [ ] Integration tests: [What boundaries to test]
- [ ] E2E tests: [What user journeys to test]
- [ ] Performance: [Any performance requirements?]
- [ ] Security: [Any security concerns?]

### Test Data
- Data source: [Factories/Fixtures/API]
- Special data needs: [Edge cases, large datasets, etc.]

### CI/CD
- Blocking: [Which tests block merge?]
- Non-blocking: [Which tests are advisory?]

### Acceptance Criteria (Testable)
1. Given [context], when [action], then [expected result]
2. ...
```

### Test Strategy for a Microservice

```markdown
## Test Strategy: [Service Name]

### Unit Tests
- Business logic in domain layer: 90%+ branch coverage
- Framework: [Vitest/JUnit/pytest]
- Run: Every PR, < 3 min

### Contract Tests (Consumer)
- Consumers of our API: [List consumers]
- Tool: Pact
- Run: Every PR, verify before deploy

### Contract Tests (Provider)
- APIs we consume: [List providers]
- Tool: Pact
- Run: Triggered by consumer pact changes

### Integration Tests
- Database: Testcontainers (PostgreSQL)
- Message broker: Testcontainers (Kafka)
- External APIs: WireMock stubs
- Run: Every PR, < 10 min

### E2E Tests
- Critical journeys: [2-3 key flows]
- Run: Pre-deploy to staging
- Blocking: Yes

### Performance Tests
- Load test: [Expected RPS, p95 target]
- Run: Weekly or pre-release
- Blocking: Advisory (fail → investigate)
```
