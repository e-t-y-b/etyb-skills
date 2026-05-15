---
title: Firebase Studio
description: AI-first cloud dev environment for Firebase + Gemini-integrated workflows. Rebranded from Project IDX in 2025; surface still evolving.
product:
  name: Firebase Studio
  stack: firebase
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, frontend-architect, ai-ml-engineer]
  authoritative_url: https://firebase.studio/
  notes: "Rebranded from Project IDX 2025; AI-first dev environment; surface still evolving."
---

<div class="etyb-currency-banner">Last verified: 2026-05-14 against Firebase 2026 Q2.</div>

## What it is

Firebase Studio is Google's AI-first cloud development environment — browser-based IDE with deep Firebase integration, Gemini Code Assist, and built-in deployment to App Hosting / Cloud Run / Functions. Rebranded from **Project IDX** in 2025. Same product surface, new branding, deeper Firebase + Gemini integration.

Canonical reference: [Firebase Studio site](https://firebase.studio/).

## When to use it

**Use Firebase Studio when:**

- You want a zero-setup cloud dev environment for Firebase work
- Gemini-assisted coding is a primary workflow
- You're prototyping and want one-click deployment to App Hosting

**Don't use Firebase Studio when:**

- Your team standardizes on a different IDE (VS Code, JetBrains)
- You need deep customization of your local toolchain
- Compliance / data-residency requires your code stays on your machine

## 2025-2026 currency anchors

- **Renamed from Project IDX** (2025). Old name is wrong — use "Firebase Studio."
- **Surface still evolving** — features ship monthly. Don't anchor to a specific feature without checking current state.
- **Gemini Code Assist integration** is the differentiator from generic cloud IDEs.

## Patterns

### Quick start a new project

Open Firebase Studio, pick a template (Next.js + Firebase, Flutter + Firebase, etc.), and the workspace provisions a configured environment with the Firebase CLI, Local Emulator Suite, and Gemini Code Assist ready.

### Pair with a local IDE

For most production work, Firebase Studio is a prototyping surface. Production engineering still happens in local IDEs with the Firebase CLI + Emulator Suite.

## Anti-patterns

- **Calling it "Project IDX"** — stale name.
- **Committing to Firebase Studio for production engineering** — the product is still evolving; lock-in risk is real for a still-shaping surface.
- **Using Firebase Studio without source-control discipline** — the environment is browser-hosted; Git push to a real repo on every meaningful change.

## Gotchas

- **Surface still evolving** — UI and features change. Don't write internal docs that hard-link to specific Firebase Studio UI elements.
- **Performance varies by region** — the workspace runs in a GCP region; far-from-you latency is real.
- **Persistence model** — check current docs for workspace lifecycle (auto-pause, hibernation, etc.) — it has changed.
- **Gemini Code Assist features depend on model tier** — features that work in one tier may not in another.

## Cross-references

- [Firebase CLI](/stacks/firebase/firebase-cli/) — preinstalled in Firebase Studio
- [Local Emulator Suite](/stacks/firebase/emulator-suite/) — integrated in Firebase Studio
- [Firebase App Hosting](/stacks/firebase/firebase-app-hosting/) — one-click deploy target
- [Genkit](/stacks/firebase/genkit/) — Genkit dev UI in Firebase Studio
- Authoritative: [firebase.studio](https://firebase.studio/)
