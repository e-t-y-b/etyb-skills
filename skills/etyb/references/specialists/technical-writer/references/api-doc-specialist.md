# API Documentation Specialist — Deep Reference

**Always use `WebSearch` to verify current tool versions, OpenAPI specification status, and platform features before giving API documentation advice. The API tooling ecosystem evolves rapidly — especially SDK generators, documentation renderers, and developer portal platforms. Last verified: April 2026.**

## Table of Contents
1. [OpenAPI Ecosystem](#1-openapi-ecosystem)
2. [API Documentation Renderers](#2-api-documentation-renderers)
3. [Developer Portal Platforms](#3-developer-portal-platforms)
4. [AsyncAPI for Event-Driven APIs](#4-asyncapi-for-event-driven-apis)
5. [GraphQL Documentation](#5-graphql-documentation)
6. [gRPC Documentation](#6-grpc-documentation)
7. [API Reference Best Practices](#7-api-reference-best-practices)
8. [SDK Generation](#8-sdk-generation)
9. [API Changelog and Versioning](#9-api-changelog-and-versioning)
10. [Documentation-as-Code for APIs](#10-documentation-as-code-for-apis)
11. [API Style Guides](#11-api-style-guides)
12. [Developer Experience and Onboarding](#12-developer-experience-and-onboarding)
13. [Language-Specific Documentation Generators](#13-language-specific-documentation-generators)
14. [AI-Ready API Documentation](#14-ai-ready-api-documentation)

---

## 1. OpenAPI Ecosystem

### Specification Versions

| Version | Status | Key Features |
|---------|--------|-------------|
| **OpenAPI 3.1** | Widely adopted baseline | Full JSON Schema compatibility |
| **OpenAPI 3.2** (Sep 2025) | Current, backward-compatible with 3.1 | Streaming APIs (SSE), hierarchical tags, QUERY method, OAuth 2.0 Device Authorization Flow, improved multipart/form-data, enhanced XML |
| **OpenAPI 4.0 (Moonwalk)** | Early development, no release date | Using ADRs to inform design; recommend 3.x for all current projects |

### Companion Specifications

**Arazzo Specification v1.0.1** (Jan 2025): Defines deterministic, machine-readable API workflow sequences — goes beyond single-call specs to describe multi-step API interactions. Version 1.1.0 in development adds AsyncAPI support for cross-protocol workflows.

**Overlay Specification v1.0.0** (Oct 2024): Defines repeatable transformations to OpenAPI descriptions (add, overwrite, remove, copy). Useful for customizing shared specs per audience or environment without forking the base spec.

**TypeSpec** (Microsoft): A language that compiles to OpenAPI, JSON Schema, and Protobuf simultaneously. Useful when you need a single source of truth across REST and gRPC APIs.

### When to Use What

- **OpenAPI 3.1/3.2** — the standard for REST APIs. Start here for any new API documentation effort
- **Arazzo** — when documenting multi-step workflows (checkout flows, onboarding sequences)
- **Overlay** — when the same API needs different documentation for different audiences (public vs partner vs internal)
- **TypeSpec** — when a single API must generate both REST and gRPC artifacts

---

## 2. API Documentation Renderers

### Renderer Comparison

| Tool | Approach | Best For | Limitations |
|------|----------|----------|-------------|
| **Scalar** | Modern interactive reference | New projects wanting polished UX; supports Markdown/MDX, GitHub Sync, SDK generation (TS, Python, Go, PHP, Java, Ruby) | Newer ecosystem |
| **Redoc CE** (Redocly) | Three-panel read-only reference | Professional-looking static API docs | No interactive "try it" in CE |
| **Swagger UI v5.32** | Interactive reference with "try it" | Wide adoption, familiar UX; supports OAS 2.0-3.2 | Aging UI compared to alternatives |
| **RapiDoc** | Web component (LitElement) | Embedding API docs in existing sites/SPAs without heavy dependencies | Smaller community |
| **Stoplight Elements** | Embeddable React component | API-first design workflows (visual editor + mock servers + style guides) | Part of broader Stoplight platform |

### Selection Framework

```
1. Need interactive "try it" console?
   - Yes + modern UX → Scalar
   - Yes + maximum compatibility → Swagger UI
   - Yes + embeddable → RapiDoc
2. Need read-only, polished reference?
   → Redoc CE
3. Need full API design-first workflow?
   → Stoplight Elements (part of Stoplight platform)
4. Already in a developer portal platform?
   → Use the platform's built-in renderer (Mintlify, ReadMe, Redocly)
```

---

## 3. Developer Portal Platforms

### Platform Comparison

| Platform | Approach | Best For | Pricing |
|----------|----------|----------|---------|
| **Mintlify** | Git-native MDX, AI assistant, llms.txt, analytics | API-focused startups wanting fast, polished docs | Free tier; Pro ~$300/month |
| **ReadMe** | Interactive API explorer, visual editor, API metrics | API-first companies needing best-in-class interactive API docs | $79/month; Enterprise $3,000+ |
| **Docusaurus v3** (Meta) | React-based SSG, full control, self-hosted | Engineering teams wanting maximum flexibility at zero licensing | Free (open-source) |
| **Starlight** (Astro) | Fast Astro-based SSG, framework-agnostic | Framework-agnostic static docs with excellent performance | Free (open-source) |
| **Fumadocs** | Next.js headless component kit, composable | Next.js teams needing docs integrated into larger app | Free (open-source) |
| **Nextra v4** | Next.js App Router, opinionated themes | Next.js teams wanting quick setup with minimal config | Free (open-source) |
| **GitBook** | Block-based editor, AI agent for doc gaps | Mixed technical/non-technical teams; internal wikis | $65/site + $12/user/month |
| **Redocly** | OpenAPI-first, CLI tools, MCP server | Teams with complex OpenAPI specs needing production API reference | Free core; paid from ~$99/month |
| **Markdoc** (Stripe) | Markdown with custom tags, validation at build | Teams wanting Stripe-quality interactive docs with guarantees | Free (open-source) |

### Selection Framework

```
1. What's the primary need?
   - API reference (interactive) → ReadMe or Mintlify
   - API reference (static/beautiful) → Redocly
   - General developer docs → Docusaurus, Starlight, or Mintlify
   - Next.js integration → Fumadocs or Nextra
   - Internal wiki + docs → GitBook or Notion

2. What's the team's technical profile?
   - Strong React/Next.js → Fumadocs or Docusaurus
   - Vue.js → VitePress
   - Framework-agnostic → Starlight (Astro)
   - Non-technical contributors → GitBook or Notion
   - Maximum control/customization → Docusaurus or Fumadocs

3. Budget constraints?
   - Zero budget → Docusaurus, Starlight, or MkDocs Material (open-source)
   - Moderate budget → Mintlify or GitBook
   - Enterprise budget → ReadMe Enterprise or Redocly
```

---

## 4. AsyncAPI for Event-Driven APIs

### Current State: AsyncAPI 3.0

AsyncAPI 3.0 is the current major version for documenting event-driven APIs. It supports protocol-agnostic definitions for Kafka, AMQP, MQTT, WebSockets, and more.

### Key Ecosystem Tools

| Tool | Purpose |
|------|---------|
| **AsyncAPI Studio** | Visual design, validation, preview, template generation |
| **AsyncAPI Generator v3.2** (Feb 2026) | Generates documentation, code, diagrams from specs |
| **AsyncAPI CLI** | Command-line validation, generation, workflow automation |

### When to Use AsyncAPI

- Kafka event schemas that need documentation
- WebSocket API contracts
- MQTT-based IoT protocols
- Any message-driven architecture requiring contract documentation
- Cross-protocol workflows (pair with Arazzo v1.1.0 when available)

### Documentation Pattern

Document event-driven APIs alongside REST APIs in the same portal. Use OpenAPI for request-response endpoints and AsyncAPI for event streams. Many portals (Mintlify, Redocly) now support both.

---

## 5. GraphQL Documentation

### Tool Comparison

| Tool | Type | Best For |
|------|------|----------|
| **GraphiQL** | Interactive IDE | Schema exploration, query building; embedded in most GraphQL servers |
| **Apollo Studio / GraphOS Explorer** | Enterprise IDE + schema registry | Advanced schema visualization, performance metrics, managed federation |
| **SpectaQL** | Static doc generator | Auto-generated, deployable GraphQL reference from schema introspection or SDL |

### GraphQL Documentation Best Practices

- Schema is self-documenting — invest in description fields for every type, field, and argument
- Generate static reference docs from schema (SpectaQL) for browsable reference alongside interactive explorer
- Document common query patterns and real-world usage examples
- Include pagination patterns (cursor-based vs offset), error handling, and authentication
- For federated schemas: document the unified graph, not individual subgraphs

---

## 6. gRPC Documentation

### Tool Comparison

| Tool | Purpose |
|------|---------|
| **Buf** | Modern Protobuf toolchain: linting, breaking change detection, code generation, schema registry (BSR) |
| **protoc-gen-doc** | Protobuf compiler plugin generating HTML, JSON, DocBook, Markdown from proto files |

### gRPC Documentation Best Practices

- Proto comments are the single source of truth — they become generated docs
- Use Buf for linting and breaking change detection in CI
- Use protoc-gen-doc for rendering human-readable documentation
- Document the service overview, authentication, error codes, and streaming patterns separately from the auto-generated reference
- Publish proto files to Buf Schema Registry (BSR) for discoverability

---

## 7. API Reference Best Practices

### Code Examples (Stripe-quality standard)

- **Multi-language**: Minimum cURL, Python, Node.js, Go, Java — with single-click language switching
- **Working examples**: Every example should be copy-pasteable and produce a real result
- **Authentication included**: Auto-inject test API keys for logged-in users; show placeholder for anonymous users
- **Error handling shown**: Include error response examples alongside happy path
- **Response shown**: Include full response body with field descriptions

### Interactive Try-It-Out

- Embedded API explorers reduce time-to-first-call from hours to minutes
- Mock/sandbox responses for unauthenticated users
- Pre-populated with realistic test data
- Tools: Scalar (built-in), Swagger UI (built-in), ReadMe API Explorer, RapiDoc console

### Authentication Documentation

- Dedicated section with flow diagrams for each auth method
- Copy-pasteable examples for each method (API key, OAuth 2.0, JWT bearer)
- Environment-specific instructions (test vs. production credentials)
- Token lifecycle documentation (expiration, refresh, revocation)

### Error Reference

- Complete list of error codes with HTTP status, error body, and resolution
- Group by category (authentication, validation, rate limiting, server errors)
- Include troubleshooting guidance for each error
- Link common errors to relevant how-to guides

---

## 8. SDK Generation

### Tool Comparison

| Tool | Languages | Key Strength | Best For |
|------|-----------|-------------|----------|
| **Speakeasy** | 9+ (TS, Python, Go, Java, C#, PHP, etc.) | OpenAPI-native, SDK Studio GUI, also generates MCP servers and CLIs | Comprehensive OpenAPI-native generation |
| **Stainless** | TS, Python, Go, Java, Kotlin | Powers OpenAI/Anthropic/Cloudflare SDKs; "hand-crafted" quality | Premium-tier SDK quality |
| **Fern** | TS, Python, Go, Java, C#, PHP, Ruby, Swift, Rust | Unified SDK + docs from same spec; auth, retries, pagination built-in | Teams wanting SDK + docs from one platform |
| **Kiota** (Microsoft) | Multi-language | Language-agnostic code model, no templates | Microsoft ecosystem / enterprise |
| **OpenAPI Generator** | 50+ languages | Broadest language support, open-source | Budget-conscious teams needing breadth |

### Selection Framework

- Need highest quality, willing to pay → **Stainless** or **Speakeasy**
- Want unified SDK + docs pipeline → **Fern**
- Need maximum language coverage, limited budget → **OpenAPI Generator** (expect to polish output)
- Microsoft/.NET ecosystem → **Kiota**
- Also need MCP server generation → **Speakeasy** or **Stainless**

### SDK Documentation Best Practices

- Auto-generate from OpenAPI spec, don't hand-write
- Include quickstart with install + first API call
- Document each method with parameters, return types, and examples
- Show error handling patterns
- Provide migration guide between SDK versions

---

## 9. API Changelog and Versioning

### Versioning Strategies

| Strategy | Example | Best For |
|----------|---------|----------|
| **Date-based** | `2025-04-30` | Stripe model; clear, no ambiguity about ordering |
| **Semantic** | `v2.1.0` | Standard for SDKs and libraries |
| **URL path** | `/v2/users` | Simple, explicit version selection |
| **Header-based** | `API-Version: 2025-04-30` | Keeps URLs clean, flexible |

### Changelog Best Practices

- Describe what changed, impact assessment, and required consumer actions
- Categorize changes: Added, Changed, Deprecated, Removed, Fixed, Security
- Clearly mark breaking changes with migration instructions
- Provide deprecation notices well in advance with migration timelines
- Include code-level before/after examples for breaking changes
- Offer subscription mechanisms: RSS, email, webhooks for changelog updates

### Breaking Changes Documentation

A breaking change is anything that requires consumer code changes:
- Removing/renaming endpoints or fields
- Changing response structure or data types
- Modifying authentication requirements
- Altering error code semantics

For each breaking change: describe the change, explain why, provide migration steps with code examples, and specify the timeline.

---

## 10. Documentation-as-Code for APIs

### API Linting

| Tool | Language | Strength |
|------|----------|----------|
| **Spectral** (Stoplight) | Node.js | Industry standard; custom rulesets for org style guides; supports OAS 3.x, AsyncAPI 2.x, Arazzo 1.0 |
| **Vacuum** | Go | Fastest OpenAPI linter; Spectral-compatible rulesets; JUnit output for CI |
| **Redocly CLI** | Node.js | All-in-one: lint, bundle, preview, build; supports OAS 3.2, AsyncAPI 3.0, Arazzo 1.0 |

### CI/CD Workflow for API Docs

```
1. Developer updates OpenAPI spec in PR
2. CI runs:
   - Spectral/Vacuum linting (style guide enforcement)
   - Breaking change detection (oasdiff or Optic)
   - Contract tests (validate API responses match spec)
   - Doc preview deployment (Netlify/Vercel preview)
3. Reviewer checks rendered docs in preview
4. On merge to main:
   - Auto-rebuild documentation site
   - Regenerate SDKs (Speakeasy/Fern/Stainless)
   - Update changelog
   - Deploy to production docs site
```

### Spec Organization for Large APIs

- Single spec for small APIs (< 30 endpoints)
- Multi-file specs with `$ref` for medium APIs (30-100 endpoints)
- Spec-per-service with aggregation for microservices architectures
- Use Redocly CLI or Swagger CLI to bundle multi-file specs for tooling

---

## 11. API Style Guides

### Industry References

| Guide | Focus | Key Pattern |
|-------|-------|-------------|
| **Google Cloud API Design Guide** | Resource-oriented design | Standard methods (List, Get, Create, Update, Delete); naming conventions; error handling |
| **Microsoft REST API Guidelines** | Enterprise REST patterns | TypeSpec integration; Azure-specific refinements; action patterns |
| **Stripe API Design** | Developer-friendly APIs | Dated versioning, expansion parameters, idempotency keys, metadata |
| **Zalando RESTful API Guidelines** | Microservices at scale | Comprehensive REST + events guidelines; widely referenced in industry |
| **API Stylebook** (apistylebook.com) | Cross-reference | Aggregates 13+ API guides by topic for comparison |

### Enforcing Style Guides

- Codify organizational API standards as Spectral custom rulesets
- Run in CI on every PR that modifies API specs
- Include rules for naming conventions, error formats, pagination patterns, versioning
- Use Stoplight's built-in style guide enforcement or Redocly configurable rules

---

## 12. Developer Experience and Onboarding

### Time-to-First-Call Optimization

The critical metric for API documentation success. Target: developer makes a successful API call within 5 minutes of reading your docs.

**Quickstart Guide Structure:**
1. One sentence: what this API does
2. Prerequisites (accounts, API keys, SDK installation)
3. Installation command (copy-pasteable)
4. Minimal working example (< 10 lines of code)
5. Expected response
6. "What's next" links to common use cases

### Sandbox and Mock Servers

| Tool | Type | Best For |
|------|------|---------|
| **Prism** (Stoplight) | OpenAPI-to-mock server | Dynamic responses via Faker.js; supports OAS 2.0/3.0/3.1 |
| **WireMock v3.13** | Java-based mock server | Latency simulation, HTTP recording; 6M+ monthly downloads |
| **Microcks** | CNCF sandbox | Multi-protocol mocking: OpenAPI, AsyncAPI, GraphQL, gRPC |

### Onboarding Flow Best Practices

- Progressive disclosure: basic usage first, advanced patterns later
- Step-by-step with numbered instructions
- Copy-pasteable code blocks with real (test) credentials
- Expected output shown alongside each step
- Environment-specific setup (macOS, Linux, Windows, Docker)
- "What's next" linking to common use cases after quickstart

---

## 13. Language-Specific Documentation Generators

| Tool | Language | Notes |
|------|----------|-------|
| **TypeDoc v0.28** | TypeScript | Leverages TS compiler APIs; plugin system; de facto TS standard |
| **Dokka v2.2** | Kotlin | K2 analysis stable; generates HTML, Javadoc HTML, GFM, Jekyll Markdown |
| **Javadoc** (JDK 21+) | Java | Search for section headings; JShell integration; mature ecosystem |
| **Sphinx v8.2** | Python | reStructuredText-based; autodoc for Python; multiple output formats |
| **rustdoc** | Rust | Built into toolchain; doc tests (code in docs compiled and run); cargo doc |
| **pkgsite** | Go | Replaced godoc; powers pkg.go.dev; better cross-package linking |

### Documentation-in-Code Best Practices

- Write doc comments as if the reader has never seen your codebase
- Include a brief description, parameter documentation, return value, and at least one example
- Use doc tests where supported (Rust doc tests, Python doctests) — the example IS the test
- Link to related types, functions, and concepts
- Document error conditions and edge cases, not just the happy path

---

## 14. AI-Ready API Documentation

### /llms.txt Standard

A plain-text Markdown file at `/llms.txt` guiding AI models to high-value documentation resources. 844,000+ websites have implemented it as of October 2025. Adopted by Anthropic, Cloudflare, Stripe.

**Implementation:**
- Create a `/llms.txt` file listing key documentation pages with descriptions
- Include API reference, quickstart, authentication, and common patterns
- Structured for machine parsing, not human reading
- Takes ~1 hour to implement; zero downside

### MCP Server Generation

Tools like Speakeasy and Stainless can generate MCP (Model Context Protocol) servers from OpenAPI specs, exposing API documentation and operations to AI agents. This enables AI assistants to discover and interact with your API programmatically.

### Documentation for AI Agents

- Nearly half of documentation traffic now comes from AI agents (Cursor, Copilot, Claude)
- Structured content (OpenAPI specs, typed schemas) is as important as human-readable prose
- Code examples must be complete and runnable (AI agents will try to use them directly)
- Consider providing machine-readable endpoints alongside human-readable docs pages
