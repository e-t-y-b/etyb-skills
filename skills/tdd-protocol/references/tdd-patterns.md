# TDD Patterns: Framework-Specific Guidance

Language-specific and framework-specific TDD patterns. Use this reference when you need concrete examples of how to execute TDD in a specific technology stack.

---

## JavaScript / TypeScript (Jest, Vitest)

### Test Structure

```typescript
// Vitest / Jest structure
import { describe, it, expect, beforeEach, vi } from 'vitest';

describe('OrderService', () => {
  let service: OrderService;
  let mockRepo: MockOrderRepository;

  beforeEach(() => {
    mockRepo = {
      save: vi.fn(),
      findById: vi.fn(),
    };
    service = new OrderService(mockRepo);
  });

  describe('createOrder', () => {
    it('calculates total from line items', () => {
      const items = [
        { productId: 'A', price: 10.00, quantity: 2 },
        { productId: 'B', price: 25.00, quantity: 1 },
      ];

      const order = service.createOrder(items);

      expect(order.total).toBe(45.00);
    });

    it('rejects empty item list', () => {
      expect(() => service.createOrder([])).toThrow('Items required');
    });

    it('persists order to repository', async () => {
      mockRepo.save.mockResolvedValue({ id: '123' });

      const order = await service.createOrder([
        { productId: 'A', price: 10.00, quantity: 1 },
      ]);

      expect(mockRepo.save).toHaveBeenCalledWith(
        expect.objectContaining({ total: 10.00 }),
      );
    });
  });
});
```

### Mock Patterns

```typescript
// Module mocking (Jest/Vitest)
vi.mock('./email-service', () => ({
  sendEmail: vi.fn().mockResolvedValue({ sent: true }),
}));

// Manual mock with type safety
const mockEmailService: EmailService = {
  sendEmail: vi.fn().mockResolvedValue({ sent: true }),
  getStatus: vi.fn().mockReturnValue('ready'),
};

// Spy on existing methods
const spy = vi.spyOn(logger, 'warn');
// ... do something that should warn
expect(spy).toHaveBeenCalledWith('Expected warning message');

// Mock fetch / HTTP
import { http, HttpResponse } from 'msw';
import { setupServer } from 'msw/node';

const server = setupServer(
  http.get('/api/users/:id', ({ params }) => {
    return HttpResponse.json({ id: params.id, name: 'Test User' });
  }),
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

### Testing React Components (TDD Style)

```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';

describe('CartSummary', () => {
  // RED: Component doesn't exist yet
  it('displays total price', () => {
    render(<CartSummary items={[{ name: 'Widget', price: 10 }]} />);

    expect(screen.getByText('Total: $10.00')).toBeInTheDocument();
  });

  // RED: Click behavior doesn't exist yet
  it('calls onCheckout when checkout button clicked', () => {
    const onCheckout = vi.fn();
    render(
      <CartSummary
        items={[{ name: 'Widget', price: 10 }]}
        onCheckout={onCheckout}
      />
    );

    fireEvent.click(screen.getByRole('button', { name: /checkout/i }));

    expect(onCheckout).toHaveBeenCalledTimes(1);
  });

  // RED: Empty state doesn't exist yet
  it('shows empty message when no items', () => {
    render(<CartSummary items={[]} />);

    expect(screen.getByText(/cart is empty/i)).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /checkout/i })).not.toBeInTheDocument();
  });
});
```

### Testing Async Code

```typescript
// Promises
it('fetches user data', async () => {
  const user = await userService.getById('123');
  expect(user.name).toBe('Test User');
});

// Rejects
it('throws on invalid id', async () => {
  await expect(userService.getById('')).rejects.toThrow('ID required');
});

// Timers
it('debounces search input', async () => {
  vi.useFakeTimers();
  const onSearch = vi.fn();

  render(<SearchInput onSearch={onSearch} debounceMs={300} />);
  fireEvent.change(screen.getByRole('textbox'), { target: { value: 'test' } });

  expect(onSearch).not.toHaveBeenCalled();
  vi.advanceTimersByTime(300);
  expect(onSearch).toHaveBeenCalledWith('test');

  vi.useRealTimers();
});
```

### Snapshot Testing: When and When Not

```typescript
// GOOD: Snapshot for stable UI structure
it('renders login form', () => {
  const { container } = render(<LoginForm />);
  expect(container).toMatchSnapshot();
});

