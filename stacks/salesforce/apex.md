---
title: Apex
description: Salesforce's server-side language. Modern Apex (Spring '26) adds Cursors, user-mode SOQL, transaction finalizers, null coalescing.
product:
  name: Apex
  stack: salesforce
  drift_risk: medium
  last_verified_on: "2026-05-12"
  applies_to_roles: [backend-architect, qa-engineer, security-engineer, database-architect]
  authoritative_url: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/
  notes: "Spring '26 added Cursors and user-mode SOQL; transaction finalizers GA'd 2025; modern idioms diverge from pre-2024."
---

<div class="etyb-currency-banner">Last verified: 2026-05-12 against Salesforce Spring '26 (API v66.0).</div>

## What it is

Apex is Salesforce's strongly-typed, on-platform language with Java-like syntax and SOQL/SOSL/DML primitives baked in. It runs in a multi-tenant runtime with hard governor limits per transaction. Modern Apex (Spring '26) has changed significantly from pre-2024 idioms — null coalescing, safe navigation, user-mode SOQL, Apex Cursors, transaction finalizers — and stale-knowledge LLMs will produce dated code.

Canonical reference: [Apex Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/).

## When to use it (vs Flow, Agent, MuleSoft, external compute)

| Need | Default | Escape to Apex when |
|------|---------|---------------------|
| Multi-step business process, multi-user handoff | [Flow](/stacks/salesforce/flow/) | Transactional control across many objects, complex error compensation, performance pressure, dynamic query shapes Flow can't express |
| Single-transaction logic on a record (trigger, validation, derivation) | Apex trigger (handler pattern) | Default; use Flow only for trivial field updates |
| Large async work (>50 rows, callouts, scheduled work) | Apex Queueable + finalizers | Batch Apex for >50K rows; **Apex Cursors** for streaming up to 50M-row scans |
| Heavy data transformation, cross-system orchestration | MuleSoft | Direct Apex callouts only for simple, low-volume integration |
| Long-running compute, ML training | External (Lambda/Cloud Run/Functions) | Never Apex for long-running compute |

Don't use Apex when Flow suffices — admins can't read or change Apex. Don't use Flow when Apex is required — governor limits and transaction control will bite at production scale.

## 2025-2026 currency anchors

