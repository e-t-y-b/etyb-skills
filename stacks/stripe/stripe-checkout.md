---
title: Stripe Checkout
description: Stripe-hosted checkout page (hosted, embedded, or custom UI mode). The default for new builds — lowest PCI scope, full Optimized Checkout Suite.
product:
  name: Stripe Checkout
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, e-commerce-architect, saas-architect, security-engineer]
  authoritative_url: https://docs.stripe.com/payments/checkout
  notes: "Recommended default for new integrations as of 2024; `ui_mode=embedded` + `ui_mode=custom` expanded 2024-2025; Optimized Checkout Suite changed defaults."
---

## What it is

Stripe Checkout is a Stripe-hosted checkout page that handles the entire payment-collection flow — payment method rendering, address collection, tax calculation, SCA, BNPL surfacing, wallets, Link, and conversion-optimized payment method ordering. You create a Checkout Session server-side, redirect the customer to it (or embed it in your page), and listen for `checkout.session.completed` to fulfill.

Canonical reference: [docs.stripe.com/payments/checkout](https://docs.stripe.com/payments/checkout).

## When to use

**Stripe Checkout is the default recommendation for any new build that doesn't have a hard reason to take more PCI scope.** The PCI savings (SAQ-A vs SAQ-A-EP for Payment Element) plus the Optimized Checkout Suite features usually win unless the UX requirements demand a custom form layout.

Decision against alternatives:

- **Default for new builds** → Stripe Checkout. Stop here unless brand/UX requires more control.
- **Need custom form layout but standard inputs** → [Payment Element](/stacks/stripe/payment-element/) (SAQ-A-EP).
- **First-time subscription signup from a landing page** → Checkout `mode: 'subscription'`.
- **In-product plan changes / upgrades** → [Subscriptions API](/stacks/stripe/stripe-billing/) directly, using saved payment method.
- **Save card without charging** → Checkout `mode: 'setup'` (Stripe-hosted) OR [SetupIntent](/stacks/stripe/setup-intents/) with [Payment Element](/stacks/stripe/payment-element/).

### UI modes

| Mode | Behavior | Use case |
|------|----------|----------|
| `ui_mode: 'hosted'` | Customer redirects to `checkout.stripe.com` | Marketing pages, simple checkout |
| `ui_mode: 'embedded'` | Iframe inside your page | Multi-step checkout, in-app checkout — gaining adoption, still SAQ-A |
| `ui_mode: 'custom'` | Finer control over Checkout's elements (2024-2025) | When embedded isn't flexible enough but you don't want SAQ-A-EP |

All three are SAQ-A. The Optimized Checkout Suite features apply equally.

## 2025-2026 currency anchors

- **Optimized Checkout Suite** (2024-2025) is the default for new Checkout implementations. Bundle includes [Adaptive Pricing](/stacks/stripe/adaptive-pricing/) (local currency display), [Link](/stacks/stripe/link/), [Express Checkout Element](/stacks/stripe/express-checkout-element/), smart payment method ordering, connection prompts.
- **`ui_mode: 'embedded'`** matured 2024-2025 — most teams adopting Stripe Checkout now choose embedded over hosted.
- **`ui_mode: 'custom'`** (2024-2025) added finer control over Checkout's individual elements while staying SAQ-A.
- **`automatic_tax: { enabled: true }`** integrates [Stripe Tax](/stacks/stripe/stripe-tax/) into Checkout automatically.
- **`adaptive_pricing: { enabled: true }`** enables local-currency display when multi-currency [Prices](/stacks/stripe/stripe-billing/) are configured.

## Patterns

### Hosted Checkout (one-off payment)

```typescript
const session = await stripe.checkout.sessions.create({
  ui_mode: 'hosted',
  mode: 'payment',
  line_items: [{ price: 'price_xyz', quantity: 1 }],
  success_url: `${BASE_URL}/order/success?session_id={CHECKOUT_SESSION_ID}`,
  cancel_url: `${BASE_URL}/cart`,
  customer_email: cart.email,
  metadata: { order_id: order.id },
  automatic_tax: { enabled: true },
  shipping_address_collection: { allowed_countries: ['US', 'CA', 'GB'] },
  payment_intent_data: {
    metadata: { order_id: order.id },
    capture_method: 'manual',
  },
});
// Redirect to session.url
```

### Embedded Checkout

```typescript
// Server
const session = await stripe.checkout.sessions.create({
  ui_mode: 'embedded',
  return_url: `${BASE_URL}/order/return?session_id={CHECKOUT_SESSION_ID}`,
  // line_items, mode, etc.
});

// Frontend
const checkout = await stripe.initEmbeddedCheckout({
  clientSecret: serverProvidedClientSecret,
});
checkout.mount('#checkout-container');
```

### Subscription Checkout

```typescript
const session = await stripe.checkout.sessions.create({
  ui_mode: 'hosted',
  mode: 'subscription',
  line_items: [{ price: 'price_pro_monthly', quantity: 1 }],
  success_url: `${BASE_URL}/welcome?session_id={CHECKOUT_SESSION_ID}`,
  cancel_url: `${BASE_URL}/pricing`,
  customer_email: user.email,
  allow_promotion_codes: true,
  subscription_data: {
    trial_period_days: 14,
    trial_settings: {
      end_behavior: { missing_payment_method: 'cancel' },
    },
  },
});
```

### Save-card Checkout (`mode: 'setup'`)

```typescript
const session = await stripe.checkout.sessions.create({
  ui_mode: 'hosted',
  mode: 'setup',
  payment_method_types: ['card'],
  customer: customerId,
  success_url: `${BASE_URL}/settings/billing/saved`,
  cancel_url: `${BASE_URL}/settings/billing`,
});
```

### Fulfill from webhook

The synchronous redirect to `success_url` is **not** the fulfillment signal. Listen for `checkout.session.completed`:

```typescript
async function handleCheckoutCompleted(event: Stripe.Event) {
  const session = event.data.object as Stripe.Checkout.Session;
  const orderId = session.metadata?.order_id;
  // For payment mode, payment_intent is set on the session
  // For subscription mode, subscription is set
  await fulfillOrder(orderId, session);
}
```

For async payment methods (ACH, SEPA), `checkout.session.completed` fires on session completion, but money may still be in `processing`. Wait for `payment_intent.succeeded` (linked via `session.payment_intent`) before fulfilling digital goods.

## Anti-patterns

- **Reusing Checkout Sessions across visits.** Sessions are short-lived (24h default) and tied to a specific cart snapshot. Create a new Session per checkout attempt.
- **Fulfilling on the `success_url` redirect.** A user can hit `/success` without actually paying (browser back button, share the URL). Always fulfill from `checkout.session.completed` webhook.
- **Picking SAQ-A-EP integration (Payment Element) for "we want it to look custom"** — Checkout has substantial branding controls (logo, colors, button text, custom fields). Custom-feeling but Checkout-backed is usually achievable.
- **Ignoring `checkout.session.expired`** — useful signal for abandoned cart recovery.

## Gotchas

- **Hosted redirect on mobile in-app browsers** can break (no `success_url` callback). Embedded Checkout sidesteps this.
- **`automatic_tax` requires customer address.** Either pre-fill via `customer`, collect via `shipping_address_collection`, or set `billing_address_collection: 'required'`.
- **`payment_intent_data` only applies to `mode: 'payment'`.** For `mode: 'subscription'`, use `subscription_data` instead. They share some fields but not all.
- **Embedded Checkout has CSP requirements** — your page CSP must allow `js.stripe.com` and `checkout.stripe.com` frames. PCI DSS v4.0 requirements 6.4.3 and 11.6.1 are still your responsibility for the parent page (SAQ-A but the embedded page is technically yours).
- **Webhook events you MUST handle:** `checkout.session.completed`, `checkout.session.async_payment_succeeded`, `checkout.session.async_payment_failed` (for ACH/SEPA), `checkout.session.expired` (abandonment).

## Cross-references

- [Payment Element](/stacks/stripe/payment-element/) — when SAQ-A-EP is acceptable for tighter UI control
- [Payment Intents](/stacks/stripe/payment-intents/) — the underlying primitive Checkout creates
- [Setup Intents](/stacks/stripe/setup-intents/) — alternative for save-card without hosted UI
- [Optimized Checkout Suite](/stacks/stripe/optimized-checkout-suite/) — features Checkout gets for free
- [Adaptive Pricing](/stacks/stripe/adaptive-pricing/) — multi-currency display
- [Stripe Tax](/stacks/stripe/stripe-tax/) — automatic tax inside Checkout
- [Stripe Billing](/stacks/stripe/stripe-billing/) — `mode: 'subscription'` flows
- [Webhooks](/stacks/stripe/webhooks/) — `checkout.session.*` events
- [e-commerce-architect on Stripe](/stacks/stripe/e-commerce-architect/)
- [saas-architect on Stripe](/stacks/stripe/saas-architect/)
- Authoritative: [docs.stripe.com/payments/checkout](https://docs.stripe.com/payments/checkout)
