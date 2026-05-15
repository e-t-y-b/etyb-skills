---
title: Customer Portal
description: Stripe-hosted self-service portal for subscription management — update payment, view invoices, cancel, pause, change plan. Recommend as default for non-enterprise tiers.
product:
  name: Customer Portal
  stack: stripe
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [saas-architect, e-commerce-architect]
  authoritative_url: https://docs.stripe.com/customer-management
  notes: "Stripe-hosted; configuration matured 2024-2025 but core surface stable. Building your own billing UI is a year of work that doesn't differentiate."
---

## What it is

Customer Portal is a Stripe-hosted page at `billing.stripe.com/p/login/<id>` where customers self-serve common subscription operations. Configurable features:

- Update payment method
- View invoices and payment history
- Cancel subscription (immediately or at period end)
- Pause subscription
- Change plan / quantity (within configured allowed plans)
- Update billing info (address, tax ID)
- Apply promotion codes

Canonical reference: [docs.stripe.com/customer-management](https://docs.stripe.com/customer-management).

## When to use

**Recommend Customer Portal as the default for any non-enterprise tier.** Building your own billing UI is a year of work that doesn't differentiate your product.

Build your own only for:
- **Enterprise tier** where customers need SSO into your billing UI
- **Tight integration** with admin features ("manage billing alongside team management")
- **Custom workflows** Stripe doesn't support (approval flows for plan changes, multi-step renewal negotiation)

Pragmatic default: Customer Portal for all tiers initially; custom UI only when a specific enterprise customer demands it.

## 2025-2026 currency anchors

- **Configuration matured 2024-2025** — pause, plan changes, promotion codes, tax-ID collection all first-class.
- **Per-customer Portal Session** — you generate a one-time login link per session; the customer doesn't authenticate against Stripe directly.
- **Handles [SetupIntent](/stacks/stripe/setup-intents/) + SCA** for adding cards. Don't need to wire your own flow.

## Patterns

### Configure once

```typescript
const config = await stripe.billingPortal.configurations.create({
  business_profile: { headline: 'Manage your subscription' },
  features: {
    payment_method_update: { enabled: true },
    subscription_cancel: { enabled: true, mode: 'at_period_end' },
    subscription_pause: { enabled: true },
    subscription_update: {
      enabled: true,
      default_allowed_updates: ['quantity', 'price'],
      products: [/* allowed product/price combinations */],
    },
    invoice_history: { enabled: true },
  },
});
```

### Per-session redirect

```typescript
const session = await stripe.billingPortal.sessions.create({
  customer: customer.id,
  return_url: `${BASE_URL}/billing-return`,
});
// Redirect to session.url
```

The portal session is short-lived (default ~1 hour). After the customer finishes, they return to `return_url`.

### Sync changes via webhooks, not Portal callbacks

The Portal modifies subscriptions directly via Stripe; changes flow back through standard webhook events (`customer.subscription.updated`, `payment_method.attached`, etc.). Don't rely on the `return_url` callback to confirm a change — listen for the webhook.

## Anti-patterns

- **Building your own billing UI before having a real reason to.** A year of engineering on undifferentiated work.
- **Treating the `return_url` callback as a state signal.** Customer can close the tab mid-flow. Webhooks are the truth.
- **Using long-lived Portal Session URLs.** They expire. Generate per-session.
- **Allowing every plan in `subscription_update`.** Curate which plan combinations are valid; the Portal will enforce based on `products`.

## Gotchas

- **Branding limited.** Logo + colors, no custom CSS. Customers see "powered by Stripe."
- **Can't show in-app entitlement details.** Only Stripe-side state. If a customer wants "what features do I have access to," that's your app's UI, not the Portal.
- **Can't trigger custom flows in your app.** You can only redirect and capture return. Approval flows, multi-step negotiation: build your own.
- **Pause may not be available for all subscription types** — check Dashboard config.

## Cross-references

- [Stripe Billing — Subscriptions](/stacks/stripe/stripe-billing/) — what the Portal manages
- [Setup Intents](/stacks/stripe/setup-intents/) — Portal handles these for "add card"
- [Webhooks](/stacks/stripe/webhooks/) — source of truth for changes the Portal makes
- [saas-architect on Stripe](/stacks/stripe/saas-architect/)
- Authoritative: [docs.stripe.com/customer-management](https://docs.stripe.com/customer-management)
