# Salesforce Overlay — saas-architect

You are the saas-architect on a Salesforce engagement. The core saas-architect skill covers general multi-tenant SaaS patterns — Postgres row-level isolation, tenant-scoped JWTs, Stripe metering, control-plane vs data-plane separation. **None of that lifts cleanly to Salesforce.** When the runtime *is* Salesforce, multi-tenancy is the platform's problem, not yours; what you architect instead is **how your product is shaped, distributed, packaged, billed, and onboarded on top of someone else's multi-tenant CRM**. This overlay covers the four distribution models, 2GP packaging, AppExchange Security Review, ISV billing, embedded-app provisioning, internal-SaaS API monetization, and the footguns that sink first-time ISVs.

This file is for engineers designing a **product** on Salesforce — ISV / OEM / Embedded App / Internal SaaS. It is **not** for engineers building a custom CRM for one customer (that's `system-architect` territory). If the conversation is "we're customizing our company's Salesforce org," stop reading this overlay and use `system-architect.md`.

**Currency:** Spring '26 (API v66.0), TDX 2026, Dreamforce '25. Verify packaging APIs and AppExchange Checkout/Marketplace flows against current release notes before quoting specifics.

## What changed in 2025-2026 that older training data misses

- **AppExchange Checkout 2.0 / Salesforce Marketplace.** The buyer flow was rebuilt in 2026 — `AppExchange Checkout` is now the standard, default purchase path for paid managed packages. License Management App (LMA) still exists for seat tracking, but Checkout 2.0 handles the credit-card-to-license-record path end-to-end, supports multi-tier pricing pages, and integrates with Salesforce Marketplace promotion mechanics (featured listings, bundled offers). The old "fill out a form, our sales team will call you" pattern is no longer the recommended buyer experience for self-serve and SMB segments — enterprise field-sales motions still exist alongside, just no longer the default.
- **External Client Apps (ECA) mandate, May 11 2026.** ISVs ship Connected Apps inside their managed packages today; that path closes. New managed packages must include **External Client Apps** in the metadata, and existing packages need a migration release before subscriber orgs lose the ability to install ECA-less versions. This affects every ISV with OAuth, callbacks, or canvas apps.
- **AgentExchange (GA Dreamforce '25).** A new ISV surface alongside AppExchange specifically for distributing **Agentforce Topics, Actions, and Agent templates**. If your ISV motion is "ship an Agentforce agent that customers install into their org," this is the storefront. Separate listing, separate Security Review track, same 2GP packaging plumbing.
- **2GP is the only path for new ISV products.** 1GP managed packages are legacy as of 2026 — Salesforce will still service existing 1GP packages, but you cannot start a new ISV product on 1GP. Tooling (`sf package`), ancestry, and version promotion all assume 2GP.
- **`sf` CLI, not `sfdx`.** Same caveat as the rest of the pack. Any ISV CI pipeline still calling `sfdx force:package:version:create` is on a deprecated alias.
- **Subscriber Org Billing / Salesforce-collected billing** is increasingly the default for new ISVs — the platform handles the money, you focus on the product. Custom billing remains valid for usage-based and enterprise-contract pricing.

If you find yourself recommending 1GP, Connected Apps for net-new ISV releases, or the pre-2026 AppExchange buyer flow — you're on stale knowledge.

## Distribution model — your first and most consequential decision

Before you pick a packaging strategy, billing model, or onboarding flow, name which of these four shapes you're shipping. Each has different economics, different review surface, and different platform mechanics. They are not interchangeable.

| Model | What it is | Customer experience | Where your code runs | Monetization |
|-------|------------|---------------------|----------------------|--------------|
| **AppExchange Managed Package (2GP)** | You publish a package on AppExchange; customers install it into their existing Salesforce org | "Install AcmeApp from AppExchange" | Inside *each customer's* org, under their governor limits, under your namespace | AppExchange Checkout 2.0, LMA seat tracking, or your own billing |
| **OEM Embedded App** | You license Salesforce as the runtime for your product; your customers do not know they're on Salesforce | "Sign up at acmeproduct.com" — they never see Salesforce | Inside a Salesforce org you provision per customer; OEM license restricts them from raw platform use | Your own billing; OEM royalty back to Salesforce per seat |
| **Embedded App / Salesforce-as-PaaS** | Org-per-customer model where the customer logs into your branded Experience Cloud or your hosted surface | Customer interacts with your brand; some advanced users may see Salesforce UI | One Salesforce org per customer, provisioned and managed by you | Your own billing |
| **Internal SaaS** | Your product is one Salesforce org you own; customers consume it via API or Experience Cloud | "Sign up for our API / portal" | Inside *your* org, against *your* governor limits, against *your* license count | Your own billing, often per-API-call or per-seat |

**The decision drives everything downstream:**

- **Managed Package** → namespace, AppExchange Security Review, fleet upgrade strategy, FLS/CRUD enforcement from day one, customer org variability is the dominant risk.
- **OEM** → engage Salesforce ISV Partner team early (months of lead time), different licensing math, different review process, sales motion is enterprise-only.
- **Embedded App** → org provisioning automation (Trialforce, Partner API), fleet DevOps (Copado/Gearset), per-customer customization vs single codebase tension.
- **Internal SaaS** → you eat the governor limits; volume planning is YOUR problem; Experience Cloud and ECA become front-of-mind.

If the user hasn't decided which model they're shipping, **stop and force the decision** before designing anything else. Designing a Managed Package and pivoting to OEM at month 6 is multi-quarter rework.

**Choosing between the four** — the questions that actually decide it:

| Question | If answer is... | Likely model |
|----------|-----------------|--------------|
| "Do your customers already use Salesforce?" | Yes, almost all of them | **Managed Package** |
| "Do your customers already use Salesforce?" | No, most don't | **OEM**, **Embedded**, or **Internal SaaS** |
| "Should customers know they're on Salesforce?" | Yes — Salesforce is a selling point | Managed Package / Embedded App |
| "Should customers know they're on Salesforce?" | No — we want our own brand | **OEM** or **Internal SaaS** |
| "Do customers need to extend the app with their own Salesforce config?" | Yes — admin builds Flows, custom fields, reports | Managed Package or Embedded App |
| "Do customers need to extend the app with their own Salesforce config?" | No — they consume the product as-is | OEM or Internal SaaS |
| "How are you pricing?" | Pure seat-based, standard SaaS pricing | Managed Package with AppExchange Checkout |
| "How are you pricing?" | Usage-based, enterprise-contract, or hybrid | Custom billing across any model |
| "What's the sales motion?" | Self-serve / PLG | Managed Package (AppExchange = built-in distribution) or Internal SaaS |
| "What's the sales motion?" | Enterprise field sales | OEM, Managed Package + LMA, or Internal SaaS |

→ Cross-link upstream: `system-architect.md` covers the org-topology side of this same decision (single vs multi org, ISV vs internal).

**AgentExchange (2025+) is a fifth shape, layered on top of the four.** If your product is — or includes — an Agentforce agent (Topics, Actions, prompt templates, agent templates), you publish to **AgentExchange** rather than (or in addition to) AppExchange. Same 2GP packaging plumbing; separate listing, separate Security Review track tuned for agent-specific concerns (prompt injection, action authorization, grounding-data leakage). Net-new agent-shaped ISV products in 2026 default here; co-listing an agent companion to an existing AppExchange app is also common.

## 2GP Managed Package architecture

If the distribution model is AppExchange Managed Package, this is the spine of the architecture.

**Toolchain:**
- **Source format** (no metadata-API ZIPs). All metadata under `force-app/main/default/`, tracked in git.
- **Scratch orgs** for every dev/feature branch. `sf org create scratch` with a definition file that mirrors the target subscriber org shape (editions, features, settings). **Org Shape** captures a real subscriber's configuration for realistic test substrate.
- **2GP Unlocked packages** during internal dev (you control the package, no Security Review needed) — useful for shared internal libraries and for "factor out the platform layer" patterns where multiple managed packages depend on a common base.
- **2GP Managed packages** for distribution (namespaced, immutable versions, Security-Review-gated, AppExchange-listable). One Dev Hub, many packages possible.
- **`sf` CLI only.** `sfdx force:*` commands still work as deprecated aliases; CI pipelines should be on `sf package version create` / `sf package version promote` syntax.
- **Source-driven, not org-driven.** Every change starts in git, propagates to scratch org via `sf project deploy start`. The old org-as-source-of-truth pattern (build in dev org, retrieve metadata, hope) is incompatible with serious ISV cadence.

**Versioning and ancestry:**
- Every released managed package version sets `ancestorVersion` so subscribers can upgrade in any order without skipping required versions. Get ancestry wrong and you ship a release that subscribers can't install.
- `sf package version create` for builds; `sf package version promote` to release-grade (only promoted versions are installable in production orgs).
- **Beta vs Released:** beta versions install into sandboxes/scratch only; promoted/released versions install into production. Beta is freely deletable; promoted is permanent.
- **Version retirement:** you can deprecate old versions, but if a subscriber is on version N and you've retired N–3, their upgrade path may force a skinny upgrade or full reinstall.

**Namespace registration is permanent.** A namespace ties to one Dev Hub org for life — you cannot move it, rename it, or release it. Every API name your package ships (`acme__Customer_Tier__c`, `acme.OrderService`) is prefixed with the namespace forever. Pick once you know the product name will stick — most first-time ISVs reserve too early, then re-brand, then get stuck shipping a product whose internal API names don't match its marketing name. If the product is pre-PMF, defer namespace registration; use unlocked packages internally until naming stabilizes. Namespaces are also globally unique across Salesforce — short, generic, or brand-collision-prone names get taken; check availability before committing to marketing.

**Branches and build pipelines:**
- Main branch → release builds (managed, promoted)
- Release branches → patch versions for older majors
- Feature branches → scratch orgs + 2GP unlocked builds for review
- CI runs `sf package version create` on every merge to main; an internal QA org installs the latest version automatically.
- A **release-candidate org** holds the not-yet-promoted version for stakeholder demos and final QA. Promotion to release is a manual gate, not auto-on-green.
- **Push upgrades** to subscriber sandboxes during a release-candidate window — early adopters opt in, you catch upgrade issues before promoting to production-installable.

**Skinny upgrade vs full reinstall:**
- Most upgrades are **skinny** — subscribers install version N+1 over N in seconds, data preserved, metadata diff applied.
- Schema changes that drop fields, change field types, or break installed components force a **full reinstall** path — that's a customer outage and a hard sell.
- Plan schema deprecation across 2–3 versions: mark fields deprecated, dual-write, then drop in a clearly-flagged release. The discipline is the same as backwards-compatible API evolution, just slower-paced.

**Subscriber Support / login-as-a-customer:**
- **Subscriber Support Console** in your packaging org lets you log into customers' orgs (with their explicit grant) to triage issues. This is *the* support channel for ISVs — you cannot read their data via API, but you can log in as them when granted.
- License Management App is the rolodex: every install, every active license, every renewal date, every license type.
- Build a **telemetry pipeline** *out* of customer orgs (Platform Events → Pub/Sub API → your monitoring stack) for the data you do need — package version, error counts, feature usage. Never customer business data.

## AppExchange Security Review — design for it from day one

The review is non-negotiable for monetized AppExchange distribution. Treating it as "we'll fix what they flag at the end" is the most common cause of ISV launch delays. Bake these into architecture from the first commit.

**Mandatory disciplines:**

- **SOQL injection prevention.** Every SOQL query parameterized via bind variables (`:userInput`), never string concatenation. `String.escapeSingleQuotes()` is not sufficient on its own.
- **FLS / CRUD / Sharing enforced everywhere.** As of Spring '26, the right tool is `WITH USER_MODE` on SOQL/DML — it enforces FLS, CRUD, and sharing in one keyword, and the Code Analyzer Graph Engine recognizes it. Old patterns (`Security.stripInaccessible`, `Schema.DescribeFieldResult.isAccessible()`) still work but should be a last resort. Apex with `WITH SYSTEM_MODE` must have an explicit, justified comment — the reviewer will look.
- **No hard-coded credentials.** Every callout uses a **Named Credential** (or External Credential, the newer split). Hard-coded URLs, API keys, or OAuth secrets in Apex source are a Security Review fail.
- **No `seeAllData=true` test methods.** Tests must create their own data with TestDataFactory patterns; `@isTest(SeeAllData=true)` is grounds for rejection except in narrow Standard Pricebook cases.
- **Test coverage ≥75%, meaningful assertions.** Coverage alone doesn't pass review — the reviewer reads tests. `System.assertEquals(true, true)` is a flag. Each test asserts the actual behavior it claims to verify.
- **Salesforce Code Analyzer (Graph Engine) clean.** Run `sf scanner run dfa --target .` before submission. Path-based analysis finds FLS bypasses, SOQL injection, and unsafe DML that point-in-time linters miss. Ship with zero high-severity findings.
- **Customer Org Trust Layer pattern.** Your package code runs *inside the customer's org under the running user's permissions*. You — the ISV — cannot see customer data, and your code must respect what the running user is allowed to see. Architecturally: no package-level "admin escape hatch," no system-mode queries to read records the user can't, no service account that grants you cross-customer visibility.

**Review cycle reality:**
- Initial submission: 4–5 weeks.
- First-pass success rate for first-time ISVs is **low** — plan on a second submission, another 3–4 weeks. Experienced ISVs pass first time roughly half the time.
- Add **6–8 weeks of review buffer** to any product launch timeline that includes a paid AppExchange listing.
- Pre-submission, run the **AppExchange Security Review wizard** in your packaging org — it's a structured self-assessment that mirrors what the reviewers run, and catches ~60% of the issues an external reviewer would.
- Every release after the first needs review too. Patch versions can sometimes skip if the diff is scoped tightly, but assume each major version is a review event and plan release cadence accordingly. ISVs that try to ship every 2 weeks discover that AppExchange does not, in fact, ship every 2 weeks.

**Architectural shape that survives review:**
- **One package, one namespace, clean dependency graph.** Multi-package products (you ship a "base" package and an "extensions" package) are valid but compound the review surface — each package is its own review.
- **External services behind Named Credentials only.** A reviewer sees `https://` literals in Apex and rejects.
- **No anonymous Apex paths from Site / Experience Cloud** unless explicitly designed and reviewed — Guest User Profile permissions are a known attack surface and reviewers scrutinize them.
- **Test data isolation.** Tests don't call `Test.setMock` for production endpoints, don't hard-code IDs, don't depend on org state.

→ Cross-link: full Security Review playbook lives under `security-engineer.md` (iteration 2). This overlay summarizes what you architect *for*.

## Multi-tenancy on Salesforce — the platform already solved it

This is the conceptual reframe most senior architects need. The core saas-architect skill teaches you to design tenant isolation: schema-per-tenant vs row-per-tenant, tenant ID propagation, noisy-neighbor controls, control-plane separation. **None of that applies inside Salesforce, because Salesforce *is* the multi-tenant platform**, and as an ISV your code runs *inside* a customer's tenant (their org).

Implications:

- **Your custom objects, classes, fields, and flows are namespaced** (`acme__Account_Extension__c`, `acme.CustomerService.processOrder()`). The namespace prefix is the only "tenant separator" you need.
- **Governor limits are per-transaction per-org.** Each customer org gets its own SOQL/DML/heap/CPU budget. You are not splitting one pool of capacity across N tenants — every install gets its own pool. (Caveat: per-org limits *do* squeeze when an admin uses your package alongside many others. Defensive bulkification is still mandatory.)
- **You do not see customer data unless the running user has access.** No cross-org admin, no global query, no service account. Telemetry has to flow *out* of the org (events, callouts to your telemetry endpoint) — not be read *into* a central place. License Management App is the rare exception; it sees install/seat metadata, not customer business data.
- **"Tenant isolation" code patterns are red flags.** If you find yourself writing logic that says "filter by tenant ID" inside a managed package, you've smuggled in a generic-SaaS pattern that doesn't belong. The org is the tenant; SOQL inside that org returns only that org's data by definition.

The mental model is **inverted from generic SaaS**: instead of one runtime serving N tenants, you have one *codebase* running inside N independent runtimes (orgs). The hard problem isn't isolation — it's **fleet management**:

- **Observability** without data access. You can ship Platform Events that emit on errors/feature usage; customers grant consent; you subscribe via Pub/Sub API from your central monitoring plane. Without this, you find out about bugs from support tickets, weeks late.
- **Version drift across the fleet.** Even with skinny upgrades, customers defer; six months in you support N versions in production. The LMA tells you who's on what; your support runbook has to handle the matrix.
- **Customer-org-specific config you don't control.** Subscriber admin disables your trigger, edits your Flow, adds a validation rule that breaks your callout. You designed for one configuration; production has N. Defensive code, clear error messages, and "package configuration health check" tooling matter more than they would in a SaaS you control end-to-end.
- **Support escalation requires customer consent every time.** Subscriber Support Console grants are time-bounded; complex bugs may require multiple grants to triage. Design for triage from the start (log packs the customer can download, structured error objects, custom debug logs scoped to your namespace).

## Subscription / billing for ISV apps

**Salesforce-managed billing (recommended default for net-new in 2026):**
- **AppExchange Checkout 2.0** is the modernized buyer experience — credit card, contract, e-sign, license provision all in-platform.
- **License Management App (LMA)** lives in your packaging org and tracks every install, every license-seat-count, every renewal date across your subscriber base. License records sync automatically from AppExchange.
- **License types you provision:** Site (org-wide), Per-user (seat-counted), Provisional (trial), Trialforce (full trial-org spin-up).
- Salesforce collects the money, takes their cut (~15% standard ISV margin take), and deposits the rest. You don't run dunning, PCI, or invoicing.

**Custom billing (when you need it):**
- **Usage-based pricing** (per-event, per-API-call, per-record-processed) — Salesforce billing can't meter that, so you bill direct.
- **Enterprise contracts** with custom terms, multi-year discounts, mid-cycle seat changes — direct billing through Salesforce's own billing system, Stripe, or your existing platform.
- LMA still tracks installs/seats; you reconcile against your billing system out-of-band.
- You take on dunning, invoicing, PCI scope, and revenue recognition.

**Don't mix models on the same product** unless you have to. Pick one and be deliberate. Mixed-model ISVs have to explain to every prospect "you'll be billed twice, once by Salesforce and once by us, and here's why" — a sales friction tax you pay forever.

**The decision matrix:**

| Concern | Salesforce-managed (Checkout 2.0 + LMA) | Custom billing |
|---------|------------------------------------------|----------------|
| Time to first dollar | Days | Weeks (set up Stripe, dunning, invoicing) |
| Margin | 85% (Salesforce takes ~15%) | 97%+ minus your billing-platform costs |
| Pricing flexibility | Seat-based + simple tiers | Anything you can model |
| Enterprise contract terms (multi-year, custom SLAs) | Limited | Full control |
| PCI / revenue rec scope | Salesforce's problem | Your problem |
| Buyer experience | Salesforce-native, frictionless for existing customers | You design it |
| Marketplace discoverability boost | Yes (AppExchange Checkout is featured) | No |

The 85% vs 97% margin difference is real but often dominated by the time-to-launch and sales-friction wins of Salesforce-managed. Most net-new ISVs in 2026 should start there and move to custom billing only when revenue model demands it.

→ Cross-link: general billing patterns (Stripe, metering, recognition) live in the core `saas-architect` skill — this overlay covers only what's Salesforce-specific.

## Embedded App patterns (org-per-customer)

When your distribution model is Embedded App / Salesforce-as-PaaS / OEM, every new customer means **provisioning a new Salesforce org**. The architecture is fleet management, not feature development.

**Provisioning automation:**
- **Trialforce templates** — a "golden org" you snapshot, then spawn copies for trials or new customers. Managed Package installed, sample data loaded, branding applied.
- **Partner API / Signup APIs** — programmatic org creation. New customer signs up on your marketing site → background job calls Signup API → fresh org provisioned → managed package installed → admin user created → handoff email sent.
- **Org Shape (scratch orgs)** for internal testing of the provisioning flow; production provisioning uses Trialforce or Partner API.

**Per-customer configuration — where to store it:**

| Customization shape | Storage | Why |
|---------------------|---------|-----|
| Settings the admin should change in UI (workflow toggles, defaults) | **Custom Metadata Types** | Deployable, packageable, versioned with your code, queryable in tests without DML |
| Per-user preferences (UI prefs, last-viewed) | **Custom Settings (Hierarchy)** | Per-user/profile/org without deployment, fast cached reads |
| Customer-specific business data | **Custom Objects** | Standard record model, sharing rules apply, reportable |
| Per-customer feature flags | **Custom Metadata Types** | Deployable, version-aware, can ship default values, A/B testable |
| Per-customer secrets (API keys, tokens) | **External Credentials** | Encrypted at rest, scoped to Named Credentials, never in source |
| Per-customer branding (logo, colors) | **Custom Metadata + Static Resources** referenced from LWC | Packageable, replaceable per environment |

Don't put per-customer configuration in **Apex constants** — every customer gets the same value, you ship a release to change one. Don't put it in **Custom Settings (List)** — they don't deploy via metadata API cleanly.

**Single codebase, N customer orgs — DevOps strategy:**
- One git repo, one CI pipeline, fleet deployment via **Copado / Gearset / AutoRABIT** to all customer orgs (or a subset under controlled rollout).
- Treat customer orgs as **environments**, not as branches — same code, environment-specific config in Custom Metadata.
- Monitor each org's package version; alert when an org falls behind or hits an upgrade error.
- **Canary deployment** is your friend: roll a new release to 1–2 friendly customer orgs, watch for 24–72 hours, then proceed to the fleet. The customer-by-customer blast radius means you cannot hotfix all N orgs in one push.

**Tenant-customization tension.** Customers will ask for "just one small change for us" within months. Reflexively saying yes turns a single codebase into N forks within a year. Channel customization into the **product**: feature flag in Custom Metadata, configurable Flow embedded in your package, extension points exposed via Apex interfaces customers can implement in their own (non-namespaced) classes. The discipline is the same as multi-tenant SaaS configuration vs customization — you've just inherited it on a platform that makes one-off customization seductively easy.

## Internal SaaS on Salesforce — your customers consume via API

Your product is one Salesforce org you operate. Customers don't install anything; they call your API, hit your Experience Cloud site, or both. You eat the platform's costs and limits.

**Auth surface:**
- **External Client Apps (ECA, mandatory by May 11 2026)** for customer OAuth. The path that was Connected Apps closes — design net-new auth on ECA from day one.
- Refresh token flows for backend integrations; PKCE flows for SPA / mobile customers; **JWT Bearer flow** for server-to-server with no user context.
- Separate ECA per customer tier or scope set — easier to revoke, audit, and rate-limit.
- **Scope discipline.** Customers' security teams will read the scopes you request. `full` is a red flag; `api` + `refresh_token` + scoped object permissions read much better. ECA's scope model is more granular than the old Connected App pattern — use it.

**Surface technology:**
- **Experience Cloud (LWR template)** for branded customer-facing portals. Login, dashboards, self-service forms, document upload.
- **Apex REST / Apex GraphQL (Spring '26 `lightning/graphql` adjacent)** for headless API access.
- **MCP tool exposure (Headless 360, GA April 2026)** when customers want their AI agents to drive your service — newer, but it's the 2026 differentiator.

**Customer data isolation (this *is* your problem now, because everyone's data lives in one org):**
- **Record ownership** by a per-customer service user (one user per customer account in your org).
- **Sharing rules** restrict customer-A's users to records owned by customer-A's service user. OWD set to Private for every customer-data object.
- **Permission Set Groups (PSGs)** assigned per customer tier — `acme_customer_basic_psg` vs `acme_customer_pro_psg`.
- **Audit:** Shield Event Monitoring or custom audit objects logging every cross-tenant query path (there should be none in normal operation).

**Governor limits are now your scaling problem.** N customers × M average operations per minute must fit inside your org's per-transaction limits. This is the inverse of the Managed Package model — there, each customer brings their own org budget; here, all customers share one. If your projected volume can saturate sync SOQL/DML or daily API entitlements, you must architect:

- Async-first: Queueable, Batch, Apex Cursors for anything bursty.
- **Daily API request limit** ceiling check — Internal SaaS orgs hit it faster than admins expect. Buy additional API entitlement, or front the org with MuleSoft and rate-limit there.
- **Per-customer rate limits** at the ECA / Apex REST surface so one customer can't starve the rest.
- **Sharing rule count ceilings** — Salesforce caps owner-based sharing rules per object, and Internal SaaS orgs with hundreds of customer-service-users hit this faster than you'd think.

## Onboarding new tenants on Salesforce

Per distribution model:

- **Managed Package:** customer clicks Install on AppExchange → managed package lands in their org → your post-install Apex script runs setup (default Custom Metadata, sample reports, permission sets) → customer admin assigns permission sets to users → done. The **post-install handler** (`InstallHandler` Apex interface) is critical; this is your "first 60 seconds" experience and most ISVs neglect it. The handler runs in **system mode under the installing admin's context** — use it for org-wide setup, not user-facing prompts.
- **OEM / Embedded:** customer signs up on your branding → background job calls Partner API → fresh org provisioned → managed package installed → seed data loaded from a Trialforce template → admin user emailed credentials → SSO configured if applicable. Provisioning lead time matters — sub-5-minute end-to-end is achievable and a real differentiator vs incumbents running on legacy stacks.
- **Internal SaaS:** customer signs up on your Experience Cloud site → ECA-based OAuth → permission set group assigned by tier → API keys issued → optionally a SCIM connector configured for their IdP. Tier upgrades / downgrades just toggle the permission set group; design for it.

**Customer admin handoff:** every model needs a clear "now you own this" moment. Documentation, in-app guidance (Walkthroughs / In-App Guidance), a setup checklist. ISVs that skip this rack up support tickets that are 100% configuration issues — the package works, the customer never finished setup.

**Time-to-value (TTV) is the metric that matters.** Managed packages that take 4 hours to install + configure + verify lose to managed packages that take 20 minutes, every time. Architect the post-install handler to do as much as possible automatically — default Custom Metadata records, sample data (clearly flagged as deletable), permission set assignments to the installing admin, a "Setup Complete?" health check page. The first impression of your product is "did the install just work?" — and that's an architectural decision, not a docs problem.

**Per-model TTV targets that are achievable in 2026:**

| Model | "First useful action" target | Why it matters |
|-------|------------------------------|----------------|
| Managed Package | < 10 minutes from Install click | Self-serve buyers churn fast; AppExchange ratings live and die on this |
| OEM / Embedded | < 5 minutes from signup → branded org provisioned | Direct comparison vs incumbents on non-Salesforce stacks |
| Internal SaaS | < 2 minutes from signup → first successful API call | Developers benchmark every API onboarding against the fastest one they've used |

Miss these by 10x and your funnel leaks at onboarding — fix the install/setup experience before fixing the product.

## Usage metering on Salesforce

If your billing is purely seat-based, **LMA seat counts are sufficient** — Salesforce reports them, you bill from them. Done.

If your billing is usage-based (per-event, per-record-processed, per-API-call):

- **Apex callouts to your billing backend** at the point of usage — counted increment to a Stripe meter, a Snowflake event, or your own metering service.
- **Big Objects** for in-org metering history at scale — billions of usage records, queried via Async SOQL for monthly invoicing.
- **Platform Events + Pub/Sub API** to stream usage events out of customer orgs to your central metering pipeline (managed package emits a Platform Event; you subscribe via Pub/Sub API from outside).
- **Salesforce Marketplace usage records** (newer mechanism, 2026) — Salesforce-blessed path for reporting usage back to AppExchange Checkout for usage-based monetization. Worth evaluating for net-new; ecosystem still maturing.

The **architecture risk** is double-counting and missed events. Design the metering pipeline with at-least-once semantics + idempotent ingest; never trust that a one-shot Apex callout succeeded without retry.

**Patterns to follow:**
- **Buffer-then-flush** in a custom object (`acme__UsageEvent__c`), processed in batches by a scheduled Queueable that POSTs to your billing backend and marks records as sent. Failed sends stay unmarked, retry next batch.
- **Idempotency key = (org_id, event_id)** so the backend can dedupe on its side.
- **Per-customer-org reconciliation reports** monthly — fetch your billing system's totals, fetch the customer org's `acme__UsageEvent__c` totals, alert on mismatch >0.5%.
- **Never bill for events you can't show the customer.** Customer self-service usage dashboards (Experience Cloud, LWC, or even an in-org report) are an architectural requirement, not a UX nice-to-have — disputes get resolved in minutes instead of weeks.

## Cross-org architecture for multi-org SaaS

Some enterprise customers want multiple orgs — different business units, different geographies, different regulatory boundaries. As an ISV you may be asked to support a customer who runs your managed package in 3+ of their own orgs and wants unified reporting.

- **Data 360 federation** — each customer org connects to a customer-owned Data 360 instance; your reports run against the federated layer, not against any single org. Zero-copy to Snowflake/Databricks/BigQuery becomes the lingua franca.
- **MuleSoft** for cross-org integration when the customer needs synchronous read/write across orgs — heavy, license-cost, used when Data 360 isn't enough.
- **Managed package design considerations:** anything you assume "lives in this org" must be designed as "lives in *one* of N orgs" if you're selling into customers with multi-org topologies. Cross-org IDs, cross-org foreign keys, cross-org permission sets — all need explicit thought.

This is enterprise-only territory; SMB ISVs can usually defer. But **don't accidentally preclude it** in your package design: if your managed package assumes a single Account hierarchy, a single set of Custom Metadata records, or a single integration target, refactoring to support multi-org customers later is expensive. Build the seams (configurable endpoints, parameterized integrations, no global state) even if you don't activate them in v1.

## Common ISV footguns

The mistakes that show up repeatedly in first-product launches:

- **Starting on 1GP managed package.** Legacy. 2GP only for net-new in 2026.
- **Reserving namespace too early.** Permanent decision. Defer until product name has shipped to ≥1 paying customer.
- **Not designing FLS/CRUD/Sharing enforcement from day one.** Bolting `WITH USER_MODE` onto an existing codebase before Security Review is weeks of rework. Build it into the first commit.
- **Hard-coded URLs / org-specific assumptions.** "We'll just call https://acme.my.salesforce.com" — your package will fail in every other customer's org. Use `URL.getOrgDomainUrl()`, Named Credentials, custom settings — never literal hosts.
- **Sharing rules that work in dev but fail in customer orgs.** Your dev org's OWD is `Public Read/Write`; the customer's is `Private`. Your package logic assumed visibility that doesn't exist for them. Test against `Private` OWD scratch orgs.
- **Forgetting ECA migration.** Connected Apps inside managed packages stop being installable after May 11 2026. Plan the ECA migration release into the roadmap *now*, not at the deadline.
- **Underestimating Security Review cycle.** Architects who treat it as "submission week" instead of "8-week ongoing process" miss launch dates. Build it into release planning as a first-class milestone.
- **Breaking managed package backwards compatibility mid-life.** Apex global methods, global classes, and global custom metadata records are part of your contract — subscribers may have built against them. You cannot remove or change global signatures without a forced reinstall and a customer-side code change. Promote to global only when you mean it forever; default everything else to public.
- **Trigger-per-object proliferation in customer orgs.** Your managed package ships a trigger on `Account`; the customer already has 3 triggers on `Account`; their AppExchange-installed-other-app ships a 4th. Order of execution becomes unpredictable. Mitigate: use Apex's trigger handler pattern, expose extension hooks rather than expecting the trigger to do everything, document trigger order expectations in install docs.
- **Not testing against `Private` OWD + locked-down profile.** Most ISV dev orgs default to permissive OWD and System Admin testing. Your customer's org is the opposite. A managed package that "works in dev, breaks at the customer" almost always has FLS/sharing assumptions that didn't hold up. Spin up a scratch org with Private OWD and a Standard User profile, run your install test there before promoting any release.
- **Designing for "the customer's admin will figure it out."** Most won't. Your post-install handler, In-App Guidance, and setup wizard are part of the product, not afterthoughts.
- **Shipping a managed package without a sandbox install test.** Promoted package versions are immutable — if v1.0.0 doesn't install cleanly in a Partial Copy sandbox shape, you ship v1.0.1 immediately and v1.0.0 is dead inventory.
- **Choosing custom billing when Salesforce-managed would have served.** "We want full control of the checkout" sounds good in week 1 and costs you a sales cycle every customer in year 2. Default to AppExchange Checkout 2.0 unless usage-based or enterprise contracts force custom.
- **Treating Trialforce as a marketing site.** Trial orgs are full Salesforce orgs running your package — they have governor limits, they generate support tickets, they have a TTV cliff if onboarding is bad. Trial conversion is an architectural concern, not a marketing one.
- **No post-install handler.** First-install experience is "admin clicks Install, lands on a confused page wondering what to do next." TTV craters; renewal probability drops with it.
- **Skipping fleet observability.** "We'll know if customers have problems because they'll tell us." They will tell you, in support tickets, weeks late, in the worst version of the story. Platform Events → your monitoring plane from day one.
- **Not budgeting for the Subscriber Support Console.** Customers grant you login access; you triage. ISVs that staff for "self-service support only" discover that enterprise customers expect a human, and find a competitor who provides one.

## A note on ISV economics and the "platform tax"

ISVs new to Salesforce often balk at the platform's revenue share, license-cost passthrough, and packaging constraints. The reframe: you are buying **distribution, runtime, identity, integration, and trust** as a bundle. AppExchange puts your product in front of millions of admins. Hyperforce gives you global multi-region without ops. Trust Layer gives you AI grounding with audit and zero retention. Security Review gives prospects a baseline assurance you didn't have to negotiate. The 15% margin take is the price of bundling those — and for net-new ISVs, it is usually cheaper than building them.

The ISVs who lose money on the platform are the ones who treat it as a hosting choice rather than a distribution channel. If your product wouldn't benefit from "every Salesforce admin can install you in 60 seconds," you may be on the wrong platform — and the right answer is **Internal SaaS** consumed via API, or moving off Salesforce entirely. Don't pay the platform tax for distribution you're not using.

## Verification checklist for saas-architect on Salesforce

Before declaring the ISV architecture done, prove:

- [ ] Distribution model named explicitly (Managed Package / OEM / Embedded App / Internal SaaS) and documented — not implicit, not "we'll figure it out."
- [ ] If Managed Package: 2GP confirmed (not 1GP), namespace decision deferred-vs-reserved with explicit rationale, ancestry strategy documented.
- [ ] AppExchange Security Review readiness: FLS/CRUD/sharing enforcement pattern defined (`WITH USER_MODE` preferred), Named Credentials for all callouts, Code Analyzer DFA in CI, test-coverage and assertion discipline documented.
- [ ] ECA migration plan in place if shipping any OAuth/callback surface — May 11 2026 deadline acknowledged.
- [ ] Billing model decided: AppExchange Checkout 2.0 + LMA, or custom billing, or hybrid — with rationale and the sales-friction tradeoff understood.
- [ ] If Embedded App: org provisioning automation (Trialforce / Partner API), per-customer config strategy (Custom Metadata vs Custom Settings vs Custom Objects), fleet DevOps tool (Copado / Gearset) selected.
- [ ] If Internal SaaS: customer-data-isolation strategy (record ownership + sharing rules + PSGs) documented, governor-limit budget for projected load checked.
- [ ] Onboarding flow designed end-to-end — post-install handler, In-App Guidance, admin handoff materials.
- [ ] Usage metering pipeline (if usage-based pricing) — at-least-once + idempotent.
- [ ] Multi-org customer support stance (Data 360 / MuleSoft / "not supported in v1") explicit.
- [ ] No legacy paths in the architecture — no 1GP, no Connected Apps for net-new, no `sfdx force:*` in CI, no `seeAllData=true` in tests, no hard-coded credentials.
- [ ] Security Review buffer (6–8 weeks for first-time ISVs) in the launch timeline.
- [ ] Currency check: AppExchange Checkout 2.0, AgentExchange, ECA mandate all reflected in the design where relevant.
- [ ] Fleet observability plan: Platform Events emitted from package, Pub/Sub API consumer wired, dashboards in your central monitoring plane.
- [ ] Subscriber Support Console workflow documented: who handles grants, SLA, log-collection patterns.
- [ ] Backwards-compatibility policy for `global` Apex signatures, public Apex used as integration points, and custom metadata records subscribers may reference.
- [ ] Trial → paid conversion architecture: trial org provisioning, trial expiration handling, data-portability story when customer upgrades or churns.
- [ ] If targeting Health / FSC / Public Sector verticals: vertical-specific data model awareness and handoff to the vertical-architect documented.

## Escalation map

| If the request becomes about... | Hand off to |
|---------------------------------|-------------|
| General multi-tenant patterns (Postgres RLS, Stripe metering, control-plane / data-plane separation) | `saas-architect` *without* this pack overlay |
| Org-topology decisions inside a single customer (single vs multi org, sandbox tiering) | `system-architect` with this pack |
| Writing the actual Apex / packaging / managed package code | `backend-architect` with this pack |
| Building the actual LWC / Experience Cloud surface | `frontend-architect` with this pack |
| CI for managed packages, scratch org pipelines, fleet deployment tooling | `devops-engineer` with this pack (iteration 2) |
| AppExchange Security Review prep, ECA migration, FLS enforcement playbook | `security-engineer` with this pack (iteration 2) |
| Compliance specifics for Health Cloud ISV products | `healthcare-architect` (HIPAA/FHIR) |
| Compliance specifics for FSC ISV products | `fintech-architect` (ledger/PCI/PSD2) |
| Agentforce Topic/Action ISV distribution via AgentExchange | `ai-ml-engineer` with this pack |
| Data 360 / Tableau cross-org federation for multi-org customers | `database-architect` with this pack (iteration 2) |
| Trial-org provisioning automation and Trialforce template lifecycle | `devops-engineer` with this pack (iteration 2) |
