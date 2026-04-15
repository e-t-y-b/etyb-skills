# Security Compliance & Governance — Deep Reference

**Always use `WebSearch` to verify dates, fine amounts, and enforcement deadlines. Regulatory landscape changes rapidly.**

## Table of Contents
1. [SOC 2 Type II](#1-soc-2-type-ii)
2. [GDPR](#2-gdpr)
3. [HIPAA](#3-hipaa)
4. [PCI DSS v4.0.1](#4-pci-dss-v401)
5. [EU Cyber Resilience Act (CRA)](#5-eu-cyber-resilience-act-cra)
6. [EU AI Act](#6-eu-ai-act)
7. [ISO 27001:2022](#7-iso-270012022)
8. [NIST Cybersecurity Framework 2.0](#8-nist-cybersecurity-framework-20)
9. [FedRAMP](#9-fedramp)
10. [Privacy Frameworks](#10-privacy-frameworks)
11. [Compliance-as-Code](#11-compliance-as-code)
12. [Data Classification & Retention](#12-data-classification--retention)

---

## 1. SOC 2 Type II

### Trust Services Criteria (TSC)
Developed by AICPA. Five categories, **Security is mandatory** for every SOC 2 audit:

| Criterion | Focus | Required |
|-----------|-------|----------|
| **Security** (Common Criteria) | Protection from unauthorized access, disclosure, modification | Yes (always) |
| **Availability** | System uptime and operational commitments | Optional |
| **Processing Integrity** | Data processing is complete, valid, accurate, timely | Optional |
| **Confidentiality** | Data classified as confidential is protected | Optional |
| **Privacy** | Personal information lifecycle management | Optional |

Core criteria framework established in 2017. AICPA issued revised points of focus in 2022 addressing evolving technologies, threats, and regulatory requirements.

### Type I vs Type II
- **Type I**: Point-in-time assessment — controls are suitably designed at a specific date
- **Type II**: Period assessment — controls are designed AND operating effectively over 3-12 months
- Type II is the standard enterprises demand from vendors

### Audit Process
1. **Scoping**: Select applicable TSC categories based on services provided
2. **Readiness Assessment**: Gap analysis against selected criteria (optional but recommended)
3. **Control Implementation**: Deploy controls, policies, procedures
4. **Observation Period**: 3-12 months of operating controls (Type II)
5. **Evidence Collection**: Automated + manual evidence gathering
6. **Audit Examination**: Independent CPA firm tests controls
7. **Report Issuance**: SOC 2 report with opinion letter, system description, control tests

### Compliance Automation Platforms (2025-2026 Comparison)

| Platform | Integrations | Starting Price | Best For | Market Position |
|----------|-------------|---------------|----------|-----------------|
| **Vanta** | 400+ native | ~$10K-12K/yr (Core) | Engineering-heavy startups, deep AWS/GCP/Azure evidence | Largest market share, broadest integrations |
| **Drata** | 200+ native | ~$7K-7.5K/yr | HR/device management automation, guided onboarding | Best UI/UX, white-glove support |
| **Secureframe** | Custom + API | Low five-figure range | Enterprise/custom/legacy environments | Developer-friendly API, advisory services |
| **Sprinto** | 80+ native | ~$4K-5K/yr | Cost-conscious SMBs, APAC market, multi-framework | ~10% market share, autonomous GRC |
| **Thoropass** (formerly Laika) | 90+ auditor-vetted | ~$8K-11K/yr (platform) | Bundled audit + platform in one vendor | In-house auditors, First Pass AI |
| **Laika** | Merged into Thoropass | See Thoropass | See Thoropass | Rebranded to Thoropass |

**Vanta (Detail)**:
- Tests run hourly by default, up to ~1,200 checks/hour
- Supports 35+ compliance frameworks (SOC 2, ISO 27001, HITRUST, HIPAA, PCI DSS, GDPR, etc.)
- AI powers evidence collection, continuous monitoring, security reviews, vendor risk
- Plans: Core (~$10K), Plus ($15K-$30K), Growth ($30K+)

**Drata (Detail)**:
- AI agent for vendor risk evaluations (2025 feature)
- Added DORA, NIS2, ISO 42001 (AI risk management) framework support in 2025
- Mid-tier plans ~$15K, large deployments $40K+
- Personalized support with dedicated success managers

**Sprinto (Detail)**:
- Magic Mapping, continuous control monitoring, guided audit workflows
- Multi-framework/multi-entity: layer SOC 2, ISO 27001, HIPAA on single control set
- Map controls once, reuse evidence across audits
- All-inclusive pricing (no extra fees for risk assessments, policy templates, security training)

**Thoropass (Detail)**:
- In-platform auditors run readiness checks before formal audit
- First Pass AI flags gaps pre-audit
- Combined platform + audit reduces certification timelines from months to weeks
- Median buyer price ~$30K/yr when factoring bundled services

---

## 2. GDPR

### Current State (2025-2026)
- **Cumulative fines**: ~EUR 5.88 billion since GDPR took effect (by March 2025)
- **Total fines recorded**: 2,245 as of March 1, 2025
- **2024 enforcement**: ~EUR 1.2 billion issued during 2024 alone

### Largest Fines (Top 10 All-Time)

| Rank | Entity | Amount | Year | Violation |
|------|--------|--------|------|-----------|
| 1 | Meta (Facebook) | EUR 1.2B | 2023 | Data transfers to US without sufficient safeguards |
| 2 | Amazon | EUR 746M | 2021 | Improper data handling / targeted advertising |
| 3 | TikTok | EUR 530M | 2025 | Illegally transferring EEA user data to China (Art. 46(1)) |
| 4 | Instagram | EUR 405M | 2022 | Children's data protection failures |
| 5 | LinkedIn | EUR 310M | 2024 | Behavioral analysis and targeted advertising violations |
| 6 | Meta (Facebook) | EUR 251M | 2024 | Security breach affecting 29M users globally |
| 7 | WhatsApp | EUR 225M | 2021 | Transparency failures |
| 8 | Google (CNIL) | EUR 100M+ | Various | Cookie consent manipulation (dark patterns) |

**Enforcement patterns**: 40% of top fines relate to minors' data. Non-compliance with general processing principles triggers largest penalties.

### GDPR Omnibus / Reform Proposals (Q4 2025)
The European Commission's Digital Package proposal introduces three major changes:
1. **SME Relief**: Records of Processing Activities exemption expanded from <250 employees to <750 employees
2. **Cookie Banner Standardization**: Mandatory one-click reject with equal prominence to accept
3. **AI Compliance Clarification**: Explicit permission to rely on legitimate interests for AI-related processing

### GDPR and AI Act Interaction
- **Parallel sanctions**: Fines can be imposed under both GDPR and AI Act simultaneously
- **LLM anonymization**: EDPB April 2025 report clarifies LLMs rarely achieve anonymization standards
- **Controller obligations**: Third-party LLM deployers must conduct comprehensive legitimate interests assessments
- **Technology-neutral no more**: AI explicitly embedded in GDPR reform framework (November 2025 GDPR Omnibus)
- **Narrowing "personal data"**: Definition being refined based on recent CJEU rulings

### Key Data Subject Rights
| Right | GDPR Article | Automation Notes |
|-------|-------------|-----------------|
| Right of access | Art. 15 | Automate via data subject access request (DSAR) portals |
| Right to erasure | Art. 17 | Cascading deletion across systems, verify with data maps |
| Right to portability | Art. 20 | Machine-readable export (JSON/CSV) |
| Right to rectification | Art. 16 | Propagate corrections across all processing systems |
| Right to object | Art. 21 | Automated opt-out workflows |
| Right to restrict processing | Art. 18 | Tag and freeze data in place |
| Right not to be subject to automated decisions | Art. 22 | Human-in-the-loop mechanisms for AI/ML systems |

---

## 3. HIPAA

### Proposed Security Rule Updates (2025-2026)
On **December 27, 2024**, HHS/OCR issued a Notice of Proposed Rulemaking (NPRM) to modify the HIPAA Security Rule. Published in Federal Register **January 6, 2025**. 60-day comment period concluded **March 7, 2025**.

**Major changes proposed**:
- **Encryption mandate**: All ePHI encrypted at rest AND in transit — no longer "addressable"
- **MFA requirement**: Multi-factor authentication across ALL ePHI access points
- **Elimination of "addressable"**: All implementation specifications become "required" with limited exceptions
- **72-hour notification**: Restore access to ePHI within 72 hours of incident
- **Annual risk assessments**: Formalized requirement
- **Asset inventory**: Technology asset inventory and network map required
- **Patch management**: Specific timelines for critical vulnerability remediation

**Status**: Regulatory freeze from January 31, 2025 executive order. Final rule expected late 2025 or early 2026, with 6-24 month compliance deadline after publication.

### HITECH Act Relationship
- **HITECH Act (2009)**: Extended HIPAA requirements to business associates, increased penalties, established breach notification requirements
- **Penalty tiers**: Four tiers from $100-$50,000 per violation up to $1.5M annual maximum per violation category
- **Safe harbor**: Recognized security practices (NIST CSF, HIPAA Security Rule best practices) considered as mitigating factor in enforcement (2021 HITECH amendment)
- **Audit authority**: OCR can conduct periodic audits of covered entities and business associates

### PHI Handling Best Practices
```
PHI Protection Layers:
├── Administrative Safeguards
│   ├── Security Officer designation
│   ├── Risk analysis and management
│   ├── Workforce training and awareness
│   ├── Access management policies
│   └── Contingency planning
├── Physical Safeguards
│   ├── Facility access controls
│   ├── Workstation use policies
│   ├── Device and media controls
│   └── Disposal procedures
└── Technical Safeguards
    ├── Access controls (unique user IDs, emergency access)
    ├── Audit controls (logging all ePHI access)
    ├── Integrity controls (mechanism to authenticate ePHI)
    ├── Transmission security (encryption in transit)
    └── Authentication (verify persons seeking access)
```

### Cloud HIPAA Compliance (AWS, Azure, GCP)

| Feature | AWS | Azure | GCP |
|---------|-----|-------|-----|
| **BAA** | Standard BAA covering 100+ services | Part of Online Service Terms for enterprise | Standard terms for covered services |
| **HIPAA-eligible services** | 100+ (EC2, S3, RDS, Lambda, etc.) | 80+ (Azure VMs, SQL, Blob, etc.) | 60+ (Compute Engine, BigQuery, Cloud Storage, etc.) |
| **Encryption** | AES-256 at rest, TLS in transit | AES-256, Azure Key Vault | AES-256, Cloud KMS |
| **Audit logging** | CloudTrail, CloudWatch | Azure Monitor, Diagnostic Logs | Cloud Audit Logs |
| **Compliance tools** | AWS Audit Manager, Config | Azure Policy, Compliance Manager | Security Command Center |
| **AI/ML services** | SageMaker (HIPAA-eligible) | Azure AI (HIPAA-eligible) | Vertex AI (HIPAA-eligible with BAA) |

**Critical**: Signing a BAA does NOT make your deployment HIPAA-compliant. Compliance is a **shared responsibility** — your organization must properly configure services, manage access controls, encrypt data, and maintain audit logs. Cloud AI/ML services are "HIPAA-eligible" not automatically "HIPAA-compliant."

---

## 4. PCI DSS v4.0.1

### Version Timeline
| Date | Event |
|------|-------|
| March 2022 | PCI DSS v4.0 released |
| March 31, 2024 | v3.2.1 retired, v4.0 becomes only active version |
| June 2024 | PCI DSS v4.0.1 published (limited revision) |
| December 31, 2024 | v4.0 retired, v4.0.1 becomes only active version |
| **March 31, 2025** | **All future-dated requirements become mandatory** |

### Key Changes from v3.2.1 to v4.0/v4.0.1

**Client-Side Security (NEW)**:
- **Req 6.4.3**: Payment page script management — maintain inventory of all JavaScript on payment pages, confirm each script is authorized, ensure integrity
- **Req 11.6.1**: Change/tamper detection for HTTP headers and payment page content, run at least weekly

**Authentication Enhancements**:
- **Req 8.3.6**: Minimum password length increased from 7 to 12 characters (or 8 if system cannot support 12)
- **Req 8.4.2**: MFA required for all access to the cardholder data environment (not just remote access)
- **Req 8.6.3**: Passwords/passphrases for application/system accounts managed and changed periodically

**Risk-Based Approach**:
- **Customized Approach**: Alternative to defined approach — meet security objective via custom controls with documented risk analysis
- **Targeted Risk Analysis**: Required for controls where entity defines frequency/scope

**Encryption and Key Management**:
- **Req 3.5.1.2**: Disk-level encryption only acceptable for removable media (not for primary storage)
- **Req 12.3.3**: Cryptographic cipher suites and protocols documented and reviewed annually

**Logging and Monitoring**:
- **Req 10.4.1.1**: Automated audit log review mechanisms
- **Req 10.7.2**: Prompt detection and response to failures of critical security control systems

**v4.0.1 Specific Clarification**:
- Reverted to v3.2.1 language: 30-day patching applies only to "critical vulnerabilities" (v4.0 had expanded to "critical and high severity")

### SAQ Types

| SAQ Type | Applies To | Key Requirements |
|----------|-----------|-----------------|
| **SAQ A** | Card-not-present merchants fully outsourcing payment processing | v4.0.1: No longer requires 6.4.3/11.6.1, BUT must confirm entire website secure from script attacks |
| **SAQ A-EP** | E-commerce merchants partially outsourcing | Must implement 6.4.3 and 11.6.1 |
| **SAQ B** | Merchants with imprint machines or standalone terminals (no electronic storage) | Limited controls |
| **SAQ B-IP** | Merchants with standalone PTS terminals connected via IP | Network segmentation focus |
| **SAQ C** | Merchants with payment application systems connected to internet | Application security controls |
| **SAQ C-VT** | Merchants with web-based virtual terminals | Virtual terminal security |
| **SAQ D** | All other merchants AND all service providers | Full PCI DSS requirements |
| **SAQ P2PE** | Merchants using validated P2PE solutions | Reduced scope via hardware encryption |

---

## 5. EU Cyber Resilience Act (CRA)

### Status and Timeline
- **Regulation**: (EU) 2024/2847
- **Entered into force**: December 10, 2024
- **Reporting obligations**: September 11, 2026 (manufacturers must report actively exploited vulnerabilities)
- **Full application**: December 11, 2027 (main obligations apply)

### Requirements for Software Products
Applies to ALL "products with digital elements" sold in the EU:
- Hardware and software products that connect to networks (directly or indirectly)
- Standalone software distributed commercially
- Cloud/SaaS solutions that process data on behalf of users

**Manufacturer Obligations**:
1. **Security by design**: Products must meet essential cybersecurity requirements before market placement
2. **Vulnerability handling**: Establish coordinated vulnerability disclosure process
3. **Security updates**: Provide security updates for product lifetime (minimum 5 years)
4. **Incident reporting**: Report actively exploited vulnerabilities to ENISA within 24 hours (from Sept 2026)
5. **Documentation**: Technical documentation, EU declaration of conformity, CE marking
6. **SBOM**: Machine-readable Software Bill of Materials

### SBOM Mandates
- **Format**: Machine-readable, "commonly used" format required (SPDX or CycloneDX expected but not mandated)
- **Coverage**: At minimum top-level dependencies
- **Maintenance**: Must be kept up to date throughout product lifecycle
- **Disclosure**: Provided to market-surveillance authorities on request (NOT required to be made public)
- **Draft standard**: Horizontal standard for Annex I requirements (including SBOM schema) expected by mid-2026

### Open Source Impact
```
CRA Open Source Classification:
├── Commercial OSS (covered by CRA)
│   ├── OSS integrated into commercial products
│   ├── OSS with paid support/services
│   └── OSS monetized through dual licensing
├── Open Source Stewards (lighter obligations)
│   ├── Foundations managing OSS projects
│   ├── Must establish cybersecurity policy
│   └── Must cooperate with market surveillance
└── Non-Commercial OSS (exempt)
    ├── Purely hobby/non-monetized development
    ├── Academic/research projects
    └── Internal-use-only tools
```

**Penalties**: Up to EUR 15 million or 2.5% of global turnover.

---

## 6. EU AI Act

### Regulation: (EU) 2024/1689
Published in Official Journal August 1, 2024.

### Risk Classification Tiers

```
Unacceptable Risk (PROHIBITED) — Effective Feb 2, 2025
├── Subliminal manipulation causing harm
├── Exploitation of vulnerabilities (age, disability, social situation)
├── Social scoring by public authorities
├── Predictive policing based solely on profiling
├── Untargeted facial recognition database scraping
├── Emotion recognition in workplaces/education
├── Biometric categorization using sensitive attributes
└── Real-time remote biometric ID in public spaces (3 narrow exceptions)

High Risk (STRICTLY REGULATED) — Effective Aug 2, 2026
├── Annex III listed systems:
│   ├── Biometric identification and categorization
│   ├── Critical infrastructure management
│   ├── Education and vocational training
│   ├── Employment, worker management, self-employment
│   ├── Essential services access (credit, insurance)
│   ├── Law enforcement
│   ├── Migration, asylum, border control
│   └── Administration of justice and democratic processes
└── Requirements:
    ├── Risk management system
    ├── Data governance
    ├── Technical documentation
    ├── Record-keeping / logging
    ├── Transparency and user information
    ├── Human oversight
    ├── Accuracy, robustness, cybersecurity
    ├── Quality management system
    ├── Conformity assessment + CE marking
    └── EU database registration

Limited Risk (TRANSPARENCY OBLIGATIONS)
├── AI chatbots / conversational AI → must disclose AI interaction
├── Emotion recognition systems → must inform subjects
├── Deepfake generators → must label content as AI-generated
└── AI-generated text published as news → must disclose

Minimal Risk (NO SPECIFIC OBLIGATIONS)
├── AI-enabled video games
├── Spam filters
├── Inventory management
└── Most consumer AI applications
```

### General-Purpose AI (GPAI) Models
**Effective August 2, 2025**:

| Obligation | All GPAI Providers | Systemic Risk GPAI |
|-----------|-------------------|-------------------|
| Technical documentation | Required | Required |
| Training content summary | Required (public) | Required (public) |
| Copyright Directive compliance | Required | Required |
| Model evaluations | -- | Required |
| Adversarial testing | -- | Required |
| Serious incident tracking/reporting | -- | Required |
| Cybersecurity protections | -- | Required |

**Systemic risk threshold**: Cumulative training compute > 10^25 FLOPs.

### Timeline Summary
| Date | Milestone |
|------|-----------|
| August 1, 2024 | Published in Official Journal |
| February 2, 2025 | Prohibitions on unacceptable-risk AI take effect |
| August 2, 2025 | GPAI obligations + governance infrastructure operational |
| August 2, 2026 | High-risk AI system requirements enforceable; Commission enforcement powers active |
| August 2, 2027 | Extended transition for high-risk AI embedded in regulated products |

### Penalties
| Violation | Maximum Fine |
|-----------|-------------|
| Prohibited AI practices | EUR 35M or 7% global turnover |
| High-risk AI non-compliance | EUR 15M or 3% global turnover |
| Incorrect information to authorities | EUR 7.5M or 1% global turnover |
| SME/startup reductions | Lower of absolute amount or percentage |

---

## 7. ISO 27001:2022

### Key Changes from 2013 Version

| Aspect | ISO 27001:2013 | ISO 27001:2022 |
|--------|---------------|----------------|
| **Total controls** | 114 | 93 |
| **Control domains** | 14 domains | 4 themes |
| **New controls** | -- | 11 new controls added |
| **Merged controls** | -- | 56 controls merged into 24 |
| **Unchanged controls** | -- | 58 with minor updates |
| **Clause structure** | 10 clauses | 10 clauses (refined) |

### Four Control Themes (Annex A)
| Theme | Controls | Examples |
|-------|----------|---------|
| **Organizational** (A.5) | 37 controls | Policies, roles, threat intelligence, cloud security |
| **People** (A.6) | 8 controls | Screening, awareness, remote working |
| **Physical** (A.7) | 14 controls | Perimeters, equipment, monitoring |
| **Technological** (A.8) | 34 controls | Endpoints, access, cryptography, coding |

### 11 New Controls

| Control ID | Name | Theme | Purpose |
|-----------|------|-------|---------|
| A.5.7 | Threat intelligence | Organizational | Collect, analyze threat data for proactive defense |
| A.5.23 | Information security for cloud services | Organizational | Cloud acquisition, use, management, exit security |
| A.5.30 | ICT readiness for business continuity | Organizational | ICT recovery planning and testing |
| A.7.4 | Physical security monitoring | Physical | Surveillance and detection systems |
| A.8.9 | Configuration management | Technological | Secure baseline configurations |
| A.8.10 | Information deletion | Technological | Secure disposal when no longer needed |
| A.8.11 | Data masking | Technological | Limit exposure of sensitive data (PII focus) |
| A.8.12 | Data leakage prevention | Technological | DLP controls for data in use/motion/rest |
| A.8.16 | Monitoring activities | Technological | Network/system/application monitoring |
| A.8.23 | Web filtering | Technological | Block access to malicious/unauthorized websites |
| A.8.28 | Secure coding | Technological | Secure development standards and practices |

### Certification Transition
- **Transition deadline**: October 31, 2025 (36 months from transition start October 31, 2022)
- **Certification bodies**: Had 12 months from October 31, 2023 to transition
- **Audit types for transition**: Surveillance audit, Recertification audit, or Special audit
- **New certifications**: Must be against ISO 27001:2022 (2013 no longer issued)

### Certification Process
```
ISO 27001:2022 Certification Path:
├── Stage 1: Documentation Review
│   ├── ISMS scope and policy review
│   ├── Statement of Applicability (SoA)
│   ├── Risk assessment methodology
│   └── Gap identification
├── Stage 2: Implementation Audit
│   ├── Control effectiveness testing
│   ├── Process observation
│   ├── Staff interviews
│   └── Evidence review
├── Certification Decision
│   ├── Audit findings reviewed
│   ├── Non-conformities addressed
│   └── Certificate issued (3-year validity)
└── Surveillance (Annual)
    ├── Year 1: Surveillance audit
    ├── Year 2: Surveillance audit
    └── Year 3: Recertification audit
```

---

## 8. NIST Cybersecurity Framework 2.0

### Release
- **Published**: February 26, 2024
- **Document**: NIST CSWP 29
- **Scope change**: Expanded from critical infrastructure to ALL organizations in any sector

### Six Core Functions (NEW: Govern added)

```
                    ┌──────────┐
                    │  GOVERN  │  (NEW in 2.0)
                    │  (GV)    │
                    └────┬─────┘
                         │
    ┌────────────────────┼────────────────────┐
    │                    │                    │
┌───┴───┐          ┌────┴────┐          ┌────┴────┐
│IDENTIFY│          │ PROTECT │          │ DETECT  │
│ (ID)   │          │  (PR)   │          │  (DE)   │
└───┬───┘          └────┬────┘          └────┬────┘
    │                    │                    │
    │              ┌─────┴─────┐              │
    │              │           │              │
    │          ┌───┴───┐  ┌───┴───┐          │
    └──────────│RESPOND│  │RECOVER│──────────┘
               │ (RS)  │  │ (RC)  │
               └───────┘  └───────┘
```

**Govern sits at the center**, influencing all other functions.

### Govern Function Categories (6 categories, 28 subcategories)

| Category | ID | Focus |
|----------|----|-------|
| **Organizational Context** | GV.OC | Mission, stakeholder expectations, legal/regulatory/contractual requirements |
| **Risk Management Strategy** | GV.RM | Risk tolerance, appetite, enterprise risk integration |
| **Roles, Responsibilities, Authorities** | GV.RR | Cybersecurity leadership, accountability structures |
| **Policy** | GV.PO | Cybersecurity policy establishment and communication |
| **Oversight** | GV.OV | Continuous review and adjustment of risk strategy |
| **Cybersecurity Supply Chain Risk Mgmt** | GV.SC | Third-party/supplier risk, post-agreement provisions |

### Implementation Tiers

| Tier | Name | Governance Rigor | Risk Management |
|------|------|-----------------|-----------------|
| **Tier 1** | Partial | Ad hoc, reactive | Limited awareness, irregular practices |
| **Tier 2** | Risk Informed | Management-approved but not org-wide policy | Awareness exists, inconsistently applied |
| **Tier 3** | Repeatable | Formally established policy, regularly updated | Consistent practices, informed by threat landscape |
| **Tier 4** | Adaptive | Continuously improving based on lessons learned | Real-time risk-informed, predictive capabilities |

### Key Changes from CSF 1.1

| Aspect | CSF 1.1 | CSF 2.0 |
|--------|---------|---------|
| **Functions** | 5 (Identify, Protect, Detect, Respond, Recover) | 6 (+Govern) |
| **Scope** | Critical infrastructure focus | All organizations, all sectors |
| **Governance** | Implicit | Explicit core function |
| **Supply chain** | Addressed in Identify | Elevated to Govern subcategory (GV.SC) |
| **Profiles** | Organizational profiles | Community Profiles + Organizational Profiles |
| **Guidance** | Framework only | Framework + Implementation Examples + Quick-Start Guides |

---

## 9. FedRAMP

### Modernization Overview (FY25-FY26)
FedRAMP is undergoing major modernization via two parallel tracks:

**Track 1: FedRAMP Rev 5** (Evolution of traditional process)
- Transition from NIST SP 800-53 Rev 4 to Rev 5 baselines
- Machine-readable authorization packages required
- Sponsorless certification path (no agency sponsor required)
- "FedRAMP Ready" renamed to "Legacy FedRAMP Ready" (no new submissions accepted)

**Track 2: FedRAMP 20x** (New agile authorization)
- Cloud-native, automation-first approach
- Authorization timeline target: ~3 months (down from 18+ months)
- Uses Key Security Indicators (KSIs) instead of traditional control assessments

### FedRAMP Rev 5 Timeline

| Date | Milestone |
|------|-----------|
| January 13, 2026 | Six new RFCs released (0019-0024) |
| April 15, 2026 | Materials published to support adoption |
| September 30, 2026 | Machine-readable package requirements take effect |
| September 30, 2027 | Grace period expires — non-compliant services lose FedRAMP certification |

**Key Rev 5 Features**:
- **Machine-Readable Packages**: Authorization packages must be tool-ingestible (OSCAL format)
- **Minimum Assessment Standard (MAS)**: Optionally replaces boundary guidance, simplifies scope
- **Significant Change Notifications (SCN)**: Optionally replaces Significant Change Request process
- **Sponsorless Certification**: Rev5 path without agency sponsor requirement

### FedRAMP 20x Phases

| Phase | Timeline | Focus |
|-------|----------|-------|
| **Phase 1** | 2025 (completed) | Low baseline pilot, establish KSI framework |
| **Phase 2** | Nov 2025 - Mar 2026 | Moderate baseline pilot, 13 participants, 2 cohorts |
| **Phase 3** | Q3-Q4 2026 (target) | Wide-scale public adoption for Low and Moderate |

**20x Phase 2 Details**:
- Formally began November 2025
- Cohort 1 final submission: January 30, 2026
- Cohort 2 final submission: March 13, 2026
- ~13 total pilot participants (SaaS providers)

### Authorization Levels

| Impact Level | Description | Controls (Rev 5) |
|-------------|-------------|-------------------|
| **Low** | Limited adverse effect | ~156 controls |
| **Moderate** | Serious adverse effect | ~325 controls |
| **High** | Severe or catastrophic effect | ~421 controls |
| **LI-SaaS** | Low Impact SaaS (streamlined) | Subset of Low controls |

---

## 10. Privacy Frameworks

### CCPA/CPRA (California)
- **CCPA**: Effective January 1, 2020
- **CPRA**: Approved November 2020, effective January 1, 2023 (amends CCPA, does not replace)
- **Enforcer**: California Privacy Protection Agency (CPPA)

**2025 Thresholds**:
- Annual revenue exceeding $25 million (reduced from $50M in 2023)
- Handle data of 100,000+ California residents/households
- Derive 50%+ revenue from selling/sharing personal data

**Key CPRA additions over CCPA**:
- Right to correct inaccurate personal information
- Right to limit use of sensitive personal information
- Dedicated enforcement agency (CPPA)
- Data minimization and purpose limitation requirements
- Automated decision-making opt-out rights

### US State Privacy Laws Landscape (2025-2026)

**20+ states** have enacted comprehensive privacy laws as of 2026:

| State | Law | Effective Date |
|-------|-----|---------------|
| California | CCPA/CPRA | Jan 1, 2020 / Jan 1, 2023 |
| Virginia | VCDPA | Jan 1, 2023 |
| Colorado | ColoPA | Jul 1, 2023 |
| Connecticut | CDPA | Jul 1, 2023 |
| Utah | UCPA | Dec 31, 2023 |
| Oregon | OCPA | Jul 1, 2024 |
| Texas | TDPSA | Jul 1, 2024 |
| Montana | MCDPA | Oct 1, 2024 |
| Delaware | DPDPA | Jan 1, 2025 |
| Iowa | ICDPA | Jan 1, 2025 |
| Nebraska | NDPA | Jan 1, 2025 |
| New Hampshire | NHPA | Jan 1, 2025 |
| New Jersey | NJDPA | Jan 15, 2025 |
| Tennessee | TIPA | Jul 1, 2025 |
| Minnesota | MCDPA | Jul 31, 2025 |
| Maryland | MODPA | Oct 1, 2025 (enforcement Apr 1, 2026) |
| Indiana | IDPA | Jan 1, 2026 |
| Kentucky | KCDPA | Jan 1, 2026 |
| Rhode Island | RIDPA | Jan 1, 2026 |

**2025 Amendments**: Colorado, Montana, Oregon all have significant amendments effective in H2 2025 (children's data, geolocation, data broker transparency).

### Brazil LGPD
- **Effective**: August 16, 2020
- **Scope**: Personal data of individuals in Brazil, or data collected/processed in Brazil
- **Enforcer**: ANPD (National Data Protection Authority)
- **Key features beyond GDPR**: Broader legal bases for processing (10 total vs GDPR's 6), explicit protection for data transfers, sensitive data processing requirements
- **Penalties**: Up to 2% of revenue in Brazil (capped at R$50 million per violation)

### Data Localization Requirements (2025-2026)

| Country/Region | Requirements |
|---------------|-------------|
| **Russia** | Copy of personal data stored on local servers. Fines up to RUB 18M (~EUR 200K) for repeat violations. Stricter rules effective July 1, 2025. |
| **China** | PIPL requires adequacy approval, standard contracts, or cybersecurity review for transfers. Financial/health data must remain in mainland China. January 2025 implementing regulations for "important data." |
| **India** | Sensitive personal data stored locally (proposed DPDP Bill). Licensed banks/payment providers must retain data locally. |
| **EU** | Schrems II: Standard Contractual Clauses (SCCs) + Transfer Impact Assessments (TIAs) required for non-adequate countries. EU-US Data Privacy Framework provides adequacy for participating US companies. |
| **US (NEW)** | DOJ Data Security Rule (effective April 2025): Prohibits/restricts bulk sensitive personal data transfers to countries of concern (China, Iran, Russia, etc.) |

---

## 11. Compliance-as-Code

### Policy Engine Comparison

| Engine | Language | Best For | Performance | Ecosystem |
|--------|----------|----------|-------------|-----------|
| **OPA (Open Policy Agent)** | Rego | Infrastructure-wide policy (K8s, APIs, Terraform, CI/CD) | Baseline | CNCF graduated, broad community |
| **OPA/Gatekeeper** | Rego + CEL | Kubernetes admission control | Good | K8s-native via OPA |
| **Kyverno** | YAML (declarative) | Kubernetes-native policy (no Rego needed) | Good | CNCF incubating |
| **AWS Cedar** | Cedar | Fine-grained ABAC/RBAC in AWS ecosystem | 42-60x faster than Rego | AWS Verified Permissions |
| **Google Zanzibar** | Relationship tuples | Relationship-based access control (ReBAC) at scale | Excellent at scale | Google-internal, OSS inspired (OpenFGA, SpiceDB) |
| **Checkov** | Python/YAML | IaC scanning (Terraform, CloudFormation, K8s) | Fast | Bridgecrew/Palo Alto |
| **Sentinel** | Sentinel | HashiCorp ecosystem (Terraform Enterprise, Vault) | Good | HashiCorp only |

### OPA/Rego Deep Dive
```rego
# Example: Enforce container image registry
package kubernetes.admission

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    not startswith(container.image, "registry.company.com/")
    msg := sprintf("Container image '%v' must be from approved registry", [container.image])
}
```
- **Use cases**: K8s admission control, API authorization, Terraform plan validation, microservice policies
- **Deployment**: Sidecar, daemon, library, or centralized service
- **Decision logs**: Full audit trail of policy decisions

### Kyverno Deep Dive
```yaml
# Example: Require resource limits
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-limits
spec:
  validatingAdmissionPolicy: true
  rules:
    - name: check-limits
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "CPU and memory limits are required"
        pattern:
          spec:
            containers:
              - resources:
                  limits:
                    memory: "?*"
                    cpu: "?*"
```
- **Advantages**: No new language to learn (YAML), K8s-native CRDs, built-in reporting/compliance dashboards
- **Features**: Resource mutation, generation, cleanup, image verification, policy autogeneration
- **Reporting**: Out-of-box compliance dashboards, audit functionality for existing resource scanning

### AWS Cedar
```cedar
// Example: Allow project members to read documents
permit (
    principal in Group::"project-team",
    action == Action::"ReadDocument",
    resource in Folder::"project-docs"
) when {
    principal.clearanceLevel >= resource.requiredClearance
};
```
- **Design**: Formally verified, deterministic, safe by construction
- **Performance**: 42-60x faster than Rego in benchmarks
- **Integration**: AWS Verified Permissions, Amazon Cognito
- **Use case**: Application-level authorization, fine-grained permissions

### Automated Evidence Collection
```
Continuous Compliance Pipeline:
├── Source Systems
│   ├── Cloud providers (AWS Config, Azure Policy, GCP SCC)
│   ├── Identity providers (Okta, Azure AD, Google Workspace)
│   ├── Code repositories (GitHub, GitLab)
│   ├── CI/CD pipelines (Jenkins, GitHub Actions)
│   ├── HR systems (BambooHR, Workday, Rippling)
│   └── Endpoint management (Jamf, Intune, CrowdStrike)
├── Collection Layer
│   ├── API integrations (scheduled pulls)
│   ├── Webhook listeners (real-time events)
│   ├── Agent-based collection (endpoint data)
│   └── Log aggregation (SIEM feeds)
├── Policy Engine
│   ├── Control mapping (evidence → framework requirements)
│   ├── Automated testing (pass/fail against policy)
│   ├── Drift detection (continuous monitoring)
│   └── Exception management (documented deviations)
└── Output
    ├── Compliance dashboards (real-time posture)
    ├── Audit-ready evidence packages
    ├── Alert/notification pipelines
    └── Remediation workflows (auto-ticket creation)
```

### Continuous Compliance Monitoring Approach
- **Frequency**: Hourly or real-time checks (vs annual/quarterly audits)
- **Drift detection**: Alert on configuration changes that violate policy
- **Auto-remediation**: Automatically revert non-compliant changes (with approval gates)
- **Evidence retention**: Automated archival with tamper-proof storage (immutable logs)
- **Framework mapping**: Single control maps to multiple frameworks (SOC 2 CC6.1 = ISO 27001 A.8.2 = NIST PR.AC-1)

---

## 12. Data Classification & Retention

### Classification Levels

| Level | Sensitivity | Examples | Access |
|-------|------------|---------|--------|
| **Public** | None | Marketing materials, published APIs, press releases | Anyone |
| **Internal** | Low | Org charts, internal policies, meeting notes | All employees |
| **Confidential** | Medium | Financial reports, business strategies, customer lists | Need-to-know teams |
| **Restricted** | High | PII, PHI, PCI data, trade secrets, credentials | Named individuals only |

**Government/Regulated Extensions**:
- Top Secret, Secret, Confidential, Sensitive, Unclassified (5-tier)
- HIPAA: PHI, ePHI (specific handling requirements)
- PCI: Cardholder data, Sensitive authentication data
- GDPR: Personal data, Special category data

### Automated Classification Tools

| Tool | Vendor | Capabilities | Best For |
|------|--------|-------------|----------|
| **Microsoft Purview** | Microsoft | Sensitivity labels, 300+ sensitive info types, AI-powered classification, DLP, retention labels | Microsoft 365 / Azure ecosystem |
| **Google Sensitive Data Protection** (formerly Cloud DLP) | Google | 150+ predefined detectors, custom detectors, de-identification, risk analysis | GCP / Google Workspace |
| **Amazon Macie** | AWS | ML-powered S3 data discovery, PII/financial data detection, automated alerts | AWS S3 data lakes |
| **Nightfall AI** | Nightfall | API-first DLP, scans SaaS apps (Slack, GitHub, Confluence, Jira), ML detection | SaaS-sprawl environments |
| **BigID** | BigID | Data discovery across cloud/on-prem, ML classification, privacy-centric (DSAR automation) | Multi-cloud data governance |
| **Varonis** | Varonis | File system classification, access pattern analysis, insider threat detection | On-prem file shares, hybrid |

### Microsoft Purview Details
- **Sensitivity labels**: Highly Confidential, Restricted, Confidential, Internal, Public
- **Auto-labeling**: Trainable classifiers + sensitive information types (regex + ML)
- **DLP policies**: Cross-Microsoft 365 (Exchange, SharePoint, Teams, OneDrive, Endpoint)
- **Data lifecycle**: Retention labels, retention policies, records management
- **Compliance Manager**: Pre-built assessments for GDPR, HIPAA, SOC 2, ISO 27001

### Google Sensitive Data Protection Details
- **150+ predefined detectors**: Credit cards, SSN, passport numbers, API keys, etc.
- **Custom detectors**: Regex, dictionary, surrogate type
- **De-identification**: Masking, tokenization, bucketing, date shifting, cryptographic hashing
- **Integration**: BigQuery, Cloud Storage, Datastore, DLP API for custom workloads

### Retention Policy Framework

```
Retention Policy Design:
├── Legal/Regulatory Requirements
│   ├── HIPAA: 6 years for PHI records
│   ├── SOX: 7 years for financial records
│   ├── PCI DSS: 1 year for audit logs
│   ├── GDPR: No longer than necessary (purpose limitation)
│   ├── SEC 17a-4: 3-6 years for broker-dealer records
│   └── Tax records: 7 years (US IRS)
├── Classification-Based Retention
│   ├── Public: Retain indefinitely or until superseded
│   ├── Internal: 3-5 years after last use
│   ├── Confidential: 5-7 years, then secure destruction
│   └── Restricted: Per regulatory requirement, secure destruction
├── Implementation
│   ├── Automated retention labels (Microsoft Purview, Google Vault)
│   ├── Policy-driven lifecycle management
│   ├── Legal hold capability (suspend deletion for litigation)
│   ├── Destruction certificates (documented proof of secure deletion)
│   └── Cross-border considerations (different jurisdictions = different rules)
└── Governance
    ├── Data stewards assigned per classification
    ├── Annual retention policy review
    ├── Exception and override process
    └── Audit trail of all disposition actions
```

### Policy-as-Code for Data Governance
The policy-as-code approach is the leading practice for 2025-2026:
- Governance rules expressed as programmable templates
- Version-controlled alongside application code
- Test, deploy, update policies across environments without manual configuration
- Automated classification in data pipelines (tag-on-ingest)
- Real-time enforcement via data catalogs and access control layers
- Continuous monitoring replaces point-in-time audits

**Key principle (2026)**: Regulators increasingly look for evidence of "living governance" — static compliance documentation is no longer sufficient.

---

## Cross-Reference: Framework Mapping

| Control Area | SOC 2 | ISO 27001 | NIST CSF 2.0 | HIPAA | PCI DSS |
|-------------|-------|-----------|-------------|-------|---------|
| Access Control | CC6.1-CC6.8 | A.5.15-A.5.18, A.8.2-A.8.5 | PR.AA | 164.312(a) | Req 7, 8 |
| Encryption | CC6.1, CC6.7 | A.8.24 | PR.DS-1, PR.DS-2 | 164.312(a)(2)(iv), 164.312(e)(2)(ii) | Req 3, 4 |
| Logging/Monitoring | CC7.1-CC7.4 | A.8.15, A.8.16 | DE.CM, DE.AE | 164.312(b) | Req 10 |
| Incident Response | CC7.3-CC7.5 | A.5.24-A.5.28 | RS.MA, RS.AN | 164.308(a)(6) | Req 12.10 |
| Vulnerability Mgmt | CC7.1 | A.8.8 | ID.RA | 164.308(a)(1) | Req 6, 11 |
| Change Management | CC8.1 | A.8.9, A.8.32 | PR.IP-3 (1.1) | 164.312(e)(2)(ii) | Req 6.5 |
| Vendor/Supply Chain | CC9.2 | A.5.19-A.5.22 | GV.SC | 164.308(b) | Req 12.8 |
| Risk Assessment | CC3.1-CC3.4 | A.5.1-A.5.5 | GV.RM, ID.RA | 164.308(a)(1)(ii)(A) | Req 12.2 |

---

## Sources & Further Reading

### SOC 2
- [SOC 2 Compliance Platforms Compared 2026 (Cavanex)](https://cavanex.com/blog/soc-2-compliance-platforms-compared-2026)
- [Vanta vs Drata vs Secureframe vs Sprinto 2026](https://sprinto.com/blog/secureframe-vs-vanta-vs-drata/)
- [SOC 2 Trust Services Criteria (Secureframe)](https://secureframe.com/hub/soc-2/trust-services-criteria)
- [Best SOC 2 Compliance Software 2026 (Vanta)](https://www.vanta.com/resources/best-soc-2-compliance-software)
- [Thoropass Review 2025](https://sprinto.com/blog/thoropass-review/)

### GDPR
- [GDPR Fines Hit EUR 7.1 Billion (Kiteworks)](https://www.kiteworks.com/gdpr-compliance/gdpr-fines-data-privacy-enforcement-2026/)
- [2025 in Data Protection (CMS Law)](https://cms-lawnow.com/en/ealerts/2026/01/2025-in-data-protection)
- [GDPR Enforcement Tracker Report 2024/2025 (CMS)](https://cms.law/en/int/publication/gdpr-enforcement-tracker-report/numbers-and-figures)
- [Biggest GDPR Fines of 2025](https://complydog.com/blog/biggest-gdpr-fines-of-2025)

### HIPAA
- [HIPAA Security Rule Updates 2025 (HIPAAVault)](https://www.hipaavault.com/resources/hipaa-security-rule-updates-2025/)
- [HIPAA NPRM Factsheet (HHS.gov)](https://www.hhs.gov/hipaa/for-professionals/security/hipaa-security-rule-nprm/factsheet/index.html)
- [HIPAA Cloud Compliance 2026 (Medcurity)](https://medcurity.com/hipaa-cloud-compliance/)
- [HIPAA MFA Requirements 2026](https://www.datawiza.com/blog/industry/hipaa-mfa/)

### PCI DSS
- [PCI DSS v4.0.1 Published (PCI SSC Blog)](https://blog.pcisecuritystandards.org/just-published-pci-dss-v4-0-1)
- [PCI DSS v4.0.1 Changes (Secureframe)](https://secureframe.com/blog/pci-dss-4.0.1)
- [PCI DSS v4.0.1 SAQ A Changes (Akamai)](https://www.akamai.com/blog/security/pci-dss-v4-0-1-changes-qualify-saq-a)
- [PCI DSS v4.0 Key Changes (Secureframe)](https://secureframe.com/blog/pci-dss-4.0)

### EU CRA
- [EU CRA Official (European Commission)](https://digital-strategy.ec.europa.eu/en/policies/cyber-resilience-act)
- [CRA SBOM Requirements (Anchore)](https://anchore.com/sbom/eu-cra/)
- [CRA Open Source Impact (OpenSSF)](https://openssf.org/public-policy/eu-cyber-resilience-act/)
- [One Year Countdown to CRA Compliance (Keysight)](https://www.keysight.com/blogs/en/tech/nwvs/2025/09/11/one-year-countdown-to-eu-cra-compliance-september-11-2026-changes-everything)

### EU AI Act
- [EU AI Act Official (European Commission)](https://digital-strategy.ec.europa.eu/en/policies/regulatory-framework-ai)
- [EU AI Act 2026 Updates (LegalNodes)](https://www.legalnodes.com/article/eu-ai-act-2026-updates-compliance-requirements-and-business-risks)
- [EU AI Act Timeline (DataGuard)](https://www.dataguard.com/eu-ai-act/timeline)
- [Article 5 Prohibited Practices](https://artificialintelligenceact.eu/article/5/)
- [GPAI Guidelines (European Commission)](https://digital-strategy.ec.europa.eu/en/policies/guidelines-gpai-providers)

### ISO 27001
- [ISO 27001:2013 vs 2022 (ANAB)](https://blog.ansi.org/anab/iso-iec-27001-2013-2022-comparison/)
- [11 New Controls Explained (Advisera)](https://advisera.com/27001academy/explanation-of-11-new-iso-27001-2022-controls/)
- [ISO 27001:2022 Changes (Drata)](https://drata.com/grc-central/iso-27001/2022)

### NIST CSF
- [NIST CSF 2.0 Official (NIST)](https://www.nist.gov/cyberframework)
- [CSF 2.0 Complete Guide 2026 (Isora GRC)](https://www.saltycloud.com/blog/nist-csf-2-0-complete-guide-2026/)
- [Govern Function Explained (Arctic Wolf)](https://arcticwolf.com/resources/blog/nist-csf-2-0-understanding-and-implementing-the-govern-function/)

### FedRAMP
- [FedRAMP 20x Overview](https://www.fedramp.gov/20x/)
- [FedRAMP Rev5 Machine-Readable Packages RFC](https://www.fedramp.gov/rfcs/0024/)
- [FedRAMP Built Modern Foundation in FY25](https://www.fedramp.gov/2025-09-30-fedramp-built-a-modern-foundation-in-fy25-to-deliver-massive-improvements-in-fy26/)
- [FedRAMP 20x Phase Two (Secureframe)](https://secureframe.com/blog/fedramp-20x-phase-two)

### Privacy
- [US State Privacy Legislation Tracker (IAPP)](https://iapp.org/resources/article/us-state-privacy-legislation-tracker)
- [20 State Privacy Laws in 2026 (MultiState)](https://www.multistate.us/insider/2026/2/4/all-of-the-comprehensive-privacy-laws-that-take-effect-in-2026)
- [Cross-Border Data Transfers 2025 Guide](https://secureprivacy.ai/blog/cross-border-data-transfers-2025-guide)
- [Data Localization 2025 (Cookie Script)](https://cookie-script.com/guides/data-localization-2025)

### Compliance-as-Code
- [Policy as Code Tools 2026 (Spacelift)](https://spacelift.io/blog/policy-as-code-tools)
- [OPA vs Cedar (Permit.io)](https://www.permit.io/blog/opa-vs-cedar)
- [OPA vs Kyverno (Plural)](https://www.plural.sh/blog/open-policy-agent-vs-kyverno/)
- [Cedar Policy Language Guide (StrongDM)](https://www.strongdm.com/cedar-policy-language)

### Data Classification
- [Data Classification Tools 2026 (Netwrix)](https://netwrix.com/en/resources/blog/data-classification-tools/)
- [Microsoft Purview Data Classification](https://learn.microsoft.com/en-us/purview/data-map-classification)
- [Automated Data Governance 2026 (OvalEdge)](https://www.ovaledge.com/blog/automated-data-governance)
