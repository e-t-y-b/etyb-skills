# iOS Native (Swift + SwiftUI) — Deep Reference

**Always use `WebSearch` to verify version numbers and features. Apple releases major Xcode and iOS updates annually at WWDC, with point releases throughout the year. Last verified: April 2026.**

## Table of Contents
1. [Swift Language](#1-swift-language)
2. [SwiftUI Maturity](#2-swiftui-maturity)
3. [UIKit vs SwiftUI](#3-uikit-vs-swiftui)
4. [Navigation](#4-navigation)
5. [Swift Concurrency](#5-swift-concurrency)
6. [Data Persistence](#6-data-persistence)
7. [Networking](#7-networking)
8. [Architecture Patterns](#8-architecture-patterns)
9. [Dependency Injection](#9-dependency-injection)
10. [Testing](#10-testing)
11. [Xcode and Tooling](#11-xcode-and-tooling)
12. [App Lifecycle and Extensions](#12-app-lifecycle-and-extensions)
13. [Privacy and Security](#13-privacy-and-security)
14. [Performance](#14-performance)
15. [App Store Guidelines](#15-app-store-guidelines)
16. [Distribution](#16-distribution)
17. [SwiftUI Component Patterns](#17-swiftui-component-patterns)
18. [Combine vs async/await](#18-combine-vs-asyncawait)
19. [Apple Platform Integration](#19-apple-platform-integration)
20. [visionOS and Spatial Computing](#20-visionos-and-spatial-computing)
21. [Package Management](#21-package-management)
22. [Accessibility](#22-accessibility)
23. [Localization](#23-localization)
24. [Background Processing](#24-background-processing)

---

## 1. Swift Language

### Current: Swift 6.2 (September 2025, shipped with Xcode 26)

### Swift 6 Concurrency Safety

Swift 6.0 (September 2024) made complete concurrency checking default. Data-race safety is enforced at compile time. The `Sendable` protocol and `@Sendable` closures are strict requirements under Swift 6 language mode.

### Swift 6.1 (March 2025)

- **Trailing commas everywhere** (SE-0439): arrays, tuples, function parameters, generic parameters
- **`@implementation` attribute** for Objective-C interop
- **`nonisolated` on types and extensions** — full type-level isolation control
- **Package Traits**: conditional compilation for environments like Embedded Swift and WebAssembly

### Swift 6.2 — "Approachable Concurrency"

The headline theme is making concurrency easier to adopt:

- **Default Main Actor isolation** (opt-in per target): Code runs on main thread without explicit `@MainActor` — ideal for UI code
- **`@concurrent` attribute** (SE-0461): Explicitly mark functions that should run off the caller's actor
- **Nonisolated async methods** now execute on the caller's actor rather than jumping threads
- **Sendable improvements**: Properties of Sendable types, partial/unapplied method references automatically `@Sendable`
- **Isolated deinitializers** (SE-0371): Actor-isolated classes can mark `deinit` as isolated
- **New `Subprocess` package**: Concurrency-friendly API for launching external processes
- **Enhanced debugging**: Reliable async stepping in LLDB, task context surfacing, named tasks in profiling

### Best Practices

- Enable Swift 6 language mode for new projects
- For existing projects, adopt upcoming features incrementally
- Use `@concurrent` when you explicitly need off-actor execution
- Use named tasks for debugging visibility

---

## 2. SwiftUI Maturity

### Production-Ready for Most Applications (2026)

SwiftUI is now 7 years old. The claim "SwiftUI isn't ready for serious work" no longer holds.

### What You Can Build Entirely in SwiftUI

- Standard CRUD apps, settings screens, forms, lists, detail views
- Multi-platform apps (iOS, iPadOS, macOS, watchOS, tvOS, visionOS)
- Complex navigation hierarchies with NavigationStack/NavigationSplitView
- Rich animations, custom transitions, matched geometry effects
- Widget extensions, Live Activities, App Intents surfaces
- Spatial computing interfaces (visionOS)

### What Still Benefits from UIKit

- Browsers and creative tools with extreme rendering demands
- Deeply customized collection view layouts and cell animations
- Custom view controller transitions with precise control
- Third-party SDKs providing only UIKit components

### iOS 26 / WWDC 2025 Highlights

- **Liquid Glass**: New translucent design language with real-time light bending. Apps using native SwiftUI controls get Liquid Glass automatically by recompiling against iOS 26 SDK
- **Rich text editor** with enhanced `AttributedString`
- **Strengthened SwiftUI-UIKit/AppKit interop** — Apple acknowledges both frameworks will coexist
- Tab bars/sidebars redesigned (shrink on scroll, expand on scroll-back)
- New **SwiftUI Instrument** for understanding when/why views update
- iOS version numbering jumped from iOS 18 to **iOS 26** (aligning with calendar year)

---

## 3. UIKit vs SwiftUI

### Decision Framework (2026)

**Default: SwiftUI for all new projects** unless specific requirements push toward UIKit.

| Factor | SwiftUI | UIKit |
|--------|---------|-------|
| **New projects** | Default choice | Only for specific requirements |
| **Multi-platform** | iOS + Mac + Watch + TV + Vision | iOS only (separate per platform) |
| **Development speed** | Significantly faster (declarative) | More boilerplate |
| **Performance** | 95% of UIKit for most cases | 5-10% edge in benchmarks |
| **Customization** | Growing rapidly | Maximum control |
| **Testing** | Preview-driven, snapshot-friendly | XCUITest, mature tooling |

### Performance Reality

- UIKit is 5-10% faster in benchmarks
- List scrolling: UIKit 60fps vs SwiftUI 58fps — imperceptible
- SwiftUI is "fast enough" for 95% of use cases

### Hybrid Approach (Recommended for Existing Apps)

70% of professional teams use hybrid. Build new screens in SwiftUI, gradually migrate UIKit as you touch it. Use `UIViewRepresentable` / `UIViewControllerRepresentable` for bridging.

---

## 4. Navigation

### NavigationStack (iOS 16+)

- Stack-based navigation similar to UIKit's navigation controllers
- `NavigationPath` for dynamic, state-driven, programmatic navigation
- `.navigationDestination(for:)` for type-based routing
- Enables deep linking and pop-to-root functionality

### NavigationSplitView (iOS 16+)

- Two-column and three-column layouts for iPad and Mac
- Automatically wraps root views in sidebar, content, and detail columns
- No manual NavigationStack wrapping needed unless navigating outside content pane

### Coordinator Pattern

- Feature Coordinators manage navigation flow, dependency injection, deep linking
- Abstracts navigation logic away from individual views
- Works with NavigationStack and NavigationPath
- Testable and maintainable for complex navigation graphs

### Best Practices

- `NavigationStack` for single-column flows, `NavigationSplitView` for multi-column
- Keep navigation state in `@Observable` objects for testability
- Use sheet presentation for modal flows
- Implement deep links through the coordinator/path layer

---

## 5. Swift Concurrency

### async/await

The recommended approach for all asynchronous work. Reads like synchronous code with compile-time safety guarantees through Sendable checking.

### Actors

First-class primitives for protecting mutable state from data races:
- Serial execution of methods on an actor's isolated state
- `@MainActor` for UI-bound work; custom actors for domain-specific isolation
- In Swift 6.2, default main-actor isolation makes UI code simpler

### TaskGroup

`withTaskGroup(of:)` and `withThrowingTaskGroup(of:)` for concurrent work:
- Manages child tasks, ensures all complete before scope exits
- Results collected via `for await` or `reduce`

### AsyncStream / AsyncSequence

- `AsyncStream` bridges callback-based or delegate APIs into async sequences
- Swift Async Algorithms package provides operators (merge, combineLatest, debounce, throttle)
- Note: `AsyncStream` can break structured concurrency if continuation escapes scope

### Best Practices

- Prefer structured concurrency (`async let`, `TaskGroup`) over unstructured `Task { }`
- Use actors instead of locks/queues for mutable shared state
- Mark types `Sendable` when they cross isolation boundaries
- Use `@concurrent` in Swift 6.2 when you need off-actor execution
- Leverage named tasks for debugging visibility

---

## 6. Data Persistence

### SwiftData (iOS 17+ — Recommended for New Projects)

- Apple's modern persistence framework built on Core Data's SQLite store
- `@Model` macro — no separate model editor needed
- Deep SwiftUI integration with `@Query` property wrapper
- CloudKit sync built-in (private database only)
- 48% faster development cycles, 65% fewer persistence-related crashes vs Core Data
- **Limitations**: No `NSFetchedResultsController` equivalent, no group-by queries, limited migration tooling, only private CloudKit zones, `@Attribute(.unique)` incompatible with CloudKit

### Core Data (Mature, Still Relevant)

- Slightly faster for large datasets and complex queries
- Full migration support (lightweight and heavyweight)
- `NSFetchedResultsController` for efficient list updates
- Supports shared CloudKit databases
- Best for: medical records, complex migrations, legacy stores

### GRDB.swift 7.10.x

- Thin, powerful wrapper around SQLite — 100% open source Swift
- Value-type models (structs) rather than class-based objects
- Supports raw SQL alongside query builder
- Best for: direct SQLite control, maximum transparency

### Decision Framework

| Use Case | Recommended |
|----------|-------------|
| New apps, iOS 17+ | SwiftData |
| Complex enterprise, legacy stores | Core Data |
| Cross-platform (iOS + Android) | Realm |
| Maximum SQL control | GRDB.swift |
| CloudKit sync (simple) | SwiftData |
| CloudKit sync (complex/shared) | Core Data + NSPersistentCloudKitContainer |

---

## 7. Networking

### URLSession (Built-in — Recommended Default)

- Native async/await: `let (data, response) = try await URLSession.shared.data(from: url)`
- Handles JSON fetching, file downloads, uploads, background transfers
- `URLSessionWebSocketTask` for WebSockets
- No third-party dependency needed for most apps

### Alamofire 5.11.x (April 2026)

- Requires Xcode 16.0 and Swift 6 compiler
- Full async/await support
- Key advantages: request adaptation/retry (`RequestInterceptor`), certificate pinning, response validation, multipart uploads, network reachability
- New `OfflineRetrier` for retrying based on `NWPathMonitor`
- Best for: complex auth (token refresh), sophisticated retry logic, certificate pinning

### Best Practices

- Default to `URLSession` with async/await for new projects
- Add Alamofire if you need request adaptation/retry, complex auth, or certificate pinning
- Use `Codable` for JSON serialization
- Handle errors with typed error enums, not generic `Error`
- Monitor connectivity with `NWPathMonitor` (Network framework)

---

## 8. Architecture Patterns

### MVVM (Most Popular in 2026)

- Works naturally with SwiftUI's data flow (`@Observable` ViewModels)
- Testable and maintainable — the "sweet spot" for most apps
- Best for: small to medium teams, most app categories

### TCA — The Composable Architecture (Point-Free)

- Redux-inspired for SwiftUI with unidirectional data flow, reducers, effects
- Used by Adidas, Crypto.com, The Browser Company
- Excellent testability, time-travel debugging, built-in dependency injection
- **Steep learning curve** — functional programming background helpful
- Best for: large teams, apps requiring predictable state management

### Clean Architecture

- Domain, data, and presentation layer separation
- Best for: enterprise apps, large teams where coordination matters

### MV (Model-View) Pattern

- Lightweight: `@Observable` models used directly by views
- Eliminates ViewModel boilerplate for simpler features
- Can lead to bloated models in complex scenarios

### Decision Framework

| Project Scale | Recommended |
|--------------|-------------|
| Solo / small team, standard app | MVVM |
| Large team, complex state | TCA |
| Enterprise, team coordination | Clean Architecture |
| Simple features, prototyping | MV pattern |

---

## 9. Dependency Injection

### Constructor Injection (Start Here)

Pass dependencies through initializers. Compile-time safe. No framework needed.

### SwiftUI Environment

- `@Environment` and `@EnvironmentObject` for injecting through the view hierarchy
- Limitation: tied to SwiftUI view tree — can't access in non-view code

### Factory (by hmlongco)

- Container-based DI for Swift and SwiftUI
- Compile-time safe — a factory must exist or code won't compile
- Supports scopes, lazy registration, auto-injection

### Swift-Dependencies (Point-Free)

- API inspired by SwiftUI's Environment, powered by task-local machinery
- Works outside views (reducers, services)
- Pairs naturally with TCA but usable independently
- Built-in test/preview/live values

### Best Practices

- Start with constructor injection — graduate to a framework as the app grows
- `@Environment` for SwiftUI-specific values (color scheme, locale)
- Factory or Swift-Dependencies for service-layer DI outside views
- Always provide mock/preview implementations

---

## 10. Testing

### XCTest (Built-in, Mature)

- Apple's foundational framework for unit, performance, and UI tests
- `XCUITest` for UI automation: taps, swipes, text entry
- Performance tests with `measure { }` blocks

### Swift Testing (Recommended for New Tests)

- `@Test` macro — no `XCTestCase` subclass needed
- **Parameterized tests**: `@Test(arguments: [1, 2, 3])` — automatic iteration
- `#expect()` macro replaces `XCTAssert*` with better diagnostics
- `@Suite` for organizing tests
- Traits system for shared setup/teardown (`TestScoping` in Swift 6.1+)
- **Coexists with XCTest** — both work in the same target

### Snapshot Testing (Point-Free)

- Works with both Swift Testing and XCTestCase
- Snapshot any value: UIViews, CALayers, strings, data
- Snapshots saved alongside test files for version control
- Catches visual regressions automatically

### Migration Strategy

- Write new tests with Swift Testing
- Keep XCTest for UI tests (`XCUITest`) — Swift Testing doesn't replace UI testing yet
- Migrate incrementally, starting with tests that benefit from parameterization

---

## 11. Xcode and Tooling

### Xcode 26 (Current, with patches through 26.3)

### Build System

- **Swift Build** — open-source build system engine
- **35% faster build times** (30-40% from caching)
- **40% faster workspace loading**
- **50% typing latency improvement** in complex expressions

### AI Integration

- Built-in coding intelligence supporting **ChatGPT, Claude, Gemini**, and local models (Ollama/LM Studio)
- **Agentic coding** (Xcode 26.3): Agents search docs, explore files, update settings, capture Previews, iterate builds/fixes autonomously
- **Model Context Protocol (MCP)** support
- Developers choose models, mark favorites, use own API keys

### Debugging

- Reliable async stepping in LLDB for Swift Concurrency
- Task context visibility — see which task code runs on
- Named tasks in debugging and profiling tools
- New **SwiftUI Instrument** — captures when/why views update

---

## 12. App Lifecycle and Extensions

### Scene-Based Lifecycle

- `@main` with `App` protocol and `Scene` body
- `WindowGroup`, `DocumentGroup`, `Settings` scenes
- `ScenePhase` environment value for active/inactive/background states

### Widget Extensions (WidgetKit)

- 2026: "surface-centric" design — widgets are primary interaction surfaces
- Interactive widgets with Button and Toggle via App Intents
- Spatial on visionOS (snap to walls and tables)
- **3-Second Rule**: Users expect micro-tasks in under 3 seconds from widgets

### Live Activities (ActivityKit)

- Real-time, glanceable widgets on Lock Screen and Dynamic Island
- SwiftUI + WidgetKit layout
- Interactivity via `Button(_:intent:)` and `Toggle(_:isOn:intent:)` with App Intents
- Updated via push notifications or ActivityKit

### App Intents Framework

- Gateway to Siri, Shortcuts, Spotlight, Apple Intelligence, and Action button
- **Expected rather than optional** in 2026
- Primary mechanism for widget and Live Activity interactivity

---

## 13. Privacy and Security

### Privacy Manifests (Mandatory)

- `PrivacyInfo.xcprivacy` file required for all apps and SDKs
- Declare: data collected, purpose, linked/unlinked to identity, tracking status
- Document third-party library data collection
- Must declare "required reason APIs" usage (UserDefaults timestamp, file timestamp, disk space)
- Apple automatically rejects incomplete/inaccurate manifests

### Keychain Services

- Required for passwords, authentication tokens, encryption keys
- Hardware-backed encryption with biometric authentication
- **Never use UserDefaults or property lists for sensitive data**

### App Attest / DeviceCheck

- `DCAppAttestService` for hardware-backed assertions
- Verify requests from legitimate app instances on genuine Apple devices
- Use for fraud prevention and server-side validation

### App Transport Security (ATS)

- Enforces HTTPS connections
- Exceptions must be declared and justified during review

---

## 14. Performance

### Instruments

- **Time Profiler**: CPU bottleneck identification
- **Allocations**: Memory growth tracking, "Mark Generation" between user actions
- **Leaks**: Retain cycle detection
- **SwiftUI Instrument** (Xcode 26): When/why views update
- **Network**: Request timing and payload sizes
- **Energy Log**: Power consumption by subsystem

### ARC (Automatic Reference Counting)

- Tracks strong reference counts; deallocates at zero
- **Retain cycles**: Primary source of memory leaks — use `[weak self]` or `[unowned self]`
- Memory Graph Debugger in Xcode: Visualize references, find cycles

### Xcode Organizer

- Crash logs, energy reports, disk writes, launch times from real users
- MetricKit for field performance metrics

### Best Practices

1. Profile with Instruments regularly, not just when problems appear
2. Use `@Observable` instead of `ObservableObject` for efficient view updates
3. Lazy-load views with `LazyVStack`/`LazyHStack`
4. Avoid GeometryReader in main view tree — use `.background` or `.overlay`
5. Monitor memory with Memory Graph Debugger during development

---

## 15. App Store Guidelines

### Review Process

- Up to 90% of submissions reviewed within 24 hours
- Five areas: Safety, Performance, Business, Design, Legal
- ~25% rejection rate (7.77M reviewed in 2024)

### Common Rejections

1. **Crashes and bugs**: Incomplete features, broken links, stability issues
2. **Privacy violations**: Missing/inaccurate privacy manifests, inadequate consent
3. **Design issues**: Non-standard UI, pure WebView wrappers, HIG violations
4. **Metadata problems**: Misleading screenshots, broken privacy policy links
5. **In-app purchase issues**: Missing pricing, unclear subscription terms
6. **Minimum functionality**: Apps too simple or replicating website without native value

### 2026 Requirements

- Starting April 2026: All apps must be built with **iOS 26 SDK** (Xcode 26+)
- Privacy manifests mandatory
- AI feature disclosure required

---

## 16. Distribution

### TestFlight

- Up to 10,000 external testers, 100 internal testers
- 90-day build expiration
- "Ready for Sale" renamed to **"Ready for Distribution"**

### App Store Connect

- 11 additional languages supported
- Enhanced TestFlight feedback sorting
- Improved accessibility features

### Enterprise Distribution

- Apple Enterprise Program actively discouraged
- Recommended: **Custom Apps** through Apple Business Manager / Apple School Manager
- Standard Developer Program ($99/year) covers most needs including private distribution
- Enterprise Program ($299/year) still exists

### Alternative Distribution (EU)

- Alternative app marketplaces under Digital Markets Act
- Notarization required for sideloaded apps

---

## 17. SwiftUI Component Patterns

### @Observable Macro (iOS 17+)

Replaces `ObservableObject` / `@Published`:
- All stored properties automatically observable — no `@Published` needed
- Views only re-render when properties they **actually read in body** change (granular observation)
- Significant performance improvement over `ObservableObject`
- Use `@State` to own the instance, `@Bindable` for binding to unowned instances

### ViewModifiers

- Custom modifiers via `ViewModifier` protocol for reusable styling/behavior
- Compose modifiers for consistent design systems
- Create custom view extensions for clean API

### Custom Layouts (iOS 16+)

- `Layout` protocol for custom container layouts
- Replaces many GeometryReader use cases
- Implement `sizeThatFits` and `placeSubviews`

### GeometryReader

- Provides access to parent size and coordinate space
- **Avoid in main view tree** — use `.background` or `.overlay` with `PreferenceKey`
- iOS 17+: `onGeometryChange` modifier is a better alternative

---

## 18. Combine vs async/await

### Combine Status

Not officially deprecated but effectively in maintenance mode. No new APIs at WWDC 2023, 2024, or 2025. Still useful for reactive UI bindings and complex data pipelines.

### When to Use Each

| Scenario | Recommendation |
|----------|---------------|
| One-shot async operations | async/await |
| Sequential async chains | async/await |
| Parallel work with results | TaskGroup |
| Continuous data streams | AsyncStream / AsyncSequence |
| Complex reactive pipelines | Combine or Swift Async Algorithms |
| SwiftUI bindings to publishers | Combine (or migrate to @Observable) |
| New projects | async/await + Swift Async Algorithms |

### Migration

- `values` property bridges Combine publishers to AsyncSequence
- Swift Async Algorithms closes the operator gap (merge, combineLatest, debounce, throttle)
- No need to rewrite all Combine code at once — both coexist

---

## 19. Apple Platform Integration

### StoreKit 2

- Modern async/await API for in-app purchases and subscriptions
- `Product`, `Transaction`, `Subscription.Status` types
- Server-side validation with App Store Server API and Notifications V2
- StoreKit Testing in Xcode for local development

### HealthKit

- Read/write health and fitness data with user permission
- Workout session support for Apple Watch
- Background delivery for health data updates

### MapKit

- `Map` SwiftUI view with annotations and overlays
- Look Around, route planning, points of interest

### WeatherKit

- Weather data API: 500,000 calls/month on base tier
- `WeatherService` with async/await support

---

## 20. visionOS and Spatial Computing

### visionOS 26

- Consumer-oriented platform (beyond niche pro tool)
- Apps **aligned to physical surfaces**, persisting across restarts
- Spatial widgets snap to walls and tables

### Development

- **SwiftUI** is the recommended framework
- `RealityKit` for 3D content and immersive experiences
- `ARKit` for hand tracking, scene understanding, world anchoring

### Window Types

| Type | Purpose |
|------|---------|
| `WindowGroup` | Standard 2D windows |
| `.windowStyle(.volumetric)` | 3D bounded volumes |
| `ImmersiveSpace` | Full immersive experiences |

### Cross-Platform

- Most iOS SwiftUI apps run on visionOS in compatible window mode
- `#if os(visionOS)` for platform-specific spatial features

---

## 21. Package Management

### Swift Package Manager (SPM) — The Standard

- Built into Swift and Xcode — no separate installation
- Supports binary dependencies, resources, plugins, package traits (Swift 6.1+)
- Xcode 26 includes new SPM implementation preview

### CocoaPods — Sunsetting

- **Trunk becomes permanently read-only December 2, 2026**
- No new pods or updates after that date
- **Migrate to SPM before December 2026**

### Carthage — Legacy

- Still functional but no significant development
- Migrate to SPM

---

## 22. Accessibility

### VoiceOver

- SwiftUI views automatically inherit accessibility labels from `Text`
- Images and custom views need explicit `accessibilityLabel()`
- `accessibilityHint()` for action results
- `accessibilityValue()` for current state
- `accessibilityElement(children: .combine)` to group child views

### Dynamic Type

- System fonts or `.scaledFont()` for automatic size adjustment
- Test with all Dynamic Type sizes (xSmall to AX5)
- `@ScaledMetric` property wrapper for scaling numeric values

### SwiftUI Accessibility Modifiers

- `.accessibilityAction()`, `.accessibilityAdjustableAction()`, `.accessibilityScrollAction()`
- `.accessibilityRotor()` for custom VoiceOver rotors
- `.accessibilitySortPriority()` for reading order
- `.accessibilityRepresentation()` for custom representations

### 2026 Updates

- **Accessibility Nutrition Labels**: Register supported accessibility features in App Store Connect
- Improved VoiceOver with iOS 26 SwiftUI modifiers

---

## 23. Localization

### String Catalogs (.xcstrings) — The Standard

- Replaces fragmented `.strings` + `.stringsdict` with unified system
- Xcode scans Swift, SwiftUI, Interface Builder to auto-extract strings
- Built-in plural support (no more `.stringsdict` files)
- Translation state tracking in IDE

### Xcode 26 Enhancements

- **AI-generated context comments** for translators
- **Type-safe symbol generation**: `String(localized:)` with compiler-checked access
- Format version 1.1 (backward compatible with 1.0)

### Workflow

1. Add `Localizable.xcstrings` to project
2. Use `Text("key")` or `String(localized: "key")` in code
3. Xcode auto-discovers and populates catalog
4. Export `.xcloc` files for translators
5. Import translations back

---

## 24. Background Processing

### BGTaskScheduler (Primary API)

- **BGAppRefreshTask**: Periodic background fetch (~15-30 seconds)
- **BGProcessingTask**: Longer tasks (minutes), during charging/idle
- Register in `Info.plist` under `BGTaskSchedulerPermittedIdentifiers`
- Not guaranteed to run at exact times — system decides based on battery, connectivity, usage

### Silent Push Notifications

- Wake app with `content-available: 1`
- 30 seconds execution time
- Not guaranteed delivery — depends on device conditions
- Low Power Mode may postpone

### Best Practices

- `BGAppRefreshTask` for periodic data sync (news, email, feeds)
- `BGProcessingTask` for heavy work (ML training, data cleanup)
- Silent push notifications for time-sensitive server-triggered updates
- Always handle delayed or denied execution gracefully
- Test with LLDB: `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"your.task.id"]`

## Version Quick Reference (April 2026)

| Technology | Version |
|------------|---------|
| Swift | 6.2.4 |
| Xcode | 26.3 |
| iOS / iPadOS | 26.x |
| macOS | Tahoe 26 |
| watchOS | 26 |
| visionOS | 26 |
| SwiftData | iOS 17+ (3rd year) |
| Alamofire | 5.11.2 |
| GRDB.swift | 7.10.0 |
| CocoaPods | Sunsetting Dec 2, 2026 |
| Swift Testing | Ships with Xcode 16+ |
