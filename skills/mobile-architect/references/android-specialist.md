# Android Native (Kotlin + Jetpack Compose) — Deep Reference

**Always use `WebSearch` to verify version numbers, API levels, and library features. Android evolves with annual OS releases, quarterly Compose updates, and frequent Jetpack library releases. Last verified: April 2026.**

## Table of Contents
1. [Kotlin Language](#1-kotlin-language)
2. [Jetpack Compose Fundamentals](#2-jetpack-compose-fundamentals)
3. [Compose vs XML Views](#3-compose-vs-xml-views)
4. [Navigation](#4-navigation)
5. [Coroutines and Flow](#5-coroutines-and-flow)
6. [Data Persistence](#6-data-persistence)
7. [Networking](#7-networking)
8. [Architecture Patterns](#8-architecture-patterns)
9. [Dependency Injection](#9-dependency-injection)
10. [Testing](#10-testing)
11. [Android Studio and Build System](#11-android-studio-and-build-system)
12. [Jetpack Libraries](#12-jetpack-libraries)
13. [Performance](#13-performance)
14. [Material 3 and Theming](#14-material-3-and-theming)
15. [Kotlin Multiplatform (KMP)](#15-kotlin-multiplatform-kmp)
16. [Security](#16-security)
17. [Accessibility](#17-accessibility)
18. [Background Work](#18-background-work)
19. [Firebase Integration](#19-firebase-integration)
20. [Deep Linking and App Links](#20-deep-linking-and-app-links)
21. [Modularization](#21-modularization)
22. [Play Store Guidelines](#22-play-store-guidelines)
23. [Distribution](#23-distribution)
24. [Compose Patterns and Side Effects](#24-compose-patterns-and-side-effects)

---

## 1. Kotlin Language

### Current Version: Kotlin 2.3.20 (March 2026)

Kotlin 2.4.0 is in Beta.

### K2 Compiler

Stable since Kotlin 2.0.0 (May 2024). Delivers up to 2x faster compilation. kapt uses K2 by default in 2.2+. Build reports include compiler performance metrics for Kotlin/Native tasks.

### Key Language Features (2.2–2.3)

- **Name-based destructuring**: Match variables to property names instead of position — eliminates bugs from positional destructuring
- **Unused return value checker**: Warns when expression returns non-Unit/Nothing value that is silently dropped
- **Explicit backing fields**: Stable and default — `field` keyword for custom backing field types
- **Context-sensitive resolution**: Compiler resolves ambiguous overloads based on context
- **Java 25 interop**: Full compatibility with latest JVM

### KMP Improvements (2.2+)

- Swift export available by default
- Stable cross-platform compilation for Kotlin libraries
- New approach for declaring common dependencies

---

## 2. Jetpack Compose Fundamentals

### Current: Compose BOM 2026.03.00 / Compose UI 1.11.0-rc01

Jetpack Compose is the default UI toolkit for Android. Google apps are Compose-first. 24% of the top 1000 Play Store apps have adopted Compose.

### Key 2026 Features

- **Pausable Composition in Lazy Prefetch**: Enabled by default — fundamentally changes how the runtime schedules work, significantly reducing jank. Internal benchmarks show Compose now matches Views performance for scrolling
- **Background Text Prefetch**: Pre-warms text layout caches on background thread, reducing text layout jank
- **FlexBox()**: Upcoming container composable inspired by CSS flexbox, combining Row/Column with FlowRow/FlowColumn
- **Compose Hot Reload**: Stable and bundled by default (Compose Multiplatform 1.10.0+)

### What You Can Build Entirely in Compose

Full production apps including: all Material 3 components, navigation, animations, camera/media integration, widgets (via Glance), adaptive layouts for foldables/tablets. There is no longer a reason to start a new project with XML views.

### Core Concepts

- **Composable functions**: `@Composable` annotation marks UI-building functions
- **State**: `remember { mutableStateOf() }`, `rememberSaveable`, state hoisting
- **Recomposition**: Only affected composables recompose when state changes
- **Modifiers**: Chain-able UI modifications (padding, size, click, semantics)
- **Slots**: Content lambda parameters for composable composition

---

## 3. Compose vs XML Views

### Decision Framework (2026)

**Default: Compose for all new projects and new screens.**

| Factor | Compose | XML Views |
|--------|---------|-----------|
| **New projects** | Always | Never |
| **New screens in existing apps** | Yes | Only if team lacks Compose expertise |
| **Development speed** | 30-50% less code | Baseline |
| **Testing** | Semantics tree (superior) | View-based (Espresso) |
| **Animation** | Declarative, composable | More boilerplate |
| **Multiplatform potential** | Compose Multiplatform | None |

**When XML Views still make sense:**
- Legacy codebase with heavy View investment (migrate incrementally, not wholesale)
- Third-party SDKs providing View-based components (wrap with `AndroidView` composable)
- Team lacks Kotlin/Compose expertise and cannot invest in training

**Migration strategy**: Use interop APIs (`ComposeView` in XML, `AndroidView` in Compose). Migrate screen by screen, starting with leaf screens.

---

## 4. Navigation

### Navigation Compose 2.9.7

### Type-Safe Navigation (Stable since 2.8.0)

Replace string routes with `@Serializable` data classes/objects:

```kotlin
@Serializable data class Profile(val userId: String)
@Serializable object Home

// In NavHost
composable<Profile> { backStackEntry ->
    val profile: Profile = backStackEntry.toRoute()
}

// Navigate
navController.navigate(Profile(userId = "123"))
```

### Key 2.9.x Features

- `List<Enum>` as route argument type without custom NavType
- Value classes as routes or argument types (2.9.0-alpha03+)
- `CollectionNavType<T>` for collection-based arguments
- Multi-destination display support (SupportingPane for side-by-side destinations)
- Lint checks for missing `@Serializable` annotations on routes

### Navigation 3 (Experimental)

Introduced in Compose Multiplatform 1.10.0 with Material 3 adaptive layout support. Early stage — use Navigation 2.9.x for production.

### Best Practices

- Use type-safe routes for all new navigation
- Prefer `NavHost` with sealed class/interface route hierarchy
- Handle deep links via `deepLinks` parameter in `composable<Route>()`
- Avoid passing complex objects as navigation arguments — pass IDs and load from repository

---

## 5. Coroutines and Flow

### kotlinx.coroutines 1.10.x

### StateFlow

Hot flow with initial value — the standard for UI state in ViewModels:

- Always has a `.value` property; replays most recent value to new subscribers
- Conflates emissions (only latest value kept when collector is slow)
- Collect with `collectAsStateWithLifecycle()` in Compose (lifecycle-aware)

### SharedFlow

Hot flow for event broadcasting:

- No initial value; configurable `replay` and `extraBufferCapacity`
- Use for one-off events: navigation commands, snackbars, toasts
- Never create a new SharedFlow per call — store in a property

### Key Patterns

- **callbackFlow**: Converts callback-based APIs to Flow. Must call `awaitClose {}` for cleanup
- **channelFlow**: For concurrent flow production from different CoroutineContexts
- **stateIn() / shareIn()**: Convert cold flows to hot (with SharingStarted policy)
- **combine() / flatMapLatest() / map()**: Flow transformation operators

### Best Practices

- Use `StateFlow` for state, `SharedFlow` for events
- Scope flows to lifecycle: `repeatOnLifecycle(Lifecycle.State.STARTED)`
- Use `collectAsStateWithLifecycle()` in Compose (not `collectAsState()`)
- Avoid emitting state changes from `onEach` or side-effect operators

---

## 6. Data Persistence

### Room 2.8.3 (Room 3.0 in Alpha)

Google's official recommendation for structured data:

- Full KMP support since 2.7.0 (Android, iOS, JVM Desktop)
- Room 3.0 alpha adds JavaScript and WebAssembly support
- Kotlin-first: runtime converted to Kotlin, code generation produces Kotlin by default
- Compile-time SQL verification, migration support, Flow integration
- Requires Kotlin 2.0 minimum

### DataStore 1.2.1

- **Preferences DataStore**: Key-value pairs, no schema, coroutine-based
- **Proto DataStore**: Typed objects via Protocol Buffers, type-safe
- Replaces SharedPreferences — async, transactional, consistent
- Use for small config/settings data, not large datasets

### SQLDelight

- Generates Kotlin from SQL files — SQL-first approach
- Full KMP compatibility (Android, iOS, JVM, JS, Native)
- Best when you need maximum SQL control and cross-platform sharing
- No annotation processing — uses Gradle plugin

### Decision Framework

| Use Case | Recommended |
|----------|-------------|
| Structured relational data (Android-first) | Room |
| KMP + SQL-first approach | SQLDelight |
| Preferences/settings/small config | DataStore |
| Future-proofing for KMP + Web/WASM | Room 3.0 |

---

## 7. Networking

### Retrofit 3.0.0 (May 2025)

- Native coroutine support with suspend functions (no `Call<T>` needed)
- Uses OkHttp 4.12 under the hood
- Binary compatible with Retrofit 2.x
- Not KMP-compatible (JVM/Android only)

### OkHttp 5.3.0

- Separate JVM and Android artifacts (AAR for Android)
- Improved connection pooling, modern networking features

### Ktor Client 3.4.0 (March 2026)

- Pure Kotlin, fully KMP-compatible
- Plugin-based architecture (install only what you need)
- Built-in coroutine support
- Supports OkHttp, CIO, and other engines
- Best choice for KMP projects

### kotlinx.serialization 1.10.0

- JSON API stabilization (case-insensitive enum decoding, trailing commas, comments)
- KMP compatible — replaces Gson/Moshi for Kotlin-first projects
- Spring Boot 4 native integration module

### Decision Framework

| Scenario | Recommended |
|----------|-------------|
| Android-only, established project | Retrofit 3.0 + OkHttp 5.x |
| KMP / Kotlin-first | Ktor Client 3.4 |
| Migrating Retrofit → KMP | Ktorfit (Retrofit annotations on Ktor) |
| Serialization (all new projects) | kotlinx.serialization |

---

## 8. Architecture Patterns

### Google's Official Recommendation

Layered architecture: UI Layer → Domain Layer (optional) → Data Layer. MVVM is the default pattern with ViewModel + StateFlow/Compose state.

### MVVM (Model-View-ViewModel)

- Google-recommended default. ViewModel exposes StateFlow; Compose collects state
- Best for: medium-sized projects, teams following Jetpack guidelines
- "Now in Android" sample app demonstrates this pattern

### MVI (Model-View-Intent)

- Unidirectional data flow: immutable UI state, user actions as Intents, reducer-style updates
- Best for: complex UIs with many state transitions — naturally Compose-friendly
- Libraries: Orbit MVI, MVIKotlin

### Clean Architecture

- Use Cases encapsulate business logic; strict layer separation
- Layers: Presentation → Domain (Use Cases) → Data (Repositories)
- Best for: large teams, enterprise apps, maximum testability
- Can be combined with MVVM or MVI at the presentation layer

### Practical Guidance

| Project Scale | Recommended Pattern |
|--------------|---------------------|
| Small/medium | MVVM + Repository |
| Complex state management | MVI |
| Large team / enterprise | Clean Architecture + MVVM or MVI |

---

## 9. Dependency Injection

### Hilt 2.57.1

- Built on Dagger — compile-time safety and validation
- Google's official recommendation for Android DI
- KSP support (replaces kapt): `ksp "com.google.dagger:hilt-compiler:2.57.1"`
- AGP 9 support in Hilt Gradle plugin
- `@HiltViewModel`, `@Inject`, `@Module`, `@Provides`, `@Binds`

### Koin 4.0

- Pure Kotlin DSL — no code generation or annotation processing
- Full KMP support with compiler plugin
- `@InjectedParam` and `@Provided` annotations for Verify API
- Koin Annotations available for compile-time verification
- Simpler setup, smaller learning curve

### Decision Framework

| Scenario | Recommended |
|----------|-------------|
| Android-only, compile-time safety | Hilt |
| KMP projects, simpler setup | Koin |
| Libraries, minimal projects | Manual DI |

---

## 10. Testing

### Unit Testing

- **JUnit 5**: Preferred for pure unit tests (parameterized tests, nested tests)
- **MockK**: Preferred mocking library for Kotlin (over Mockito) — coroutine support, DSL syntax
- **Turbine 1.2.1**: Testing library for kotlinx.coroutines Flow — `flow.test { awaitItem(), awaitComplete() }`

### Compose Testing

- `createComposeRule()` provides ComposeTestRule
- Queries semantics tree (not View hierarchy)
- **Finders**: `onNodeWithText()`, `onNodeWithContentDescription()`, `onNodeWithTag()`
- **Actions**: `performClick()`, `performScrollTo()`, `performTextInput()`
- **Assertions**: `assertIsDisplayed()`, `assertTextEquals()`, `assertExists()`
- Can run on Robolectric (JVM, fast) or device/emulator

### Robolectric

- Runs Android tests on JVM without emulator — maintained by Google
- Supports Compose tests ("blazing fast Compose tests")
- Use AndroidX Test APIs for portability between Robolectric and device

### Espresso

- View-based UI testing — still relevant for hybrid apps with XML views
- Can run on Robolectric or real devices via AndroidX Test

### Best Practices

- Use Robolectric for fast local Compose tests; real devices for final validation
- Test ViewModels with Turbine for Flow assertions
- Use semantics `testTag` for stable test selectors
- Separate unit tests (/test) from instrumentation tests (/androidTest)

---

## 11. Android Studio and Build System

### Android Studio Narwhal 3 Feature Drop (2025.1.3)

**Gemini AI Features:**
- **Agent Mode**: Stable and default — handles multi-stage tasks (add features, generate tests)
- AGENTS.md project files for custom Gemini context
- Image-to-Compose code generation from UI mockups
- Unit test generation analyzing constructor dependencies
- MCP protocol support for external tool integration

### Android Gradle Plugin 9.1 (March 2026)

- Built-in Kotlin support (no separate `org.jetbrains.kotlin.android` plugin needed)
- New DSL interfaces (implementations fully hidden)
- Maximum supported API level: 36.1

### Gradle 9.0

- Configuration Cache stable and recommended
- Kotlin DSL is default for new builds
- Full IDE assistance (auto-completion, navigation, refactoring)
- Faster feedback loops with Kotlin 2 features

### Build Optimization

- Enable Configuration Cache for faster builds
- Use Gradle's `--scan` for performance analysis
- Version Catalogs (`gradle/libs.versions.toml`) for centralized dependency management
- Convention plugins for shared build configuration across modules
- Use BOM for Compose, Firebase to avoid version conflicts

---

## 12. Jetpack Libraries

### Key Libraries (April 2026)

| Library | Version | Purpose |
|---------|---------|---------|
| **WorkManager** | 2.11.2 | Reliable background work with constraints |
| **Paging** | 3.4.2 | Lazy loading with `collectAsLazyPagingItems()` |
| **CameraX** | 1.4.0-rc04 / 1.7.0-alpha01 | Camera capture, video, Media3 integration |
| **Media3** | 1.10.0 | Unified media playback (ExoPlayer successor) |
| **Glance** | 1.1.x | Compose-like API for Android widgets |
| **Lifecycle** | 2.9.x | Lifecycle-aware components, ViewModel |
| **DataStore** | 1.2.1 | Preferences and proto storage |

### Glance (App Widgets)

- Compose-like API: `GlanceAppWidget`, `provideContent {}`
- Background data fetching via WorkManager
- Limited to RemoteViews-compatible components
- Use for: glanceable information, quick actions

---

## 13. Performance

### Baseline Profiles

AOT compile critical code paths for faster startup and smoother interactions:

- **Impact**: Up to 30-40% faster startup. Google Maps achieved 30% faster startup (2.4% more searches). Meta reported 3-40% improvements
- **Implementation**: Macrobenchmark library with `BaselineProfileRule`
- **Cloud Profiles**: Google Play distributes aggregated profiles from other users
- R8 automatically rewrites profile rules to match obfuscated code

### Startup Profiles

- Drive DEX layout optimization — critical startup code placed in primary DEX file
- Combined with Baseline Profiles for maximum benefit

### R8 Optimization

- Default code shrinker/optimizer since AGP 3.4.0+
- Code shrinking, obfuscation, optimization, and resource shrinking in one step
- **Full mode recommended**: `android.enableR8.fullMode=true`
- Must be enabled for Baseline/Startup Profiles to work effectively

### Macrobenchmark

- Measures app-level metrics: startup time, scroll jank, animations
- Captures Perfetto traces for performance debugging
- CI-ready JSON output
- Firebase Test Lab for real-device benchmark execution

### Best Practices

1. Always generate Baseline Profiles for production apps
2. Enable R8 with full mode for release builds
3. Use Macrobenchmark for startup and scroll regression testing
4. Profile on physical devices — emulators are unreliable for performance
5. Test on mid-range devices (P50 user's device, not flagship)

---

## 14. Material 3 and Theming

### Compose Material 3 1.4.x (via BOM 2026.03.00)

### Material 3 Expressive (Android 16+)

- 15 new/refreshed components: button groups, split buttons, toolbars, loading indicators
- 35 new shape options with shape-morphing transitions
- Physics-based motion (springier, natural-feeling animations)
- Updated typography with larger sizes and heavier weights
- Richer dynamic color palettes

### Dynamic Color

Available on Android 12+ — derives color tones from user's wallpaper:

```kotlin
val colorScheme = when {
    dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S ->
        if (darkTheme) dynamicDarkColorScheme(context)
        else dynamicLightColorScheme(context)
    else ->
        if (darkTheme) DarkColorScheme else LightColorScheme
}
MaterialTheme(colorScheme = colorScheme) { /* content */ }
```

- Accessible by default (tonal palette system meets contrast standards)
- Falls back to custom theme on devices without dynamic color support

### Best Practices

- Use Compose BOM to avoid version mismatches
- Support both dynamic color and custom fallback theme
- Test with both light and dark themes
- Use Material 3 token system for consistent theming across app

---

## 15. Kotlin Multiplatform (KMP)

### Status: Production-ready (stable since November 2023)

Companies like Netflix, McDonald's, Cash App running in production.

### What to Share

- **Battle-tested**: Networking, data models, validation, business rules
- **Industry standard**: Shared ViewModels (up to 85% presentation logic)
- **Infrastructure**: Persistence (Room KMP, DataStore KMP), lifecycle
- **Tooling**: Analytics, logging, configuration

### What to Keep Native

- UI layer (Compose for Android, SwiftUI for iOS) — though Compose Multiplatform iOS is stable since 1.8.0
- Platform-specific APIs (camera, sensors, Bluetooth)

### Compose Multiplatform 1.10.3

- iOS support stable since 1.8.0; Web support in Beta (1.9.0+)
- Unified `@Preview` annotation across platforms
- Navigation 3 support (experimental)
- Compose Hot Reload stable and bundled by default
- Compatible with AGP 9.0.0

### Jetpack KMP Libraries

Room 2.8.3 / 3.0-alpha, DataStore 1.2.1, Lifecycle, ViewModel, Navigation Compose — all KMP compatible.

---

## 16. Security

### R8 / Code Obfuscation

- R8 is the default (ProGuard effectively replaced)
- Code shrinking, obfuscation, optimization
- Use `-keepattributes` and `-keep` rules for reflection-dependent code
- Full mode recommended

### Certificate Pinning

- Network Security Configuration XML with `<pin-set>` and expiration dates
- OkHttp `CertificatePinner` for programmatic pinning
- Always include backup pins and set expiration dates
- Note: OWASP 2025 now recommends against pinning due to operational risks — consider Certificate Transparency as an alternative

### Encrypted Storage

- `EncryptedSharedPreferences` with AES256_GCM encryption via `MasterKey`
- Part of `androidx.security:security-crypto`
- Use for API keys, tokens, sensitive preferences

### Biometrics

- `BiometricPrompt` API for fingerprint, face, iris
- Support levels: `BIOMETRIC_STRONG`, `BIOMETRIC_WEAK`, `DEVICE_CREDENTIAL`
- Use as convenience layer, not sole authentication factor

### 2026 Requirements

- Google Play Data Safety declaration mandatory
- EU Digital Markets Act compliance
- Network security config required for cleartext traffic opt-out

---

## 17. Accessibility

### TalkBack

- Gesture-based screen reader built into Android
- 2026: Gemini-powered features (richer camera descriptions, improved dictation)

### Compose Accessibility

- Semantics tree is the accessibility tree
- `Modifier.semantics { }` for custom properties
- `Modifier.clearAndSetSemantics { }` to override default semantics
- `mergeDescendants = true` to merge child semantics into parent
- Test with `onNodeWithContentDescription()` in ComposeTestRule

### Content Descriptions

- Required for images and graphical elements conveying meaning
- Must be precise and describe purpose, not appearance ("Favorite" not "Heart icon")
- Use `contentDescription` parameter: `Icon(contentDescription = "Search")`
- Decorative images: `contentDescription = null`

### Custom Accessibility Actions

- Replace default announcements
- Provide alternatives for gesture-based actions (drag-and-drop, swipes)
- `Modifier.semantics { customActions = listOf(...) }`

### Android 16 Improvements

- Outline text replaces high contrast text (larger contrasting area)

---

## 18. Background Work

### WorkManager 2.11.2 (Recommended for Most Tasks)

- Guaranteed execution with constraints (network, charging, battery)
- Survives process death and device reboots
- `OneTimeWorkRequest`, `PeriodicWorkRequest`
- Chaining, parallelism, unique work policies
- Expedited work for time-sensitive tasks

### Foreground Services

- Android 14+ requires foreground service type declaration in manifest
- Types: camera, microphone, location, mediaPlayback, dataSync
- Must show notification. Use for ongoing operations visible to user

### AlarmManager

- `SCHEDULE_EXACT_ALARM` permission required on Android 13+
- Use for: alarms, reminders, calendar events (precise timing required)
- Prefer `setAndAllowWhileIdle()` unless exact timing is critical

### Decision Framework

| Use Case | Recommended |
|----------|-------------|
| Deferrable, constraint-based work | WorkManager |
| Exact timing (alarms, reminders) | AlarmManager |
| User-visible ongoing operations | Foreground Service |

---

## 19. Firebase Integration

### Setup

Use Firebase BoM for consistent versioning: `platform("com.google.firebase:firebase-bom:33.x.x")`

### Key Services

| Service | Use Case |
|---------|----------|
| **Auth** | Email/password, Google Sign-In, phone auth, anonymous |
| **Firestore** | Real-time NoSQL with offline persistence |
| **Crashlytics** | Crash, non-fatal error, ANR reporting |
| **Analytics** | Events, user properties (foundation for other services) |
| **Remote Config** | Server-side configuration, A/B testing |
| **App Distribution** | Beta distribution to testers |
| **Cloud Messaging** | Push notifications via FCM |

### Best Practices

- Always use BoM for version alignment
- Initialize Crashlytics and Analytics early in application lifecycle
- Use Firestore offline persistence for offline-first data
- Integrate Analytics with Crashlytics for breadcrumb context

---

## 20. Deep Linking and App Links

### Deep Link Types

| Type | Verification | User Experience |
|------|-------------|-----------------|
| **URI Scheme** (`myapp://`) | None | Disambiguation dialog |
| **Web Links** (`http://`) | None | Opens browser or app |
| **App Links** (`https://`) | Domain verification | Opens directly in app |

### App Links Implementation

1. Create `/.well-known/assetlinks.json` on your domain
2. Declare intent filters with `android:autoVerify="true"` in manifest
3. Handle incoming intents in Activity/NavController

### Navigation Compose Integration

Type-safe deep links with `@Serializable` routes via `deepLinks` parameter in `composable<Route>()`.

### Best Practices

- Use App Links (HTTPS) for all user-facing links
- URI schemes only for internal app-to-app communication
- Deep link should go directly to content (no interstitials or logins blocking)
- Test on physical devices: `adb shell dumpsys package d` to verify domain approval
- Log deep link analytics for debugging

---

## 21. Modularization

### Module Types

```
:app                    → Application entry point
:feature:login          → Feature modules (one per feature)
:feature:home
:feature:profile
:core:network           → Shared infrastructure
:core:database
:core:ui
:core:common
:domain                 → Business logic, use cases (optional)
```

### Principles

- High cohesion, low coupling, dependency inversion
- Features depend on core modules, **never on each other**
- Navigation between features via Navigation Compose routes (type-safe)

### Dynamic Feature Modules

- Download features on demand via Play Feature Delivery
- Delivery modes: install-time, on-demand, conditional
- Reduces initial install size

### Best Practices

- Start with one feature module; build confidence before expanding
- Use convention plugins to share build configuration
- Core module at the bottom: networking, analytics, design system
- Feature modules should be independently buildable and testable
- Use API modules for public interfaces, impl modules for implementations

---

## 22. Play Store Guidelines

### Target API Level Requirements

| Deadline | Required API Level |
|----------|-------------------|
| August 31, 2025 | API 35 (Android 15) |
| August 31, 2026 | API 36 (Android 16) |

New app submissions require API 36 starting April 2026.

### Android 16 (API 36) Key Changes

- Live Updates notifications for ongoing activities
- Health Connect FHIR support
- Orientation/resize/aspect ratio restrictions removed on ≥600dp displays
- Auto-expiring permissions for unused apps
- MediaStore version unique per app (anti-fingerprinting)

### Publishing Requirements

- Android App Bundle (AAB) format required (not APK)
- Data Safety declaration mandatory
- EU Digital Markets Act data protection compliance
- Provide test accounts for apps with login

---

## 23. Distribution

### Google Play Console Tracks

| Track | Audience | Review |
|-------|----------|--------|
| Internal testing | Up to 100 testers | Instant, no review |
| Closed testing | Limited, invite-only | Requires review |
| Open testing | Public beta | Requires review |
| Production | Full release | Staged rollout supported |

### Firebase App Distribution

- Fast distribution without Play Store review
- Supports AAB format (integrates with Play internal app sharing)
- CLI, Console, and CI/CD integration (Fastlane, GitHub Actions)
- Tester groups management with email/in-app notifications

### Best Practices

- Use Firebase App Distribution for rapid QA iteration
- Play Console Internal Testing for final pre-release validation
- Production: staged rollout (start 1-5%, monitor crashes, increase)

---

## 24. Compose Patterns and Side Effects

### State Management

- **`remember { mutableStateOf() }`**: Stores values across recompositions
- **`remember(key) { }`**: Recomputes when key changes
- **`rememberSaveable`**: Survives configuration changes and process death
- **`derivedStateOf`**: Creates derived state — only recomposes when derived value changes. Use when inputs change more frequently than needed

### Side Effects

| Effect | Purpose | Cleanup |
|--------|---------|---------|
| **`LaunchedEffect(key)`** | Suspend function on enter/key change | Auto-cancels |
| **`DisposableEffect(key)`** | Effect with `onDispose {}` cleanup | Manual cleanup |
| **`SideEffect`** | Non-suspending, runs after every composition | None |
| **`rememberUpdatedState`** | Captures latest value without restarting effect | None |

### Stability

Compose stability affects recomposition skipping:

- **`@Immutable`**: Public properties never change after construction
- **`@Stable`**: Property changes are observable via Compose snapshot system
- Unstable parameters force recomposition even when values didn't change
- Use Compose compiler reports to identify stability issues
- Prefer primitive types, String, and `@Immutable`/`@Stable` annotated classes for parameters

### Best Practices

- Hoist state to the lowest common ancestor
- Use `LaunchedEffect` for API calls, navigation side effects
- Use `DisposableEffect` for registering/unregistering listeners
- Use `derivedStateOf` for scroll position threshold checks and filtered lists
- Avoid creating new lambdas in `remember` blocks — use `rememberUpdatedState` instead
