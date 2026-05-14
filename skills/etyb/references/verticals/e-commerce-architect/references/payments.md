# Payment Systems Architecture — Deep Reference

**Always use `WebSearch` to verify PSP features, pricing, compliance requirements, and payment method availability before giving advice. Payment ecosystems evolve rapidly and vary by region.**

## Table of Contents
1. [Payment Service Provider Selection](#1-payment-service-provider-selection)
2. [Payment Flow Architecture](#2-payment-flow-architecture)
3. [PCI DSS Compliance](#3-pci-dss-compliance)
4. [Payment Methods](#4-payment-methods)
5. [Recurring Payments & Subscriptions](#5-recurring-payments--subscriptions)
6. [Fraud Prevention](#6-fraud-prevention)
7. [Refunds & Disputes](#7-refunds--disputes)
8. [Multi-Currency & International](#8-multi-currency--international)
9. [Financial Reconciliation](#9-financial-reconciliation)
10. [Payment Security Patterns](#10-payment-security-patterns)

---

## 1. Payment Service Provider Selection

### PSP Comparison Matrix

| PSP | Transaction Fee (US) | International | Key Strengths | Best For |
|-----|---------------------|---------------|--------------|---------|
| **Stripe** | 2.9% + $0.30 | 47+ countries | Best DX, extensive API, huge ecosystem | Most businesses, developer-first teams |
| **Adyen** | IC++ (interchange + markup) | 100+ countries | Enterprise-grade, omnichannel (online + POS), lowest fees at volume | Enterprise, high-volume, omnichannel |
| **Braintree (PayPal)** | 2.59% + $0.49 | 45+ countries | PayPal integration, Venmo, strong US presence | US-focused, PayPal/Venmo merchants |
| **Square** | 2.9% + $0.30 | US, CA, UK, AU, JP, IE, FR, ES | POS + online unified, simple pricing | Small business, omnichannel (POS + online) |
| **Checkout.com** | IC++ | 150+ countries | Lowest rates at volume, strong in EU/MENA | High-volume international merchants |
| **Mollie** | 1.8% + €0.25 (EU cards) | EU-focused | Best for European merchants, simple pricing | EU-based businesses |

### IC++ vs Blended Pricing

**Blended (Stripe default)**: Fixed rate (2.9% + $0.30) regardless of card type. Simple, predictable, but you pay the same for a debit card (low interchange) as a premium rewards card (high interchange).

**IC++ (Interchange Plus Plus)**: Interchange fee (set by card networks, varies by card type) + PSP markup + scheme fee. More complex billing, but typically 15-30% cheaper at $1M+ volume.

**When to switch to IC++**: At ~$500K-$1M annual processing volume, negotiate IC++ pricing with Adyen, Checkout.com, or Stripe (available on request for larger merchants).

### Multi-PSP Strategy

At scale, having a backup PSP provides:
- **Failover**: If Stripe has an outage, route to Adyen
- **Cost optimization**: Route transactions to the cheapest PSP by region/card type
- **Authorization rate optimization**: Some PSPs have better auth rates in certain regions

**Payment orchestration platforms** handle multi-PSP routing:

| Platform | What It Does | Best For |
|----------|-------------|---------|
| **Primer** | Unified API for multiple PSPs, smart routing, no-code workflows | Mid-to-large merchants wanting PSP flexibility |
| **Spreedly** | Payment vault + multi-PSP routing | Marketplaces, platforms needing PSP abstraction |
| **Gr4vy** | Cloud payment orchestration, vault, routing | Enterprises wanting turnkey orchestration |

**When to go multi-PSP**: Don't do it prematurely. A single PSP (Stripe) is fine until you hit $10M+ in processing volume or have specific needs (regional PSPs for better auth rates in certain markets).

---

## 2. Payment Flow Architecture

### The Standard E-Commerce Payment Flow

```
Customer submits payment
       │
       ▼
1. AUTHORIZATION (Auth)
   PSP contacts card network → issuing bank approves/declines
   Funds are "held" on customer's card (not yet charged)
   Result: payment_intent.status = "requires_capture" or "succeeded"
       │
       ▼
2. CAPTURE (can be immediate or delayed)
   Merchant captures the authorized amount → funds transfer initiated
   For physical goods: capture when order ships (best practice)
   For digital goods: capture immediately
       │
       ▼
3. SETTLEMENT
   Funds arrive in merchant's bank account
   Timing: T+2 days (Stripe standard), T+1 (Stripe Instant Payouts for a fee)
       │
       ▼
4. RECONCILIATION
   Match settlement deposits against orders
   Handle partial captures, refunds, disputes
```

### Authorization & Capture Patterns

| Pattern | Auth | Capture | Use Case |
|---------|------|---------|----------|
| **Auth + immediate capture** | At checkout | Immediately | Digital goods, in-stock items shipping same day |
| **Auth + delayed capture** | At checkout | When order ships | Physical goods, made-to-order, pre-orders |
| **Auth + partial capture** | Full amount | Only amount shipped | Split shipments (capture per shipment) |
| **Incremental auth** | Initial estimate | Increase before capture | Tips, variable-amount orders (gas stations, restaurants) |

**Stripe Payment Intents flow (recommended):**

```
Frontend                            Backend                          Stripe
   │                                   │                               │
   │  1. Start checkout                │                               │
   │──────────────────────────────────▶│                               │
   │                                   │  2. Create PaymentIntent      │
   │                                   │─────────────────────────────▶│
   │                                   │  {amount, currency,           │
   │                                   │   capture_method: 'manual'}   │
   │                                   │◀─────────────────────────────│
   │  3. Return client_secret          │  {client_secret, id}          │
   │◀──────────────────────────────────│                               │
   │                                   │                               │
   │  4. Confirm payment               │                               │
   │  (stripe.confirmCardPayment)      │                               │
   │──────────────────────────────────────────────────────────────────▶│
   │                                   │                               │
   │  5. 3DS challenge (if required)   │                               │
   │◀─────────────────────────────────────────────────────────────────│
   │  6. Payment authorized            │                               │
   │──────────────────────────────────────────────────────────────────▶│
   │                                   │                               │
   │                                   │  7. Webhook: payment_intent   │
   │                                   │     .amount_capturable        │
   │                                   │◀─────────────────────────────│
   │                                   │  8. Create order               │
   │                                   │  9. Reserve inventory          │
   │                                   │                               │
   │                                   │  10. Capture (when shipping)  │
   │                                   │─────────────────────────────▶│
```

### Webhook-Driven Payment Architecture

**Critical principle**: Never rely on the frontend callback to confirm payment. The customer's browser can close, lose connection, or crash. Always use webhooks as the source of truth.

```
Stripe Webhook Events → Your Webhook Endpoint → Update Order State
```

Key webhook events to handle:

| Event | Action |
|-------|--------|
| `payment_intent.succeeded` | Create/confirm order, reserve inventory |
| `payment_intent.payment_failed` | Show error, allow retry |
| `payment_intent.canceled` | Release inventory reservation |
| `charge.refunded` | Process refund in your system |
| `charge.dispute.created` | Flag order, pause fulfillment, gather evidence |
| `charge.dispute.closed` | Update dispute outcome |
| `invoice.payment_succeeded` | (Subscriptions) Renew subscription period |
| `invoice.payment_failed` | (Subscriptions) Start dunning flow |
| `customer.subscription.deleted` | Cancel subscription in your system |

### Webhook Security

```python
# Always verify webhook signatures
import stripe

@app.post("/webhooks/stripe")
async def stripe_webhook(request: Request):
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")
    
    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, WEBHOOK_SECRET
        )
    except stripe.error.SignatureVerificationError:
        raise HTTPException(status_code=400)
    
    # Process event
    if event["type"] == "payment_intent.succeeded":
        handle_payment_success(event["data"]["object"])
    
    return {"status": "ok"}  # Always return 200 quickly
```

### Idempotency

Payment operations MUST be idempotent. Network retries, webhook redelivery, and user double-clicks can all cause duplicate requests.

```python
# Stripe idempotency key
payment_intent = stripe.PaymentIntent.create(
    amount=5000,
    currency="usd",
    idempotency_key=f"order_{order_id}_payment",  # unique per order attempt
)

# Your own idempotency
# Store processed webhook event IDs and skip duplicates
processed = redis.setnx(f"webhook:{event_id}", "1")
if not processed:
    return  # Already handled this event
redis.expire(f"webhook:{event_id}", 86400 * 7)  # Keep for 7 days
```

---

## 3. PCI DSS Compliance

### PCI Compliance Levels

| Level | Criteria | Requirement |
|-------|---------|------------|
| **Level 1** | >6M transactions/year | Annual on-site audit by QSA, quarterly network scans |
| **Level 2** | 1-6M transactions/year | Annual SAQ, quarterly network scans |
| **Level 3** | 20K-1M e-commerce transactions/year | Annual SAQ, quarterly network scans |
| **Level 4** | <20K e-commerce or <1M total/year | Annual SAQ, quarterly scans (recommended) |

### SAQ Types (Self-Assessment Questionnaire)

| SAQ | PCI Scope | What It Means | How to Achieve |
|-----|-----------|--------------|----------------|
| **SAQ A** | Lowest | All payment processing outsourced, no card data touches your servers | Use Stripe Checkout (hosted), Adyen Drop-in, PayPal hosted buttons |
| **SAQ A-EP** | Low-Medium | Card data entered on your page but submitted directly to PSP | Use Stripe Elements, Adyen Custom Card Component (tokenization via JS SDK) |
| **SAQ D** | Highest (full PCI) | Card data touches your servers | Custom payment forms posting to your backend — AVOID unless necessary |

**Recommendation**: Use SAQ A or SAQ A-EP. There is almost never a good reason for an e-commerce business to handle raw card data (SAQ D).

### Tokenization Architecture

```
Customer's Browser
       │
       │  Card number entered into Stripe Elements iframe
       │  (card data NEVER touches your server)
       │
       ▼
Stripe's Servers
       │
       │  Card tokenized → returns PaymentMethod token (pm_xxx)
       │
       ▼
Your Backend
       │
       │  Receives only the token (pm_xxx), NOT card data
       │  Creates PaymentIntent with the token
       │  Stores token for future charges (with customer consent)
       │
       ▼
Stripe Vault
       │
       │  Stores encrypted card data
       │  You reference it by token forever
```

### PCI Compliance Checklist for E-Commerce

1. **Never log card data** — not in application logs, error tracking (Sentry), or analytics
2. **Use hosted payment fields** — Stripe Elements, Adyen Drop-in, Braintree Hosted Fields
3. **TLS everywhere** — HTTPS on all pages, not just checkout
4. **Restrict access** — Only authorized personnel access payment dashboards
5. **Regular vulnerability scans** — Quarterly ASV scans if required by your SAQ level
6. **Incident response plan** — Know what to do if card data is exposed
7. **Vendor compliance** — Ensure all third parties handling payments are PCI compliant

---

## 4. Payment Methods

### Payment Method Coverage by Region

| Region | Primary Methods | Must-Have |
|--------|----------------|-----------|
| **US** | Cards (Visa, Mastercard, Amex), Apple Pay, Google Pay | Cards + Apple Pay/Google Pay |
| **EU** | Cards, SEPA Direct Debit, iDEAL (NL), Bancontact (BE), Sofort (DE/AT), Klarna | Cards + local methods per country |
| **UK** | Cards, Apple Pay, Google Pay, Klarna, PayPal | Cards + Apple Pay/Google Pay |
| **LATAM** | Cards, Boleto (BR), OXXO (MX), PIX (BR), local cards | Local payment methods critical |
| **India** | UPI, cards, net banking, wallets (Paytm, PhonePe) | UPI is dominant |
| **China** | Alipay, WeChat Pay | Alipay + WeChat Pay mandatory |
| **Japan** | Cards, convenience store (konbini), PayPay | Cards + konbini |
| **SEA** | GrabPay, GCash, bank transfers, cards | Local wallets per country |

### BNPL (Buy Now, Pay Later) Integration

| Provider | Markets | Integration | Split Model |
|----------|---------|-------------|-------------|
| **Klarna** | US, EU, UK, AU | Direct API or Stripe | Pay in 4, Pay in 30, Financing |
| **Affirm** | US, CA | Direct API or Stripe | Pay in 4, Monthly installments |
| **Afterpay/Clearpay** | US, AU, UK, NZ | Direct API or Stripe | Pay in 4 |
| **Sezzle** | US, CA | Direct API | Pay in 4 |

BNPL typically increases AOV by 20-30% and reduces cart abandonment. The merchant pays the BNPL fee (3-6% of transaction) but receives full payment upfront from the BNPL provider.

### Digital Wallet Implementation

```javascript
// Stripe Payment Request Button (supports Apple Pay + Google Pay with one integration)
const paymentRequest = stripe.paymentRequest({
  country: 'US',
  currency: 'usd',
  total: { label: 'My Store', amount: 4999 },
  requestPayerName: true,
  requestPayerEmail: true,
  requestShipping: true,
  shippingOptions: [
    { id: 'standard', label: 'Standard Shipping', amount: 599 },
    { id: 'express', label: 'Express Shipping', amount: 1299 },
  ],
});

// Check if Apple Pay / Google Pay is available
const canMakePayment = await paymentRequest.canMakePayment();
if (canMakePayment) {
  // Show the button
  const prButton = elements.create('paymentRequestButton', { paymentRequest });
  prButton.mount('#payment-request-button');
}
```

---

## 5. Recurring Payments & Subscriptions

### Subscription Billing Platforms

| Platform | Focus | Pricing | Best For |
|----------|-------|---------|---------|
| **Stripe Billing** | Integrated with Stripe | Included with Stripe (0.5% for Billing features) | Stripe-first businesses, simple subscriptions |
| **Recurly** | Subscription management | $0.10-0.19/transaction | Complex subscription logic, enterprise |
| **Chargebee** | Subscription + revenue ops | From $249/mo + per-transaction | Revenue operations, complex pricing models |
| **Paddle** | Merchant of Record | 5% + $0.50 | Global tax compliance, SaaS |
| **Lemon Squeezy** | Merchant of Record | 5% + $0.50 | Simple digital products, indie developers |

### Subscription Architecture

```sql
CREATE TABLE subscriptions (
  id              UUID PRIMARY KEY,
  customer_id     BIGINT REFERENCES customers(id),
  plan_id         BIGINT REFERENCES plans(id),
  status          VARCHAR(20) NOT NULL,
  -- active, trialing, past_due, paused, canceled, expired
  
  -- Billing cycle
  current_period_start  TIMESTAMPTZ,
  current_period_end    TIMESTAMPTZ,
  billing_interval      VARCHAR(10),   -- 'month', 'year', 'week'
  billing_interval_count INTEGER DEFAULT 1,
  
  -- Trial
  trial_start     TIMESTAMPTZ,
  trial_end       TIMESTAMPTZ,
  
  -- Payment
  payment_method_id VARCHAR(100),    -- Stripe PaymentMethod token
  
  -- Cancellation
  cancel_at_period_end BOOLEAN DEFAULT FALSE,
  canceled_at     TIMESTAMPTZ,
  cancellation_reason VARCHAR(255),
  
  -- Dunning
  past_due_since  TIMESTAMPTZ,
  retry_count     INTEGER DEFAULT 0,
  
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);
```

### Dunning Management (Failed Payment Recovery)

When a recurring payment fails (expired card, insufficient funds, bank decline):

```
Payment Failed
       │
       ├── Retry 1 (Day 1): Automatic retry, email "Payment failed — please update card"
       │
       ├── Retry 2 (Day 3): Second retry, email "Action required — update payment method"
       │
       ├── Retry 3 (Day 5): Third retry, email "Last attempt — your subscription will be paused"
       │
       ├── Retry 4 (Day 7): Final retry
       │     │
       │     ├── Success → resume subscription
       │     │
       │     └── Failure → pause/cancel subscription, email "Subscription paused"
       │
       └── Grace period: Keep access for 3-7 days after first failure (reduces involuntary churn)
```

Stripe Smart Retries uses ML to retry at optimal times (e.g., retry debit cards on payday). This alone recovers 11% of failed payments on average.

### SCA (Strong Customer Authentication) for EU Recurring Payments

PSD2/SCA requires two-factor authentication for EU card payments. For subscriptions:

1. **Initial payment**: SCA required — customer completes 3DS2 challenge
2. **Merchant-initiated transactions (MIT)**: Subsequent recurring charges can use a stored mandate — no SCA required if the initial payment was properly authenticated and the customer gave consent
3. **Customer-initiated changes**: If the customer changes plan/amount, SCA may be triggered again

Stripe handles most of this automatically with `off_session: true` on recurring charges.

---

## 6. Fraud Prevention

### Fraud Prevention Layers

```
Layer 1: Pre-Authorization Checks
  ├── Device fingerprinting (device age, bot detection)
  ├── Velocity checks (too many attempts from same IP/device/card)
  ├── Email/phone validation (disposable email detection)
  ├── Geolocation vs billing address mismatch
  └── Blocklist check (known fraudulent cards/emails/IPs)
       │
       ▼
Layer 2: Payment Authorization
  ├── AVS (Address Verification System) — match billing address
  ├── CVV check — ensures physical card possession
  ├── 3D Secure (3DS2) — issuing bank authentication
  └── Network token validation
       │
       ▼
Layer 3: Post-Authorization / Machine Learning
  ├── Stripe Radar / Adyen RevenueProtect
  ├── Third-party fraud scoring (Sift, Riskified, Signifyd, Forter)
  ├── Manual review queue (for flagged transactions)
  └── Rules engine (block orders matching fraud patterns)
       │
       ▼
Layer 4: Post-Order Monitoring
  ├── Shipping address change detection
  ├── Multiple orders with different cards, same shipping address
  └── Chargeback pattern detection
```

### Fraud Tool Comparison

| Tool | Model | Strengths | Pricing |
|------|-------|----------|---------|
| **Stripe Radar** | ML + rules, built into Stripe | Zero integration effort for Stripe users, good default protection | Included (basic), $0.07/screened (advanced) |
| **Sift** | ML platform, multi-product | Account protection + payment fraud + content trust | Per-decision pricing |
| **Riskified** | Guaranteed fraud protection | Chargeback guarantee — they pay if they approve a fraudulent order | Revenue share (higher %) |
| **Signifyd** | Guaranteed fraud protection | Similar to Riskified, strong in enterprise | Revenue share |
| **Forter** | ML-based, real-time | Low false-positive rate, good for high-value goods | Per-decision pricing |

**Recommendation for most businesses**: Start with Stripe Radar (included with Stripe). Add custom Radar rules as you learn your fraud patterns. Graduate to a dedicated fraud solution (Sift, Riskified) only when chargebacks exceed 0.5% or you're processing >$10M/year.

### 3D Secure (3DS2) Implementation

3DS2 adds an authentication step where the issuing bank verifies the cardholder's identity. Benefits:
- **Liability shift**: If a 3DS-authenticated transaction results in a chargeback, the liability shifts from merchant to issuing bank
- **Required in EU/UK** (PSD2/SCA regulation)
- **Optional elsewhere** but recommended for high-risk transactions

```javascript
// Stripe handles 3DS2 automatically with Payment Intents
const paymentIntent = await stripe.paymentIntents.create({
  amount: 5000,
  currency: 'usd',
  payment_method: 'pm_card_visa',
  confirmation_method: 'manual',
  confirm: true,
  return_url: 'https://yoursite.com/checkout/complete',
});

// If 3DS is required, paymentIntent.status will be 'requires_action'
// Frontend handles the challenge via stripe.js
```

---

## 7. Refunds & Disputes

### Refund Types

| Type | Description | Use Case |
|------|------------|----------|
| **Full refund** | Return entire payment | Complete return, order cancellation |
| **Partial refund** | Return portion of payment | Partial return, item quality issue, price adjustment |
| **Store credit** | Issue credit to customer account (not back to card) | Encourage repeat purchase, faster than card refund |
| **Exchange** | No refund — swap for different item | Size/color exchange |

### Refund Data Model

```sql
CREATE TABLE refunds (
  id              UUID PRIMARY KEY,
  order_id        UUID REFERENCES orders(id),
  payment_id      VARCHAR(100),       -- PSP payment reference
  type            VARCHAR(20),        -- 'full', 'partial', 'store_credit'
  amount          NUMERIC(12,2) NOT NULL,
  currency        CHAR(3),
  reason          VARCHAR(50),        -- 'customer_request', 'defective', 'not_as_described', 'duplicate'
  notes           TEXT,
  
  -- PSP refund tracking
  psp_refund_id   VARCHAR(100),       -- Stripe refund ID (re_xxx)
  psp_status      VARCHAR(20),        -- 'pending', 'succeeded', 'failed'
  
  -- Internal tracking
  status          VARCHAR(20) DEFAULT 'pending', -- pending, approved, processed, failed
  requested_by    BIGINT,             -- customer or admin user ID
  approved_by     BIGINT,             -- admin who approved
  
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  processed_at    TIMESTAMPTZ
);
```

### Chargeback (Dispute) Handling

```
Customer disputes charge with their bank
       │
       ▼
PSP notifies merchant (webhook: charge.dispute.created)
       │
       ├── 1. Pause fulfillment (if order hasn't shipped)
       │
       ├── 2. Gather evidence:
       │     - Order confirmation email
       │     - Shipping tracking + delivery confirmation
       │     - Customer communication history
       │     - IP address and device info
       │     - 3DS authentication proof
       │     - Terms of service / refund policy
       │     - Product description matching what was delivered
       │
       ├── 3. Submit evidence via PSP (Stripe: stripe.disputes.update)
       │     └── Deadline: typically 7-21 days from dispute creation
       │
       └── 4. Wait for bank decision (30-90 days)
              │
              ├── Won → funds returned to merchant
              └── Lost → funds kept by customer + chargeback fee ($15-25)
```

### Chargeback Prevention

- **Clear billing descriptor**: Customer sees "MYSTORE.COM" on their statement, not "STRIPE* 39XY2"
- **Proactive refunds**: If you know an order will be disputed, refund preemptively (no chargeback fee)
- **Alerts**: Verifi (Visa) and Ethoca (Mastercard) alert you before a dispute is filed — you can refund to prevent it
- **Delivery confirmation**: Always get tracking and delivery signatures for high-value orders
- **Clear return policy**: Display prominently during checkout and in confirmation emails

---

## 8. Multi-Currency & International

### Multi-Currency Payment Architecture

```
Customer (EUR region) browses store
       │
       ▼
Display prices in EUR (from EUR price list)
       │
       ▼
Checkout in EUR
       │
       ▼
Payment processed in EUR by PSP
       │
       ├── Stripe: Create PaymentIntent with currency: 'eur'
       │
       ▼
Settlement
       │
       ├── Option A: Settle in EUR → merchant's EUR bank account
       │     (no FX conversion, merchant manages multi-currency treasury)
       │
       └── Option B: Auto-convert to USD → merchant's USD account
           (PSP charges FX fee, typically 1-2%)
```

### Local Acquiring

For the best authorization rates, use a PSP that processes payments locally:
- US card, processed by US-based PSP entity → higher auth rate
- EU card, processed by EU-based PSP entity → higher auth rate (also required for SCA)

Stripe and Adyen automatically route to local entities when available. This is transparent to the merchant.

### Cross-Border Commerce Considerations

| Consideration | What to Do |
|--------------|-----------|
| **Currency display** | Show local currency, allow switching, show conversion disclaimer |
| **Payment methods** | Offer local payment methods per country (iDEAL for NL, UPI for India) |
| **Tax** | Calculate VAT/GST based on customer's country, register if required |
| **Duties and import fees** | For physical goods: DDP (delivered duty paid) vs DDU (delivered duty unpaid) |
| **Data residency** | Some countries require payment data to stay in-country (India, Russia) |
| **Sanctions screening** | Block transactions from sanctioned countries/individuals (OFAC, EU sanctions) |

### Duty and Import Fee Solutions

For cross-border physical goods:
- **Zonos**: Calculates duties, taxes, and fees at checkout (landed cost)
- **Global-e**: End-to-end cross-border solution (pricing, payments, shipping, duties)
- **Passport Shipping**: DDP shipping with duties calculated upfront

Showing the full landed cost at checkout (including duties) reduces cart abandonment for international orders. Unexpected import fees at delivery are the #1 reason for international order refusals.

---

## 9. Financial Reconciliation

### The Reconciliation Problem

Money flows through multiple systems:
```
Customer pays $100
  → PSP processes ($100)
  → PSP deducts fees ($100 - $3.20 = $96.80)
  → PSP batches payout ($96.80 lands in bank in 2 days)
  → Customer returns item → Refund $100
  → Next payout reduced by $100
  → Dispute filed → $15 fee deducted from next payout
```

Each of these movements must be reconciled against your orders.

### Ledger Pattern for E-Commerce

```sql
CREATE TABLE ledger_entries (
  id              UUID PRIMARY KEY,
  order_id        UUID REFERENCES orders(id),
  type            VARCHAR(30) NOT NULL,
  -- 'sale', 'refund', 'fee', 'payout', 'dispute', 'dispute_reversal', 'adjustment'
  
  amount          NUMERIC(12,2) NOT NULL,  -- positive for credits, negative for debits
  currency        CHAR(3) NOT NULL,
  
  -- Reference to external systems
  psp_reference   VARCHAR(100),     -- Stripe payment/refund/payout ID
  bank_reference  VARCHAR(100),     -- Bank transaction reference
  
  description     TEXT,
  metadata        JSONB DEFAULT '{}',
  
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Example entries for a typical order lifecycle:
-- Sale:       +$100.00  (order placed)
-- PSP Fee:     -$3.20   (Stripe processing fee)
-- Shipping:    -$5.00   (shipping cost)
-- COGS:       -$40.00   (cost of goods)
-- Net:        +$51.80   (gross margin)
```

### Automated Reconciliation

```
Daily Reconciliation Job
       │
       ├── 1. Fetch PSP payouts for yesterday
       │     └── Stripe: GET /v1/payouts?arrival_date=yesterday
       │
       ├── 2. Fetch payout transactions (balance transactions in payout)
       │     └── Stripe: GET /v1/balance_transactions?payout=po_xxx
       │
       ├── 3. Match each balance transaction to an order
       │     └── payment_intent → order (via stored payment_intent_id on order)
       │
       ├── 4. Identify discrepancies
       │     └── Orders with payments not in any payout
       │     └── Payout amounts that don't match order amounts (partial captures, refunds)
       │
       └── 5. Generate reconciliation report
              └── Matched: X orders, $Y amount
              └── Unmatched: N items requiring manual review
```

### Accounting Integration

| Accounting System | Integration Pattern |
|------------------|-------------------|
| **QuickBooks Online** | REST API — create invoices, payments, refunds |
| **Xero** | REST API — similar to QuickBooks |
| **NetSuite** | SuiteCloud APIs — enterprise ERP |
| **SAP** | IDoc/BAPI — complex enterprise integration |
| **Stripe Revenue Recognition** | Built into Stripe — automated revenue recognition (ASC 606) |

For most businesses: Use Stripe's built-in reporting + a connector to your accounting system (QuickBooks/Xero). Services like Synder or A2X automate this sync.

---

## 10. Payment Security Patterns

### Security Architecture

```
Customer Browser
  │
  │  HTTPS only (TLS 1.2+)
  │  CSP headers (restrict iframe sources)
  │  Subresource Integrity (SRI) on payment JS
  │
  ▼
Your Application (Payment page)
  │
  │  Hosted payment fields (Stripe Elements) — card data in PSP iframe
  │  No card data in your application logs
  │  No card data in error tracking (Sentry, Datadog)
  │  CSRF tokens on all payment endpoints
  │
  ▼
Your Backend
  │
  │  Webhook signature verification
  │  Idempotency keys on all payment operations
  │  Rate limiting on payment endpoints
  │  Amount validation (never trust client-side amounts)
  │  Audit logging (who did what, when)
  │
  ▼
PSP (Stripe / Adyen)
  │
  │  PCI Level 1 certified
  │  Card data encrypted at rest (AES-256)
  │  Network tokenization
  │  Fraud ML models
```

### Common Payment Security Mistakes

1. **Trusting client-side amounts**: Always recalculate order total server-side before creating PaymentIntent
2. **Logging card data**: Even partial card numbers in logs violate PCI. Mask everything except last 4.
3. **Storing CVV**: Never store CVV, even temporarily. It's a PCI violation.
4. **Missing webhook verification**: Without signature checking, anyone can fake payment confirmations
5. **No idempotency**: Network retries can cause double charges
6. **Hardcoded API keys**: Use environment variables, never commit Stripe secret keys to git
7. **Using test keys in production**: Use separate Stripe accounts for test vs production, or at minimum, environment-specific keys
8. **Missing rate limiting**: Attackers can use your checkout to validate stolen cards (card testing attacks)

### Card Testing Attack Prevention

Fraudsters use stolen card numbers and test them by making small purchases:

```
Detection signals:
- Many small transactions ($0.50-$1.00) in quick succession
- Different card numbers from same IP/device
- High decline rate from single source
- Card numbers entered sequentially (auto-generated)

Prevention:
- Rate limit payment attempts per IP (5/minute)
- Rate limit per email (3 payment attempts/hour)
- CAPTCHA on payment form after 2 failed attempts
- Block TOR exit nodes and known VPN IPs
- Enable Stripe Radar's card testing protection
- Minimum order amount ($5+)
```
