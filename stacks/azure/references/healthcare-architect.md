---
role: healthcare-architect
stack: azure
last_verified_on: "2026-05-14"
---

# Azure — healthcare-architect overlay

**This is a thin overlay.** It teaches the Azure-side mechanisms for healthcare workloads: Azure Health Data Services (FHIR R4 + DICOM + MedTech), HIPAA-eligible service inventory, Confidential Computing for PHI, Purview classification for PHI. The **healthcare-architect specialist (without this overlay) owns HIPAA / HITRUST / FHIR semantics / audit discipline / BAA workflow.** Don't restate compliance content from this overlay — route to the specialist.

## What this role does on Azure

- Picks the **right Azure healthcare services** (Health Data Services, Confidential Computing, etc.).
- Verifies **HIPAA-eligible service inventory** + **BAA scope**.
- Designs **PHI data flow** with encryption at rest + in transit + in use (Confidential Computing where required).
- Designs **FHIR R4** integration via Health Data Services FHIR service.
- Designs **DICOM** integration via Health Data Services DICOM service.
- Designs **HL7 v2 + IoMT ingestion** via MedTech connector.
- Implements **audit logging** to compliance-grade retention.
- Implements **Purview classification** for PHI discovery + DLP.
- Designs **patient consent** + **data minimization** patterns.

## Decision frameworks

### Azure Health Data Services

GA 2022, evolving. Unified platform for healthcare data:

| Service | Purpose |
|---------|---------|
| **FHIR service** | FHIR R4 API + storage (replaces retired Azure API for FHIR) |
| **DICOM service** | DICOMweb + DIMSE for medical imaging |
| **MedTech service** | IoMT device data normalization → FHIR resources |
| **De-identification service** (preview / GA) | HIPAA Safe Harbor de-id of FHIR / unstructured text |

**Azure API for FHIR (retired)** — migrate to Health Data Services FHIR service.

**Patterns**:

- IoT device → IoT Hub → MedTech → FHIR
- DICOM modality → DICOM service (DIMSE protocol) → Blob storage
- EHR integration → HL7 v2 → MedTech transformation → FHIR
- App reads via FHIR service REST API (auth via Entra)

