---
title: EAS Submit
description: Automated App Store + Play Store submission of EAS Build artifacts. ASC API key + Google Play service account plumbing, one command per platform.
product:
  name: EAS Submit
  stack: expo
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [devops-engineer]
  authoritative_url: https://docs.expo.dev/submit/introduction/
  notes: "App Store Connect + Play Console flows; metadata + ASC API key plumbing; tracks per platform"
---

## What it is

**EAS Submit** uploads an EAS Build artifact to App Store Connect (iOS) or Google Play Console (Android). One command, one config block in `eas.json`, no Fastlane setup, no manual Xcode Organizer dance.

```bash
eas submit --platform ios --profile production --latest
eas submit --platform android --profile production --latest
```

Canonical surface: [EAS Submit Introduction](https://docs.expo.dev/submit/introduction/).

## When to use

For every store submission past the first manual upload. The first submission of a brand-new app often still needs a manual ASC / Play Console pass to fill in metadata, screenshots, privacy nutrition labels — but subsequent versions are `eas submit` from then on.

Particularly powerful chained from EAS Workflows: build → test → submit in one CI run.

## 2025-2026 currency anchors

- **ASC API Key auth required** for iOS (`.p8` file + key ID + issuer ID). Apple-ID-password auth is deprecated.
- **Google Play service account JSON** for Android — created in GCP, granted Play Console access via Play Console → Setup → API Access.
- **Internal vs External vs Production tracks** — separate `track` setting per submit profile.
- **TestFlight Internal** is instant (up to 100 testers, no Apple review); External Testing is reviewed (~24h, up to 10,000 testers).
- **Play Internal Testing** is instant (up to 100 testers); Closed/Open Testing reviewed if Closed is new, otherwise gated by manual roll-out.
- **`auto_submit: true`** chainable from `eas build` — submits the just-built artifact automatically.

## Patterns + anti-patterns

### Pattern: Submit profile per environment

```json
{
  "submit": {
    "preview": {
      "ios": {
        "ascApiKeyPath": "./secrets/AuthKey_PREVIEW.p8",
        "ascApiKeyId": "...",
        "ascApiIssuerId": "...",
        "track": "internal"
      },
      "android": {
        "serviceAccountKeyPath": "./secrets/play-service-account.json",
        "track": "internal"
      }
    },
    "production": {
      "ios": {
        "ascApiKeyPath": "./secrets/AuthKey_PROD.p8",
        "ascApiKeyId": "...",
        "ascApiIssuerId": "..."
        // no track = production track default
      },
      "android": {
        "serviceAccountKeyPath": "./secrets/play-service-account.json",
        "track": "production",
        "releaseStatus": "draft"
      }
    }
  }
}
```

`releaseStatus: "draft"` on Android stages a release without auto-publishing — final "Release" click happens in Play Console after sanity check.

### Pattern: Chain submit after build

In `eas.json`:

```json
"build": {
  "production": {
    "ios": { "autoIncrement": true },
    "auto_submit": true
  }
}
```

Or in workflow:

```yaml
jobs:
  build_ios:
    type: build
    params: { platform: ios, profile: production, auto_submit: true }
```

### Pattern: ASC API Key rotation

ASC API Keys are valid until revoked; convention is **rotate every 6 months**. Steps:

1. Generate new key in ASC → Users & Access → Integrations → App Store Connect API → Generate.
2. Download `.p8` once (you cannot re-download).
3. Update `eas.json` `ascApiKeyPath` + IDs OR upload via `eas credentials`.
4. Revoke old key.

### Anti-pattern: TestFlight beta on production track

```bash
eas submit --platform ios --profile production --track external
```

Don't promote a production build to TestFlight External without an explicit phase gate. Use `track: internal` for QA builds; only promote to External / Production after sign-off.

### Anti-pattern: Submitting without pre-flight checks

Common rejects:

- Crash on launch (Apple's automated check — test the production build, not a debug build)
- Missing privacy policy URL
- Unjustified permissions ("why does this app need contacts?")
- App tracking transparency prompt not shown when expected
- Reference to non-Apple payment for digital goods (Apple Guideline 3.1.1)
- Use of private APIs (rare in RN, but `expo-doctor` flags some)

Pre-flight: install production-profile build on a real device, run through critical paths, verify permissions, test cold start.

## Gotchas

- **Apple's review queue is ~24-48h** for new submissions; faster (sometimes minutes) for metadata-only updates.
- **Play Console reviews** are 1-3 days for first-time submissions; minutes for in-place updates.
- **App-Specific Password** is no longer the recommended auth — use ASC API Key. App-Specific Password may still work but is on the deprecation path.
- **Google service account permissions** are easy to misconfigure — needs "Service Account User" on the service account itself plus Play Console grant. The IAM / Play Console split confuses new teams.
- **Privacy nutrition labels** on iOS and Data Safety section on Android are required and audited. Lying about data collection = rejection (or worse, post-launch enforcement).
- **`--latest`** submits the most recent EAS Build matching the profile; use `--id <build-id>` for an explicit build.

## Cross-references

- [EAS Build](/stacks/expo/eas-build/) — produces the artifact submitted
- [EAS Workflows](/stacks/expo/eas-workflows/) — chains build + submit
- [EAS CLI](/stacks/expo/eas-cli/) — `eas submit`, `eas submit:view`
- [app.json / app.config.js](/stacks/expo/app-config/) — bundle ID, version, metadata
- `expo-deployment` skill (delegate) — store submission specifics
- Role overlays: [devops-engineer](/stacks/expo/devops-engineer/)
- [EAS Submit Introduction](https://docs.expo.dev/submit/introduction/)
