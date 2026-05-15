---
title: expo-notifications
description: Local + remote push notifications via Expo Push (or direct FCM/APNs). FCMv1-only since 2024. Android channels required; iOS foreground handler shape changed.
product:
  name: expo-notifications
  stack: expo
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, devops-engineer]
  authoritative_url: https://docs.expo.dev/versions/latest/sdk/notifications/
  notes: "FCMv1 mandatory; Android channels required; iOS foreground handler shape changed (shouldShowBanner/List); APNs token auth required"
---

## What it is

**`expo-notifications`** is the Expo push + local notification API. It wraps FCM (Android) + APNs (iOS), provides local scheduling, foreground handlers, notification categories with actions, and integrates with the **Expo Push Service** — a free relay that lets you send to one Expo push token instead of managing FCM + APNs APIs directly.

```ts
import * as Notifications from 'expo-notifications';

// Get token
const token = (await Notifications.getExpoPushTokenAsync({ projectId })).data;
// → "ExponentPushToken[xxxxxxxx]"

// Send (server-side, not from app)
await fetch('https://exp.host/--/api/v2/push/send', {
  method: 'POST',
  body: JSON.stringify({ to: token, title: 'Hello', body: 'World' }),
});
```

Canonical surface: [`expo-notifications` reference](https://docs.expo.dev/versions/latest/sdk/notifications/) + [Push Notifications overview](https://docs.expo.dev/push-notifications/overview/).

## When to use

For any app needing push notifications. Two paths:

1. **Expo Push (recommended)** — one API, one credential set, batched up to 100 per request. Free.
2. **Direct FCM + APNs** — if you have existing infrastructure, Firebase templating, or regulatory reasons (some governments restrict transit through 3rd parties).

For local notifications (in-app scheduled reminders), `expo-notifications` is the only first-party option.

## 2025-2026 currency anchors

- **FCMv1 mandatory since June 2024** — legacy FCM HTTP API turned off. Re-download `google-services.json` from Firebase Console for pre-2024 projects.
- **APNs token auth required** — certificate auth deprecated. Use `.p8` key + key ID + team ID.
- **Foreground handler shape change** — `shouldShowAlert` deprecated; use `shouldShowBanner` + `shouldShowList`:

  ```ts
  Notifications.setNotificationHandler({
    handleNotification: async () => ({
      shouldShowBanner: true,
      shouldShowList: true,
      shouldPlaySound: true,
      shouldSetBadge: false,
    }),
  });
  ```
- **Android 13+ runtime permission** for `POST_NOTIFICATIONS` — `expo-notifications` handles via `requestPermissionsAsync()`.
- **Expo Push tokens stable across reinstalls** *only if* the user reinstalls without uninstalling. True uninstall invalidates the underlying APNs/FCM token.

## Patterns + anti-patterns

### Pattern: Registration flow

```ts
import * as Notifications from 'expo-notifications';
import * as Device from 'expo-device';

async function registerForPush() {
  if (!Device.isDevice) return null;

  const { status: existing } = await Notifications.getPermissionsAsync();
  let status = existing;
  if (status !== 'granted') {
    const { status: req } = await Notifications.requestPermissionsAsync();
    status = req;
  }
  if (status !== 'granted') return null;

  const token = (
    await Notifications.getExpoPushTokenAsync({
      projectId: process.env.EXPO_PUBLIC_EAS_PROJECT_ID,
    })
  ).data;
  return token;
}
```

POST the token to your backend; store per-user.

### Pattern: Sending from your server

```ts
await fetch('https://exp.host/--/api/v2/push/send', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    to: token,
    title: 'New message',
    body: 'Alice sent you a message',
    data: { conversationId: 'c123' },
    sound: 'default',
    badge: 1,
    channelId: 'messages', // Android
  }),
});
```

Batch up to 100 per request.

### Pattern: Tap handler

```ts
useEffect(() => {
  const sub = Notifications.addNotificationResponseReceivedListener((response) => {
    const { conversationId } = response.notification.request.content.data;
    router.push(`/chat/${conversationId}`);
  });
  return () => sub.remove();
}, []);

// Plus: cold-start launch
useEffect(() => {
  Notifications.getLastNotificationResponseAsync().then((response) => {
    if (response) {
      // App was launched from notification; route
    }
  });
}, []);
```

### Pattern: Android channels

```ts
await Notifications.setNotificationChannelAsync('messages', {
  name: 'Messages',
  importance: Notifications.AndroidImportance.HIGH,
  sound: 'default',
  vibrationPattern: [0, 250, 250, 250],
});
```

Required on Android 8+ for sound/vibration/heads-up display.

### Anti-pattern: Testing on simulator

```ts
// Doesn't work — simulators don't get push
```

Use a real device. Apple's simulators don't deliver push; Android emulators with Play Services *can* receive but real devices are the truth.

### Anti-pattern: Relying on `shouldShowAlert`

```ts
// BAD (deprecated)
{ shouldShowAlert: true }
```

Use `shouldShowBanner` + `shouldShowList` (iOS 14+ semantics). Older code may still work but warns.

## Gotchas

- **Push to simulator/emulator silently fails** — always test on real devices.
- **Token rotation** on uninstall+reinstall — always re-register on app start, don't trust cached tokens.
- **Silent push throttling** — Apple aggressively rate-limits `_contentAvailable: true` notifications. Don't blast them.
- **`google-services.json` rotation** — if you inherited a pre-2024 project, re-download from Firebase Console and update EAS credentials.
- **Categories / action buttons** require `setNotificationCategoryAsync()` at app start.
- **Foreground handler** — iOS by default doesn't display notifications while the app is foregrounded. Set the handler before any notification arrives.

## Cross-references

- [Expo SDK](/stacks/expo/expo-sdk/) — bundled in the SDK
- [app.json / app.config.js](/stacks/expo/app-config/) — `expo-notifications` plugin for icon/color/sounds
- [Custom Dev Clients](/stacks/expo/custom-dev-clients/) — push requires a real build, not Expo Go
- [EAS Build](/stacks/expo/eas-build/) — manages FCM/APNs credentials
- Role overlays: [mobile-architect](/stacks/expo/mobile-architect/), [devops-engineer](/stacks/expo/devops-engineer/)
- [`expo-notifications` reference](https://docs.expo.dev/versions/latest/sdk/notifications/)
- [Push Notifications overview](https://docs.expo.dev/push-notifications/overview/)
