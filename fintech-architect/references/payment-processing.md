# Payment Processing Architecture — Deep Reference

**Always use `WebSearch` to verify PSP features, pricing, payment rail availability, and regulatory requirements before giving advice. Payment ecosystems evolve rapidly, vary by region, and regulatory deadlines shift frequently. Last verified: April 2026.**

## Table of Contents
1. [Payment Orchestration Layer](#1-payment-orchestration-layer)
2. [PSP Selection & Multi-PSP Strategy](#2-psp-selection--multi-psp-strategy)
3. [Authorization, Capture & Settlement Flows](#3-authorization-capture--settlement-flows)
4. [Webhook-Driven Payment Architecture](#4-webhook-driven-payment-architecture)
5. [Money Movement Rails](#5-money-movement-rails)
6. [Real-Time Payments](#6-real-time-payments)
7. [Open Banking & PSD2/PSD3 Payment Initiation](#7-open-banking--psd2psd3-payment-initiation)
8. [Payment Tokenization](#8-payment-tokenization)
9. [Recurring Payments & Subscription Billing](#9-recurring-payments--subscription-billing)
10. [Multi-Currency & Cross-Border Payments](#10-multi-currency--cross-border-payments)
11. [Payment Method Landscape](#11-payment-method-landscape)
12. [Smart Routing & Optimization](#12-smart-routing--optimization)
13. [Payment Idempotency & Reliability](#13-payment-idempotency--reliability)

---

## 1. Payment Orchestration Layer

A payment orchestration platform (POP) connects businesses to multiple PSPs, acquirers, and fraud tools through a single integration. At scale, this is how you optimize authorization rates, reduce costs, and add resilience.

### When to Introduce Orchestration

- **Don't need it yet**: Single PSP, <$10M annual processing, simple payment flows
- **Consider it**: Multi-PSP, $10M-$100M processing, regional PSP needs, authorization rate concerns
- **Essential**: $100M+ processing, global operations, complex routing rules, cost optimization mandate

### Platform Comparison

| Platform | Architecture | Key Strength | Best For | Pricing |
|----------|-------------|-------------|---------|---------|
| **Primer** | Unified API + no-code workflows | Visual workflow builder, no gateway-specific code | Mid-to-large merchants wanting flexibility | Per-transaction |
| **Spreedly** | Payment vault + multi-PSP routing | Portable vault (credentials stored independent of PSP), 120+ gateways | Marketplaces, platforms needing PSP portability | Per-transaction |
| **Gr4vy** | Dedicated cloud instance per merchant | Isolated infrastructure (not shared multi-tenant), strong security posture | Enterprises wanting infrastructure isolation | Per-transaction |
| **Custom** | Build your own | Full control, no vendor dependency | $1B+ processing with dedicated engineering team | Engineering cost |

### Orchestration Architecture

```
Customer Payment Request
       │
       ▼
┌─────────────────────┐
│ Payment Orchestrator │
│  - Routing engine    │
│  - Token vault       │
│  - Retry logic       │
│  - Fallback rules    │
└──────────┬──────────┘
           │
    ┌──────┼──────┬──────┐
    ▼      ▼      ▼      ▼
┌──────┐┌──────┐┌──────┐┌──────┐
│Stripe││Adyen ││ Local ││Backup│
│      ││      ││ PSP  ││ PSP  │
└──────┘└──────┘└──────┘└──────┘
```

### Custom Orchestration (When to Build Your Own)

Build custom when:
- You process $1B+ annually and the cost savings justify the engineering investment
- You need routing logic that no vendor supports (e.g., ML-based routing tied to your fraud models)
- Regulatory requirements demand full control of payment data flows

Key components to build:
1. **Router**: Decides which PSP handles each transaction
2. **Normalizer**: Translates between your internal format and each PSP's API
3. **Vault**: Stores payment credentials (PCI compliant)
4. **Retry engine**: Handles retries with backoff, failover to alternate PSPs
5. **Observability**: Latency, auth rates, error rates per PSP per route

---

## 2. PSP Selection & Multi-PSP Strategy

### PSP Comparison Matrix

| PSP | Pricing | Global Reach | Key Strength | Best For |
|-----|---------|-------------|-------------|---------|
| **Stripe** | 2.9% + $0.30 (blended) | 47+ countries | Best developer experience, huge ecosystem | Most businesses, developer-first teams |
| **Adyen** | IC++ | 100+ countries | Enterprise-grade, omnichannel, lowest fees at volume | Enterprise, high-volume, omnichannel |
| **Checkout.com** | IC++ | 150+ countries | Lowest rates at volume, strong EU/MENA | High-volume international merchants |
| **Mollie** | 1.8% + €0.25 (EU cards) | EU-focused | Simplest for European merchants | EU-based businesses |
| **Braintree** | 2.59% + $0.49 | 45+ countries | PayPal + Venmo integration | US-focused, PayPal merchants |
| **Square** | 2.9% + $0.30 | US, CA, UK, AU, JP, IE, FR, ES | POS + online unified | Small business, omnichannel |
| **Razorpay** | 2% | India | Dominant India PSP, UPI support | India-first businesses |
| **Mercado Pago** | Varies by country | LATAM | Dominant LATAM PSP, PIX, Boleto | LATAM-first businesses |

### IC++ vs Blended Pricing

**Blended (Stripe default)**: Fixed rate (2.9% + $0.30) regardless of card type. Simple, predictable, but you pay the same for a debit card (low interchange) as a premium rewards card (high interchange).

**IC++ (Interchange Plus Plus)**: Interchange fee (set by card networks, varies by card type) + PSP markup + scheme fee. More complex billing, but typically 15-30% cheaper at $500K+ annual volume.

**Decision point**: At ~$500K-$1M annual processing volume, negotiate IC++ pricing. Available from Adyen, Checkout.com, and Stripe (on request for larger merchants).

### Multi-PSP Strategy

| Processing Volume | Strategy | Rationale |
|------------------|----------|-----------|
| < $10M/year | Single PSP (Stripe) | Simplicity, no integration overhead |
| $10M-$100M | Primary + backup PSP | Failover, some cost optimization |
| $100M-$1B | 2-3 PSPs with orchestration | Route by region, card type, cost, auth rate |
| $1B+ | Multi-PSP with custom/advanced orchestration | Full optimization, dedicated routing ML |

---

## 3. Authorization, Capture & Settlement Flows

### The Card Payment Lifecycle

```
1. AUTHORIZATION (Auth)
   Merchant → Acquirer → Card Network → Issuing Bank
   "Can this card be charged $X?"
   Result: Approved / Declined / Requires Authentication (3DS)
   Funds "held" on customer's card (not yet charged)
       │
       ▼
2. CAPTURE
   Merchant tells PSP to capture authorized amount
   Can be: immediate, delayed (up to 7 days for most cards), or partial
   For physical goods: capture when order ships
   For digital goods or services: capture immediately
       │
       ▼
3. CLEARING
   Card network batches captured transactions
   Calculates interchange fees (issuer's share)
   Sends settlement instructions to banks
       │
       ▼
4. SETTLEMENT
   Acquiring bank deposits funds (minus fees) to merchant's bank account
   Timing: T+1 to T+3 depending on PSP and payout schedule
   Stripe: T+2 standard, T+1 or instant available
       │
       ▼
5. RECONCILIATION
   Match settlement deposits against transactions
   Verify fee calculations
   Handle refunds, chargebacks, adjustments
```

### Auth + Capture Patterns

| Pattern | When to Capture | Use Case |
|---------|----------------|----------|
| **Auth + immediate capture** | Instantly | Digital goods, services, in-stock items |
| **Auth + delayed capture** | When fulfilled | Physical goods, made-to-order, pre-orders |
| **Auth + partial capture** | Per shipment | Split shipments, partial fulfillment |
| **Incremental authorization** | Before final capture | Tips, variable amounts (gas, restaurants) |
| **Auth void** | Cancel before capture | Order cancellation (no fees charged) |

### Stripe Payment Intents Flow

```
Frontend                          Backend                         Stripe
   │                                │                              │
   │ 1. Start checkout              │                              │
   │───────────────────────────────▶│                              │
   │                                │ 2. Create PaymentIntent      │
   │                                │────────────────────────────▶│
   │                                │  {amount, currency,          │
   │                                │   capture_method: 'manual'}  │
   │                                │◀────────────────────────────│
   │ 3. Return client_secret        │                              │
   │◀───────────────────────────────│                              │
   │                                │                              │
   │ 4. Confirm (stripe.js)         │                              │
   │───────────────────────────────────────────────────────────────▶│
   │                                │                              │
   │ 5. 3DS challenge (if needed)   │                              │
   │◀──────────────────────────────────────────────────────────────│
   │ 6. Auth complete               │                              │
   │───────────────────────────────────────────────────────────────▶│
   │                                │                              │
   │                                │ 7. Webhook: authorized       │
   │                                │◀────────────────────────────│
   │                                │ 8. Create order, reserve inv │
   │                                │                              │
   │                                │ 9. Capture (at fulfillment)  │
   │                                │────────────────────────────▶│
```

---

## 4. Webhook-Driven Payment Architecture

**Critical principle**: Never rely on the frontend callback to confirm payment success. The customer's browser can close, lose connection, or crash. Webhooks are the source of truth for payment state.

### Webhook Processing Architecture

```
PSP (Stripe/Adyen)
       │
       │  POST /webhooks/payments
       │  (signed payload)
       ▼
┌────────────────────┐
│ Webhook Endpoint   │
│  1. Verify signature│
│  2. Check idempotency│
│  3. Parse event     │
│  4. Return 200 fast │
└─────────┬──────────┘
          │ (async)
          ▼
┌────────────────────┐
│ Event Processor    │
│  - Update order    │
│  - Post ledger     │
│  - Send notification│
│  - Trigger workflows│
└────────────────────┘
```

### Key Webhook Events

| Event | Action |
|-------|--------|
| `payment_intent.succeeded` | Create/confirm order, reserve inventory, post ledger entry |
| `payment_intent.payment_failed` | Notify customer, allow retry, log for fraud analysis |
| `payment_intent.canceled` | Release holds, update order status |
| `charge.captured` | Confirm capture, update ledger |
| `charge.refunded` | Process refund in ledger, update order, notify customer |
| `charge.dispute.created` | Freeze funds, gather evidence, alert operations |
| `charge.dispute.closed` | Process outcome (won/lost), update ledger |
| `payout.paid` | Record bank settlement, trigger reconciliation |
| `payout.failed` | Alert operations, investigate banking issue |

### Webhook Reliability

```python
# 1. Always verify signatures
event = stripe.Webhook.construct_event(payload, sig_header, WEBHOOK_SECRET)

# 2. Idempotency — skip already-processed events
if await redis.setnx(f"webhook:{event.id}", "processing"):
    await redis.expire(f"webhook:{event.id}", 7 * 86400)  # 7 days
    await process_event(event)
else:
    return {"status": "already_processed"}

# 3. Return 200 quickly — process asynchronously if heavy
# Stripe retries up to 3 days for non-2xx responses

# 4. Handle out-of-order delivery
# Events may arrive out of order (e.g., refund before capture webhook)
# Use event timestamps and state machines to handle gracefully
```

---

## 5. Money Movement Rails

### Rail Comparison

| Rail | Speed | Cost | Max Amount | Availability | Best For |
|------|-------|------|-----------|-------------|---------|
| **ACH** | 1-3 business days (Same-day ACH: same day) | $0.20-$1.50 | $1M (same-day) | US only | Payroll, vendor payments, recurring billing |
| **Wire (Fedwire)** | Same day (hours) | $15-$35 | Unlimited | US | High-value urgent transfers |
| **RTP (The Clearing House)** | Seconds (24/7/365) | $0.25-$1.00 | $1M | US (1000+ banks) | Instant disbursements, time-sensitive payments |
| **FedNow** | Seconds (24/7/365) | $0.01-$0.04 | $500K (default) | US (1,192+ institutions) | Low-cost instant payments |
| **SWIFT** | 1-5 business days | $15-$50 | Unlimited | Global | Cross-border high-value |
| **SEPA Credit Transfer** | 1 business day | €0.20-€0.50 | Unlimited | EU/EEA | EUR transfers within Europe |
| **SEPA Instant** | Seconds (24/7/365) | €0.20-€1.00 | €100K | EU/EEA | Instant EUR transfers |
| **PIX** | Seconds (24/7/365) | Free (individuals) | Unlimited | Brazil | All payments in Brazil |
| **UPI** | Seconds (24/7/365) | Free | ₹1 lakh (~$1.2K) | India | All payments in India |
| **Faster Payments** | Seconds (24/7/365) | Free-£0.30 | £1M | UK | UK instant payments |

### Dynamic Rail Selection

Modern payment systems choose the optimal rail per transaction based on speed, cost, and amount:

```python
def select_rail(transfer):
    # Urgent + high value → Wire
    if transfer.priority == 'urgent' and transfer.amount > 100_000_00:
        return 'wire'
    
    # Instant needed → RTP or FedNow
    if transfer.priority == 'instant':
        if transfer.amount <= 500_000_00:
            return 'fednow'  # Lower cost
        elif transfer.amount <= 1_000_000_00:
            return 'rtp'
        else:
            return 'wire'  # Only option for large instant
    
    # Standard → ACH (cheapest)
    if transfer.amount <= 1_000_000_00:
        if transfer.priority == 'same_day':
            return 'ach_same_day'
        return 'ach_standard'
    
    return 'wire'  # Fallback for large amounts
```

### ACH Architecture

```
Originator (You)
       │
       │  NACHA-format batch file
       ▼
Originating Depository Financial Institution (ODFI)
  (Your bank / banking partner)
       │
       │  Submits to ACH network
       ▼
ACH Operator (Federal Reserve / EPN)
       │
       │  Routes to receiving bank
       ▼
Receiving Depository Financial Institution (RDFI)
  (Recipient's bank)
       │
       │  Credits/debits recipient account
       ▼
Receiver (Recipient)
```

**ACH return codes to handle:**

| Code | Meaning | Action |
|------|---------|--------|
| R01 | Insufficient funds | Retry once, then notify customer |
| R02 | Account closed | Remove payment method, notify customer |
| R03 | No account / unable to locate | Verify account details |
| R04 | Invalid account number | Verify with customer |
| R10 | Customer advises not authorized | Fraud investigation |
| R29 | Corporate customer advises not authorized | Similar to R10 for businesses |

**Nacha fraud monitoring requirement (mid-2026)**: All non-consumer ACH participants must monitor for suspected fraud. Build this into your ACH processing pipeline.

---

## 6. Real-Time Payments

### FedNow Implementation

```python
# FedNow operates via ISO 20022 messaging (pacs.008 for credit transfers)
# Most fintechs access via their banking partner's API, not directly

class FedNowPayment:
    def initiate(self, payment):
        # Validate
        if payment.amount > 500_000_00:  # $500K default limit
            raise AmountExceedsLimit("FedNow limit is $500,000")
        
        # Submit via banking partner API
        result = self.bank_api.send_fednow(
            amount=payment.amount,
            currency='USD',
            sender_account=payment.from_account,
            receiver_routing=payment.to_routing_number,
            receiver_account=payment.to_account_number,
            reference=payment.idempotency_key,
        )
        
        # FedNow settles in seconds — webhook confirms
        return result
```

### Real-Time Payment Considerations

1. **Irrevocability**: Real-time payments are generally irrevocable once settled. Unlike ACH, there is no return window. This shifts fraud risk — you must validate before sending, not after.
2. **24/7 operations**: Your systems must handle transactions at 3am on Christmas Day. No batch windows.
3. **Liquidity management**: Real-time settlement means real-time liquidity changes. Monitor position continuously.
4. **Fraud risk**: Speed is the enemy of fraud detection. You have seconds, not hours, to decide. Pre-transaction screening is critical.

---

## 7. Open Banking & PSD2/PSD3 Payment Initiation

### PSD2: Current State

PSD2 established API-based connectivity between European banks and third-party providers:

- **AISP (Account Information Service Provider)**: Read-only access to bank account data (balances, transactions)
- **PISP (Payment Initiation Service Provider)**: Initiate payments directly from customer's bank account (bypassing card networks)

### PSD3/PSR: Coming 2026-2027

The provisional agreement (November 2025) introduces:

- **PSD3** (Directive): Licensing and supervision framework, needs local transposition
- **PSR** (Regulation): Directly applicable rules covering security, SCA, PSP obligations
- **Enforcement**: Banks must give clear reasons for declining PSP access; failure to meet API obligations is now enforceable with penalties
- **Enhanced SCA**: Adaptive, risk-sensitive authentication including biometrics
- **APP fraud liability**: Materially resets liability for authorized push payment fraud

### Account-to-Account (A2A) Payments

A2A payments bypass card networks entirely — customer pays directly from their bank account. Lower cost than cards (no interchange), but different user experience.

```
Customer → Selects "Pay by Bank" → Redirected to their bank → Authenticates → 
Bank initiates payment → Merchant receives confirmation → Funds settle (instant or same-day)
```

**Benefits**: No interchange fees (typically 0.1-0.5% vs 2-3% for cards), no chargebacks (bank-authenticated), instant settlement via SEPA Instant/Faster Payments

**Challenges**: No auth/capture separation (funds move immediately), limited refund mechanics, bank UX varies, not all banks have reliable APIs

---

## 8. Payment Tokenization

### Token Types

| Token Type | What It Is | Scope | Example |
|-----------|-----------|-------|---------|
| **PSP token** | PSP stores card data, returns a token | PSP-specific | Stripe `pm_card_visa` |
| **Network token** | Visa/Mastercard replaces PAN with token | Cross-PSP | Visa `tok_xxx` |
| **Device token** | Apple Pay / Google Pay tokenized card | Device-specific | DPAN in Secure Element |
| **Custom vault token** | Your own PCI-compliant vault | Your systems | UUID mapped to card data |

### Network Tokenization Benefits

Network tokens (Visa Token Service, Mastercard MDES) provide:
- **Automatic card updates**: When a card is reissued (new expiry, new number), the token automatically updates. No failed recurring charges.
- **Higher auth rates**: Network tokens see 2-5% improvement in authorization rates because they signal trusted relationships.
- **Lifecycle management**: Card networks manage token validity, reducing stale credential issues.

**2025-2026 trajectory**: Tokenized transactions projected to double from 283B (2025) to 574B (2029). Visa and Mastercard targeting near-universal token adoption by 2030.

### Tokenization Architecture

```
Customer's Browser
       │
       │  Card data entered into PSP's iframe (Stripe Elements, Adyen Drop-in)
       │  Card data NEVER touches your server
       ▼
PSP's Servers (PCI Level 1)
       │
       │  Card tokenized → PaymentMethod token returned
       │  PSP also requests network token from Visa/MC
       ▼
Your Backend
       │
       │  Receives only the token (pm_xxx), NOT card data
       │  Associates token with customer for future charges
       │  Your PCI scope: SAQ A or SAQ A-EP (minimal)
       ▼
PSP Vault
       │
       │  Stores: PAN → PSP token → Network token
       │  Card lifecycle management
       │  Automatic updates on reissuance
```

---

## 9. Recurring Payments & Subscription Billing

### Billing Platform Selection

| Platform | Focus | Pricing | Best For |
|----------|-------|---------|---------|
| **Stripe Billing** | Integrated with Stripe | 0.5% on Billing-specific features | Stripe-first, simple subscriptions |
| **Recurly** | Subscription management | $0.10-$0.19/transaction | Complex subscription logic, enterprise |
| **Chargebee** | Subscription + RevOps | From $249/mo + per-txn | Revenue operations, complex pricing |
| **Paddle** | Merchant of Record | 5% + $0.50 | Global tax compliance (SaaS) |
| **Lago** | Open-source billing | Free (self-hosted) | Usage-based billing, self-hosted control |
| **Orb** | Usage-based billing | Per-event pricing | Metered/usage billing at scale |

### Dunning Management (Failed Payment Recovery)

```
Payment Failed (expired card, insufficient funds, bank decline)
       │
       ├── Day 0: Automatic retry, email "Payment failed — update card"
       │
       ├── Day 3: Second retry (Stripe Smart Retries picks optimal time)
       │           Email "Action required — update payment method"
       │
       ├── Day 5: Third retry, email "Last chance before service interruption"
       │
       ├── Day 7: Final retry
       │     │
       │     ├── Success → resume, reset retry counter
       │     │
       │     └── Failure → downgrade/pause service
       │
       └── Grace period: 3-7 days of continued access after first failure
           (reduces involuntary churn by 15-25%)
```

**Stripe Smart Retries** use ML to retry at optimal times (e.g., retry debit cards on payday). Recovers ~11% of failed payments on average.

### SCA for Recurring Payments

PSD2/SCA requires two-factor authentication for EU card payments, but recurring charges work differently:

1. **Initial payment**: SCA required — customer completes 3DS2 challenge
2. **Subsequent charges (MIT — Merchant Initiated Transaction)**: Use stored mandate, no SCA required if initial auth was proper and customer consented
3. **Amount changes**: If subscription amount changes significantly, SCA may be re-triggered
4. Stripe handles this automatically with `off_session: true` on recurring charges

---

## 10. Multi-Currency & Cross-Border Payments

### Multi-Currency Processing Architecture

```
Customer (EUR) browses service → Prices displayed in EUR
       │
       ▼
Payment processed in EUR by PSP
       │
       ├── Option A: Settle in EUR → your EUR bank account
       │     (no FX, you manage multi-currency treasury)
       │
       └── Option B: Auto-convert to USD → your USD account
             (PSP charges FX fee: 1-2%)
```

### Local Acquiring

For best authorization rates, process payments through a local acquiring entity:
- EU card processed by EU acquirer → higher auth rate + SCA compliance
- US card processed by US acquirer → higher auth rate
- Stripe and Adyen automatically route to local entities (transparent to merchant)

### Cross-Border Payment Considerations

| Consideration | What to Do |
|--------------|-----------|
| **Currency display** | Show local currency, use GeoIP for default, allow switching |
| **Payment methods** | Offer local methods: iDEAL (NL), UPI (India), PIX (Brazil), Alipay (China) |
| **FX rates** | Use mid-market rate + transparent markup, or let PSP handle |
| **Data residency** | Some countries require payment data in-country (India, Russia, China) |
| **Sanctions** | Screen against OFAC, EU, UN sanctions lists before processing |
| **Regulatory** | Each country may have specific payment regulations and licensing requirements |

---

## 11. Payment Method Landscape

### Global Payment Method Share (2025-2026)

| Method | E-Commerce Share | POS Share | Growth Trend |
|--------|-----------------|-----------|-------------|
| **Digital wallets** (Apple Pay, Google Pay, etc.) | 56% | 33% | Growing rapidly |
| **Cards** (credit + debit) | 22% | 44% | Stable, declining share |
| **A2A / bank transfers** | 8% | 3% | Strong growth (open banking) |
| **BNPL** | 5% | 1% | 20% annual growth |
| **Cash** | 0% | 16% | Declining |
| **Crypto / stablecoins** | 1% | <1% | Growing (39% US merchant acceptance) |

### BNPL Integration

| Provider | Markets | Integration |
|----------|---------|-------------|
| **Klarna** | US, EU, UK, AU | Direct API or via Stripe/Adyen |
| **Affirm** | US, CA | Direct API or via Stripe |
| **Afterpay/Clearpay** | US, AU, UK, NZ | Direct API or via Stripe |
| **PayPal Pay Later** | US, UK, DE, FR, AU | Via PayPal/Braintree |

BNPL increases average order value by 20-30% and reduces cart abandonment. Merchant pays 3-6% fee but receives full payment upfront.

### Stablecoins for Payments (Emerging)

Stablecoins moved $33 trillion in 2025 — more than Visa and Mastercard combined. The Genius Act (signed July 2025) created a US regulatory framework.

**Use cases in fintech**:
- Cross-border settlement (faster, cheaper than SWIFT)
- Treasury management (yield on idle balances)
- Remittances (lower fees than traditional corridors)
- B2B payments (programmable money, instant settlement)

**Not yet suitable for**: Consumer checkout (UX friction, regulatory uncertainty in most jurisdictions)

---

## 12. Smart Routing & Optimization

### Routing Decision Factors

```python
def route_payment(payment, customer, merchant):
    candidates = get_available_psps(payment.currency, payment.method)
    
    scored = []
    for psp in candidates:
        score = 0
        
        # Authorization rate (historical, weighted heavily)
        auth_rate = get_auth_rate(psp, payment.card_bin, payment.currency)
        score += auth_rate * 40
        
        # Cost (interchange + PSP markup + scheme fees)
        cost = estimate_cost(psp, payment)
        score += (1 - cost / payment.amount) * 30
        
        # Local acquiring (prefer local entity)
        if psp.has_local_entity(payment.card_issuer_country):
            score += 15
        
        # Recent health (last-hour error rate)
        health = get_psp_health(psp)
        score += health * 15
        
        scored.append((psp, score))
    
    scored.sort(key=lambda x: x[1], reverse=True)
    return scored[0][0]  # Best scoring PSP
```

### PSP Health Monitoring

```python
# Track PSP health in real-time
class PSPHealthMonitor:
    def record(self, psp_id, success: bool, latency_ms: int):
        key = f"psp_health:{psp_id}:{current_minute()}"
        pipeline = redis.pipeline()
        pipeline.hincrby(key, 'total', 1)
        if success:
            pipeline.hincrby(key, 'success', 1)
        pipeline.hincrby(key, 'latency_sum', latency_ms)
        pipeline.expire(key, 3600)  # Keep 1 hour of data
        pipeline.execute()
    
    def get_health(self, psp_id, window_minutes=5):
        # Aggregate last N minutes
        total = success = latency_sum = 0
        for i in range(window_minutes):
            key = f"psp_health:{psp_id}:{minute_ago(i)}"
            data = redis.hgetall(key)
            total += int(data.get('total', 0))
            success += int(data.get('success', 0))
            latency_sum += int(data.get('latency_sum', 0))
        
        if total == 0:
            return 1.0  # No data, assume healthy
        
        success_rate = success / total
        avg_latency = latency_sum / total
        
        # Combine success rate and latency into health score
        latency_penalty = min(avg_latency / 5000, 0.5)  # Penalize >5s latency
        return max(success_rate - latency_penalty, 0)
```

### Cascade / Failover Pattern

```
Primary PSP attempt
       │
       ├── Success → done
       │
       └── Failure (timeout, 5xx, specific decline codes)
              │
              ▼
       Retry with backup PSP
              │
              ├── Success → done (log primary failure for monitoring)
              │
              └── Failure → return failure to customer
                    (don't cascade to 3rd PSP — diminishing returns + risk of
                     multiple auth holds on customer's card)
```

**Only cascade on recoverable failures**: network timeouts, PSP server errors, specific soft decline codes. Do NOT cascade on: insufficient funds, card blocked, 3DS failure, fraud blocks.

---

## 13. Payment Idempotency & Reliability

### Idempotency Keys

Every payment operation must be idempotent. Network retries, webhook redelivery, and user double-clicks must not cause duplicate charges.

```python
# Client-generated idempotency key (best practice)
payment_intent = stripe.PaymentIntent.create(
    amount=5000,
    currency="usd",
    idempotency_key=f"order_{order_id}_attempt_{attempt_num}",
)

# Server-side idempotency for webhooks
async def process_webhook(event):
    lock_key = f"webhook:{event.id}"
    
    # Atomic check-and-set
    acquired = await redis.set(lock_key, "processing", nx=True, ex=86400 * 7)
    if not acquired:
        return  # Already processed or in progress
    
    try:
        await handle_event(event)
        await redis.set(lock_key, "completed", xx=True, ex=86400 * 7)
    except Exception:
        await redis.delete(lock_key)  # Allow retry on failure
        raise
```

### At-Least-Once Delivery

Assume every asynchronous message (webhooks, events, queue messages) will be delivered at least once and potentially out of order. Design every handler to be:

1. **Idempotent**: Processing the same message twice has no additional effect
2. **Order-tolerant**: Handle events arriving out of sequence (use timestamps and state machines)
3. **Failure-safe**: If processing fails, the message will be retried (return non-2xx for webhooks)

### Payment State Machine

```
              ┌────────────────────────────────────┐
              │                                    │
              ▼                                    │
CREATED → PENDING_AUTH → AUTHORIZED → CAPTURED → SETTLED
              │               │          │
              │               │          └── PARTIALLY_REFUNDED → REFUNDED
              │               │
              │               └── VOIDED (auth cancelled before capture)
              │
              └── FAILED (auth declined)
              
DISPUTED (can happen at any settled state)
  ├── DISPUTE_WON → original state restored
  └── DISPUTE_LOST → funds deducted
```
