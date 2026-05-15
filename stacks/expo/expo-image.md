---
title: expo-image
description: SDWebImage/Glide-backed image component for React Native — caching, off-thread decoding, modern formats. Non-negotiable for remote images in production.
product:
  name: expo-image
  stack: expo
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, mobile-architect]
  authoritative_url: https://docs.expo.dev/versions/latest/sdk/image/
  notes: "Replaces `react-native-fast-image` (not NA-ready); only modern image solution in 2026"
---

## What it is

**`expo-image`** is a React Native `Image` replacement powered by **SDWebImage** on iOS and **Glide** on Android. It does what RN's built-in `Image` doesn't: aggressive caching (memory + disk), off-thread decoding, modern format support (WebP, AVIF), placeholder + blurhash, content-fit modes matching CSS `object-fit`.

```tsx
import { Image } from 'expo-image';

<Image
  source="https://example.com/avatar.jpg"
  style={{ width: 100, height: 100 }}
  contentFit="cover"
  placeholder={{ blurhash: 'L6PZfSi_.AyE_3t7t7R**0o#DgR4' }}
  transition={200}
/>
```

Canonical surface: [`expo-image` reference](https://docs.expo.dev/versions/latest/sdk/image/).

## When to use

For **every remote image** in 2026. The previous community option `react-native-fast-image` is unmaintained for the New Architecture. RN's built-in `Image` is suitable only for static local assets bundled with the app.

Use cases:

- Avatars, product images, hero images from CDN
- Thumbnails in lists (with blurhash placeholders)
- Long-tail of remote content where caching matters

## 2025-2026 currency anchors

- **Stable, NA-compatible** since SDK 49.
- **Source as string** — `source="url"` works directly; no inline object identity headaches like with RN's `Image`.
- **Blurhash placeholder** built in.
- **Transition prop** for fade-in.
- **Priority hint** (`priority="high"`) for above-the-fold images.
- **Cache policy** — `cachePolicy="memory-disk"` (default), `"memory"`, `"disk"`, `"none"`.
- **`recyclingKey`** for use inside FlashList recycler — explicit cell-to-image identity.

## Patterns + anti-patterns

### Pattern: Avatar with blurhash placeholder

```tsx
<Image
  source={avatarUrl}
  style={styles.avatar}
  contentFit="cover"
  placeholder={{ blurhash: avatarBlurhash }}
  transition={200}
  cachePolicy="memory-disk"
/>
```

### Pattern: List image with recycling key

```tsx
<FlashList
  data={products}
  renderItem={({ item }) => (
    <Image source={item.image} recyclingKey={item.id} style={styles.thumb} />
  )}
/>
```

`recyclingKey` tells `expo-image` "this cell now represents a different image" so cached pixels of the previous item aren't shown.

### Pattern: Preload hero images

```tsx
import { Image } from 'expo-image';

useEffect(() => {
  Image.prefetch(hero.imageUrl, 'memory-disk');
}, []);
```

Useful for navigation transitions — prefetch the next screen's hero before the user taps.

### Anti-pattern: `Image` from `react-native` for remote URLs

```tsx
// BAD
import { Image } from 'react-native';
<Image source={{ uri: avatarUrl }} />
```

- No aggressive caching
- New object identity per render → defeats Image's diff
- No off-thread decoding
- No modern format support

Always `expo-image` for remote.

### Anti-pattern: `react-native-fast-image`

Unmaintained for the New Architecture. Migrate to `expo-image`.

## Gotchas

- **Bundle adds ~150KB** for the native dependency. Acceptable for any real app; not worth it for a static-only app.
- **iOS uses SDWebImage**, Android uses Glide — same API, slight perf differences.
- **`cachePolicy="none"`** doesn't cache at all — useful for one-off captures, never for repeat-load images.
- **Local assets** (`require('./image.png')`) work but you don't need `expo-image`'s caching for them; the built-in `Image` is fine.
- **Animated GIFs / WebP** play by default; control with `autoplay` prop.

## Cross-references

- [Expo SDK](/stacks/expo/expo-sdk/) — bundled in the SDK
- [New Architecture](/stacks/expo/new-architecture/) — `expo-image` is NA-compatible (unlike `react-native-fast-image`)
- `vercel-react-native-skills` skill (delegate) — perf patterns for lists with images
- Role overlays: [frontend-architect](/stacks/expo/frontend-architect/), [mobile-architect](/stacks/expo/mobile-architect/)
- [`expo-image` reference](https://docs.expo.dev/versions/latest/sdk/image/)
