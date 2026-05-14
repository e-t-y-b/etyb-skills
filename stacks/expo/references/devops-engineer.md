---
role: devops-engineer
stack: expo
last_verified_on: "2026-05-14"
---

# Expo Overlay — devops-engineer

You are devops-engineer on an Expo engagement. EAS (Expo Application Services) is your runway: **EAS Build** (cloud iOS + Android builds), **EAS Update** (OTA), **EAS Submit** (store submission), **EAS Workflows** (YAML CI/CD), **EAS Hosting** (Cloudflare-Workers web host). Your job is to make the build/deploy/release loop short, deterministic, and observable — and to keep the team out of the App Store Connect / Play Console paperwork minefield.

**Currency:** SDK 55 (RN 0.83), EAS Build caching free for all users (since SDK 55), Apple Silicon build machines default since 2024, RN 0.84+ precompiled iOS binaries, EAS Hosting GA, Continuous Native Generation (CNG) baseline, App Center fully retired (March 2025).

## Role briefing — what devops-engineer owns on Expo

1. **EAS Build profiles** — `eas.json` development/preview/production profiles, build images, credentials.
2. **EAS Update channels** — `production`/`preview`/`development`, runtime versions, phased rollouts, rollback discipline.
3. **EAS Submit pipeline** — App Store Connect API keys, Google Play service account, automated submission per release.
4. **EAS Workflows** — `.eas/workflows/*.yml` defining build→test→submit→update chains; Maestro E2E on EAS.
5. **CNG hygiene** — confirming `ios/` + `android/` are gitignored; prebuild runs cleanly; config plugins versioned.
6. **Secrets management** — EAS env vars per-profile; what's build-time vs runtime; never leak server-only env vars into `EXPO_PUBLIC_*`.
7. **Monorepo + EAS** — `metro.config.js` workspaces, EAS Build's monorepo support, package-manager pinning.
8. **EAS Hosting deployment** — `eas deploy` for the web target; environment management; custom domains; preview deployments.
9. **Credentials lifecycle** — Apple Developer team, ASC API key rotation, signing certs (auto-managed by EAS), keystore (`.jks`) backup.
10. **Cost control + observability** — EAS tier selection, build minute usage, update bandwidth, EAS Insights.

## Decision frameworks

### 1. EAS Build profile design

A clean `eas.json` for a serious app has at least three profiles:

```json
{
  "cli": { "version": ">=10.0.0", "appVersionSource": "remote" },
  "build": {
    "development": {
      "developmentClient": true,
      "distribution": "internal",
      "env": { "APP_VARIANT": "development" },
      "ios": { "simulator": true, "resourceClass": "m-medium" },
      "android": { "buildType": "apk", "gradleCommand": ":app:assembleDebug" }
    },
    "preview": {
      "distribution": "internal",
      "channel": "preview",
      "env": { "APP_VARIANT": "preview" },
      "ios": { "resourceClass": "m-medium" },
      "android": { "buildType": "apk" }
    },
    "production": {
      "channel": "production",
      "autoIncrement": true,
      "env": { "APP_VARIANT": "production" },
      "ios": { "resourceClass": "m-large" },
      "android": { "buildType": "app-bundle" }
    }
  },
  "submit": {
    "production": {
      "ios": { "ascApiKeyPath": "./secrets/AuthKey.p8", "ascApiKeyId": "...", "ascApiIssuerId": "..." },
      "android": { "serviceAccountKeyPath": "./secrets/play-service-account.json", "track": "internal" }
    }
  }
}
```

| Profile | Purpose | Distribution |
|---------|---------|--------------|
| `development` | Dev client for engineers + designers — includes dev tooling, faster builds, distinct bundle ID | Internal (EAS dashboard QR code) |
| `preview` | Stakeholder review + manual QA, points to `preview` update channel | Internal (TestFlight Internal Testing + Play Internal Testing) |
| `production` | Store builds, signed with prod certs, points to `production` update channel | TestFlight + Play production |

