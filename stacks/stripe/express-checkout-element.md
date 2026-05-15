---
title: Express Checkout Element
description: Single Stripe component rendering Apple Pay, Google Pay, Link, Amazon Pay, PayPal — replaces hand-wired Payment Request Button and individual wallet integrations.
product:
  name: Express Checkout Element
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [e-commerce-architect, backend-architect]
  authoritative_url: https://docs.stripe.com/elements/express-checkout-element
  notes: "GA 2024; consolidates wallets into one component. Replaces legacy Payment Request Button + per-wallet button integrations."
---

## What it is

Express Checkout Element is a single React/JS component that renders a row of "express" payment buttons — Apple Pay, Google Pay, Link, Amazon Pay, PayPal — based on what the buyer's device supports and what you've enabled in Dashboard. Each button completes checkout in one tap using the wallet's stored card + address.

Released GA in 2024. Replaces the legacy Payment Request Button + hand-wired Apple Pay / Google Pay / PayPal integrations.

Canonical reference: [docs.stripe.com/elements/express-checkout-element](https://docs.stripe.com/elements/express-checkout-element).

## When to use

**Use Express Checkout Element for every new build with a custom checkout page.** Putting wallets above the main payment form lifts conversion measurably — Apple Pay / Google Pay users complete in one tap without filling forms.

If you're using [Stripe Checkout](/stacks/stripe/stripe-checkout/), Express Checkout is already integrated. This Element is for [Payment Element](/stacks/stripe/payment-element/) integrations where you control the page.

## 2025-2026 currency anchors

- **GA 2024** — before this, you composed Payment Request Button + individual wallet buttons. Those integrations are obsolete.
- **Buttons render conditionally per device.** Apple Pay only shows on Safari iOS/macOS; Google Pay on Chrome/Android; Link to returning Link users; Amazon Pay where enabled; PayPal where enabled. No empty-button placeholder problems.
- **Single component handles wallet detection, button rendering, accessibility, internationalization** — you don't wire each wallet separately.

## Patterns

### Above the Payment Element

```typescript
const elements = stripe.elements({ clientSecret });

const expressCheckout = elements.create('expressCheckout');
expressCheckout.mount('#express-checkout');

// Below it:
const paymentElement = elements.create('payment', { layout: 'tabs' });
paymentElement.mount('#payment-element');
```

The order matters for conversion. Returning wallet users see their preferred button first and complete without scrolling.

### Apple Pay domain verification

Apple Pay requires a domain verification file at `/.well-known/apple-developer-merchantid-domain-association`. Stripe Dashboard generates the file content; you host it at every domain you accept Apple Pay on. Stripe handles the merchant identity side.

### Wallet event handling

```typescript
expressCheckout.on('confirm', async (event) => {
  const { error } = await stripe.confirmPayment({
    elements,
    confirmParams: { return_url: `${window.location.origin}/complete` },
  });
  if (error) event.complete('fail');
});
```

The Element handles confirmation; you receive the result via the standard confirm flow.

## Anti-patterns

- **Composing Payment Request Button + individual wallet buttons by hand** — obsolete pattern since 2024 GA. Use this Element.
- **Loading wallet buttons separately on the page** (e.g., a separate PayPal SDK) — duplicates the surface. Express Checkout Element handles PayPal via Stripe's integration.
- **Forgetting Apple Pay domain verification** — buttons silently don't render. The Stripe Dashboard surfaces missing verification.

## Gotchas

- **Wallet availability depends on the customer's device + browser.** Test from Safari macOS for Apple Pay, Chrome desktop for Google Pay (or use Stripe's "Test in Mobile" tools).
- **PayPal via Stripe** is the newer integration (Stripe historically integrated PayPal via Braintree). Verify support in your country.
- **Express Checkout buttons honor your Element styling options** — you can theme the button row to match your form.

## Cross-references

- [Payment Element](/stacks/stripe/payment-element/) — main form Element to compose with
- [Link](/stacks/stripe/link/) — one of the wallets rendered here
- [Stripe Checkout](/stacks/stripe/stripe-checkout/) — has Express Checkout built in
- [Optimized Checkout Suite](/stacks/stripe/optimized-checkout-suite/) — bundle that includes Express Checkout
- [Payment Intents](/stacks/stripe/payment-intents/) — underlying intent
- [e-commerce-architect on Stripe](/stacks/stripe/e-commerce-architect/)
- Authoritative: [docs.stripe.com/elements/express-checkout-element](https://docs.stripe.com/elements/express-checkout-element)
