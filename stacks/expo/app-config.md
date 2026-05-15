---
title: app.json / app.config.js
description: "The single source of truth for an Expo app — name, bundle ID, version, permissions, plugins, splash, icons. Static (`app.json`) or dynamic (`app.config.js/ts`)."
product:
  name: app.json / app.config.js
  stack: expo
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, frontend-architect, devops-engineer]
  authoritative_url: https://docs.expo.dev/workflow/configuration/
  notes: "Schema additions per SDK; config plugin contract stable but gains hooks"
---

## What it is

**`app.json`** (static) or **`app.config.js` / `app.config.ts`** (dynamic) is the single source of truth for an Expo app. It defines:

- App identity — name, slug, version, owner
- Native bundle IDs — `ios.bundleIdentifier`, `android.package`
- Permissions — usage description strings, Android permissions
- Plugins — config plugins, native module config
- UI — icon, splash, theme colors
- Routing — `expo-router` config (typed routes, etc.)
- Web — `expo.web.output` mode, favicon
- Build — `runtimeVersion` policy, version source

`expo prebuild` reads this file to generate native projects.

Canonical surface: [Configuration with app.json / app.config.js](https://docs.expo.dev/workflow/configuration/).

## When to use

Always. Every Expo project has one. Choose the format based on whether you need dynamic config:

- **`app.json`** — static; no runtime logic. Simplest.
- **`app.config.js` / `app.config.ts`** — dynamic; can branch on env vars (e.g., `APP_VARIANT=preview` → different bundle ID).

Most non-trivial projects move to `app.config.js` for the variant pattern.

## 2025-2026 currency anchors

- **`expo.runtimeVersion.policy = "fingerprint"`** is the default for new SDK 51+ projects.
- **Typed routes plugin** — `["expo-router", { "typedRoutes": true }]` in plugins.
- **`expo-build-properties`** for build-level config (Kotlin version, iOS deployment target).
- **Privacy Manifests** (iOS 2024+) — most `expo-*` modules add them automatically via their config plugins.
- **`expo.scheme`** — your custom URL scheme; required for OAuth callbacks via custom schemes.
- **`expo.web.output`** — `"single"` (SPA, default), `"static"` (SEO surfaces), `"server"` (SSR alpha, SDK 55).

## Patterns + anti-patterns

### Pattern: Dynamic config with variants

```js
// app.config.js
const variants = {
  development: { bundleIdentifier: 'com.acme.app.dev', name: 'Acme (Dev)' },
  preview:     { bundleIdentifier: 'com.acme.app.preview', name: 'Acme (Preview)' },
  production:  { bundleIdentifier: 'com.acme.app', name: 'Acme' },
};

module.exports = ({ config }) => {
  const variant = process.env.APP_VARIANT ?? 'development';
  return { ...config, ...variants[variant] };
};
```

Pair with `eas.json` env vars per profile. Three apps coexist on a device.

### Pattern: TypeScript config

```ts
// app.config.ts
import type { ExpoConfig } from 'expo/config';

const config: ExpoConfig = {
  name: 'Acme',
  slug: 'acme',
  version: '1.0.0',
  // ...
};

export default config;
```

Gives you type-checked config + IDE autocomplete.

### Pattern: Plugin ordering

```json
"plugins": [
  "expo-router",
  ["expo-build-properties", { "ios": { "deploymentTarget": "15.1" } }],
  ["expo-notifications", { "icon": "./assets/notification-icon.png" }],
  "./plugins/with-bluetooth"
]
```

Order matters — earlier plugins run first. Use the order shown above for typical apps.

### Pattern: Local custom plugin

```json
"plugins": [
  "./plugins/with-custom-thing"
]
```

```js
// plugins/with-custom-thing.js
const { withAndroidManifest, createRunOncePlugin } = require('expo/config-plugins');
// ...
module.exports = createRunOncePlugin(withCustomThing, 'with-custom-thing', '1.0.0');
```

### Anti-pattern: Hardcoding secrets in `app.config.js`

```js
// BAD
module.exports = ({ config }) => ({
  ...config,
  extra: { apiSecret: 'sk_live_abc123' },  // 👈 ships in bundle
});
```

Secrets belong in EAS Hosting env vars or your backend — never inline in app config. The whole `extra` block is shipped to the device.

### Anti-pattern: Hand-editing `Info.plist`

If you find yourself editing native files after `expo prebuild`, you're fighting CNG. Write a config plugin instead.

## Gotchas

- **`config.extra`** is exposed to JS via `Constants.expoConfig.extra`. Anything in it is in the bundle.
- **`EXPO_PUBLIC_*` env vars** are inlined at build time into the bundle. Not secret.
- **Schema validation** — `npx expo config --type public` (or `--type prebuild`) prints the resolved config; useful for debugging plugin output.
- **`platforms`** — `["ios", "android", "web"]` by default; restrict if needed.
- **`assetBundlePatterns`** controls which assets are bundled. Default `**/*` includes everything; for size-conscious apps, narrow.
- **iOS Privacy Manifest** — each `expo-*` module that uses Apple's "required reason APIs" adds privacy declarations. Don't strip them.

## Cross-references

- [Continuous Native Generation](/stacks/expo/continuous-native-generation/) — what reads `app.json`
- [Expo CLI](/stacks/expo/expo-cli/) — `npx expo config` inspects the resolved config
- [EAS Build](/stacks/expo/eas-build/) — uses bundle ID + version
- [Expo Router](/stacks/expo/expo-router/) — typed routes plugin lives here
- Role overlays: [mobile-architect](/stacks/expo/mobile-architect/), [devops-engineer](/stacks/expo/devops-engineer/)
- [Configuration with app.json / app.config.js](https://docs.expo.dev/workflow/configuration/)
- [Config plugins reference](https://docs.expo.dev/config-plugins/introduction/)
