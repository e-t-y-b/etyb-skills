# HL7 & FHIR Interoperability — Deep Reference

**Always use `WebSearch` to verify FHIR specification versions, Implementation Guide updates, ONC regulatory deadlines, and EHR platform API capabilities before giving advice. Healthcare interoperability standards evolve continuously, and EHR vendors update their FHIR support regularly. Last verified: April 2026.**

## Table of Contents
1. [Healthcare Interoperability Landscape](#1-healthcare-interoperability-landscape)
2. [FHIR R4 Resource Model](#2-fhir-r4-resource-model)
3. [FHIR RESTful API Patterns](#3-fhir-restful-api-patterns)
4. [FHIR Profiles & Implementation Guides](#4-fhir-profiles--implementation-guides)
5. [SMART on FHIR](#5-smart-on-fhir)
6. [CDS Hooks — Clinical Decision Support](#6-cds-hooks--clinical-decision-support)
7. [HL7 v2 Messaging](#7-hl7-v2-messaging)
8. [C-CDA — Clinical Document Architecture](#8-c-cda--clinical-document-architecture)
9. [Bulk FHIR Data Access](#9-bulk-fhir-data-access)
10. [FHIR Server Implementations](#10-fhir-server-implementations)
11. [Clinical Terminology Services](#11-clinical-terminology-services)
12. [FHIR Subscriptions](#12-fhir-subscriptions)
13. [ONC Regulations & Information Blocking](#13-onc-regulations--information-blocking)
14. [FHIR Migration Strategies](#14-fhir-migration-strategies)

---

## 1. Healthcare Interoperability Landscape

Healthcare interoperability is the ability of different health IT systems to exchange, interpret, and use clinical data. The landscape has evolved significantly:

### Standards Timeline

```
1987 ─── HL7 v2 ─── ADT, ORM, ORU messages ─── Still dominant in hospital interfaces
         │
1999 ─── HL7 v3 / CDA ─── XML-based ─── Complex, limited adoption
         │
2005 ─── C-CDA ─── Consolidated clinical documents ─── Meaningful Use, document exchange
         │
2014 ─── FHIR (DSTU) ─── RESTful, JSON ─── Modern API approach
         │
2019 ─── FHIR R4 ─── First normative release ─── US Core, regulatory mandate
         │
2023 ─── FHIR R5 ─── Subscriptions, improved search ─── Adoption beginning
         │
2024+ ── FHIR R6 ─── In development ─── Next generation
```

### Current Adoption Reality

| Standard | Adoption | Where Used | Status |
|----------|---------|-----------|--------|
| **HL7 v2** | Very high | Hospital ADT, lab results, orders, pharmacy | Still ~95% of real-time hospital interfaces |
| **C-CDA** | High | Document exchange, transitions of care, MU compliance | Required for CMS programs, declining for new projects |
| **FHIR R4** | Growing rapidly | Patient access APIs, SMART apps, payer data exchange | ONC-mandated, all certified EHRs must support |
| **FHIR R5** | Early | New implementations, Subscriptions | Limited EHR support, backport features available |
| **Direct messaging** | Moderate | Provider-to-provider secure messaging | Point-to-point clinical communication |

### The Realistic Integration Picture

Most healthcare organizations use a mix of all standards simultaneously:

```
Hospital Environment:
┌─────────────────────────────────────────────────────┐
│  HL7 v2: Lab results, ADT, orders (real-time)       │
│  FHIR:   Patient access API, SMART apps, analytics  │
│  C-CDA:  Transitions of care, document exchange      │
│  Direct: Provider-to-provider messaging               │
│  Proprietary: EHR-specific APIs, vendor integrations  │
└─────────────────────────────────────────────────────┘
```

**Key insight**: Don't assume "everything is FHIR now." Real healthcare integration requires fluency in multiple standards, with HL7 v2 remaining the workhorse for real-time hospital data.

---

## 2. FHIR R4 Resource Model

FHIR (Fast Healthcare Interoperability Resources) organizes clinical data into **Resources** — discrete, self-contained units of healthcare information. FHIR R4 (v4.0.1) is the current normative standard and the version mandated by ONC for certified EHR technology.

### Core Resource Categories

**Foundation Resources:**

| Resource | Purpose | Example |
|----------|---------|---------|
| `Patient` | Demographics, identifiers | Name, DOB, MRN, address, phone |
| `Practitioner` | Provider information | Name, NPI, specialty, credentials |
| `Organization` | Healthcare organizations | Hospital, clinic, insurance company |
| `Location` | Physical or virtual places | Room, bed, clinic address, telehealth |
| `Encounter` | Clinical interaction | Office visit, ED visit, hospitalization |

**Clinical Resources:**

| Resource | Purpose | Example |
|----------|---------|---------|
| `Condition` | Diagnoses, problems | Diabetes (SNOMED: 73211009), Hypertension |
| `Observation` | Measurements, findings | Blood pressure (LOINC: 85354-9), lab result |
| `Procedure` | Clinical procedures | Surgery, biopsy, therapy session |
| `MedicationRequest` | Prescriptions | Metformin 500mg BID (RxNorm: 861007) |
| `MedicationStatement` | What patient is taking | Self-reported medications |
| `AllergyIntolerance` | Allergies, intolerances | Penicillin allergy, latex allergy |
| `Immunization` | Vaccinations | COVID-19 vaccine, influenza |

**Diagnostic Resources:**

| Resource | Purpose | Example |
|----------|---------|---------|
| `DiagnosticReport` | Report with results | Lab panel, imaging report, pathology |
| `Observation` (grouped) | Individual results in a report | Hemoglobin A1c: 7.2% |
| `ImagingStudy` | DICOM imaging reference | CT scan, MRI, X-ray |
| `DocumentReference` | Unstructured documents | C-CDA documents, PDFs, clinical notes |

**Care Coordination:**

| Resource | Purpose | Example |
|----------|---------|---------|
| `CarePlan` | Plan of care | Diabetes management plan |
| `CareTeam` | Team of providers | Primary care, endocrinology, nursing |
| `Goal` | Clinical goals | HbA1c <7.0% within 6 months |
| `ServiceRequest` | Referrals, orders | Referral to cardiology, lab order |

### Resource Relationships

```
                    Patient
                   /   |    \
                  /    |     \
          Encounter  Condition  AllergyIntolerance
           /    \        |
          /      \       |
  Observation  Procedure |
      |                  |
  DiagnosticReport    MedicationRequest
                         |
                    MedicationDispense
                         |
                    MedicationAdministration
```

### Resource Structure (Patient Example)

```json
{
  "resourceType": "Patient",
  "id": "example-patient",
  "meta": {
    "versionId": "3",
    "lastUpdated": "2026-04-14T10:00:00Z",
    "profile": [
      "http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient"
    ]
  },
  "identifier": [
    {
      "system": "http://hospital.example.org/mrn",
      "value": "MRN12345"
    },
    {
      "system": "http://hl7.org/fhir/sid/us-ssn",
      "value": "999-99-9999"
    }
  ],
  "active": true,
  "name": [
    {
      "use": "official",
      "family": "Smith",
      "given": ["John", "Michael"]
    }
  ],
  "gender": "male",
  "birthDate": "1980-03-15",
  "address": [
    {
      "use": "home",
      "line": ["123 Main St"],
      "city": "Springfield",
      "state": "IL",
      "postalCode": "62701"
    }
  ],
  "telecom": [
    {
      "system": "phone",
      "value": "555-123-4567",
      "use": "home"
    },
    {
      "system": "email",
      "value": "john.smith@email.com"
    }
  ]
}
```

---

## 3. FHIR RESTful API Patterns

FHIR uses standard RESTful patterns with healthcare-specific extensions.

### Base Operations

| Operation | HTTP Method | URL Pattern | Example |
|-----------|------------|-------------|---------|
| **Read** | GET | `[base]/[type]/[id]` | `GET /fhir/Patient/123` |
| **VRead** | GET | `[base]/[type]/[id]/_history/[vid]` | `GET /fhir/Patient/123/_history/2` |
| **Update** | PUT | `[base]/[type]/[id]` | `PUT /fhir/Patient/123` |
| **Patch** | PATCH | `[base]/[type]/[id]` | `PATCH /fhir/Patient/123` (JSON Patch) |
| **Delete** | DELETE | `[base]/[type]/[id]` | `DELETE /fhir/Patient/123` |
| **Create** | POST | `[base]/[type]` | `POST /fhir/Patient` |
| **Search** | GET/POST | `[base]/[type]?params` | `GET /fhir/Patient?name=Smith` |
| **History** | GET | `[base]/[type]/[id]/_history` | `GET /fhir/Patient/123/_history` |
| **Capabilities** | GET | `[base]/metadata` | `GET /fhir/metadata` |

### Search Parameters

FHIR search is powerful but complex. Key patterns:

```
# Basic search
GET /fhir/Patient?family=Smith&given=John

# Date range
GET /fhir/Observation?date=ge2026-01-01&date=le2026-04-14

# Code search (terminology)
GET /fhir/Condition?code=http://snomed.info/sct|73211009

# Reference search
GET /fhir/Observation?patient=Patient/123

# Token search (status, codes)
GET /fhir/Observation?status=final&category=vital-signs

# String search (contains)
GET /fhir/Patient?name:contains=smi

# Include related resources (reduce round trips)
GET /fhir/Observation?patient=Patient/123&_include=Observation:patient

# Reverse include (get resources that reference this one)
GET /fhir/Patient/123?_revinclude=Condition:patient

# Sort
GET /fhir/Observation?patient=Patient/123&_sort=-date

# Pagination
GET /fhir/Patient?_count=20&_offset=40

# Summary (metadata only, no full content)
GET /fhir/Patient?_summary=true

# Elements (specific fields only — minimum necessary!)
GET /fhir/Patient?_elements=id,name,birthDate
```

### Search Result Bundle

```json
{
  "resourceType": "Bundle",
  "type": "searchset",
  "total": 42,
  "link": [
    {
      "relation": "self",
      "url": "https://fhir.example.org/fhir/Patient?name=Smith&_count=10"
    },
    {
      "relation": "next",
      "url": "https://fhir.example.org/fhir/Patient?name=Smith&_count=10&_offset=10"
    }
  ],
  "entry": [
    {
      "fullUrl": "https://fhir.example.org/fhir/Patient/123",
      "resource": {
        "resourceType": "Patient",
        "id": "123"
      },
      "search": {
        "mode": "match"
      }
    }
  ]
}
```

### Transaction Bundles

For atomic multi-resource operations:

```json
{
  "resourceType": "Bundle",
  "type": "transaction",
  "entry": [
    {
      "fullUrl": "urn:uuid:patient-1",
      "resource": {
        "resourceType": "Patient",
        "name": [{"family": "Smith", "given": ["John"]}]
      },
      "request": {
        "method": "POST",
        "url": "Patient"
      }
    },
    {
      "fullUrl": "urn:uuid:condition-1",
      "resource": {
        "resourceType": "Condition",
        "subject": {
          "reference": "urn:uuid:patient-1"
        },
        "code": {
          "coding": [
            {
              "system": "http://snomed.info/sct",
              "code": "73211009",
              "display": "Diabetes mellitus"
            }
          ]
        }
      },
      "request": {
        "method": "POST",
        "url": "Condition"
      }
    }
  ]
}
```

---

## 4. FHIR Profiles & Implementation Guides

### US Core Implementation Guide

US Core is the foundational FHIR Implementation Guide for the US healthcare system. ONC requires certified EHRs to support US Core profiles.

**US Core mandates specific profiles for:**

| Profile | Base Resource | What It Adds |
|---------|--------------|-------------|
| US Core Patient | Patient | Race, ethnicity, birth sex extensions |
| US Core Condition | Condition | Must use SNOMED CT or ICD-10-CM |
| US Core Observation (Vitals) | Observation | Blood pressure, heart rate, temperature, etc. (LOINC codes) |
| US Core Observation (Lab) | Observation | Lab results with LOINC codes |
| US Core MedicationRequest | MedicationRequest | RxNorm coding required |
| US Core AllergyIntolerance | AllergyIntolerance | SNOMED CT for substance |
| US Core DiagnosticReport (Lab) | DiagnosticReport | Lab reports with LOINC |
| US Core DiagnosticReport (Note) | DiagnosticReport | Clinical notes (discharge summary, progress note, etc.) |
| US Core DocumentReference | DocumentReference | Clinical documents |
| US Core Encounter | Encounter | Visit information |
| US Core Goal | Goal | Clinical goals |
| US Core Immunization | Immunization | CVX codes required |
| US Core CarePlan | CarePlan | Documented care plans |
| US Core CareTeam | CareTeam | Care team members |
| US Core Procedure | Procedure | SNOMED CT or CPT codes |
| US Core Provenance | Provenance | Data provenance tracking |

### SMART App Launch

SMART on FHIR defines how third-party apps authenticate and launch within EHR contexts:

| Launch Type | Flow | Use Case |
|-------------|------|----------|
| **EHR Launch** | App launched from within EHR; receives context (patient, encounter) | In-workflow clinical tools, embedded dashboards |
| **Standalone Launch** | App launches independently; user selects context | Patient-facing apps, research tools, analytics |
| **Backend Services** | System-to-system, no user present | Bulk data access, scheduled exports, ETL pipelines |

### CDS Hooks

Clinical Decision Support integration at the point of care:

| Hook | When It Fires | Use Case |
|------|--------------|----------|
| `patient-view` | Provider opens patient chart | Risk alerts, care gap reminders |
| `order-select` | Provider begins an order | Drug interaction warnings, formulary checks |
| `order-sign` | Provider signs an order | Final safety checks before order processing |
| `encounter-start` | New encounter begins | Insurance eligibility, pre-visit planning |
| `encounter-discharge` | Patient being discharged | Discharge checklist, follow-up scheduling |
| `appointment-book` | Appointment being scheduled | Scheduling optimization, prep instructions |

---

## 5. SMART on FHIR

SMART on FHIR (Substitutable Medical Applications, Reusable Technology) is the standard for healthcare app authorization and launch. It extends OAuth 2.0 with healthcare-specific scopes and launch contexts.

### 5.1 EHR Launch Sequence

```
1. User clicks "Launch App" in EHR
       │
       ▼
2. EHR redirects to app's launch URL with:
   - launch: opaque launch token
   - iss: FHIR server base URL
       │
       ▼
3. App discovers OAuth endpoints from:
   GET [iss]/.well-known/smart-configuration
   (or GET [iss]/metadata → CapabilityStatement → oauth-uris extension)
       │
       ▼
4. App redirects to authorization endpoint:
   authorize?response_type=code
     &client_id=my-app
     &redirect_uri=https://myapp.com/callback
     &scope=launch openid fhirUser patient/Observation.read
     &state=random-state
     &launch=<launch-token>
     &aud=<fhir-server-url>
       │
       ▼
5. EHR authenticates user, checks app scopes
       │
       ▼
6. EHR redirects back to app with authorization code:
   https://myapp.com/callback?code=abc123&state=random-state
       │
       ▼
7. App exchanges code for access token:
   POST /token
   grant_type=authorization_code&code=abc123&redirect_uri=...
       │
       ▼
8. Token response includes:
   {
     "access_token": "eyJ...",
     "token_type": "bearer",
     "expires_in": 3600,
     "scope": "launch openid fhirUser patient/Observation.read",
     "patient": "Patient/123",         ← Launch context
     "encounter": "Encounter/456",     ← Launch context
     "id_token": "eyJ...",             ← OpenID Connect
     "fhirUser": "Practitioner/789"    ← Who launched the app
   }
       │
       ▼
9. App uses access_token to call FHIR API:
   GET /fhir/Observation?patient=Patient/123
   Authorization: Bearer eyJ...
```

### 5.2 SMART Scopes

SMART scopes follow the pattern: `<context>/<resource>.<permission>`

| Scope | Meaning | Example |
|-------|---------|---------|
| `patient/Patient.read` | Read patient resource for current patient | Patient demographics |
| `patient/Observation.read` | Read observations for current patient | Lab results, vitals |
| `patient/*.read` | Read all resources for current patient | Full chart access |
| `user/Patient.read` | Read patients the user has access to | Multi-patient access |
| `user/Observation.write` | Write observations (as the user) | Enter vitals, results |
| `system/Patient.read` | System-level read (backend services) | Bulk data, ETL |
| `launch` | Request launch context | EHR launch |
| `launch/patient` | Request patient selection (standalone) | Pick a patient |
| `openid fhirUser` | Get user identity | Who is logged in |
| `offline_access` | Refresh token for long-lived access | Background sync |

### 5.3 SMART v2 (STU 2.1+) Enhancements

- **Granular scopes**: `patient/Observation.rs?category=vital-signs` — read+search only vital signs
- **Token introspection**: Standard introspection endpoint for token validation
- **PKCE**: Required for public clients (mobile apps, SPAs)
- **Asymmetric client authentication**: RSA/EC key pairs instead of client_secret for confidential clients

### 5.4 Backend Services Authorization

For system-to-system access (no user present):

```
1. App creates signed JWT assertion:
   {
     "iss": "client-id",
     "sub": "client-id",
     "aud": "https://ehr.example.org/token",
     "exp": <5 minutes from now>,
     "jti": <unique-id>
   }
   Signed with app's private key (registered with EHR)

2. App requests token:
   POST /token
   grant_type=client_credentials
   &client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer
   &client_assertion=<signed-jwt>
   &scope=system/Patient.read system/Observation.read

3. Token response:
   {
     "access_token": "eyJ...",
     "token_type": "bearer",
     "expires_in": 300,
     "scope": "system/Patient.read system/Observation.read"
   }
```

---

## 6. CDS Hooks — Clinical Decision Support

CDS Hooks enables real-time clinical decision support within EHR workflows. When a clinician takes a specific action (opens a chart, writes an order), the EHR fires a "hook" to registered CDS services.

### 6.1 Architecture

```
┌────────────────┐     ┌─────────────────┐     ┌──────────────┐
│  EHR           │     │  CDS Service    │     │  Knowledge   │
│                │     │                 │     │  Base        │
│  Clinician     │ 1.  │  /cds-services  │     │              │
│  opens chart   │────▶│  (discovery)    │     │  Drug DB     │
│                │     │                 │     │  Guidelines  │
│  Clinician     │ 2.  │  /cds-services/ │     │  Risk Models │
│  orders med    │────▶│  order-select   │     │              │
│                │     │                 │     └──────────────┘
│  EHR displays  │ 3.  │  Returns:       │
│  CDS cards     │◀────│  - Info cards    │
│                │     │  - Warning cards │
│  Clinician     │ 4.  │  - Suggestions  │
│  acts on card  │────▶│  (with actions) │
└────────────────┘     └─────────────────┘
```

### 6.2 CDS Service Discovery

```json
// GET /cds-services
{
  "services": [
    {
      "hook": "patient-view",
      "title": "Diabetes Risk Assessment",
      "description": "Evaluates patient risk factors for diabetes",
      "id": "diabetes-risk",
      "prefetch": {
        "patient": "Patient/{{context.patientId}}",
        "conditions": "Condition?patient={{context.patientId}}&category=problem-list-item",
        "observations": "Observation?patient={{context.patientId}}&code=4548-4&_sort=-date&_count=3"
      }
    },
    {
      "hook": "order-select",
      "title": "Drug Interaction Checker",
      "description": "Checks for drug-drug interactions",
      "id": "drug-interactions",
      "prefetch": {
        "patient": "Patient/{{context.patientId}}",
        "medications": "MedicationRequest?patient={{context.patientId}}&status=active"
      }
    }
  ]
}
```

### 6.3 CDS Request/Response

```json
// POST /cds-services/drug-interactions
// Request:
{
  "hookInstance": "d1577c69-dfbe-44ad-ba6d-3e05e953b2ea",
  "hook": "order-select",
  "context": {
    "userId": "Practitioner/789",
    "patientId": "Patient/123",
    "encounterId": "Encounter/456",
    "selections": ["MedicationRequest/draft-rx-1"],
    "draftOrders": {
      "resourceType": "Bundle",
      "entry": [
        {
          "resource": {
            "resourceType": "MedicationRequest",
            "id": "draft-rx-1",
            "medicationCodeableConcept": {
              "coding": [
                {
                  "system": "http://www.nlm.nih.gov/research/umls/rxnorm",
                  "code": "861007",
                  "display": "Metformin 500 MG"
                }
              ]
            }
          }
        }
      ]
    }
  },
  "prefetch": {
    "patient": { "resourceType": "Patient", "id": "123" },
    "medications": {
      "resourceType": "Bundle",
      "entry": []
    }
  }
}

// Response:
{
  "cards": [
    {
      "uuid": "card-1",
      "summary": "No drug interactions detected",
      "indicator": "info",
      "source": {
        "label": "Drug Interaction Service",
        "url": "https://cds.example.org"
      },
      "detail": "Metformin 500 MG has no known interactions with current medications."
    }
  ]
}
```

### 6.4 Card Indicators

| Indicator | Meaning | EHR Display |
|-----------|---------|-------------|
| `info` | Informational, no action needed | Blue/green card |
| `warning` | Attention needed, review recommended | Yellow/orange card |
| `critical` | Immediate action required, potential harm | Red card, may block order |

---

## 7. HL7 v2 Messaging

HL7 v2 remains the most widely used healthcare messaging standard. Despite FHIR's growth, HL7 v2 carries ~95% of real-time hospital interface traffic.

### 7.1 Message Types

| Message Type | Trigger | Use Case | Direction |
|-------------|---------|----------|-----------|
| **ADT** (A01-A60) | Admit/Discharge/Transfer | Patient registration, bed management, transfers | EHR → Downstream |
| **ORM** (O01) | Order message | Lab orders, radiology orders, procedure orders | EHR → Order system |
| **ORU** (R01) | Unsolicited results | Lab results, pathology results | Lab → EHR |
| **SIU** (S12-S26) | Scheduling | Appointment creation, modification, cancellation | Scheduler ↔ EHR |
| **MDM** (T01-T11) | Medical document | Clinical document notifications | Document system → EHR |
| **DFT** (P03) | Detailed financial transaction | Charge capture, billing | Clinical → Billing |
| **RDE** (O11) | Pharmacy encoded order | Medication orders to pharmacy | EHR → Pharmacy |
| **RAS** (O17) | Administration | Medication administration recording | MAR → EHR |
| **VXU** (V04) | Vaccination update | Immunization records | EHR → Immunization registry |

### 7.2 HL7 v2 Message Structure

```
MSH|^~\&|SENDING_APP|SENDING_FAC|RECEIVING_APP|RECEIVING_FAC|20260414100000||ADT^A01^ADT_A01|MSG00001|P|2.5.1
EVN|A01|20260414100000
PID|1||MRN12345^^^HOSPITAL^MR||SMITH^JOHN^M||19800315|M|||123 MAIN ST^^SPRINGFIELD^IL^62701||5551234567|||||SSN999999999
PV1|1|I|ICU^BED3^1|E|||1234^JONES^ROBERT^A^MD|||MED||||7|||1234^JONES^ROBERT^A^MD|IP||||||||||||||||||||||||||20260414100000
DG1|1||I10^Essential hypertension^ICD10|||A
IN1|1|1|BCBS001|BLUE CROSS BLUE SHIELD|||||||GROUP123|||||SMITH^JOHN^M|18|19800315
```

**Segment breakdown:**
- `MSH`: Message header (sender, receiver, type, version)
- `EVN`: Event type (what triggered this message)
- `PID`: Patient identification (demographics, identifiers)
- `PV1`: Patient visit (location, attending physician, admit date)
- `DG1`: Diagnosis (ICD-10 codes)
- `IN1`: Insurance information
- `OBR`: Observation request (order details)
- `OBX`: Observation result (individual results)

### 7.3 Interface Engines

Interface engines are middleware that routes, transforms, and manages HL7 v2 (and increasingly FHIR) messages between systems:

| Engine | Type | Strengths | Best For |
|--------|------|-----------|----------|
| **Mirth Connect (NextGen)** | Commercial (as of v4.6, March 2025) | Extensive channel library, FHIR support, large community | Existing Mirth users, commercial deployments |
| **BridgeLink** | Open source (Mirth 4.5.2 fork) | Legal fork of last open-source Mirth, available on AWS Marketplace | Budget-conscious, former open-source Mirth users |
| **Open Integration Engine (OIE)** | Open source | Community-driven, vendor-neutral, HL7/FHIR/DICOM/X12, free TLS plugin | Open-source-first organizations |
| **Rhapsody (Rhapsody Health)** | Commercial | Enterprise-grade, advanced routing, EDI support, HL7 FHIR | Large health systems, complex environments |
| **Google Cloud Healthcare API** | Cloud | Managed HL7v2 store, FHIR conversion, DICOM | GCP-based health IT |
| **Redox** | Cloud platform | Pre-built EHR connections, normalized data model | SaaS health tech companies |
| **InterSystems HealthShare** | Commercial | Enterprise, analytics, unified health record | Large health systems, IDNs |

**Note on Mirth Connect licensing change**: As of version 4.6 (March 2025), NextGen transitioned Mirth Connect from open-source to fully commercial licensing. The last open-source version was 4.5.2. BridgeLink and OIE emerged as community-driven forks. Always use `WebSearch` to verify current licensing status.

### 7.4 HL7 v2 to FHIR Mapping

Common mapping patterns:

| HL7 v2 Segment | FHIR Resource | Notes |
|---------------|---------------|-------|
| PID | Patient | Demographics, identifiers |
| PV1 | Encounter | Visit information, location |
| DG1 | Condition | Diagnosis (requires ICD → SNOMED mapping) |
| OBR | ServiceRequest / DiagnosticReport | Order/report header |
| OBX | Observation | Individual results |
| RXA | Immunization / MedicationAdministration | Depends on context |
| IN1 | Coverage | Insurance information |
| NK1 | RelatedPerson | Next of kin, emergency contact |
| AL1 | AllergyIntolerance | Allergies |

**HL7 v2 to FHIR conversion tools:**
- **FHIR Converter** (Microsoft): Open-source Liquid template-based converter
- **Google Cloud HL7v2-to-FHIR pipeline**: Managed conversion service
- **HAPI FHIR converter**: Java library for v2-to-FHIR mapping
- **Mirth Connect FHIR channels**: Built-in HL7 v2 to FHIR transformation

---

## 8. C-CDA — Clinical Document Architecture

C-CDA (Consolidated Clinical Document Architecture) is an HL7 standard for structured clinical documents. While FHIR is preferred for APIs, C-CDA remains important for document exchange.

### 8.1 Common Document Types

| Document Type | Purpose | When Used |
|--------------|---------|-----------|
| **CCD** (Continuity of Care Document) | Summary of patient's health status | Transitions of care, referrals |
| **Discharge Summary** | Summary of hospital stay | Hospital discharge |
| **Progress Note** | Visit documentation | Office visits, follow-ups |
| **Consultation Note** | Specialist consultation | Referral responses |
| **History & Physical** | Comprehensive assessment | Admissions, annual physicals |
| **Operative Note** | Surgical procedure documentation | Post-surgery |
| **Referral Note** | Referral request with clinical context | Outgoing referrals |

### 8.2 C-CDA and FHIR

C-CDA documents can be represented in FHIR using:
- `DocumentReference`: Pointer to the document (metadata + URL)
- `Composition`: FHIR representation of a structured document
- `Bundle` (type: document): Complete FHIR document bundle

**C-CDA to FHIR conversion**: Use the HL7 C-CDA on FHIR Implementation Guide for mapping C-CDA sections to FHIR resources.

---

## 9. Bulk FHIR Data Access

Bulk FHIR enables large-scale data export for analytics, population health, and payer data exchange.

### 9.1 Bulk Data Export Flow

```
1. Client initiates export:
   GET /fhir/Patient/$export
     ?_type=Patient,Condition,Observation,MedicationRequest
     &_since=2026-01-01T00:00:00Z
   Authorization: Bearer <backend-service-token>

2. Server responds with 202 Accepted:
   Content-Location: https://fhir.example.org/bulkstatus/job-123

3. Client polls for status:
   GET /bulkstatus/job-123
   → 202 (still processing, X-Progress: 45%)
   → 200 (complete)

4. Complete response:
   {
     "transactionTime": "2026-04-14T10:00:00Z",
     "request": "https://fhir.example.org/fhir/Patient/$export",
     "requiresAccessToken": true,
     "output": [
       {
         "type": "Patient",
         "url": "https://fhir.example.org/bulkdata/patient-001.ndjson",
         "count": 50000
       },
       {
         "type": "Condition",
         "url": "https://fhir.example.org/bulkdata/condition-001.ndjson",
         "count": 150000
       }
     ],
     "error": []
   }

5. Client downloads NDJSON files:
   GET /bulkdata/patient-001.ndjson
   → Each line is a complete FHIR JSON resource
```

### 9.2 Export Types

| Endpoint | Scope | Use Case |
|----------|-------|----------|
| `GET /fhir/Patient/$export` | All patients | Full population export |
| `GET /fhir/Group/[id]/$export` | Specific patient group | Attributed patients, cohort |
| `POST /fhir/Patient/$export` (with Parameters) | Filtered export | Custom resource types, date ranges |

### 9.3 NDJSON Format

```
{"resourceType":"Patient","id":"1","name":[{"family":"Smith","given":["John"]}],"birthDate":"1980-03-15"}
{"resourceType":"Patient","id":"2","name":[{"family":"Jones","given":["Jane"]}],"birthDate":"1975-08-22"}
{"resourceType":"Patient","id":"3","name":[{"family":"Williams","given":["Robert"]}],"birthDate":"1990-12-01"}
```

Each line is a complete, valid JSON resource. This format enables streaming processing without loading entire files into memory.

---

## 10. FHIR Server Implementations

### 10.1 Server Comparison

| Server | Language | License | FHIR Version | Best For |
|--------|---------|---------|-------------|----------|
| **HAPI FHIR** | Java | Apache 2.0 | R4, R5 | Self-hosted, full control, largest community |
| **Microsoft FHIR Server** | C# | MIT | R4 | Azure ecosystem, open source |
| **Azure Health Data Services** | Managed | Commercial | R4 | Managed Azure, DICOM + FHIR |
| **Google Cloud Healthcare API** | Managed | Commercial | R4 | Managed GCP, HL7v2 + FHIR + DICOM |
| **AWS HealthLake** | Managed | Commercial | R4 | Managed AWS, analytics integration |
| **LinuxForHealth FHIR** (IBM) | Java | Apache 2.0 | R4 | IBM ecosystem |
| **Aidbox** | Clojure | Commercial | R4, R5 | Developer-friendly, PostgreSQL-based |
| **Medplum** | TypeScript | Apache 2.0 | R4 | Modern developer experience, React SDK |
| **Firely Server** | C# | Commercial | R4, R5 | .NET ecosystem, compliance features |

### 10.2 HAPI FHIR Deep Dive

HAPI FHIR is the most widely used open-source FHIR server/library:

**Key capabilities:**
- Full FHIR R4 and R5 support
- Built-in search parameter indexing
- Terminology service (ValueSet expansion, CodeSystem operations)
- Subscription support (REST-hook, WebSocket)
- Bulk data export
- SMART on FHIR integration
- JPA backend (PostgreSQL, MySQL, Oracle, MS SQL)
- Interceptors for custom logic (authorization, audit, validation)

**Architecture:**

```
┌─────────────────────────────────────────────┐
│  HAPI FHIR Server                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ REST API │  │ Intercep-│  │Terminol- │  │
│  │ Layer    │  │  tors    │  │ogy Svc   │  │
│  │ (Spring) │  │(Auth,    │  │(LOINC,   │  │
│  │          │  │ Audit,   │  │ SNOMED,  │  │
│  │          │  │ Consent) │  │ RxNorm)  │  │
│  └────┬─────┘  └────┬─────┘  └──────────┘  │
│       │              │                      │
│  ┌────▼──────────────▼──────────────────┐   │
│  │  JPA Data Access Layer               │   │
│  │  (Search index, resource storage)    │   │
│  └──────────────────┬───────────────────┘   │
│                     │                       │
│  ┌──────────────────▼───────────────────┐   │
│  │  PostgreSQL / MySQL / Oracle          │   │
│  │  (Encrypted at rest, audit logged)   │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

---

## 11. Clinical Terminology Services

Clinical terminology is the foundation of interoperable healthcare data. Using standardized code systems ensures data can be exchanged and understood across systems.

### 11.1 Major Code Systems

| Code System | URI | What It Codes | Example |
|-------------|-----|--------------|---------|
| **SNOMED CT** | `http://snomed.info/sct` | Clinical findings, procedures, body structures | 73211009 = Diabetes mellitus |
| **LOINC** | `http://loinc.org` | Lab tests, clinical observations, document types | 4548-4 = Hemoglobin A1c |
| **RxNorm** | `http://www.nlm.nih.gov/research/umls/rxnorm` | Medications (US) | 861007 = Metformin 500 MG |
| **ICD-10-CM** | `http://hl7.org/fhir/sid/icd-10-cm` | Diagnoses (billing) | E11.9 = Type 2 diabetes without complications |
| **ICD-10-PCS** | `http://www.cms.gov/Medicare/Coding/ICD10` | Inpatient procedures (billing) | 0DBN0ZZ = Excision of sigmoid colon |
| **CPT** | `http://www.ama-assn.org/go/cpt` | Outpatient procedures (billing) | 99213 = Office visit, established patient |
| **HCPCS** | `https://www.cms.gov/Medicare/Coding/HCPCSReleaseCodeSets` | Supplies, drugs, services | J0135 = Adalimumab injection |
| **CVX** | `http://hl7.org/fhir/sid/cvx` | Vaccine types | 208 = COVID-19 mRNA BNT162b2 |
| **NDC** | `http://hl7.org/fhir/sid/ndc` | Drug packaging (US) | 00378-6166-01 = Metformin 500mg 100ct |

### 11.2 FHIR Terminology Operations

| Operation | Purpose | Example |
|-----------|---------|---------|
| `ValueSet/$expand` | Get all codes in a value set | Expand "vital signs" value set |
| `CodeSystem/$lookup` | Get details about a specific code | Look up SNOMED code 73211009 |
| `ConceptMap/$translate` | Map between code systems | ICD-10 E11.9 → SNOMED equivalent |
| `CodeSystem/$validate-code` | Validate if a code exists | Is 73211009 a valid SNOMED code? |
| `ValueSet/$validate-code` | Validate if code is in value set | Is this LOINC code a vital sign? |

### 11.3 Terminology Mapping Challenges

```
Clinical Reality: Same concept, different codes

"Type 2 Diabetes"
  ├── SNOMED CT: 44054006 (Type 2 diabetes mellitus)
  ├── ICD-10-CM: E11 (Type 2 diabetes mellitus) — many sub-codes
  ├── Read Codes: C10F. (Type 2 diabetes mellitus) — UK legacy
  └── Local code: DM2 (hospital-specific)

Mapping strategy:
1. Store in FHIR Condition with BOTH SNOMED + ICD-10 codings
2. Use ConceptMap resources for system-level mappings
3. Handle 1:many mappings (one SNOMED → multiple ICD-10)
4. Handle unmappable codes (local codes → flag for manual review)
5. Version-aware: ICD-10 updates annually (October)
```

---

## 12. FHIR Subscriptions

FHIR Subscriptions enable event-driven data flow — systems are notified when relevant data changes rather than polling.

### 12.1 R5 Topic-Based Subscriptions (Backported to R4B)

```
Subscription Architecture:
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  FHIR Server │     │ Subscription │     │  Subscriber  │
│              │────▶│ Manager      │────▶│  (Your App)  │
│  Data changes│     │              │     │              │
│  are detected│     │ Match against│     │ Receives     │
│              │     │ topic filters│     │ notification │
└──────────────┘     └──────────────┘     └──────────────┘
```

### 12.2 Notification Channels

| Channel | Mechanism | Best For |
|---------|-----------|----------|
| `rest-hook` | HTTP POST to a URL | Server-to-server, most common |
| `websocket` | WebSocket connection | Real-time UI updates |
| `email` | Email notification | Low-frequency alerts |
| `message` | FHIR Messaging | Cross-organization |

### 12.3 Subscription Example

```json
{
  "resourceType": "Subscription",
  "status": "active",
  "reason": "Monitor new lab results for patient panel",
  "criteria": "Observation?category=laboratory&status=final",
  "channel": {
    "type": "rest-hook",
    "endpoint": "https://myapp.example.org/fhir-notifications",
    "header": ["Authorization: Bearer <token>"],
    "payload": "application/fhir+json"
  }
}
```

---

## 13. ONC Regulations & Information Blocking

### 13.1 21st Century Cures Act

The Cures Act mandates healthcare data interoperability and prohibits information blocking:

**Key provisions:**
- All certified EHR technology must support FHIR APIs for patient access
- Health IT developers, providers, and HIEs must not engage in information blocking
- USCDI (US Core Data for Interoperability) defines the minimum data set that must be exchangeable
- Patients have the right to access their electronic health information via APIs

### 13.2 Information Blocking Rules

Information blocking is a practice that is likely to interfere with the access, exchange, or use of electronic health information (EHI). Exceptions exist but are narrow:

| Exception | When It Applies |
|-----------|----------------|
| **Preventing harm** | Sharing data would endanger patient or others |
| **Privacy** | Required by federal/state privacy law |
| **Security** | Necessary to protect system/data security |
| **Infeasibility** | Technically not feasible at this time |
| **Health IT performance** | Temporary measures to maintain system performance |
| **Content and manner** | Alternative means of access offered |
| **Fees** | Reasonable fees for data access (must be justified) |
| **Licensing** | Reasonable licensing terms for interoperability |

### 13.3 TEFCA (Trusted Exchange Framework and Common Agreement)

TEFCA establishes a universal floor for nationwide health information exchange:

```
┌─────────────────────────────────────────────────────┐
│  TEFCA Framework                                     │
│                                                      │
│  RCE (Recognized Coordinating Entity) — The Sequoia  │
│  Project — manages the framework                      │
│                                                      │
│  QHINs (Qualified Health Information Networks):       │
│  ├── CommonWell Health Alliance                       │
│  ├── Carequality (via QHINs)                         │
│  ├── eHealth Exchange                                │
│  ├── Epic Nexus (QHIN status)                        │
│  ├── KONZA                                           │
│  └── Others applying...                              │
│                                                      │
│  Exchange Purposes:                                   │
│  - Treatment                                         │
│  - Payment                                           │
│  - Healthcare Operations                             │
│  - Public Health                                     │
│  - Individual Access Services                         │
└─────────────────────────────────────────────────────┘
```

### 13.4 USCDI (US Core Data for Interoperability)

USCDI defines the standardized health data classes and elements that must be exchangeable. Each version expands the required data set:

| Version | Key Additions |
|---------|--------------|
| USCDI v1 | Demographics, allergies, conditions, immunizations, labs, medications, procedures, vital signs, clinical notes |
| USCDI v2 | Sexual orientation, gender identity, social determinants of health, health insurance |
| USCDI v3 | Disability status, mental/cognitive status, health status assessments, care team members |
| USCDI v4+ | Expanding (verify current version via WebSearch) |

**US Core IG**: Current published version is US Core v8.0.1 (STU8) based on FHIR R4. This defines the FHIR profiles that implement USCDI requirements.

### 13.5 Key Regulatory Deadlines

| Deadline | Requirement | Impact |
|----------|-----------|--------|
| **January 2026** | CMS Prior Authorization FHIR API mandate | Payers must support FHIR-based prior auth |
| **September 2026** | Azure API for FHIR retirement | Migrate to Azure Health Data Services |
| **January 2027** | All four CMS FHIR APIs mandatory | Patient Access, Provider Access, Payer-to-Payer, Prior Authorization |
| **2026 ongoing** | ONC information blocking enforcement | Up to $1M/violation penalties for health IT developers |

### 13.6 Information Blocking Enforcement

As of February 2026, ONC began issuing letters of nonconformity to EHR developers. ~1,600 complaints submitted to the Information Blocking Complaint Portal. Penalties can reach $1M per violation for health IT developers with potential stacking.

---

## 14. FHIR Migration Strategies

### 14.1 From HL7 v2 to FHIR

Most organizations will run HL7 v2 and FHIR simultaneously for years. The migration is evolutionary, not revolutionary:

**Phase 1: FHIR Facade**
- Keep HL7 v2 interfaces for existing hospital systems
- Add a FHIR API layer that translates v2 data on-the-fly
- New applications connect via FHIR only
- No data migration needed

**Phase 2: Dual-Write**
- HL7 v2 messages are converted and stored in FHIR format
- Both v2 and FHIR representations maintained
- New data enters via FHIR when possible
- v2 interfaces gradually decommissioned

**Phase 3: FHIR-Primary**
- FHIR is the primary data store and API
- Legacy v2 interfaces maintained via FHIR-to-v2 translation
- v2 only for systems that cannot upgrade

**Key principle**: Don't try to eliminate HL7 v2 — coexist with it. Many hospital systems (lab instruments, pharmacy, radiology) will use v2 for years to come.

### 14.2 Common Migration Pitfalls

| Pitfall | How to Avoid |
|---------|-------------|
| Trying to convert everything at once | Start with patient access API, expand incrementally |
| Ignoring terminology differences | Build a terminology mapping service early |
| Assuming 1:1 v2-to-FHIR mapping | Many v2 fields have no FHIR equivalent; use extensions when needed |
| Not testing with real EHR data | EHR FHIR implementations vary significantly; test with actual sandbox data |
| Forgetting about historical data | Bulk export + convert for historical; live interface for new data |
| Underestimating search complexity | FHIR search is more complex than v2 queries; invest in search index design |