// BAD: Snapshot for logic — use behavioral assertions instead
// Don't do this:
it('calculates total', () => {
  expect(calculateTotal(items)).toMatchSnapshot();
});
// Do this instead:
it('calculates total', () => {
  expect(calculateTotal(items)).toEqual({ subtotal: 45, tax: 3.60, total: 48.60 });
});
```

**Rule**: Use snapshots for UI structure (HTML, component trees). Never use snapshots for logic, data transformations, or API responses.

---

## Python (pytest)

### Test Structure

```python
# test_order_service.py
import pytest
from order_service import OrderService
from unittest.mock import Mock, patch


class TestOrderService:
    """Tests for OrderService — TDD-driven."""

    @pytest.fixture
    def mock_repo(self):
        return Mock()

    @pytest.fixture
    def service(self, mock_repo):
        return OrderService(repository=mock_repo)

    def test_calculates_total_from_line_items(self, service):
        """RED: OrderService doesn't calculate totals yet."""
        items = [
            {"product_id": "A", "price": 10.00, "quantity": 2},
            {"product_id": "B", "price": 25.00, "quantity": 1},
        ]

        order = service.create_order(items)

        assert order.total == 45.00

    def test_rejects_empty_item_list(self, service):
        """RED: No validation exists yet."""
        with pytest.raises(ValueError, match="Items required"):
            service.create_order([])

    def test_persists_order_to_repository(self, service, mock_repo):
        """RED: Persistence not implemented yet."""
        mock_repo.save.return_value = {"id": "123"}

        service.create_order([
            {"product_id": "A", "price": 10.00, "quantity": 1},
        ])

        mock_repo.save.assert_called_once()
        saved_order = mock_repo.save.call_args[0][0]
        assert saved_order.total == 10.00
```

### Fixtures and Parametrize

```python
# Parametrized tests for data-driven TDD
@pytest.mark.parametrize("items,expected_total", [
    ([], 0),
    ([{"price": 10, "quantity": 1}], 10.00),
    ([{"price": 10, "quantity": 2}], 20.00),
    ([{"price": 10, "quantity": 2}, {"price": 5, "quantity": 3}], 35.00),
    ([{"price": 0.1, "quantity": 3}], 0.30),  # Floating point edge case
])
def test_calculate_subtotal(items, expected_total):
    result = calculate_subtotal(items)
    assert result == pytest.approx(expected_total)


# Shared fixtures in conftest.py
# conftest.py
@pytest.fixture
def sample_items():
    return [
        {"product_id": "A", "price": 10.00, "quantity": 2},
        {"product_id": "B", "price": 25.00, "quantity": 1},
    ]

@pytest.fixture
def db_session():
    """Transactional test fixture — rolls back after each test."""
    session = create_test_session()
    yield session
    session.rollback()
    session.close()
```

### Mocking with unittest.mock and monkeypatch

```python
from unittest.mock import Mock, patch, AsyncMock

# Patching a module-level function
@patch("order_service.send_confirmation_email")
def test_sends_confirmation_after_order(mock_send):
    service = OrderService()
    service.create_order(items)
    mock_send.assert_called_once_with(order_id="123", email="user@test.com")

# monkeypatch for environment/config
def test_uses_production_api_url(monkeypatch):
    monkeypatch.setenv("API_URL", "https://api.prod.example.com")
    config = load_config()
    assert config.api_url == "https://api.prod.example.com"

# Async mocking
@pytest.mark.asyncio
async def test_async_order_creation():
    mock_repo = AsyncMock()
    mock_repo.save.return_value = {"id": "123"}
    service = OrderService(repository=mock_repo)

    result = await service.create_order_async(items)

    assert result.id == "123"
```

### Property-Based Testing with Hypothesis

```python
from hypothesis import given, strategies as st

@given(
    price=st.floats(min_value=0.01, max_value=10000, allow_nan=False),
    quantity=st.integers(min_value=1, max_value=1000),
    tax_rate=st.floats(min_value=0, max_value=0.5, allow_nan=False),
)
def test_total_always_greater_than_or_equal_to_subtotal(price, quantity, tax_rate):
    """Property: total is always >= subtotal when tax rate >= 0."""
    items = [{"price": price, "quantity": quantity}]
    result = calculate_total(items, tax_rate)
    assert result["total"] >= result["subtotal"]