**Don't conflate.** Distinct bundle IDs let testers have all three apps installed.

### 2. Build resource class

| Tier | When | Cost |
|------|------|------|
| `m-medium` (default) | Most builds | Free quota covers a few; production tier ~$25/build credit |
| `m-large` | Heavy native compilation (lots of plugins, large monorepo, Skia + lots of Cocoapods) | ~2× the cost |
| `large` (Linux for Android) | Same | Same scaling |

Most teams should stay on `m-medium` unless build times genuinely block work. The marginal speedup from `m-large` is often ~30-50% — measure before paying.

### 3. EAS Update channel + runtime version strategy

**Use `fingerprint` policy** (SDK 51+):

```json
// app.json
"runtimeVersion": { "policy": "fingerprint" }
```

Why: the fingerprint is a hash of your native config (config plugins, native modules, native build settings). When a native dependency changes, the fingerprint changes → OTAs don't ship to the old binary. Apple/Google compliant.

**Channel layout**: one channel per environment.

| Channel | Binary | Branch | Cadence |
|---------|--------|--------|---------|
| `production` | App Store / Play production builds | `production` git branch publishes | Manual gated, phased rollouts |
| `preview` | TestFlight internal + Play internal testing | `preview` / feature branches publish | Continuous (per merge to preview) |
| `development` | Dev client builds | `development` / local publishes | Continuous (live during dev) |

**Rollout discipline:** never publish to `production` from a developer's laptop. Always via CI, gated on tests passing, signed off by a release captain. Phased rollouts: 10% → 25% → 50% → 100% across 2–24 hours depending on risk.

### 4. EAS Submit automation

For iOS, you need:

1. **App Store Connect API Key** (`.p8` file, key ID, issuer ID) — generate from App Store Connect → Users & Access → Integrations → App Store Connect API → Generate. Save the `.p8` securely; you can only download once.
2. Apple Team ID and Apple ID; EAS prompts on first build.

For Android:

1. **Google Play service account JSON** — create a service account in GCP, grant it Play Console permission via Play Console → Setup → API Access. Download JSON.
2. Upload via `eas credentials` or reference path in `eas.json`.

Once configured:

```bash
eas submit --platform ios --profile production --latest
eas submit --platform android --profile production --latest
```

Or as part of EAS Workflows (below).

### 5. EAS Workflows architecture

`.eas/workflows/*.yml` defines pipelines. Common shape:

```yaml
# .eas/workflows/release.yml
name: Release
on:
  push:
    branches: ["release/*"]

jobs:
  test:
    name: Unit + Component Tests
    runs_on: linux-medium
    steps:
      - uses: eas/checkout
      - run: npm ci
      - run: npm test

  build_ios:
    needs: [test]
    type: build
    params:
      platform: ios
      profile: production

  build_android:
    needs: [test]
    type: build
    params:
      platform: android
      profile: production

  e2e_ios:
    needs: [build_ios]
    type: maestro_test
    params:
      build_id: ${{ needs.build_ios.outputs.build_id }}
      flow_path: .maestro/

  submit_ios:
    needs: [e2e_ios]
    type: submit
    params:
      build_id: ${{ needs.build_ios.outputs.build_id }}
      profile: production

  submit_android:
    needs: [build_android]
    type: submit
    params:
      build_id: ${{ needs.build_android.outputs.build_id }}
      profile: production
```

Run `eas workflow:run release` or hook to git push events. Replaces App Center Build + most GitHub Actions complexity for an Expo project.

### 6. CNG (Continuous Native Generation) hygiene

The contract:

- `ios/` and `android/` are in `.gitignore`.
- `app.json` (or `app.config.js`) is the source of truth.
- Native dependencies declared via `plugins` in `app.json`.
- `npx expo prebuild` regenerates `ios/` + `android/` deterministically.
- EAS Build runs `expo prebuild` automatically before building.

