# Red-Green-Refactor: The TDD Cycle

This is the mechanical heart of TDD. Every implementation follows this cycle. No shortcuts. No variations. The discipline IS the value.

## The Cycle Overview

```
    ┌─────────┐
    │   RED   │ ◄── Write a single failing test
    └────┬────┘
         │
         ▼
    ┌─────────┐
    │ VERIFY  │ ◄── Run it. Confirm it fails for the RIGHT reason.
    │   RED   │
    └────┬────┘
         │
         ▼
    ┌─────────┐
    │  GREEN  │ ◄── Write MINIMAL code to make it pass
    └────┬────┘
         │
         ▼
    ┌─────────┐
    │ VERIFY  │ ◄── Run ALL tests. Everything must be green.
    │  GREEN  │
    └────┬────┘
         │
         ▼
    ┌──────────┐
    │ REFACTOR │ ◄── Clean up. Tests stay green throughout.
    └────┬─────┘
         │
         ▼
    ┌─────────┐
    │ COMMIT  │ ◄── Small, green commit. Then next cycle.
    └─────────┘
```

---

## Phase 1: RED — Write a Single Failing Test

### What RED Means

Write ONE test that describes ONE behavior the code should have. The test MUST fail because the behavior does not exist yet. Not because of a typo. Not because of a missing import. Because the behavior is genuinely absent.

### Rules of RED

1. **One test at a time** — Do not write multiple failing tests. Write one, make it green, then write the next.
2. **Test behavior, not implementation** — "it calculates total with tax" not "it calls multiply method"
3. **Name the test descriptively** — The test name should read like a specification
4. **Set up minimal context** — Only arrange what this specific test needs
5. **Assert one logical concept** — Multiple assertions are fine if they verify one behavior

### RED in JavaScript/TypeScript (Jest/Vitest)

```typescript
// RED: We want a function that calculates total price with tax
// This test WILL FAIL because calculateTotal doesn't exist yet

import { describe, it, expect } from 'vitest';
import { calculateTotal } from './cart';

describe('calculateTotal', () => {
  it('applies tax rate to subtotal', () => {
    const items = [
      { name: 'Widget', price: 10.00, quantity: 2 },
      { name: 'Gadget', price: 25.00, quantity: 1 },
    ];
    const taxRate = 0.08; // 8%

    const result = calculateTotal(items, taxRate);

    expect(result).toEqual({
      subtotal: 45.00,
      tax: 3.60,
      total: 48.60,
    });
  });
});
```

### RED in Python (pytest)

```python
# RED: We want a function that calculates total price with tax
# This test WILL FAIL because calculate_total doesn't exist yet

from cart import calculate_total


def test_calculate_total_applies_tax_to_subtotal():
    items = [
        {"name": "Widget", "price": 10.00, "quantity": 2},
        {"name": "Gadget", "price": 25.00, "quantity": 1},
    ]
    tax_rate = 0.08  # 8%

    result = calculate_total(items, tax_rate)

    assert result == {
        "subtotal": 45.00,
        "tax": 3.60,
        "total": 48.60,
    }
```

### RED in Go (Table-Driven Tests)

```go
// RED: We want a function that calculates total price with tax
// This test WILL FAIL because CalculateTotal doesn't exist yet

package cart

import "testing"

func TestCalculateTotal(t *testing.T) {
    tests := []struct {
        name     string
        items    []Item
        taxRate  float64
        wantSub  float64
        wantTax  float64
        wantTotal float64
    }{
        {
            name: "applies tax rate to subtotal",
            items: []Item{
                {Name: "Widget", Price: 10.00, Quantity: 2},
                {Name: "Gadget", Price: 25.00, Quantity: 1},
            },
            taxRate:   0.08,
            wantSub:   45.00,
            wantTax:   3.60,
            wantTotal: 48.60,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := CalculateTotal(tt.items, tt.taxRate)
            if result.Subtotal != tt.wantSub {
                t.Errorf("subtotal = %v, want %v", result.Subtotal, tt.wantSub)
            }
            if result.Tax != tt.wantTax {
                t.Errorf("tax = %v, want %v", result.Tax, tt.wantTax)
            }
            if result.Total != tt.wantTotal {
                t.Errorf("total = %v, want %v", result.Total, tt.wantTotal)
            }
        })
    }
}
```

### RED in Java (JUnit 5)

