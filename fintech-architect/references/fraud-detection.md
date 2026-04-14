# Fraud Detection Architecture — Deep Reference

**Always use `WebSearch` to verify fraud platform features, pricing, and capabilities before giving advice. Fraud patterns evolve rapidly, and new attack vectors emerge constantly. The tools and techniques described here should be validated against current threat intelligence. Last verified: April 2026.**

## Table of Contents
1. [Fraud Detection Architecture Overview](#1-fraud-detection-architecture-overview)
2. [Rule Engines vs ML-Based Detection](#2-rule-engines-vs-ml-based-detection)
3. [Real-Time Transaction Scoring](#3-real-time-transaction-scoring)
4. [Behavioral Biometrics](#4-behavioral-biometrics)
5. [Device Fingerprinting](#5-device-fingerprinting)
6. [Account Takeover Prevention](#6-account-takeover-prevention)
7. [Velocity Checks & Rate Limiting](#7-velocity-checks--rate-limiting)
8. [Network & Graph Analysis](#8-network--graph-analysis)
9. [Fraud Platform Selection](#9-fraud-platform-selection)
10. [Synthetic Identity Fraud](#10-synthetic-identity-fraud)
11. [Authorized Push Payment (APP) Fraud](#11-authorized-push-payment-app-fraud)
12. [Chargeback Management](#12-chargeback-management)
13. [Card Testing Attack Prevention](#13-card-testing-attack-prevention)
14. [Fraud Detection by Vertical](#14-fraud-detection-by-vertical)

---

## 1. Fraud Detection Architecture Overview

### Defense-in-Depth Model

```
Layer 1: Pre-Transaction (Before Authorization)
  ├── Device fingerprinting (is this a known device?)
  ├── Behavioral biometrics (is this how the real user types/swipes?)
  ├── Velocity checks (too many attempts from same source?)
  ├── Geolocation analysis (location vs billing address vs usual pattern)
  ├── Email/phone validation (disposable? recently created?)
  ├── IP risk scoring (VPN, TOR, proxy, data center IP?)
  └── Blocklist check (known fraudulent identifiers)
       │
       ▼
Layer 2: At Authorization (During Payment)
  ├── AVS (Address Verification System)
  ├── CVV check
  ├── 3D Secure 2 (issuing bank authentication)
  ├── Network tokenization validation
  └── ML risk score (real-time model inference)
       │
       ▼
Layer 3: Post-Authorization (After Approval, Before Fulfillment)
  ├── ML fraud scoring on approved transactions
  ├── Manual review queue (for flagged transactions)
  ├── Fulfillment delay rules (hold high-risk orders)
  └── Cross-order pattern detection
       │
       ▼
Layer 4: Post-Fulfillment (Ongoing Monitoring)
  ├── Shipping address change detection
  ├── Chargeback pattern analysis
  ├── Account behavior monitoring
  └── Fraud ring detection (graph analysis)
```

### Key Metrics

| Metric | Definition | Good Target |
|--------|-----------|------------|
| **Fraud rate** | Fraud losses / total volume | < 0.1% of revenue |
| **Chargeback rate** | Chargebacks / total transactions | < 0.5% (card network threshold: 1%) |
| **False positive rate** | Legitimate transactions blocked | < 2-5% |
| **Detection rate** | Fraudulent transactions caught | > 95% |
| **Review rate** | Transactions sent to manual review | < 2-3% |
| **Automation rate** | Decisions made without human review | > 95% |

---

## 2. Rule Engines vs ML-Based Detection

### Rule-Based Detection

**How it works**: Predefined thresholds and conditions. If X happens, then Y action.

```python
# Example rules
RULES = [
    # Velocity rule
    Rule("high_velocity_card", 
         condition=lambda tx: count_transactions(tx.card_id, hours=1) > 5,
         action="block", severity="high"),
    
    # Geographic rule
    Rule("geo_mismatch",
         condition=lambda tx: tx.ip_country != tx.billing_country,
         action="review", severity="medium"),
    
    # Amount rule
    Rule("unusual_amount",
         condition=lambda tx: tx.amount > 3 * avg_amount(tx.customer_id),
         action="review", severity="medium"),
    
    # New account + high value
    Rule("new_account_high_value",
         condition=lambda tx: (account_age(tx.customer_id) < timedelta(days=7) 
                              and tx.amount > 50000),
         action="review", severity="high"),
]
```

**Pros**: Transparent, easy to explain, fast to implement, no training data needed
**Cons**: High false positive rate (12-20% industry average), can't detect novel patterns, requires manual maintenance, attackers adapt quickly

### ML-Based Detection

**How it works**: Models learn fraud patterns from historical data and score each transaction in real-time.

**Model types:**
| Model | Purpose | Example |
|-------|---------|---------|
| **Supervised classification** | Score known fraud patterns | Gradient boosting (XGBoost, LightGBM), neural networks |
| **Unsupervised anomaly detection** | Find novel fraud patterns | Isolation Forest, autoencoders, clustering |
| **Graph neural networks** | Detect fraud networks | GNNs on transaction/entity graphs |
| **Sequence models** | Analyze transaction sequences | LSTM/Transformer on customer transaction history |

**Measurable results (2024-2025):**
- US Treasury recovered **$4 billion** in fraud through ML systems (2024)
- Commonwealth Bank of Australia cut scam losses **nearly in half**
- PayPal reported **40% reduction** in fraud losses
- Mastercard: Generative AI delivered **300% improvement** in detection rates (2025)

### Hybrid Approach (Recommended)

Use both: rules for known patterns and hard blocks, ML for scoring and novel detection.

```
Transaction
       │
       ├── Hard rules (synchronous, fast)
       │     Block known fraud patterns (blocklists, impossible travel, etc.)
       │     Pass → continue
       │     Block → reject immediately
       │
       ├── ML scoring (synchronous, <50ms)
       │     Feature engineering → model inference → risk score
       │     Score < 30 → approve
       │     Score 30-70 → review
       │     Score > 70 → block
       │
       └── Async analysis (post-decision)
             Graph analysis, pattern detection
             Update models, refine rules
```

---

## 3. Real-Time Transaction Scoring

### Feature Engineering

The quality of your fraud model depends on the features (signals) you feed it. Good features capture:

**Transaction features:**
```python
features = {
    # Amount patterns
    'amount': tx.amount,
    'amount_vs_avg': tx.amount / customer.avg_transaction_amount,
    'amount_vs_max': tx.amount / customer.max_transaction_amount,
    'is_round_amount': tx.amount % 1000 == 0,
    
    # Velocity
    'txn_count_1h': count_transactions(customer, hours=1),
    'txn_count_24h': count_transactions(customer, hours=24),
    'txn_amount_1h': sum_transactions(customer, hours=1),
    'unique_merchants_24h': count_unique_merchants(customer, hours=24),
    
    # Temporal
    'hour_of_day': tx.timestamp.hour,
    'day_of_week': tx.timestamp.weekday(),
    'is_unusual_time': is_outside_normal_hours(customer, tx.timestamp),
    
    # Device & location
    'device_age_days': (now - device.first_seen).days,
    'ip_risk_score': ip_intel.risk_score(tx.ip),
    'distance_from_home': geodistance(tx.ip_location, customer.home_location),
    'is_new_device': device.id not in customer.known_devices,
    
    # Account
    'account_age_days': (now - customer.created_at).days,
    'days_since_last_txn': (now - customer.last_transaction).days,
    'total_lifetime_txns': customer.transaction_count,
    'previous_chargebacks': customer.chargeback_count,
    
    # Payment method
    'is_new_payment_method': pm.first_used == now,
    'card_country_matches_billing': card.country == billing.country,
    'card_bin_risk': bin_risk_table.get(card.bin, 'unknown'),
}
```

### Model Serving Architecture

```
Transaction Request (< 100ms budget)
       │
       ▼
┌──────────────────┐
│ Feature Store     │  ← Pre-computed features (Redis, DynamoDB)
│ (5-10ms)          │     Customer history, device profiles, velocity counters
└──────────┬───────┘
           │
           ▼
┌──────────────────┐
│ Model Inference   │  ← ML model (XGBoost, neural network)
│ (10-30ms)         │     Deployed via: SageMaker, Vertex AI, custom service
└──────────┬───────┘
           │
           ▼
┌──────────────────┐
│ Decision Engine   │  ← Combines ML score + rules + business logic
│ (5-10ms)          │     Apply thresholds, exemptions, overrides
└──────────┬───────┘
           │
           ▼
   Approve / Review / Block
```

### Feature Store Design

```python
# Real-time feature store (Redis-based)
class FraudFeatureStore:
    def __init__(self, redis_client):
        self.redis = redis_client
    
    async def record_transaction(self, customer_id, amount, timestamp):
        pipe = self.redis.pipeline()
        
        # Sliding window counters (sorted sets with timestamps as scores)
        key = f"txn:{customer_id}"
        pipe.zadd(key, {f"{timestamp}:{amount}": timestamp.timestamp()})
        pipe.zremrangebyscore(key, 0, (timestamp - timedelta(days=7)).timestamp())
        pipe.expire(key, 7 * 86400)
        
        await pipe.execute()
    
    async def get_velocity_features(self, customer_id, now):
        key = f"txn:{customer_id}"
        
        # Count and sum transactions in various windows
        h1_start = (now - timedelta(hours=1)).timestamp()
        h24_start = (now - timedelta(hours=24)).timestamp()
        d7_start = (now - timedelta(days=7)).timestamp()
        
        h1_txns = await self.redis.zrangebyscore(key, h1_start, now.timestamp())
        h24_txns = await self.redis.zrangebyscore(key, h24_start, now.timestamp())
        d7_txns = await self.redis.zrangebyscore(key, d7_start, now.timestamp())
        
        return {
            'txn_count_1h': len(h1_txns),
            'txn_count_24h': len(h24_txns),
            'txn_count_7d': len(d7_txns),
            'txn_amount_1h': sum(int(t.split(':')[1]) for t in h1_txns),
            'txn_amount_24h': sum(int(t.split(':')[1]) for t in h24_txns),
        }
```

---

## 4. Behavioral Biometrics

Behavioral biometrics analyzes **how** users interact with devices — not what credentials they provide, but how they type, swipe, hold their phone, and navigate. This creates a continuous authentication signal throughout the session.

### Signals Collected

| Signal | What It Measures | Fraud Indicator |
|--------|-----------------|----------------|
| **Typing rhythm** | Key press/release timing, flight time between keys | Bots type uniformly; humans have unique rhythms |
| **Mouse movement** | Speed, acceleration, curvature, jitter | Bots move in straight lines; humans curve |
| **Touch patterns** | Pressure, contact area, swipe velocity, angle | Different from the real user's established pattern |
| **Device orientation** | How the phone is held (accelerometer/gyroscope) | Unusual hold pattern suggests different person |
| **Navigation pattern** | Page visit sequence, time per page, scroll behavior | Fraudsters navigate differently (more purposeful, less browsing) |
| **Copy-paste behavior** | Frequency of paste actions for form fields | Legitimate users type their own info; fraudsters paste from stolen data |
| **Session rhythm** | Time between interactions, overall session cadence | Automated scripts have different timing patterns |

### Behavioral Biometrics Architecture

```
User Session
       │
       │  JavaScript SDK / mobile SDK collects signals
       │  (typing, mouse, touch, device sensors)
       ▼
┌────────────────────┐
│ Behavioral Analysis│
│                    │
│  1. Build session  │  ← Compare to established user profile
│     profile        │
│  2. Compare to     │  ← ML models: similarity scoring
│     stored profile │
│  3. Generate risk  │  ← Continuous risk score (updates throughout session)
│     signal         │
└────────────┬───────┘
             │
             ▼
   Feed into fraud decision engine as one of many signals
```

### Key Players

| Vendor | Strength | Best For |
|--------|----------|---------|
| **BioCatch** | Leader in ATO, social engineering, money mule detection | Banks, account-level fraud |
| **Sardine** | Integrates behavioral biometrics with device intelligence | Fintech, holistic fraud + compliance |
| **Feedzai** | Named leader in QKS Group 2025 SPARK Matrix | Enterprise financial institutions |

### When to Deploy Behavioral Biometrics

- **Account creation**: Detect bot-driven mass registration
- **Login**: Detect account takeover (different person using stolen credentials)
- **High-risk actions**: Money transfers, payment method changes, profile updates
- **Session monitoring**: Continuous authentication throughout the session

---

## 5. Device Fingerprinting

Device fingerprinting creates a persistent identity for a device based on its hardware and software attributes, even without cookies or login.

### Fingerprint Components

```
Browser/App Attributes
  ├── User agent string
  ├── Screen resolution + color depth
  ├── Installed fonts
  ├── Browser plugins
  ├── WebGL renderer (GPU identification)
  ├── Canvas fingerprint (render differences)
  ├── Audio context fingerprint
  ├── Timezone + language
  └── Hardware concurrency (CPU cores)

Network Attributes
  ├── IP address + geolocation
  ├── VPN/proxy/TOR detection
  ├── Network type (WiFi, cellular, data center)
  └── ISP identification

Mobile-Specific
  ├── Device model + OS version
  ├── Battery level + charging status
  ├── Sensor data (accelerometer, gyroscope)
  ├── Screen size + density
  └── Installed apps (limited, privacy-restricted)
```

### Device Risk Signals

| Signal | Risk Indicator |
|--------|---------------|
| **New device** | First time seeing this device for this account |
| **Device velocity** | Same device used across many accounts (fraud ring) |
| **Emulator/VM** | Transaction from emulated device (bot activity) |
| **Rooted/jailbroken** | Elevated device permissions (higher risk) |
| **VPN/proxy** | Hiding true location (could be legitimate or fraudulent) |
| **Impossible travel** | Same account, two devices, different countries, short timeframe |
| **Device age** | Brand new device fingerprint (never seen before) |
| **Browser manipulation** | Canvas/WebGL randomization (anti-fingerprint tools) |

### Device Intelligence Vendors

| Vendor | Approach | Best For |
|--------|----------|---------|
| **Sardine** | Device intelligence + behavioral biometrics combined | Fintech-focused, comprehensive |
| **SEON** | Device fingerprinting + email/phone intel | E-commerce, account fraud |
| **ThreatMetrix (LexisNexis)** | Enterprise device identity network | Large institutions, global network |
| **Fingerprint.js** | Open-source browser fingerprinting library | DIY implementations |

---

## 6. Account Takeover (ATO) Prevention

ATO is when a fraudster gains access to a legitimate user's account. It's particularly dangerous in fintech because the account has real money.

### ATO Attack Vectors

| Vector | How It Works | Prevention |
|--------|-------------|-----------|
| **Credential stuffing** | Automated login attempts with stolen email/password combos | Rate limiting, CAPTCHA, credential breach monitoring |
| **Phishing** | Fake login pages harvest credentials | Domain monitoring, customer education, phishing-resistant MFA |
| **SIM swapping** | Fraudster ports victim's phone number | Use authenticator apps over SMS, carrier PIN |
| **Session hijacking** | Steal active session tokens | Short session expiry, IP-binding, device-binding |
| **Social engineering** | Trick support into resetting credentials | Strict verification for support actions, callback verification |
| **Malware** | Keyloggers, banking trojans, screen capture | Device health checks, behavioral biometrics |

### ATO Prevention Architecture

```
Login Attempt
       │
       ├── Rate limiting (per IP, per account)
       ├── Credential breach check (Have I Been Pwned, SpyCloud)
       ├── Device recognition (known device?)
       ├── Behavioral biometrics (typing pattern matches?)
       ├── Geographic check (usual location?)
       │
       ▼
  Risk Assessment
       │
       ├── Low risk → Allow login
       ├── Medium risk → Step-up authentication (MFA)
       └── High risk → Block + notify account holder

Post-Login Monitoring (continuous)
       │
       ├── Behavioral biometrics (session-level)
       ├── Sensitive action triggers (transfer, payment method change)
       │     └── Re-authenticate for high-risk actions
       └── Anomaly detection on account activity
```

### Step-Up Authentication Triggers

Require additional verification for sensitive actions, even after successful login:
- Changing email, phone, or password
- Adding new payment method
- Transferring above threshold amount
- First transfer to a new recipient
- Changing notification settings (fraudsters disable alerts)
- API key creation or modification

---

## 7. Velocity Checks & Rate Limiting

### Velocity Check Types

| Check | What It Monitors | Example Threshold |
|-------|-----------------|-------------------|
| **Transaction velocity** | Transactions per time window per entity | > 5 txns per hour per card |
| **Amount velocity** | Total amount per time window | > $10,000 per day per account |
| **Decline velocity** | Failed attempts per time window | > 3 declines per hour per card |
| **Account velocity** | Accounts per device or IP | > 3 accounts from same device |
| **Signup velocity** | Account creations per time window | > 5 signups per hour per IP |
| **Payment method velocity** | Different cards per account | > 3 new cards added per week |

### Implementation

```python
class VelocityChecker:
    """Redis-based velocity checks with sliding windows"""
    
    RULES = {
        'card_txn_1h':      {'key': 'vel:card:{card_id}:txn:1h',    'limit': 5,  'window': 3600},
        'card_amount_24h':  {'key': 'vel:card:{card_id}:amt:24h',   'limit': 10000_00, 'window': 86400, 'type': 'sum'},
        'ip_decline_1h':    {'key': 'vel:ip:{ip}:dec:1h',           'limit': 3,  'window': 3600},
        'device_accounts':  {'key': 'vel:dev:{device_id}:acct',     'limit': 3,  'window': 86400 * 7, 'type': 'unique'},
        'account_new_cards': {'key': 'vel:acct:{acct_id}:cards:7d', 'limit': 3,  'window': 86400 * 7, 'type': 'unique'},
    }
    
    async def check(self, context: dict) -> list[VelocityViolation]:
        violations = []
        now = time.time()
        
        for rule_name, rule in self.RULES.items():
            key = rule['key'].format(**context)
            window_start = now - rule['window']
            
            # Clean old entries
            await self.redis.zremrangebyscore(key, 0, window_start)
            
            if rule.get('type') == 'sum':
                # Sum-based (total amount)
                entries = await self.redis.zrangebyscore(key, window_start, now, withscores=False)
                current = sum(int(e) for e in entries) + context.get('amount', 0)
            elif rule.get('type') == 'unique':
                # Unique count
                current = await self.redis.zcard(key)
            else:
                # Count-based
                current = await self.redis.zcard(key)
            
            if current >= rule['limit']:
                violations.append(VelocityViolation(
                    rule=rule_name,
                    current=current,
                    limit=rule['limit'],
                    window=rule['window'],
                ))
        
        return violations
```

---

## 8. Network & Graph Analysis

### Why Graph Analysis for Fraud

Traditional fraud detection looks at individual transactions in isolation. But modern fraud is largely committed by **organized fraud rings** — groups of coordinated actors sharing devices, addresses, funding sources, and payout destinations. Graph analysis reveals these hidden connections.

### Entity Relationship Graph

```
         ┌──────┐
         │ Card │
         └──┬───┘
            │ used_by
    ┌───────┴───────┐
    │               │
┌───▼───┐     ┌─────▼────┐
│Account│     │ Account  │     ← Same card used by different accounts
│  A    │     │    B     │
└───┬───┘     └────┬─────┘
    │ login_from    │ login_from
    ▼               ▼
┌───────┐     ┌──────────┐
│Device │     │  Device  │     ← Different devices
│  X    │     │    Y     │
└───┬───┘     └────┬─────┘
    │ login_from    │ login_from
    ▼               ▼
┌────────┐    ┌──────────┐
│  IP    │    │   IP     │     ← Different IPs, BUT...
│ 1.2.3  │    │  4.5.6   │
└───┬────┘    └────┬─────┘
    │               │
    └──────┬────────┘
           ▼
     ┌──────────┐
     │ Ship To  │     ← SAME shipping address! → Fraud ring signal
     │ Address  │
     └──────────┘
```

### Graph Database for Fraud Detection

```python
# Example: Neo4j query to find fraud rings
# "Find all accounts that share a device with accounts that have chargebacks"

QUERY = """
MATCH (flagged:Account)-[:USED_DEVICE]->(d:Device)<-[:USED_DEVICE]-(connected:Account)
WHERE flagged.has_chargeback = true
AND connected.id <> flagged.id
RETURN connected.id, connected.email, 
       count(distinct d) as shared_devices,
       collect(distinct flagged.id) as connected_to_flagged
ORDER BY shared_devices DESC
"""

# Multi-hop query: find accounts 2 degrees away from known fraud
QUERY_2HOP = """
MATCH (fraud:Account {is_fraud: true})
      -[:USED_DEVICE|USED_IP|SHIPPED_TO*1..2]-
      (suspicious:Account)
WHERE suspicious.is_fraud IS NULL
RETURN suspicious.id, 
       count(distinct fraud) as fraud_connections,
       collect(distinct type(r)) as connection_types
HAVING fraud_connections >= 2
ORDER BY fraud_connections DESC
"""
```

### Graph Neural Networks (GNNs)

GNNs extend ML fraud detection to graph-structured data:
- **Node features**: Account attributes, transaction history, device characteristics
- **Edge features**: Transaction amounts, frequency, timestamps
- **Graph features**: Cluster density, shortest paths, community structure

GNNs can identify fraud that traditional ML overlooks because they leverage **relational reasoning** — how entities relate to each other, not just standalone attributes.

---

## 9. Fraud Platform Selection

### Platform Comparison Matrix

| Platform | Model | Key Strength | Best For | Pricing |
|----------|-------|-------------|---------|---------|
| **Stripe Radar** | ML + rules, built into Stripe | Zero integration effort for Stripe | Stripe merchants, standard fraud patterns | Included (basic), $0.07/screened (advanced) |
| **Sardine** | AI + behavioral biometrics + device intel | Full lifecycle fraud + AML + compliance | Fintech, holistic fraud + compliance | Per-decision |
| **Unit21** | Real-time + no-code rules | Sub-second evaluation, easy rule management | Fintechs wanting flexible rules + monitoring | Per-event |
| **Sift** | ML platform, multi-product | Account protection + payment + content trust | Large platforms with multiple fraud vectors | Per-decision |
| **Riskified** | Guaranteed fraud protection | Chargeback guarantee (they pay if approved txn is fraud) | E-commerce wanting guaranteed protection | Revenue share (higher %) |
| **Featurespace (ARIC)** | Adaptive Behavioral Analytics | Individualized behavioral profiles per user | Banks, large financial institutions | Enterprise pricing |
| **Alloy** | Identity + fraud prevention | Combines KYC + fraud signals in one platform | Fintechs wanting unified identity + fraud | Per-decision |

### Selection Framework

```
                        ┌──────────────────────────────┐
                        │ What's your primary concern?  │
                        └──────────┬───────────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              ▼                    ▼                    ▼
      Payment fraud         Account fraud         AML + fraud
              │                    │                    │
      ┌───────┴──────┐    ┌───────┴──────┐            │
      ▼              ▼    ▼              ▼            ▼
  Using Stripe?  Other PSP  Simple       Complex    Sardine
      │              │       │              │        Unit21
      ▼              ▼       ▼              ▼        Alloy
  Stripe Radar   Sift      SEON         Featurespace
  (start here)   Riskified              BioCatch
```

### Staged Approach (Recommended)

| Stage | Volume | Fraud Stack | Monthly Cost |
|-------|--------|------------|-------------|
| **Startup** | < $1M/mo | PSP-native (Stripe Radar) + basic rules | $0 (included) |
| **Growth** | $1M-$10M/mo | PSP + dedicated platform (Sardine/Unit21) + custom rules | $2K-$10K |
| **Scale** | $10M-$100M/mo | Multi-vendor ensemble + custom ML + graph analysis | $10K-$100K |
| **Enterprise** | $100M+/mo | In-house ML team + vendor ensemble + dedicated fraud ops | $100K+ |

---

## 10. Synthetic Identity Fraud

### What It Is

Synthetic identity fraud creates **fake identities** by combining real information (e.g., a stolen SSN) with fabricated details (fake name, address, date of birth). The resulting identity doesn't belong to any real person, making it extremely hard to detect through traditional verification.

### How It Works

```
1. Acquire real SSN (often from children, elderly, immigrants who rarely use credit)
2. Combine with fabricated name, DOB, address
3. Apply for credit (initial applications get denied, but this creates a credit file)
4. Gradually build credit history ("bust-out" scheme):
   - Get small secured credit card
   - Make payments on time for 6-12 months
   - Get credit limit increases
   - Open more accounts
5. Bust-out: Max all credit lines, disappear
   - Average loss per synthetic identity: $15,000-$20,000
```

### Detection Approaches

| Approach | How It Helps |
|----------|-------------|
| **SSN analysis** | Check if SSN was issued in expected year/state range, cross-reference with death records |
| **Identity graph** | Same SSN appearing with multiple names, addresses, DOBs |
| **Credit behavior** | Authorized user patterns (piggybacking on others' credit), thin file with sudden activity |
| **Phone/email analysis** | Recently created phone numbers, disposable emails |
| **Address analysis** | Commercial vs residential, multiple identities at same address |
| **ML models** | Trained on known synthetic patterns, anomaly detection on identity attributes |

---

## 11. Authorized Push Payment (APP) Fraud

### What It Is

APP fraud is when customers are manipulated (social engineering) into authorizing payments to fraudsters. The transaction is technically legitimate — the real account holder authorized it. This makes traditional fraud controls useless because there's nothing technically "fraudulent" about the transaction.

### Scale

- US losses projected to reach **$15 billion by 2028**
- US/UK/India losses expected to double by 2026 ($5.25 billion, 21% CAGR)
- AI-enhanced: Deepfakes and AI-generated content make scams more convincing

### Common APP Fraud Scenarios

| Scenario | How It Works |
|----------|-------------|
| **Investment scam** | Fake investment platform, initially shows gains, user deposits more, can't withdraw |
| **Romance scam** | Fake relationship, eventual requests for money |
| **CEO fraud / BEC** | Impersonate executive, instruct employee to wire money |
| **Purchase scam** | Fake seller, buyer pays, goods never arrive |
| **Impersonation** | Pretend to be bank/government, convince customer to "protect" money by transferring |

### Prevention Architecture

```
Outbound Payment
       │
       ├── 1. Payee risk assessment
       │     - Is this a known mule account?
       │     - New payee + large amount = higher risk
       │     - Crypto exchange as destination = higher risk
       │
       ├── 2. Behavioral analysis
       │     - Is the customer on a call while transacting? (phone + payment simultaneously)
       │     - Session duration anomaly (coached through the process)
       │     - Unusual payment pattern for this customer
       │
       ├── 3. Warning and friction
       │     - Show clear warning about common scams
       │     - Require delay for first-time large transfers to new payees
       │     - "Did someone ask you to make this payment?"
       │
       ├── 4. Confirmation of payee
       │     - Verify payee name matches account holder name at receiving bank
       │     - Mismatch → warning to customer
       │
       └── 5. Post-payment monitoring
             - Flag if receiving account quickly moves funds (layering)
             - Monitor for patterns of mule account usage
```

### Regulatory Response

- **PSD3/PSR**: Resets liability for APP fraud in EU
- **UK PSR**: Mandatory reimbursement for APP fraud victims (October 2024, max £85,000)
- **Nacha (US)**: Requires fraud monitoring for ACH by mid-2026
- **TRAPS Act (US)**: Federal task force for digital payment scams (June 2025)

---

## 12. Chargeback Management

### Chargeback Process

```
Customer disputes charge with issuing bank
       │
       ▼
Issuing bank files chargeback through card network
       │
       ▼
PSP notifies merchant (webhook: charge.dispute.created)
       │
       ├── 1. Pause fulfillment (if not yet shipped)
       │
       ├── 2. Investigate:
       │     - Was this a legitimate purchase?
       │     - Was there a delivery issue?
       │     - Did the customer attempt a refund first?
       │
       ├── 3. Gather evidence (if fighting):
       │     - Order confirmation + receipt
       │     - Shipping tracking + delivery proof
       │     - Customer communication logs
       │     - IP address + device fingerprint
       │     - 3DS authentication proof
       │     - Terms of service
       │     - Product description
       │     - Customer previous order history
       │
       ├── 4. Submit evidence (7-21 day deadline)
       │
       └── 5. Wait for bank decision (30-90 days)
              ├── Won → funds returned + evidence preserved
              └── Lost → funds stay with customer + chargeback fee ($15-25)
```

### Chargeback Prevention

| Strategy | How It Helps |
|----------|-------------|
| **Clear billing descriptor** | Customer recognizes charge (not "STRIPE* 39XY2") |
| **Proactive refunds** | Refund before dispute → no chargeback fee |
| **Pre-dispute alerts** | Verifi (Visa) + Ethoca (Mastercard) alert before formal dispute |
| **3DS authentication** | Liability shift to issuer for authenticated transactions |
| **Delivery confirmation** | Tracking + signature for high-value orders |
| **Clear return policy** | Prominently displayed, easy to follow |
| **Customer communication** | Responsive support reduces "can't reach merchant" disputes |

### Card Network Thresholds

| Network | Program | Threshold | Consequence |
|---------|---------|-----------|-------------|
| **Visa** | Dispute Monitoring (VDMP) | 0.9% dispute rate OR 100 disputes/mo | Monitoring, fines ($25K-$50K/mo), potential termination |
| **Mastercard** | Excessive Chargeback Program (ECP) | 1.5% chargeback rate OR 100 chargebacks/mo | Fines escalating from $1K to $200K/mo |

**Target**: Keep chargeback rate below **0.5%** to maintain healthy card network standing.

---

## 13. Card Testing Attack Prevention

### What It Is

Fraudsters use stolen card numbers and test them by making small purchases. If the card works (authorization success), they know it's valid and use it for larger fraud elsewhere.

### Detection Signals

```
- Many small transactions ($0.50-$1.00) in quick succession
- Different card numbers from same IP, device, or email
- High decline rate from single source (testing many stolen cards)
- Card numbers entered sequentially (auto-generated)
- Transactions with no browsing history (direct to checkout)
- New accounts with immediate purchase attempts
```

### Prevention Stack

```python
# Layer 1: Rate limiting
CARD_TESTING_RULES = {
    'payment_attempts_per_ip_per_hour': 5,
    'payment_attempts_per_email_per_hour': 3,
    'payment_attempts_per_device_per_hour': 5,
    'decline_rate_per_ip_per_hour': 0.5,  # > 50% decline rate → block
    'unique_cards_per_ip_per_day': 3,
}

# Layer 2: CAPTCHA after failures
# Show CAPTCHA after 2 consecutive payment failures from same session

# Layer 3: Minimum amount
# Reject transactions below $5 (or $1) from new accounts

# Layer 4: Block known bad sources
# Block TOR exit nodes, known VPN IPs for payment pages (not browsing)
# Block data center IPs (legitimate users don't pay from AWS)

# Layer 5: PSP-level protection
# Enable Stripe Radar's card testing protection
# Configure Adyen RevenueProtect card testing rules
```

---

## 14. Fraud Detection by Vertical

### Payments / PSP

| Fraud Type | Key Signals | Prevention |
|-----------|------------|-----------|
| Card-not-present fraud | Stolen card data, mismatched AVS/CVV | 3DS2, device fingerprinting, ML scoring |
| Card testing | High-velocity small transactions | Rate limiting, CAPTCHA, minimum amounts |
| Account takeover | Unusual login patterns, credential stuffing | MFA, behavioral biometrics, device recognition |
| Merchant fraud | Collusive merchants processing fake transactions | Merchant monitoring, velocity checks per merchant |

### Lending / Credit

| Fraud Type | Key Signals | Prevention |
|-----------|------------|-----------|
| Application fraud | Fake/synthetic identity, income fabrication | Identity verification, income verification (Plaid), SSN analysis |
| First-party fraud | Borrower has no intent to repay | Behavioral analysis, income-to-debt ratio, social signals |
| Stacking | Multiple simultaneous loan applications | Credit bureau inquiry monitoring, application velocity |
| Bust-out | Build credit then max all lines | Pattern detection, credit utilization monitoring |

### Account Opening / Onboarding

| Fraud Type | Key Signals | Prevention |
|-----------|------------|-----------|
| Bot registration | Mass account creation, similar patterns | CAPTCHA, device fingerprinting, behavioral analysis |
| Synthetic identity | Fabricated identity with real SSN | Identity graph analysis, SSN validation, ML models |
| Promo abuse | Multiple accounts for signup bonuses | Device/phone/email linkage, address matching |
| Money mule | Legitimate-looking accounts used for laundering | Behavioral profiling, rapid fund movement patterns |