@given(items=st.lists(
    st.fixed_dictionaries({
        "price": st.floats(min_value=0.01, max_value=1000, allow_nan=False),
        "quantity": st.integers(min_value=1, max_value=100),
    }),
    min_size=1,
    max_size=50,
))
def test_subtotal_equals_sum_of_line_items(items):
    """Property: subtotal is always the sum of price * quantity for each item."""
    expected = sum(item["price"] * item["quantity"] for item in items)
    result = calculate_subtotal(items)
    assert result == pytest.approx(expected)
```

---

## Go

### Table-Driven Tests

```go
package cart

import (
    "testing"
)

func TestCalculateTotal(t *testing.T) {
    tests := []struct {
        name      string
        items     []Item
        taxRate   float64
        wantTotal float64
        wantErr   bool
    }{
        {
            name:      "single item with tax",
            items:     []Item{{Price: 10.00, Qty: 1}},
            taxRate:   0.08,
            wantTotal: 10.80,
        },
        {
            name:      "multiple items with tax",
            items:     []Item{{Price: 10.00, Qty: 2}, {Price: 25.00, Qty: 1}},
            taxRate:   0.08,
            wantTotal: 48.60,
        },
        {
            name:      "zero tax rate",
            items:     []Item{{Price: 10.00, Qty: 1}},
            taxRate:   0.0,
            wantTotal: 10.00,
        },
        {
            name:    "empty items returns error",
            items:   []Item{},
            taxRate: 0.08,
            wantErr: true,
        },
        {
            name:    "nil items returns error",
            items:   nil,
            taxRate: 0.08,
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := CalculateTotal(tt.items, tt.taxRate)
            if tt.wantErr {
                if err == nil {
                    t.Fatal("expected error, got nil")
                }
                return
            }
            if err != nil {
                t.Fatalf("unexpected error: %v", err)
            }
            if got.Total != tt.wantTotal {
                t.Errorf("total = %v, want %v", got.Total, tt.wantTotal)
            }
        })
    }
}
```

### Mocking with Interfaces

```go
// Define interface for the dependency
type OrderRepository interface {
    Save(order Order) (string, error)
    FindByID(id string) (Order, error)
}

// Mock implementation for testing (no framework needed)
type mockOrderRepo struct {
    saveFunc     func(Order) (string, error)
    findByIDFunc func(string) (Order, error)
}

func (m *mockOrderRepo) Save(order Order) (string, error) {
    return m.saveFunc(order)
}

func (m *mockOrderRepo) FindByID(id string) (Order, error) {
    return m.findByIDFunc(id)
}

// Test using the mock
func TestOrderService_CreateOrder(t *testing.T) {
    repo := &mockOrderRepo{
        saveFunc: func(o Order) (string, error) {
            return "order-123", nil
        },
    }
    service := NewOrderService(repo)

    id, err := service.CreateOrder([]Item{{Price: 10, Qty: 2}})

    if err != nil {
        t.Fatalf("unexpected error: %v", err)
    }
    if id != "order-123" {
        t.Errorf("id = %q, want %q", id, "order-123")
    }
}
```

### Testing with testify

```go
import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
    "github.com/stretchr/testify/suite"
)

// Simple assertions
func TestCalculateTotal_WithTestify(t *testing.T) {
    result, err := CalculateTotal(items, 0.08)

    require.NoError(t, err)
    assert.Equal(t, 48.60, result.Total)
    assert.Equal(t, 45.00, result.Subtotal)
}

// Test suite for shared setup
type OrderServiceSuite struct {
    suite.Suite
    service *OrderService
    repo    *mockOrderRepo
}

func (s *OrderServiceSuite) SetupTest() {
    s.repo = &mockOrderRepo{}
    s.service = NewOrderService(s.repo)
}

func (s *OrderServiceSuite) TestCreateOrder() {
    s.repo.saveFunc = func(o Order) (string, error) { return "123", nil }

    id, err := s.service.CreateOrder(items)

    s.NoError(err)
    s.Equal("123", id)
}

func TestOrderServiceSuite(t *testing.T) {
    suite.Run(t, new(OrderServiceSuite))
}
```

### Benchmarks Alongside Tests

```go
func BenchmarkCalculateTotal(b *testing.B) {
    items := generateItems(100) // 100 line items
    b.ResetTimer()

    for i := 0; i < b.N; i++ {
        CalculateTotal(items, 0.08)
    }
}
```

---

## Java (JUnit 5)

### Test Structure

```java
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import static org.assertj.core.api.Assertions.*;

