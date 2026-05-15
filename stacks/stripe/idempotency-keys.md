---
title: Idempotency Keys
description: "The `Idempotency-Key` header on outbound calls to Stripe. 24-hour TTL contractually guaranteed since 2024. Don't confuse with webhook event-ID dedup."
product:
  name: Idempotency Keys
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, security-engineer]
  authoritative_url: https://docs.stripe.com/api/idempotent_requests
  notes: "TTL guaranteed at 24 hours since 2024; some teams still mint UUIDs that don't survive client retries. Distinct from webhook event-ID dedup."
---

## What it is

The `Idempotency-Key` header is what makes outbound POSTs to Stripe safe under retry. If your code sends the same key with the same request body, Stripe returns the same response — no duplicate resource created, no double-charge.

Canonical reference: [docs.stripe.com/api/idempotent_requests](https://docs.stripe.com/api/idempotent_requests).

## When to use

Every state-changing API call to Stripe should pass `Idempotency-Key`. Specifically:

- `POST /v1/charges`
- `POST /v1/payment_intents`
- `POST /v1/transfers`
- `POST /v1/refunds`
- `POST /v1/subscriptions`
- `POST /v1/customers`
- `POST /v1/accounts`
- Etc.

If you don't include the key, network retries from your side create duplicate resources. That's a double-charge bug waiting to happen.

## 2025-2026 currency anchors

- **24-hour TTL contractually guaranteed** since 2024. Before, "best effort"; now a real guarantee — but only for 24 hours.
- **Retry chains longer than 24h must mint new keys.** You've already accepted duplicate-work risk at that point.
- **Distinct from webhook dedup.** Webhook events deduplicate by `evt_*` event ID; that's a separate mechanism. Don't confuse the two.

## Patterns

### Deterministic key from business intent

```typescript
const idempotencyKey = `create-pi-${orderId}-${attemptId}`;
const pi = await stripe.paymentIntents.create(
  {
    amount: 5000,
    currency: 'usd',
    metadata: { orderId },
  },
  { idempotencyKey },
);
```

The key should be derivable from inputs ("charge for order X attempt Y"), not from the current HTTP request. If the client retries due to a network blip, the same key produces the same PaymentIntent. If the user explicitly retries (new attempt), a new key produces a new PaymentIntent.

### Persist before calling

If the call succeeds but your local commit fails, you need to retry with the same key to avoid duplicates. Insert the intent record with the key first, then call Stripe.

```typescript
async function createPaymentIntentForOrder(orderId: string) {
  const order = await db.orders.findUnique({ where: { id: orderId } });
  if (order.stripePaymentIntentId) {
    return await stripe.paymentIntents.retrieve(order.stripePaymentIntentId);
  }
  
  const pi = await stripe.paymentIntents.create(
    { /* ... */ },
    { idempotencyKey: `order-pi-${orderId}` },
  );
  
  await db.orders.update({
    where: { id: orderId },
    data: { stripePaymentIntentId: pi.id },
  });
  
  return pi;
}
```

### Meter events use `identifier`

[Meter API](/stacks/stripe/meter-api/) events take an `identifier` field instead of `Idempotency-Key`. Same semantic — dedup by deterministic ID. Use request IDs or job IDs.

## Anti-patterns

- **Random UUIDs minted per request.** If your retry path mints a new UUID, retries create duplicates. Defeats the entire purpose.
- **Confusing inbound webhook dedup with outbound idempotency.** Webhook events dedup by `evt_*`; outbound calls dedup by `Idempotency-Key`. Different keys, different mechanisms.
- **Reusing keys across different requests.** Stripe returns the original response, which may not match what you wanted. Keys must match request bodies.
- **No idempotency on `transfers` or `refunds`.** Double-transfer or double-refund are real failure modes. Include the key.

## Gotchas

- **`StripeIdempotencyError`** — same key used with a different request body. Bug; fix the caller.
- **24h is a real limit.** Don't design retry chains that span days assuming Stripe still dedupes.
- **Key length** — alphanumeric, up to 255 chars. Keep them reasonable.
- **PATCH vs POST** — some PATCHes accept idempotency keys, but consult docs per endpoint.

## Cross-references

- [Webhooks](/stacks/stripe/webhooks/) — inbound dedup by `evt_*` (separate mechanism)
- [Payment Intents](/stacks/stripe/payment-intents/) — primary place to use idempotency keys
- [Meter API](/stacks/stripe/meter-api/) — `identifier` field semantic equivalent
- [Stripe Connect](/stacks/stripe/stripe-connect/) — idempotent Connect account creation
- [backend-architect on Stripe](/stacks/stripe/backend-architect/)
- Authoritative: [docs.stripe.com/api/idempotent_requests](https://docs.stripe.com/api/idempotent_requests)
