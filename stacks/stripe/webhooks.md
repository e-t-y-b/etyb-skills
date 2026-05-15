---
title: Webhooks
description: Stripe's event delivery surface — at-least-once, ordering NOT guaranteed, signing verification is mandatory. The highest-value piece of Stripe infrastructure.
product:
  name: Webhooks
  stack: stripe
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, security-engineer, fintech-architect]
  authoritative_url: https://docs.stripe.com/webhooks
  notes: "Delivery ordering is NOT guaranteed; signing secret verification is mandatory; replay-tolerant idempotency is the team's responsibility, not Stripe's."
---

## What it is

Webhooks are how Stripe notifies your system of state changes asynchronously. Stripe HTTP POSTs a signed JSON event to your registered endpoint when a relevant change happens (payment succeeded, subscription updated, account capability changed, etc.).

**Webhooks are the source of truth for state changes in Stripe.** The synchronous API response is a snapshot; the webhook is the event. Build your system around webhooks first.

Canonical reference: [docs.stripe.com/webhooks](https://docs.stripe.com/webhooks).

## When to use

Every Stripe integration has webhooks. The question is which events to wire, not whether to use them.

Pattern: **Webhook is the only writer for state derived from Stripe.** Don't write Stripe-derived state from synchronous API responses — race conditions guaranteed.

## 2025-2026 currency anchors

- **Signing secret verification is mandatory.** Stripe still ships unauthenticated endpoint examples but production must verify.
- **`stripe.webhooks.constructEvent`** is the canonical verifier in the Node/Python/Ruby/etc. SDKs.
- **Per-endpoint signing secrets** — accounts often have 3-5 endpoints (main app, billing, Connect, analytics); each has its own secret.
- **Stripe CLI test-mode secret** — `stripe listen` generates a per-session secret; different from the persistent Dashboard-managed endpoint secret.

## The non-negotiable handler shape

```typescript
// Next.js App Router — pattern applies to any framework
export async function POST(req: Request) {
  const sig = req.headers.get('stripe-signature');
  const body = await req.text();  // raw body, NOT req.json()

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(
      body,
      sig!,
      process.env.STRIPE_WEBHOOK_SECRET!,
    );
  } catch (err) {
    return new Response('signature verification failed', { status: 400 });
  }

  // Idempotency: have we seen this event ID before?
  const alreadyProcessed = await db.processedStripeEvents.findUnique({
    where: { eventId: event.id },
  });
  if (alreadyProcessed) {
    return new Response('ok', { status: 200 });
  }

  // Mark as processed in the SAME transaction as the side effect
  await db.$transaction(async (tx) => {
    await tx.processedStripeEvents.create({
      data: { eventId: event.id, type: event.type, receivedAt: new Date() },
    });
    await handleStripeEvent(event, tx);
  });

  return new Response('ok', { status: 200 });
}
```

The non-negotiable parts:

1. **Raw body, not `req.json()`** — signature hashes the exact bytes. Re-stringified JSON won't match.
2. **Verify with per-endpoint secret** — multiple endpoints means multiple secrets.
3. **Idempotent by event ID** — Stripe is at-least-once; `evt_*` is the dedup key.
4. **Dedup + side effect in same transaction** — or you'll get marked-but-unprocessed (crash between) or re-applied (different crash).
5. **Return 200 quickly** — Stripe times out at ~30s and retries on non-2xx. Heavy work means queue-front.

## Patterns

### Queue-fronting for slow handlers

```typescript
export async function POST(req: Request) {
  const event = verifyAndDedup(req);
  await queue.send('stripe-events', { eventId: event.id, payload: event });
  return new Response('ok', { status: 200 });
}

// Worker
async function processStripeEvent(msg: QueueMessage) {
  await db.$transaction(async (tx) => {
    const seen = await tx.processedStripeEvents.findUnique({ where: { eventId: msg.eventId } });
    if (seen) return;
    await tx.processedStripeEvents.create({ data: { eventId: msg.eventId, type: msg.payload.type, receivedAt: new Date() } });
    await handleStripeEvent(msg.payload, tx);
  });
}
```

Use SQS / Cloud Tasks / Inngest / Trigger.dev / pg_boss — whatever your stack provides.

### Defense in depth (high-value operations)

For large refunds, marketplace payouts: verify signature, check timestamp window, check event ID dedup, then fetch the resource from Stripe (don't trust the event payload alone), then process, then ack. The fetch-from-Stripe step protects against an unlikely-but-possible forged-signature attack on a leaked signing secret.

### Webhook signature verification under test

```typescript
import Stripe from 'stripe';

const fakeSecret = 'whsec_test_secret';
const event = { id: 'evt_test_1', type: 'payment_intent.succeeded', data: { object: { id: 'pi_test_1' } } };
const payload = JSON.stringify(event);
const timestamp = Math.floor(Date.now() / 1000);
const signature = Stripe.webhooks.generateTestHeaderString({
  payload,
  secret: fakeSecret,
  timestamp,
});

const res = await fetch('/api/webhooks/stripe', {
  method: 'POST',
  headers: { 'stripe-signature': signature },
  body: payload,
});
expect(res.status).toBe(200);
```

Use `Stripe.webhooks.generateTestHeaderString`; don't compute HMAC by hand.

## Anti-patterns

- **Parsing `req.json()` then re-stringifying for signature.** Bytes differ; verification silently fails.
- **Skipping signature verification "for now."** Code gets deployed, path gets forgotten, attacker discovers it and forges `payment_intent.succeeded` to your fulfillment system.
- **Shared signing secret across endpoints.** Different endpoints, different secrets.
- **Trusting `Stripe-Signature` header existence without verification.** Always run `constructEvent`.
- **Returning non-2xx on verification failure with retries.** Use 400 (malformed), not 401/500 — 400 means "don't retry."
- **Assuming ordering.** `invoice.payment_succeeded` can arrive before `invoice.created`. Build handlers order-independent.
- **Fulfilling on synchronous API response, not webhook.** Webhook is the truth.
- **Idempotency by anything other than `evt_*`.** Don't dedup by amount or customer or metadata.
- **Rate-limiting your end of webhook ingestion.** Stripe will hammer during backlog drain.

## Gotchas

- **Webhook ordering NOT guaranteed.** Observed: `payment_intent.succeeded` before `payment_intent.processing`; `customer.subscription.updated` before `customer.subscription.created`; `charge.refunded` before `charge.succeeded`.
- **At-least-once delivery.** You will see `evt_*` more than once during retries. The event ID is the dedup key.
- **30-second timeout.** Stripe retries on non-2xx. Queue-front anything heavy.
- **Connect platforms have additional event types** — `account.updated`, `capability.updated`, `payout.*`, `transfer.*`, `application_fee.*`. See [Stripe Connect](/stacks/stripe/stripe-connect/).
- **Test mode + live mode have separate endpoints and secrets.** Configure both.
- **Workbench → Webhooks → Send test event** lets you replay any event to your endpoint.

## Cross-references

- [Idempotency Keys](/stacks/stripe/idempotency-keys/) — for outbound calls TO Stripe (different mechanism)
- [API Versions + Pinning](/stacks/stripe/api-versions/) — per-endpoint pinning
- [Stripe CLI](/stacks/stripe/stripe-cli/) — `stripe listen` + `stripe trigger` for local dev
- [Stripe Workbench](/stacks/stripe/stripe-workbench/) — endpoint management, event log, replay
- [Payment Intents](/stacks/stripe/payment-intents/) — `payment_intent.*` events
- [Stripe Billing](/stacks/stripe/stripe-billing/) — `invoice.*`, `customer.subscription.*`
- [Stripe Connect](/stacks/stripe/stripe-connect/) — `account.updated`, `capability.updated`, `payout.*`, `transfer.*`
- [Stripe Issuing](/stacks/stripe/stripe-issuing/) — `issuing_authorization.request` synchronous decision
- [backend-architect on Stripe](/stacks/stripe/backend-architect/)
- [security-engineer on Stripe](/stacks/stripe/security-engineer/) — signature security
- Authoritative: [docs.stripe.com/webhooks](https://docs.stripe.com/webhooks)
