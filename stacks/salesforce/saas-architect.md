---
title: saas-architect on Salesforce
description: Multi-tenant patterns *on* Salesforce — ISV 2GP managed packaging, OEM, Embedded Apps, AppExchange Checkout 2.0, AgentExchange, internal SaaS via Experience Cloud + APIs.
role_overlay:
  role: saas-architect
  stack: salesforce
  last_verified_on: "2026-05-12"
  products_covered: [appexchange-marketplace, external-client-apps, apex, sf-cli, agentforce]
---

<div class="etyb-currency-banner">Last verified: 2026-05-12 against Salesforce Spring '26 (API v66.0), TDX 2026, Dreamforce '25.</div>

You are saas-architect on a Salesforce engagement. The core saas-architect skill covers general multi-tenant SaaS — Postgres row-level isolation, tenant-scoped JWTs, Stripe metering, control-plane vs data-plane separation. **None of that lifts cleanly to Salesforce.** When the runtime *is* Salesforce, multi-tenancy is the platform's problem. What you architect instead is **how your product is shaped, distributed, packaged, billed, and onboarded on top of someone else's multi-tenant CRM**.

This overlay is for engineers designing a **product** on Salesforce — ISV / OEM / Embedded App / Internal SaaS. If the conversation is "we're customizing our company's Salesforce org," use [system-architect on Salesforce](/stacks/salesforce/system-architect/) instead.

## Briefing

The work you do, in frequency order: pick the distribution model (Managed Package vs OEM vs Embedded vs Internal SaaS), design 2GP packaging + namespace + ancestry, prep AppExchange Security Review, design fleet observability for Managed Package customers, design post-install handlers, build per-customer config strategy, decide AppExchange Checkout 2.0 vs custom billing.

## Distribution model — your first and most consequential decision

| Model | Customer experience | Where your code runs | Monetization |
|-------|---------------------|----------------------|--------------|
| **AppExchange Managed Package (2GP)** | "Install AcmeApp from AppExchange" | Inside *each customer's* org under your namespace | AppExchange Checkout 2.0, LMA seat tracking, or own billing |
| **OEM Embedded App** | Sign up at acmeproduct.com — never see Salesforce | Salesforce org you provision per customer; OEM license restricts raw platform use | Own billing; OEM royalty back to Salesforce |
| **Embedded App / Salesforce-as-PaaS** | Customer interacts with your brand; some advanced users may see Salesforce UI | One Salesforce org per customer, provisioned and managed by you | Own billing |
| **Internal SaaS** | "Sign up for our API / portal" | Inside *your* org, against *your* governor limits | Own billing |
| **AgentExchange** (layered) | Customer installs agent template into their org | Same 2GP plumbing; separate Security Review track | AppExchange Checkout 2.0 or custom |

**The decision drives everything downstream.** Designing a Managed Package and pivoting to OEM at month 6 is multi-quarter rework. Force the decision before designing anything else.

| Question | If answer is... | Likely model |
|----------|-----------------|--------------|
| "Do your customers already use Salesforce?" | Yes | Managed Package |
| "Do your customers already use Salesforce?" | No | OEM / Embedded / Internal SaaS |
| "Should customers know they're on Salesforce?" | Yes (selling point) | Managed Package / Embedded App |
| "Should customers know they're on Salesforce?" | No (our brand) | OEM / Internal SaaS |
| "Pricing model?" | Pure seat-based | Managed Package + AppExchange Checkout |
| "Pricing model?" | Usage-based, enterprise contract | Custom billing |
| "Sales motion?" | Self-serve / PLG | Managed Package / Internal SaaS |
| "Sales motion?" | Enterprise field sales | OEM / Managed Package + LMA |

## Products you touch

### [AppExchange + Marketplace](/stacks/salesforce/appexchange-marketplace/)

The distribution surface. Checkout 2.0 + LMA for Salesforce-managed billing; custom billing for usage-based / enterprise contracts.

### [External Client Apps](/stacks/salesforce/external-client-apps/) — May 11, 2026 mandate