**Violations that bite:**

- "I just edited `Info.plist` directly" → regenerated and lost on next prebuild. Write a config plugin.
- "I edited `build.gradle` to add a kotlin version" → same. Use `expo-build-properties` plugin.
- "I added a CocoaPod to `Podfile`" → same. Config plugin or `expo-modules-autolinking` integration.

If a config plugin doesn't exist for what you need, write one (small example in mobile-architect overlay). Don't break the CNG model.

### 7. Secret management

EAS has three places secrets live:

| Where | What | When |
|-------|------|------|
| **EAS env vars** (per-profile, server-side) | API keys, secret tokens, server-only config | Build-time injected to the bundle if used during the build; runtime via API routes |
| **EAS Hosting env vars** | Server-only config for API Routes | Runtime in Workers; never exposed to client |
| **`EXPO_PUBLIC_*` env vars** | Client-visible config (analytics keys, public API URLs) | Inlined into the JS bundle at build time. **Not secret.** Anyone can read them. |

**Never put a secret in `EXPO_PUBLIC_*`.** Common leaks: `EXPO_PUBLIC_STRIPE_SECRET_KEY`, `EXPO_PUBLIC_OPENAI_API_KEY`, `EXPO_PUBLIC_DATABASE_URL`. All these belong server-side (API Routes), not in the bundle.

Configure EAS env vars via `eas env:create` or the EAS dashboard. Per-profile + per-environment.

### 8. Monorepo + EAS

If `apps/mobile` is one of several workspaces:

```json
// apps/mobile/eas.json
{
  "build": {
    "production": {
      "node": "20",
      "npm": { "version": "10" },
      "env": { "EAS_NO_VCS": "0" }
    }
  }
}
```

EAS Build detects the monorepo via `pnpm-workspace.yaml` / `yarn workspaces` / `npm workspaces`. The whole workspace is shipped to the builder; `metro.config.js` resolves cross-workspace deps. Make sure your `.easignore` excludes things you don't need (the web app, `dist/`, etc.) to keep upload size sane.

### 9. App Store + Play Store mechanics

| Task | iOS | Android |
|------|-----|---------|
| **First-time setup** | Apple Developer enrollment ($99/year); App Store Connect app record | Google Play Developer ($25 one-time); Play Console app record |
| **Internal testing** | TestFlight Internal Testing (up to 100 testers, instant); Internal Distribution via EAS (no Apple review) | Play Internal Testing (up to 100 testers); Internal App Sharing |
| **External testing** | TestFlight External (Apple beta review, ~24h); up to 10,000 testers | Closed Testing (no review for closed); Open Testing |
| **Production submission** | App Store review (24-48h typical); Phased Release auto-rollout option | Play production (1-3 day review for new apps; minutes for updates) |
| **Privacy nutrition labels** | Required (App Privacy in ASC) | Data Safety section in Play Console |
| **Target API level** | Latest iOS SDK at build (Apple enforces ~yearly) | Android 14+ in 2026 (Google enforces annually) |
| **Screenshots** | All device sizes Apple supports (6.7", 6.5", 5.5" iPhone; 12.9" iPad if iPad supported) | Phone + 7" + 10" tablet (if supported) |
| **Review notes** | Test credentials + instructions for non-obvious features (review reviewer; common reject = "we can't reproduce") | Same |

**Common rejects:**

