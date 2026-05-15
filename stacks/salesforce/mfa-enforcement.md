---
title: MFA Enforcement
description: Phased mandate June-August 2026. Phishing-resistant MFA required for admin-tier users; SMS and TOTP no longer sufficient for high-privilege roles.
product:
  name: MFA Enforcement
  stack: salesforce
  drift_risk: high
  last_verified_on: "2026-05-12"
  applies_to_roles: [security-engineer, devops-engineer]
  authoritative_url: https://help.salesforce.com/s/articleView?id=sf.security_overview_mfa.htm
  notes: "Phased enforcement June-August 2026; phishing-resistant MFA required for Modify All Data / View All Data / Customize Application / Author Apex."
---

<div class="etyb-currency-banner">Last verified: 2026-05-12 against Salesforce Spring '26.</div>

## What it is

Salesforce's phased MFA mandate for UI logins, with elevated requirements for high-privilege users. The window is **June – August 2026**, phased across customer cohorts. Phishing-resistant factors (passkeys, FIDO2 security keys) become mandatory for the admin tier; SMS and TOTP are no longer sufficient for users with Modify All Data, View All Data, Customize Application, or Author Apex.

Canonical reference: [Salesforce MFA Overview](https://help.salesforce.com/s/articleView?id=sf.security_overview_mfa.htm).

## Tiers and acceptable factors

| Tier | Requirement | Acceptable factors |
|------|-------------|-------------------|
| All UI users | MFA required at every login | TOTP (Salesforce Authenticator, Google Authenticator), security key, passkey |
| API-only users (no UI access) | Exempt | n/a (use [External Client Apps](/stacks/salesforce/external-client-apps/) + scoped tokens) |
| **Modify All Data / View All Data / Customize Application / Author Apex** | **Phishing-resistant MFA required** | **Security keys (FIDO2 / WebAuthn) or passkeys only.** SMS and TOTP not sufficient. |

## When this matters

- Every Salesforce org with UI users (which is most)
- Especially: orgs with seasoned admins on SMS or TOTP — must move them to passkey/FIDO2 before their cohort's enforcement date
- ISVs distributing apps used by admin-tier customer users — your install/configuration UX must work for passkey-required users

## 2025-2026 currency anchors

- Phased enforcement **June – August 2026** by customer cohort.
- **Phishing-resistant MFA required** for high-privilege users — SMS / TOTP are no longer sufficient for that tier.
- **High-risk IP auto-containment** (expansion May 2026) — anonymizing VPNs / proxies / Tor auto-blocked for connected apps and API by default.

## Operational checklist

- [ ] Enable MFA org-wide (Setup → Identity Verification → "Require multi-factor authentication for all direct UI logins")
- [ ] Identify the high-privilege user set: query `PermissionSetAssignment` joined to `PermissionSet` for `PermissionsModifyAllData`, `PermissionsViewAllData`, `PermissionsCustomizeApplication`, `PermissionsAuthorApex`
- [ ] Issue FIDO2 keys (YubiKey, Titan) or enroll passkeys for that set
- [ ] Configure a **Login Flow** to detect the high-privilege user set and enforce phishing-resistant factor selection
- [ ] Remove SMS as an MFA option for the high-privilege set (Setup → Identity Verification → factor allowlist)
- [ ] Audit `LoginHistory` for users without a strong factor recorded; block them with a temporary IP restriction until enrolled
- [ ] Document the API-only user inventory and confirm those users have no UI login capability (profile / permission set check)

## Anti-patterns

- **SMS or TOTP for an admin** in 2026 — no longer compliant.
- **Treating MFA enforcement as "set and forget."** Phishing-resistant factor enrollment requires per-user issuance and a fallback story.
- **API-only users with UI access "just in case."** Either fully API-only (exempt from MFA but with no UI login) or full UI user (must enroll). The hybrid is a hole.
- **Skipping the LoginHistory audit.** Users who never logged in since MFA was enabled may show no MFA enrollment — and they will lock out when they try.

## Gotchas

- **Phishing-resistant requirement is on the *permission*, not the *user*.** A user inherits the requirement from any assignment of Modify All Data / View All Data / Customize Application / Author Apex.
- **Login Flows are the enforcement primitive** for phishing-resistant — branch on user attribute, force a passkey factor selection step.
- **High Assurance sessions** can require fresh MFA step-up before sensitive actions (export PII, run admin reports). This is *separate* from login-time MFA — both can be in effect.
- **High-risk IP auto-containment expanded May 2026** — verify the toggle on older orgs that may not have it enabled by default.

## Cross-references

- Security depth and migration: [security-engineer on Salesforce](/stacks/salesforce/security-engineer/)
- API-only paths using ECA: [External Client Apps](/stacks/salesforce/external-client-apps/)
- CI auth (JWT-bearer is API, not UI — exempt from MFA): [sf CLI](/stacks/salesforce/sf-cli/)
- Authoritative: [Salesforce MFA documentation](https://help.salesforce.com/s/articleView?id=sf.security_overview_mfa.htm)
