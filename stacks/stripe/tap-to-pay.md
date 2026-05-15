---
title: Tap to Pay
description: Turn an iPhone or Android phone into a contactless card reader using Stripe Terminal SDK. No hardware required. Country availability expanding.
product:
  name: Tap to Pay
  stack: stripe
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [e-commerce-architect, backend-architect]
  authoritative_url: https://docs.stripe.com/terminal/payments/setup-reader/tap-to-pay
  notes: "iPhone (US/UK/CA/AU/etc.) and Android availability expanding 2025-2026; entitlement gates and merchant requirements differ by country."
---

## What it is

Tap to Pay is Stripe Terminal's no-hardware in-person payments option. The phone (iPhone or Android) acts as the card reader — customers tap their contactless card, phone, or watch against the merchant's phone. Integrates via the Stripe Terminal SDK.

Canonical reference: [docs.stripe.com/terminal/payments/setup-reader/tap-to-pay](https://docs.stripe.com/terminal/payments/setup-reader/tap-to-pay).

## When to use

| Need | Tap to Pay? |
|------|-------------|
| Pop-up retail, mobile vendors, in-person events | Yes — no hardware to ship |
| Hybrid online/in-person (Stripe one account for both) | Yes |
| Specific industries (delivery on-demand, in-home services) | Yes |
| High-volume retail | Use dedicated [Stripe Terminal](/stacks/stripe/stripe-terminal/) readers — more durable + cheaper per transaction at scale |

## 2025-2026 currency anchors

- **iPhone availability**: US, UK, Canada, Australia, France, Netherlands, and more. Requires iOS 16.4+.
- **Android availability**: newer; available in fewer markets. Verify current support.
- **Merchant onboarding (entitlement)** is per-Stripe-account, per-country — different requirements in each market.
- **Expanding through 2025-2026** — drift risk high; check current support before quoting countries to customers.

## Patterns

### iOS Terminal SDK

```swift
// Build a native iOS app (or React Native / Flutter with Stripe Terminal SDK bindings)
import StripeTerminal

Terminal.shared.collectPaymentMethod(paymentIntent: pi) { intent, error in
  Terminal.shared.processPayment(intent) { result, error in
    // result is the final PaymentIntent
  }
}
```

### Android Terminal SDK

Similar shape; Stripe Terminal SDK for Android.

### Cross-platform options

- **React Native** — `@stripe/stripe-terminal-react-native` (wraps native SDKs)
- **Flutter** — community bindings exist; verify Stripe official support per platform

## Anti-patterns

- **Promising Tap to Pay in countries where it's not yet supported.** Country-check before listing.
- **Web-based Tap to Pay.** Not supported; this is a native SDK feature using device NFC.
- **High-volume retail on Tap to Pay phones.** Dedicated [Terminal](/stacks/stripe/stripe-terminal/) hardware is more durable + cheaper at scale.

## Gotchas

- **Entitlement gates** — Apple/Google have entitlements; Stripe handles most of the activation, but the first-time setup per merchant is a flow, not instant.
- **NFC + location permissions** required on the device.
- **Network connectivity** required at point-of-tap — Tap to Pay isn't fully offline.
- **Refunds + voids** — supported via Terminal SDK after the tap, same as dedicated readers.

## Cross-references

- [Stripe Terminal](/stacks/stripe/stripe-terminal/) — broader in-person product
- [Payment Intents](/stacks/stripe/payment-intents/) — underlying primitive
- [e-commerce-architect on Stripe](/stacks/stripe/e-commerce-architect/)
- Authoritative: [docs.stripe.com/terminal/payments/setup-reader/tap-to-pay](https://docs.stripe.com/terminal/payments/setup-reader/tap-to-pay)
