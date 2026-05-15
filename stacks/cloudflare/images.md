---
title: Images
description: Cloudflare's image platform — Polish (auto-optimization), Resizing (URL-grammar transforms), and Images delivery (signed URLs, custom domains).
product:
  name: Images
  stack: cloudflare
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect, frontend-architect]
  authoritative_url: https://developers.cloudflare.com/images/
  notes: "Polish + Resizing + Images delivery; transforms URL grammar stable."
---

## What it is

Cloudflare Images is the managed image platform — automatic optimization (Polish), URL-grammar-based transforms (Resizing — `cdn-cgi/image/<options>/<source>`), and stored Images with signed URLs and custom domains. URL grammar is stable across 2024-26.

Authoritative reference: [developers.cloudflare.com/images](https://developers.cloudflare.com/images/).

## When to use

- **Image resizing/cropping/format conversion on the fly** via URL transforms.
- **Auto-optimization** (Polish) for images served from your origin — WebP/AVIF where supported.
- **User-uploaded images** — stored Images with thumbnail generation, signed URLs for private access.
- **CMS / catalog images** with many size variants.

Don't use Images when:

- **Video** — use [Stream](/stacks/cloudflare/stream/).
- **Generic large blobs** — use [R2](/stacks/cloudflare/r2/) (and consider a Worker for custom transforms).

## 2025-2026 currency anchors

- **URL transform grammar is stable** — `/cdn-cgi/image/width=400,quality=80/<source>` for resizing.
- **Polish** auto-optimizes images at the zone level — set-and-forget.
- **Pricing per stored image + delivery operations** — verify against current docs.

## Patterns

### URL-based resizing

```html
<img src="https://example.com/cdn-cgi/image/width=400,quality=80,format=auto/https://origin.example.com/photo.jpg" />
```

`format=auto` serves WebP/AVIF when the browser supports it. Use this for any user-facing imagery.

### Stored Images with variants

Upload an image to Cloudflare Images; define variants (`thumbnail`, `card`, `hero`) in the dashboard; reference by variant URL.

```html
<img src="https://imagedelivery.net/<account-hash>/<image-id>/thumbnail" />
```

### Signed URLs for private images

Generate a signed URL on the Worker for time-limited access; rotate the signing key per env.

## Anti-patterns

- **Rolling your own resize/transform Worker** when URL transforms cover the use case.
- **Storing dozens of size variants per image manually** — use the variants feature.
- **Forgetting `format=auto`** — clients without AVIF/WebP support are handled gracefully when you set it.

## Gotchas

1. **Transform URL grammar** is positional — verify against the docs for current option names.
2. **Polish vs Resizing** are different products — Polish is zone-level auto-opt; Resizing is the explicit transform URL.
3. **Signed-URL TTLs** matter for security — too long = leakable, too short = expires before user finishes loading.

## Cross-references

- [R2](/stacks/cloudflare/r2/) — origin for image bytes when not stored in Images
- [Workers](/stacks/cloudflare/workers/) — generate signed URLs, orchestrate access
- [Workers Static Assets](/stacks/cloudflare/workers-static-assets/) — alternative path for static image delivery
- Role overlay: [backend-architect on Cloudflare](/stacks/cloudflare/backend-architect/)
- Authoritative: [developers.cloudflare.com/images](https://developers.cloudflare.com/images/)
