---
title: Cloud Messaging (FCM)
description: Push notifications for iOS, Android, and web — HTTP v1 API, notification vs data messages, APNs auth keys, topic subscriptions.
product:
  name: Cloud Messaging (FCM)
  stack: firebase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, backend-architect, security-engineer]
  authoritative_url: https://firebase.google.com/docs/cloud-messaging
  notes: "Legacy HTTP/XMPP server APIs deprecated; HTTP v1 + Admin SDK only; APNs auth key rotation discipline matters."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Firebase Cloud Messaging (FCM) is the cross-platform push notification service. It abstracts **APNs** (Apple) and **Android's push transport** behind one API. Sending: server → FCM → APNs/Android → device. Receiving: device → FCM SDK handler.

Canonical reference: [FCM docs](https://firebase.google.com/docs/cloud-messaging).

## When to use it

**Use FCM directly when:**

- You need push to iOS + Android + web from one API
- Your sending volume is moderate and you can write the segmentation logic
- You're cost-sensitive (FCM is free)

**Use OneSignal / Airship / Pusher / Braze on top of FCM/APNs when:**

- Marketing-led "send 8 push variants with conversion attribution" workflows
- In-app messaging + push in one product
- Smarter delivery scheduling, automations, UI for non-engineers

The layered services *use* FCM/APNs under the hood — you pay one vendor + cost for the targeting UI.

## 2025-2026 currency anchors

- **FCM legacy server APIs are deprecated.** `fcm.googleapis.com/fcm/send` and the XMPP server API are gone. Code referencing "Server Key" headers in cleartext is legacy.
- **HTTP v1 API only**, OAuth-scoped service account credentials. Use the Admin SDK (`getMessaging().send(...)`) for the easiest path.
- **APNs auth keys (`.p8`)** are the modern auth method. Old "APNs certificates" still work but expire annually — migrate to auth keys.

## Two message types — get this right

| Type | Body shape | Behavior when app is in background |
|------|------------|-------------------------------------|
| **Notification** | `notification: { title, body, ... }` | OS displays the notification automatically; your `onMessage` handler does NOT fire. |
| **Data** | `data: { custom: "fields" }` | OS does NOT display anything; your `onMessage` handler fires (iOS: requires `content-available: true`). |
| **Combined** | Both `notification` + `data` | OS displays notification AND handler fires (sort of — depends on platform). |

**The most common FCM bug:** "Why doesn't my onMessage fire when the app is backgrounded?" Cause: you sent a notification-only message. The OS rendered the notification; your code never ran. Fix: send a data message (or both), handle display yourself if needed.

## Patterns

### Sending via Admin SDK

```ts
import { getMessaging } from "firebase-admin/messaging";

await getMessaging().send({
  token: deviceToken,
  notification: { title: "Hello", body: "World" },
  android: { priority: "high", notification: { channelId: "default" } },
  apns: {
    headers: { "apns-priority": "10" },
    payload: { aps: { alert: { title: "Hello", body: "World" }, sound: "default" } }
  }
});
```

In Cloud Functions, the Admin SDK handles auth automatically.

### Sending via HTTP v1 directly

```bash
curl -X POST https://fcm.googleapis.com/v1/projects/PROJECT_ID/messages:send \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "message": { ... } }'
```

OAuth access token comes from your service account. Don't ship server-account JSON in client builds; mint tokens on a backend.

### iOS-specific config

- **APNs token registration must complete before FCM can deliver.** `Messaging.messaging().delegate = self` and call `UIApplication.shared.registerForRemoteNotifications()` early.
- **APNs auth key (`.p8`)** uploaded once to Firebase Console (Cloud Messaging tab); covers all apps in the team.
- **`content-available: true`** for silent/background data messages. iOS rate-limits aggressively (a few per hour per app); FCM won't queue indefinitely.
- **`mutable-content: true`** if you want a Notification Service Extension to modify the payload (e.g., download an image).
- **`apns-priority: 10`** for user-visible; `apns-priority: 5` for background data. Wrong priority → iOS throttles your push.

### Android-specific config

- **Notification channels** (Android 8+) are required for displayed notifications. Create channels at app start; assign each notification to a channel. Without a channel, the notification is silently dropped.
- **POST_NOTIFICATIONS permission** is required on Android 13+. Runtime permission request; without it, notifications don't display.
- **Background work** — if your data message handler does meaningful work, run it via `WorkManager`, not directly in the FCM callback. FCM gives ~10 seconds before the OS may terminate the process.
- **Doze mode** can delay non-`high-priority` messages indefinitely. Set `priority: high` for user-facing notifications.

### Topic subscriptions

```kotlin
Firebase.messaging.subscribeToTopic("news-en-us")
```

```ts
await getMessaging().send({ topic: "news-en-us", notification: {...} });
```

Great for "all users opted into category X." Limitations: topic sends are best-effort, not guaranteed delivery; subscription propagation can take minutes. For one-to-one critical messages, send to device tokens directly.

### Token management

Device tokens are not stable forever — they rotate on app reinstall, app data clear, or OS decision. Every app should:

1. Listen for token refresh events
2. Send the new token to your backend, keyed to the current Firebase Auth UID
3. Periodically (e.g., on app start) re-sync the token to handle missed refresh events

Stale tokens cause "we sent the push, the user never saw it" bugs. FCM returns `UNREGISTERED` or `INVALID_ARGUMENT` for stale tokens — clean them up in your DB when you see those error codes.

## Anti-patterns

- **Code referencing FCM legacy server keys / `fcm.googleapis.com/fcm/send`** — broken or about to be.
- **Notification-only message sent expecting `onMessage` to fire when backgrounded** — won't fire. Use data or combined.
- **Forgetting Android notification channels** — silently dropped on Android 8+.
- **Forgetting POST_NOTIFICATIONS permission on Android 13+** — silently dropped.
- **Topic subscription from the client without rate limits** — if the app binary leaks, bots can subscribe. Gate sensitive topics via an authenticated server call.
- **Not cleaning up stale tokens** — wasted send attempts; cost adds up.
- **APNs certificates instead of auth keys** — annual rotation, more failure surface.

## Gotchas

- **APNs auth key (`.p8`) is team-wide** — uploading to Firebase covers all apps in your Apple Developer team.
- **Topic subscription propagation** takes minutes; don't expect immediate delivery after subscribing.
- **iOS silent push rate limits** — a few per hour per app. Don't use background data messages for high-frequency signaling.
- **APNs auth key compromise** = total push compromise for your team. Rotate annually as standard practice and immediately on leak.
- **FCM tokens differ from APNs device tokens** — FCM tokens abstract over both. Your backend stores FCM tokens.

## Cross-references

- [App Check](/stacks/firebase/app-check/) — enforce on FCM token registration to prevent spam token creation
- [Cloud Functions for Firebase](/stacks/firebase/cloud-functions-firebase/) — server-side sending via Admin SDK
- [mobile-architect overlay](/stacks/firebase/mobile-architect/#firebase-cloud-messaging-fcm) — full mobile FCM playbook
- Authoritative: [firebase.google.com/docs/cloud-messaging](https://firebase.google.com/docs/cloud-messaging)