```java
// RED: We want a method that calculates total price with tax
// This test WILL FAIL because calculateTotal doesn't exist yet

import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.assertThat;

class CartTest {

    @Test
    void appliesTaxRateToSubtotal() {
        var items = List.of(
            new Item("Widget", 10.00, 2),
            new Item("Gadget", 25.00, 1)
        );
        double taxRate = 0.08;

        var result = Cart.calculateTotal(items, taxRate);

        assertThat(result.subtotal()).isEqualTo(45.00);
        assertThat(result.tax()).isEqualTo(3.60);
        assertThat(result.total()).isEqualTo(48.60);
    }
}
```

### RED in Rust

```rust
// RED: We want a function that calculates total price with tax
// This test WILL FAIL because calculate_total doesn't exist yet

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn applies_tax_rate_to_subtotal() {
        let items = vec![
            Item { name: "Widget".into(), price: 10.00, quantity: 2 },
            Item { name: "Gadget".into(), price: 25.00, quantity: 1 },
        ];
        let tax_rate = 0.08;

        let result = calculate_total(&items, tax_rate);

        assert_eq!(result.subtotal, 45.00);
        assert_eq!(result.tax, 3.60);
        assert_eq!(result.total, 48.60);
    }
}
```

---

## Phase 2: Verify RED

### Why This Step Exists

Running the test and confirming it fails is NOT optional. You must verify:

