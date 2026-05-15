# Order Management Architecture — Deep Reference

**Always use `WebSearch` to verify OMS platform features, fulfillment provider APIs, and shipping carrier integrations before giving advice. This reference provides architectural context; the ecosystem evolves rapidly.**

## Table of Contents
1. [Order Lifecycle & State Machine](#1-order-lifecycle--state-machine)
2. [Order Data Model](#2-order-data-model)
3. [Order Orchestration](#3-order-orchestration)
4. [Fulfillment Architecture](#4-fulfillment-architecture)
5. [Post-Order Modifications](#5-post-order-modifications)
6. [Returns & Exchanges](#6-returns--exchanges)
7. [Notifications & Communication](#7-notifications--communication)
8. [Order Analytics & Reporting](#8-order-analytics--reporting)
9. [B2B Order Management](#9-b2b-order-management)
10. [Distributed Order Management](#10-distributed-order-management)

---

## 1. Order Lifecycle & State Machine

### Order State Machine

An order is NOT a single linear flow — it has parallel state tracks that evolve independently:

```
ORDER STATES (overall):
  placed → confirmed → processing → partially_shipped → shipped → delivered → completed
                    ↘ canceled                      ↗ partially_returned → returned

PAYMENT STATES (independent track):
  pending → authorized → partially_captured → captured → partially_refunded → refunded

FULFILLMENT STATES (per shipment):
  unfulfilled → picking → packed → shipped → in_transit → delivered → returned
```

### State Machine Implementation

```typescript
// Using XState-style state machine definition
const orderStateMachine = {
  id: 'order',
  initial: 'placed',
  states: {
    placed: {
      on: {
        PAYMENT_AUTHORIZED: 'confirmed',
        PAYMENT_FAILED: 'payment_failed',
        CANCEL: 'canceled',
      },
    },
    confirmed: {
      on: {
        BEGIN_FULFILLMENT: 'processing',
        CANCEL: 'canceled',
        MODIFY: 'confirmed', // stay in confirmed, apply modifications
      },
    },
    processing: {
      on: {
        PARTIAL_SHIP: 'partially_shipped',
        SHIP: 'shipped',
        CANCEL: 'canceled', // only if not yet shipped
      },
    },
    partially_shipped: {
      on: {
        SHIP_REMAINING: 'shipped',
        CANCEL_REMAINING: 'shipped', // ship what's shipped, cancel the rest
      },
    },
    shipped: {
      on: {
        DELIVER: 'delivered',
        RETURN_REQUESTED: 'shipped', // stay shipped, return is a parallel process
      },
    },
    delivered: {
      on: {
        RETURN_REQUESTED: 'delivered',
        COMPLETE: 'completed', // after return window closes
      },
    },
    completed: {
      type: 'final',
    },
    canceled: {
      type: 'final',
      entry: ['releaseInventory', 'refundPayment', 'notifyCustomer'],
    },
    payment_failed: {
      on: {
        RETRY_PAYMENT: 'placed',
        CANCEL: 'canceled',
      },
    },
  },
};
```

### State Machine Visualization

```
                    ┌──────────────┐
                    │    placed    │
                    └──────┬───────┘
                           │ PAYMENT_AUTHORIZED
                    ┌──────▼───────┐
               ┌────│   confirmed  │────┐
               │    └──────┬───────┘    │
               │           │ BEGIN_     │ CANCEL
               │           │ FULFILLMENT│
               │    ┌──────▼───────┐    │
               │    │  processing  │────┤
               │    └──┬───────┬───┘    │
               │       │       │        │
        PARTIAL_SHIP   │   SHIP│        │
               │       │       │        │
        ┌──────▼──┐    │ ┌─────▼──┐     │
        │partially│    │ │ shipped│     │
        │ shipped │────┘ └───┬────┘     │
        └─────────┘          │          │
                      DELIVER│     ┌────▼────┐
                      ┌──────▼──┐  │canceled │
                      │delivered│  └─────────┘
                      └───┬─────┘
                   COMPLETE│
                      ┌────▼────┐
                      │completed│
                      └─────────┘
```

### How Platforms Model Order States

| Platform | States | Approach |
|----------|--------|----------|
| **Shopify** | Financial status (authorized, paid, refunded) + Fulfillment status (unfulfilled, partial, fulfilled) | Two parallel status tracks |
| **Medusa** | Order status + Payment status + Fulfillment status | Three parallel tracks |
| **Commercetools** | Order state (Open, Confirmed, Complete, Cancelled) + Payment state + Shipment state | Separate state per concern |
| **Saleor** | Order status + Payment charge status + multiple fulfillments with own statuses | Composable states |

**Key insight**: Don't try to model everything in a single `status` field. Use separate status tracks for payment, fulfillment, and the overall order. They evolve independently.

---

## 2. Order Data Model

### Core Order Schema

```sql
CREATE TABLE orders (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number    VARCHAR(20) UNIQUE NOT NULL,  -- human-readable (#10001)
  
  -- References
  customer_id     BIGINT REFERENCES customers(id),
  checkout_id     UUID,                         -- reference to checkout that created this
  cart_id         UUID,                         -- reference to cart
  
  -- Status tracks
  status          VARCHAR(20) NOT NULL DEFAULT 'placed',
  payment_status  VARCHAR(20) NOT NULL DEFAULT 'pending',
  fulfillment_status VARCHAR(20) NOT NULL DEFAULT 'unfulfilled',
  
  -- Contact
  email           VARCHAR(255) NOT NULL,
  phone           VARCHAR(20),
  
  -- Addresses (snapshot at time of order — never changes even if customer updates address)
  shipping_address JSONB NOT NULL,
  billing_address  JSONB NOT NULL,
  
  -- Financial summary
  currency        CHAR(3) NOT NULL,
  subtotal        NUMERIC(12,2) NOT NULL,   -- sum of line item totals
  discount_total  NUMERIC(12,2) DEFAULT 0,
  shipping_total  NUMERIC(12,2) DEFAULT 0,
  tax_total       NUMERIC(12,2) DEFAULT 0,
  grand_total     NUMERIC(12,2) NOT NULL,   -- what the customer pays
  
  -- Tax details
  tax_breakdown   JSONB,  -- [{jurisdiction, rate, amount, taxable_amount}]
  tax_inclusive    BOOLEAN DEFAULT FALSE,
  
  -- Payment
  payment_method  VARCHAR(50),              -- 'card', 'apple_pay', 'klarna'
  payment_provider VARCHAR(30),             -- 'stripe', 'adyen'
  payment_intent_id VARCHAR(100),           -- PSP reference
  
  -- Promotions applied
  promotions      JSONB DEFAULT '[]',       -- [{code, type, value, discount_amount}]
  
  -- Metadata
  source          VARCHAR(30),              -- 'web', 'mobile_app', 'pos', 'api', 'marketplace'
  ip_address      INET,
  user_agent      TEXT,
  notes           TEXT,                     -- internal notes
  customer_notes  TEXT,                     -- customer's order notes
  metadata        JSONB DEFAULT '{}',
  
  -- Idempotency
  idempotency_key VARCHAR(100) UNIQUE,
  
  -- Timestamps
  placed_at       TIMESTAMPTZ DEFAULT NOW(),
  confirmed_at    TIMESTAMPTZ,
  shipped_at      TIMESTAMPTZ,
  delivered_at    TIMESTAMPTZ,
  completed_at    TIMESTAMPTZ,
  canceled_at     TIMESTAMPTZ,
  
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE order_items (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id        UUID REFERENCES orders(id),
  
  -- Product snapshot (immutable — captures state at time of order)
  variant_id      BIGINT,                   -- reference, but don't FK (product may be deleted)
  sku             VARCHAR(100) NOT NULL,
  product_name    VARCHAR(255) NOT NULL,
  variant_title   VARCHAR(255),             -- "Black / Size 10"
  product_image   VARCHAR(500),
  
  -- Pricing
  unit_price      NUMERIC(12,2) NOT NULL,
  quantity        INTEGER NOT NULL,
  total           NUMERIC(12,2) NOT NULL,   -- unit_price * quantity
  
  -- Adjustments
  discount_amount NUMERIC(12,2) DEFAULT 0,
  tax_amount      NUMERIC(12,2) DEFAULT 0,
  
  -- Fulfillment tracking per line item
  fulfilled_quantity INTEGER DEFAULT 0,
  returned_quantity  INTEGER DEFAULT 0,
  
  -- Metadata
  metadata        JSONB DEFAULT '{}',       -- custom options, personalization data
  
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_orders_customer ON orders(customer_id, placed_at DESC);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_placed ON orders(placed_at DESC);
CREATE INDEX idx_order_items_order ON order_items(order_id);
```

### Immutability Principle

**Critical**: Order records should be immutable snapshots. When the order is placed, capture:
- Product name, description, image (product may be renamed/deleted later)
- Price at time of purchase (price may change)
- Shipping/billing address (customer may update their address later)
- Tax rates (tax laws change)

Never join back to the products table to display order history — you'll show wrong data if products have changed. The order IS the record of what was purchased.

### Order Number Generation

Human-readable order numbers separate from UUIDs:

```sql
-- Sequence-based (simple, predictable)
CREATE SEQUENCE order_number_seq START 10001;
-- Usage: SELECT nextval('order_number_seq');  → 10001, 10002, ...

-- Format: #10001, #10002 (prefix is for display only)
```

Or use a more complex format: `ORD-2026-0001`, `US-10001`, `WEB-50001` (prefixed by year, region, or channel). Keep it short — customers will read this over the phone to support agents.

---

## 3. Order Orchestration

### The Saga Pattern for Order Processing

An order involves multiple services that must coordinate:

```
Order Placed
       │
       ├── 1. Reserve Inventory     → Success? Continue. Fail? Cancel order.
       │
       ├── 2. Authorize Payment     → Success? Continue. Fail? Release inventory.
       │
       ├── 3. Calculate Tax (final) → Success? Continue. Fail? Release inventory, void auth.
       │
       ├── 4. Confirm Order         → Create order record, send confirmation
       │
       ├── 5. Route Fulfillment     → Assign to warehouse, create shipment
       │
       └── 6. Notify Customer       → Confirmation email, SMS
```

Each step has a **compensation** (rollback) action:

| Step | Action | Compensation |
|------|--------|-------------|
| Reserve Inventory | `inventory.allocate(items)` | `inventory.release(items)` |
| Authorize Payment | `payment.authorize(amount)` | `payment.void(auth_id)` |
| Confirm Order | `order.create(data)` | `order.cancel(order_id)` |
| Route Fulfillment | `fulfillment.create(order)` | `fulfillment.cancel(fulfillment_id)` |

### Choreography vs Orchestration

**Choreography** (event-driven, decentralized):
```
Order Service → emits "order.placed"
  → Inventory Service listens → reserves stock → emits "inventory.reserved"
    → Payment Service listens → authorizes payment → emits "payment.authorized"
      → Fulfillment Service listens → creates shipment
```
- Pro: Loose coupling, no single point of failure
- Con: Hard to debug, distributed transaction visibility is poor, "event spaghetti"
- Best for: Simple flows with few steps

**Orchestration** (centralized coordinator):
```
Order Orchestrator:
  1. Call inventory.reserve()
  2. Call payment.authorize()
  3. Call order.confirm()
  4. Call fulfillment.route()
  5. Call notification.send()
  If any step fails: execute compensations in reverse order
```
- Pro: Clear flow, easy to debug, centralized error handling
- Con: Orchestrator is a single point of failure, tighter coupling
- Best for: Complex flows with many steps, when you need visibility

### Temporal / Cadence for Long-Running Workflows

For complex order workflows that span hours or days (backorders, pre-orders, approval workflows):

```typescript
// Temporal workflow for order processing
async function orderWorkflow(orderId: string): Promise<void> {
  // Step 1: Reserve inventory (retries automatically on failure)
  await activities.reserveInventory(orderId);
  
  // Step 2: Authorize payment
  const authResult = await activities.authorizePayment(orderId);
  if (!authResult.success) {
    // Compensation: release inventory
    await activities.releaseInventory(orderId);
    throw new Error('Payment authorization failed');
  }
  
  // Step 3: Confirm order
  await activities.confirmOrder(orderId);
  
  // Step 4: Wait for fulfillment (could take days)
  // Temporal handles the long wait — no cron jobs needed
  await activities.routeToFulfillment(orderId);
  
  // Step 5: Wait for shipment event
  const shipmentSignal = await workflow.condition(
    () => shipmentCreated,
    { timeout: '7 days' }
  );
  
  // Step 6: Capture payment when shipped
  await activities.capturePayment(orderId);
  
  // Step 7: Send shipping notification
  await activities.notifyShipped(orderId);
}
```

**When to use Temporal/Cadence**:
- Order workflows with human approval steps
- Pre-order campaigns (authorize now, capture weeks later)
- Multi-step fulfillment (manufacturing + assembly + shipping)
- Subscription renewal workflows
- Complex return/exchange workflows

For simple e-commerce (place order → ship → deliver), a state machine with event listeners is sufficient. Use Temporal when your workflow has long waits, complex branching, or needs durable execution guarantees.

---

## 4. Fulfillment Architecture

### Fulfillment Routing

When an order comes in, decide WHERE to fulfill from:

```
Order received (items: A, B, C)
       │
       ▼
Routing Engine
       │
       ├── Check inventory at each location
       │     Warehouse NYC:  A(50), B(0),  C(20)
       │     Warehouse LA:   A(30), B(25), C(15)
       │     Store Chicago:  A(5),  B(10), C(0)
       │
       ├── Find optimal fulfillment plan:
       │
       │   Option 1: Ship all from LA (all items available)
       │     Cost: $8.50 (distance to customer)
       │     Speed: 3-5 days
       │
       │   Option 2: Split — A,C from NYC + B from LA
       │     Cost: $6.20 + $4.80 = $11.00 (two shipments)
       │     Speed: 2-3 days (NYC closer to customer) + 3-5 days
       │
       │   Option 3: Split — A from NYC + B,C from LA
       │     Cost: $4.20 + $6.30 = $10.50
       │     Speed: 2-3 days + 3-5 days
       │
       └── Select based on strategy:
              - Cost-optimized: Option 1 (single shipment, lowest cost)
              - Speed-optimized: Option 2 (fastest for most items)
              - Balanced: Configurable per business rules
```

### Routing Decision Factors

| Factor | Weight | How to Evaluate |
|--------|--------|----------------|
| **Inventory availability** | Highest | Does the location have ALL items? Avoid splits if possible. |
| **Proximity to customer** | High | Use lat/lng distance calculation. Closer = faster + cheaper. |
| **Shipping cost** | High | Real-time carrier rate quotes per origin-destination pair. |
| **Number of shipments** | Medium | Fewer shipments = lower total cost, better customer experience. |
| **Location capacity** | Medium | Is the warehouse overloaded? Spread load across locations. |
| **SLA/Speed requirement** | Varies | Express orders → ship from nearest location regardless of cost. |

### Split Fulfillment Data Model

```sql
CREATE TABLE fulfillments (
  id              UUID PRIMARY KEY,
  order_id        UUID REFERENCES orders(id),
  location_id     BIGINT REFERENCES locations(id),
  status          VARCHAR(20) DEFAULT 'pending',
  -- 'pending', 'picking', 'packed', 'shipped', 'delivered', 'canceled'
  
  -- Shipping
  carrier         VARCHAR(50),             -- 'usps', 'ups', 'fedex', 'dhl'
  service         VARCHAR(50),             -- 'ground', 'express', '2day'
  tracking_number VARCHAR(100),
  tracking_url    VARCHAR(500),
  shipping_label_url VARCHAR(500),
  
  -- Costs
  shipping_cost   NUMERIC(12,2),
  
  -- Dates
  estimated_delivery DATE,
  shipped_at      TIMESTAMPTZ,
  delivered_at    TIMESTAMPTZ,
  
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE fulfillment_items (
  fulfillment_id  UUID REFERENCES fulfillments(id),
  order_item_id   UUID REFERENCES order_items(id),
  quantity        INTEGER NOT NULL,
  PRIMARY KEY (fulfillment_id, order_item_id)
);
```

### Drop-Shipping Integration

When you don't hold inventory — the supplier ships directly to the customer:

```
Order placed on your store
       │
       ▼
Create purchase order to supplier
  - via API (modern suppliers)
  - via EDI (traditional suppliers)
  - via email (small suppliers — automate with templates)
       │
       ▼
Supplier ships to customer
  - Provides tracking number
  - Your store sends tracking to customer (branded as your store)
       │
       ▼
Settlement
  - You pay supplier (wholesale price)
  - You keep the margin (retail - wholesale - shipping)
```

### 3PL (Third-Party Logistics) Integration

| 3PL | Specialization | Integration | Best For |
|-----|---------------|-------------|---------|
| **ShipBob** | DTC fulfillment, US + international | REST API, Shopify/BigCommerce plugins | Growing DTC brands |
| **Deliverr (Shopify Fulfillment)** | Fast shipping, marketplace fulfillment | API, Shopify integration | Shopify merchants |
| **Red Stag** | Heavy/oversized items | API, EDI | Furniture, equipment |
| **ShipMonk** | Subscription boxes, DTC | API | Subscription businesses |
| **Amazon MCF** | Multi-channel fulfillment using FBA inventory | API | Sellers already using FBA |

---

## 5. Post-Order Modifications

### Modification Windows

| Modification | Window | Complexity |
|-------------|--------|-----------|
| **Cancel order** | Before shipping | Low — release inventory, void/refund payment |
| **Change quantity** | Before shipping | Medium — adjust inventory, partial refund/charge |
| **Remove item** | Before shipping | Medium — release item inventory, partial refund |
| **Add item** | Before shipping | High — check stock, additional charge, modify fulfillment |
| **Change shipping address** | Before shipping | Medium — recalculate shipping/tax, update fulfillment |
| **Change shipping method** | Before shipping | Low — adjust shipping charge |

### Modification Data Model

```sql
CREATE TABLE order_edits (
  id              UUID PRIMARY KEY,
  order_id        UUID REFERENCES orders(id),
  status          VARCHAR(20) DEFAULT 'pending',
  -- 'pending', 'confirmed', 'declined'
  
  requested_by    VARCHAR(20),   -- 'customer', 'admin', 'system'
  reason          TEXT,
  
  -- Financial impact
  subtotal_diff   NUMERIC(12,2),  -- positive = increase, negative = decrease
  tax_diff        NUMERIC(12,2),
  shipping_diff   NUMERIC(12,2),
  total_diff      NUMERIC(12,2),  -- net change to grand_total
  
  -- Resolution
  refund_amount   NUMERIC(12,2),  -- if total decreased
  charge_amount   NUMERIC(12,2),  -- if total increased
  
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  confirmed_at    TIMESTAMPTZ
);

CREATE TABLE order_edit_items (
  id              UUID PRIMARY KEY,
  order_edit_id   UUID REFERENCES order_edits(id),
  action          VARCHAR(10),   -- 'add', 'remove', 'update'
  
  order_item_id   UUID,          -- existing item (for remove/update)
  variant_id      BIGINT,        -- for add
  
  old_quantity    INTEGER,
  new_quantity    INTEGER,
  
  unit_price      NUMERIC(12,2)
);
```

### Cancellation Flow

```
Customer requests cancellation
       │
       ├── Order not yet shipped?
       │     │
       │     ├── YES:
       │     │     1. Cancel fulfillment (if created)
       │     │     2. Release inventory allocation
       │     │     3. Void payment authorization (if not captured)
       │     │        OR refund (if captured)
       │     │     4. Update order status → canceled
       │     │     5. Send cancellation confirmation email
       │     │
       │     └── NO (already shipped):
       │           1. Inform customer: "Order already shipped, please return"
       │           2. Offer to initiate return when delivered
       │           3. OR intercept with carrier (UPS/FedEx intercept API)
       │              — costs $15-30, not always successful
```

---

## 6. Returns & Exchanges

### Return Workflow

```
Customer initiates return (self-service portal)
       │
       ├── Select items to return
       ├── Select reason per item
       ├── Choose: refund, exchange, or store credit
       │
       ▼
Return approved (auto or manual review)
       │
       ├── Generate return shipping label
       │     - Prepaid (merchant pays): better CX, builds trust
       │     - Customer pays: lower cost, deduct from refund
       │
       ├── Send label + instructions to customer
       │
       ▼
Customer ships items back
       │
       ▼
Warehouse receives return
       │
       ├── Inspect items
       │     ├── Pass inspection → process refund/exchange
       │     └── Fail inspection → notify customer, partial refund or reject
       │
       ├── Update inventory (restock or dispose)
       │
       └── Process refund
              ├── Original payment method (Stripe refund)
              ├── Store credit (gift card)
              └── Exchange (create new order)
```

### Exchange Architecture

Exchanges are more complex than refunds — they're effectively a return + a new order:

```
Return of Item A (Red, Size M)
       │
       ├── 1. Check stock of exchange item B (Blue, Size L)
       │
       ├── 2. Financial calculation:
       │     Original item: $50
       │     Exchange item: $60
       │     Difference: Customer owes $10
       │     (or: Original $50, Exchange $40 → Refund $10)
       │
       ├── 3. If customer owes: charge difference
       │     If merchant owes: refund difference
       │     If same price: no financial transaction
       │
       ├── 4. Create new fulfillment for exchange item
       │     Ship immediately (don't wait for return receipt)
       │
       └── 5. When original item received: inspect + restock/dispose
```

### Return Policy Configuration

```sql
CREATE TABLE return_policies (
  id              BIGINT PRIMARY KEY,
  name            VARCHAR(100),
  
  -- Window
  return_window_days INTEGER NOT NULL,  -- 30, 60, 90 days from delivery
  
  -- Conditions
  requires_receipt    BOOLEAN DEFAULT FALSE,
  requires_tags       BOOLEAN DEFAULT FALSE,  -- item must have tags attached
  requires_original_packaging BOOLEAN DEFAULT FALSE,
  
  -- Financial
  restocking_fee_pct  NUMERIC(5,2) DEFAULT 0,  -- e.g., 15%
  free_return_shipping BOOLEAN DEFAULT TRUE,
  
  -- Exclusions
  final_sale_skus     TEXT[],           -- SKUs that cannot be returned
  excluded_categories BIGINT[],        -- category IDs excluded from returns
  
  is_default          BOOLEAN DEFAULT FALSE,
  
  created_at          TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 7. Notifications & Communication

### Order Notification Timeline

| Event | Channel | Timing | Content |
|-------|---------|--------|---------|
| Order placed | Email + SMS | Immediate | Order number, items, total, estimated delivery |
| Payment confirmed | Email | Immediate | Receipt, payment method used |
| Order shipped | Email + SMS + Push | When carrier scans | Tracking number, carrier, ETA |
| Out for delivery | Push + SMS | Day of delivery | "Your order arrives today" |
| Delivered | Email + Push | Delivery scan | "Your order has been delivered" + photo (if available) |
| Return approved | Email | When processed | Return label, instructions |
| Refund processed | Email | When refund initiated | Refund amount, expected timeline |

### Tracking Integration

| Service | Carriers | Features | Pricing |
|---------|---------|----------|---------|
| **AfterShip** | 1,100+ carriers | Tracking page, notifications, analytics | Free tier + paid plans |
| **Shippo** | Major carriers | Tracking API, labels | Included with label purchases |
| **Route** | Major carriers | Tracking + shipping protection | Revenue share |
| **Narvar** | Major carriers | Branded tracking page, returns, delivery estimates | Enterprise pricing |

### Branded Tracking Page

Instead of sending customers to UPS.com, create a branded tracking page on your domain:

```
https://yourstore.com/orders/track/ORD-10001

┌─────────────────────────────────────────┐
│  [Your Logo]                             │
│                                          │
│  Order #10001                            │
│  ────────────────────────────────       │
│                                          │
│  ● Ordered — March 5                     │
│  ● Shipped — March 6                     │
│  ● In Transit — March 7                  │
│  ○ Out for Delivery                      │
│  ○ Delivered                             │
│                                          │
│  Carrier: UPS                            │
│  Tracking: 1Z999AA10123456784            │
│  Estimated Delivery: March 8-10          │
│                                          │
│  [View Order Details]  [Need Help?]      │
│                                          │
│  ────────────────────────────────       │
│  You might also like:                    │
│  [Product 1] [Product 2] [Product 3]     │
│                                          │
└─────────────────────────────────────────┘
```

Benefits: Keeps customers on your site, reduces "where's my order" support tickets, opportunity for upsell/cross-sell.

---

## 8. Order Analytics & Reporting

### Key E-Commerce Metrics

| Metric | Formula | Benchmark |
|--------|---------|-----------|
| **Conversion Rate** | Orders / Sessions | 1-3% (varies by industry) |
| **Average Order Value (AOV)** | Revenue / Orders | Industry-dependent |
| **Customer Lifetime Value (CLV)** | AOV × Purchase Frequency × Customer Lifespan | Higher = healthier |
| **Cart Abandonment Rate** | Carts Created without Order / Carts Created | ~70% average |
| **Return Rate** | Returns / Orders | 5-15% (apparel: 20-30%) |
| **Order Fulfillment Time** | Ship Date - Order Date | <2 days (target) |
| **First-Contact Resolution** | Support tickets resolved in first contact | >70% |
| **Revenue per Visitor** | Revenue / Unique Visitors | Better than conversion rate alone |

### Order Funnel Analysis

```sql
-- Daily order funnel
SELECT
  date_trunc('day', created_at) AS day,
  COUNT(*) FILTER (WHERE step >= 'cart')     AS carts_created,
  COUNT(*) FILTER (WHERE step >= 'checkout') AS checkouts_started,
  COUNT(*) FILTER (WHERE step >= 'shipping') AS shipping_entered,
  COUNT(*) FILTER (WHERE step >= 'payment')  AS payment_entered,
  COUNT(*) FILTER (WHERE step = 'completed') AS orders_completed,
  
  -- Conversion rates
  ROUND(
    COUNT(*) FILTER (WHERE step = 'completed')::NUMERIC /
    NULLIF(COUNT(*) FILTER (WHERE step >= 'cart'), 0) * 100, 2
  ) AS cart_to_order_pct
FROM checkout_sessions
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY 1
ORDER BY 1;
```

### Cohort Analysis

Track customer retention by first-purchase cohort:

```sql
WITH customer_cohorts AS (
  SELECT
    customer_id,
    date_trunc('month', MIN(placed_at)) AS cohort_month,
    date_trunc('month', placed_at) AS order_month
  FROM orders
  WHERE status != 'canceled'
  GROUP BY customer_id, date_trunc('month', placed_at)
)
SELECT
  cohort_month,
  order_month,
  (EXTRACT(YEAR FROM order_month) - EXTRACT(YEAR FROM cohort_month)) * 12 +
    (EXTRACT(MONTH FROM order_month) - EXTRACT(MONTH FROM cohort_month)) AS months_since_first,
  COUNT(DISTINCT customer_id) AS customers
FROM customer_cohorts
GROUP BY 1, 2
ORDER BY 1, 2;
```

### Revenue Recognition (ASC 606)

For subscription or multi-deliverable orders, revenue must be recognized when the performance obligation is satisfied (not when payment is received):

| Order Type | When Revenue is Recognized |
|-----------|--------------------------|
| Physical goods | When product is delivered (or shipped, depending on terms) |
| Digital goods | When access is granted |
| Subscriptions | Ratably over the subscription period |
| Gift cards | When gift card is redeemed (not when purchased) |
| Pre-orders | When product is delivered |

Stripe Revenue Recognition automates this for Stripe payments. Otherwise, integrate with your accounting system.

---

## 9. B2B Order Management

### B2B-Specific Requirements

| Feature | B2C | B2B |
|---------|-----|-----|
| Payment terms | Pay now | Net 30/60/90 |
| Pricing | Public, uniform | Customer-specific, contracted |
| Order approval | None | Manager approval workflows |
| Minimum order | None | Minimum order quantity/value |
| Ordering method | Web checkout | Web + PO + phone + EDI |
| Invoicing | Receipt at checkout | Invoice sent post-order |
| Reordering | Add to cart again | Quick reorder from history |

### Purchase Order (PO) Flow

```
Buyer sends PO (via portal, email, EDI, or fax)
       │
       ▼
PO received → auto-parse or manual entry
       │
       ├── Validate against contract:
       │     - Customer has approved pricing?
       │     - Within credit limit?
       │     - Items match contracted catalog?
       │
       ├── Check stock availability
       │
       ├── Auto-approve (if within rules) or queue for sales review
       │
       ▼
Order confirmed → Invoice generated (Net 30)
       │
       ▼
Fulfill and ship
       │
       ▼
Payment due in 30 days
       │
       ├── Payment received → close invoice
       └── Overdue → dunning emails → collections
```

### B2B Order Data Model Extensions

```sql
-- B2B-specific order fields
ALTER TABLE orders ADD COLUMN po_number VARCHAR(50);           -- customer's PO reference
ALTER TABLE orders ADD COLUMN payment_terms VARCHAR(20);       -- 'net_30', 'net_60', 'due_on_receipt'
ALTER TABLE orders ADD COLUMN approval_status VARCHAR(20);     -- 'pending', 'approved', 'rejected'
ALTER TABLE orders ADD COLUMN approved_by BIGINT;
ALTER TABLE orders ADD COLUMN approved_at TIMESTAMPTZ;
ALTER TABLE orders ADD COLUMN invoice_number VARCHAR(50);
ALTER TABLE orders ADD COLUMN invoice_due_date DATE;

-- Credit management
CREATE TABLE customer_credit (
  customer_id     BIGINT PRIMARY KEY REFERENCES customers(id),
  credit_limit    NUMERIC(12,2) NOT NULL,
  credit_used     NUMERIC(12,2) DEFAULT 0,
  credit_available NUMERIC(12,2) GENERATED ALWAYS AS (credit_limit - credit_used) STORED,
  payment_terms   VARCHAR(20) DEFAULT 'net_30',
  currency        CHAR(3) DEFAULT 'USD'
);
```

### EDI Integration

EDI (Electronic Data Interchange) is still the standard for large B2B:

| EDI Document | Purpose | Modern Alternative |
|-------------|---------|-------------------|
| EDI 850 | Purchase Order | API order creation |
| EDI 855 | PO Acknowledgment | API order confirmation |
| EDI 856 | Advance Ship Notice | API shipment notification |
| EDI 810 | Invoice | API/email invoice |

Modern approach: Use an EDI gateway (SPS Commerce, TrueCommerce, Orderful) that translates EDI to/from your API. Don't build EDI parsing yourself unless you have a very good reason.

---

## 10. Distributed Order Management (DOM)

### What is DOM?

DOM is the intelligence layer that decides the optimal way to fulfill every order across multiple locations, channels, and fulfillment methods.

### DOM Routing Rules

```
Order Received
       │
       ▼
Rule 1: Can we fulfill entirely from one location?
  YES → Select cheapest/fastest single location → done
  NO  → Continue to Rule 2
       │
       ▼
Rule 2: Find the split with minimum shipments
  - Try all 2-location splits
  - Rank by: total shipping cost, delivery speed, number of packages
       │
       ▼
Rule 3: Priority overrides
  - Express orders → ship from nearest location regardless of cost
  - Hazmat items → only ship from hazmat-certified locations
  - Oversized items → only from locations with freight capability
  - International orders → only from export-licensed locations
       │
       ▼
Rule 4: Load balancing
  - If two locations are equal candidates, prefer the one with lower current fulfillment load
  - Spread orders to prevent single-point bottlenecks
       │
       ▼
Rule 5: Store fulfillment (ship-from-store)
  - If customer is near a store with stock, offer store pickup or ship-from-store
  - Ship-from-store is often cheaper than warehouse shipping for nearby customers
```

### DOM Platforms

| Platform | Focus | Best For |
|----------|-------|---------|
| **Fluent Commerce** | Cloud-native DOM | Mid-to-large omnichannel retailers |
| **Manhattan Active Omni** | Enterprise DOM + WMS | Large enterprise, complex fulfillment |
| **IBM Sterling** | Enterprise OMS/DOM | Legacy enterprise, highly configurable |
| **Fabric OMS** | Modern API-first OMS | Growing merchants, headless commerce |
| **Custom-built** | Tailored routing | When specific routing logic is unique to your business |

### When You Need DOM

You need a DOM solution when:
- You fulfill from 3+ locations
- You do ship-from-store
- You have complex routing rules (hazmat, oversized, regional restrictions)
- You're losing money on shipping due to suboptimal routing
- Customer delivery times are inconsistent

You do NOT need DOM when:
- Single warehouse
- Two warehouses with simple geographic split (East/West)
- Low order volume (<500/day)
