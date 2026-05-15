---
title: Email Workers
description: Programmable inbound email handlers — write a Worker that receives, transforms, forwards, or drops mail delivered through Email Routing.
product:
  name: Email Workers
  stack: cloudflare
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, ai-ml-engineer]
  authoritative_url: https://developers.cloudflare.com/email-routing/email-workers/
  notes: "Inbound-only handler surface; tied to Email Routing. Body shape and reply APIs evolve slowly."
---

## What it is

Email Workers are [Workers](/stacks/cloudflare/workers/) with an `email(message, env, ctx)` handler. Cloudflare's [Email Routing](/stacks/cloudflare/email-routing/) delivers inbound mail for your custom domain to your Worker; the Worker can forward, drop, reply, or process. **Inbound-only** — Cloudflare does not send outbound mail from your domain by default.

Authoritative reference: [developers.cloudflare.com/email-routing/email-workers](https://developers.cloudflare.com/email-routing/email-workers/).

## When to use

- **Programmatic triage** — classify inbound mail with [Workers AI](/stacks/cloudflare/workers-ai/) (spam vs sales vs support) and route accordingly.
- **Inbound webhooks via email** — partners that emit reports as email attachments; parse and store in [R2](/stacks/cloudflare/r2/) or [D1](/stacks/cloudflare/d1/).
- **Auto-responders with conditional logic** — different replies based on sender, subject, or body.
- **Ticket ingestion** — convert inbound mail to support tickets in your CRM via API.

Don't reach for Email Workers when:

- Simple address-to-address forwarding suffices — use plain [Email Routing](/stacks/cloudflare/email-routing/) rules.
- High-volume processing is involved — the Worker should ACK fast and push to a [Queue](/stacks/cloudflare/queues/) for the heavy work.
- You need to send outbound mail — Email Workers cannot originate mail; use a transactional email provider.

## 2025-2026 currency anchors

- **Stable handler shape.** `email(message, env, ctx)` with `message.forward(address)`, `message.setReject(reason)`, and `message.reply(emailMessage)`.
- **`reply()` for in-thread responses** is supported; verify current limits on size and frequency before designing auto-reply flows.
- **Tighter integration with AI Gateway + Workers AI** for classification and summarization — `await env.AI.run(...)` inside an email handler is a 2025-era pattern.

## Patterns

### Triage and forward

```ts
export default {
  async email(message, env, ctx) {
    const classification = await env.AI.run("@cf/meta/llama-4-scout-17b-16e-instruct", {
      messages: [
        { role: "system", content: "Classify support email. Output one of: bug, billing, sales, spam." },
        { role: "user", content: `Subject: ${message.headers.get("subject")}\n\n${await streamToString(message.raw)}` }
      ]
    });
    const label = classification.response.trim().toLowerCase();
    if (label === "spam") return message.setReject("Spam");
    if (label === "billing") return message.forward("billing@example.com");
    if (label === "sales") return message.forward("sales@example.com");
    return message.forward("support@example.com");
  }
};
```

### ACK-fast, queue the work

```ts
export default {
  async email(message, env, ctx) {
    const raw = await new Response(message.raw).arrayBuffer();
    const key = `inbound/${Date.now()}-${crypto.randomUUID()}.eml`;
    await env.R2.put(key, raw);
    await env.JOBS.send({ type: "process_email", key, from: message.from, to: message.to });
    // The Email Worker handler exits; downstream processing is decoupled.
  }
};
```

This pattern is the email-ingest equivalent of webhook ACK-fast. Heavy work — parsing MIME, calling external CRMs, running LLM analysis — belongs in a [Queue](/stacks/cloudflare/queues/) consumer or a [Workflow](/stacks/cloudflare/workflows/).

### Conditional reply

```ts
import { EmailMessage } from "cloudflare:email";

const reply = new EmailMessage(
  "support@example.com",
  message.from,
  `From: support@example.com\nTo: ${message.from}\nIn-Reply-To: ${message.headers.get("message-id")}\nSubject: Re: ${message.headers.get("subject")}\n\nThanks — we got your message and will reply within 24h.\n`
);
await message.reply(reply);
```

## Anti-patterns

- **Heavy synchronous work in the email handler.** Email handlers share Worker CPU budgets — long-running parsing or external API calls inflate cold-paths. Push to a [Queue](/stacks/cloudflare/queues/).
- **No spam controls before AI classification.** Burning [Workers AI](/stacks/cloudflare/workers-ai/) neurons on obvious spam is wasteful — apply basic SPF/DKIM/DMARC + sender allow/deny lists first.
- **Trying to outbound from the Email Worker as a generic SMTP client.** The runtime does not provide outbound SMTP. Use Resend / Postmark / MailChannels via HTTPS.

## Gotchas

1. **`message.raw` is a `ReadableStream`.** Consume it once. If you need both the raw bytes and parsed MIME, tee the stream or buffer once.
2. **Reply quotas exist.** Cloudflare rate-limits `reply()` to discourage abuse loops; design auto-responders to be idempotent and capped.
3. **No outbound mail by default.** If your business needs outbound notifications, set up a transactional provider — Email Workers handle the inbound half only.
4. **MIME parsing isn't built in.** Use a lightweight parser (`postal-mime` and similar are edge-compatible) — full Node-style libraries often won't run on workerd.

## Cross-references

- [Email Routing](/stacks/cloudflare/email-routing/) — the inbound delivery surface that triggers Email Workers
- [Workers](/stacks/cloudflare/workers/) — the runtime
- [Queues](/stacks/cloudflare/queues/) — decouple heavy processing
- [Workers AI](/stacks/cloudflare/workers-ai/) — classification, summarization, triage
- [R2](/stacks/cloudflare/r2/) — archive raw `.eml` for replay
- Role overlay: [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/)
- Authoritative: [developers.cloudflare.com/email-routing/email-workers](https://developers.cloudflare.com/email-routing/email-workers/)