1. **The test actually runs** — No syntax errors, no import failures, no configuration issues
2. **The test fails** — If it passes, your test is wrong (it doesn't test what you think)
3. **The failure message makes sense** — The error should clearly describe what's missing

### What a Good RED Failure Looks Like

```
FAIL  src/cart.test.ts
  ✕ applies tax rate to subtotal

  Error: Cannot find module './cart'
```

This is acceptable — the module doesn't exist yet. The test fails because the behavior is absent.

```
FAIL  src/cart.test.ts
  ✕ applies tax rate to subtotal

  TypeError: calculateTotal is not a function
```

Also acceptable — the function doesn't exist yet.

### What a Bad RED Failure Looks Like

```
FAIL  src/cart.test.ts
  SyntaxError: Unexpected token '}'
```

This is NOT a valid RED. The test has a syntax error. Fix the test first.

```
FAIL  src/cart.test.ts
  ✕ applies tax rate to subtotal

  Expected: 48.60
  Received: undefined
```

This IS a valid RED if `calculateTotal` exists but returns nothing. It means the function exists but doesn't implement the behavior yet.

### If the Test Passes on First Run

**Your test is wrong.** It is testing something that already exists, or it is not testing what you think it is testing. Common causes:

- Testing a behavior that was already implemented (write a different test)
- The assertion is too loose (`expect(result).toBeTruthy()` — this passes for almost anything)
- You imported the wrong module or called the wrong function
- The test setup provides a default that satisfies the assertion

Delete the test. Understand why it passed. Write a better test.

---

## Phase 3: GREEN — Write the Minimal Code

### What GREEN Means

Write the **absolute minimum** code to make the failing test pass. Not elegant code. Not complete code. Not the code you "know" you'll need. Just enough to go green.

### The Discipline of Minimal

This is where TDD is hardest. You KNOW you need error handling. You KNOW you need edge cases. You KNOW the algorithm could be more efficient. **Don't write any of that yet.** Each of those things will come when a test demands it.

### GREEN Examples

**After the RED test for `calculateTotal`:**

```typescript
// GREEN: The MINIMAL implementation to make the test pass
// This is deliberately simple — we'll add edge cases when tests demand them

export function calculateTotal(
  items: Array<{ price: number; quantity: number }>,
  taxRate: number,
) {
  const subtotal = items.reduce(
    (sum, item) => sum + item.price * item.quantity,
    0,
  );
  const tax = Math.round(subtotal * taxRate * 100) / 100;
  const total = subtotal + tax;

  return { subtotal, tax, total };
}
```

**What NOT to do in GREEN:**

```typescript
// BAD GREEN: This is over-implementation
export function calculateTotal(items, taxRate) {
  if (!items || items.length === 0) throw new Error('Items required');  // NO — no test demands this yet
  if (taxRate < 0 || taxRate > 1) throw new Error('Invalid tax rate');  // NO — no test demands this yet

  const subtotal = items.reduce((sum, item) => {
    if (item.quantity < 0) throw new Error('Invalid quantity');  // NO — no test demands this yet
    return sum + item.price * item.quantity;
  }, 0);

  // ... etc
}
```

Each of those guards will be added when a test says "what happens with empty items?" or "what happens with a negative tax rate?" Those are future RED steps.

### The Fake-It-Till-You-Make-It Technique

Sometimes the minimal GREEN is a hardcoded value:

```python
# RED: test_greet_returns_hello_name
def test_greet_returns_hello_name():
    assert greet("World") == "Hello, World!"

# GREEN: The minimal implementation
def greet(name):
    return "Hello, World!"  # Yes, this is valid GREEN
```

This feels wrong, but it's correct TDD. The next test will force you to generalize:

```python
# Next RED: force generalization
def test_greet_with_different_name():
    assert greet("Alice") == "Hello, Alice!"

# Next GREEN: now you must use the parameter
def greet(name):
    return f"Hello, {name}!"
```

This technique is called **Triangulation** — each new test constrains the implementation further until the fake can't work anymore.

---

## Phase 4: Verify GREEN

### Why This Step Exists

You must run **ALL tests**, not just the new one. Reasons:

1. Your new code might break an existing test
2. Your new code might have unintended side effects
3. Running all tests proves the system still works as a whole

### The Command

Run the full test suite, not just the new test file:

```bash
# JavaScript/TypeScript
npm test          # or: npx vitest run
npx jest          # all tests

# Python
pytest            # all tests
python -m pytest  # all tests

# Go
go test ./...     # all tests in all packages

# Java
mvn test          # all tests
./gradlew test    # all tests

# Rust
cargo test        # all tests
```

### If Another Test Broke

**Stop.** Do not proceed to REFACTOR. Your GREEN step broke something.

1. Read the failing test — understand what behavior broke
2. Adjust your implementation to satisfy BOTH the new test AND the existing tests
3. If the existing test is wrong (testing implementation details that legitimately changed), update the existing test — but be very careful here. Most of the time, your new code is the problem.
4. Run ALL tests again. Only proceed when everything is green.

### If the New Test Still Fails

Your GREEN wasn't sufficient. Add more code — but still keep it minimal. Common issues:

- Off-by-one error in the implementation
- Type mismatch (string vs number)
- Floating point comparison (use `toBeCloseTo` / `pytest.approx`)
- Async code not awaited

---

## Phase 5: REFACTOR — Clean Up

### What REFACTOR Means

Now — and ONLY now — you clean up. With all tests green, you have a safety net. Refactoring means changing the structure of code without changing its behavior. The tests prove behavior is preserved.

### What to Refactor

**In production code:**
- Extract methods/functions for clarity
- Rename variables for readability
- Remove duplication (DRY)
- Improve data structures
- Apply design patterns where they reduce complexity
- Simplify conditional logic

**In test code (equally important):**
- Extract shared setup to `beforeEach` / fixtures / helpers
- Improve test names for clarity
- Remove duplication between tests
- Create test utilities and builders
- Ensure test readability (a test should read like documentation)

### Refactoring Rules

1. **Tests stay green throughout** — Run tests after every refactoring step, not just at the end
2. **No new behavior** — If you find yourself adding a feature, STOP. That's a new RED
3. **Small steps** — Extract one method, run tests. Rename one variable, run tests. Don't batch refactoring
4. **Refactor both** — Production code AND test code. Test code is production code

### Refactoring Example

**Before refactoring (after GREEN):**

```typescript
export function calculateTotal(items, taxRate) {
  const subtotal = items.reduce(
    (sum, item) => sum + item.price * item.quantity,
    0,
  );
  const tax = Math.round(subtotal * taxRate * 100) / 100;
  const total = subtotal + tax;
  return { subtotal, tax, total };
}
```

**After refactoring:**

```typescript
function sumLineItems(items: CartItem[]): number {
  return items.reduce(
    (sum, item) => sum + item.price * item.quantity,
    0,
  );
}

function roundCurrency(amount: number): number {
  return Math.round(amount * 100) / 100;
}

export function calculateTotal(
  items: CartItem[],
  taxRate: number,
): CartTotal {
  const subtotal = sumLineItems(items);
  const tax = roundCurrency(subtotal * taxRate);
  const total = roundCurrency(subtotal + tax);
  return { subtotal, tax, total };
}
```

The tests still pass. The behavior is identical. The code is clearer.

---

## Phase 6: COMMIT

### The Commit Rhythm

After every green-refactor cycle, commit. This creates:

- **Clean git history** — Each commit is a working state
- **Bisectable history** — `git bisect` can find regressions
- **Reviewable PRs** — Reviewer can step through the TDD process
- **Safety net** — You can always revert to the last green state

### Commit Message Patterns

```
# Option A: Behavior-focused (preferred)
feat: calculate cart total with tax applied
test: add edge case for empty cart
refactor: extract tax calculation helper

# Option B: TDD-phase-focused (for learning/tracking)
RED: add test for cart total with tax
GREEN: implement cart total calculation
REFACTOR: extract sumLineItems and roundCurrency

# Option C: Conventional commits (if team uses them)
feat(cart): calculate total with tax rate
test(cart): verify empty cart returns zero total
refactor(cart): extract currency rounding utility
```

### When NOT to Commit RED

Some teams commit every phase (RED, GREEN, REFACTOR). Others only commit GREEN+REFACTOR. Both are valid:

| Approach | Pros | Cons |
|----------|------|------|
| Commit every phase | Complete TDD audit trail, can see the test-first discipline | Noisy history, RED commits don't compile |
| Commit GREEN+REFACTOR only | Clean history, every commit is green | Less visible that TDD was followed |
| Squash to one commit per feature | Cleanest history for main branch | TDD evidence lost (fine if PR shows it) |

Choose what works for your team. The important thing is that commits are frequent and each GREEN state is captured.

---

## The Outside-In Approach (London School / Mockist TDD)

### When to Use Outside-In

- Building features that span multiple layers (UI -> API -> Service -> Database)
- Working with existing systems where you want to define the outer behavior first
- When the user story defines the behavior from the outside

### How It Works

```
1. Start with an acceptance test (outermost layer)
   → This test defines the feature behavior
   → It FAILS because nothing is implemented

2. Drop down to the next layer
   → Write a test for the component the acceptance test needs
   → Mock the layer below it
   → Make it green

3. Continue inward
   → Each layer gets its own test
   → Each layer mocks the layer below
   → Work inward until you reach the bottom

4. Remove mocks at the bottom
   → The innermost layer tests against real implementations
   → Integration tests verify the layers work together

5. Acceptance test passes
   → When all inner layers are complete, the outer test goes green
```

### Outside-In Example

```typescript
// 1. Acceptance test (outer): API endpoint
it('POST /api/orders creates an order and returns 201', async () => {
  const response = await request(app)
    .post('/api/orders')
    .send({ items: [{ productId: '123', quantity: 2 }] });

  expect(response.status).toBe(201);
  expect(response.body.orderId).toBeDefined();
});

// 2. Controller test: mock the service
it('delegates to OrderService and returns created order', () => {
  const mockService = { createOrder: vi.fn().mockResolvedValue({ id: 'abc' }) };
  const controller = new OrderController(mockService);

  const result = await controller.create({ items: [...] });

  expect(mockService.createOrder).toHaveBeenCalledWith({ items: [...] });
  expect(result.orderId).toBe('abc');
});

// 3. Service test: mock the repository
it('calculates total and persists order', () => {
  const mockRepo = { save: vi.fn().mockResolvedValue({ id: 'abc' }) };
  const service = new OrderService(mockRepo);

  const result = await service.createOrder({ items: [...] });

  expect(mockRepo.save).toHaveBeenCalledWith(
    expect.objectContaining({ total: 45.00 })
  );
});

// 4. Repository test: real database (innermost)
it('persists order to database', async () => {
  const repo = new OrderRepository(testDb);

  const saved = await repo.save({ items: [...], total: 45.00 });

  const found = await testDb.query('SELECT * FROM orders WHERE id = $1', [saved.id]);
  expect(found.rows[0].total).toBe(45.00);
});
```

---

## The Inside-Out Approach (Chicago School / Classical TDD)

### When to Use Inside-Out

- Building new components from scratch with no existing outer layer
- When the domain logic is the core value (DDD-style)
- When you want to minimize mocking
- When building libraries or utilities

### How It Works

```
1. Start with the smallest, innermost unit
   → Test the core domain logic with no dependencies
   → Real objects, no mocks

2. Compose upward
   → Build the next layer using the real inner components
   → Tests use real implementations, not mocks

3. Continue outward
   → Each layer integrates with the real layer below
   → Mocks only for truly external dependencies (HTTP, database)

4. Add integration tests
   → Verify the composed system works end-to-end
```

### Inside-Out Example

```python
# 1. Innermost: domain logic (no dependencies)
def test_line_item_calculates_subtotal():
    item = LineItem(price=10.00, quantity=3)
    assert item.subtotal == 30.00

# 2. Compose: order uses real line items
def test_order_calculates_total_from_line_items():
    order = Order(items=[
        LineItem(price=10.00, quantity=2),
        LineItem(price=25.00, quantity=1),
    ])
    assert order.subtotal == 45.00

# 3. Continue outward: service uses real order
def test_order_service_applies_tax():
    service = OrderService(tax_rate=0.08)
    order = Order(items=[LineItem(price=10.00, quantity=2)])

    result = service.process(order)

    assert result.tax == 1.60
    assert result.total == 21.60

# 4. Outermost: controller uses real service (mock only DB)
def test_create_order_endpoint(mock_db):
    service = OrderService(tax_rate=0.08)
    controller = OrderController(service, mock_db)

    response = controller.create({"items": [{"price": 10.00, "quantity": 2}]})

    assert response.status_code == 201
```

---

## Choosing Between Outside-In and Inside-Out

| Factor | Outside-In | Inside-Out |
|--------|-----------|------------|
| **Starting point** | User behavior / acceptance criteria | Core domain logic |
| **Mocking** | Heavy (mock inner layers) | Light (mock only external boundaries) |
| **Best for** | Feature stories, API design, UI features | Domain logic, libraries, utilities |
| **Risk** | Over-mocking, tests pass but integration fails | Bottom-up may not match outer requirements |
| **Design driver** | The test shapes the API from the consumer's perspective | The test shapes the domain model from the inside |
| **When stuck** | "What should the user see/get?" | "What is the simplest piece I can build and test?" |

### The Pragmatic Middle Ground

Most experienced TDD practitioners use both:

1. **Start outside-in** for the feature: write an acceptance test that defines the outer behavior
2. **Switch to inside-out** for the internals: TDD the domain logic from the smallest unit up
3. **Connect the layers**: the acceptance test goes green when the inside-out implementation is complete

This gives you the best of both worlds: the outer test ensures you build the right thing, the inner tests ensure each piece works correctly.

---

## Advanced Cycle Techniques

### Triangulation

When unsure how to generalize, add more examples:

```python
# First test: specific case
def test_add_two_numbers():
    assert add(2, 3) == 5

# GREEN: could hardcode return 5

# Second test: forces generalization
def test_add_different_numbers():
    assert add(10, 20) == 30

# GREEN: now must actually implement addition
```

### Transformation Priority Premise

When going from RED to GREEN, prefer simpler transformations:

1. `{}` -> nil/null (return nothing)
2. nil -> constant (return a hardcoded value)
3. constant -> variable (use a parameter)
4. unconditional -> conditional (add an if)
5. scalar -> collection (single value to list)
6. statement -> recursion/iteration (loop)

Each transformation is a small step. Prefer the simplest transformation that makes the test pass.

### The Three Laws of TDD (Robert C. Martin)

1. You may not write production code until you have written a failing test
2. You may not write more of a test than is sufficient to fail (and not compiling is failing)
3. You may not write more production code than is sufficient to pass the currently failing test

These three laws create a tight cycle measured in seconds to minutes, not hours.

---

## Common Cycle Mistakes

| Mistake | Why It's Wrong | How to Fix |
|---------|---------------|-----------|
| Writing multiple failing tests at once | Breaks the "one test at a time" rule; you lose focus | Delete all but one. Make it green. Then write the next |
| Writing production code before the test | Entire point of TDD is test-first | Stop. Delete the code. Write the test. Then rewrite the code |
| Making the test pass with too much code | You're guessing at requirements; tests should drive design | Delete the extra code. It will come back when a test demands it |
| Skipping the refactor step | Technical debt accumulates; code becomes unreadable | Schedule refactoring into your cycle. It's not optional |
| Not running ALL tests after GREEN | You might break something else without knowing | Always run the full suite. Set up `--watch` for instant feedback |
| Committing broken tests | History contains non-green states | Only commit when all tests pass (or explicitly mark RED commits) |
| Testing implementation details | Tests break on every refactor; they test HOW not WHAT | Rewrite tests to test behavior through the public API |
| Giant refactoring steps | Risk of introducing bugs in a big batch | Small steps: extract one thing, run tests, repeat |
