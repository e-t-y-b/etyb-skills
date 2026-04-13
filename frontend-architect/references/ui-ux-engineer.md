# UI/UX Engineer — Deep Reference

**Always use `WebSearch` to verify tool versions, design token specs, and component library status. Design tooling evolves rapidly.**

## Table of Contents
1. [Design Systems](#1-design-systems)
2. [Design Tokens](#2-design-tokens)
3. [Component Library Architecture](#3-component-library-architecture)
4. [Storybook](#4-storybook)
5. [Figma-to-Code Workflow](#5-figma-to-code-workflow)
6. [CSS Architecture](#6-css-architecture)
7. [Animation and Motion](#7-animation-and-motion)
8. [Responsive Design](#8-responsive-design)
9. [Dark Mode and Theming](#9-dark-mode-and-theming)
10. [Typography](#10-typography)
11. [Micro-Interactions and UX Patterns](#11-micro-interactions-and-ux-patterns)
12. [Design-to-Development Workflow](#12-design-to-development-workflow)
13. [Accessibility in Design Systems](#13-accessibility-in-design-systems)

---

## 1. Design Systems

### What a Design System Is
A design system is not a component library. It's the complete set of standards, documentation, and tools that drive consistent product design:

```
Design System
├── Design Tokens (colors, spacing, typography, shadows, motion)
├── Component Library (UI primitives + composed patterns)
├── Documentation (usage guidelines, do/don't examples)
├── Design Assets (Figma library, icons, illustrations)
├── Code Standards (naming conventions, API patterns, a11y requirements)
└── Governance (contribution process, versioning, breaking changes)
```

### Building vs Buying

| Approach | When to Use | Examples |
|----------|-----------|---------|
| **Build from headless primitives** | Custom brand, unique design language | Radix + Tailwind, React Aria + CSS |
| **Adopt existing library** | Internal tools, speed over uniqueness | MUI, Ant Design, Vuetify, Angular Material |
| **Fork and customize** | shadcn approach — own the code | shadcn/ui, shadcn-vue, shadcn-svelte |
| **Full custom** | Large org, dedicated design system team | Rare — usually start headless |

### Design System Maturity Model
1. **Ad hoc**: No system. Each team builds independently.
2. **Component library**: Shared UI components, basic documentation.
3. **Design system**: Tokens, components, guidelines, Figma library, contribution process.
4. **Platform**: Multi-brand support, automated tooling, design-to-code pipeline, analytics.

### Multi-Brand / White-Label Systems
- Use design tokens as the theming layer
- Same components, different token sets per brand
- CSS custom properties for runtime theme switching
- Separate token packages per brand, shared component package

### Governance and Contribution
- **RFC process** for new components or breaking changes
- **Semantic versioning** for component library releases
- **Deprecation policy**: Mark deprecated, provide migration path, remove after 2 major versions
- **Design review** before component approval
- **Automated visual regression** to catch unintended changes

---

## 2. Design Tokens

### What Design Tokens Are
Design tokens are the atomic values of a design system — the single source of truth for colors, spacing, typography, shadows, borders, motion, etc. They bridge design and code.

### Token Architecture (3-Tier)
```
Tier 1: Global/Primitive Tokens (raw values)
  --color-blue-500: #3b82f6
  --space-4: 1rem
  --font-size-lg: 1.125rem

Tier 2: Semantic/Alias Tokens (intent)
  --color-primary: var(--color-blue-500)
  --color-text: var(--color-gray-900)
  --space-component-gap: var(--space-4)

Tier 3: Component Tokens (specific)
  --button-bg: var(--color-primary)
  --button-padding: var(--space-3) var(--space-4)
  --card-border-radius: var(--radius-lg)
```

**Why 3 tiers matter:**
- Changing a primitive token cascades through semantics to components
- Themes override at the semantic layer — swap `--color-primary` without touching components
- Component tokens allow fine-grained overrides

### W3C Design Tokens Specification (v2025.10 — First Stable)
- First stable version published **October 28, 2025** by the Design Tokens Community Group
- JSON-based: `{ "color": { "primary": { "$value": "#3b82f6", "$type": "color" } } }`
- All spec properties use `$` prefix: `$value`, `$type`, `$description`, `$extensions`, `$deprecated`
- Token types: color (CSS Color 4 spaces including P3/Oklch), dimension, fontFamily, fontWeight, duration, cubicBezier, number, strokeStyle, border, transition, shadow, gradient, typography
- Composite types for shadows, gradients, borders, typography
- `$extends` property and group inheritance for multi-brand management
- Supported by Style Dictionary 5.x, Tokens Studio, Figma (native DTCG import/export)
- **Status**: Stable — use for all new systems

### Token Types
| Type | Examples | CSS Implementation |
|------|---------|-------------------|
| Color | Primary, surface, text, error | `--color-*` custom properties |
| Spacing | Component gap, page margin, stack | `--space-*` (4px/8px scale) |
| Typography | Font family, size, weight, line-height | `--font-*`, `--text-*` |
| Sizing | Icon size, avatar, touch target | `--size-*` |
| Border radius | Rounded, pill, circle | `--radius-*` |
| Shadow | Elevation levels (sm, md, lg, xl) | `--shadow-*` |
| Motion | Duration, easing | `--duration-*`, `--ease-*` |
| Opacity | Disabled, overlay | `--opacity-*` |
| Z-index | Layers (dropdown, modal, toast) | `--z-*` |

### Style Dictionary
- Build system for design tokens
- Input: JSON/YAML token definitions
- Output: CSS custom properties, SCSS, JS modules, iOS, Android, etc.
- Transform pipeline: name format, value resolution, platform output
- **Use when**: Need multi-platform token output (web + mobile + design tool)

### Tokens Studio (Figma Plugin)
- Define tokens in Figma, sync to code via JSON
- Git integration (push token changes as PRs)
- Supports W3C Design Tokens format
- Theme switching in Figma tied to code tokens

---

## 3. Component Library Architecture

### Headless Component Approach — Recommended

Build accessible behavior without styling, then layer design on top:

| Library | Framework | Components | Philosophy |
|---------|-----------|-----------|------------|
| **Radix UI** | React | 30+ primitives | Unstyled, accessible, composable |
| **React Aria** (Adobe) | React | 40+ hooks/components | Maximum a11y compliance, i18n |
| **Headless UI** | React, Vue | 10+ components | Tailwind Labs, simpler API |
| **Bits UI** | Svelte | 30+ primitives | Radix port for Svelte |
| **Radix Vue** | Vue | 30+ primitives | Radix port for Vue |
| **Angular CDK** | Angular | Foundation utilities | Overlay, drag-drop, a11y, virtual scroll |
| **Melt UI** | Svelte | Builder pattern | Maximum flexibility |

### Component API Design Principles
1. **Composition over configuration**: `<Select><SelectTrigger /><SelectContent>...</SelectContent></Select>` — not `<Select options={[...]} />`
2. **Reasonable defaults**: Work without configuration, customize when needed
3. **Controlled and uncontrolled**: Support both `value`/`onChange` and internal state
4. **Slot/children pattern**: Allow content customization without prop explosion
5. **Polymorphic `as` prop**: Render as different elements (`<Button as="a" href="...">`)
6. **Forward refs and native props**: Pass through HTML attributes, forward refs

### Component Anatomy Template
```typescript
// Every component in a design system should have:
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'ghost' | 'destructive'  // Visual variants
  size?: 'sm' | 'md' | 'lg'                                     // Size scale
  disabled?: boolean                                              // State
  loading?: boolean                                               // Async state
  asChild?: boolean                                               // Composition
  children: React.ReactNode                                       // Content
  // ...native button props via ComponentPropsWithoutRef<'button'>
}
```

### Variant Management (CVA)
```typescript
// class-variance-authority (cva) — recommended for Tailwind component variants
import { cva, type VariantProps } from 'class-variance-authority'

const button = cva('inline-flex items-center rounded font-medium', {
  variants: {
    variant: {
      primary: 'bg-primary text-white hover:bg-primary/90',
      secondary: 'bg-secondary text-secondary-foreground',
      ghost: 'hover:bg-accent hover:text-accent-foreground',
    },
    size: {
      sm: 'h-8 px-3 text-sm',
      md: 'h-10 px-4',
      lg: 'h-12 px-6 text-lg',
    },
  },
  defaultVariants: { variant: 'primary', size: 'md' },
})
```

---

## 4. Storybook

### Storybook 10 (Current)
- **CSF Factories**: Next evolution of Component Story Format — `preview.meta()` + `meta.story()` for full type safety
- **Visual testing**: Chromatic integration for pixel-perfect regression testing
- **Vitest addon** (`@storybook/addon-vitest`): Run component tests via Vitest, calculate project coverage
- **Interaction testing**: Play functions + `sb.mock` for simplified mocking
- **MCP integration**: `@storybook/addon-mcp` exposes component knowledge to AI agents
- **Docs mode**: Auto-generated documentation from stories + JSDoc + MDX
- **Controls**: Auto-generated knobs from component props
- **First-class Vite support**: Fast builds with Vite builder
- **Framework support**: React, Vue, Angular, Svelte, Web Components

### CSF Factories (Storybook 10+)
```typescript
// Button.stories.ts
import { config } from '#storybook/preview'
import { Button } from './Button'

const meta = config.meta({
  title: 'Components/Button',
  component: Button,
  tags: ['autodocs'],
  argTypes: {
    variant: { control: 'select', options: ['primary', 'secondary', 'ghost'] },
    size: { control: 'radio', options: ['sm', 'md', 'lg'] },
  },
})

export const Primary = meta.story({
  args: { variant: 'primary', children: 'Click me' },
})

export const WithInteraction = meta.story({
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement)
    await userEvent.click(canvas.getByRole('button'))
    await expect(canvas.getByText('Clicked!')).toBeInTheDocument()
  },
})
```

### Storybook Addons
- **a11y**: Automated accessibility checks (axe-core) per story
- **viewport**: Responsive preview at different breakpoints
- **backgrounds**: Switch background colors for contrast testing
- **actions**: Log event handlers
- **measure**: Inspect spacing and dimensions
- **designs**: Link Figma frames to stories

### Visual Regression Testing
- **Chromatic** (by Storybook team): Cloud-based visual testing
  - Captures screenshots of every story in CI
  - Visual diff review workflow
  - Turbosnap: only screenshots stories with changed code
- **Percy** (BrowserStack): Alternative visual testing platform
- **Playwright screenshots**: Self-hosted visual regression with `toHaveScreenshot()`

---

## 5. Figma-to-Code Workflow

### Figma Dev Mode
- Inspect designs with developer-focused view
- CSS/iOS/Android code snippets per element
- Component details: props, variants, states
- Redlines: spacing, dimensions auto-displayed
- **Key insight**: Dev Mode is for inspection, not code generation — use it to understand design intent

### Figma Variables (Design Tokens)
- Figma-native design tokens: colors, numbers, strings, booleans
- Collection/mode system maps to theme/breakpoint switching
- Export to CSS custom properties via plugins (Tokens Studio, Variables Export)
- **Bridge**: Define tokens in Figma variables → export → CSS custom properties → components

### Design Handoff Workflow
```
1. Designer defines tokens in Figma Variables / Tokens Studio
2. Tokens sync to Git (JSON format)
3. Build system (Style Dictionary) generates CSS/JS tokens
4. Developer builds components using generated tokens
5. Components documented in Storybook
6. Storybook stories linked back to Figma via Design addon
7. Visual regression catches unintended changes
```

### Figma Plugins for Developers
- **Tokens Studio**: Design token management with Git sync
- **Figma to Code**: Generate HTML/CSS/React code from Figma frames
- **Locofy**: AI-powered Figma-to-code (React, Vue, Next.js)
- **Anima**: Generate code from Figma with design-to-code accuracy

### Figma MCP / AI Integration
- Use Figma API/MCP to read design data programmatically
- AI tools can parse Figma frames and generate component code
- Style extraction: colors, fonts, spacing from Figma designs
- **Workflow**: Figma frame → AI reads design specs → generates component matching design

---

## 6. CSS Architecture

### Modern CSS Features (2025)
```css
/* Container queries — component-level responsiveness */
.card-container { container-type: inline-size; }
@container (min-width: 400px) {
  .card { display: grid; grid-template-columns: 1fr 2fr; }
}

/* CSS nesting — native, no preprocessor needed */
.card {
  padding: 1rem;
  & .title { font-weight: bold; }
  &:hover { background: var(--hover-bg); }
  @media (width >= 768px) { padding: 2rem; }
}

/* :has() — parent selector */
.form:has(:invalid) { border-color: red; }
.card:has(img) { padding-top: 0; }

/* CSS layers — control specificity */
@layer reset, base, components, utilities;
@layer components {
  .button { padding: 0.5rem 1rem; }
}

/* Subgrid — inherit parent grid in children */
.grid { display: grid; grid-template-columns: repeat(3, 1fr); }
.grid-item { display: grid; grid-template-columns: subgrid; grid-column: span 3; }

/* :is() / :where() — selector grouping */
:is(h1, h2, h3) { font-weight: bold; }  /* normal specificity */
:where(h1, h2, h3) { color: inherit; }  /* zero specificity */

/* Scroll-driven animations */
@keyframes reveal { from { opacity: 0; } to { opacity: 1; } }
.card { animation: reveal linear; animation-timeline: view(); }
```

### Tailwind CSS v4
- CSS-first configuration (no `tailwind.config.js` needed)
- Lightning CSS engine (faster builds)
- `@theme` directive for custom values
- Automatic content detection
- Container queries: `@container`, `@sm:`, `@lg:`
- 3D transforms: `rotate-x-45`, `perspective-500`
- **Migration**: `npx @tailwindcss/upgrade` from v3

### CSS Custom Properties for Theming
```css
:root {
  --color-bg: #ffffff;
  --color-text: #111827;
  --color-primary: #3b82f6;
  --radius: 0.5rem;
  --shadow: 0 1px 3px rgba(0,0,0,0.1);
}

[data-theme="dark"] {
  --color-bg: #0f172a;
  --color-text: #f1f5f9;
  --color-primary: #60a5fa;
}

.card {
  background: var(--color-bg);
  color: var(--color-text);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
}
```

---

## 7. Animation and Motion

### Motion Design Principles
1. **Purpose**: Every animation should communicate something (state change, hierarchy, feedback)
2. **Speed**: Fast transitions feel responsive (150-300ms). Slow ones feel sluggish.
3. **Easing**: Ease-out for entrances, ease-in for exits, ease-in-out for movement
4. **Respect preferences**: Always honor `prefers-reduced-motion`

### Framework Animation Libraries

| Library | Framework | Best For |
|---------|-----------|----------|
| **Motion** (formerly Framer Motion) | React, Vue | Spring physics, gestures, layout animations, scroll |
| **GSAP** (now 100% free, acquired by Webflow) | Any | Advanced timelines, ScrollTrigger, SVG morphing, scroll-driven |
| **Svelte transitions** | Svelte | Built-in, zero-config transitions |
| **Angular Animations** | Angular | Component state transitions |
| **Auto Animate** | Any | Drop-in list animations |

### View Transitions API
```typescript
// Same-document transition
document.startViewTransition(() => {
  updateDOM() // Your DOM changes
})

// CSS customization
::view-transition-old(root) { animation: fade-out 0.2s; }
::view-transition-new(root) { animation: fade-in 0.2s; }

// Named transitions for specific elements
.hero-image { view-transition-name: hero; }
```
- Smooth page transitions without SPA overhead
- Cross-document transitions (MPA)
- Framework support: Next.js (experimental), SvelteKit, Astro

### Scroll-Driven Animations (CSS)
```css
/* Animate as element scrolls into view */
@keyframes slide-in { from { transform: translateX(-100%); } }
.element {
  animation: slide-in linear;
  animation-timeline: view();
  animation-range: entry 0% entry 100%;
}
```
- Pure CSS, no JavaScript needed
- Hardware-accelerated, smooth performance
- Progressive enhancement — falls back to static

### Lottie Animations
- After Effects animations rendered as JSON
- Lightweight player: `lottie-web`, `@lottiefiles/dotlottie-web`
- **When to use**: Complex illustrative animations, onboarding, empty states, loading

---

## 8. Responsive Design

### Modern Responsive Approach
```
Traditional: Media queries (viewport-based)
Modern: Container queries (component-based) + Fluid values + Intrinsic sizing
```

### Container Queries
```css
/* Component responds to its container, not viewport */
.card-wrapper { container-type: inline-size; container-name: card; }

@container card (min-width: 400px) {
  .card { flex-direction: row; }
}

/* With Tailwind v4 */
<div class="@container">
  <div class="flex flex-col @md:flex-row">...</div>
</div>
```
- Components are self-contained — responsive regardless of where placed
- Better for reusable components and design systems

### Fluid Typography
```css
/* clamp(min, preferred, max) */
h1 { font-size: clamp(1.5rem, 1rem + 2vw, 3rem); }
body { font-size: clamp(1rem, 0.875rem + 0.5vw, 1.125rem); }

/* Full fluid type scale */
:root {
  --text-sm: clamp(0.8rem, 0.75rem + 0.25vw, 0.875rem);
  --text-base: clamp(1rem, 0.9rem + 0.5vw, 1.125rem);
  --text-lg: clamp(1.125rem, 1rem + 0.625vw, 1.25rem);
  --text-xl: clamp(1.25rem, 1rem + 1.25vw, 1.875rem);
  --text-2xl: clamp(1.5rem, 1rem + 2.5vw, 2.5rem);
}
```
- Smooth scaling between breakpoints — no jumps
- Replace most `@media` queries for font sizing

### Fluid Spacing
```css
:root {
  --space-s: clamp(0.75rem, 0.6rem + 0.75vw, 1rem);
  --space-m: clamp(1rem, 0.8rem + 1vw, 1.5rem);
  --space-l: clamp(1.5rem, 1rem + 2.5vw, 2.5rem);
}
```
- Apply fluid values to padding, margins, gaps
- Consistent proportions at all viewport sizes

### Intrinsic Design Patterns
```css
/* Content dictates layout, not breakpoints */
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(min(100%, 300px), 1fr)); gap: 1rem; }

/* Sidebar layout that collapses naturally */
.with-sidebar { display: flex; flex-wrap: wrap; gap: 1rem; }
.with-sidebar > :first-child { flex-basis: 300px; flex-grow: 1; }
.with-sidebar > :last-child { flex-basis: 0; flex-grow: 999; min-width: 60%; }
```

---

## 9. Dark Mode and Theming

### Implementation Strategies

| Strategy | How | Pros | Cons |
|----------|-----|------|------|
| CSS `light-dark()` | `color-scheme: light dark` + `light-dark()` | Native CSS, minimal code | Limited to color values |
| CSS custom properties | Toggle `data-theme` attribute | Simple, performant, no flash | Manual color management |
| Tailwind `dark:` | `dark:bg-gray-900` classes | Easy with Tailwind | Doubles class count |
| CSS `color-scheme` | `color-scheme: dark` | Native form elements adapt | Limited to system colors |
| Token-based theming | Swap token set at semantic layer | Scalable, multi-brand | More architecture upfront |

### Recommended Pattern (Token-Based)
```css
/* tokens.css */
:root, [data-theme="light"] {
  color-scheme: light;
  --color-bg: #ffffff;
  --color-surface: #f8fafc;
  --color-text: #0f172a;
  --color-text-muted: #64748b;
  --color-primary: #2563eb;
  --color-border: #e2e8f0;
}

[data-theme="dark"] {
  color-scheme: dark;
  --color-bg: #0f172a;
  --color-surface: #1e293b;
  --color-text: #f1f5f9;
  --color-text-muted: #94a3b8;
  --color-primary: #60a5fa;
  --color-border: #334155;
}
```

### Preventing Flash of Wrong Theme (FOWT)
```html
<!-- Inline script in <head> BEFORE any CSS/body -->
<script>
  const theme = localStorage.getItem('theme') ||
    (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
  document.documentElement.setAttribute('data-theme', theme)
</script>
```

### System Preference Detection
```typescript
const prefersDark = window.matchMedia('(prefers-color-scheme: dark)')

// Listen for system changes
prefersDark.addEventListener('change', (e) => {
  if (userPreference === 'system') {
    setTheme(e.matches ? 'dark' : 'light')
  }
})
```

### Three-Way Toggle (Light / Dark / System)
Most design systems should support: explicit light, explicit dark, follow system preference. Store choice in localStorage and `data-theme` attribute.

---

## 10. Typography

### Web Font Strategy
```css
/* Variable font with fallback */
@font-face {
  font-family: 'Inter';
  src: url('/fonts/Inter-Variable.woff2') format('woff2');
  font-weight: 100 900;
  font-display: swap;
  font-style: normal;
}

/* Optical sizing for variable fonts */
body { font-optical-sizing: auto; }
```

### Variable Fonts
- Single file contains all weights, widths, styles
- Smaller total download than multiple static font files
- Smooth weight transitions for hover/animation effects
- Popular variable fonts: Inter, Geist, Plus Jakarta Sans, Source Sans 3, Manrope

### Font Loading Strategy
1. **`font-display: swap`**: Show fallback immediately, swap when loaded. Good for body text.
2. **`font-display: optional`**: Use cached font or fallback. Zero CLS. Best for performance.
3. **Preload critical fonts**: `<link rel="preload" href="font.woff2" as="font" crossorigin>`
4. **Self-host**: Avoid Google Fonts CDN — self-host for speed and privacy
5. **Subset**: Strip unused characters with `unicode-range` or build-time subsetting

### Type Scale
```css
:root {
  /* Minor third scale (1.2 ratio) — good for most apps */
  --text-xs: 0.694rem;
  --text-sm: 0.833rem;
  --text-base: 1rem;
  --text-lg: 1.2rem;
  --text-xl: 1.44rem;
  --text-2xl: 1.728rem;
  --text-3xl: 2.074rem;
  --text-4xl: 2.488rem;
}
```
- Use a consistent mathematical ratio (1.125, 1.2, 1.25, 1.333, 1.5)
- Tools: utopia.fyi for fluid type scales, typescale.com for previewing ratios

---

## 11. Micro-Interactions and UX Patterns

### Loading States (Best Practices)
| State | Pattern | When |
|-------|---------|------|
| Initial load | Skeleton screens | Page/component first render |
| Action pending | Button spinner + disabled | Form submit, API call |
| Background refresh | Subtle indicator (top bar) | Data refetch |
| Long operation | Progress bar + status text | File upload, export |
| Optimistic | Instant UI update | Like, comment, toggle |

### Skeleton Screens > Spinners
- Skeletons provide spatial preview — user knows what's coming
- Use `pulse` animation on gray blocks matching content shape
- Never skeleton text lines — use varying width blocks
- Remove all at once or individually as content loads

### Toast / Notification Patterns
- Auto-dismiss after 3-5 seconds (configurable)
- Allow manual dismiss
- Stack with limit (max 3-5 visible)
- Position: top-right or bottom-right (avoid bottom-center on mobile — covers nav)
- Accessible: `role="status"` with `aria-live="polite"`

### Optimistic UI
```
User clicks → Update UI immediately → Send request → 
  Success: Keep UI state
  Error: Revert + show error toast
```
- Critical for perceived performance
- TanStack Query, SWR provide built-in optimistic update support

### Empty States
- Never show a blank screen — always communicate what should be here
- Include: illustration/icon, explanatory text, primary action (CTA)
- Different empty states: first use, no results, error, no permission

---

## 12. Design-to-Development Workflow

### The Modern Pipeline
```
1. Design Tokens (Figma Variables → Tokens Studio → Git PR)
       ↓
2. Token Build (Style Dictionary → CSS custom properties + JS constants)
       ↓
3. Component Development (Headless primitives + tokens + Storybook)
       ↓
4. Visual QA (Chromatic / Percy — screenshot comparison vs Figma)
       ↓
5. Documentation (Storybook auto-docs + usage guidelines)
       ↓
6. Release (Semantic versioning, changelog, migration guide)
```

### Design QA Checklist
- [ ] Colors match design tokens (not hard-coded hex values)
- [ ] Spacing uses token scale (not arbitrary pixel values)
- [ ] Typography follows type scale
- [ ] Component matches Figma at all breakpoints
- [ ] Hover, focus, active, disabled states implemented
- [ ] Dark mode renders correctly
- [ ] Keyboard navigation works
- [ ] Screen reader announces correctly

### Visual Regression in CI
```yaml
# GitHub Actions — Chromatic visual testing
- name: Visual Testing
  uses: chromaui/action@latest
  with:
    projectToken: ${{ secrets.CHROMATIC_PROJECT_TOKEN }}
    buildScriptName: build-storybook
    exitZeroOnChanges: true  # don't fail build, just flag changes
```

---

## 13. Accessibility in Design Systems

### Designing for Accessibility
Every design system component should meet WCAG 2.2 AA by default:

- **Color contrast**: 4.5:1 for normal text, 3:1 for large text. Check in both light and dark themes.
- **Focus indicators**: Visible, high-contrast focus ring (not just browser default). Minimum 2px solid contrasting outline.
- **Touch targets**: Minimum 44x44px (48x48px recommended). Ensure adequate spacing between targets.
- **Motion**: Respect `prefers-reduced-motion`. Disable or reduce all animations.
- **Color independence**: Never convey information by color alone (add icons, text, patterns).

### Inclusive Component Patterns
```
✅ Dialog: Focus trap, Escape to close, return focus to trigger
✅ Tabs: Arrow key navigation, proper ARIA roles (tablist/tab/tabpanel)
✅ Dropdown: Arrow key navigation, type-ahead search, proper ARIA
✅ Toast: aria-live="polite", auto-dismiss pausable on hover/focus
✅ Form: Labels, error messages linked via aria-describedby
✅ Tooltip: Keyboard accessible (on focus, not just hover)
```

### Testing Accessibility in Components
1. **Storybook a11y addon**: Automated axe-core checks per story
2. **jest-axe**: Unit test accessibility with `expect(container).toHaveNoViolations()`
3. **Playwright a11y**: `expect(page).toBeAccessible()` in E2E
4. **Manual screen reader testing**: Essential — automated tools catch only ~30% of issues

---

## Decision Summary

| Decision | Default | Switch When |
|----------|---------|-------------|
| Design tokens | CSS custom properties (3-tier) | Multi-platform → Style Dictionary |
| Component approach | Headless primitives + Tailwind | Internal tools → full library (MUI) |
| Variant management | CVA (class-variance-authority) | Non-Tailwind → CSS custom properties |
| Documentation | Storybook 8 | Small team → inline docs |
| Visual testing | Chromatic | Self-hosted → Playwright screenshots |
| Figma sync | Tokens Studio → Git | Simple → manual token maintenance |
| Dark mode | Token-based (data-theme attribute) | Simple app → Tailwind dark: classes |
| Typography | Variable fonts + fluid scale | Performance-critical → system fonts |
| Responsive | Container queries + fluid values | IE support needed → media queries only |
| Animation | View Transitions API + CSS | Complex → Framer Motion / GSAP |
