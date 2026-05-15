---
title: Health Cloud
description: Salesforce's healthcare industries cloud. Rebranded Agentforce Health (Dreamforce '25). FHIR R4 + HL7 v2 adapters, OmniStudio templates, pre-built agents.
product:
  name: Health Cloud
  stack: salesforce
  drift_risk: low
  last_verified_on: "2026-05-12"
  applies_to_roles: [healthcare-architect, system-architect, database-architect, ai-ml-engineer, security-engineer]
  authoritative_url: https://help.salesforce.com/s/articleView?id=sf.health_cloud.htm
  notes: "Data model stable; FHIR R4 + HL7 v2 adapters configurable through Setup; rebrand to Agentforce Health (Dreamforce '25) is naming, not capability."
---

<div class="etyb-currency-banner">Last verified: 2026-05-12 against Salesforce Spring '26, Dreamforce '25.</div>

## What it is

Health Cloud is Salesforce's healthcare Industries cloud, extending standard Salesforce objects with a healthcare-specific schema (Patient, Practitioner, CarePlan, Encounter, Coverage, etc.) plus FHIR/HL7 adapters and OmniStudio clinical workflow templates. As of Dreamforce '25 it is rebranded **Agentforce Health** in the Agentforce-1-Editions lineup with pre-built care management, patient outreach, member services, and prior authorization agents.

