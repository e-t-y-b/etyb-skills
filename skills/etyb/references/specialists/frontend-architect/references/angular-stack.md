# Angular Stack — Deep Reference

**Always use `WebSearch` to verify version numbers and features. Angular releases major versions every 6 months.**

## Table of Contents
1. [Modern Angular (17+)](#1-modern-angular-17)
2. [Signals](#2-signals)
3. [Standalone Components](#3-standalone-components)
4. [New Control Flow](#4-new-control-flow)
5. [SSR and Hydration](#5-ssr-and-hydration)
6. [State Management](#6-state-management)
7. [Styling](#7-styling)
8. [Component Libraries](#8-component-libraries)
9. [Forms](#9-forms)
10. [Testing](#10-testing)
11. [Performance](#11-performance)
12. [Build Tools](#12-build-tools)
13. [Routing](#13-routing)
14. [Analog.js](#14-analogjs)
15. [RxJS vs Signals](#15-rxjs-vs-signals)

---

## 1. Modern Angular (17+)

### Angular 17 (November 2023) — The Renaissance
- **New control flow**: `@if`, `@for`, `@switch` (replaces `*ngIf`, `*ngFor`, `ngSwitch`)
- **Deferrable views**: `@defer` for lazy loading with `@placeholder`, `@loading`, `@error`
- **Signals stable**: `signal()`, `computed()`, `effect()` — fine-grained reactivity
- **Standalone by default**: `ng generate component` creates standalone components
- **New build system**: esbuild + Vite for dev server (replacing Webpack)
- **SSR improvements**: hydration improvements, `provideClientHydration()`
- **New branding**: angular.dev, new logo, modernized documentation

### Angular 18 (May 2024)
- **Zoneless change detection** (experimental): `provideExperimentalZonelessChangeDetection()`
- **Material 3 (M3)**: Default theme for Angular Material
- **Control flow stable**: `@if`, `@for`, `@switch` graduated from developer preview
- **Fallback content for ng-content**: `<ng-content>Default content</ng-content>`
- **Route redirects as functions**: Dynamic redirect logic
- **Stable SSR hydration**: Full application hydration stable

### Angular 19+ (Late 2024-2025)
- **Signals becoming primary**: More APIs moved to signal-based
- **Incremental hydration**: Hydrate components as they become visible (tied to `@defer`)
- **Signal-based inputs**: `input()` function replacing `@Input()` decorator
- **Signal-based queries**: `viewChild()`, `contentChild()` replacing `@ViewChild`
- **Resource API**: Signal-based data fetching (`resource()`)
- **Linked signals**: `linkedSignal()` for dependent state
- **Effect improvements**: Better control over effect timing and cleanup
- **Zoneless improvements**: Moving toward stable zoneless

### Migration Path
Angular provides schematics for migrating:
- `ng generate @angular/core:control-flow` — migrate to new control flow
- `ng generate @angular/core:standalone` — migrate to standalone components
- `ng generate @angular/core:signals` — migrate to signal-based inputs/queries

---

## 2. Signals

### Core API
```typescript
// Writable signal
const count = signal(0);
count();        // read: 0
count.set(5);   // set
count.update(v => v + 1); // update based on previous

// Computed (derived, read-only)
const double = computed(() => count() * 2);

// Effect (side effects)
effect(() => {
  console.log(`Count is: ${count()}`);
  // Runs when count changes
});
```

### Why Signals Matter for Angular
- **Fine-grained reactivity**: Only re-render the components/DOM nodes that depend on changed signals
- **No Zone.js needed**: Signals trigger change detection precisely, enabling zoneless Angular
- **Simpler than RxJS for sync state**: No need for `BehaviorSubject` + `async` pipe for simple state
- **Better performance**: No dirty checking of entire component tree

### Signal-Based Inputs (Angular 19+)
```typescript
// Old
@Input() name: string = '';

// New
name = input<string>('');        // required: input.required<string>()
// Read: this.name() — it's a signal
```

### Signal-Based Queries (Angular 19+)
```typescript
// Old
@ViewChild('myRef') myRef!: ElementRef;

// New
myRef = viewChild<ElementRef>('myRef');
// Read: this.myRef() — signal, auto-updates
```

---

## 3. Standalone Components

### Default Since Angular 17
```typescript
@Component({
  selector: 'app-user',
  standalone: true,           // default in 17+
  imports: [CommonModule, RouterLink],  // import what you need
  template: `...`,
})
export class UserComponent { }
```

### Impact on Architecture
- **No more NgModules** for most use cases
- Each component declares its own dependencies via `imports`
- `bootstrapApplication()` replaces `bootstrapModule()`
- Providers configured via `provideRouter()`, `provideHttpClient()`, etc.
- **Simpler mental model**: Components are self-contained units

### When NgModules Still Make Sense
- Library development (packaging related components)
- Lazy-loaded feature modules (though standalone lazy routes work too)
- Legacy codebases (gradual migration)

---

## 4. New Control Flow

### @if
```html
@if (user()) {
  <app-user-profile [user]="user()" />
} @else if (loading()) {
  <app-skeleton />
} @else {
  <p>No user found</p>
}
```

### @for (with required `track`)
```html
@for (item of items(); track item.id) {
  <app-item [item]="item" />
} @empty {
  <p>No items available</p>
}
```
- `track` is required (replaces `trackBy` function — less error-prone)
- `@empty` block for empty collections (built-in)
- 90% faster than `*ngFor` in benchmarks (optimized diffing)

### @switch
```html
@switch (status()) {
  @case ('active') { <span class="green">Active</span> }
  @case ('inactive') { <span class="red">Inactive</span> }
  @default { <span>Unknown</span> }
}
```

### @defer (Deferrable Views)
```html
@defer (on viewport) {
  <app-heavy-chart [data]="chartData()" />
} @placeholder {
  <div class="chart-placeholder">Chart loading...</div>
} @loading (minimum 500ms) {
  <app-spinner />
} @error {
  <p>Failed to load chart</p>
}
```

**Triggers**: `on viewport`, `on idle`, `on interaction`, `on hover`, `on timer(5s)`, `on immediate`, `when condition()`

- Automatically code-splits the deferred component
- Lazy loads JS only when trigger fires
- **Huge for performance**: Split large pages into deferred sections

---

## 5. SSR and Hydration

### Angular SSR (formerly Angular Universal)
- `ng add @angular/ssr` — adds SSR support
- `provideClientHydration()` enables hydration
- Pre-renders to full HTML on server, hydrates on client

### Hydration Modes
- **Full hydration** (stable): Entire app hydrated on client. SSR HTML preserved.
- **Incremental hydration** (experimental, Angular 19+): Components hydrate when they become visible or interacted with. Tied to `@defer` blocks.
- `withIncrementalHydration()` in `provideClientHydration()`

### Streaming SSR
- Angular supports HTTP streaming for faster TTFB
- Initial HTML shell sent immediately, content streams as components resolve
- Event replay: user interactions during hydration are replayed after hydration completes

### SSG (Prerendering)
- `ng build --prerender` — pre-render specified routes at build time
- Configure routes in `angular.json` or via `routes` configuration
- Best for: landing pages, marketing pages, documentation

---

## 6. State Management

### Signals (Built-in) — Recommended Default
- Use for: component-level state, shared state via services
```typescript
@Injectable({ providedIn: 'root' })
export class UserStore {
  private _users = signal<User[]>([]);
  users = this._users.asReadonly();

  async loadUsers() {
    const data = await fetch('/api/users').then(r => r.json());
    this._users.set(data);
  }
}
```
- Simple, performant, no external dependency

### NgRx SignalStore (for Complex State)
```typescript
export const UserStore = signalStore(
  withState({ users: [] as User[], loading: false }),
  withComputed(({ users }) => ({
    activeUsers: computed(() => users().filter(u => u.active)),
  })),
  withMethods((store) => ({
    async loadUsers() {
      patchState(store, { loading: true });
      const users = await fetchUsers();
      patchState(store, { users, loading: false });
    },
  })),
);
```
- **When to use**: Complex state with computed values, side effects, devtools
- Replaces traditional NgRx Store + Effects for most use cases

### NgRx Store (Traditional Redux Pattern)
- Actions → Reducers → Selectors → Effects
- **When to use**: Very large apps with complex async flows, teams with NgRx expertise
- **Trend**: Moving toward SignalStore for new code

### NGXS
- Simpler Redux-like pattern with decorators
- Less boilerplate than NgRx Store
- **When to use**: Teams wanting Redux pattern with less ceremony

### RxJS Patterns (When Still Needed)
- HTTP requests: `HttpClient` returns Observables
- WebSocket streams, real-time data
- Complex async coordination (debounce, switchMap, combineLatest)
- Convert to signals: `toSignal(observable)` for template consumption

---

## 7. Styling

### Component Styles (ViewEncapsulation)
- `ViewEncapsulation.Emulated` (default): Scoped CSS via attribute selectors
- `ViewEncapsulation.None`: Global styles
- `ViewEncapsulation.ShadowDom`: True Shadow DOM encapsulation
- `:host`, `:host-context()`, `::ng-deep` (deprecated — use global styles instead)

### Tailwind CSS with Angular
- Full support. `@angular-builders/tailwindcss` or just configure `tailwind.config.js`
- Works with standalone components
- **Recommended for**: Custom-designed apps, rapid prototyping

### Angular Material (Latest)
- MDC-based components (Material Design Components for Web)
- Material 3 (M3) theming (Angular 18+)
- `@angular/material` — Buttons, Cards, Dialog, Snackbar, Table, etc.
- Angular CDK: Foundation for custom components (overlay, drag-drop, virtual scroll, a11y)
- **When to use**: Internal tools, dashboards, enterprise apps. Material Design aesthetic OK.

### Other Libraries
- **PrimeNG**: Rich component library. 80+ components. Themes (Material, Bootstrap, custom).
- **NG-ZORRO**: Ant Design for Angular. Enterprise-focused.
- **Spartan UI**: shadcn-like for Angular. Headless primitives + Tailwind. Growing community.
- **Infragistics / Syncfusion**: Commercial. Complex data grids, charts.

---

## 8. Forms

### Reactive Forms (Recommended)
```typescript
form = new FormGroup({
  name: new FormControl('', [Validators.required]),
  email: new FormControl('', [Validators.required, Validators.email]),
});
```
- **Typed forms** (Angular 14+): `FormControl<string>` — full type safety
- Explicit, testable, composable
- Dynamic form controls with `FormArray`

### Template-Driven Forms
```html
<input [(ngModel)]="user.name" required />
```
- Simpler for basic forms
- Less testable, harder to manage complex validation
- **When to use**: Simple forms, quick prototypes

### Validation Patterns
- Built-in: `Validators.required`, `.email`, `.min`, `.max`, `.pattern`
- Custom validators: functions returning `ValidationErrors | null`
- Async validators: for server-side checks (username availability)
- Cross-field validation: at `FormGroup` level

---

## 9. Testing

### Unit Testing
- **Jest** or **Vitest** (replacing Karma/Jasmine)
- `ng test` can be configured for Jest: `@angular-builders/jest`
- Angular Testing Library: test from user perspective
- `TestBed.configureTestingModule()` for component tests

### Component Testing
```typescript
it('should display user name', () => {
  const { getByText } = render(UserComponent, {
    componentInputs: { user: { name: 'Alice' } },
  });
  expect(getByText('Alice')).toBeTruthy();
});
```

### E2E Testing
- **Playwright** (recommended over Protractor, which is deprecated)
- `@playwright/test` for cross-browser testing
- Component testing mode also available

### Testing Signals
```typescript
it('should update computed value', () => {
  TestBed.runInInjectionContext(() => {
    const count = signal(5);
    const double = computed(() => count() * 2);
    expect(double()).toBe(10);
    count.set(10);
    expect(double()).toBe(20);
  });
});
```

---

## 10. Performance

### OnPush Change Detection
- Component only checks when: `@Input` reference changes, event handler fires, async pipe emits, `markForCheck()` called
- **With signals**: Even more granular — only the signal-dependent template bindings update
- **Recommendation**: Use OnPush everywhere. Signals make it the natural default.

### @defer for Lazy Loading
- Automatically code-splits deferred content
- Loads JS only when trigger fires (viewport, idle, interaction, hover, timer)
- Replace heavy route-level lazy loading with component-level `@defer`

### NgOptimizedImage
```html
<img ngSrc="hero.jpg" width="800" height="600" priority />
```
- Automatic lazy loading (except `priority` images)
- Width/height enforcement (prevents CLS)
- Automatic `srcset` generation
- Preconnect warnings for image domains
- LCP image optimization (automatic `fetchpriority="high"`)

### Virtual Scrolling (CDK)
```html
<cdk-virtual-scroll-viewport itemSize="48" class="h-96">
  <div *cdkVirtualFor="let item of items">{{ item.name }}</div>
</cdk-virtual-scroll-viewport>
```
- Renders only visible items. Essential for large lists.

### Web Workers
- `ng generate web-worker` — scaffolds a web worker
- Offload heavy computation (data processing, encryption) off main thread
- Improves INP for CPU-intensive operations

---

## 11. Build Tools

### Angular CLI + esbuild (Default)
- `@angular/build:application` — esbuild-based builder (default since Angular 17)
- 2-4x faster than Webpack-based builder
- Vite for dev server (HMR, fast refresh)

### Nx for Angular Monorepos
- First-class Angular support with `@nx/angular` plugin
- Code generators: `nx g @nx/angular:component`
- Affected detection: only build/test changed projects
- Computation caching (local + remote)
- Module federation for micro-frontends
- **Recommended for**: Large Angular monorepos, multi-app workspaces

---

## 12. Routing

### Angular Router (Latest)
```typescript
export const routes: Routes = [
  { path: '', component: HomeComponent },
  { path: 'users/:id', component: UserComponent },
  {
    path: 'admin',
    loadComponent: () => import('./admin/admin.component'),  // lazy standalone
    canActivate: [() => inject(AuthService).isAdmin()],     // functional guard
  },
];
```

### Key Features
- **Functional guards and resolvers** (Angular 15+): No more classes for guards
- **Lazy loading standalone components**: `loadComponent` for route-level code splitting
- **Preloading strategies**: `PreloadAllModules`, `QuicklinkStrategy` (prefetch visible links)
- **Route params as inputs**: `withComponentInputBinding()` — route params mapped to `@Input()`/`input()`
- **Navigation events**: `Router.events` observable for tracking navigation

---

## 13. Analog.js

### "Next.js for Angular"
- Vite-powered Angular meta-framework
- **File-based routing**: `src/app/pages/index.page.ts`, `src/app/pages/users.[id].page.ts`
- **API routes**: `src/server/routes/api/users.ts` — server-side API endpoints
- **SSR/SSG**: Server-side rendering and static site generation
- **Content**: Markdown content with frontmatter (like Astro/Next.js)
- **Server-side data fetching**: `routeMeta` for route-level data loading

### When to Use Analog
- Angular projects needing SSR/SSG without boilerplate
- Teams wanting Next.js-like DX in Angular
- Content sites built with Angular
- **Growing but still young** — smaller community than Next.js

---

## 14. RxJS vs Signals

### When to Use Signals
- Synchronous state (counters, toggles, form values)
- Derived/computed values
- Component-level state
- Template bindings (simpler than `async` pipe)
- Simple shared state via services

### When to Still Use RxJS
- HTTP requests (`HttpClient` returns Observables)
- WebSocket/real-time streams
- Complex async coordination (debounce, switchMap, merge, combineLatest)
- Event streams with backpressure
- Operators for transformation pipelines

### Interop
```typescript
// Observable → Signal
const users = toSignal(this.http.get<User[]>('/api/users'));

// Signal → Observable
const count$ = toObservable(this.count);
```

### Migration Path
- New code: signals for state, RxJS for async streams
- Existing code: gradually convert `BehaviorSubject` patterns to signals
- `HttpClient` will likely get signal-based alternative in future Angular versions

---

## Recommended Angular Stack (2025)

| Layer | Recommended | Alternative |
|-------|------------|-------------|
| Angular | 19+ (latest) | 17+ minimum for modern features |
| Components | Standalone (default) | NgModules (legacy) |
| State (simple) | Signals | — |
| State (complex) | NgRx SignalStore | NgRx Store (large apps) |
| Async data | HttpClient + toSignal() | RxJS patterns |
| Styling | Tailwind CSS | Angular Material (enterprise) |
| Component lib | Angular Material / Spartan UI | PrimeNG, NG-ZORRO |
| Forms | Reactive Forms (typed) | Template-driven (simple) |
| Testing | Jest/Vitest + Angular Testing Library | Playwright (E2E) |
| Build | Angular CLI (esbuild) | Nx (monorepo) |
| SSR | Angular SSR (`@angular/ssr`) | Analog.js (meta-framework) |
| Routing | Angular Router (functional guards) | Analog file-based |
| Control flow | `@if`/`@for`/`@switch` | `*ngIf`/`*ngFor` (legacy) |
| Lazy loading | `@defer` + `loadComponent` | NgModule lazy routes (legacy) |
