# Patient Data Management — Deep Reference

**Always use `WebSearch` to verify clinical data model versions, terminology updates, patient matching vendor capabilities, and data governance best practices before giving advice. Healthcare data management standards and tools evolve continuously. Last verified: April 2026.**

## Table of Contents
1. [Patient Identity & Matching](#1-patient-identity--matching)
2. [Master Patient Index (MPI)](#2-master-patient-index-mpi)
3. [Clinical Data Models](#3-clinical-data-models)
4. [Healthcare Data Pipeline Architecture](#4-healthcare-data-pipeline-architecture)
5. [Clinical Terminology & Mapping](#5-clinical-terminology--mapping)
6. [Consent Management](#6-consent-management)
7. [De-identification & Anonymization](#7-de-identification--anonymization)
8. [Healthcare Data Governance](#8-healthcare-data-governance)
9. [Healthcare Analytics & Population Health](#9-healthcare-analytics--population-health)
10. [Patient Data Portability](#10-patient-data-portability)
11. [Data Retention & Destruction](#11-data-retention--destruction)
12. [Imaging Data (DICOM & PACS)](#12-imaging-data-dicom--pacs)

---

## 1. Patient Identity & Matching

Patient identity is the foundational challenge of healthcare data management. The same patient may have records in dozens of systems, each with slightly different demographics. Matching these records accurately is critical for patient safety and data integrity.

### 1.1 The Patient Identity Problem

```
The same patient across systems:

Hospital EHR:   John M Smith, DOB: 03/15/1980, MRN: 12345
Lab System:     John Smith, DOB: 3/15/80, Account: LAB-987
Pharmacy:       J. Michael Smith, DOB: 1980-03-15, Rx: RX-456
Insurance:      SMITH, JOHN MICHAEL, DOB: 15-MAR-1980, Member: INS-789
Patient Portal: john.smith@email.com, DOB: March 15, 1980
Urgent Care:    Jon Smith, DOB: 03/15/1980, MRN: UC-2345   ← typo in name!
```

**Consequences of mismatching:**
- **False negative** (missed match): Patient records fragmented → clinician misses critical allergies, medications, or diagnoses → **patient safety risk**
- **False positive** (incorrect match): Two different patients' records merged → wrong medications, wrong diagnoses applied → **patient safety risk**

### 1.2 Matching Algorithms

**Deterministic Matching:**
- Exact or rule-based comparison of identifiers
- Example: SSN match + DOB match + first 3 letters of last name match
- Fast, simple, but misses many valid matches (typos, name changes, data entry errors)
- Best for: High-confidence matching, deduplication within a single system

**Probabilistic Matching:**
- Statistical approach using Fellegi-Sunter model
- Assigns weights to each field based on how discriminating it is
- Produces a match score — above threshold = match, below = no match, in between = manual review
- More flexible than deterministic, handles data quality issues better
- Best for: Cross-organization matching, HIE, large-scale deduplication

**ML-Based Matching:**
- Machine learning models trained on known match/non-match pairs
- Can learn complex patterns (nicknames, cultural name variations, address changes)
- Requires labeled training data (often from manual review queue)
- Best for: Large-scale, high-volume matching with diverse populations

### 1.3 Matching Fields and Weights

| Field | Discriminating Power | Notes |
|-------|---------------------|-------|
| SSN | Very high (when available) | Not always available; sometimes shared (SSN fraud); HIPAA-sensitive |
| Date of birth | High | Rarely changes; can have entry errors (month/day swap) |
| Last name | Medium-high | Name changes (marriage, legal), cultural variations, typos |
| First name | Medium | Nicknames (William/Bill/Will), typos, cultural variations |
| Gender | Low (50/50) | Useful as a blocking variable, not a matching variable |
| Address | Medium | Changes frequently, formatting varies wildly |
| Phone number | Medium-high | Changes, but relatively stable short-term |
| Email | Medium-high | Useful for patient-portal matching |
| MRN | Very high (within system) | Not portable across systems |
| Insurance ID | High (within payer) | Changes with job/plan changes |

### 1.4 Matching Architecture

```
┌──────────────────────────────────────────────────────┐
│                Patient Matching Pipeline              │
│                                                      │
│  ┌──────────┐    ┌──────────┐    ┌──────────────┐   │
│  │  Input    │    │  Block   │    │  Compare     │   │
│  │  Standardi│───▶│  (reduce │───▶│  (score each │   │
│  │  zation   │    │  search  │    │  candidate   │   │
│  │           │    │  space)  │    │  pair)       │   │
│  │  - Name   │    │          │    │              │   │
│  │    parsing│    │  - DOB   │    │  - Fellegi-  │   │
│  │  - Address│    │    block │    │    Sunter    │   │
│  │    normal │    │  - Soundex│   │  - or ML     │   │
│  │  - Phone  │    │    block │    │    model     │   │
│  │    format │    │  - ZIP   │    │              │   │
│  └──────────┘    │    block │    └──────┬───────┘   │
│                  └──────────┘           │           │
│                                         ▼           │
│  ┌──────────────────────────────────────────────┐   │
│  │  Decision                                     │   │
│  │                                               │   │
│  │  Score > 0.95 → Auto-match (link records)    │   │
│  │  Score 0.70-0.95 → Manual review queue       │   │
│  │  Score < 0.70 → No match (new patient)       │   │
│  └──────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────┘
```

### 1.5 Name Standardization

| Input | Standardized | Technique |
|-------|-------------|-----------|
| `Dr. Robert A. Smith Jr.` | `SMITH, ROBERT A` | Remove titles, suffixes, normalize order |
| `María García-López` | `GARCIA LOPEZ, MARIA` | Handle hyphens, diacritics |
| `WILLIAM "BILL" JONES` | `JONES, WILLIAM` (alias: `BILL`) | Extract nicknames, store as aliases |
| `O'BRIEN` | `OBRIEN` | Normalize apostrophes |
| `LE, TRAN NGOC` | `LE, TRAN NGOC` | Preserve multi-word names, handle cultural order |

---

## 2. Master Patient Index (MPI)

The MPI is the authoritative source of patient identities and cross-references. It links a patient's identifiers across all connected systems.

### 2.1 MPI Data Model

```sql
-- Core MPI schema
CREATE TABLE mpi_person (
    person_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    golden_record BOOLEAN DEFAULT FALSE,  -- Is this the "best" version?
    confidence_score DECIMAL(5,4),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'active'  -- active, merged, inactive
);

CREATE TABLE mpi_identifier (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id UUID NOT NULL REFERENCES mpi_person(person_id),
    identifier_system VARCHAR(255) NOT NULL,  -- 'hospital-a-mrn', 'ssn', 'insurance'
    identifier_value VARCHAR(255) NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    UNIQUE(identifier_system, identifier_value)
);

CREATE TABLE mpi_demographics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id UUID NOT NULL REFERENCES mpi_person(person_id),
    source_system VARCHAR(100) NOT NULL,  -- Which system provided this data
    family_name VARCHAR(100),
    given_name VARCHAR(100),
    middle_name VARCHAR(100),
    date_of_birth DATE,
    gender VARCHAR(20),
    ssn_hash VARCHAR(64),  -- Store hash, not plaintext SSN
    address_line VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(2),
    postal_code VARCHAR(10),
    phone VARCHAR(20),
    email VARCHAR(255),
    source_updated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE mpi_link (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    person_id_a UUID NOT NULL REFERENCES mpi_person(person_id),
    person_id_b UUID NOT NULL REFERENCES mpi_person(person_id),
    link_type VARCHAR(20) NOT NULL,  -- 'definite', 'probable', 'possible'
    match_score DECIMAL(5,4),
    match_method VARCHAR(50),  -- 'deterministic', 'probabilistic', 'manual'
    reviewed_by UUID,  -- NULL = auto-matched, set = manually reviewed
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Merge tracking (never lose history)
CREATE TABLE mpi_merge_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    surviving_person_id UUID NOT NULL,
    merged_person_id UUID NOT NULL,
    merged_by UUID NOT NULL,
    merge_reason TEXT,
    merged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Store snapshot of merged record for potential undo
    merged_record_snapshot JSONB NOT NULL
);
```

### 2.2 MPI Operations

| Operation | Description | Trigger |
|-----------|------------|---------|
| **Match** | Find existing person for incoming demographics | New patient registration, ADT message |
| **Link** | Associate an identifier with an existing person | Match found above threshold |
| **Merge** | Combine two person records that represent the same individual | Manual review, high-confidence auto-match |
| **Unmerge** | Reverse an incorrect merge | Error discovered post-merge |
| **Update** | Update demographics from a trusted source | Demographic update message |
| **Deactivate** | Mark a person as inactive (deceased, etc.) | Death notification, record cleanup |

### 2.3 MPI Vendor Landscape

| Vendor/Product | Type | Notes |
|---------------|------|-------|
| **Verato** | Cloud MPI service | Referential matching using vast identity database; considered gold standard for accuracy |
| **Splink** | Open source (Python) | Fellegi-Sunter probabilistic matching; can link 1M records in ~1 minute; supports DuckDB, Spark, AWS Athena; used by NHS England and Harvard/Mass General Brigham (8.1M records) |
| **IBM Initiate (now Merative)** | Enterprise MPI | Probabilistic matching, long history in healthcare |
| **Informatica MDM** | Enterprise MDM | Broader than healthcare, configurable for MPI use |
| **NextGate** | Enterprise MPI | Healthcare-focused, EMPI for health systems |
| **HAPI FHIR MDM** | Open source (Java) | Built-in MDM module (`hapi.fhir.mdm_enabled=true`); patient matching/linking within FHIR server |
| **Custom (HAPI FHIR + Splink)** | DIY | HAPI FHIR server with Splink-based probabilistic matching pipeline |

---

## 3. Clinical Data Models

### 3.1 OMOP CDM (Observational Medical Outcomes Partnership Common Data Model)

OMOP CDM is the dominant clinical data model for healthcare analytics and research, maintained by OHDSI (Observational Health Data Sciences and Informatics).

**Why OMOP:**
- Standardized vocabulary mapping (all data mapped to standard concepts)
- Large community (OHDSI network: 800+ collaborators, 100+ countries)
- Extensive analytics tools (ATLAS, Achilles, CohortDiagnostics)
- Enables federated research without sharing patient-level data
- Growing regulatory acceptance (FDA, EMA use OMOP for drug safety)

**Core OMOP Tables:**

| Table | Purpose | Key Fields |
|-------|---------|-----------|
| `person` | Patient demographics | person_id, gender, birth_date, race, ethnicity |
| `visit_occurrence` | Encounters/visits | visit_id, person_id, visit_start_date, visit_type |
| `condition_occurrence` | Diagnoses | condition_concept_id (SNOMED), start_date |
| `drug_exposure` | Medications | drug_concept_id (RxNorm), start_date, quantity |
| `procedure_occurrence` | Procedures | procedure_concept_id (SNOMED/CPT), date |
| `measurement` | Lab results, vitals | measurement_concept_id (LOINC), value, unit |
| `observation` | Other clinical facts | observation_concept_id, value |
| `device_exposure` | Medical devices | device_concept_id, start_date |
| `note` | Clinical notes (text) | note_text, note_type_concept_id |
| `specimen` | Biospecimens | specimen_concept_id, specimen_date |

**OMOP Concept Mapping:**

```
Source data:    ICD-10: E11.9 (Type 2 diabetes without complications)
                    ↓
Vocabulary mapping: concept_id: 201826 (standard SNOMED concept)
                    ↓
Standard concept:   SNOMED: 44054006 (Type 2 diabetes mellitus)

Every piece of clinical data maps to a "standard concept" in the
OMOP vocabulary, enabling cross-system analytics regardless of
the source coding system.
```

### 3.2 i2b2 (Informatics for Integrating Biology and the Bedside)

| Aspect | Description |
|--------|------------|
| Origin | NIH-funded, maintained by Partners Healthcare / Harvard |
| Strength | Patient cohort discovery — "How many patients have X and Y?" |
| Model | Star schema with observation_fact as central table |
| Tools | Web-based query tool, self-service for researchers |
| Best for | Academic medical centers, clinical research feasibility |
| Limitation | Less standardized vocabulary than OMOP, more institution-specific |

### 3.3 Choosing a Clinical Data Model

| Factor | OMOP CDM | i2b2 | Custom |
|--------|----------|------|--------|
| Analytics/research | Excellent (OHDSI tools) | Good (cohort queries) | Build your own |
| Vocabulary standardization | Comprehensive | Institution-specific | Manual |
| Community support | Large global community | Academic community | None |
| Multi-site federation | Designed for it | Possible | Difficult |
| Real-time clinical use | Not designed for | Not designed for | Flexible |
| Learning curve | Moderate (large model) | Moderate | Low |
| Regulatory acceptance | Growing (FDA, EMA) | Academic | None |

---

## 4. Healthcare Data Pipeline Architecture

### 4.1 End-to-End Pipeline

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Ingest  │──▶│ Validate │──▶│Normalize │──▶│  Store   │──▶│  Serve   │
│          │   │ & Parse  │   │& Enrich  │   │          │   │          │
│ HL7 v2   │   │          │   │          │   │ FHIR     │   │ FHIR API │
│ FHIR     │   │ Schema   │   │ Terminol │   │ OMOP CDM │   │ Bulk     │
│ C-CDA    │   │ Validate │   │ Mapping  │   │ Search   │   │ Analytics│
│ CSV/flat │   │ PHI check│   │ Patient  │   │ Index    │   │ Dashbd   │
│ API      │   │ Consent  │   │ Matching │   │ Encrypt  │   │ Export   │
└──────────┘   └──────────┘   └──────────┘   └──────────┘   └──────────┘
     │              │              │              │              │
     ▼              ▼              ▼              ▼              ▼
  Audit Log     Error Queue    Mapping Log   Audit Trail    Access Log
```

### 4.2 Ingestion Patterns

| Source | Protocol | Pattern | Error Handling |
|--------|----------|---------|---------------|
| HL7 v2 | TCP/MLLP | Interface engine (Mirth Connect) receives, parses, routes | NACK on parse failure, dead letter queue |
| FHIR | HTTPS | Webhook or polling; Bulk FHIR for batch | Retry with backoff, track last successful sync |
| C-CDA | HTTPS/Direct | Document download, parse XML | Validate against schema, flag malformed sections |
| CSV/flat files | SFTP/S3 | Batch upload, scheduled processing | Row-level validation, reject file on critical errors |
| HL7 v2 batch | File-based | FTP/SFTP batch file transfer | Process per-message, report failures |

### 4.3 Data Quality Framework

```
Data Quality Dimensions for Clinical Data:

1. Completeness
   - Are required fields populated? (e.g., DOB, gender for demographics)
   - Are expected code systems used? (SNOMED vs free-text for diagnoses)
   - What % of lab results have proper LOINC codes?

2. Conformance
   - Do dates use valid formats? (ISO 8601 for FHIR)
   - Are codes valid in their code system? (is this a real SNOMED code?)
   - Do values fall within expected ranges? (BMI of 500 is likely an error)

3. Plausibility
   - Are temporal relationships logical? (diagnosis before birth date = error)
   - Are lab values physiologically possible? (hemoglobin of 50 g/dL = error)
   - Are medication dosages reasonable? (1000 mg of a drug normally dosed at 10 mg)

4. Consistency
   - Do gender and gender-specific conditions align?
   - Are medication and allergy records consistent?
   - Do admission/discharge dates make temporal sense?

5. Timeliness
   - How current is the data? (lab result from 3 years ago may not be relevant)
   - Is there a significant lag between event and data arrival?
```

### 4.4 Deduplication

Patient records often contain duplicate entries from multiple sources:

```
Deduplication Strategy:

1. Exact duplicate detection
   - Same patient, same data, same timestamp → discard duplicate
   - Hash-based: SHA-256 of normalized content → detect exact copies

2. Clinical deduplication
   - Same patient, same test, same date, different source systems
   - Example: Lab result appears via HL7 v2 feed AND FHIR API
   - Strategy: Keep the most recent/authoritative version
   - Track provenance of each data point

3. Observation deduplication
   - Blood pressure recorded by nurse AND by vitals monitor
   - Same patient, same time (±5 min), same type → potential duplicate
   - Strategy: Keep both with provenance, flag for review if values differ

4. Document deduplication
   - Same C-CDA document from multiple HIE queries
   - Compare document IDs, or content hash if no reliable ID
   - Strategy: Store once, link from all sources
```

---

## 5. Clinical Terminology & Mapping

### 5.1 Terminology Mapping Challenges

Real-world clinical data arrives in many code systems that must be mapped to a standard representation:

```
Mapping Pipeline:

Source Data                    Mapping Service              Standard Output
─────────────                  ──────────────              ──────────────
ICD-10: E11.9  ──────────────▶ ConceptMap    ──────────────▶ SNOMED: 44054006
                               /translate                    (Type 2 DM)

Local code: "DM2" ───────────▶ Custom map   ──────────────▶ SNOMED: 44054006
                               table

Free text: "diabetes" ────────▶ NLP/NER     ──────────────▶ SNOMED: 73211009
                               (Comprehend                   (Diabetes mellitus)
                                Medical)

NDC: 00378-6166-01 ──────────▶ NDC→RxNorm  ──────────────▶ RxNorm: 861007
                               crosswalk                     (Metformin 500mg)
```

### 5.2 Terminology Mapping Strategies

| Strategy | How It Works | Best For |
|----------|-------------|----------|
| **FHIR ConceptMap** | Standard FHIR resource for code-to-code mapping | FHIR-native systems, standard crosswalks |
| **UMLS (Unified Medical Language System)** | NLM's comprehensive mapping of medical terminologies | Cross-terminology mapping, research |
| **OHDSI Vocabulary** | OMOP vocabulary tables with comprehensive mappings | OMOP CDM implementations |
| **NLP/NER** | Natural language processing for free-text extraction | Unstructured clinical notes, free-text fields |
| **Manual curation** | Human experts create and maintain mappings | Institution-specific codes, edge cases |

### 5.3 NLP for Clinical Data

| Tool | Provider | Capabilities |
|------|---------|-------------|
| **Amazon Comprehend Medical** | AWS | Entity extraction (medications, conditions, procedures), ICD-10/RxNorm linking |
| **Google Cloud Healthcare NLP** | GCP | Entity extraction, relationship detection, assertion classification |
| **Azure Text Analytics for Health** | Azure | Entity extraction, relation extraction, UMLS linking |
| **cTAKES** | Apache (open source) | Clinical NLP, SNOMED/RxNorm extraction from notes |
| **MedSpaCy** | Open source (SpaCy extension) | Clinical NLP pipeline, section detection, context |
| **John Snow Labs (Spark NLP)** | Commercial + open source | Healthcare-specific NLP models, de-identification |

---

## 6. Consent Management

### 6.1 Consent Models

| Model | Description | Complexity | Use Case |
|-------|------------|-----------|----------|
| **Opt-out** | Patient data is shared unless they explicitly opt out | Low | Default for TPO in US (HIPAA) |
| **Opt-in** | Patient must explicitly consent before data sharing | Medium | Research, marketing, special categories |
| **Granular consent** | Patient controls which data types and recipients | High | Patient-controlled sharing, advanced privacy |
| **Dynamic consent** | Real-time, revocable, purpose-specific consent | Very high | Research platforms, longitudinal studies |

### 6.2 FHIR Consent Resource

```json
{
  "resourceType": "Consent",
  "id": "consent-example",
  "status": "active",
  "scope": {
    "coding": [{
      "system": "http://terminology.hl7.org/CodeSystem/consentscope",
      "code": "patient-privacy"
    }]
  },
  "category": [{
    "coding": [{
      "system": "http://loinc.org",
      "code": "59284-0",
      "display": "Patient Consent"
    }]
  }],
  "patient": {
    "reference": "Patient/123"
  },
  "dateTime": "2026-04-14",
  "performer": [{
    "reference": "Patient/123"
  }],
  "organization": [{
    "reference": "Organization/hospital-a"
  }],
  "policy": [{
    "authority": "https://www.hhs.gov",
    "uri": "https://www.hhs.gov/hipaa/for-professionals/privacy/"
  }],
  "provision": {
    "type": "permit",
    "period": {
      "start": "2026-04-14",
      "end": "2027-04-14"
    },
    "actor": [{
      "role": {
        "coding": [{
          "system": "http://terminology.hl7.org/CodeSystem/v3-ParticipationType",
          "code": "IRCP"
        }]
      },
      "reference": {
        "reference": "Organization/research-lab"
      }
    }],
    "action": [{
      "coding": [{
        "system": "http://terminology.hl7.org/CodeSystem/consentaction",
        "code": "access"
      }]
    }],
    "class": [{
      "system": "http://hl7.org/fhir/resource-types",
      "code": "Observation"
    }],
    "provision": [{
      "type": "deny",
      "class": [{
        "system": "http://hl7.org/fhir/resource-types",
        "code": "Condition"
      }],
      "code": [{
        "coding": [{
          "system": "http://snomed.info/sct",
          "code": "74732009",
          "display": "Mental disorder"
        }]
      }]
    }]
  }
}
```

### 6.3 Consent Enforcement Architecture

```
┌──────────────────────────────────────────────────────┐
│                 API Gateway                           │
│                                                      │
│  Request: GET /fhir/Condition?patient=123             │
│  User: Dr. Smith (Organization: ResearchLab)          │
│  Purpose: research                                    │
│                                                      │
│  ┌──────────────────────────────────────────────┐    │
│  │  Consent Decision Engine                      │    │
│  │                                               │    │
│  │  1. Lookup active consents for Patient/123    │    │
│  │  2. Filter by: purpose=research,              │    │
│  │     actor=Organization/research-lab           │    │
│  │  3. Apply provisions:                         │    │
│  │     ✓ Permit access to Observations           │    │
│  │     ✗ Deny access to mental health Conditions │    │
│  │  4. Return filtered result set                │    │
│  │                                               │    │
│  └──────────────────────────────────────────────┘    │
│                                                      │
│  Response: Conditions returned (minus mental health)  │
│  Audit: Log what was accessed AND what was filtered   │
└──────────────────────────────────────────────────────┘
```

---

## 7. De-identification & Anonymization

### 7.1 HIPAA De-identification (Recap)

See `references/hipaa-compliance.md` Section 5.3 for full details. Summary:

| Method | Approach | Data Utility | Risk |
|--------|---------|-------------|------|
| **Safe Harbor** | Remove all 18 identifiers | Lower (more data removed) | Very low re-identification risk |
| **Expert Determination** | Statistical analysis of re-identification risk | Higher (more data retained) | Requires expert, documented process |

### 7.2 Technical De-identification Pipeline

```
Raw PHI Data → Identify PHI Elements → Apply Transforms → Validate → Output
     │                │                      │               │          │
     ▼                ▼                      ▼               ▼          ▼
  Source data    NLP/regex for      Suppress/generalize/   Check that    De-identified
  with full     unstructured text   shift/hash per field   all PHI is    dataset
  identifiers   Rule-based for                             removed
                structured fields                          Re-ID risk
                                                           assessment
```

### 7.3 Date Shifting

Date shifting preserves temporal relationships while removing identifiable dates:

```python
# Date shifting strategy (pseudocode)
def shift_dates(patient_data, patient_id):
    # Generate a consistent random offset for this patient
    # Range: -365 to +365 days (configurable)
    seed = hash(patient_id + SECRET_KEY)
    rng = Random(seed)
    offset_days = rng.randint(-365, 365)
    
    # Apply same offset to ALL dates for this patient
    for field in patient_data.date_fields:
        field.value = field.value + timedelta(days=offset_days)
    
    # This preserves:
    # - Time between events (admission 3 days before discharge = still 3 days)
    # - Seasonal patterns (if offset is small)
    # - Temporal ordering of events
    
    # This breaks:
    # - Exact dates (can't identify patient by admission date)
    # - Cross-patient temporal correlation (different offset per patient)
```

### 7.4 Synthetic Data Generation

| Tool | Description | Output Formats | Use Case |
|------|------------|---------------|----------|
| **Synthea** | Open-source patient generator | FHIR Bundles, C-CDA, CSV | Development, testing, demos, education |
| **MDClone** | Synthetic data platform | Tabular, FHIR | Research, analytics (commercial) |
| **Gretel.ai** | AI-based synthetic data | Various | General synthetic data with healthcare models |
| **Tonic.ai** | Data de-identification + synthesis | Database replicas | Test environments from production data |

**Synthea features:**
- Generates complete patient histories (birth to death)
- Includes realistic disease progressions based on medical literature
- Supports chronic diseases, acute events, medications, procedures
- Configurable demographics and geographic distribution
- No HIPAA concerns — data is entirely synthetic

---

## 8. Healthcare Data Governance

### 8.1 Data Governance Framework

```
Healthcare Data Governance Structure:

┌─────────────────────────────────────────────┐
│  Data Governance Committee                   │
│  (CISO, Privacy Officer, CMIO, CIO, Legal)  │
└─────────────────────┬───────────────────────┘
                      │
    ┌─────────────────┼─────────────────┐
    ▼                 ▼                 ▼
┌──────────┐  ┌──────────┐  ┌──────────────┐
│  Data    │  │  Data    │  │  Data        │
│  Quality │  │  Privacy │  │  Architecture│
│  Team    │  │  Team    │  │  Team        │
│          │  │          │  │              │
│ - Metrics│  │ - Consent│  │ - Standards  │
│ - DQ     │  │ - De-ID  │  │ - Models     │
│   rules  │  │ - Access │  │ - Lineage    │
│ - Reports│  │ - Breach │  │ - Catalog    │
└──────────┘  └──────────┘  └──────────────┘
```

### 8.2 Data Classification for Healthcare

| Classification | Description | Examples | Handling |
|---------------|------------|---------|---------|
| **Public** | No restrictions | Hospital name, public health reports | No special handling |
| **Internal** | Business-sensitive, not PHI | Employee schedules, operational metrics | Standard access controls |
| **Confidential (PHI)** | Protected Health Information | Patient records, lab results, clinical notes | HIPAA safeguards required |
| **Highly Confidential** | Sensitive PHI categories | HIV/AIDS, mental health, substance use, genetic | Enhanced controls (42 CFR Part 2, state laws) |
| **Restricted** | Highest sensitivity | Research identifiers, encryption keys, audit master logs | Strict access, dual-control |

### 8.3 Data Lineage Tracking

```
Data Lineage for a Lab Result:

1. Lab instrument produces result
   → Source: Analyzer Model XYZ, Serial #ABC
   
2. Lab Information System (LIS) receives result
   → System: Sunquest LIS, Interface: HL7 v2 ORU
   
3. Interface engine routes to EHR
   → System: Mirth Connect, Channel: lab-results-inbound
   
4. EHR stores result
   → System: Epic, Resource: Observation, ID: obs-789
   
5. FHIR API exposes result
   → System: Epic on FHIR, GET /Observation/obs-789
   
6. Your app ingests result
   → System: Your ETL pipeline, Job: daily-lab-sync-2026-04-14
   
7. Result stored in clinical data warehouse
   → System: OMOP CDM, Table: measurement, ID: meas-456
   
8. Result used in analytics
   → System: Population health dashboard, Report: HbA1c trends

Each step logged with timestamp, system, transformation applied
```

---

## 9. Healthcare Analytics & Population Health

### 9.1 Quality Measures

| Measure Type | Description | Examples |
|-------------|-------------|---------|
| **HEDIS** | Health plan quality measures (NCQA) | Diabetes screening rates, well-child visits |
| **eCQM** | Electronic clinical quality measures (CMS) | Colorectal cancer screening, blood pressure control |
| **MIPS** | Merit-based Incentive Payment System | Quality, cost, improvement activities, promoting interoperability |
| **Star Ratings** | CMS health plan ratings | Patient experience, clinical outcomes |

### 9.2 Population Health Architecture

```
┌──────────────────────────────────────────────────────┐
│  Population Health Platform                           │
│                                                      │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐    │
│  │ Clinical   │  │ Claims     │  │ SDoH       │    │
│  │ Data       │  │ Data       │  │ Data       │    │
│  │ (EHR/FHIR)│  │ (Payer)    │  │ (Census,   │    │
│  │            │  │            │  │  surveys)  │    │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘    │
│        │               │               │           │
│        └───────────────┬┼───────────────┘           │
│                        ▼                            │
│  ┌──────────────────────────────────────────────┐   │
│  │  OMOP CDM (Unified Clinical Data)            │   │
│  └────────────────────┬─────────────────────────┘   │
│                       │                             │
│  ┌────────┬───────────┼───────────┬──────────┐     │
│  ▼        ▼           ▼           ▼          ▼     │
│ Cohort   Risk     Care Gap    Quality    Utilization│
│ Builder  Strat    Identify    Measures   Analysis   │
│          ification             (eCQM)              │
└──────────────────────────────────────────────────────┘
```

### 9.3 OHDSI Analytics Tools

| Tool | Purpose | How It Works |
|------|---------|-------------|
| **ATLAS** | Web-based analytics for OMOP CDM | Cohort builder, characterization, pathway analysis, prediction |
| **Achilles** | Data characterization and quality | Automated analysis of OMOP CDM, generates data quality report |
| **CohortDiagnostics** | Evaluate cohort definitions | Assess sensitivity/specificity of phenotype algorithms |
| **PatientLevelPrediction** | Clinical prediction models | Build and validate predictive models on OMOP data |
| **CostEffectivenessAnalysis** | Health economics | Cost-effectiveness studies across populations |

---

## 10. Patient Data Portability

### 10.1 Patient Access API (CMS/ONC Mandate)

CMS and ONC require that patients can access their health data electronically:

| Regulation | Who Must Comply | What They Must Provide |
|-----------|----------------|----------------------|
| CMS Interoperability Rule | Health plans, Medicare Advantage, Medicaid managed care | Patient access API (FHIR), provider directory API, payer-to-payer exchange |
| ONC Cures Act Final Rule | Certified EHR developers | FHIR APIs (US Core), no information blocking |

### 10.2 Blue Button 2.0

CMS Blue Button 2.0 provides Medicare beneficiaries access to their claims data via FHIR API:

```
Blue Button 2.0 API:
Base URL: https://sandbox.bluebutton.cms.gov/v2/fhir/

Resources available:
- Patient (demographics)
- ExplanationOfBenefit (claims data)
- Coverage (insurance information)

Auth: OAuth 2.0 (patient-authorized)
Format: FHIR R4
```

### 10.3 Personal Health Records (PHR)

| Approach | Description | FHIR Support |
|----------|------------|-------------|
| **Apple Health Records** | Patient-facing FHIR data from connected EHRs | FHIR R4 (read-only from EHR) |
| **CommonHealth (Android)** | Android equivalent for health data aggregation | FHIR-based, SMART on FHIR |
| **Patient portal export** | Download records from EHR patient portal | C-CDA, FHIR (varies by EHR) |
| **Custom PHR apps** | Third-party apps using patient access APIs | FHIR R4 via SMART on FHIR |

---

## 11. Data Retention & Destruction

### 11.1 Healthcare Data Retention Requirements

| Data Type | Federal Minimum | Common State Requirement | Notes |
|-----------|----------------|------------------------|-------|
| Adult medical records | No federal minimum (HIPAA doesn't specify) | 6-10 years after last encounter (varies by state) | Check state-specific laws |
| Minor medical records | No federal minimum | Until age of majority + state retention period | Some states: age 21 + 6 years |
| Medicare/Medicaid records | 6 years (CMS) | May be longer per state | CMS Conditions of Participation |
| HIPAA audit logs | 6 years (documentation retention) | May be longer | §164.530(j) — 6 years for policies/procedures |
| Imaging (DICOM) | Varies | 5-10 years typically | Mammography: per MQSA requirements |
| Research data | Per IRB protocol | Often 6-10 years post-study | Sponsor requirements may be longer |

### 11.2 Secure Destruction

| Data Location | Destruction Method | Verification |
|--------------|-------------------|-------------|
| Database records | Cryptographic erasure (delete encryption keys) or secure delete | Confirm deletion, audit log |
| Cloud storage (S3, GCS) | Delete objects + lifecycle policy for versioned buckets | Verify no residual versions |
| Backup tapes/media | Degaussing or physical destruction | Certificate of destruction |
| Development environments | Never should contain real PHI | Use Synthea/synthetic data |
| Logs with PHI | Automated lifecycle + encryption | Verify expiry |

---

## 12. Imaging Data (DICOM & PACS)

### 12.1 DICOM Overview

DICOM (Digital Imaging and Communications in Medicine) is the universal standard for medical imaging:

| Concept | Description |
|---------|-------------|
| **Study** | A complete imaging examination (e.g., "Chest CT") |
| **Series** | A set of related images within a study (e.g., axial slices) |
| **Instance (SOP)** | A single image or object |
| **DICOM tags** | Metadata fields (patient name, modality, body part, acquisition parameters) |
| **Modalities** | CT, MRI, US (ultrasound), CR/DR (X-ray), MG (mammography), NM (nuclear medicine) |

### 12.2 PACS Architecture

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Modality │───▶│  PACS    │───▶│ Viewer   │    │ Cloud    │
│ (CT, MRI,│    │ Server   │    │ (Web/    │    │ Archive  │
│  X-ray)  │    │          │    │  Desktop)│    │ (VNA)    │
└──────────┘    │ - Store  │    └──────────┘    └──────────┘
                │ - Route  │            │
                │ - Query  │    ┌───────▼──────┐
                │ - Retrieve│   │ AI/ML        │
                └──────────┘    │ Analysis     │
                                │ (CAD, detect)│
                                └──────────────┘
```

### 12.3 Cloud-Native Imaging

| Service | Provider | DICOM Support | FHIR Integration |
|---------|---------|---------------|-----------------|
| **Google Cloud Healthcare API** | GCP | DICOM store (DICOMweb) | ImagingStudy resource |
| **Azure Health Data Services** | Azure | DICOM service | ImagingStudy resource |
| **AWS HealthImaging** | AWS | Cloud-native medical imaging | FHIR integration |

**DICOMweb** is the modern HTTP-based API for DICOM, replacing legacy network protocols:
- WADO-RS: Retrieve images and metadata
- STOW-RS: Store images
- QIDO-RS: Query for images
- UPS-RS: Unified Procedure Step (worklist)

### 12.4 Imaging and FHIR

FHIR `ImagingStudy` resource references DICOM studies:

```json
{
  "resourceType": "ImagingStudy",
  "id": "example",
  "status": "available",
  "subject": {
    "reference": "Patient/123"
  },
  "started": "2026-04-14T09:00:00Z",
  "numberOfSeries": 2,
  "numberOfInstances": 120,
  "series": [{
    "uid": "1.2.840.113619.2.55.3.60412344.54321.1",
    "modality": {
      "system": "http://dicom.nema.org/resources/ontology/DCM",
      "code": "CT"
    },
    "bodySite": {
      "system": "http://snomed.info/sct",
      "code": "51185008",
      "display": "Thorax"
    },
    "numberOfInstances": 60,
    "endpoint": [{
      "reference": "Endpoint/dicom-wado-rs"
    }]
  }]
}
```