class OrderServiceTest {

    private OrderService service;
    private OrderRepository mockRepo;

    @BeforeEach
    void setUp() {
        mockRepo = mock(OrderRepository.class);
        service = new OrderService(mockRepo);
    }

    @Test
    @DisplayName("calculates total from line items with tax")
    void calculatesTotal() {
        var items = List.of(
            new Item("Widget", 10.00, 2),
            new Item("Gadget", 25.00, 1)
        );

        var result = service.calculateTotal(items, 0.08);

        assertThat(result.getSubtotal()).isEqualTo(45.00);
        assertThat(result.getTax()).isCloseTo(3.60, within(0.01));
        assertThat(result.getTotal()).isCloseTo(48.60, within(0.01));
    }

    @Test
    @DisplayName("rejects empty item list")
    void rejectsEmptyItems() {
        assertThatThrownBy(() -> service.calculateTotal(List.of(), 0.08))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage("Items required");
    }
}
```

### Parameterized Tests

```java
@ParameterizedTest
@CsvSource({
    "10.00, 1, 0.08, 10.80",
    "10.00, 2, 0.08, 21.60",
    "25.00, 1, 0.10, 27.50",
    "0.01, 1, 0.00, 0.01",
})
@DisplayName("calculates total with various inputs")
void calculatesVariousTotals(double price, int qty, double tax, double expected) {
    var items = List.of(new Item("Test", price, qty));

    var result = service.calculateTotal(items, tax);

    assertThat(result.getTotal()).isCloseTo(expected, within(0.01));
}
```

### Mockito Patterns

```java
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepo;

    @Mock
    private EmailService emailService;

    @InjectMocks
    private OrderService service;

    @Test
    void persistsOrderAndSendsConfirmation() {
        when(orderRepo.save(any(Order.class))).thenReturn("order-123");

        service.createOrder(items);

        verify(orderRepo).save(argThat(order ->
            order.getTotal() == 45.00
        ));
        verify(emailService).sendConfirmation("order-123");
    }

    @Test
    void rollsBackOnEmailFailure() {
        when(orderRepo.save(any())).thenReturn("order-123");
        doThrow(new EmailException("SMTP down"))
            .when(emailService).sendConfirmation(any());

        assertThatThrownBy(() -> service.createOrder(items))
            .isInstanceOf(OrderException.class);

        verify(orderRepo).delete("order-123");
    }
}
```

### Spring Boot Integration TDD

```java
@SpringBootTest
@AutoConfigureMockMvc
class OrderControllerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private OrderService orderService;

    @Test
    void createOrderReturns201WithOrderId() throws Exception {
        when(orderService.createOrder(any())).thenReturn(new Order("123", 45.00));

        mockMvc.perform(post("/api/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"items": [{"productId": "A", "price": 10.00, "quantity": 2}]}
                    """))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.orderId").value("123"))
            .andExpect(jsonPath("$.total").value(45.00));
    }

    @Test
    void createOrderReturns400ForEmptyItems() throws Exception {
        mockMvc.perform(post("/api/orders")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"items": []}
                    """))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.error").value("Items required"));
    }
}
```

---

## Rust

### Test Structure

```rust
// In src/cart.rs

pub struct Item {
    pub name: String,
    pub price: f64,
    pub quantity: u32,
}

pub struct CartTotal {
    pub subtotal: f64,
    pub tax: f64,
    pub total: f64,
}