Cite: [Azure Health Data Services](https://learn.microsoft.com/azure/healthcare-apis/healthcare-apis-overview).

### HIPAA-eligible services

**Not every Azure service is HIPAA-eligible.** Per-service per-region eligibility is published in [Microsoft Trust Center HIPAA documentation](https://learn.microsoft.com/compliance/regulatory/offering-hipaa-hitech).

Standard healthcare-on-Azure service stack:

- Compute: AKS, Container Apps, Functions, App Service, VMs (in HIPAA-eligible regions)
- Data: Cosmos DB, Azure SQL, PostgreSQL Flex, Blob, ADLS Gen2
- Health-specific: Health Data Services (FHIR / DICOM / MedTech)
- Identity: Entra ID + Entra External ID for patient portals (with BAA scope)
- Secrets: Key Vault + Managed HSM (Managed HSM for highest-sensitivity keys)
- Monitoring: Azure Monitor / Log Analytics (with PHI handling considerations)
- Security: Defender for Cloud, Sentinel (with appropriate data handling)

**Critical: sign Microsoft BAA**. The Online Services BAA covers HIPAA-eligible services. Confirm BAA execution + scope before processing PHI.

**Anti-pattern: assuming all Azure services are HIPAA-eligible**. Verify per service.

### Confidential Computing for PHI

When threat model requires that even Microsoft can't see PHI in use:

- **DCsv3 / DCsv5** (Intel SGX) or **DCadsv5 / ECadsv5** (AMD SEV-SNP) VMs
- **Confidential Containers on AKS** — encrypted containers
- **Azure Attestation** — verify TEE state

Use cases:

- Federated learning across health systems (data never leaves provider, even to Microsoft)
- Privacy-preserving analytics on patient records
- Confidential AI inference (model + data isolated from host OS)

**Anti-pattern: Confidential Computing where standard encryption-at-rest + Managed Identity suffice.** Most healthcare workloads use standard managed services with appropriate encryption + access controls; Confidential Computing is for specific threat models.

### PHI data handling patterns

- **Encryption at rest**: default for all Azure managed services + CMK from Key Vault / Managed HSM for highest sensitivity.
- **Encryption in transit**: TLS 1.2+ everywhere; TLS 1.3 where supported.
- **Encryption in use**: Confidential Computing where threat model demands.
- **Access controls**: Entra ID with PIM for admin access to PHI systems; least-privilege RBAC; Conditional Access requiring compliant device + phishing-resistant MFA.
- **Audit logging**: every PHI access logged with user + time + record + reason; retained per HIPAA (6 years typical).
- **De-identification**: De-identification service for use cases that don't need re-identification.

### Purview classification for PHI

Purview classifies PHI in your data stores automatically:

- Built-in classifications: SSN, MRN, ICD codes, patient name + DOB combinations
- Custom classifications: org-specific PHI patterns
- Lineage tracking: where did PHI originate + flow
- DLP policies: block exfiltration of PHI

**Pattern**: classify before encrypting. Purview discovers PHI; sensitivity labels applied; DLP enforces.

### Patient consent + data minimization

- **Consent management**: FHIR Consent resource for granular consent capture.
- **Data minimization**: collect / store / share only what's necessary for the use case.
- **Right to access / delete (GDPR / state laws)**: app must support patient data export + deletion.
- **De-identification**: for analytics / research, de-identify per HIPAA Safe Harbor (18 identifiers removed) or Expert Determination.

### Telehealth + video

- **Azure Communication Services** — HIPAA-eligible (in scope BAA) for voice / video / messaging.
- **Custom telehealth on Azure** vs Teams for Healthcare vs third-party (Doxy.me, etc.) — decision per requirements.

## 2025-2026 platform reset items relevant to this role

- **Azure API for FHIR retired** — migrate to Health Data Services FHIR service.
- **Health Data Services De-identification service** — built-in HIPAA Safe Harbor de-id (GA / preview status varies).
- **DICOM service** (Health Data Services) — DICOMweb + DIMSE.
- **MedTech service** — IoMT normalization to FHIR.
- **Purview PHI classification** — better built-in classifiers.
- **Defender for Cloud regulatory compliance initiatives** — HIPAA HITRUST initiative current.
- **Entra External ID for patient portals** — replaces B2C for new patient-facing apps.
- **Azure Communication Services HIPAA eligibility** for telehealth.

## Patterns and anti-patterns

### Pattern: Health Data Services FHIR as the patient record API

Don't roll your own FHIR. Use the managed service. It handles search, history, FHIR semantics, _includes, conditional ops.

### Pattern: MedTech for IoMT ingestion

Devices → IoT Hub → MedTech (normalization rules) → FHIR Observation resources. Don't write the normalization pipeline yourself.

### Pattern: DICOM service for imaging

DICOMweb-compliant; integrates with PACS systems. Store + retrieve + query studies.

### Pattern: Purview classify + Defender sensitive data discovery

Two surfaces, same data. Purview is broader (classification + lineage + DLP); Defender CSPM Premium adds attack-path-aware sensitive data findings.

### Pattern: Confidential Computing for federated learning

Multiple health systems train a joint model; data never leaves provider, even to Microsoft. Attestation guarantees TEE isolation.

### Anti-pattern: building custom FHIR on Cosmos / SQL

Health Data Services FHIR is the right answer. Custom FHIR = re-implementing search + history + semantics + compliance.

### Anti-pattern: assuming all Azure services are HIPAA-eligible

Verify per service in [Trust Center](https://www.microsoft.com/trust-center).

### Anti-pattern: PHI in unclassified data stores

Classify before storing. Purview discovers; sensitivity labels applied; DLP enforces.

### Anti-pattern: BAA not signed before processing PHI

Microsoft Online Services BAA must be executed. Confirm scope covers the services you're using.

### Anti-pattern: PHI in App Insights / Log Analytics without redaction

Telemetry data logged without redaction can capture PHI. Redact at app layer; Purview classification on logs as defense in depth.

## When to escalate to the specialist (healthcare-architect, no overlay)

- HIPAA control mapping + evidence collection
- HITRUST certification scope + roadmap
- FHIR R4 profile design (US Core, IPS, specific implementation guides)
- FHIR resource modeling (Patient, Encounter, Observation, Condition specifics)
- HL7 v2 → FHIR mapping semantics
- DICOM workflow specifics (modality worklist, structured reports)
- ICD / SNOMED / LOINC code system handling
- HIPAA breach notification workflow
- GDPR / state law (CCPA, etc.) data subject rights workflow

## Cross-references to products_covered

| Product | Role usage |
|---------|------------|
| `Azure Health Data Services` | FHIR + DICOM + MedTech |
| `Azure Confidential Computing` | TEE for PHI processing |
| `Microsoft Purview` | PHI classification + DLP |
| `Microsoft Entra ID` + `Entra External ID` | Auth (in BAA scope) |
| `Azure Key Vault` + `Managed HSM` | Encryption key custody |
| `Defender for Cloud` (HIPAA initiative) | Compliance posture |
| `Microsoft Sentinel` | Security monitoring with PHI handling |
| `Azure Communication Services` | Telehealth (HIPAA-eligible) |

## When to refresh this overlay

- Health Data Services feature GA
- New HIPAA-eligible services
- BAA scope changes
- New regulatory initiative (state-level, FDA, etc.)
- Purview PHI classifier improvements

Target refresh cadence: every 6 months; sooner on Health Data Services major feature releases.
