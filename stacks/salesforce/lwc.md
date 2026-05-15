---
title: Lightning Web Components
description: Salesforce's web-standard component model. Spring '26 adds TypeScript types, lightning/graphql with mutations, reactive screen flows, Lightning Out 2.0.
product:
  name: Lightning Web Components
  stack: salesforce
  drift_risk: medium
  last_verified_on: "2026-05-12"
  applies_to_roles: [frontend-architect, qa-engineer]
  authoritative_url: https://developer.salesforce.com/docs/component-library/documentation/en/lwc
  notes: "Spring '26: TypeScript types, lightning/graphql with mutations; Lightning Out 2.0 GA Winter '26; Aura deprecated for new work."
---

<div class="etyb-currency-banner">Last verified: 2026-05-12 against Salesforce Spring '26 (API v66.0).</div>

## What it is

Lightning Web Components (LWC) is Salesforce's component model, built on web standards (Web Components, ES Modules, shadow DOM). It is the default UI primitive on Salesforce — Aura is legacy maintenance-only, Visualforce is effectively frozen, and new work lands in LWC unless there's a specific platform reason otherwise (rare).

Canonical reference: [LWC Developer Guide](https://developer.salesforce.com/docs/component-library/documentation/en/lwc).

## When to use it

| Need | Use |
|------|-----|
| Records-bound UI inside Salesforce | LWC with wire-first data |
| Multi-step service workflow | Screen Flow + LWC steps; OmniScript on Industries |
| Customer-facing portal / community | LWR (Lightning Web Runtime) for Experience Cloud |
| Embed Salesforce data in an external (non-SF) site | Lightning Out 2.0 (no Aura wrappers) |
| Custom modal / toast / spinner / button | Use `lightning/modal`, `lightning/platformShowToastEvent`, `lightning/spinner`, `lightning/button` |

## 2025-2026 currency anchors

| Feature | Status | What it changes |
|---------|--------|-----------------|
| **TypeScript types for base components** (`@salesforce/lightning-types`) | GA Spring '26 | Use `.ts` for LWC controllers — typed wire adapters, props, events. Templates remain `.html`. |
| **`lightning/graphql` module** | GA Spring '26 | Supersedes `lightning/uiGraphQLApi`. Supports mutations as of Spring '26. The recommended data path for arbitrary CRM queries. |
| **Complex template expressions** | Beta Spring '26 | JavaScript subset in `{}` expressions. Reduces getter sprawl. |
| **Reactive Screen Flows** | GA | Field values update across screens without "Next" clicks. New collection operators in Winter '26. |
| **Lightning Web Runtime (LWR)** | GA | Sub-second Experience Cloud sites via static publish + cache |
| **Lightning Out 2.0** | GA Winter '26 | Embed LWCs in external sites without Aura wrappers. Decade-long beta finally done. |
| **Aura `ui:*` namespace** | Deprecated | Don't write new Aura |
| **Visualforce** | Frozen | PDF rendering until LWC parity, email templates only |

## Patterns

### Wire-first data (non-negotiable for record-bound components)

```js
import { LightningElement, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import INDUSTRY_FIELD from '@salesforce/schema/Account.Industry';

export default class AccountSummary extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: [NAME_FIELD, INDUSTRY_FIELD] })
    account;

    get accountName() {
        return getFieldValue(this.account.data, NAME_FIELD);
    }
}
```

Why wire by default:
- **LDS-backed wires honor FLS, CRUD, and sharing automatically.** No `WITH USER_MODE` worries on the client.
- **Cached across components.** Multiple components requesting the same record get one network round-trip.
- **Auto-refreshes** when the underlying record changes.
- **`refreshApex()`** invalidates explicitly.

Wire adapters worth knowing: `getRecord`, `getRecords`, `getRelatedListRecords`, `getRelatedListsInfo`, `getObjectInfo`, `getPicklistValues`, `getNavItems`, plus the new GraphQL wire.

### GraphQL (the 2026 default for complex queries)

```js
import { gql, graphql } from 'lightning/graphql';

const ACCOUNTS_QUERY = gql`
    query getHealthcareAccounts {
        uiapi {
            query {
                Account(where: { Industry: { eq: "Healthcare" } }, first: 25) {
                    edges {
                        node {
                            Id
                            Name { value }
                            AnnualRevenue { value }
                        }
                    }
                }
            }
        }
    }
`;

export default class HealthcareAccounts extends LightningElement {
    @wire(graphql, { query: ACCOUNTS_QUERY })
    accounts;
}
```

Use `lightning/graphql` for:
- Multi-object queries that would need multiple wire calls
- Pagination with cursors (connection model maps naturally)
- **Mutations (Spring '26+)** — write operations without imperative Apex
- Cross-org reads via Salesforce Connect external sources

Use plain `getRecord`/`getRecords` for single-record reads — LDS cache is more efficient and auto-refreshes.

`lightning/uiGraphQLApi` (older module) is deprecated — migrate to `lightning/graphql`.

### When imperative Apex is justified

```js
import getCases from '@salesforce/apex/CaseService.getCasesForAccount';

async handleClick() {
    try {
        this.cases = await getCases({ accountId: this.recordId });
    } catch (error) {
        this.error = error;
    }
}
```

Use imperative when:
- Calling Apex on demand (user click, lifecycle hook), not on render
- Server method does more than CRUD — joining, aggregation, side effects
- Custom REST endpoints

The Apex must be `@AuraEnabled` (use `cacheable=true` only for pure reads).

### Lightning Web Runtime (LWR) for Experience Cloud

Modern runtime for Experience Cloud sites. Sub-second loads via static publish + CDN cache. Every new Experience Cloud site should use LWR — Aura sites are legacy.

Differences from LEX LWC dev:
- **Build-time publish step.** Components bundled at site publish, not loaded dynamically.
- **Limited base components.** Check the [LWR-supported components reference](https://developer.salesforce.com/docs/atlas.en-us.exp_cloud_lwr.meta/exp_cloud_lwr/).
- **Different wire adapter set.** Public/unauthenticated calls need variants that work without a logged-in user.
- **Theme overrides via SLDS tokens.**

"Build a customer portal" or "branded community" → LWR site. "Internal app inside Salesforce" → standard LEX with LWC.

### Lightning Out 2.0 — LWCs in external sites

GA Winter '26. Embed an LWC into a non-Salesforce page without Aura wrappers.

```html
<script src="https://your-domain.my.site.com/lightning/lightning.out.js"></script>
<script>
    $Lightning.use("c:MyOutApp", function() {
        $Lightning.createComponent("c:myEmbeddableComponent",
            { recordId: "001..." },
            "embed-target",
            function(cmp) { /* ready */ }
        );
    });
</script>
<div id="embed-target"></div>
```

Auth modes: anonymous (Site/Experience Cloud guest), session-based (logged-in Salesforce user), OAuth (app-to-app). Use cases: embedding Service Cloud chat into a marketing site, Account record cards into an external partner portal, pricing widgets in an external storefront.

Not every base component is supported in Out 2.0 mode (still being expanded). Test standalone before assuming it'll work embedded.

### Component composition

**Use base components first.** `lightning/button`, `lightning/input`, `lightning/datatable`, `lightning/recordForm`, `lightning/recordEditForm`. They handle FLS, theming, accessibility, mobile, dark mode, RTL.

**Compose with slots.**

```html
<template>
    <lightning-card title="Account Details">
        <slot name="header"></slot>
        <div class="slds-p-around_medium">
            <slot></slot>
        </div>
        <slot name="footer" slot="footer"></slot>
    </lightning-card>
</template>
```

**Cross-component communication via Lightning Message Service (LMS)** — replaces Aura application events. Use sparingly; most components pass data via props and emit events to parents.

### Aura → LWC migration

1. **Don't migrate everything.** Aura still works. Migrate when: component is being modified anyway, has performance issues, or depends on deprecated APIs.
2. **LWC can nest inside Aura.** Migrate leaves first.
3. **Component events** → custom DOM events (`this.dispatchEvent(new CustomEvent(...))`).
4. **Application events** → Lightning Message Service.
5. **`aura:method`** → expose with `@api` on the LWC.
6. **`force:recordData`** → `getRecord` wire.

## Anti-patterns

- **Hardcoded `recordId` in `@api`.** Always set from the parent or record context.
- **Forgetting `@api` on public properties.**
- **Mutating wire response data directly.** Wire data is frozen — clone before mutating.
- **Using `@track` reflexively.** Default for object/array properties since 2020.
- **`@AuraEnabled(cacheable=true)` with non-cacheable behavior.** Stale data and lost `refreshApex` semantics.
- **Cross-LWC communication via global variables.** Use LMS or events.
- **Forgetting to test the empty state.** Wires return `{ data: undefined, error: undefined }` initially.
- **Building custom modal/toast/spinner primitives.** Use `lightning/modal`, `lightning/platformShowToastEvent`, `lightning/spinner`.
- **Ignoring SLDS theming tokens.** Hard-coded colors break in dark mode and SLDS updates.
- **`lightning/uiGraphQLApi`** — deprecated. Migrate to `lightning/graphql`.

## Gotchas

- **Too many wire adapters firing on initial render.** Consolidate into one GraphQL query if hitting 4+ wires for the same render.
- **Large datatables without virtualization.** `lightning-datatable` virtualizes by default; custom markup with `for:each` over 500+ rows tanks.
- **Synchronous getters that recompute on every render.** Cache derived state or memoize.
- **`console.log` in production** survives minification.
- **Aura wrappers around LWC degrade perf.** Migrate leafward.
- **Accessibility:** semantic HTML first (`<button>`, `<a>`); roles only when needed; focus management on dynamic content. Custom interactive markup must opt in.

## Cross-references

- Frontend architecture depth: [frontend-architect on Salesforce](/stacks/salesforce/frontend-architect/)
- Backing Apex: [Apex](/stacks/salesforce/apex/), [backend-architect on Salesforce](/stacks/salesforce/backend-architect/)
- Testing: [qa-engineer on Salesforce](/stacks/salesforce/qa-engineer/)
- Agent-rendered UI (Slack, mobile, external): [Agentforce](/stacks/salesforce/agentforce/)
- Authoritative: [LWC Developer Guide](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)