pub fn calculate_total(items: &[Item], tax_rate: f64) -> Result<CartTotal, String> {
    if items.is_empty() {
        return Err("Items required".into());
    }

    let subtotal: f64 = items.iter()
        .map(|item| item.price * item.quantity as f64)
        .sum();
    let tax = (subtotal * tax_rate * 100.0).round() / 100.0;
    let total = subtotal + tax;

    Ok(CartTotal { subtotal, tax, total })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn calculates_total_with_tax() {
        let items = vec![
            Item { name: "Widget".into(), price: 10.0, quantity: 2 },
            Item { name: "Gadget".into(), price: 25.0, quantity: 1 },
        ];

        let result = calculate_total(&items, 0.08).unwrap();

        assert_eq!(result.subtotal, 45.0);
        assert_eq!(result.tax, 3.6);
        assert_eq!(result.total, 48.6);
    }

    #[test]
    fn rejects_empty_items() {
        let result = calculate_total(&[], 0.08);
        assert!(result.is_err());
        assert_eq!(result.unwrap_err(), "Items required");
    }

    #[test]
    fn handles_zero_tax() {
        let items = vec![Item { name: "A".into(), price: 10.0, quantity: 1 }];

        let result = calculate_total(&items, 0.0).unwrap();

        assert_eq!(result.total, 10.0);
        assert_eq!(result.tax, 0.0);
    }
}
```

### Property-Based Testing with proptest

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn total_always_gte_subtotal(
        price in 0.01f64..10000.0,
        quantity in 1u32..1000,
        tax_rate in 0.0f64..0.5,
    ) {
        let items = vec![Item {
            name: "Test".into(),
            price,
            quantity,
        }];

        let result = calculate_total(&items, tax_rate).unwrap();
        prop_assert!(result.total >= result.subtotal);
    }

    #[test]
    fn subtotal_is_sum_of_line_items(
        prices in prop::collection::vec(0.01f64..1000.0, 1..20),
        quantities in prop::collection::vec(1u32..100, 1..20),
    ) {
        let len = prices.len().min(quantities.len());
        let items: Vec<Item> = (0..len)
            .map(|i| Item {
                name: format!("Item {}", i),
                price: prices[i],
                quantity: quantities[i],
            })
            .collect();

        let expected: f64 = items.iter()
            .map(|i| i.price * i.quantity as f64)
            .sum();

        let result = calculate_total(&items, 0.0).unwrap();
        prop_assert!((result.subtotal - expected).abs() < f64::EPSILON);
    }
}
```

### Integration Tests (tests/ directory)

```rust
// tests/integration_test.rs
// These are separate from unit tests and test the public API

use my_crate::cart::{calculate_total, Item};

#[test]
fn full_cart_workflow() {
    let items = vec![
        Item { name: "Widget".into(), price: 10.0, quantity: 2 },
        Item { name: "Gadget".into(), price: 25.0, quantity: 1 },
    ];

    let result = calculate_total(&items, 0.08).unwrap();

    assert_eq!(result.total, 48.6);
}
```

### Testing Async with tokio

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn creates_order_and_returns_id() {
        let repo = MockOrderRepo::new();
        repo.expect_save().returning(|_| Ok("order-123".into()));

        let service = OrderService::new(repo);
        let result = service.create_order(items).await.unwrap();

        assert_eq!(result.id, "order-123");
    }

    #[tokio::test]
    async fn returns_error_on_repo_failure() {
        let repo = MockOrderRepo::new();
        repo.expect_save()
            .returning(|_| Err(RepoError::ConnectionLost));

        let service = OrderService::new(repo);
        let result = service.create_order(items).await;

        assert!(matches!(result, Err(OrderError::PersistenceFailed(_))));
    }
}
```

---

## Anti-Patterns (Critical Section)

These are the most common ways TDD discipline breaks down. Recognize them and fix them immediately.

### 1. Fake-Green

**What it looks like**: Test passes before implementation exists.

```typescript
// ANTI-PATTERN: Test passes without real implementation
it('validates email', () => {
  const result = validateEmail('test@example.com');
  expect(result).toBeTruthy(); // passes because undefined is... wait, this would fail
  // Actually, the function returns true for ALL inputs — fake green
});
```

**Why it's dangerous**: You think you have a passing test, but it doesn't actually test the behavior. Implementation bugs will be invisible.

**Fix**: Always verify RED first. If a test passes immediately, it's wrong.

### 2. Test-After-Fill

**What it looks like**: Code is written first, then tests are fitted around it.

```python
# ANTI-PATTERN: Test written after code, testing implementation details
def test_order_service_create_order():
    service = OrderService()
    # Testing that specific internal methods are called in specific order
    # This test mirrors the implementation, not the behavior
    assert service._validate_items.called
    assert service._calculate_subtotal.called
    assert service._apply_tax.called
    assert service._persist.called
