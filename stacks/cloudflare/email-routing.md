---
title: Email Routing
description: Cloudflare's inbound email routing — accept mail to your custom domain, forward to mailbox(es) or process via Email Workers.
product:
  name: Email Routing
  stack: cloudflare
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer]
  authoritative_url: https://developers.cloudflare.com/email-routing/
  notes: "Inbound-only; outbound via MailChannels or providers via SMTP."
---

## What it is

Email Routing handles inbound email for your custom domain — accept mail to addresses like `support@example.com`, route it to a mailbox, multiple recipients, or to a Worker via [Email Workers](/stacks/cloudflare/email-workers/). **Inbound-only** — for outbound, use external providers (Resend, Postmark, MailChannels, SES).

Authoritative reference: [developers.cloudflare.com/email-routing](https://developers.cloudflare.com/email-routing/).

## When to use

- **Custom-domain inbound email** without running your own MTA.
- **Auto-forward `support@`, `hello@`, etc. to a real mailbox.**
- **Programmatic processing of inbound mail** — pair with [Email Workers](/stacks/cloudflare/email-workers/).

Don't use Email Routing for outbound — use Resend / Postmark / MailChannels / SES.

## 2025-2026 currency anchors

- **Stable.** Inbound-only is the canonical scope.
- **Outbound from Workers** typically goes through MailChannels (sometimes Cloudflare-promoted) or first-party providers via SMTP.

## Patterns

### Simple forwarding

Configure in dashboard: `support@example.com` → `team@your-company.com`. Cloudflare handles SPF/DKIM/DMARC alignment for your domain.

### Forward to Email Worker

See [Email Workers](/stacks/cloudflare/email-workers/) for the handler. Cloudflare delivers the inbound message to your Worker; the Worker can forward, drop, or process.

### Forward to multiple recipients

Configure multi-recipient routing in the dashboard; each gets a copy.

## Anti-patterns

- **Trying to send outbound from Email Routing** — it's inbound-only.
- **Not setting up SPF/DKIM/DMARC** for your domain — Cloudflare can help with the records but they need to exist.
- **Routing high-volume inbound to a single Worker** without queueing — use [Queues](/stacks/cloudflare/queues/) if processing is non-trivial.

## Gotchas

1. **Inbound-only.** No outbound from Email Routing itself.
2. **SPF/DKIM/DMARC** alignment matters for deliverability — Cloudflare's DNS makes this manageable.
3. **Attachments and size limits** apply — verify against current docs.

## Cross-references

- [Email Workers](/stacks/cloudflare/email-workers/) — programmatic handlers for inbound mail
- [Workers](/stacks/cloudflare/workers/) — runtime for Email Workers
- [Queues](/stacks/cloudflare/queues/) — for high-volume inbound processing decoupling
- Role overlay: [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/), [devops-engineer on Cloudflare](/stacks/cloudflare/devops-engineer/)
- Authoritative: [developers.cloudflare.com/email-routing](https://developers.cloudflare.com/email-routing/)
