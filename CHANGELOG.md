# Changelog

All notable changes to ETYB Skills are documented here. Format is loosely based on [Keep a Changelog](https://keepachangelog.com/). Versions follow [SemVer](https://semver.org/).

The public-facing changelog lives at https://etyb.ai/changelog. Every ETYB response links there.

## [4.0.0] — 2026-05-14

**One brand. One channel. 13 vendor Stacks. Future-ready.** v4 is the largest release in the project's history — three changes in one:

1. **Structural collapse 30 → 1.** Where v3 surfaced 30 separate slash commands (one per specialist + protocol + vertical), v4 ships a single coordinated skill (`/etyb`) holding all 29 as internal references. The user always talks to `/etyb`; ETYB silently routes to the right expertise. Every Tier 1-4 response is signed (`ETYB · <role-engaged>`) and links the public changelog.

2. **Knowledge-currency framework.** Every Stack now carries `last_verified_on`, `authoritative_sources.primary` URLs, `delegate_to_skills` (vendor MCPs/skills ETYB defers to when installed), and `products_covered` with per-product `drift_risk`. A new tiered drift-check protocol (`core/knowledge-currency.md`) governs when ETYB answers from baked knowledge, when it discloses currency, and when it must defer to a vendor surface or WebFetch the authoritative source. The maintainer-side validator `scripts/maintainer/check-currency.sh` flags stale Stacks before release.

3. **12 new Stacks shipping with v4.** Built in parallel, all current as of 2026-05-14. AWS, GCP, Azure, Anthropic Claude, OpenAI, Cloudflare, Vercel, Supabase, Firebase, Expo, Stripe, and a multi-vendor Observability Stack. Combined with the v2-retrofitted Salesforce Stack, v4 ships **13 vendor knowledge overlays** out of the box covering ~350 distinct products across infrastructure, AI, data, payments, mobile, and observability.

### Why this is a major release

- **Slash-command pollution gone.** v3 had 30 trigger surfaces competing at activation time. v4 has one. The router becomes ETYB's responsibility, not Claude's.
- **Tier-based installs.** Three install tiers (`lite`, `core`, `pro`) ship different subsets of internal references. Solo devs get a small footprint; domain shops get verticals. Same `/etyb`, different breadth.
- **Brand consolidation.** Every response now identifies as ETYB and links to `etyb.ai/changelog`. Users don't have to remember 30 names; they remember one.
- **Skill-creator-compliant.** This aligns the repo with Anthropic's Domain Organization guidance: one skill with internal `references/<variant>/` files, rather than 30 sibling skills.

### Added

- **`skills/etyb/references/specialists/`** — 14 core specialist READMEs (was: `skills/<name>/SKILL.md`).
- **`skills/etyb/references/protocols/`** — 9 always-on protocol READMEs.
- **`skills/etyb/references/verticals/`** — 6 vertical-domain READMEs (Pro tier only).
- **`skills/etyb/core/signature.md`** — output template appended to every Tier 1-4 response: a divider line, `ETYB · <role-engaged>`, and `What's new — etyb.ai/changelog`. Tier 0 skips the signature; Tier 2 incidents skip the changelog line to keep firefighting output lean.
- **`skills/etyb/core/knowledge-currency.md`** — tiered drift-check protocol (soft default disclosing currency + source; strict for high-stakes/stale-high-drift claims). Tells ETYB when to defer to vendor MCPs/skills, when to WebFetch authoritative sources, and how to surface currency to the user.
- **Tier system in `manifest.json`** — declares which references each tier installs. Replaces the v3 bundle system.
- **Stack v2 schema** in every Stack frontmatter — `last_verified_on`, `authoritative_sources.primary`, `delegate_to_skills`, `products_covered` with per-product `drift_risk` and notes.
- **12 new vendor Stacks** — AWS, GCP, Azure, Anthropic Claude, OpenAI, Cloudflare, Vercel, Supabase, Firebase, Expo, Stripe, Observability (multi-vendor). ~47K lines across ~81 files. Every Stack ships role overlays for the specialists that touch its surface, with `delegate_to_skills` entries naming the vendor MCPs/skills users should expect to coexist with.
- **`scripts/maintainer/check-currency.sh`** — walks every Stack's frontmatter, flags products whose `drift_risk` threshold has been exceeded (high=90d, medium=180d, low=365d). Optional URL probe with `CHECK_CURRENCY_FETCH=1`. Wired into `validate-pr.sh`.
- **`.claude/skills/etyb-oss-maintainer/references/currency-spec.md`** — maintainer playbook for the currency model: refresh-PR flow, delegation maintenance, anti-patterns.
- **v3→v4 migration check in `scripts/install.sh`** — detects sibling skills from v3.x installs (`research-analyst/`, `tdd-protocol/`, etc.) and offers to back them up so they don't compete with `/etyb` at trigger time. Also rewrites stale Claude-Code hook paths in `.claude/settings.json`.
- **`scripts/maintainer/v4-migrate-skill.sh`** — the migration helper used to move the 29 sibling skills into internal references. Kept in the repo for future similar restructures.

### Changed

- **`skills/etyb/SKILL.md`** — new description optimized for v4 collapsed routing (~210 words, category-level triggers rather than enumerated keywords from 29 deleted skills). New "Internal References" section documenting the three reference libraries and tier-dependent availability.
- **`skills/etyb/core/team-registry.md`, `core/charter.md`, `core/always-on-protocols.md`, all other core files** — references rewritten from `skills/<name>/` paths to `references/<library>/<name>/` paths.
- **`skills/etyb/core/stack-registry.md`** — extended with v2 routing (delegate_to_skills probing + drift-check protocol entry-point); detection signals added for the 12 new Stacks.
- **`stacks/salesforce/SKILL.md`** — retrofitted to v2 schema (authoritative_sources, delegate_to_skills, products_covered with 16 products' drift_risk). `verified_on` renamed to `last_verified_on` for schema consistency.
- **7 vendor-heavy specialist files migrated to pointer + platform-neutral summary** — `cloud-aws-specialist.md`, `cloud-gcp-specialist.md`, `cloud-azure-specialist.md`, `llm-specialist.md`, `ai-integration.md`, `monitoring-specialist.md`, `react-native-specialist.md`. Each one's vendor-specific content moved into the matching Stack(s); each one now retains the role's platform-neutral principles and points at the Stack(s) for vendor specifics. Net: -6,209 lines / +218 lines across these 7 files.
- **`scripts/install.sh`** — rewritten around `--tier <lite|core|pro>`. Always copies `skills/etyb/`, prunes references not in the chosen tier.
- **`.claude-plugin/marketplace.json`** — one plugin (`etyb`) that installs the full Pro version. Tier selection is a CLI-installer concern, not a marketplace concern.
- **`manifest.json`** — `skills: {...}` map collapses to `skill: {etyb: 4.0.0}`. New `tiers` block. Stack `available_on_tiers` field added. 13 Stacks declared (Salesforce + 12 new), each with `applies_to_roles`, `deferred_roles`, `last_verified_on`, `available_on_tiers`.
- **`STACKS.md`** — public-doc v2 schema. New Available Stack Packs table includes all 13. Authoring conventions updated, currency-check section added, maintainer responsibilities section added.
- **`scripts/maintainer/validate-pr.sh`** — now includes `check-currency.sh` in the umbrella suite.
- **`scripts/maintainer/validate-skill-manifest-sync.sh`** — rewritten for v4 single-skill layout + tier integrity check.
- **`scripts/maintainer/validate-version-sync.sh`** — updated for the v4 `manifest.json .skill` shape (was `.skills`) and frontmatter consolidation.
- **`scripts/lint-portability.sh`** — rewritten around v4 (1 installable skill, 14+9+6 references, Claude hook paths at v4 locations).
- **README.md, CLAUDE.md** — rewritten around the one-skill-three-tiers model + Stack table refresh.

### Removed

- **29 sibling skill directories** (`skills/research-analyst/`, `skills/tdd-protocol/`, `skills/fintech-architect/`, etc.) — content lives under `skills/etyb/references/`.
- **`bundles/`** — 4 plain-text bundle files. Replaced by `manifest.json`'s `tiers` block.
- **`scripts/generate-bundles.py`** — no longer needed.
- **Per-sibling `evals/`** — each sibling shipped its own eval set. Those targeted the deleted shape; we'll rebuild a single eval set for `/etyb` once the description is empirically tuned.

### Migration notes for v3 users

- `/plugin install etyb-full@etyb-skills` → `/plugin install etyb@etyb-skills`
- `./scripts/install.sh --bundle process-protocols` → `./scripts/install.sh --tier lite`
- `./scripts/install.sh --bundle core-team` → `./scripts/install.sh --tier core`
- `./scripts/install.sh --bundle verticals` → `./scripts/install.sh --tier pro`
- `./scripts/install.sh --skills X,Y,Z` (à la carte) — removed. The CLI installer is now tier-based. Drop to `--tier lite` for the smallest footprint, or fork the repo if you need a custom slice.
- Old slash commands like `/backend-architect` no longer exist. Use `/etyb` and describe your task; ETYB will route to the backend-architect reference internally.

v3 remains installable for one release cycle (deprecation banner on `main`); plan to migrate before the v3 EOL date in the [public changelog](https://etyb.ai/changelog).

## [3.0.0] — 2026-05-12

**Stack Packs are here. Salesforce is live.** ETYB now ships tech-stack expertise alongside the engineering team — knowledge overlays that load on top of the existing 20 specialists whenever the work involves a specific platform. The first pack ships full Salesforce coverage current to Spring '26, capturing the 2025–2026 platform reset (Agentforce, Data 360, MCP-native dev, Apex Cursors, ECA migration, MFA mandate) that pre-2025 training data misses. Same pattern will land for AWS, GCP, Azure, Vercel, Supabase, Snowflake, Databricks, Stripe, Shopify, SAP, and ServiceNow.

### Why this is a major release

This adds a **new artifact type** to ETYB. Until now, ETYB was specialists + protocols — two orthogonal axes. Now it's specialists + protocols + stack expertise — three orthogonal axes. Stack Packs sit alongside the team without bloating it: a Salesforce engagement still routes to backend-architect, frontend-architect, security-engineer, and ai-ml-engineer — but each one picks up the platform overlay for that engagement. When the work changes stack, the overlay rotates; the team doesn't. The architecture scales by adding folders, not roles.

This release also adopts **single-version semantics**. Every skill, every stack, every artifact tracks the bundle version on every release. No more per-skill version drift (which had silently put etyb at 2.0.0 in SKILL.md and 2.1.0 in the manifest before this release).

### Added

- **Stack Packs** — new top-level artifact type. Each pack lives under `stacks/<name>/` with a `SKILL.md` orchestrator briefing and per-role overlays at `references/<role>.md`. ETYB's router loads them via the new `skills/etyb/core/stack-registry.md` when stack signals match the user's request. Packs compose across roles, defer to vertical specialists on compliance, and always-on protocols still apply unchanged.
- **Salesforce Stack Pack** — full 11-role coverage current to Spring '26 (API v66.0), Dreamforce '25, and TrailblazerDX 2026. Each role gets a focused overlay:
  - `system-architect` — primitive selection (Flow vs Apex vs Agentforce vs MuleSoft vs external), Headless 360 patterns, org-strategy decisions, integration-boundary calls.
  - `backend-architect` — modern Apex (Cursors, user-mode SOQL, transaction finalizers, Queueable patterns), Pub/Sub API, MCP authoring + Apex-as-Agent-Action plumbing, Named & External Credentials, bulkification and the trigger handler pattern.
  - `frontend-architect` — LWC 2026 (TypeScript types, `lightning/graphql`, reactive screen flows, LWR for Experience Cloud, Lightning Out 2.0), wire-first data, Aura → LWC migration, LWC Jest testing.
  - `ai-ml-engineer` — Agentforce design (Topics / Actions / Guardrails / Atlas Reasoning Engine), Prompt Builder, Agent Script for deterministic flow, BYOM via Einstein Studio, Data 360 grounding with vector search, MCP-native development, Voice agents, the three Agentforce pricing models.
  - `database-architect` — Data 360, Zero Copy with Snowflake / Databricks / BigQuery, BYOM data plumbing, Big Objects vs Data 360, calculated insights, sharing-aware data modeling, LDV patterns.
  - `devops-engineer` — `sf` CLI (replaces deprecated `sfdx` alias), scratch orgs, 2GP unlocked / managed packaging, source format, DevOps Center vs Copado / Gearset / AutoRABIT, **smart test selection (Spring '26)**, Agentforce Vibes IDE.
  - `security-engineer` — Einstein Trust Layer (deep architecture), **External Client Apps migration mandate (May 11, 2026)**, **MFA enforcement (phased June–August 2026)**, Shield (Platform Encryption / Event Monitoring / Field Audit Trail), permission sets and PSGs, FLS / CRUD code-layer enforcement (`WITH USER_MODE`), AppExchange Security Review prep.
  - `qa-engineer` — Apex tests with meaningful assertions (≥85% target), bulk path testing, LWC Jest, Salesforce Code Analyzer + Graph Engine for SOQL injection and FLS gap detection, ApexGuru for runtime performance, smart test selection (Spring '26), UTAM / Provar for E2E.
  - `saas-architect` — multi-tenant patterns on the platform, ISV distribution shapes (2GP managed, OEM, Embedded Apps, Internal SaaS), AppExchange Checkout 2.0, Salesforce Marketplace, License Management App.
  - `healthcare-architect` — Health Cloud data model, Industries FHIR R4 + HL7 v2 adapters, OmniStudio for clinical workflows, Agentforce Health agents. Thin overlay — defers to healthcare-architect for HIPAA / FHIR semantics / audit retention policy.
  - `fintech-architect` — Financial Services Cloud data model, MuleSoft Banking Accelerator, Pub/Sub for transaction events, Open Banking adapters, Agentforce Financial Services agents with deterministic money-movement gates. Thin overlay — defers to fintech-architect for ledger / PCI / PSD2 / AML interpretation. Salesforce is NOT the ledger.
- **2025–2026 platform reset captured.** Every overlay reflects the renames, retirements, and additions that an LLM with a pre-2025 cutoff will get wrong: Einstein Copilot → Agentforce (Jan 2025), Data Cloud → Data 360 (Dreamforce '25), Apex Cursors (Spring '26), LWC `lightning/graphql` + TypeScript types (Spring '26), Salesforce-Hosted MCP Servers (GA April 2026), Headless 360 (TDX 2026), External Client Apps mandatory by May 11 2026, MFA mandate phased June–August 2026, Flow Orchestration going free (Feb 2026), Heroku end-of-new-enterprise-sales (Feb 2026), Salesforce Functions retirement (Jan 2025).
- **`STACKS.md`** — top-level registry of available Stack Packs with version, last-verified release, status, and authoring conventions for the next pack.
- **`skills/etyb/core/stack-registry.md`** — ETYB router cue layer for tech-stack detection. Sits alongside `team-registry.md`. Includes positive signals (Salesforce / Apex / LWC / Agentforce / `sfdx` / Trailhead / Dreamforce / TDX / 60+ keywords) and negative signals so migrating *off* a stack doesn't falsely activate the overlay.
- **`manifest.json` `stacks` section** — first-class versioned registration of stacks alongside `skills`, with `last_verified_release`, `verified_on`, and `applies_to_roles` per stack.
- **MARKETPLACE.md Stack Packs section** — new lane in the marketplace copy that introduces Stack Packs alongside the existing 30 skills.

### Changed

- **Single-version semantics.** The bundle version is now THE version. Every skill (30), every stack (1), every artifact tracks it on every release — including `manifest.json .skills.*`, `manifest.json .stacks.*.version`, and every `SKILL.md` frontmatter `metadata.version`. `scripts/maintainer/validate-version-sync.sh` is extended to enforce this; the validator now fails the release if any per-skill or per-stack version drifts from `VERSION`. The 5 historical bundle files (`VERSION`, `package.json`, `manifest.json .bundle.version`, `.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json`) plus all per-artifact locations move together.
- **`skills/etyb/SKILL.md` core modules table** — adds `core/stack-registry.md`. ETYB reads it after `team-registry.md` to detect tech-stack signals and load the matching pack.

### Roadmap

Future Stack Packs on the candidate list, in rough priority order based on common ETYB use cases:

- **AWS** — Bedrock, Lambda, EventBridge, ECS, IAM, S3, RDS / Aurora
- **GCP** — Vertex AI, Cloud Run, Pub/Sub, Firestore, BigQuery
- **Azure** — OpenAI Service, Functions, AKS, Entra ID, Cosmos DB
- **Vercel** — Next.js patterns, Edge Functions, Vercel AI SDK
- **Supabase** — Postgres + Auth + Realtime + Storage + Edge Functions
- **Snowflake** — Warehouse architecture, Native Apps, Cortex
- **Databricks** — Lakehouse, Mosaic AI, Delta Live Tables
- **Stripe** — Payment intents, Billing, Connect, fraud
- **Shopify** — Storefront API, Hydrogen, app development
- **SAP S/4HANA** — Integration patterns, BTP
- **ServiceNow** — Now Platform, Flow Designer, integration patterns

The pattern is set — adding a new stack adds a folder, not a roster slot.

## [2.2.0] — 2026-04-18

The install-parity and hardening release. Bundle-aware installs reach every platform (not just Claude Code's native marketplace), hook scripts get a ShellCheck-clean CI gate, and a JSON-injection bug in the plan-execution edit log is fixed.

### Added

- **Bundle-aware `install.sh`.** New flags `--bundle NAME`, `--skills a,b,c`, and `--list-bundles` bring Codex / Antigravity / manual installs to parity with Claude's plugin marketplace. `--bundle` accepts short (`process-protocols`) and long (`etyb-process-protocols`) forms. Default behaviour (no flag) is unchanged — every skill on disk is installed.
- **Bundle generator** (`scripts/generate-bundles.py`). Reads `.claude-plugin/marketplace.json` and emits `bundles/<plugin>.txt` so `install.sh` stays dependency-free. `--check` mode is wired into CI to enforce that generated manifests never drift from the marketplace definition.
- **CI workflow** (`.github/workflows/ci.yml`). ShellCheck across every `.sh` with no severity exclusions, hook regression tests, bundle drift check, and installer tests — all on every PR and push to main.
- **Regression test for the hook JSON-injection fix** (`tests/hooks/test-post-edit-log-json-escaping.sh`). Fires `post-edit-log.sh` with hostile payloads and asserts the log stays well-formed.
- **Installer tests** (`tests/install/test-install-flags.sh`). Happy paths for each new flag, all three error paths, and one real non-dry-run install to confirm bundles copy exactly the expected directories.

### Fixed

- **Log injection in `post-edit-log.sh`.** The hook previously splatted file paths, task IDs, and plan names straight into a JSON heredoc. A filename containing a quote, backslash, or newline corrupted `edit-log.jsonl` or let an attacker forge log entries. Fields are now JSON-escaped before write. Flagged as High Risk by Gen on skills.sh; Socket and Snyk had passed.
- **`pre-commit-review-check.sh` failed to parse.** Two `if` blocks were closed with `done` instead of `fi`. With `set -euo pipefail` at the top the script errored on every invocation — meaning the pre-commit review reminder never fired since it shipped.
- **Silent glob shadowing in `pre-edit-check.sh`.** Earlier glob patterns in the config-file skip list (`*.config.*`, `*.mod`, `*.sum`) shadowed later explicit entries (`jest.config.*`, `vitest.config.*`, `go.mod`, `go.sum`). Collapsed into a single arm that reflects real coverage.
- **Unquoted pattern expansion** in `post-edit-log.sh`'s `${FILE_PATH#$PROJECT_ROOT/}` — stripping failed when the path contained glob metacharacters.
- **Version drift.** `.claude-plugin/marketplace.json` and `.claude-plugin/plugin.json` had been stuck at `2.0.0` through the `2.1.0` release; skill counts said "31" in two places and "30" elsewhere. All version fields now track `VERSION` and all skill counts read `30`.

### Changed

- **Docs updated.** README and `docs/installation.md` document the new `--bundle`, `--skills`, `--list-bundles` flags and list the four bundles (`full`, `process-protocols`, `core-team`, `verticals`) with skill counts.
- **`install-codex-runtime.sh` cleanup.** Dropped an unused `FORCE` variable; `--force` effect is carried by `ON_CONFLICT="replace"` alone.

## [2.1.0] — 2026-04-16

The Codex runtime release. ETYB now ships with full OpenAI Codex runtime support — lifecycle hooks, custom agents, and per-skill metadata — upgrading Codex from model-trusted to partial runtime-enforced.

### Added

- **Codex lifecycle hooks** (`.codex/hooks/`). 4 Python hooks — `UserPromptSubmit` (blocks gate-skipping prompts), `PreToolUse` (guards merge/commit without tests), `PostToolUse` (captures test pass/fail signals), `Stop` (blocks completion claims without verification evidence).
- **Codex custom agents** (`.codex/agents/`). 4 TOML-defined agents — explorer, planner, reviewer, docs researcher — providing Codex-native parallel dispatch.
- **Per-skill Codex metadata** (`agents/openai.yaml`). All 30 skills now ship with `interface` + `policy` metadata for Codex skill discovery.
- **Codex runtime installer** (`scripts/install-codex-runtime.sh`). Installs `.codex/` config, hooks, and agents into any project with conflict detection and backup.
- **Codex runtime evals** (`skills/etyb/evals/codex-runtime-evals.json`). Eval suite for verifying hook behavior on a real Codex instance.
- **Portability linter** (`scripts/lint-portability.sh`). Cross-platform compliance checker — validates skill count, Codex metadata, plan path portability, and doc consistency.

### Changed

- **Codex enforcement upgraded.** Platform status changed from "model-trusted" to "partial runtime-enforced + model-trusted gaps." Edit-before-test remains model-trusted; all other gates now have hook support.
- **README overhauled.** OG image banner, platform badges, dedicated platform support table, restructured install section with Codex runtime details.
- **`.gitignore` updated.** Added `.etyb/` (runtime plan artifacts) and `__pycache__/` (Codex hook bytecode).

## [2.0.0] — 2026-04-15

The portability release. ETYB is now a cross-platform virtual engineering team with adapters for Claude Code, OpenAI Codex, and Google Antigravity. Skills are reorganized for independent use on any agentskills.io-compliant platform.

### Breaking

- **`orchestrator` skill renamed to `etyb`.** The folder moved from `skills/orchestrator/` to `skills/etyb/`. Any code or prompts invoking the old name must be updated. Motivation: the skill IS the product brand — one name across marketplace, repo, invocation.
- **`etyb/references/verification-protocol.md` → `skills/verification-protocol/`.** Verification is now its own peer skill. Specialists that referenced the old path have been updated; external references need to update to `skills/verification-protocol/references/verification-methodology.md`.
- **`etyb/references/debugging-protocol.md` → `skills/debugging-protocol/`.** Same pattern as verification.
- **Installable skill count: 28 → 30.** Two new peer protocol skills (verification-protocol, debugging-protocol) extracted from etyb's references.

### Added

- **Portable core architecture.** `skills/etyb/SKILL.md` is now a 65-line thin entry point pointing at eight focused core modules (`core/charter.md`, `team-registry.md`, `gates.md`, `expert-mandating.md`, `coordination-patterns.md`, `response-formats.md`, `scale-calibration.md`, `always-on-protocols.md`). Core modules are platform-neutral and loadable on demand.
- **Claude Code adapter** (`skills/etyb/adapters/claude/`) — ADAPTER.md, hooks.md, plan-mode.md, subagents.md. Deterministic hook enforcement; flagship experience.
- **OpenAI Codex adapter** (`skills/etyb/adapters/codex/`) — ADAPTER.md, enforcement-notes.md, openai-yaml-example.md. Grounded in the current Codex skill model.
- **Google Antigravity adapter** (`skills/etyb/adapters/antigravity/`) — ADAPTER.md, enforcement-notes.md, adk-integration.md. Markdown-first, model-trusted, with ADK documented as a future path.
- **`verification-protocol` skill** — the Five Verification Questions, universal completion report, done criteria per gate, evidence standards. Independently installable.
- **`debugging-protocol` skill** — root-cause-first methodology, hypothesis-driven debugging, one-variable rule, three-failure escalation. Independently installable.
- **`VERSION` file, `manifest.json`, `CHANGELOG.md`** at repo root for versioning and update-mechanism infrastructure.

### Changed

- **Bundle name/brand alignment.** Plugin descriptions, marketplace configs, README, CLAUDE.md, architecture.md, and all cross-references now use "ETYB" as the brand name.
- **Frontmatter compliance.** All 30 SKILL.md files validated against the agentskills.io specification — name (lowercase+hyphens, matches parent dir), description (≤1024 chars), compatibility (≤500 chars where present).
- **Specialists are standalone.** Every specialist now works without etyb installed. References to etyb are supplemental cross-references, not hard dependencies. The invariant "uninstall etyb → specialists still function" holds.
- **Counts updated across docs.** 30 total installable skills, 9 process protocols (was 7), 1 reference remaining in etyb (was 3 — two extracted as peer skills).

### Migration Notes

If you had `skills/orchestrator/` installed:
1. `git pull` (or reinstall via your marketplace tool of choice) — the rename is a `git mv` so history is preserved.
2. Update any prompts or scripts invoking `orchestrator` to use `etyb` instead.
3. If you had custom references to `skills/etyb/references/verification-protocol.md` or `skills/etyb/references/debugging-protocol.md`, update them to `skills/verification-protocol/references/verification-methodology.md` and `skills/debugging-protocol/references/debugging-methodology.md`.

## [1.0.0] — 2026-04-14

### Added

- Initial release: 28 installable AI agent skills organized as a virtual engineering company — 1 orchestrator, 14 core teams, 6 domain specialists, 7 process protocols, plus 3 orchestrator references.
