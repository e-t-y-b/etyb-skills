# Compliance & Regulatory Architecture — Deep Reference

**Always use `WebSearch` to verify regulatory deadlines, compliance requirements, and licensing obligations before giving advice. Financial regulations change frequently, vary by jurisdiction, and the consequences of non-compliance can include fines, license revocation, and criminal liability. Last verified: April 2026.**

## Table of Contents
1. [PCI DSS v4.0.1](#1-pci-dss-v401)
2. [PSD2/SCA & The Upcoming PSD3/PSR](#2-psd2sca--the-upcoming-psd3psr)
3. [AML/KYC/KYB Implementation](#3-amlkyckyb-implementation)
4. [SOX Compliance for Fintech](#4-sox-compliance-for-fintech)
5. [GDPR for Financial Data](#5-gdpr-for-financial-data)
6. [DORA — Digital Operational Resilience Act](#6-dora--digital-operational-resilience-act)
7. [Money Transmission Licensing](#7-money-transmission-licensing)
8. [MiCA & Crypto Compliance](#8-mica--crypto-compliance)
9. [AMLA & EU AML Single Rulebook](#9-amla--eu-aml-single-rulebook)
10. [Compliance Automation & RegTech](#10-compliance-automation--regtech)
11. [EU AI Act for Financial Services](#11-eu-ai-act-for-financial-services)
12. [Regulatory Sandboxes](#12-regulatory-sandboxes)
13. [Compliance Architecture Patterns](#13-compliance-architecture-patterns)

---

## 1. PCI DSS v4.0.1

PCI DSS (Payment Card Industry Data Security Standard) governs how organizations handle cardholder data. Version 4.0.1 (released June 2024) is the current standard, and all requirements — including previously "future-dated" ones — became mandatory **March 31, 2025**.

### Compliance Levels

| Level | Criteria | Requirement |
|-------|---------|------------|
| **Level 1** | >6M transactions/year | Annual on-site audit by QSA, quarterly ASV scans |
| **Level 2** | 1-6M transactions/year | Annual SAQ, quarterly ASV scans |
| **Level 3** | 20K-1M e-commerce txns/year | Annual SAQ, quarterly ASV scans |
| **Level 4** | <20K e-commerce or <1M total/year | Annual SAQ, quarterly scans recommended |

### SAQ Types

| SAQ | PCI Scope | How to Achieve | Example |
|-----|-----------|---------------|---------|
| **SAQ A** | Lowest | All payment processing outsourced (hosted checkout page) | Stripe Checkout, Adyen Drop-in |
| **SAQ A-EP** | Low-Medium | Card data entered on your page but submitted directly to PSP via JS SDK | Stripe Elements, Adyen Custom Card Component |
| **SAQ D** | Highest (full PCI) | Card data touches your servers | Custom payment forms — AVOID unless absolutely necessary |

**Recommendation**: Use SAQ A or SAQ A-EP. There is almost never a legitimate reason for a fintech to handle raw card data at SAQ D scope.

### Key v4.0.1 Changes (Now Mandatory)

| Requirement | What Changed | Impact |
|-------------|-------------|--------|
| **MFA everywhere** (8.4.2) | MFA required for ALL access to CDE, not just admin | Every developer, support agent, and system account accessing payment environments needs MFA |
| **Payment page script security** (6.4.3) | All scripts on payment pages must be authorized, integrity-checked, and inventoried | Monitor for skimming attacks (Magecart-style), implement CSP headers, SRI on all payment JS |
| **No full disk encryption alone** (3.5.1.2) | Full disk encryption no longer acceptable as sole protection for stored cardholder data | Implement field-level or database-level encryption |
| **Authenticated internal scans** (11.3.1.1) | Internal vulnerability scans must use authentication | Configure authenticated scan profiles for internal systems |
| **Targeted risk analysis** (12.3.1) | Customized risk analysis for each PCI requirement lacking a defined frequency | Document risk-based justification for security control frequencies |

### PCI Compliance Architecture

```
Customer Browser
  │
  │  HTTPS only (TLS 1.2+)
  │  CSP headers (restrict iframe sources, script sources)
  │  SRI on all payment JavaScript
  │  
  ▼
Your Application (payment page)
  │
  │  Hosted payment fields (Stripe Elements / Adyen Drop-in)
  │  Card data lives in PSP's iframe — never touches your DOM
  │  No card data in logs, error tracking, or analytics
  │  CSRF protection on all payment endpoints
  │
  ▼
Your Backend
  │
  │  Receives only tokens (pm_xxx), NEVER raw card data
  │  Webhook signature verification
  │  Rate limiting on payment endpoints
  │  Server-side amount validation (never trust client)
  │  Audit logging of all payment operations
  │  MFA on all CDE access
  │
  ▼
PSP (PCI Level 1 Certified)
  │
  │  Card vault (AES-256 encryption at rest)
  │  Network tokenization
  │  Fraud detection
  │  3DS2 authentication
```

### Payment Page Script Inventory (Requirement 6.4.3)

```javascript
// Maintain an inventory of all scripts on payment pages
const AUTHORIZED_SCRIPTS = [
  { src: 'https://js.stripe.com/v3/', integrity: 'sha384-xxx...', purpose: 'Payment processing' },
  { src: '/js/checkout.js', integrity: 'sha384-yyy...', purpose: 'Checkout flow logic' },
  // NO analytics, chat widgets, or marketing tags on payment pages
];

// Content Security Policy header for payment pages
// script-src 'self' https://js.stripe.com;
// frame-src https://js.stripe.com https://hooks.stripe.com;
// connect-src https://api.stripe.com;
```

---

## 2. PSD2/SCA & The Upcoming PSD3/PSR

### PSD2 — Current State

PSD2 (Payment Services Directive 2) governs payment services in the EU/EEA. Key provisions:

**Strong Customer Authentication (SCA)**: Requires two-factor authentication for electronic payments using at least two of:
- **Knowledge**: Something the customer knows (password, PIN)
- **Possession**: Something the customer owns (phone, hardware token)
- **Inherence**: Something the customer is (fingerprint, face recognition)

**SCA Exemptions** (transactions that may skip SCA):
| Exemption | Criteria | Who Decides |
|-----------|---------|-------------|
| **Low value** | < €30 (up to €100 cumulative or 5 consecutive) | Issuer |
| **Low risk (TRA)** | Based on fraud rate thresholds per amount band | Acquirer or issuer |
| **Trusted beneficiary** | Customer whitelists the merchant | Issuer |
| **Recurring MIT** | Fixed-amount recurring charges (after initial SCA) | Acquirer |
| **Corporate payments** | Between two businesses using dedicated corporate channels | Acquirer |

**Transaction Risk Analysis (TRA) thresholds:**
| Amount | Max Fraud Rate for Exemption |
|--------|----------------------------|
| < €100 | 0.13% |
| < €250 | 0.06% |
| < €500 | 0.01% |

### PSD3/PSR — Coming 2026-2027

Provisional agreement reached November 2025. Two instruments:

**PSD3 (Directive)**: Licensing and supervision framework
- Needs local transposition by member states
- Updated licensing categories for payment institutions
- Clarified passporting rules

**PSR (Payment Services Regulation)**: Directly applicable rules
- **Enforceable API obligations**: Banks must give clear reasons for declining PSP access; penalties for non-compliance
- **Enhanced SCA**: Adaptive, risk-sensitive authentication including physiological + behavioral biometrics combination
- **APP fraud liability**: Materially resets liability for authorized push payment fraud
- **Open finance scope**: Extends beyond payments to savings, investments, insurance data

### 3DS2 Implementation

```
Customer at Checkout
       │
       ▼
PSP sends authentication request to card network
       │
       ▼
Card network routes to issuing bank
       │
       ├── Frictionless Flow (80-90% of transactions)
       │     AI risk analysis of 100+ data points
       │     Low risk → Approved without customer interaction
       │     
       └── Challenge Flow (10-20% of transactions)
             Customer sees authentication screen
             Enters OTP / biometric / app approval
             Bank confirms identity
             
Result → Authentication successful → Proceed with authorization
       → Authentication failed → Decline transaction
       → Liability shift: Fraud liability moves from merchant to issuer
```

**Regional 3DS2 mandates (2025-2026):**
- **EU/UK**: Mandatory for all customer-initiated card payments (SCA requirement)
- **France** (March 2025): Issuers soft-decline all customer-initiated exemptions except via EMV 3DS
- **Japan** (April 2025): 3DS2 mandatory on all card transactions
- **India**: RBI mandates additional factor authentication for all online transactions

---

## 3. AML/KYC/KYB Implementation

### The KYC/KYB Lifecycle

```
Customer Onboarding
       │
       ├── 1. Identity Verification (KYC)
       │     - Document verification (ID, passport, driver's license)
       │     - Selfie/liveness check (anti-spoofing)
       │     - Database checks (credit bureau, government records)
       │     - PEP (Politically Exposed Person) screening
       │     - Sanctions screening (OFAC, EU, UN)
       │
       ├── 2. Business Verification (KYB) — for business accounts
       │     - Company registration verification
       │     - Beneficial ownership identification (UBO)
       │     - Director/officer verification
       │     - Business license validation
       │     - Source of funds verification
       │
       ├── 3. Risk Assessment
       │     - Customer risk score (low/medium/high)
       │     - Country risk
       │     - Product risk
       │     - Channel risk
       │     - Enhanced Due Diligence (EDD) if high-risk
       │
       └── 4. Ongoing Monitoring
             - Transaction monitoring (patterns, velocity, anomalies)
             - Periodic re-verification (annual for high-risk)
             - Adverse media screening
             - Sanctions list updates (real-time)
             - Suspicious Activity Report (SAR) filing
```

### KYC/AML Vendor Comparison

| Vendor | Focus | Key Strength | Best For |
|--------|-------|-------------|---------|
| **Alloy** | Identity + compliance orchestration | Orchestrates multiple data sources, decisioning engine | US fintechs wanting configurable KYC workflows |
| **Jumio** | Identity verification | AI-powered document + biometric verification | Global identity verification |
| **Onfido** | Identity verification | Document + biometric + fraud signals | International coverage |
| **Sardine** | KYC + fraud + compliance | Behavioral biometrics + device intelligence integrated | Holistic fraud + compliance |
| **ComplyAdvantage** | AML data + screening | Real-time sanctions, PEP, adverse media database | Transaction monitoring and screening |
| **Plaid Identity** | US identity verification | Leverages bank connection for identity proof | US-focused, Plaid ecosystem |
| **Sumsub** | Full KYC/AML platform | All-in-one: verification, monitoring, case management | International, all-in-one solution |

### Transaction Monitoring Architecture

```
Transactions
       │
       ▼
┌──────────────────────────┐
│ Transaction Monitor      │
│                          │
│  Rule-based checks:      │
│  - Amount thresholds     │
│  - Geographic anomalies  │
│  - Structuring patterns  │
│  - Velocity checks       │
│                          │
│  ML-based detection:     │
│  - Behavioral profiling  │
│  - Peer group comparison │
│  - Network analysis      │
│                          │
│  Sanctions screening:    │
│  - Real-time name match  │
│  - OFAC, EU, UN lists    │
│  - Fuzzy matching        │
└──────────┬───────────────┘
           │
     ┌─────┼─────┐
     ▼     ▼     ▼
  Clear  Alert  Block
         │       │
         ▼       ▼
   Case Mgmt  Immediate
   Queue      Hold + Review
         │
         ▼
   SAR Filing
   (if warranted)
```

### Currency Transaction Report (CTR) Requirements

- **US**: Report cash transactions > $10,000 (FinCEN CTR)
- **Structuring**: Detect intentional splitting of transactions to avoid thresholds (e.g., multiple $9,999 deposits)
- **SAR filing**: File within 30 days of detecting suspicious activity
- **Record retention**: 5 years for all KYC/AML records

### Emerging AI Threats to KYC

- Deepfake fraud attempts up **1,100%** in the US (2025)
- Synthetic-ID document fraud up **300%** in Q1 2025
- Require liveness detection (blink, turn head, 3D depth) in identity verification flows
- Consider vendors with anti-AI-fraud capabilities (document injection detection, digital alteration detection)

---

## 4. SOX Compliance for Fintech

SOX (Sarbanes-Oxley Act) applies to US publicly traded companies and their subsidiaries. Many fintech companies encounter SOX requirements post-IPO or when serving regulated clients.

### Key Requirements

| Section | Requirement | Fintech Impact |
|---------|------------|----------------|
| **302** | CEO/CFO certify financial statements | Financial data in your platform must be accurate and auditable |
| **404** | Internal controls over financial reporting (ICFR) | Requires documented controls for all financial processes |
| **906** | Criminal penalties for false financial statements | Up to $5M fines / 20 years prison for willful violations |

### Internal Controls for Fintech Systems

```
Access Controls
  ├── Role-based access (RBAC) for financial systems
  ├── Segregation of duties (person who creates ≠ person who approves)
  ├── MFA on all financial system access
  └── Quarterly access reviews with evidence

Change Management
  ├── All code changes to financial systems require peer review
  ├── Separate dev/staging/production environments
  ├── Change approval records with business justification
  └── Automated deployment with audit trail

Data Integrity
  ├── Immutable ledger (append-only, no modifications)
  ├── Reconciliation controls (internal + external)
  ├── Input validation and sanity checks
  └── Data backup and recovery procedures

Monitoring
  ├── Alerting on financial anomalies
  ├── Audit log for all financial transactions
  ├── Periodic control testing
  └── Exception reporting
```

---

## 5. GDPR for Financial Data

GDPR applies to any fintech processing personal data from EU residents, regardless of company location.

### The GDPR vs Financial Regulation Tension

Financial regulations often require data retention (AML: 5 years, SOX: 7 years), while GDPR demands data minimization and right to erasure. The resolution:

| Scenario | GDPR Right | Financial Obligation | Resolution |
|----------|-----------|---------------------|-----------|
| Customer requests data deletion | Right to erasure | AML requires 5-year retention | **Financial regulation wins** — retain for compliance, document legal basis |
| Customer requests data export | Right to portability | Audit trail must be maintained | **Both apply** — export data but don't delete audit records |
| Marketing data | Consent-based processing | Not required for compliance | **GDPR wins** — delete on consent withdrawal |
| Transaction history | Right to access | Reconciliation records | **Both apply** — provide access, maintain records |

### Data Residency Requirements

Several jurisdictions require financial data to stay in-country:

| Jurisdiction | Requirement | Impact |
|-------------|-------------|--------|
| **India (RBI)** | Payment data must be stored in India | Deploy Indian database instances for Indian customers |
| **Russia** | Personal data of Russian citizens stored in Russia | Most fintechs choose not to serve Russia |
| **China** | Cross-border data transfer restricted | Requires local entity and infrastructure |
| **EU (GDPR)** | Adequate protection for transfers outside EEA | Standard Contractual Clauses or adequacy decisions |
| **Brazil (LGPD)** | Similar to GDPR, encourages local processing | Consider Brazilian infrastructure for LATAM |

### GDPR Penalties

- Maximum: **€20M or 4% of global annual turnover** (whichever is higher)
- Cumulative fines reached ~€5.88 billion by January 2025
- Financial services sector among the most heavily fined

---

## 6. DORA — Digital Operational Resilience Act

DORA became effective in **January 2025** across the EU. It strengthens IT risk management for financial entities, including fintechs, their cloud providers, and third-party ICT vendors.

### Key Requirements

| Area | Requirement | What to Do |
|------|------------|-----------|
| **ICT Risk Management** | Comprehensive framework for identifying, protecting, detecting, responding to ICT risks | Document ICT risk management policy, regular risk assessments |
| **Incident Reporting** | Report major ICT incidents to regulators within 4 hours (initial), 72 hours (intermediate), 1 month (final) | Build incident classification and reporting pipeline |
| **Digital Operational Resilience Testing** | Regular testing including threat-led penetration testing (TLPT) for significant institutions | Annual penetration tests, periodic resilience testing |
| **Third-Party Risk** | Manage risks from ICT third-party providers (cloud, SaaS) | Vendor risk assessments, contractual requirements, exit strategies |
| **Information Sharing** | Share cyber threat intelligence with other financial entities | Join ISACs (Information Sharing and Analysis Centers) |

### DORA for Cloud / SaaS Providers

If your fintech product is used by EU financial institutions, **you are an ICT third-party provider under DORA**. Your customers will require:
- Right to audit (or SOC 2 Type II reports)
- Incident notification SLAs
- Business continuity and disaster recovery plans
- Data location transparency
- Exit strategy provisions in contracts

---

## 7. Money Transmission Licensing

### US Money Transmission

In the US, money transmission is regulated at both federal and state levels:

**Federal**: Register with FinCEN as a Money Services Business (MSB)

**State**: Obtain money transmitter licenses in each state you operate in (or use exemptions). 49 states + DC + territories each have their own requirements.

| Approach | Time | Cost | Best For |
|----------|------|------|---------|
| **Direct licensing** | 12-24 months, all states | $1M-$5M (applications, bonds, legal) | Large fintechs planning long-term operations |
| **Sponsor bank / BaaS** | 1-3 months | Revenue share with sponsor | Startups, faster time to market |
| **Uniform licensing (NMLS)** | Streamlined but still per-state | Reduced per-state cost | Companies with dedicated compliance teams |

### EU Payment Institution Licensing

| License Type | Scope | Capital Requirement | Example |
|-------------|-------|-------------------|---------|
| **Payment Institution (PI)** | Execute payment transactions | €20K-€125K depending on services | Payment processors, remittance services |
| **Electronic Money Institution (EMI)** | Issue electronic money + PI services | €350K | Digital wallets, prepaid cards, neobanks |
| **Bank License** | Full banking services | €5M+ | Full-service digital banks |

### Sponsor Bank Model

Most fintech startups avoid direct licensing by partnering with a sponsor bank:

```
Your Fintech App → API → Sponsor Bank → Banking Infrastructure
                         (holds licenses)
                         
Responsibilities:
  You:           UI/UX, customer acquisition, product logic
  Sponsor Bank:  Compliance, licensing, bank account custody, regulatory reporting
  Shared:        AML/KYC, fraud monitoring (specifics vary by agreement)
```

**Key consideration**: The sponsor bank is ultimately liable for compliance. They will impose restrictions and oversight on your operations. Choose a sponsor bank whose risk appetite matches your business model.

---

## 8. MiCA & Crypto Compliance

MiCA (Markets in Crypto-Assets) is the EU's comprehensive regulatory framework for crypto assets, fully applicable from **December 2024** (with stablecoin provisions from June 2024).

### Key Obligations

| Entity Type | Requirements |
|------------|-------------|
| **CASPs** (Crypto-Asset Service Providers) | Authorization, AML/KYC, custody rules, consumer disclosures, risk management |
| **Stablecoin Issuers** (ARTs/EMTs) | Reserve requirements, redemption rights, capital requirements, operational resilience |
| **Token Issuers** | White paper requirements, marketing rules, liability provisions |

### Crypto-Specific AML Obligations

- Full transaction monitoring for crypto (same standard as traditional finance)
- Travel Rule compliance (transmit sender/receiver info for transfers)
- Sanctions screening on blockchain addresses (OFAC SDN list includes crypto addresses)
- Wallet screening and chain analysis (Chainalysis, Elliptic, TRM Labs)

---

## 9. AMLA & EU AML Single Rulebook

### EU Anti-Money Laundering Authority (AMLA)

Established 2024, becoming operational 2025-2027:
- **Direct supervision** of high-risk cross-border financial entities
- **Single rulebook** replacing 27 national AML interpretations
- **Full enforcement** from July 2027

### Impact on Fintechs

- Harmonized KYC/AML requirements across EU (less national variation)
- Higher standards for digital onboarding (remote KYC)
- Enhanced beneficial ownership transparency requirements
- Stricter crypto AML obligations
- Direct AMLA supervision possible for large cross-border fintechs

---

## 10. Compliance Automation & RegTech

### RegTech Vendor Landscape

| Category | Vendors | What They Do |
|----------|---------|-------------|
| **KYC/Identity** | Alloy, Jumio, Onfido, Sumsub | Identity verification, document checks, liveness |
| **AML/Transaction Monitoring** | ComplyAdvantage, Unit21, Sardine, Featurespace | Real-time transaction screening, suspicious activity detection |
| **Sanctions Screening** | ComplyAdvantage, Dow Jones, Refinitiv | Real-time screening against global sanctions lists |
| **Regulatory Reporting** | Regnology, AxiomSL, Vermeg | Automated regulatory report generation |
| **Compliance Workflow** | Alloy, Cable, Lucinity | Case management, SAR filing, audit trail |
| **Data Privacy** | OneTrust, BigID, Securiti | GDPR/CCPA compliance automation |

### Compliance-as-Code

Modern fintechs implement compliance rules as code — version-controlled, testable, and auditable:

```python
# Example: Transaction monitoring rule (compliance-as-code)
class StructuringDetection(ComplianceRule):
    """Detect potential structuring (splitting transactions to avoid CTR threshold)"""
    
    THRESHOLD = 10_000_00  # $10,000 in cents
    WINDOW_HOURS = 24
    MIN_TRANSACTIONS = 3
    
    async def evaluate(self, transaction, customer):
        recent = await self.get_recent_transactions(
            customer_id=customer.id,
            hours=self.WINDOW_HOURS,
            direction='credit',
        )
        
        # Check for multiple deposits just under threshold
        suspicious = [t for t in recent if t.amount >= 8_000_00 and t.amount < self.THRESHOLD]
        total = sum(t.amount for t in suspicious) + transaction.amount
        
        if len(suspicious) >= self.MIN_TRANSACTIONS and total >= self.THRESHOLD:
            return ComplianceAlert(
                rule='structuring_detection',
                severity='high',
                customer_id=customer.id,
                total_amount=total,
                transaction_count=len(suspicious) + 1,
                evidence=suspicious,
                action='REVIEW',  # Route to compliance team
            )
        
        return None
```

---

## 11. EU AI Act for Financial Services

The EU AI Act introduces risk-based regulation for AI systems. Key provisions affecting fintech:

### High-Risk AI in Finance

The following AI systems in financial services are classified as **high-risk** (requirements apply from **August 2026**):
- **Credit scoring / creditworthiness assessment**
- **Risk assessment and pricing for insurance**
- **Fraud detection systems** (when they make autonomous decisions to block transactions)

### High-Risk AI Requirements

| Requirement | What It Means |
|-------------|-------------|
| **Conformity assessment** | Technical documentation, testing, and certification before deployment |
| **Transparency** | Inform users they're interacting with AI; explain how decisions are made |
| **Human oversight** | Human-in-the-loop for consequential decisions (loan denials, account blocks) |
| **Data governance** | Training data quality, bias testing, representativeness |
| **Record-keeping** | Log AI system outputs and decisions for auditability |
| **Accuracy monitoring** | Ongoing performance monitoring, drift detection |

### Practical Impact

If your fintech uses ML for credit decisions or automated fraud blocking:
1. **Document your models**: Training data, architecture, performance metrics, bias testing
2. **Implement explainability**: Users must understand why they were denied credit or had a transaction blocked
3. **Human review**: Provide appeal mechanisms with human decision-makers
4. **Monitor continuously**: Track model performance, demographic fairness, drift

---

## 12. Regulatory Sandboxes

Regulatory sandboxes allow fintechs to test innovative products under relaxed regulatory conditions with regulator oversight.

### Notable Sandboxes

| Regulator | Country | Focus | Track Record |
|-----------|---------|-------|-------------|
| **FCA** | UK | Pioneer (2016), broad fintech | Companies see 15% more capital raised, 50% more likely to be funded |
| **MAS** | Singapore | Broad fintech + digital banking | Strong for APAC expansion |
| **CBI** | Ireland | EU entry point, post-Brexit alternative | Growing fintech hub |
| **DFSA/ADGM** | UAE | Broad fintech + crypto | Strong for MENA |
| **Various states** | US | Arizona, Utah, others | State-level, limited scope |

### How to Use Sandboxes

1. Apply with a specific innovation (not just "we're a fintech")
2. Demonstrate consumer benefit and genuine innovation
3. Operate under regulator supervision with defined metrics
4. Graduate to full licensing based on sandbox performance
5. Duration: typically 6-24 months

---

## 13. Compliance Architecture Patterns

### Defense in Depth for Compliance

```
Layer 1: Onboarding Controls
  ├── KYC/KYB verification
  ├── Sanctions screening
  ├── PEP screening
  ├── Risk assessment
  └── Account limits based on verification level

Layer 2: Transaction Controls
  ├── Real-time transaction monitoring
  ├── Velocity checks
  ├── Amount thresholds
  ├── Geographic restrictions
  └── Sanctions re-screening

Layer 3: Periodic Controls
  ├── Ongoing customer due diligence
  ├── Periodic re-verification (risk-based)
  ├── Adverse media monitoring
  ├── Account activity review
  └── Enhanced due diligence for high-risk

Layer 4: Reporting & Audit
  ├── SAR/STR filing workflows
  ├── CTR reporting
  ├── Regulatory reporting automation
  ├── Audit trail and evidence preservation
  └── Board/management reporting
```

### Compliance Event Architecture

```
Transaction Event
       │
       ▼
┌─────────────────────┐
│ Compliance Gateway   │
│ (synchronous checks) │
│  - Sanctions screen  │
│  - Account status    │
│  - Amount limits     │
│  - Country blocks    │
└──────────┬──────────┘
           │
     ┌─────┼─────┐
     ▼     │     ▼
  Block    │   Allow
           ▼
   Async Monitoring
     ├── Rule engine
     ├── ML models
     ├── Pattern detection
     └── Alert generation
           │
           ▼
   Case Management
     ├── Alert triage
     ├── Investigation
     ├── SAR decision
     └── Evidence preservation
```

### Audit Trail Requirements

Every compliance-relevant action must be logged with:

```sql
CREATE TABLE compliance_audit_log (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- What happened
  event_type      VARCHAR(50) NOT NULL,    -- 'kyc_check', 'sanctions_screen', 'sar_filed', 'alert_created'
  action          VARCHAR(50) NOT NULL,    -- 'approved', 'rejected', 'escalated', 'reviewed'
  
  -- Who/what was involved
  customer_id     UUID,
  transaction_id  UUID,
  account_id      UUID,
  
  -- Who made the decision
  actor_type      VARCHAR(20) NOT NULL,    -- 'system', 'human', 'model'
  actor_id        VARCHAR(100) NOT NULL,   -- user ID, system name, or model version
  
  -- Context
  decision_reason TEXT NOT NULL,           -- why this decision was made
  risk_score      NUMERIC(5,2),
  evidence        JSONB DEFAULT '{}',      -- supporting data
  
  -- Regulatory metadata
  regulation      VARCHAR(50),             -- 'aml', 'pci', 'gdpr', 'sox'
  jurisdiction    VARCHAR(10),             -- 'US', 'EU', 'UK'
  
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  
  -- Immutable — no updates or deletes
  -- (enforce via database rules or application logic)
);

CREATE INDEX idx_audit_customer ON compliance_audit_log(customer_id, created_at);
CREATE INDEX idx_audit_type ON compliance_audit_log(event_type, created_at);
```

### "Failure to Prevent" Laws

The UK's new economic crime law (2024-2025) flips the burden of proof — companies must prove they had "reasonable procedures" in place to prevent financial crime. Similar legislation is being considered in other jurisdictions.

**Implications for fintechs**:
- Documented compliance programs are no longer optional — they're your defense
- "We had a policy" is not enough — demonstrate the policy was implemented, monitored, and effective
- First prosecutions under these laws expected by 2026
