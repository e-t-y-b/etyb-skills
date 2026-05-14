---
role: security-engineer
stack: stripe
last_verified_on: "2026-05-14"
last_verified_api_version: "2025-11-15.acacia"
---

# Stripe Overlay — security-engineer

You are security-engineer on a Stripe engagement. The Stripe surface in 2026 has three security planes that all need attention: **PCI scope reduction** (which integration path you pick changes your audit burden by orders of magnitude), **key + credential hygiene** (publishable / secret / restricted / webhook signing secret — different threat models for each), and **fraud + authentication** (Radar configuration, 3DS2/SCA compliance for EU/UK, Connect platform liability). Get these wrong and the consequences range from a failed SAQ to material customer harm.

**Currency:** Stripe API `2025-11-15.acacia` and PCI DSS v4.0.1. PCI DSS v4.0 enforcement began 31 March 2024; v4.0.1 (clarifications) released June 2024. Verify against current PCI Security Standards Council docs and [docs.stripe.com/security](https://docs.stripe.com/security) if more than 6 months past `last_verified_on`.

## What changed in 2025-2026 that older training data misses

| Change | Effective | Implication |
|--------|-----------|-------------|
| **PCI DSS v4.0 enforcement** of previously "best practice" controls | March 31, 2024 → fully enforced 2025 | Targeted risk analyses, anti-phishing controls, account-data inventory all required. The "we'll do it later" grace period is over. |
| **PCI DSS v4.0 requirement 6.4.3** — managing payment page scripts | Enforced 2025 | All scripts on the payment page must be inventoried, authorized, and integrity-monitored. Affects SAQ-A-EP merchants heavily. Stripe published guidance on `script-src` and SRI patterns. |
| **PCI DSS v4.0 requirement 11.6.1** — change-and-tamper detection on payment pages | Enforced 2025 | Real-time detection of payment-page modifications. Stripe's Elements handles this for SAQ-A-EP scope, but you must wire monitoring on your own page. |
| **SCA enforcement maturity** in EU/UK/EEA | Continuous through 2024-2026 | Mandatory; no longer "soft launching." Non-compliant flows are silently declining at the issuing bank. |
| **Stripe Radar ML model updates** + Adaptive Acceptance | Ongoing | Block-list patterns shifted — Adaptive Acceptance can over-ride blocks with good signal. Rules need re-tuning at least annually. |
| **Restricted API keys** GA + recommended | Ongoing through 2024-2026 | Service-to-Stripe integrations should use restricted keys. "Just use the secret key" is now a finding in security review. |
| **Stripe-hosted MCP** for agents | 2025 | Agents can drive Stripe. The threat model now includes prompt injection that triggers Stripe operations. Restricted keys + audit logging + scoped operations are mandatory. |
| **Connect platform liability shifts** under controller properties | 2024 | The `controller.losses.payments` field makes liability explicit (Stripe or platform). Misconfigured platforms now have a clear field to point at when liability is disputed. |
| **3DS2 (3-D Secure 2)** is the default; legacy 3DS1 sunset | 2024 onward | If you see 3DS1 flow code, it's dead. PaymentIntents handle 3DS2 transparently. |

If you find yourself recommending "the secret key is fine for our analytics job," "we'll add CSP later," or "we don't need to monitor our payment-page scripts because Elements handles PCI" — you're using stale knowledge or misunderstanding scope. Read on.

## PCI DSS scope — the decision that dominates everything else

Your PCI scope is determined by **how cardholder data enters and traverses your environment**, not by the payment processor you chose. Picking Stripe doesn't make you SAQ-A; picking Stripe **a certain way** can.

### The three integration paths and their PCI scope

| Integration | What touches your servers | PCI scope | SAQ |
|-------------|---------------------------|-----------|-----|
| **Stripe Checkout (hosted)** | Customer is redirected (or embedded iframe) to Stripe-hosted page. Cardholder data never enters your DOM, never your servers. | Lowest | SAQ-A |
| **Stripe Elements / Payment Element** | Card inputs are Stripe-hosted iframes embedded in your page. You can style the surrounding form, but Stripe owns the input fields and the token submission. | Low, but page-level | SAQ-A-EP |
| **Raw API (custom card form)** | Your page captures the card number, expiry, CVC into your form, you POST to Stripe. Cardholder data is in your DOM and (briefly) in your network. | Highest | SAQ-D |

### SAQ-A — Stripe Checkout

Roughly 22 questions, mostly about general security hygiene (no plaintext storage of card data, secure auth to your hosting provider, change management). The card data never touches you; you certify you're not doing anything that would change that.

**This is the default recommendation for any new build that doesn't have a hard reason to take more scope.** The Optimized Checkout Suite gives you Apple Pay, Google Pay, Link, BNPL methods, Adaptive Pricing, smart payment method ordering — all without you adding PCI scope.

### SAQ-A-EP — Elements / Payment Element

Roughly 197 questions. You're not handling card data directly, but the *page that hosts the card-entry iframe* is in scope. This means:

- **Your web server hosting that page is in scope.** Hardening, change management, vulnerability scanning all apply.
- **The page's scripts are in scope under PCI DSS v4.0 requirement 6.4.3.** Every script that runs on the page must be inventoried, authorized, and integrity-monitored. Third-party scripts (analytics, ads, chat widgets) on the payment page need explicit review.
- **The page must be change-detected under 11.6.1.** Real-time detection of tampering with the payment page.
- **Quarterly ASV scan** required.

Stripe.js does the heavy lifting (the iframe boundary keeps card data out of your DOM), but you own everything around it. Teams routinely underestimate this — they pick Elements expecting SAQ-A, then discover the audit asks for 197 things.

### SAQ-D — custom form

You're capturing card data into your form. **Avoid this for new builds.** PCI scope expands to your entire CDE (cardholder data environment): networks, servers, applications, processes touching card data. Quarterly internal/external vulnerability scans, annual penetration test, network segmentation enforcement, key management for stored card data, the whole catalog of ~330 requirements.

Reasons people end up in SAQ-D:
- Custom card form pre-Elements era — should migrate to Elements
- Capturing card data for a phone-order flow — should use the [MOTO Payment Element](https://docs.stripe.com/payments/payment-element) or Terminal
- Vault-and-multi-PSP architecture using a third-party tokenization layer (Spreedly, Basis Theory) — different threat model; consult their specific guidance

### How to recommend the right integration

```
Is this a net-new build with no special UX constraints?
   → Stripe Checkout (SAQ-A). Stop here.

Is the constraint "we need our own form layout but standard inputs"?
   → Payment Element (SAQ-A-EP). Plan for v4.0 6.4.3 / 11.6.1 controls.

Is the constraint "we have a multi-PSP architecture or vault"?
   → Talk to security-engineer outside this overlay; this is multi-PSP territory.

Is the constraint "we accept phone orders"?
   → Terminal SDK or MOTO Payment Element. Don't roll your own.

Is anyone proposing "custom card form, send to Stripe"?
   → Push back. Justify the PCI scope or use Elements.
```

### PCI DSS v4.0 controls specific to SAQ-A-EP merchants

The two big ones, both enforced as of 2025:

**6.4.3 — Payment page scripts management.** Every script element on the payment page (or pages hosting the payment iframe) must be:
- Authorized — there's a documented approval that this script can run on this page
- Justified — there's a business reason it's there
- Integrity-protected — Subresource Integrity (SRI) hash on script tags, OR a Content Security Policy that pins script sources to known origins

In practice: keep the payment page minimal. Don't load analytics SDKs, chat widgets, A/B test frameworks, or marketing pixels on the page. If you must, inventory them and add SRI hashes.

```html
<!-- Pattern: SRI on Stripe.js -->
<script
  src="https://js.stripe.com/v3/"
  integrity="sha384-<hash>"
  crossorigin="anonymous"
></script>
```

Stripe.js loads from `js.stripe.com` — pin to that origin in CSP, never self-host or proxy Stripe.js (you'll break the iframe boundary and PCI guidance both).

**11.6.1 — Tamper / change detection on payment pages.** Real-time monitoring of modifications to the payment page or its scripts. Options:
- Build it yourself (DOM mutation observers reporting unexpected changes)
- Use a commercial CSP / page-integrity service (Akamai Page Integrity Manager, Jscrambler, etc.)
- Use Stripe's published guidance + CSP report-uri to capture violations

If you can't demonstrate this control during audit, you fail 11.6.1.

### Cross-link

PCI scope ultimately rolls up to your QSA / SAQ submission. This overlay tells you what Stripe lets you achieve; the broader compliance program is security-engineer's general purview. See `skills/etyb/references/specialists/security-engineer/` for the PCI DSS narrative.

## Key + credential hygiene

Stripe issues several key types. Each has a different threat model.

### Key types

| Key | Where it lives | Threat if leaked |
|-----|---------------|------------------|
| **Publishable key (`pk_live_*`, `pk_test_*`)** | Client-side (browser, mobile app) | Low. Can only do what Stripe.js / Mobile SDKs let it do — create PaymentMethods, confirm PaymentIntents with client_secret. No money movement possible without server-side confirmation or secret key. |
| **Secret key (`sk_live_*`, `sk_test_*`)** | Server-side environment variables | Catastrophic. Full account access. Can create charges, refunds, transfers, read all customer data, change webhook endpoints. |
| **Restricted key (`rk_live_*`, `rk_test_*`)** | Server-side, less-trusted services | Scope-limited. Powerful within scope (e.g., a key with "Refunds — write" can issue refunds). Threat depends on scope. |
| **Webhook signing secret (`whsec_*`)** | Server-side, in the webhook handler | If leaked, an attacker can forge webhook events. Threat: forged `payment_intent.succeeded` events could trigger fulfillment without payment. Severity depends on handler logic. |
| **Connect-specific keys / OAuth tokens** | Per-connected-account; platform may hold OAuth refresh tokens | If platform's OAuth secret leaks, attacker can impersonate the platform to all connected accounts. Catastrophic for the platform. |

### Publishable key

It's safe to expose. That's its job. Common over-defensive mistake: putting publishable keys in a "secrets" vault. Just commit it in `.env.example` and ship the `pk_live_*` to the browser. The only thing to worry about is **using the wrong mode's key** (test key in production, live key in test) — handle this with environment-specific configuration and a deploy-time check.

### Secret key

- **Never in client-side code.** `NEXT_PUBLIC_STRIPE_SECRET_KEY` does not exist as a concept. If you see it, rotate immediately.
- **Per-environment.** Test mode secret key for test, live mode secret key for live. Stripe Workbench → API keys page surfaces both.
- **Per-service if possible.** Stripe supports multiple secret keys per account. Issuing one per high-trust service (your main API server, your reconciliation worker that needs writes) lets you rotate one without disrupting others.
- **Rotation triggers**: employee with access leaves; suspicion of leak; vendor breach in your CI/CD chain; scheduled annual rotation for low-traffic services.
- **Rotation procedure**: create new key in Workbench → roll new key to one service at a time → verify each service is using the new key → expire the old key. Stripe lets you have multiple secret keys live simultaneously, so zero-downtime rotation is achievable.

### Restricted keys

The 2024-2026 best practice for any non-full-trust service. Service-to-Stripe access patterns that should use restricted keys:

- **Analytics jobs** reading charges/invoices/customers → restricted key with read-only on those resources
- **Reconciliation workers** that compare your DB to Stripe → read-only restricted key
- **Webhook handlers that only read additional data** (e.g., fetch a customer to enrich an event) → restricted key with read on Customers
- **Third-party SaaS integrations** (Zapier, Make, n8n) → restricted key scoped to the operations they need
- **AI agents calling Stripe MCP** → restricted key scoped to read + the specific writes you've approved
- **Mobile clients calling your backend that proxies Stripe** → your backend still uses the secret key, but if you ever expose a Stripe-proxying endpoint to mobile, the credentials checking which endpoint is allowed should be scoped

**Scoping pattern**: start with "no permissions," add the minimum to make the service work, test, lock down. Don't start with "everything" and try to remove.

### Webhook signing secret

- One **per webhook endpoint**. Accounts often have 3-5 endpoints (main app, billing service, Connect-specific, analytics). Each has its own secret.
- The handler must verify against the correct endpoint's secret. Hardcoding "the" secret in code breaks the moment you add a second endpoint.
- **Stripe CLI (`stripe listen`) generates a temporary secret** per session — used for local dev. Don't confuse with the persistent endpoint secret.
- **Rotation**: Dashboard lets you reveal and roll. After rolling, deploy code with new secret, then expire the old. Brief window where both are valid (Stripe sends old + new headers during rotation, I think? — verify in docs before rotating in production, this is a detail that changes).

## Webhook signature verification

The single most common security mistake in Stripe integrations: skipping or weakening signature verification. The pattern that's correct:

```typescript
import Stripe from 'stripe';

const event = stripe.webhooks.constructEvent(
  rawBody,                                  // exact bytes, not parsed
  req.headers.get('stripe-signature')!,     // header from Stripe
  process.env.STRIPE_WEBHOOK_SECRET!,        // per-endpoint signing secret
  300,                                       // tolerance in seconds (default 300)
);
```

The signature header includes a timestamp and the HMAC of `timestamp.body` keyed by the signing secret. `constructEvent` verifies both:

1. The HMAC matches.
2. The timestamp is within tolerance (replay protection — defaults to 5 minutes).

### Mistakes that fail verification silently

- **Parsing `req.json()` and passing the parsed object back as a string** — the re-stringified JSON is byte-different from the original. Use raw body.
- **Frameworks that JSON-parse all POSTs by default** — Next.js App Router needs `req.text()`, not the App Router default JSON parsing. Express needs `bodyParser.raw({ type: 'application/json' })`. Rails needs to skip the param parser for this route.
- **Hardcoding `STRIPE_WEBHOOK_SECRET` when you have multiple endpoints** — use the endpoint-specific secret per route handler.
- **Trusting `Stripe-Signature` header existence without verification** — always run `constructEvent`; the header alone is not authentication.

### When verification fails

Return **400, not 401 or 500**. Stripe interprets non-2xx as "delivery failed" and retries. A 400 is appropriate ("malformed event"); a 500 makes Stripe retry forever. A 401 also triggers retries.

Log the failure for monitoring — repeated verification failures could indicate an attacker probing for missing signature checks.

## 3D Secure 2 / Strong Customer Authentication (SCA)

PSD2's SCA mandate applies to EEA + UK transactions. Stripe handles the mechanics; you must wire your flow to let it work.

### The default modern flow

1. PaymentIntent created with `automatic_payment_methods: { enabled: true }`.
2. Client confirms via `stripe.confirmPayment({ clientSecret, confirmParams: { return_url } })`.
3. If the issuer challenges, Stripe.js handles the 3DS2 redirect (or iframe) automatically.
4. After the challenge, the customer returns to `return_url`. Stripe finalizes the PaymentIntent.
5. Your webhook receives `payment_intent.succeeded` (or `payment_intent.payment_failed` if the issuer rejects).

**You do not call `stripe.confirmPayment` server-side for the on-session flow.** Server-side confirmation skips the 3DS2 challenge UI, and the PaymentIntent will sit in `requires_action` forever (or fail if you try to capture without challenge completion).

### Off-session (merchant-initiated) transactions

For saved-card flows where the customer isn't at the keyboard (subscriptions, scheduled charges, post-trial conversions):

1. Card must have been saved earlier with a SetupIntent or PaymentIntent with `setup_future_usage`.
2. Off-session charge attempt: PaymentIntent with `off_session: true, confirm: true, payment_method: <saved>`.
3. If the issuer demands SCA (rare but happens), Stripe returns `requires_action`. You then need to re-engage the customer (email link → return to a page that uses the saved client_secret to complete authentication).

### Exemptions

- **Low value (< €30 / £30)** — Stripe automatically applies the LVE exemption when applicable.
- **TRA (transaction risk analysis)** — Stripe applies based on Radar's risk score; you get higher exemption rates as your fraud rate stays low.
- **Merchant-initiated transactions (MIT)** — recurring/scheduled charges with the right setup_future_usage exempt.
- **Recurring transactions (RT)** — fixed-amount recurring (e.g., monthly subscription) with the same amount across charges exempt.

Don't try to claim exemptions manually — Stripe handles it via PaymentIntents. The wrong action is "let's just disable 3DS for our checkout" — that doesn't work for EEA/UK transactions and you'll see decline rates spike.

### Decline analysis

Workbench → Payments → filter by `outcome.reason` to see what's declining. Common SCA-related decline reasons:
- `authentication_required` — Stripe tried to confirm without challenge UI; reconfigure flow.
- `setup_intent_authentication_failure` — saved card later failed SCA on off-session use; re-engage customer.

## Radar — fraud configuration

Stripe Radar is the ML fraud system, on by every account by default for cards. Two tiers:

- **Radar (free with cards)** — ML-driven blocks/holds, no manual rules.
- **Radar for Fraud Teams** — adds the Rules engine, manual review queue, custom velocity rules, allow/block lists, dashboard for manual triage. Usage-priced.

### Configuration discipline

1. **Don't disable Radar without a replacement.** Radar's ML model is trained on Stripe's global fraud network. Turning it off and relying solely on your own fraud system means you lose that signal — almost always net-negative for fraud rate.

2. **Tune the risk threshold based on dispute rate.** Default is balanced for an average merchant. If your dispute rate is rising, lower the threshold (more blocks, fewer disputes, slightly higher false positives). If you have low fraud and are getting too many holds, raise the threshold.

3. **Custom rules in Radar for Fraud Teams**: keep them minimal. ML beats most rules. Use rules for:
   - Compliance — block specific countries you can't legally serve
   - Known-fraudster patterns specific to your business (e.g., "block if email matches our internal fraud list")
   - Velocity — "block if this customer has 5+ attempts in 1 hour"
   
   Don't write rules trying to recreate Radar's ML signal (CVC mismatches, AVS mismatches, etc.) — Radar already uses those.

4. **Allow-lists for VIP customers** — if you have customers who repeatedly trip Radar's blocks for legitimate reasons (high-value frequent buyers, business accounts with multiple cards), add them to an allow-list.

5. **Adaptive Acceptance** (2024+) — Radar can occasionally over-ride a block when the signal is strong that it's legitimate. Trust it; don't fight to make rules more aggressive than Stripe's defaults.

### Early Fraud Warnings (EFWs)

`radar.early_fraud_warning.created` — pre-dispute signal from the network that a chargeback is likely. **Handle this webhook.** Options when it fires:
- Refund proactively — lose the charge revenue but avoid the chargeback fee + dispute time.
- Investigate and decide — Workbench shows the EFW details.
- Ignore — accept that ~70%+ of EFWs become disputes, you're betting on the rest.

For high-fraud verticals (digital goods, gift cards), proactive refund is usually correct.

### Disputes

`charge.dispute.created` — chargeback fired. You have ~7 days (varies by network) to submit evidence. Workflow:
- Pause shipping / freeze access (if applicable)
- Gather evidence (delivery confirmation, customer communications, IP address, device fingerprint)
- Submit via Dashboard or API (`disputes.update` with `evidence`)
- Outcome: won (charge restored, often minus a small fee) or lost (chargeback stands)

Don't auto-submit boilerplate evidence — banks discount low-quality submissions. Take the time to assemble specific evidence per dispute.

## Connect platform liability

Platforms using Connect have different liability profiles based on `controller` properties (modern) or `type` (legacy shorthand).

| Configuration | Liability for losses | KYC responsibility | Stripe fees paid by |
|---------------|---------------------|--------------------|--------------------|
| Standard (legacy type) | Stripe (mostly) | Connected account collects, Stripe verifies | Connected account |
| Express (legacy type) | Configurable; default Stripe | Stripe hosts collection UI | Platform (typically) |
| Custom / `controller.losses.payments: 'application'` | **Platform** | Platform collects, sends to Stripe | Platform |
| `controller.losses.payments: 'stripe'` | Stripe | Depends on other controller fields | Platform |

### Implications for the platform

If `losses.payments = 'application'`:
- The platform is on the hook for unrecovered chargebacks
- The platform must hold reserves or pre-fund
- The platform owns the customer relationship and can refuse to serve high-risk sellers
- Underwriting + monitoring is the platform's responsibility — Stripe's tools (Radar, account monitoring) help but don't replace your judgment

If `losses.payments = 'stripe'`:
- Stripe holds the loss
- Stripe sets the underwriting criteria — your platform can be capped or have sellers offboarded by Stripe
- Stripe controls the seller-facing dashboards (Standard / Express)

The fintech-architect overlay has the full decision framework. From security's perspective: **know which liability model you're on** before designing the seller monitoring, fraud signals, and seller-suspension workflows.

### Connected account monitoring

Even when Stripe takes losses, the platform should monitor:
- `account.updated` events — capabilities going inactive often signal Stripe's fraud team has flagged the account
- `capability.updated` events — same
- `person.updated` events — KYC info changes
- `payout.failed` events — bank-side issues, often a precursor to seller offboarding
- `application_fee.refunded` events — Stripe pulled back your fee (usually a dispute the platform owes)
- Sudden spike in `charge.refunded` from a connected account — internal fraud, returns abuse, or compromised seller account

Build internal dashboards over Sigma / Data Pipeline. Don't wait for Stripe to tell you a seller is problematic.

## Stripe Identity (KYC)

Stripe Identity provides document + selfie verification. Used most often for:
- Connect platform KYC of sellers (alternative to platform-built KYC)
- High-value transaction step-up verification
- Account opening flows where you need to verify a real human

Threat model considerations:
- Stripe Identity is **not HIPAA-covered**. PHI in selfies / documents is not a covered use.
- **Storage**: Stripe stores verification results; you can retrieve `verified_outputs` (verified name, DOB, address). Raw document images are short-retention.
- **GDPR**: Stripe is data processor for Identity; ensure your DPA covers it.
- **Integration**: hosted (redirect or embedded) — you don't handle document images directly. Don't pass document images through your servers.

For platforms doing their own KYC instead of Stripe Identity: fintech-architect overlay covers the broader KYC landscape (Persona, Jumio, Onfido, Veriff, Trulioo).

## Stripe MCP — agent security posture

The Stripe-hosted MCP server lets AI agents drive Stripe operations. New threat surface:

| Threat | Mitigation |
|--------|-----------|
| Prompt injection that triggers a Stripe operation | Restricted key scoped to read-only OR a tightly scoped write surface (e.g., "issue refunds up to $50") |
| Agent acting on stale context (refunding the wrong order) | Multi-step confirmation patterns; agent shows summary, human approves before write |
| Audit trail gap — who triggered which Stripe call | Log every MCP tool invocation with operator identity, agent session ID, tool name, parameters, response |
| Credentials leak via agent's debug output | Don't put secrets in MCP config the agent can echo; use ephemeral tokens / proxy MCP through your own service |

### Restricted-key patterns for agents

A typical setup:
- **Dev / debugging agents** — test mode restricted key, scoped wide (read-everything, write-customer)
- **Production analytics agents** — live mode restricted key, read-only on customers, charges, invoices
- **Production write agents (refund bot, etc.)** — live mode restricted key, scoped to ONLY the operations the agent is supposed to do, with rate limits on the agent's runner

### Proxy MCP for additional control

For high-stakes agents, consider proxying the Stripe MCP server through your own service:
- Your service holds the Stripe credentials (not the agent)
- Your service enforces additional checks (allow-list of operations, value caps, approval flows)
- Your service logs every call with full context

Stripe-hosted MCP is direct-to-Stripe; a custom proxy gives you defense-in-depth.

## Data residency and GDPR

- **Stripe data residency**: most customer data lives in US (or EU, depending on account home). Stripe does not currently offer single-region EU-only data residency for the core API (as of 2026). If a customer requires EU residency (Schrems II concern), you may need to architect around it (e.g., minimize PII in Stripe, store PII in EU-resident DB, use Stripe customer ID as the linkage).
- **GDPR DPA**: sign Stripe's standard DPA. Stripe is data processor for the data you send.
- **Right to erasure**: Stripe supports deletion via `stripe.customers.del` — soft delete that anonymizes the customer record while preserving payment history for compliance/audit. PaymentIntents and Charges are retained for regulatory periods.
- **Data minimization in metadata**: don't pile PII into PaymentIntent metadata. Metadata is searchable, exportable, and visible in Dashboard — only put what's needed for reconciliation (order ID, tenant ID).

## Audit logging

What Stripe gives you:
- **Workbench → API logs** — every API request your account made (90-day retention; longer with Sigma/Data Pipeline)
- **Workbench → Events** — every webhook event Stripe fired (30-day retention in UI; export via API or Data Pipeline)
- **Dashboard activity logs** — who logged in, what they changed (team-member-action audit)

What you should add:
- Every webhook event received → your own append-only log (S3, BigQuery, Snowflake)
- Every outbound Stripe API call from your services → your application logs with request ID, response status, idempotency key
- Every restricted-key creation/rotation → infrastructure audit log
- Every MCP tool invocation → application + agent audit log

Reconciliation: monthly, verify Stripe's events log matches your application's record of received events. Gaps indicate webhook delivery failures or your handler dropping events.

## Patterns and anti-patterns

### Pattern: defense in depth on webhooks

Verify signature → check timestamp window → verify event ID hasn't been processed → fetch the resource from Stripe (don't trust the event payload alone for high-value operations) → process → ack.

For high-value operations (large refunds, marketplace payouts), the fetch-from-Stripe step protects against an unlikely-but-possible forged signature attack on a leaked signing secret.

### Pattern: per-environment, per-service restricted keys

Test mode restricted key for staging tests. Live mode restricted key per service. Never share keys across environments or services. Rotation becomes per-key, not per-everything.

### Pattern: deploy-time mode check

```typescript
const key = process.env.STRIPE_SECRET_KEY;
if (process.env.NODE_ENV === 'production' && !key?.startsWith('sk_live_')) {
  throw new Error('Production environment using test mode Stripe key');
}
if (process.env.NODE_ENV !== 'production' && key?.startsWith('sk_live_')) {
  throw new Error('Non-production environment using live mode Stripe key');
}
```

Catches the most common deployment-misconfiguration class of mistake.

### Anti-pattern: skipping signature verification "for now"

"We'll add signature verification later." No, you won't. Code gets deployed, the path gets forgotten, and one day an attacker discovers the unsigned webhook endpoint and forges `payment_intent.succeeded` to your fulfillment system. Signature verification is in the first commit or it's a bug.

### Anti-pattern: storing card data "for convenience"

Stripe's tokenization exists so you don't have to. Stripe's PaymentMethod IDs are your "card on file" representation. Never store PAN, full card number, CVC. If you find yourself even *considering* storing card data, escalate immediately.

### Anti-pattern: shared signing secret across endpoints

"We have one webhook secret for everything." When you add a second endpoint (Connect, billing), you'll either reuse the secret (security risk — the second endpoint has the same trust as the first) or hardcode the wrong one. Different endpoints, different secrets, configured per route handler.

### Anti-pattern: trusting metadata for authorization

`paymentIntent.metadata = { isAdmin: true }` and your code reads it back. Anyone with secret-key access can write metadata. Use your own DB for authorization decisions.

### Anti-pattern: rate-limiting your end of webhook ingestion

Stripe will hammer your webhook endpoint during a backlog drain. Don't put a CDN rate limit in front that drops Stripe's IPs. Either ingest fast (queue-fronting the handler) or have signed-allowlist for Stripe's IP ranges.

## Decision frameworks

### When to use SAQ-A vs SAQ-A-EP

If you can ship Stripe Checkout, use it (SAQ-A). The reasons to pick SAQ-A-EP / Payment Element:
- UI brand strictly requires no redirect / no iframe-shaped payment form
- Multi-step checkout where you need finer control over the form composition
- You're already SAQ-A-EP for other reasons and adding the payment page doesn't expand scope

Don't pick SAQ-A-EP for "we want it to look custom" — Hosted Checkout's customization options usually suffice (logos, colors, button copy, fields).

### When to use Restricted Key vs Secret Key

Decision rule: would this service be allowed to refund all charges, transfer money to arbitrary accounts, and update webhook endpoints? If yes, secret key. If no, restricted key with the minimum scope.

### When to use Stripe Identity vs another KYC vendor

Stripe Identity for:
- Stripe Connect platforms doing seller verification (deep integration)
- Single-product KYC needs ("verify this user once")
- US/UK/EU + a growing list of supported countries — check current support list

Other vendors (Persona, Jumio, Onfido) for:
- Multi-step KYC with custom workflows
- Countries Stripe Identity doesn't support well
- Custom document types Stripe doesn't handle
- Ongoing periodic re-verification at scale

## Tooling specifics

- **Workbench** ([dashboard.stripe.com/workbench](https://dashboard.stripe.com/workbench)) — API logs, events, webhook endpoints, API keys, restricted keys, API version. Single most important developer + security surface.
- **Stripe CLI** — `stripe listen` for local dev signature flow; `stripe logs tail` for real-time API log streaming; `stripe trigger` for synthetic events. Test mode only.
- **Stripe Sigma** — SQL queries over Stripe data for ad-hoc security/fraud analysis (suspicious patterns, refund rates by user, etc.).
- **Stripe Data Pipeline** — sync to your warehouse for long-term audit retention + integration with your SIEM.
- **`stripe-mock`** — Docker mock for tests. Useful but doesn't simulate signature verification realistically (test the real verification flow against test mode).

## Integration with always-on protocols

### TDD on signature verification

Red: test that a request with a tampered body returns 400. Test that a request with a stale timestamp (>5min old) returns 400. Test that a valid event is processed once and a replay is acked-without-reprocessing.

Green: implement.

Refactor: extract verification middleware so multiple webhook routes share it.

### Verification on PCI-relevant changes

Don't claim "we're SAQ-A" because you picked Checkout. Verify by running through the actual SAQ-A questionnaire and signing it. The integration choice qualifies you; the questionnaire is the artifact.

### Debugging Stripe security issues

Failed signature → check raw body handling, check secret matches the endpoint's secret in Workbench, check timestamp tolerance. One variable at a time.

Failed 3DS → check `automatic_payment_methods` is enabled, check confirmation is client-side via `confirmPayment`, check the issuer isn't outright declining (Workbench shows the decline reason).

Radar over-blocking → tune the threshold, then add specific allow-list entries for known-good customers. Don't disable Radar without a replacement.

### Branch safety

Stripe code touches money. Security review (this overlay) + backend review (backend-architect overlay) before merge for any change that touches: webhook handlers, key handling, restricted key scopes, payment flow logic, Connect platform liability config.

## Cross-references

- [Webhook architecture mechanics → backend-architect.md](backend-architect.md)
- [PCI / SAQ context across the broader compliance program → `skills/etyb/references/specialists/security-engineer/`](../../../skills/etyb/references/specialists/security-engineer/)
- [Connect platform liability framework → fintech-architect.md](fintech-architect.md)
- [SaaS billing pricing-model implementation → saas-architect.md](saas-architect.md)
- [Checkout / Elements / wallets UX → e-commerce-architect.md](e-commerce-architect.md)

## Products covered relevant to this role

Payment Intents API, Setup Intents API, Stripe Checkout (hosted), Stripe Elements / Payment Element, Stripe Billing (subscriptions for security model context), Customer Portal, Stripe Connect (controller properties and liability), Stripe Treasury (financial accounts security), Stripe Issuing (card program security), Stripe Identity, Stripe Tax (data residency implications), Stripe Radar, Restricted API Keys, Webhooks (signature verification), Connect Webhooks, API versions + pinning (for security context — newer versions sometimes ship security improvements), Stripe-hosted MCP, Stripe Workbench, SCA / 3D Secure 2, Stripe Sigma (for audit/forensic queries), Stripe Data Pipeline (audit retention).
