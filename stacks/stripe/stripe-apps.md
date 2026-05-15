---
title: Stripe Apps
description: Build embedded apps inside the Stripe Dashboard using Stripe Apps SDK and Stripe UI Toolkit. Distribution via Stripe App Marketplace.
product:
  name: Stripe Apps
  stack: stripe
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, frontend-architect]
  authoritative_url: https://docs.stripe.com/stripe-apps
  notes: "Embedded apps in Stripe Dashboard; Stripe Apps SDK + Stripe UI Toolkit. Different surface from the main API; less common but worth knowing exists."
---

## What it is

Stripe Apps lets you build apps that run **inside** the Stripe Dashboard — extensions that appear next to Stripe's native UI surfaces (customer pages, payment pages, invoice pages). Built with the Stripe Apps SDK + Stripe UI Toolkit (React-based component library matching Stripe's design system).

Distribution is via the Stripe App Marketplace.

Canonical reference: [docs.stripe.com/stripe-apps](https://docs.stripe.com/stripe-apps).

## When to use

Stripe Apps is the right surface when:
- You're a B2B vendor whose product integrates closely with Stripe (CRM augmentation, billing analytics, dispute management, tax tooling, reconciliation)
- Your customers spend significant time in the Stripe Dashboard and would benefit from your app being visible there
- You want a discovery + installation channel (App Marketplace)

If you're just calling Stripe's API from your own app, you don't need Stripe Apps. Stripe Apps is specifically for things rendered inside the Dashboard.

## 2025-2026 currency anchors

- **Stripe UI Toolkit** matured — modern React components matching Stripe's design system.
- **App Marketplace** — distribution channel for apps. Listing requires Stripe review.
- **Permissions model** — apps declare scoped permissions (similar to OAuth scopes); users approve at install.

## Patterns

### Manifest-driven configuration

A Stripe App is configured via a manifest that declares:
- Where in the Dashboard the app appears (customer view, payment view, navigation menu, etc.)
- Permissions the app needs
- Auth method (OAuth or API key based)

### UI Toolkit components

Components: `Box`, `Button`, `Inline`, `List`, `Section`, `Switch`, `TextField`, `Banner`, etc. Use them; don't try to render custom CSS — the Dashboard sandbox restricts what you can do.

### Auth + permissions

Apps run in a sandboxed iframe inside the Dashboard. They authenticate against Stripe via signed JWT or use the user's authenticated session, depending on the integration shape. Permissions are scoped at install.

## Anti-patterns

- **Trying to use Stripe Apps as your main product surface.** It's an extension surface; your primary product UI should live in your own app.
- **Building Stripe Apps when an API integration would do.** If your customers don't need to interact with your tool inside the Dashboard, build a standalone app + Stripe API integration.

## Gotchas

- **Sandboxed iframe limitations** — no arbitrary DOM, no third-party scripts beyond what UI Toolkit allows.
- **Listing review** — App Marketplace listings go through Stripe review; plan timeline.
- **Permission scopes affect install conversion** — overly broad permissions reduce install rate.

## Cross-references

- [Restricted API Keys](/stacks/stripe/restricted-api-keys/) — scoping the app's Stripe access
- [Stripe Workbench](/stacks/stripe/stripe-workbench/) — adjacent developer surface
- Authoritative: [docs.stripe.com/stripe-apps](https://docs.stripe.com/stripe-apps)
