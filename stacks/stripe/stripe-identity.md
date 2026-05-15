---
title: Stripe Identity
description: Document + selfie KYC verification — hosted flow for Connect onboarding supplement, step-up verification, account opening. Not enterprise-scale KYC.
product:
  name: Stripe Identity
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [fintech-architect, security-engineer, backend-architect]
  authoritative_url: https://docs.stripe.com/identity
  notes: "Document + selfie verification; pricing and supported countries shifted 2024-2025. NOT HIPAA-covered. Not a complete enterprise KYC solution."
---

## What it is

Stripe Identity provides document + selfie verification — the customer uploads a government ID (passport, driver's license, ID card) and a selfie, Stripe runs OCR + face match + liveness checks, and returns a verified result.

Canonical reference: [docs.stripe.com/identity](https://docs.stripe.com/identity).

## When to use

| Need | Stripe Identity? |
|------|------------------|
| KYC of [Connect](/stacks/stripe/stripe-connect/) platform sellers (supplemental) | Often yes |
| Account opening verification for a non-Connect service | Yes (light/medium volume) |
| Step-up verification on high-value transactions | Yes |
| Enterprise KYC at scale | **No** — use Persona, Jumio, Onfido, Veriff, Trulioo |
| Multi-step KYB (business verification, beneficial owners) | No (use specialized vendor) |
| Ongoing periodic re-verification | No (limited automation) |

For Connect platforms, the built-in Connect onboarding KYC (collected via `account_link`) is usually sufficient. Stripe Identity supplements when you need verification outside the Connect onboarding flow.

## 2025-2026 currency anchors

- **Supported countries expanded** through 2024-2025; check current support list before committing.
- **Pricing model shifted** 2024-2025 — verify per-verification cost.
- **NOT HIPAA-covered** out of the box. PHI in selfies/documents is not a covered use.
- **GDPR**: Stripe is data processor for Identity; ensure DPA covers it.

## Patterns

### Create a verification session

```typescript
const session = await stripe.identity.verificationSessions.create({
  type: 'document',  // or 'id_number' for SSN-style
  options: {
    document: {
      allowed_types: ['driving_license', 'passport', 'id_card'],
      require_id_number: true,
      require_live_capture: true,
      require_matching_selfie: true,
    },
  },
  metadata: { user_id: userId },
});

// Send session.url to the user (or use the embedded JS SDK)
```

### Listen for outcome

```typescript
async function handleVerificationVerified(event: Stripe.Event) {
  const session = event.data.object as Stripe.Identity.VerificationSession;
  const userId = session.metadata?.user_id;
  const verifiedOutputs = session.last_verification_report; // verified name, DOB, address
  await markUserVerified(userId, verifiedOutputs);
}
```

Webhook event: `identity.verification_session.verified`.

### Don't pass document images through your servers

The hosted (redirect or embedded JS) flow uploads documents directly to Stripe. You receive `verified_outputs` (extracted name, DOB, address, ID number) — never the raw document image on your servers. Don't try to proxy.

## Anti-patterns

- **Using Stripe Identity for PHI workflows.** Not HIPAA-covered. Escalate immediately if PHI is in play.
- **Storing raw document images** — Stripe stores them; you receive verified outputs. Don't try to pull and re-store.
- **Identity as your entire KYC.** For enterprise volume or multi-step KYB, dedicated vendors (Persona, Jumio, Onfido) have richer workflows.
- **Identity for ongoing periodic re-verification.** Limited automation; build the re-verification trigger yourself and call Identity per cycle.

## Gotchas

- **Country support varies.** Verify your target geographies are supported before integrating.
- **Liveness checks reject low-light + poor-camera selfies.** Build the retry UX gracefully.
- **`verified_outputs.address` may be missing** if the document doesn't carry an address. Don't assume completeness.
- **`document.allowed_types`** restricts which documents the customer can use. Limiting too narrowly causes drop-off; allowing too broadly may include weaker documents.

## Cross-references

- [Stripe Connect](/stacks/stripe/stripe-connect/) — primary use case (supplemental seller KYC)
- [Webhooks](/stacks/stripe/webhooks/) — `identity.verification_session.*` events
- [fintech-architect on Stripe](/stacks/stripe/fintech-architect/) — broader KYC vendor landscape
- [security-engineer on Stripe](/stacks/stripe/security-engineer/) — data residency + HIPAA
- Authoritative: [docs.stripe.com/identity](https://docs.stripe.com/identity)
