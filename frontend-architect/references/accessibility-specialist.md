# Accessibility Specialist — Deep Reference

**Always use `WebSearch` to verify WCAG versions, legal requirements, and tool compatibility. Accessibility standards and legal landscape evolve frequently.**

## Table of Contents
1. [WCAG 2.2](#1-wcag-22)
2. [WCAG 3.0 Status](#2-wcag-30-status)
3. [ARIA Patterns](#3-aria-patterns)
4. [Keyboard Navigation](#4-keyboard-navigation)
5. [Screen Reader Testing](#5-screen-reader-testing)
6. [Color and Contrast](#6-color-and-contrast)
7. [Motion and Animation](#7-motion-and-animation)
8. [Forms Accessibility](#8-forms-accessibility)
9. [Automated Testing Tools](#9-automated-testing-tools)
10. [Accessible Component Patterns](#10-accessible-component-patterns)
11. [Legal Landscape](#11-legal-landscape)
12. [Framework Accessibility](#12-framework-accessibility)
13. [Cognitive Accessibility](#13-cognitive-accessibility)
14. [Media Accessibility](#14-media-accessibility)

---

## 1. WCAG 2.2

### Overview
- **WCAG 2.2** became W3C Recommendation on October 5, 2023
- Builds on WCAG 2.1 with 9 new success criteria
- Three conformance levels: A (minimum), AA (standard target), AAA (enhanced)
- **Target AA** for all web projects — it's the legal standard in most jurisdictions

### The Four Principles (POUR)

#### Perceivable
Users must be able to perceive the information presented.

| Criterion | Level | What It Means |
|-----------|-------|--------------|
| 1.1.1 Non-text Content | A | All images, icons, charts need text alternatives |
| 1.2.1-5 Time-based Media | A-AA | Captions for video, transcripts for audio, audio descriptions |
| 1.3.1 Info and Relationships | A | Structure conveyed through markup (headings, lists, tables, landmarks) |
| 1.3.4 Orientation | AA | Content works in both portrait and landscape |
| 1.3.5 Identify Input Purpose | AA | `autocomplete` on personal data inputs |
| 1.4.1 Use of Color | A | Color is not the sole means of conveying information |
| 1.4.3 Contrast (Minimum) | AA | 4.5:1 for normal text, 3:1 for large text (18px+ or 14px+ bold) |
| 1.4.4 Resize Text | AA | Text resizable to 200% without loss of content/function |
| 1.4.10 Reflow | AA | Content reflows at 320px width (400% zoom) — no horizontal scroll |
| 1.4.11 Non-text Contrast | AA | 3:1 for UI components and graphical objects |
| 1.4.12 Text Spacing | AA | Content works with increased line-height (1.5x), letter/word spacing |
| 1.4.13 Content on Hover/Focus | AA | Hover/focus content dismissable, hoverable, persistent |

#### Operable
Users must be able to operate the interface.

| Criterion | Level | What It Means |
|-----------|-------|--------------|
| 2.1.1 Keyboard | A | All functionality operable via keyboard |
| 2.1.2 No Keyboard Trap | A | Focus can always be moved away from any component |
| 2.4.3 Focus Order | A | Meaningful, logical focus sequence |
| 2.4.4 Link Purpose | A | Link text (or context) describes the destination |
| 2.4.6 Headings and Labels | AA | Headings and labels describe topic/purpose |
| 2.4.7 Focus Visible | AA | Keyboard focus indicator is clearly visible |
| 2.4.11 Focus Not Obscured (Minimum) | AA | **NEW in 2.2** — Focused element not entirely hidden by sticky headers/modals |
| 2.4.12 Focus Not Obscured (Enhanced) | AAA | **NEW in 2.2** — Focused element fully visible |
| 2.4.13 Focus Appearance | AAA | **NEW in 2.2** — Focus indicator meets size and contrast requirements |
| 2.5.7 Dragging Movements | AA | **NEW in 2.2** — Drag operations have single-pointer alternative |
| 2.5.8 Target Size (Minimum) | AA | **NEW in 2.2** — Interactive targets minimum 24x24px (with exceptions) |

#### Understandable
Content must be understandable.

| Criterion | Level | What It Means |
|-----------|-------|--------------|
| 3.1.1 Language of Page | A | `<html lang="en">` |
| 3.1.2 Language of Parts | AA | `lang` attribute on content in different language |
| 3.2.1 On Focus | A | No unexpected context changes on focus |
| 3.2.2 On Input | A | No unexpected changes when interacting with form controls |
| 3.3.1 Error Identification | A | Errors identified and described in text |
| 3.3.2 Labels or Instructions | A | Labels or instructions for user input |
| 3.3.3 Error Suggestion | AA | Suggest corrections for input errors |
| 3.3.7 Redundant Entry | A | **NEW in 2.2** — Don't ask users to re-enter previously provided info |
| 3.3.8 Accessible Authentication (Minimum) | AA | **NEW in 2.2** — No cognitive function test for auth (allow paste, password managers) |
| 3.3.9 Accessible Authentication (Enhanced) | AAA | **NEW in 2.2** — No cognitive test at all for auth |

#### Robust
Content must be robust enough for assistive technologies.

| Criterion | Level | What It Means |
|-----------|-------|--------------|
| 4.1.2 Name, Role, Value | A | Components have accessible name, role, state (ARIA or native HTML) |
| 4.1.3 Status Messages | AA | Status messages announced without focus change (aria-live) |

### Most Commonly Failed Criteria
Based on WebAIM Million survey:
1. **Low contrast text** (86% of pages)
2. **Missing alt text** (54%)
3. **Missing form labels** (48%)
4. **Empty links** (44%)
5. **Missing document language** (28%)
6. **Empty buttons** (26%)

---

## 2. WCAG 3.0 Status

### Where It Stands
- Working Draft stage (latest: September 4, 2025) — **NOT ready for adoption**
- **NOT a W3C Recommendation** — must not be used for compliance purposes yet
- Major conceptual shift from WCAG 2.x

### Expected Timeline
- **Q4 2027**: Candidate Recommendation anticipated
- **2028**: Last major draft for comments
- **Late 2029**: Final W3C Recommendation target

### Key Changes Coming
- **APCA** (Accessible Perceptual Contrast Algorithm): Replaces simple contrast ratios with perceptual model
  - Reports contrast as **Lc (Lightness Contrast)** values from 0 to ~105+
  - Lc 90 preferred for body text, Lc 75 minimum, Lc 60 for large/bold text
  - Font size and weight factored into contrast calculation
  - Handles dark mode natively (accounts for polarity)
- **Outcomes replace success criteria**: 174 outcomes (plain-language desired results) replace binary pass/fail
- **Scoring system**: Bronze/Silver/Gold instead of A/AA/AAA. Graduated scale 0-4 per outcome.
- **12 Functional Categories** replace POUR principles — includes new categories like User Protection (dark patterns, algorithmic fairness) and Cognitive Accessibility
- **Broader scope**: Covers XR (AR/VR/MR), voice assistants, cognitive disabilities

### What to Do Now
- **Build to WCAG 2.2 AA** — it's the current standard
- **Watch APCA** — it's the candidate contrast method for WCAG 3.0
- Don't wait for WCAG 3.0 to start accessibility work

---

## 3. ARIA Patterns

### First Rule of ARIA
**Don't use ARIA if native HTML can do the job.**
```html
<!-- BAD -->
<div role="button" tabindex="0" onclick="..." onkeydown="...">Click</div>

<!-- GOOD -->
<button onclick="...">Click</button>
```
Native HTML elements have built-in keyboard handling, focus management, and screen reader support.

### Essential ARIA Attributes

**Labeling:**
```html
<!-- aria-label: labels an element directly -->
<button aria-label="Close dialog"><svg>...</svg></button>

<!-- aria-labelledby: references another element's text -->
<h2 id="section-title">Settings</h2>
<div role="region" aria-labelledby="section-title">...</div>

<!-- aria-describedby: additional description -->
<input type="password" aria-describedby="pw-hint" />
<p id="pw-hint">Must be at least 8 characters</p>
```

**States:**
```html
<button aria-expanded="false" aria-controls="menu">Menu</button>
<ul id="menu" hidden>...</ul>

<input type="checkbox" aria-checked="true" />
<button aria-pressed="true">Bold</button>
<div aria-busy="true">Loading...</div>
<input aria-invalid="true" aria-errormessage="email-error" />
```

**Live Regions:**
```html
<!-- polite: announced when user is idle -->
<div aria-live="polite" aria-atomic="true">
  3 items in cart
</div>

<!-- assertive: announced immediately (interrupts) -->
<div role="alert">Error: Payment failed</div>
<!-- role="alert" implies aria-live="assertive" -->

<!-- status: polite live region for status updates -->
<div role="status">Saving...</div>
```

### Landmark Roles
```html
<header>   <!-- role="banner" -->
<nav>      <!-- role="navigation" -->
<main>     <!-- role="main" -->
<aside>    <!-- role="complementary" -->
<footer>   <!-- role="contentinfo" -->
<section aria-labelledby="title"> <!-- role="region" when labeled -->
<form aria-labelledby="form-title"> <!-- role="form" when labeled -->
<search>   <!-- role="search" (HTML5.2) -->
```
- Screen reader users navigate by landmarks
- Every page should have `main`, most should have `banner`, `navigation`, `contentinfo`
- Label multiple navs: `<nav aria-label="Primary">`, `<nav aria-label="Footer">`

---

## 4. Keyboard Navigation

### Focus Management Fundamentals

**Focus order must be logical:**
- Match visual reading order (don't use `tabindex > 0`)
- `tabindex="0"`: Element is focusable in natural tab order
- `tabindex="-1"`: Programmatically focusable but not in tab order
- **Never use `tabindex > 0`** — breaks natural order

**Focus indicators:**
```css
/* Custom focus indicator — visible on all backgrounds */
:focus-visible {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}

/* Remove default only if replacing */
button:focus-visible {
  outline: 2px solid #2563eb;
  outline-offset: 2px;
  box-shadow: 0 0 0 4px rgba(37, 99, 235, 0.2);
}

/* NEVER do this without replacement */
/* :focus { outline: none; } ← ACCESSIBILITY VIOLATION */
```

### Focus Trapping for Modals
```typescript
function trapFocus(dialog: HTMLElement) {
  const focusable = dialog.querySelectorAll(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
  )
  const first = focusable[0] as HTMLElement
  const last = focusable[focusable.length - 1] as HTMLElement

  dialog.addEventListener('keydown', (e) => {
    if (e.key !== 'Tab') return

    if (e.shiftKey) {
      if (document.activeElement === first) {
        last.focus()
        e.preventDefault()
      }
    } else {
      if (document.activeElement === last) {
        first.focus()
        e.preventDefault()
      }
    }
  })

  first.focus()
}
```
- Use `<dialog>` element — handles focus trap natively
- Or use headless component libraries (Radix, React Aria) — built-in focus management

### The `inert` Attribute
```html
<!-- Disable interaction for everything behind a modal -->
<main inert>
  <!-- Content behind modal — not focusable, not interactive -->
</main>
<dialog open>
  <!-- Modal content — fully interactive -->
</dialog>
```
- `inert` makes entire subtree non-interactive and invisible to assistive tech
- Better than manually managing `aria-hidden` and `tabindex="-1"` on background

### Roving Tabindex Pattern
```typescript
// For toolbar, tab list, radio group — single tab stop, arrow key navigation
function rovingTabindex(container: HTMLElement, items: HTMLElement[]) {
  let current = 0

  items[0].tabIndex = 0  // First item focusable
  items.slice(1).forEach(item => item.tabIndex = -1)

  container.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
      items[current].tabIndex = -1
      current = (current + 1) % items.length
      items[current].tabIndex = 0
      items[current].focus()
    }
    if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
      items[current].tabIndex = -1
      current = (current - 1 + items.length) % items.length
      items[current].tabIndex = 0
      items[current].focus()
    }
  })
}
```
- Tab key enters/exits the group, arrow keys move within
- Used by: tabs, toolbars, menus, radio groups, tree views

### Skip Navigation
```html
<body>
  <a href="#main-content" class="skip-link">Skip to main content</a>
  <nav><!-- long navigation --></nav>
  <main id="main-content">
    <!-- main content -->
  </main>
</body>
```
```css
.skip-link {
  position: absolute;
  top: -100%;
  left: 0;
  z-index: 100;
}
.skip-link:focus {
  top: 0;
  background: var(--color-primary);
  color: white;
  padding: 0.5rem 1rem;
}
```

---

## 5. Screen Reader Testing

### Primary Screen Readers

| Screen Reader | Platform | Browser | Market Share |
|--------------|----------|---------|-------------|
| **NVDA** | Windows | Firefox/Chrome | ~30% |
| **JAWS** | Windows | Chrome | ~40% |
| **VoiceOver** | macOS/iOS | Safari | ~20% |
| **TalkBack** | Android | Chrome | ~10% |
| **Narrator** | Windows | Edge | ~5% |

### Minimum Testing Matrix
- **Desktop**: NVDA + Firefox, VoiceOver + Safari
- **Mobile**: VoiceOver + Safari (iOS), TalkBack + Chrome (Android)
- JAWS if enterprise/corporate audience

### Common Screen Reader Quirks
- **NVDA/JAWS** may announce `role="button"` differently than native `<button>`
- **VoiceOver** on macOS has different navigation than iOS VoiceOver
- `aria-live` behavior varies: some readers delay, some interrupt
- **Table navigation**: Screen readers use special table mode — broken tables = broken navigation
- Image `alt=""` (empty) is correctly hidden, but `alt` omitted entirely is announced as filename
- `display: none` and `hidden` attribute hide from screen readers (correct)
- `visibility: hidden` hides from screen readers (correct)
- `opacity: 0` does NOT hide from screen readers (still announced)

### VoiceOver Quick Testing
```
Enable: Cmd+F5 (macOS) or Settings → Accessibility → VoiceOver (iOS)
Navigate: VO+Right Arrow (next element)
Rotor: VO+U (landmarks, headings, links, forms)
Read all: VO+A
```

### Screen Reader Accessible Hiding
```css
/* Visually hidden but accessible to screen readers */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}

/* Not this — removes from accessibility tree too */
.hidden { display: none; }
```

---

## 6. Color and Contrast

### WCAG 2.2 Contrast Requirements

| Content Type | Minimum Ratio (AA) | Enhanced (AAA) |
|-------------|-------------------|----------------|
| Normal text (< 18px) | 4.5:1 | 7:1 |
| Large text (≥ 18px or ≥ 14px bold) | 3:1 | 4.5:1 |
| UI components (borders, icons) | 3:1 | — |
| Graphical objects | 3:1 | — |
| Focus indicators | 3:1 against adjacent color | — |

### APCA (Advanced Perceptual Contrast Algorithm)
- Accounts for font size, weight, and polarity (light/dark mode)
- More accurate than simple ratio — allows more design flexibility for large/bold text
- Stricter for small/thin text on dark backgrounds
- **Not yet a WCAG requirement** — but recommended for modern design systems
- Tool: `apca-w3` npm package, Polypane browser

### Color Blindness Considerations
```
~8% of males, ~0.5% of females have some form of color vision deficiency

Types:
- Deuteranopia/Deuteranomaly (red-green, most common)
- Protanopia/Protanomaly (red-green)
- Tritanopia/Tritanomaly (blue-yellow, rare)
- Achromatopsia (total color blindness, very rare)
```

**Design rules:**
- Never use color as the **only** indicator (add icons, patterns, text)
- Red/green distinction is especially problematic (use red/blue or add icons)
- Test with simulation tools: Chrome DevTools → Rendering → Emulate vision deficiency

### Dark Mode Contrast
- Dark backgrounds require different contrast considerations
- Avoid pure white (#fff) text on pure black (#000) — too harsh, causes halation
- Recommended: off-white (#f0f0f0) on dark gray (#1a1a1a)
- Test contrast for BOTH light and dark themes

### Tools
- **WebAIM Contrast Checker**: Quick ratio check
- **Chrome DevTools**: Inspect element → color picker shows contrast ratio
- **Polypane**: Multi-viewport browser with contrast checking
- **Stark**: Figma/Sketch plugin for contrast checking in design
- **axe DevTools**: Browser extension with contrast analysis

---

## 7. Motion and Animation

### `prefers-reduced-motion`
```css
/* Respect user preference */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}

/* Or opt-in to motion instead of opt-out */
.animated {
  /* No animation by default */
  transition: none;
}
@media (prefers-reduced-motion: no-preference) {
  .animated {
    transition: transform 0.3s ease;
  }
}
```

### Motion Guidelines
- **Essential motion** (conveys information): Reduce but don't remove. Use fade/opacity instead of movement.
- **Decorative motion** (aesthetic only): Disable entirely for `prefers-reduced-motion`.
- **Auto-playing content**: Provide pause/stop control. Never auto-play video with sound.
- **Parallax scrolling**: Disable for reduced motion. Can cause vestibular disorders.
- **Flashing content**: Never flash more than 3 times per second (seizure risk — WCAG 2.3.1 Level A).

### Scroll-Driven Animations Accessibility
```css
@media (prefers-reduced-motion: no-preference) {
  .reveal { animation: fade-in linear; animation-timeline: view(); }
}
@media (prefers-reduced-motion: reduce) {
  .reveal { opacity: 1; } /* Static, fully visible */
}
```

---

## 8. Forms Accessibility

### Essential Form Patterns

**Labels (every input MUST have one):**
```html
<!-- Explicit label (preferred) -->
<label for="email">Email address</label>
<input id="email" type="email" autocomplete="email" />

<!-- Implicit label -->
<label>Email address <input type="email" /></label>

<!-- aria-label for icon-only inputs -->
<input type="search" aria-label="Search products" />

<!-- aria-labelledby for complex labels -->
<span id="name-label">Full name</span>
<span id="name-hint">(as it appears on your ID)</span>
<input aria-labelledby="name-label name-hint" />
```

**Error Messages:**
```html
<label for="email">Email</label>
<input id="email" type="email"
  aria-invalid="true"
  aria-describedby="email-error"
  aria-errormessage="email-error" />
<p id="email-error" role="alert">
  Please enter a valid email address
</p>
```
- Link error to input with `aria-describedby` or `aria-errormessage`
- Use `aria-invalid="true"` to indicate error state
- Announce errors with `role="alert"` or `aria-live`
- **Don't only show errors on blur** — screen reader users might miss them

**Fieldset and Legend (group related inputs):**
```html
<fieldset>
  <legend>Shipping address</legend>
  <label for="street">Street</label>
  <input id="street" />
  <label for="city">City</label>
  <input id="city" />
</fieldset>
```

**Autocomplete (WCAG 1.3.5 — identify input purpose):**
```html
<input type="text" autocomplete="given-name" />
<input type="text" autocomplete="family-name" />
<input type="email" autocomplete="email" />
<input type="tel" autocomplete="tel" />
<input type="text" autocomplete="street-address" />
<input type="password" autocomplete="new-password" />
```
- Helps password managers, auto-fill, and assistive tech
- Required by WCAG 2.2 for personal information inputs

**Required Fields:**
```html
<!-- Both visual and programmatic indication -->
<label for="name">Name <span aria-hidden="true">*</span></label>
<input id="name" required aria-required="true" />
```

---

## 9. Automated Testing Tools

### Testing Pyramid for Accessibility

```
           /\
          /  \  Manual testing with screen readers
         /    \  (catches 40-60% of issues automated tools miss)
        /------\
       /        \ Component-level axe checks (Storybook, jest-axe)
      /          \ (catches ~30-40% of issues)
     /------------\
    /              \ Linting (eslint-plugin-jsx-a11y)
   /                \ (catches ~10-15% of issues)
  /------------------\
```

**Automated tools catch ~30% of accessibility issues.** Manual testing with assistive tech is essential.

### axe-core (Engine)
- Industry-standard accessibility testing engine
- Zero false positives by design
- Integrations: Playwright, Cypress, Jest, Storybook, Chrome DevTools

### Tool Comparison

| Tool | Type | Best For |
|------|------|---------|
| **axe DevTools** (browser extension) | Manual | Quick page audits during development |
| **Lighthouse a11y** | Automated (CI) | CI/CD gates, powered by axe |
| **Pa11y** | CLI/CI | Batch testing, CI pipelines |
| **WAVE** (browser extension) | Manual | Visual error overlay on page |
| **jest-axe** | Unit test | Component-level testing |
| **@axe-core/playwright** | E2E test | Page-level testing in CI |
| **Storybook a11y addon** | Development | Per-story checks during component dev |
| **eslint-plugin-jsx-a11y** | Linting | Catch issues at code-write time (React) |
| **eslint-plugin-vuejs-accessibility** | Linting | Catch issues at code-write time (Vue) |

### Integration Examples

**jest-axe (component testing):**
```typescript
import { axe, toHaveNoViolations } from 'jest-axe'
expect.extend(toHaveNoViolations)

test('Button has no a11y violations', async () => {
  const { container } = render(<Button>Click me</Button>)
  const results = await axe(container)
  expect(results).toHaveNoViolations()
})
```

**Playwright (E2E testing):**
```typescript
import AxeBuilder from '@axe-core/playwright'

test('page has no a11y violations', async ({ page }) => {
  await page.goto('/dashboard')
  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa', 'wcag22aa'])
    .analyze()
  expect(results.violations).toEqual([])
})
```

**Storybook a11y addon:**
```typescript
// .storybook/preview.ts
import { withA11y } from '@storybook/addon-a11y'
export const decorators = [withA11y]

// Runs axe on every story automatically
// Shows pass/fail in Storybook panel
```

---

## 10. Accessible Component Patterns

### Dialog / Modal
```html
<dialog id="my-dialog" aria-labelledby="dialog-title">
  <h2 id="dialog-title">Confirm Action</h2>
  <p>Are you sure you want to delete this item?</p>
  <button autofocus>Cancel</button>
  <button>Delete</button>
</dialog>
```
Requirements:
- Focus moves to dialog on open (first focusable element or dialog itself)
- Focus trapped within dialog
- Escape key closes dialog
- Focus returns to trigger element on close
- Background content is `inert`
- `aria-labelledby` references dialog title

### Tabs
```html
<div role="tablist" aria-label="Settings">
  <button role="tab" id="tab-1" aria-selected="true" aria-controls="panel-1">General</button>
  <button role="tab" id="tab-2" aria-selected="false" aria-controls="panel-2" tabindex="-1">Security</button>
</div>
<div role="tabpanel" id="panel-1" aria-labelledby="tab-1">...</div>
<div role="tabpanel" id="panel-2" aria-labelledby="tab-2" hidden>...</div>
```
Requirements:
- Arrow keys move between tabs (roving tabindex)
- Tab key moves focus into the panel
- `aria-selected` indicates current tab
- `aria-controls` links tab to panel
- Only active panel is visible

### Accordion
```html
<h3>
  <button aria-expanded="false" aria-controls="section-1">
    What is your return policy?
  </button>
</h3>
<div id="section-1" role="region" aria-labelledby="..." hidden>
  <p>You can return items within 30 days...</p>
</div>
```
Requirements:
- `aria-expanded` toggles with open/close
- Enter/Space activates the trigger
- Content region is `hidden` when collapsed

### Combobox / Autocomplete
```html
<label for="search">Search</label>
<input id="search" role="combobox"
  aria-expanded="false"
  aria-autocomplete="list"
  aria-controls="search-listbox"
  aria-activedescendant="" />
<ul id="search-listbox" role="listbox" hidden>
  <li role="option" id="opt-1">Result 1</li>
  <li role="option" id="opt-2">Result 2</li>
</ul>
```
Requirements:
- Arrow keys navigate options
- `aria-activedescendant` points to highlighted option
- Enter selects, Escape closes
- Type-ahead supported
- **Most complex pattern** — strongly recommend using headless library

### Toast / Notification
```html
<div role="status" aria-live="polite" aria-atomic="true">
  <!-- Inject toast content here dynamically -->
  Settings saved successfully.
</div>
```
Requirements:
- `aria-live="polite"` for non-urgent (success, info)
- `role="alert"` (`aria-live="assertive"`) for urgent (errors)
- Auto-dismiss should pause on hover and focus
- Provide dismiss button
- Don't stack too many (max 3-5)

### Data Tables
```html
<table>
  <caption>Quarterly Revenue</caption>
  <thead>
    <tr>
      <th scope="col">Quarter</th>
      <th scope="col">Revenue</th>
      <th scope="col">Growth</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row">Q1 2025</th>
      <td>$1.2M</td>
      <td>+15%</td>
    </tr>
  </tbody>
</table>
```
Requirements:
- `<caption>` describes the table
- `scope="col"` / `scope="row"` for headers
- Don't use tables for layout
- For complex tables: `headers` attribute linking cells to multiple headers

---

## 11. Legal Landscape

### Key Legislation

| Law | Region | Scope | Standard |
|-----|--------|-------|----------|
| **ADA** (Americans with Disabilities Act) | USA | Public accommodations (broadly interpreted to include websites) | WCAG 2.1 AA (common standard in settlements) |
| **Section 508** | USA | Federal agencies and contractors | WCAG 2.0 AA (revised 2018) |
| **EAA** (European Accessibility Act) | EU | Products and services (including websites, apps, e-commerce) | EN 301 549 (maps to WCAG 2.1 AA) |
| **AODA** | Ontario, Canada | Public and large private orgs | WCAG 2.0 AA |
| **Equality Act** | UK | Service providers | WCAG 2.1 AA (PSBAR compliance) |

### EAA (European Accessibility Act) — Now Active
- **June 28, 2025**: Enforcement began across all EU member states
- Covers: websites, mobile apps, e-commerce, banking, transport, e-books, telecommunications
- References **EN 301 549** (aligned with WCAG 2.1 AA)
- Applies to private sector (not just government)
- **Penalties vary by member state**: administrative fines EUR 5,000 to EUR 100,000 typically; up to **EUR 3 million** in some jurisdictions; product/service removal from market possible
- Micro-enterprises (<10 employees, <EUR 2M turnover) have partial exemptions

### US Litigation Trends (2025)
- **5,000+ ADA digital accessibility lawsuits** filed in 2025 (~20% increase over 2024)
- E-commerce is the top target: **69%** of all digital accessibility lawsuits
- **45-46%** of federal cases targeted companies already sued before (repeat litigation)
- **Overlay widgets are not a defense**: 1,000+ businesses sued despite having accessibility widgets/overlays
- Top states: New York (31.6%), Florida (24.2%), California (18.9%)
- **Settlements typically require**: WCAG 2.1 AA conformance, ongoing monitoring, remediation timeline

### Best Practices for Compliance
1. **Set WCAG 2.2 AA as your standard** — covers most legal requirements globally
2. **Document your accessibility efforts** — VPAT/ACR (Voluntary Product Accessibility Template)
3. **Publish an accessibility statement** — acknowledge commitment, provide contact
4. **Conduct regular audits** — annual third-party audit + continuous automated testing
5. **Train your team** — designers and developers need accessibility knowledge

---

## 12. Framework Accessibility

### Accessible Component Libraries (Comparison)

| Library | Framework | Components | A11y Quality | Philosophy |
|---------|-----------|-----------|-------------|------------|
| **React Aria** (Adobe) | React | 40+ | Best-in-class | Hooks + components, i18n, maximum compliance |
| **Radix UI** | React | 30+ | Excellent | Unstyled primitives, composable |
| **Headless UI** | React, Vue | 10+ | Very good | Simpler API, Tailwind Labs |
| **Bits UI** | Svelte | 30+ | Very good | Radix philosophy for Svelte |
| **Radix Vue** | Vue | 30+ | Very good | Radix port for Vue |
| **Angular CDK** | Angular | Foundation | Excellent | Low-level a11y utilities |
| **Melt UI** | Svelte | Builder pattern | Good | Maximum flexibility |

### React Accessibility
- **React Aria**: Most comprehensive a11y solution — hooks for every ARIA pattern
- `eslint-plugin-jsx-a11y`: Linting for common mistakes
- Focus management: `useRef` + `focus()`, or React Aria's `FocusScope`
- Route change announcements: Needs explicit implementation (not built into React Router)

### Angular Accessibility
- **Angular CDK a11y module**: `FocusTrap`, `FocusMonitor`, `LiveAnnouncer`, `AriaDescriber`
- `@angular/cdk/a11y`: Built-in focus management utilities
- `LiveAnnouncer`: Programmatic screen reader announcements
- `FocusTrap`: Built-in focus trapping for dialogs
- Route change: `TitleStrategy` + `LiveAnnouncer` for route announcements

### Vue Accessibility
- **Radix Vue**: Accessible headless primitives
- `eslint-plugin-vuejs-accessibility`: Linting for Vue templates
- `vue-announcer`: Route change announcements for screen readers
- Nuxt: `useHead()` for accessible page titles per route

### Svelte Accessibility
- **Bits UI**: Accessible headless components
- Svelte compiler warns about missing alt text and other a11y issues at build time
- SvelteKit: `afterNavigate()` for route change announcements

---

## 13. Cognitive Accessibility

### COGA (Cognitive and Learning Disabilities) Guidelines
W3C's Cognitive and Learning Disabilities Accessibility Task Force recommends:

- **Plain language**: Write at 8th-grade reading level or below
- **Consistent navigation**: Same location, same order across pages
- **Clear labels**: Use common, recognizable words (not jargon)
- **Error prevention**: Confirm destructive actions, undo support
- **Timeout warnings**: Warn before timeout, allow extension
- **Step indicators**: Show progress in multi-step flows (1 of 3)
- **Familiar patterns**: Don't reinvent standard UI patterns

### Readability
- Short sentences (< 25 words)
- Short paragraphs (2-3 sentences)
- Active voice over passive
- One idea per paragraph
- Use headings to break content
- Bulleted lists for scannability

### Cognitive Load Reduction
- Progressive disclosure — show only what's needed
- Sensible defaults — pre-fill when possible (WCAG 3.3.7)
- Remove unnecessary fields from forms
- Chunk information into digestible pieces
- Visual hierarchy guides attention

---

## Accessibility Audit Checklist

### Quick Audit (15 minutes)
- [ ] Page has `<html lang="...">`
- [ ] All images have meaningful `alt` (or empty `alt=""` for decorative)
- [ ] All form inputs have visible labels
- [ ] Color contrast meets 4.5:1 for text
- [ ] Tab through entire page — logical order, visible focus, no traps
- [ ] Page has heading hierarchy (h1 → h2 → h3, no skips)
- [ ] Interactive elements have accessible names
- [ ] No content relies solely on color to convey meaning

### Deep Audit (2-4 hours)
- [ ] All quick audit items
- [ ] Screen reader testing (VoiceOver + NVDA minimum)
- [ ] Keyboard testing for all interactive components
- [ ] Zoom to 400% — content reflows without horizontal scroll
- [ ] Test with text spacing overrides (WCAG 1.4.12)
- [ ] Dynamic content announced via aria-live regions
- [ ] Error handling: errors identified, described, and linked to inputs
- [ ] Focus management in modals (trapped, restored on close)
- [ ] Route changes announced to screen readers
- [ ] Automated scan with axe DevTools (zero critical/serious)
- [ ] Touch targets ≥ 24x24px (44x44px recommended)
- [ ] prefers-reduced-motion honored
- [ ] prefers-color-scheme respected (dark mode contrast)
