---
title: New Architecture (Fabric + TurboModules)
description: React Native's modern renderer + native module system. Mandatory in SDK 53+, bridgeless-only in RN 0.82+. The bridge is dead.
product:
  name: New Architecture
  stack: expo
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect]
  authoritative_url: https://reactnative.dev/docs/the-new-architecture/landing-page
  notes: "Default in SDK 51+, mandatory in SDK 53+; bridgeless-only in RN 0.82+; many older libs still being ported"
---

## What it is

The **New Architecture** is React Native's modern runtime:

- **Fabric** — the new renderer; synchronous, concurrent-mode-friendly, integrated with React 18+.
- **TurboModules** — the new native module system; lazy-loaded, JSI-backed, type-safe via codegen.
- **JSI** — JavaScript Interface; direct native ↔ JS object exposure without JSON serialization across "the bridge."
- **Bridgeless mode** — the bridge is removed entirely (RN 0.82+, mandatory in newer SDKs).

The "old architecture" was the bridge-based system from 2015-2024. It's gone. Code that targets it (e.g., `RCTBridgeModule`, `ReactContextBaseJavaModule`) doesn't run anymore.

Canonical surface: [The New Architecture](https://reactnative.dev/docs/the-new-architecture/landing-page).

## When to use

You're using it. There's no switch.

What you control:

- **Library compatibility** — every native module in your app must be NA-compatible. Most popular libs are; older ones aren't.
- **Codegen specs** — if you write a custom native component or TurboModule, you write a TS spec (`Native<X>.ts` or `<X>NativeComponent.ts`) that `expo prebuild` codegens against.

## 2025-2026 currency anchors

- **SDK 51 (mid-2024)** — NA became default for new projects; opt-out flag still existed.
- **SDK 52 (early 2025)** — opt-out removed; JSC deprecated.
- **SDK 53 (mid-2025)** — opt-out *fully* removed from Expo's surface; React 19.
- **RN 0.82 (late 2025)** — old architecture deleted from the React Native repo.
- **RN 0.85 (April 2026)** — "post-bridge era." Bridgeless mode is the only mode.
- **FlashList v2 requires NA** — v1 deprecated.
- **MMKV v4 requires NA** — Nitro Module.
- **Reanimated 4** is NA-only.
- **`react-native-svg` v15+** is NA-compatible; older versions are not.

## Patterns + anti-patterns

### Pattern: Audit dependencies for NA compatibility

```bash
npx expo-doctor
```

Flags libraries with known NA issues. Cross-check at [newarch.dev](https://newarch.dev) (RN team's directory) or each library's GitHub.

### Pattern: Replace NA-incompatible libraries

| Old | New |
|-----|-----|
| `react-native-fast-image` | [`expo-image`](/stacks/expo/expo-image/) |
| `@react-native-async-storage/async-storage` (hot paths) | `react-native-mmkv` v4 |
| `react-native-flatlist` perf issues | `@shopify/flash-list` v2 |
| `react-native-image-crop-picker` | `expo-image-picker` + `expo-image-manipulator` |
| `react-native-blob-util` | [`expo-file-system/next`](/stacks/expo/expo-file-system/) |
| `react-native-keychain` (some setups) | [`expo-secure-store`](/stacks/expo/expo-secure-store/) |
| `react-native-fs` | `expo-file-system` |
| `react-native-device-info` | `expo-device` + `expo-application` |
| `react-native-vector-icons` | `@expo/vector-icons` (bundled) or `expo-symbols` (SF Symbols on iOS) |
| `react-native-svg` < v15 | `react-native-svg` v15+ |

### Pattern: Codegen for custom native components

If you write a custom native view, you write a TS spec:

```ts
// MyComponentNativeComponent.ts
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';
import type { ViewProps } from 'react-native';

interface NativeProps extends ViewProps {
  myProp: string;
}

export default codegenNativeComponent<NativeProps>('MyComponent');
```

`expo prebuild` runs codegen, generates the native binding stubs. Errors surface there.

### Anti-pattern: Bridge-era modules

```objc
// BAD — RCTBridgeModule is dead
@interface MyModule : NSObject <RCTBridgeModule>
@end
```

Use [Expo Modules API](/stacks/expo/expo-modules/) or write a TurboModule.

### Anti-pattern: Pinning to old SDK to keep one library

If a library hasn't been updated for NA, replace it, fork it, or wrap it in an Expo Module. Don't freeze the whole app on an unsupported architecture.

## Gotchas

- **`react-native-bridge` API removed.** Anything calling `NativeModules.<X>` directly or registering an `RCTBridgeModule` is broken. Rewrite as TurboModule or Expo Module.
- **`UIManager.dispatchViewManagerCommand`** is gone. Use `commands` declared on the component spec.
- **`InteractionManager.runAfterInteractions`** is largely a no-op in concurrent mode. Use `requestIdleCallback` or `setTimeout(0)` if you need to defer.
- **Fabric clipping is stricter** — views that used to render off-screen now don't. Check `pointerEvents` and parent overflow if a custom component disappears post-layout.
- **Runtime-only NA regressions** — some libraries compile fine but crash on render. Sentry surfaces these as `TypeError: undefined is not a function` in native frames.

## Cross-references

- [Expo SDK](/stacks/expo/expo-sdk/) — NA shipped progressively across SDKs
- [Hermes](/stacks/expo/hermes/) — the JS engine that the NA depends on for JSI
- [Expo Modules API](/stacks/expo/expo-modules/) — NA-compatible module authoring
- [expo-doctor](/stacks/expo/expo-doctor/) — flags NA compat issues
- Role overlays: [mobile-architect](/stacks/expo/mobile-architect/)
- [The New Architecture](https://reactnative.dev/docs/the-new-architecture/landing-page)
- [newarch.dev](https://newarch.dev) — community NA compatibility directory
