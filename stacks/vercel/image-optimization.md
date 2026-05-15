---
title: Image Optimization
description: "`next/image` — auto WebP/AVIF + multi-size srcset + lazy loading. Mature; the budget conversation (transforms per month) is the lever to watch."
product:
  name: Image Optimization
  stack: vercel
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [frontend-architect, devops-engineer]
  authoritative_url: https://nextjs.org/docs/app/api-reference/components/image
  notes: "Mature. Pricing model (image transforms) is the lever — defaults can blow budgets quickly. For high-volume catalogs, consider Cloudflare Images / imgix instead."
---

## What it is

`next/image` is the Next.js Image component — automatic WebP/AVIF transcoding, multi-size srcset generation, lazy loading by default, placeholder support. On Vercel, each transform counts against a per-plan quota. See [nextjs.org/docs/app/api-reference/components/image](https://nextjs.org/docs/app/api-reference/components/image).

## When to use

- **Responsive images** that need device-appropriate sizes.
- **User-uploaded content** that benefits from format optimization (WebP/AVIF).
- **LCP-critical images** — `priority` prop preloads.

Don't use `next/image` for:

- **Tiny icons / logos** — static images don't benefit from optimization; serve from `/public`.
- **High-volume catalogs (1M+ user-uploaded images at multiple sizes)** — Cloudflare Images / imgix often cheaper.
- **Static assets you've already optimized** — `unoptimized` prop bypasses transforms.

## 2025-2026 currency anchors

- **Pricing model: image transforms per month.** Each unique source + size + format combination counts. Easy to blow.
- **`sizes` matters more than ever** — defaults overserve; tune to actual layout.
- **Configurable `deviceSizes` + `imageSizes` in `next.config.ts`** — limits the transform matrix.
- **`placeholder="blur"` needs `blurDataURL`** for user uploads (generate at upload time with `sharp` or Plaiceholder).

## Image Optimization budget conversation

`next/image` transforms count against your plan quota. A page that lists 100 user-uploaded avatars at 4 sizes each will burn through the quota in days. **Defenses:**

1. **Set `sizes` realistically.** A grid image at `w-1/3` on desktop and `w-full` on mobile should be `sizes="(min-width: 768px) 33vw, 100vw"`, not the default `100vw`.
2. **Configure `images.deviceSizes` and `images.imageSizes`** in `next.config.ts` to limit the transform matrix. Defaults generate ~16 sizes per image; you probably need 4-6.
3. **Use `priority` only for above-the-fold LCP-critical images.** Everything else lazy-loads.
4. **For high-volume catalogs (1M+ user-uploaded images), use Cloudflare Images or imgix at the source** and serve via `next/image` with `unoptimized` (or skip `next/image` entirely). Pay them, not Vercel transform quota.
5. **For app icons, logos, decorative imagery** — host on [Vercel Blob](/stacks/vercel/vercel-blob/) with cache headers, serve as plain `<img>` or `next/image unoptimized`. Static assets that don't need responsive sizing don't need optimization.
6. **`placeholder="blur"` needs `blurDataURL`.** For user uploads, generate at upload time (Plaiceholder, `sharp`); don't request `placeholder="blur"` without it.

## Patterns + anti-patterns

**Pattern: Tuned `next.config.ts`.**

```ts
const nextConfig = {
  images: {
    deviceSizes: [640, 750, 1080, 1920],
    imageSizes: [16, 32, 64, 128],
    formats: ['image/avif', 'image/webp'],
  },
};
```

**Pattern: `sizes` per use case.**

```tsx
<Image src="/hero.jpg" alt="" width={1920} height={1080} priority
  sizes="100vw" />
<Image src={avatar} alt="" width={48} height={48}
  sizes="48px" />
```

**Pattern: `unoptimized` for already-optimized assets.**

```tsx
<Image src="/already-optimized.webp" unoptimized width={400} height={300} alt="" />
```

**Anti-pattern: Default `sizes="100vw"`.** Overserves on mobile, burns transforms.

**Anti-pattern: `priority` on every image.** Defeats lazy loading.

**Anti-pattern: 100 user-uploaded avatars × 4 sizes × `next/image`.** Burns quota in days. Cache + serve as static, or move to Cloudflare Images.

## Gotchas

- **Transforms per source-size combo** are billed individually — even a "small change" like adjusting a `sizes` breakpoint can re-generate.
- **`placeholder="blur"`** without `blurDataURL` falls back silently.
- **Domain allowlist for remote images** — set `remotePatterns` in `next.config.ts`.
- **`fill` prop requires positioned parent** — set `position: relative` or absolute on the parent.

## Cross-references

- [Vercel Blob](/stacks/vercel/vercel-blob/) — host static assets to skip optimization
- [Vercel Cache](/stacks/vercel/vercel-cache/) — transforms are cached at the edge
- [Speed Insights](/stacks/vercel/speed-insights/) — LCP measurement
- [frontend-architect on Vercel](/stacks/vercel/frontend-architect/) — full image budget conversation
- [devops-engineer on Vercel](/stacks/vercel/devops-engineer/) — cost monitoring
- Authoritative: [next/image docs](https://nextjs.org/docs/app/api-reference/components/image)
- Delegate: `vercel:nextjs`
