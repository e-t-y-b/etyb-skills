---
title: Expo DOM Components
description: "Run React-DOM trees inside a webview on native via the `'use dom'` directive. Useful for rich-text editors, charts, web-only third-party widgets."
product:
  name: Expo DOM Components
  stack: expo
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect]
  authoritative_url: https://docs.expo.dev/guides/dom-components/
  notes: "Run web code inside a webview on native; bridges via marshalled props/messages; stable since SDK 52"
---

## What it is

**Expo DOM Components** let you mark a React component with `'use dom'` at the top of the file. On native, the component renders inside a `react-native-webview`. On web, it renders as-is. The bridge between native and the webview is JSON-serializable props (in) + a `postMessage`-style channel (out via callbacks).

```tsx
'use dom';
import { Editor } from '@tiptap/react';

export default function RichTextEditor({
  initialHtml,
  onChange,
}: {
  initialHtml: string;
  onChange: (html: string) => void;
}) {
  return (
    <div contentEditable onInput={(e) => onChange(e.currentTarget.innerHTML)}>
      {initialHtml}
    </div>
  );
}
```

Canonical surface: [DOM Components guide](https://docs.expo.dev/guides/dom-components/).

## When to use

When you have a web library that has no native equivalent, and reimplementing it in RN would take longer than embedding the web version. Concrete cases:

- **Rich-text editors** — Tiptap, ProseMirror, Lexical, Quill. RN doesn't have anything comparable.
- **Charts** — Recharts, Chart.js, D3-based libraries. Native chart libs exist (Victory Native, react-native-skia) but have rougher edges.
- **Web-only third parties** — Stripe Elements (separate from `@stripe/stripe-react-native`), Plaid Link Web, embedded Calendly.
- **Incremental migration** — bring existing web code into a native app while you write native replacements.

**Don't use** for:

- Trivial UI (buttons, lists) — DOM has webview overhead, not worth it
- Performance-critical surfaces (scrolling lists, animation-heavy screens)
- Things needing deep native integration (camera, GPS, sensors)

## 2025-2026 currency anchors

- **Stable since SDK 52** (2024).
- **`'use dom'` directive** at the top of a `.tsx` file makes the export render inside webview on native, as-is on web.
- **Props are JSON-serializable** — pass strings, numbers, booleans, plain objects. No refs across the bridge.
- **Outbound calls** — callbacks (functions in props) become `postMessage`-shaped channels under the hood. They work, with serialization caveats.
- **`react-native-webview` is bundled** by Expo DOM Components — you don't install it separately.
- **Bundle size impact** — each DOM component adds the webview footprint (~minor on iOS, larger on Android first-page-load).

## Patterns + anti-patterns

### Pattern: Rich-text editor

```tsx
// components/RichTextEditor.tsx
'use dom';
import { useEditor, EditorContent } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';

export default function RichTextEditor({
  initialHtml,
  onChange,
}: {
  initialHtml: string;
  onChange: (html: string) => void;
}) {
  const editor = useEditor({
    extensions: [StarterKit],
    content: initialHtml,
    onUpdate: ({ editor }) => onChange(editor.getHTML()),
  });
  return <EditorContent editor={editor} />;
}
```

Use as if it were a regular component:

```tsx
import RichTextEditor from '@/components/RichTextEditor';

<RichTextEditor initialHtml={post.content} onChange={setHtml} />
```

On native, it's in a webview. On web, it's just React DOM.

### Pattern: Chart with web library

```tsx
'use dom';
import { LineChart, Line, XAxis, YAxis } from 'recharts';

export default function PriceChart({ data }: { data: Array<{ time: number; price: number }> }) {
  return (
    <LineChart width={400} height={300} data={data}>
      <XAxis dataKey="time" />
      <YAxis />
      <Line type="monotone" dataKey="price" stroke="#8884d8" />
    </LineChart>
  );
}
```

### Anti-pattern: Heavy DOM component for trivial UI

```tsx
'use dom';
export default function Button({ label, onPress }) {
  return <button onClick={onPress}>{label}</button>;
}
```

Don't wrap a button in a webview. Webview overhead per instance is real (memory, startup, accessibility-tree extra hop). DOM Components are for components with genuine web-only value.

### Anti-pattern: Sharing refs across the bridge

```tsx
'use dom';
const ref = useRef();
// Trying to share ref with native parent — won't work
```

The DOM ref lives in the webview process; native can't poke it. Communicate via props in + callbacks out only.

## Gotchas

- **JSON-only props** — Date objects, Maps, Sets, class instances need serialization helpers.
- **CSS and assets** load from the bundle; `import './styles.css'` works.
- **Network requests** in DOM components use the webview's `fetch`, not RN's. CORS rules apply.
- **Accessibility** — DOM Components on native render as a single AccessibilityElement (the webview itself). Internal a11y tree isn't exposed to VoiceOver/TalkBack. For accessible content, prefer RN or wrap with AccessibilityInfo announcements.
- **Performance** — first-paint of a DOM component is slower than RN (webview cold start). Subsequent renders are fast within the same component instance.
- **Debugging** — open `react-native-webview` devtools (Safari Web Inspector on iOS connected to simulator/device; Chrome DevTools `chrome://inspect` for Android).

## Cross-references

- [Expo Router](/stacks/expo/expo-router/) — DOM components used as regular screens or sub-screens
- `use-dom` skill (delegate) — DOM Components patterns
- Role overlays: [frontend-architect](/stacks/expo/frontend-architect/)
- [DOM Components guide](https://docs.expo.dev/guides/dom-components/)
