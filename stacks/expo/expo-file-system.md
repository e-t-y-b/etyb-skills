---
title: expo-file-system
description: "File I/O for Expo apps — read, write, download, upload, list, info. Modern object-API in `expo-file-system/next`; legacy module API still supported through SDK 56."
product:
  name: expo-file-system
  stack: expo
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, frontend-architect]
  authoritative_url: https://docs.expo.dev/versions/latest/sdk/filesystem/
  notes: "`/next` (object-API) shipped SDK 54; legacy exports through SDK 56"
---

## What it is

**`expo-file-system`** is the file I/O API for Expo apps — read, write, list directories, download/upload, file info, MIME, hash. Two API shapes coexist in SDK 55:

- **Legacy module API** (`import * as FileSystem from 'expo-file-system'`) — async functions like `readAsStringAsync(uri)`, scheduled for graduation in SDK 56.
- **`/next` object API** (`import { File, Directory } from 'expo-file-system/next'`) — object-oriented, faster, ergonomic. The recommended path for new code.

```ts
// /next API
import { File } from 'expo-file-system/next';
const file = new File('file:///path/to/data.json');
const text = await file.text();
const json = JSON.parse(text);
```

Canonical surface: [`expo-file-system` reference](https://docs.expo.dev/versions/latest/sdk/filesystem/).

## When to use

For any local file work — caching downloaded assets, saving user-generated content, manipulating images post-capture, importing/exporting data files.

Replaces (and surpasses):

- `react-native-fs` — older, separate API, NA-incompatible
- `react-native-blob-util` — older, separate API
- `react-native-fetch-blob` — abandoned

## 2025-2026 currency anchors

- **`/next` API shipped SDK 54** — object-based, sync + async methods on `File` and `Directory` instances. Better TS types.
- **Legacy module API graduates SDK 56** — current and future SDKs will warn; new code should use `/next`.
- **Sandboxed directories** — `Paths.cache`, `Paths.document`, etc., for OS-correct storage locations.
- **`File` instance has `.size`, `.exists`, `.creationTime`, `.modificationTime`** without separate `getInfoAsync` calls.

## Patterns + anti-patterns

### Pattern: Read a JSON cache (new API)

```ts
import { File, Paths } from 'expo-file-system/next';

const cacheFile = new File(Paths.cache, 'snapshot.json');
if (cacheFile.exists) {
  const data = JSON.parse(await cacheFile.text());
  return data;
}
```

### Pattern: Download with progress (new API)

```ts
import { File, Paths } from 'expo-file-system/next';

const file = new File(Paths.document, 'big-asset.zip');
await file.downloadFile('https://cdn.example.com/big.zip', {
  onProgress: (received, total) => console.log(`${received}/${total}`),
});
```

### Pattern: Hashing for integrity check

```ts
import { File } from 'expo-file-system/next';
const file = new File(uri);
const hash = await file.md5();
// or file.sha256(), file.sha1()
```

### Anti-pattern: Mixing legacy and new APIs in the same file

```ts
import * as FileSystem from 'expo-file-system';
import { File } from 'expo-file-system/next';
// Confusing; pick one per file
```

Pick one per module. Migrating? Migrate file by file, not mid-function.

### Anti-pattern: Storing large blobs in MMKV

MMKV is for ≤1MB. For larger blobs (images, audio, video, downloads), use `expo-file-system`. Keep MMKV for indexes + metadata only.

## Gotchas

- **`file://` URIs are platform-specific paths** — iOS sandboxed app container, Android scoped storage. Don't pass them across platform boundaries.
- **Background downloads** — `expo-file-system` supports background downloads on iOS (continue when app is backgrounded); Android uses `expo-task-manager` patterns.
- **`Paths.cache` is OS-prunable** — the OS may clear cache directory under disk pressure. Don't store anything that can't be regenerated.
- **`Paths.document` is user-data** — backed up by iCloud / Google backup by default unless you mark otherwise. Don't store giant blobs there if iCloud sync matters.
- **Asset path resolution** — `require('./asset.png')` yields an int (asset ID); for the URI, use `Asset.fromModule(asset).uri`.

## Cross-references

- [Expo SDK](/stacks/expo/expo-sdk/) — bundled in the SDK
- [expo-secure-store](/stacks/expo/expo-secure-store/) — for sensitive data (tokens) instead of file I/O
- Role overlays: [mobile-architect](/stacks/expo/mobile-architect/), [frontend-architect](/stacks/expo/frontend-architect/)
- [`expo-file-system` reference](https://docs.expo.dev/versions/latest/sdk/filesystem/)
