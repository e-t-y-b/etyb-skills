# Unit Test Specialist — Deep Reference

**Always use `WebSearch` to verify current tool versions, breaking changes, and framework updates before giving unit testing advice. The JavaScript testing ecosystem in particular evolves rapidly.**

## Table of Contents
1. [JavaScript/TypeScript Testing Frameworks](#1-javascripttypescript-testing-frameworks)
2. [Java/Kotlin Testing Frameworks](#2-javakotlin-testing-frameworks)
3. [Python Testing Frameworks](#3-python-testing-frameworks)
4. [Go Testing](#4-go-testing)
5. [.NET Testing Frameworks](#5-net-testing-frameworks)
6. [Rust Testing](#6-rust-testing)
7. [TDD and BDD Patterns](#7-tdd-and-bdd-patterns)
8. [Mocking Strategies and Test Doubles](#8-mocking-strategies-and-test-doubles)
9. [Test Isolation Patterns](#9-test-isolation-patterns)
10. [Coverage Analysis](#10-coverage-analysis)
11. [Mutation Testing](#11-mutation-testing)
12. [Property-Based Testing](#12-property-based-testing)
13. [Snapshot Testing](#13-snapshot-testing)
14. [Component Testing (Frontend)](#14-component-testing-frontend)
15. [Writing Testable Code](#15-writing-testable-code)
16. [Unit Test Decision Framework](#16-unit-test-decision-framework)

---

## 1. JavaScript/TypeScript Testing Frameworks

### Framework Comparison (2025-2026)

| Framework | Runtime | Speed | ESM Support | TypeScript | Watch Mode | Best For |
|-----------|---------|-------|-------------|------------|------------|----------|
| **Vitest 4.x** | Vite (native ESM) | Fastest | Native | Native (via Vite) | HMR-based | Vite/modern projects, new projects |
| **Jest 30.x** | Custom transform | Fast | Via transform | Via ts-jest/SWC | File-based | React (CRA/Next.js), existing Jest codebases |
| **Node.js Test Runner** (22+) | Node.js native | Very fast | Native | Via tsx/ts-node | Built-in `--watch` | Zero-dependency, simple Node.js projects |
| **Bun Test** | Bun runtime | Fastest | Native | Native | Built-in | Bun-based projects |

### Vitest 4.x — Current Recommended Default

Vitest has become the default choice for modern JavaScript/TypeScript projects. It uses Vite's transformation pipeline for near-instant HMR-based test reruns.

**Key features (v4.x, 2025-2026):**
- **Browser mode stabilized**: Run tests in real browsers (Chromium, Firefox, WebKit) — no longer experimental
- **Visual regression testing**: Screenshot-based comparison for component snapshots in browser mode
- **Playwright Trace support**: Debug browser-mode test failures with traces
- **Schema matching API**: Assert against Zod, Valibot, Arktype, or Yup schemas directly in `expect()`
- **File-system cache**: Experimental disk caching for faster subsequent runs
- **Imports breakdown**: See per-module load times in UI, VS Code extension, and terminal
- **Workspace support**: Multi-project monorepo testing with shared configuration
- **Benchmark mode**: Built-in benchmarking with `bench()` API (Tinybench under the hood)
- **Type testing**: `expectTypeOf()` for compile-time type assertions (no runtime overhead)
- **In-source testing**: Write tests inline alongside production code with tree-shaking in production builds
- **Coverage**: Built-in via `@vitest/coverage-v8` (V8) or `@vitest/coverage-istanbul`
- **UI**: `@vitest/ui` provides a browser-based test dashboard

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,                    // inject describe/it/expect globally
    environment: 'jsdom',             // or 'happy-dom' for faster DOM tests
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    coverage: {
      provider: 'v8',                // or 'istanbul'
      reporter: ['text', 'lcov', 'html'],
      thresholds: {
        branches: 80,
        functions: 80,
        lines: 80,
        statements: 80,
      },
    },
    setupFiles: ['./src/test/setup.ts'],
    // Parallelism
    pool: 'forks',                    // 'threads' (default), 'forks', or 'vmThreads'
    poolOptions: {
      forks: { maxForks: 4 },
    },
  },
})
```

**Migration from Jest:**
- Vitest is largely Jest-compatible — most tests work with minimal changes
- Replace `jest.fn()` with `vi.fn()`, `jest.mock()` with `vi.mock()`
- Replace `jest.useFakeTimers()` with `vi.useFakeTimers()`
- `@testing-library/*` works identically
- Import from `vitest` instead of `@jest/globals`

### Jest 30.x — Still Dominant

Jest remains the most widely used JavaScript testing framework. Version 30.x brings significant performance improvements.

**Key features (v30.x, 2025-2026):**
- **Native ESM support**: Improved ESM handling (previously experimental)
- **SWC transform**: `@swc/jest` for faster TypeScript transformation than ts-jest
- **Snapshot serializers**: Custom serializers for cleaner snapshots
- **Fake timers**: Modern fake timer implementation (based on @sinonjs/fake-timers)
- **Module mocking**: `jest.mock()` with factory functions, `jest.spyOn()`

```typescript
// jest.config.ts
import type { Config } from 'jest'

const config: Config = {
  preset: 'ts-jest',
  // Or use SWC for faster transforms:
  // transform: { '^.+\\.tsx?$': ['@swc/jest'] },
  testEnvironment: 'jsdom',
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  collectCoverageFrom: ['src/**/*.{ts,tsx}', '!src/**/*.d.ts'],
  coverageThreshold: {
    global: { branches: 80, functions: 80, lines: 80, statements: 80 },
  },
  setupFilesAfterSetup: ['<rootDir>/src/test/setup.ts'],
}

export default config
```

### Node.js Built-in Test Runner (v22+)

For projects that want zero external testing dependencies. Ships with Node.js.

```typescript
import { describe, it, mock, beforeEach } from 'node:test'
import assert from 'node:assert/strict'

describe('Calculator', () => {
  it('should add two numbers', () => {
    assert.strictEqual(add(2, 3), 5)
  })

  it('should handle negative numbers', () => {
    assert.strictEqual(add(-1, 1), 0)
  })
})
```

**When to use:** Simple Node.js libraries or scripts where you want zero dependencies. Not recommended for large applications (limited ecosystem, no snapshot testing, basic mocking).

### Framework Selection Decision

| Scenario | Recommendation |
|----------|---------------|
| New Vite/React/Vue/Svelte project | Vitest |
| Existing Next.js/CRA project with Jest | Stay with Jest (unless migrating is low effort) |
| Monorepo with mixed projects | Vitest workspaces |
| Simple Node.js library | Node.js test runner or Vitest |
| Bun-based project | Bun test |
| Need browser-environment tests | Vitest browser mode or Jest + jsdom |

---

## 2. Java/Kotlin Testing Frameworks

### JUnit 5/6 (Jupiter) — The Standard

JUnit 6.0.3 (released February 2026) unifies versioning across Platform, Jupiter, and Vintage. The Jupiter API provides modern testing features. JUnit 5.11+ remains widely deployed.

**Key features (JUnit 5.11+ / JUnit 6.x, 2025-2026):**
- **Parameterized tests**: `@ParameterizedTest` with `@ValueSource`, `@CsvSource`, `@MethodSource`, `@EnumSource`
- **Nested tests**: `@Nested` for BDD-style test organization
- **Display names**: `@DisplayName` and `@DisplayNameGeneration` for readable test output
- **Extensions**: `@ExtendWith` for dependency injection, lifecycle callbacks, conditional execution
- **Parallel execution**: `junit.jupiter.execution.parallel.enabled = true`
- **Temporary directory**: `@TempDir` for file system tests
- **Kotlin support**: Full Kotlin DSL compatibility, backtick method names

```java
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import static org.assertj.core.api.Assertions.*;

@DisplayName("Order Service")
class OrderServiceTest {

    private OrderService orderService;
    private PaymentGateway paymentGateway;

    @BeforeEach
    void setUp() {
        paymentGateway = mock(PaymentGateway.class);
        orderService = new OrderService(paymentGateway);
    }

    @Nested
    @DisplayName("when placing an order")
    class PlacingOrder {

        @Test
        @DisplayName("should create order with correct total")
        void shouldCreateOrderWithCorrectTotal() {
            var items = List.of(
                new OrderItem("Widget", 2, Money.of(9.99)),
                new OrderItem("Gadget", 1, Money.of(24.99))
            );

            var order = orderService.placeOrder(items);

            assertThat(order.getTotal()).isEqualTo(Money.of(44.97));
            assertThat(order.getStatus()).isEqualTo(OrderStatus.PENDING);
        }

        @ParameterizedTest
        @CsvSource({
            "1, 9.99, 9.99",
            "2, 9.99, 19.98",
            "0, 9.99, 0.00",
        })
        @DisplayName("should calculate line total correctly")
        void shouldCalculateLineTotal(int qty, double price, double expected) {
            var lineTotal = OrderItem.calculateTotal(qty, Money.of(price));
            assertThat(lineTotal).isEqualTo(Money.of(expected));
        }
    }
}
```

### AssertJ — Fluent Assertions (Recommended)

AssertJ provides fluent, readable assertions. Prefer it over JUnit's built-in assertions.

```java
// Instead of: assertEquals(expected, actual)
assertThat(actual).isEqualTo(expected);

// Rich collection assertions
assertThat(users)
    .hasSize(3)
    .extracting(User::getName)
    .containsExactlyInAnyOrder("Alice", "Bob", "Charlie");

// Exception assertions
assertThatThrownBy(() -> service.findById(null))
    .isInstanceOf(IllegalArgumentException.class)
    .hasMessageContaining("ID must not be null");

// Soft assertions (collect all failures)
SoftAssertions.assertSoftly(softly -> {
    softly.assertThat(order.getStatus()).isEqualTo(CONFIRMED);
    softly.assertThat(order.getTotal()).isGreaterThan(Money.ZERO);
    softly.assertThat(order.getItems()).isNotEmpty();
});
```

### Mockito 5.x (5.21.0) — Mocking for Java

```java
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;

// Mocking
var repository = mock(UserRepository.class);
when(repository.findById(1L)).thenReturn(Optional.of(new User("Alice")));

// Verification
verify(repository, times(1)).findById(1L);
verify(repository, never()).delete(any());

// Argument captors
var captor = ArgumentCaptor.forClass(User.class);
verify(repository).save(captor.capture());
assertThat(captor.getValue().getName()).isEqualTo("Alice");

// BDD-style
given(repository.findById(1L)).willReturn(Optional.of(user));
then(repository).should().findById(1L);
```

### Kotlin-Specific Testing

```kotlin
// Kotest — Kotlin-native testing framework
class OrderServiceTest : FunSpec({
    test("should calculate order total") {
        val service = OrderService()
        val total = service.calculateTotal(listOf(Item(9.99), Item(24.99)))
        total shouldBe 34.98
    }

    context("when placing an order") {
        test("should validate minimum quantity") {
            shouldThrow<IllegalArgumentException> {
                OrderService().placeOrder(emptyList())
            }
        }
    }
})

// MockK — Kotlin mocking library
val repository = mockk<UserRepository>()
every { repository.findById(1L) } returns User("Alice")
verify(exactly = 1) { repository.findById(1L) }
```

---

## 3. Python Testing Frameworks

### pytest — The Standard

pytest is the dominant Python testing framework. Fixtures, parametrize, and plugins make it extremely powerful.

**Key features (9.x, 2025-2026):**
- **Fixtures**: Dependency injection via `@pytest.fixture` with scope control
- **Parametrize**: `@pytest.mark.parametrize` for data-driven tests
- **Plugins**: 1000+ plugins (pytest-asyncio, pytest-cov, pytest-mock, pytest-xdist, etc.)
- **Assertion rewriting**: Detailed assertion introspection without special assert methods
- **Markers**: Custom markers for categorizing tests (`@pytest.mark.slow`, `@pytest.mark.integration`)

```python
import pytest
from decimal import Decimal
from myapp.services import OrderService, InsufficientStockError

class TestOrderService:
    @pytest.fixture
    def order_service(self, mock_inventory, mock_payment):
        return OrderService(
            inventory=mock_inventory,
            payment_gateway=mock_payment,
        )

    @pytest.fixture
    def mock_inventory(self, mocker):
        inventory = mocker.Mock()
        inventory.check_stock.return_value = True
        inventory.reserve.return_value = "reservation-123"
        return inventory

    @pytest.fixture
    def mock_payment(self, mocker):
        payment = mocker.Mock()
        payment.charge.return_value = {"transaction_id": "txn-456"}
        return payment

    def test_place_order_success(self, order_service, mock_inventory, mock_payment):
        items = [{"sku": "WIDGET-1", "qty": 2, "price": Decimal("9.99")}]

        order = order_service.place_order(items)

        assert order.status == "confirmed"
        assert order.total == Decimal("19.98")
        mock_inventory.reserve.assert_called_once()
        mock_payment.charge.assert_called_once_with(amount=Decimal("19.98"))

    @pytest.mark.parametrize("qty,price,expected_total", [
        (1, Decimal("9.99"), Decimal("9.99")),
        (3, Decimal("10.00"), Decimal("30.00")),
        (0, Decimal("9.99"), Decimal("0.00")),
    ])
    def test_calculate_line_total(self, qty, price, expected_total):
        assert OrderService.calculate_line_total(qty, price) == expected_total

    def test_place_order_insufficient_stock(self, order_service, mock_inventory):
        mock_inventory.check_stock.return_value = False
        items = [{"sku": "WIDGET-1", "qty": 100, "price": Decimal("9.99")}]

        with pytest.raises(InsufficientStockError, match="WIDGET-1"):
            order_service.place_order(items)
```

**Essential pytest plugins:**

| Plugin | Purpose |
|--------|---------|
| `pytest-cov` | Coverage reporting (`--cov=myapp`) |
| `pytest-mock` | `mocker` fixture wrapping `unittest.mock` |
| `pytest-asyncio` | `async def test_*` support with `@pytest.mark.asyncio` |
| `pytest-xdist` | Parallel test execution (`-n auto`) |
| `pytest-randomly` | Randomize test order to catch hidden dependencies |
| `pytest-timeout` | Fail tests that exceed time limits |
| `pytest-freezegun` | Freeze time for deterministic date/time testing |
| `pytest-factoryboy` | FactoryBoy integration for test data |
| `pytest-snapshot` | Snapshot testing for Python |
| `pytest-benchmark` | Benchmark test performance |

### conftest.py Patterns

```python
# conftest.py — shared fixtures, available to all tests in directory and below

import pytest
from myapp import create_app
from myapp.database import db as _db

@pytest.fixture(scope="session")
def app():
    """Create application for testing."""
    app = create_app(config="testing")
    yield app

@pytest.fixture(scope="function")
def db(app):
    """Create database tables and rollback after each test."""
    with app.app_context():
        _db.create_all()
        yield _db
        _db.session.rollback()
        _db.drop_all()

@pytest.fixture
def client(app):
    """HTTP test client."""
    return app.test_client()

@pytest.fixture(autouse=True)
def _reset_caches():
    """Clear all LRU caches between tests."""
    import functools
    import gc
    gc.collect()
    for obj in gc.get_objects():
        if isinstance(obj, functools._lru_cache_wrapper):
            obj.cache_clear()
```

---

## 4. Go Testing

Go has excellent built-in testing support. The standard library's `testing` package covers most needs.

### Standard Library Testing

```go
package order

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestCalculateTotal(t *testing.T) {
    tests := []struct {
        name     string
        items    []OrderItem
        expected Money
    }{
        {
            name:     "single item",
            items:    []OrderItem{{Qty: 1, Price: Money(999)}},
            expected: Money(999),
        },
        {
            name:     "multiple items",
            items:    []OrderItem{{Qty: 2, Price: Money(999)}, {Qty: 1, Price: Money(2499)}},
            expected: Money(4497),
        },
        {
            name:     "empty cart",
            items:    []OrderItem{},
            expected: Money(0),
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            total := CalculateTotal(tt.items)
            assert.Equal(t, tt.expected, total)
        })
    }
}

// Table-driven tests with subtests — the Go idiom
func TestOrderService_PlaceOrder(t *testing.T) {
    t.Run("success", func(t *testing.T) {
        mockPayment := &MockPaymentGateway{ChargeResult: "txn-123"}
        svc := NewOrderService(mockPayment)

        order, err := svc.PlaceOrder([]OrderItem{{Qty: 1, Price: Money(999)}})

        require.NoError(t, err)
        assert.Equal(t, StatusConfirmed, order.Status)
        assert.Equal(t, Money(999), order.Total)
    })

    t.Run("payment failure", func(t *testing.T) {
        mockPayment := &MockPaymentGateway{ChargeErr: ErrPaymentDeclined}
        svc := NewOrderService(mockPayment)

        _, err := svc.PlaceOrder([]OrderItem{{Qty: 1, Price: Money(999)}})

        assert.ErrorIs(t, err, ErrPaymentDeclined)
    })
}
```

### Go Mocking Tools

| Tool | Approach | Best For |
|------|----------|----------|
| **Hand-written mocks** | Implement interfaces manually | Small interfaces (1-3 methods), full control |
| **gomock / mockgen** | Code generation from interfaces | Large interfaces, strict verification |
| **testify/mock** | Runtime mock with fluent API | Quick mocking with assertion helpers |
| **moq** | Code generation, type-safe | Type-safe generated mocks |
| **counterfeiter** | Code generation | Go-generate workflow |

**Best practice in Go:** Prefer hand-written mocks for small interfaces. Go interfaces are implicitly satisfied, so a simple struct implementing the interface is often the clearest approach. Use code-generated mocks only for interfaces with many methods.

```go
// Interface
type PaymentGateway interface {
    Charge(amount Money) (string, error)
}

// Hand-written mock
type MockPaymentGateway struct {
    ChargeResult string
    ChargeErr    error
    ChargeCalls  []Money  // record calls for verification
}

func (m *MockPaymentGateway) Charge(amount Money) (string, error) {
    m.ChargeCalls = append(m.ChargeCalls, amount)
    return m.ChargeResult, m.ChargeErr
}
```

### Go Coverage

```bash
# Run tests with coverage
go test -coverprofile=coverage.out ./...

# View coverage report
go tool cover -html=coverage.out -o coverage.html

# Coverage by function
go tool cover -func=coverage.out

# Race detection (always use in CI)
go test -race ./...
```

---

## 5. .NET Testing Frameworks

### xUnit.net — Recommended Default

```csharp
public class OrderServiceTests
{
    private readonly Mock<IPaymentGateway> _paymentGateway;
    private readonly OrderService _sut;

    public OrderServiceTests()
    {
        _paymentGateway = new Mock<IPaymentGateway>();
        _sut = new OrderService(_paymentGateway.Object);
    }

    [Fact]
    public async Task PlaceOrder_WithValidItems_ShouldReturnConfirmedOrder()
    {
        // Arrange
        _paymentGateway
            .Setup(x => x.ChargeAsync(It.IsAny<decimal>()))
            .ReturnsAsync("txn-123");

        var items = new[] { new OrderItem("Widget", 2, 9.99m) };

        // Act
        var order = await _sut.PlaceOrderAsync(items);

        // Assert
        order.Status.Should().Be(OrderStatus.Confirmed);  // FluentAssertions
        order.Total.Should().Be(19.98m);
    }

    [Theory]
    [InlineData(1, 9.99, 9.99)]
    [InlineData(2, 9.99, 19.98)]
    [InlineData(0, 9.99, 0.00)]
    public void CalculateLineTotal_ShouldReturnCorrectAmount(int qty, decimal price, decimal expected)
    {
        var total = OrderItem.CalculateTotal(qty, price);
        total.Should().Be(expected);
    }
}
```

**Mocking in .NET:** Moq is the most popular mocking library. NSubstitute is a lighter alternative. For `ILogger<T>`, consider using `NullLogger<T>` instead of mocking.

---

## 6. Rust Testing

Rust has excellent built-in testing support — no external framework needed for most cases.

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_calculate_total() {
        let items = vec![
            OrderItem { qty: 2, price_cents: 999 },
            OrderItem { qty: 1, price_cents: 2499 },
        ];
        assert_eq!(calculate_total(&items), 4497);
    }

    #[test]
    #[should_panic(expected = "quantity must be positive")]
    fn test_negative_quantity_panics() {
        OrderItem::new(-1, 999);
    }

    #[test]
    fn test_empty_cart() {
        assert_eq!(calculate_total(&[]), 0);
    }
}
```

**Property-based testing in Rust:** Use `proptest` or `quickcheck` crate for generative testing.

---

## 7. TDD and BDD Patterns

### Test-Driven Development (TDD) — Red-Green-Refactor

```
1. RED:    Write a failing test for the next piece of behavior
2. GREEN:  Write the minimum code to make the test pass
3. REFACTOR: Clean up the code while keeping tests green
```

**When TDD shines:**
- Well-defined business rules (pricing, validation, state machines)
- Algorithm implementation
- Bug fixes (write a failing test that reproduces the bug first)
- Library/SDK development

**When TDD is less useful:**
- Exploratory prototyping (write code first, test later)
- UI layout (visual verification is more useful)
- Integration with external APIs (test after you understand the API)

### Outside-In TDD (London School)

Start with the outermost layer (controller/handler) and work inward, mocking dependencies as you go. This drives the API design from the consumer's perspective.

```
1. Write E2E or acceptance test (fails — nothing exists)
2. Write controller test, mock service layer
3. Implement controller, write service test, mock repository
4. Implement service, write repository test
5. Implement repository
6. All tests pass, including the original acceptance test
```

### Classic TDD (Detroit School)

Start with the innermost layer (domain/business logic) and work outward. Use real collaborators instead of mocks where possible.

**When to use which:**
- **London/Outside-In**: When you want to drive interface design, when dependencies are heavy (I/O, network)
- **Detroit/Classic**: When you want to test behavior through real collaborations, simpler domain logic

### BDD with Cucumber/Gherkin

```gherkin
# features/order_placement.feature
Feature: Order Placement
  As a customer
  I want to place orders
  So that I can purchase products

  Scenario: Successful order with valid items
    Given the following items are in stock:
      | SKU      | Name   | Price |
      | WIDGET-1 | Widget | 9.99  |
      | GADGET-1 | Gadget | 24.99 |
    When I place an order with:
      | SKU      | Quantity |
      | WIDGET-1 | 2        |
      | GADGET-1 | 1        |
    Then the order should be confirmed
    And the order total should be 44.97

  Scenario: Order rejected due to insufficient stock
    Given "WIDGET-1" has only 1 item in stock
    When I try to order 5 of "WIDGET-1"
    Then the order should be rejected
    And I should see "Insufficient stock for WIDGET-1"
```

**BDD frameworks by language:**

| Language | Framework | Status |
|----------|-----------|--------|
| JavaScript | Cucumber.js | Active, integrates with Playwright |
| Java | Cucumber-JVM | Active, Spring integration |
| Python | Behave, pytest-bdd | Both active |
| .NET | SpecFlow, Reqnroll | Reqnroll is the active successor to SpecFlow |
| Ruby | Cucumber (original) | Active |

---

## 8. Mocking Strategies and Test Doubles

### The Test Doubles Taxonomy

| Type | What It Does | When to Use |
|------|-------------|-------------|
| **Dummy** | Passed around but never used | Filling required parameters that aren't relevant to the test |
| **Stub** | Returns predetermined responses | Controlling indirect inputs (e.g., mock API returning fixed data) |
| **Spy** | Records calls for later verification | Verifying side effects (e.g., was this method called?) |
| **Mock** | Pre-programmed expectations + verification | Verifying interactions with dependencies |
| **Fake** | Working implementation with shortcuts | In-memory database, fake file system, fake clock |

### When to Mock (and When Not To)

**Mock these:**
- External HTTP APIs (use WireMock, MSW, or HTTP client mocks)
- Databases (for unit tests — use Testcontainers for integration tests)
- File system (use in-memory FS or temp directories)
- Time/clocks (use fake timers for deterministic tests)
- Random number generators (seed them for reproducibility)
- Email/SMS/notification services
- Payment gateways

**Don't mock these:**
- Your own domain logic (test through the real code)
- Simple value objects and DTOs
- Pure functions with no side effects
- Data structures (arrays, maps, etc.)
- Anything you own that's fast and deterministic

### The Mock Spectrum

```
                    More Isolated                    More Integrated
                    ◄────────────────────────────────────────────►
                    Mocks          Fakes          Real implementations
                    
Unit tests    ─────────────────►
Integration   ────────────────────────────────►
E2E                                           ──────────────────►
```

### Mocking Library Quick Reference

| Language | Library | Style |
|----------|---------|-------|
| JS/TS | `vi.fn()` / `jest.fn()` | Built-in, function-level |
| JS/TS | `MSW` (Mock Service Worker) | Network-level HTTP/GraphQL mocking |
| Java | `Mockito` | Annotation-based, fluent API |
| Java | `WireMock` | HTTP service mocking |
| Python | `unittest.mock` / `pytest-mock` | Built-in, function-level |
| Python | `responses` / `httpretty` | HTTP mocking |
| Go | `gomock` | Interface-based code generation |
| Go | Hand-written | Implement interfaces manually |
| .NET | `Moq` / `NSubstitute` | Proxy-based |
| Rust | `mockall` | Trait-based code generation |

---

## 9. Test Isolation Patterns

### Dependency Injection for Testability

The single most impactful pattern for writing testable code. Inject dependencies instead of creating them internally.

```typescript
// HARD TO TEST — creates its own dependencies
class OrderService {
  async placeOrder(items: OrderItem[]) {
    const db = new DatabaseConnection()     // can't substitute in tests
    const payment = new StripeClient()       // hits real Stripe in tests!
    // ...
  }
}

// EASY TO TEST — dependencies injected
class OrderService {
  constructor(
    private readonly db: Database,
    private readonly payment: PaymentGateway,
  ) {}

  async placeOrder(items: OrderItem[]) {
    // Uses injected dependencies — can substitute fakes/mocks in tests
  }
}
```

### Test Fixtures and Factories

**Factories** (recommended over raw fixtures):

```typescript
// TypeScript — using Fishery
import { Factory } from 'fishery'

const userFactory = Factory.define<User>(({ sequence }) => ({
  id: sequence,
  name: `User ${sequence}`,
  email: `user${sequence}@example.com`,
  role: 'member',
  createdAt: new Date('2025-01-01'),
}))

// Usage in tests
const admin = userFactory.build({ role: 'admin' })
const users = userFactory.buildList(5)
```

```python
# Python — using factory_boy
import factory
from myapp.models import User

class UserFactory(factory.Factory):
    class Meta:
        model = User

    id = factory.Sequence(lambda n: n + 1)
    name = factory.Faker('name')
    email = factory.LazyAttribute(lambda o: f'{o.name.lower().replace(" ", ".")}@example.com')
    role = 'member'

# Usage
admin = UserFactory(role='admin')
users = UserFactory.create_batch(5)
```

```java
// Java — using Instancio
var user = Instancio.of(User.class)
    .set(field(User::getRole), Role.ADMIN)
    .create();

var users = Instancio.ofList(User.class).size(5).create();
```

### Handling Time in Tests

```typescript
// Vitest
beforeEach(() => { vi.useFakeTimers() })
afterEach(() => { vi.useRealTimers() })

test('token expires after 1 hour', () => {
  vi.setSystemTime(new Date('2025-01-01T00:00:00Z'))
  const token = createToken()

  vi.advanceTimersByTime(60 * 60 * 1000) // advance 1 hour

  expect(token.isExpired()).toBe(true)
})
```

```python
# Python with freezegun
from freezegun import freeze_time

@freeze_time("2025-01-01")
def test_token_expiration():
    token = create_token(expires_in=timedelta(hours=1))
    
    with freeze_time("2025-01-01 01:00:01"):
        assert token.is_expired() is True
```

---

## 10. Coverage Analysis

### Coverage Metrics Explained

| Metric | What It Measures | Usefulness |
|--------|-----------------|-----------|
| **Line coverage** | % of lines executed | Basic, can be gamed easily |
| **Branch coverage** | % of branches (if/else) taken | Better — catches untested paths |
| **Function coverage** | % of functions called | Useful for finding dead code |
| **Statement coverage** | % of statements executed | Similar to line coverage |
| **Mutation score** | % of code mutations caught by tests | Best indicator of test effectiveness |

### Coverage Targets — A Pragmatic Approach

| Code Type | Suggested Coverage | Why |
|-----------|-------------------|-----|
| Core business logic | 90%+ (branch) | These are the rules that define your product |
| API handlers/controllers | 80%+ | Cover happy path + key error cases |
| Utility/helper functions | 80%+ | Usually pure functions, easy to test |
| UI components | 70%+ | Focus on interaction behavior, not layout |
| Generated code / DTOs | Skip | No logic to test |
| Infrastructure / glue code | 50%+ | Test critical paths, skip boilerplate |

**Coverage anti-patterns:**
- Writing tests solely to increase coverage numbers (tests with no meaningful assertions)
- Requiring 100% coverage (creates maintenance burden, tests trivial code)
- Using coverage as a gate without reviewing what's covered (high coverage with bad tests)

### Coverage Tools by Language

| Language | Tool | Command |
|----------|------|---------|
| JS/TS | V8 coverage (via Vitest/Jest) | `vitest --coverage` |
| JS/TS | c8 | `c8 node --test` |
| JS/TS | Istanbul/nyc | `nyc mocha` |
| Java | JaCoCo | Maven/Gradle plugin |
| Python | coverage.py / pytest-cov | `pytest --cov=myapp` |
| Go | Built-in | `go test -cover ./...` |
| .NET | Coverlet | `dotnet test --collect:"XPlat Code Coverage"` |
| Rust | cargo-llvm-cov | `cargo llvm-cov` |

**Aggregation platforms:** Codecov, Coveralls, SonarCloud — integrate with CI to track coverage over time and enforce thresholds on PRs.

---

## 11. Mutation Testing

Mutation testing is the gold standard for evaluating test effectiveness. It works by introducing small changes (mutations) to your code and checking if your tests catch them.

### How It Works

```
1. Take your production code
2. Create "mutants" — small changes like:
   - Replace `>` with `>=`
   - Replace `true` with `false`
   - Remove a method call
   - Change `+` to `-`
3. Run your test suite against each mutant
4. If tests fail → mutant "killed" (good!)
5. If tests pass → mutant "survived" (your tests missed this!)
6. Mutation score = killed / total mutants
```

### Mutation Testing Tools

| Language | Tool | Maturity |
|----------|------|----------|
| JS/TS | **Stryker Mutator** | Production-ready, excellent |
| Java/Kotlin | **pitest** | Production-ready, industry standard |
| Python | **mutmut** | Good, actively maintained |
| C#/.NET | **Stryker.NET** | Production-ready |
| Rust | **cargo-mutants** | Good, actively maintained |

### Stryker Mutator (JavaScript/TypeScript)

```bash
npx stryker init  # guided setup
npx stryker run   # run mutation testing
```

```json
// stryker.config.json
{
  "mutate": ["src/**/*.ts", "!src/**/*.test.ts", "!src/**/*.spec.ts"],
  "testRunner": "vitest",
  "reporters": ["html", "clear-text", "progress"],
  "thresholds": { "high": 80, "low": 60, "break": 50 },
  "concurrency": 4
}
```

### pitest (Java)

```xml
<!-- Maven -->
<plugin>
  <groupId>org.pitest</groupId>
  <artifactId>pitest-maven</artifactId>
  <version>1.17.0</version>
  <configuration>
    <targetClasses>
      <param>com.myapp.services.*</param>
    </targetClasses>
    <targetTests>
      <param>com.myapp.services.*Test</param>
    </targetTests>
    <mutationThreshold>80</mutationThreshold>
  </configuration>
</plugin>
```

### When to Use Mutation Testing

- **Core business logic**: High value, tests need to be thorough
- **Financial calculations**: Every edge case matters
- **Security-sensitive code**: Authentication, authorization, validation
- **After refactoring**: Verify tests still catch the same faults

**When to skip:** UI tests, integration tests (too slow), generated code, prototypes.

---

## 12. Property-Based Testing

Property-based testing generates hundreds of random inputs and verifies that properties (invariants) hold for all of them. It catches edge cases that example-based tests miss.

### fast-check (JavaScript/TypeScript)

```typescript
import fc from 'fast-check'

test('sort is idempotent', () => {
  fc.assert(
    fc.property(fc.array(fc.integer()), (arr) => {
      const sorted = mySort([...arr])
      const doubleSorted = mySort([...sorted])
      expect(doubleSorted).toEqual(sorted)
    })
  )
})

test('encode then decode is identity', () => {
  fc.assert(
    fc.property(fc.string(), (s) => {
      expect(decode(encode(s))).toBe(s)
    })
  )
})

test('addition is commutative', () => {
  fc.assert(
    fc.property(fc.integer(), fc.integer(), (a, b) => {
      expect(add(a, b)).toBe(add(b, a))
    })
  )
})
```

### Hypothesis (Python)

```python
from hypothesis import given, strategies as st

@given(st.lists(st.integers()))
def test_sort_is_idempotent(xs):
    sorted_once = sorted(xs)
    sorted_twice = sorted(sorted_once)
    assert sorted_once == sorted_twice

@given(st.text())
def test_encode_decode_roundtrip(s):
    assert decode(encode(s)) == s

@given(st.integers(min_value=1, max_value=10000), st.decimals(min_value=0, max_value=99999))
def test_order_total_is_non_negative(qty, price):
    total = calculate_line_total(qty, price)
    assert total >= 0
```

### Common Properties to Test

| Property | Description | Example |
|----------|-------------|---------|
| **Roundtrip** | encode(decode(x)) == x | Serialization, encryption, compression |
| **Idempotency** | f(f(x)) == f(x) | Sorting, normalization, formatting |
| **Commutativity** | f(a, b) == f(b, a) | Addition, set union, merge |
| **Invariant** | Property holds for all inputs | Total >= 0, length >= 0, valid state |
| **Model-based** | Behavior matches a simpler model | Custom hashmap matches built-in dict |
| **No crash** | Function doesn't throw for any valid input | Parsing, validation |

---

## 13. Snapshot Testing

Snapshot testing captures the output of a function/component and compares it against a stored "snapshot". Useful for detecting unintended changes.

### When to Use Snapshots

**Good use cases:**
- Component rendering output (detect unintended UI changes)
- Serialized data structures (API responses, configuration objects)
- Error messages (ensure they don't change unexpectedly)

**Bad use cases:**
- Large, frequently changing data (constant snapshot updates)
- Random/dynamic data (flaky by nature)
- As a substitute for real assertions (lazy testing)

### Inline Snapshots (Preferred)

```typescript
// Vitest/Jest
test('formats user display name', () => {
  const result = formatDisplayName({ firstName: 'John', lastName: 'Doe', title: 'Dr.' })
  expect(result).toMatchInlineSnapshot(`"Dr. John Doe"`)
})
```

**Inline snapshots** are preferred because the expected value lives right next to the assertion — no separate `.snap` file to maintain.

---

## 14. Component Testing (Frontend)

### Testing Library Approach — Test Behavior, Not Implementation

Testing Library (React, Vue, Angular, Svelte variants) is the standard for component testing. It encourages testing from the user's perspective.

```typescript
// React Testing Library + Vitest
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'

test('submits order when form is valid', async () => {
  const user = userEvent.setup()
  const onSubmit = vi.fn()

  render(<OrderForm onSubmit={onSubmit} />)

  // Interact as a user would
  await user.type(screen.getByLabelText('Quantity'), '3')
  await user.selectOptions(screen.getByLabelText('Product'), 'widget')
  await user.click(screen.getByRole('button', { name: /place order/i }))

  // Assert on the outcome, not internal state
  await waitFor(() => {
    expect(onSubmit).toHaveBeenCalledWith({
      product: 'widget',
      quantity: 3,
    })
  })
})

test('shows validation error for zero quantity', async () => {
  const user = userEvent.setup()
  render(<OrderForm onSubmit={vi.fn()} />)

  await user.type(screen.getByLabelText('Quantity'), '0')
  await user.click(screen.getByRole('button', { name: /place order/i }))

  expect(screen.getByRole('alert')).toHaveTextContent('Quantity must be at least 1')
})
```

### Query Priority (Testing Library)

```
1. getByRole           — accessible role + name (best, most user-like)
2. getByLabelText      — form inputs by label
3. getByPlaceholderText — fallback for unlabeled inputs
4. getByText           — non-interactive text content
5. getByDisplayValue   — current value of form elements
6. getByAltText        — images
7. getByTitle          — title attribute (last resort)
8. getByTestId         — data-testid (escape hatch, avoid if possible)
```

---

## 15. Writing Testable Code

### Principles That Make Code Testable

1. **Dependency Injection**: Pass dependencies in, don't create them internally
2. **Pure Functions**: Functions that return the same output for the same input, no side effects
3. **Single Responsibility**: Each function/class does one thing — easier to test in isolation
4. **Interface Segregation**: Small interfaces are easier to mock than large ones
5. **Separation of Concerns**: Keep I/O at the boundaries, logic in the core

### Hexagonal Architecture for Testability

```
┌───────────────────────────────────────────────┐
│                  Application                   │
│                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │  HTTP     │  │  Domain  │  │ Database │    │
│  │  Adapter  │──│  Logic   │──│ Adapter  │    │
│  │ (in port) │  │ (core)   │  │(out port)│    │
│  └──────────┘  └──────────┘  └──────────┘    │
│       ▲              ▲              ▲          │
│       │              │              │          │
│  Unit test:     Unit test:     Integration:   │
│  Mock domain    Test pure       Testcontainers│
│                 logic directly                 │
└───────────────────────────────────────────────┘
```

**Core domain** = pure business logic, no I/O → easiest to unit test
**Adapters** = I/O boundaries → integration test with fakes or containers
**Composition root** = wires everything together → E2E test

---

## 16. Unit Test Decision Framework

### Choosing the Right Testing Approach

| Scenario | Approach | Tools |
|----------|----------|-------|
| New function with clear inputs/outputs | TDD (write test first) | Framework of your language |
| Bug report with reproduction steps | Write failing test, then fix | Any test framework |
| Refactoring existing code | Add characterization tests first | Approval testing, snapshot testing |
| Complex business rules | Property-based + example-based | fast-check, Hypothesis |
| Hard-to-test legacy code | Seam extraction, then test | Michael Feathers' "Working Effectively with Legacy Code" |
| React/Vue/Svelte components | Testing Library | @testing-library/* |
| Pure utility functions | Simple unit tests | Standard framework |
| Time-dependent logic | Fake timers | vi.useFakeTimers(), freezegun |
| Randomness-dependent logic | Seed the RNG | Inject the random source |

### Test Naming Conventions

**The three-part pattern:**
```
should_[expected behavior]_when_[condition]

// Examples:
should_return_zero_when_cart_is_empty
should_throw_InsufficientStockError_when_quantity_exceeds_stock
should_apply_discount_when_user_has_premium_membership
```

**Or the Given-When-Then pattern in nested describes:**
```typescript
describe('OrderService', () => {
  describe('placeOrder', () => {
    describe('when cart has items', () => {
      it('creates an order with correct total', () => { ... })
      it('charges the payment gateway', () => { ... })
    })
    describe('when cart is empty', () => {
      it('throws EmptyCartError', () => { ... })
    })
  })
})
```

### Common Unit Test Mistakes

| Mistake | Why It's Bad | Fix |
|---------|-------------|-----|
| Testing implementation details | Breaks on refactoring | Test behavior/outcomes instead |
| Too many mocks | Test doesn't verify real behavior | Reduce mocking scope, use fakes |
| No assertions | Test always passes | Every test needs meaningful assertions |
| Shared mutable state | Tests depend on execution order | Reset state in beforeEach/setUp |
| Testing trivial code | Maintenance cost > value | Skip getters, setters, DTOs |
| Giant test methods | Hard to understand failure | One behavior per test |
| Copy-paste test code | Maintenance nightmare | Use factories, helpers, parametrize |
