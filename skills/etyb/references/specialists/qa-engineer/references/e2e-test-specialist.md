# E2E Test Specialist — Deep Reference

**Always use `WebSearch` to verify current tool versions, breaking changes, and framework updates before giving E2E testing advice. Playwright in particular releases frequently with new features.**

## Table of Contents
1. [E2E Framework Comparison](#1-e2e-framework-comparison)
2. [Playwright — The Modern Default](#2-playwright--the-modern-default)
3. [Cypress](#3-cypress)
4. [Selenium / WebDriver BiDi](#4-selenium--webdriver-bidi)
5. [Page Object Model and Test Organization](#5-page-object-model-and-test-organization)
6. [Visual Regression Testing](#6-visual-regression-testing)
7. [Mobile E2E Testing](#7-mobile-e2e-testing)
8. [Flaky Test Management](#8-flaky-test-management)
9. [Test Data for E2E](#9-test-data-for-e2e)
10. [Cross-Browser and Cross-Device Testing](#10-cross-browser-and-cross-device-testing)
11. [E2E Test Speed Optimization](#11-e2e-test-speed-optimization)
12. [Accessibility Testing Automation](#12-accessibility-testing-automation)
13. [E2E in CI/CD](#13-e2e-in-cicd)
14. [E2E Test Decision Framework](#14-e2e-test-decision-framework)

---

## 1. E2E Framework Comparison

### Framework Selection Matrix (2025-2026)

| Feature | Playwright (1.58+) | Cypress (15.x) | Selenium 4.41+ |
|---------|-----------|---------|-------------|
| **Multi-browser** | Chromium, Firefox, WebKit | Chromium, Firefox, WebKit (experimental) | All browsers via WebDriver |
| **Multi-tab/window** | Native support | Limited | Supported |
| **iframe support** | Native, easy | Supported but limited | Supported |
| **Network interception** | `page.route()` | `cy.intercept()` | Via proxy or CDP |
| **Auto-waiting** | Built-in, smart | Built-in | Manual waits |
| **Parallelism** | Built-in sharding + workers | Paid (Cypress Cloud) | Selenium Grid |
| **API testing** | Built-in `request` context | `cy.request()` | Separate library |
| **Component testing** | `@playwright/experimental-ct-*` | Native (Cypress CT) | No |
| **Language support** | JS, TS, Python, Java, C# | JS, TS only | All major languages |
| **Mobile testing** | Emulation (viewport, device) | Viewport only | Appium (native apps) |
| **Trace viewer** | Excellent (built-in) | Time-travel in Test Runner | No |
| **Codegen** | `playwright codegen` | Cypress Studio (limited) | Selenium IDE |
| **Speed** | Fast (browser contexts) | Fast (in-browser) | Slowest (WebDriver protocol) |
| **Community/ecosystem** | Growing fast, Microsoft-backed | Large, established | Largest, oldest |

### When to Choose What

| Scenario | Recommendation | Why |
|----------|---------------|-----|
| New project, any stack | **Playwright** | Best DX, multi-browser, fastest growing |
| Existing Cypress suite | **Stay with Cypress** | Migration cost usually not worth it |
| Need Safari testing | **Playwright** (WebKit) | Native WebKit support |
| Need IE/Edge Legacy | **Selenium** | Only option for legacy browsers |
| Mobile web testing | **Playwright** (device emulation) | Best mobile emulation |
| Native mobile app | **Detox/Maestro/Appium** | Playwright/Cypress don't test native |
| Cross-language team | **Playwright or Selenium** | Cypress is JS/TS only |
| Component testing focus | **Cypress CT or Playwright CT** | Both have component testing support |

---

## 2. Playwright — The Modern Default

### Setup and Configuration

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,        // fail if .only() in CI
  retries: process.env.CI ? 2 : 0,     // retry in CI only
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { open: 'never' }],
    ['json', { outputFile: 'test-results/results.json' }],
    process.env.CI ? ['github'] : ['list'],
  ],

  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',           // capture trace on retry
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
    { name: 'mobile-chrome', use: { ...devices['Pixel 7'] } },
    { name: 'mobile-safari', use: { ...devices['iPhone 15'] } },
  ],

  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
})
```

### Core Playwright Patterns

```typescript
import { test, expect } from '@playwright/test'

test.describe('Order Placement', () => {
  test.beforeEach(async ({ page }) => {
    // API-driven test setup (faster than UI setup)
    await page.request.post('/api/test/seed', {
      data: { scenario: 'user-with-items-in-cart' },
    })
    await page.goto('/cart')
  })

  test('should complete checkout flow', async ({ page }) => {
    // Fill shipping info
    await page.getByLabel('Full Name').fill('Alice Johnson')
    await page.getByLabel('Address').fill('123 Main St')
    await page.getByLabel('City').fill('San Francisco')
    await page.getByLabel('ZIP Code').fill('94102')

    // Proceed to payment
    await page.getByRole('button', { name: 'Continue to Payment' }).click()

    // Fill payment info
    await page.getByLabel('Card Number').fill('4242424242424242')
    await page.getByLabel('Expiry').fill('12/26')
    await page.getByLabel('CVV').fill('123')

    // Place order
    await page.getByRole('button', { name: 'Place Order' }).click()

    // Verify confirmation
    await expect(page.getByRole('heading', { name: 'Order Confirmed' })).toBeVisible()
    await expect(page.getByText('Order #')).toBeVisible()
    await expect(page.getByText('$49.97')).toBeVisible()
  })

  test('should show validation errors for empty fields', async ({ page }) => {
    await page.getByRole('button', { name: 'Continue to Payment' }).click()

    await expect(page.getByText('Full name is required')).toBeVisible()
    await expect(page.getByText('Address is required')).toBeVisible()
  })
})
```

### Network Interception

```typescript
test('should handle payment API failure gracefully', async ({ page }) => {
  // Intercept payment API and return error
  await page.route('**/api/payments', (route) => {
    route.fulfill({
      status: 500,
      body: JSON.stringify({ error: 'Payment gateway unavailable' }),
    })
  })

  await page.goto('/checkout')
  await fillCheckoutForm(page)
  await page.getByRole('button', { name: 'Place Order' }).click()

  await expect(page.getByRole('alert')).toContainText('Payment failed')
  await expect(page.getByRole('button', { name: 'Retry Payment' })).toBeVisible()
})
```

### Authentication Handling

```typescript
// auth.setup.ts — run once, share auth state across tests
import { test as setup, expect } from '@playwright/test'

setup('authenticate', async ({ page }) => {
  await page.goto('/login')
  await page.getByLabel('Email').fill('test@example.com')
  await page.getByLabel('Password').fill('password123')
  await page.getByRole('button', { name: 'Sign in' }).click()

  await expect(page.getByText('Dashboard')).toBeVisible()

  // Save signed-in state
  await page.context().storageState({ path: '.auth/user.json' })
})

// Tests use the saved auth state
test.use({ storageState: '.auth/user.json' })

test('authenticated user can view dashboard', async ({ page }) => {
  await page.goto('/dashboard')
  await expect(page.getByRole('heading', { name: 'Welcome' })).toBeVisible()
})
```

### Playwright API Testing

```typescript
test.describe('API Tests', () => {
  test('should create and retrieve an order', async ({ request }) => {
    // Create order via API
    const createResponse = await request.post('/api/orders', {
      data: {
        items: [{ sku: 'WIDGET-1', qty: 2 }],
      },
    })
    expect(createResponse.ok()).toBeTruthy()
    const order = await createResponse.json()
    expect(order.id).toBeDefined()

    // Retrieve order via API
    const getResponse = await request.get(`/api/orders/${order.id}`)
    expect(getResponse.ok()).toBeTruthy()
    const retrieved = await getResponse.json()
    expect(retrieved.items).toHaveLength(1)
    expect(retrieved.items[0].sku).toBe('WIDGET-1')
  })
})
```

### Playwright Trace Viewer

The trace viewer is one of Playwright's most powerful features for debugging:

```typescript
// Capture traces for failed tests
use: {
  trace: 'on-first-retry',  // or 'on' for all tests, 'retain-on-failure'
}
```

```bash
# View trace file
npx playwright show-trace test-results/my-test/trace.zip

# Open Playwright report with traces
npx playwright show-report
```

The trace viewer provides:
- Screenshot at every action
- DOM snapshot at every step
- Network requests/responses
- Console logs
- Source code highlighting

---

## 3. Cypress

### Core Cypress Patterns

```typescript
// cypress/e2e/checkout.cy.ts
describe('Checkout Flow', () => {
  beforeEach(() => {
    // API-driven setup
    cy.request('POST', '/api/test/seed', { scenario: 'user-with-cart' })
    cy.login('test@example.com', 'password123')  // custom command
    cy.visit('/cart')
  })

  it('should complete checkout', () => {
    cy.findByLabelText('Full Name').type('Alice Johnson')
    cy.findByLabelText('Address').type('123 Main St')
    cy.findByRole('button', { name: /continue to payment/i }).click()

    // Intercept payment API
    cy.intercept('POST', '/api/payments', {
      statusCode: 200,
      body: { transactionId: 'txn-123', status: 'success' },
    }).as('payment')

    cy.findByLabelText('Card Number').type('4242424242424242')
    cy.findByRole('button', { name: /place order/i }).click()

    cy.wait('@payment')
    cy.findByRole('heading', { name: /order confirmed/i }).should('be.visible')
  })
})
```

### Custom Commands

```typescript
// cypress/support/commands.ts
declare global {
  namespace Cypress {
    interface Chainable {
      login(email: string, password: string): Chainable
      seedDatabase(scenario: string): Chainable
    }
  }
}

Cypress.Commands.add('login', (email, password) => {
  // Programmatic login via API (faster than UI login)
  cy.request('POST', '/api/auth/login', { email, password }).then((response) => {
    window.localStorage.setItem('token', response.body.token)
  })
})

Cypress.Commands.add('seedDatabase', (scenario) => {
  cy.request('POST', '/api/test/seed', { scenario })
})
```

### Cypress vs Playwright — Migration Mapping

| Cypress | Playwright |
|---------|-----------|
| `cy.visit('/page')` | `page.goto('/page')` |
| `cy.get('[data-testid="btn"]')` | `page.getByTestId('btn')` |
| `cy.findByRole('button', { name: /submit/i })` | `page.getByRole('button', { name: /submit/i })` |
| `cy.intercept('POST', '/api/*')` | `page.route('**/api/*', handler)` |
| `cy.wait('@alias')` | `await page.waitForResponse('**/api/*')` |
| `.should('be.visible')` | `await expect(locator).toBeVisible()` |
| `.should('have.text', 'Hello')` | `await expect(locator).toHaveText('Hello')` |
| `cy.request('POST', '/api/...')` | `request.post('/api/...')` |

---

## 4. Selenium / WebDriver BiDi

### When to Still Use Selenium

- **Legacy browser support**: IE11, older Edge
- **Non-JavaScript teams**: Native support for Java, Python, C#, Ruby
- **Existing Selenium infrastructure**: Migration cost too high
- **Selenium Grid**: Managed browser infrastructure at scale

### WebDriver BiDi — The Future

WebDriver BiDi is the new bidirectional protocol replacing the classic WebDriver protocol (Selenium 4.41+). It enables:
- Network interception (like Playwright/Cypress)
- Console log capture
- Real-time event subscriptions
- Better performance (bidirectional communication)
- New `webExtension` module for deeper browser access

Playwright and Selenium 4+ are both moving toward BiDi as the standard. Selenium 5 will offer high-level BiDi APIs. Selenium Manager now handles automatic driver/browser downloads.

---

## 5. Page Object Model and Test Organization

### Page Object Model (POM)

```typescript
// pages/checkout.page.ts
import { Page, Locator, expect } from '@playwright/test'

export class CheckoutPage {
  readonly page: Page
  readonly fullName: Locator
  readonly address: Locator
  readonly city: Locator
  readonly zipCode: Locator
  readonly continueButton: Locator
  readonly orderTotal: Locator

  constructor(page: Page) {
    this.page = page
    this.fullName = page.getByLabel('Full Name')
    this.address = page.getByLabel('Address')
    this.city = page.getByLabel('City')
    this.zipCode = page.getByLabel('ZIP Code')
    this.continueButton = page.getByRole('button', { name: 'Continue to Payment' })
    this.orderTotal = page.getByTestId('order-total')
  }

  async goto() {
    await this.page.goto('/checkout')
  }

  async fillShippingInfo(info: { name: string; address: string; city: string; zip: string }) {
    await this.fullName.fill(info.name)
    await this.address.fill(info.address)
    await this.city.fill(info.city)
    await this.zipCode.fill(info.zip)
  }

  async continueToPayment() {
    await this.continueButton.click()
  }

  async expectTotal(amount: string) {
    await expect(this.orderTotal).toHaveText(amount)
  }
}

// Usage in test
test('checkout with shipping info', async ({ page }) => {
  const checkout = new CheckoutPage(page)
  await checkout.goto()
  await checkout.fillShippingInfo({
    name: 'Alice Johnson',
    address: '123 Main St',
    city: 'San Francisco',
    zip: '94102',
  })
  await checkout.continueToPayment()
  // continue with PaymentPage...
})
```

### Test Organization Patterns

```
e2e/
├── fixtures/              # Test data and setup helpers
│   ├── auth.setup.ts      # Authentication setup (runs once)
│   ├── test-data.ts       # Shared test data
│   └── global-setup.ts    # Global one-time setup
├── pages/                 # Page objects
│   ├── login.page.ts
│   ├── checkout.page.ts
│   └── dashboard.page.ts
├── specs/                 # Test files organized by feature
│   ├── auth/
│   │   ├── login.spec.ts
│   │   └── signup.spec.ts
│   ├── checkout/
│   │   ├── shipping.spec.ts
│   │   └── payment.spec.ts
│   └── dashboard/
│       └── overview.spec.ts
└── utils/                 # Shared test utilities
    ├── api-helpers.ts     # API shorthand for test setup
    └── assertions.ts      # Custom assertions
```

---

## 6. Visual Regression Testing

### Playwright Screenshots (Built-in)

```typescript
test('dashboard matches visual snapshot', async ({ page }) => {
  await page.goto('/dashboard')
  await page.waitForLoadState('networkidle')

  // Full page screenshot comparison
  await expect(page).toHaveScreenshot('dashboard.png', {
    maxDiffPixelRatio: 0.01,  // 1% tolerance
    fullPage: true,
  })
})

test('button states', async ({ page }) => {
  await page.goto('/components')

  // Element-level screenshot
  const button = page.getByRole('button', { name: 'Submit' })
  await expect(button).toHaveScreenshot('submit-button-default.png')

  await button.hover()
  await expect(button).toHaveScreenshot('submit-button-hover.png')
})
```

### Dedicated Visual Testing Tools

| Tool | Approach | Pricing | Best For |
|------|----------|---------|----------|
| **Percy** (BrowserStack) | Cloud-based, cross-browser rendering | Paid | Teams needing cross-browser visual testing |
| **Chromatic** (Storybook) | Storybook component screenshots | Free tier + paid | Storybook users, component-level visual testing |
| **Argos CI** | GitHub-integrated, Playwright/Cypress | Free for open source + paid | Open source projects, simple setup |
| **Lost Pixel** | Self-hosted or cloud, Storybook/Playwright | Free (self-hosted) + paid | Cost-conscious teams |
| **Playwright built-in** | Local snapshot comparison | Free | Basic visual regression without cloud |

### When to Use Visual Regression Testing

**Good candidates:**
- Design system components (button states, form controls, cards)
- Landing pages and marketing pages
- Data visualization (charts, dashboards)
- Email templates

**Poor candidates:**
- Dynamic content (live data, timestamps, random avatars)
- Rapidly iterating UI (constant false positives from intentional changes)
- Text-heavy pages (minor font rendering differences across OS)

---

## 7. Mobile E2E Testing

### Framework Comparison

| Framework | Target | Speed | Stability | Language |
|-----------|--------|-------|-----------|----------|
| **Detox** | React Native | Fast (grey-box) | Good | JS/TS |
| **Maestro** | iOS + Android | Fast (simple API) | Good | YAML flows |
| **Appium 2** | Any native/hybrid | Slow (black-box) | Medium | Any language |
| **XCUITest** | iOS only | Fast | Excellent | Swift |
| **Espresso** | Android only | Fast | Excellent | Kotlin/Java |

### Detox (React Native)

```typescript
describe('Login Flow', () => {
  beforeAll(async () => {
    await device.launchApp()
  })

  it('should login successfully', async () => {
    await element(by.id('email-input')).typeText('test@example.com')
    await element(by.id('password-input')).typeText('password123')
    await element(by.id('login-button')).tap()

    await expect(element(by.text('Welcome'))).toBeVisible()
  })
})
```

### Maestro (YAML-based)

```yaml
# flows/login.yaml
appId: com.myapp
---
- launchApp
- tapOn: "Email"
- inputText: "test@example.com"
- tapOn: "Password"
- inputText: "password123"
- tapOn: "Sign In"
- assertVisible: "Welcome"
```

**When to use Maestro:** Simplest possible mobile E2E — YAML-based, no code, very fast to write. Good for smoke tests and critical path validation.

---

## 8. Flaky Test Management

### Root Causes of Flaky Tests

| Cause | Frequency | Fix |
|-------|-----------|-----|
| **Race conditions** | Very common | Use auto-waiting (Playwright), avoid `sleep()` |
| **Shared state** | Common | Isolate test data, clean up between tests |
| **Network timing** | Common | Mock external APIs, use `waitForResponse()` |
| **Animation timing** | Common | Disable animations in test environment |
| **Date/time dependency** | Occasional | Use fake timers, freeze time |
| **Random data** | Occasional | Seed random generators, use deterministic data |
| **Browser rendering** | Rare | Use `networkidle`, wait for specific elements |
| **Resource exhaustion** | Rare | Limit parallelism, add memory to CI |

### Flaky Test Strategy

```
1. DETECT — Track flaky test rate (target: < 1% of runs)
   - Mark tests that fail inconsistently
   - Track flaky rate over time

2. QUARANTINE — Don't let flakiness block CI
   - Separate flaky tests from the main suite
   - Run them separately, don't gate deployments
   - Set SLA: fix or delete within 2 weeks

3. DIAGNOSE — Find the root cause
   - Use Playwright traces (trace: 'on-first-retry')
   - Increase retries temporarily to collect data
   - Check for shared state, race conditions, timing

4. FIX — Address the root cause
   - Replace sleeps with proper waits
   - Add proper test isolation
   - Mock flaky external dependencies
   - Delete tests that can't be stabilized

5. PREVENT — Stop new flakiness
   - Review E2E tests in code review for anti-patterns
   - Run new E2E tests 10x before merging
   - Enforce no `page.waitForTimeout()` in linting
```

### Playwright Retry Configuration

```typescript
// playwright.config.ts
export default defineConfig({
  retries: process.env.CI ? 2 : 0,

  // Per-project retries
  projects: [
    {
      name: 'stable-tests',
      testMatch: /.*\.spec\.ts/,
      retries: 1,
    },
    {
      name: 'known-flaky',
      testMatch: /.*\.flaky\.ts/,
      retries: 3,
    },
  ],
})
```

---

## 9. Test Data for E2E

### Strategies

| Strategy | Speed | Isolation | Realism | Best For |
|----------|-------|-----------|---------|----------|
| **API-driven setup** | Fast | Excellent | High | Most E2E tests |
| **Database seeding** | Fast | Good | High | Complex data scenarios |
| **UI-driven setup** | Slow | Good | Highest | Testing the setup flow itself |
| **Snapshot restore** | Medium | Excellent | High | Large datasets |
| **Shared test environment** | None | Poor | Varies | Quick smoke tests only |

**Best practice:** Use **API-driven setup** for most E2E tests. Create test data via API calls in `beforeEach`, not through the UI.

```typescript
// API-driven setup — fast and reliable
test.beforeEach(async ({ request }) => {
  // Create test user via API
  const user = await request.post('/api/test/users', {
    data: { name: 'Alice', email: 'alice@test.com', role: 'customer' },
  })

  // Create products via API
  await request.post('/api/test/products', {
    data: [
      { name: 'Widget', price: 9.99, stock: 100 },
      { name: 'Gadget', price: 24.99, stock: 50 },
    ],
  })

  // Add items to cart via API
  await request.post('/api/test/cart', {
    data: { userId: (await user.json()).id, items: [{ sku: 'WIDGET', qty: 2 }] },
  })
})
```

---

## 10. Cross-Browser and Cross-Device Testing

### Playwright Browser Matrix

```typescript
// playwright.config.ts — comprehensive cross-browser setup
projects: [
  // Desktop browsers
  { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
  { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
  { name: 'webkit', use: { ...devices['Desktop Safari'] } },

  // Mobile viewports
  { name: 'mobile-chrome', use: { ...devices['Pixel 7'] } },
  { name: 'mobile-safari', use: { ...devices['iPhone 15'] } },
  { name: 'tablet', use: { ...devices['iPad Pro 11'] } },
]
```

### What to Test Cross-Browser

- **All browsers**: Critical user journeys (login, checkout, core features)
- **Webkit/Safari only**: CSS features with Safari-specific quirks (flexbox gaps, date inputs)
- **Mobile only**: Touch interactions, responsive layouts, viewport-specific behavior
- **Don't cross-browser test**: Every single test — run the full suite on one browser, critical paths on all

---

## 11. E2E Test Speed Optimization

### Techniques by Impact

| Technique | Speed Impact | Effort |
|-----------|-------------|--------|
| **API-driven setup** (skip UI setup) | 2-5x faster per test | Low |
| **Parallel execution** (workers/sharding) | 2-4x faster total | Low |
| **Reuse auth state** (storageState) | Skip login per test | Low |
| **Selective test execution** (affected tests only) | 5-20x fewer tests run | Medium |
| **Disable animations** | Slight improvement per test | Low |
| **Reduce screenshot/video** (failure only) | Modest improvement | Low |
| **Test against API directly** (skip UI for data validation) | 10-50x faster per test | Medium |

### Sharding in CI

```yaml
# GitHub Actions — run tests across 4 shards
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: npx playwright test --shard=${{ matrix.shard }}/4
```

---

## 12. Accessibility Testing Automation

### axe-core with Playwright

```typescript
import AxeBuilder from '@axe-core/playwright'

test('checkout page has no accessibility violations', async ({ page }) => {
  await page.goto('/checkout')

  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag21aa'])
    .exclude('.third-party-widget')  // exclude elements you don't control
    .analyze()

  expect(results.violations).toEqual([])
})
```

### When to Run Accessibility Tests

- **Every PR**: Run on critical pages (login, checkout, homepage)
- **Nightly**: Full-site accessibility scan
- **Before release**: Complete WCAG compliance check

---

## 13. E2E in CI/CD

### Best Practices

```yaml
# .github/workflows/e2e.yml
e2e-tests:
  runs-on: ubuntu-latest
  timeout-minutes: 30
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with: { node-version: '22' }

    - run: npm ci
    - run: npx playwright install --with-deps chromium

    - run: npx playwright test
      env:
        CI: true
        BASE_URL: http://localhost:3000

    - uses: actions/upload-artifact@v4
      if: always()
      with:
        name: playwright-report
        path: playwright-report/
        retention-days: 14

    - uses: actions/upload-artifact@v4
      if: failure()
      with:
        name: test-traces
        path: test-results/
        retention-days: 7
```

---

## 14. E2E Test Decision Framework

### How Many E2E Tests Do You Need?

| Application Type | Critical Paths | Suggested E2E Count |
|-----------------|---------------|-------------------|
| Landing page / marketing site | 2-3 (navigation, CTA, form) | 5-10 |
| SaaS app with auth | 5-10 (signup, login, core CRUD, settings, billing) | 20-50 |
| E-commerce | 5-8 (browse, search, cart, checkout, orders, returns) | 30-60 |
| Enterprise platform | 10-20 (per module) | 50-200 |

### The E2E Test Checklist

For each critical user journey:
1. **Happy path**: The main success scenario
2. **Primary error path**: Most common failure (validation error, payment decline)
3. **Empty state**: First-time user with no data
4. **Edge case**: Large data, special characters, boundary conditions

Don't test every possible combination — that's what unit and integration tests are for. E2E tests verify that the entire flow works end-to-end for the most important scenarios.
