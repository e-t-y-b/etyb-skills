# SEO Specialist — Deep Reference

**Always use `WebSearch` to verify current SEO best practices, Core Web Vitals thresholds, and Google algorithm updates. SEO evolves constantly.**

## Table of Contents
1. [Core Web Vitals](#1-core-web-vitals)
2. [Rendering Strategies and SEO](#2-rendering-strategies-and-seo)
3. [Structured Data](#3-structured-data)
4. [Technical SEO](#4-technical-seo)
5. [JavaScript SEO](#5-javascript-seo)
6. [Performance and SEO](#6-performance-and-seo)
7. [Content SEO for Web Apps](#7-content-seo-for-web-apps)
8. [AI and SEO](#8-ai-and-seo)
9. [International SEO](#9-international-seo)
10. [SEO Tools](#10-seo-tools)

---

## 1. Core Web Vitals

### LCP (Largest Contentful Paint)
- **Thresholds**: Good ≤ 2.5s | Needs Improvement 2.5-4.0s | Poor > 4.0s
- **Measures**: Render time of largest visible element (image, video poster, block text, background image)
- **Optimization**:
  - `<link rel="preload">` for LCP image/font
  - `fetchpriority="high"` on LCP image
  - Never lazy-load the LCP image
  - Inline critical CSS, eliminate render-blocking resources
  - Server-side render above-fold content
  - TTFB < 800ms (use CDN, edge SSR)
  - WebP/AVIF for images, proper sizing

### INP (Interaction to Next Paint) — Replaced FID March 2024
- **Thresholds**: Good ≤ 200ms | Needs Improvement 200-500ms | Poor > 500ms
- **Measures**: Full duration of ALL interactions (input delay + processing + presentation), reports 98th percentile
- **Key difference from FID**: Measures ALL interactions, not just the first one
- **Optimization**:
  - Break long tasks with `scheduler.yield()` or `setTimeout`
  - Code split — less JS on main thread
  - `content-visibility: auto` for off-screen content
  - Virtualize long lists (TanStack Virtual, react-window)
  - Web Workers for heavy computation
  - Debounce/throttle expensive handlers
  - `startViewTransition()` to defer visual updates

### CLS (Cumulative Layout Shift)
- **Thresholds**: Good ≤ 0.1 | Needs Improvement 0.1-0.25 | Poor > 0.25
- **Causes**: Images without dimensions, dynamic content injection, font loading shifts, late-loading ads
- **Fixes**:
  - Always set `width`/`height` on images/videos (or `aspect-ratio`)
  - Reserve space for ads/embeds
  - `font-display: optional` (best for CLS) or `swap` with `size-adjust`
  - Preload fonts, self-host instead of Google Fonts CDN
  - `transform` animations instead of layout-triggering properties
  - `contain: layout` on dynamic containers

### How Google Uses CWV
- Part of "page experience" ranking signals
- Acts as **tiebreaker** between otherwise equal content
- Uses **field data** (Chrome UX Report), not lab data
- **75th percentile** of page loads used for assessment
- Must meet Good for ALL THREE metrics to get page experience boost
- Content relevance still far outweighs CWV

---

## 2. Rendering Strategies and SEO

| Strategy | SEO Impact | Initial HTML | JS Shipped | Best For |
|----------|-----------|-------------|-----------|----------|
| **SSG** | Best | Full content | Minimal | Blogs, docs, marketing, catalogs |
| **SSR** | Excellent | Full content | Framework JS | Dynamic SEO content (news, search) |
| **ISR** | Excellent | Full (cached) | Framework JS | Large sites with changing content |
| **PPR** | Excellent | Static shell + streamed | Selective | Mix of static/dynamic per page |
| **Islands** | Excellent | Full content | Only interactive parts | Content sites with interactive islands |
| **CSR/SPA** | Poor | Empty shell | Everything | Authenticated apps (no SEO needs) |

### Key Principles
- **SEO-critical content MUST be in initial HTML** — don't rely on client-side JS rendering
- Googlebot CAN render JS but with delays (two-wave indexing) and resource limits
- Streaming SSR improves TTFB while maintaining full content delivery
- Server Components (React) produce real HTML with zero client JS — excellent for SEO
- Islands (Astro) ship zero JS by default — best CWV scores

### CSR Mitigation
If SPA is required for SEO pages, options (in order of preference):
1. Switch to SSR/SSG framework (best)
2. Hybrid: SSR for public pages, SPA for authenticated areas
3. Pre-rendering service (prerender.io) — workaround, not long-term solution

---

## 3. Structured Data

### JSON-LD (Recommended Format)
```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Article",
  "headline": "Title",
  "author": { "@type": "Person", "name": "Author" },
  "datePublished": "2025-01-15",
  "image": "https://example.com/image.jpg"
}
</script>
```

### Key Schemas and Their Rich Results

| Schema | Rich Result | Key Fields |
|--------|-----------|------------|
| **Article** | Article snippet | headline, author, datePublished, image |
| **Product** | Product card, merchant listing | name, offers (price, availability), image, review |
| **FAQPage** | Expandable FAQ | question, acceptedAnswer |
| **HowTo** | Step-by-step | step, name, text, image |
| **BreadcrumbList** | Breadcrumb trail | itemListElement (position, name, item) |
| **Organization** | Knowledge panel | name, logo, url, sameAs |
| **LocalBusiness** | Local pack, Maps | address, geo, openingHours |
| **Review/AggregateRating** | Star ratings | ratingValue, reviewCount |
| **WebSite + SearchAction** | Sitelinks searchbox | potentialAction, query-input |
| **VideoObject** | Video rich result | name, description, thumbnailUrl, uploadDate |

### Best Practices
- Google explicitly recommends JSON-LD over Microdata/RDFa
- Can have multiple JSON-LD blocks per page
- Keep structured data consistent with visible page content (mismatch = penalty)
- Use most specific type available (`NewsArticle` over `Article`)
- Validate with Google's Rich Results Test
- Monitor via Search Console "Enhancements" reports
- Rich results can increase CTR by 20-30%

---

## 4. Technical SEO

### Essentials Checklist
- **Canonical URLs**: `<link rel="canonical">` on every page. Self-referencing. Prevents duplicate content.
- **XML Sitemaps**: Max 50K URLs per file. Accurate `<lastmod>`. Submit via Search Console.
- **Robots.txt**: Controls crawling (not indexing). Don't block JS/CSS files needed for rendering.
- **Meta robots**: `noindex, nofollow` for pages that shouldn't be indexed.
- **HTTPS**: Required. HTTP sites are penalized.
- **Mobile viewport**: `<meta name="viewport" content="width=device-width, initial-scale=1">`

### URL Structure for SPAs
- Clean, descriptive URLs (`/products/blue-widget` not `/p?id=123`)
- Use `history.pushState` for client navigation
- Every meaningful view needs a unique URL
- **Never use hash routing** (`/#/page`) — Googlebot ignores fragments
- Framework routers (`next/link`, Angular `routerLink`) produce real `<a href>` elements

### Internal Linking
- Flat architecture: important pages within 3 clicks of homepage
- Descriptive anchor text (not "click here")
- Topical clusters: pillar page + cluster content linked bidirectionally
- In-content links pass more equity than nav/footer links
- Breadcrumb navigation aids both users and crawlers

### Mobile-First Indexing
- Google uses mobile version for indexing (fully rolled out)
- Mobile and desktop content must be identical
- Touch targets minimum 48x48px
- Font sizes minimum 16px body text
- No horizontal scrolling

---

## 5. JavaScript SEO

### How Googlebot Renders JS
- Evergreen Chromium-based Web Rendering Service (WRS)
- Has a rendering budget per page — heavy JS may not fully render
- Does NOT execute user interactions (no click, scroll, hover)
- Stateless: no localStorage/sessionStorage between crawls

### Two-Wave Indexing
1. **Wave 1**: Crawl raw HTML, index what's there, discover links in HTML
2. **Wave 2**: Enter render queue, execute JS, re-index with rendered content
- Delay between waves: seconds to days (weeks for low-priority pages)
- **Critical content should be in initial HTML** — don't depend on Wave 2

### Server Components and SEO
- React Server Components render on server, produce real HTML
- Zero client-side JS bundle for server components
- Full content in initial HTML — excellent for SEO
- Metadata API in Next.js: `export const metadata = {}` or `generateMetadata()`

### Hydration Strategies
| Strategy | SEO | INP Impact | Framework |
|----------|-----|------------|-----------|
| Full hydration | Good (HTML present) | Heavy (re-render entire tree) | React, Angular |
| Partial/Progressive | Good | Better (only interactive parts) | Astro, RSC |
| Resumability | Good | Best (no hydration) | Qwik |
| Islands | Good | Best (independent hydration) | Astro |

---

## 6. Performance and SEO

### Page Speed as Ranking Factor
- Confirmed since 2018, reinforced by CWV in 2021
- Primarily affects mobile rankings
- Acts as tiebreaker — content relevance is far more important
- Poor speed increases bounce rates, indirectly hurting rankings

### Image Optimization
- **WebP**: 25-35% smaller than JPEG, widely supported
- **AVIF**: 50% smaller than JPEG, growing support
- **Lazy loading**: `loading="lazy"` on below-fold images. NEVER on LCP image.
- **Responsive**: `srcset` + `sizes` for appropriate resolution per device
- **Dimensions**: Always specify `width`/`height` to prevent CLS
- **Framework components**: `next/image`, `NgOptimizedImage` — auto WebP/AVIF, lazy loading, srcset

### Font Optimization
- `font-display: optional` — best for CLS (uses font only if cached)
- `font-display: swap` — shows text immediately, swaps font (may cause CLS)
- Subset fonts (strip unused characters)
- Variable fonts (one file for all weights)
- Preload critical fonts: `<link rel="preload" href="font.woff2" as="font" crossorigin>`
- Self-host fonts (faster than Google Fonts CDN)
- `size-adjust`, `ascent-override` to match fallback metrics

### Resource Hints
| Hint | Purpose | Use For |
|------|---------|---------|
| `preload` | Fetch critical resources early | LCP image, fonts, critical JS |
| `prefetch` | Fetch for next navigation (low priority) | Next page assets |
| `preconnect` | Early connection (DNS+TCP+TLS) | Third-party origins |
| `dns-prefetch` | DNS lookup only | Fallback for preconnect |
| `fetchpriority="high"` | Prioritize resource | LCP image |

### Critical CSS
- Inline critical CSS in `<head>` for above-fold content
- Keep under 14KB (fits in first TCP roundtrip)
- Tools: `critical`, `critters` (auto-extracts critical CSS)
- Modern frameworks handle CSS code splitting automatically

---

## 7. Content SEO for Web Apps

### Meta Tags (Every Page)
- **Title**: 50-60 chars, primary keyword near beginning, unique per page
- **Description**: 150-160 chars, compelling copy, unique per page
- **OG tags**: `og:title`, `og:description`, `og:image` (1200x630px), `og:url`, `og:type`
- **Twitter**: `twitter:card` (`summary_large_image`), `twitter:title`, `twitter:image`
- **In Next.js**: `metadata` export or `generateMetadata()` function
- **In Angular**: `Meta` and `Title` services, or Angular Universal for SSR

### Dynamic OG Images
- `@vercel/og` or `satori` for programmatic image generation
- Generate unique social share images per page/article
- Massive impact on social engagement and CTR

### Heading Hierarchy
- One `<h1>` per page
- Logical nesting: h1 > h2 > h3 (don't skip levels)
- Describe content, don't use for styling

### E-E-A-T (Experience, Expertise, Authoritativeness, Trustworthiness)
- Not a direct ranking factor — informs quality rater guidelines
- Implementation: author bios, about pages, editorial policies, citations
- YMYL topics held to highest standards
- **Trustworthiness** is most important factor

---

## 8. AI and SEO (2025)

### Google AI Overviews / SGE Impact
- AI Overviews appear at top of informational queries, pushing organic results down
- Being **cited** in AI Overviews drives traffic
- Structured data helps Google understand and cite your content
- Long-tail, specific queries less likely to trigger AI Overviews
- Transactional/navigational queries less affected

### Optimizing for AI-Powered Search
- Write clear, direct answers to specific questions
- Structured data for entity relationships and facts
- Topical authority through comprehensive content clusters
- **Information gain**: provide unique data/perspectives not found elsewhere
- Ensure factual accuracy — AI cross-references multiple sources
- Be the definitive source for your topic/brand

### AI-Generated Content
- Google: focus on quality, not creation method
- Not automatically penalized
- Scaled AI content without editorial oversight violates spam policies
- Add genuine expertise, original insight, value
- SpamBrain detects low-quality mass-produced AI content

---

## 9. International SEO

### hreflang Implementation
```html
<link rel="alternate" hreflang="en-us" href="https://example.com/en/page">
<link rel="alternate" hreflang="es" href="https://example.com/es/page">
<link rel="alternate" hreflang="x-default" href="https://example.com/page">
```
- Must be **reciprocal** (bidirectional references)
- Include **self-referencing** hreflang
- `x-default` for language selector / fallback
- Can implement via HTML tags, HTTP headers, or XML sitemap

### Domain Strategy
| Approach | Geo Signal | Authority | Best For |
|----------|-----------|-----------|----------|
| ccTLDs (example.de) | Strongest | Separate per domain | Single-market brands |
| Subdirectories (/de/) | Good (with hreflang) | Shared (recommended) | Most sites |
| Subdomains (de.example.com) | Weak | Separate | Different teams per region |

Google recommends **subdirectories** for most cases.

### Localization vs Translation
- Translation: minimum viable. Localization: adapt culturally (currency, dates, imagery, idioms)
- Localized content may target different keywords (search behavior varies)
- Professional translation with local review outperforms machine translation

---

## 10. SEO Tools

### Essential Stack
- **Google Search Console**: Performance, indexing, CWV field data, structured data validation
- **web-vitals** npm package: RUM measurement, attribution build for diagnostics
- **Lighthouse CI**: Automated auditing in CI/CD, performance budgets, fail builds on regression
- **PageSpeed Insights**: Lab + field data combined for a URL
- **Chrome DevTools**: Performance panel, Lighthouse tab, Core Web Vitals overlay

### Third-Party
- **Ahrefs**: Backlinks, keyword research, competitor analysis, site audits
- **SEMrush**: Similar to Ahrefs + content marketing, PPC analysis
- **Screaming Frog**: Desktop crawler for technical audits (broken links, redirects, missing meta)
- **Google Rich Results Test**: Validate structured data
- **Facebook Sharing Debugger / Twitter Card Validator**: Test social sharing appearance

### RUM (Real User Monitoring)
```javascript
import { onLCP, onINP, onCLS } from 'web-vitals';

onLCP(console.log);  // or send to analytics
onINP(console.log);
onCLS(console.log);
```
- Attribution build provides diagnostic info (which element, which interaction)
- Send to: Google Analytics 4, custom analytics endpoint, Vercel Analytics, SpeedCurve

### Lighthouse CI in Pipeline
```yaml
# GitHub Actions
- run: npx @lhci/cli autorun
  env:
    LHCI_ASSERT: |
      categories:performance >= 0.9
      categories:accessibility >= 0.9
      categories:seo >= 0.9
```

---

## SEO Priority Checklist

1. **Rendering**: SSR or SSG for SEO-critical pages. Never pure CSR for public content.
2. **Core Web Vitals**: LCP ≤ 2.5s, INP ≤ 200ms, CLS ≤ 0.1. Measure with RUM.
3. **Structured Data**: JSON-LD for all relevant content types.
4. **Technical**: Canonical URLs, XML sitemaps, proper robots directives, HTTPS.
5. **Meta Tags**: title, description, OG on every page. Dynamic `generateMetadata()`.
6. **Images**: WebP/AVIF, srcset, lazy loading (except LCP), always set dimensions.
7. **JS SEO**: Content in initial HTML. Minimize client-side rendering for indexable content.
8. **Monitoring**: web-vitals RUM + Lighthouse CI + Search Console.
9. **AI Search**: Structured data, clear answers, topical authority, information gain.
10. **International**: hreflang with subdirectories, localization, reciprocal references.
