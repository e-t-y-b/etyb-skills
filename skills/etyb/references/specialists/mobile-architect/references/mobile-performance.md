# Mobile Performance — Deep Reference

**Always use `WebSearch` to verify version numbers, tool capabilities, and platform-specific thresholds. Mobile performance tools and OS constraints change with every major OS release. Last verified: April 2026.**

## Table of Contents
1. [App Size Optimization](#1-app-size-optimization)
2. [Startup Time](#2-startup-time)
3. [Rendering Performance](#3-rendering-performance)
4. [Memory Management](#4-memory-management)
5. [Battery Optimization](#5-battery-optimization)
6. [Network Optimization](#6-network-optimization)
7. [Offline-First Architecture](#7-offline-first-architecture)
8. [Profiling and Monitoring](#8-profiling-and-monitoring)
9. [Animation Performance](#9-animation-performance)
10. [Performance Testing and Budgets](#10-performance-testing-and-budgets)

---

## 1. App Size Optimization

App size directly impacts install conversion — every 6MB increase reduces installs by approximately 1%. Target under 40MB for consumer apps, under 60MB for enterprise apps.

### Platform-Specific Strategies

**Android:**
- **R8 code shrinking**: Removes unused classes/methods, achieving 20-50% size reduction. R8 (default since AGP 3.4) combines desugaring, shrinking, obfuscation, and optimization in a single step
- **Android App Bundle (AAB)**: Generates optimized split APKs per device configuration (screen density, CPU architecture, language). Google Play mandates AAB format
- **Dynamic Feature Modules**: On-demand delivery of features, reducing initial install size. Three delivery modes: install-time, on-demand, and conditional

**iOS:**
- **App Thinning**: Delivers only resources needed for specific devices through App Slicing (asset variants) and On-Demand Resources (ODR) for assets downloaded as needed
- **Swift Optimizer**: Strips unused code in release builds
- **Asset catalogs**: Proper use ensures only relevant density assets are included

**React Native:**
- **Hermes bytecode**: Pre-compilation reduces JS bundle size by 15-25% compared to JSC. Hermes is the default engine since RN 0.84 (February 2026)
- **Tree-shaking with Metro**: Combined with dynamic imports, can achieve 30-70% bundle reduction
- **Minimal app baseline**: ~5-8MB (Android), ~10-15MB (iOS)

**Flutter:**
- **Dart AOT tree shaking**: Automatically eliminates unused code and libraries in release builds
- **Deferred Components**: Split heavy features into on-demand modules via deferred imports
- **Minimal app baseline**: ~8-12MB (Android), ~15-20MB (iOS) due to bundled rendering engine
- Real-world case: teams have achieved 64% size reduction (87MB → 31MB) through systematic optimization, tripling install rates

### Common Anti-Patterns
- Bundling unused assets (fonts, images, localization files)
- Including debug symbols in release builds
- Not splitting by ABI on Android (shipping arm64 + x86 + armv7 together)
- Using PNG when WebP/AVIF would suffice
- Including entire icon libraries when only a few icons are used

---

## 2. Startup Time

### Cold vs Warm vs Hot Start

| Type | Definition | Target (2026) |
|------|-----------|---------------|
| **Cold start** | App process not in memory; full initialization | TTID < 2s, TTFD < 4s |
| **Warm start** | Process exists but Activity/ViewController needs recreation | < 1.5s |
| **Hot start** | Activity/ViewController brought to foreground | < 1s |

TTID = Time to Initial Display. TTFD = Time to Full Display (all content loaded).

### Android: Baseline Profiles

Baseline Profiles are developer-defined rules shipped in the AAB that tell ART which code paths to AOT-compile on install:

- **Performance impact**: Up to 30-40% faster startup. Google Maps achieved 30% faster startup, driving 2.4% more searches. Meta reported 3-40% improvements across start, scroll, and navigation
- **Implementation**: Use Jetpack Macrobenchmark library with `BaselineProfileRule`. Available since AGP 8.2 / Android Studio Iguana
- **Cloud Profiles**: Google Play distributes aggregated profiles from other users as a complement

### iOS: Pre-main Time Optimization

Pre-main encompasses everything before `main()`: dyld loading, ObjC/Swift runtime setup, `+load` methods, static initializers:

- **dyld launch closures** (iOS 16+): Pre-compute conformances, accelerating lookups
- **Static linking**: Reduces dyld overhead — DoorDash reduced iOS launch time by 60% through static linking and reducing dynamic frameworks
- **Xcode Predictive Profiling**: Simulates launch performance across devices using ML models
- **Key strategy**: Reduce work, delay work, measure correctly. Fewer dynamic frameworks = less dyld overhead

### React Native: Hermes Pre-compilation

- Hermes compiles JS to bytecode at build time, skipping runtime parsing
- Cold start improvement: 30-50% faster, especially on low-end devices
- RN 0.84 (February 2026) makes Hermes V1 the default engine

### Flutter: AOT Compilation

- Dart AOT compiles to native machine code, delivering near-native startup
- Flutter cold start: ~2.1s vs RN's ~2.8s for comparable apps
- Dart 3.5 (2025) optimized memory allocation and GC

### Universal Lazy Initialization Patterns

Regardless of platform:
1. Defer non-critical SDK initialization (analytics, crash reporting) until after first frame
2. Use dependency injection frameworks with lazy providers
3. Load heavy modules on-demand rather than at startup
4. Pre-warm only what's needed for the first screen
5. Avoid disk I/O on the main thread during startup

### Measurement Tools

| Platform | Tools |
|----------|-------|
| Android | `adb shell am start -W` (TTID), Macrobenchmark (TTFD), Perfetto traces |
| iOS | Xcode Instruments App Launch template, `DYLD_PRINT_STATISTICS` |
| React Native | React Native DevTools, custom `performance.now()` markers |
| Flutter | `flutter run --profile`, DevTools timeline |

---

## 3. Rendering Performance

### Frame Rate Targets

| Display | Frame Budget | Target |
|---------|-------------|--------|
| 60Hz (standard) | 16.67ms per frame | 60fps |
| 90Hz (mid-range 2025+) | 11.11ms per frame | 90fps |
| 120Hz (flagship) | 8.33ms per frame | 120fps |

### Flutter Impeller Engine

Impeller replaced Skia as the default renderer (iOS: Flutter 3.16+, Android: Flutter 3.27+):

- **Eliminates shader jank**: Precompiles all shaders at build time rather than runtime
- **Frame rasterization**: ~50% faster in complex scenes
- **120Hz capable**: Consistently stays under 8ms threshold
- **Memory**: ~100MB less than the Skia backend
- **No shader warm-up needed**: Unlike Skia, first-render of any widget is as fast as subsequent renders

### React Native Fabric Renderer

Fabric (New Architecture) is production-ready:
- Layout calculations happen synchronously on the UI thread, eliminating the asynchronous bridge jank
- Delivers consistent 60fps for standard UI patterns (lists, forms, navigation)
- Combined with JSI (JavaScript Interface) for direct native module calls without serialization overhead

### List Rendering Optimization

Lists are the most common source of jank. Platform-specific best practices:

**Android RecyclerView:**
- ViewHolder pattern caches `findViewById` calls. Keep layouts < 3 levels deep
- `DiffUtil` calculates minimal update operations (Myers's diff algorithm) — up to 70% fewer UI redraws
- Prefetch: `setItemViewCacheSize(n)` keeps off-screen views ready
- Stable version: RecyclerView 1.4.0 (January 2025)

**iOS UICollectionView:**
- Compositional Layout with Diffable Data Source for automatic diff-based updates
- Pre-fetching API (`UICollectionViewDataSourcePrefetching`) for async data loading
- `UICollectionViewListCell` auto-updates from `@Observable` models

**React Native FlashList (Shopify):**
- Uses RecyclerView internally (cell recycling vs FlatList's virtualization)
- 5-10x faster than FlatList. JS thread CPU drops from >90% to <10%
- Drop-in replacement for FlatList API
- More memory efficient (no destroy/recreate cycle)

**Flutter ListView.builder:**
- Always use `ListView.builder` (lazy) over `ListView` (eager)
- Set `itemExtent` for fixed-height items to skip layout calculations
- `SliverList` with `SliverChildBuilderDelegate` for mixed-layout scroll views
- Lazy loading cuts initial render time by 40%, reduces memory spikes by 25%

### Common Anti-Patterns
- Nesting scrollable views without `NeverScrollableScrollPhysics` (Flutter) or `nestedScrollingEnabled=false`
- Rebuilding entire lists on single-item changes
- Heavy computation in `onBindViewHolder` / `cellForItemAt` / `build` methods
- Not using `const` constructors in Flutter widgets
- Complex widget trees inside list items without extraction into separate widgets

---

## 4. Memory Management

### iOS: ARC (Automatic Reference Counting)

- ARC tracks retain counts; objects released when count reaches zero
- **Primary risk**: Retain cycles (two objects with strong references to each other)
- Use `weak` for delegate references, `unowned` for guaranteed-lifetime references
- `autoreleasepool` blocks for loops creating many temporary objects
- **Detection**: Xcode Instruments Allocations and Leaks instruments

### Android: Garbage Collection

- Java/Kotlin apps use automatic GC. Short-lived objects during scrolling/animation cause GC pauses
- **Strategies**: Reduce object allocation in hot paths, use object pools, avoid boxing primitives
- **Detection**: Android Studio Memory Profiler — real-time heap allocations, GC events

### React Native Memory

- Images are the #1 cause of memory crashes. Use `react-native-fast-image` (backed by SDWebImage/Glide) for caching and pooling
- Monitor JS heap via React Native DevTools
- Bridge (legacy architecture) serialization can cause memory spikes with large payloads — New Architecture eliminates this

### Flutter Memory

- Dart has its own GC, optimized for UI workloads (generational, semi-space collector)
- `cached_network_image` package for disk/memory caching
- `ResizeImage` widget for automatic downsampling
- Use `flutter_memory_detector` or DevTools Memory View for leak detection

### Image Memory Management

| Platform | Library | Key Feature |
|----------|---------|-------------|
| Android | Glide | Aggressive bitmap reuse via BitmapPool |
| Android | Coil | Kotlin-first, automatic bitmap pooling and downsampling |
| iOS | SDWebImage | Progressive decoding, memory/disk caching, auto eviction |
| iOS | Kingfisher | Swift-native, prefetching, memory pressure handling |
| React Native | react-native-fast-image | Backed by SDWebImage (iOS) / Glide (Android) |
| Flutter | cached_network_image | Disk/memory caching with placeholder support |

### Leak Detection Tools

| Tool | Platform | Capabilities |
|------|----------|-------------|
| Xcode Instruments (Leaks + Allocations) | iOS | Runtime leak detection, allocation tracking, memory graph |
| LeakCanary | Android | Automatic leak detection with stack traces |
| Android Studio Profiler | Android | Heap inspection, GC events, allocation timeline |
| React Native DevTools | React Native | Component tree memory, re-render detection |
| Flutter DevTools | Flutter | Memory profiling, allocation tracking, diff snapshots |

### Common Anti-Patterns
- Strong reference cycles in closures/blocks (use `[weak self]` / `WeakReference`)
- Loading full-resolution images when thumbnails suffice
- Not clearing image caches under memory pressure
- Registering observers/listeners without removing them
- Holding references to Activities/ViewControllers in long-lived objects

---

## 5. Battery Optimization

Battery is a critical mobile UX factor that has no web equivalent. Poor battery usage leads to app uninstalls.

### Background Processing

**Android (WorkManager):**
- Unified API replacing JobScheduler/AlarmManager. Intelligently chooses underlying implementation per API level
- Supports constraints: `RequiresCharging`, `RequiresNetworkType`, `RequiresBatteryNotLow`
- Can save up to 30% battery by delaying non-essential tasks and batching updates
- Android 14+ enforces stricter background service lifecycles

**iOS (BGTaskScheduler):**
- `BGAppRefreshTask`: Short background refresh (~30 seconds)
- `BGProcessingTask`: Long-running tasks (minutes), scheduled during charging/Wi-Fi
- The OS decides optimal timing based on battery level, network, and usage patterns

**Expo:**
- `expo-background-task` (2025) replaces deprecated `expo-background-fetch`, using BGTaskScheduler (iOS) and WorkManager (Android)

### Wake Lock Enforcement (Android)

Google Play Store (March 2026) began enforcing wake lock quality treatments — apps with excessive wake locks face reduced discoverability:
- "Excessive" = >2 cumulative hours of non-exempt wake locks in 24 hours
- `PARTIAL_WAKE_LOCK` is the only acceptable type
- Tools: `adb shell dumpsys batterystats`, Battery Historian, Android Studio Energy Profiler

### Location Services Optimization
- Use coarse location when fine-grained isn't needed (`ACCESS_COARSE_LOCATION` vs `ACCESS_FINE_LOCATION`)
- Geofencing over continuous tracking where possible
- Reduce location update frequency when app is backgrounded
- iOS: significant-change location service uses cell towers (minimal battery impact)

### Push Notification Strategies

| Platform | Normal Priority | High Priority | Guidance |
|----------|----------------|---------------|----------|
| FCM (Android) | Batched in Doze mode | Immediate, wakes device | Use high-priority sparingly |
| APNs (iOS) | Priority 5, batched by OS | Priority 10, immediate | Apple gates based on battery/memory |

### Common Anti-Patterns
- Holding wake locks during long network operations
- Polling APIs instead of using push notifications
- Requesting fine-grained location when coarse is sufficient
- Not using `setInexactRepeating` for recurring alarms
- Continuous sensor polling without throttling

---

## 6. Network Optimization

### HTTP/3 (QUIC) on Mobile

HTTP/3 over QUIC provides major benefits for mobile:
- **Connection migration**: Seamless continuation when switching Wi-Fi to cellular (UDP-based)
- **No head-of-line blocking**: At the transport layer, unlike HTTP/2 over TCP
- **Real benchmarks**: Response times improved from 3s to 0.8s (~47% improvement)
- **Strongest gains**: On unstable mobile networks and high-latency connections
- **Adoption**: ~35% global adoption (October 2025, Cloudflare data)

### Image Format Selection

| Format | vs JPEG Compression | Support | Best For |
|--------|--------------------|---------|---------| 
| **AVIF** | 50% smaller | 94.9% browser, growing native | Photos, complex images |
| **WebP** | 25-34% smaller | Universal | General purpose, animations |
| **HEIC** | 50% smaller | iOS native, limited Android | iOS-only apps |
| **JPEG** | Baseline | Universal | Legacy fallback |

Best practice: Let an image CDN auto-negotiate format (AVIF > WebP > JPEG fallback).

### Caching Strategies

Multi-level caching is essential for mobile:
1. **Memory cache**: Instant access, cleared on memory pressure
2. **Disk cache**: Persistent across sessions, bounded by size limits
3. **HTTP cache**: ETags / Last-Modified / Cache-Control headers
4. **Stale-while-revalidate**: Serve cached data immediately, refresh in background

Hybrid caching models increase user engagement by ~20% due to faster response times.

### GraphQL vs REST on Mobile

| Factor | GraphQL | REST |
|--------|---------|------|
| Network latency (slow connections) | 50-70% reduction | Baseline |
| Data transfer | 41% less on average | More over-fetching |
| Battery impact | Higher CPU (query parsing) | 28% better battery life |
| Server CPU | 10-30% overhead | Baseline |
| **Recommendation** | Complex data requirements, multiple views per screen | Simple CRUD, battery-sensitive apps |

Modern consensus: hybrid approach — REST for simple CRUD, GraphQL for complex data requirements.

### Certificate Pinning (2026 Guidance)

OWASP 2025 and Google now recommend **against** SSL pinning for mobile apps:
- Operational risks: breaks on cert rotation, false sense of security, easily bypassed with Frida
- **Modern alternatives**: Shorter certificate lifetimes, Certificate Transparency, automated rotation
- If still required (regulated industries): minimal performance impact on TLS handshake, but significant operational risk

### Common Anti-Patterns
- Not compressing request/response bodies
- Making sequential API calls when parallel calls are possible
- Ignoring `Cache-Control` headers
- Not implementing exponential backoff with jitter for retries
- Downloading resources that are already cached locally

---

## 7. Offline-First Architecture

### Core Principle

The local device is the primary source of truth; the network is a background optimization:

```
Read → Local DB first (instant)
Write → Local DB first (works offline)
Sync → Push/pull when connected
Conflict → Resolve (last-write-wins, merge, CRDT)
```

Used by Notion, Obsidian, Spotify, Slack.

### Storage Technologies

| Library | Platform | Speed | Best For |
|---------|----------|-------|----------|
| **SQLite** (custom sync) | All | Flexible | Full control, complex queries |
| **WatermelonDB** | React Native | 5-50x faster than AsyncStorage | Large datasets (50k+ records) |
| **MMKV** | React Native | 20x faster than AsyncStorage | Key-value storage, settings |
| **Realm** | All | Zero-copy architecture | Reactive UI (note: Atlas Device Sync deprecated Sept 2025) |
| **TinyBase** | JS/RN | ~5KB bundle | Lightweight local state |
| **Room** | Android | SQL abstraction | Android-native apps |
| **SwiftData** | iOS | SwiftUI integration | iOS-native apps |
| **Drift** | Flutter | Type-safe SQL | Flutter apps with complex queries |
| **Isar** | Flutter | NoSQL, fast | Flutter apps with simple data |

### Conflict Resolution Strategies

| Strategy | Complexity | Data Safety | Best For |
|----------|-----------|-------------|----------|
| **Last-Write-Wins (LWW)** | Simple | Can lose data | Settings, preferences |
| **CRDTs** | Complex | No data loss | Collaborative editing, counters, sets |
| **Version vectors** | Medium | Detects conflicts | Multi-device sync |
| **Custom merge functions** | High | Application-specific | Complex business objects |

### Optimistic UI Patterns

Update UI immediately assuming the server operation will succeed:
- **Flutter**: Official `Optimistic State` pattern in Flutter documentation — set optimistic state, revert on failure
- **React Native**: `useOptimistic` Hook (React 19) manages state that reverts on API failure
- **Use cases**: Chat messages, likes, cart updates, collaborative editing
- **Rollback strategy**: Queue operations, mark as pending, revert on failure with user notification

### Common Anti-Patterns
- Treating the server as the only source of truth
- Not handling sync conflicts (silent data loss)
- Synchronizing entire datasets instead of deltas
- Not implementing retry logic for failed syncs
- Blocking UI on network responses

---

## 8. Profiling and Monitoring

### Platform-Specific Profilers

**Xcode Instruments (iOS):**
- **Time Profiler**: CPU sampling at 1ms intervals. Identifies main-thread blocking functions
- **Allocations**: Real-time memory tracking by object type, peak memory spikes
- **Leaks**: Automatic retain cycle detection
- **App Launch**: Startup time profiling template
- **Energy Log**: Power consumption by subsystem
- Always profile on **physical devices** — simulators produce unreliable results

**Android Studio Profiler:**
- **CPU Profiler**: Method tracing, system trace (Perfetto-based)
- **Memory Profiler**: Heap dump, allocation tracking, GC event visualization
- **Energy Profiler**: CPU, network, and location energy impact
- **Network Profiler**: Request/response inspection, payload sizes
- **Macrobenchmark v3** (2025): AI-based Baseline Profile Hints, Compose support, power/thermal metrics

**React Native DevTools (2025-2026):**
- Replaces Flipper (deprecated since RN 0.73, removed from templates in RN 0.74)
- Built on Chrome DevTools Protocol (CDP), supports all RN apps running Hermes
- React DevTools Profiler: component render times, re-render cascade detection
- "Highlight Updates" visualizes which components re-render on state changes

**Flutter DevTools:**
- **Performance View**: Frame-by-frame rendering timeline. Red bars indicate janky frames
- Shows raster thread and GPU events separately
- CPU Profiler, Memory View, Widget Rebuild Tracker
- 120Hz devices: frames must complete in <8ms

### Crash and Error Monitoring

| Tool | Strengths | SDK Size |
|------|----------|----------|
| **Firebase Crashlytics** | Deep Android integration, free, automatic ANR detection | ~200KB |
| **Sentry** | Distributed tracing, performance monitoring, cross-platform | ~400KB |
| **Bugsnag** | Stability scoring, release health tracking | ~300KB |
| **Embrace** | Mobile-first observability, session replay | ~500KB |

Combining Crashlytics + Sentry reduces MTTR by up to 65%.

### Real User Monitoring (RUM)

Providers: Datadog RUM, Splunk RUM, Amazon CloudWatch RUM (iOS/Android support added November 2025), New Relic Mobile.

Key metrics to track:
- App launch time (cold/warm)
- Screen load time
- Network request latency (by endpoint)
- Page stutter rate / janky frames
- Crash-free session rate
- Custom business milestones ("Checkout Complete", "Signup Success")

### Common Anti-Patterns
- Only monitoring crashes, not performance
- Not setting performance baselines before launch
- Using emulators/simulators for performance measurements
- Not correlating technical metrics with business KPIs

---

## 9. Animation Performance

### GPU vs CPU Animations

- **GPU animations**: Transform, opacity, and compositing operations. Offloaded from main thread — always prefer these
- **CPU animations**: Layout-triggering properties (width, height, padding). Block main thread — avoid animating these
- **Rule**: Always animate transform/opacity; avoid animating layout properties

### React Native Reanimated

Reanimated offloads animation logic to the native UI thread via worklets, bypassing the JS bridge:
- RN + Skia + Reanimated: improved from 38fps on 1500 elements (2023) to 60fps on 3000 elements (2025)
- **Reanimated 4** (stable 2026): More efficient worklet serialization, lower frame drop rates on Android
- Combined with React Native Skia for direct GPU rendering
- Gesture handlers eliminate round-trip latency from JS thread

### Flutter Animation

- All Flutter animations run on the GPU, bypassing CPU-JS thread communication
- **Impeller**: Precompiles shaders at build time, eliminating first-animation jank
- `CustomPainter`: Use `shouldRepaint` to prevent unnecessary repaints
- `AnimatedBuilder` over `AnimatedWidget` to minimize rebuild scope

### iOS Core Animation

- `CALayer` animations are GPU-accelerated by default
- `UIView.animate(withDuration:)` for implicit animations
- `CADisplayLink` for frame-synchronized updates
- **Avoid off-screen rendering triggers**: `cornerRadius` + `masksToBounds` together, shadows without `shadowPath`

### Android Property Animations

- `ObjectAnimator` and `ValueAnimator` for property animations
- `RenderThread` (Android 5.0+) handles animations independently from the main thread
- `ViewPropertyAnimator` for hardware-accelerated view property animations
- `ItemAnimator` for RecyclerView item animations

### Frame Drop Detection

| Platform | Tool | Method |
|----------|------|--------|
| Android | FrameMetrics API, Macrobenchmark | Jank detection in CI |
| iOS | CADisplayLink, Instruments Core Animation | Frame timing analysis |
| Flutter | DevTools Performance View | Red frame overlay for jank |
| React Native | React DevTools Profiler | Perf Monitor overlay |

### Common Anti-Patterns
- Animating layout properties instead of transforms
- Running animations on the JS/main thread
- Not using hardware layers for complex animations
- Creating new `Paint` objects every frame in Flutter `CustomPainter`
- Triggering layout recalculations during animations

---

## 10. Performance Testing and Budgets

### Benchmark Frameworks

**Android:**
- **Microbenchmark**: Isolated method-level testing (hot code paths, data conversions)
- **Macrobenchmark v3** (2025): Full-flow testing (startup, scrolling, animations). AI-based Baseline Profile Hints, Compose/Lazy Layout support, power/thermal metrics
- Output: JSON results + Perfetto traces, CI-ready
- Firebase Test Lab for real-device benchmark execution

**iOS:**
- **XCTest Performance Tests**: `measure(metrics:)` with `XCTApplicationLaunchMetric`, `XCTCPUMetric`, `XCTMemoryMetric`
- Baselines with acceptable standard deviation for regression detection
- Results in `.xcresult` files, parseable with `xcresulttool` for CI

**React Native:**
- **Reassure** (by Callstack): Regression testing for RN performance. Compares render times against baselines
- **Flashlight** (by BAM): Automated performance testing
- Custom `performance.now()` markers with Hermes

**Flutter:**
- `flutter_test` with `benchmarkWidgets` for widget-level benchmarks
- Integration test driver for full-app performance measurement
- `TimelineSummary` from integration tests for frame timing analysis

### Performance Budgets

Define and enforce in CI:

| Metric | Consumer App Target | Enterprise App Target |
|--------|--------------------|-----------------------|
| **App size** | < 40MB | < 60MB |
| **Cold start (TTID)** | < 2s | < 3s |
| **Janky frames** | < 5% of total frames | < 8% of total frames |
| **Peak memory** | < 200MB | < 300MB |
| **Crash-free sessions** | > 99.5% | > 99.0% |
| **ANR rate** (Android) | < 0.47% | < 1.0% |

### CI Integration

- **Android**: Macrobenchmark JSON output in GitHub Actions/CircleCI. Firebase Test Lab for real devices
- **iOS**: XCTest results from `.xcresult` files. Xcode Cloud or Bitrise for device farms
- **Gates**: Define max render time, acceptable frame drops, startup time thresholds. Build fails if exceeded
- **Trend tracking**: Monitor metrics over time to detect gradual regressions before they become noticeable

### The Reference Device Strategy

Don't test only on flagships. Your reference device should be your P50 user's device:
- Android: A mid-range device from 2-3 years ago (e.g., Samsung Galaxy A-series, Xiaomi Redmi Note)
- iOS: 2-3 generations back (e.g., iPhone 12/13)
- Test on both reference and flagship to understand the performance range

### Common Anti-Patterns
- Testing only on emulators/simulators
- Running benchmarks without controlling for thermal throttling
- Not establishing baselines before measuring
- Treating performance testing as a one-time pre-launch activity
- Not testing on low-end devices
