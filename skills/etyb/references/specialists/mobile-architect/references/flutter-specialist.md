# Flutter / Dart — Deep Reference

**Always use `WebSearch` to verify version numbers and features. Flutter ships quarterly stable releases, and the Dart/Flutter ecosystem evolves rapidly. Last verified: April 2026.**

## Table of Contents
1. [Flutter and Dart Versions](#1-flutter-and-dart-versions)
2. [State Management](#2-state-management)
3. [Navigation](#3-navigation)
4. [Architecture Patterns](#4-architecture-patterns)
5. [Networking](#5-networking)
6. [Local Storage](#6-local-storage)
7. [UI and Theming](#7-ui-and-theming)
8. [Platform Channels and FFI](#8-platform-channels-and-ffi)
9. [Impeller Rendering Engine](#9-impeller-rendering-engine)
10. [Testing](#10-testing)
11. [DevTools and Debugging](#11-devtools-and-debugging)
12. [Build and Deployment](#12-build-and-deployment)
13. [Animation](#13-animation)
14. [Code Generation](#14-code-generation)
15. [Dart Macros and Augmentations](#15-dart-macros-and-augmentations)
16. [Multi-Platform Maturity](#16-multi-platform-maturity)
17. [Performance Optimization](#17-performance-optimization)
18. [Package Ecosystem](#18-package-ecosystem)
19. [Firebase Integration](#19-firebase-integration)
20. [Internationalization](#20-internationalization)
21. [Deep Linking](#21-deep-linking)
22. [Monorepo Patterns](#22-monorepo-patterns)

---

## 1. Flutter and Dart Versions

### Flutter 3.41.x (Latest Stable, February 2026)

Flutter follows a quarterly release cadence (~4 stable releases per year). Key highlights:

- Widget previewer with `dart:ffi` support
- Material and Cupertino libraries migrated to separate packages (independent release cycles)
- Platform-specific asset tagging in `pubspec.yaml`
- Impeller gap closure (most shader/rendering edge cases resolved)

### Flutter 3.38.0 (November 2025)

- Android 16KB page support compliance
- Predictive back gesture default on Android
- Build hooks stable
- Hot reload for web
- GenUI SDK alpha

### Dart 3.9–3.10 (Paired with Flutter 3.38–3.41)

Key Dart language features across recent releases:

| Version | Feature |
|---------|---------|
| Dart 3.6 | Digit separators (`1_000_000`) |
| Dart 3.7 | Wildcard variables (`_` as true wildcard) |
| Dart 3.8 | Intelligent automatic trailing comma in formatter |
| Dart 3.9 | Null safety type promotion, ~50% faster `dart analyze` (AOT-compiled) |
| Dart 3.10 | **Dot shorthand syntax** — `.start` instead of `MainAxisAlignment.start` |

Dot shorthand syntax is a major ergonomic improvement that significantly reduces widget verbosity.

---

## 2. State Management

### Riverpod 3.x (Recommended for Most Projects)

- **Version**: flutter_riverpod 3.0.2–3.3.x (stable, released September 2025)
- Compile-time safety, lowest boilerplate of any production-ready solution

**Key features in 3.0:**
- **Automatic retry**: Failed providers retry on transient errors (network failures) instead of immediately throwing
- **Offline persistence** (experimental): Cache provider state locally, restore on app reopen
- **Mutations API**: Actions (Login, Post Comment) automatically expose lifecycle state (Idle, Pending, Success, Error)
- **Pause/Resume**: Off-screen widget providers automatically pause listeners
- **Code generation**: `@riverpod` annotation generates typed providers with minimal boilerplate

**When to use**: Most Flutter projects in 2026
**When NOT to use**: Simple apps where `setState` suffices; teams deeply invested in BLoC

### BLoC / Cubit 9.x

- **Version**: bloc 9.2.0, flutter_bloc 9.1.1 (~1.57M weekly downloads)
- Strict event-driven state management with audit trail
- `EmittableStateStreamableSource`, `MultiBlocObserver`, `BlocSelector` for fine-grained rebuilds
- Use **Cubit** for simple synchronous state (toggles, nav index); **Bloc** for complex async flows needing event audit

**When to use**: Enterprise apps in regulated industries (checkout, authentication)
**When NOT to use**: Small to medium apps where Riverpod suffices

### Provider

- **Status**: Maintained but considered legacy. Riverpod is the recommended successor (same author)
- **When to use**: Existing projects already on Provider; simple DI-only use cases
- **When NOT to use**: New projects (use Riverpod)

### Signals 6.x

- Fine-grained reactivity ported from Preact.js Signals
- `signal(...)` = state, `computed(...)` = derived, `Watch(...)` = reactive UI
- Surgical UI updates — only delta changes trigger rebuilds
- Author: Rody Davis (Google DevRel)
- **When to use**: Performance-critical apps needing surgical precision
- **When NOT to use**: Teams needing established community patterns (Riverpod/BLoC are more mature)

---

## 3. Navigation

### GoRouter 17.x (Official Recommendation)

- Official Flutter team package — the recommended routing solution
- Declarative routing with Router API
- Path/query parameter parsing with template syntax (`user/:id`)
- `ShellRoute` for tabs/bottom navigation
- Typed routes via `go_router_builder` (compile-time type-safe)
- Deep linking out of the box
- Auth redirects based on application state
- **When to use**: Most Flutter apps
- **When NOT to use**: Very simple apps with 2-3 screens (`Navigator.push` suffices)

### AutoRoute 10.x

- Code generation based routing (`@AutoRouterConfig`)
- Strongly-typed arguments passing
- `AutoTabsRouter` for tab navigation
- Modular architecture support
- **When to use**: Large apps needing fully type-safe routing with code generation

### Routing Landscape

The ecosystem has consolidated around declarative routing. Navigator 2.0 remains the underlying API, but direct use is discouraged — use GoRouter or AutoRoute abstractions.

---

## 4. Architecture Patterns

### MVVM (Dominant in 2026)

- Flutter official docs recommend MVVM
- Views and ViewModels have one-to-one relationship
- ViewModels convert app data into UI state
- Works naturally with Riverpod or BLoC

### Clean Architecture

- Data → Domain → Presentation layer separation
- Domain layer: entities, use cases, repository interfaces
- Best for: medium-to-large apps, enterprise

### Feature-First Organization

- Each feature isolated with its own data/domain/presentation layers
- Easy to add/remove/refactor features independently
- Strong traction in 2026 Flutter projects
- Works well with Riverpod architecture code generation

### Riverpod Architecture (Andrea Bizzotto)

- Layers: Presentation (widgets + controllers) → Application (services) → Data (repositories)
- `AsyncNotifier` replaces `FutureProvider + StateNotifier`
- Code generation with `@riverpod` for boilerplate reduction
- Recommended for new projects in 2026

### Decision Framework

| Project Scale | Recommended |
|--------------|-------------|
| Early-stage / simple | MVVM with Riverpod |
| Medium / growing | Feature-first + Clean Architecture |
| Large / enterprise | Clean Architecture + BLoC or Riverpod |

---

## 5. Networking

### Dio 5.x + Retrofit 4.x (Standard Combination)

**Dio**: Global configuration, interceptors, FormData, request cancellation, file upload/download, timeout, custom adapters. Use singleton pattern for consistent headers/base URLs.

**Retrofit** (retrofit ^4.9.0, retrofit_generator ^10.0.1): Annotation-based API definition with code generation, built on Dio. Enforces clean architectural boundaries.

**When to use Dio + Retrofit**: Large-scale apps needing type-safe API layer

### Chopper

- HTTP client generator using source_gen, inspired by Retrofit
- Smaller ecosystem, lacks Dio support
- **When to use**: Projects preferring Chopper's middleware architecture

### http (Official Dart Package)

- Simple HTTP with minimal overhead
- **When to use**: Simple API calls, no interceptor needs
- **When NOT to use**: Large apps needing interceptors, retry logic, file uploads

---

## 6. Local Storage

### Drift 2.30.x (Relational — Recommended)

- Type-safe SQLite ORM with compile-time query checks
- Joins, views, migrations, web support (via sql.js/IndexedDB)
- Actively maintained (updates every 2-4 weeks), sponsored by Stream Inc
- **When to use**: Structured apps (e-commerce, finance), complex queries, relational data
- **When NOT to use**: Simple key-value storage

### Hive CE 2.8–2.9.x (Simple Key-Value)

- Community fork of abandoned Hive — actively maintained
- Lightweight NoSQL key-value database, pure Dart
- Works on mobile/desktop/web (WASM)
- **When to use**: Small/simple apps (notes, settings), fast prototyping
- **When NOT to use**: Complex relational data, advanced queries

### SharedPreferences 2.5.x

- New APIs: `SharedPreferencesAsync` and `SharedPreferencesWithCache` (legacy API deprecated)
- **When to use**: Small data (login state, theme, counters)
- **When NOT to use**: Structured data or large datasets

### Isar (Not Recommended for New Projects)

- Original author abandoned development. Community maintenance uncertain.
- **When to use**: Existing projects already on Isar only

### ObjectBox

- High-performance NoSQL with object-oriented mapping, relations
- On-device vector search (first for mobile/IoT)
- **Limitation**: No web support
- **When to use**: Large-scale real-time apps, on-device AI/RAG

### sqflite

- Raw SQLite access for Flutter
- **When to use**: Direct SQL control without ORM
- **When NOT to use**: Most apps (Drift provides better type safety on top)

---

## 7. UI and Theming

### Material Design 3

- Fully integrated, `useMaterial3: true` is the default
- Dynamic color system via `ColorScheme.fromSeed()`
- Material and Cupertino libraries being migrated to separate packages for independent release cycles (ongoing in 3.41)

### Cupertino

- Automatically adapts to iOS system themes
- Uses system fonts for native iOS consistency
- `MaterialBasedCupertinoThemeData` harmonizes Cupertino with Material theme

### Custom Theming

- `ThemeData` with `ColorScheme.fromSeed()` for dynamic color
- `ThemeExtension` for custom theme properties
- `ThemeMode` for light/dark mode

### Adaptive Layouts

- 600px breakpoint: standard phone vs tablet threshold
- `LayoutBuilder` for responsive layouts, `MediaQuery` for screen dimensions
- Material's adaptive scaffold and navigation rail patterns
- Official tutorials cover adaptive layouts, navigation patterns, advanced scrolling

---

## 8. Platform Channels and FFI

### Platform Channels

- **MethodChannel**: Async bridge between Dart and native (Swift/Kotlin)
- **EventChannel**: Stream-based continuous data from native to Dart
- **Pigeon**: Code generation eliminating string matching; supports nested classes, async, bidirectional messaging
- **When to use**: Standard native feature integration (Firebase, permissions, sensors)

### FFI (Foreign Function Interface)

- 2026: Developers can call Swift/Kotlin APIs using FFI directly without async platform channels
- `dart:ffi` for calling C/C++/Rust functions — no method channels or async wrappers
- Faster and cleaner than platform channels for performance-critical calls

### UI Thread Merge (New in 2026)

- **Flutter 3.32**: Threads merged by default on iOS and Android
- **Flutter 3.33 beta**: Threads merged on Windows and macOS
- Enables direct native API calls without threading overhead

**Decision**: Platform Channels for standard native features. Pigeon for type-safe channel alternative. FFI for performance-critical native calls and C/C++/Rust integration.

---

## 9. Impeller Rendering Engine

### Status (2026)

| Platform | Status |
|----------|--------|
| **iOS** | Only engine — Skia completely removed, no opt-out |
| **Android** | Default on API 29+ (Android 10+). Skia removal committed for 2026 |
| **Web** | Still uses Skia (canvaskit/skwasm). May use Impeller in future |
| **Desktop** | Rolling out, Skia still available |

### Performance

- **30-50%** reduction in jank frames during complex animations
- **20-40%** improvement in text rendering
- Real-world: **1.5% dropped frames** with Impeller vs **12%** with Skia
- Pre-compiled specialized shader set at build time (AOT) — eliminates runtime shader compilation jank
- Flutter 3.41: Most shader/rendering edge cases resolved

### Impeller vs Skia

| Aspect | Impeller | Skia |
|--------|----------|------|
| Shader compilation | AOT (build time) | JIT (runtime, causes jank) |
| Architecture | Built for Flutter specifically | General-purpose 2D graphics |
| Dropped frames | ~1.5% | ~12% |
| Custom shaders | Most gaps closed in 3.41 | Full support |

---

## 10. Testing

### Unit Testing

- Built-in `test` package; standard Dart unit testing
- `mocktail` (preferred) or `mockito` for mocking
- Focus on business logic, repositories, use cases

### Widget Testing

- `flutter_test` package built-in
- `WidgetTester` for pumping widgets and interacting with finders
- Fast (runs on host machine without emulator)

### Integration Testing

- `integration_test` package for full app testing on devices/emulators
- `flutter drive` for end-to-end tests

### Patrol 4.0 (E2E with Native Interaction)

- Web integration testing now available (new in 4.0, uses Playwright)
- Interacts with native OS features: permission dialogs, notifications, WebViews
- Custom finder system for concise tests, test isolation
- Cross-platform: write once, run on mobile and web
- **When to use**: E2E tests needing native OS interaction

### Golden Tests

- **Alchemist** has replaced discontinued golden_toolkit as the standard
- Platform tests generate human-readable golden files
- CI tests replace text with colored squares for cross-platform consistency
- **When to use**: Visual regression testing

### Recommended Testing Stack

- `test` + `mocktail` for unit tests
- `flutter_test` for widget tests
- Patrol 4.0 for E2E
- Alchemist for golden/visual regression tests

---

## 11. DevTools and Debugging

### Flutter DevTools (2026)

- **Widget Property Editor**: Live-tweak widget properties during debug
- **Inspector 2.0**: Unified UI revamp
- **Flex Explorer**: Modify mainAxisAlignment, crossAxisAlignment, flex in real time
- **Performance View**: Pinpoint slowdowns — heavy animations, expensive builds
- **Memory Analysis**: Track allocations, detect leaks
- **Network Monitoring**: Integrated API call tracking
- **Select Widget Mode**: Tap on running app to locate widget in tree
- Benchmarks show DevTools reduces debugging time by up to 40%

---

## 12. Build and Deployment

### Fastlane

- De facto standard for mobile deployment automation
- Handles code signing, screenshots, app store uploads
- Integrates with GitHub Actions and Codemagic

### Codemagic

- Purpose-built CI/CD for Flutter
- Apple Silicon M2 machines (first CI/CD with Apple silicon)
- Built-in code signing and Apple Developer portal integration
- Auto-deploy to App Store, Google Play, Microsoft Store, Huawei App Gallery
- Pricing: Free tier available; $3,990/year for teams

### GitHub Actions

- Production-ready Flutter CI/CD pipelines
- Combine with Fastlane for deployment automation

**Recommended**: GitHub Actions for CI (lint, test, build) + Fastlane for CD (signing, deployment) — or Codemagic as all-in-one.

---

## 13. Animation

### Implicit Animations (Simple)

- `AnimatedContainer`, `AnimatedOpacity`, `AnimatedPositioned`, `AnimatedSize`, `AnimatedScale`
- Automatically animate between values when target changes
- No `AnimationController` needed
- **When to use**: Fade-in/out, color change, alignment, position

### Explicit Animations (Complex)

- Require `AnimationController` + `TickerProviderStateMixin`
- Full control over timing, curves, sequences
- `AnimatedBuilder`, `AnimatedWidget`, custom `Tween`s
- **When to use**: Complex coordinated animations, user-input-driven, repetitive timing

### Rive 0.14.x

- Uses native C++ runtime via `rive_native` for better performance
- Interactive state machines for dynamic animations
- **When to use**: Complex interactive animations, game-like UI, state-machine-driven

### Lottie 3.x

- Pure Dart implementation, renders After Effects animations
- `renderCache` parameter to reduce energy consumption
- Supports all platforms (mobile, desktop, web)
- **When to use**: Designer-provided After Effects animations, loading indicators

---

## 14. Code Generation

### build_runner 2.6.x

Core orchestrator for code generation:
- `flutter pub run build_runner build` — one-time generation
- `flutter pub run build_runner watch` — continuous rebuilds

### freezed 3.2.x

- Creates immutable data classes with union types, copyWith, equality, serialization
- **New in 3.0**: "Mixed mode" — supports both sealed classes and extending base classes
- Pairs with `json_serializable` for JSON serialization + immutable state

### json_serializable 6.9.x

- Automatic `toJson`/`fromJson` code generation
- Full compatibility with freezed

### Drift Code Generation

- `drift_dev` generates type-safe database code, migration utilities, verification logic
- Integrates with build_runner

---

## 15. Dart Macros and Augmentations

### Macros: CANCELLED

The Dart team stopped work on macros entirely, despite 1,400+ upvotes and 2+ years of development. Reasoning: the opportunity cost was too high — runtime introspection conflicts with tree-shaking optimizations needed for smaller binaries.

### Augmentations (Shipping in 2026)

A narrower, practical feature extracted from the macros prototype:
- `augment` keyword allows splitting class definitions across files
- Code generators will output augmentations instead of part files
- Not a full macro replacement — solves the most common pain point of cleaner generated code

**Impact**: build_runner, freezed, json_serializable, and Drift continue as primary metaprogramming tools. Augmentations make their output cleaner but don't eliminate code generation.

---

## 16. Multi-Platform Maturity

### Platform Status (April 2026)

| Platform | Status | Notes |
|----------|--------|-------|
| **iOS** | Production | Impeller only, full support |
| **Android** | Production | Impeller default API 29+, 16KB page support |
| **Web** | Production | Wasm compilation, hot reload |
| **macOS** | Stable | Thread merge in beta |
| **Windows** | Stable | Firebase support expanding |
| **Linux** | Stable | Canonical partnership |

### Flutter Web

- WebAssembly (Wasm): Dart compiles directly to Wasm for near-native execution speeds
- Two renderers: canvaskit (CanvasKit/Skia) and skwasm (Skia via Wasm)
- Hot reload added in Flutter 3.38
- Best for: dashboards, admin panels, internal tools, PWAs
- Limitations: SEO challenging; initial load size larger than JS frameworks

### Flutter Desktop

- Stable since Flutter 3.26.0 (Q1 2026)
- Asset compression reduces binary size by up to 25% (Flutter 3.29)
- Multi-window support in progress (Canonical contributing)
- Firebase App Check and Realtime Database support Windows

---

## 17. Performance Optimization

### Profiling Workflow

1. Profile in **profile mode** on a **physical device** (preferably budget Android)
2. Run `flutter run --profile`
3. Enable PerformanceOverlay (press 'P' in terminal)
4. Capture DevTools timeline, analyze flame chart
5. Target: 16ms per frame (60fps); 8-11ms for 90-120Hz displays

### Core Optimization Strategies

- **`const` constructors**: Short-circuit rebuild work on widgets that don't change
- **`RepaintBoundary`**: Isolate expensive paint operations from the rest of the tree
- **`compute()` function**: Heavy work (JSON parsing, encryption, image processing) on background isolates
- **`cached_network_image`**: Cache instead of loading images on every build
- **`cacheWidth`/`cacheHeight`**: Image downsampling to reduce memory
- **State management**: Riverpod/BLoC to minimize unnecessary widget rebuilds
- **Widget tree restructuring**: Reduce rebuild scope, extract widgets

### Tools

- Flutter DevTools (Performance, Memory, Network tabs)
- PerformanceOverlay widget
- `flutter analyze` for static analysis
- Dart DevTools CPU/memory profiler

---

## 18. Package Ecosystem

- **pub.dev** hosts **55,000+** published packages
- **700,000+** monthly active users
- Only **9 known vulnerable packages** in the OSV database
- Flutter Ecosystem Committee curates Flutter Favorites
- Package topics (1-5 tags) for improved discovery
- Challenge: abundance requires discerning eye among 55K+ options

---

## 19. Firebase Integration (FlutterFire)

### Current State

- Official FlutterFire plugins maintained by Firebase team
- `firebase_core` as required foundation
- Firebase Android SDK 34.12.0, Firebase iOS SDK 12.12.0

### Key Services

Authentication, Firestore, Realtime Database, Cloud Functions, Crashlytics, Analytics, Cloud Messaging, Remote Config, Storage

### Firebase AI Logic SDK

- `firebase_ai` package replaces deprecated `FirebaseVertexAI`
- Direct Gemini model integration from Flutter apps

### Setup

`flutterfire configure` CLI for automatic project configuration. Works with Melos for monorepo setups.

---

## 20. Internationalization

### intl (Official)

- Foundation of Flutter i18n
- Locale-aware date formatting, currency display, complex plural rules (including Arabic's six forms)
- Gender-aware messages, bidirectional text
- ARB files for translation management

### easy_localization

- Higher-level wrapper for simplified i18n
- Supports JSON, CSV, HTTP, XML, YAML files
- Hot reload for translations, simpler API
- **When to use**: Teams wanting faster setup with less configuration

### Best Practices

- Implement i18n from day one (76% of consumers prefer purchasing in native language)
- Use `flutter_localizations` in `MaterialApp`/`CupertinoApp`
- Use ARB files for translator-friendly format

---

## 21. Deep Linking

### app_links (Current Standard)

- Replaces deprecated uni_links (abandoned 2+ years) and Firebase Dynamic Links (deprecated)
- Handles custom URL schemes, Android App Links, iOS Universal Links

### Setup

**iOS Universal Links**: Configure Associated Domains in Xcode (`applinks:<domain>`), host `apple-app-site-association` at `/.well-known/`

**Android App Links**: Configure `intent-filter` in AndroidManifest.xml, host `assetlinks.json` at `/.well-known/`

**Important**: If using `app_links`, disable Flutter's built-in deep link handler (`flutter_deeplinking_enabled`) to prevent conflicts.

### GoRouter Integration

GoRouter has built-in deep linking support with path/query parameter parsing.

---

## 22. Monorepo Patterns

### Melos 7.3.x

- CLI tool for managing Dart/Flutter monorepos
- Used by FlutterFire and other major projects
- **Breaking change in v7**: All configuration under `melos:` key in `pubspec.yaml` (no separate melos.yaml)
- Features: bootstrapping, versioning, changelog generation, CI scripting, selective test running

### Pub Workspaces (Native, Dart 3.6+ / Flutter 3.27+)

- Native monorepo support: `resolution: workspace` in root pubspec.yaml
- Complementary to Melos (Melos adds CI/versioning features on top)

### Very Good CLI

- Opinionated starter templates for generating packages/apps
- Well-structured project scaffolding

**Best practice**: Pub Workspaces for dependency resolution + Melos for scripting, versioning, and CI orchestration.

## Version Quick Reference (April 2026)

| Technology | Version |
|------------|---------|
| Flutter | 3.41.x |
| Dart | 3.9–3.10 |
| Riverpod | 3.0.2–3.3.x |
| BLoC | 9.2.0 |
| GoRouter | 17.x |
| AutoRoute | 10.1.x |
| Dio | 5.x |
| Retrofit | 4.9.x |
| Drift | 2.30.x |
| Hive CE | 2.8–2.9.x |
| freezed | 3.2.x |
| Patrol | 4.0 |
| Melos | 7.3.x |
| Rive | 0.14.x |
| Lottie | 3.x |
| Signals | 6.x |
