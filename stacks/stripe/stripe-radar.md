---
title: Stripe Radar
description: Stripe's ML fraud system. On by default for cards; Radar for Fraud Teams adds rules engine, manual review, allow/block lists.
product:
  name: Stripe Radar
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, e-commerce-architect, fintech-architect]
  authoritative_url: https://docs.stripe.com/radar
  notes: "ML models updated continuously; Adaptive Acceptance (2024) shifted block patterns. Don't disable Radar without a replacement."
---

## What it is

Stripe Radar is the ML fraud detection system. Every card payment processed by Stripe runs through Radar — it computes a risk score, applies your configuration (default or custom rules), and either approves, blocks, or holds the charge for review.

Two tiers:
- **Radar** (free with cards) — ML-driven blocks/holds, no manual rules
- **Radar for Fraud Teams** — adds the Rules engine, manual review queue, custom velocity rules, allow/block lists, dashboard for manual triage. Usage-priced.

Canonical reference: [docs.stripe.com/radar](https://docs.stripe.com/radar).

## When to use

Radar is on by default for card payments. The question is whether to upgrade to Radar for Fraud Teams:

- **Free Radar** — sufficient for low-fraud verticals, smaller volumes, teams without fraud expertise
- **Radar for Fraud Teams** — needed when you have repeat fraud patterns specific to your business, want manual review queues, need allow-list for VIP customers, or want custom velocity rules

## 2025-2026 currency anchors

- **ML models updated continuously** — block-list patterns shift; rules should be re-tuned annually.
- **Adaptive Acceptance** (2024) — Radar can occasionally over-ride a block when signal is strong it's legitimate. Trust it; don't fight to make rules more aggressive than defaults.
- **Early Fraud Warnings (EFWs)** — pre-dispute signals via `radar.early_fraud_warning.created` webhook. Most EFWs become disputes.

## Patterns

### Configuration discipline

1. **Don't disable Radar without a replacement.** Radar's ML is trained on Stripe's global fraud network. Turning it off and relying solely on your own fraud system loses that signal — almost always net-negative for fraud rate.

2. **Tune risk threshold based on dispute rate.** Default is balanced for an average merchant. Rising dispute rate → lower threshold (more blocks, fewer disputes, slightly higher false positives). Low fraud + too many holds → raise the threshold.

3. **Custom rules in Radar for Fraud Teams**: keep minimal. ML beats most rules. Use rules for:
   - Compliance (block specific countries you can't legally serve)
   - Known-fraudster patterns specific to your business (block if email matches your fraud list)
   - Velocity (block if this customer has 5+ attempts in 1 hour)
   
   Don't recreate Radar's ML signal with rules (CVC/AVS mismatches, etc.) — Radar already uses them.

4. **Allow-lists for VIP customers** — high-value frequent buyers who repeatedly trip Radar's blocks.

### Handle Early Fraud Warnings

`radar.early_fraud_warning.created` — pre-dispute network signal. Two strategies:

- **Proactive refund** — lose the charge revenue but avoid dispute fee + time. Best for low-margin, high-fraud-risk items, digital goods, gift cards.
- **Investigate** — Workbench shows EFW details. Refund if suspicious; accept otherwise.

Set an internal alert on EFWs; don't let them sit in the inbox until they become disputes.

### Disputes

`charge.dispute.created` — chargeback fired. ~7-21 days to submit evidence depending on network and reason. See the [e-commerce-architect overlay](/stacks/stripe/e-commerce-architect/) for dispute evidence templates.

## Anti-patterns

- **Disabling Radar without a replacement.** Net-negative for fraud rate.
- **Writing rules to recreate Radar's ML.** CVC/AVS, BIN risk, velocity — Radar uses them. Your rules should add business-specific signal, not duplicate.
- **Auto-submitting boilerplate dispute evidence.** Banks discount low-quality submissions. Take time per dispute.
- **Treating EFWs as just data.** Most become disputes. Act.

## Gotchas

- **Test mode Radar uses simplified rules.** Production fraud signal will differ — don't assume test mode behavior.
- **Adaptive Acceptance occasionally overrides blocks.** Expected; don't engineer around it.
- **Radar score is not exposed in real-time API.** You see `outcome.risk_level` (`normal`, `elevated`, `highest`) on the Charge after processing.
- **Custom rules can over-block.** Monitor false positive rate; tune.

## Cross-references

- [Payment Intents](/stacks/stripe/payment-intents/) — Radar runs on PI creation
- [Webhooks](/stacks/stripe/webhooks/) — `radar.early_fraud_warning.*`, `charge.dispute.*`
- [Stripe Sigma](/stacks/stripe/stripe-sigma/) — query suspicious patterns
- [Stripe Connect](/stacks/stripe/stripe-connect/) — platform liability for connected-account fraud
- [security-engineer on Stripe](/stacks/stripe/security-engineer/)
- [e-commerce-architect on Stripe](/stacks/stripe/e-commerce-architect/) — dispute evidence
- Authoritative: [docs.stripe.com/radar](https://docs.stripe.com/radar)
