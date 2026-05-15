---
title: Metro Bundler
description: "React Native's JavaScript bundler. Expo wraps it with `expo/metro-config`. SDK 55 adds experimental tree-shaking + module-graph improvements."
product:
  name: Metro Bundler
  stack: expo
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, frontend-architect]
  authoritative_url: https://metrobundler.dev/
  notes: "RN's bundler; Expo wraps it; SDK 55 added module-graph improvements + experimental tree-shaking"
---

## What it is

**Metro** is the JS bundler used by React Native. Expo wraps it (`expo/metro-config`) with Expo-specific defaults: TS support, SVG handling, asset extensions, monorepo resolution, web target support.

```js
// metro.config.js
const { getDefaultConfig } = require('expo/metro-config');
const config = getDefaultConfig(__dirname);
module.exports = config;
```

Canonical surface: [metrobundler.dev](https://metrobundler.dev/).

## When to use

You're using it. Every Expo project has Metro. What you control:

- `metro.config.js` overrides for monorepos (workspace resolution)
- Custom asset extensions
- Custom transformers (e.g., SVG-as-component via `react-native-svg-transformer`)
- Tree-shaking flags (experimental in SDK 55)

## 2025-2026 currency anchors

- **`expo/metro-config`** is the wrapper — provides Expo Router resolution, web target support, asset handling.
- **Experimental tree-shaking** (SDK 55) — `expo.tools.metro.treeShake` flag. Until stable, deep imports (`import x from 'lodash/x'`) are the workaround.
- **Module-graph improvements** in SDK 55 — faster cold rebuilds.
- **Workspace resolution** — `config.resolver.disableHierarchicalLookup = true` + explicit `nodeModulesPaths` for monorepos.
- **Dynamic imports** — `import()` works since RN 0.74 → SDK 51.

## Patterns + anti-patterns

### Pattern: Monorepo Metro config

```js
const { getDefaultConfig } = require('expo/metro-config');
const path = require('path');

const projectRoot = __dirname;
const workspaceRoot = path.resolve(projectRoot, '../..');

const config = getDefaultConfig(projectRoot);
config.watchFolders = [workspaceRoot];
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, 'node_modules'),
  path.resolve(workspaceRoot, 'node_modules'),
];
config.resolver.disableHierarchicalLookup = true;

module.exports = config;
```

Teaches Metro to resolve workspace packages without hoisting confusion.

### Pattern: SVG as React component

```bash
npx expo install react-native-svg react-native-svg-transformer
```

```js
const { getDefaultConfig } = require('expo/metro-config');
const config = getDefaultConfig(__dirname);
const { transformer, resolver } = config;
config.transformer = { ...transformer, babelTransformerPath: require.resolve('react-native-svg-transformer') };
config.resolver = {
  ...resolver,
  assetExts: resolver.assetExts.filter((ext) => ext !== 'svg'),
  sourceExts: [...resolver.sourceExts, 'svg'],
};
module.exports = config;
```

Now `import Logo from './logo.svg'` returns a React component.

### Pattern: Dynamic imports for code splitting

```ts
const HeavyAnalytics = lazy(() => import('@/features/analytics/Analytics'));

function ScreenWrapper() {
  return (
    <Suspense fallback={<LoadingShimmer />}>
      <HeavyAnalytics />
    </Suspense>
  );
}
```

Metro produces a separate chunk; loaded on first render.

### Pattern: Deep imports until tree-shaking stable

```ts
// Without tree-shaking
import { debounce } from 'lodash';   // 👈 drags all of lodash

// Deep import
import debounce from 'lodash/debounce';   // 👈 small
```

Until SDK 55's `expo.tools.metro.treeShake` stabilizes, deep imports keep bundles lean.

### Anti-pattern: Modifying `config.resolver` without inheriting

```js
// BAD — loses Expo defaults
module.exports = { resolver: { sourceExts: ['ts', 'tsx'] } };
```

Always extend `getDefaultConfig` — Expo's defaults handle asset extensions, web target, monorepo, etc.

## Gotchas

- **Cache invalidation** — `npx expo start --clear` clears Metro's cache. Useful when you see "old code" after a config change.
- **Watchman** on macOS speeds up file watching; install via `brew install watchman` for big repos.
- **`.expo/`** is gitignored cache; safe to delete.
- **Babel + Metro pipeline** — Metro runs Babel internally. `babel.config.js` is shared between local + EAS Build.
- **Web target uses Metro too** — `expo start --web` runs Metro with `platform=web`; `expo export --platform web` produces the bundle for EAS Hosting.

## Cross-references

- [Expo SDK](/stacks/expo/expo-sdk/) — Metro version pinned by SDK
- [Expo CLI](/stacks/expo/expo-cli/) — `npx expo start` runs Metro
- [Expo Router](/stacks/expo/expo-router/) — depends on `expo/metro-config`
- Role overlays: [mobile-architect](/stacks/expo/mobile-architect/), [frontend-architect](/stacks/expo/frontend-architect/)
- [metrobundler.dev](https://metrobundler.dev/)
