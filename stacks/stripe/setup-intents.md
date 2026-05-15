---
title: Setup Intents
description: Save a payment method for later off-session use under SCA. The right primitive when you're not charging now but will charge later.
product:
  name: Setup Intents API
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, saas-architect, e-commerce-architect, security-engineer]
  authoritative_url: https://docs.stripe.com/payments/save-and-reuse
  notes: "Commonly confused with PaymentIntent + setup_future_usage; using the wrong one breaks SCA exemptions and creates phantom charges."
---

## What it is

A SetupIntent is the Stripe primitive for **saving a payment method without an immediate charge**, under the SCA mandate. It carries the customer through any 3DS2 challenge required to set up the payment method for off-session reuse later, then attaches the resulting PaymentMethod to a Customer.

Canonical reference: [docs.stripe.com/payments/save-and-reuse](https://docs.stripe.com/payments/save-and-reuse).

## When to use

The decision against [PaymentIntent](/stacks/stripe/payment-intents/) is the most common mistake on this surface:

| Need | Primitive |
|------|-----------|
| Charge now, no save | PaymentIntent |
| Charge now AND save for later | PaymentIntent with `setup_future_usage: 'off_session'` |
| Save card now, charge later (no immediate charge) | **SetupIntent** |
| Save card via hosted page | [Stripe Checkout](/stacks/stripe/stripe-checkout/) in `mode: 'setup'` |
| Save card via [Payment Element](/stacks/stripe/payment-element/) | SetupIntent — pass its `client_secret` to the Element |

Concrete situations that call for SetupIntent:

- **Trial signup that captures the card up front but doesn't charge** — SetupIntent at signup; the [Subscription](/stacks/stripe/stripe-billing/) attaches the saved PaymentMethod and charges at trial end.
- **B2B account setup** where billing happens on invoice cadence, not at signup.
- **Add-a-card flow inside [Customer Portal](/stacks/stripe/customer-portal/)** or a custom "payment methods" UI.
- **Marketplace seller adding a payout method** (when relevant).

## 2025-2026 currency anchors

- **`usage: 'off_session'`** is the right setting for cards that will be charged when the customer is not at the keyboard (subscriptions, scheduled merchant-initiated transactions). SCA exemption rules differ between `on_session` and `off_session` — set it correctly at creation.
- **SetupIntent client-side confirmation** uses `stripe.confirmSetup({ elements, confirmParams: { return_url } })` — same shape as `confirmPayment` for PaymentIntents.
- **`setup_intent.succeeded`** is the webhook signal that the PaymentMethod is now attached and ready for off-session charges.

## Patterns

### Capture-card-at-signup, charge-at-trial-end

```typescript
// At signup
const customer = await stripe.customers.create({ email: user.email });
const setupIntent = await stripe.setupIntents.create({
  customer: customer.id,
  usage: 'off_session',
  automatic_payment_methods: { enabled: true },
});
// Frontend mounts Payment Element with setupIntent.client_secret
// Customer enters card; stripe.confirmSetup() runs any 3DS challenge

// At trial end, when Subscription tries the first charge:
// Stripe uses the saved PaymentMethod off-session.
// If SCA is required, PI returns requires_action — re-engage customer via email.
```

### Add a card from Customer Portal

Stripe's [Customer Portal](/stacks/stripe/customer-portal/) handles SetupIntent flows for you when `payment_method_update.enabled: true`. The portal creates the SetupIntent and walks the customer through 3DS.

### Re-engage on `requires_action` for off-session use later

If a saved card later fails an off-session charge with `requires_action`, send the customer a link to a page that resumes the original PaymentIntent's `client_secret` via `stripe.confirmPayment` — this completes the SCA challenge and the charge proceeds.

## Anti-patterns

- **Using PaymentIntent with `setup_future_usage` when nothing is being charged.** Creates a $0 PaymentIntent that breaks SCA exemption logic and clutters the Dashboard. Use SetupIntent for true save-only flows.
- **Skipping `usage` field.** The default may not match your intent. Set `usage: 'off_session'` for any saved card that will be charged when the customer is not present.
- **Confirming SetupIntent server-side.** Same rule as PaymentIntent — on-session confirmation belongs on the client. Server-side confirm skips the 3DS challenge UI.
- **Treating SetupIntent success as "the customer will definitely pay next time."** SCA can fire again on the first off-session use. Build the re-engagement path.

## Gotchas

- **Off-session charges can still trigger SCA.** Rare, but happens. The off-session attempt returns `requires_action` and you must re-engage the customer.
- **The PaymentMethod is attached to a Customer.** SetupIntent without a `customer` parameter creates an unattached PaymentMethod that you have to manage yourself.
- **Test card `4000 0000 0000 0341`** attaches successfully via SetupIntent then fails on the first charge — useful for testing your re-engagement flow.
- **Webhook events you MUST handle:** `setup_intent.succeeded`, `setup_intent.setup_failed`, `payment_method.attached` (sync the saved method into your UI).

## Cross-references

- [Payment Intents](/stacks/stripe/payment-intents/) — for charging now
- [Stripe Billing](/stacks/stripe/stripe-billing/) — subscriptions that use saved cards
- [Customer Portal](/stacks/stripe/customer-portal/) — Stripe-hosted "manage cards" UI
- [SCA / 3D Secure 2](/stacks/stripe/sca-3ds2/)
- [Payment Element](/stacks/stripe/payment-element/) — frontend surface for SetupIntent confirmation
- [saas-architect on Stripe](/stacks/stripe/saas-architect/)
- Authoritative: [docs.stripe.com/payments/save-and-reuse](https://docs.stripe.com/payments/save-and-reuse)
