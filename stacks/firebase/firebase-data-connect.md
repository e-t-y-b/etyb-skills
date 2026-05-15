---
title: Firebase Data Connect
description: Managed Cloud SQL Postgres + generated, typed GraphQL clients. Firebase's first-class relational option. GA 2024-2025.
product:
  name: Firebase Data Connect
  stack: firebase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, database-architect, frontend-architect]
  authoritative_url: https://firebase.google.com/docs/data-connect
  notes: "Postgres-backed managed schema + generated GraphQL clients; GA 2024-2025; competing surface with Firestore for relational use cases."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Firebase Data Connect is Firebase's managed Cloud SQL Postgres + GraphQL-style schema + generated, typed client SDKs. GA'd in 2024-2025; materially changes the architectural choice on Firebase by adding a first-class **relational** option alongside [Firestore](/stacks/firebase/cloud-firestore/) (document) and [RTDB](/stacks/firebase/realtime-database/) (tree).

- **Backing store:** Cloud SQL Postgres, managed by Firebase
- **Schema:** GraphQL-style SDL defines tables + relationships
- **Client:** Generated, fully-typed SDKs (TS/Swift/Kotlin/etc.) that compile your queries against the schema at build time
- **Operations:** Pre-compiled — clients don't send arbitrary GraphQL strings; they call generated functions backed by precompiled, secured operations. **Closes the GraphQL security/perf hole** that pure-runtime GraphQL has.

Canonical reference: [Data Connect docs](https://firebase.google.com/docs/data-connect).

## When to use it

**Use Data Connect when:**

- You need joins across types
- You need referential integrity (FK constraints)
- You need aggregations (SUM, COUNT, GROUP BY)
- You need transactions across heterogeneous types
- You have a strong typed schema and want the client to enforce it
- You want server-controlled query shapes (no client-defined queries)

**Use [Firestore](/stacks/firebase/cloud-firestore/) when:**

- Your queries are mostly by-key or by-single-field
- Your data is naturally document-shaped, no FK semantics
- Aggregations are rare or done offline
- Transactions are within a small set of docs
- Schema is evolving; you want flexibility
- You're OK with clients composing queries

**You can mix:** Data Connect for relational core domain, Firestore for activity feeds + real-time listeners, [Storage](/stacks/firebase/firebase-storage/) for blobs. They coexist cleanly.

**Use Cloud SQL Postgres directly when:**

- Existing Postgres workload
- Custom SQL, full Postgres surface (extensions, functions, materialized views) you need outside Data Connect's exposure
- BigQuery / analytics warehouse workload (defer to GCP stack)

## 2025-2026 currency anchors

- **GA 2024-2025.** Pre-2024 references describe it as preview / private GA.
- **Schema-first + generated SDKs** is the GA shape. Operations are pre-compiled.
- **Cloud SQL Postgres** is the only backing engine; pricing per Cloud SQL.
- **Local Emulator support** in the Local Emulator Suite.
- **`@auth(level: ...)`** directive for per-operation access control.

## Patterns

### Schema example

```graphql
# schema.gql
type Movie @table {
  id: UUID! @default(expr: "uuidV4()")
  title: String!
  releaseYear: Int!
  director: User! @ref
  ratings: [Rating!]! @ref(field: "movie")
}

type Rating @table {
  movie: Movie! @ref
  user: User! @ref
  score: Int!
}

type User @table {
  id: String!
  name: String!
}
```

### Operation example

```graphql
# queries.gql
query GetMovieWithRatings($id: UUID!) @auth(level: PUBLIC) {
  movie(id: $id) {
    title
    releaseYear
    director { name }
    ratings { score user { name } }
  }
}

mutation RateMovie($movieId: UUID!, $score: Int!) @auth(level: USER) {
  rating_insert(data: { movieId: $movieId, score: $score, userId_expr: "auth.uid" })
}
```

`@auth(level: ...)` enforces Firebase Auth requirements per operation:

- `PUBLIC` — anyone
- `PUBLIC_OR_USER` — anonymous or signed in
- `USER` — must be signed in
- `USER_ANON` — anonymous user
- `USER_EMAIL_VERIFIED` — signed in + verified email
- `NO_ACCESS` — explicit deny (useful for internal-only)

Push access control into the schema layer.

### Generated client SDKs

```bash
firebase dataconnect:sdk:generate
```

Generates TypeScript, Swift, Kotlin (etc.) SDKs in your client repos. Each operation is a typed function:

```ts
const result = await getMovieWithRatings({ id: movieId });
// result is fully typed against the operation's return shape
```

### Schema migrations

`firebase deploy --only dataconnect` applies schema diffs. Migrations are diff-based; reversible operations are auto-detected, destructive ones require explicit approval.

### Local emulator

Data Connect emulator is part of the [Local Emulator Suite](/stacks/firebase/emulator-suite/) — TDD locally before deploying.

## Anti-patterns

- **Treating Data Connect as a generic Postgres** — you don't get arbitrary SQL access. Operations are pre-compiled.
- **Bypassing `@auth(level: ...)`** for "easier dev" — push auth into the schema; don't gate access only client-side.
- **Frequent destructive migrations** — irreversible changes require approval flow; plan schema evolution carefully.
- **Provisioning Cloud SQL Postgres separately** when you only need Data Connect's surface — Data Connect manages its own instance.

## Gotchas

- **Cloud SQL Postgres pricing** — not free-tier-friendly the way Firestore is. Smallest Cloud SQL instance has real monthly cost.
- **Schema migrations are diff-based** — destructive ops need explicit approval. Plan reversible-vs-destructive accordingly.
- **Generated SDKs ship into your client repo** via `firebase dataconnect:sdk:generate` — commit them.
- **No real-time listeners** the way Firestore has. Polling or external pub/sub for live updates.
- **Cross-region latency** matters — Data Connect runs in a region; client + region affects perceived latency.

## Cross-references

- [Cloud Firestore](/stacks/firebase/cloud-firestore/) — document-shaped alternative
- [Firebase Authentication](/stacks/firebase/firebase-auth/) — `@auth(level: ...)` enforces against Firebase Auth
- [App Check](/stacks/firebase/app-check/) — enforce on Data Connect endpoints
- [Local Emulator Suite](/stacks/firebase/emulator-suite/) — Data Connect emulator
- [backend-architect overlay](/stacks/firebase/backend-architect/#firebase-data-connect--the-relational-option-ga-2024-2025) — Data Connect deep dive
- Authoritative: [firebase.google.com/docs/data-connect](https://firebase.google.com/docs/data-connect)
