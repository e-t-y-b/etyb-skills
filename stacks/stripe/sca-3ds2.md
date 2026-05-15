---
title: SCA / 3D Secure 2
description: PSD2's Strong Customer Authentication mandate — required in EU/UK/EEA. PaymentIntents handle 3DS2 automatically with the right confirm flow.
product:
  name: SCA / 3D Secure 2
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, e-commerce-architect, backend-architect]
  authoritative_url: https://docs.stripe.com/strong-customer-authentication
  notes: "Mandatory in EU/UK/EEA; PaymentIntents handle by default if `automatic_payment_methods` enabled and confirm flow used correctly. 3DS1 sunset 2024."
---

## What it is

Strong Customer Authentication (SCA) is the EU's PSD2 mandate requiring 2-factor authentication on most consumer payments in EEA + UK. The mechanism is **3-D Secure 2 (3DS2)** — the issuing bank challenges the cardholder during checkout (biometric, SMS code, app prompt) before authorizing.

Stripe [PaymentIntents](/stacks/stripe/payment-intents/) handle this transparently when configured correctly. Legacy 3DS1 was sunset by 2024.

Canonical reference: [docs.stripe.com/strong-customer-authentication](https://docs.stripe.com/strong-customer-authentication).

## When to use

SCA applies whenever:
- The card issuer is in the EEA + UK, AND
- The transaction is consumer-facing (B2C), AND
- No exemption applies (low value, TRA, MIT, recurring)

This means: if you accept EU/UK cards, SCA logic must be in your flow. Even if your merchant entity is US-based.

## 2025-2026 currency anchors

- **Mandatory and enforced** — no longer "soft launching." Non-compliant flows silently decline at the issuing bank.
- **3DS1 sunset** by 2024. If you see 3DS1 flow code, it's dead.
- **PaymentIntents with `automatic_payment_methods: { enabled: true }`** handle 3DS2 transparently.
- **Server-side `pi.confirm` for on-session breaks SCA** — there's no browser to present the challenge UI.

## Patterns

### The default modern flow (on-session)

1. Server creates PaymentIntent with `automatic_payment_methods: { enabled: true }`
2. Client confirms via `stripe.confirmPayment({ clientSecret, confirmParams: { return_url } })`
3. If issuer challenges, Stripe.js handles the 3DS2 redirect/iframe automatically
4. Customer returns to `return_url`; Stripe finalizes the PaymentIntent
5. `payment_intent.succeeded` webhook fires (or `payment_intent.payment_failed` if rejected)

You do not call `pi.confirm` server-side for on-session. Server-side confirmation skips the 3DS2 UI; the PaymentIntent sits in `requires_action` forever or fails on capture.

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

If the issuer demands SCA (rare on saved cards but happens), the PaymentIntent returns `requires_action`. Re-engage the customer (email link → page that resumes confirmation via the same `client_secret`).

### Exemptions Stripe applies automatically

- **Low value (< €30 / £30)** — LVE exemption
- **TRA (transaction risk analysis)** — applied based on [Radar](/stacks/stripe/stripe-radar/) score
- **Merchant-initiated transactions (MIT)** — recurring/scheduled charges with `setup_future_usage` set correctly
- **Recurring transactions (RT)** — fixed-amount recurring with same amount across charges

Don't try to claim exemptions manually — Stripe handles it via PaymentIntent configuration.

### Decline analysis

[Workbench](/stacks/stripe/stripe-workbench/) → Payments → filter by `outcome.reason`. Common SCA-related decline reasons:
- `authentication_required` — your flow didn't handle 3DS; reconfigure
- `setup_intent_authentication_failure` — saved card later failed SCA on off-session use; re-engage

## Anti-patterns

- **Disabling 3DS to "improve conversion."** Doesn't work for EEA/UK transactions; decline rates spike.
- **Server-side `pi.confirm` for on-session flows.** Breaks 3DS2 challenge UI.
- **Trying to claim exemptions manually.** Stripe handles via PaymentIntent config.
- **Legacy Sources API or direct Charges API for EU/UK cards.** Neither handles SCA cleanly. Use PaymentIntent.
- **No re-engagement path** when off-session saved-card charges return `requires_action`.

## Gotchas

- **`requires_action` is silent without client-side wiring.** PaymentIntent sits, customer never sees the challenge, charge never completes.
- **Issuing bank decides when to challenge.** Even with TRA exemption attempted, the issuer can challenge anyway. Build for the challenge case.
- **SCA applies even to off-session in some cases.** Plan the re-engagement UX.
- **Country mapping** — SCA applies based on **issuing bank's country**, not buyer's residence or merchant's country.

## Cross-references

- [Payment Intents](/stacks/stripe/payment-intents/) — primary mechanism for SCA
- [Setup Intents](/stacks/stripe/setup-intents/) — save card under SCA for future off-session
- [Payment Element](/stacks/stripe/payment-element/) — frontend that handles 3DS UI
- [Stripe Checkout](/stacks/stripe/stripe-checkout/) — hosted alternative that handles SCA
- [Stripe Radar](/stacks/stripe/stripe-radar/) — TRA exemption signal
- [Webhooks](/stacks/stripe/webhooks/) — `payment_intent.requires_action`, `payment_intent.succeeded`, `payment_intent.payment_failed`
- [security-engineer on Stripe](/stacks/stripe/security-engineer/)
- [e-commerce-architect on Stripe](/stacks/stripe/e-commerce-architect/)
- Authoritative: [docs.stripe.com/strong-customer-authentication](https://docs.stripe.com/strong-customer-authentication)