- **Null coalescing and safe navigation** (GA Winter '24) — `account?.Name ?? 'Unknown'`. Collapses 4-line null guards into one expression.
- **User-mode SOQL and DML** (GA Spring '24) — `WITH USER_MODE` and `Database.insert(records, AccessLevel.USER_MODE)`. Replaces `WITH SECURITY_ENFORCED` and `Security.stripInaccessible()`. **Modern default.**
- **Apex Cursors** (GA Spring '26) — iterate through up to 50M-row SOQL result sets across transactions without exploding heap.
- **Transaction finalizers on Queueable** (GA Summer '23) — run *after* the Queueable completes, in their own transaction. The only sanctioned way to do post-Queueable cleanup or compensating actions.
- **Named Credentials + External Credentials** — the modern auth pattern; older `NamedCredential` with embedded auth is deprecated.

## Patterns

### Modern Apex idioms

```apex
// Null coalescing + safe navigation
String name = account?.Name ?? 'Unknown';

// User-mode SOQL — enforces CRUD/FLS/sharing at query level
List<Account> accounts = [
    SELECT Id, Name, Industry
    FROM Account
    WHERE Industry = 'Healthcare'
    WITH USER_MODE
];

// User-mode DML
Database.insert(newRecords, AccessLevel.USER_MODE);
```

### Apex Cursors (Spring '26)

```apex
Database.Cursor cursor = Database.getCursor(
    'SELECT Id, Email FROM Contact WHERE LastModifiedDate < :cutoff'
);
Integer position = 0;
while (position < cursor.getNumRecords()) {
    List<Contact> chunk = cursor.fetch(position, 200);
    // process chunk — DML, callouts, etc.
    position += chunk.size();
}
```

Use when:
- Data set is large but you want simpler control flow than `Database.Batchable`
- You don't need Batch Apex's multiple `execute()` chunk semantics
- You're streaming into a Queueable chain rather than running a full batch job

Still use Batch Apex when you want auto-chunked parallel execution with retry semantics.

### Transaction finalizers

```apex
public class OrderProcessor implements Queueable, Finalizer {
    public void execute(QueueableContext ctx) {
        // main work
    }
    public void execute(FinalizerContext ctx) {
        if (ctx.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
            // log to custom object, enqueue retry, notify admin
        }
    }
}
System.attachFinalizer(new OrderProcessor());
```

Use whenever a Queueable has side effects that need follow-up (notifications, retry enqueuing, plan updates).

### The trigger handler pattern (non-negotiable)

```apex
trigger AccountTrigger on Account (
    before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    new AccountTriggerHandler().run();
}
```

```apex
public class AccountTriggerHandler extends TriggerHandler {
    public override void beforeInsert() { /* ... */ }
    public override void afterUpdate() { /* ... */ }
}
```

Rules:
1. **One trigger per object.** Two triggers on the same object = undefined execution order.
2. **Logic lives in classes, not triggers.** Triggers are dispatchers.
3. **Recursion control built into the handler.** Updates from inside the handler re-fire the trigger; short-circuit re-entry.
4. **Context-method dispatch** (`beforeInsert`, `afterUpdate`). No `if (Trigger.isBefore && Trigger.isInsert)` forest.

### Bulkification

The mistake every Salesforce dev makes once and never again:

```apex
// WRONG — SOQL inside a loop, DML inside a loop
for (Account a : Trigger.new) {
    List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId = :a.Id];
    for (Contact c : contacts) {
        c.Status__c = 'Updated';
        update c;  // 100-row trigger = 100 DML statements = limit hit
    }
}

// RIGHT — bulk query, bulk DML
Set<Id> accountIds = new Set<Id>();
for (Account a : Trigger.new) accountIds.add(a.Id);
List<Contact> contactsToUpdate = new List<Contact>();
for (Contact c : [SELECT Id FROM Contact WHERE AccountId IN :accountIds]) {
    c.Status__c = 'Updated';
    contactsToUpdate.add(c);
}
update contactsToUpdate;
```

Every Apex method that touches records must handle 1 row and 200 rows the same way. Triggers fire in batches of up to 200; bulk APIs and Flow batches deliver more. **Loop-and-query is the #1 cause of "works in dev, fails in prod."** Code Analyzer and ApexGuru will flag these.

### Async patterns

| Pattern | Best for | Constraints |
|---------|----------|-------------|
| `@future` | Fire-and-forget callout from sync context | No return value, no chaining, primitive params only. Legacy — prefer Queueable. |
| **Queueable** (modern default) | Async work — chainable, supports finalizers | Max chain depth 50 in test, unlimited in prod |
| Batch Apex | >50K rows, parallel chunked execution with retry | `start` → `execute` → `finish`; scope up to 2000 |
| **Apex Cursors** | Streaming reads across transactions | Spring '26+; up to 50M rows |
| Scheduled Apex | Recurring jobs | 100 scheduled jobs per org |
| Platform Events | Decoupled async dispatch | Replay window 72h |

### Apex REST + custom endpoints

```apex
@RestResource(urlMapping='/orders/*')
global with sharing class OrderResource {
    @HttpGet
    global static Order__c getOrder() {
        String orderId = RestContext.request.requestURI.substringAfterLast('/');
        return [SELECT Id, Name FROM Order__c WHERE Id = :orderId WITH USER_MODE];
    }
}
```

Apex REST is the modern default — versioned at the org's API version, OAuth-secured via [Connected App / ECA](/stacks/salesforce/external-client-apps/), traceable in Event Monitoring.

### MCP authoring — Apex-as-Agent-Action

```apex
public class CaseHelper {
    @InvocableMethod(
        label='Get Case Details'
        description='Returns case summary including priority, account, and recent activity'
        category='Customer Service'
    )
    public static List<Output> getCaseDetails(List<Input> inputs) {
        // ... bulk-safe implementation
    }
    public class Input { @InvocableVariable(required=true) public Id caseId; }
    public class Output { @InvocableVariable public String summary; @InvocableVariable public String priority; }
}
```

Critical rules:
1. **Bulk in, bulk out.** Inputs and outputs are lists.
2. **`description=` is read by Atlas** to decide whether to call your Action. Write descriptions like API doc strings.
3. **No PII in the action's prompt-visible output** without Trust Layer masking.
4. **Honor user-mode at the query level.** `WITH USER_MODE` is non-negotiable.
5. **Return deterministic, schema-stable output.**

See [Salesforce-Hosted MCP](/stacks/salesforce/salesforce-hosted-mcp/) for MCP-tool exposure.

## Governor limits cheat sheet

Synchronous transaction:
- 100 SOQL queries
- 50,000 records returned by SOQL
- 150 DML statements
- 10,000 records DMLed
- 6 MB heap
- 10s CPU time
- 100 callouts

Async (Queueable / Batch / Schedulable / `@future`):
- Same SOQL/DML count, 200 callouts, 12 MB heap, 60s CPU

If your design can't fit, design for async. If async still can't fit, escape to MuleSoft or external compute.

## Anti-patterns

- **SOQL injection.** Never concatenate user input into dynamic SOQL. Use bind variables (`:varName`) or `String.escapeSingleQuotes()`. Graph Engine catches most — run it.
- **DML in triggers without `try`/`catch`.** A bad record in a 200-row batch fails the whole DML. Partial-success patterns (`Database.insert(records, false)`) collect errors and continue.
- **Recursive triggers** without guards in the handler.
- **Mixed DML on setup vs non-setup objects** in the same transaction. Use `@future` or Queueable to separate.
- **Hard-coded IDs / org-specific values.** Use custom metadata or settings.
- **Async Apex from triggers without bulkification awareness.** 200-row trigger enqueuing a Queueable per record blows the async limit.
- **`Schema.SObjectType.X.fields.Y.isAccessible()` everywhere.** Verbose. Use `WITH USER_MODE`.
- **Callouts without explicit timeouts.** Default leaves callouts hanging up to platform max (120s).
- **Connected App for new auth integrations.** As of May 11, 2026, new Connected Apps cannot be created. Use [External Client Apps](/stacks/salesforce/external-client-apps/).

## Gotchas

- **Platform events count as DML.** `EventBus.publish` counts toward the DML limit.
- **`@AuraEnabled(cacheable=true)` only for pure reads** with no side effects. Otherwise stale data and lost `refreshApex` semantics.
- **Two publish modes on Platform Events** — Publish Immediate (fires regardless of transaction) and Publish After Commit. Set at design time on the event definition.
- **CDC events** auto-generated for sObjects — great for "react to record changes" without trigger sprawl.

## Cross-references

- Modern backend depth: [backend-architect on Salesforce](/stacks/salesforce/backend-architect/)
- Testing: [qa-engineer on Salesforce](/stacks/salesforce/qa-engineer/)
- Security: [security-engineer on Salesforce](/stacks/salesforce/security-engineer/), [Einstein Trust Layer](/stacks/salesforce/einstein-trust-layer/)
- Auth + endpoints: [External Client Apps](/stacks/salesforce/external-client-apps/)
- Agent actions: [Agentforce](/stacks/salesforce/agentforce/), [Salesforce-Hosted MCP](/stacks/salesforce/salesforce-hosted-mcp/)
- Query architecture: [Data 360](/stacks/salesforce/data-360/), [database-architect on Salesforce](/stacks/salesforce/database-architect/)
- Authoritative: [Apex Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/)
