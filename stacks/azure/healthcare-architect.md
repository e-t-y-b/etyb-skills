---
title: Healthcare Architect on Azure
description: Thin overlay — Azure Health Data Services (FHIR/DICOM/MedTech), HIPAA-eligible service inventory, Confidential Computing for PHI, Purview classification. Routes to healthcare-architect specialist for HIPAA / FHIR semantics.
role_overlay:
  role: healthcare-architect
  stack: azure
  last_verified_on: "2026-05-14"
  products_covered:
    - microsoft-purview
    - key-vault
    - entra-id
    - entra-external-id
    - defender-for-cloud
    - sentinel
    - cosmos-db
    - azure-sql
    - postgresql-flexible-server
    - storage-account
---

## Role briefing

**This is a thin overlay.** It teaches the Azure-side mechanisms for healthcare workloads: Azure Health Data Services (FHIR R4 + DICOM + MedTech), HIPAA-eligible service inventory, Confidential Computing for PHI, Purview classification for PHI. The **healthcare-architect specialist (without this overlay) owns HIPAA / HITRUST / FHIR semantics / audit discipline / BAA workflow.** Don't restate compliance content here — route to the specialist.

## Decision frameworks specific to this role's lens on Azure

### Azure Health Data Services

GA 2022, evolving. Unified platform for healthcare data:

| Service | Purpose |
|---------|---------|
| **FHIR service** | FHIR R4 API + storage (replaces retired Azure API for FHIR) |
| **DICOM service** | DICOMweb + DIMSE for medical imaging |
| **MedTech service** | IoMT device data normalization → FHIR resources |
| **De-identification service** (preview / GA) | HIPAA Safe Harbor de-id of FHIR / unstructured text |

**Azure API for FHIR is retired** — migrate to Health Data Services FHIR service.

Patterns:

- IoT device → IoT Hub → MedTech → FHIR
- DICOM modality → DICOM service (DIMSE) → Blob storage
- EHR integration → HL7 v2 → MedTech transformation → FHIR
- App reads via FHIR service REST API (auth via Entra)

### HIPAA-eligible services

