---
title: Security Rules
description: "Declarative access control for Firestore, Realtime Database, Cloud Storage — deny-by-default discipline, `request.auth` checks, rules unit testing via emulator."
product:
  name: Security Rules
  stack: firebase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [security-engineer, backend-architect, frontend-architect, mobile-architect]
  authoritative_url: https://firebase.google.com/docs/rules
  notes: "Firestore + RTDB + Storage rules; rules unit testing via emulator; deny-by-default discipline non-negotiable."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Firebase Security Rules are a purpose-built declarative language for access control on client-facing Firebase data stores: **[Cloud Firestore](/stacks/firebase/cloud-firestore/)**, **[Realtime Database](/stacks/firebase/realtime-database/)**, and **[Cloud Storage for Firebase](/stacks/firebase/firebase-storage/)**. Rules are evaluated server-side on every read and write originating from a Firebase client SDK. First-class concepts: `request.auth`, `resource`, `request.resource`, `request.app`, `request.time`, and helper functions.

Canonical reference: [Security Rules docs](https://firebase.google.com/docs/rules).

## When to use it

**Use Security Rules for:**

- Every Firestore collection, every RTDB path, every Storage bucket — there is no path that legitimately needs zero rules
- Enforcing ownership, role-based access, App Check requirements
- Validating write shape (size limits, content type, required fields)

**Do NOT rely on Security Rules for:**

- **Business logic** that the rules language can't express cleanly — move it to a callable Cloud Function
- **Secrecy** — rules are public; anyone with your project ID can fetch them
- **Rate limiting** — that's an [App Check](/stacks/firebase/app-check/) job
- **Complex authorization graphs** that require multiple cross-collection reads — those run out of rule-eval budget

## Universal principles

1. **Deny by default.** Every rules file ends with `match /{document=**} { allow read, write: if false; }`.
2. **Rules are public.** Treat them as enforcement, not secrecy.
3. **Check `request.auth` on every read and write** unless the path is genuinely public.
4. **Check `request.app != null`** to require App Check tokens on every privileged path.
5. **Validate `request.resource.data`** on writes — shape, types, max sizes, no surprise fields.
6. **Use `get()` and `exists()` sparingly** — each rule-eval read costs a Firestore read and can chain unexpectedly. Cap at 10 per rule.
7. **Unit-test every rule** with `@firebase/rules-unit-testing` against the emulator. Ship rules tests with every rule change.

## Patterns

### Firestore rules — production-quality example

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isSignedIn() { return request.auth != null; }
    function isOwner(userId) { return isSignedIn() && request.auth.uid == userId; }
    function hasRole(role) { return isSignedIn() && request.auth.token.role == role; }
    function appCheckPassed() { return request.app != null; }

    match /users/{userId} {
      allow read: if appCheckPassed() && (isOwner(userId) || hasRole('admin'));
      allow create: if appCheckPassed() && isOwner(userId)
                    && request.resource.data.keys().hasOnly(['email','displayName','createdAt']);
      allow update: if appCheckPassed() && isOwner(userId)
                    && request.resource.data.diff(resource.data).affectedKeys()
                       .hasOnly(['displayName']);
      allow delete: if appCheckPassed() && hasRole('admin');
    }

    match /posts/{postId} {
      allow read: if appCheckPassed();
      allow create: if appCheckPassed() && isSignedIn()
                    && request.resource.data.authorId == request.auth.uid
                    && request.resource.data.body is string
                    && request.resource.data.body.size() <= 10000;
      allow update, delete: if appCheckPassed()
                            && (resource.data.authorId == request.auth.uid
                                || hasRole('moderator'));
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

Notes:

- **`request.auth.token.role`** — custom claim set server-side via `getAuth().setCustomUserClaims(uid, { role: 'admin' })`. The claim is in the ID token; rules see it natively.
- **`diff().affectedKeys().hasOnly(...)`** — locks down which fields can change on update. Without it, a user can stuff a `role: 'admin'` claim into their own doc.
- **`hasOnly([...])`** on create blocks unexpected fields.
- **App Check check appears on every match** — repetitive but worth it. Wrap in a helper.

### Storage rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read:  if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
    }

    match /{path=**} {
      allow read, write: if false;
    }
  }
}
```

**Always size-bound uploads.** Without a size cap, a client can upload 10 GB. **Always content-type-validate** for type-specific apps.

### RTDB rules — JSON tree shape

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read":  "auth != null && auth.uid === $uid",
        ".write": "auth != null && auth.uid === $uid"
      }
    }
  }
}
```