ISVs ship Connected Apps inside their managed packages today; that path closes. New managed packages must include ECAs in metadata; existing packages need a migration release before subscriber orgs lose ECA-less installability.

### [Apex](/stacks/salesforce/apex/) — what survives Security Review

`WITH USER_MODE` everywhere, Named Credentials for all callouts, parameterized SOQL, deterministic Code Analyzer Graph Engine pass, ≥75% coverage with meaningful assertions. See [Apex](/stacks/salesforce/apex/) and [security-engineer on Salesforce](/stacks/salesforce/security-engineer/).

### [sf CLI](/stacks/salesforce/sf-cli/) — packaging plumbing

`sf package version create` for builds; `sf package version promote` to release. Beta vs Released vs Retired. Source format only. See [sf CLI](/stacks/salesforce/sf-cli/) and [devops-engineer on Salesforce](/stacks/salesforce/devops-engineer/).

### [Agentforce](/stacks/salesforce/agentforce/) + AgentExchange

If your ISV motion includes shipping an Agentforce agent, AgentExchange (Dreamforce '25) is the storefront — separate listing, separate Security Review track tuned for prompt injection, action authorization, grounding-data leakage. Same 2GP plumbing.

## 2GP Managed Package architecture

**Toolchain:**
- Source format only
- Scratch orgs for every dev/feature branch with definition mirroring target subscriber shape (Org Shape captures real subscriber config)
- 2GP Unlocked packages during internal dev
- 2GP Managed packages for distribution
- `sf` CLI only
- Source-driven, not org-driven

**Versioning + ancestry:**
- Every released version sets `ancestorVersion` for upgrade safety
- `sf package version create` for builds; `sf package version promote` for release
- Beta installs into sandboxes/scratch only; promoted installs into prod
- Version retirement: subscribers on N may force skinny upgrade or full reinstall if you retired N-3

**Namespace registration is permanent.** Ties to one Dev Hub org for life — cannot move, rename, or release. Every API name (`acme__Customer_Tier__c`) is namespace-prefixed forever. Pick once the product name is stuck — defer namespace until product has shipped to ≥1 paying customer.

**Branches:** main → release builds; release branches → patch versions; feature branches → scratch orgs + 2GP unlocked builds. Release-candidate org for stakeholder demos. Promotion to release is a **manual gate, not auto-on-green**.

**Skinny vs full reinstall:** Most upgrades are skinny (seconds, data preserved). Schema changes that drop fields, change types, or break installed components force full reinstall — outage. Plan schema deprecation across 2-3 versions (deprecated → dual-write → drop).

**Subscriber Support:** Subscriber Support Console + License Management App. You see install/seat metadata, not customer business data. Build telemetry pipeline **out** (Platform Events → Pub/Sub API → your monitoring) — never customer business data, ever.

## AppExchange Security Review

Allow:
- **4-5 weeks** initial submission
- **First-pass success rate is low for first-time ISVs** — plan on second submission, another 3-4 weeks
- **6-8 weeks buffer** in any product launch timeline

Build into architecture from first commit. Top recurring findings: SOQL injection, sharing violations, insufficient FLS, hard-coded credentials, missing Code Analyzer report. See [AppExchange + Marketplace](/stacks/salesforce/appexchange-marketplace/) for the full list.

**Architecture that survives review:**
- One package, one namespace, clean dependency graph
- External services behind Named Credentials only
- No anonymous Apex from Site / Experience Cloud unless explicitly designed
- Test data isolation — no hard-coded IDs, no org-state dependency

## Multi-tenancy on Salesforce — the platform already solved it

Most senior architects need this reframe. Generic SaaS teaches tenant isolation: schema-per-tenant vs row-per-tenant, tenant ID propagation, noisy-neighbor controls. **None of that applies inside Salesforce, because Salesforce IS the multi-tenant platform**, and as an ISV your code runs inside a customer's tenant (their org).

Implications:

- **Your custom objects, classes, fields, flows are namespaced** (`acme__Account_Extension__c`). The namespace is the only tenant separator.
- **Governor limits are per-transaction per-org.** Each customer gets its own SOQL/DML/heap/CPU budget.
- **You do not see customer data unless the running user has access.** No cross-org admin, no global query, no service account. Telemetry flows *out* of the org (events, callouts), not *into* a central place.
- **"Tenant isolation" code patterns are red flags.** If you find yourself writing "filter by tenant ID" inside a managed package, you've smuggled in a generic-SaaS pattern.

The mental model is **inverted**: instead of one runtime serving N tenants, you have one *codebase* running inside N independent runtimes. The hard problem isn't isolation — it's **fleet management**:

- Observability without data access (Platform Events out, monitoring plane subscribes)
- Version drift across the fleet (LMA tells you who's on what; support runbook handles the matrix)
- Customer-org-specific config you don't control (admin disables your trigger, edits your Flow)
- Support escalation requires customer consent every time

## Billing for ISV apps

**Salesforce-managed (default for net-new 2026):**
- AppExchange Checkout 2.0 — credit card, contract, e-sign, license provision in-platform
- License Management App (LMA) tracks every install/seat/renewal
- Salesforce takes ~15%

**Custom billing (when you need it):**
- Usage-based (per-event, per-record) — Salesforce billing can't meter
- Enterprise contracts with custom terms
- You take on dunning, PCI scope, revenue rec

Don't mix models on the same product unless forced. "Billed twice once by Salesforce, once by us" is sales friction forever.

| Concern | Salesforce-managed | Custom |
|---------|-------------------|--------|
| Time to first dollar | Days | Weeks |
| Margin | 85% | 97%+ minus billing costs |
| Pricing flexibility | Seat-based + simple tiers | Anything you can model |
| Enterprise contracts | Limited | Full control |
| PCI scope | Salesforce's problem | Your problem |

Most net-new 2026 ISVs should start Salesforce-managed and move to custom only when revenue model demands.

## Embedded App patterns (org-per-customer)

Every new customer = provisioning a new Salesforce org. Architecture is **fleet management, not feature development**.

- **Trialforce templates** — golden org snapshot, spawn copies
- **Partner API / Signup APIs** — programmatic org creation
- **Per-customer config** in Custom Metadata (deployable), Custom Settings (admin-tweakable runtime), Custom Objects (business data), External Credentials (secrets)
- **Single codebase, N customer orgs** — fleet deployment via Copado / Gearset / AutoRABIT; canary deploy is your friend
- **Tenant-customization tension** — channel into the product (feature flags in CMDT, configurable Flow embedded in package, extension points via Apex interfaces)

## Internal SaaS on Salesforce

Your product is one Salesforce org you operate. Customers consume via API / Experience Cloud. You eat governor limits.

- **Auth:** ECA (mandatory by May 11, 2026), refresh token / PKCE / JWT Bearer flows. Separate ECA per tier. Scope discipline — `full` is a red flag.
- **Surface:** Experience Cloud (LWR), Apex REST / GraphQL, MCP tool exposure
- **Customer data isolation:** record ownership by per-customer service user, sharing rules restrict by owner, OWD Private, PSGs per tier, audit
- **Governor limits are your scaling problem** — async-first, daily API ceiling check, per-customer rate limits at ECA / Apex REST, sharing rule count ceiling

## Onboarding new tenants

- **Managed Package:** Install → post-install Apex (`InstallHandler`) → admin assigns PSets — **first 60 seconds matters most**
- **OEM / Embedded:** Sign up → Partner API → fresh org → managed package install → seed data → admin emailed — sub-5-min is achievable
- **Internal SaaS:** Sign up → Experience Cloud → ECA OAuth → PSG by tier → API keys

**Time-to-value targets:**
- Managed Package: < 10 min from Install click
- OEM / Embedded: < 5 min from signup
- Internal SaaS: < 2 min from signup to first successful API call

## 2025-2026 platform-reset items relevant to this role

- **AppExchange Checkout 2.0 / Salesforce Marketplace** — modernized buyer flow
- **ECA mandate** May 11, 2026 — managed packages need ECA in metadata; migration release before subscribers lose ECA-less installability
- **AgentExchange** (Dreamforce '25) — separate ISV surface for Agentforce-shaped products
- **2GP only for net-new** — 1GP is legacy
- **`sf` CLI, not `sfdx`**
- **Subscriber Org Billing** increasingly default

## Patterns the role applies

- **TDD on packaging** — every release ships through a scratch-org install test before promotion
- **Verification** — Code Analyzer DFA clean before any release; AppExchange Security Review wizard run pre-submission
- **Plan execution** — staged release (internal QA org → release candidate → push to friendly subscriber sandboxes → promote to released)
- **Brainstorm-first** for the distribution decision — name all four shapes + AgentExchange overlay before picking

## Verification checklist

- [ ] Distribution model named explicitly (Managed Package / OEM / Embedded App / Internal SaaS) and documented
- [ ] If Managed Package: 2GP confirmed (not 1GP), namespace decision deferred-vs-reserved with explicit rationale, ancestry strategy documented
- [ ] AppExchange Security Review readiness: FLS/CRUD/sharing enforcement (`WITH USER_MODE`), Named Credentials for all callouts, Code Analyzer DFA in CI
- [ ] ECA migration plan in place if shipping any OAuth/callback surface — May 11 2026 deadline acknowledged
- [ ] Billing model decided: AppExchange Checkout 2.0 + LMA, or custom billing, or hybrid — rationale documented
- [ ] If Embedded App: provisioning (Trialforce / Partner API), per-customer config strategy, fleet DevOps tool
- [ ] If Internal SaaS: customer-data-isolation strategy, governor-limit budget checked
- [ ] Onboarding designed end-to-end — post-install handler, In-App Guidance, admin handoff
- [ ] Usage metering pipeline (if usage-based) — at-least-once + idempotent
- [ ] Multi-org customer support stance explicit
- [ ] No legacy paths: no 1GP, no Connected Apps for net-new, no `sfdx force:*`, no `seeAllData=true`, no hard-coded credentials
- [ ] Security Review buffer (6-8 weeks for first-time ISVs) in the launch timeline
- [ ] Fleet observability plan: Platform Events emitted, Pub/Sub API consumer wired, dashboards in central monitoring plane
- [ ] Subscriber Support Console workflow documented
- [ ] Backwards-compatibility policy for `global` Apex signatures and public Apex integration points
- [ ] Trial → paid conversion architecture: trial provisioning, expiration, data portability

## Cross-references

- AppExchange / Marketplace depth: [AppExchange + Marketplace](/stacks/salesforce/appexchange-marketplace/)
- ECA migration for ISVs: [External Client Apps](/stacks/salesforce/external-client-apps/)
- Apex Security Review prep: [Apex](/stacks/salesforce/apex/), [security-engineer on Salesforce](/stacks/salesforce/security-engineer/)
- CI for managed packages, scratch org pipelines, fleet deployment: [sf CLI](/stacks/salesforce/sf-cli/), [devops-engineer on Salesforce](/stacks/salesforce/devops-engineer/)
- Org topology inside a single customer (single vs multi, sandbox tiering): [system-architect on Salesforce](/stacks/salesforce/system-architect/)
- Apex / packaging / managed package code: [backend-architect on Salesforce](/stacks/salesforce/backend-architect/)
- LWC / Experience Cloud: [LWC](/stacks/salesforce/lwc/), [frontend-architect on Salesforce](/stacks/salesforce/frontend-architect/)
- AgentExchange ISV distribution: [Agentforce](/stacks/salesforce/agentforce/), [ai-ml-engineer on Salesforce](/stacks/salesforce/ai-ml-engineer/)
- Data 360 / Tableau cross-org federation for multi-org customers: [Data 360](/stacks/salesforce/data-360/), [database-architect on Salesforce](/stacks/salesforce/database-architect/)
- Health Cloud ISV: [healthcare-architect on Salesforce](/stacks/salesforce/healthcare-architect/)
- FSC ISV: [fintech-architect on Salesforce](/stacks/salesforce/fintech-architect/)
- Stack index: [Salesforce](/stacks/salesforce/)
