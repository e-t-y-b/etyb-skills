---
title: Snack
description: Browser-based Expo playground. Edit code, see it run live in Expo Go or in a web preview. Great for repros, demos, learning.
product:
  name: Snack
  stack: expo
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, frontend-architect, qa-engineer]
  authoritative_url: https://snack.expo.dev/
  notes: "Browser playground; latest SDK supported within ~2 weeks of release"
---

## What it is

**Snack** is the in-browser Expo editor + runtime at [snack.expo.dev](https://snack.expo.dev/). Write code in a Monaco editor, see it live in:

- A web preview (RN-web compatible code)
- Expo Go on a real device via QR code
- An iOS simulator embedded in the page (paid SDK feature)

Snacks have URLs, can be shared, can be saved to your Expo account, can be forked.

## When to use

- **Repros** — minimal Snack on a GitHub issue is the gold standard for filing bugs against Expo / RN / `expo-*` libs.
- **Demos** — share a working UI with a colleague or stakeholder without setting up their dev environment.
- **Learning** — quick exploration of a new Expo Router pattern, a Reanimated technique, an `expo-*` API.
- **Workshops + interviews** — pair programming on a Snack instead of screen-sharing local environments.

**Don't use** for serious development. Snack is for snippets, not apps.

## 2025-2026 currency anchors

- **Latest SDK supported within ~2 weeks** of release. After SDK 55 shipped (Feb 2026), Snack updated by late Feb.
- **Web preview** — works for components without native-only APIs (no `expo-camera`, no `expo-haptics`).
- **Expo Go integration** — scan QR with Expo Go on a real device to load the Snack live.
- **Custom dependencies** — add `expo-*` and many third-party libs via the Dependencies panel; subject to a curated allowlist.

## Patterns + anti-patterns

### Pattern: Minimal repro template

```tsx
// Snack: https://snack.expo.dev/@you/bug-repro
import { View, Text } from 'react-native';

export default function App() {
  // Steps to reproduce:
  // 1. ...
  // 2. ...
  // Expected: ...
  // Actual: ...
  return <View><Text>Hello</Text></View>;
}
```

Share the URL on GitHub / Discord. Maintainers can fork and verify in seconds.

### Pattern: Component sandbox

Use Snack to prototype a component in isolation, then copy into your project. Faster than scaffolding a project for one component.

### Anti-pattern: Building a real app on Snack

Snack has size limits, no source control, no EAS integration. Use a real project for anything you'll ship.

### Anti-pattern: Including private API keys

Snacks can be public by default. Don't paste real API keys.

## Gotchas

- **Some `expo-*` modules don't work in Snack** — anything requiring native config plugins beyond what Snack pre-bakes (e.g., custom permission strings, native modules outside the allowlist). Use a real project for those.
- **Snack on Expo Go** uses the *Expo Go bundled module set* — same limitations as Expo Go itself.
- **Persistence** — save to your Expo account; otherwise URLs are session-bound.
- **Bandwidth** — heavy bundles load slowly in Expo Go over LAN; tunneling helps.

## Cross-references

- [Expo Go](/stacks/expo/expo-go/) — runtime Snacks deploy to on device
- [Expo SDK](/stacks/expo/expo-sdk/) — Snack tracks SDK releases
- Role overlays: [mobile-architect](/stacks/expo/mobile-architect/), [frontend-architect](/stacks/expo/frontend-architect/)
- [snack.expo.dev](https://snack.expo.dev/)