**Not every Azure service is HIPAA-eligible.** Per-service per-region eligibility is published in [Microsoft Trust Center HIPAA documentation](https://learn.microsoft.com/compliance/regulatory/offering-hipaa-hitech).

Standard healthcare-on-Azure stack:

- Compute: [AKS](/stacks/azure/aks/), [Container Apps](/stacks/azure/container-apps/), [Functions](/stacks/azure/functions/), [App Service](/stacks/azure/app-service/), [VMs](/stacks/azure/virtual-machines/) (in HIPAA-eligible regions)
- Data: [Cosmos DB](/stacks/azure/cosmos-db/), [Azure SQL](/stacks/azure/azure-sql/), [PostgreSQL Flex](/stacks/azure/postgresql-flexible-server/), [Storage Account](/stacks/azure/storage-account/) (Blob, ADLS Gen2)
- Health-specific: Health Data Services (FHIR / DICOM / MedTech)
- Identity: [Entra ID](/stacks/azure/entra-id/) + [Entra External ID](/stacks/azure/entra-external-id/) for patient portals (with BAA scope)
- Secrets: [Key Vault](/stacks/azure/key-vault/) + Managed HSM (Managed HSM for highest-sensitivity keys)
- Monitoring: [Azure Monitor](/stacks/azure/azure-monitor/) / [Log Analytics](/stacks/azure/log-analytics/) (with PHI handling considerations)
- Security: [Defender for Cloud](/stacks/azure/defender-for-cloud/), [Sentinel](/stacks/azure/sentinel/) (with PHI handling)

**Critical: sign Microsoft BAA.** Online Services BAA covers HIPAA-eligible services. Confirm BAA execution + scope before processing PHI.

**Anti-pattern: assuming all Azure services are HIPAA-eligible.** Verify per service.

### Confidential Computing for PHI

When threat model requires that even Microsoft can't see PHI in use:

- **DCsv3 / DCsv5** (Intel SGX) or **DCadsv5 / ECadsv5** (AMD SEV-SNP) VMs
- **Confidential Containers on AKS**
- **Azure Attestation**

Use cases:

- Federated learning across health systems
- Privacy-preserving analytics on patient records
- Confidential AI inference (model + data isolated from host OS)

**Anti-pattern: Confidential Computing where standard encryption-at-rest + Managed Identity suffice.** Most healthcare workloads use standard managed services with appropriate encryption + access controls; Confidential Computing is for specific threat models.

### PHI data handling patterns

- **Encryption at rest**: default for all managed services + CMK from Key Vault / Managed HSM for highest sensitivity.
- **Encryption in transit**: TLS 1.2+ everywhere; TLS 1.3 where supported.
- **Encryption in use**: Confidential Computing where threat model demands.
- **Access controls**: Entra ID with PIM for admin; least-privilege RBAC; Conditional Access requiring compliant device + phishing-resistant MFA.
- **Audit logging**: every PHI access logged with user + time + record + reason; retained per HIPAA (6 years typical).
- **De-identification**: De-identification service for use cases not needing re-identification.

### Purview classification for PHI

[Purview](/stacks/azure/microsoft-purview/) classifies PHI in data stores automatically. Built-in: SSN, MRN, ICD codes, patient name + DOB combinations. Custom: org-specific patterns. Lineage tracking. DLP policies block exfiltration.

**Pattern**: classify before encrypting. Purview discovers PHI; sensitivity labels applied; DLP enforces.

### Patient consent + data minimization

- **Consent management**: FHIR Consent resource for granular capture.
- **Data minimization**: collect / store / share only what's necessary.
- **Right to access / delete (GDPR / state laws)**: app must support patient data export + deletion.
- **De-identification**: per HIPAA Safe Harbor (18 identifiers removed) or Expert Determination.

### Telehealth + video

- **Azure Communication Services** — HIPAA-eligible (in BAA scope) for voice / video / messaging.
- Custom telehealth on Azure vs Teams for Healthcare vs third-party — decision per requirements.

## 2025-2026 platform-reset items relevant to this role

- **Azure API for FHIR retired** — migrate to Health Data Services FHIR service.
- **Health Data Services De-identification service** — HIPAA Safe Harbor de-id built-in.
- **DICOM service** — DICOMweb + DIMSE.
- **MedTech service** — IoMT normalization to FHIR.
- **Purview PHI classification** — better built-in classifiers.
- **Defender for Cloud regulatory compliance initiatives** — HIPAA HITRUST current.
- **Entra External ID for patient portals** — replaces B2C.
- **Azure Communication Services HIPAA eligibility** for telehealth.

## Patterns the role applies

### Pattern: Health Data Services FHIR as the patient record API

Don't roll your own FHIR. Managed service handles search, history, semantics, `_includes`, conditional ops.

### Pattern: MedTech for IoMT ingestion

Devices → IoT Hub → MedTech (normalization rules) → FHIR Observation. Don't write the normalization pipeline.

### Pattern: DICOM service for imaging

DICOMweb-compliant; integrates with PACS. Store + retrieve + query studies.

### Pattern: Purview classify + Defender sensitive data discovery

Two surfaces, same data. Purview is broader; Defender CSPM Premium adds attack-path-aware findings.

### Pattern: Confidential Computing for federated learning

Multiple health systems train joint model; data never leaves provider, even to Microsoft. Attestation guarantees TEE isolation.

### Anti-pattern: building custom FHIR on Cosmos / SQL

Health Data Services FHIR is the right answer.

### Anti-pattern: assuming all Azure services are HIPAA-eligible

### Anti-pattern: PHI in unclassified data stores

### Anti-pattern: BAA not signed before processing PHI

### Anti-pattern: PHI in App Insights / Log Analytics without redaction

Redact at app layer; Purview classification on logs as defense in depth.

## When to escalate to the specialist (healthcare-architect, no overlay)

- HIPAA control mapping + evidence collection
- HITRUST certification scope + roadmap
- FHIR R4 profile design (US Core, IPS, specific implementation guides)
- FHIR resource modeling specifics (Patient, Encounter, Observation, Condition)
- HL7 v2 → FHIR mapping semantics
- DICOM workflow specifics (modality worklist, structured reports)
- ICD / SNOMED / LOINC code system handling
- HIPAA breach notification workflow
- GDPR / state law (CCPA, etc.) data subject rights workflow

## Cross-references

- [System Architect on Azure](/stacks/azure/system-architect/) — overall topology
- [Security Engineer on Azure](/stacks/azure/security-engineer/) — HIPAA-eligible controls
- [Database Architect on Azure](/stacks/azure/database-architect/) — FHIR data design
- [AI/ML Engineer on Azure](/stacks/azure/ai-ml-engineer/) — Confidential AI for PHI inference
- [Azure Stack index](/stacks/azure/)
- [Azure Health Data Services](https://learn.microsoft.com/azure/healthcare-apis/healthcare-apis-overview)
- [HIPAA on Azure](https://learn.microsoft.com/compliance/regulatory/offering-hipaa-hitech)
- [Microsoft Trust Center](https://www.microsoft.com/trust-center)
