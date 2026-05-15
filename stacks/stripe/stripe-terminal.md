---
title: Stripe Terminal
description: In-person payments via dedicated card readers (BBPOS, Verifone, Stripe Reader S700) or Tap to Pay on iPhone/Android.
product:
  name: Stripe Terminal
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [e-commerce-architect, backend-architect]
  authoritative_url: https://docs.stripe.com/terminal
  notes: "Reader SDKs evolve quarterly. Stripe Reader S700 released 2023. Pairs with Tap to Pay for no-hardware in-person."
---

## What it is

Stripe Terminal is Stripe's in-person payments product. It supports two integration shapes:

1. **Dedicated readers** — BBPOS WisePOS E, Verifone P400, Stripe Reader S700, BBPOS Chipper 2X BT
2. **[Tap to Pay](/stacks/stripe/tap-to-pay/)** on iPhone or Android — the phone IS the reader

You build a POS app (native iOS/Android, or React Native / Flutter with Terminal SDK bindings) that discovers + connects to the reader, drives a [PaymentIntent](/stacks/stripe/payment-intents/) through it, and captures the result. Refunds, voids, partial captures all supported.

Canonical reference: [docs.stripe.com/terminal](https://docs.stripe.com/terminal).

## When to use

| Need | Terminal? |
|------|-----------|
| Pop-up retail, mobile vendors, in-person events | Yes — Tap to Pay is no-hardware |
| Hybrid online/in-person merchant | Yes — one Stripe account for both |
| Specific industries (delivery on-demand, in-home services) | Yes — Tap to Pay |
| High-volume retail | Yes — dedicated readers more durable + cheaper per transaction at scale |
| MOTO (mail-order/telephone-order) | Use MOTO Payment Element or Terminal |

## 2025-2026 currency anchors

- **Reader SDKs evolve quarterly.** Check current SDK version + reader firmware compatibility.
- **Stripe Reader S700** (released 2023) is Stripe's first-party smart terminal.
- **Tap to Pay availability expanded** through 2025 — see [Tap to Pay](/stacks/stripe/tap-to-pay/) for current country support.

## Patterns

### Reader-based POS

```typescript
// Server: create a Terminal PaymentIntent
const pi = await stripe.paymentIntents.create({
  amount: 5000,
  currency: 'usd',
  payment_method_types: ['card_present'],
  capture_method: 'manual',  // common for in-person
});
```

```swift
// iOS Terminal SDK (Swift)
Terminal.shared.collectPaymentMethod(paymentIntent: pi) { intent, error in
  if let intent = intent {
    Terminal.shared.processPayment(intent) { result, error in
      // result is the final PaymentIntent
    }
  }
}
```

### Reader hardware options

| Reader | Form factor | Use |
|--------|-------------|-----|
| BBPOS WisePOS E | Android-based smart terminal | Countertop |
| Verifone P400 | Countertop terminal | Traditional retail |
| Stripe Reader S700 | Stripe-branded smart terminal | Modern integrated retail |
| BBPOS Chipper 2X BT | Bluetooth mobile reader | Paired with phone/tablet POS app |

### Refunds, voids, captures

```typescript
// Capture authorized amount
await stripe.paymentIntents.capture(pi.id);

// Void (release auth before capture)
await stripe.paymentIntents.cancel(pi.id);

// Refund
await stripe.refunds.create({ payment_intent: pi.id, amount: 2000 });
```

## Anti-patterns

- **Web-based card-present.** Card-present requires the Terminal SDK on a real device with a real reader (or Tap to Pay). Web can't do card-present.
- **Mixing test and live reader connections.** Use test-mode keys + a test reader for development.
- **Skipping reader firmware updates.** Outdated firmware can fail to read modern chip cards or contactless.

## Gotchas

- **Reader discovery requires location permissions** on mobile (Bluetooth needs location on iOS/Android).
- **Connection drops are common** in retail environments — design your POS app to reconnect gracefully.
- **Reader-side encryption** — the reader encrypts the card data before sending. Your app never sees raw card data, even briefly. This keeps you out of SAQ-D scope.

## Cross-references

- [Tap to Pay](/stacks/stripe/tap-to-pay/) — no-hardware variant
- [Payment Intents](/stacks/stripe/payment-intents/) — underlying primitive
- [Stripe Issuing](/stacks/stripe/stripe-issuing/) — closed-loop scenarios (accept + issue)
- [e-commerce-architect on Stripe](/stacks/stripe/e-commerce-architect/)
- Authoritative: [docs.stripe.com/terminal](https://docs.stripe.com/terminal)
