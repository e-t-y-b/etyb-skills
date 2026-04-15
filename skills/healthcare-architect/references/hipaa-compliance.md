# HIPAA Compliance Architecture — Deep Reference

**Always use `WebSearch` to verify regulatory requirements, enforcement actions, penalty amounts, and compliance deadlines before giving advice. HIPAA regulations are interpreted through OCR guidance that evolves continuously, and state laws may impose stricter requirements. Last verified: April 2026.**

## Table of Contents
1. [HIPAA Regulatory Framework Overview](#1-hipaa-regulatory-framework-overview)
2. [Security Rule — Technical Safeguards](#2-security-rule--technical-safeguards)
3. [Security Rule — Administrative Safeguards](#3-security-rule--administrative-safeguards)
4. [Security Rule — Physical Safeguards](#4-security-rule--physical-safeguards)
5. [Privacy Rule Implementation](#5-privacy-rule-implementation)
6. [Breach Notification Rule](#6-breach-notification-rule)
7. [Business Associate Agreements](#7-business-associate-agreements)
8. [Cloud-Specific HIPAA Architecture](#8-cloud-specific-hipaa-architecture)
9. [HIPAA for Modern Architectures](#9-hipaa-for-modern-architectures)
10. [State-Specific Health Privacy Laws](#10-state-specific-health-privacy-laws)
11. [42 CFR Part 2 — Substance Use Disorder Records](#11-42-cfr-part-2--substance-use-disorder-records)
12. [HITRUST CSF & HIPAA](#12-hitrust-csf--hipaa)
13. [Compliance Automation & Tooling](#13-compliance-automation--tooling)
14. [HIPAA Enforcement & Penalties](#14-hipaa-enforcement--penalties)

---

## 1. HIPAA Regulatory Framework Overview

HIPAA (Health Insurance Portability and Accountability Act of 1996) establishes national standards for protecting health information. The HITECH Act (2009) strengthened enforcement and extended requirements to Business Associates. Together they create a comprehensive framework.

### Critical Update: 2025 NPRM (Proposed Rule)

On December 27, 2024, HHS/OCR issued a Notice of Proposed Rulemaking (NPRM) — the most sweeping update to the HIPAA Security Rule since 2013. A final rule is expected in 2026 (timeline uncertain due to regulatory review). Key changes to plan for now:

- **Eliminates "required" vs "addressable" distinction**: All safeguards become mandatory with limited exceptions. HHS observed entities incorrectly treated "addressable" as "optional."
- **Written technology asset inventory**: Identification, version, accountable person, location of all ePHI systems.
- **Network map**: Illustrating ePHI movement through all electronic information systems.
- **72-hour system restore**: Critical ePHI systems must be restorable within 72 hours.
- **Vulnerability scanning**: At least every 6 months.
- **Penetration testing**: At least every 12 months.
- **Annual compliance audit**: Against all Security Rule requirements.
- **Mandatory encryption**: No longer addressable — required for all ePHI at rest and in transit.
- **Mandatory MFA**: For all ePHI access points.

**Recommendation**: Treat all safeguards as mandatory now — don't wait for the final rule. OCR is already enforcing encryption and MFA as de facto requirements in enforcement actions.

### The Four HIPAA Rules

| Rule | What It Governs | Key Standard |
|------|----------------|-------------|
| **Privacy Rule** | Who can access PHI, when, and for what purposes | Minimum necessary, patient rights, permitted uses/disclosures |
| **Security Rule** | How ePHI must be protected technically | Administrative, physical, and technical safeguards |
| **Breach Notification Rule** | What to do when PHI is compromised | 60-day notification, risk assessment, state requirements |
| **Enforcement Rule** | How violations are investigated and penalized | Tiered penalties, corrective action plans, criminal referrals |

### What Is PHI?

Protected Health Information (PHI) is any individually identifiable health information that relates to:
- Past, present, or future physical or mental health condition
- Provision of healthcare to an individual
- Past, present, or future payment for healthcare

The 18 HIPAA identifiers that make health information "individually identifiable":

| # | Identifier | Example |
|---|-----------|---------|
| 1 | Names | Full name, maiden name |
| 2 | Geographic data smaller than state | Street address, city, ZIP code (first 3 digits OK if population >20K) |
| 3 | Dates (except year) related to individual | Birth date, admission date, discharge date, death date |
| 4 | Phone numbers | Home, mobile, work |
| 5 | Fax numbers | Any fax number |
| 6 | Email addresses | Personal, work |
| 7 | Social Security numbers | SSN |
| 8 | Medical record numbers | MRN |
| 9 | Health plan beneficiary numbers | Insurance ID |
| 10 | Account numbers | Financial account numbers |
| 11 | Certificate/license numbers | Driver's license, professional license |
| 12 | Vehicle identifiers | License plate, VIN |
| 13 | Device identifiers | Serial numbers, UDI |
| 14 | Web URLs | Personal websites, patient portal URLs |
| 15 | IP addresses | Connection IP addresses |
| 16 | Biometric identifiers | Fingerprints, retinal scans, voice prints |
| 17 | Full-face photographs | Any identifiable image |
| 18 | Any other unique identifying number | Study IDs linked to identity, genetic sequences |

### Covered Entities vs Business Associates

| Role | Who | HIPAA Obligation |
|------|-----|-----------------|
| **Covered Entity (CE)** | Health plans, healthcare clearinghouses, healthcare providers who transmit electronically | Full HIPAA compliance, ultimate responsibility for PHI |
| **Business Associate (BA)** | Any entity that creates, receives, maintains, or transmits PHI on behalf of a CE | Must sign BAA, comply with Security Rule, report breaches to CE |
| **Subcontractor** | Entity that a BA delegates PHI handling to | Must sign BAA with BA, same obligations flow down |

The chain of responsibility flows downward: CE → BA → Subcontractor. Each level must have a BAA with the level above.

---

## 2. Security Rule — Technical Safeguards

The Security Rule applies to electronic PHI (ePHI) and requires three categories of safeguards. Technical safeguards are the technology-based protections.

### 2.1 Access Control (§ 164.312(a))

**Required implementations:**

- **Unique user identification**: Every person who accesses ePHI must have a unique identifier. No shared accounts, no generic logins.
- **Emergency access procedure**: Process to access ePHI in an emergency (break-the-glass). Must be documented and auditable.
- **Automatic logoff**: Sessions must timeout after inactivity. Common standard: 15 minutes for clinical workstations, configurable for API sessions.
- **Encryption and decryption**: Implement mechanisms to encrypt and decrypt ePHI.

```
Access Control Architecture:
┌─────────────────────────────────────────────────────┐
│                   API Gateway                        │
│  ┌─────────────┐  ┌──────────┐  ┌───────────────┐  │
│  │ Auth (OAuth2/│  │ RBAC     │  │ Consent       │  │
│  │ SMART on     │  │ Policy   │  │ Enforcement   │  │
│  │ FHIR)        │  │ Engine   │  │ Layer         │  │
│  └──────┬──────┘  └────┬─────┘  └───────┬───────┘  │
│         │              │                 │          │
│         └──────────────┼─────────────────┘          │
│                        ▼                            │
│              ┌─────────────────┐                    │
│              │  Audit Logger   │                    │
│              │  (Every access) │                    │
│              └─────────────────┘                    │
└─────────────────────────────────────────────────────┘
```

**Role-Based Access Control (RBAC) for Healthcare:**

| Role | Access Level | PHI Scope | Example |
|------|-------------|-----------|---------|
| Treating physician | Full clinical | Own patients | Read/write all clinical data for assigned patients |
| Nurse | Clinical subset | Unit/department patients | Vitals, medications, orders for current shift |
| Lab technician | Lab results | Lab orders only | Lab results they process, no clinical notes |
| Billing/coding | Administrative + clinical codes | Diagnosis/procedure codes | ICD-10, CPT codes, no clinical narratives |
| Researcher | De-identified only | Approved cohorts | OMOP CDM access, no direct identifiers |
| Patient (portal) | Own data | Self only | View own records via patient access API |
| System admin | Infrastructure | No PHI content | Manage servers, no ability to read PHI content |
| Emergency (break-the-glass) | Full clinical | Any patient | Time-limited, requires justification, triggers alert |

**Break-the-Glass Implementation:**

```
Break-the-Glass Flow:
1. Clinician requests access to non-assigned patient
2. System presents warning: "This patient is not in your care panel"
3. Clinician provides justification (emergency, consult, covering)
4. System grants temporary elevated access (e.g., 4-hour window)
5. Immediate audit alert → privacy officer queue
6. Post-hoc review within 24 hours (mandatory)
7. If inappropriate → investigation, potential sanctions
```

### 2.2 Audit Controls (§ 164.312(b))

**Required**: Implement hardware, software, and/or procedural mechanisms that record and examine activity in systems containing ePHI.

Audit logging is the foundation of HIPAA compliance verification. Every access to ePHI must be logged:

**Minimum audit log fields:**

| Field | Description | Example |
|-------|------------|---------|
| `who` | Authenticated user/system identity | `dr.smith@hospital.org`, `service:lab-interface` |
| `what` | Resource accessed or action taken | `Patient/123/_history`, `Observation.create` |
| `when` | Timestamp (UTC, millisecond precision) | `2026-04-14T10:23:45.123Z` |
| `where` | Source IP, device, location | `10.0.1.45`, `workstation-ER-3`, `Emergency Dept` |
| `why` | Purpose of access | `treatment`, `payment`, `operations`, `emergency` |
| `outcome` | Success or failure | `success`, `denied:insufficient_scope` |
| `patient` | Which patient's data was accessed | `Patient/456` |
| `data_elements` | Which specific data elements | `[vitals, medications, lab_results]` |

See `references/audit-trails.md` for comprehensive audit architecture.

### 2.3 Integrity Controls (§ 164.312(c))

**Required**: Protect ePHI from improper alteration or destruction.

- **Checksums/hashes**: Compute SHA-256 hashes for stored clinical documents. Verify integrity on retrieval.
- **Database integrity**: Use database constraints, foreign keys, and application-level validation for clinical data integrity.
- **Version control**: Clinical data should be versioned, not overwritten. FHIR's `meta.versionId` supports this natively.
- **Digital signatures**: For clinical documents that require non-repudiation (e.g., signed clinical notes, prescriptions).

```sql
-- Example: Immutable clinical observation with integrity
CREATE TABLE clinical_observation (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patient(id),
    code_system VARCHAR(255) NOT NULL,  -- e.g., 'http://loinc.org'
    code VARCHAR(50) NOT NULL,           -- e.g., '8867-4' (heart rate)
    value_quantity DECIMAL(10,4),
    value_unit VARCHAR(50),
    effective_datetime TIMESTAMPTZ NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'final',
    recorded_by UUID NOT NULL REFERENCES practitioner(id),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- Integrity
    content_hash VARCHAR(64) NOT NULL,   -- SHA-256 of canonical content
    version_id INTEGER NOT NULL DEFAULT 1,
    supersedes_id UUID REFERENCES clinical_observation(id),
    -- No UPDATE or DELETE allowed via application logic
    -- Corrections create new rows with supersedes_id pointing to original
    CONSTRAINT chk_status CHECK (status IN ('preliminary','final','amended','corrected','cancelled','entered-in-error'))
);

-- Row-level security: Users only see patients they have access to
ALTER TABLE clinical_observation ENABLE ROW LEVEL SECURITY;

CREATE POLICY patient_access ON clinical_observation
    FOR SELECT
    USING (
        patient_id IN (
            SELECT patient_id FROM user_patient_access
            WHERE user_id = current_setting('app.current_user_id')::UUID
            AND access_expires_at > NOW()
        )
        OR current_setting('app.break_the_glass')::BOOLEAN = TRUE
    );
```

### 2.4 Transmission Security (§ 164.312(e))

**Required**: Protect ePHI when transmitted over networks.

| Requirement | Implementation | Minimum Standard |
|-------------|---------------|-----------------|
| Encryption in transit | TLS for all connections | TLS 1.2 minimum, TLS 1.3 preferred |
| API communication | HTTPS only | HSTS headers, certificate pinning for mobile |
| Database connections | Encrypted connections | SSL/TLS for PostgreSQL, require-ssl |
| Internal service-to-service | mTLS or encrypted overlay | Service mesh (Istio/Linkerd) or mTLS |
| Email with PHI | S/MIME or TLS-enforced | Direct messaging protocol for clinical email |
| File transfers | SFTP or encrypted API | No unencrypted FTP, no plain HTTP |
| VPN for remote access | IPsec or WireGuard | Split-tunnel prohibited for PHI access |

### 2.5 Encryption at Rest

While not explicitly "required" (listed as "addressable"), encryption at rest is effectively mandatory — OCR has indicated that lack of encryption at rest is a significant risk factor in breach assessments:

| Data Store | Encryption Method | Key Management |
|-----------|-------------------|---------------|
| Databases (PostgreSQL, MySQL) | TDE (Transparent Data Encryption) or AES-256 | AWS KMS / GCP Cloud KMS / Azure Key Vault |
| Object storage (S3, GCS) | SSE-S3 or SSE-KMS (customer-managed key) | Customer-managed KMS key |
| Block storage (EBS, Persistent Disk) | Volume encryption | KMS-managed key |
| Application-level encryption | Field-level encryption for highly sensitive fields | Application-managed or KMS |
| Backups | Encrypted backup at rest | Same KMS key or dedicated backup key |
| Search indexes (Elasticsearch) | Encrypted index | KMS key with index-level encryption |
| Caches (Redis, Memcached) | Redis AUTH + TLS + encrypted at rest | ElastiCache encryption |
| Message queues (Kafka, SQS) | SSE for messages at rest | KMS key per topic/queue |

**Key Management Architecture:**

```
┌──────────────────────────────────────────┐
│              AWS KMS / Cloud KMS          │
│  ┌────────────────────────────────────┐  │
│  │   CMK (Customer Master Key)        │  │
│  │   - Never leaves KMS HSM           │  │
│  │   - Automatic rotation (annual)    │  │
│  │   - IAM policies control access    │  │
│  └────────────┬───────────────────────┘  │
│               │                          │
│  ┌────────────▼───────────────────────┐  │
│  │   Data Encryption Keys (DEKs)      │  │
│  │   - Generated per resource         │  │
│  │   - Envelope encryption            │  │
│  │   - Encrypted DEK stored with data │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘

Key Policy:
- Separate KMS keys for: database, storage, backups, audit logs
- Key rotation: automatic annual rotation (KMS handles transparently)
- Key deletion: 7-30 day waiting period (configurable), irrecoverable
- Access: IAM role-based, logged in CloudTrail
- Cross-region: replicate keys for DR (not shared across accounts)
```

---

## 3. Security Rule — Administrative Safeguards

Administrative safeguards are the policies, procedures, and organizational measures that manage the selection, development, implementation, and maintenance of security measures.

### 3.1 Security Management Process (§ 164.308(a)(1))

**Risk Analysis (Required):**

Every organization handling ePHI must conduct a thorough risk analysis. This is the most commonly cited deficiency in OCR enforcement actions.

Risk analysis methodology:
1. **Identify ePHI**: Map every system, database, file share, device, and process that creates, receives, stores, or transmits ePHI
2. **Identify threats**: Natural (floods, earthquakes), human (hackers, insider threats, errors), environmental (power failure, hardware failure)
3. **Identify vulnerabilities**: Unpatched software, weak passwords, unencrypted data, excessive access
4. **Assess current controls**: What safeguards exist today?
5. **Determine likelihood**: High/Medium/Low probability of threat exploiting vulnerability
6. **Determine impact**: High/Medium/Low impact if PHI is compromised
7. **Calculate risk level**: Likelihood × Impact = Risk
8. **Document mitigation plan**: For each risk, what will be done, by whom, by when
9. **Implement and monitor**: Execute the plan and reassess periodically (at least annually)

**Risk Management (Required):**

```
Risk Register Example:
┌──────────────────┬────────┬────────┬──────┬──────────────────┬──────────┐
│ Risk             │Likeli- │Impact  │ Risk │ Mitigation       │ Status   │
│                  │ hood   │        │Level │                  │          │
├──────────────────┼────────┼────────┼──────┼──────────────────┼──────────┤
│ Unencrypted      │ High   │ High   │ Crit │ Enable TDE, KMS  │ Complete │
│ database at rest │        │        │      │ encryption       │          │
├──────────────────┼────────┼────────┼──────┼──────────────────┼──────────┤
│ No MFA on admin  │ High   │ High   │ Crit │ Enforce MFA via  │ Complete │
│ accounts         │        │        │      │ IdP policy       │          │
├──────────────────┼────────┼────────┼──────┼──────────────────┼──────────┤
│ Excessive access │ Medium │ High   │ High │ Implement RBAC,  │ In prog  │
│ to PHI           │        │        │      │ quarterly review │          │
├──────────────────┼────────┼────────┼──────┼──────────────────┼──────────┤
│ No disaster      │ Low    │ High   │ Med  │ Implement multi- │ Planned  │
│ recovery plan    │        │        │      │ region failover  │          │
└──────────────────┴────────┴────────┴──────┴──────────────────┴──────────┘
```

### 3.2 Workforce Security & Training (§ 164.308(a)(3-5))

- **Workforce clearance**: Background checks for employees with PHI access
- **Access authorization**: Formal process to grant/modify/revoke PHI access
- **Termination procedures**: Immediate access revocation upon termination; documented within 24 hours
- **Security awareness training**: Required for all workforce members, annually at minimum
  - Phishing recognition
  - Password management
  - PHI handling procedures
  - Incident reporting
  - Mobile device security
- **Security reminders**: Periodic updates about threats, policy changes

### 3.3 Contingency Planning (§ 164.308(a)(7))

| Component | Requirement | Implementation |
|-----------|------------|----------------|
| Data backup plan | Regular backups of ePHI | Automated daily backups, encrypted, tested monthly |
| Disaster recovery plan | Restore ePHI systems after disaster | Multi-region/multi-AZ, RTO/RPO defined |
| Emergency mode operation | Continue critical processes during emergency | Documented failover procedures |
| Testing and revision | Regular testing of contingency plans | Annual DR test, tabletop exercises |
| Application/data criticality | Prioritize systems for recovery | Tier systems: critical (4h RTO), important (24h), deferrable (72h) |

---

## 4. Security Rule — Physical Safeguards

### 4.1 Cloud Environment Physical Controls

When using cloud providers (AWS, GCP, Azure), physical safeguards for data centers are covered by the provider under the shared responsibility model — but you must verify this is documented in your BAA.

**Your responsibilities in cloud:**

| Control | Your Responsibility | Provider Responsibility |
|---------|-------------------|----------------------|
| Data center physical security | N/A (covered by BAA) | Physical access controls, surveillance, environmental controls |
| Workstation security | Encrypted drives, screen locks, secure workspace policy | N/A |
| Device controls (laptops, phones) | MDM, remote wipe, encryption, PIN/biometric | N/A |
| Media disposal | Cryptographic erasure (destroy encryption keys) | Physical media destruction (AWS Nitro, shredding) |
| Facility access controls | Office security, visitor logs, badge access | Data center access controls |

### 4.2 Workstation and Device Security

```
Device Security Requirements:
- Full disk encryption (FileVault, BitLocker, LUKS)
- MDM enrollment (Jamf, Intune, Kandji) for any device accessing PHI
- Automatic screen lock after 5 minutes
- Remote wipe capability
- No PHI on personal devices unless MDM-managed
- No PHI stored locally — access via web/API only
- VPN required for remote PHI access (no split tunneling)
- USB storage disabled via MDM policy
```

---

## 5. Privacy Rule Implementation

The Privacy Rule governs who can access PHI, when, and for what purposes. Unlike the Security Rule (which is about "how to protect"), the Privacy Rule is about "who may access and under what conditions."

### 5.1 Permitted Uses and Disclosures

PHI can be used/disclosed without patient authorization for:

| Purpose | Description | Example |
|---------|------------|---------|
| **Treatment** | Providing, coordinating, managing healthcare | Doctor reads patient chart, referral to specialist |
| **Payment** | Billing, claims, eligibility, coverage | Submitting claims to insurance, prior authorization |
| **Healthcare Operations** | Quality assessment, training, auditing, business management | Quality improvement studies, credentialing, fraud detection |
| **Required by law** | Court orders, subpoenas, regulatory mandates | State mandatory reporting, FDA adverse event reporting |
| **Public health** | Disease surveillance, vital statistics | CDC reporting, immunization registries |
| **Abuse/neglect/domestic violence** | Mandatory reporting | Child protective services, elder abuse reporting |
| **Health oversight** | Regulatory audits, investigations | CMS audits, state health department inspections |
| **Law enforcement** | Under specific, limited circumstances | Court order, imminent threat, identification of suspect |
| **Research** | With IRB/Privacy Board waiver or de-identified data | Clinical trials with proper authorization/waiver |

All other uses require explicit **patient authorization** (written, specific, time-limited, revocable).

### 5.2 Minimum Necessary Standard

The minimum necessary principle requires that PHI disclosed or used be limited to the minimum amount necessary to accomplish the intended purpose. This applies to:
- **Internal access**: Role-based access limiting users to data needed for their job function
- **API design**: Return only requested/needed fields, not entire patient records
- **Disclosures**: Only share the minimum PHI needed to fulfill a request
- **Automated systems**: Apply field-level filtering based on purpose of use

**Exception**: The minimum necessary standard does NOT apply to:
- Treatment purposes (clinicians need full picture for patient safety)
- Patient's own PHI access requests
- Required by law or HHS investigation
- Individual authorization

```
Minimum Necessary API Pattern:

GET /fhir/Patient/123
  → Scope: user/Patient.read
  → Purpose: treatment
  → Returns: Full Patient resource (minimum necessary exception for treatment)

GET /fhir/Patient/123
  → Scope: user/Patient.read
  → Purpose: payment
  → Returns: Patient demographics + insurance only (no clinical data)

GET /fhir/Patient/123
  → Scope: user/Patient.read
  → Purpose: operations (quality review)
  → Returns: De-identified or limited dataset
```

### 5.3 De-identification Methods

HIPAA defines two methods for de-identification:

**Method 1: Safe Harbor (§ 164.514(b)(2))**

Remove all 18 identifiers listed in Section 1. The resulting data is not PHI and HIPAA no longer applies. This is the simpler method but produces less useful data.

Additional requirements:
- No actual knowledge that residual information could identify an individual
- ZIP codes must be truncated to first 3 digits (or removed if population <20,000)
- Dates must be generalized to year only (or age; ages >89 grouped as "90+")

**Method 2: Expert Determination (§ 164.514(a))**

A qualified statistical expert determines that the risk of identification is "very small." This allows retention of more data elements but requires:
- Expert with appropriate knowledge and experience
- Application of statistical and scientific principles
- Documented determination of "very small" re-identification risk
- Methods and results documented

**Technical De-identification Approaches:**

| Technique | How It Works | Use Case |
|-----------|-------------|----------|
| **Suppression** | Remove identifier entirely | Remove names, SSNs |
| **Generalization** | Replace specific value with broader category | "Age 47" → "Age 40-49" |
| **Date shifting** | Shift all dates by random offset (consistent per patient) | Preserve intervals while hiding actual dates |
| **Pseudonymization** | Replace identifiers with consistent pseudonyms | Research cohorts needing longitudinal tracking |
| **k-Anonymity** | Ensure each record is identical to at least k-1 other records on quasi-identifiers | Population-level datasets |
| **Differential privacy** | Add calibrated noise to query results | Aggregate analytics queries |
| **Synthetic data** | Generate statistically similar but entirely fake data | Development/testing (Synthea) |

### 5.4 Patient Rights Implementation

HIPAA grants patients specific rights regarding their PHI:

| Right | What It Means | Implementation |
|-------|--------------|----------------|
| **Right of Access** | Patients can request copies of their PHI in electronic format | Patient access API (FHIR), portal download, Blue Button 2.0 |
| **Right to Amend** | Patients can request corrections to their PHI | Amendment request workflow, append corrections (never delete original) |
| **Right to Accounting of Disclosures** | Patients can request a list of who their PHI was disclosed to | Comprehensive disclosure log (see audit-trails.md) |
| **Right to Request Restrictions** | Patients can request limits on PHI use/disclosure | Consent management system, honor restrictions |
| **Right to Confidential Communications** | Patients can request PHI be sent to alternate address/method | Communication preference system |
| **Right to Receive Notice** | Patients must receive Notice of Privacy Practices (NPP) | Provide at first encounter, post on website |
| **Right to Complain** | Patients can file complaints with CE or HHS | Complaint intake process, no retaliation |

### 5.5 Consent Management Architecture

```
┌──────────────────────────────────────────────┐
│            Consent Management System          │
│                                              │
│  ┌─────────────┐  ┌──────────────────────┐  │
│  │  Consent     │  │  Policy Engine       │  │
│  │  Repository  │  │                      │  │
│  │              │  │  - Evaluate consent   │  │
│  │  - Grantor   │  │    at request time   │  │
│  │  - Scope     │  │  - Apply defaults    │  │
│  │  - Purpose   │  │  - Handle conflicts  │  │
│  │  - Period    │  │  - Log decisions     │  │
│  │  - Status    │  │                      │  │
│  └──────┬──────┘  └──────────┬───────────┘  │
│         │                     │              │
│         └─────────┬───────────┘              │
│                   ▼                          │
│         ┌─────────────────┐                  │
│         │  FHIR Consent   │                  │
│         │  Resource       │                  │
│         │  (R4/R5)        │                  │
│         └─────────────────┘                  │
└──────────────────────────────────────────────┘

Consent Model:
- WHO is granting: Patient or legal representative
- TO WHOM: Specific organization, provider, or system
- FOR WHAT: Treatment, research, marketing, specific data types
- WHEN: Date range (start → expiration)
- WHAT DATA: All records, specific encounter types, specific conditions
- CONDITIONS: Opt-in vs opt-out, break-the-glass override allowed?
```

---

## 6. Breach Notification Rule

A breach is the acquisition, access, use, or disclosure of unsecured PHI in a manner not permitted by the Privacy Rule that compromises the security or privacy of the PHI.

### 6.1 The Four-Factor Risk Assessment

When a potential breach occurs, perform this assessment to determine if notification is required:

1. **Nature and extent of PHI involved**: What types of identifiers? Clinical data or just demographic? How sensitive (HIV, mental health, substance use)?
2. **Who accessed or received the PHI**: Internal unauthorized access? External malicious actor? Known healthcare provider?
3. **Whether the PHI was actually acquired or viewed**: Was it encrypted and the key not compromised? Was it accessed but not downloaded?
4. **Extent of risk mitigation**: Can you get the data back? Can you get assurance it wasn't further disclosed?

If, after this assessment, there is a **low probability that the PHI was compromised**, no notification is required. Document the assessment regardless.

### 6.2 Notification Requirements

If breach notification IS required:

| Who to Notify | When | How |
|--------------|------|-----|
| **Affected individuals** | Within 60 days of discovery | Written notice (mail), or email if individual consented to electronic notice |
| **HHS (OCR)** | Within 60 days if ≥500 affected; annual report if <500 | HHS breach portal (ocrportal.hhs.gov) |
| **Media** | Within 60 days if ≥500 in a single state/jurisdiction | Prominent media outlets in the affected area |
| **State attorneys general** | Per state law (many require notification) | State-specific portals, varies by state |

### 6.3 Breach Response Architecture

```
Incident Detection → Triage → Investigate → Assess → Notify → Remediate
       │                │          │            │          │          │
       ▼                ▼          ▼            ▼          ▼          ▼
  SIEM Alerts     Privacy Officer  Forensics  4-Factor    HHS/State  Root cause
  Access Anomaly  Risk Assessment  Evidence   Assessment  Individuals Fix
  Employee Report Scope Impact     Timeline   Document    Media      Monitor
  Vendor Report   Classify         Contain    Decision    BAA chain  Re-assess
```

**Breach documentation requirements:**
- Date of breach discovery
- Date of breach occurrence (if different)
- Nature of PHI involved
- Number of individuals affected
- Who discovered the breach and how
- Forensic investigation findings
- Four-factor risk assessment and conclusion
- Notification actions taken (who, when, how)
- Corrective actions implemented

---

## 7. Business Associate Agreements

A BAA is a legal contract between a Covered Entity and a Business Associate that establishes the permitted uses and disclosures of PHI.

### 7.1 When a BAA Is Required

| Scenario | BAA Required? | Why |
|----------|--------------|-----|
| Cloud hosting provider storing ePHI | Yes | Creates, receives, maintains, or transmits ePHI |
| SaaS tool processing PHI (e.g., EHR, analytics) | Yes | Receives and processes ePHI |
| Payment processor (no PHI access) | No | Only processes financial data, not PHI |
| ISP/telephone company (conduit) | No | Mere conduit exception — data passes through, not stored |
| Cleaning company with facility access | No | No access to ePHI (unless they could access workstations) |
| Software developer with access to production PHI | Yes | Access to ePHI during development/support |
| Pen testing firm testing systems with ePHI | Yes | May access ePHI during testing |
| De-identification service | Yes | Receives PHI (before de-identification) |

### 7.2 BAA Key Provisions

A BAA must include:
- Permitted uses and disclosures of PHI
- Agreement not to use or disclose PHI beyond what's permitted
- Implement appropriate safeguards (Security Rule compliance)
- Report breaches and security incidents to CE
- Ensure subcontractors agree to same restrictions (downstream BAAs)
- Make PHI available for patient access requests
- Return or destroy PHI at termination
- Allow HHS access for compliance audits
- CE may terminate the agreement if BA violates terms

### 7.3 Cloud Provider BAAs

| Provider | BAA Available? | How to Activate | Scope |
|----------|---------------|----------------|-------|
| **AWS** | Yes | Sign AWS BAA via AWS Artifact in console | Only covers HIPAA-eligible services |
| **Google Cloud** | Yes | Sign GCP BAA via Cloud console | Covers all GCP services used to process PHI |
| **Microsoft Azure** | Yes | Included in Online Services Terms | Covers Azure, M365, Dynamics 365 |
| **Heroku** | Yes (Shield) | Heroku Shield plan only | Heroku Shield PostgreSQL, Private Spaces |
| **Vercel** | Limited | Enterprise plan only | Check current status via WebSearch |
| **Supabase** | Yes | Pro plan and above | Database, storage, auth |
| **MongoDB Atlas** | Yes | Enterprise plan | Atlas dedicated clusters only |
| **Datadog** | Yes | Enterprise plan | Monitoring, logging |
| **Auth0** | Yes | Enterprise plan | Identity management |
| **Okta** | Yes | Included in agreement | All Okta services |

**Critical**: Always verify BAA availability and scope via `WebSearch` — these change frequently.

---

## 8. Cloud-Specific HIPAA Architecture

### 8.1 AWS HIPAA Architecture

AWS provides a HIPAA-eligible services list (166+ services as of 2025). Only services on this list may be used with PHI:

**Key HIPAA-eligible AWS services (verify current list at aws.amazon.com/compliance/hipaa-eligible-services-reference/):**
- **Compute**: EC2, ECS, EKS, Lambda, Fargate
- **Storage**: S3, EBS, EFS, Glacier
- **Database**: RDS (PostgreSQL, MySQL, Aurora), DynamoDB, ElastiCache, DocumentDB
- **Healthcare-specific**: HealthLake (FHIR), Comprehend Medical (NLP), HealthImaging
- **Analytics**: Redshift, Athena, EMR, Glue
- **AI/ML**: SageMaker, Bedrock (verify current status)
- **Networking**: VPC, CloudFront, Route 53, API Gateway
- **Security**: KMS, CloudTrail, GuardDuty, Security Hub, WAF
- **Messaging**: SQS, SNS, Kinesis, MSK (managed Kafka)
- **Identity**: IAM, Cognito, SSO

**AWS HIPAA reference architecture:**

```
┌──────────────────────────────────────────────────────────┐
│  AWS Account (dedicated for PHI workloads)                │
│  ┌──────────────────────────────────────────────────┐    │
│  │  VPC (private subnets, no IGW for data tier)     │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐       │    │
│  │  │ ALB      │  │ ECS/EKS  │  │ RDS      │       │    │
│  │  │ (HTTPS   │  │ (Fargate │  │ (Encrypted│      │    │
│  │  │  only)   │──▶│  tasks)  │──▶│  at rest) │      │    │
│  │  └──────────┘  └──────────┘  └──────────┘       │    │
│  │                      │                           │    │
│  │  ┌──────────┐  ┌────▼─────┐  ┌──────────┐       │    │
│  │  │ S3       │  │ KMS      │  │ CloudTrail│       │    │
│  │  │(Encrypted│  │(CMK per  │  │ (all API  │       │    │
│  │  │  SSE-KMS)│  │ service) │  │  calls)   │       │    │
│  │  └──────────┘  └──────────┘  └──────────┘       │    │
│  └──────────────────────────────────────────────────┘    │
│                                                          │
│  Guardrails:                                             │
│  - AWS Config rules (encryption, public access)          │
│  - GuardDuty (threat detection)                          │
│  - Security Hub (compliance dashboard)                   │
│  - SCPs (prevent disabling CloudTrail, encryption)       │
│  - Macie (PHI detection in S3)                           │
└──────────────────────────────────────────────────────────┘
```

### 8.2 GCP HIPAA Architecture

**Key GCP services for HIPAA workloads:**
- **Healthcare-specific**: Cloud Healthcare API (FHIR, HL7v2, DICOM stores), Healthcare NLP
- **Compute**: Compute Engine, GKE, Cloud Run, Cloud Functions
- **Storage**: Cloud Storage, Persistent Disks
- **Database**: Cloud SQL, Cloud Spanner, Firestore, Bigtable, AlloyDB
- **Analytics**: BigQuery, Dataflow, Dataproc
- **AI/ML**: Vertex AI, AutoML
- **Security**: Cloud KMS, Cloud Audit Logs, Security Command Center

### 8.3 Azure HIPAA Architecture

**Key Azure services for HIPAA workloads:**
- **Healthcare-specific**: Azure Health Data Services (FHIR, DICOM, MedTech), Azure Health Bot
- **Compute**: Virtual Machines, AKS, App Service, Azure Functions
- **Storage**: Blob Storage, Managed Disks, Azure Files
- **Database**: Azure SQL, Cosmos DB, Azure Database for PostgreSQL
- **AI/ML**: Azure OpenAI Service, Azure Machine Learning, Azure Cognitive Services
- **Security**: Azure Key Vault, Azure Monitor, Microsoft Defender for Cloud

### 8.4 Shared Responsibility Model

```
┌──────────────────────────────────────────────────────┐
│                  YOUR RESPONSIBILITY                  │
│  - Data classification and encryption decisions       │
│  - Access control and identity management             │
│  - Application security and code                      │
│  - Network configuration (security groups, NACLs)     │
│  - Operating system patches (if using EC2/VMs)        │
│  - Audit logging configuration and monitoring         │
│  - BAA signing and compliance documentation           │
│  - Incident response procedures                       │
│  - Training and awareness                             │
├──────────────────────────────────────────────────────┤
│              CLOUD PROVIDER RESPONSIBILITY            │
│  - Physical security of data centers                  │
│  - Hardware maintenance and disposal                  │
│  - Network infrastructure (backbone, DDoS)            │
│  - Hypervisor and host OS security                    │
│  - Service availability and redundancy                │
│  - Compliance certifications (SOC 2, ISO 27001)       │
│  - BAA terms and legal framework                      │
└──────────────────────────────────────────────────────┘
```

---

## 9. HIPAA for Modern Architectures

### 9.1 Microservices and HIPAA

Microservices introduce additional HIPAA considerations:

| Challenge | Solution |
|-----------|---------|
| PHI flows across service boundaries | Service mesh with mTLS (Istio, Linkerd); encrypt PHI in transit between all services |
| Multiple services store PHI | Centralize PHI in a dedicated data service; other services reference by ID only |
| Audit trail fragmented across services | Centralized audit log service; correlation IDs across all service calls |
| Access control per service | Centralized AuthZ service (OPA/Cedar); propagate user context via JWT claims |
| Breach scope unclear | PHI data mapping per service; clear ownership; network segmentation |

**PHI Minimization Pattern:**

```
Anti-pattern: Every service stores full patient records
┌──────────┐  ┌──────────┐  ┌──────────┐
│Scheduling │  │ Billing  │  │  CDS     │
│ Service   │  │ Service  │  │ Engine   │
│ has: name,│  │ has: name│  │ has: name│
│ DOB, MRN, │  │ SSN, MRN,│  │ MRN,    │
│ insurance │  │ address  │  │ diagnosis│
└──────────┘  └──────────┘  └──────────┘

Preferred: Centralized PHI, services reference by ID
┌──────────┐  ┌──────────┐  ┌──────────┐
│Scheduling │  │ Billing  │  │  CDS     │
│ Service   │  │ Service  │  │ Engine   │
│ has:      │  │ has:     │  │ has:     │
│ patient_id│  │patient_id│  │patient_id│
│ slot_time │  │ amount   │  │ rules    │
└─────┬────┘  └─────┬────┘  └─────┬────┘
      │              │              │
      └──────────────┼──────────────┘
                     ▼
              ┌──────────────┐
              │  Patient     │
              │  Service     │
              │  (PHI owner) │
              │  RBAC + Audit│
              └──────────────┘
```

### 9.2 Containers and HIPAA

| Requirement | Implementation |
|-------------|---------------|
| Image security | Scan images for vulnerabilities (Trivy, Grype); use minimal base images (distroless) |
| Runtime isolation | No privileged containers; read-only root filesystem; no host networking |
| Secrets management | Never bake secrets in images; use Kubernetes Secrets (encrypted at rest), Vault, or CSI Secret Store |
| Logging | Container logs must not contain PHI; structured logging with PHI scrubbing |
| Network segmentation | Kubernetes NetworkPolicies to restrict pod-to-pod communication; namespace isolation |
| Image provenance | Sign images (cosign/Notary); only deploy from trusted registries |

### 9.3 Serverless and HIPAA

| Concern | AWS Lambda / Cloud Functions |
|---------|-----|
| Cold storage of PHI | Function memory is ephemeral — no PHI persists in function runtime |
| Environment variables | Encrypt with KMS; never store PHI in env vars |
| Logging | CloudWatch/Cloud Logging are HIPAA-eligible; but scrub PHI from log output |
| VPC access | Use VPC-attached Lambda for database access; no public internet for PHI |
| Timeout/retry | Ensure idempotent processing; failed PHI operations must not leave partial state |
| Concurrency | Account for burst concurrency in audit logging (don't lose audit events) |

### 9.4 AI/ML and HIPAA

Using AI/ML with PHI requires careful consideration:

| Concern | Approach |
|---------|---------|
| Training data | De-identify before training when possible; if using PHI, document in risk analysis |
| Model storage | Models trained on PHI should be treated as containing PHI (membership inference risk) |
| Third-party AI (OpenAI, Claude, etc.) | Most do NOT have healthcare BAAs. Verify before sending PHI. Use de-identified data or self-hosted models |
| LLM API calls | Never send raw PHI to third-party LLMs without BAA and documented risk assessment |
| Model explainability | Clinical AI may need to explain decisions (FDA, clinical safety); maintain audit trail of model inputs/outputs |
| Bias and fairness | Healthcare AI must be evaluated for demographic bias; document in risk analysis |
| FDA oversight | Clinical AI that influences treatment decisions may be SaMD — check FDA requirements |

---

## 10. State-Specific Health Privacy Laws

Many states have laws stricter than HIPAA. You must comply with both federal HIPAA and applicable state laws (the stricter standard prevails):

| State | Law | Key Additions Beyond HIPAA |
|-------|-----|---------------------------|
| **California** | CMIA (Confidentiality of Medical Information Act), CCPA/CPRA | Broader definition of medical information; private right of action for breaches; 15-day breach notification |
| **New York** | SHIELD Act, Mental Hygiene Law | 72-hour breach notification; stricter protections for mental health and HIV |
| **Texas** | HB 300, TMRA | 60-day notification; training requirements; specific EHR privacy requirements |
| **Washington** | My Health My Data Act | Broadly applies beyond HIPAA covered entities; consent for health data collection; geofencing restrictions |
| **Colorado** | Colorado Privacy Act, HB23-1006 | Health data protections in general privacy law |
| **Connecticut** | PA 22-15 | Consumer health data protections |
| **Nevada** | SB 370 | Consumer health data act |

**Important**: State laws are evolving rapidly (2024-2026 saw significant new health privacy legislation). Always use `WebSearch` to verify current state requirements.

---

## 11. 42 CFR Part 2 — Substance Use Disorder Records

42 CFR Part 2 provides **stricter protections** than HIPAA for records of substance use disorder (SUD) treatment. Recent amendments (effective February 2024) partially aligned Part 2 with HIPAA, but significant differences remain:

### Key Differences from HIPAA

| Aspect | HIPAA | 42 CFR Part 2 |
|--------|-------|---------------|
| Consent for treatment/payment/operations | Not required | Required (specific written consent) |
| Consent requirements | General authorization | Must specify who, what, why, how much, expiration |
| Re-disclosure | Generally permitted for TPO | Prohibited — must include "prohibition on re-disclosure" notice |
| Breach notification | 60 days | 60 days (aligned with HIPAA under 2024 amendments) |
| Scope | All PHI | SUD treatment records from federally assisted programs |
| Penalties | Civil and criminal | Civil, criminal, AND specific Part 2 penalties |
| Use in legal proceedings | Subpoena possible | Generally inadmissible without patient consent |

### Implementation Considerations

- **Segmentation**: SUD records should be segmented (tagged) so consent rules can be enforced separately
- **Consent tracking**: Maintain separate consent records for Part 2 data with all required elements
- **Re-disclosure controls**: When sharing Part 2 data, include the mandated re-disclosure notice
- **System design**: The system must be able to distinguish Part 2 records and apply stricter rules automatically

---

## 12. HITRUST CSF & HIPAA

HITRUST CSF (Common Security Framework) is a certifiable framework that maps to HIPAA, NIST, ISO 27001, PCI DSS, and other standards. Many large healthcare organizations (health systems, payers) require HITRUST certification from their vendors.

### HITRUST Assessment Types

| Type | Effort | Validity | Best For |
|------|--------|----------|----------|
| **e1** (Essential) | 1-3 months | 1 year | Startups, low-risk organizations, first assessment |
| **i1** (Implemented) | 3-6 months | 1 year | Mid-size, demonstrates implemented controls |
| **r2** (Risk-based) | 6-12 months | 2 years | Enterprise, comprehensive risk-based assessment |

### HITRUST and HIPAA Relationship

HITRUST is not required by HIPAA, but it provides:
- A structured way to demonstrate HIPAA compliance
- Third-party certification (trusted by healthcare industry)
- Cross-framework compliance (one assessment covers multiple standards)
- Increasingly required by large health systems as a vendor requirement

---

## 13. Compliance Automation & Tooling

### 13.1 Compliance Platforms

| Platform | What It Does | Healthcare Suitability |
|----------|-------------|----------------------|
| **Vanta** | Automated compliance monitoring, evidence collection, policy templates | HIPAA framework supported, integrates with AWS/GCP/Azure |
| **Drata** | Continuous compliance monitoring, automated evidence | HIPAA framework, real-time monitoring dashboard |
| **Secureframe** | Compliance automation, vendor management | HIPAA + HITRUST support |
| **Dash (by Dash Solutions)** | Healthcare-specific compliance | Purpose-built for healthcare, HITRUST support |
| **Tugboat Logic (now OneTrust)** | GRC platform, compliance automation | Broad framework support including HIPAA |
| **Sprinto** | Compliance automation for startups | HIPAA support, faster onboarding |

### 13.2 Technical Controls Automation

| Tool | Purpose | HIPAA Relevance |
|------|---------|----------------|
| **AWS Config** | Continuous configuration compliance | Detect non-compliant resources (unencrypted, public) |
| **AWS Security Hub** | Aggregated security findings | HIPAA compliance checks built-in |
| **GCP Security Command Center** | Security posture management | Healthcare compliance monitoring |
| **Azure Policy** | Policy-as-code enforcement | HIPAA policy initiatives |
| **Open Policy Agent (OPA)** | Authorization policy engine | Enforce RBAC/ABAC for PHI access |
| **Cedar (AWS)** | Authorization policy language | Fine-grained healthcare access control |
| **HashiCorp Vault** | Secrets management, encryption as a service | PKI, dynamic credentials, transit encryption |
| **Trivy/Grype** | Container vulnerability scanning | Scan for vulnerabilities in healthcare images |
| **Amazon Macie** | PHI detection in S3 | Automatically discover and classify PHI |

---

## 14. HIPAA Enforcement & Penalties

### 14.1 Penalty Tiers (Effective January 28, 2026, inflation-adjusted)

| Tier | Knowledge Level | Min Per Violation | Max Per Violation | Annual Cap |
|------|----------------|------------------|------------------|------------|
| **Tier 1** | Didn't know and wouldn't have known | $145 | $36,505 | $36,505 |
| **Tier 2** | Reasonable cause (not willful neglect) | $1,461 | $73,011 | $146,053 |
| **Tier 3** | Willful neglect, corrected within 30 days | $14,602 | $73,011 | $365,052 |
| **Tier 4** | Willful neglect, NOT corrected within 30 days | $73,011 | $2,190,294 | $2,190,294 |

Note: OCR's 2019 Notice of Enforcement Discretion reduced annual caps for Tiers 1-3. These adjusted figures reflect that guidance plus inflation adjustments.

**Criminal penalties** (DOJ):
- Knowingly obtaining/disclosing PHI: Up to $50,000 fine and 1 year imprisonment
- Under false pretenses: Up to $100,000 and 5 years
- For personal gain, malicious harm, or commercial advantage: Up to $250,000 and 10 years

### 14.2 Recent Enforcement Trends (2024-2026)

Always use `WebSearch` to verify the latest enforcement actions and trends.

**Enforcement volume**: 22 investigations resulting in penalties/settlements in 2024 alone — one of the busiest enforcement years. 10 penalties announced by end of May 2025. Total collections since 2024: $9.4M+. 17 of 20 recent enforcement actions targeted covered entities (not BAs).

**Top enforcement focus areas (2025-2026):**
- **Risk analysis failures** (most common — cited in 13 of 22 actions in 2024)
- **Insufficient access controls** (excessive access, no audit review)
- **Lack of encryption** (especially for portable devices and backups)
- **Business Associate oversight failures** (no BAAs, no monitoring)
- **Right of access failures** (not providing patient records timely — 30 days with one 30-day extension)
- **Hacking/ransomware response adequacy** (increasing enforcement focus)
- **Online tracking technology** on healthcare websites (pixels, cookies sharing PHI with Meta, Google)
- **Reproductive health privacy** (new protections following Dobbs decision)

### 14.3 OCR Audit Protocol

When OCR investigates, they typically review:

```
OCR Investigation Focus Areas:
1. Risk Analysis
   - Is there a current, comprehensive risk analysis?
   - Does it cover all systems with ePHI?
   - Are identified risks being actively managed?

2. Risk Management
   - Is there a risk management plan?
   - Are mitigation measures implemented?
   - Is progress tracked?

3. Information System Activity Review
   - Are audit logs reviewed regularly?
   - Is there a process for investigating anomalies?
   - How frequently are reviews conducted?

4. Access Controls
   - Is access role-based and minimum necessary?
   - Are access rights reviewed periodically?
   - Is there a process for termination/modification?

5. Security Awareness Training
   - Is training provided to all workforce members?
   - Is it documented and tracked?
   - Does it cover current threats?

6. Contingency Planning
   - Is there a disaster recovery plan?
   - Has it been tested?
   - Are backups encrypted and tested?

7. BAA Management
   - Are BAAs in place with all Business Associates?
   - Do BAAs contain required provisions?
   - Is there a process for monitoring BA compliance?
```
