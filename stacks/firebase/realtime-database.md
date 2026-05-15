---
title: Realtime Database
description: The original Firebase database — JSON tree, sub-100ms fan-out, presence-friendly. Still the right call for true real-time at small payload sizes.
product:
  name: Realtime Database
  stack: firebase
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, frontend-architect, mobile-architect, real-time-architect]
  authoritative_url: https://firebase.google.com/docs/database
  notes: "Stable legacy product; still recommended for presence + sub-100ms fan-out; otherwise prefer Firestore."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Realtime Database (RTDB) is the original Firebase database — a JSON tree-shaped store with WebSocket-pushed updates, weak querying, and very fast small-payload fan-out. Predates [Cloud Firestore](/stacks/firebase/cloud-firestore/) by several years and is still actively supported but rarely the default choice for new apps.

Canonical reference: [RTDB docs](https://firebase.google.com/docs/database).

## When to use it

**Use RTDB when:**

- You need **sub-100ms fan-out to many clients** (presence, live cursor positions, chat typing indicators) and updates are tiny
- You need simple region pinning with low ops cost and your data shape is naturally a JSON tree
- The total dataset fits comfortably in RTDB's per-database limits (single-region; ~200K simultaneous connections per DB)

**Don't use RTDB when:**

- You need to query on fields other than the path (RTDB queries are weak — single child key, no compound queries)
- You need multi-document transactions
- You're building anything with rich querying needs → use [Firestore](/stacks/firebase/cloud-firestore/)

## 2025-2026 currency anchors

- RTDB is stable. There have been no major product changes; this is a maintenance-mode product.
- Rules language stable. JSON-tree-shaped, cascading from parent down.
- Still supported by all Firebase SDKs (web modular, iOS, Android, Flutter, RN).

## Patterns

### Hybrid Firestore + RTDB

Many production apps use **Firestore for canonical data** and **RTDB for ephemeral presence/typing/cursor data**. Legitimate pattern — each plays to its strength.

### RTDB rules — JSON-tree shape

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read":  "auth != null && auth.uid === $uid",
        ".write": "auth != null && auth.uid === $uid",
        "private": {
          ".read":  "auth.uid === $uid",
          ".write": "auth.uid === $uid"
        }
      }
    },
    "presence": {
      "$uid": {
        ".read":  "auth != null",
        ".write": "auth != null && auth.uid === $uid"
      }
    }
  }
}
```

RTDB rules **cascade down the tree** — a `.read: true` at a parent means everything under it is readable, regardless of stricter rules on children. Be wary of permissive parent rules.

Validate writes via `.validate` expressions:

```json
"posts": {
  "$id": {
    ".validate": "newData.hasChildren(['authorId','body']) && newData.child('body').isString() && newData.child('body').val().length <= 10000",
    "authorId": { ".validate": "newData.val() === auth.uid" }
  }
}
```

### Presence pattern

RTDB's `onDisconnect()` is the standard primitive for presence:

```ts
const presenceRef = ref(rtdb, `presence/${uid}`);
onDisconnect(presenceRef).remove();
set(presenceRef, { online: true, lastSeen: serverTimestamp() });
```

The `onDisconnect` handler fires server-side when the client's connection drops, ensuring presence flips off without the client needing to send a "goodbye" message.

## Anti-patterns

- **Using RTDB for rich querying** — you'll fight the data model. Use Firestore.
- **Permissive `.read: true` at a parent path** with the assumption that child rules will tighten — they won't. Parent rules cascade open.
- **Trusting client-asserted identity in writes** — `auth.uid` is the source of truth; `$uid` path interpolation must match it via rules.

## Gotchas

- **Single-region per database.** No multi-region replication.
- **~200K simultaneous connections per DB.** For larger apps, shard by URL or use Firestore for cold data.
- **Queries are single-child-key.** No compound queries. No vector search. No real query plans.
- **Listeners count.** Each `onValue` listener is a live connection contribution; clean up.
- **Rules cascade open at parent.** Granular path-level rules don't override a permissive parent.

## Cross-references

- [Cloud Firestore](/stacks/firebase/cloud-firestore/) — the modern document sibling
- [Security Rules](/stacks/firebase/security-rules/) — RTDB rules language
- [Cloud Functions for Firebase](/stacks/firebase/cloud-functions-firebase/) — RTDB triggers (`onValueWritten`, `onValueCreated`, etc.)
- Authoritative: [firebase.google.com/docs/database](https://firebase.google.com/docs/database)