RTDB rules **cascade down** — a `.read: true` at a parent opens everything beneath. Validate writes via `.validate` expressions.

### Rules unit testing

```ts
import { initializeTestEnvironment, assertSucceeds, assertFails } from "@firebase/rules-unit-testing";

const env = await initializeTestEnvironment({
  projectId: "demo",
  firestore: { rules: readFileSync("firestore.rules", "utf8") },
});

const alice = env.authenticatedContext("alice").firestore();
const mallory = env.unauthenticatedContext().firestore();

await assertSucceeds(setDoc(doc(alice, "users/alice"), { email: "alice@x.com", displayName: "Alice", createdAt: new Date() }));
await assertFails(setDoc(doc(mallory, "users/alice"), { /* ... */ }));
```

Run rules tests in CI on every PR that touches `firestore.rules` / `storage.rules` / `database.rules.json`. Cover positive and negative cases for every `match` block.

## Anti-patterns

| Anti-pattern | What's wrong | Fix |
|--------------|--------------|-----|
| `allow read, write: if request.auth != null` | Any authenticated user can read/write everything | Scope by ownership / role / collection semantics |
| `allow read: if true` on a sensitive collection | World-readable | Authentication + authorization gates |
| Enforcing arbitrary business logic in rules | Rules language can't do it; rules become unmaintainable | Move logic to a callable Cloud Function |
| Trusting client-supplied `request.resource.data.userId` | Client lies | Use `request.auth.uid` for the writer's identity |
| Unbounded `get()` chains in rules | Hidden cost; rules limit kicks in | Refactor to denormalize or move to a callable function |
| No rules tests | Rules drift silently | `@firebase/rules-unit-testing` for every collection |
| Permissive RTDB parent rule, restrictive children | Parent cascades open | Tighten parents |

## Gotchas

- **Rules are public.** Anyone with your project ID can fetch them. Treat as enforcement, not secrecy.
- **Direct console edits to "fix prod"** can permanently widen access — there's no "compare with main" in the console. Force all changes through PR.
- **`get()` / `exists()` costs Firestore reads** — and the rules engine caps at ~10 per evaluation.
- **`request.auth.token.<claim>` reflects ID token state** — claim changes are seen only after token refresh.
- **`request.app.app_check_token.replay_protected`** — set when the client minted a single-use token. Check in rules for sensitive operations.
- **RTDB rules cascade open at parent paths** — granular child rules can't override a permissive parent.

## Cross-references

- [Firebase Authentication](/stacks/firebase/firebase-auth/) — `request.auth` and custom claims
- [App Check](/stacks/firebase/app-check/) — `request.app` checks
- [Cloud Firestore](/stacks/firebase/cloud-firestore/) — Firestore rules language
- [Realtime Database](/stacks/firebase/realtime-database/) — RTDB rules language
- [Cloud Storage for Firebase](/stacks/firebase/firebase-storage/) — Storage rules language
- [Local Emulator Suite](/stacks/firebase/emulator-suite/) — `@firebase/rules-unit-testing` integration
- [security-engineer overlay](/stacks/firebase/security-engineer/#security-rules--the-discipline) — full rules playbook
- Authoritative: [firebase.google.com/docs/rules](https://firebase.google.com/docs/rules)
