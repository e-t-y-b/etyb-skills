# Requirements Engineering — Deep Reference

**Always use `WebSearch` to verify current tool capabilities, framework versions, methodology updates, and standards before giving recommendations. Requirements engineering practices evolve with the industry — agile, DDD, and AI-assisted approaches are rapidly reshaping how requirements are captured and managed.**

## Table of Contents
1. [Modern Requirements Engineering](#1-modern-requirements-engineering)
2. [BRD to TRD Translation](#2-brd-to-trd-translation)
3. [User Story Mapping & Story Slicing](#3-user-story-mapping--story-slicing)
4. [Requirements Elicitation Techniques](#4-requirements-elicitation-techniques)
5. [Edge Case Identification](#5-edge-case-identification)
6. [Non-Functional Requirements (NFRs)](#6-non-functional-requirements-nfrs)
7. [Acceptance Criteria Patterns](#7-acceptance-criteria-patterns)
8. [Domain-Driven Design for Requirements](#8-domain-driven-design-for-requirements)
9. [API Contract Requirements](#9-api-contract-requirements)
10. [Requirements Prioritization](#10-requirements-prioritization)
11. [Requirements Validation & Verification](#11-requirements-validation--verification)
12. [Requirements Management Tools & Practices](#12-requirements-management-tools--practices)

---

## 1. Modern Requirements Engineering

### The Requirements Spectrum (2025-2026)

Requirements engineering isn't one-size-fits-all. The approach should match the context:

| Context | Requirements Style | Formality | Documentation |
|---------|-------------------|-----------|---------------|
| **Startup/MVP** | Lean — problem statements, rough user stories | Very Low | Sticky notes, Notion docs, conversation notes |
| **Agile Team (small)** | User stories with acceptance criteria | Low-Medium | Jira/Linear tickets, story map on Miro/FigJam |
| **Agile Team (large/multi-team)** | Epics → Features → User Stories, shared domain model | Medium | Confluence/Notion, shared backlog, architecture docs |
| **Regulated Industry** | Formal BRDs, TRDs, traceability matrices | High | Dedicated requirements management tools |
| **Contract/Agency Work** | Detailed specifications, scope documents | High | SOWs, PRDs, signed-off specifications |
| **Open Source** | RFCs, GitHub issues, ADRs | Medium | GitHub discussions, RFC documents |

### Requirements as Living Documents

Modern requirements are never "done" — they evolve:

```
Discovery → Rough requirements (problem + hypothesis)
     ↓
Sprint Planning → Refined requirements (user stories + acceptance criteria)
     ↓
Implementation → Clarified requirements (edge cases found during development)
     ↓
Testing → Validated requirements (does the software match the intent?)
     ↓
Production → Evolved requirements (user feedback → new requirements)
```

**Key Principle**: The goal of requirements is shared understanding between stakeholders and the development team, not comprehensive documentation. Documentation is a means to that end, not the end itself.

### The "3 Cs" of User Stories

| C | Meaning | In Practice |
|---|---------|-------------|
| **Card** | A brief description of the requirement | "As a [user], I want [goal] so that [benefit]" on a card/ticket |
| **Conversation** | Discussion between stakeholders and developers | Questions, clarifications, edge cases discovered through dialogue |
| **Confirmation** | Acceptance criteria that verify the story is done | Testable conditions that demonstrate the requirement is met |

The story is NOT the card. The card is a placeholder for a conversation.

---

## 2. BRD to TRD Translation

### Business Requirements Document (BRD) Structure

```markdown
# Business Requirements Document: [Project Name]

## 1. Executive Summary
[1-2 paragraphs: What problem does this solve? What's the business value?]

## 2. Business Context
### Problem Statement
[What pain point are we addressing? Who experiences it? What's the impact?]

### Business Objectives
[Measurable goals: increase revenue by X%, reduce support tickets by Y%]

### Success Metrics
| Metric | Current State | Target | Measurement Method |
|--------|-------------|--------|-------------------|
| [metric] | [baseline] | [target] | [how to measure] |

## 3. Scope
### In Scope
- [Feature/capability 1]
- [Feature/capability 2]

### Out of Scope
- [Explicitly excluded items]

### Assumptions
- [Business assumptions that must hold true]

## 4. Stakeholders
| Stakeholder | Role | Interest | Influence |
|-------------|------|----------|-----------|
| [Name] | [Title] | [What they care about] | High/Medium/Low |

## 5. Business Requirements
### BR-001: [Requirement Name]
- **Description**: [What the business needs]
- **Priority**: [Must Have / Should Have / Nice to Have]
- **Business Rule**: [Specific rule or constraint]
- **Acceptance**: [How we know this is met]

## 6. Business Process Flows
[Diagrams or descriptions of current vs. future processes]

## 7. Constraints
[Budget, timeline, regulatory, organizational constraints]

## 8. Dependencies
[External systems, other projects, third-party services]

## 9. Risks
[Business risks, market risks, adoption risks]
```

### Technical Requirements Document (TRD) Structure

```markdown
# Technical Requirements Document: [Project Name]

## 1. Overview
[Technical summary of what's being built and how it maps to the BRD]

### BRD Reference
[Link to the BRD this TRD implements]

### Architecture Context
[Where this fits in the overall system architecture — C4 Context/Container diagram or reference]

## 2. Technical Requirements

### Functional Requirements

#### TR-001: [Requirement Name] (implements BR-001)
- **Description**: [Technical description of what the system must do]
- **API**: [Endpoint, method, request/response format]
- **Data Model**: [New or modified entities, fields, relationships]
- **Business Logic**: [Specific algorithms, calculations, validations]
- **Error Handling**: [Expected error conditions and responses]
- **Edge Cases**: [Known edge cases and how to handle them]

### Non-Functional Requirements

#### NFR-001: Performance
- **Response Time**: [p50, p95, p99 targets]
- **Throughput**: [Requests/sec, concurrent users]
- **Data Volume**: [Expected data size, growth rate]

#### NFR-002: Security
- **Authentication**: [Auth mechanism]
- **Authorization**: [Access control model]
- **Data Protection**: [Encryption, PII handling]

#### NFR-003: Scalability
- **Scaling Strategy**: [Horizontal/vertical, auto-scaling triggers]
- **Bottleneck Analysis**: [Known bottlenecks and mitigation]

## 3. System Design
### Component Diagram
[Which services/components are involved]

### Data Flow
[How data moves through the system for key operations]

### Database Changes
[Schema changes, migrations needed]

### API Contracts
[New or modified API endpoints with OpenAPI spec or equivalent]

## 4. Dependencies
| Dependency | Type | Status | Risk |
|-----------|------|--------|------|
| [Service/API] | External/Internal | Available/Pending | High/Low |

## 5. Testing Strategy
[What types of testing are needed — unit, integration, E2E, performance]

## 6. Deployment Plan
[How this will be deployed — feature flags, migration steps, rollback plan]

## 7. Monitoring & Observability
[Key metrics, alerts, dashboards needed]

## 8. Traceability Matrix
| Business Req | Technical Req | Test Case | Status |
|-------------|--------------|-----------|--------|
| BR-001 | TR-001, TR-002 | TC-001, TC-002 | Pending |
| BR-002 | TR-003 | TC-003 | Pending |
```

### BRD → TRD Translation Patterns

| BRD Says | TRD Specifies |
|----------|--------------|
| "Users should be able to search products" | Search API endpoint, search algorithm (full-text, fuzzy, faceted), indexing strategy, response format, performance SLAs |
| "The system must be fast" | p95 < 200ms for API responses, < 3s page load, specific throughput targets |
| "Data must be secure" | Encryption at rest (AES-256), in transit (TLS 1.3), PII masking, access control model, audit logging |
| "The system must handle growth" | Horizontal scaling strategy, database sharding plan, CDN configuration, auto-scaling triggers |
| "Users should receive notifications" | Notification channels (email, push, in-app), delivery mechanisms, retry policies, user preferences model, template system |

### Common Translation Mistakes

| Mistake | Example | Better Approach |
|---------|---------|-----------------|
| Copying BRD language verbatim | "System must be user-friendly" | Define specific UX requirements (load time, accessibility, workflow steps) |
| Over-specifying implementation | "Use Redis for caching" in TRD | "Response cache with < 10ms hit time" — let architects choose the tool |
| Missing the "why" | "Add field X to the database" | "Add field X to support requirement BR-003 (user preferences)" |
| Ignoring edge cases | "Users can upload files" | What file types? Max size? Virus scanning? Concurrent uploads? Failed uploads? |
| Skipping NFRs | Only documenting functional requirements | Every functional requirement has implicit NFRs — make them explicit |

---

## 3. User Story Mapping & Story Slicing

### Jeff Patton's User Story Mapping

Story mapping arranges user stories in a 2D layout:
- **Horizontal axis**: User journey (left to right = sequence of activities)
- **Vertical axis**: Priority/detail (top = essential, bottom = nice-to-have)

```
User Activities (journey left → right):
──────────────────────────────────────────────────────────
│ Sign Up    │ Browse     │ Add to Cart │ Checkout  │ Track Order │
├────────────┼────────────┼─────────────┼───────────┼─────────────┤
│ Email      │ Search     │ Add item    │ Enter     │ View status │ ← MVP
│ signup     │ products   │             │ payment   │             │   (Release 1)
├────────────┼────────────┼─────────────┼───────────┼─────────────┤
│ Social     │ Filter by  │ Save for    │ Apply     │ Email       │ ← Release 2
│ login      │ category   │ later       │ coupon    │ updates     │
├────────────┼────────────┼─────────────┼───────────┼─────────────┤
│ SSO /      │ AI recom-  │ Wishlist    │ Multiple  │ Real-time   │ ← Release 3
│ enterprise │ mendations │ sharing     │ payment   │ tracking    │
│            │            │             │ methods   │ map         │
──────────────────────────────────────────────────────────
```

**The Walking Skeleton**: The first horizontal slice (MVP) should be the thinnest possible end-to-end journey that provides value. It's not feature-complete in any area, but it works from start to finish.

### Story Slicing Techniques

When a story is too large (> 8 story points), slice it using these patterns:

| Slicing Pattern | Description | Example |
|----------------|-------------|---------|
| **By Workflow Step** | Split along the steps of a user journey | "Checkout" → "Enter shipping" + "Enter payment" + "Confirm order" |
| **By Business Rule** | Each business rule variant is a story | "Apply discount" → "Percentage discount" + "Fixed amount" + "BOGO" |
| **By Data Variation** | Different input types become different stories | "Upload file" → "Upload image" + "Upload CSV" + "Upload PDF" |
| **By Interface** | Different interaction points are different stories | "Notifications" → "Email notification" + "Push notification" + "In-app" |
| **By Operation** | CRUD operations as separate stories | "Manage profile" → "View profile" + "Edit profile" + "Delete account" |
| **By Happy Path / Edge Case** | Implement happy path first, edge cases later | "Payment" → "Successful payment" + "Declined card" + "Timeout" |
| **By Performance** | Basic functionality first, optimization later | "Search" → "Basic search" + "Search with facets" + "Search < 100ms" |
| **By Platform** | Different platforms as different stories | "Mobile app" → "iOS app" + "Android app" + "Responsive web" |

### SPIDR Method (Mike Cohn)

A complementary approach — "almost every story can be split with one of these five":

| Letter | Technique | Example |
|--------|-----------|---------|
| **S** | Spike | Research activity to reduce uncertainty before splitting |
| **P** | Paths | Split by different user workflow paths/scenarios |
| **I** | Interfaces | Split by different interfaces (web, mobile, API, CLI) |
| **D** | Data | Deliver value with a subset of data first, expand later |
| **R** | Rules | Split by business rules, implementing simplest rules first |

### INVEST Criteria

Every user story should be:

| Letter | Criterion | What It Means | Red Flag |
|--------|----------|---------------|----------|
| **I** | Independent | Can be developed and deployed separately | "This story can't start until story X is done" |
| **N** | Negotiable | Details can be discussed and refined | "The BRD says exactly this, we can't change it" |
| **V** | Valuable | Delivers value to a user or stakeholder | "This is a technical refactoring task" (reframe as user value) |
| **E** | Estimable | Team can estimate the effort | "We have no idea how long this will take" (need a spike) |
| **S** | Small | Can be completed in one sprint | "This is a 3-month epic" (needs slicing) |
| **T** | Testable | Has clear criteria for "done" | "Make it good" (needs concrete acceptance criteria) |

---

## 4. Requirements Elicitation Techniques

### Technique Selection Guide

| Technique | Best For | Participants | Time Investment | Output |
|-----------|----------|-------------|-----------------|--------|
| **Stakeholder Interviews** | Understanding business context, goals, constraints | 1-on-1 with stakeholders | 1 hour per person | Interview notes, requirements list |
| **User Interviews** | Understanding user needs, pain points, workflows | 1-on-1 with users | 45-60 min per person | User needs, personas |
| **Requirements Workshop** | Building shared understanding across stakeholders | Group (5-12 people) | Half-day to full day | Requirements list, story map |
| **Event Storming** | Discovering domain events and business processes | Developers + domain experts | 2-4 hours | Event timeline, bounded contexts |
| **Example Mapping** | Refining a specific story's acceptance criteria | Dev team + product (3-6 people) | 25-30 minutes per story | Examples, rules, questions |
| **Domain Storytelling** | Understanding business workflows visually | Domain experts + development team | 1-2 hours per scenario | Pictographic workflow diagrams |
| **Observation / Shadowing** | Understanding actual (vs. reported) workflows | Analyst + user | 2-4 hours per session | Workflow documentation, pain points |
| **Prototyping** | Validating UX requirements, getting concrete feedback | Design + users | Days-weeks | Interactive prototype, user feedback |
| **Three Amigos** | Refining a story's requirements from three perspectives | Dev + QA + Product (3 people) | 30-60 minutes per story | Shared understanding, edge cases, test scenarios |
| **Domain Storytelling** | Understanding workflows through domain narratives | Domain experts + facilitators | 1-2 hours per scenario | Pictographic workflow diagrams, requirements |
| **Survey / Questionnaire** | Gathering data from many users | Many users | Days (to collect) | Quantitative data, common patterns |

### Event Storming Deep Dive

Event Storming (created by Alberto Brandolini) is particularly powerful for complex domains:

**Notation:**

| Color | Represents | Example |
|-------|-----------|---------|
| **Orange** (sticky) | Domain Event (past tense) | "Order Placed", "Payment Received", "Item Shipped" |
| **Blue** (sticky) | Command (imperative) | "Place Order", "Process Payment", "Ship Item" |
| **Yellow** (small) | Actor / User | "Customer", "Admin", "System" |
| **Pink/Red** (sticky) | External System | "Payment Gateway", "Shipping API", "Email Service" |
| **Purple** (sticky) | Policy / Business Rule | "If order > $100, free shipping", "Auto-approve returns < $50" |
| **Green** (sticky) | Read Model / View | "Order Summary", "Invoice", "Tracking Page" |
| **Red** (small) | Hot Spot / Problem | Confusion, disagreement, missing knowledge |

**Process:**
1. **Big Picture** (2-3 hours): Everyone writes domain events on orange stickies, places them on a timeline (left to right). Don't debate — just capture.
2. **Enforce the Timeline**: Arrange events chronologically. Add commands (blue) and actors (yellow) that trigger each event.
3. **Identify Boundaries**: Draw vertical lines between clusters of related events — these become bounded contexts.
4. **Add Policies**: Place purple stickies for business rules that connect events ("When X happens, then Y should happen").
5. **Mark Hot Spots**: Red stickies for confusion, disagreement, or missing knowledge — these need investigation.

### Example Mapping (Matt Wynne)

For refining individual stories before sprint:

```
Story: "As a customer, I can return a product for a refund"

RULES (blue cards):                  EXAMPLES (green cards):
┌─────────────────────────┐          ┌──────────────────────────────────┐
│ Returns accepted within  │ ←───── │ Customer returns shirt after 20  │
│ 30 days of purchase      │         │ days → accepted, full refund     │
│                          │ ←───── │ Customer returns shirt after 35  │
│                          │         │ days → rejected, offer store     │
│                          │         │ credit                           │
└─────────────────────────┘          └──────────────────────────────────┘
┌─────────────────────────┐          ┌──────────────────────────────────┐
│ Item must be in original │ ←───── │ Worn jacket with stains →        │
│ condition                │         │ rejected                         │
│                          │ ←───── │ Unworn jacket, tags attached →   │
│                          │         │ accepted                         │
└─────────────────────────┘          └──────────────────────────────────┘
┌─────────────────────────┐
│ Refund goes to original  │ ←───── [examples for different payment methods]
│ payment method           │
└─────────────────────────┘

QUESTIONS (red cards):
┌──────────────────────────────────────────┐
│ What if the item was a gift?              │
│ What if the original payment method       │
│ expired?                                  │
│ International returns — who pays shipping?│
└──────────────────────────────────────────┘
```

---

## 5. Edge Case Identification

### Edge Case Identification Checklist

Use this checklist when reviewing any requirement:

**Data Edge Cases:**

| Category | Questions to Ask |
|----------|-----------------|
| **Empty/Null** | What happens with no input? Null values? Empty strings? Empty arrays? |
| **Boundaries** | What's the minimum? Maximum? Off-by-one? Exactly at the limit? |
| **Special Characters** | Unicode? Emojis? HTML entities? SQL injection characters? RTL text? |
| **Large Data** | What if there are 1M records? 10GB file? 100K character string? |
| **Concurrent Access** | Two users editing the same record? Race conditions? |
| **Duplicate Data** | Duplicate submissions? Duplicate emails? Idempotency? |
| **Format Variations** | Different date formats? Phone number formats? Currency formats? |
| **Missing Data** | Required fields missing? Partial data? Incomplete records? |

**User Behavior Edge Cases:**

| Category | Questions to Ask |
|----------|-----------------|
| **Back Button** | What happens if the user hits back during a multi-step flow? |
| **Refresh** | What happens on page refresh mid-operation? |
| **Multiple Tabs** | Same user, same session, two tabs — what breaks? |
| **Timeout** | Session expires mid-operation? API timeout mid-transaction? |
| **Rapid Actions** | Double-click submit? Rapidly toggling a setting? Spam clicking? |
| **Cancel/Abort** | User cancels mid-upload? Closes browser mid-checkout? |
| **Offline** | Internet connection drops mid-operation? Airplane mode? |
| **Wrong Order** | Steps done out of expected sequence? Deeplinked into the middle? |

**System Edge Cases:**

| Category | Questions to Ask |
|----------|-----------------|
| **Time** | Midnight? DST transition? Leap year? Different timezones? End of month? |
| **Network** | Slow connection? Packet loss? DNS failure? Third-party API down? |
| **Storage** | Disk full? Database connection limit reached? Cache eviction? |
| **Versioning** | Old client + new API? Migration in progress? Partial rollout? |
| **Permission Changes** | User's role changes mid-session? Access revoked during operation? |
| **Account State** | Deleted user? Suspended account? Trial expired mid-use? |

### The ZOMBIE Mnemonic

For identifying edge cases in any feature:

| Letter | Category | Example |
|--------|----------|---------|
| **Z** | Zero | No items in cart, zero balance, empty search results |
| **O** | One | Single item, first user, one character password |
| **M** | Many | Thousands of items, millions of users, deep nesting |
| **B** | Boundary | Max integer, string length limit, date range boundary |
| **I** | Interface | API contract violations, unexpected input types, missing fields |
| **E** | Exceptional | Network failure, timeout, out of memory, disk full |

---

## 6. Non-Functional Requirements (NFRs)

### ISO/IEC 25010:2023 Quality Model (Updated)

The ISO/IEC 25010 standard was significantly revised in 2023, expanding from 8 to **9 quality characteristics** with new sub-characteristics. This is the current standard:

| Quality Characteristic | Sub-Characteristics | Example NFR |
|----------------------|--------------------| ------------|
| **Functional Suitability** | Completeness, Correctness, Appropriateness | "All calculations must match the approved financial model within 0.01% tolerance" |
| **Performance Efficiency** | Time behavior, Resource utilization, Capacity | "API responses < 200ms p95, support 10K concurrent users" |
| **Compatibility** | Co-existence, Interoperability | "Must work alongside existing system X without interference" |
| **Interaction Capability** (was Usability) | Learnability, Operability, Accessibility, User engagement, Inclusivity (new), Self-descriptiveness (new), User error protection | "WCAG 2.2 AA compliant, new user completes core workflow in < 5 min" |
| **Reliability** | Availability, Fault tolerance, Recoverability, Faultlessness (replaced Maturity) | "99.9% uptime (8.7 hours/year downtime), RTO < 1 hour, RPO < 5 min" |
| **Security** | Confidentiality, Integrity, Non-repudiation, Accountability, Authenticity, Resistance (new) | "Data encrypted at rest (AES-256), all actions audit-logged, SOC2 Type II" |
| **Maintainability** | Modularity, Reusability, Analyzability, Modifiability, Testability | "New feature from concept to production in < 2 weeks, > 80% test coverage" |
| **Flexibility** (was Portability) | Adaptability, Installability, Replaceability, Scalability (new) | "Must run on AWS and GCP, database-agnostic DAL, auto-scale to 10x" |
| **Safety** (new) | Operational constraint satisfaction, Risk identification, Fail safe, Hazard warning, Safe integration | "System must fail-safe on sensor failure, hazard warnings within 100ms" |

**Key 2023 Changes**: "Usability" renamed to "Interaction Capability" with new sub-characteristics for inclusivity and self-descriptiveness. "Portability" renamed to "Flexibility" and gained "Scalability" as a sub-characteristic. "Safety" added as an entirely new characteristic. "Resistance" added under Security for resilience against attacks.

### FURPS+ Framework

Alternative to ISO 25010, sometimes simpler for teams:

| Category | What It Covers | Example Requirement |
|----------|---------------|-------------------|
| **F** — Functionality | Features, capabilities, security | "Support OAuth 2.0 + SAML SSO" |
| **U** — Usability | UX, documentation, help, accessibility | "Screen reader accessible, < 3 clicks to complete core task" |
| **R** — Reliability | Uptime, accuracy, recoverability, predictability | "99.95% availability, automated failover < 30s" |
| **P** — Performance | Speed, throughput, resource usage, scalability | "< 100ms API response, handle 50K RPM" |
| **S** — Supportability | Testability, maintainability, configurability, installability | "Feature flags for all new features, structured logging" |
| **+** — Constraints | Design, implementation, interface, physical constraints | "Must use approved tech stack, HIPAA compliant hosting" |

### Writing Measurable NFRs

Bad NFR: "The system must be fast."
Good NFR: "API response time must be < 200ms at p95 under normal load (< 5K concurrent users)."

| NFR Type | Measurement Template |
|----------|---------------------|
| Performance | "[Operation] must complete in < [time] at p[percentile] under [load condition]" |
| Availability | "[System/service] must have [X]% uptime measured [monthly/annually], excluding planned maintenance windows of [duration]" |
| Scalability | "[System] must support [N] concurrent [users/requests/connections] with < [X]% performance degradation" |
| Recovery | "RTO (Recovery Time Objective) < [time], RPO (Recovery Point Objective) < [time]" |
| Security | "[Data type] must be encrypted [at rest/in transit] using [standard]. Access logs retained for [duration]" |
| Accessibility | "Must conform to [WCAG 2.2 Level AA / Section 508] verified by [automated tool + manual audit]" |
| Maintainability | "New [feature type] from concept to production in < [time period] with current team" |

---

## 7. Acceptance Criteria Patterns

### Given-When-Then (Gherkin)

The most common acceptance criteria format, based on BDD (Behavior-Driven Development):

```gherkin
Feature: Shopping Cart

  Scenario: Add item to empty cart
    Given I have an empty shopping cart
    When I add a product with price $29.99
    Then the cart should contain 1 item
    And the cart total should be $29.99

  Scenario: Apply percentage discount code
    Given I have items in my cart totaling $100.00
    When I apply discount code "SAVE20" (20% off)
    Then the cart total should be $80.00
    And the discount should be shown as "-$20.00"

  Scenario: Attempt to apply expired discount code
    Given I have items in my cart
    When I apply discount code "EXPIRED2024"
    Then I should see an error "This discount code has expired"
    And the cart total should remain unchanged
```

**When to Use**: When the behavior has clear preconditions, actions, and expected outcomes. Especially good for QA and automated testing.

### Rule-Based Criteria

List the business rules that must be enforced:

```markdown
## Acceptance Criteria: Password Requirements

Rules:
- [ ] Minimum 8 characters
- [ ] Maximum 128 characters
- [ ] Must contain at least one uppercase letter
- [ ] Must contain at least one lowercase letter
- [ ] Must contain at least one number
- [ ] Must contain at least one special character (!@#$%^&*)
- [ ] Must not be in the list of common passwords (top 10,000)
- [ ] Must not be the same as the last 5 passwords
- [ ] Password strength indicator shows real-time feedback
- [ ] Clear error message for each rule violation
```

**When to Use**: When the acceptance criteria are a set of rules or validations rather than a workflow.

### Example-Based Criteria

Provide concrete input/output examples:

```markdown
## Acceptance Criteria: Price Formatting

| Input | Expected Output | Notes |
|-------|----------------|-------|
| 9.99 | $9.99 | Standard price |
| 9.9 | $9.90 | Pad to 2 decimal places |
| 1000 | $1,000.00 | Thousands separator |
| 0 | $0.00 | Zero price (free item) |
| 1234567.89 | $1,234,567.89 | Large number |
| -10 | Error: negative price | Negative not allowed |
| null | Error: price required | Missing price |
```

**When to Use**: When the behavior is best demonstrated through examples, especially for formatting, calculations, and transformations.

### Checklist Criteria

Simple pass/fail checklist for less complex stories:

```markdown
## Acceptance Criteria: User Profile Page

- [ ] Displays user's name, email, and avatar
- [ ] Edit button opens inline editing mode
- [ ] Changes are saved when "Save" is clicked
- [ ] Cancel reverts to original values
- [ ] Shows success toast on save
- [ ] Shows error message if save fails
- [ ] Accessible via keyboard navigation
- [ ] Responsive on mobile (< 768px)
```

**When to Use**: For UI-focused stories where the criteria are observable checks.

---

## 8. Domain-Driven Design for Requirements

### DDD Concepts for Requirements Discovery

| DDD Concept | What It Means for Requirements | When to Use |
|------------|-------------------------------|-------------|
| **Ubiquitous Language** | The exact words used in code must match the words used by business stakeholders | Always — alignment starts with shared vocabulary |
| **Bounded Context** | Different parts of the system may use the same word with different meanings | When the domain is complex with overlapping concepts |
| **Aggregate** | A cluster of objects treated as a single unit for data changes | When defining data consistency boundaries |
| **Domain Event** | Something that happened that domain experts care about | When defining system behaviors and integrations |
| **Value Object** | An immutable object defined by its attributes, not its identity | When clarifying what is an entity (has ID) vs. what is a value |
| **Entity** | An object with a distinct identity that persists over time | When defining the core objects in the system |

### Ubiquitous Language in Practice

**Problem**: Business says "customer," sales says "account," engineering says "user" — all referring to the same concept. This misalignment causes bugs, miscommunication, and wrong implementations.

**Solution**: Build a shared glossary:

```markdown
## Domain Glossary: E-Commerce

| Term | Definition | NOT the same as | Used in |
|------|-----------|-----------------|---------|
| **Customer** | A person who has made at least one purchase | User (may not have purchased), Visitor (anonymous) | Orders, Returns, Support |
| **User** | A person with an account (registered) | Customer (requires purchase), Visitor | Auth, Profile, Preferences |
| **Visitor** | An anonymous person browsing the site | User (has no account) | Analytics, Cart (guest cart) |
| **Order** | A confirmed purchase of one or more items | Cart (not yet confirmed), Invoice (financial document) | Fulfillment, Returns |
| **SKU** | A specific variant of a product (size/color) | Product (the general item) | Inventory, Fulfillment |
```

### Context Mapping

When multiple teams or systems interact, map how their bounded contexts relate:

| Relationship | Description | Example |
|-------------|-------------|---------|
| **Shared Kernel** | Two contexts share a common model they both maintain | Orders and Inventory share "Product" definition |
| **Customer-Supplier** | One context (supplier) provides data/services the other (customer) depends on | Payment service supplies transaction data to Analytics |
| **Conformist** | Downstream context accepts the upstream's model as-is | Your system conforms to a third-party API's data model |
| **Anti-Corruption Layer** | Downstream context translates upstream's model to its own | Wrapping a legacy system's API with a clean internal interface |
| **Open Host Service** | Upstream provides a well-defined protocol for all downstream contexts | Public REST API with versioning |
| **Published Language** | Shared language between contexts (usually a standard) | JSON:API, OpenAPI spec, Protocol Buffers |

---

## 9. API Contract Requirements

### OpenAPI-First / Schema-First Approach

Define the API contract before writing code:

**Benefits:**
- Frontend and backend teams can work in parallel
- API documentation is always in sync with the spec
- Contract testing can validate implementation against spec
- Code generation for client SDKs, server stubs, and validators

**Process:**
1. Write the OpenAPI spec based on requirements
2. Review the spec with frontend and backend teams
3. Use the spec to generate mock servers (Prism, MSW)
4. Frontend develops against the mock
5. Backend implements against the spec
6. Contract tests verify implementation matches spec

### API Specification Standards (2025-2026)

| Standard | Use Case | Status |
|----------|----------|--------|
| **OpenAPI 3.1** | REST APIs (dominant standard) | Mature, widely adopted |
| **AsyncAPI 3.0** | Event-driven APIs, WebSockets, message brokers | Growing, released 2024 |
| **GraphQL SDL** | GraphQL APIs, federated schemas | Mature |
| **Protocol Buffers** | gRPC service definitions | Mature |
| **TypeSpec** (Microsoft) | Multi-format API definitions (generates OpenAPI, gRPC, etc.) | Emerging |
| **JSON Schema** | Data validation, shared components | Mature, foundation for OpenAPI |

### API Requirements Checklist

| Category | Requirements to Specify |
|----------|----------------------|
| **Endpoints** | Resource paths, HTTP methods, URL structure |
| **Request Format** | Headers, query params, request body schema, content types |
| **Response Format** | Response body schema, status codes, error format |
| **Authentication** | Auth method (API key, OAuth, JWT), scopes/permissions |
| **Pagination** | Cursor-based vs. offset, page size limits, total count |
| **Filtering/Sorting** | Supported filter fields, operators, sort directions |
| **Rate Limiting** | Limits per tier, rate limit headers, retry-after behavior |
| **Versioning** | Versioning strategy (URL, header), deprecation policy |
| **Error Handling** | Error response format, error codes, retry guidance |
| **Idempotency** | Which operations are idempotent? Idempotency key header? |
| **Webhooks** | Event types, payload format, retry policy, signature verification |
| **Caching** | Cache headers, ETag support, cache invalidation |

### Error Response Requirements

Standardize error responses across the API:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The request body contains invalid fields.",
    "details": [
      {
        "field": "email",
        "message": "Must be a valid email address",
        "code": "INVALID_FORMAT"
      },
      {
        "field": "age",
        "message": "Must be between 0 and 150",
        "code": "OUT_OF_RANGE"
      }
    ],
    "request_id": "req_abc123",
    "documentation_url": "https://docs.example.com/errors/VALIDATION_ERROR"
  }
}
```

---

## 10. Requirements Prioritization

### Prioritization Frameworks

| Framework | How It Works | Best For | Limitations |
|-----------|-------------|----------|-------------|
| **MoSCoW** | Categorize as Must/Should/Could/Won't | Quick prioritization, stakeholder alignment | Binary categories, no relative ranking within categories |
| **RICE** | Reach × Impact × Confidence / Effort | Data-driven prioritization, comparing diverse items | Requires quantitative estimates that may be guesses |
| **WSJF** | Weighted Shortest Job First = Cost of Delay / Job Size | SAFe teams, economic decision-making | Complex to calculate, requires CoD estimation |
| **Kano Model** | Categorize features as Basic/Performance/Excitement | Understanding customer satisfaction drivers | Requires customer research, categories are subjective |
| **Value vs. Effort Matrix** | Plot on 2×2: high value/low effort = quick wins | Simple visual prioritization | Oversimplifies, doesn't account for dependencies |
| **ICE** | Impact × Confidence × Ease | Simpler version of RICE | Less rigorous, very subjective |

### MoSCoW Method

| Category | Meaning | Guideline |
|----------|---------|-----------|
| **Must Have** | Required for the release to be viable | If this is missing, the release is a failure |
| **Should Have** | Important but not critical for launch | Will be included if possible, but launch can proceed without |
| **Could Have** | Desirable if time and resources permit | Nice-to-have, no impact on success if excluded |
| **Won't Have** | Explicitly excluded from this release | Acknowledged as valid but deferred (manages expectations) |

**Rule of Thumb**: No more than 60% of effort should go to "Must Have" items — leave room for the unexpected.

### RICE Scoring

| Factor | How to Score |
|--------|-------------|
| **Reach** | How many users/customers will this affect per quarter? (100, 1000, 10000+) |
| **Impact** | How much will it affect each user? (3=massive, 2=high, 1=medium, 0.5=low, 0.25=minimal) |
| **Confidence** | How sure are you about the above? (100%=high, 80%=medium, 50%=low) |
| **Effort** | Person-months of work (0.5, 1, 2, 3, 5+) |

```
RICE Score = (Reach × Impact × Confidence) / Effort
```

### Kano Model

| Feature Type | Definition | Example | Customer Reaction |
|-------------|-----------|---------|-------------------|
| **Basic (Must-be)** | Expected — absence causes dissatisfaction, presence doesn't delight | Login works, data doesn't get lost, app loads | Dissatisfied if missing, neutral if present |
| **Performance (One-dimensional)** | More is better — satisfaction scales linearly with quality | Page load speed, number of integrations, storage space | Proportional satisfaction |
| **Excitement (Attractive)** | Unexpected delight — absence doesn't disappoint, presence delights | AI-powered suggestions, beautiful animations, surprising shortcuts | Neutral if missing, delighted if present |
| **Indifferent** | Customer doesn't care either way | Internal refactoring, technology migration | No impact on satisfaction |
| **Reverse** | Some customers actively dislike this feature | Forced tutorials, gamification for enterprise users | Causes dissatisfaction |

---

## 11. Requirements Validation & Verification

### Validation vs. Verification

| | Validation | Verification |
|---|-----------|-------------|
| **Question** | "Are we building the right thing?" | "Are we building it right?" |
| **Focus** | Customer/business needs | Technical specification |
| **When** | Throughout, especially early | During and after implementation |
| **Methods** | Reviews, prototypes, user testing | Testing, code review, formal inspection |
| **Done By** | Stakeholders + development team | Development team + QA |

### Requirements Quality Checklist

Validate every requirement against these criteria:

| Criterion | Check | Red Flag |
|-----------|-------|----------|
| **Clear** | Can two people read it and reach the same understanding? | "The system should be intuitive" |
| **Complete** | Are all necessary details specified? Edge cases? Error handling? | "Users can upload files" (what types? max size?) |
| **Consistent** | Does this contradict any other requirement? | Req A says "email required", Req B says "anonymous users supported" |
| **Testable** | Can you write a test that proves this requirement is met? | "The system should be reliable" (not testable without specific metrics) |
| **Feasible** | Can this actually be built with available resources and technology? | "Process any file in < 1ms" (physically impossible for large files) |
| **Traceable** | Can you trace this to a business need and forward to a test? | Orphan requirement with no business justification |
| **Prioritized** | Is the relative importance known? | "Everything is P0" |
| **Unambiguous** | Is there only one possible interpretation? | "The system should handle errors gracefully" |

### Handling Ambiguity and Conflict

| Situation | Approach |
|-----------|---------|
| **Ambiguous requirement** | Ask the stakeholder for examples. "Can you give me 3 specific scenarios?" |
| **Conflicting requirements** | Bring conflicting stakeholders together. Surface the tradeoff explicitly. |
| **Missing requirements** | Use edge case checklists, event storming, example mapping to surface gaps |
| **Changing requirements** | Embrace it (this is normal). Track changes, assess impact, re-prioritize |
| **Gold-plating** | "Is this a requirement or a preference? What's the cost of not having it?" |
| **Assumed requirements** | Make assumptions explicit. "We're assuming users have modern browsers — is that true?" |

---

## 12. Requirements Management Tools & Practices

### Tool Categories (2025-2026)

| Category | Tools | Best For |
|----------|-------|---------|
| **Agile Project Management** | Jira, Linear, Shortcut, Asana, Monday.com | User stories, sprint tracking, backlog management |
| **Documentation** | Notion, Confluence, GitBook, Coda | BRDs, TRDs, specifications, wikis |
| **Visual Collaboration** | Miro, FigJam, Lucidspark, Excalidraw | Story mapping, event storming, brainstorming |
| **Diagramming** | Mermaid (in Markdown), draw.io/diagrams.net, Lucidchart | Flow diagrams, data models, architecture diagrams |
| **Requirements Management** | Jama Connect, IBM DOORS, Helix RM, Modern Requirements (Azure) | Formal requirements management, traceability, regulated industries |
| **API Specification** | Stoplight, SwaggerHub, Redocly | API-first design, OpenAPI spec management |
| **Design/Prototype** | Figma, Sketch, Framer | UI/UX requirements, interactive prototypes |

### Requirements Traceability

For regulated industries or complex projects, maintain a traceability matrix:

```
Business Need → Business Requirement → Technical Requirement → Design → Code → Test Case

BN-001: "Reduce checkout abandonment"
  └── BR-001: "Show order summary before payment"
        └── TR-001: "Order summary API endpoint"
        │     └── Design: OrderSummaryComponent
        │     └── Code: src/components/OrderSummary.tsx
        │     └── Test: e2e/checkout/order-summary.spec.ts
        └── TR-002: "Calculate totals including tax and shipping"
              └── Design: PricingService
              └── Code: src/services/pricing.ts
              └── Test: unit/services/pricing.test.ts
```

### Requirements Review Checklist

Before accepting a requirements document:

- [ ] All requirements have a unique identifier (BR-001, TR-001)
- [ ] All requirements are testable (have acceptance criteria)
- [ ] All requirements trace to a business need
- [ ] Edge cases have been considered (use ZOMBIE checklist)
- [ ] Non-functional requirements are specified with measurable targets
- [ ] Assumptions are documented
- [ ] Dependencies are identified
- [ ] Out-of-scope items are explicitly listed
- [ ] Stakeholders have reviewed and signed off
- [ ] Glossary of domain terms is included
- [ ] Priority is assigned to all requirements
- [ ] No conflicting requirements exist
