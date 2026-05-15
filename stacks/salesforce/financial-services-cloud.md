---
title: Financial Services Cloud
description: Salesforce's financial services Industries cloud. Wealth/banking/insurance/mortgage data model + Agentforce Financial Services agents.
product:
  name: Financial Services Cloud
  stack: salesforce
  drift_risk: low
  last_verified_on: "2026-05-12"
  applies_to_roles: [fintech-architect, system-architect, database-architect, ai-ml-engineer, security-engineer]
  authoritative_url: https://help.salesforce.com/s/articleView?id=sf.financial_services_cloud.htm
  notes: "Data model stable; ledger/PCI/PSD2 interpretation defers to fintech-architect core; Agentforce FSC bundle added Dreamforce '25."
---

<div class="etyb-currency-banner">Last verified: 2026-05-12 against Salesforce Spring '26, Dreamforce '25.</div>

## What it is

Financial Services Cloud (FSC) is Salesforce's Industries cloud for wealth management, banking, insurance, and mortgage. It ships an opinionated, regulator-friendly data model (FinancialAccount, InsurancePolicy, Claim, etc.) plus OmniStudio templates and Agentforce Financial Services agents.

**Salesforce is NOT the ledger.** FSC holds customer context, derived state, advisor/banker workflows, claims handling. The core banking platform, brokerage custodian, card processor, and policy admin system are the books of record. FSC is downstream.