```

**Why it's dangerous**: Tests are coupled to implementation, not behavior. They break on every refactor. They pass even if the behavior is wrong, as long as the methods are called.

**Fix**: Test WHAT happens, not HOW. `assert order.total == 48.60`, not `assert _calculate_subtotal.called`.

### 3. Snapshot-Only

**What it looks like**: Tests rely entirely on snapshots with no behavioral assertions.

```typescript
// ANTI-PATTERN: Snapshot with no behavioral assertion
it('renders order summary', () => {
  const { container } = render(<OrderSummary order={mockOrder} />);
  expect(container).toMatchSnapshot();
  // What if the total is wrong? The snapshot will just update.
});
```

**Why it's dangerous**: Snapshots test structure, not behavior. When they break, developers blindly update them with `--updateSnapshot` instead of investigating.

**Fix**: Add behavioral assertions alongside snapshots: `expect(screen.getByText('$48.60')).toBeInTheDocument()`.

### 4. Happy-Path-Only

**What it looks like**: All tests cover the success case. No error handling, no edge cases, no boundary conditions.

```python
# ANTI-PATTERN: Only testing the happy path
def test_create_order():
    result = create_order(valid_items)
    assert result.id is not None
# What about: empty items? negative prices? None items? huge quantities?
# What about: database down? duplicate order? concurrent creation?
```

**Why it's dangerous**: Happy-path tests create false confidence. The code "works" until it encounters any non-ideal input, which is most of production traffic.

**Fix**: After the happy path, immediately write tests for: empty/null input, boundary values, error conditions, concurrent access.

### 5. Over-Mocking

**What it looks like**: So many mocks that the test doesn't test anything real.

```java
// ANTI-PATTERN: Everything is mocked
@Test
void createOrder() {
    when(mockValidator.validate(any())).thenReturn(true);
    when(mockCalculator.calculate(any())).thenReturn(45.00);
    when(mockTaxService.apply(any(), any())).thenReturn(48.60);
    when(mockRepo.save(any())).thenReturn("123");
    when(mockEmailer.send(any())).thenReturn(true);

    service.createOrder(items);

    verify(mockRepo).save(any()); // What did we actually test? That mocks work?
}
```

**Why it's dangerous**: You're testing that your mocks return what you told them to return. The real objects might behave completely differently. Bugs hide in the gaps between mocks.

**Fix**: Mock only external boundaries (HTTP, database, file system). Use real objects for business logic. If you need to mock 5+ things, your code has too many dependencies.

### 6. Test-Per-Method

**What it looks like**: One test per method, mirroring the class structure.

```python
# ANTI-PATTERN: Testing methods, not behaviors
class TestOrderService:
    def test_validate_items(self): ...
    def test_calculate_subtotal(self): ...
    def test_apply_tax(self): ...
    def test_persist_order(self): ...
```

**Why it's dangerous**: Tests are coupled to the class structure. Renaming a method breaks a test. Private methods get tested directly. The tests don't describe behavior that a user or consumer cares about.

**Fix**: Organize tests by behavior: `test_creates_order_with_correct_total`, `test_rejects_empty_cart`, `test_applies_regional_tax_rate`. Test through the public API.

### 7. Assertion-Free Tests

**What it looks like**: Test runs code but never asserts anything.

```typescript
// ANTI-PATTERN: No assertions
it('processes order', () => {
  const service = new OrderService();
  service.processOrder(items); // runs without error = "passes"
  // But did it do the right thing? We have no idea.
});
```

**Why it's dangerous**: The test passes as long as the code doesn't throw. It provides zero confidence about correctness. It inflates coverage numbers while testing nothing.

**Fix**: Every test must assert something. If you can't think of what to assert, you don't understand the behavior well enough. `expect(result.total).toBe(48.60)` — be specific.

---

## TDD Pattern Selection Guide

| Situation | Recommended Pattern |
|-----------|-------------------|
| Pure business logic | Classical TDD (inside-out), real objects, no mocks |
| API endpoint | Outside-in TDD, mock the service layer |
| React/UI component | Render-act-assert with Testing Library |
| Database interaction | Integration test with real DB (Testcontainers), TDD the query logic |
| External API consumer | Mock the HTTP boundary (MSW, WireMock), TDD the client logic |
| Data transformation | Parametrized/table-driven tests, many input/output pairs |
| Error handling | Test each error condition independently, verify error messages |
| Concurrent code | Property-based testing, stress tests with multiple threads/goroutines |
| Configuration | Test that config loads and produces expected behavior |
| CLI tool | Test the command handler functions, mock I/O |
