---
title: expo-location
description: GPS + geocoding + geofencing for Expo apps. Foreground + background modes. Background mode permissions are the biggest store-review pain point.
product:
  name: expo-location
  stack: expo
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect]
  authoritative_url: https://docs.expo.dev/versions/latest/sdk/location/
  notes: "Background mode permissions are Apple/Google's biggest review pain points; foreground simple, background needs justification"
---

## What it is

**`expo-location`** is the geolocation API — current position, watching position, geocoding (address → coordinates), reverse geocoding, geofencing (regions you enter/exit). Foreground and background modes.

```ts
import * as Location from 'expo-location';

const { status } = await Location.requestForegroundPermissionsAsync();
if (status === 'granted') {
  const pos = await Location.getCurrentPositionAsync({});
  console.log(pos.coords.latitude, pos.coords.longitude);
}
```

Canonical surface: [`expo-location` reference](https://docs.expo.dev/versions/latest/sdk/location/).

## When to use

For any location need:

- One-time fix (where am I?) — `getCurrentPositionAsync`
- Continuous tracking (mapping, fitness) — `watchPositionAsync` (foreground) + `startLocationUpdatesAsync` (background via `expo-task-manager`)
- Geofencing (notify on region enter/exit) — `startGeofencingAsync`
- Geocoding — `geocodeAsync` (address → coords), `reverseGeocodeAsync` (coords → address)

## 2025-2026 currency anchors

- **Foreground + background permissions split** — `requestForegroundPermissionsAsync` then separately `requestBackgroundPermissionsAsync`. iOS requires the user to grant "Always" via Settings; the app can only request "While Using" inline.
- **`expo-task-manager` integration** required for background location — register a task name; OS calls it with batched location updates.
- **Permission strings mandatory** in app.json — `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, Android `ACCESS_FINE_LOCATION` + `ACCESS_BACKGROUND_LOCATION`.
- **iOS Privacy Manifest** (2024+) — declare the API reasons; `expo-location` adds them via its config plugin.
- **Android 14+ "approximate" vs "precise"** — user can choose; request both if you need precise.

## Patterns + anti-patterns

### Pattern: Foreground one-shot

```ts
const { status } = await Location.requestForegroundPermissionsAsync();
if (status !== 'granted') return showPermissionUI();

const pos = await Location.getCurrentPositionAsync({
  accuracy: Location.Accuracy.High,
});
```

### Pattern: Watch position (foreground)

```ts
const sub = await Location.watchPositionAsync(
  { accuracy: Location.Accuracy.Balanced, distanceInterval: 10 },
  (pos) => updateMap(pos),
);
// later
sub.remove();
```

### Pattern: Background tracking with TaskManager

```ts
import * as TaskManager from 'expo-task-manager';
import * as Location from 'expo-location';

const LOCATION_TASK = 'background-location';

TaskManager.defineTask(LOCATION_TASK, ({ data, error }) => {
  if (error) return;
  const { locations } = data;
  // Send to backend / persist
});

async function startBackground() {
  const { status } = await Location.requestBackgroundPermissionsAsync();
  if (status !== 'granted') return;

  await Location.startLocationUpdatesAsync(LOCATION_TASK, {
    accuracy: Location.Accuracy.Balanced,
    timeInterval: 60000,
    distanceInterval: 50,
    foregroundService: {
      notificationTitle: 'Tracking your run',
      notificationBody: 'Tap to return',
    },
  });
}
```

`foregroundService` is required on Android — the OS shows a persistent notification while tracking.

### Anti-pattern: Always-on background tracking

iOS and Google both review apps requesting background location heavily. "We track to improve experience" is not a justification that passes review. Track only when the user actively expects it (recording a run, ride-share driver online, etc.) and show clear UI that tracking is happening.

### Anti-pattern: Requesting Always permission inline

iOS doesn't let apps ask "Always" inline — only "While Using." For Always, request "While Using," let the user use the feature, then guide them to Settings to upgrade to Always when needed.

## Gotchas

- **Background permission is a UX cliff** — user grants foreground, then later you need background; iOS shows "Always" only via Settings.
- **Battery drain** — high-accuracy + short interval drains battery fast. Use `Balanced` accuracy + longer intervals where possible.
- **Geocoding quotas** — `geocodeAsync` calls Apple/Google services with per-app limits. Don't reverse-geocode every position update.
- **Simulator GPS** is mockable but not realistic — test on real device for drift/timing.
- **Store reviewers will ask** "why do you need background location?" — have a clear answer + UI evidence.

## Cross-references

- [Expo SDK](/stacks/expo/expo-sdk/) — bundled in the SDK
- [app.json / app.config.js](/stacks/expo/app-config/) — permission strings
- Role overlays: [mobile-architect](/stacks/expo/mobile-architect/)
- [`expo-location` reference](https://docs.expo.dev/versions/latest/sdk/location/)
