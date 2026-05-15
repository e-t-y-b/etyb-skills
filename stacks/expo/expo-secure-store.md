---
title: expo-secure-store
description: Secure key-value store backed by iOS Keychain and Android Keystore-encrypted prefs. The right home for auth tokens and biometric secrets. Not a general database.
product:
  name: expo-secure-store
  stack: expo
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, security-engineer]
  authoritative_url: https://docs.expo.dev/versions/latest/sdk/securestore/
  notes: "Keychain (iOS) / Keystore-backed encrypted prefs (Android); stable API; default accessibility = WhenUnlockedThisDeviceOnly"
---

## What it is

**`expo-secure-store`** is a small encrypted key-value store. On iOS, items live in **Keychain** with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` by default. On Android, items are encrypted with **Android Keystore** and stored in `SharedPreferences`. Maximum value size is ~2KB per key.

```ts
import * as SecureStore from 'expo-secure-store';

await SecureStore.setItemAsync('refresh_token', token);
const token = await SecureStore.getItemAsync('refresh_token');
await SecureStore.deleteItemAsync('refresh_token');
```

Canonical surface: [`expo-secure-store` reference](https://docs.expo.dev/versions/latest/sdk/securestore/).

## When to use

For data that must be encrypted at rest **and** small (≤2KB per key):

- Refresh tokens (OAuth/OIDC)
- API session tokens
- Biometric-gated secrets (with `requireAuthentication: true` option)
- Device-specific identifiers used in authentication

**Do not use** for:

- App settings, preferences, feature flags → use [`MMKV`](https://github.com/mrousavy/react-native-mmkv) (much faster, larger values)
- Cached server data → use [`expo-file-system`](/stacks/expo/expo-file-system/) or React Query persisted to MMKV
- Anything ≥2KB

## 2025-2026 currency anchors

- **API stable** since SDK 33+; minor option additions over the years.
- **`requireAuthentication: true`** (option) prompts Face ID / Touch ID / device passcode on read.
- **Default accessibility** is `WHEN_UNLOCKED_THIS_DEVICE_ONLY` on iOS — not synced to iCloud, requires device unlock.
- **Android Keystore** uses hardware-backed key storage on devices that support it; falls back to software keystore otherwise.
- **No web fallback** — `expo-secure-store` doesn't run on web (no Keychain equivalent). Use `crypto.subtle` + IndexedDB or skip the secret on web.

## Patterns + anti-patterns

### Pattern: Token storage for OIDC

```ts
import * as SecureStore from 'expo-secure-store';

async function persistTokens(access: string, refresh: string) {
  // Refresh token: long-lived, must be encrypted
  await SecureStore.setItemAsync('refresh_token', refresh);
  // Access token: short-lived; MMKV is acceptable here for speed
  storage.set('access_token', access);
}
```

### Pattern: Biometric-gated read

```ts
const secret = await SecureStore.getItemAsync('vault_key', {
  requireAuthentication: true,
  authenticationPrompt: 'Unlock your vault',
});
// Throws if user cancels / Face ID fails
```

### Anti-pattern: Storing JWTs in MMKV

```ts
// BAD
storage.set('refresh_token', token);  // plaintext on disk
```

MMKV is unencrypted by default. Refresh tokens must go in SecureStore.

### Anti-pattern: Storing user PII in SecureStore

```ts
// BAD — wastes Keychain space; SecureStore items are slow
await SecureStore.setItemAsync('user_address', JSON.stringify(address));
```

PII goes in your encrypted server-side store. The client should hold tokens that fetch it.

### Anti-pattern: Assuming SecureStore = HIPAA-compliant

It's encrypted at rest *on the device*. PHI requires server-side encryption, BAAs, audit logging. SecureStore is one layer; the regulatory frame is separate. See the healthcare-architect vertical for the full picture.

## Gotchas

- **2KB value limit** — large secrets need different storage (file system with `requireAuthentication` is one pattern).
- **Keychain isn't synced** with default options — backup/restore behavior varies; test the restore flow if user-data continuity matters.
- **Android Keystore corruption** is rare but possible on user-initiated device wipes / OS upgrades. Code defensively: catch errors, force re-auth if a token can't be retrieved.
- **Debugger access** — a jailbroken iOS device with a debugger can read Keychain items. Don't store anything you'd refuse to put in an `Authorization:` header without TLS.
- **Web stub** — `expo-secure-store` is a no-op on web; calls succeed but read returns `null`. Don't rely on it for cross-platform.

## Cross-references

- [Expo SDK](/stacks/expo/expo-sdk/) — bundled in the SDK
- [`expo-auth-session`](/stacks/expo/expo-auth-session/) — OAuth/OIDC client; tokens go in SecureStore
- Role overlays: [mobile-architect](/stacks/expo/mobile-architect/)
- [`expo-secure-store` reference](https://docs.expo.dev/versions/latest/sdk/securestore/)