Canonical reference: [FSC documentation](https://help.salesforce.com/s/articleView?id=sf.financial_services_cloud.htm).

## When to use it

For Salesforce builds serving financial services workflows. **Do not** model FinancialAccount/Claim as custom objects when FSC exists; fighting the data model breaks Agentforce FSC grounding, household sharing, OmniStudio templates, and AppExchange add-ons.

## 2025-2026 currency anchors

- **Agentforce Financial Services** (Dreamforce '25 rebrand) — agent-bundled SKU on top of FSC. Pre-built wealth, banking, insurance, mortgage agents.
- **Agentforce 1 Editions** (TDX 2026) — FSC packaged in the Agentforce-1-Industries SKU lineup; agent entitlements ride with the FSC license.
- **OmniStudio Standard designers built-in** (Winter '26) — no separate Vlocity package install for net-new orgs.
- **MuleSoft Anypoint Banking Accelerator v6** (2025) — refreshed connectors for FIS, Fiserv, Jack Henry, Temenos; pre-built FSC mappings.
- **Open Banking adapter maturity** — UK Open Banking, EU PSD2 AISP/PISP, Brazil Open Finance, Australia CDR, India Account Aggregator. Plaid/Yodlee/MX connectors AppExchange-validated.
- **Pub/Sub API for transaction events** — sanctioned ingestion from core banking; deprecated Streaming API / CometD should not be used for new builds.
- **FSC Insurance** expanded — Claim, Coverage, InsurancePolicyParticipant, FNOL OmniScripts.

## Core data model

### Banking and wealth

- **FinancialAccount** — bank account, brokerage account, retirement account, loan, line of credit. Customer-facing view of a real account in core banking / custodian. **Not the ledger.**
- **FinancialAccountRole** — relationship between Person/Account and FinancialAccount (Primary Owner, Joint Owner, Beneficiary, Authorized Signer, Power of Attorney). Household sharing model rides on these roles.
- **FinancialAccountBalance** — point-in-time snapshot. Populated from core banking. Cadence matters per use case.
- **FinancialAccountTransaction** — derived transaction record. Customer-visible activity in advisor/service contexts. **Never use as authoritative ledger.**
- **Securities / SecuritiesHolding** — instrument master and per-account positions.
- **InvestmentAccount** — aggregation parent for brokerage/advisory accounts.
- **AssetsAndLiabilities** — net-worth and financial-profile capture.
- **FinancialGoal / FinancialGoalProgress** — planning structure.

### Insurance

- **InsurancePolicy** — policy master; parent for coverage and claims.
- **Coverage** — line items (collision, comprehensive, dwelling, riders).
- **Claim** — FNOL and ongoing claim record.
- **InsurancePolicyParticipant** — drivers, insureds, beneficiaries.
- **InsurancePolicyCoverage / Asset / Coverage Type** — structured exposure.

### Compliance / onboarding

- **ComplianceCase** — KYC, AML, sanctions, OFAC review record. Workflow object; **not** the SAR/CTR system of record.
- **CustomerActionPlan** — onboarding/remediation playbook.
- **Application / ApplicantContact / ApplicantAddress** — loan and account-opening intake.

### Person Account vs Account+Contact

FSC defaults to Person Account for retail consumer banking and wealth (one record = one human). B2B commercial banking and treasury management use Account+Contact. The choice is **org-wide and effectively permanent** — flip before data loads, not after.

## Patterns

### OmniStudio for financial workflows

- **OmniScripts** — guided experiences (New Client Onboarding with KYC, Account Opening, Financial Review, Goal Planning, FNOL). Extend, don't replace.
- **FlexCards** — Household View, Portfolio Snapshot, Policy Summary, Claim Status.
- **Integration Procedures** — server-side orchestration (parallel pulls from core banking + custodian + CRM, normalize, return).
- **Data Mapper** — system ↔ FSC translation for OmniScript and Integration Procedures.

### Agentforce Financial Services agents

Pre-built starting points; production customizes per institution.

| Agent | Default scope | Money-movement? |
|-------|---------------|-----------------|
| **Wealth Management Service** | Portfolio review, performance Q&A, rebalancing *suggestions* | No execution; advisor approves |
| **Personal Banking Service** | Account inquiries, transaction lookup, dispute initiation, card lock/unlock | Card lock as deterministic Action; disputes routed to human queue |
| **Insurance Service / FNOL** | Policy questions, claim status, FNOL intake | N/A (claim payout is separate human-approved process) |
| **Mortgage Origination** | Application status, document follow-up, rate questions | No commitment; underwriting human-gated |
| **Collections / Servicing** | Hardship intake, payment plan proposal | Plan execution requires deterministic gate |

### The money-movement deterministic gate — non-negotiable

**Any agent Action that moves money** (wire, ACH, card payment, internal transfer, claim disbursement, refund) must be a deterministic Apex or Flow Action, gated by explicit human approval, with an immutable audit record. **Never** let the LLM decide whether to execute money movement.

Pattern:

1. Agent gathers intent and parameters in natural language
2. Agent calls a *proposal* Action (returns a proposal record, not an executed transaction)
3. Proposal presented to user (advisor UI or consumer-app confirmation screen)
4. **Human confirms** via deterministic UI control (LWC button, step-up MFA where required)
5. Confirmation triggers separate deterministic Action that calls core banking via Named Credential, records on FinancialAccountTransaction, emits Platform Event
6. Event Monitoring captures the chain; Field Audit Trail retains for regulator-required period

If a user/PM/stakeholder asks for "one-shot" agent that wires money on free-text intent: refuse, escalate, do not ship.

### Read / propose / execute Action design rule

| Tier | Examples | Gate |
|------|----------|------|
| **Read** | Balance lookup, transaction history, policy summary, claim status | User-mode SOQL; Trust Layer masks PII; no human gate |
| **Propose** | Draft a transfer, suggest rebalance, build payment plan, generate dispute | Returns proposal record only; nothing posts to core |
| **Execute** | Post transfer, lock card, submit dispute, file FNOL with carrier | Human approval + step-up auth + audit event + Named-Credential call into system of record |

Mixing tiers in a single Action — "propose-and-execute if confidence > 0.9" — is the dangerous shortcut. Don't.

### Integration patterns

- **Pub/Sub API** for near-real-time transaction events from core banking. Replay window 72h.
- **MuleSoft Anypoint Banking Accelerator** — pre-built connectors for FIS (Profile, IBS, Horizon), Fiserv (DNA, Premier, Signature), Jack Henry (SilverLake, Symitar, Banno), Temenos (T24, Transact).
- **Plaid / Yodlee / MX** for held-away accounts (wealth aggregation, PFM).
- **Open Banking APIs** — UK Open Banking, EU PSD2 (AISP read, PISP money-movement gated), Brazil Open Finance, Australia CDR, India Account Aggregator.
- **Bureau callouts** (TransUnion, Experian, Equifax) via Named Credentials.
- **Idempotency keys** on every outbound state-changing call. **Retry with backoff** in MuleSoft / adapter, never in trigger context.
- **Reconciliation surface** — daily diff between FSC projection and core authoritative report. Discrepancies route to ComplianceCase or `Reconciliation_Exception__c`.

## Salesforce-specific compliance hooks

(Platform features the regulator-facing posture rides on. Interpretation belongs to fintech-architect core.)

- **Shield Platform Encryption** — deterministic for queryable fields (last-4 of account, masked TIN); probabilistic elsewhere
- **Field Audit Trail** — 10-year retention for regulated fields
- **Event Monitoring** — stream to Splunk / Snowflake / Data 360 for long-term retention
- **Hyperforce regional residency** — US, EU, UK, Canada, Japan, India, Australia, Brazil, UAE, KSA
- **Einstein Trust Layer masking** — mandatory for SSN, TIN, full account numbers, full card PANs, DOB

## Anti-patterns

- **Custom objects in place of FSC standard objects.** Fights the platform; breaks Agentforce FSC agent grounding, household sharing, OmniStudio templates, AppExchange add-ons.
- **Treating Salesforce as the ledger.** Reconciliation is daily; FSC is downstream.
- **Letting an Agentforce agent execute money movement on free-text intent.** Always deterministic Action + human gate + audit.
- **Storing full card PANs or unencrypted account numbers.** Fails Security Review and pulls Salesforce into PCI scope unnecessarily. Tokenize via Spreedly / Basis Theory / Very Good Security / processor-tokenized.
- **Streaming API / CometD for new transaction sync.** Use Pub/Sub API.
- **Embedded credentials in Apex callouts** to bureau or core banking. Always Named Credential + External Credential.
- **Big-bang core banking cutover.** Slice it; Pub/Sub + MuleSoft incrementally.
- **Synchronous LWC → core-banking callouts** for transaction history. Front with FSC projection; refresh async.
- **Connected Apps for new bureau/KYC integrations.** Use [External Client Apps](/stacks/salesforce/external-client-apps/) — Connected App creation blocked May 11, 2026.
- **Dual-writing the ledger into Salesforce.** Two ledgers, neither authoritative, reconciliation pain forever.
- **Agent confidence scoring as a gate.** Not a gate — it's a soft threshold on a non-deterministic component. Gates are deterministic checks and human approvals.

## Gotchas

- **Household sharing misconfiguration silently exposes** one household member's accounts to another. Test with personas (joint owner, authorized signer, beneficiary, advisor-of-record).
- **Balance freshness cadence** must be explicit per use case. UI "available balance" needs near-real-time; statement export tolerates nightly.
- **Encrypted fields must be declared in Setup** — retrofit requires mass re-encrypt.
- **Insurance + Banking + Wealth mix** in one org needs deliberate object scoping; not every FSC feature is on every license.
- **Ledger/PCI/PSD2/AML interpretation belongs to fintech-architect core.** This product page is the platform map.

## Cross-references

- Fintech-on-Salesforce depth: [fintech-architect on Salesforce](/stacks/salesforce/fintech-architect/)
- Agent design and Agent Script for money flows: [Agentforce](/stacks/salesforce/agentforce/), [ai-ml-engineer on Salesforce](/stacks/salesforce/ai-ml-engineer/)
- Trust Layer: [Einstein Trust Layer](/stacks/salesforce/einstein-trust-layer/)
- Apex patterns (Integration Procedures, async): [Apex](/stacks/salesforce/apex/), [backend-architect on Salesforce](/stacks/salesforce/backend-architect/)
- Encryption + audit: [security-engineer on Salesforce](/stacks/salesforce/security-engineer/)
- Authoritative: [FSC documentation](https://help.salesforce.com/s/articleView?id=sf.financial_services_cloud.htm)
