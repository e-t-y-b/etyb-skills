# Cart & Checkout Architecture — Deep Reference

**Always use `WebSearch` to verify platform features, tax service pricing, and shipping carrier APIs before giving advice. This reference provides architectural context; the ecosystem evolves rapidly.**

## Table of Contents
1. [Cart Architecture](#1-cart-architecture)
2. [Cart Operations & Validation](#2-cart-operations--validation)
3. [Promotions & Discount Engine](#3-promotions--discount-engine)
4. [Tax Calculation](#4-tax-calculation)
5. [Shipping Calculation](#5-shipping-calculation)
6. [Checkout Flow Design](#6-checkout-flow-design)
7. [Cart Abandonment & Recovery](#7-cart-abandonment--recovery)
8. [High-Traffic Checkout](#8-high-traffic-checkout)
9. [Headless Checkout](#9-headless-checkout)

---

## 1. Cart Architecture

### Cart Storage Strategies

The cart is the most frequently mutated object in an e-commerce system. Where and how you store it matters.

#### Server-Side Cart (Database-Backed)

```sql
CREATE TABLE carts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id     BIGINT REFERENCES customers(id),  -- NULL for guest carts
  session_id      VARCHAR(100),                      -- for anonymous carts
  status          VARCHAR(20) DEFAULT 'active',      -- active, merged, converted, abandoned
  currency        CHAR(3) DEFAULT 'USD',
  metadata        JSONB DEFAULT '{}',
  expires_at      TIMESTAMPTZ DEFAULT NOW() + INTERVAL '30 days',
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE cart_items (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cart_id         UUID REFERENCES carts(id) ON DELETE CASCADE,
  variant_id      BIGINT REFERENCES product_variants(id),
  quantity        INTEGER NOT NULL CHECK (quantity > 0),
  unit_price      NUMERIC(12,2) NOT NULL,  -- price at time of add (snapshot)
  metadata        JSONB DEFAULT '{}',      -- custom options, personalization
  added_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (cart_id, variant_id)             -- one line per variant
);

CREATE INDEX idx_cart_items_cart ON cart_items(cart_id);
CREATE INDEX idx_carts_customer ON carts(customer_id);
CREATE INDEX idx_carts_session ON carts(session_id);
CREATE INDEX idx_carts_expires ON carts(expires_at) WHERE status = 'active';
```

- Pro: Cart survives across devices, enables abandonment tracking, supports server-side validation
- Con: Every add-to-cart is a DB write, requires cart expiration cleanup
- Best for: Most production e-commerce (this is the standard approach)

#### Redis-Backed Cart (for High Performance)

```
Key: cart:{cart_id}
Type: Hash
Fields:
  items     → JSON array of {variant_id, quantity, unit_price, metadata}
  customer  → customer_id or null
  currency  → "USD"
  metadata  → JSON object
TTL: 30 days
```

- Pro: Sub-millisecond reads/writes, great for high-traffic stores
- Con: Data loss risk (Redis persistence isn't as durable as PostgreSQL), harder to query for analytics
- Best for: High-traffic stores, flash sales — use Redis as primary with async persistence to PostgreSQL

#### Client-Side Cart (LocalStorage/Cookie)

- Pro: Zero server load for cart operations, works offline
- Con: No cross-device sync, no server-side validation until checkout, no abandonment tracking, size limits (cookies: 4KB), security risk (price tampering)
- Best for: Simple stores with very low traffic — generally not recommended for serious e-commerce

**Recommended approach**: Database-backed cart (PostgreSQL) with Redis caching for read performance. Cart writes go to PostgreSQL, reads served from Redis. This gives durability + speed.

### Anonymous → Authenticated Cart Merge

When a guest user adds items to cart, then logs in or creates an account:

```
1. Guest browses → session_id assigned → cart created (customer_id = NULL)
2. Guest adds items to cart (associated with session_id)
3. Guest logs in or creates account
4. Merge logic:
   a. Find active cart for customer_id (if exists from previous session)
   b. Find active cart for session_id (current guest cart)
   c. If both exist: merge items (sum quantities, prefer latest prices)
   d. If only guest cart: assign customer_id to it
   e. If only customer cart: add session items to it
5. Clear session_id from merged cart, update customer_id
```

**Conflict resolution strategies:**
- **Additive merge** (default): Combine items from both carts, sum quantities
- **Guest wins**: Replace authenticated cart with guest cart (freshest intent)
- **Latest wins**: Keep the most recently updated cart, discard the other
- **Ask the user**: Show a merge dialog (rarely done — adds friction)

### Cart Expiration and Cleanup

```sql
-- Periodic cleanup job (run daily)
-- 1. Mark old active carts as abandoned
UPDATE carts
SET status = 'abandoned'
WHERE status = 'active'
  AND updated_at < NOW() - INTERVAL '30 days';

-- 2. Delete very old abandoned carts (after abandonment emails have been sent)
DELETE FROM carts
WHERE status = 'abandoned'
  AND updated_at < NOW() - INTERVAL '90 days';
```

For Redis carts, rely on TTL for automatic expiration.

---

## 2. Cart Operations & Validation

### Cart Validation Pipeline

Every time the cart is read or the user enters checkout, validate:

```
Cart Read / Checkout Entry
       │
       ├── 1. Product availability check
       │     └── Is the product still active? Not deleted/archived?
       │
       ├── 2. Variant availability check
       │     └── Is the specific variant still available? Not discontinued?
       │
       ├── 3. Price freshness check
       │     └── Has the price changed since the item was added?
       │     └── If yes: update cart item price, show notification to user
       │
       ├── 4. Stock check
       │     └── Is the requested quantity still available?
       │     └── If not: adjust quantity, show notification
       │
       ├── 5. Quantity limits
       │     └── Min/max per item, max total items, max total quantity
       │
       ├── 6. Promotion validity
       │     └── Are applied coupons still valid? Conditions still met?
       │
       └── 7. Geographic restrictions
              └── Can this item ship to the customer's location?
```

### Price Locking

When should you lock prices?

| Strategy | When Price is Locked | Pros | Cons |
|----------|---------------------|------|------|
| **Never lock** | Price always reflects current | Simple, always accurate | Customer sees price change mid-checkout, frustrating |
| **Lock at add-to-cart** | When item is added | Price stability for customer | Stale prices if customer waits days |
| **Lock at checkout entry** | When checkout begins | Balanced — recent price, stable during checkout | Must re-validate if customer leaves and returns |
| **Lock at payment** | At payment authorization | Most accurate | Price can change during checkout flow |

**Recommended**: Lock prices when checkout begins (or when the "place order" page is rendered). Show a notification if prices changed since the item was added. This balances customer experience with business accuracy.

### Cart Locking During Checkout

To prevent modifications while payment is processing:

```sql
ALTER TABLE carts ADD COLUMN locked_at TIMESTAMPTZ;
ALTER TABLE carts ADD COLUMN lock_expires_at TIMESTAMPTZ;

-- Lock cart when entering payment step
UPDATE carts SET locked_at = NOW(), lock_expires_at = NOW() + INTERVAL '15 minutes'
WHERE id = :cart_id AND locked_at IS NULL;

-- Reject modifications to locked carts
-- Application code: if cart.locked_at IS NOT NULL AND NOW() < cart.lock_expires_at → reject
-- Auto-unlock after timeout (in case payment flow is abandoned)
```

---

## 3. Promotions & Discount Engine

### Promotion Types

| Type | Example | Implementation |
|------|---------|---------------|
| **Percentage off** | 20% off all shoes | Apply percentage to matching items |
| **Fixed amount off** | $10 off orders over $50 | Subtract from order total |
| **BOGO** | Buy 2 get 1 free | Add free item when condition met |
| **Free shipping** | Free shipping over $75 | Override shipping cost to $0 |
| **Bundle discount** | Buy shampoo + conditioner, save 15% | Detect bundle, apply combined discount |
| **Tiered/Volume** | Buy 3+ for $10 each (normally $15) | Check quantity, adjust unit price |
| **Gift with purchase** | Free tote bag with orders over $100 | Auto-add gift item to qualifying carts |
| **First-time buyer** | 10% off first order | Check customer order history |
| **Loyalty points** | Spend 500 points for $5 off | Points deduction as payment |

### Promotion Data Model

```sql
CREATE TABLE promotions (
  id              BIGINT PRIMARY KEY,
  name            VARCHAR(255) NOT NULL,
  code            VARCHAR(50) UNIQUE,      -- NULL = automatic (no code needed)
  type            VARCHAR(30) NOT NULL,     -- percentage, fixed, bogo, free_shipping, etc.
  value           NUMERIC(12,2),            -- 20 (for 20%), 10.00 (for $10 off)
  
  -- Scope: what does this apply to?
  target          VARCHAR(20) NOT NULL,     -- 'order', 'line_item', 'shipping'
  
  -- Conditions
  min_purchase    NUMERIC(12,2),            -- minimum order subtotal
  min_quantity    INTEGER,                  -- minimum total items
  max_uses        INTEGER,                  -- total redemptions allowed
  max_uses_per_customer INTEGER,            -- per-customer limit
  current_uses    INTEGER DEFAULT 0,
  
  -- Validity
  starts_at       TIMESTAMPTZ NOT NULL,
  ends_at         TIMESTAMPTZ,             -- NULL = no end date
  is_active       BOOLEAN DEFAULT TRUE,
  
  -- Stacking
  is_exclusive    BOOLEAN DEFAULT FALSE,    -- can't combine with other promotions
  priority        INTEGER DEFAULT 0,        -- higher = applied first
  
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Which products/categories/collections a promotion applies to
CREATE TABLE promotion_conditions (
  id              BIGINT PRIMARY KEY,
  promotion_id    BIGINT REFERENCES promotions(id),
  condition_type  VARCHAR(30),  -- 'product', 'category', 'collection', 'customer_group', 'tag'
  operator        VARCHAR(10),  -- 'in', 'not_in', 'equals'
  value           JSONB         -- [1, 2, 3] (product IDs), ["vip"] (tags)
);
```

### Rule Engine for Complex Promotions

For stores with many overlapping promotions, implement a rule engine:

```
For each promotion (sorted by priority):
  1. Check validity (date range, usage limits)
  2. Check conditions (min purchase, qualifying products, customer eligibility)
  3. If eligible:
     a. Calculate discount amount
     b. If exclusive: mark this as the only promotion and stop
     c. If stackable: accumulate with other discounts
  4. Apply "best for customer" rule if multiple exclusive promotions qualify
```

**Stacking rules** (common patterns):
- Only one coupon code at a time (most common)
- Automatic promotions stack with one coupon code
- Never exceed 100% discount (cap total discounts at subtotal)
- Some promotions are "compounding" (20% off + 10% off = 28% off, not 30%)

### Medusa v2 Promotions Architecture

Medusa takes a clean approach: promotions are a separate module with rules and conditions defined as configuration. The promotion engine evaluates all applicable promotions against the cart context and returns a list of adjustments. This separation keeps the cart service clean.

### Commercetools Discount Model

Commercetools uses predicate-based targeting: discounts have a `predicate` field with expressions like `lineItemCount(sku = "ABC") >= 2` or `totalPrice > "50.00 USD"`. This is powerful for complex rules but requires learning the predicate syntax.

---

## 4. Tax Calculation

### Tax Complexity by Region

| Region | Tax Type | Complexity | Key Challenge |
|--------|---------|------------|---------------|
| **US** | Sales tax | Very High | 13,000+ tax jurisdictions, varying rates, nexus rules |
| **EU** | VAT | High | Country-specific rates (17-27%), reverse charge for B2B, digital goods rules (OSS) |
| **UK** | VAT | Medium | Standard (20%), reduced (5%), zero-rated categories |
| **Canada** | GST/HST/PST | High | Federal + provincial taxes, varying by province |
| **Australia** | GST | Low | Flat 10% on most goods and services |

### Tax Service Selection

| Service | Strength | Pricing | Best For |
|---------|---------|---------|---------|
| **Avalara (AvaTax)** | Most comprehensive, best for complex US nexus | $$ (per transaction) | US businesses with multi-state nexus |
| **TaxJar** | Simple API, Stripe integration | $$ (per transaction) | SMBs, Stripe-centric stacks |
| **Vertex** | Enterprise, SAP/Oracle integration | $$$$ | Large enterprises with ERP |
| **Stripe Tax** | Built into Stripe, easiest if already using Stripe | $ (0.5% of transaction) | Stripe-first businesses |

### Tax Calculation Architecture

```
Checkout: Customer enters shipping address
       │
       ▼
Tax Calculation Request
  - Ship-from address (warehouse/store)
  - Ship-to address (customer)
  - Line items with:
    - Product tax code (e.g., "PC040100" for clothing)
    - Amount
    - Quantity
  - Shipping amount
  - Customer tax exemption status
       │
       ▼
Tax Service (Avalara / TaxJar / Stripe Tax)
       │
       ▼
Tax Response
  - Tax per line item
  - Tax on shipping
  - Jurisdiction breakdown (state, county, city, special district)
  - Tax rate applied
       │
       ▼
Display tax on checkout → Include in order total
```

### Tax-Inclusive vs Tax-Exclusive Pricing

**Tax-exclusive (US model)**: Displayed price = $29.99, tax calculated and added at checkout → total = $32.29
**Tax-inclusive (EU/UK model)**: Displayed price = $29.99 including VAT, tax is extracted from the price → net price = $24.99, VAT = $5.00

```sql
-- Store which pricing model each market uses
CREATE TABLE tax_settings (
  region      VARCHAR(10) PRIMARY KEY,  -- 'US', 'EU', 'GB'
  inclusive   BOOLEAN NOT NULL,          -- true = tax-inclusive pricing
  default_rate NUMERIC(5,4)             -- 0.2000 = 20% (for display purposes)
);
```

### Digital Goods Tax

Digital products have special tax rules:
- **EU**: VAT applies based on customer's country (not seller's). Must register for OSS (One-Stop Shop) or register in each country.
- **US**: Varies by state. Some states tax digital goods, some don't. A patchwork.
- Services like Paddle and Lemon Squeezy act as "merchant of record" — they handle all tax compliance for digital goods, which is often worth the higher transaction fee.

---

## 5. Shipping Calculation

### Shipping Rate Strategies

| Strategy | How It Works | Best For |
|----------|-------------|---------|
| **Flat rate** | $5.99 shipping on all orders | Simple stores, uniform product sizes |
| **Free over threshold** | Free shipping on orders over $75 | Most DTC brands (incentivizes larger orders) |
| **Weight-based** | Rate table by weight brackets | Stores with varying product weights |
| **Zone-based** | Rate by destination zone | Domestic shipping with regional variation |
| **Real-time carrier rates** | Live rates from USPS/UPS/FedEx | Accurate pricing, heavy/oversized items |
| **Calculated at checkout** | Complex rules combining multiple factors | Large catalogs with diverse shipping needs |

### Shipping API Aggregators

| Service | Carriers | Features | Pricing |
|---------|---------|----------|---------|
| **EasyPost** | 100+ carriers | Label purchase, tracking, address verification | Pay per label |
| **Shippo** | 85+ carriers | Multi-carrier rates, labels, returns | Free tier + pay per label |
| **ShipEngine** | Multiple carriers | Rate comparison, labels, tracking | Pay per label |
| **GoShippo** | Major US carriers | Discounted USPS/UPS rates | Pay per label |

### Shipping Calculation Flow

```
Cart items + Customer address
       │
       ├── 1. Determine ship-from location(s)
       │     └── Based on inventory availability, proximity to customer
       │
       ├── 2. Package estimation
       │     └── Which items fit in which boxes? (bin-packing algorithm)
       │     └── Services like EasyPost provide packing optimization
       │
       ├── 3. Get rates from carriers
       │     └── Query USPS, UPS, FedEx APIs (or aggregator)
       │     └── Include package dimensions, weight, origin, destination
       │
       ├── 4. Apply shipping rules
       │     └── Free shipping threshold, flat rate overrides, handling fees
       │
       └── 5. Present options to customer
              └── "Standard (5-7 days): $5.99"
              └── "Express (2-3 days): $12.99"
              └── "Next Day: $24.99"
```

### Split Shipments

When items ship from different locations:

```sql
CREATE TABLE shipment_groups (
  id              UUID PRIMARY KEY,
  cart_id         UUID REFERENCES carts(id),
  ship_from_id    BIGINT REFERENCES locations(id),
  shipping_method VARCHAR(50),
  shipping_cost   NUMERIC(12,2),
  estimated_days  INTEGER
);

CREATE TABLE shipment_group_items (
  shipment_group_id UUID REFERENCES shipment_groups(id),
  cart_item_id      UUID REFERENCES cart_items(id),
  quantity          INTEGER NOT NULL,
  PRIMARY KEY (shipment_group_id, cart_item_id)
);
```

Show the customer: "Your order will arrive in 2 packages" with separate ETAs. Let them choose: "Wait for all items to ship together?" (fewer packages, slower) or "Ship items as they're ready?" (faster, potentially more shipping cost).

---

## 6. Checkout Flow Design

### Single-Page vs Multi-Step Checkout

| Approach | Conversion Impact | Best For |
|----------|------------------|---------|
| **Single-page** | Higher conversion (fewer clicks to complete) | Mobile, simple products, returning customers |
| **Multi-step** | Lower anxiety (less overwhelming), better analytics per step | Complex orders, B2B, custom products |
| **Accordion** | Middle ground — all steps visible, one expanded at a time | Desktop, moderate complexity |

### Checkout as a State Machine

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│ Contact  │────▶│ Shipping │────▶│ Payment  │────▶│ Review & │
│  Info    │     │ Address  │     │  Method  │     │  Place   │
└──────────┘     └──────────┘     └──────────┘     └──────────┘
     │                │                │                │
     ▼                ▼                ▼                ▼
  Validate         Validate         Validate         Create Order
  email/phone      address          payment info     Process Payment
  (duplicate       (verification    (tokenize card   Confirm
   detection)       API)             via PSP)
```

### Checkout Data Model

```sql
CREATE TABLE checkouts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cart_id         UUID REFERENCES carts(id),
  
  -- Contact
  email           VARCHAR(255),
  phone           VARCHAR(20),
  
  -- Shipping address
  shipping_first_name VARCHAR(100),
  shipping_last_name  VARCHAR(100),
  shipping_address1   VARCHAR(255),
  shipping_address2   VARCHAR(255),
  shipping_city       VARCHAR(100),
  shipping_state      VARCHAR(100),
  shipping_postal     VARCHAR(20),
  shipping_country    CHAR(2),
  
  -- Billing address (NULL = same as shipping)
  billing_first_name  VARCHAR(100),
  billing_last_name   VARCHAR(100),
  billing_address1    VARCHAR(255),
  billing_address2    VARCHAR(255),
  billing_city        VARCHAR(100),
  billing_state       VARCHAR(100),
  billing_postal      VARCHAR(20),
  billing_country     CHAR(2),
  
  -- Shipping method
  shipping_method_id  VARCHAR(50),
  shipping_cost       NUMERIC(12,2),
  
  -- Tax
  tax_total           NUMERIC(12,2),
  tax_breakdown       JSONB,  -- [{jurisdiction, rate, amount}]
  
  -- Totals (computed)
  subtotal            NUMERIC(12,2),
  discount_total      NUMERIC(12,2),
  grand_total         NUMERIC(12,2),
  
  -- State
  step                VARCHAR(20) DEFAULT 'contact',  -- contact, shipping, payment, review
  completed_at        TIMESTAMPTZ,
  abandoned_at        TIMESTAMPTZ,
  
  -- Idempotency
  idempotency_key     VARCHAR(100) UNIQUE,
  
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);
```

### Guest Checkout

Guest checkout is critical — requiring account creation before purchase kills conversion. Industry data shows 25-35% of customers abandon checkout when forced to create an account.

Pattern:
1. Collect email at the start of checkout (for abandonment recovery)
2. Complete purchase as guest
3. After order confirmation: "Save your details for faster checkout next time? Create an account with one click." (post-purchase account creation)

### Express Checkout (Apple Pay, Google Pay, Shop Pay)

Express checkout buttons bypass the entire checkout form — they provide address, payment, and contact in one tap.

```
Product Page / Cart
       │
  ┌────┴────┐
  │ Express │  ← Apple Pay / Google Pay / Shop Pay button
  │ Checkout│
  └────┬────┘
       │
       ▼
  Payment Sheet (native)
  - Address (from wallet)
  - Card (from wallet)
  - Shipping (selected in sheet)
       │
       ▼
  Payment authorized → Create order → Confirmation
```

Implementation: Use Stripe's Payment Request Button (supports Apple Pay + Google Pay with one integration) or the Web Payments API.

### Address Validation

Invalid shipping addresses cause failed deliveries and customer support costs. Validate at checkout:

| Service | Strengths | Pricing |
|---------|----------|---------|
| **Google Places Autocomplete** | Great UX (type-ahead), global | $2.83 per 1,000 requests (Autocomplete session) |
| **Smarty (SmartyStreets)** | Best US address verification, CASS certified | From $0.01/lookup |
| **Loqate (GBG)** | Strong international coverage | Per-lookup |
| **USPS Address API** | Free for US addresses, authoritative | Free |

---

## 7. Cart Abandonment & Recovery

### Abandonment Rates (Industry Benchmarks)

Average cart abandonment rate: ~70% (Baymard Institute). Reasons:
- 48% — Extra costs too high (shipping, tax, fees)
- 26% — Required to create an account
- 25% — Checkout was too complex
- 18% — Couldn't see total cost upfront
- 17% — Didn't trust site with credit card

### Abandonment Recovery Strategy

```
Cart Abandoned (no activity for 1 hour)
       │
       ├── Email 1 (1 hour): "You left something behind" — reminder with cart contents
       │
       ├── Email 2 (24 hours): "Still interested?" — reminder + social proof / reviews
       │
       └── Email 3 (72 hours): "Last chance" — include incentive (10% off, free shipping)
       │
       └── (Optional) SMS (if phone collected, with consent)
       │
       └── Retargeting ads (Facebook, Google) — show cart items
```

Recovery email typically recovers 5-15% of abandoned carts.

### Technical Implementation

```sql
-- Identify abandoned carts for recovery campaigns
SELECT c.id, c.email, c.updated_at,
       json_agg(json_build_object(
         'name', p.name,
         'image', pi.url,
         'price', ci.unit_price,
         'quantity', ci.quantity
       )) AS items
FROM checkouts c
JOIN cart_items ci ON ci.cart_id = c.cart_id
JOIN product_variants pv ON pv.id = ci.variant_id
JOIN products p ON p.id = pv.product_id
LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.position = 0
WHERE c.completed_at IS NULL
  AND c.email IS NOT NULL
  AND c.updated_at < NOW() - INTERVAL '1 hour'
  AND c.abandoned_at IS NULL
  AND c.id NOT IN (SELECT checkout_id FROM abandonment_emails)
GROUP BY c.id;
```

Integrate with email services: Klaviyo (best for e-commerce), Customer.io, Brevo, or build custom with SendGrid.

---

## 8. High-Traffic Checkout

### Flash Sale / High-Demand Patterns

Flash sales (limited inventory, massive simultaneous traffic) are the hardest checkout problem in e-commerce.

#### Queue-Based Checkout

For extremely high-demand drops (limited-edition products, concert tickets):

```
User clicks "Buy Now"
       │
       ▼
  Join Queue (assigned position)
       │
       ▼
  Wait Page (shows position, estimated wait time)
       │
       ▼ (when turn comes)
  Exclusive checkout session (10-15 minute timer)
       │
       ├── Complete purchase → inventory decremented
       │
       └── Timer expires → inventory released → next in queue
```

Services: Queue-it, Cloudflare Waiting Room, or build custom with Redis sorted sets.

#### Rate Limiting Add-to-Cart

```python
# Redis-based rate limiting
def can_add_to_cart(user_id: str, variant_id: str) -> bool:
    key = f"add_to_cart:{user_id}:{variant_id}"
    count = redis.incr(key)
    if count == 1:
        redis.expire(key, 60)  # 1-minute window
    return count <= 5  # max 5 add-to-cart per variant per minute
```

#### Bot Protection

Flash sales attract bots. Layered defense:
1. **Cloudflare Bot Management / AWS WAF Bot Control**: Block known bot signatures
2. **CAPTCHA on checkout**: hCaptcha or Cloudflare Turnstile (avoid friction for legitimate users)
3. **Device fingerprinting**: Detect multiple accounts from same device
4. **Purchase velocity limits**: One unit per customer per SKU for limited drops

### Idempotent Order Creation

Prevent double orders from network retries or double-clicks:

```sql
-- Use idempotency key (client-generated UUID)
INSERT INTO orders (id, checkout_id, idempotency_key, ...)
VALUES (:id, :checkout_id, :idempotency_key, ...)
ON CONFLICT (idempotency_key) DO NOTHING
RETURNING id;

-- If the insert was a no-op (key already exists), return the existing order
```

Stripe also supports idempotency keys on payment intents — pass the same key for retries.

---

## 9. Headless Checkout

### Headless Checkout Architecture

In a headless setup, the checkout UI is completely custom (React/Next.js/Remix), calling commerce APIs:

```
Custom Frontend (Next.js)
       │
       ├── POST /checkout/start         → Create checkout session
       ├── PUT  /checkout/:id/contact   → Set email, phone
       ├── PUT  /checkout/:id/shipping  → Set address, get rates
       ├── PUT  /checkout/:id/method    → Select shipping method
       ├── POST /checkout/:id/tax       → Calculate tax
       ├── POST /checkout/:id/promo     → Apply coupon code
       ├── POST /checkout/:id/payment   → Initiate payment (returns client_secret)
       └── POST /checkout/:id/complete  → Finalize order
       │
       ▼
Commerce API (Medusa / Saleor / Custom)
       │
       ├── Inventory service (reserve stock)
       ├── Tax service (Avalara / Stripe Tax)
       ├── Shipping service (EasyPost / Shippo)
       └── Payment service (Stripe / Adyen)
```

### Shopify Checkout Extensibility

Shopify's checkout is historically locked down, but Checkout Extensions (2023+) allow:
- Custom UI blocks in checkout (banners, upsells, fields)
- Payment customizations (hide/reorder payment methods)
- Shipping customizations (rename, reorder, hide shipping options)
- Post-purchase extensions (upsell page after payment)

Limitations: You can't fully replace the Shopify checkout — you add to it. For complete checkout control, you need a headless platform (Medusa, Saleor, Commercetools) or custom-built.

### Checkout Security Considerations

1. **Never trust client-side prices**: Always recalculate totals server-side before processing payment
2. **Validate addresses server-side**: Don't rely on client-side validation
3. **Rate-limit checkout endpoints**: Prevent brute-force coupon scanning
4. **Use idempotency keys**: Prevent double-charges from retries
5. **PCI compliance**: Use hosted payment fields (Stripe Elements) to keep card data off your servers
6. **CSRF protection**: All checkout mutations need CSRF tokens
7. **Session binding**: Bind checkout to authenticated session to prevent checkout hijacking
