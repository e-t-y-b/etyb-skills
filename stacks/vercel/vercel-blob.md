---
title: Vercel Blob
description: "Object storage on Vercel — presigned uploads, CDN-fronted, per-blob ACL. For user uploads, AI-generated artifacts, static assets too dynamic for `/public`."
product:
  name: Vercel Blob
  stack: vercel
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, frontend-architect]
  authoritative_url: https://vercel.com/docs/storage/vercel-blob
  notes: "Stable API. Pricing tiers updated 2025. For PB-scale catalogs or egress-sensitive workloads, Cloudflare R2 is often cheaper."
---

## What it is

Vercel Blob is the platform's object storage: direct + presigned uploads, CDN-fronted, per-blob ACL (public/private). The API surface is small and stable. See [vercel.com/docs/storage/vercel-blob](https://vercel.com/docs/storage/vercel-blob).

## When to use

- **User uploads** — avatars, attachments, profile images.
- **AI-generated artifacts** — images, PDFs, audio.
- **Static assets too dynamic for `/public`** — generated reports, exported data.
- **Anywhere you'd reach for S3 in a non-Vercel context** at small-to-medium scale.

Don't use Blob at:

- **PB scale or analytical data lake** — Cloudflare R2 (egress-free), AWS S3, Backblaze B2 win on cost.
- **High-volume image catalogs requiring transforms** — Cloudflare Images / imgix often cheaper than `next/image` against Blob.
- **Hot-cached static assets** — `/public` is fine for those.

## 2025-2026 currency anchors

- **Pricing tiers updated 2025** — verify the current per-GB stored and egress pricing.
- **Presigned URLs** support browser-direct uploads — the server signs, the browser uploads, no proxying through your function.
- **CDN-fronted delivery** — global edge cache by default.

## Patterns + anti-patterns

**Pattern: Browser-direct upload via presigned URL.**

```ts
// Server: Route Handler
import { put } from '@vercel/blob';

export async function POST(req: Request) {
  const formData = await req.formData();
  const file = formData.get('file') as File;
  const blob = await put(`uploads/${crypto.randomUUID()}-${file.name}`, file, {
    access: 'public',
  });
  return Response.json(blob);
}
```

**Pattern: Skip `next/image` for known static dimensions.** Host static assets on Blob with long Cache-Control; serve as plain `<img>` or `next/image unoptimized`. Static assets that don't need responsive sizing don't need optimization transforms.

**Pattern: Set explicit content-type + cache-control on upload.** Browser caches better when headers are right.

**Anti-pattern: Proxying user uploads through your function.** Wastes function CPU + bandwidth. Use presigned URLs.

**Anti-pattern: Storing PB-scale catalogs on Blob.** R2 / S3 / B2 are cheaper at that scale, especially for egress-heavy workloads.

**Anti-pattern: Putting secrets in blob URLs.** Public URLs are public; use private access + signed URLs for sensitive content.

## Gotchas

- **Public vs private access** — set explicitly at upload; can't change later without re-upload.
- **Egress pricing** matters at scale — model it before going PB.
- **`next/image` against Blob** — fine for moderate volume; consider the [Image Optimization](/stacks/vercel/image-optimization/) budget conversation.
- **Lifecycle policies** — no built-in automatic deletion; if you need TTL, track in your DB and delete on schedule.

## Cross-references

- [Image Optimization](/stacks/vercel/image-optimization/) — relationship to next/image
- [Marketplace](/stacks/vercel/marketplace/) — for R2/S3 alternatives
- [backend-architect on Vercel](/stacks/vercel/backend-architect/) — storage decision matrix
- Authoritative: [Blob docs](https://vercel.com/docs/storage/vercel-blob)
- Delegate: `vercel:vercel-storage`
