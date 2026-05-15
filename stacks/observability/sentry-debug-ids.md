---
title: Sentry Debug IDs (Source Maps)
description: Modern source-map workflow — Debug IDs embed in artifacts and match by ID, not by release name. Mandatory for 2026 builds.
product:
  name: Sentry Debug IDs
  stack: observability
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, devops-engineer]
  authoritative_url: https://docs.sentry.io/platforms/javascript/sourcemaps/
  notes: "Debug IDs mandatory for modern builds; legacy release-name path deprecated 2024; sentry-cli sourcemaps inject is the canonical command."
---

## What it is

Sentry Debug IDs are the modern source-map workflow. `sentry-cli sourcemaps inject` adds a Debug ID (UUID-like) to each JS file + source map. Sentry matches stack trace frames by Debug ID, not by release name. See [docs.sentry.io/platforms/javascript/sourcemaps](https://docs.sentry.io/platforms/javascript/sourcemaps/).

**Critical: the legacy "release name → source maps" association is deprecated.** Legacy `sentry-cli releases files upload-sourcemaps` patterns produce silently broken stack traces in 2026 builds.

## When to use

**Always**, for any browser/Node app shipping to Sentry. Debug IDs are mandatory for production-grade error tracking in 2026.

## 2025-2026 currency anchors

- **Debug IDs are the only supported path** for new installs.
- **`sentry-cli sourcemaps inject`** is the canonical command — runs after build, adds IDs.
- **`sentry-cli sourcemaps upload`** uploads both JS + maps.

## Patterns

```bash
# Production build pipeline
npm run build
npx sentry-cli sourcemaps inject ./dist
npx sentry-cli sourcemaps upload --release="$SERVICE_VERSION" ./dist
```

## Anti-patterns

- **Legacy `sentry-cli releases files upload-sourcemaps`** — produces broken stack traces. Migrate.
- **Uploading source maps without injecting Debug IDs first** — frames don't match.
- **Uploading server source maps to public Sentry** — verifying only client maps uploaded matters for security.

## Gotchas

- **CI environment must have `sentry-cli` available** — Docker images differ.
- **`--no-upload-source-maps` for server-only builds** — prevent server code exposure.
- **Bundle tools (Vite, webpack, esbuild)** have Sentry plugins — use them where possible.

## Cross-references

- [Sentry Errors](/stacks/observability/sentry-errors/)
- Source maps security (server vs client) → [security-engineer overlay](/stacks/observability/security-engineer/)
- Authoritative: [docs.sentry.io/platforms/javascript/sourcemaps](https://docs.sentry.io/platforms/javascript/sourcemaps/)
