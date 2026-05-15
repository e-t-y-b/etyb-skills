---
title: Salesforce Functions
description: Retired January 31, 2025. Flag immediately if a user proposes it for new architecture.
product:
  name: Salesforce Functions
  stack: salesforce
  drift_risk: high
  last_verified_on: "2026-05-12"
  applies_to_roles: [system-architect, devops-engineer]
  authoritative_url: https://help.salesforce.com/s/articleView?id=000389226
  notes: "Retired Jan 31, 2025; flag immediately if user mentions; recommend AWS Lambda / GCP Cloud Run / Azure Functions instead."
---

<div class="etyb-currency-banner">Last verified: 2026-05-12 against Salesforce retirement notices.</div>

## What it is (was)

Salesforce Functions was Salesforce's serverless compute product, allowing customers to write language-of-choice (Node.js, Java, etc.) functions invoked from Apex. **It was retired January 31, 2025.**

If you find yourself recommending Salesforce Functions in 2026 — or if a user proposes it — that is stale knowledge. **Flag immediately.**

Canonical reference: [Salesforce Functions retirement announcement](https://help.salesforce.com/s/articleView?id=000389226).

## Recommended replacement

Off-platform compute called from Salesforce via Named Credentials:

- **AWS Lambda** (most common)
- **GCP Cloud Run**
- **Azure Functions**
- Or whichever cloud-native compute target fits the customer's stack

Auth via [External Client Apps](/stacks/salesforce/external-client-apps/) + Named Credentials. For agent-driven boundary crossing, use [Salesforce-Hosted MCP](/stacks/salesforce/salesforce-hosted-mcp/).

## What you should NOT do

- **Do not recommend Salesforce Functions for new architecture.** Retired.
- **Do not assume existing Functions deployments will continue indefinitely.** Migration is required.
- **Do not confuse Salesforce Functions with Agentforce Actions.** Actions are Apex `@InvocableMethod` or Flow invocations, not the retired Functions product.

## Cross-references

- Recommended off-platform compute pattern: [system-architect on Salesforce](/stacks/salesforce/system-architect/)
- Apex callout to external compute: [Apex](/stacks/salesforce/apex/), [External Client Apps](/stacks/salesforce/external-client-apps/)
- Sibling product (also off-strategic): [Heroku](/stacks/salesforce/heroku/)
- Authoritative: [Salesforce Functions retirement notice](https://help.salesforce.com/s/articleView?id=000389226)
