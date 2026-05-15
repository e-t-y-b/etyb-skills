---
title: External Client Apps (ECA)
description: The replacement for Connected Apps. Mandatory migration deadline May 11, 2026 — new Connected Apps cannot be created after.
product:
  name: External Client Apps
  stack: salesforce
  drift_risk: high
  last_verified_on: "2026-05-12"
  applies_to_roles: [security-engineer, backend-architect, devops-engineer, saas-architect, fintech-architect]
  authoritative_url: https://help.salesforce.com/s/articleView?id=sf.connected_apps_eca_migration.htm
  notes: "Mandatory migration deadline May 11, 2026; Connected App creation blocked after."
---

<div class="etyb-currency-banner">Last verified: 2026-05-12 against Salesforce Spring '26.</div>

## What it is

**External Client Apps (ECA)** are the modern replacement for Connected Apps — Salesforce's auth surface for any external app, integration, OAuth flow, or callback. ECAs ship short-lived access tokens, rotatable refresh tokens, named principals (multiple identities per app), scoped permissions, and first-class auditability.

**The most important date in the Salesforce stack right now:** **May 11, 2026.** After that date, plain Connected App creation is blocked for AppExchange listings and most new auth integrations.

Canonical reference: [External Client Apps Migration](https://help.salesforce.com/s/articleView?id=sf.connected_apps_eca_migration.htm).

## When to use it

**Use ECAs for:**

- All net-new auth integrations (CI/CD JWT, customer-facing OAuth, server-to-server)
- All AppExchange-distributed managed packages
- Server-to-server integrations needing OAuth client credentials
- Backend integrations needing rotated refresh tokens
- Any auth scenario that would have been a Connected App pre-2026

**Existing Connected Apps continue to function** — until Salesforce announces a sunset (no date yet). Treat them as technical debt.

## 2025-2026 currency anchors

| What | When | Who affected |
|------|------|-------------|
| Plain Connected App creation locked for AppExchange listings | **May 11, 2026** | Every ISV and every customer with an AppExchange-published Connected App |
| Existing Connected Apps keep functioning | After May 11 | Until Salesforce announces a sunset |
| ECA-only world for new connected experiences | After May 11 | New auth on AppExchange must be ECA; many customer internal orgs will adopt ECA as the default |

## ECA vs Connected App

| Feature | Connected App | External Client App (ECA) |
|---------|---------------|---------------------------|
| Token lifetime | Long-lived refresh tokens common | **Short-lived access tokens**; refresh tokens rotate |
| Principal model | Single named principal or per-user | **Named principals** (multiple identities per app); per-user still supported |
| Secret storage | OAuth consumer secret in custom metadata or installed package | **External Credentials + Named Credentials** — first-class, rotatable |
| Permission scoping | Coarse OAuth scopes | Scoped + custom permissions + granular admin-controlled consent |
| Auditability | Login history only | Full ECA event stream; better fit for Event Monitoring |

## Migration path

1. **Inventory existing Connected Apps.** `SELECT Id, Name, CreatedDate, LastUsedDate FROM ConnectedApplication` plus AppManager / AppExchange listing review.
2. **Categorize** — internal-only vs AppExchange-published vs partner-distributed.
3. **Build ECA equivalents.** For AppExchange ISVs: produce a new ECA-based 2GP package alongside the legacy Connected App. For internal orgs: define the ECA in metadata, wire External Credentials, route auth through it.
4. **Cut over** subscribers/users with a flag-driven migration; don't big-bang.
5. **Decommission the Connected App** once traffic has moved (revoke tokens, delete the metadata).

## Patterns

### ECA metadata sketch

```xml
<!-- force-app/main/default/externalClientApps/MyApp.eca-meta.xml -->
<ExternalClientApplication xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>My App</label>
    <contactEmail>security@example.com</contactEmail>
    <distributionState>Local</distributionState>
    <oauthSettings>
        <isClientCredentialsFlowEnabled>true</isClientCredentialsFlowEnabled>
        <isRefreshTokenRotationEnabled>true</isRefreshTokenRotationEnabled>
        <accessTokenValueType>Opaque</accessTokenValueType>
        <scopes>
            <scope>api</scope>
            <scope>refresh_token</scope>
        </scopes>
    </oauthSettings>
</ExternalClientApplication>
```

### External Credential bound to the ECA

```xml
<!-- force-app/main/default/externalCredentials/MyApp_EC.externalCredential-meta.xml -->
<ExternalCredential xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>My App External Credential</label>
    <authenticationProtocol>OAuth</authenticationProtocol>
    <namedPrincipals>
        <parameters>
            <parameterName>OAuthClient</parameterName>
            <parameterValue>MyApp_ECA</parameterValue>
        </parameters>
        <principalName>IntegrationUser</principalName>
        <sequenceNumber>1</sequenceNumber>
    </namedPrincipals>
</ExternalCredential>
```

### CI/CD JWT against ECA

```bash
sf org login jwt \
  --client-id "$SF_CLIENT_ID" \
  --jwt-key-file "$SF_JWT_KEY_PATH" \
  --username "$SF_USERNAME" \
  --instance-url "$SF_INSTANCE_URL" \
  --alias ci-target
```

Store the private key in your CI secrets manager (GitHub Encrypted Secrets, GitLab CI variables, AWS Secrets Manager). Never commit the `.key` file. See [sf CLI](/stacks/salesforce/sf-cli/).

### Apex callouts using ECA-backed Named Credentials

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:My_Stripe_Credential/v1/charges');
req.setMethod('POST');
req.setBody(payload);
HttpResponse res = new Http().send(req);
```

Never hard-code credentials in Apex. The current pattern is **External Credential** (auth) + **Named Credential** (endpoint URL).

## Anti-patterns

- **Creating new Connected Apps in 2026.** Past May 11, 2026, the surface is blocked for AppExchange. For everything else, you're explicitly choosing technical debt.
- **Long-lived refresh tokens without rotation.** Refresh token rotation must be on; tokens expire on use.
- **Embedded credentials in custom metadata or custom settings.** Custom metadata is queryable by any developer with Author Apex permission.
- **Password-based integration users.** ECA + named principal + OAuth client credentials. Password integrations are 2014.
- **Single ECA across all environments.** Each environment (dev / UAT / staging / production) has its own External Credential principal pointing at its own vendor credentials. Named Credential name stays constant; the credential varies.

## Gotchas

- **Plain Connected Apps continue working after May 11** — but you can't create new ones. Existing ones are tech debt with no sunset date.
- **AppExchange ISVs** must produce ECA-based 2GP packages alongside legacy Connected App packages — migration release before subscribers lose ECA-less installability.
- **The Named Credential name stays constant across environments.** The credential behind it varies. This is how Apex code stays environment-agnostic.
- **ECA refresh token rotation** is on by default for new ECAs; verify per-protocol for OAuth flows.

## Cross-references

- Security depth and migration playbook: [security-engineer on Salesforce](/stacks/salesforce/security-engineer/)
- Apex callout patterns: [Apex](/stacks/salesforce/apex/), [backend-architect on Salesforce](/stacks/salesforce/backend-architect/)
- CI/CD JWT: [sf CLI](/stacks/salesforce/sf-cli/), [devops-engineer on Salesforce](/stacks/salesforce/devops-engineer/)
- AppExchange ISV implications: [saas-architect on Salesforce](/stacks/salesforce/saas-architect/), [AppExchange + Marketplace](/stacks/salesforce/appexchange-marketplace/)
- Authoritative: [ECA Migration Guide](https://help.salesforce.com/s/articleView?id=sf.connected_apps_eca_migration.htm)
