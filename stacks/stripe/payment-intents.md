---
title: Payment Intents
description: Stripe's modern primitive for accepting a payment — handles SCA, dynamic payment methods, async settlement. The default for any new charge flow since 2019.
product:
  name: Payment Intents API
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, security-engineer, e-commerce-architect, fintech-architect]
  authoritative_url: https://docs.stripe.com/payments/payment-intents
  notes: "Stable but the confirmation flow and `automatic_payment_methods` semantics shifted 2024-2025; legacy server-side `pi.confirm` for on-session flows breaks SCA."
---

## What it is

The PaymentIntent is the central Stripe primitive for accepting a one-off payment. It models the payment lifecycle as a state machine — `requires_payment_method` → `requires_confirmation` → optionally `requires_action` (for SCA) → `processing` (for async methods) → `succeeded`. Every modern Stripe payment surface (Checkout, Payment Element, raw API) creates a PaymentIntent under the hood.

PaymentIntents have been the default since 2019. The older Charges API is functional but legacy; it does not handle SCA, 3D Secure 2, or dynamic payment methods cleanly. Don't propose Charges for new builds.

Canonical reference: [docs.stripe.com/payments/payment-intents](https://docs.stripe.com/payments/payment-intents).

## When to use

Use PaymentIntents whenever you need to charge a customer **now**, whether one-off or as the first charge in a subscription. Decision against alternatives:

- **Charge now, customer at keyboard** → PaymentIntent with `automatic_payment_methods: { enabled: true }`, client-side confirm via `stripe.confirmPayment`. This is the default modern flow.
- **Charge now AND save card for later** → PaymentIntent with `setup_future_usage: 'off_session' | 'on_session'`. Single intent saves the card during the charge.
- **Save card now, charge later** → use [Setup Intents](/stacks/stripe/setup-intents/), not PaymentIntent with `setup_future_usage`. Common mistake: minting $0 PaymentIntents for save-card flows.
- **Off-session merchant-initiated** (saved-card subscription renewal, scheduled charge) → server-side PaymentIntent with `off_session: true, confirm: true, payment_method: <saved>`.
- **Hosted UI, minimum PCI scope** → wrap in [Stripe Checkout](/stacks/stripe/stripe-checkout/) — Checkout creates the PaymentIntent for you.
- **Recurring billing** → create a [Subscription](/stacks/stripe/stripe-billing/); the Subscription creates PaymentIntents for each invoice.

## 2025-2026 currency anchors

- **`automatic_payment_methods: { enabled: true }`** is the 2024+ default. Stripe selects which payment methods to surface based on country, currency, amount, and methods enabled in Dashboard. Don't enumerate `payment_method_types` manually unless you need to override.
- **Client-side confirmation via `stripe.confirmPayment({ clientSecret, confirmParams: { return_url } })`** is the on-session flow. Server-side `pi.confirm` for on-session breaks SCA — the customer's browser must be present to complete 3DS2 challenges.
- **PaymentIntents are versioned by API pin.** A 2019-pinned account receives a different PaymentIntent JSON shape than a `2025-11-15.acacia`-pinned account. See [API versions + pinning](/stacks/stripe/api-versions/).
- **`payment_intent.processing`** state is what async methods (ACH, SEPA, bank transfers) sit in for days. Don't fulfill orders on `processing`.

## Patterns

### Server creates, client confirms

```typescript
// Server
const pi = await stripe.paymentIntents.create(
  {
    amount: 5000,
    currency: 'usd',
    automatic_payment_methods: { enabled: true },
    metadata: { order_id: order.id },
  },
  { idempotencyKey: `order-pi-${order.id}` },
);
// Send pi.client_secret to the frontend
```

```typescript
// Frontend (Payment Element)
const { error } = await stripe.confirmPayment({
  elements,
  confirmParams: { return_url: `${window.location.origin}/order/complete` },
});
```

After the customer returns, Stripe finalizes the PI. The `payment_intent.succeeded` webhook is the signal to fulfill.

### Off-session (merchant-initiated)

```typescript
const pi = await stripe.paymentIntents.create({
  amount: 5000,
  currency: 'usd',
  customer: customerId,
  payment_method: savedPaymentMethodId,
  off_session: true,
  confirm: true,
});
```

If the issuer demands SCA (rare but happens on saved cards), the PI returns `requires_action`. You must re-engage the customer (email link → page that resumes confirmation with the same `client_secret`).

### Auth-then-capture for physical goods

```typescript
const pi = await stripe.paymentIntents.create({
  amount: 5000,
  currency: 'usd',
  capture_method: 'manual',
  automatic_payment_methods: { enabled: true },
});
// Later, when ready to ship:
await stripe.paymentIntents.capture(pi.id);
// Or partial capture if shipping less than authorized:
await stripe.paymentIntents.capture(pi.id, { amount_to_capture: 3000 });
```

Auth holds for ~7 days (varies by card network). Cancel before capture to release the auth cleanly: `paymentIntents.cancel(pi.id)`.

### Idempotency

Every state-changing PaymentIntent call should pass `Idempotency-Key`. The key should be deterministic from business intent ("create PI for order X attempt Y"), not a fresh UUID per HTTP request. See [Idempotency Keys](/stacks/stripe/idempotency-keys/).

## Anti-patterns

- **Using PaymentIntent with `setup_future_usage` when no immediate charge is needed.** Creates phantom $0 PaymentIntents, breaks SCA exemptions. Use [SetupIntent](/stacks/stripe/setup-intents/) instead.
- **Server-side `pi.confirm` for on-session flows.** Breaks 3DS2 because there's no browser to present the challenge. Use client-side `stripe.confirmPayment` for on-session.
- **Enumerating `payment_method_types` manually instead of `automatic_payment_methods`.** Loses dynamic method ordering and ML-driven conversion lift.
- **Trusting the synchronous create response for fulfillment.** The response is a snapshot; the [webhook](/stacks/stripe/webhooks/) (`payment_intent.succeeded`) is the event. Update your DB from the webhook.
- **Storing security-relevant facts in PaymentIntent `metadata`.** Metadata is writable by anyone with the secret key. Use it for reconciliation hints (order ID, tenant ID), not authorization decisions.

## Gotchas

- **Webhook ordering is not guaranteed.** `payment_intent.succeeded` can arrive before `payment_intent.processing` in pathological cases. Make handlers order-independent.
- **`payment_intent.processing` lasts days for ACH/SEPA.** Communicate the delivery delay to buyers; never fulfill digital goods on `processing`.
- **`requires_action` is silent without client-side wiring.** A PI sitting in `requires_action` means the customer needs to complete an SCA challenge; if you never re-engaged them, the PI eventually times out.
- **`automatic_payment_methods` rendering is country + currency + amount dependent.** A US customer in USD sees different methods than an EU customer in EUR. Don't hardcode expectations.
- **Webhook events you MUST handle:** `payment_intent.succeeded`, `payment_intent.payment_failed`, `payment_intent.processing`, `payment_intent.requires_action`, `payment_intent.amount_capturable_updated` (for manual capture).

## Cross-references

- [Setup Intents](/stacks/stripe/setup-intents/) — for save-card-now-charge-later
- [Stripe Checkout](/stacks/stripe/stripe-checkout/) — hosted UI that creates PIs for you
- [Payment Element](/stacks/stripe/payment-element/) — modern Element that confirms PIs from the frontend
- [Webhooks](/stacks/stripe/webhooks/) — event verification + idempotent processing
- [Idempotency Keys](/stacks/stripe/idempotency-keys/) — preventing duplicate charges on retry
- [SCA / 3D Secure 2](/stacks/stripe/sca-3ds2/) — how PIs handle the EU/UK mandate
- [API Versions + Pinning](/stacks/stripe/api-versions/) — why JSON shapes differ across accounts
- [backend-architect on Stripe](/stacks/stripe/backend-architect/)
- [e-commerce-architect on Stripe](/stacks/stripe/e-commerce-architect/)
- Authoritative: [docs.stripe.com/payments/payment-intents](https://docs.stripe.com/payments/payment-intents)
