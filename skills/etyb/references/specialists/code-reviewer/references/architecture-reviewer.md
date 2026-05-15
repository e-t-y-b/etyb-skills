# Architecture Reviewer — Deep Reference

**Always use `WebSearch` to verify current tool versions, framework features, and architecture testing capabilities before giving advice. Architecture tooling is maturing rapidly — new enforcement tools and analysis capabilities emerge regularly.**

## Table of Contents
1. [Design Pattern Adherence](#1-design-pattern-adherence)
2. [Separation of Concerns](#2-separation-of-concerns)
3. [Coupling and Cohesion Analysis](#3-coupling-and-cohesion-analysis)
4. [Clean Architecture Compliance](#4-clean-architecture-compliance)
5. [Circular Dependency Detection](#5-circular-dependency-detection)
6. [Layer Violation Detection](#6-layer-violation-detection)
7. [Technical Debt at Architecture Level](#7-technical-debt-at-architecture-level)
8. [API Contract Review](#8-api-contract-review)
9. [Microservices Anti-Patterns](#9-microservices-anti-patterns)
10. [Domain-Driven Design Adherence](#10-domain-driven-design-adherence)
11. [Architecture Testing Tools](#11-architecture-testing-tools)
12. [Architecture Decision Records](#12-architecture-decision-records)
13. [Architecture Review Checklist](#13-architecture-review-checklist)

---

## 1. Design Pattern Adherence

### What to Review

Architecture review isn't about enforcing design patterns dogmatically — it's about ensuring the codebase has *consistent* patterns that the team understands and can work with. The worst codebase isn't one without patterns — it's one with *multiple conflicting patterns* for the same concern.

### Common Pattern Issues in Review

**Pattern inconsistency**: The same type of problem solved differently in different parts of the codebase.

| Inconsistency | Example | Impact |
|--------------|---------|--------|
| Data access | Some modules use Repository pattern, others call DB directly | Confusion about where data access logic belongs |
| Error handling | Some modules use exceptions, others use Result types, others return null | Inconsistent error propagation, missed error handling |
| API response format | Some endpoints return `{data, error}`, others return raw data or `{success, message}` | Frontend must handle multiple response formats |
| State management | Mix of global state, module singletons, and dependency injection | Hard to trace data flow, testing difficulties |
| Configuration | Some services read env vars, others use config files, others use config services | Deployment complexity, environment inconsistency |

**Pattern misapplication**: Using a pattern where it doesn't fit.

| Misapplication | Signal | Better Approach |
|---------------|--------|----------------|
| Singleton for everything | Global state everywhere, hidden dependencies | Dependency injection |
| Observer pattern for simple notifications | Over-engineered event system for 2 components | Direct method call or callback |
| Strategy pattern for one strategy | Interface with single implementation | Direct implementation until second variant exists |
| Abstract Factory for one product family | Factory hierarchy for creating one type of object | Constructor or simple factory method |
| Service layer that just delegates | `UserService.getUser()` calls `UserRepository.getUser()` with no additional logic | Remove pass-through layer |

### When Patterns Help vs. Hurt

**Patterns help when**: There's a real need (multiple variants, cross-cutting concern, complex creation), the team understands the pattern, and it simplifies the code.

**Patterns hurt when**: Applied prophylactically ("we might need this"), the team doesn't know the pattern (creating confusion, not clarity), or the pattern adds more indirection than the problem warrants.

**Review heuristic**: If removing the pattern and writing straightforward code makes things simpler *and* the "we might need it" scenario hasn't materialized, the pattern is overhead.

---

## 2. Separation of Concerns

### What to Look For

**Mixed concerns in a single module**:

| Mixing | Example | Impact |
|--------|---------|--------|
| Business logic + I/O | Business rules inside HTTP handler / controller | Can't test business logic without HTTP, can't reuse in CLI/background job |
| Business logic + presentation | Formatting HTML/JSON inside domain model | Domain changes break presentation, presentation changes break domain |
| Data access + business logic | SQL queries interleaved with business rules | Can't change database without touching business logic |
| Configuration + logic | Hardcoded values mixed with behavior | Can't configure without code change |
| Cross-cutting + business | Logging, auth, caching mixed into business methods | Business methods obscured, can't change cross-cutting independently |

### The Key Question

For each module/class/function, ask: "If I need to change [the database / the UI framework / the business rules / the API format], how many files do I need to touch?"

If changing one concern requires modifying multiple layers, concerns are leaking across boundaries.

### Boundary Patterns

| Pattern | What It Separates | When to Use |
|---------|------------------|-------------|
| **Ports and Adapters** (Hexagonal) | Domain from infrastructure | When domain logic must be independent of delivery mechanism |
| **MVC / MVVM** | Model from View from Controller | UI applications |
| **Repository Pattern** | Data access from business logic | When data source might change, or for testability |
| **DTO/ViewModel** | Internal representation from external contract | API boundaries, service-to-service communication |
| **Anti-Corruption Layer** | Your domain from external system's model | Integration with legacy or third-party systems |

---

## 3. Coupling and Cohesion Analysis

### Coupling Types (Worst to Best)

| Type | Description | Example | Risk |
|------|------------|---------|------|
| **Content coupling** | Module directly modifies another's internal data | Reaching into another class's private fields | Extremely fragile, any internal change breaks both |
| **Common coupling** | Modules share global mutable state | Global configuration object, shared singleton state | Changes to global affect all consumers unpredictably |
| **Control coupling** | Module tells another *how* to behave via flags | `process(data, isAdmin=true)` changing internal flow | Caller knows too much about callee's internals |
| **Stamp coupling** | Module passes more data than needed | Passing entire User object when only userId is needed | Unnecessary dependency on data structure |
| **Data coupling** | Modules share only necessary data via parameters | `getUser(userId)` | Minimal coupling, ideal |
| **Message coupling** | Modules communicate via messages/events | Event bus, message queue | Loosest coupling, asynchronous |

### Cohesion Types (Worst to Best)

| Type | Description | Signal |
|------|------------|--------|
| **Coincidental** | Unrelated functions grouped together | `Utils`, `Helpers`, `Misc` classes |
| **Logical** | Related by category, not function | `AuthController` handling login, registration, password reset, MFA, and user profile |
| **Temporal** | Run at the same time | `startup()` function that initializes DB, logger, cache, and queue |
| **Procedural** | Steps in a process | Fine for scripts, but modules should be higher |
| **Communicational** | Operate on the same data | `UserService` with methods that all operate on User entity |
| **Functional** | All parts contribute to a single function | `EmailSender` that only sends emails | Ideal for single responsibility |

### Metrics

| Metric | What It Measures | Tool | Warning Threshold |
|--------|-----------------|------|------------------|
| **CBO** (Coupling Between Objects) | Direct dependencies between classes | SonarQube, JDepend, NDepend | > 14 |
| **LCOM4** (Lack of Cohesion) | Connected components in method-attribute graph | SonarQube, JDepend | > 1 (class should be split) |
| **Ca** (Afferent Coupling) | Incoming dependencies (how many depend on this) | JDepend, NDepend | High Ca = stable component, hard to change |
| **Ce** (Efferent Coupling) | Outgoing dependencies (how many this depends on) | JDepend, NDepend | High Ce = unstable component, often changes |
| **Instability** | Ce / (Ca + Ce) | JDepend, NDepend | Stable (I≈0) should be abstract; unstable (I≈1) should be concrete |

### The Stable Abstractions Principle

Packages that many others depend on (high Ca, low instability) should be abstract (interfaces, not implementations). This prevents changes to stable packages from cascading.

Packages that few depend on (low Ca, high instability) should be concrete — they're free to change without impact.

**Review signal**: A concrete class with many dependents. If this class changes, many things break. It should probably be behind an interface.

---

## 4. Clean Architecture Compliance

### The Dependency Rule

The fundamental rule: **source code dependencies must point inward only**. Nothing in an inner layer can know about an outer layer.

```
┌──────────────────────────────────────────────────────┐
│                  Frameworks & Drivers                 │
│  (Express, Django, React, PostgreSQL driver, Redis)   │
│  ┌──────────────────────────────────────────────────┐ │
│  │              Interface Adapters                   │ │
│  │  (Controllers, Presenters, Gateways, Repos)       │ │
│  │  ┌──────────────────────────────────────────────┐ │ │
│  │  │             Application Layer                 │ │ │
│  │  │  (Use Cases, Application Services)            │ │ │
│  │  │  ┌──────────────────────────────────────────┐ │ │ │
│  │  │  │           Domain / Entities               │ │ │ │
│  │  │  │  (Business rules, Value Objects)          │ │ │ │
│  │  │  └──────────────────────────────────────────┘ │ │ │
│  │  └──────────────────────────────────────────────┘ │ │
│  └──────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────┘
                  Dependencies point INWARD →
```

### What to Look For in Review

**Layer violations** (outer layer imported in inner layer):

```python
# VIOLATION — domain layer importing framework
# File: domain/models/order.py
from django.db import models  # ❌ Domain depends on Django

class Order(models.Model):  # ❌ Domain entity IS a Django model
    total = models.DecimalField()

# CORRECT — domain is framework-free
# File: domain/models/order.py
from dataclasses import dataclass
from decimal import Decimal

@dataclass
class Order:
    total: Decimal
    
# Infrastructure maps to/from Django models
# File: infrastructure/persistence/django_order_model.py
from django.db import models

class DjangoOrder(models.Model):
    total = models.DecimalField()
```

```typescript
// VIOLATION — use case importing Express
// File: application/use-cases/create-user.ts
import { Request, Response } from 'express'; // ❌

export function createUser(req: Request, res: Response) { // ❌ Tied to HTTP
    // ...
}

// CORRECT — use case is framework-free
// File: application/use-cases/create-user.ts
import { UserRepository } from '../ports/user-repository'; // ✅ Depends on port (interface)

export function createUser(input: CreateUserInput, repo: UserRepository) {
    // Business logic only
}
```

### When Clean Architecture Is Overkill

Clean Architecture adds complexity (more files, more mapping). It's worth it when:
- The domain is complex and changes independently of infrastructure
- Multiple delivery mechanisms exist (API + CLI + background workers)
- Infrastructure might change (database migration, framework swap)
- Team is large enough that boundaries prevent accidental coupling

It's overkill when:
- Simple CRUD app with no complex business logic
- Prototype/MVP where speed matters more than architecture
- Small team (1-3) where communication prevents coupling anyway

---

## 5. Circular Dependency Detection

### Why Circular Dependencies Are Problematic

- **Build issues**: Compilation order becomes undefined, incremental builds may fail
- **Deployment coupling**: Can't deploy modules independently
- **Comprehension**: Can't understand module A without understanding module B and vice versa
- **Testing**: Can't test in isolation
- **Change amplification**: Change in one module may require changes in the other

### How to Spot in Review

**Direct circular dependency** (A → B → A):
- Module A imports from Module B, and Module B imports from Module A
- Often happens when two modules evolve together and gradually take on responsibilities that reference each other

**Indirect circular dependency** (A → B → C → A):
- Harder to spot, often emerges as modules are added
- Requires dependency graph analysis

### Detection Tools

| Tool | Language | How to Use |
|------|----------|-----------|
| **Madge** | JavaScript/TypeScript | `madge --circular src/` — finds and lists all circular import chains |
| **dependency-cruiser** | JavaScript/TypeScript | Rules-based validation with visual dependency graphs |
| **deptry** | Python | Finds unused, missing, and transitive dependencies |
| **cargo-depgraph** | Rust | Visualizes crate dependency graph |
| **go mod graph** | Go | Built-in dependency graph, pipe to tool for cycle detection |
| **JDepend** | Java | Package-level dependency cycles |
| **ArchUnit** | Java | Test-based detection: `slices().should().beFreeOfCycles()` |
| **ArchUnitTS** | TypeScript | Same as ArchUnit for TS projects |

### Breaking Circular Dependencies

| Technique | How It Works | When to Use |
|-----------|-------------|-------------|
| **Extract interface** | A depends on interface I (in A's layer), B implements I | When A needs to call B but shouldn't depend on B's implementation |
| **Dependency inversion** | Move shared types to a third module C; both A and B depend on C | When both modules need shared types/interfaces |
| **Event-based decoupling** | A emits event, B subscribes | When the dependency is for notification, not data retrieval |
| **Merge modules** | If A and B are always used together, they might be one module | When the separation was premature |

---

## 6. Layer Violation Detection

### Common Layer Violation Patterns

| Violation | Example | Fix |
|-----------|---------|-----|
| **Controller calling repository directly** | HTTP handler queries database, skipping service layer | Route through service/use case layer |
| **Domain depending on persistence** | Entity class extends ORM model class | Use separate persistence models, map at boundary |
| **Service depending on HTTP** | Service method accepts `Request` object | Accept plain data types, convert at controller |
| **UI logic in business layer** | Service formats dates, generates HTML | Return raw data, format in presentation layer |
| **Infrastructure logic in domain** | Domain entity calls external API | Use domain event or port/adapter |

### Enforcement Tools

| Tool | Language | How It Enforces |
|------|----------|----------------|
| **ArchUnit** | Java | JUnit tests: `noClasses().that().resideInAPackage("..domain..").should().dependOnClassesThat().resideInAPackage("..infrastructure..")` |
| **ArchUnitTS** | TypeScript | Same declarative rules for TypeScript import direction |
| **dependency-cruiser** | JavaScript/TypeScript | Configuration-based rules with visual output |
| **fresh-onion** | TypeScript | Uses TypeScript compiler API to check clean architecture rules |
| **Go internal packages** | Go | Built-in: `internal/` directories restrict imports to parent tree |
| **Module boundaries** (Java 9+) | Java | `module-info.java` controls which packages are exported |

### Example: ArchUnit Rules for Clean Architecture

```java
@Test
void domainShouldNotDependOnInfrastructure() {
    noClasses()
        .that().resideInAPackage("..domain..")
        .should().dependOnClassesThat()
        .resideInAnyPackage("..infrastructure..", "..framework..", "..persistence..")
        .check(importedClasses);
}

@Test
void useCasesShouldNotDependOnFramework() {
    noClasses()
        .that().resideInAPackage("..application..")
        .should().dependOnClassesThat()
        .resideInAnyPackage("..framework..", "..web..", "..persistence..")
        .check(importedClasses);
}

@Test
void noCircularDependenciesBetweenSlices() {
    slices().matching("com.example.(*)..").should().beFreeOfCycles()
        .check(importedClasses);
}
```

---

## 7. Technical Debt at Architecture Level

### Types of Architectural Debt

| Type | Description | Examples | Impact |
|------|------------|---------|--------|
| **Structural debt** | Architecture doesn't match current needs | Monolith that should be decomposed, microservices that should be merged | Change velocity slows, deployment risk increases |
| **Decision debt** | Past decisions no longer make sense | Chose NoSQL but now need joins everywhere, chose REST but need real-time | Workarounds accumulate, complexity grows |
| **Erosion debt** | Architecture rules violated over time | Bypassed layers, mixed concerns, circular dependencies | Original architecture benefits lost |
| **Technology debt** | Outdated or EOL technologies | Framework 2 major versions behind, deprecated APIs, unsupported libraries | Security risk, hiring difficulty, migration urgency |

### Identifying Architectural Debt in Review

**Signals in PRs**:
- Workarounds that bypass the architecture ("I know this should go through the service layer, but...")
- Same change required in many unrelated files (shotgun surgery)
- New feature requiring modifications to shared/core modules
- Increasing reliance on shared mutable state
- Growing `utils` or `helpers` directories (misplaced responsibilities)
- Defensive programming against other modules' bugs

### Communicating Architectural Debt in Reviews

Don't just say "this adds tech debt." Be specific:

```
🟠 Architecture: This PR adds a direct database call in the controller layer,
bypassing the service layer.

Why this matters: We've been using the service layer as the authorization
boundary — all permission checks happen there. Bypassing it means this
endpoint has no permission checks. It also sets a precedent that makes
the service layer optional, which will erode over time.

Options:
1. Move the query logic into UserService (recommended — 15 min)
2. Add permission checks directly in the controller (works but inconsistent)
3. Accept as-is and track as tech debt ticket (if time-pressured)
```

---

## 8. API Contract Review

### Breaking Change Detection

**What constitutes a breaking change**:
- Removing a field from a response
- Renaming a field
- Changing a field's type
- Making a previously optional field required
- Removing an endpoint
- Changing authentication requirements
- Changing the meaning/behavior of an existing field (behavioral breaking change)

**What is NOT a breaking change**:
- Adding a new optional field to a response
- Adding a new endpoint
- Adding a new optional parameter
- Deprecating (but not removing) a field

### Automated Detection Tools

| Tool | What It Does | Integration |
|------|-------------|-------------|
| **oasdiff** | Compares two OpenAPI specs, detects breaking changes | CI — block merges with breaking changes |
| **Optic** | API behavior diff — compares actual traffic to spec | CI/CD, staging environment |
| **Specmatic** | Contract testing from OpenAPI spec | Integration tests |
| **Pact** | Consumer-driven contract testing | CI — verify provider against consumer contracts |

### API Versioning Strategy Review

| Strategy | Pros | Cons | Best For |
|----------|------|------|----------|
| **URL versioning** (`/v1/users`) | Clear, easy to route | URL pollution, hard to sunset | Public APIs |
| **Header versioning** (`Accept: application/vnd.api.v1+json`) | Clean URLs | Hidden, harder to test/debug | Internal APIs, sophisticated clients |
| **Query parameter** (`/users?version=1`) | Easy to add, optional | Caching complications | Quick prototyping |
| **No versioning** (additive changes only) | Simplest, no migration | Requires discipline, can't remove fields | Internal APIs with controlled consumers |

### What to Check in API PRs

- [ ] New endpoints follow existing naming conventions
- [ ] Response format consistent with existing endpoints
- [ ] Error responses use same structure as other endpoints
- [ ] No breaking changes (or version bumped if breaking)
- [ ] Pagination for list endpoints
- [ ] Input validation with clear error messages
- [ ] Rate limiting considered for new public endpoints
- [ ] Documentation/OpenAPI spec updated

---

## 9. Microservices Anti-Patterns

### Anti-Patterns to Flag in Review

| Anti-Pattern | What It Looks Like | Why It's Bad | Fix |
|-------------|-------------------|-------------|-----|
| **Distributed Monolith** | Services that must be deployed together, share databases, or have synchronous call chains | All the complexity of microservices, none of the benefits | Establish proper service boundaries, async communication |
| **Shared Database** | Multiple services reading/writing the same tables | No independent deployment, schema changes break others | Each service owns its data, use APIs/events to share |
| **Chatty Services** | Many synchronous calls between services for single operations | Latency compounds, cascading failures | Aggregate calls, use async events, consider merging chatty services |
| **God Service** | One service that everything depends on | Single point of failure, deployment bottleneck | Decompose by domain, extract responsibilities |
| **Circular Dependencies** | Service A calls B, B calls C, C calls A | Can't deploy independently, deadlock risk | Break cycles with events, shared data via ownership |
| **Nano Services** | Services that are too small to justify their overhead | Network overhead exceeds benefit, operational complexity | Merge related nano-services |

### Detection During Review

**Shared database access**: Any PR adding a direct query to a database that another service "owns" is a red flag.

**Synchronous chains**: If completing one user request requires calling 3+ services synchronously, that's a distributed monolith. Check for `await serviceB.call()` chains.

**Data duplication without sync**: If two services store the same data but have no synchronization mechanism (events, CDC), they'll inevitably diverge.

---

## 10. Domain-Driven Design Adherence

### What to Review for DDD Projects

**Bounded Context Integrity**:
- Types/entities from one bounded context shouldn't leak into another
- Each context has its own models, even if they represent "the same" real-world concept (User in auth context ≠ User in billing context)
- Anti-corruption layers at context boundaries

**Aggregate Design**:
- Aggregates are the consistency boundary — transactions should not cross aggregate boundaries
- Aggregate root controls all access to internal entities
- External references to aggregates should be by ID, not by direct object reference

**Domain Events**:
- Cross-context communication should be via domain events, not direct calls
- Events should describe what happened (past tense: `OrderPlaced`), not what to do (`ProcessOrder`)
- Events should be immutable value objects

**Ubiquitous Language**:
- Code terminology matches business terminology within each bounded context
- No technical jargon where business language would be clearer (`Payment` not `MonetaryTransaction`)
- Consistent naming within a context (don't mix `Customer` and `Client` for the same concept)

---

## 11. Architecture Testing Tools

### Comprehensive Tool Matrix

| Tool | Language | Layer Rules | Cycle Detection | API Contracts | Visual |
|------|----------|------------|-----------------|---------------|--------|
| **ArchUnit** | Java | Yes (declarative) | Yes | No | No |
| **ArchUnitTS** | TypeScript | Yes | Yes | No | No |
| **dependency-cruiser** | JavaScript/TS | Yes (config) | Yes | No | Yes (SVG/dot) |
| **fresh-onion** | TypeScript | Yes | No | No | No |
| **Madge** | JavaScript/TS | No | Yes | No | Yes (SVG) |
| **oasdiff** | Any (OpenAPI) | No | No | Yes | No |
| **Pact** | Multi-language | No | No | Yes (CDC) | Dashboard |
| **NDepend** | .NET | Yes | Yes | No | Yes |
| **JDepend** | Java | Metrics | Yes | No | No |

### CI Integration Pattern

```yaml
# GitHub Actions example
architecture-check:
  runs-on: ubuntu-latest
  steps:
    # Java: ArchUnit runs as part of tests
    - run: mvn test -pl architecture-tests
    
    # TypeScript: dependency-cruiser
    - run: npx depcruise src --config .dependency-cruiser.cjs --output-type err
    
    # API contract: oasdiff
    - run: oasdiff breaking main..HEAD -- api/openapi.yaml
    
    # JavaScript: Madge circular check
    - run: npx madge --circular src/ && echo "No circular dependencies"
```

---

## 12. Architecture Decision Records

### When to Request an ADR in Review

If a PR makes a significant architectural decision (new pattern, new technology, new module boundary), ask: "Is there an ADR for this decision?"

ADRs are valuable because:
- They capture *why* a decision was made (the context and constraints)
- Future developers can understand the reasoning without archaeological git digs
- They prevent re-litigating decided issues

### ADR Format (Lightweight)

```markdown
# ADR-NNN: Title

## Status
Proposed | Accepted | Deprecated | Superseded by ADR-XXX

## Context
What is the issue or challenge? What constraints exist?

## Decision
What did we decide to do?

## Consequences
What are the positive and negative consequences of this decision?
```

### When an ADR Is Warranted

- Choosing a new framework, library, or technology
- Defining module/service boundaries
- Changing data access patterns
- Introducing new cross-cutting patterns (caching, auth, logging)
- Making a decision that constrains future options

---

## 13. Architecture Review Checklist

### Structure
- [ ] Clear module/package boundaries with defined responsibilities
- [ ] Consistent patterns within each architectural layer
- [ ] No circular dependencies between modules
- [ ] Dependencies point in the correct direction (inward for clean architecture)

### Coupling
- [ ] Modules depend on abstractions, not concretions (where appropriate)
- [ ] No shared mutable global state between modules
- [ ] Changes to one module don't require changes to unrelated modules
- [ ] Service-to-service communication uses defined contracts

### Cohesion
- [ ] Each module has a clear, single purpose
- [ ] No "utils" or "helpers" accumulating misplaced logic
- [ ] Related functionality is co-located (not spread across many modules)

### Consistency
- [ ] New code follows established patterns (or documents why it diverges)
- [ ] API contracts are consistent (naming, error format, pagination)
- [ ] Error handling strategy is consistent across layers

### Evolvability
- [ ] Architecture supports expected changes without major refactoring
- [ ] New features can be added without modifying existing modules excessively
- [ ] Significant architectural decisions are documented (ADRs)
- [ ] Technical debt is tracked and visible
