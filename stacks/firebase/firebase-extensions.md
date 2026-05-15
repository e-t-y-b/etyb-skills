---
title: Firebase Extensions
description: Pre-packaged Firebase deployments for common tasks — auth resize, trigger email, image processing, Stripe payments (community), AI extensions. Marketplace expanded post-2024.
product:
  name: Firebase Extensions
  stack: firebase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, ai-ml-engineer, devops-engineer]
  authoritative_url: https://firebase.google.com/docs/extensions
  notes: "Marketplace expanded; v1 spec stable; some popular extensions (e.g., Stripe payments) now community-maintained."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Firebase Extensions are pre-packaged, configurable Firebase deployments — typically a set of Cloud Functions + resources (Firestore collections, Storage buckets, IAM bindings) wired together for a common task. Install with one command; configure with extension-specific parameters; the extension owns its lifecycle.

Canonical reference: [Firebase Extensions docs](https://firebase.google.com/docs/extensions).

## When to use it

**Use Extensions when:**

- A standard task fits a published extension (image resize, trigger email, BigQuery export, search mirror)
- You want curated, security-reviewed glue code over rolling your own
- The extension is actively maintained (check the marketplace)

**Don't use Extensions when:**

- You need significant behavioral customization beyond the extension's parameters — fork or write your own
- The extension is unmaintained — community-maintained extensions vary in quality
- Compliance requires you to own every line of backend code

## 2025-2026 currency anchors

- **Marketplace expanded post-2024.** More first-party + community extensions.
- **v1 spec stable.** Extension authoring discipline is well-defined.
- **Stripe payment extension now community-maintained.** Production teams typically write their own Cloud Functions for Stripe integration rather than depend on a community extension.
- **AI extensions** — multiple extensions for Gemini integration, RAG indexing, embedding generation. Evaluate against rolling [Genkit](/stacks/firebase/genkit/) directly.

## Patterns

### Install via CLI

```bash
firebase ext:install firebase/firestore-bigquery-export --project=my-project
```

Prompts for extension parameters. Deploys Cloud Functions + creates required resources.

### Install via console

The Firebase Console → Extensions tab has a visual flow. Easier for first-time installs; CLI is better for repeatable infrastructure.

### Common useful extensions

- **`firestore-bigquery-export`** — mirrors Firestore writes to BigQuery for analytics. Almost always the right answer for "I want SQL on my Firestore data."
- **`firestore-send-email`** — triggers SendGrid / Mailgun email on Firestore writes. Good for "send confirmation email on order creation" patterns.
- **`storage-resize-images`** — resizes uploaded images to multiple variants. Standard for image-heavy apps.
- **AI extensions** — `firestore-genai-chatbot`, `firestore-multimodal-genai`, etc. Evaluate against direct Genkit deployment.

### Authoring your own extension

For ISV distribution or internal reuse, authoring an Extension is a separate discipline. Out of scope for most ETYB engagements; defer to the [Firebase Extensions authoring docs](https://firebase.google.com/docs/extensions/publishers).

## Anti-patterns

- **Treating Extensions as production-grade off-the-shelf for sensitive integrations** — community-maintained extensions (notably the Stripe one) drift; for payments, write your own Cloud Functions.
- **Installing extensions without reading the IAM bindings** — extensions request the IAM roles they need. Review before approving.
- **Modifying extension-installed functions** — the next `ext:update` overwrites your changes. Fork or write your own.
- **Stacking many extensions without governance** — each is a deployment surface; updates can break dependencies.

## Gotchas

- **Extension Cloud Functions count toward your Functions quota** — a heavy extension can use significant resources.
- **Updates are opt-in** — extensions don't auto-update. Pin to a version; review changelog before bumping.
- **Extension-managed Firestore collections are still YOUR data** — uninstalling doesn't delete the data; document this in your runbook.
- **Region selection at install time** — match the extension's Cloud Functions region to your data region.
- **Permissions sprawl** — every extension grants its functions IAM roles. Audit periodically.

## Cross-references

- [Cloud Functions for Firebase](/stacks/firebase/cloud-functions-firebase/) — the substrate Extensions deploy on
- [Genkit](/stacks/firebase/genkit/) — direct alternative to AI extensions
- [Firebase CLI](/stacks/firebase/firebase-cli/) — `ext:install`, `ext:update`, `ext:uninstall`
- Authoritative: [firebase.google.com/docs/extensions](https://firebase.google.com/docs/extensions)
