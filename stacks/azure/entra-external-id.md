---
title: Entra External ID
description: Renamed from Azure AD B2C (2024). CIAM for customer-facing apps. New builds use External ID — B2C is in legacy support.
product:
  name: Entra External ID
  stack: azure
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, saas-architect, system-architect, healthcare-architect]
  authoritative_url: https://learn.microsoft.com/entra/external-id/
  notes: "Replaces Azure AD B2C; B2C in legacy support — do not propose new B2C tenant in 2026."
---

## What it is

Entra External ID is Microsoft's customer identity (CIAM) platform — email/password, social providers (Google, Facebook, Apple), enterprise SSO (SAML, WS-Federation), custom branding, MFA, Conditional Access for customer accounts. Renamed from Azure AD B2C in 2024. Canonical reference: [Entra External ID docs](https://learn.microsoft.com/entra/external-id/).

## When to use

Pick Entra External ID when:

- **Customer-facing app** (B2C-style) — sign-up, sign-in, password reset, social login.
- **White-label SaaS** — per-tenant branded sign-in pages.
- **Hybrid auth** — customers without their own IdP use External ID; customers with [Entra ID](/stacks/azure/entra-id/) get B2B federation.

Pick [Entra ID](/stacks/azure/entra-id/) instead for: employee SSO, partner B2B, AI agent identity.

## 2025-2026 currency anchors

- **Renamed from Azure AD B2C** (2024). B2C is in legacy support — do not propose new B2C tenants in 2026.
- **Same Conditional Access + MFA + Identity Protection** as workforce Entra ID — extended to customer accounts.
- **Custom branding** per app — logo, colors, layouts.
- **Self-service password reset.**
- **Custom user attributes** (extension properties) — useful for SaaS app tenant routing.
- **Token claims customization** — include `tenantId`, roles, groups in JWT.

## Patterns + anti-patterns

### Pattern: SaaS app tenant routing via extension attribute

Add `tenantId` extension attribute on user; include in token claims; app routes by claim. One External ID tenant serves many app tenants. See [SaaS Architect on Azure](/stacks/azure/saas-architect/).

### Pattern: Hybrid External ID + B2B federation

Customers without their own IdP → External ID local accounts (email/password or social).
Customers with Entra ID → multi-tenant Entra app + B2B federation; their users sign in with their creds.
Same app, multiple auth paths.

### Pattern: Per-customer External ID tenant for white-label

Provision an External ID tenant per customer organization; their users sign in to "their" portal. Branded sign-in pages, custom domain.

### Pattern: Conditional Access for customer accounts

MFA for high-value actions (account changes, payment), risk-based blocking on suspicious sign-ins, location-based controls. Same Conditional Access engine as workforce; configured per app.

### Anti-pattern: New Azure AD B2C tenant in 2026

B2C is in legacy support. New customer-facing apps go on External ID. Existing B2C tenants continue to work but new builds shouldn't choose B2C.

### Anti-pattern: Mixing customer + employee accounts in workforce Entra ID

Workforce tenant is for employees + partner B2B. Customer accounts go in External ID.

### Anti-pattern: Hard-coded tenant config in app

Tenant config (tier, features, custom domain) in DB or App Configuration with tenant-keyed entries.

## Gotchas

- **B2C → External ID migration** is real work. Plan as a project; not a flip-switch.
- **Custom branding** is per-app — multi-app SaaS = multiple branding configs.
- **Token claim customization** has structural limits — don't put large payloads in tokens.
- **Self-service flows** (sign-up, password reset) require careful UX + custom localization for international SaaS.
- **Federation with customer Entra ID** requires multi-tenant Entra app + customer-admin consent on their tenant.

## Cross-references

- [Entra ID](/stacks/azure/entra-id/) — workforce identity / B2B
- [SaaS Architect on Azure](/stacks/azure/saas-architect/) — multi-tenant customer auth
- [Security Engineer on Azure](/stacks/azure/security-engineer/) — Conditional Access for customer accounts
- [Healthcare Architect on Azure](/stacks/azure/healthcare-architect/) — External ID for patient portals (in BAA scope)
- [Entra External ID overview](https://learn.microsoft.com/entra/external-id/customers/overview)
