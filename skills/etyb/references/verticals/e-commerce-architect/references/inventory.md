# Inventory Management Architecture — Deep Reference

**Always use `WebSearch` to verify WMS features, fulfillment provider APIs, and inventory management tools before giving advice. This reference provides architectural context; the ecosystem evolves rapidly.**

## Table of Contents
1. [Inventory Data Model](#1-inventory-data-model)
2. [Stock Reservation Patterns](#2-stock-reservation-patterns)
3. [Real-Time Inventory Tracking](#3-real-time-inventory-tracking)
4. [Multi-Channel Inventory](#4-multi-channel-inventory)
5. [Warehouse Management Integration](#5-warehouse-management-integration)
6. [Demand Forecasting](#6-demand-forecasting)
7. [Backorder & Pre-Order Management](#7-backorder--pre-order-management)
8. [Returns & Reverse Logistics](#8-returns--reverse-logistics)
9. [Concurrency & Race Conditions](#9-concurrency--race-conditions)
10. [Inventory Architecture by Scale](#10-inventory-architecture-by-scale)

---

## 1. Inventory Data Model

### Core Inventory Schema

```sql
-- Locations where inventory is stored
CREATE TABLE locations (
  id              BIGINT PRIMARY KEY,
  name            VARCHAR(100) NOT NULL,     -- "Main Warehouse", "NYC Store"
  type            VARCHAR(20) NOT NULL,      -- 'warehouse', 'store', 'dropship', '3pl'
  address_line1   VARCHAR(255),
  city            VARCHAR(100),
  state           VARCHAR(50),
  postal_code     VARCHAR(20),
  country         CHAR(2),
  latitude        NUMERIC(10,7),             -- for proximity-based routing
  longitude       NUMERIC(10,7),
  is_active       BOOLEAN DEFAULT TRUE,
  priority        INTEGER DEFAULT 0,         -- routing priority
  fulfillment_enabled BOOLEAN DEFAULT TRUE   -- can fulfill online orders?
);

-- Inventory levels per variant per location
CREATE TABLE inventory_items (
  id              BIGINT PRIMARY KEY,
  variant_id      BIGINT REFERENCES product_variants(id),
  location_id     BIGINT REFERENCES locations(id),
  sku             VARCHAR(100) NOT NULL,
  
  -- Quantity breakdown
  on_hand         INTEGER NOT NULL DEFAULT 0,   -- physically in the location
  allocated       INTEGER NOT NULL DEFAULT 0,   -- reserved for confirmed orders
  available       INTEGER GENERATED ALWAYS AS (on_hand - allocated) STORED,
  
  -- Tracking
  incoming        INTEGER NOT NULL DEFAULT 0,   -- purchase orders in transit
  
  -- Thresholds
  low_stock_threshold  INTEGER DEFAULT 10,
  reorder_point        INTEGER DEFAULT 20,
  reorder_quantity     INTEGER DEFAULT 100,
  
  -- Constraints
  UNIQUE (variant_id, location_id),
  CHECK (on_hand >= 0),
  CHECK (allocated >= 0),
  CHECK (allocated <= on_hand)
);

CREATE INDEX idx_inventory_variant ON inventory_items(variant_id);
CREATE INDEX idx_inventory_location ON inventory_items(location_id);
CREATE INDEX idx_inventory_low_stock ON inventory_items(available)
  WHERE available <= low_stock_threshold;
```

### Quantity Types Explained

```
on_hand = 100      (physically present)
allocated = 15     (reserved for orders not yet shipped)
available = 85     (on_hand - allocated = sellable quantity)
incoming = 50      (purchase orders in transit, not yet received)

Available to Promise (ATP) = available + incoming = 135
  → This is what you can sell if you allow backorder-like behavior

Available to Sell (ATS) = available = 85
  → This is what you should show on the storefront
```

### Extended Tracking (Lot, Serial, Expiry)

For regulated industries (food, pharma, electronics):

```sql
CREATE TABLE inventory_lots (
  id              BIGINT PRIMARY KEY,
  inventory_item_id BIGINT REFERENCES inventory_items(id),
  lot_number      VARCHAR(100) NOT NULL,
  serial_number   VARCHAR(100),          -- for serialized inventory
  quantity        INTEGER NOT NULL,
  cost_per_unit   NUMERIC(12,2),         -- for FIFO/LIFO costing
  received_at     DATE NOT NULL,
  expires_at      DATE,                  -- for perishable goods
  
  UNIQUE (inventory_item_id, lot_number, serial_number)
);

-- FEFO (First Expired, First Out) picking query
SELECT * FROM inventory_lots
WHERE inventory_item_id = :item_id
  AND quantity > 0
  AND (expires_at IS NULL OR expires_at > CURRENT_DATE)
ORDER BY expires_at ASC NULLS LAST, received_at ASC;
```

### Inventory Events (Audit Trail)

Every inventory change should be recorded as an event:

```sql
CREATE TABLE inventory_events (
  id              BIGINT PRIMARY KEY,
  inventory_item_id BIGINT REFERENCES inventory_items(id),
  event_type      VARCHAR(30) NOT NULL,
  -- 'received', 'allocated', 'deallocated', 'shipped', 'returned',
  -- 'adjusted', 'transferred', 'damaged', 'counted'
  
  quantity_change  INTEGER NOT NULL,      -- positive or negative
  quantity_after   INTEGER NOT NULL,       -- snapshot of on_hand after change
  
  reference_type   VARCHAR(30),           -- 'order', 'purchase_order', 'transfer', 'adjustment'
  reference_id     VARCHAR(100),          -- order ID, PO number, etc.
  
  reason          VARCHAR(255),
  performed_by    BIGINT,                 -- user who triggered the change
  
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_inv_events_item ON inventory_events(inventory_item_id, created_at DESC);
CREATE INDEX idx_inv_events_ref ON inventory_events(reference_type, reference_id);
```

---

## 2. Stock Reservation Patterns

### Soft vs Hard Reservation

| Pattern | When Reserved | When Released | Use Case |
|---------|--------------|--------------|----------|
| **No reservation** | Never | N/A | Simple stores, risk of overselling acceptable |
| **Soft reservation** | When added to cart | Cart expiry (30 min - 24 hr) | Prevent showing items as available when in someone's cart |
| **Hard reservation** | At checkout / payment authorization | Order cancellation or refund | Standard e-commerce, prevents overselling |
| **Two-phase reservation** | Soft at cart, hard at checkout | Soft→hard at checkout, hard→shipped at fulfillment | Best of both worlds, most complex |

### Hard Reservation (Standard Pattern)

```sql
-- When an order is placed (payment authorized):
BEGIN;

-- Lock the inventory row and check availability
SELECT on_hand, allocated
FROM inventory_items
WHERE variant_id = :variant_id AND location_id = :location_id
FOR UPDATE;

-- If available >= requested quantity:
UPDATE inventory_items
SET allocated = allocated + :quantity
WHERE variant_id = :variant_id
  AND location_id = :location_id
  AND (on_hand - allocated) >= :quantity;

-- Check affected rows: if 0, insufficient stock → abort
-- If 1, reservation succeeded

INSERT INTO inventory_events (inventory_item_id, event_type, quantity_change, ...)
VALUES (:item_id, 'allocated', :quantity, ...);

COMMIT;
```

### Soft Reservation (Cart-Level)

```sql
CREATE TABLE cart_reservations (
  id              UUID PRIMARY KEY,
  cart_id         UUID REFERENCES carts(id) ON DELETE CASCADE,
  variant_id      BIGINT REFERENCES product_variants(id),
  location_id     BIGINT REFERENCES locations(id),
  quantity        INTEGER NOT NULL,
  expires_at      TIMESTAMPTZ NOT NULL,     -- typically 15-30 minutes
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Available quantity = on_hand - allocated - active_soft_reservations
-- (soft reservations from other carts reduce displayed availability)
```

**Tradeoffs of soft reservation:**
- Pro: Prevents customers from seeing "in stock" and getting a "sold out" error at checkout
- Con: Holding stock in carts reduces apparent availability for other customers
- Con: Cart abandonment means stock is "locked" until reservation expires
- Recommendation: Use soft reservation only for limited inventory items (flash sales, limited editions). For general catalog, rely on hard reservation at checkout.

### Two-Phase Reservation for Flash Sales

For high-demand limited drops:

```
Phase 1: Soft Reserve (cart add)
  - Decrement "available for cart" counter (Redis)
  - Set 10-minute expiration
  - Show countdown timer to customer: "Item held for 9:47"
  
Phase 2: Hard Reserve (checkout completion)
  - Convert soft reservation to hard allocation (database)
  - Remove from Redis counter
  - If checkout timer expires: release soft reservation
  
Phase 3: Fulfill (order ships)
  - Decrement on_hand, decrement allocated
  - Inventory physically leaves the building
```

---

## 3. Real-Time Inventory Tracking

### Event Sourcing for Inventory

Instead of storing only current state, store every inventory change as an immutable event. Current state is derived by replaying events.

```
Event Log:
  1. received(+100)       → on_hand: 100
  2. allocated(+5)        → on_hand: 100, allocated: 5
  3. shipped(-5)          → on_hand: 95,  allocated: 0
  4. received(+50)        → on_hand: 145, allocated: 0
  5. allocated(+10)       → on_hand: 145, allocated: 10
  6. returned(+2)         → on_hand: 147, allocated: 10
  7. damaged(-3)          → on_hand: 144, allocated: 10
  
Current state: on_hand=144, allocated=10, available=134
```

**Benefits of event sourcing:**
- Full audit trail — know exactly how inventory reached current state
- Time travel — reconstruct inventory at any point in the past
- Debugging — understand why a discrepancy occurred
- Analytics — inventory velocity, shrinkage patterns

**Drawbacks:**
- More complex to implement
- Need snapshots for performance (don't replay from the beginning every time)
- Eventual consistency if using async event processing

**When to use event sourcing**: When inventory accuracy is critical (regulated goods, high-value items), when you need an audit trail, or when you have multi-channel inventory that's hard to reconcile.

### CQRS for Inventory

Separate the write model (allocation, adjustment, receiving) from the read model (available quantity for storefront display):

```
Write Side (Command)                Read Side (Query)
  ┌──────────────┐                   ┌──────────────────┐
  │  Inventory   │                   │ Inventory Read   │
  │  Commands    │                   │ Model (Redis)    │
  │              │                   │                  │
  │ - Allocate   │──── Events ──────▶│ variant:123:     │
  │ - Receive    │    (Kafka/NATS)   │   available: 85  │
  │ - Adjust     │                   │   low_stock: no  │
  │ - Ship       │                   │                  │
  └──────────────┘                   └──────────────────┘
       │                                     │
       ▼                                     ▼
  PostgreSQL                          Storefront queries
  (source of truth)                   (sub-ms reads)
```

**Eventual consistency tradeoff**: The read model may be a few seconds behind the write model. This means a customer might see "in stock" and get a "sold out" error at checkout. Acceptable tradeoff for most stores. For flash sales, use synchronous reservation instead.

---

## 4. Multi-Channel Inventory

### The Multi-Channel Problem

Inventory must be synchronized across:
- Online store (your website)
- Marketplaces (Amazon, eBay, Etsy, Walmart Marketplace)
- Point of sale (physical stores)
- Wholesale/B2B orders
- Social commerce (Instagram Shop, TikTok Shop)

### Inventory Allocation Strategies

#### Shared Pool (Simplest)

All channels sell from the same pool. Total available = total on_hand - total allocated.
- Pro: Maximum availability, no channel-locked stock
- Con: Risk of overselling if sync is slow between channels

#### Channel-Specific Buffers

Allocate a portion of inventory to each channel:

```sql
CREATE TABLE channel_allocations (
  id              BIGINT PRIMARY KEY,
  variant_id      BIGINT REFERENCES product_variants(id),
  channel         VARCHAR(30),     -- 'website', 'amazon', 'ebay', 'wholesale', 'pos'
  allocated_qty   INTEGER NOT NULL,  -- max available for this channel
  buffer_qty      INTEGER DEFAULT 0  -- safety buffer (held back from channel)
);

-- Channel available = MIN(channel.allocated_qty - channel.buffer_qty, total_available)
```

- Pro: Prevents one channel from selling out inventory needed by another
- Con: Stock sitting in one channel while another is sold out (missed sales)

#### Dynamic Channel Allocation

Adjust channel allocation based on demand signals:
- High velocity on Amazon → increase Amazon allocation
- Low velocity on eBay → reduce eBay allocation, redistribute
- Black Friday → allocate more to website, reduce wholesale

### Marketplace Sync Architecture

```
Inventory Service (source of truth)
       │
       ├── Event: inventory.updated(variant_id, available_qty)
       │
       ├──▶ Website: Update product availability (real-time, <1s)
       │
       ├──▶ Amazon: Update via SP-API (batch, 15-min delay)
       │     └── amazon.updateInventory({sku, quantity})
       │
       ├──▶ eBay: Update via Trading API (near real-time)
       │     └── ebay.reviseInventoryStatus({sku, quantity})
       │
       └──▶ Shopify POS: Update via Admin API (near real-time)
             └── shopify.inventoryLevel.set({location, quantity})
```

**Sync tools**: ChannelAdvisor, Linnworks, Sellbrite, Zentail, or build custom with marketplace APIs.

**Critical**: Always sync available quantity, not on_hand. Don't expose your full physical inventory to marketplaces.

---

## 5. Warehouse Management Integration

### WMS Integration Patterns

| WMS | Type | Best For | Integration |
|-----|------|---------|-------------|
| **ShipBob** | 3PL with WMS | DTC brands, US fulfillment | REST API, Shopify/BigCommerce plugins |
| **ShipHero** | Cloud WMS | Growing DTC, multi-warehouse | REST API, webhooks |
| **Fulfil.io** | ERP + WMS | Custom workflows, manufacturing | REST API |
| **Deposco** | Enterprise WMS | Large operations, multi-channel | REST API, EDI |
| **Manhattan Associates** | Enterprise WMS/OMS | Enterprise, complex fulfillment | EDI, APIs |
| **NetSuite WMS** | ERP-integrated WMS | NetSuite users | Built-in |

### Pick/Pack/Ship Workflow

```
Order Received
       │
       ▼
1. PICK — Retrieve items from warehouse locations
   ├── Single order pick: One picker, one order (low volume)
   ├── Batch pick: One picker, multiple orders (10-50 orders at a time)
   ├── Wave pick: Timed batches, optimized routes (high volume)
   └── Zone pick: Each picker handles one zone, orders move between zones
       │
       ▼
2. PACK — Package items for shipping
   ├── Select box size (or auto-suggest based on item dimensions)
   ├── Add packing slip, marketing inserts
   ├── Weight verification (catch pick errors)
   └── Generate shipping label
       │
       ▼
3. SHIP — Hand off to carrier
   ├── Carrier pickup or drop-off
   ├── Tracking number generated
   ├── Customer notification sent
   └── Inventory decremented (on_hand reduced, allocated reduced)
```

### Warehouse Bin/Location Management

```sql
CREATE TABLE warehouse_bins (
  id              BIGINT PRIMARY KEY,
  location_id     BIGINT REFERENCES locations(id),
  zone            VARCHAR(20),    -- 'A', 'B', 'C' (pick zones)
  aisle           VARCHAR(10),
  rack            VARCHAR(10),
  shelf           VARCHAR(10),
  bin             VARCHAR(10),
  bin_code        VARCHAR(50) UNIQUE,  -- "A-01-03-02" (zone-aisle-rack-shelf)
  bin_type        VARCHAR(20),         -- 'pick', 'bulk', 'overstock', 'staging'
  max_capacity    INTEGER              -- max units
);

CREATE TABLE bin_inventory (
  bin_id          BIGINT REFERENCES warehouse_bins(id),
  variant_id      BIGINT REFERENCES product_variants(id),
  quantity        INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (bin_id, variant_id)
);
```

---

## 6. Demand Forecasting

### Basic Inventory Metrics

| Metric | Formula | Benchmark |
|--------|---------|-----------|
| **Inventory Turnover** | COGS / Average Inventory | 4-12x/year (varies by industry) |
| **Days of Supply** | Average Inventory / (COGS / 365) | 30-90 days |
| **Sell-Through Rate** | Units Sold / Units Received | >70% is healthy |
| **Stockout Rate** | SKUs out of stock / Total SKUs | <2% target |
| **Dead Stock %** | No sales in 90+ days / Total SKUs | <5% target |

### Safety Stock Calculation

```
Safety Stock = Z × σ × √LT

Where:
  Z  = service level factor (1.65 for 95%, 2.33 for 99%)
  σ  = standard deviation of daily demand
  LT = lead time in days (order to delivery)
```

Example: If daily demand averages 10 units with σ = 3, and lead time is 14 days:
- 95% service level: 1.65 × 3 × √14 = 18.5 ≈ 19 units safety stock
- 99% service level: 2.33 × 3 × √14 = 26.2 ≈ 27 units safety stock

### Reorder Point

```
Reorder Point = (Average Daily Demand × Lead Time) + Safety Stock
             = (10 × 14) + 19
             = 159 units

→ When available quantity drops to 159, trigger a purchase order.
```

### ABC Analysis

Classify SKUs by revenue contribution:

| Class | % of SKUs | % of Revenue | Strategy |
|-------|----------|-------------|----------|
| **A** | ~20% | ~80% | High safety stock, tight monitoring, frequent reorder |
| **B** | ~30% | ~15% | Moderate safety stock, standard monitoring |
| **C** | ~50% | ~5% | Low safety stock, order less frequently, consider dropship |

```sql
-- ABC classification query
WITH sku_revenue AS (
  SELECT variant_id, SUM(quantity * unit_price) AS revenue
  FROM order_items
  WHERE created_at > NOW() - INTERVAL '90 days'
  GROUP BY variant_id
),
ranked AS (
  SELECT variant_id, revenue,
         SUM(revenue) OVER (ORDER BY revenue DESC) AS cumulative,
         SUM(revenue) OVER () AS total
  FROM sku_revenue
)
SELECT variant_id, revenue,
  CASE
    WHEN cumulative / total <= 0.80 THEN 'A'
    WHEN cumulative / total <= 0.95 THEN 'B'
    ELSE 'C'
  END AS abc_class
FROM ranked;
```

### ML-Based Demand Prediction

For stores with sufficient historical data (>12 months, >100 orders/day):

| Approach | Complexity | Data Needed | Accuracy |
|----------|-----------|------------|----------|
| **Moving average** | Low | 30+ days of history | Fair |
| **Exponential smoothing** | Low | 90+ days | Good |
| **ARIMA/SARIMA** | Medium | 1+ years (seasonal) | Good for stable patterns |
| **Prophet (Meta)** | Medium | 1+ years | Good, handles holidays/seasonality well |
| **Gradient boosting (XGBoost/LightGBM)** | High | 2+ years + features | Very good with external features |
| **Deep learning (DeepAR, N-BEATS)** | Very High | 2+ years, many SKUs | Best for large catalogs |

For most e-commerce businesses, Prophet or exponential smoothing provides good results without deep ML expertise.

---

## 7. Backorder & Pre-Order Management

### Pre-Order Patterns

```sql
CREATE TABLE preorder_campaigns (
  id              BIGINT PRIMARY KEY,
  variant_id      BIGINT REFERENCES product_variants(id),
  type            VARCHAR(20) NOT NULL,
  -- 'pay_now': charge immediately, fulfill later
  -- 'pay_later': authorize now, capture when available
  -- 'notify_only': collect interest, no payment
  
  max_quantity     INTEGER,              -- cap on pre-orders
  estimated_ship   DATE,                 -- expected availability
  
  starts_at       TIMESTAMPTZ,
  ends_at         TIMESTAMPTZ,
  is_active       BOOLEAN DEFAULT TRUE,
  
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE preorders (
  id              BIGINT PRIMARY KEY,
  campaign_id     BIGINT REFERENCES preorder_campaigns(id),
  order_id        UUID REFERENCES orders(id),
  customer_id     BIGINT REFERENCES customers(id),
  variant_id      BIGINT REFERENCES product_variants(id),
  quantity        INTEGER NOT NULL,
  status          VARCHAR(20) DEFAULT 'pending',
  -- 'pending', 'allocated', 'shipped', 'canceled'
  
  payment_status  VARCHAR(20),
  -- 'authorized', 'captured', 'refunded'
  
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
```

### Backorder Workflow

```
Customer orders item (stock = 0, backorders enabled)
       │
       ▼
Order created with status "backordered"
Payment authorized (but NOT captured)
       │
       ▼
Customer notified: "Your order is on backorder. Estimated ship date: March 15"
       │
       ▼
Purchase order received at warehouse → stock available
       │
       ▼
Backorder allocation:
  1. Sort backorders by date (FIFO)
  2. Allocate incoming stock to oldest backorders first
  3. Capture payment for allocated orders
  4. Notify customer: "Your backordered item is now shipping"
       │
       ▼
Ship order → update tracking → notify customer
```

**Important**: For "pay later" pre-orders with delayed capture, authorizations typically expire after 7 days (varies by card network). For longer delays, either:
- Charge immediately (pay now model)
- Use Stripe's "uncaptured payment intents" with manual extension
- Re-authorize when ready to ship (requires customer's stored payment method)

---

## 8. Returns & Reverse Logistics

### Return Processing Data Model

```sql
CREATE TABLE returns (
  id              UUID PRIMARY KEY,
  order_id        UUID REFERENCES orders(id),
  customer_id     BIGINT REFERENCES customers(id),
  status          VARCHAR(20) DEFAULT 'requested',
  -- 'requested', 'approved', 'label_sent', 'in_transit', 'received',
  -- 'inspected', 'completed', 'rejected'
  
  type            VARCHAR(20),    -- 'return', 'exchange'
  resolution      VARCHAR(20),    -- 'refund', 'store_credit', 'exchange', 'repair'
  
  shipping_label_url VARCHAR(500),
  tracking_number    VARCHAR(100),
  
  -- Financial
  refund_amount      NUMERIC(12,2),
  restocking_fee     NUMERIC(12,2) DEFAULT 0,
  return_shipping_cost NUMERIC(12,2),
  
  requested_at       TIMESTAMPTZ DEFAULT NOW(),
  received_at        TIMESTAMPTZ,
  completed_at       TIMESTAMPTZ,
  
  notes              TEXT
);

CREATE TABLE return_items (
  id              UUID PRIMARY KEY,
  return_id       UUID REFERENCES returns(id),
  order_item_id   UUID REFERENCES order_items(id),
  variant_id      BIGINT REFERENCES product_variants(id),
  quantity        INTEGER NOT NULL,
  reason          VARCHAR(50),
  -- 'wrong_size', 'defective', 'not_as_described', 'changed_mind',
  -- 'arrived_late', 'wrong_item', 'damaged_in_shipping'
  
  condition       VARCHAR(20),     -- 'new', 'opened', 'damaged', 'defective'
  disposition     VARCHAR(20),     -- 'restock', 'refurbish', 'dispose', 'donate'
  
  restocked       BOOLEAN DEFAULT FALSE,
  restocked_at    TIMESTAMPTZ
);
```

### Return Platforms

| Platform | Type | Best For |
|----------|------|---------|
| **Loop Returns** | Self-service return portal | DTC brands, encourages exchanges over refunds |
| **Returnly (Affirm)** | Instant refund / exchange | Brands wanting to reduce refund friction |
| **Narvar** | Post-purchase experience (returns + tracking) | Mid-large merchants, full post-purchase suite |
| **AfterShip Returns** | Self-service returns | Budget-friendly, integrates with AfterShip tracking |
| **Happy Returns** | In-person return drop-off + portal | Brands wanting return bar experience |

### Disposition Logic

When a returned item is received at the warehouse:

```
Item Received
       │
       ├── Inspect condition
       │     │
       │     ├── Condition: New / Unopened
       │     │     └── Disposition: RESTOCK → add back to available inventory
       │     │
       │     ├── Condition: Opened, Good condition
       │     │     └── Disposition: RESTOCK (open box discount) or REFURBISH
       │     │
       │     ├── Condition: Damaged / Defective
       │     │     └── Disposition: RETURN TO VENDOR, DISPOSE, or REFURBISH
       │     │
       │     └── Condition: Used / Not resellable
       │           └── Disposition: DONATE or DISPOSE
       │
       └── Update inventory based on disposition
              └── If RESTOCK: increment on_hand
              └── If other: do not increment (write off)
```

---

## 9. Concurrency & Race Conditions

### The Overselling Problem

Two customers try to buy the last item simultaneously:

```
Customer A: SELECT available FROM inventory WHERE variant_id = 1;  → 1
Customer B: SELECT available FROM inventory WHERE variant_id = 1;  → 1
Customer A: UPDATE inventory SET allocated = allocated + 1 WHERE variant_id = 1;  → OK
Customer B: UPDATE inventory SET allocated = allocated + 1 WHERE variant_id = 1;  → OK!
→ allocated = 2, but on_hand = 1 → OVERSOLD
```

### Solution 1: Pessimistic Locking (SELECT FOR UPDATE)

```sql
BEGIN;
SELECT on_hand, allocated
FROM inventory_items
WHERE variant_id = :variant_id AND location_id = :location_id
FOR UPDATE;  -- locks the row until COMMIT/ROLLBACK

-- Check: if on_hand - allocated >= requested_quantity
UPDATE inventory_items
SET allocated = allocated + :quantity
WHERE variant_id = :variant_id AND location_id = :location_id;
COMMIT;
```

- Pro: Strong consistency, no overselling
- Con: Locks block concurrent transactions — can become a bottleneck under high load
- Best for: Standard e-commerce (adequate for 99% of stores)

### Solution 2: Optimistic Locking (Version Column)

```sql
-- Read current state
SELECT id, on_hand, allocated, version
FROM inventory_items
WHERE variant_id = :variant_id AND location_id = :location_id;

-- Update with version check (CAS — Compare and Swap)
UPDATE inventory_items
SET allocated = allocated + :quantity, version = version + 1
WHERE id = :item_id
  AND version = :expected_version
  AND (on_hand - allocated) >= :quantity;

-- Check affected rows: if 0, someone else modified it → retry
```

- Pro: No locking, better concurrency
- Con: Retries under contention, potential for retry storms
- Best for: Moderate contention (most items have enough stock)

### Solution 3: Atomic Conditional Update (Simplest)

```sql
-- Single atomic statement — no race condition
UPDATE inventory_items
SET allocated = allocated + :quantity
WHERE variant_id = :variant_id
  AND location_id = :location_id
  AND (on_hand - allocated) >= :quantity;

-- Check affected rows: if 0, insufficient stock
-- No need for SELECT first, no explicit locking needed
```

- Pro: Simplest, no explicit locking, atomic
- Con: No row-level lock means you can't do complex validation before the update
- Best for: Simple allocation scenarios (recommended starting point)

### Solution 4: Redis-Based Distributed Lock (Flash Sales)

For extreme concurrency (flash sales with thousands of simultaneous requests):

```python
import redis

def reserve_stock(variant_id: str, quantity: int, timeout: int = 10) -> bool:
    key = f"stock:{variant_id}"
    
    # Atomic decrement with floor check
    lua_script = """
    local current = tonumber(redis.call('GET', KEYS[1]) or '0')
    if current >= tonumber(ARGV[1]) then
        redis.call('DECRBY', KEYS[1], ARGV[1])
        return 1
    end
    return 0
    """
    result = redis.eval(lua_script, 1, key, quantity)
    return result == 1

# Initialize stock in Redis before flash sale starts
redis.set(f"stock:{variant_id}", available_quantity)
```

- Pro: Extremely fast (microseconds), handles massive concurrency
- Con: Redis is not durable by default (use AOF persistence or accept data loss risk)
- Best for: Flash sales, limited drops, ticket sales — sync to PostgreSQL asynchronously

### Recommendation by Scale

| Scale | Approach | Why |
|-------|---------|-----|
| **<1K orders/day** | Atomic conditional UPDATE | Simplest, PostgreSQL handles the concurrency fine |
| **1K-10K orders/day** | SELECT FOR UPDATE | Explicit control, still performant |
| **>10K orders/day** | Redis + async DB sync | Need the speed, can handle eventual consistency |
| **Flash sales** | Redis with Lua + queue-based checkout | Extreme concurrency on single SKU |

---

## 10. Inventory Architecture by Scale

### Startup (1-100 orders/day)

```
Shopify / Commerce Platform
  └── Built-in inventory tracking
  └── Single location
  └── Manual adjustments
  └── ShipStation for label generation
```

Don't build custom inventory. Use your commerce platform's built-in tools.

### Growth (100-1K orders/day)

```
Commerce Platform (Medusa / Saleor / Custom)
       │
       ├── Inventory service (custom)
       │     ├── Multi-location tracking
       │     ├── Allocation on order placement
       │     └── Low-stock alerts
       │
       ├── WMS integration (ShipBob / ShipHero)
       │     └── Sync inventory levels via API
       │
       └── Marketplace sync (Amazon, eBay)
             └── Channel-specific buffers
```

### Scale (1K-10K orders/day)

```
Event-Driven Inventory Service
       │
       ├── PostgreSQL (source of truth)
       ├── Redis (fast availability lookups)
       ├── Kafka (inventory events)
       │     ├── → Search index update
       │     ├── → Marketplace sync
       │     ├── → Analytics pipeline
       │     └── → Low-stock alerting
       │
       ├── CQRS read model (denormalized availability)
       ├── Multiple warehouse locations
       ├── Automated reorder (PO generation)
       └── Demand forecasting (Prophet/simple ML)
```

### Enterprise (10K+ orders/day)

```
Distributed Inventory System
       │
       ├── Event-sourced inventory (full audit trail)
       ├── Multi-region inventory services
       ├── Real-time ATP (Available to Promise) engine
       ├── Distributed order management (routing optimization)
       ├── WMS integration (Manhattan / Deposco)
       ├── EDI integration (suppliers, retailers)
       ├── ML demand forecasting (per SKU, per location)
       ├── Automated replenishment
       └── Cycle counting workflows
```
