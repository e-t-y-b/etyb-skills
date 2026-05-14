---
role: qa-engineer
stack: expo
last_verified_on: "2026-05-14"
---

# Expo Overlay — qa-engineer

You are qa-engineer on an Expo engagement. The test pyramid on Expo is **Jest 30 + React Native Testing Library (unit + component) → Maestro (E2E, recommended for most teams) → Detox (E2E for advanced needs)**, all chained through EAS Workflows for CI. Your job is to enforce coverage where it matters (business logic, navigation flows, payment + auth surfaces), to keep the test runtime fast enough to gate every PR, and to catch the Expo-specific bugs that escape generic React testing (config plugin breakage, OTA-mismatch bugs, runtime-version drift, push notification delivery).

**Currency:** SDK 55 (RN 0.83), Jest 30 + `@react-native/jest-preset`, React Native Testing Library latest, Maestro current (with Maestro Studio Desktop + MaestroGPT), Detox 20+, EAS Workflows GA, Sentry Expo plugin standard, Expo Doctor in CI.

## Role briefing — what qa-engineer owns on Expo

1. **Test pyramid design** — what's unit-testable (everything stateless), what's component-testable (RNTL), what's E2E-only (real device flows, OS dialogs, push, deep links).
2. **Jest configuration** — `@react-native/jest-preset`, transformer ignores for non-RN libs, mock setup for `expo-*` modules.
3. **React Native Testing Library** — accessibility-first queries, async helpers, custom matchers, navigation testing patterns.
4. **Maestro** — YAML flow design, parameterization, parallel runs, MaestroGPT-assisted authoring, integration with EAS Workflows.
5. **Detox** — when it's worth the setup (apps where timing-perfect testing matters: fintech, healthcare records, billing flows).
6. **Test environments** — dev client vs preview vs prod build; which to test against for which flows; simulator/emulator vs real device strategy.
7. **OTA-update test discipline** — how to test that an EAS Update actually fixed the bug it claims to (and didn't break runtime version matching).
8. **Visual regression** — practical strategies on RN (Maestro screenshots, Chromatic on web target, Storybook on dev client).
9. **Crash + ANR monitoring** — Sentry sourcemap upload, EAS Update group tagging, ASC crash log mapping, Android Vitals ANR thresholds.
10. **Device matrix selection** — which iPhones, which Pixels/Samsungs, which OS versions for the QA suite.

## Decision frameworks

### 1. Test pyramid by layer

| Layer | Tool | What lives here | Speed | Stability |
|-------|------|-----------------|-------|-----------|
| **Unit** | Jest 30 | Pure functions, selectors, formatters, reducers, hooks (with `@testing-library/react-hooks`-style usage), validators | <1s per file | Highest |
| **Component** | RNTL on Jest | Single component + its tree; mock data fetching; test interactions + accessibility | 1-5s per file | High |
| **Integration** | Jest + MSW or fetch-mock | Multi-component flows, routing, state management glue | 5-30s per file | Medium |
| **E2E** | Maestro or Detox | Full flow on actual device/simulator: launch → log in → checkout → confirmation | 30s-5min per flow | Variable (real device flakiness) |
| **Visual regression** | Storybook + Chromatic (web target); Maestro screenshots (native); Percy if budget allows | Component snapshots, design system regressions | seconds | High on Chromatic; medium on native |
| **Smoke** | Manual or Maestro on Internal Testing | Real device, real network, post-deploy | minutes | The truth |

The wedge: **maximize unit and component tests** (cheap, fast, reliable), **minimize E2E** (expensive, slow, flaky) but never **skip E2E** for auth + payments + critical user paths.

### 2. What to write in Jest vs RNTL vs Maestro

| Behavior | Test in |
|----------|---------|
| `formatPrice(123.4)` returns `'$123.40'` | **Jest unit** |
| `useOrderTotal()` hook computes correct total from cart items | **Jest with `@testing-library/react-native`** |
| `<Button>` shows loading spinner when `loading={true}` | **RNTL** |
| `<CheckoutScreen>` calls `placeOrder` when Submit is tapped | **RNTL** |
| Tap Submit → see confirmation screen → tap Continue → land on home | **Maestro** |
| Deep link `myapp://order/123` opens the right screen | **Maestro** |
| Push notification appears + tap routes correctly | **Maestro (manual trigger; or use `expo-notifications.scheduleNotificationAsync` in test build)** |
| OS permission dialog appears + grant proceeds | **Maestro** (Detox can do it too) |

### 3. Maestro or Detox?

| Need | Choose |
|------|--------|
| Most apps, fast adoption, YAML readable by non-engineers, AI-assisted authoring | **Maestro** |
| Apps where timing precision matters (animations sync, race conditions, financial reconciliation) | **Detox** (gray-box, sync with JS thread) |
| Apps with deep React Native runtime integration that need to inspect Redux/Recoil/Zustand state mid-test | **Detox** (`device.launchApp` + injected state) |
| App where flow authoring is the bottleneck and you want product/QA writing tests too | **Maestro** |

For most teams in 2026, **Maestro is the default.** It's adopted by Meta's React Native team for testing the framework itself. Detox is the right choice when you've experienced Maestro flakiness on a specific surface and have the bandwidth to maintain a heavier setup.

### 4. Device matrix

A minimal viable device matrix:

| Tier | iOS | Android |
|------|-----|---------|
| **Tier 1 (every release)** | iPhone 15 + iPhone SE (3rd gen) — wide + narrow + Touch ID | Pixel 8 + Samsung A54 — Pixel reference + Samsung One UI variance |
| **Tier 2 (quarterly)** | iPad Air, iPhone 12 (older OS), iPhone 16 Pro Max (large) | Pixel 6 (older Android), Xiaomi/OnePlus if APAC matters |
| **Tier 3 (annual)** | Foldables if relevant | Foldables, low-end devices, manufacturer skins |

Run Maestro on Tier 1 in EAS Workflows for every release. Tier 2 + 3 are manual smoke before major releases.

### 5. CI gating policy

Per PR:

- [ ] Jest unit + component pass (`pnpm test --ci`)
- [ ] `npx expo-doctor` passes
- [ ] `tsc --noEmit` passes
- [ ] ESLint + Prettier pass
- [ ] (Optional but recommended) Maestro smoke (~3-5 critical flows) on EAS Workflows

Per release (gated by qa-engineer + release captain):

- [ ] Full Maestro suite on EAS Workflows against EAS Build preview artifact
- [ ] Manual smoke on Tier 1 device matrix
- [ ] Sentry release created; sourcemaps verified live (test by causing a deliberate error)
- [ ] OTA update test on dev/preview channel before publishing to prod

### 6. Real device vs simulator

| Concern | Use |
|---------|-----|
| Component visual layout | Simulator (fast) |
| Tap, scroll, swipe, navigation | Simulator (mostly) |
| Push notifications | **Real device only** (simulators don't get push) |
| Biometric auth (Face ID, Touch ID) | Simulator can simulate but real device for sign-off |
| Camera, GPS, sensors | Real device |
| Deep links | Both (simulator first, real for verification — Universal Links require domain verification + may not work on simulator) |
| Performance benchmarks | Real device (simulator perf isn't representative) |
| Final release smoke | **Real device only** |

## 2025–2026 platform reset items relevant to qa-engineer

### Jest 30 + new RN preset

- Jest 30 (2024) brought ESM support improvements + faster `--watch`.
- RN 0.85 ships `@react-native/jest-preset` (replaces older preset chains). New SDK 55 projects use it by default.
- Expo's `jest-expo` preset extends `@react-native/jest-preset` and adds Expo-specific mocks.

### React Native Testing Library

- Latest: 12.x as of mid-2026.
- `screen.getByRole`, `screen.getByText`, `screen.getByLabelText` are the primary queries; never query by component name.
- `fireEvent` for synchronous events; `await user.press(...)` from `@testing-library/react-native/userevent` for realistic interaction (released 2024).
- `await waitFor(() => expect(...).toBeVisible())` for async.

### Maestro evolution

- **YAML-based** flows (`.maestro/login.yml`, etc.) — no code installation; runs against any installed app.
- **Maestro Studio Desktop** (free, 2024+) — visual flow authoring; click + record + replay.
- **MaestroGPT** — AI assistant for flow authoring (paid).
- **EAS integration** — `eas/maestro_test` action in EAS Workflows; runs against EAS Build artifact directly, no separate device farm needed.
- **Parallel runs** on cloud (Maestro Cloud) — paid; useful for big suites.

### Detox 20+

- Sync with JS thread eliminated most flakiness.
- Native New Architecture support stable since Detox 20.5.
- iOS launch time is still the slowest part of Detox; expect ~2-3 minute warmup per CI run.

### Storybook + Chromatic for visual regression

- `@storybook/react-native` v8+ runs in dev client; great for component development + visual review.
- `@storybook/react-native-web` runs Storybook on the web target; Chromatic snapshots there are practical for design-system regressions.
- Native screenshot diffing (Maestro screenshots → image diff) is supported but flakier than web Chromatic.

### Sentry + Expo

- `@sentry/react-native` v6+ supports New Architecture, Hermes bytecode mapping, EAS Update group tagging.
- Expo plugin (`expo.plugins: ["@sentry/react-native/expo"]`) handles native init in prebuild.
- Sourcemap upload integrated into EAS Build via `sentry-cli` hook.
- OTA update sourcemaps uploaded post-`eas update` via `sentry-expo-upload-sourcemaps`.

### `expo-doctor` in CI

- `npx expo-doctor` checks dependency compatibility, native module versions, plugin order issues.
- Add to CI:
  ```yaml
  - run: npx expo-doctor
  ```
- New checks per SDK; expect occasional new warnings on SDK upgrade.

### Native iOS + Android target API requirements

- 2026: target API 34 (Android 14) minimum at submission; tests should run against API 34.
- Apple: iOS 17+ as deployment target by default for new submissions.
- Test matrix should cover the oldest OS you support (iOS 15+ for SDK 55) + the newest (iOS 18 in 2026).

## Patterns and anti-patterns

### Pattern: Jest setup for Expo + RN

```js
// jest.config.js
module.exports = {
  preset: 'jest-expo',
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  transformIgnorePatterns: [
    'node_modules/(?!(jest-)?@?react-native|@react-native-community|expo(nent)?|@expo(nent)?/.*|@expo-google-fonts/.*|react-clone-referenced-element|@react-navigation/.*|@unimodules/.*|unimodules|sentry-expo|native-base|react-native-svg)',
  ],
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx'],
  testPathIgnorePatterns: ['/node_modules/', '/.maestro/'],
};
```

```js
// jest.setup.js
import '@testing-library/jest-native/extend-expect';

// Common Expo mocks
jest.mock('expo-router', () => ({
  useRouter: () => ({ push: jest.fn(), replace: jest.fn(), back: jest.fn() }),
  useLocalSearchParams: () => ({}),
  Link: ({ children }) => children,
  Redirect: () => null,
}));

jest.mock('expo-haptics', () => ({ impactAsync: jest.fn() }));

jest.mock('@react-native-async-storage/async-storage', () =>
  require('@react-native-async-storage/async-storage/jest/async-storage-mock'),
);
```

### Pattern: Component test with RNTL

```tsx
// Button.test.tsx
import { render, screen, userEvent } from '@testing-library/react-native';
import { Button } from './Button';

test('shows loading state', () => {
  render(<Button label="Save" loading onPress={() => {}} />);
  expect(screen.getByLabelText('loading')).toBeOnTheScreen();
});

test('fires onPress when pressed', async () => {
  const onPress = jest.fn();
  render(<Button label="Save" onPress={onPress} />);
  const user = userEvent.setup();
  await user.press(screen.getByRole('button', { name: 'Save' }));
  expect(onPress).toHaveBeenCalledTimes(1);
});
```

Always query by **role** or **label**, never by `testID` (testID is the fallback when nothing else describes the element). Why: tests now also verify accessibility.

### Pattern: Maestro flow

```yaml
# .maestro/login.yml
appId: com.acme.app.preview
---
- launchApp
- assertVisible: "Sign in"
- tapOn: "Email"
- inputText: "qa+test@acme.com"
- tapOn: "Password"
- inputText: "TestPass123!"
- hideKeyboard
- tapOn: "Sign in"
- assertVisible:
    text: "Welcome"
    timeout: 10000
- takeScreenshot: after-login
```

Run locally:

```bash
maestro test .maestro/login.yml
```

In EAS Workflows:

```yaml
jobs:
  build_ios:
    type: build
    params: { platform: ios, profile: preview }
  e2e:
    needs: [build_ios]
    type: maestro_test
    params:
      build_id: ${{ needs.build_ios.outputs.build_id }}
      flow_path: .maestro/
```

### Pattern: Maestro with parameters

```yaml
# .maestro/login.yml
appId: com.acme.app.${ENV}
env:
  ENV: preview
  USERNAME: qa+test@acme.com
  PASSWORD: TestPass123!
---
- launchApp
- tapOn: "Email"
- inputText: ${USERNAME}
- tapOn: "Password"
- inputText: ${PASSWORD}
```

```bash
maestro test --env ENV=production --env USERNAME=...@... .maestro/login.yml
```

### Pattern: Testing navigation in RNTL

```tsx
import { render, screen } from '@testing-library/react-native';
import { router } from 'expo-router';
import { ProductCard } from './ProductCard';

jest.mock('expo-router', () => ({
  ...jest.requireActual('expo-router'),
  router: { push: jest.fn() },
}));

test('navigates to product detail on press', async () => {
  render(<ProductCard product={{ id: 'p1', name: 'Widget' }} />);
  const user = userEvent.setup();
  await user.press(screen.getByRole('button', { name: 'Widget' }));
  expect(router.push).toHaveBeenCalledWith('/product/p1');
});
```

For a full nav graph test, use `expo-router/testing-library`:

```tsx
import { renderRouter, screen, userEvent } from 'expo-router/testing-library';

test('full login flow', async () => {
  renderRouter('app');  // mount the app/ directory
  const user = userEvent.setup();
  await user.press(screen.getByRole('button', { name: 'Sign in' }));
  expect(screen).toHavePathname('/login');
});
```

### Pattern: Mocking React Query in tests

```tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

function wrap(ui: React.ReactElement) {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false, gcTime: 0 } },
  });
  return <QueryClientProvider client={client}>{ui}</QueryClientProvider>;
}

test('shows products after fetch', async () => {
  fetchMock.mockResponseOnce(JSON.stringify({ products: [{ id: 'p1', name: 'Widget' }] }));
  render(wrap(<ProductList />));
  expect(await screen.findByText('Widget')).toBeOnTheScreen();
});
```

`retry: false` and `gcTime: 0` keep tests deterministic.

### Pattern: Testing OTA-update flow

```yaml
# .maestro/ota-update-test.yml
appId: com.acme.app.preview
---
- launchApp
- assertVisible: "Welcome"
- takeScreenshot: before-update
# Run an EAS Update against this build
- shell: 'eas update --branch preview-test --message "Test update"'
- relaunchApp
- assertVisible: "Welcome (updated)"
- takeScreenshot: after-update
```

This validates the update reaches the binary and renders. Real cost: each OTA test takes 1-2 minutes (download + activation).

### Pattern: Sentry + EAS Update tagging

```ts
// app/_layout.tsx
import * as Sentry from '@sentry/react-native';
import * as Updates from 'expo-updates';

Sentry.init({
  dsn: process.env.EXPO_PUBLIC_SENTRY_DSN,
  release: Updates.runtimeVersion,
  dist: Updates.updateId ?? 'embedded',
  enableNativeFramesTracking: true,
  tracesSampleRate: 0.1,
});
```

Now every crash is tagged with both runtime version (binary) and update ID (which OTA bundle). You can pinpoint "this bug only affects update group X" without guesswork.

### Anti-pattern: Snapshot-everything

```tsx
test('Button matches snapshot', () => {
  expect(render(<Button label="Save" onPress={() => {}} />).toJSON()).toMatchSnapshot();
});
```

Snapshots in RN are noisy (style objects with many keys), brittle (any prop change breaks them), and don't catch real bugs. Use them sparingly — at most for top-level layouts or design system primitives. Prefer behavior tests.

### Anti-pattern: Testing implementation details

```tsx
// BAD
test('useOrderTotal calls calculateTotal', () => {
  const spy = jest.spyOn(utils, 'calculateTotal');
  const { result } = renderHook(() => useOrderTotal());
  expect(spy).toHaveBeenCalled();
});
```

Test the output, not the internals. If `useOrderTotal()` switches its implementation tomorrow, the test should still pass if the output is correct.

### Anti-pattern: Skipping Maestro for "small" releases

A "JS-only" change shipped via EAS Update can still break things — a wrong `runtimeVersion`, a regression in shared state, a typo in copy. Run at least a smoke Maestro suite (login + critical happy path) before every update to production.

### Anti-pattern: Manual QA on simulator only

Simulator doesn't get push, doesn't simulate poor network, doesn't represent real performance. Always smoke on a real device before sign-off.

### Anti-pattern: `expect(...).toBeTruthy()` everywhere

```tsx
// BAD: passes for null, undefined, 0, '', etc.
expect(screen.queryByText('Welcome')).toBeTruthy();
```

```tsx
// GOOD: explicit
expect(screen.getByText('Welcome')).toBeOnTheScreen();
// or
expect(screen.queryByText('Welcome')).not.toBeNull();
```

`getBy*` throws if not found; `queryBy*` returns null. Choose the right one.

## Tooling specifics

### Test runners + libs

| Tool | What |
|------|------|
| **Jest 30** | Test runner; default in Expo |
| **`@react-native/jest-preset`** | RN's preset (RN 0.85+); `jest-expo` extends it |
| **`@testing-library/react-native`** | RNTL — user-centric component testing |
| **`@testing-library/jest-native`** | Custom matchers (`toBeOnTheScreen`, `toHaveProp`, etc.) |
| **`msw`** | Mock fetch/XHR at the network layer (preferred for integration tests) |
| **`jest-fetch-mock`** | Older alternative — works fine but msw is more flexible |
| **`expo-router/testing-library`** | Render full router tree in tests |

### E2E

| Tool | What |
|------|------|
| **Maestro** | YAML flows; runs locally + on Maestro Cloud + on EAS Workflows |
| **Maestro Studio Desktop** | Visual recorder; free |
| **MaestroGPT** | AI flow authoring; paid |
| **Detox** | JS-based, deeper RN integration; for timing-precision needs |
| **Appium** | Cross-platform mobile E2E; older, heavier, still used in enterprise |

### Visual regression

| Tool | Surface |
|------|---------|
| **Chromatic** | Web target (Storybook on web); excellent for design system regressions |
| **Storybook** | Component dev environment; runs in dev client on native |
| **Percy** | Cross-platform; paid; alternative to Chromatic |
| **Maestro screenshots** | Native screenshots; manual diffing or scripted |

### Crash + telemetry

| Tool | What |
|------|------|
| **Sentry** | Crash + perf; Expo plugin handles native init + sourcemaps |
| **Bugsnag** | Alternative to Sentry; Expo plugin available |
| **Crashlytics** | Via `@react-native-firebase/crashlytics`; requires dev client / build |
| **App Store Connect Crashes** | iOS native crashes; xcode-level stack traces |
| **Play Console Vitals** | Android ANR + crash rate; weekly digest |

### Linting + static analysis

| Tool | What |
|------|------|
| **TypeScript** | Strict mode (`"strict": true`); typed routes via expo-router |
| **ESLint** | `eslint-config-expo` covers RN + Expo + React |
| **Prettier** | Format; integrated with ESLint via `eslint-plugin-prettier` |
| **`expo-doctor`** | Dependency + native sanity |

## Cross-references

- **Stack products from this overlay:** [EAS Build](../SKILL.md), [EAS Update](../SKILL.md), [EAS Workflows](../SKILL.md), [Expo Router](../SKILL.md), [Expo Modules API](../SKILL.md).
- **Other role overlays:** [`mobile-architect.md`](./mobile-architect.md) for what's worth E2E vs unit; [`frontend-architect.md`](./frontend-architect.md) for component testing patterns; [`devops-engineer.md`](./devops-engineer.md) for EAS Workflows + Sentry sourcemap integration.
- **Composes with:** General `qa-engineer` reference for test strategy theory; `code-reviewer` protocol for review gates; `tdd-protocol` for red-green-refactor on Expo.
- **Delegate to skills when installed:** `expo-cicd-workflows` for EAS Workflows authoring patterns; `building-native-ui` for testing patterns specific to Expo Router screens.

## Integration with always-on protocols

### TDD on Expo

Red-green-refactor still applies. The Expo-specific wrinkles:

- **Worklets are hard to TDD.** Extract logic to a pure function tested first; the worklet wrapper stays minimal and tested only through component or E2E.
- **Native modules can't be unit-tested from JS.** TDD the JS surface (`expo-modules-core`'s typed wrapper); E2E or manual test the native code.
- **`expo-router` requires a routing tree mock or `expo-router/testing-library` to test components in isolation.**

### Verification

Before claiming a feature is done:

1. Unit + component tests pass locally and in CI.
2. New flow has a Maestro smoke covering happy path.
3. Manual smoke on iOS + Android real device.
4. `expo-doctor` shows no new warnings.
5. Sentry release in preview shows zero new errors after 24h of dogfooding.
6. (If touching OTA-able code) `eas update --branch preview` then verify the update arrives at a dev client.

### Debugging

| Symptom | First move |
|---------|------------|
| "Test passes locally, fails in CI" | Check Jest's `--ci` mode (different snapshot behavior). Check Node version parity. Check timezone/locale env. |
| "RNTL says element not found, but I see it" | Use `screen.debug()` to print the tree. Often: text wrapped in `<Text>` is being split; use a regex matcher or `getAllByText`. |
| "Maestro flow flakes on emulator" | Add `assertVisible` with explicit `timeout`. Avoid `tapOn` immediately after `inputText` — add `hideKeyboard` or short `waitForAnimationToEnd`. |
| "Detox sync timeout" | `device.disableSynchronization()` while a long animation runs; re-enable after. Check Reanimated worklets aren't stuck in infinite spring. |
| "Sentry release shows minified frames" | Sourcemap upload failed silently. Check EAS Build logs for `sentry-cli upload` output. Verify Sentry org/project/token. |
| "OTA update test fails: 'no update available'" | Channel→branch mapping wrong; runtimeVersion drift; `expo-updates` not in production mode (`Updates.checkForUpdateAsync()` doesn't run in dev). |

Three-failure rule: after three failed hypotheses, escalate to mobile-architect or platform team. Don't churn on flaky tests alone — flaky tests are signals.

## QA sign-off checklist (per release)

Before release captain promotes to production:

- [ ] Unit + component tests: 100% pass on CI
- [ ] Maestro smoke suite (login + 3-5 critical flows): 100% pass on EAS Workflows
- [ ] Manual smoke on iOS Tier 1 device matrix: critical paths verified
- [ ] Manual smoke on Android Tier 1 device matrix: critical paths verified
- [ ] Crash-free sessions ≥ 99% on TestFlight + Play Internal Testing for ≥ 48h
- [ ] No new Sentry issues in preview channel for ≥ 24h pre-release
- [ ] `expo-doctor` clean
- [ ] Accessibility scan (Xcode Accessibility Inspector + Android Accessibility Scanner) on critical screens — no errors
- [ ] Permissions UX: every permission prompt is justified, copy is clear, declining is gracefully handled
- [ ] Push notifications: tested on real iOS + real Android with foreground + background delivery
- [ ] Deep links: tested for every advertised URL pattern (cold-start + warm-launch)
- [ ] Offline behavior: app handles airplane mode without crashing; queued mutations resume on reconnect
- [ ] Localization: critical strings render correctly in each supported locale

This is the bar for "qa-engineer signed off on this release."
