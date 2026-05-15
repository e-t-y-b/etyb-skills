---
title: Expo Modules API
description: Swift / Kotlin DSL for authoring native modules. JSI-backed. The default path for adding native APIs to Expo apps in 2026.
product:
  name: Expo Modules API
  stack: expo
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect]
  authoritative_url: https://docs.expo.dev/modules/overview/
  notes: "Swift/Kotlin module authoring; JSI-backed; consistent surface but evolves with RN architecture"
---

## What it is

**Expo Modules API** is the DSL for writing native modules in Swift (iOS) and Kotlin (Android) that expose APIs to JS. It's JSI-backed, supports async functions, events, view managers, and types defined via the DSL itself.

```swift
// iOS
public class NativeAudioModule: Module {
  public func definition() -> ModuleDefinition {
    Name("NativeAudio")
    Function("play") { (uri: String) -> Void in /* ... */ }
    AsyncFunction("getDuration") { (uri: String) -> Double in /* ... */ }
    Events("onPlaybackComplete")
  }
}
```

Canonical surface: [Expo Modules — Overview](https://docs.expo.dev/modules/overview/).

## When to use

When you need a native API not exposed by an existing Expo package, and you can't express it as a config plugin. Use cases:

- Bridging a Swift / Kotlin SDK (Sumup card reader, Adyen drop-in, specific OS APIs)
- Custom audio / video processing
- Hardware integrations (BLE peripherals beyond `expo-bluetooth`'s coverage, sensors)
- Reusing a native library that has no React Native wrapper

Three variants by use case:

| Use | Choose |
|-----|--------|
| App-specific native logic | **Local Expo Module** (in `modules/` folder, `--local` flag of `create-expo-module`) |
| Reusable OSS library | **Expo Module published to npm** (no `--local`) |
| Max performance, willing to spec types in TS | **Nitro Module** (Margelo) — codegen via `nitrogen`; used by `react-native-mmkv` v4 |

**Don't write a legacy native module.** Anything extending `RCTBridgeModule` (iOS) or `ReactContextBaseJavaModule` (Android) is bridge-era and won't work on the New Architecture.

## 2025-2026 currency anchors

- **JSI-backed, New Architecture compatible** out of the box.
- **`create-expo-module@latest --local`** scaffolds in a `modules/` folder; auto-wired via `expo-modules-autolinking`.
- **`create-expo-module@latest`** (no `--local`) scaffolds a standalone npm package.
- **TypeScript types** generated from the Swift/Kotlin DSL.
- **`appContext.reactContext`** (Android) and `Module` lifecycle (iOS) give access to the host app.
- **View managers** for native UI components (Swift `View { ... }` block).
- **Compatibility with Nitro / TurboModules** — coexist in the same app without conflict.

## Patterns + anti-patterns

### Pattern: Local module scaffold

```bash
npx create-expo-module@latest --local
# Prompts: name, platforms
```

Creates `modules/<name>/` with iOS Swift, Android Kotlin, TS surface. `npx expo prebuild` includes it automatically; EAS Build picks it up.

### Pattern: Async function with error

```swift
AsyncFunction("getDuration") { (uri: String) -> Double in
  guard let url = URL(string: uri),
        let p = try? AVAudioPlayer(contentsOf: url) else {
    throw Exception(name: "DurationError", description: "Failed to load")
  }
  return p.duration
}
```

Throws an Expo `Exception` → JS receives a typed error.

### Pattern: Events for streaming data

```swift
Events("onPlaybackComplete", "onProgress")

// later, fire event:
self.sendEvent("onProgress", [
  "currentTime": player.currentTime,
  "duration": player.duration,
])
```

```ts
// JS side
import { EventEmitter } from 'expo-modules-core';
const emitter = new EventEmitter(NativeAudioModule);
const sub = emitter.addListener('onProgress', (event) => { ... });
```

### Anti-pattern: Bridge modules

```swift
// BAD — bridge-era, won't work on NA
@objc(MyModule)
class MyModule: NSObject, RCTBridgeModule {
  static func moduleName() -> String! { "MyModule" }
}
```

Use Expo Modules DSL instead. Bridge-era APIs are dead in 2026.

### Anti-pattern: Writing a module for a one-liner

If you just need to add a key to Info.plist, write a [config plugin](/stacks/expo/app-config/) — not a module. Modules are for runtime behavior; plugins are for build-time config.

## Gotchas

- **CocoaPods + Gradle plumbing** — `npx expo prebuild` regenerates these; don't edit by hand.
- **Codegen at build time** — if you write a custom native component with a view manager, codegen runs during `expo prebuild`. Errors in the spec surface there.
- **Module names must be unique** across the app — collisions silently break loading.
- **Hot reload doesn't reload native code** — rebuild (`expo prebuild` + `eas build`) after Swift/Kotlin changes.
- **Testing native code from JS** — unit-testable via the typed wrapper; integration-test via E2E (Maestro / Detox).

## Cross-references

- [Expo SDK](/stacks/expo/expo-sdk/) — modules ship with the SDK
- [New Architecture](/stacks/expo/new-architecture/) — required runtime
- [Continuous Native Generation](/stacks/expo/continuous-native-generation/) — `expo prebuild` includes local modules
- [app.json / app.config.js](/stacks/expo/app-config/) — config plugins for build-time edits
- Role overlays: [mobile-architect](/stacks/expo/mobile-architect/)
- [Expo Modules — Overview](https://docs.expo.dev/modules/overview/)
