# Ledger Systems Architecture — Deep Reference

**Always use `WebSearch` to verify ledger platform features, pricing, and API capabilities before giving advice. The ledger-as-a-service space is evolving rapidly with frequent acquisitions and new entrants. Last verified: April 2026.**

## Table of Contents
1. [Double-Entry Bookkeeping Fundamentals](#1-double-entry-bookkeeping-fundamentals)
2. [Chart of Accounts Design](#2-chart-of-accounts-design)
3. [Ledger Data Model](#3-ledger-data-model)
4. [Event-Sourced Ledger Architecture](#4-event-sourced-ledger-architecture)
5. [CQRS for Financial Data](#5-cqrs-for-financial-data)
6. [Balance Computation Strategies](#6-balance-computation-strategies)
7. [Multi-Currency Ledger Design](#7-multi-currency-ledger-design)
8. [Concurrency Control & Double-Spend Prevention](#8-concurrency-control--double-spend-prevention)
9. [Reconciliation Architecture](#9-reconciliation-architecture)
10. [Ledger-as-a-Service Platform Selection](#10-ledger-as-a-service-platform-selection)
11. [PostgreSQL-Based Ledger Implementation](#11-postgresql-based-ledger-implementation)
12. [Ledger Performance & Scaling](#12-ledger-performance--scaling)

---

## 1. Double-Entry Bookkeeping Fundamentals

Every money movement in a financial system must be recorded as two equal and opposite entries — a debit in one account and a credit in another. This is non-negotiable. Single-entry systems (just tracking balances) will fail audits, make reconciliation impossible, and hide errors.

### Core Principles

1. **Conservation of money**: For every entry, `sum(debits) = sum(credits)`. The ledger must always balance.
2. **Immutability**: Once a journal entry is posted, it is never modified or deleted. Corrections are made by posting new compensating (reversing) entries.
3. **Completeness**: Every money movement — no matter how small — must be recorded. This includes fees, interest, FX conversions, holds, and reversals.
4. **Traceability**: Every entry links back to the business event that caused it (payment, refund, transfer, fee assessment).

### The Five Account Types

| Account Type | Normal Balance | Debit Effect | Credit Effect | Examples |
|-------------|---------------|-------------|--------------|---------|
| **Asset** | Debit | Increase | Decrease | Cash, bank accounts, receivables, held funds |
| **Liability** | Credit | Decrease | Increase | Customer balances, payables, deposits held |
| **Equity** | Credit | Decrease | Increase | Owner's equity, retained earnings |
| **Revenue** | Credit | Decrease | Increase | Transaction fees, interest income, subscription revenue |
| **Expense** | Debit | Increase | Decrease | PSP fees, interchange costs, operational costs |

### Journal Entry Examples

**Customer deposits $100 via ACH:**
```
Debit:  Asset:Bank:Operating       $100.00    (our bank account increases)
Credit: Liability:Customer:12345   $100.00    (we owe the customer $100)
```

**Customer sends $50 to another customer (P2P transfer):**
```
Debit:  Liability:Customer:12345   $50.00     (sender's balance decreases)
Credit: Liability:Customer:67890   $50.00     (receiver's balance increases)
```

**Platform charges $2.50 transaction fee:**
```
Debit:  Liability:Customer:12345   $2.50      (customer's balance decreases)
Credit: Revenue:TransactionFees    $2.50      (platform earns revenue)
```

**Reversing an incorrect fee:**
```
Debit:  Revenue:TransactionFees    $2.50      (reverse the revenue)
Credit: Liability:Customer:12345   $2.50      (restore customer's balance)
Metadata: reversal_of=entry_id_xxx, reason="duplicate fee assessment"
```

### Metadata as First-Class Data

Attach rich metadata to every journal entry. This is your safety net for audits, disputes, and investigations:

- **Reference ID**: Link to the originating business event (payment ID, transfer ID)
- **Effective date**: When the transaction economically occurred (may differ from posting date)
- **Posted date**: When the entry was recorded in the ledger
- **Actor**: Who or what initiated the transaction (user ID, system process, API key)
- **Reason code**: Standardized reason for the entry (deposit, withdrawal, fee, reversal, adjustment)
- **Reversal reference**: If this is a reversal, link to the original entry
- **External references**: PSP transaction ID, bank reference number, settlement batch ID

---

## 2. Chart of Accounts Design

The chart of accounts (CoA) is the hierarchical structure of all accounts in your ledger. Design it for your business model — a payment processor has different accounts than a neobank.

### Account Hierarchy Patterns

**Flat structure** (simple, startup):
```
Assets:Bank:Operating
Assets:Bank:Reserve
Liability:Customer:{customer_id}
Revenue:TransactionFees
Revenue:InterestIncome
Expense:PSPFees
Expense:BankFees
```

**Hierarchical structure** (growth, multiple products):
```
Assets
  ├── Bank
  │   ├── Operating:USD
  │   ├── Operating:EUR
  │   ├── Reserve:USD
  │   └── FBO:{bank_partner}     (For Benefit Of — customer funds held at partner bank)
  ├── Receivables
  │   ├── PSPSettlement:Stripe
  │   └── PSPSettlement:Adyen
  └── Clearing
      ├── PendingACH
      └── PendingWire

Liabilities
  ├── Customer:{customer_id}
  │   ├── Available
  │   ├── Held                   (funds on hold — disputes, pending verification)
  │   └── PendingDeposit         (ACH deposits not yet settled)
  ├── Escrow:{escrow_id}
  └── Payables
      ├── VendorPayments
      └── TaxWithholding

Revenue
  ├── TransactionFees
  │   ├── DomesticTransfers
  │   ├── InternationalTransfers
  │   └── CardPayments
  ├── InterestIncome
  ├── SubscriptionFees
  └── FXSpread

Expenses
  ├── PSPFees
  │   ├── Stripe
  │   └── Adyen
  ├── BankFees
  │   ├── ACH
  │   ├── Wire
  │   └── RTP
  ├── FraudLosses
  └── ChargebackCosts
```

### Account Properties

```sql
CREATE TABLE accounts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code            VARCHAR(100) UNIQUE NOT NULL,   -- e.g., 'liability:customer:12345:available'
  name            VARCHAR(255) NOT NULL,
  type            VARCHAR(20) NOT NULL,           -- asset, liability, equity, revenue, expense
  normal_balance  VARCHAR(6) NOT NULL,            -- debit, credit
  currency        CHAR(3) NOT NULL,               -- ISO 4217
  parent_id       UUID REFERENCES accounts(id),
  
  -- Balance tracking
  balance         BIGINT NOT NULL DEFAULT 0,      -- in smallest currency unit (cents)
  version         BIGINT NOT NULL DEFAULT 0,      -- optimistic locking
  
  -- Metadata
  is_system       BOOLEAN DEFAULT FALSE,          -- system accounts vs customer accounts
  is_active       BOOLEAN DEFAULT TRUE,
  metadata        JSONB DEFAULT '{}',
  
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);
```

### Sub-Ledgers

For high-volume systems, separate customer accounts into sub-ledgers that roll up to control accounts in the general ledger. This keeps the general ledger manageable while supporting millions of individual customer accounts.

```
General Ledger:  Liability:CustomerFunds (control account, aggregate balance)
                      │
Sub-Ledger:     ┌─────┼─────┐
                │     │     │
             Cust1  Cust2  Cust3  (individual customer accounts)
```

---

## 3. Ledger Data Model

### Core Schema

```sql
-- Journal entries (the atomic unit of the ledger)
CREATE TABLE journal_entries (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Business context
  reference_type  VARCHAR(50) NOT NULL,     -- 'payment', 'transfer', 'fee', 'reversal', 'adjustment'
  reference_id    UUID NOT NULL,            -- ID of the business event
  description     TEXT,
  
  -- Timing
  effective_date  DATE NOT NULL,            -- when the transaction economically occurred
  posted_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Idempotency
  idempotency_key VARCHAR(255) UNIQUE,      -- prevents duplicate entries
  
  -- Audit
  created_by      VARCHAR(100) NOT NULL,    -- user ID, API key, or system process
  metadata        JSONB DEFAULT '{}',
  
  -- Status
  status          VARCHAR(20) NOT NULL DEFAULT 'posted',  -- posted, reversed
  reversed_by     UUID REFERENCES journal_entries(id),
  reversal_of     UUID REFERENCES journal_entries(id)
);

-- Ledger entries (individual debit/credit lines within a journal entry)
CREATE TABLE ledger_entries (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journal_entry_id UUID NOT NULL REFERENCES journal_entries(id),
  
  account_id      UUID NOT NULL REFERENCES accounts(id),
  direction       VARCHAR(6) NOT NULL,      -- 'debit' or 'credit'
  amount          BIGINT NOT NULL CHECK (amount > 0),  -- always positive, direction indicates debit/credit
  currency        CHAR(3) NOT NULL,
  
  -- Denormalized balance snapshot (for audit trail)
  balance_before  BIGINT NOT NULL,
  balance_after   BIGINT NOT NULL,
  account_version BIGINT NOT NULL,          -- version of account at time of posting
  
  posted_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enforce double-entry constraint via database trigger or application logic
-- sum(debit amounts) = sum(credit amounts) for every journal_entry_id

CREATE INDEX idx_ledger_entries_account ON ledger_entries(account_id, posted_at);
CREATE INDEX idx_ledger_entries_journal ON ledger_entries(journal_entry_id);
CREATE INDEX idx_journal_entries_reference ON journal_entries(reference_type, reference_id);
CREATE INDEX idx_journal_entries_effective ON journal_entries(effective_date);
```

### Enforcing the Double-Entry Constraint

```sql
-- Option 1: Database trigger (enforced at DB level)
CREATE OR REPLACE FUNCTION check_double_entry()
RETURNS TRIGGER AS $$
DECLARE
  debit_sum BIGINT;
  credit_sum BIGINT;
BEGIN
  SELECT 
    COALESCE(SUM(CASE WHEN direction = 'debit' THEN amount END), 0),
    COALESCE(SUM(CASE WHEN direction = 'credit' THEN amount END), 0)
  INTO debit_sum, credit_sum
  FROM ledger_entries
  WHERE journal_entry_id = NEW.journal_entry_id;
  
  -- Only check when all entries for this journal are inserted
  -- (use a deferred constraint trigger or check at commit)
  IF debit_sum != credit_sum THEN
    RAISE EXCEPTION 'Double-entry violation: debits (%) != credits (%)', debit_sum, credit_sum;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

```python
# Option 2: Application-level enforcement (more common in practice)
def post_journal_entry(entries: list[LedgerEntry], reference: Reference) -> JournalEntry:
    # Validate double-entry before touching the database
    debit_total = sum(e.amount for e in entries if e.direction == 'debit')
    credit_total = sum(e.amount for e in entries if e.direction == 'credit')
    
    if debit_total != credit_total:
        raise DoubleEntryViolation(f"Debits ({debit_total}) != Credits ({credit_total})")
    
    if debit_total == 0:
        raise EmptyJournalEntry("Journal entry must have at least one debit and one credit")
    
    # All entries posted in a single database transaction
    with db.transaction():
        journal = JournalEntry.create(
            reference_type=reference.type,
            reference_id=reference.id,
            idempotency_key=reference.idempotency_key,
        )
        
        for entry in entries:
            account = Account.select_for_update(entry.account_id)  # lock the account row
            
            balance_before = account.balance
            if entry.direction == 'debit':
                if account.normal_balance == 'debit':
                    account.balance += entry.amount
                else:
                    account.balance -= entry.amount
            else:  # credit
                if account.normal_balance == 'credit':
                    account.balance += entry.amount
                else:
                    account.balance -= entry.amount
            
            LedgerEntry.create(
                journal_entry_id=journal.id,
                account_id=entry.account_id,
                direction=entry.direction,
                amount=entry.amount,
                currency=entry.currency,
                balance_before=balance_before,
                balance_after=account.balance,
                account_version=account.version + 1,
            )
            
            account.version += 1
            account.save()
        
        return journal
```

---

## 4. Event-Sourced Ledger Architecture

Event sourcing treats every state change as an immutable event. The current balance is not a field you update — it is the result of replaying a sequence of events. This is a natural fit for financial ledgers because immutability and auditability are requirements, not nice-to-haves.

### Why Event Sourcing for Ledgers

- **Complete audit trail by default**: Past entries are never erased. Regulators love this.
- **Temporal queries**: Reconstruct any account balance at any point in time (critical for end-of-day reporting, regulatory snapshots, dispute resolution).
- **Debugging**: When balances don't match, replay events to find exactly where things diverged.
- **Compliance cost reduction**: Institutions implementing event sourcing report ~28% reduction in compliance-related costs with 41% improvement in data integrity.

### Event Types

```
AccountCreated          { account_id, type, currency, metadata }
FundsDeposited          { account_id, amount, currency, source, reference_id }
FundsWithdrawn          { account_id, amount, currency, destination, reference_id }
FundsTransferred        { from_account_id, to_account_id, amount, currency, reference_id }
FundsHeld               { account_id, amount, currency, hold_id, reason, expires_at }
HoldReleased            { account_id, hold_id, amount }
HoldCaptured            { account_id, hold_id, amount, journal_entry_id }
FeeAssessed             { account_id, amount, currency, fee_type, reference_id }
InterestAccrued         { account_id, amount, currency, rate, period }
AdjustmentPosted        { account_id, amount, currency, direction, reason, authorized_by }
AccountFrozen           { account_id, reason, frozen_by }
AccountClosed           { account_id, final_balance, closed_by }
```

### Event Store Design

```sql
CREATE TABLE ledger_events (
  id              BIGSERIAL PRIMARY KEY,
  event_type      VARCHAR(50) NOT NULL,
  aggregate_id    UUID NOT NULL,           -- account ID (the aggregate root)
  aggregate_version BIGINT NOT NULL,       -- monotonically increasing per aggregate
  
  -- Event payload
  data            JSONB NOT NULL,
  
  -- Metadata
  correlation_id  UUID NOT NULL,           -- groups related events (e.g., a transfer creates 2 events)
  causation_id    UUID,                    -- the event that caused this event
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by      VARCHAR(100) NOT NULL,
  
  -- Uniqueness constraint prevents duplicate events for same aggregate version
  UNIQUE(aggregate_id, aggregate_version)
);

CREATE INDEX idx_events_aggregate ON ledger_events(aggregate_id, aggregate_version);
CREATE INDEX idx_events_correlation ON ledger_events(correlation_id);
CREATE INDEX idx_events_type_time ON ledger_events(event_type, created_at);
```

### Projections (Read Models)

Event sourcing separates the write model (event store) from read models (projections). Build projections for specific query patterns:

```
Event Store                          Projections
┌─────────────────┐     ┌──────────────────────────────────┐
│ FundsDeposited   │────▶│ Account Balance (current balance) │
│ FundsWithdrawn   │────▶│ Transaction History (paginated)   │
│ FundsTransferred │────▶│ Daily Summary (end-of-day)        │
│ FeeAssessed      │────▶│ Revenue Report (fee totals)       │
│ ...              │────▶│ Compliance Report (SAR triggers)  │
└─────────────────┘     └──────────────────────────────────┘
```

---

## 5. CQRS for Financial Data

CQRS (Command Query Responsibility Segregation) separates write and read paths, allowing each to be optimized independently. This is particularly valuable for financial systems where the write path demands strict consistency while the read path needs fast, flexible queries.

### Write Path (Commands)

Optimized for **consistency, durability, and correctness**:
- Validate business rules (sufficient balance, account status, limits)
- Enforce double-entry constraints
- Write to the primary database in a single ACID transaction
- Publish domain events after successful commit

### Read Path (Queries)

Optimized for **query performance and flexibility**:
- Denormalized views for common queries (account balance, transaction history)
- Materialized views for reporting (daily summaries, compliance reports)
- Separate read replicas or dedicated analytics databases
- Caching for frequently accessed data (current balances)

### CQRS Implementation Pattern

```
Commands (Writes)                    Queries (Reads)
┌────────────────┐                  ┌────────────────┐
│ PostTransfer   │                  │ GetBalance     │
│ AssessFee      │                  │ ListTxns       │
│ HoldFunds      │                  │ DailyReport    │
│ ReverseEntry   │                  │ SearchEntries  │
└───────┬────────┘                  └───────┬────────┘
        │                                   │
        ▼                                   ▼
┌────────────────┐  events    ┌────────────────┐
│ Primary DB     │──────────▶│ Read Replicas  │
│ (PostgreSQL)   │            │ + Projections  │
│ Strong consist.│            │ + Cache (Redis)│
└────────────────┘            └────────────────┘
```

### Eventual Consistency Considerations

The read model may lag behind the write model by milliseconds to seconds. For financial systems, this is acceptable for most queries but NOT for balance checks before debits. For critical operations:

```python
# Balance check for debit: ALWAYS read from primary (write) database
async def check_balance_for_debit(account_id: str, amount: int) -> bool:
    # Read from primary, not replica
    account = await primary_db.get_account(account_id, for_update=True)
    return account.available_balance >= amount

# Transaction history display: OK to read from replica (slight lag is fine)
async def get_transaction_history(account_id: str, page: int) -> list:
    return await read_replica.get_transactions(account_id, page=page, limit=50)
```

---

## 6. Balance Computation Strategies

### Strategy 1: Running Balance (Denormalized Cache)

Store the current balance directly on the account record. Update it with every transaction.

**Pros**: Fast reads (O(1) for current balance), simple queries
**Cons**: Requires careful concurrency control, balance can drift from entries if bugs occur

```sql
-- The account table has a balance column that's updated with every transaction
UPDATE accounts 
SET balance = balance - 5000, version = version + 1
WHERE id = 'acct_123' AND version = 42;  -- optimistic lock
```

### Strategy 2: Computed Balance (Aggregated)

Calculate the balance by summing all ledger entries for an account.

**Pros**: Balance is always correct (derived from source of truth), trivial to audit
**Cons**: Slow for accounts with many entries (O(n)), expensive at scale

```sql
-- Compute balance from entries (the source of truth)
SELECT 
  SUM(CASE WHEN direction = 'credit' AND a.normal_balance = 'credit' THEN amount
           WHEN direction = 'debit' AND a.normal_balance = 'debit' THEN amount
           ELSE -amount END) as balance
FROM ledger_entries le
JOIN accounts a ON le.account_id = a.id
WHERE le.account_id = 'acct_123';
```

### Strategy 3: Hybrid (Recommended for Production)

Store both the running balance (for fast reads) and validate it against the computed balance (the source of truth). This is what most production fintech systems use.

```python
# The running balance is a denormalized cache. The sum of entries is ground truth.
# Periodically verify:

async def verify_account_balance(account_id: str):
    account = await db.get_account(account_id)
    computed = await db.compute_balance_from_entries(account_id)
    
    if account.balance != computed:
        logger.critical(
            "Balance mismatch detected",
            account_id=account_id,
            cached_balance=account.balance,
            computed_balance=computed,
            delta=account.balance - computed,
        )
        # Alert operations team — do NOT auto-correct
        # This needs human investigation
        await alert_operations("BALANCE_MISMATCH", account_id=account_id)
```

### Balance Snapshots for Historical Queries

For point-in-time balance queries (required for regulatory reporting), take periodic snapshots:

```sql
CREATE TABLE balance_snapshots (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id      UUID NOT NULL REFERENCES accounts(id),
  balance         BIGINT NOT NULL,
  snapshot_type   VARCHAR(20) NOT NULL,  -- 'end_of_day', 'end_of_month', 'regulatory'
  snapshot_date   DATE NOT NULL,
  computed_from   BIGINT NOT NULL,       -- last ledger_entry ID included
  
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(account_id, snapshot_type, snapshot_date)
);

-- To get balance at a past date:
-- 1. Find the nearest snapshot before the target date
-- 2. Replay entries from snapshot to target date
-- Much faster than replaying from the beginning
```

---

## 7. Multi-Currency Ledger Design

### Golden Rule: Store Amounts as Integers

Never use floating-point for money. Use the smallest currency unit (cents for USD, pence for GBP, yen for JPY — which has no minor unit).

```python
# WRONG: floating point
price = 19.99  # This is 19.989999999999998... in IEEE 754

# RIGHT: integer (smallest currency unit)
price_cents = 1999  # Unambiguous
```

### Currency Precision Table

| Currency | ISO 4217 | Minor Unit | Multiplier | Example |
|----------|----------|-----------|-----------|---------|
| USD | 840 | Cent | 100 | $19.99 → 1999 |
| EUR | 978 | Cent | 100 | €19.99 → 1999 |
| GBP | 826 | Penny | 100 | £19.99 → 1999 |
| JPY | 392 | (none) | 1 | ¥1999 → 1999 |
| BHD | 48 | Fils | 1000 | 19.999 BHD → 19999 |
| BTC | (crypto) | Satoshi | 100000000 | 0.00019999 BTC → 19999 |

### Multi-Currency Account Structure

**Option 1: One account per currency** (recommended for most cases)
```
Liability:Customer:12345:USD
Liability:Customer:12345:EUR
Liability:Customer:12345:GBP
```
Simple, no FX confusion. Customer holds separate balances per currency.

**Option 2: Multi-currency account with sub-balances** (complex, use only if needed)
```
Liability:Customer:12345
  ├── balance_usd: 10000
  ├── balance_eur: 8500
  └── balance_gbp: 7200
```

### FX Conversion Entries

When converting between currencies, create explicit journal entries that capture the exchange rate:

```
Customer converts $100 USD → EUR at rate 1 USD = 0.92 EUR:

Debit:  Liability:Customer:12345:USD    $100.00   (USD balance decreases)
Credit: Asset:FXClearing:USD            $100.00   (clearing account receives USD)

Debit:  Asset:FXClearing:EUR            €92.00    (clearing account sends EUR)
Credit: Liability:Customer:12345:EUR    €92.00    (EUR balance increases)

Metadata: fx_rate=0.92, fx_provider="wise", fx_quote_id="qt_xxx"
```

If the platform takes an FX spread:
```
FX spread: market rate 0.925, customer rate 0.920, spread = $0.50 on $100:

Additional entry:
Debit:  Asset:FXClearing:EUR            €0.50     (difference stays in clearing)
Credit: Revenue:FXSpread                €0.50     (platform earns spread revenue)
```

---

## 8. Concurrency Control & Double-Spend Prevention

Financial systems face extreme concurrency challenges. Two requests to spend the same funds can arrive simultaneously. The system must guarantee that only one succeeds.

### Layered Defense Architecture

```
Layer 1: API-Level Idempotency Keys
  └── Client includes unique key per operation
  └── Server rejects duplicate keys (same key + different params = error)

Layer 2: Optimistic Locking (preferred for most cases)
  └── Account has version column
  └── UPDATE WHERE version = expected_version
  └── On conflict: retry with exponential backoff

Layer 3: Pessimistic Locking (for high-contention accounts)
  └── SELECT ... FOR UPDATE locks the account row
  └── Guarantees exclusive access during transaction
  └── Use sparingly — creates bottlenecks

Layer 4: Distributed Locks (for multi-service architectures)
  └── Redis SETNX or database advisory locks
  └── Acquire lock → check balance → transfer → release lock
  └── Always set TTL to prevent deadlocks
```

### Optimistic Locking Implementation

```sql
-- Transfer $50 from Account A to Account B
BEGIN;

-- Read both accounts
SELECT id, balance, version FROM accounts WHERE id IN ('acct_a', 'acct_b') FOR UPDATE;
-- acct_a: balance=10000, version=42
-- acct_b: balance=5000, version=17

-- Validate
-- Is acct_a.balance >= 5000? Yes.

-- Debit sender
UPDATE accounts 
SET balance = balance - 5000, version = version + 1, updated_at = NOW()
WHERE id = 'acct_a' AND version = 42;
-- If 0 rows updated → concurrent modification → ROLLBACK and retry

-- Credit receiver
UPDATE accounts 
SET balance = balance + 5000, version = version + 1, updated_at = NOW()
WHERE id = 'acct_b' AND version = 17;

-- Create ledger entries
INSERT INTO journal_entries (...) VALUES (...);
INSERT INTO ledger_entries (...) VALUES (...), (...);

COMMIT;
```

### Retry Strategy

```python
MAX_RETRIES = 3

async def transfer_with_retry(from_id, to_id, amount, idempotency_key):
    for attempt in range(MAX_RETRIES):
        try:
            return await execute_transfer(from_id, to_id, amount, idempotency_key)
        except OptimisticLockError:
            if attempt == MAX_RETRIES - 1:
                raise TransferFailed("Max retries exceeded — high contention")
            # Exponential backoff with jitter
            wait = (2 ** attempt) + random.uniform(0, 0.1)
            await asyncio.sleep(wait)
```

### Hot Account Problem

Some accounts (treasury, fee collection) receive thousands of transactions per second. They become bottlenecks with row-level locking.

**Solutions:**
1. **Sharded sub-accounts**: Split hot account into N sub-accounts, distribute writes randomly, aggregate for reads
2. **Batch posting**: Accumulate entries in a buffer, post in batches every N seconds
3. **TigerBeetle**: Purpose-built for this — handles 8,189 transfers per batch with zero locks

---

## 9. Reconciliation Architecture

Reconciliation verifies that your internal records match external systems. In fintech, you reconcile against banks, PSPs, card networks, and partner systems.

### Types of Reconciliation

| Type | What It Reconciles | Frequency | Tolerance |
|------|-------------------|-----------|-----------|
| **Internal** | Ledger debits vs credits, control vs sub-ledger | Real-time or hourly | Zero (must balance exactly) |
| **Bank** | Your ledger vs bank statements | Daily | Near-zero (timing differences OK) |
| **PSP** | Your ledger vs PSP settlement reports | Daily | Near-zero (fee discrepancies flagged) |
| **Card Network** | Your records vs Visa/MC settlement files | Daily | Per-transaction matching |
| **Partner** | Your records vs partner/merchant records | Daily or weekly | Configurable threshold |

### Automated Reconciliation Pipeline

```
┌──────────────┐     ┌───────────────┐     ┌──────────────┐
│ Fetch External│────▶│ Match & Compare│────▶│ Report &     │
│ Data Sources  │     │ Records       │     │ Escalate     │
└──────────────┘     └───────────────┘     └──────────────┘
       │                     │                     │
  Bank statements       1:1 matching          Matched items
  PSP settlements       Fuzzy matching        Unmatched items
  Network files         Amount tolerance      Discrepancies
  Partner reports       Date windowing        Auto-resolve rules
```

### Matching Strategies

```python
# Three-way match: Your ledger entry ↔ PSP record ↔ Bank settlement
class ReconciliationEngine:
    def match_records(self, internal, external):
        matched = []
        unmatched_internal = []
        unmatched_external = list(external)
        
        for record in internal:
            match = self.find_match(record, unmatched_external)
            if match:
                matched.append((record, match))
                unmatched_external.remove(match)
            else:
                unmatched_internal.append(record)
        
        return matched, unmatched_internal, unmatched_external
    
    def find_match(self, internal, candidates):
        # Match by external reference ID (exact)
        for c in candidates:
            if internal.external_ref == c.reference_id:
                if abs(internal.amount - c.amount) <= self.tolerance:
                    return c
        
        # Fuzzy match by amount + date window (fallback)
        for c in candidates:
            if (internal.amount == c.amount and
                abs((internal.date - c.date).days) <= 2):
                return c
        
        return None
```

### Reconciliation Breaks

When records don't match, classify the break and route it:

| Break Type | Common Cause | Resolution |
|-----------|-------------|-----------|
| **Missing internal** | Webhook missed, processing error | Reprocess from PSP records |
| **Missing external** | PSP hasn't settled yet, timing | Wait and re-reconcile next day |
| **Amount mismatch** | Fee discrepancy, partial capture, FX rounding | Investigate and post adjustment entry |
| **Status mismatch** | Refund processed but not reflected | Verify with PSP and update status |

---

## 10. Ledger-as-a-Service Platform Selection

### Platform Comparison Matrix

| Platform | Type | Key Strength | Best For | Pricing Model |
|----------|------|-------------|---------|---------------|
| **Modern Treasury** | Proprietary SaaS | Full pipeline: ledger + money movement + compliance | Companies wanting one vendor for ledger + payments | Per-transaction |
| **Formance** | Open-source (Apache 2.0) | Programmable ledger with Numscript DSL | Teams wanting self-hosted control + customization | Free (self-hosted) or managed |
| **TigerBeetle** | Open-source database | Extreme throughput (1000x traditional DBs) | High-throughput systems needing raw performance | Free (self-hosted) |
| **Fragment** | Proprietary API | GraphQL-based with visual fund flow designer | Visual thinkers, teams wanting quick setup | Per-transaction |
| **Blnk Finance** | Open-source (Apache 2.0) | Production-grade with auto-reconciliation | Teams wanting open-source with batteries included | Free (self-hosted) |
| **Moov** | Open-source (Apache 2.0) | Full-stack: ledger + ACH + wires + RTP + OFAC | Teams wanting open-source financial infrastructure | Free (self-hosted) or managed |

### Decision Framework

**Choose Modern Treasury when:**
- You want a single vendor for ledger + money movement
- You don't have deep ledger expertise on the team
- You're OK with per-transaction pricing
- You need bank connectivity out of the box

**Choose Formance when:**
- You want full control (self-hosted)
- You have complex financial logic that benefits from Numscript programmability
- Open-source matters (Apache 2.0)
- You have engineering capacity to deploy and operate

**Choose TigerBeetle when:**
- Raw throughput is your primary concern (thousands of transfers/second)
- You're building a high-frequency system (payment processor, exchange)
- You're comfortable with a purpose-built database (not general-purpose)
- You can build your own application logic on top

**Choose building custom (PostgreSQL) when:**
- Your requirements are well-understood and relatively simple
- You have strong database engineering on the team
- You want zero vendor dependency
- Your transaction volume doesn't require TigerBeetle-level throughput

### Consolidation Watch

The ledger space is consolidating: ProcessOut was acquired by Checkout.com, Numeral by Mambu, Modern Treasury acquired Beam, WePay shut down. Always use `WebSearch` to verify a platform is still actively maintained and independently operated before committing.

---

## 11. PostgreSQL-Based Ledger Implementation

For teams building custom, PostgreSQL is the most common choice. It offers ACID transactions, strong consistency, and excellent tooling.

### The pgledger Pattern

Inspired by production PostgreSQL ledger implementations:

```sql
-- Accounts with optimistic locking
CREATE TABLE accounts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code            VARCHAR(255) UNIQUE NOT NULL,
  name            VARCHAR(255) NOT NULL,
  type            VARCHAR(20) NOT NULL CHECK (type IN ('asset','liability','equity','revenue','expense')),
  normal_balance  VARCHAR(6) NOT NULL CHECK (normal_balance IN ('debit','credit')),
  currency        CHAR(3) NOT NULL,
  balance         BIGINT NOT NULL DEFAULT 0,
  version         BIGINT NOT NULL DEFAULT 0,
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  metadata        JSONB DEFAULT '{}',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Journal entries (immutable)
CREATE TABLE journal_entries (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  idempotency_key VARCHAR(255) UNIQUE NOT NULL,
  reference_type  VARCHAR(50) NOT NULL,
  reference_id    UUID NOT NULL,
  effective_date  DATE NOT NULL,
  description     TEXT,
  metadata        JSONB DEFAULT '{}',
  posted_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by      VARCHAR(100) NOT NULL
);

-- Ledger lines (immutable, linked to journal entries)
CREATE TABLE ledger_lines (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journal_entry_id UUID NOT NULL REFERENCES journal_entries(id),
  account_id      UUID NOT NULL REFERENCES accounts(id),
  direction       VARCHAR(6) NOT NULL CHECK (direction IN ('debit','credit')),
  amount          BIGINT NOT NULL CHECK (amount > 0),
  currency        CHAR(3) NOT NULL,
  balance_before  BIGINT NOT NULL,
  balance_after   BIGINT NOT NULL,
  account_version BIGINT NOT NULL,
  posted_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Prevent modification of posted entries
CREATE RULE prevent_update_journal AS ON UPDATE TO journal_entries DO INSTEAD NOTHING;
CREATE RULE prevent_delete_journal AS ON DELETE FROM journal_entries DO INSTEAD NOTHING;
CREATE RULE prevent_update_ledger AS ON UPDATE TO ledger_lines DO INSTEAD NOTHING;
CREATE RULE prevent_delete_ledger AS ON DELETE FROM ledger_lines DO INSTEAD NOTHING;
```

### Key Implementation Notes

1. **All ledger operations execute within the same DB transaction as application logic** — atomic commit/rollback
2. **Version field enables optimistic locking** — retry on conflict, not block
3. **balance_before and balance_after on each line** provide a built-in audit trail
4. **Immutability rules at the database level** prevent accidental modification even if application code has bugs
5. **Idempotency key on journal entries** prevents duplicate postings from retries or webhook redelivery

---

## 12. Ledger Performance & Scaling

### Scaling Strategies

| Strategy | When to Use | Complexity |
|----------|-----------|-----------|
| **Vertical scaling** | First option, PostgreSQL handles millions of accounts well | Low |
| **Read replicas** | Read-heavy workloads (reporting, dashboards) | Low |
| **Connection pooling (PgBouncer)** | Many application instances connecting | Low |
| **Partitioning** | Tables with billions of rows (partition ledger_lines by month) | Medium |
| **Sharding by account** | Extreme write throughput, millions of TPS | High |
| **TigerBeetle** | Purpose-built for extreme throughput | Medium (different paradigm) |

### Partitioning Ledger Lines

```sql
-- Partition by month for efficient querying and archival
CREATE TABLE ledger_lines (
  id UUID NOT NULL DEFAULT gen_random_uuid(),
  journal_entry_id UUID NOT NULL,
  account_id UUID NOT NULL,
  direction VARCHAR(6) NOT NULL,
  amount BIGINT NOT NULL,
  currency CHAR(3) NOT NULL,
  balance_before BIGINT NOT NULL,
  balance_after BIGINT NOT NULL,
  account_version BIGINT NOT NULL,
  posted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
) PARTITION BY RANGE (posted_at);

-- Create monthly partitions
CREATE TABLE ledger_lines_2026_01 PARTITION OF ledger_lines
  FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE ledger_lines_2026_02 PARTITION OF ledger_lines
  FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
-- ... automated via pg_partman or cron job
```

### Performance Benchmarks (Reference Points)

| System | Throughput | Latency | Notes |
|--------|-----------|---------|-------|
| PostgreSQL (single node, optimized) | 5,000-10,000 TPS | 1-5ms | Good enough for most fintechs |
| PostgreSQL (partitioned, read replicas) | 10,000-50,000 TPS | 1-10ms | Handles growth stage |
| TigerBeetle | 1,000,000+ TPS | <1ms | Purpose-built, zero locks |
| Custom event-sourced (Kafka + PostgreSQL) | 50,000-200,000 TPS | 5-50ms | Complex but flexible |

These are approximate and depend heavily on hardware, schema design, and query patterns. Always benchmark your specific workload.
