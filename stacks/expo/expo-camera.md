---
title: expo-camera
description: "Camera component with capture, recording, barcode scanning, and modern `CameraView` API. Replaces legacy `Camera`. NA-compatible. Permission UX is platform-specific."
product:
  name: expo-camera
  stack: expo
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, frontend-architect]
  authoritative_url: https://docs.expo.dev/versions/latest/sdk/camera/
  notes: "New CameraView API in SDK 51; legacy Camera deprecated; permission UX is platform-specific"
---

## What it is

**`expo-camera`** is the Expo camera component — live preview, photo capture, video recording, barcode scanning, torch, zoom, focus. The current API is `CameraView` (SDK 51+); the legacy `Camera` component is deprecated and slated for removal in a future SDK.

```tsx
import { CameraView, useCameraPermissions } from 'expo-camera';

function Scanner() {
  const [permission, requestPermission] = useCameraPermissions();
  if (!permission) return null;
  if (!permission.granted) return <RequestUI onPress={requestPermission} />;

  return (
    <CameraView
      style={{ flex: 1 }}
      facing="back"
      barcodeScannerSettings={{ barcodeTypes: ['qr', 'code128'] }}
      onBarcodeScanned={({ data }) => console.log(data)}
    />
  );
}
```

Canonical surface: [`expo-camera` reference](https://docs.expo.dev/versions/latest/sdk/camera/).

## When to use

For any camera capture in an Expo app — selfie, document scan, QR scan, video clip. Alternatives are libraries like `react-native-vision-camera` (more powerful, more complex, separate native dep); for most apps `expo-camera` is sufficient and ships with the SDK's NA compatibility guarantee.

For document OCR, ML on the camera stream, or 60fps frame processors, `react-native-vision-camera` is the right choice. For everything else, `expo-camera`.

## 2025-2026 currency anchors

- **`CameraView` (new API)** — SDK 51+; functional component, hooks-based permissions, declarative props for torch / zoom / focus.
- **Legacy `Camera`** — deprecated, still works through SDK 56. Migrate to `CameraView` for new code.
- **`useCameraPermissions()`** hook replaces older `Camera.requestPermissionsAsync()` style.
- **Built-in barcode scanning** — no separate library for QR/Code128/EAN/etc.
- **Video recording** — `recordAsync()` on a ref; supports max duration, quality presets.
- **Photo capture** — `takePictureAsync()` returns a URI usable with `expo-image-manipulator` for resize/rotate.
- **iOS Privacy Manifest** required for any camera-using app (Apple enforced 2024+); `expo-camera` ships the manifest automatically when its config plugin runs.

## Patterns + anti-patterns

### Pattern: Permission request flow

```tsx
const [permission, requestPermission] = useCameraPermissions();

if (!permission) {
  return <Loading />; // permissions still loading
}

if (!permission.granted) {
  return (
    <View>
      <Text>We need camera access to scan QR codes.</Text>
      <Button title="Grant access" onPress={requestPermission} />
      {!permission.canAskAgain && (
        <Text>Camera permission was denied. Open Settings to enable.</Text>
      )}
    </View>
  );
}

return <CameraView ... />;
```

Always explain *why* before requesting. iOS rejects on principle of "asked too early, no context."

### Pattern: Barcode scanner with throttling

```tsx
const [scanned, setScanned] = useState(false);

<CameraView
  barcodeScannerSettings={{ barcodeTypes: ['qr'] }}
  onBarcodeScanned={({ data }) => {
    if (scanned) return; // ignore subsequent scans
    setScanned(true);
    handleScan(data);
  }}
/>
```

`onBarcodeScanned` fires repeatedly while a code is in frame. Throttle or use a "scanned" gate.

### Anti-pattern: Requesting permission on app start

```tsx
// BAD — Apple will reject
useEffect(() => {
  Camera.requestPermissionsAsync();
}, []);
```

Request permission **in context** — when the user taps "Scan QR" or "Take photo," not on app start. Apple guidelines + Play Store policies both require justified prompts.

### Anti-pattern: Using legacy `Camera` for new code

```tsx
// BAD
import { Camera } from 'expo-camera';
<Camera ... />
```

Use `CameraView`. Legacy API is deprecated.

## Gotchas

- **Permission text is required** — `NSCameraUsageDescription` (iOS) and Android permissions need a *purpose* string in `app.json`. Without it, the permission prompt is rejected at runtime / submission.
- **Simulator camera is broken** — iOS simulator can't access a real camera; use a real device for camera testing.
- **Web fallback** — `CameraView` uses `getUserMedia` on web; works but has its own permission model. Test on real browsers.
- **Frame processors** — for ML-on-stream needs, `expo-camera` lacks first-class support; reach for `react-native-vision-camera`.
- **Video recording requires microphone permission too** — request both `useCameraPermissions` and `useMicrophonePermissions`.

## Cross-references

- [Expo SDK](/stacks/expo/expo-sdk/) — bundled in the SDK
- [expo-file-system](/stacks/expo/expo-file-system/) — for post-capture file handling
- [app.json / app.config.js](/stacks/expo/app-config/) — permission strings
- Role overlays: [mobile-architect](/stacks/expo/mobile-architect/), [frontend-architect](/stacks/expo/frontend-architect/)
- [`expo-camera` reference](https://docs.expo.dev/versions/latest/sdk/camera/)
