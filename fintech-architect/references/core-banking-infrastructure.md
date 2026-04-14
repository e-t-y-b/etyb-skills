# Core Banking & Financial Infrastructure — Deep Reference

**Always use `WebSearch` to verify platform features, pricing, licensing requirements, and partnership availability before giving advice. The BaaS and core banking space is evolving rapidly with frequent acquisitions, pivots, and regulatory changes. Last verified: April 2026.**

## Table of Contents
1. [Core Banking Platform Selection](#1-core-banking-platform-selection)
2. [Banking-as-a-Service (BaaS) Architecture](#2-banking-as-a-service-baas-architecture)
3. [Card Issuing Infrastructure](#3-card-issuing-infrastructure)
4. [Embedded Finance Patterns](#4-embedded-finance-patterns)
5. [Treasury & Cash Management](#5-treasury--cash-management)
6. [Virtual Accounts & Sub-Account Hierarchies](#6-virtual-accounts--sub-account-hierarchies)
7. [Money Movement Rail Integration](#7-money-movement-rail-integration)
8. [Multi-Tenancy for Fintech Platforms](#8-multi-tenancy-for-fintech-platforms)
9. [Sponsor Bank Relationships](#9-sponsor-bank-relationships)
10. [Wallet & Stored Value Systems](#10-wallet--stored-value-systems)

---

## 1. Core Banking Platform Selection

Core banking platforms are the foundational systems that manage accounts, transactions, and products for banks and bank-like institutions. The market is bifurcated between born-in-the-cloud platforms and cloud-available versions of traditional systems.

### Platform Comparison Matrix

| Platform | Architecture | Key Clients | Strengths | Best For |
|----------|-------------|------------|----------|---------|
| **Thought Machine Vault** | Cloud-native, zero legacy | JPMorgan Chase, Standard Chartered, Lloyds, SEB | Gartner Leader 2025, infinitely configurable via Smart Contracts (Python) | Tier 1 banks doing digital transformation, neobanks at scale |
| **Mambu** | SaaS, composable | N26, OakNorth, 200+ institutions in 65 countries | Fastest deployment, modular, acquired Numeral for ledger | Mid-market, rapid launch, lending-heavy |
| **10x Banking** | Cloud-native | Founded by ex-Barclays CEO | Built for both challengers and traditional bank transformation | Banks wanting modern architecture with banking DNA |
| **Temenos Transact** | Transitioning to cloud | 3,000+ banks globally | Largest install base, comprehensive functionality | Traditional banks, extensive product catalog |
| **Finxact (Fiserv)** | Cloud-native, API-first | Acquired by Fiserv (2022) | US market, Fiserv ecosystem integration | US banks wanting cloud-native with Fiserv backing |
| **Tuum** | Cloud-native, EU-based | European neobanks and embedded finance | Modular core with embedded finance focus | EU fintechs, embedded banking |

### Decision Framework

**Choose Thought Machine when:**
- You're a large bank doing digital transformation OR a well-funded neobank
- You need extreme configurability (Smart Contracts are Turing-complete in Python)
- Scale is critical — proven at tier-1 bank volume
- Budget for implementation complexity (6-18 month typical deployment)

**Choose Mambu when:**
- Speed-to-market is critical (weeks-months, not months-years)
- You're building a lending product (Mambu's core strength)
- You want SaaS simplicity (managed by Mambu, not self-hosted)
- Mid-market scale (200+ institutions proves the model)

**Choose 10x Banking when:**
- You want cloud-native architecture from people who understand banking
- You're a traditional bank that needs modern tech with banking domain expertise

**Choose BaaS (next section) when:**
- You're not a bank and don't want to become one
- You need banking capabilities embedded in your product
- Speed-to-market is more important than infrastructure control
- You don't have (or want) a banking license

### Build vs Buy Decision

| Factor | Build Custom | Core Banking Platform | BaaS |
|--------|-------------|---------------------|------|
| Time to market | 18-36 months | 6-18 months | 1-6 months |
| Engineering team | 20-50+ engineers | 5-15 engineers | 2-5 engineers |
| Regulatory compliance | Fully owned | Shared (platform + you) | Mostly sponsor bank |
| Customization | Unlimited | High (varies by platform) | Limited to BaaS API |
| Cost (first year) | $3M-$10M+ | $500K-$3M | $50K-$500K |
| Banking license needed | Yes | Yes (or sponsor bank) | No (sponsor bank provides) |
| Control | Full | High | Limited |

---

## 2. Banking-as-a-Service (BaaS) Architecture

BaaS enables non-bank companies to offer banking products (accounts, cards, payments) through APIs without obtaining their own banking license. The BaaS provider handles regulatory compliance through a partner/sponsor bank.

### BaaS Architecture Stack

```
Your Application (UI/UX, customer experience)
       │
       │  REST/GraphQL APIs
       ▼
BaaS Platform (API layer + orchestration)
       │
       │  Banking APIs: accounts, cards, payments, KYC
       ▼
Sponsor Bank (licensed entity, holds deposits)
       │
       │  Connected to banking infrastructure
       ▼
Banking Rails (ACH, RTP, FedNow, card networks)
```

### BaaS Platform Comparison

| Platform | Focus | Key Capabilities | Best For |
|----------|-------|-----------------|---------|
| **Unit** | US embedded banking | Accounts, cards, payments, lending, charge cards | US fintechs wanting comprehensive embedded banking |
| **Stripe Treasury** | Stripe ecosystem banking | Accounts, money movement, integrated with Stripe payments | Stripe merchants wanting to add banking features |
| **Treasury Prime** | Bank partnership network | Connects fintechs with multiple sponsor banks | Fintechs wanting choice of sponsor bank |
| **Column** | Developer-focused bank | Own bank charter + API, no middleware | Fintechs wanting direct bank relationship |
| **Synctera** | Banking compliance + API | End-to-end BaaS with compliance tooling | Fintechs needing strong compliance support |
| **Weavr** | EU embedded finance | EU-licensed EMI, accounts + cards | European embedded finance |
| **Railsr** (formerly Railsbank) | EU + UK | Multi-currency accounts, cards, compliance | UK/EU fintechs |
| **Griffin** | UK BaaS | UK bank license + API | UK embedded banking |

### BaaS Integration Architecture

```python
# Example: Creating a customer account via BaaS (Unit API pattern)

class BankingService:
    def __init__(self, baas_client):
        self.baas = baas_client
    
    async def create_customer_account(self, customer):
        # 1. Create customer in BaaS (triggers KYC)
        baas_customer = await self.baas.create_customer(
            first_name=customer.first_name,
            last_name=customer.last_name,
            email=customer.email,
            ssn=customer.ssn_encrypted,  # BaaS handles KYC
            date_of_birth=customer.dob,
            address=customer.address,
        )
        
        # 2. Wait for KYC approval (async — webhook or polling)
        # BaaS runs identity verification, sanctions screening, etc.
        
        # 3. Once approved, open deposit account
        account = await self.baas.create_deposit_account(
            customer_id=baas_customer.id,
            product_type='checking',
        )
        
        # 4. Issue debit card (optional)
        card = await self.baas.create_card(
            account_id=account.id,
            card_type='virtual',  # virtual or physical
        )
        
        return {
            'account_number': account.account_number,
            'routing_number': account.routing_number,
            'card': card,
        }
```

### BaaS Economics

| Revenue Source | Typical Range | Notes |
|--------------|--------------|-------|
| **Interchange** | 1.0-1.8% of card spend | Split between you, BaaS platform, and sponsor bank |
| **Float income** | Fed Funds Rate × average balance | Significant at scale with higher rates |
| **Transaction fees** | $0.25-$2.00 per ACH/wire | Pass-through or markup |
| **Subscription fees** | $0-$15/month per account | Your pricing to end customers |
| **FX spread** | 0.5-3% on conversions | Revenue on multi-currency products |

---

## 3. Card Issuing Infrastructure

### Card Issuing Platform Comparison

| Platform | Strengths | Architecture | Best For |
|----------|----------|-------------|---------|
| **Marqeta** | Market leader, $84B/quarter processed, 99.99% uptime | Traditional issuer processor, component in multi-vendor stack | Straightforward card programs, proven scale |
| **Lithic** | Ships in 3 weeks vs 3 months, developer-focused | API-first, minimal configuration | Speed-to-market, developer experience |
| **Highnote** | Unified: issuing + acquiring + credit + ledger | All-in-one platform, configurable building blocks | Reducing vendor sprawl, program innovation |
| **Galileo** (SoFi) | Large scale, established US player | API-based processing, card management | US market, SoFi ecosystem |
| **i2c** | Flexible, global reach | Configurable platform, supports complex programs | Complex card programs, global |

### Card Program Architecture

```
Your Application
       │
       │  Card management APIs
       ▼
Card Issuing Platform (Marqeta/Lithic/Highnote)
       │
       │  Authorization decisions, card lifecycle
       ▼
Card Network (Visa/Mastercard)
       │
       │  Routes transactions
       ▼
Sponsor Bank / Issuing Bank
       │
       │  Holds funds, regulatory compliance
       ▼
Cardholder
```

### Card Types

| Card Type | Funding | Use Case | Example |
|-----------|---------|----------|---------|
| **Debit** | Linked to deposit account | Consumer spending, neobank cards | Chime debit card |
| **Prepaid** | Pre-loaded balance | Gift cards, expense management, payroll | Corporate expense cards |
| **Credit** | Credit line | Consumer credit, BNPL | Fintech credit card |
| **Charge** | Must pay in full each cycle | Corporate cards, premium products | Corporate T&E |
| **Virtual** | Same as above, no physical card | Online-only, instant issuance, single-use | One-time purchase cards |

### Authorization Flow (Just-in-Time / JIT)

```
Cardholder taps/swipes at POS or enters card online
       │
       ▼
Card Network (Visa/Mastercard) routes to issuer processor
       │
       ▼
Issuing Platform receives authorization request
       │
       ├── JIT Funding (if configured):
       │     Your webhook receives auth request
       │     You decide: approve/decline
       │     Check balance, apply rules, fraud check
       │     Respond within 2 seconds
       │
       ├── Standard (pre-funded):
       │     Platform checks available balance
       │     Auto-approve if funds available
       │
       ▼
Response sent back through card network → merchant → cardholder
       (total round-trip: <3 seconds)
```

### JIT Funding Webhook

```python
# Your server receives authorization requests in real-time
@app.post("/webhooks/card-authorization")
async def handle_auth(request: AuthorizationRequest):
    # You have ~2 seconds to respond
    
    # 1. Check business rules
    account = await get_account(request.account_id)
    
    if account.status != 'active':
        return AuthResponse(approved=False, reason='account_inactive')
    
    if request.amount > account.available_balance:
        return AuthResponse(approved=False, reason='insufficient_funds')
    
    # 2. Apply custom rules (spend limits, merchant categories, etc.)
    if request.merchant_category_code in BLOCKED_CATEGORIES:
        return AuthResponse(approved=False, reason='category_blocked')
    
    if request.amount > account.single_transaction_limit:
        return AuthResponse(approved=False, reason='exceeds_limit')
    
    # 3. Fraud check (must be fast — sub-second)
    risk_score = await fast_fraud_check(request)
    if risk_score > 0.8:
        return AuthResponse(approved=False, reason='fraud_suspected')
    
    # 4. Approve and hold funds
    await hold_funds(account.id, request.amount, request.auth_id)
    
    return AuthResponse(approved=True)
```

---

## 4. Embedded Finance Patterns

Embedded finance integrates financial services directly into non-financial platforms — a SaaS tool offering lending, a marketplace offering instant payouts, a gig platform offering banking.

### Embedded Finance Architecture

```
Non-Financial Platform (SaaS, marketplace, gig platform)
       │
       │  Embeds financial features via APIs
       ▼
┌─────────────────────────────────────────────────┐
│ Financial Infrastructure Layer                   │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │ Payments │  │ Accounts │  │ Lending  │      │
│  │ (Stripe) │  │  (Unit)  │  │ (custom) │      │
│  └──────────┘  └──────────┘  └──────────┘      │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │  Cards   │  │  KYC/AML │  │ Treasury │      │
│  │(Marqeta) │  │ (Alloy)  │  │(ModernTr)│      │
│  └──────────┘  └──────────┘  └──────────┘      │
│                                                  │
└──────────────────────┬──────────────────────────┘
                       │
                       ▼
              Sponsor Bank(s)
```

### Common Embedded Finance Use Cases

| Use Case | What It Means | Example |
|----------|-------------|---------|
| **Embedded payments** | Accept payments within platform | Shopify payments, Toast restaurant payments |
| **Embedded accounts** | Banking accounts within platform | Lyft driver bank accounts, Shopify Balance |
| **Embedded lending** | Credit/loans within platform | Amazon lending to sellers, Shopify Capital |
| **Embedded insurance** | Insurance at point of need | Tesla insurance, travel booking insurance |
| **Embedded cards** | Branded cards for platform users | DoorDash Dasher card, Uber Pro card |

### Embedded B2B Payments

Projected at **$2.6T in 2026, $16T by 2030**. Key patterns:
- Accounts payable automation (pay suppliers from within procurement software)
- Invoice financing (offer early payment to suppliers for a fee)
- Virtual cards for B2B spending (controlled, trackable)
- Cross-border B2B payments (often the highest-friction area)

---

## 5. Treasury & Cash Management

### Treasury Architecture

```
┌─────────────────────────────────────────┐
│ Treasury Management System               │
│                                          │
│  Data Layer                              │
│  ├── Real-time account balances          │
│  ├── Pending transactions                │
│  ├── Cash flow projections               │
│  └── Position monitoring                 │
│                                          │
│  Intelligence Layer                      │
│  ├── Cash flow forecasting (AI/ML)       │
│  ├── Liquidity optimization              │
│  ├── FX exposure management              │
│  └── Interest rate optimization          │
│                                          │
│  Control Layer                           │
│  ├── Approval workflows                  │
│  ├── Segregation of duties               │
│  ├── Payment authorization limits        │
│  └── Audit trail                         │
│                                          │
│  Execution Layer                         │
│  ├── Payment initiation (multi-rail)     │
│  ├── FX execution                        │
│  ├── Investment management               │
│  └── Sweep accounts                      │
└─────────────────────────────────────────┘
```

### Cash Flow Forecasting

```python
class TreasuryForecaster:
    """Predict cash positions to optimize liquidity"""
    
    def forecast_position(self, account_id, days_ahead=30):
        current_balance = self.get_current_balance(account_id)
        
        # Known future movements
        scheduled_inflows = self.get_scheduled_inflows(account_id, days_ahead)
        scheduled_outflows = self.get_scheduled_outflows(account_id, days_ahead)
        
        # Predicted movements (ML model)
        predicted_inflows = self.ml_model.predict_inflows(account_id, days_ahead)
        predicted_outflows = self.ml_model.predict_outflows(account_id, days_ahead)
        
        daily_positions = []
        balance = current_balance
        
        for day in range(days_ahead):
            inflow = scheduled_inflows.get(day, 0) + predicted_inflows.get(day, 0)
            outflow = scheduled_outflows.get(day, 0) + predicted_outflows.get(day, 0)
            balance += inflow - outflow
            
            daily_positions.append({
                'date': today() + timedelta(days=day),
                'projected_balance': balance,
                'confidence': self.ml_model.confidence(day),  # decreases with time
                'alert': balance < self.minimum_balance_threshold,
            })
        
        return daily_positions
```

### Sweep Accounts

Automatically move excess funds between accounts to optimize yield or maintain minimum balances:

```
Operating Account (checking)
  Balance: $500K | Target: $200K-$300K
       │
       │  Excess ($200K-$300K) swept nightly
       ▼
Investment Account (money market / T-bills)
  Earns: Fed Funds Rate - spread
  
  If operating account drops below $200K:
  Reverse sweep → move funds back to operating
```

---

## 6. Virtual Accounts & Sub-Account Hierarchies

### Virtual Account Architecture

Virtual accounts are logical accounts that exist within a single physical bank account. They enable multi-tenant money management without opening separate bank accounts for each customer.

```
Physical Bank Account (master account at sponsor bank)
  └── Routing: 021000021 / Account: 123456789
       │
       ├── Virtual Account: VA-001 (Customer A)
       │     Balance: $15,000
       │     Virtual routing/account numbers for ACH receipt
       │
       ├── Virtual Account: VA-002 (Customer B)
       │     Balance: $8,500
       │
       ├── Virtual Account: VA-003 (Escrow for Deal XYZ)
       │     Balance: $100,000
       │     Release conditions: both parties approve
       │
       └── Virtual Account: VA-004 (Operating)
             Balance: $50,000
             Platform's own funds (fees collected, etc.)
```

### Use Cases

| Use Case | How Virtual Accounts Help |
|----------|-------------------------|
| **Customer wallets** | Each customer gets a virtual account with unique identifiers for receiving funds |
| **Escrow** | Hold funds in isolated virtual accounts with release conditions |
| **Sub-accounts** | Savings goals, expense categories, project-based accounting |
| **Merchant settlement** | Hold merchant funds separately before payout |
| **Payroll** | Segregate payroll funds from operating funds |

### FBO (For Benefit Of) Account Structure

Fintech companies typically custody customer funds in FBO accounts at partner banks:

```
FBO Account at Sponsor Bank
  "For Benefit Of [Your Fintech]'s Customers"
       │
       │  Total balance = sum of all customer balances
       │  FDIC pass-through insurance (up to $250K per customer)
       │
       ├── Your ledger tracks individual customer balances
       │     Customer A: $15,000
       │     Customer B: $8,500
       │     Customer C: $22,000
       │
       └── Reconciliation: Your ledger total MUST equal FBO account balance
           Any discrepancy = immediate investigation
```

---

## 7. Money Movement Rail Integration

### Multi-Rail Architecture

```
Payment Request
       │
       ▼
┌──────────────────────────┐
│ Money Movement Controller │
│                           │
│  1. Determine optimal rail│
│  2. Format for rail       │
│  3. Submit to bank/partner│
│  4. Track status          │
│  5. Handle returns/errors │
└──────────┬───────────────┘
           │
    ┌──────┼──────┬──────┬──────┐
    ▼      ▼      ▼      ▼      ▼
┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐
│ ACH  ││ Wire ││ RTP  ││FedNow││ SWIFT│
└──────┘└──────┘└──────┘└──────┘└──────┘
```

### Integration Options

| Approach | How | Pros | Cons |
|----------|-----|------|------|
| **Direct bank API** | Connect to your sponsor bank's API | Lowest cost, most control | Single bank dependency, complex integration |
| **Money movement platform** (Modern Treasury, Moov) | Unified API for multiple rails | Multi-rail via single integration, managed compliance | Platform fees, less control |
| **BaaS platform** | Included in BaaS offering (Unit, Column) | Part of broader banking package | Limited to BaaS provider's supported rails |

### Modern Treasury Integration Pattern

```python
# Modern Treasury provides a unified API for multiple payment rails

class MoneyMovementService:
    def __init__(self, mt_client):
        self.mt = mt_client
    
    async def send_payment(self, payment):
        # 1. Create counterparty (recipient's bank details)
        counterparty = await self.mt.create_counterparty(
            name=payment.recipient_name,
            accounts=[{
                'account_number': payment.recipient_account,
                'routing_number': payment.recipient_routing,
                'account_type': 'checking',
            }]
        )
        
        # 2. Create payment order (Modern Treasury selects rail or you specify)
        order = await self.mt.create_payment_order(
            type=payment.rail,  # 'ach', 'wire', 'rtp'
            direction='credit',
            amount=payment.amount,
            currency='USD',
            originating_account_id=self.operating_account_id,
            receiving_account_id=counterparty.accounts[0].id,
            description=payment.description,
            metadata={'internal_id': payment.id},
        )
        
        # 3. Track via webhooks
        # Modern Treasury sends webhooks for status changes:
        # pending → processing → sent → completed
        # or: pending → processing → returned (with return code)
        
        return order
```

### SWIFT Integration (Cross-Border)

For international wire transfers:

```
Your System → Sponsor Bank → SWIFT Network → Correspondent Bank → Beneficiary Bank → Recipient

Key fields (MT103 / ISO 20022 pacs.008):
  - Ordering customer (sender)
  - Beneficiary (recipient)
  - Intermediary bank (correspondent)
  - Amount + currency
  - Purpose/reference
  - Charges instruction (SHA/BEN/OUR)
```

**ISO 20022 migration**: SWIFT is migrating from MT messages to ISO 20022 format. This provides richer, structured data and better straight-through processing. Most banks are in the coexistence phase (supporting both formats).

---

## 8. Multi-Tenancy for Fintech Platforms

### The Multi-Tenancy Challenge

Core banking systems were designed for single-tenant use (the bank). Fintech platforms — especially BaaS providers and embedded finance platforms — need to support multiple tenants (fintech programs) within the same infrastructure.

### Multi-Tenancy Models

| Model | Isolation | Cost | Complexity | Best For |
|-------|----------|------|-----------|---------|
| **Shared schema** | Low (row-level) | Lowest | Low | Small tenants, non-regulated |
| **Schema per tenant** | Medium | Medium | Medium | Mid-market, moderate regulation |
| **Database per tenant** | High | Higher | High | Regulated tenants needing strong isolation |
| **Infrastructure per tenant** | Highest | Highest | Highest | Enterprise, highest regulatory requirements |

### Tenant Hierarchy

```
Platform (BaaS Provider)
  └── Bank Partner (Sponsor Bank)
       ├── Tenant A (Fintech Program)
       │     ├── Sub-tenant A1 (Merchant/Customer segment)
       │     └── Sub-tenant A2
       └── Tenant B (Another Fintech Program)
             └── Sub-tenant B1
```

### Data Isolation Architecture

```sql
-- Row-level security for tenant isolation (PostgreSQL)

-- All financial tables include tenant_id
CREATE TABLE accounts (
  id          UUID PRIMARY KEY,
  tenant_id   UUID NOT NULL REFERENCES tenants(id),
  -- ... account fields
);

-- Row-level security policy
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON accounts
  USING (tenant_id = current_setting('app.current_tenant_id')::uuid);

-- Application sets tenant context per request
-- SET app.current_tenant_id = 'tenant-uuid-here';
-- All subsequent queries automatically filtered
```

### Per-Tenant Configuration

```python
# Each tenant gets its own configuration for:
class TenantConfig:
    tenant_id: str
    
    # API access
    api_keys: list[APIKey]
    webhook_urls: dict[str, str]  # event → URL
    
    # Product configuration
    account_types: list[AccountType]  # which account products are enabled
    card_programs: list[CardProgram]  # card configurations
    fee_schedule: FeeSchedule         # transaction fees, monthly fees
    
    # Limits
    transaction_limits: TransactionLimits
    daily_limits: DailyLimits
    
    # Compliance
    kyc_provider: str                 # which KYC vendor to use
    risk_rules: list[RiskRule]        # custom fraud/risk rules
    
    # Branding
    card_art: str                     # card design
    notification_templates: dict      # email/SMS templates
```

---

## 9. Sponsor Bank Relationships

### How Sponsor Bank Partnerships Work

```
Your Fintech                    Sponsor Bank
┌─────────────────┐            ┌─────────────────┐
│ Build product    │            │ Provide license  │
│ Customer-facing  │◀──────────▶│ Hold deposits    │
│ KYC enrollment   │   API +    │ Regulatory       │
│ Transaction logic│   Contract │   oversight      │
│ Fraud monitoring │            │ Bank Secrecy Act │
│ Customer support │            │ Examination      │
└─────────────────┘            └─────────────────┘
```

### Key Terms in Sponsor Bank Agreements

| Term | What It Means | Typical Range |
|------|-------------|---------------|
| **Revenue share** | Split of interchange, float, fees | 50-80% to fintech (varies by volume) |
| **Minimum commitment** | Guaranteed annual payment to bank | $50K-$500K/year |
| **Compliance requirements** | Your obligations for AML/KYC/BSA | Varies — bank dictates standards |
| **Audit rights** | Bank can audit your operations | Annual or ad-hoc |
| **Termination clause** | Notice period and unwinding | 90-180 days typical |
| **Program oversight** | Bank reviews your product changes | Approval needed for new features |

### Choosing a Sponsor Bank

| Factor | What to Evaluate |
|--------|-----------------|
| **Risk appetite** | Does the bank support your business model? (crypto, lending, cannabis?) |
| **Technology** | Quality of APIs, webhook reliability, sandbox availability |
| **Speed** | How fast can they onboard new programs? |
| **Regulatory history** | Any consent orders or enforcement actions? |
| **Scale capacity** | Can they handle your growth? |
| **Geographic coverage** | Do they support your target markets? |

### Regulatory Risk

The OCC and FDIC have increased scrutiny of sponsor bank / fintech partnerships. Banks are responsible for their fintech partners' compliance. If a fintech partner causes issues:
- Bank faces regulatory action (consent orders, fines)
- Bank may terminate the fintech relationship
- Customer funds remain protected (FDIC insurance via FBO)

**Impact on fintechs**: Due diligence from sponsor banks is intensifying. Expect longer onboarding, more compliance requirements, and more oversight. Build compliance into your DNA — it's your ticket to maintaining sponsor bank relationships.

---

## 10. Wallet & Stored Value Systems

### Wallet Types

| Type | How It Works | Regulatory | Example |
|------|-------------|-----------|---------|
| **Pass-through wallet** | Facilitates payments but doesn't hold funds | Lower regulation | PayPal (basic), Google Pay |
| **Stored value wallet** | Holds customer balance (prefunded) | Money transmission license or bank partnership | Venmo balance, Cash App |
| **Custodial wallet** | Holds assets on behalf of user (crypto) | Varies by jurisdiction | Coinbase custodial, Kraken |
| **Non-custodial wallet** | User controls private keys | Generally less regulated | MetaMask, hardware wallets |

### Wallet Architecture

```sql
-- Wallet data model
CREATE TABLE wallets (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id     UUID NOT NULL REFERENCES customers(id),
  type            VARCHAR(20) NOT NULL,    -- 'fiat', 'crypto', 'rewards'
  currency        CHAR(3) NOT NULL,
  
  -- Balance (managed by ledger — this is denormalized)
  available       BIGINT NOT NULL DEFAULT 0,  -- spendable balance
  held            BIGINT NOT NULL DEFAULT 0,  -- funds on hold (pending txns, disputes)
  pending         BIGINT NOT NULL DEFAULT 0,  -- incoming funds not yet settled
  
  -- The source of truth is the ledger, not these columns
  -- These are denormalized for fast reads
  ledger_account_id UUID NOT NULL REFERENCES accounts(id),
  
  -- Limits
  daily_send_limit     BIGINT,
  monthly_send_limit   BIGINT,
  max_balance          BIGINT,
  
  -- Status
  status          VARCHAR(20) NOT NULL DEFAULT 'active',
  kyc_tier        VARCHAR(20) NOT NULL DEFAULT 'unverified',
  
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- KYC tier determines limits
-- Tier 1 (email only): $500 balance, $250/day send
-- Tier 2 (ID verified): $10,000 balance, $2,500/day send  
-- Tier 3 (full KYC): $50,000 balance, $10,000/day send
```

### P2P Transfer Flow

```
Sender initiates transfer
       │
       ├── 1. Validate
       │     - Sender wallet active?
       │     - Sufficient available balance?
       │     - Within daily/monthly limits?
       │     - Receiver wallet active and can receive?
       │
       ├── 2. Compliance checks
       │     - Sanctions screening on receiver
       │     - Transaction monitoring (AML rules)
       │     - Velocity checks
       │
       ├── 3. Execute (atomic ledger operation)
       │     Debit:  Sender wallet account    $50.00
       │     Credit: Receiver wallet account  $50.00
       │     (Optional fee entry if platform charges)
       │
       ├── 4. Notify
       │     - Push notification to sender (confirmation)
       │     - Push notification to receiver (money received)
       │     - Email receipts to both
       │
       └── 5. Record
             - Transaction record with full audit trail
             - Compliance log entry
             - Analytics event
```

### Wallet Funding and Withdrawal

```
Funding (money in):
  ├── Bank transfer (ACH pull) → pending for 3-5 days → available
  ├── Debit card (instant) → available immediately (higher fee)
  ├── Another wallet (P2P) → available immediately
  └── Direct deposit (payroll) → available on payday

Withdrawal (money out):
  ├── Bank transfer (ACH push) → 1-3 business days → free
  ├── Instant transfer (RTP/debit push) → seconds → fee ($0.25-$1.75)
  ├── Card withdrawal (ATM via issued card) → instant → ATM fees
  └── Check (mail) → 7-10 days → rare, legacy
```

### Regulatory Considerations for Wallets

| Jurisdiction | Stored Value Regulation | Key Requirement |
|-------------|------------------------|----------------|
| **US** | Money transmission licenses (state-by-state) | License in each state OR sponsor bank partnership |
| **EU** | E-Money Directive (EMD2) / PSD2 | E-Money Institution license or exemption |
| **UK** | E-Money Regulations 2011 | FCA authorization as EMI |
| **India** | Prepaid Payment Instruments (PPI) | RBI PPI license |
| **Brazil** | Payment Institution regulation | BACEN authorization |

**Safeguarding requirements**: Customer funds in stored-value wallets must be safeguarded (held in trust, segregated accounts, or insured). This is a regulatory requirement in most jurisdictions — mixing customer funds with operating funds is a serious violation.
