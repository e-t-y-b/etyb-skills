---
title: Payment Element
description: The modern unified Stripe Element — renders cards, wallets, BNPL, bank debits dynamically based on country/currency/amount. Replaces the legacy Card Element.
product:
  name: Payment Element
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [e-commerce-architect, backend-architect, security-engineer]
  authoritative_url: https://docs.stripe.com/payments/payment-element
  notes: "Modern default Element; legacy Card Element should NOT be used for new builds — only renders cards, no dynamic method surfacing."
---

## What it is

Payment Element is a single iframe-backed Element that dynamically renders all enabled payment methods (cards, wallets, BNPL, bank debits, local methods) based on the buyer's country, the currency, and the amount. It replaces the legacy Card Element + hand-wired wallet integrations.

Mounted on your page, the Element keeps cardholder data inside Stripe's iframe — you stay SAQ-A-EP rather than SAQ-D. You build the surrounding form (email, address, etc.) and the Element handles the payment method capture.

Canonical reference: [docs.stripe.com/payments/payment-element](https://docs.stripe.com/payments/payment-element).

## When to use

Pick Payment Element when [Stripe Checkout](/stacks/stripe/stripe-checkout/) is too constrained but you want to avoid SAQ-D scope.

| Constraint | Recommended |
|------------|-------------|
| Net-new build, no special UX | [Stripe Checkout](/stacks/stripe/stripe-checkout/) (SAQ-A) |
| Need custom form layout, standard inputs | **Payment Element** (SAQ-A-EP) |
| Multi-step checkout with payment mid-flow | Payment Element |
| Fully custom UI everywhere | Don't (SAQ-D). Cost-benefit doesn't pay off in 2026. |

The legacy **Card Element** should NOT be used for new builds — it only renders cards and misses every dynamic-method advantage of Payment Element (wallets, BNPL, Link, local methods like iDEAL/Bancontact).

## 2025-2026 currency anchors

- **Payment Element is the modern unified Element.** Card Element is legacy; flag if a team proposes it.
- **`automatic_payment_methods: { enabled: true }`** on the underlying [PaymentIntent](/stacks/stripe/payment-intents/) is what makes the Element render dynamic methods. Without it, you fall back to whatever `payment_method_types` is explicitly listed.
- **Pair with [Express Checkout Element](/stacks/stripe/express-checkout-element/)** for wallets (Apple Pay, Google Pay, Link, Amazon Pay, PayPal) above the standard form.
- **Pair with [Link Authentication Element](/stacks/stripe/link/)** as the email input — Link users skip the form.
- **PCI DSS v4.0 requirements 6.4.3 and 11.6.1** (enforced 2025) apply to the page hosting the Element. Every script on the page must be inventoried + integrity-monitored; tamper detection on the page is required.

## Patterns

### Full checkout composition

```typescript
// Server
const pi = await stripe.paymentIntents.create({
  amount: 5000,
  currency: 'usd',
  automatic_payment_methods: { enabled: true },
});

// Frontend
const elements = stripe.elements({ clientSecret: pi.client_secret });

const linkAuthElement = elements.create('linkAuthentication');
linkAuthElement.mount('#link-auth');

const expressCheckout = elements.create('expressCheckout');
expressCheckout.mount('#express-checkout');

const addressElement = elements.create('address', { mode: 'shipping' });
addressElement.mount('#address');

const paymentElement = elements.create('payment', { layout: 'tabs' });
paymentElement.mount('#payment-element');

// On submit
const { error } = await stripe.confirmPayment({
  elements,
  confirmParams: { return_url: `${window.location.origin}/order/complete` },
});
```

Order matters for conversion: put Express Checkout Element above the Payment Element so returning Apple Pay / Google Pay / Link users can complete checkout in one tap.

### Layout options

- `layout: 'tabs'` — payment methods shown as tabs at the top
- `layout: 'accordion'` — collapsible sections per method
- `layout: { type: 'accordion', defaultCollapsed: false, radios: true }` — fine control

Test both with your method mix; rendering differs for 1 method vs 5+.

### SetupIntent on Payment Element

Same Element, different underlying intent. Pass a SetupIntent's `client_secret` instead of a PaymentIntent's:

```typescript
const { error } = await stripe.confirmSetup({
  elements,
  confirmParams: { return_url: `${window.location.origin}/billing/saved` },
});
```

## Anti-patterns

- **Using the legacy Card Element for a new build.** It only renders cards, no dynamic method surfacing. Migrate any legacy integration to Payment Element.
- **Hand-wiring Payment Request Button + individual Apple Pay / Google Pay buttons.** Use [Express Checkout Element](/stacks/stripe/express-checkout-element/) instead.
- **Server-side `pi.confirm` after Element mount.** Breaks SCA on on-session flows. Confirm from the client via `stripe.confirmPayment`.
- **Loading analytics SDKs, chat widgets, A/B test frameworks on the payment page** — every script is in PCI 6.4.3 scope under SAQ-A-EP. Keep the page minimal.
- **Self-hosting or proxying `js.stripe.com`.** Breaks the iframe boundary and PCI guidance. Always load Stripe.js from `js.stripe.com` directly, with SRI hash + CSP pin.

## Gotchas

- **The `clientSecret` is scoped to one intent.** Don't pass it around your codebase as a generic "payment session ID."
- **Methods that render depend on the underlying intent's country/currency/amount + Dashboard config.** Test with realistic combinations.
- **Browser support**: modern browsers only. Stripe.js drops IE long ago; check current support list before assuming reach.
- **PCI scope: SAQ-A-EP, not SAQ-A.** ~197 questions vs ~22. Plan for the audit burden when picking Element over Checkout.

## Cross-references

- [Stripe Checkout](/stacks/stripe/stripe-checkout/) — SAQ-A alternative
- [Express Checkout Element](/stacks/stripe/express-checkout-element/) — pair with Payment Element for wallets
- [Link](/stacks/stripe/link/) — Link Authentication Element pairing
- [Payment Intents](/stacks/stripe/payment-intents/) — the intent the Element confirms
- [Setup Intents](/stacks/stripe/setup-intents/) — for save-card-only flows
- [SCA / 3D Secure 2](/stacks/stripe/sca-3ds2/) — how the Element handles challenges
- [e-commerce-architect on Stripe](/stacks/stripe/e-commerce-architect/)
- [security-engineer on Stripe](/stacks/stripe/security-engineer/) — PCI DSS v4.0 implications
- Authoritative: [docs.stripe.com/payments/payment-element](https://docs.stripe.com/payments/payment-element)
