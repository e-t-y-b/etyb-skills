---
title: Hermes
description: "Default and only JavaScript engine for React Native in 2026. Bytecode compilation, JSI, WASM-stable. `jsEngine: 'jsc'` is dead."
product:
  name: Hermes
  stack: expo
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect]
  authoritative_url: https://hermesengine.dev/
  notes: "Default and only JS engine in SDK 52+; JSC removed; Hermes V1 default in RN 0.84+"
---

## What it is

**Hermes** is the JavaScript engine for React Native, developed by Meta. It compiles JS to bytecode at build time (faster cold start, smaller bundles), implements **JSI** (JavaScript Interface) for direct native ↔ JS object exposure without JSON serialization, and supports WASM.

In 2026, Hermes is the *only* JS engine for RN — JavaScriptCore (JSC) was removed from the React Native repo. `jsEngine: 'jsc'` in `app.json` is a no-op (or warning in older SDKs).

Canonical surface: [hermesengine.dev](https://hermesengine.dev/).

## When to use

You're using it. There's no choice in 2026.

What you actually control:

- **React Compiler** — opt-in via `babel-plugin-react-compiler`. Speeds up renders by auto-memoizing. Most apps see +5–15% in heavy-render scenarios. Not enabled by default in Expo.
- **`babel-plugin-transform-remove-console`** — strip `console.log` from release builds. Hermes still ships the call; the plugin removes it at build time.
- **Worklets** — `react-native-reanimated` runs functions on a separate Hermes runtime on the UI thread. Different rules apply.

## 2025-2026 currency anchors

- **SDK 52+** — JSC removed, Hermes mandatory.
- **Hermes V1** (default in RN 0.84+) — 30% lower memory than previous Hermes; bytecode pre-compilation cuts cold starts by 10–15% TTI.
- **WASM in Hermes V1** is stable — groundwork for on-device AI inference; not many apps use this yet.
- **Multi-CDP debugging** (RN 0.85) — multiple simultaneous Chrome DevTools / VS Code / AI-agent connections.
- **JSI** is how MMKV, Nitro modules, and the New Architecture get speed — direct native object exposure.

## Patterns + anti-patterns

### Pattern: Strip console in release

```js
// babel.config.js
module.exports = function (api) {
  api.cache(true);
  return {
    presets: ['babel-preset-expo'],
    env: {
      production: { plugins: ['transform-remove-console'] },
    },
  };
};
```

`console.log` left in production allocates objects per call. Strip them.

### Pattern: React Compiler (opt-in)

```js
// babel.config.js
plugins: [['babel-plugin-react-compiler', { /* opts */ }]];
```

Auto-memoizes components and hooks. Test thoroughly — most apps benefit; some are sensitive to memoization side effects.

### Anti-pattern: `jsEngine: 'jsc'`

```json
// BAD (dead config)
"jsEngine": "jsc"
```

No-op since SDK 52. Remove it.

### Anti-pattern: Capturing non-serializable refs in worklets

```ts
const ref = useRef(...);

const fn = useAnimatedStyle(() => {
  ref.current.method();  // 👈 crashes — UI thread can't see ref
});
```

Worklets run in a separate Hermes runtime on the UI thread. Use `runOnJS(fn)(args)` to bounce back to the JS thread for ref/native-module access.

## Gotchas

- **`console.log` from worklets** doesn't work normally — use `console.log.call(globalThis, ...)` or a worklet-safe logger.
- **`global` is the JSI root** — native code can attach values that JS sees synchronously. Useful for Nitro / Expo Modules / MMKV.
- **Debugger** — React Native DevTools (Chrome DevTools frontend) connects via CDP. Multi-connection mode in RN 0.85+ lets DevTools + VS Code + agents share the session.
- **Bytecode is platform-specific** — iOS bytecode != Android bytecode. EAS Build handles this; if you ever ship bundles manually, build per platform.
- **Sourcemaps** — Hermes bytecode in Sentry is unreadable without sourcemaps. Upload via `sentry-expo-upload-sourcemaps` post-build.

## Cross-references

- [Expo SDK](/stacks/expo/expo-sdk/) — Hermes ships with the SDK
- [New Architecture](/stacks/expo/new-architecture/) — JSI is the foundation
- Role overlays: [mobile-architect](/stacks/expo/mobile-architect/)
- [hermesengine.dev](https://hermesengine.dev/)
- [React Native — Hermes](https://reactnative.dev/docs/hermes)