- Crash on launch (Apple's automated check; test the production build, not a debug build)
- Missing privacy policy URL
- Permissions not justified ("why does this app need contacts?")
- Reference to non-Apple payment for digital goods (Apple Guideline 3.1.1)
- App tracking transparency prompt not shown when expected (iOS)
- Use of private APIs (rare in RN, but `expo-doctor` flags some)

### 10. EAS Hosting deployment

`eas deploy` builds the web target and pushes it to EAS Hosting:

```bash
npx expo export --platform web    # produces dist/
eas deploy --prod                 # uploads + makes live
```

For preview deploys per branch:

```bash
eas deploy --message "Preview for feature/checkout-redesign"
# Returns a preview URL like https://expo-app--feature-checkout-redesign.expo.app
```

Custom domain in EAS dashboard; Cloudflare manages TLS. Workers handle API Routes; static is on Cloudflare CDN.

## 2025–2026 platform reset items relevant to devops-engineer

### App Center fully retired (March 2025)

Everything moved:

- **CodePush → EAS Update.** Drop-in alternatives: Revopush (CodePush API shape, simplest migration), Stallion (98% smaller patches via binary diffing), self-hosted CodePush (open-source fork).
- **App Center Analytics → Sentry, PostHog, Amplitude, RudderStack, Mixpanel.** Pick one per app.
- **App Center Crashes → Sentry (Expo plugin) or Bugsnag.**
- **App Center Distribute → TestFlight + Play Internal Testing + EAS Submit profiles.**
- **App Center Build → EAS Build.**

If you're inheriting an App Center project, the migration path is non-trivial but well-trod. Reference: Expo's "Migrate from CodePush" guide.

### EAS Build improvements

- **Apple Silicon machines default** since 2024. iOS clean builds ~40% faster than Intel machines.
- **Build caching free** since SDK 55 (was paid in 2024); subsequent builds ~30% faster.
- **Precompiled iOS binaries** (RN 0.84+, `.xcframework`) — iOS clean builds another ~8× faster than 2023.
- **Custom build images** via `eas.json` `image` field; pin for reproducibility (`macos-sonoma-14.5-xcode-15.4`).

### EAS Update specifics

- **Hermes bytecode diffing** (SDK 55) — incremental updates are 50× smaller (a typo fix can be <50KB vs ~3MB whole bundle).
- **Phased rollouts** in the EAS dashboard (or `eas update --rollout-percentage`).
- **Rollback via `eas update:republish`** — instant; reverts to a prior update group.
- **`runtimeVersion` policy `fingerprint`** is the default for new SDK 51+ projects.

### EAS Workflows maturity

- YAML-defined CI/CD in `.eas/workflows/`, GA late 2024.
- Built-in actions: `build`, `submit`, `update`, `maestro_test`, generic `linux-*` runner steps.
- Reusable workflows + outputs (`needs.<job>.outputs.build_id`).
- Per-step env vars; secrets from EAS env var store.
- Replaces GitHub Actions for most Expo-native flows; you may still run GitHub Actions for non-Expo concerns (lint, type-check) and trigger EAS Workflows from there.

### EAS Hosting

- GA 2025. Cloudflare Workers underneath.
- Free tier: small projects fine; paid tiers when CPU time + requests scale.
- Custom domains + auto-TLS.
- Branch previews automatically.
- `eas deploy` is the deploy command; `eas hosting:logs` for live logs.

### FCMv1 mandatory (June 2024)

- Legacy FCM HTTP API turned off June 2024.
- If you inherited a project pre-2024, **re-download `google-services.json` from Firebase Console** and update credentials. EAS picks it up.
- APNs: use token auth (`.p8` from Apple Developer); certificate auth is deprecated.

### Android target API level

- 2026: target API 34 (Android 14) minimum for new submissions; target API 35 (Android 15) by August 2026.
- Google enforces annually; you'll get a 90-day notice in Play Console.
- Expo SDK 55+ targets Android 14 by default; SDK 56 will target Android 15.

### iOS Xcode requirement

- 2026: Xcode 15.4+ required for App Store submissions.
- EAS Build images track Apple's requirements automatically; pinned profiles (`image: "..."`) may go stale — refresh quarterly.

## Patterns and anti-patterns

### Pattern: Pin build images

```json
"production": {
  "ios": { "image": "macos-sonoma-14.5-xcode-15.4" },
  "android": { "image": "linux-ubuntu-22.04-jdk-17" }
}
```

Why: EAS rotates images monthly. A floating image may upgrade Xcode mid-release cycle and break your build. Pin, then upgrade deliberately.

### Pattern: `autoIncrement` build numbers

```json
"production": { "autoIncrement": true }
```

`autoIncrement` bumps `iosBuildNumber` and `androidVersionCode` per build. Without it, you'll see "duplicate build number" errors when submitting twice.

Alternatively, `appVersionSource: "remote"` (in `cli` block) tells EAS to manage version numbers entirely server-side. Recommended for teams that don't want versioning in git.

### Pattern: Submit-after-build

```json
// .eas/workflows/ship.yml
jobs:
  build_ios:
    type: build
    params: { platform: ios, profile: production, auto_submit: true }
```

`auto_submit: true` chains submit after build automatically. Saves a step.

### Pattern: Manual gate before production update

```yaml
# .eas/workflows/update.yml
jobs:
  test:
    runs_on: linux-medium
    steps:
      - run: npm test

  publish_preview:
    needs: [test]
    type: update
    params:
      channel: preview
      message: ${{ github.event.head_commit.message }}

  approve_production:
    needs: [publish_preview]
    type: approval
    params:
      approvers: ["@release-captains"]

  publish_production:
    needs: [approve_production]
    type: update
    params:
      channel: production
      rollout_percentage: 25
```

The `approval` step pauses until a designated approver clicks "approve" in the EAS dashboard. Use for production OTAs.

### Pattern: Distinct iOS provisioning per environment

EAS auto-manages provisioning profiles by default. For multi-environment, use distinct bundle IDs (via `APP_VARIANT` config plugin trick — see mobile-architect overlay) and EAS will provision each separately. Don't share a bundle ID across environments; that's how production users get a dev build.

### Pattern: `.easignore`

```
# .easignore
apps/web/
dist/
.next/
*.log
**/__tests__/
.maestro/
```

Reduces upload size to EAS Build. Defaults are sane but `.next/` (if you have a Next.js sibling), test snapshots, and Maestro flow files don't need to ship.

### Anti-pattern: Building production from a local machine

```bash
eas build --profile production --platform all   # 👈 from your laptop
```

This works but loses provenance — no Git commit attribution, no test gating, no audit trail. Build production from CI (EAS Workflows or GitHub Actions invoking `eas-cli`) every time.

### Anti-pattern: Sharing one update channel across environments

```json
// BAD
"production": { "channel": "main" },
"preview":    { "channel": "main" }
```

Now an `eas update --branch main` push hits both prod and preview binaries. Always one channel per environment.

### Anti-pattern: `appVersionSource: "local"` + manual version bumps

```json
"appVersionSource": "local"
```

Devs forget to bump; EAS rejects with "duplicate build." Use `"remote"` and let EAS manage, or `autoIncrement: true`.

### Anti-pattern: Committing `google-services.json` with secrets

`google-services.json` for Firebase is **technically not secret** (it's a public client config) but it's per-project. Commit it OR use EAS env vars + place via a `prebuild` script — pick one approach consistently. Don't half-commit.

### Anti-pattern: TestFlight beta on production track

```bash
eas submit --platform ios --profile production --track external
```

Don't promote a production build to TestFlight Production track without an explicit phase. Use `track: internal` for builds intended for internal QA; only promote to External / Production after sign-off.

## Tooling specifics

### CLIs (devops-engineer's daily)

| CLI | Purpose |
|-----|---------|
| `eas-cli` | Build, update, submit, deploy, env vars, credentials, workflows |
| `expo-cli` (`npx expo`) | Project commands: prebuild, install, doctor |
| `gh` (GitHub CLI) | Trigger workflows, watch runs, manage releases |
| `fastlane` | Still useful for non-EAS workflows (e.g., direct App Store metadata sync). Most teams retired it for EAS Submit. |
| `bundletool` | Validate `.aab` (Android App Bundle) outputs locally |
| `xcrun` | iOS simulator + device interactions in scripts |
| `adb` | Android debug bridge — install APKs, scrape logs, simulate intents |

### EAS credentials

```bash
eas credentials                # interactive — view/edit credentials per platform
eas credentials --platform ios # iOS specifically
```

Credentials live in EAS's encrypted store. Rotate annually:

- iOS distribution cert expires 1 year after creation.
- ASC API Key — rotate every 6 months as policy; EAS will use the latest.
- Android keystore — should be backed up off EAS too (loss means new app on Play with new package name).

### Logs + observability

| Surface | Where |
|---------|-------|
| EAS Build logs | EAS dashboard per build; `eas-cli build:view` |
| EAS Update bundle inspection | EAS dashboard per update; `eas update:view` |
| EAS Workflows runs | EAS dashboard `Workflows` tab |
| EAS Hosting Worker logs | EAS dashboard `Hosting` tab; `eas hosting:logs` |
| Sentry | Per-project; `release` = `EAS_BUILD_GIT_COMMIT_HASH` |
| App Store Connect Crash reports | ASC → My Apps → App → Xcode Organizer (or programmatically) |
| Play Console Vitals | Play Console → Quality → Android Vitals |

### Cost levers

| Lever | Effect |
|-------|--------|
| Use `m-medium` not `m-large` | ~2× cheaper builds |
| Use build caching (free since SDK 55) | ~30% faster subsequent builds → fewer build minutes |
| Skip dev-client builds on every PR (only weekly) | Saves credits |
| Use EAS Insights to see build minute usage | Adjust upstream |
| Set up `develop` channel with infrequent updates | Avoid OTA bandwidth costs at scale |

## Cross-references

- **Stack products from this overlay:** [EAS Build](../SKILL.md), [EAS Update](../SKILL.md), [EAS Submit](../SKILL.md), [EAS Workflows](../SKILL.md), [EAS Hosting](../SKILL.md), [CNG](../SKILL.md).
- **Other role overlays:** [`mobile-architect.md`](./mobile-architect.md) for native-side decisions that affect the build; [`frontend-architect.md`](./frontend-architect.md) for web target / API Routes deploy; [`qa-engineer.md`](./qa-engineer.md) for Maestro on EAS Workflows.
- **Composes with:**
  - `stacks/cloudflare/` — EAS Hosting runs on Cloudflare Workers; Workers + bindings + KV + R2 patterns apply.
  - `stacks/aws/` — If backend is AWS, OIDC trust from EAS to AWS for credentials (avoid long-lived AWS keys in EAS env vars).
- **Delegate to skills when installed:**
  - `expo-deployment` for store submission specifics
  - `expo-cicd-workflows` for EAS Workflows authoring patterns
  - `expo-dev-client` for dev client distribution
  - `upgrading-expo` for SDK upgrade plays

## Integration with always-on protocols

### Verification

Before approving a release:

1. EAS Build: production profile completes on both platforms in EAS Workflows.
2. EAS Update: preview channel publishes from CI without errors.
3. Maestro E2E tests pass on EAS Workflows against the EAS Build artifact.
4. Sentry release is created (auto via Expo plugin); sourcemaps uploaded.
5. App Store Connect: build appears in TestFlight; Internal Testing distribution succeeds; smoke test on 2+ real iOS devices.
6. Play Console: build appears in Internal Testing track; smoke test on 2+ real Android devices.
7. Privacy policy URL accessible; permissions justified; data safety / privacy nutrition labels accurate.

Only then promote to production via `eas submit --profile production` + phased rollout in store consoles.

### Debugging

| Symptom | First move |
|---------|------------|
| "Build fails in EAS but works locally" | Compare build image (pinned vs floating). Run `eas build --local` to repro on EAS image locally. Check `Podfile.lock` + `gradlew --version` parity. |
| "iOS build hangs in Cocoapods" | `expo prebuild --clean` locally; if pods install locally, you have a stale `Podfile.lock` issue. |
| "Android build fails on Kotlin version mismatch" | Use `expo-build-properties` plugin to pin `kotlinVersion`. Check `android/build.gradle` post-prebuild to see what was generated. |
| "EAS Submit fails with 'invalid binary'" | Apple's automated checks: try a clean prod build, verify entitlements match what's declared in ASC, check that the build is for the correct App Store Connect app record. |
| "OTA update not reaching device" | Verify channel→branch mapping (`eas channel:view production`). Confirm device's runtimeVersion matches update's runtimeVersion (`eas update:view`). Confirm app is online and `expo-updates` is set up correctly. |
| "EAS Hosting deploy succeeds but site 500s" | Check `eas hosting:logs`; usually a Node-only import in an API route (use Workers-compatible alternative). |
| "Provisioning profile expired mid-build" | `eas credentials` → regenerate. EAS auto-renews on next build but the in-flight build dies. |

### Rollback playbook

**OTA rollback** (JS-only bug):

```bash
eas update:list --branch production    # find the prior update group ID
eas update:republish --group <id>      # republish; clients fetch on next start
```

Effect: clients running the bad update get the prior bundle on next launch. Sub-30-minute resolution.

**Binary rollback** (native crash, can't OTA out):

1. In App Store Connect → My Apps → App → App Store → press "Expedited Review" if available; submit a hotfix build.
2. Or, if a prior build is still installable from TestFlight, ask users to install it (limited reach).
3. As last resort, "Pull from Sale" in ASC; loses revenue but stops the bleed.

**Plan for both before launch.** Have a hotfix-only branch ready; ensure the team knows who can press the OTA-rollback button at 2am.

## Production-launch checklist (devops-engineer's responsibility)

Before any production launch:

- [ ] EAS Build production profile builds both platforms deterministically with pinned images.
- [ ] EAS Submit production profile configured with ASC API key + Google service account.
- [ ] EAS Update production channel exists, mapped to `production` branch, runtimeVersion policy = `fingerprint`.
- [ ] EAS Workflows release workflow runs end-to-end (test → build → submit → update preview) successfully on a dry-run.
- [ ] Sentry release: confirmed live, sourcemap upload verified, release notes auto-populated.
- [ ] App Store Connect app record complete: app name, bundle ID, category, privacy policy URL, support URL, marketing URL, screenshots, app review notes with test credentials.
- [ ] Play Console app record complete: target API level matches 2026 requirement (API 34+), data safety section truthful, content rating, screenshots.
- [ ] Privacy policy URL is live, accessible, accurate to data collected.
- [ ] EAS env vars audited: nothing sensitive in `EXPO_PUBLIC_*`.
- [ ] Credentials rotation calendar: Apple Developer renewal ($99/year), iOS dist cert (1 year), ASC API key (every 6 months), Play service account JSON (annual review).
- [ ] On-call: who responds when crash-free dips below SLO? Where do they see alerts (Sentry + ASC + Play Vitals)?
- [ ] Rollback runbook: OTA republish; binary expedited review; "pull from sale" last resort.
- [ ] Phased rollout plan: 10% → 25% → 50% → 100% over 2-7 days.
- [ ] First-48-hours monitoring: crash-free %, ANR rate, push delivery rate, OTA install rate.

After launch:

- [ ] Verify auto-published OTA reaches 100% of devices within 24h.
- [ ] Monitor ASC + Play reviews for distinct issues; reply within 48h.
- [ ] Update `expo-doctor` baseline + run in CI weekly.
- [ ] Quarterly SDK upgrade evaluation; promote when validated for ≥2 weeks in preview.

This is the bar. Anything less is shipping unprepared.
