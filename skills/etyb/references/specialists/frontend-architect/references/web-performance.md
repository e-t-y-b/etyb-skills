# Web Performance — Deep Reference

**Always use `WebSearch` to verify Core Web Vitals thresholds, tool versions, and browser support. Performance standards evolve with browser updates and Google ranking changes. Last verified: April 2026.**

## Table of Contents
1. [Core Web Vitals (2025)](#1-core-web-vitals-2025)
2. [Bundle Optimization](#2-bundle-optimization)
3. [Runtime Performance](#3-runtime-performance)
4. [Memory Management](#4-memory-management)
5. [Image Optimization](#5-image-optimization)
6. [Font Optimization](#6-font-optimization)
7. [Resource Loading](#7-resource-loading)
8. [Rendering Optimization](#8-rendering-optimization)
9. [Caching Strategies](#9-caching-strategies)
10. [Monitoring and Measurement](#10-monitoring-and-measurement)
11. [Framework-Specific Performance](#11-framework-specific-performance)
12. [Network Optimization](#12-network-optimization)
13. [Performance Budgets](#13-performance-budgets)

---

## 1. Core Web Vitals (2026)

### The Three Metrics

| Metric | Measures | Good | Needs Improvement | Poor |
|--------|---------|------|-------------------|------|
| **LCP** (Largest Contentful Paint) | Loading — when main content is visible | ≤ 2.5s | 2.5-4.0s | > 4.0s |
| **INP** (Interaction to Next Paint) | Responsiveness — delay from input to visual update | ≤ 200ms | 200-500ms | > 500ms |
| **CLS** (Cumulative Layout Shift) | Visual stability — how much content shifts | ≤ 0.1 | 0.1-0.25 | > 0.25 |

### How Google Uses CWV
- Part of **page experience** ranking signals
- Assessed using **field data** (Chrome UX Report / CrUX), NOT lab data
- Uses **75th percentile** of real user page loads
- Must meet Good for **ALL THREE** metrics to get the page experience boost
- Acts as **tiebreaker** — content relevance still dominates rankings
- Applies to both mobile and desktop (assessed separately)

### LCP Deep Dive

**What counts as LCP:**
- `<img>` elements (including `<img>` inside `<picture>`)
- `<video>` poster image
- Elements with `background-image` (CSS)
- Block-level text elements (largest text block)

**LCP Optimization Checklist:**
1. **Reduce TTFB** (Time to First Byte)
   - CDN for static content, edge SSR for dynamic
   - Target TTFB < 800ms
   - HTTP/2 or HTTP/3
   - Database query optimization for SSR pages

2. **Eliminate render-blocking resources**
   - Inline critical CSS (< 14KB to fit first TCP roundtrip)
   - `defer` or `async` for non-critical JS
   - `<link rel="preload">` for critical resources

3. **Optimize LCP resource**
   - `fetchpriority="high"` on LCP image
   - **Never lazy-load the LCP image**
   - `<link rel="preload" as="image" href="hero.webp">`
   - Responsive images with `srcset` (serve right size)
   - Modern formats: WebP/AVIF (30-50% smaller)

4. **Avoid client-side rendering for LCP**
   - Server-render above-fold content (SSR/SSG)
   - Use Server Components for data-dependent LCP

### INP Deep Dive

**INP measures the FULL interaction lifecycle:**
```
Input Delay → Processing Time → Presentation Delay = Total INP
(queue wait)    (event handlers)  (render + paint)
```

**INP Optimization Checklist:**
1. **Reduce input delay** (event handler starts faster)
   - Minimize main thread blocking (< 50ms long tasks)
   - Code split — less JS on initial load
   - Defer non-critical JS with `defer` or dynamic `import()`

2. **Reduce processing time** (event handler runs faster)
   - Break long tasks with `scheduler.yield()` (Scheduler API)
   - Use `requestIdleCallback` for non-urgent work
   - Debounce/throttle expensive handlers
   - Move heavy computation to Web Workers

3. **Reduce presentation delay** (DOM updates paint faster)
   - `content-visibility: auto` for off-screen content
   - Avoid forced layout/reflow in event handlers
   - Use `transform`/`opacity` for animations (compositor-only)
   - Virtualize long lists (`@tanstack/virtual`, `react-window`)
   - `startViewTransition()` to defer visual updates

### CLS Deep Dive

**Common CLS Causes and Fixes:**

| Cause | Fix |
|-------|-----|
| Images without dimensions | Always set `width`/`height` or `aspect-ratio` |
| Dynamic content injection | Reserve space with min-height or skeleton |
| Web fonts causing reflow | `font-display: optional` or `size-adjust` descriptor |
| Ads/embeds without reserved space | CSS `contain: layout` + reserved dimensions |
| Late CSS loading | Inline critical CSS, preload stylesheets |
| Dynamic navigation/banners | Fixed position or reserved space |

---

## 2. Bundle Optimization

### The Bundle Budget
- **Target**: < 200KB initial JS (compressed/transferred)
- Each KB of JS costs ~1ms parse time on mid-range mobile
- 200KB JS = ~200ms parse time = significant INP impact

### Code Splitting Strategies

**Route-level splitting** (automatic in meta-frameworks):
```typescript
// Next.js: automatic per page
// SvelteKit: automatic per route
// Vue Router: lazy routes
const routes = [
  { path: '/dashboard', component: () => import('./Dashboard.vue') },
]
```

**Component-level splitting**:
```typescript
// React
const HeavyChart = React.lazy(() => import('./HeavyChart'))
// Vue
const HeavyChart = defineAsyncComponent(() => import('./HeavyChart.vue'))
// Angular
@defer (on viewport) { <app-heavy-chart /> }
```

**Library-level splitting**:
```typescript
// Only import when needed (chart libraries, date pickers, editors)
const handleChartClick = async () => {
  const { Chart } = await import('chart.js')
  // Use Chart
}
```

### Tree Shaking
- Requires ESM imports (`import { x } from 'lib'`, not `require`)
- `sideEffects: false` in library's `package.json` enables deep tree shaking
- **Named imports** tree-shake: `import { debounce } from 'lodash-es'` (not `import _ from 'lodash'`)
- Verify with bundle analyzer — some libraries don't tree-shake well

### Bundle Analysis Tools

| Tool | For | Usage |
|------|-----|-------|
| `@next/bundle-analyzer` | Next.js | Visualize bundle composition |
| `rollup-plugin-visualizer` | Vite/Rollup | Interactive treemap of bundle |
| `source-map-explorer` | Any bundler | Source map analysis |
| `bundlephobia.com` | Package evaluation | Check size before adding dependency |
| `packagephobia.com` | Install size | Check install size (node_modules) |
| `webpack-bundle-analyzer` | Webpack | Classic bundle visualization |
| `vite-bundle-visualizer` | Vite | Vite-specific analyzer |

### Common Bundle Bloat Causes
- Importing entire libraries (`lodash` vs `lodash-es`)
- Date libraries (moment.js = 300KB; use `date-fns` or `dayjs` instead)
- Icon libraries (import individual icons, not entire set)
- CSS-in-JS runtime (use compile-time alternatives)
- Polyfills for browsers you don't support
- Duplicate dependencies (check `pnpm why` or `npm ls`)

---

## 3. Runtime Performance

### Long Tasks
- Any task blocking main thread for > 50ms is a "long task"
- Long tasks block interactions → poor INP
- Identify with: Performance panel → Main thread → Long tasks (red corners)

### Breaking Up Long Tasks
```typescript
// scheduler.yield() — give browser a chance to process events
// Supported: Chrome 129+, Edge 129+, Firefox 142+. Safari: not yet.
async function processLargeList(items) {
  for (let i = 0; i < items.length; i++) {
    processItem(items[i])
    if (i % 100 === 0) {
      await scheduler.yield()  // Yield to main thread
    }
  }
}

// Fallback for browsers without scheduler.yield()
function yieldToMain() {
  if ('scheduler' in globalThis && 'yield' in scheduler) {
    return scheduler.yield()
  }
  return new Promise(resolve => setTimeout(resolve, 0))
}

// requestIdleCallback — run when browser is idle
requestIdleCallback((deadline) => {
  while (deadline.timeRemaining() > 0 && tasks.length > 0) {
    processTask(tasks.shift())
  }
})
```

### Web Workers
```typescript
// worker.ts
self.onmessage = (e) => {
  const result = heavyComputation(e.data)
  self.postMessage(result)
}

// main.ts
const worker = new Worker(new URL('./worker.ts', import.meta.url))
worker.postMessage(data)
worker.onmessage = (e) => updateUI(e.data)
```
- Offload CPU-intensive work off main thread
- Use for: data processing, image manipulation, parsing, encryption
- **Comlink**: Simplifies Worker communication with proxy API
- **SharedArrayBuffer**: Shared memory between threads (requires COOP/COEP headers)

### OffscreenCanvas
```typescript
// Offload canvas rendering to worker
const offscreen = canvas.transferControlToOffscreen()
worker.postMessage({ canvas: offscreen }, [offscreen])
```
- Move canvas/WebGL rendering to Web Worker
- Main thread stays responsive during complex rendering

### Long Animation Frames API (LoAF)
- Successor to Long Tasks API with much richer attribution data
- Reports frames taking > 50ms with script attribution, source URLs, and timing breakdowns
- **Chrome 123+** only (not yet in Firefox/Safari)
- Provides `PerformanceLongAnimationFrameTiming` entries with `scripts` array showing exactly which scripts caused the long frame
- Essential for diagnosing INP issues in production
- Use with `PerformanceObserver` to capture and send to analytics

### requestAnimationFrame
```typescript
// Smooth animations synced to display refresh rate
function animate() {
  element.style.transform = `translateX(${position}px)`
  position += speed
  if (position < target) requestAnimationFrame(animate)
}
requestAnimationFrame(animate)
```
- Always use rAF for visual updates (not `setTimeout`/`setInterval`)
- Pauses when tab is hidden (battery efficient)

---

## 4. Memory Management

### Common Memory Leak Patterns

| Pattern | Cause | Fix |
|---------|-------|-----|
| Event listeners not removed | `addEventListener` without cleanup | Remove in cleanup/unmount |
| Detached DOM nodes | References to removed elements | Null references after removal |
| Closures retaining large objects | Inner function captures outer scope | Minimize closure scope |
| Timers not cleared | `setInterval`/`setTimeout` leaking | Clear in cleanup |
| Stale state in closures | React/Vue watchers capturing old state | Proper dependency management |
| Growing collections | Maps/Sets/arrays that only grow | Implement size limits or cleanup |
| Observers not disconnected | IntersectionObserver, MutationObserver | Disconnect when done |

### Chrome DevTools Memory Profiling
1. **Heap snapshot**: Capture memory state, compare snapshots to find leaks
   - Take snapshot A → do action → take snapshot B → compare
   - Look for growing object counts between snapshots
2. **Allocation timeline**: Record allocations over time
   - Blue bars = allocated, gray bars = freed
   - Persistent blue bars = potential leak
3. **Performance monitor**: Real-time memory usage, DOM nodes, event listeners

### WeakRef and FinalizationRegistry
```typescript
// WeakRef — hold reference without preventing GC
const cache = new Map<string, WeakRef<BigObject>>()

function getCached(key: string): BigObject | undefined {
  const ref = cache.get(key)
  const obj = ref?.deref()
  if (!obj) cache.delete(key)
  return obj
}

// FinalizationRegistry — callback when object is GC'd
const registry = new FinalizationRegistry((key) => {
  cache.delete(key)
})
```
- Use for caches that shouldn't prevent garbage collection
- Don't use for critical logic — GC timing is non-deterministic

### DOM Node Budgets
- Modern browsers handle 10,000+ DOM nodes, but performance degrades
- Target: < 1,500 DOM nodes per page
- Virtualize large lists: only render visible items
- `content-visibility: auto` for off-screen sections

---

## 5. Image Optimization

### Format Selection
| Format | Compression | Browser Support | Best For |
|--------|------------|----------------|----------|
| **AVIF** | Best (50% smaller than JPEG) | Chrome, Firefox, Safari 16.4+ | Photos, hero images |
| **WebP** | Great (25-35% smaller than JPEG) | All modern browsers | Universal modern format |
| **JPEG** | Good | Universal | Fallback for older browsers |
| **PNG** | Lossless | Universal | Screenshots, images with text/transparency |
| **SVG** | Vector (tiny) | Universal | Icons, logos, illustrations |

### Responsive Images
```html
<picture>
  <!-- AVIF for supporting browsers -->
  <source type="image/avif"
    srcset="hero-400.avif 400w, hero-800.avif 800w, hero-1200.avif 1200w"
    sizes="(max-width: 768px) 100vw, 50vw" />
  <!-- WebP fallback -->
  <source type="image/webp"
    srcset="hero-400.webp 400w, hero-800.webp 800w, hero-1200.webp 1200w"
    sizes="(max-width: 768px) 100vw, 50vw" />
  <!-- JPEG fallback -->
  <img src="hero-800.jpg" alt="Hero image"
    width="1200" height="800"
    loading="lazy"
    decoding="async" />
</picture>
```

### Framework Image Components
- **`next/image`**: Auto WebP/AVIF, srcset, lazy loading, blur placeholder, CDN optimization
- **`<NuxtImg>`**: Nuxt Image with providers (Cloudinary, imgix, Vercel)
- **`NgOptimizedImage`**: Angular — width/height enforcement, srcset, priority hints, lazy loading
- **Always use these** over raw `<img>` in framework projects

### Image CDN Services
| Service | Pricing | Key Features |
|---------|---------|-------------|
| Cloudinary | Free tier + usage-based | Transforms, AI cropping, video |
| imgix | Usage-based | Real-time processing, CDN |
| Cloudflare Images | Flat rate + per-image | Simple, cheap, global CDN |
| Vercel Image Optimization | Included with Vercel | Automatic with Next.js |

### Priority Hints
```html
<!-- High priority — LCP image -->
<img src="hero.webp" fetchpriority="high" />

<!-- Low priority — below-fold images -->
<img src="footer-bg.webp" fetchpriority="low" loading="lazy" />
```

---

## 6. Font Optimization

### Loading Strategy Decision

| Strategy | `font-display` | CLS Impact | User Experience |
|----------|---------------|-----------|-----------------|
| **Optional** (recommended for CLS) | `optional` | Zero CLS | Uses cached font or fallback. Font only loads on subsequent visits. |
| **Swap** (recommended for branding) | `swap` | Possible CLS | Shows fallback immediately, swaps when loaded. Brief flash. |
| **Fallback** | `fallback` | Minimal CLS | Short block period (~100ms), then fallback if not loaded. |
| **Block** | `block` | None (but invisible text) | 3s invisible text, then fallback. Bad UX. |

### Font Matching (Reduce CLS with `swap`)
```css
@font-face {
  font-family: 'Inter';
  src: url('/fonts/Inter-Variable.woff2') format('woff2');
  font-weight: 100 900;
  font-display: swap;
  /* Match fallback metrics to reduce layout shift */
  ascent-override: 90%;
  descent-override: 22%;
  line-gap-override: 0%;
  size-adjust: 107%;
}
```
- `ascent-override`, `descent-override`, `line-gap-override`, `size-adjust` match fallback font metrics
- Tools: `fontaine`, `@capsizecss/metrics` for computing values automatically
- Frameworks: Next.js `next/font` does this automatically

### Self-Hosting (Recommended)
```css
/* Self-hosted — no third-party DNS lookup, no cookie/tracking concerns */
@font-face {
  font-family: 'Geist';
  src: url('/fonts/Geist-Variable.woff2') format('woff2');
  font-weight: 100 900;
  font-display: swap;
}
```
- Faster than Google Fonts CDN (no cross-origin connection)
- Privacy-friendly (no Google tracking)
- Bundle with application for guaranteed availability

### Font Subsetting
```bash
# pyftsubset — strip unused characters
pyftsubset Inter-Regular.woff2 \
  --output-file=Inter-Regular-Latin.woff2 \
  --unicodes="U+0020-007E,U+00A0-00FF" \
  --flavor=woff2
```
- Latin subset: ~20KB vs full font: ~100KB+
- `unicode-range` in `@font-face` for loading only needed subsets
- **Always subset** for CJK fonts (can be 5MB+ without subsetting)

---

## 7. Resource Loading

### Resource Hints

| Hint | What It Does | When to Use |
|------|-------------|-------------|
| `<link rel="preload">` | Fetch critical resource early (high priority) | LCP image, critical font, above-fold CSS |
| `<link rel="prefetch">` | Fetch for next navigation (low priority) | Next page assets, predicted user journey |
| `<link rel="preconnect">` | Early connection (DNS+TCP+TLS) | Third-party origins (fonts, APIs, CDNs) |
| `<link rel="dns-prefetch">` | DNS lookup only | Fallback for preconnect, many third parties |
| `<link rel="modulepreload">` | Preload ES module + dependencies | Critical JS modules |

### fetchpriority Attribute
```html
<img src="hero.webp" fetchpriority="high" />     <!-- Boost LCP image -->
<img src="carousel-2.webp" fetchpriority="low" /> <!-- Deprioritize below-fold -->
<script src="analytics.js" fetchpriority="low"></script> <!-- Deprioritize non-critical JS -->
<link rel="preload" as="font" href="font.woff2" fetchpriority="high" crossorigin />
```

### Early Hints (103 Status Code)
```
HTTP/1.1 103 Early Hints
Link: </styles.css>; rel=preload; as=style
Link: </font.woff2>; rel=preload; as=font; crossorigin

HTTP/1.1 200 OK
Content-Type: text/html
...
```
- Server sends preload hints BEFORE the full response
- Browser starts fetching resources while server computes page
- Supported by Cloudflare, Chrome. Huge TTFB improvement.

### Speculation Rules API
```html
<script type="speculationrules">
{
  "prerender": [
    { "where": { "href_matches": "/products/*" } }
  ],
  "prefetch": [
    { "where": { "selector_matches": "a.likely-link" } }
  ]
}
</script>
```
- Browser prerenders or prefetches pages before user navigates
- Instant page transitions for predicted navigations
- More powerful than `<link rel="prefetch">` — prerender includes full page render
- Supported in Chrome 122+, Edge. Growing adoption in frameworks (Next.js, Astro).
- **Document rules** (`where` syntax) allow matching patterns without listing every URL

---

## 8. Rendering Optimization

### CSS Containment
```css
/* Tell browser this element's rendering is independent */
.card { contain: layout style paint; }

/* content-visibility: skip rendering for off-screen content */
.section { content-visibility: auto; contain-intrinsic-size: 0 500px; }
```
- `contain: layout` — layout changes don't affect outside
- `contain: paint` — painting doesn't bleed outside bounds
- `contain: style` — counter/quote styles don't escape
- `content-visibility: auto` — **huge** rendering optimization for long pages (skip off-screen content entirely)
- `contain-intrinsic-size` — reserve space to prevent CLS

### Compositor-Only Animations
```css
/* GOOD — compositor thread only, smooth 60fps */
.animate { transition: transform 0.3s, opacity 0.3s; }
.animate:hover { transform: scale(1.05); opacity: 0.8; }

/* BAD — triggers layout recalculation */
.animate:hover { width: 110%; margin-top: -5px; }
```
- Only `transform`, `opacity`, and `filter` can be animated on compositor thread
- Everything else (width, height, margin, padding, top/left) triggers layout → jank
- Use `will-change: transform` sparingly for promoted layers

### Avoiding Forced Reflow
```typescript
// BAD — reads then writes in loop (forced synchronous layout)
elements.forEach(el => {
  const height = el.offsetHeight  // READ (forces layout)
  el.style.height = height + 10 + 'px'  // WRITE (invalidates layout)
})

// GOOD — batch reads, then batch writes
const heights = elements.map(el => el.offsetHeight)  // All reads
elements.forEach((el, i) => {
  el.style.height = heights[i] + 10 + 'px'  // All writes
})
```

### View Transitions API
```typescript
// Smooth page transitions
document.startViewTransition(() => {
  // Update DOM
  updatePage()
})
```
```css
/* Customize transition */
::view-transition-old(root) { animation: 0.2s ease-out fade-out; }
::view-transition-new(root) { animation: 0.2s ease-in fade-in; }

/* Element-level transition */
.hero { view-transition-name: hero; }
```

---

## 9. Caching Strategies

### HTTP Caching Headers

| Pattern | Cache-Control | Use For |
|---------|--------------|---------|
| **Immutable assets** (hashed filenames) | `public, max-age=31536000, immutable` | JS/CSS bundles, images with hash |
| **Dynamic HTML** | `no-cache` or `private, max-age=0, must-revalidate` | HTML pages, API responses |
| **Stale while revalidate** | `public, max-age=60, stale-while-revalidate=3600` | API data that can be slightly stale |
| **Never cache** | `no-store` | Sensitive data, auth responses |

### Service Workers and Cache API
```typescript
// Workbox — Google's service worker library
import { precacheAndRoute } from 'workbox-precaching'
import { registerRoute } from 'workbox-routing'
import { StaleWhileRevalidate, CacheFirst } from 'workbox-strategies'

// Precache build artifacts
precacheAndRoute(self.__WB_MANIFEST)

// Cache-first for images
registerRoute(
  ({ request }) => request.destination === 'image',
  new CacheFirst({ cacheName: 'images', plugins: [/* expiration, etc */] })
)

// Stale-while-revalidate for API
registerRoute(
  ({ url }) => url.pathname.startsWith('/api/'),
  new StaleWhileRevalidate({ cacheName: 'api' })
)
```

### CDN Caching Tiers
```
Browser Cache → CDN Edge → CDN Origin Shield → Application Server
```
- **Edge**: Close to user, first cache hit. Minutes-hours TTL.
- **Origin Shield**: Single cache between CDN and origin. Reduces origin load.
- Stale-while-revalidate at CDN level for background refresh

---

## 10. Monitoring and Measurement

### Lab vs Field Data

| Type | What | Tools | Use For |
|------|------|-------|---------|
| **Lab** | Controlled environment, consistent | Lighthouse, WebPageTest, DevTools | Debugging, CI/CD gates, development |
| **Field** | Real user data, actual conditions | CrUX, web-vitals, RUM tools | Google ranking, actual user experience |

**Critical**: Google uses **field data** (CrUX) for ranking. Lab data is for debugging.

### web-vitals Library
```typescript
import { onLCP, onINP, onCLS } from 'web-vitals'

// Basic reporting
onLCP(console.log)
onINP(console.log)
onCLS(console.log)

// Attribution build (diagnostic details)
import { onLCP, onINP, onCLS } from 'web-vitals/attribution'

onINP((metric) => {
  console.log(metric.attribution.eventTarget)     // Which element
  console.log(metric.attribution.eventType)        // Which interaction
  console.log(metric.attribution.loadState)        // Page state during interaction
  sendToAnalytics(metric)
})
```

### Monitoring Tools

| Tool | Type | Best For |
|------|------|---------|
| **Google Search Console** | Field | CWV by page, indexing issues |
| **CrUX API / CrUX Vis** | Field | Historical CWV trends (CrUX Dashboard deprecated Nov 2025, use CrUX Vis or API) |
| **PageSpeed Insights** | Lab + Field | Quick URL analysis |
| **Lighthouse 13** (Latest: 13.1.0) | Lab | CI/CD performance gates. Requires Node 22 LTS+. |
| **web-vitals** | Field (RUM) | Custom analytics integration |
| **SpeedCurve** | Lab + Field | Performance monitoring platform |
| **Calibre** | Lab + Field | Performance monitoring + budgets |
| **DebugBear** | Lab + Field | CWV monitoring + recommendations |
| **Vercel Analytics** | Field | Zero-config for Vercel deployments |
| **Sentry Performance** | Field | Error tracking + performance |

### Lighthouse CI in Pipeline
```yaml
# .lighthouserc.json
{
  "ci": {
    "assert": {
      "assertions": {
        "categories:performance": ["error", { "minScore": 0.9 }],
        "categories:accessibility": ["error", { "minScore": 0.9 }],
        "first-contentful-paint": ["warn", { "maxNumericValue": 2000 }],
        "interactive": ["error", { "maxNumericValue": 5000 }],
        "total-byte-weight": ["warn", { "maxNumericValue": 500000 }]
      }
    }
  }
}
```

---

## 11. Framework-Specific Performance

### React Performance
- **React Compiler** (auto-memoization): Eliminates need for `useMemo`/`useCallback`
- **Server Components**: Zero client JS for data/layout components
- **Suspense + streaming**: Progressive loading, prioritized hydration
- **Selective hydration**: React 18 hydrates interactive parts first
- **`React.lazy()`**: Component-level code splitting
- **React Profiler**: DevTools flamechart for component render time

### Angular Performance
- **Signals**: Fine-grained reactivity, skip unnecessary change detection
- **OnPush change detection**: Component re-checks only on input change or signal update
- **`@defer`**: Built-in lazy loading with viewport/idle/interaction triggers
- **NgOptimizedImage**: Automatic image optimization
- **Zoneless mode**: Eliminate Zone.js overhead entirely

### Vue Performance
- **Compiler optimizations**: Static hoisting, patch flags, block trees
- **`v-memo`**: Skip subtree re-render when dependencies unchanged
- **`v-once`**: Render once, never update
- **`defineAsyncComponent()`**: Component-level code splitting
- **KeepAlive**: Cache component instances for tab interfaces
- **Vapor mode** (Vue 3.6 beta): Direct DOM operations, no VDOM. Feature-complete but in beta — expected stable Q3-Q4 2026.

### Svelte Performance
- **Compile-time reactivity**: No runtime framework overhead
- **No virtual DOM**: Direct DOM mutations
- **Smallest bundles**: ~3KB shared runtime vs 33-60KB for others
- **Built-in transitions**: Hardware-accelerated CSS transitions

### Rendering Strategy Performance Impact
| Strategy | TTFB | FCP | LCP | INP | JS Shipped |
|----------|------|-----|-----|-----|-----------|
| SSG | Best (CDN) | Best | Best | Depends on JS | Framework + page |
| Islands (Astro) | Best (CDN) | Best | Best | Best (minimal JS) | Only islands |
| SSR + Streaming | Good | Good | Good | Depends on hydration | Framework + page |
| PPR (Next.js) | Best (static shell) | Best | Good (streams) | Depends on hydration | Framework + page |
| SPA | Poor (empty HTML) | Poor (JS parse) | Poor | Good after load | Everything |

---

## 12. Network Optimization

### HTTP/3 (QUIC) — 35% Global Adoption
- UDP-based: no head-of-line blocking
- Faster connection setup (0-RTT)
- Better performance on lossy connections (mobile)
- **35% of global traffic** flows over HTTP/3 (as of late 2025, per Cloudflare)
- Enabled by default on major CDNs (Cloudflare, Fastly, Google)
- No code changes needed — server/CDN configuration

### Compression

| Algorithm | Compression | Speed | Support |
|-----------|------------|-------|---------|
| **Brotli** (br) | Best (15-25% smaller than gzip) | Slower compress, same decompress | All modern browsers |
| **gzip** | Good | Fast | Universal |
| **Zstandard** (zstd) | Better than Brotli for some content | Fastest | Chrome 123+, Firefox 126+, Edge 123+. Safari: not yet. Growing adoption. |

- Use Brotli for static assets (pre-compress at build time)
- Use gzip as fallback
- CDN typically handles this automatically

### Critical Request Chain
```
HTML → CSS → Font → LCP Image
          ↘ JS → Data Fetch → Render
```
- Minimize chain depth — fewer sequential requests
- Preload resources that are discovered late (fonts in CSS, images in JS)
- Inline critical CSS to remove one step from the chain

---

## 13. Performance Budgets

### Setting Budgets

| Metric | Budget (Recommended) | Why |
|--------|---------------------|-----|
| Total JS (compressed) | < 200KB | Parse time on mid-range mobile |
| Total CSS (compressed) | < 50KB | Render-blocking |
| Total page weight | < 1.5MB | Low-bandwidth users |
| LCP | < 2.5s | Google CWV Good threshold |
| INP | < 200ms | Google CWV Good threshold |
| CLS | < 0.1 | Google CWV Good threshold |
| TTFB | < 800ms | Foundation for good LCP |
| Total requests | < 50 | Connection overhead |

### Enforcing Budgets
```javascript
// bundlesize (CI check)
// package.json
{
  "bundlesize": [
    { "path": "dist/js/*.js", "maxSize": "200 kB" },
    { "path": "dist/css/*.css", "maxSize": "50 kB" }
  ]
}

// Lighthouse CI (performance score threshold)
// Assert performance score >= 90 in CI
```

### Performance.mark / Performance.measure
```typescript
// Custom performance marks for business-critical interactions
performance.mark('search-start')
const results = await searchAPI(query)
performance.mark('search-end')
performance.measure('search-duration', 'search-start', 'search-end')

// Send to analytics
const measure = performance.getEntriesByName('search-duration')[0]
analytics.track('search_performance', { duration: measure.duration })
```

---

## Performance Optimization Priority

When optimizing, work through this order. Each level has diminishing returns:

1. **Ship less JavaScript** — biggest impact. Remove unused deps, code split, lazy load.
2. **Optimize LCP** — preload hero image/font, inline critical CSS, SSR/SSG.
3. **Fix CLS** — image dimensions, font display, reserved space.
4. **Reduce INP** — break long tasks, virtualize lists, defer work.
5. **Cache aggressively** — CDN for static, SWR for API, service worker for offline.
6. **Optimize images** — modern formats, responsive srcset, lazy loading.
7. **Optimize fonts** — self-host, subset, variable fonts, font-display.
8. **Fine-tune loading** — resource hints, priority hints, speculation rules.
9. **Monitor continuously** — web-vitals RUM, Lighthouse CI, CrUX.
