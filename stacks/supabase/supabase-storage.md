---
title: Supabase Storage
description: "S3-compatible object storage with Postgres-row metadata in `storage.objects`. RLS-gated like any other table."
product:
  name: Supabase Storage
  stack: supabase
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, frontend-architect, security-engineer]
  authoritative_url: https://supabase.com/docs/guides/storage
  notes: "TUS resumable uploads, image transforms, and S3-compatible API are GA; RLS on storage.objects is non-negotiable."
---

## What it is

Supabase Storage is S3-compatible object storage with Postgres-backed metadata. Every uploaded file is a row in `storage.objects` (per bucket configured in `storage.buckets`). Because objects are rows, **storage authorization is RLS** on `storage.objects` — the same primitive as the rest of the database.

Source: [Storage docs](https://supabase.com/docs/guides/storage).

## When to use

Use Supabase Storage for:

- **User-uploaded files in a Supabase-native app** — invoices, avatars, attachments, exports.
- **Public assets** when you want signed URLs + image transforms without standing up CloudFront.
- **Per-tenant file scoping** — folder-name-as-tenant-ID is the canonical convention.

Don't use it for:
- **Hot CDN serving at extreme scale** — Cloudflare R2 + custom CDN may be cheaper at very high egress.
- **Media transcoding pipelines** — use Mux/Cloudflare Stream for video; Storage holds the source.
- **Large unstructured datasets** — S3 with lifecycle rules is more cost-flexible for archive.

## 2025-2026 currency anchors

- **TUS resumable uploads** — files >50MB use the TUS protocol. `supabase-js` has `uploadToSignedUrl` for chunked uploads.
- **Image transformations** — on-the-fly resize, format, quality. Transform params are part of the signed URL; the CDN caches per-variant.
- **S3-compatible API GA** — point any S3 client at `https://<project>.supabase.co/storage/v1/s3`.
- **Bucket-level config** — public flag, file size limit, allowed MIME types set on `storage.buckets`.
- **Folder convention is the standard tenant-scoping pattern** — `<user_id>/...` or `<org_id>/...` in the object name; RLS uses `storage.foldername(name)`.

## Patterns and anti-patterns

### Patterns

**Bucket config — set conservatively at create time:**

```sql
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'invoices',
  'invoices',
  false,                       -- not publicly listed
  10485760,                    -- 10 MiB per file
  ARRAY['application/pdf']     -- PDF only
);
```

**RLS on `storage.objects` — folder-by-user-id pattern:**

```sql
create policy "users read own invoices" on storage.objects
  for select using (
    bucket_id = 'invoices'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "users insert to own folder" on storage.objects
  for insert with check (
    bucket_id = 'invoices'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
```

**Direct browser upload** (the common case):

```ts
const filePath = `${userId}/${crypto.randomUUID()}-${file.name}`;
const { data, error } = await supabase.storage
  .from("user-uploads")
  .upload(filePath, file, {
    contentType: file.type,
    upsert: false,
  });
```

**Server-side upload (Edge Function with service role)** when the caller can't directly:

```ts
const { data, error } = await adminClient.storage
  .from("invoices")
  .upload(`org-123/2026-05-invoice.pdf`, new Uint8Array(buf), {
    contentType: "application/pdf",
    upsert: false,
  });
```

**Signed URLs — short-lived by default:**

```ts
const { data } = await supabase.storage
  .from("invoices")
  .createSignedUrl("org-123/2026-05-invoice.pdf", 3600);  // 1 hour
```

Tune expiration to the use case: clicked-immediately link = 60s; emailed invoice attachment = 24h; long-tail access = a server route that re-signs on demand.

**Image transforms via signed URL:**

```ts
const { data } = supabase.storage
  .from("avatars")
  .getPublicUrl("user-123/avatar.png", {
    transform: { width: 200, height: 200, resize: "cover" },
  });
```

### Anti-patterns

- **Public bucket "to start with."** It ships as world-readable storage; even if RLS exists, the bucket flag wins. Default to private.
- **No INSERT policy on `storage.objects` for a bucket users upload to.** The default-deny means no uploads work; teams flip the bucket to public to "fix" it. Wrong fix.
- **Putting user-supplied size/format params in the transform URL.** An attacker hits arbitrary sizes and blows your CDN cache. Bound the allowed transforms server-side.
- **30-day signed URLs as "permalinks."** Defeats the point of signed URLs. Re-sign on demand.
- **Storing PII in object names.** The path is logged everywhere; use UUIDs in the name and metadata in `storage.objects.user_metadata`.

## Gotchas

- **`storage.objects` policies are RLS policies** — they obey every rule from the [Row-Level Security](/stacks/supabase/row-level-security/) page (`(select auth.uid())` wrap, indexes on policy columns).
- **The bucket's `public` flag bypasses RLS.** Setting it to `true` means anyone with the URL can read; RLS only applies if `public = false`.
- **File size limits enforced at the bucket level.** Setting on the bucket; the API rejects oversize uploads. Don't try to enforce in app code only.
- **Image transforms cached at the CDN.** Cache busting requires either a new path or query-string variation.
- **TUS uploads need a server-side signed upload URL.** The browser PUTs chunks to the signed URL; getting the URL is an Edge Function call.
- **The "list objects" API hits the database directly** — large buckets need pagination + indexes on `bucket_id, name`.
- **Storage policies show up in the Supabase Database Advisor's lint** — review periodically.

## Cross-references

- [Row-Level Security](/stacks/supabase/row-level-security/) — the same primitive applies to `storage.objects`
- [security-engineer role view](/stacks/supabase/security-engineer/) — full storage-security checklist
- [backend-architect role view](/stacks/supabase/backend-architect/) — server-side upload patterns
- [frontend-architect role view](/stacks/supabase/frontend-architect/) — browser upload + display
- Supabase docs: [Storage guide](https://supabase.com/docs/guides/storage), [Storage security](https://supabase.com/docs/guides/storage/security/access-control)
