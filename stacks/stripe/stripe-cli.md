---
title: Stripe CLI
description: "The Stripe developer dev loop — `stripe listen`, `stripe trigger`, `stripe logs tail`. Stable surface; the standard for local Stripe development."
product:
  name: Stripe CLI
  stack: stripe
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, qa-engineer, security-engineer]
  authoritative_url: https://docs.stripe.com/stripe-cli
  notes: "Stable; `stripe listen` is the standard webhook dev loop. `stripe trigger` produces synthetic events for tests."
---

## What it is

The Stripe CLI is the local-development companion for Stripe. The main subcommands:

- **`stripe login`** — authenticates the CLI against your Stripe account (test mode).
- **`stripe listen --forward-to <url>`** — forwards real webhook deliveries from Stripe to your local server.
- **`stripe trigger <event>`** — produces a synthetic event in your test account (creating the underlying resources and firing the webhook).
- **`stripe logs tail`** — real-time streaming of API logs.
- **`stripe events resend <event_id>`** — replay a specific event.

Canonical reference: [docs.stripe.com/stripe-cli](https://docs.stripe.com/stripe-cli).

## When to use

Whenever you're developing Stripe code locally. Specifically:

- **Local webhook dev** — `stripe listen` is essentially mandatory; Stripe can't deliver webhooks directly to `localhost`.
- **Triggering test events** — happy-path + edge-case [webhook](/stacks/stripe/webhooks/) testing.
- **Log tailing** — debug live API calls in real time.
- **Resource scaffolding** — `stripe customers create`, `stripe products create`, etc. for quick test data.

## 2025-2026 currency anchors

- **Stable surface.** Versions ship regularly but no major breaks.
- **Per-session webhook signing secret** — `stripe listen` outputs a temporary `whsec_*` per session. Use as `STRIPE_WEBHOOK_SECRET` in local env. NOT the same as the live endpoint secret in Dashboard.
- **Tap to Pay simulator** — CLI can act as a virtual Terminal reader for local testing.

## Patterns

### Standard dev loop

```bash
# Terminal 1: forward webhooks to your local server
stripe listen --forward-to localhost:3000/api/webhooks/stripe

# Terminal 2: trigger synthetic events
stripe trigger payment_intent.succeeded
stripe trigger customer.subscription.created
stripe trigger invoice.payment_failed

# Terminal 3: tail logs
stripe logs tail
```

`stripe listen` outputs the webhook signing secret — copy it to your local `.env` as `STRIPE_WEBHOOK_SECRET`.

### Targeting specific events

```bash
stripe listen --events payment_intent.succeeded,charge.refunded --forward-to localhost:3000/webhooks
```

Filter to only the events you care about during a specific debugging session.

### Replay a specific event

```bash
stripe events resend evt_xxx
```

Useful when investigating a missed webhook — find the event ID in Workbench, resend it to your local handler.

### Resource scaffolding

```bash
stripe customers create --email=test@example.com
stripe products create --name="Test Product"
stripe prices create --product=prod_xxx --unit-amount=1000 --currency=usd
```

Faster than clicking through Dashboard during early development.

## Anti-patterns

- **Trying to use ngrok / custom tunneling for Stripe webhook dev.** `stripe listen` does this natively, with proper signature handling.
- **Using `stripe listen` signing secret as your live webhook secret.** It's per-session and test-mode-only. Live endpoints have their own persistent secrets.
- **Triggering events in live mode.** `stripe trigger` is test-mode only; you can't fire synthetic events in live.

## Gotchas

- **`stripe listen` session ends when CLI exits.** Restart and copy the new secret if your session drops.
- **`stripe trigger` creates real test-mode resources** — they accumulate. Clean up periodically.
- **Some events can't be triggered** directly — Connect-specific events, certain Treasury events. Drive the API directly to produce them.
- **Test mode only** for `trigger`, `listen` (against local), and synthetic events. Live operations require the API.

## Cross-references

- [Webhooks](/stacks/stripe/webhooks/) — the surface CLI helps you develop against
- [Stripe Workbench](/stacks/stripe/stripe-workbench/) — Dashboard counterpart for API logs/events
- [Payment Intents](/stacks/stripe/payment-intents/) — common `trigger` target
- [backend-architect on Stripe](/stacks/stripe/backend-architect/) — dev loop in context
- Authoritative: [docs.stripe.com/stripe-cli](https://docs.stripe.com/stripe-cli)
