---
title: expo-auth-session
description: OAuth 2.0 + OIDC client for Expo. PKCE mandatory in 2026; secure code-exchange happens on your backend, never in the app.
product:
  name: expo-auth-session
  stack: expo
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [mobile-architect, security-engineer]
  authoritative_url: https://docs.expo.dev/versions/latest/sdk/auth-session/
  notes: "OIDC/OAuth client; PKCE mandatory; redirect URI conventions stable; works with Auth0/Cognito/Clerk/Supabase/Google/Apple"
---

## What it is

**`expo-auth-session`** is the OAuth 2.0 + OpenID Connect client for Expo apps. It opens an in-app browser session (ASWebAuthenticationSession on iOS, Chrome Custom Tabs on Android), handles the redirect back to your app, and gives you the authorization code or token.

```ts
import * as AuthSession from 'expo-auth-session';
import * as WebBrowser from 'expo-web-browser';

WebBrowser.maybeCompleteAuthSession();

const discovery = AuthSession.useAutoDiscovery('https://auth.example.com');
const [request, response, promptAsync] = AuthSession.useAuthRequest(
  {
    clientId: process.env.EXPO_PUBLIC_OAUTH_CLIENT_ID!,
    scopes: ['openid', 'profile', 'email'],
    redirectUri: AuthSession.makeRedirectUri({ scheme: 'myapp', path: 'redirect' }),
    usePKCE: true,
  },
  discovery,
);
```

Canonical surface: [`expo-auth-session` reference](https://docs.expo.dev/versions/latest/sdk/auth-session/).

## When to use

For any third-party OIDC / OAuth login flow on mobile:

- Auth0, Okta, Cognito, Azure AD / Entra ID
- Google (`expo-auth-session/providers/google`)
- Apple (`expo-apple-authentication` for native Sign in with Apple; `expo-auth-session` for OIDC-style)
- Supabase / Clerk (these usually have their own SDKs, but `expo-auth-session` is the underlying primitive)
- Your own OIDC server

For straightforward username/password against your own backend, just use `fetch` — no need for `expo-auth-session`. The library is for the *authorization flow* (browser → redirect → code).

## 2025-2026 currency anchors

- **PKCE mandatory** — public clients (mobile apps) must use Proof Key for Code Exchange. `usePKCE: true` (default in modern usage).
- **No client_secret in the app** — public clients don't have one. Refresh tokens stay on your backend; ship short-lived access tokens to the device.
- **ASWebAuthenticationSession (iOS) / Chrome Custom Tabs (Android)** — these are *not* WebView; they share cookies with the system browser, enabling SSO sessions across apps.
- **Universal Links / App Links** are the preferred redirect mechanism — more robust than custom schemes (which can be hijacked).
- **`makeRedirectUri()`** generates the right URI for the runtime — `myapp://redirect` in dev clients, `https://myapp.com/redirect` if associatedDomains is configured.

## Patterns + anti-patterns

### Pattern: OIDC auth-code with PKCE

```ts
import * as AuthSession from 'expo-auth-session';
import * as WebBrowser from 'expo-web-browser';

WebBrowser.maybeCompleteAuthSession();

const discovery = AuthSession.useAutoDiscovery('https://auth.example.com');

const [request, response, promptAsync] = AuthSession.useAuthRequest(
  {
    clientId: process.env.EXPO_PUBLIC_OAUTH_CLIENT_ID!,
    scopes: ['openid', 'profile', 'email'],
    redirectUri: AuthSession.makeRedirectUri({ scheme: 'myapp', path: 'redirect' }),
    usePKCE: true,
  },
  discovery,
);

useEffect(() => {
  if (response?.type === 'success') {
    const code = response.params.code;
    // Send code + PKCE verifier to YOUR BACKEND; backend exchanges with auth server using client_secret
    // Backend returns access + refresh tokens; store access in MMKV, refresh in SecureStore
  }
}, [response]);

return <Button title="Sign in" onPress={() => promptAsync()} disabled={!request} />;
```

The mobile app never sees `client_secret`. The backend does the code-for-token exchange.

### Pattern: Refresh token rotation server-side

Don't ship refresh tokens to the device if you can help it. Instead:

- Backend issues a *session cookie* or a custom short-lived JWT (15 min)
- Mobile sends the session token on each API call
- Backend silently refreshes against the auth server

If you must hold refresh tokens on the device, put them in [`expo-secure-store`](/stacks/expo/expo-secure-store/).

### Anti-pattern: client_secret in the app

```ts
// BAD
{ clientId: 'abc', clientSecret: 'xyz' }
```

Public clients don't have a secret. If your provider requires one, that's a **confidential client** — those run on servers, not phones. Get a public client setup from your auth provider.

### Anti-pattern: WebView for OAuth

```tsx
// BAD — silos cookies, fails SSO, blocked by some providers
<WebView source={{ uri: authUrl }} />
```

Use `expo-auth-session` (ASWebAuthenticationSession / Chrome Custom Tabs). WebView OAuth is deprecated by Google and a TOS violation for several providers.

## Gotchas

- **`maybeCompleteAuthSession()`** must run at module load on the web side of the auth flow if you ever invoke from web — handles the redirect handoff. On native, it's a no-op.
- **Deep link `scheme` collisions** — `myapp://redirect` works only if `scheme` in `app.json` is unique. Hijacking is theoretical but real; prefer Universal Links for production OAuth.
- **iOS associated domains** — if you use a HTTPS redirect URI, you need AASA at the redirect host. See [Expo Router](/stacks/expo/expo-router/) deep-link patterns.
- **State parameter** — `expo-auth-session` generates a state nonce automatically; don't disable it.
- **Provider quirks** — Google requires `prompt='consent'` to always re-issue refresh tokens; Microsoft requires `response_mode='query'` for code flow. Read your provider's RFC oddities.

## Cross-references

- [Expo SDK](/stacks/expo/expo-sdk/) — bundled in the SDK
- [`expo-secure-store`](/stacks/expo/expo-secure-store/) — where tokens land
- [Expo Router](/stacks/expo/expo-router/) — deep linking for the redirect
- Role overlays: [mobile-architect](/stacks/expo/mobile-architect/)
- [`expo-auth-session` reference](https://docs.expo.dev/versions/latest/sdk/auth-session/)
