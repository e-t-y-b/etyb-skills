# User Documentation Specialist — Deep Reference

**Always use `WebSearch` to verify current platform versions, framework features, and tooling updates before giving user documentation advice. Documentation platforms ship major updates frequently. Last verified: April 2026.**

## Table of Contents
1. [Information Architecture — Diataxis Framework](#1-information-architecture--diataxis-framework)
2. [Documentation Platform Selection](#2-documentation-platform-selection)
3. [Documentation-as-Code Workflows](#3-documentation-as-code-workflows)
4. [Quickstart and Onboarding Documentation](#4-quickstart-and-onboarding-documentation)
5. [Content Style Guides](#5-content-style-guides)
6. [Prose Linting with Vale](#6-prose-linting-with-vale)
7. [Knowledge Base and Help Center](#7-knowledge-base-and-help-center)
8. [Documentation Accessibility](#8-documentation-accessibility)
9. [Visual Aids in Documentation](#9-visual-aids-in-documentation)
10. [AI-Assisted Documentation](#10-ai-assisted-documentation)
11. [Documentation Metrics and Analytics](#11-documentation-metrics-and-analytics)
12. [Multi-Version Documentation](#12-multi-version-documentation)
13. [Localization and i18n](#13-localization-and-i18n)
14. [Content Reuse and Single-Sourcing](#14-content-reuse-and-single-sourcing)

---

## 1. Information Architecture — Diataxis Framework

### The Four Quadrants

The Diataxis framework (by Daniele Procida) organizes documentation along two axes: **practical vs. theoretical** and **acquisition vs. application**. This produces four distinct content types:

| Type | Orientation | Reader's Goal | Key Rule |
|------|-------------|---------------|----------|
| **Tutorials** | Learning-oriented | "I want to learn" | Hand-held, always works, focused on learning not accomplishment |
| **How-to Guides** | Task-oriented | "I need to do X" | Step-by-step to solve a specific problem; assumes existing knowledge |
| **Reference** | Information-oriented | "I need to look up Y" | Dry, accurate, complete descriptions (API specs, config options) |
| **Explanation** | Understanding-oriented | "I want to understand why" | Background, context, architecture decisions, design rationale |

### Why Diataxis Matters

The key insight: **mixing content types confuses users.** A tutorial that stops to explain theory loses the learner. A reference page with lengthy preambles frustrates the engineer scanning for a parameter name. Keeping types separate makes every page better.

Adopted by: Django, Canonical (Ubuntu), Gatsby, Cloudflare, and many more.

### Applying Diataxis in Practice

```
1. Audit existing docs: classify each page as tutorial, how-to, reference, or explanation
2. Identify mixed content: pages that try to be two things at once
3. Split mixed content into separate pages linked together
4. Organize navigation around the four types:
   - Getting Started → Tutorials
   - Guides → How-to Guides
   - API / Config Reference → Reference
   - Concepts / Architecture → Explanation
5. Write new content with the type clearly in mind from the start
```

### Practical Navigation Patterns

- Left sidebar for hierarchical navigation (sections > pages)
- Top tabs for major content categories (Docs / API / Guides / Blog)
- Breadcrumbs for orientation within hierarchy
- "On this page" right sidebar for in-page table of contents
- Search as the primary discovery mechanism

---

## 2. Documentation Platform Selection

### Platform Comparison

| Platform | Approach | Best For | Pricing |
|----------|----------|----------|---------|
| **Docusaurus v3** (Meta) | React SSG, full control | Maximum flexibility at zero cost; React teams | Free (open-source) |
| **MkDocs Material** | Python-based, Markdown-pure | Python ecosystem; open-source projects; GitHub Pages | Free (open-source) |
| **Mintlify** | Git-native MDX, AI-first | Fast, polished docs with AI search; API startups | Free tier; Pro ~$300/month |
| **GitBook** | Block editor, AI agent | Mixed teams; internal wikis + docs | $65/site + $12/user/month |
| **Fumadocs** | Next.js headless components | Next.js teams wanting deep framework integration | Free (open-source) |
| **Starlight** (Astro) | Astro-based, framework-agnostic | Best performance; framework-agnostic teams | Free (open-source) |
| **Nextra v4** | Next.js App Router, opinionated | Quick setup for Next.js teams | Free (open-source) |
| **VitePress** | Vue/Vite-based | Vue.js ecosystem teams | Free (open-source) |
| **Markdoc** (Stripe) | Markdown + custom tags, build-time validation | Stripe-quality docs with validation guarantees | Free (open-source) |
| **ReadMe** | Visual editor + interactive API | API-first companies needing interactive API docs | $79/month; Enterprise $3,000+ |
| **Redocly** | OpenAPI-first, CLI tools | Teams with complex OpenAPI specs | Free core; paid ~$99/month |

### Selection Framework

```
1. What's the team's framework?
   - React → Docusaurus or Fumadocs
   - Next.js → Fumadocs or Nextra
   - Vue.js → VitePress
   - Python → MkDocs Material
   - Framework-agnostic → Starlight (Astro)

2. Budget and ops preferences?
   - Zero budget, self-hosted → Docusaurus, MkDocs, Starlight
   - Managed platform → Mintlify or GitBook
   - Enterprise needs → ReadMe or Redocly

3. Who writes the docs?
   - Engineers only → Docusaurus, MkDocs (docs-as-code)
   - Mixed technical/non-technical → GitBook (WYSIWYG)
   - API-focused → ReadMe or Mintlify

4. Key feature needs?
   - Built-in AI search → Mintlify or GitBook
   - Interactive API reference → ReadMe or Mintlify
   - Multi-version docs → Docusaurus (built-in)
   - Maximum performance → Starlight
   - Build-time validation → Markdoc
```

### Key 2025-2026 Trends

- **Astro/Starlight** ranked #1 in satisfaction/interest in 2025 State of JS
- **Fumadocs** growing 3x year-over-year (150K+ npm downloads/month, 10,300+ GitHub stars)
- **Docusaurus 3.9** added full DocSearch v4 with Algolia Ask AI
- Nearly half of doc traffic now comes from AI agents — structure matters more than ever

---

## 3. Documentation-as-Code Workflows

### Core Stack

- **Format**: Markdown for simplicity; MDX for interactive components (JSX, tabs, API playgrounds)
- **Version Control**: Git-based; docs in `docs/` folder or dedicated docs repo
- **Build**: Static site generators (Docusaurus, MkDocs, Starlight, etc.)
- **Deploy**: GitHub Pages, Netlify, Vercel, Cloudflare Pages (auto-deploy on merge)
- **Preview**: Every PR gets a preview URL (Netlify Deploy Previews, Vercel Previews)

### CI/CD Pipeline for Docs

```yaml
# Example GitHub Actions workflow
on:
  push:
    branches: [main]
    paths: ['docs/**']
  pull_request:
    paths: ['docs/**']

jobs:
  docs-quality:
    steps:
      - name: Lint prose (Vale)
      - name: Check Markdown formatting (markdownlint)
      - name: Verify links (markdown-link-check)
      - name: Spell check (cspell)
      - name: Build docs site
      - name: Deploy preview (on PR) / Deploy production (on main)
```

### Best Practice

Docs ship with every code release through the same CI/CD pipeline. PR-based review ensures documentation quality. Automated checks prevent formatting errors, broken links, and style violations from reaching production.

---

## 4. Quickstart and Onboarding Documentation

### Quickstart Guide Structure (Target: first success in under 5 minutes)

1. **One sentence**: what this product/API does
2. **Prerequisites**: runtime, accounts, API keys (keep minimal)
3. **Installation**: single copy-pasteable command
4. **Minimal working example**: < 10 lines, produces visible result
5. **Expected output**: show what success looks like
6. **"What's next"**: links to common use cases and deeper docs

### Tutorial Best Practices (Diataxis tutorial type)

- The reader should succeed every time — if a tutorial can fail, it's a bad tutorial
- Focus on learning, not accomplishment — the project being built is a vehicle for learning
- Provide the minimum necessary explanation — link to explanation pages for deeper context
- Be explicit about every step — don't assume knowledge; show exact commands and expected output
- Test the tutorial with someone unfamiliar with the product before publishing

### Interactive Onboarding

- 93% of marketers say interactive content outperforms static content
- Users spend 13 minutes with interactive content vs. 8.5 minutes with static
- Tools: **Scribe** (auto-generates step-by-step guides with screenshots), product tours with tooltips/modals
- Onboarding checklists with progress bars motivate completion
- Role-based paths (developer vs admin vs end user) improve relevance

### Key Metrics

- Time to first success / first value (target: < 5 minutes for quickstart)
- Activation rate (% completing onboarding)
- Support ticket volume from new users (should decrease with better onboarding docs)
- Rework rates

---

## 5. Content Style Guides

### Industry Standards

| Guide | Best For | Key Principles |
|-------|----------|----------------|
| **Google Developer Documentation Style Guide** | Developer/API docs | Most comprehensive for technical writing; updated Dec 2025; covers API formatting, code samples, UI terminology |
| **Microsoft Writing Style Guide** | Product documentation | "Write short, simple sentences; use active voice; address the reader as 'you'" |
| **Apple Style Guide** | Apple ecosystem / UI writing | Updated June 2025; UI/UX writing conventions |

### Readability Metrics

| Metric | Target | Notes |
|--------|--------|-------|
| **Flesch Reading Ease** | 60-70 for technical docs | Score 1-100 (100 = most readable) |
| **Flesch-Kincaid Grade Level** | Grades 7-9 (general), 9-12 (technical) | API reference can be 10-14 due to domain specificity |
| **Hemingway Editor** | Grade 9 or below for guides | Color-coded highlighting; "Technical" mode with higher tolerance |

### Writing Rules for Technical Documentation

1. **Use active voice**: "The API returns a JSON response" not "A JSON response is returned by the API"
2. **Address the reader as "you"**: "You can configure..." not "Users can configure..."
3. **Use present tense**: "The function returns..." not "The function will return..."
4. **One idea per sentence**: break long sentences into shorter ones
5. **Lead with the action**: "Run `npm install`" not "To install dependencies, you should run `npm install`"
6. **Be specific**: "Takes 50ms" not "is fast"; "Supports up to 10,000 connections" not "supports many connections"
7. **Use consistent terminology**: pick one term and use it everywhere (don't alternate between "endpoint" and "route" and "path")
8. **Avoid jargon**: if you must use it, define it on first use or link to a glossary

---

## 6. Prose Linting with Vale

Vale is the standard tool for automated style enforcement in documentation CI/CD.

### What Vale Does

- Open-source command-line prose linter
- Syntax-aware: excludes code snippets, avoids false positives
- Supports Markdown, HTML, reStructuredText, AsciiDoc, DITA, XML
- Integrates with VS Code, Git hooks, GitHub Actions, GitLab CI

### Pre-Built Style Packages

| Package | Source |
|---------|--------|
| `Google` | Google Developer Documentation Style Guide |
| `Microsoft` | Microsoft Writing Style Guide |
| `write-good` | Passive voice, weasel words, cliches |
| `proselint` | Best practices from journalism and rhetoric |
| `Joblint` | Inclusive language for job postings |

### Setup

```ini
# .vale.ini
StylesPath = .vale/styles
MinAlertLevel = suggestion

Packages = Google, write-good

[*.md]
BasedOnStyles = Google, write-good
Google.Acronyms = NO  # disable specific rules as needed
```

### CI Integration

Run Vale in GitHub Actions on every PR. Enforce as warnings initially, escalate to errors as the team builds the habit. Used by: Grafana, Datadog, Meilisearch, Spectro Cloud, Contentsquare.

---

## 7. Knowledge Base and Help Center

### Platform Comparison

| Platform | Key Strength | Best For |
|----------|-------------|----------|
| **Zendesk** | AI-powered suggestions, content blocks, deep analytics | Enterprise support teams; full ticketing + KB integration |
| **Help Scout** | Simple, affordable; KB included in free tier | Small-to-mid teams wanting simplicity |
| **Intercom** | Chat-first; articles appear contextually in conversations | Teams already using Intercom for chat |
| **Helpjuice** | Best-in-class search engine | Organizations where findability is top priority |
| **Document360** | Full-featured KB with strong organization | Mid-market; dedicated KB software |

### Article Templates

- **Problem/Solution**: describe the symptom, explain the cause, provide the fix
- **Step-by-Step Procedural**: numbered steps with screenshots
- **FAQ**: expandable sections with question/answer pairs
- **Troubleshooting Decision Tree**: if X → try Y → if still failing → try Z

### Knowledge Base Best Practices

- Structured content with clear headings, tags, and categories for search optimization
- Internal linking between related articles
- Track zero-result searches to identify content gaps
- Feedback mechanism on every article (not just thumbs up/down — include "outdated," "missing info," "hard to understand" categories)
- Regular audit: archive or update articles with low ratings or outdated content

---

## 8. Documentation Accessibility

### WCAG Compliance

WCAG 2.2 (released Oct 2023) is the current standard. **WCAG 2.1 Level AA** is now legally required:
- European Accessibility Act (EAA) in force since June 2025
- US ADA Title II requires WCAG 2.1 Level AA for public entities

### Documentation-Specific Accessibility Checklist

- [ ] **Alt text**: descriptive for informative images; empty (`alt=""`) for decorative images
- [ ] **Heading hierarchy**: semantic (h1 > h2 > h3), never skip levels; one h1 per page
- [ ] **Color contrast**: 4.5:1 for normal text, 3:1 for large text
- [ ] **Don't rely on color alone**: information must be conveyed through text/pattern too (especially code diffs)
- [ ] **Descriptive link text**: "Read the authentication guide" not "click here"
- [ ] **Keyboard navigation**: all interactive elements accessible via keyboard
- [ ] **Code blocks**: readable by screen readers (use semantic HTML, not just styled divs)
- [ ] **Video content**: provide text transcripts or captions
- [ ] **Respect system preferences**: `prefers-reduced-motion`, `prefers-contrast`

### Testing Tools

- **axe DevTools**: browser extension for accessibility audits
- **Lighthouse**: built-in Chrome audit including accessibility
- **WAVE**: web accessibility evaluation tool
- **Screen readers**: NVDA (free, Windows), VoiceOver (macOS/iOS), JAWS (Windows, paid)

---

## 9. Visual Aids in Documentation

### Diagrams-as-Code

**Mermaid** is the standard for text-based diagrams in documentation. Natively supported by GitHub Markdown, Docusaurus, GitBook, Notion, and most doc platforms. Supports 20+ diagram types: flowcharts, sequence diagrams, ER diagrams, Gantt charts, mindmaps, C4.

**D2** (Go-based) is a newer alternative with better layout control for complex diagrams.

### Screenshot and Annotation Tools

| Tool | Platform | Best For |
|------|----------|----------|
| **CleanShot X** | macOS | Screenshots with annotation, OCR, scrolling capture |
| **Scribe** | Cross-platform | AI auto-generates step-by-step guides with annotated screenshots |
| **Loom** | Cross-platform | Screen + camera recordings for video walkthroughs |
| **Tango** | Cross-platform | Workflow capture with detailed screenshots |

### Visual Aid Best Practices

- Text-based diagrams (Mermaid, D2) preferred for version control and collaboration
- Use callouts/admonitions (note, warning, tip, danger) for important information
- Annotate screenshots to highlight relevant UI elements
- Prefer light theme screenshots for documentation (better print compatibility)
- Keep screenshots current — use automated tools (Scribe) where possible
- Include alt text for every image

---

## 10. AI-Assisted Documentation

### AI Search in Docs

| Tool | Approach | Best For |
|------|----------|----------|
| **Algolia DocSearch + Ask AI** | Established search standard; free for open-source; Docusaurus 3.9 integration | General docs search with conversational AI |
| **Kapa.ai** | Indexes 20+ sources (docs, code, PDFs, support tickets); citation-based answers | Companies with knowledge scattered across sources |
| **Inkeep** | AI agents platform; visual builder + TypeScript SDK; connects to multiple data sources | Free for open-source; Starter $200/month |
| **Mendable** | Build AI chat from docs with one line of code | Quick integration |

### Chatbot-in-Docs Pattern

Embedding an AI chatbot in documentation is becoming standard. Implementation options:
- Algolia Ask AI (search bar transforms into conversational assistant)
- Kapa.ai floating widget with citation links
- Inkeep embeddable agent
- Redocly "Ask AI" floating action button
- Custom RAG implementations

### AI Documentation Tools

- **GitBook AI agent**: identifies doc gaps from GitHub issues, support tickets, Slack
- **ReadMe Agent Owlbert AI**: doc linting and style consistency
- **Confluence Rovo AI**: 20+ pre-built agents for summarizing, drafting, extracting action items
- **Hemingway Editor Plus**: AI-powered rewriting for readability

---

## 11. Documentation Metrics and Analytics

### What to Measure

| Category | Metrics | Actionability |
|----------|---------|---------------|
| **Traffic** | Page views, unique visitors, entry/exit pages | Foundational — know what's read |
| **Engagement** | Time on page, scroll depth, doc path depth | More valuable — understand usage depth |
| **Search** | Query frequency, zero-result searches, click-through rate | Most actionable — identify content gaps |
| **Feedback** | Page ratings, written comments, NPS | Qualitative — understand satisfaction |
| **Business impact** | Support ticket deflection, time to first API call, activation rate | Strategic — justify docs investment |

### Analytics Tools

| Tool | Strength | Best For |
|------|----------|----------|
| **Plausible** | Privacy-focused, lightweight, GDPR-compliant | Simple docs analytics without consent banners; $9/month |
| **PostHog** | Open-source product analytics with surveys | Docs analytics integrated with product analytics; free 1M events |
| **Google Analytics (GA4)** | Most comprehensive | Teams already using GA; requires cookie consent |
| **GitBook built-in** | Zero-config page views, feedback, search insights | GitBook users |

### Feedback Widget Best Practices

- Go beyond simple thumbs up/down: add conditional follow-up questions
- Categories: "outdated," "missing information," "hard to understand," "other"
- Place feedback widget at the bottom of every page
- Route feedback into issue tracking (Jira, Linear, GitHub Issues)
- Track and respond to feedback — closing the loop builds trust

---

## 12. Multi-Version Documentation

### Platform Support

| Platform | Versioning Mechanism |
|----------|---------------------|
| **Docusaurus** | Built-in: `docusaurus docs:version`; `/docs` (next), `/versioned_docs/version-X.X` |
| **MkDocs** | mike plugin for versioned docs |
| **GitBook** | Git-style branching and versioning |
| **ReadMe** | Multi-version API docs with version selector |
| **Fumadocs** | Via content collections |

### Versioning Best Practices

- Version feature-specific content, API references, and UI instructions
- Share general concepts, getting started guides, and policies across versions
- Default to latest stable version in navigation; allow version switching
- Define support windows for each documentation version
- Create deprecation notices with migration timelines
- Automated archival for end-of-life versions

### Changelogs

- Use **Keep a Changelog** format (keepachangelog.com)
- Categories: Added, Changed, Deprecated, Removed, Fixed, Security
- Include rationale and impact assessment
- Link changelog entries to relevant documentation pages
- Automate from conventional commits where possible

### Migration Guides

- Creating migration guides increases user satisfaction by 45%
- Structure: breaking changes first, then new features, then deprecations
- Include before/after code examples
- Provide automated migration scripts (codemods) where possible
- Test migration guides with real users before publishing

---

## 13. Localization and i18n

### Translation Management Platforms

| Platform | Strength | Best For |
|----------|----------|----------|
| **Crowdin** | 700+ integrations, AI translation, Translation Memory | Open-source projects; dev teams with many integrations |
| **Transifex** | Continuous localization, over-the-air delivery | SaaS products with frequent releases |
| **Lokalise** | Design-to-dev workflow, Figma integration | Teams needing design localization |
| **Phrase** | Enterprise TMS, strong MT engine integration | Enterprise with complex translation needs |

### Best Practices for Translatable Docs

- Internationalize from day one — retrofitting is expensive
- Use Translation Memory (TM) to avoid re-translating (reduces costs 25-50%)
- Maintain terminology glossaries for consistency
- Use sentence-style capitalization (works better with MT)
- Avoid culturally-specific idioms and humor
- Design UI with text expansion in mind (30-40% more space for some languages)
- Use locale-aware date, number, and currency formatting
- Separate translatable strings from code

### Framework-Level i18n

- **Docusaurus**: built-in i18n supporting 150+ languages; per-locale `baseUrl`/`url` overrides in 3.9
- **GitBook**: AI-powered translations
- **Crowdin + docs-as-code**: syncs with Git repos; translations pushed back as PRs

---

## 14. Content Reuse and Single-Sourcing

### Lightweight Approaches (Docs-as-Code)

**MDX Components**: Reusable components for common patterns (warnings, prerequisites, code blocks). Import shared components across pages. Docusaurus supports `@site/src/components` imports.

**Platform Snippets**:
- GitBook: content blocks reusable across articles (edit once, update everywhere)
- Zendesk: content blocks for KB articles
- Mintlify: reusable snippets as MDX components

**Partial Includes**:
- MkDocs: `snippets` extension for file fragment inclusion
- Docusaurus: MDX imports and custom components
- Hugo: shortcodes and partials

### Enterprise Approaches (DITA)

**DITA** (Darwin Information Typing Architecture): XML framework for large-scale content management. Modular, reusable "topics" with content references (conrefs). Best for enterprises with complex multi-output documentation (print, web, PDF, embedded help). Tools: Paligo, Oxygen XML, Adobe FrameMaker.

### When to Use What

- **3 or fewer reuse points** → copy-paste is fine; don't over-engineer
- **Simple shared patterns** → MDX components or platform snippets
- **Moderate reuse across a single site** → partial includes (MkDocs snippets, Docusaurus imports)
- **Heavy reuse across multiple products/outputs** → DITA or enterprise CMS
- **Variables** (product name, version, URLs) → use platform variables or MDX context providers

### ROI

- Positive ROI typically within 6-12 months
- Translation cost reduction of 25-50% (translate once, apply everywhere)
- Reduced maintenance burden (update once, propagate)
- Improved consistency across documentation