Canonical reference: [Health Cloud documentation](https://help.salesforce.com/s/articleView?id=sf.health_cloud.htm).

## When to use it

For any Salesforce build serving healthcare workflows — providers, payers, life sciences, care management. **Do not** model patients as custom `Patient__c` objects when Health Cloud exists; fighting the data model breaks shipped Flows/OmniScripts/agents and fails Security Review.

## 2025-2026 currency anchors

- **Health Cloud → Agentforce Health** branding (Dreamforce '25). Same underlying data model and Industries cloud; SKU bundled into Agentforce-1-Editions with pre-built Health agents.
- **OmniStudio standard designers built-in** to platform Setup (no separate managed package for new orgs). **DataRaptor → Data Mapper**.
- **Industries data adapters consolidated** — FHIR R4 and HL7 v2 adapters first-class, configurable through Setup rather than ad-hoc Apex.
- **Pre-built Agentforce Health agents** ship for care management, patient outreach, member services, prior authorization.
- **Industries cloud opinions intensified** — custom objects for clinical concepts are now an anti-pattern; Security Review for ISVs enforces this more strictly.
- **Hyperforce regional residency** is the default story for in-country PHI.

## Health Cloud data model

These are the platform's nouns. Map FHIR resources to these; map EHR exports to these; OmniScripts read/write these.

**Person / provider / facility:**
- **Patient** — record type on Account (Person Account model)
- **Practitioner** / **PractitionerFacilityRelationship**
- **HealthcareFacility** / **HealthcareFacilityNetwork** — use Network for cross-facility data sharing; don't invent custom relationships
- **HealthcareProvider** / **HealthcareProviderTaxonomy** — credentialing, NPI, specialty taxonomy

**Care planning:**
- **CarePlan** / **CarePlanGoal** / **CarePlanProblem**
- **CarePlanTemplate** / **CarePlanTemplateProblem**

**Clinical events:**
- **Encounter** / **EncounterParticipant**
- **ServiceRequest** — referrals, orders
- **Procedure**
- **Medication** / **PatientMedicationDosage** / **MedicationStatement**
- **Observation** — labs, vitals, clinical findings

**Coverage / member:**
- **Coverage** / **CoverageBenefit**
- **MemberPlan**

## FHIR R4 ↔ Health Cloud mapping spine

| FHIR R4 Resource | Health Cloud Object |
|------------------|---------------------|
| `Patient` | Account (Patient record type) + Contact |
| `Practitioner` | Practitioner |
| `PractitionerRole` | PractitionerFacilityRelationship |
| `Organization` (facility) | HealthcareFacility |
| `Encounter` | Encounter + EncounterParticipant |
| `Condition` | CarePlanProblem (or HealthCondition where used) |
| `CarePlan` | CarePlan + CarePlanGoal + CarePlanProblem |
| `ServiceRequest` | ServiceRequest |
| `Procedure` | Procedure |
| `Observation` | Observation |
| `MedicationRequest` / `MedicationStatement` | PatientMedicationDosage / MedicationStatement |
| `Coverage` | Coverage + CoverageBenefit + MemberPlan |

Use as a starting point; confirm against your own FHIR resource profiles.

## Patterns

### Industries data adapters

- **FHIR R4 adapter** (default Spring '26) — inbound/outbound flows configurable through Setup. Maps FHIR resources via **Data Mapper** Extract/Transform/Load configurations. R5 on the roadmap.
- **HL7 v2 adapter** — legacy ADT/ORM/ORU/SIU/DFT messaging for EHR estates. Pair with MuleSoft Anypoint Healthcare Accelerators.
- **Data Mapper** is the declarative mapping layer for both adapters and for OmniStudio. Version mapping configurations in source control via Industries metadata API.

**Do not** write Apex parsing raw FHIR JSON or HL7 pipe-delimited messages when an adapter + Data Mapper can do it declaratively.

### OmniStudio for clinical workflows

- **OmniScripts** — multi-step guided flows. Standard FSC scripts: intake, care plan creation, prior authorization, benefit verification. Configure first; build custom only when no shipped template fits.
- **FlexCards** — compact patient context displays (allergies, recent encounters, open care plans).
- **Integration Procedures** — server-side orchestration. The right place to compose FHIR query + Salesforce DML + external callout in a single declarative unit.
- **Data Mapper** — declarative read/write between Salesforce objects, external sources, and OmniScript variables.

Typical patient-intake OmniScript anatomy (6 steps: Demographics → Insurance → Clinical Intake → Consent → Schedule → Confirmation). Each step is declarative; Integration Procedures handle the "code-like" composition.

### Agentforce Health agents

Pre-built agents grounded on Health Cloud data, routed through [Einstein Trust Layer](/stacks/salesforce/einstein-trust-layer/):

- **Care management agents** — care plan adjustments, follow-up scheduling, gap-in-care alerts
- **Patient outreach agents** — preventive care reminders, appointment booking, post-discharge check-ins
- **Member services agents** — benefit lookups, coverage explanation, claim-status inquiries
- **Prior authorization agents** — pre-auth workflow, payer back-and-forth

**Customization pattern:** start from a shipped agent, customize Topics/Actions, add grounding from Data 360. Don't build from scratch.

**Mandatory:** Trust Layer masking for PHI. Re-verify masking after every Topic / Action / grounding-source change.

### Integration patterns

- **FHIR R4 inbound/outbound** — Industries adapter + Data Mapper. Default for modern EHR integration.
- **HL7 v2** — Industries adapter for legacy ADT/ORM/ORU/SIU/DFT messaging.
- **MuleSoft Anypoint Healthcare Accelerators** — pre-built HL7/FHIR connectors, EHR-specific templates (Epic, Cerner/Oracle Health, MEDITECH, Athenahealth).
- **SMART on FHIR** — embed provider-facing Salesforce experiences inside an EHR's launch context.
- **Bulk FHIR (`$export`)** — population-scale ingest (HEDIS reporting, care-gap analytics). Land in Data 360 / clinical data lake first.

## Salesforce-specific compliance hooks

(Platform features the org's HIPAA posture rides on. Interpretation belongs to your healthcare-architect core skill.)

- **Shield Platform Encryption** for PHI at rest — deterministic where filtering needed (MRN lookups), probabilistic elsewhere
- **Field Audit Trail** — 10-year retention for clinical and coverage fields
- **Event Monitoring** — HIPAA-required audit logs; stream to SIEM
- **Einstein Trust Layer masking** — mandatory for any agent flow touching PHI
- **Hyperforce regional residency** — in-country PHI; confirm the org is on Hyperforce in the right region
- **Salesforce BAA** — confirm which products in your architecture are BAA-covered

## Anti-patterns

- **Custom `Patient__c` object instead of Person Account + Patient record type.** Fights the data model, breaks shipped OmniScripts/agents, fails Security Review for ISVs. Hardest mistake to unwind.
- **Custom OmniScripts where shipped templates exist.** Customize, don't rebuild.
- **Ignoring Industries data adapters; re-implementing FHIR parsing in Apex.** Brittle, hard to maintain, no declarative observability.
- **Storing PHI in free-text fields not declared for encryption / FAT.** Audit free-text fields explicitly.
- **Building cross-facility data sharing without HealthcareFacilityNetwork.** The network object exists.
- **Big-bang FHIR migration.** Migrate incrementally per resource type via the adapter.
- **Skipping Trust Layer masking for Agentforce Health agents.** Not optional, not best-effort.
- **Sandbox seeded with production PHI without obfuscation.** Use Data Mask on every refresh.
- **Permission-set stacking** instead of Permission Set Groups + Muting Permission Sets.

## Gotchas

- **Observations are unbounded.** Continuous-monitoring devices generate millions per patient per year. Project only operationally relevant Observations; keep the rest in Data 360 / clinical data lake.
- **Encounter history** for chronic-care populations breaks naive list views — use indexed fields, large-data-volume design.
- **Event Monitoring volume** in healthcare is high. Plan SIEM ingest cost up-front.
- **Agentforce action throughput** is bounded by Apex governor limits AND Trust Layer rate limits. Population-scale agent fan-out needs Pub/Sub or MuleSoft fronting.
- **Encrypted fields must be declared in Setup** — retrofitting requires a mass re-encrypt cycle.
- **HIPAA interpretation does not live here.** Defer to healthcare-architect core; this product page is the platform map.

## Cross-references

- Healthcare-on-Salesforce depth: [healthcare-architect on Salesforce](/stacks/salesforce/healthcare-architect/)
- Agent design: [Agentforce](/stacks/salesforce/agentforce/), [ai-ml-engineer on Salesforce](/stacks/salesforce/ai-ml-engineer/)
- Trust Layer: [Einstein Trust Layer](/stacks/salesforce/einstein-trust-layer/)
- Encryption + audit: [security-engineer on Salesforce](/stacks/salesforce/security-engineer/)
- Data 360 for clinical analytics: [Data 360](/stacks/salesforce/data-360/), [database-architect on Salesforce](/stacks/salesforce/database-architect/)
- Authoritative: [Health Cloud documentation](https://help.salesforce.com/s/articleView?id=sf.health_cloud.htm)
