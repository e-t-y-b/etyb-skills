---
title: Firebase CLI
description: The canonical command-line surface for Firebase — init, deploy, emulators, secrets, App Hosting, Data Connect, Extensions, App Check, Crashlytics symbol upload.
product:
  name: Firebase CLI
  stack: firebase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, frontend-architect, mobile-architect, devops-engineer]
  authoritative_url: https://firebase.google.com/docs/cli
  notes: "Active development; Data Connect + App Hosting + Studio commands all added 2024-2025."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

The Firebase CLI (`firebase` command) is the canonical surface for Firebase project management, deploy, and tooling. It wraps Firebase + Cloud APIs into a developer-friendly command set: `firebase init`, `firebase deploy`, `firebase emulators:start`, `firebase functions:secrets:set`, and many more.

Canonical reference: [Firebase CLI reference](https://firebase.google.com/docs/cli).

## When to use it

**Use the Firebase CLI for:**

- Project init (`firebase init`)
- Local development (`firebase emulators:start`, `firebase emulators:exec`)
- Deployment of every Firebase surface (`firebase deploy --only ...`)
- Secrets management (`firebase functions:secrets:set`)
- Hosting preview channels (`firebase hosting:channel:deploy`)
- App Distribution uploads (`firebase appdistribution:distribute`)
- Crashlytics symbol uploads (`firebase crashlytics:symbols:upload`)
- Extensions install/update (`firebase ext:install`)

**Use `gcloud` directly for:**

- IAM, VPC, Cloud Run direct config, BigQuery, Pub/Sub topics outside Firebase's slice — those live in the GCP CLI.

## 2025-2026 currency anchors

- **Data Connect commands** added 2024-2025 (`firebase deploy --only dataconnect`, `firebase dataconnect:sdk:generate`).
- **App Hosting commands** added 2024 (`firebase init apphosting`).
- **Firebase Studio integration** — the CLI runs in Firebase Studio with the workspace's service account.
- **`firebase login:ci`** still mints CI tokens but **Workload Identity Federation** is the preferred CI auth path for new pipelines.
- **`firebase functions:config:*`** (legacy runtime config) is deprecated in favor of `defineSecret` + `defineString` parameterized config.

## Common commands

### Init / setup

```bash
firebase login
firebase init                       # interactive project + features setup
firebase init apphosting            # App Hosting-specific init
firebase use --add                  # bind aliases like dev/stage/prod to project IDs
```

### Deploy

```bash
firebase deploy                                     # everything
firebase deploy --only hosting                      # static site
firebase deploy --only functions                    # all functions
firebase deploy --only functions:myFunction         # one function (canary)
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only storage                      # storage rules
firebase deploy --only dataconnect                  # Data Connect schema
firebase deploy --only apphosting                   # App Hosting (also via GitHub push)
```

### Emulators

```bash
firebase emulators:start
firebase emulators:exec "npm test"
firebase emulators:start --only auth,firestore,functions
```

`firebase.json` configures emulator ports — see [Local Emulator Suite](/stacks/firebase/emulator-suite/).

### Secrets

```bash
firebase functions:secrets:set STRIPE_KEY
firebase functions:secrets:access STRIPE_KEY
firebase functions:secrets:destroy STRIPE_KEY
firebase functions:secrets:prune
```

### Hosting preview channels

```bash
firebase hosting:channel:deploy preview-pr-42 --expires 7d
firebase hosting:channel:list
firebase hosting:channel:delete preview-pr-42
```

### App Distribution

```bash
firebase appdistribution:distribute path/to/app.aab \
  --app=APP_ID --groups=qa,beta --release-notes="Fix login bug"
```

### Crashlytics symbols

```bash
firebase crashlytics:symbols:upload --app=APP_ID path/to/dsyms
```

### Extensions

```bash
firebase ext:install firebase/firestore-bigquery-export
firebase ext:list
firebase ext:update extension-id
firebase ext:uninstall extension-id
```

### Project aliases

```bash
firebase use dev
firebase use prod
firebase deploy --project prod    # one-off override
```

## Patterns

### CI deploy via Workload Identity Federation

```yaml
- uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: projects/123/locations/global/workloadIdentityPools/gh-pool/providers/gh
    service_account: deploy@my-project.iam.gserviceaccount.com
- run: firebase deploy --only functions
```

No long-lived `FIREBASE_TOKEN` in repo secrets. The Google Cloud federation trusts GitHub's OIDC tokens; the binding maps your workflow to a service account with deploy permissions.

### Multi-environment with aliases

```bash
firebase use --add    # alias dev → my-project-dev
firebase use --add    # alias prod → my-project-prod
firebase use dev
firebase deploy
firebase use prod
firebase deploy --only functions
```

Per-environment `.firebaserc` keeps the aliases.

## Anti-patterns

- **`firebase deploy` from a developer laptop to production** — no CI gating. Use CI with WIF.
- **`FIREBASE_TOKEN` (from `firebase login:ci`) in repo secrets** — long-lived; broad scope. Migrate to WIF.
- **`firebase functions:config:set`** — deprecated. Use `defineSecret` / `defineString`.
- **Service account JSON in repo** — never. Use Secret Manager / WIF.
- **`firebase deploy` without `--only`** in CI when you only changed one surface — slow + risk of unintended changes.
- **Deploy to the same project from dev laptops and CI** — race conditions, opaque state. Separate `dev`/`stage`/`prod` projects.

## Gotchas

- **`firebase login:ci` token is long-lived** — rotate on staff churn.
- **`firebase.json` is authoritative** for hosting / emulator config — keep it in source control.
- **`.firebaserc` holds project aliases** — also source-controlled (no secrets in it).
- **CLI versions matter** — new commands (Data Connect, App Hosting) require recent CLI versions. Pin in CI.
- **Cloud Build is used for App Hosting deploys** — the Firebase CLI triggers Cloud Build; runtime logs separate from Cloud Functions logs.
- **`firebase ext:update`** doesn't auto-update — opt-in.

## Cross-references

- [Local Emulator Suite](/stacks/firebase/emulator-suite/) — emulator commands
- [Firebase Hosting](/stacks/firebase/firebase-hosting/) — `firebase deploy --only hosting`
- [Firebase App Hosting](/stacks/firebase/firebase-app-hosting/) — `firebase init apphosting`
- [Cloud Functions for Firebase](/stacks/firebase/cloud-functions-firebase/) — secrets + functions deploy
- [Firebase Data Connect](/stacks/firebase/firebase-data-connect/) — schema deploy + SDK generation
- [App Distribution](/stacks/firebase/app-distribution/) — distribute uploads
- [Crashlytics](/stacks/firebase/crashlytics/) — symbol uploads
- Authoritative: [firebase.google.com/docs/cli](https://firebase.google.com/docs/cli)
