# Stack Registry — Tech Stack Detection

This is the routing layer for **Stack Packs** — knowledge overlays that load when work involves a specific tech stack (Salesforce, AWS, SAP, etc.). Read this after `team-registry.md` whenever you're routing a request.

Stack Packs are not new specialists. They are context overlays applied across the existing 20 specialists. See `STACKS.md` at the repo root for the registry of available stacks and the authoring conventions; this file is the detection/loading layer used by ETYB at runtime.

## Detection workflow

1. **After classifying the request tier** (per `charter.md`) and identifying which specialist(s) to route to (per `team-registry.md`), scan the user's request for stack signals using the tables below.
2. **On a match,** load the stack's `SKILL.md` (orchestrator briefing — applies to the whole team).
3. **When you dispatch to a specific role,** also load `stacks/<stack>/references/<role>.md` if one exists. The role uses the overlay *in addition to* its own SKILL.md, not in place of it.
4. **Multiple stacks may match.** Load all matching SKILL.md briefings; load the appropriate per-role reference from each. They compose — each pack handles its own platform-side, neither pretends to know the other.
5. **If a stack signal matches but the corresponding role overlay does not exist yet,** proceed with the role's general knowledge plus the stack SKILL.md context; tell the user explicitly that the role-specific overlay is a gap in the current Stack Pack version.

## Composition with protocols and verticals

Stack Packs do **not** relax the 9 always-on protocols. TDD, verification, debugging, review, plan execution, brainstorm-first, branch safety, subagent coordination, self-improvement, debugging — all apply unchanged. Stack Packs shape *how* the protocols are applied on a specific platform (e.g., TDD on Apex uses Apex test classes; TDD on LWC uses Jest).

Stack Packs **defer to business-domain verticals** for compliance and domain expertise. When Salesforce Health Cloud work appears, the Salesforce pack covers the platform surface (Health Cloud data model, OmniStudio templates, FSC/Health Cloud Industries opinions); `healthcare-architect` covers HIPAA, FHIR, audit-trail discipline. Don't restate domain compliance from a Stack Pack.

## Active Stack Packs

### Salesforce (`stacks/salesforce/`)

**Pack:** [`stacks/salesforce/SKILL.md`](../../../stacks/salesforce/SKILL.md)
**Version:** 1.1.0
**Last verified release:** Spring '26
**Per-role overlays available:** system-architect, backend-architect, frontend-architect, ai-ml-engineer, database-architect, devops-engineer, security-engineer, qa-engineer, saas-architect, healthcare-architect, fintech-architect (full coverage)
**Per-role overlays deferred:** _none_ — all 11 roles have overlays

**Detection signals** (case-insensitive; match anywhere in user's message):

| Signal type | Keywords / patterns |
|-------------|---------------------|
| Product names | salesforce, sfdc, sales cloud, service cloud, marketing cloud, commerce cloud, experience cloud, health cloud, financial services cloud, fsc, manufacturing cloud, public sector solutions, data 360, data cloud, tableau (when adjacent to Salesforce/Data 360 context), slack (when adjacent to Salesforce context) |
| Platform features | agentforce, einstein, atlas reasoning, trust layer, einstein trust layer, model gateway, prompt builder, agent script, agentforce vibes, agentforce builder, hyperforce |
| Development surfaces | apex, lwc, lightning web component, lightning, visualforce, aura, flow builder, flow orchestration, omnistudio, omniscript, integration procedure, data mapper, dataraptor |
| Data layer | soql, sosl, sobject, custom object, picklist, lookup, master-detail, big object, salesforce connect, external object, zero copy |
| Integration | pub/sub api, platform event, change data capture, cdc, named credential, external credential, external client app, eca, connected app, mulesoft, anypoint |
| Tooling | sf cli, sfdx, salesforce cli, scratch org, sandbox, unlocked package, 2gp, managed package, devops center, copado, gearset, autorabit, code analyzer, apex guru, apexguru, lwc jest, salesforce code analyzer |
| Compute (legacy) | heroku (when adjacent to Salesforce context), salesforce functions |
| Ecosystem | appexchange, agentexchange, trailhead, trailblazer, dreamforce, tdx, trailblazerdx |
| Roles / certs | salesforce admin, salesforce architect, ctas, certified technical architect, agentforce specialist, platform developer (when adjacent to Salesforce) |

**Negative signals** — DO NOT activate the pack when these dominate without Salesforce context:
- "Salesforce" used as a generic synonym for "CRM" without specific platform mention (rare but happens)
- Generic "lightning" references not about Salesforce (Bitcoin Lightning Network, Lightning McQueen, etc.)
- Generic "flow" without "builder" / "orchestration" / Salesforce neighborhood
- "Apex" used in non-Salesforce context (Apex Legends, Apex programming language references in academic context)
- Pure Slack / Tableau questions with no Salesforce platform involvement (those may get their own packs eventually)

When the signal is ambiguous, **ask** before loading the pack — loading it on a non-Salesforce request will inject 1000+ lines of Salesforce-specific guidance that distorts your response.

## Authoring a new entry

When a new Stack Pack ships, add a section under "Active Stack Packs" above. Required fields:

- **Pack** — path to the SKILL.md
- **Last verified release** — what platform release the content is current to
- **Per-role overlays available** — list role names with reference files
- **Per-role overlays deferred** — roles where the pack hasn't yet added an overlay
- **Detection signals** — positive signals (product names, features, surfaces, tooling, ecosystem)
- **Negative signals** — disambiguation cases where a positive keyword appears outside the stack's actual context

Stack registration in `manifest.json` is the source of truth for installed stacks; this file is the *router's view* of how to load and detect them at runtime.
