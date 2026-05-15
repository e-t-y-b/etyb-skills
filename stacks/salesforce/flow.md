---
title: Flow
description: Salesforce's declarative automation engine. Flow Orchestration became free Feb 2026; Reactive Screen Flows ship live updates without "Next" clicks.
product:
  name: Flow
  stack: salesforce
  drift_risk: medium
  last_verified_on: "2026-05-12"
  applies_to_roles: [system-architect, backend-architect, frontend-architect]
  authoritative_url: https://help.salesforce.com/s/articleView?id=sf.flow.htm
  notes: "Flow Orchestration went free Feb 2026 (no longer a paid add-on); Reactive Screen Flows ship Spring '26 collection operators."
---

<div class="etyb-currency-banner">Last verified: 2026-05-12 against Salesforce Spring '26.</div>

## What it is

Flow is Salesforce's declarative automation engine — a visual no-code/low-code surface for building business processes, screens, record updates, and orchestrations. As of 2026 it is the default automation primitive on the platform; Workflow Rules and Process Builder are end-of-life and should not be used for net-new work.

Canonical reference: [Flow documentation](https://help.salesforce.com/s/articleView?id=sf.flow.htm).

## When to use it

| Need | Use Flow when | Use Apex when |
|------|---------------|---------------|
| Multi-step business process | Default for declarative orchestration with admin maintainability | Transactional control across many objects, complex error compensation |
| Single-record validation / derivation | Trivial field updates only | Default for trigger-time logic |
| Multi-user handoff with approvals | **Flow Orchestration** (free Feb 2026) | Never |
| Reactive UI with conditional steps | Reactive Screen Flow | Custom LWC + Apex when guidance is highly bespoke |
| Long-running workflow with waits | Paused Flow / Flow Orchestration | Scheduled / Queueable Apex |

**The most common architecture mistake:** using Apex when Flow suffices (over-engineering, admins lose control) **or** using Flow when Apex is required (governor limits and transaction-control walls at production scale). The second is the painful one — Flow doesn't give full transaction semantics, and refactoring a critical-path Flow to Apex under production pressure is brutal.

## 2025-2026 currency anchors

- **Flow Orchestration is free** (Feb 2026). Previously a paid add-on. Use it for multi-user handoff workflows — assigning steps to specific users/groups, parallel/serial coordination, approvals.
- **Reactive Screen Flows** (GA) — field values update across screens without "Next" clicks. New collection operators in Winter '26.
- **Flow Builder canvas refresh** — better debugger, in-flow assertions, scoped variable inspection.
- **Auto-Layout** is the default canvas mode for new flows.

## Patterns

- **Record-triggered flows** for trigger-time logic that doesn't need Apex. One per object, before-save vs after-save mode picked deliberately.
- **Screen Flows** for guided UI inside Salesforce — embedded in record pages, App Pages, Experience Cloud sites, and Flow steps in [LWC](/stacks/salesforce/lwc/).
- **Subflows** as the unit of reuse. Versioned, deployable, callable from any context.
- **Invocable Apex** for the seams where declarative meets imperative — Flow calls `@InvocableMethod`-annotated Apex.
- **Flow Orchestration** for multi-user, multi-step handoffs: assign step to a user/queue, wait, evaluate, assign next.
- **Custom Property Editors** in screen flow components — Flow calls into [LWC](/stacks/salesforce/lwc/) for richer UI than the standard inputs.

## Anti-patterns

- **Workflow Rules / Process Builder for net-new automation.** Both are end-of-life. Migrate existing.
- **Orchestration logic in triggers** rather than Flow Orchestration. Triggers are for record-time logic, not multi-user workflows.
- **Apex for "build a wizard."** Reactive Screen Flow + base components handles it.
- **Flow chains that bypass governor-limit math.** Flow operations count toward limits — a Flow calling Subflow calling Subflow with DML at each level can hit SOQL/DML governor walls.
- **"We'll just refactor this Flow to Apex if it gets slow."** That refactor is painful under production pressure. Pick the primitive at design time.

## Gotchas

- **Flow runs in system mode by default.** FLS/CRUD not enforced unless explicitly set. Be deliberate — Flow's sharing and FLS posture is part of the security review.
- **Bulk paths through Flow** still count against per-transaction governor limits. Test with 200-record batches.
- **Paused Flows accumulate** — orgs with many long-running paused flows hit limits on paused interview count.
- **Flow tests** (Flow Test feature) are limited compared to Apex — for critical paths, prefer Apex test coverage of invocable wrappers, not just Flow Tests.
- **Versioning is per-Flow, not per-component.** Activate the right version on deploy.

## Cross-references

- Architecture decision (Flow vs Apex vs Agent): [system-architect on Salesforce](/stacks/salesforce/system-architect/)
- Apex back-end for Invocable Methods: [Apex](/stacks/salesforce/apex/), [backend-architect on Salesforce](/stacks/salesforce/backend-architect/)
- Screen flow UI consumers: [LWC](/stacks/salesforce/lwc/), [frontend-architect on Salesforce](/stacks/salesforce/frontend-architect/)
- Authoritative: [Spring '26 Release Notes](https://help.salesforce.com/s/articleView?id=release-notes.salesforce_release_notes.htm)
