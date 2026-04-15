# Infrastructure Security — Deep Reference

**Always use `WebSearch` to verify version numbers, CVEs, platform features, and compliance requirements before giving advice. Security tooling evolves rapidly and misconfigurations have direct breach consequences; this reference provides architectural context current as of early 2026.**

## Table of Contents
1. [Zero Trust Architecture](#1-zero-trust-architecture)
2. [Network Security](#2-network-security)
3. [Cloud Security Posture Management (CSPM)](#3-cloud-security-posture-management-cspm)
4. [Cloud Workload Protection (CWPP)](#4-cloud-workload-protection-cwpp)
5. [Infrastructure Vulnerability Management](#5-infrastructure-vulnerability-management)
6. [Security Groups and Network Policies](#6-security-groups-and-network-policies)
7. [Endpoint Security](#7-endpoint-security)
8. [Email and DNS Security](#8-email-and-dns-security)
9. [Supply Chain Infrastructure Security](#9-supply-chain-infrastructure-security)
10. [Security Information and Event Management (SIEM)](#10-security-information-and-event-management-siem)
11. [Decision Matrices](#11-decision-matrices)

---

## 1. Zero Trust Architecture

### NIST 800-207 Framework

NIST SP 800-207 (August 2020) defines the canonical zero trust architecture. It has been supplemented by:

| Document | Published | Focus |
|----------|-----------|-------|
| **NIST SP 800-207** | Aug 2020 | Core ZTA principles, deployment models, migration strategies |
| **NIST SP 800-207A** | Aug 2023 | ZTA for cloud-native applications in multi-cloud environments (service mesh, API gateways, SPIFFE identity) |
| **CISA Zero Trust Maturity Model v2.0** | Apr 2023 | Federal agency adoption roadmap across five pillars |
| **DoD Zero Trust Reference Architecture v2.0** | 2023 | Military/defense implementation guidance |
| **EO 14028 (May 2021)** | Ongoing | Mandates federal ZT adoption; OMB M-22-09 set Sept 2024 deadline for agencies |

**Seven Tenets of NIST 800-207:**
1. All data sources and computing services are considered resources
2. All communication is secured regardless of network location
3. Access to individual enterprise resources is granted on a per-session basis
4. Access is determined by dynamic policy — including client identity, application/service, requesting asset state, behavioral/environmental attributes
5. The enterprise monitors and measures integrity and security posture of all owned and associated assets
6. All resource authentication and authorization are dynamic and strictly enforced before access is allowed
7. The enterprise collects as much information as possible about the current state of assets, network infrastructure, and communications, and uses it to improve security posture

**CISA ZTM v2.0 Pillars and Maturity Stages:**

| Pillar | Traditional | Initial | Advanced | Optimal |
|--------|------------|---------|----------|---------|
| **Identity** | Passwords, basic MFA | Phishing-resistant MFA, SSO | Continuous validation, risk-based auth | Real-time identity governance, passwordless |
| **Devices** | Limited inventory | EDR on managed devices | Compliance-based access, BYOD policies | Continuous device health attestation |
| **Networks** | Perimeter-based | Initial microsegmentation | Encrypted DNS, east-west filtering | Full microsegmentation, encrypted all traffic |
| **Applications & Workloads** | Cloud migration started | App-aware policies | Workload identity (SPIFFE), service mesh | Immutable workloads, automated response |
| **Data** | Basic classification | DLP policies, encryption at rest | DSPM, field-level encryption | Automated data governance, zero-standing access |

**Cross-cutting:** Visibility & Analytics, Automation & Orchestration, Governance.

**Market data (2025-2026):** 81% of enterprises plan zero trust adoption (Gartner). The global ZT market is projected at $78B+ by 2030. Organizations without ZT face breach costs 38% higher; ZT reduces breach cost by an average of $1.76M per incident.

### BeyondCorp Model

Google's BeyondCorp (originated 2011, published 2014) is the original zero trust implementation that inspired NIST 800-207.

**Core architectural principles:**
- Access decisions based on user identity + device state, never network location
- No VPN required — all applications published to the internet behind an access proxy
- Device inventory and certificate-based identity (not just user credentials)
- Continuous authentication and authorization (not one-time gate)

**BeyondCorp Enterprise (Google Cloud commercial offering):**
- **Identity-Aware Proxy (IAP):** Context-aware access to GCP and on-prem applications
- **Chrome as the agent:** Agentless architecture using Chrome browser for endpoint data collection (DLP, threat protection, device trust signals)
- **Context-Aware Access:** Policies evaluate user identity, device security posture, IP, location, and time of access
- **BeyondCorp Alliance:** Ecosystem of partner integrations (CrowdStrike, Lookout, Tanium, VMware) feeding device signals
- **Certificate-Based Access (CBA):** mTLS for device-to-service authentication

### Zero Trust Platforms Comparison (2025-2026)

| Platform | Architecture | Key Differentiator | Scale | Best For |
|----------|-------------|-------------------|-------|----------|
| **Zscaler ZPA** | Cloud-native proxy, inside-out connectivity | Apps never exposed to internet; AI-powered policy; 500B+ daily transactions across 150+ PoPs | Fortune 500 (40%) | Large enterprises with complex app landscapes |
| **Cloudflare Access** | Global anycast network (209 Tbps, 300+ cities) | Speed-to-deploy, low latency, integrated with CDN/WAF/DDoS | Mid-market to enterprise | Orgs already on Cloudflare; speed-focused |
| **Palo Alto Prisma Access** | NGFW-as-a-service (App-ID, User-ID, Content-ID, WildFire in single pass) | Deepest inspection, existing NGFW integration | Enterprise | Palo Alto shops extending to SASE |
| **Tailscale** | WireGuard-based mesh VPN, identity-aware ACLs | Zero-config, direct P2P connections, no central gateway bottleneck | Startups to mid-market, DevOps teams | Developer-friendly, internal tooling access |
| **Netskope One** | Converged ZTNA + CASB + SWG + DLP + browser isolation | UEBA-powered adaptive access, strongest DLP/DSPM integration | Enterprise | Data-centric security, regulatory compliance |

**Zscaler details:** Retook top position in 2025 Gartner SSE Magic Quadrant. ZPA uses inside-out connectivity — applications initiate outbound connections to the Zscaler cloud, never exposing ports to the internet. AI-powered app segmentation and policy recommendations. Zero Trust Exchange processes 500B+ daily transactions.

**Tailscale details:** Built on WireGuard protocol. Creates a mesh network where devices connect directly to each other (P2P when possible). Identity tied to SSO provider (Okta, Azure AD, Google, GitHub). JSON-based ACLs for fine-grained access control. Exit nodes for routing internet traffic. MagicDNS for service discovery. No port forwarding or firewall rules required. Free tier for personal use (up to 100 devices).

**Prisma Access details:** Single-pass architecture inspects traffic for App-ID, User-ID, Content-ID, and WildFire simultaneously — adding security features does not multiply latency. Extends existing Palo Alto NGFW policies to cloud-delivered SASE without rip-and-replace.

---

## 2. Network Security

### Web Application Firewalls (WAF)

| Feature | AWS WAF | Cloudflare WAF | Fastly Next-Gen WAF |
|---------|---------|----------------|---------------------|
| **Deployment** | Tied to ALB, CloudFront, API Gateway, AppSync, Cognito | Global anycast, reverse proxy | Edge cloud, Varnish-based |
| **Managed Rules** | AWS Managed Rules + Marketplace (limited) | OWASP, Cloudflare Managed, leaked credentials check | SmartParse + custom thresholds |
| **API Security** | Basic rate limiting via API Gateway; no built-in API discovery | API discovery available, robust API protection | Strong API/microservices focus |
| **Bot Management** | Bot Control (targeted/common) | Bot Management (ML behavioral analysis, JS challenge) | Signal Sciences heritage — signal-based detection |
| **DDoS Integration** | Shield Standard (free) / Shield Advanced ($3,000/mo + 1yr commitment) | Unmetered DDoS included on all plans | Basic DDoS included, advanced via partnership |
| **Managed Service** | Only via Shield Advanced or SI contract (5-6 figure) | SOC-as-a-service on Enterprise | Managed WAF in Ultimate plan only |
| **Pricing Model** | Per web ACL ($5/mo) + per rule ($1/mo) + per million requests ($0.60) | Pro $20/mo, Biz $200/mo, Enterprise custom | Essentials / Professional / Premier / Ultimate tiers |
| **Best For** | AWS-native workloads | Cost-effective broad protection, API-heavy apps | DevOps teams, CI/CD-integrated security |

**Market context:** Global WAF market projected at $8.31B (2025), growing to $27.11B by 2032. APIs have surpassed websites as the most-targeted attack surface.

### DDoS Protection

| Feature | Cloudflare | AWS Shield | Azure DDoS Protection |
|---------|-----------|------------|----------------------|
| **Network Capacity** | 209 Tbps, 300+ cities | AWS global edge (CloudFront, Route 53, Global Accelerator) | Azure backbone + anycast scrubbing |
| **Always-On** | Yes, all plans | Standard: yes (L3/L4); Advanced: yes + L7 | Standard: yes; Protection tier: enhanced |
| **Layer Coverage** | L3, L4, L7 | Standard: L3/L4; Advanced: L3/L4/L7 | Standard: L3/L4; DDoS Protection: L3/L4/L7 |
| **Response Team** | Enterprise SOC | DDoS Response Team (DRT) — 24/7 with Advanced | Rapid Response team on DDoS Protection tier |
| **Cost Protection** | No overage charges on any plan | Advanced includes cost protection for scaling charges | DDoS Protection includes cost protection |
| **ML/Adaptive** | Autonomous edge mitigation, ML profiling | Automatic detection via traffic flow telemetry | Adaptive tuning, ML-based traffic profiling |
| **Pricing** | Free tier included; unmetered on all paid plans ($0.05/10K requests for WAF) | Standard: free; Advanced: $3,000/mo + 1yr commitment | Standard: free; DDoS Protection: ~$2,944/mo |
| **Market Mindshare** | 17.8% | 5.2% | Growing (Azure ecosystem) |

### Next-Generation Firewalls (NGFW)

Key vendors (2025-2026): Palo Alto Networks, Fortinet, Check Point, Cisco Firepower, Juniper SRX.

**Palo Alto NGFW capabilities:** App-ID (application identification regardless of port/protocol), User-ID (user-to-IP mapping), Content-ID (threat prevention, URL filtering, data filtering), WildFire (cloud-based sandboxing). Single-pass parallel processing architecture.

**Trend:** NGFWs are being complemented (not replaced) by microsegmentation for east-west traffic. NGFWs remain authoritative for north-south perimeter control.

### Microsegmentation

**Market:** $8.2B in 2025, projected $41B+ by 2034.

| Vendor | Approach | Key Strength |
|--------|----------|-------------|
| **Illumio** | Agent-based, workload-centric | Hybrid cloud segmentation, 2026 Gartner Customers' Choice |
| **Akamai Guardicore** | Agent + agentless, data center east-west | Integrated threat hunting, legacy/VM/container support |
| **Cilium** | eBPF-based, Kubernetes-native | L3-L7 policies, identity-aware, FQDN filtering, no sidecar overhead |
| **Zscaler Workload Segmentation** | Identity-based, agentless | Software-defined segments across cloud |
| **Elisity** | Identity-based, network-native | Campus and data center microsegmentation |

**Illumio details:** Gartner Customers' Choice 2026 for Network Security Microsegmentation. Workload-centric: labels (role, app, environment, location) define policy independent of network topology. Real-time application dependency mapping. Policy simulation before enforcement.

**Akamai Guardicore details:** Acquired by Akamai (2021). Agent-based + agentless for VMs, containers, bare metal, legacy. Process-level visibility and threat hunting. Deception-based threat detection.

---

## 3. Cloud Security Posture Management (CSPM)

### CNAPP / CSPM Platform Comparison

| Feature | Wiz | Orca Security | Prisma Cloud | AWS Security Hub | Microsoft Defender for Cloud | GCP Security Command Center |
|---------|-----|---------------|-------------|-----------------|----------------------------|----------------------------|
| **Architecture** | Agentless (cloud API + snapshot scanning) | Agentless (SideScanning block storage) | Agent + agentless (broadest CNAPP) | Native AWS service | Native Azure + multicloud | Native GCP + AWS support |
| **Core Tech** | Security Graph (contextual risk correlation) | Unified data model, SideScanning | Acquisitions: RedLock (CSPM), Bridgecrew (IaC), Twistlock (CWPP) | Automated checks + finding aggregation | CSPM + CWPP combined | Chronicle integration, Mandiant expertise |
| **Cloud Coverage** | AWS, Azure, GCP, OCI, Alibaba | AWS, Azure, GCP, Alibaba, OCI | AWS, Azure, GCP, OCI, Alibaba | AWS only | Azure, AWS, GCP | GCP + AWS |
| **Alert Volume** | ~20-30 actionable findings/day | ~20-30 actionable findings/day | 100-150 daily (70-80 false positives reported) | Tunable per standard | Tunable, risk-prioritized | Tunable per tier |
| **AI Features (2025)** | AI-SPM for AI pipeline security, GenAI remediation | AI-powered prioritization | Copilot integration for investigation | OCSF support (June 2025) | Copilot for Security, natural language queries | Gemini integration, correlated threat detection |
| **IaC Scanning** | Yes | Yes | Bridgecrew (deepest) | Limited (via partners) | DevOps security posture (paid CSPM) | Terraform validation |
| **CIEM** | Yes | Yes | Yes | IAM Access Analyzer (separate) | Permissions management | IAM recommender |
| **Pricing Model** | Per-workload | Per-asset | Module-based (complex) | Free tier + per-check pricing | Free tier (basic CSPM) + Defender CSPM plan | Free tier + Enterprise/Premium tiers |
| **Best For** | Fast agentless deployment, security graph visualization | Unified agentless coverage, low noise | Existing Palo Alto shops, broadest feature set | AWS-only environments | Microsoft/Azure-centric orgs, multicloud from Azure pane | GCP-native, Chronicle SIEM users |

**Wiz (acquired by Google Cloud, $32B, completed March 2026):**
- Crossed $1B ARR in 2025. 45-50x revenue multiple.
- Security Graph: Correlates vulnerabilities, misconfigurations, identities, network exposure, secrets, and malware across the full cloud stack into attack paths.
- AI-SPM (2025): Discovers and secures AI pipelines — training data, models, inference endpoints.
- Agentless: No agent deployment; reads cloud API metadata + disk snapshots via cloud-native APIs.
- Regulatory: EU antitrust approved Feb 2026 with multicloud support commitments maintained.
- CNAPP market share: Wiz ~11%, CrowdStrike ~13%, Palo Alto ~17% (Q1 2024).

**AWS Security Hub (enhanced, June 2025):**
- OCSF (Open Cybersecurity Schema Framework) support for normalized finding format.
- AWS Foundational Security Best Practices standard built-in; additional CIS, PCI DSS, NIST standards.
- Aggregates findings from GuardDuty, Inspector, Macie, Firewall Manager, IAM Access Analyzer.
- Event-based continuous monitoring + periodic schedule checks.

**Microsoft Defender for Cloud (2025-2026):**
- Unifying all CSPM into Microsoft Security Exposure Management (MSEM) — single pane for secure scores, recommendations, attack paths, vulnerabilities.
- Expanded multicloud posture: broader native coverage for AWS and GCP resource types (compute, databases, storage, networking, identity, secrets, DevOps, AI/ML).
- DevOps security posture: PR annotations, code-to-cloud mapping, attack path analysis (Defender CSPM plan only).
- Copilot for Security integration: natural language investigation, automated incident summaries, AI-assisted threat hunting.

**GCP Security Command Center Enterprise (H2 2025):**
- DSPM (Data Security Posture Management): bird's-eye view of data sensitivity across GCP.
- Correlated Threats Detection: 65 new threat detectors covering thousands of attack scenarios.
- Chronicle integration for SIEM/SOAR workflows.
- Mandiant expertise built into threat intelligence.
- Policy change (May 2025): New activations get 90-day finding retention (down from 13 months).

---

## 4. Cloud Workload Protection (CWPP)

### Runtime Security — eBPF-Based Tools

| Feature | Falco | Tetragon | Cilium (Network Policy) |
|---------|-------|----------|------------------------|
| **Governance** | CNCF Graduated | CNCF project (Cilium sub-project) | CNCF Graduated |
| **Current Version** | 0.40.0 (Jan 2025) | v1.6.0 (2026, depends on Cilium 1.18) | 1.19 (Feb 2026) |
| **Detection Approach** | Rule-based behavioral detection (syscall + K8s audit) | In-kernel policy filtering + enforcement | L3-L7 network policy with identity-aware enforcement |
| **eBPF Usage** | Kernel syscall monitoring (pluggable drivers: eBPF, kernel module) | Deep kernel tracing (process, file, network, namespace events) | Dataplane: packet filtering, load balancing, encryption |
| **Enforcement** | Detection/alerting only (no blocking) | Real-time enforcement (kill process, deny, signal) | Network policy enforcement (allow/deny traffic) |
| **Kernel Filtering** | Events sent to userspace for rule evaluation | In-kernel filtering and aggregation (minimal userspace overhead) | In-kernel packet processing |
| **Kubernetes Awareness** | Yes (enriches events with K8s metadata) | Native K8s awareness (pods, namespaces, labels) | Native K8s integration (CiliumNetworkPolicy CRDs) |
| **Performance Impact** | Moderate (userspace rule engine) | Low (in-kernel processing) | Low (replaces iptables with eBPF) |
| **Community Rules** | Large rule library, Falco Plugins framework | TracingPolicy CRDs | CiliumNetworkPolicy, CiliumClusterwideNetworkPolicy |
| **Integration** | Kubernetes, containerd, CRI-O, cloud audit logs | Cilium, Kubernetes, standalone Linux | Kubernetes, cloud provider CNI |
| **Best For** | Broad detection coverage, compliance auditing | Real-time enforcement, low-overhead security | Network segmentation, identity-based access |

**Falco 0.39.0 highlights:** `append_output` feature for custom event outputs by source/tag/rule. Automatic driver selection in K8s (picks best compatible driver per node). Deprecated `--cri` and `--disable-cri-async` (runtime config moves to falco.yaml).

**Falco 0.40.0 (Jan 2025):** Bug fixes, performance improvements, removed deprecated CRI CLI options (configured via falco.yaml only).

**Tetragon architecture:** Applies policy and filtering directly in the Linux kernel using eBPF. Rather than sending all events to userspace, Tetragon performs sophisticated filtering and aggregation in-kernel. TracingPolicy CRDs define what to observe and enforce. Can kill processes, send signals, or override return values in real time. Runs as non-root by default since v1.5.0+ (UID 65532).

**Cilium 1.18 (2025):** Encrypted overlay with IPsec enhancements, expanded IPv6, ingress bandwidth controls, policy performance improvements.

**Cilium 1.19 (Feb 2026, 10th anniversary):** Strict encryption modes for IPsec and WireGuard — unencrypted inter-node traffic dropped in strict mode. Security hardening, policy behavior refinements, large-cluster scalability.

### Container Security Lifecycle

| Phase | Tools | What It Does |
|-------|-------|-------------|
| **Build** | Trivy, Grype, Snyk Container, Docker Scout | Image vulnerability scanning, SBOM generation |
| **Registry** | Harbor + Cosign, ECR image scanning, ACR Defender | Admission-time scanning, signature verification |
| **Deploy** | Kyverno, OPA/Gatekeeper, Sigstore policy controller | Admission control — block unsigned/unscanned images |
| **Runtime** | Falco, Tetragon, Aqua Runtime, Sysdig Secure | Behavioral detection, process monitoring, file integrity |
| **Network** | Cilium, Calico, Kubernetes NetworkPolicy | East-west traffic control, microsegmentation |

### Serverless Security (2025-2026)

**Threat landscape:** Developers assign overly broad IAM permissions to Lambda/Cloud Functions; attackers steal temporary credentials. 61% of orgs have secrets in public repos. Supply chain attacks on function dependencies rising.

**Protection approaches:**
- **CrowdStrike Falcon Cloud Security:** Runtime protection for AWS Lambda, Google Cloud Functions, Azure Functions.
- **Microsoft Defender for Cloud:** CSPM extended to Azure Functions, Azure Web Apps, AWS Lambda (Ignite 2025).
- **Prisma Cloud serverless:** Static analysis + runtime defense for serverless functions.
- **Wiz:** Agentless scanning of serverless function configurations, dependencies, and permissions.

**Key risk areas (Qualys 2026):** Identity over-provisioning, SSRF leading to metadata service abuse, dependency confusion, cold-start credential caching.

**Gartner prediction:** By 2026, CWPP will be a foundational component of cloud security for 80%+ of enterprises.

---

## 5. Infrastructure Vulnerability Management

### Scoring Systems

| System | Version | Purpose | Scale | Update Frequency |
|--------|---------|---------|-------|-----------------|
| **CVSS** | v4.0 (Nov 2023) | Vulnerability severity scoring | 0.0-10.0 | Static per CVE |
| **EPSS** | v4 (Mar 2025) | Probability of exploitation in next 30 days | 0.0-1.0 (probability) | Daily |
| **CISA KEV** | Ongoing catalog | Known Exploited Vulnerabilities — confirmed in-the-wild exploitation | Binary (in catalog or not) | As confirmed |
| **SSVC** | v2.0 | Stakeholder-Specific Vulnerability Categorization | Track / Track* / Attend / Act | Per assessment |
| **VPR (Tenable)** | Proprietary | Vendor Priority Rating, daily-updated exploit intelligence | 0.0-10.0 | Daily |
| **TruRisk (Qualys)** | Proprietary | Normalized business risk score | 0-1,000 | Continuous |

**CVSS v4.0 key changes from v3.1:**
- Four metric groups: Base, Threat, Environmental, Supplemental (replaces Temporal)
- New Attack Requirements (AT) metric — captures prerequisites beyond just complexity
- Improved User Interaction granularity (None, Passive, Active)
- Removed problematic binary Scope metric — replaced with explicit impact on Vulnerable/Subsequent systems
- Supplemental Metric Group: Safety, Automatable, Recovery, Value Density, Provider Urgency
- Addresses v3.1 score inflation problem (too many 9.8/10.0 ratings)

**EPSS v4 (March 17, 2025):**
- Fourth major revision. Predicts probability of exploitation within 30 days.
- ML model trained on real-world exploit data (Metasploit, ExploitDB, GreyNoise, honeypots).
- Use alongside CVSS: CVSS measures severity (how bad), EPSS measures likelihood (how probable).
- Example: A CVSS 9.8 with EPSS 0.01 = severe but unlikely; a CVSS 6.5 with EPSS 0.85 = moderate but actively exploited.

**CISA KEV Catalog (2025):**
- Contains 1,484+ confirmed exploited-in-the-wild vulnerabilities.
- Federal agencies mandated to remediate KEV entries within specified timelines (BOD 22-01).
- 0.75% of published CVEs are actively exploited; 28% of exploits occur within 24 hours of disclosure.
- H1 2025: 21,500 CVEs published; 161 actively exploited.

### Vulnerability Management Platforms

| Feature | Tenable (Nessus/Tenable.io) | Qualys VMDR | Rapid7 InsightVM | CrowdStrike Falcon Exposure Management |
|---------|---------------------------|-------------|-----------------|---------------------------------------|
| **Scanning** | Active + agent + passive; largest plugin library (200K+) | Cloud agent + scanner appliances; 75K+ QIDs | Insight Agent + scan engine; adaptive security | Agent-based (Falcon sensor); external attack surface |
| **Risk Scoring** | VPR (daily exploit intelligence) + CVSS v4 + EPSS | TruRisk (0-1,000 normalized business risk) | Real Risk (live Metasploit exploit data) | ExPRT.AI (ML-based exploit prediction) |
| **Asset Discovery** | Passive network monitoring + connectors | Cloud agents, CMDB integration, passive scanning | Dynamic discovery + cloud connectors | Falcon sensor telemetry + external scanning |
| **Patch Integration** | Tenable Patch Management (acquired) | Qualys Patch Management (integrated) | InsightConnect automation | Falcon Spotlight + partner integrations |
| **Cloud Coverage** | Tenable Cloud Security (formerly Ermetic) | Qualys CloudView / TotalCloud | InsightCloudSec | Falcon Cloud Security |
| **Differentiator** | Largest vuln coverage, VPR accuracy | Unified platform (VMDR + PM + compliance), TruRisk | Metasploit integration for exploit validation | Single agent across EDR + VM + cloud |
| **Best For** | Large enterprises, broadest scan coverage | Consolidated platform buyers, compliance-heavy | Security teams wanting exploit validation | CrowdStrike shops wanting unified EDR + VM |

**Recommended prioritization workflow:**
1. **Filter by KEV:** Any CVE in CISA KEV catalog = immediate priority (patch within days)
2. **Score with EPSS:** Sort remaining by EPSS score; focus on EPSS > 0.1 (10%+ exploitation probability)
3. **Adjust with CVSS v4:** For similar EPSS scores, use CVSS v4 environmental metrics to factor in local context
4. **Apply business context:** Asset criticality, network exposure, compensating controls

---

## 6. Security Groups and Network Policies

### Cloud Provider Network Controls

| Feature | AWS Security Groups | Azure NSGs | GCP Firewall Rules |
|---------|-------------------|-----------|-------------------|
| **Model** | Stateful, instance-level | Stateful, subnet or NIC-level | Stateful, VPC-level hierarchical |
| **Default Behavior** | Deny all inbound, allow all outbound | Deny all (configurable priorities) | Implied deny inbound, allow outbound |
| **Rules Limit** | 60 inbound + 60 outbound per SG; 5 SGs per ENI | 1,000 rules per NSG | Hierarchical policies + VPC rules (quotas vary) |
| **Rule Targets** | Security group ID, IP CIDR, prefix list | IP CIDR, service tags, ASGs | IP CIDR, service accounts, network tags |
| **Logging** | VPC Flow Logs (separate config) | NSG Flow Logs | VPC Flow Logs |
| **Managed Rules** | Prefix lists, security group references | Service Tags (AzureCloud, Internet, etc.) | Implied rules, priority-based |
| **IaC Support** | Terraform `aws_security_group`, CloudFormation | Terraform `azurerm_network_security_group`, Bicep/ARM | Terraform `google_compute_firewall`, Deployment Manager |

### Kubernetes Network Policies

| Feature | Kubernetes NetworkPolicy | Cilium Network Policy | Calico Network Policy |
|---------|------------------------|----------------------|----------------------|
| **Spec** | Standard K8s API (networking.k8s.io/v1) | CiliumNetworkPolicy / CiliumClusterwideNetworkPolicy CRDs | Calico NetworkPolicy / GlobalNetworkPolicy CRDs |
| **Layer** | L3/L4 only | L3/L4 + L7 (HTTP, gRPC, Kafka, DNS) | L3/L4 + some L7 via Envoy |
| **Identity Model** | Pod label selectors, namespace selectors, IP blocks | Pod labels + Cilium Identity (efficient eBPF-based) | Pod labels, service accounts, global network sets |
| **FQDN Filtering** | Not supported | Supported (toFQDNs for external domain whitelisting) | Supported (DNS policy) |
| **Deny Rules** | Implicit deny when policy selects a pod | Explicit deny rules supported | Explicit deny rules, ordered policy tiers |
| **Cluster-Wide** | Not supported natively | CiliumClusterwideNetworkPolicy | GlobalNetworkPolicy |
| **Encryption** | Not handled | WireGuard or IPsec (transparent, per-node or per-identity) | WireGuard support |
| **Dataplane** | Depends on CNI (iptables or eBPF) | eBPF (replaces iptables entirely) | iptables or eBPF (Calico eBPF dataplane) |

**Azure NPM deprecation:** Azure Network Policy Manager (NPM) for Windows nodes deprecated September 30, 2026; Linux nodes deprecated September 30, 2028. Microsoft recommends Azure CNI Powered by Cilium with Cilium Network Policy for all new deployments.

**Cilium + AWS Security Groups integration:** Cilium on EKS supports `toGroups` in CiliumNetworkPolicy, allowing policies that reference AWS Security Groups directly. Pods can be whitelisted to communicate with EC2 instances attached to specific security groups.

**Best practice:** Deploy exactly one network policy engine per cluster to avoid conflicting enforcement. For new clusters, prefer Cilium (eBPF-native, L7 support, FQDN filtering, WireGuard encryption).

**Cilium policy example (L7 HTTP):**
```yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-api-get
spec:
  endpointSelector:
    matchLabels:
      app: api-server
  ingress:
  - fromEndpoints:
    - matchLabels:
        app: frontend
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
      rules:
        http:
        - method: GET
          path: "/api/v1/.*"
```

---

## 7. Endpoint Security

### EDR/XDR Platform Comparison (2025-2026)

| Feature | CrowdStrike Falcon | SentinelOne Singularity | Microsoft Defender for Endpoint |
|---------|-------------------|------------------------|-------------------------------|
| **Architecture** | Cloud-native, single lightweight agent | AI-driven local agent (operates without cloud connectivity) | Integrated with Microsoft 365, Entra ID, Purview |
| **Detection (MITRE 2026)** | 97.2% technique-level | 98.7% technique-level | 89.4% technique-level (96.6% in 2024 eval) |
| **Threat Remediation** | Avg 12 minutes (vs 38 min industry avg) | Automated ransomware rollback, Storyline forensics | Automated investigation and remediation |
| **XDR Scope** | Falcon platform: endpoint, cloud, identity, data protection | Singularity platform: endpoint, cloud, identity, network | Defender XDR: endpoint, email, identity, cloud apps, OT |
| **AI/ML** | Charlotte AI (generative), cloud-based threat graph | Purple AI (natural language investigation), local AI engine | Copilot for Security (GPT-4 powered investigation) |
| **OS Coverage** | Windows, macOS, Linux, ChromeOS, mobile | Windows, macOS, Linux, Kubernetes, mobile | Windows (deepest), macOS, Linux, Android, iOS |
| **Gartner Position** | Leader (EPP MQ 2025) | Leader (EPP MQ 2025) | Leader (EPP MQ 2025) |
| **Pricing** | ~$100+/endpoint/year (Falcon Pro) | ~$80/endpoint/year (Singularity Control) | ~$36-60 via M365 E5/A5 licensing |
| **Key Strength** | Fastest remediation, broadest threat intelligence (CrowdStrike Intelligence) | Best autonomous detection, ransomware rollback | Lowest cost for Microsoft shops, deepest M365 integration |
| **Key Weakness** | Highest cost; July 2024 outage (faulty content update) impacted trust | Fewer native integrations outside Singularity | Lower independent detection rates, Windows-centric depth |

**CrowdStrike Falcon platform modules:**
- Falcon Prevent (NGAV), Falcon Insight (EDR), Falcon OverWatch (managed threat hunting), Falcon Discover (IT hygiene), Falcon Spotlight (vulnerability management), Falcon Identity Threat Detection, Falcon Cloud Security, Falcon LogScale (SIEM), Falcon Data Protection (DLP).

**SentinelOne Singularity:**
- Storyline: Automatically reconstructs attack narratives from individual events into a full attack timeline.
- Ransomware rollback: Reverts encrypted files using VSS snapshots (Windows) and proprietary journaling.
- Purple AI: Natural language queries across security telemetry.

**Microsoft Defender for Endpoint:**
- Native integration with Microsoft Sentinel (SIEM), Entra ID (identity), Purview (data governance), Intune (device management).
- Microsoft Security Graph: Unified data layer across all Microsoft security products.
- Copilot for Security: AI-assisted investigation, natural language hunting queries, automated incident summaries.
- Most cost-effective for organizations already on Microsoft 365 E5.

---

## 8. Email and DNS Security

### Email Authentication Stack

| Protocol | Function | DNS Record Type | Introduced |
|----------|----------|----------------|------------|
| **SPF** | Specifies authorized sending IPs/hostnames for a domain | TXT (`v=spf1 ...`) | 2006 (RFC 4408), updated 2014 (RFC 7208) |
| **DKIM** | Adds cryptographic signature to email headers using public/private key pair | TXT (`v=DKIM1; k=rsa; p=...`) | 2007 (RFC 4871), updated 2011 (RFC 6376) |
| **DMARC** | Policy layer combining SPF + DKIM alignment; tells receivers what to do on failure | TXT (`v=DMARC1; p=reject; ...`) | 2015 (RFC 7489) |
| **BIMI** | Brand Indicators for Message Identification — displays brand logo in email clients | TXT (`v=BIMI1; l=...`) | 2023+ (emerging standard) |
| **MTA-STS** | Strict Transport Security for SMTP — enforces TLS for mail delivery | TXT + HTTPS well-known | 2018 (RFC 8461) |
| **DANE** | DNS-based Authentication of Named Entities — binds TLS certificates to DNS via TLSA records | TLSA | 2015 (RFC 7672) |

**2024-2026 Enforcement Mandates:**
- **Google (Gmail):** Since Feb 2024, bulk senders (5,000+ emails/day) must have SPF + DKIM + DMARC with p=quarantine minimum. One-click unsubscribe required.
- **Microsoft (Outlook/Hotmail):** Since May 2025, enforcing DMARC for bulk senders; non-compliant mail goes to junk.
- **Yahoo:** Aligned with Google's requirements since Feb 2024.
- **PCI DSS v4.0.1:** Requires DMARC with p=reject for organizations handling payment card data (March 2025).

**DMARC enforcement progression:**
```
p=none      → monitoring only (aggregate reports via rua=)
p=quarantine → failing emails go to spam
p=reject    → failing emails rejected at SMTP level
```

**Best practice deployment order:**
1. Deploy SPF (audit authorized senders)
2. Deploy DKIM (configure signing on all mail sources)
3. Deploy DMARC at `p=none` with `rua=` for aggregate reporting
4. Analyze DMARC reports (use tools: Valimail, dmarcian, Red Sift, PostmarkApp)
5. Tighten to `p=quarantine`, then `p=reject`
6. Add BIMI (requires VMC certificate from DigiCert/Entrust, DMARC at p=quarantine or p=reject)
7. Deploy MTA-STS for inbound TLS enforcement

### DNS Security

**DNSSEC:**
- Signs DNS records (MX, TXT/SPF, TXT/DKIM, TXT/DMARC) with cryptographic signatures.
- Resolver validates chain of trust from root → TLD → authoritative zone.
- Without DNSSEC, cache poisoning can spoof email identity and bypass DMARC.
- Adoption: ~30% of domains signed globally (2025); federal agencies mandated.

**Encrypted DNS:**

| Protocol | Port | Standard | Transport | Status (2025-2026) |
|----------|------|----------|-----------|-------------------|
| **DNS-over-TLS (DoT)** | 853 | RFC 7858 (2016) | TLS 1.3 | Supported by Android 9+ (Private DNS), major resolvers |
| **DNS-over-HTTPS (DoH)** | 443 | RFC 8484 (2018) | HTTPS/2 or /3 | Default in Firefox, Chrome, Edge; harder to block |
| **DNS-over-QUIC (DoQ)** | 853 | RFC 9250 (2022) | QUIC | Emerging; supported by AdGuard, NextDNS |

**NIST SP 800-81 Revision 3 (March 19, 2026):**
- First update in 13 years (prior: Rev 2, 2013).
- Covers: encrypted DNS (DoT, DoH, DoQ), DNSSEC, Protective DNS, zero trust integration, logging, OT/IoT environments.
- Federal mandate: January 2025 Executive Order requires encrypted DNS deployment within 180 days for federal agencies.
- Technical framework for implementing Protective DNS (blocking malicious domains at the resolver level).

**Protective DNS providers:** Cloudflare Gateway (1.1.1.1 for Families), Cisco Umbrella (OpenDNS), CISA Protective DNS, Quad9 (9.9.9.9), Infoblox BloxOne Threat Defense.

---

## 9. Supply Chain Infrastructure Security

### SLSA Framework (Supply-chain Levels for Software Artifacts)

**Governance:** OpenSSF (Linux Foundation) project, CNCF ecosystem alignment.

**Current version:** SLSA v1.0 (April 2023). Focus: Build track (provenance of how artifacts are built).

| Level | Name | Requirements | Trust |
|-------|------|-------------|-------|
| **L0** | No SLSA | No provenance | None |
| **L1** | Provenance Exists | Build platform auto-generates provenance describing how artifact was built; provenance available to consumers | Documentation |
| **L2** | Hosted Build + Signed Provenance | Builds run on hosted platform; provenance digitally signed by build platform | Tamper-evident |
| **L3** | Hardened Build | Build platform provides isolation, ephemeral environments, non-falsifiable provenance; prevents insider/credential tampering | Tamper-resistant |

**Provenance format:** in-toto attestation framework. SLSA Provenance predicate follows in-toto attestation parsing rules. Contains: builder identity, build definition (config source, entry point, parameters), run details (builder version, metadata, byproducts).

**SLSA v1.1 (draft):** Minor refinements to v1.0 spec. Build track remains primary; Source track and Dependencies track under development.

### Artifact Signing — Sigstore Ecosystem

| Component | Purpose | Details |
|-----------|---------|---------|
| **Cosign** | Signs/verifies container images and OCI artifacts | CLI tool, stores signatures in OCI registry alongside image |
| **Fulcio** | Free certificate authority | Issues short-lived signing certificates tied to OIDC identity |
| **Rekor** | Immutable transparency log | Publicly auditable record of signing events (like Certificate Transparency for code) |
| **Gitsign** | Signs Git commits using Sigstore | Keyless commit signing with OIDC identity |
| **Policy Controller** | Kubernetes admission controller | Verifies Cosign signatures before allowing image deployment |

**Keyless signing workflow:**
1. Developer authenticates via OIDC (GitHub, Google, Microsoft identity)
2. Fulcio issues short-lived certificate (minutes) bound to OIDC identity
3. Cosign signs the artifact and records the signature in Rekor
4. Private key is discarded after signing — no long-lived key management
5. Verification checks Rekor log + Fulcio certificate chain

**Adoption (2025-2026):** npm, PyPI, Homebrew, Kubernetes, Sigstore GA since Oct 2022. GitHub Actions generates SLSA L3 provenance for GitHub-hosted runners. GitLab CI supports keyless Sigstore signing natively.

### Policy Engines for Supply Chain

| Engine | Approach | Language | Strength | Weakness |
|--------|----------|----------|----------|----------|
| **Kyverno** | Kubernetes-native admission controller | YAML (declarative) | Easy to write, mutate resources, generate resources; native Cosign signature verification | K8s-only, less flexible for complex logic |
| **OPA/Gatekeeper** | General-purpose policy engine with K8s integration | Rego (purpose-built query language) | Powerful logic for complex compliance scenarios; usable outside K8s | Steeper learning curve, no built-in mutation |
| **Sigstore Policy Controller** | Kubernetes admission controller | CosignVerification CRDs | Purpose-built for image signature verification | Narrow scope (signing only) |

**Kyverno + Cosign integration:** Kyverno natively verifies Cosign image signatures. Policy can require images to be signed with specific keys or keyless identities before admission.

**Recommended hybrid approach:** Use Kyverno for straightforward Kubernetes admission policies (image signing verification, label enforcement, resource mutations). Use OPA/Gatekeeper for complex compliance logic requiring Rego's expressive query capabilities.

**SBOM (Software Bill of Materials):**
- Formats: SPDX (ISO/IEC 5962:2021), CycloneDX (OWASP)
- Generation: Syft (Anchore), Docker Scout (automatic for all images since 2026), Trivy
- Federal mandate: EO 14028 requires SBOMs for all software sold to federal government
- VEX (Vulnerability Exploitability eXchange): Companion document to SBOM indicating whether a vulnerability in a component actually affects the product

---

## 10. Security Information and Event Management (SIEM)

### SIEM Platform Comparison (2025-2026)

| Feature | Splunk Enterprise Security | Microsoft Sentinel | Elastic Security | CrowdStrike LogScale |
|---------|--------------------------|-------------------|-----------------|---------------------|
| **Architecture** | Indexer-based (on-prem or Splunk Cloud) | Cloud-native (Azure Log Analytics) | Open-source core + Elastic Cloud | Streaming log management (formerly Humio) |
| **Ownership** | Cisco (acquired late 2024/early 2025) | Microsoft | Elastic NV | CrowdStrike |
| **Data Ingestion** | Volume-based licensing (GB/day) | Pay-per-ingestion (GB) + commitment tiers | Resource-based (Elastic Cloud) or self-managed | Ingest-based licensing |
| **Cost (500 GB/day)** | ~$788,000/year (Splunk Cloud) | ~$415,000/year (30-50% less in M365 environments) | Competitive (self-managed option) | Competitive (bundled with Falcon) |
| **Query Language** | SPL (Search Processing Language) | KQL (Kusto Query Language) | EQL (Event Query Language) + ES|QL + Lucene | LogScale Query Language (LQL) |
| **AI/ML** | Splunk AI Assistant | Copilot for Security (GPT-4 powered NL queries, automated summaries) | Elastic AI Assistant (LLM-powered investigation) | Charlotte AI (integrated with Falcon platform) |
| **SOAR** | Splunk SOAR (formerly Phantom) — built-in | Logic Apps + Sentinel Automation Rules | Elastic Agent + custom integrations | Falcon Fusion (workflow automation) |
| **Integrations** | 2,800+ Splunkbase apps/add-ons | 350+ data connectors, native M365/Azure | Elastic Integrations catalog | Native Falcon ecosystem + third-party |
| **Gartner Position** | Leader (2025 MQ) | Leader (2025 MQ) | Challenger/Visionary | Visionary (first year in MQ 2025) |
| **Best For** | Large heterogeneous environments, mature SOC teams | Microsoft-heavy environments, cost optimization | Open-source flexibility, self-managed control | CrowdStrike shops, streaming analytics |

**Key trends (2025-2026):**
- **SIEM + XDR convergence:** The line between SIEM and XDR is dissolving. Microsoft, CrowdStrike, and Palo Alto offer unified platforms serving both functions.
- **Full detect-respond loop:** Splunk ES + Splunk SOAR, Sentinel + Logic Apps, and CrowdStrike Falcon platform all provide detection through response automation in one platform.
- **Cisco acquisition of Splunk:** Completed late 2024. Expect tighter integration with Cisco network telemetry (Firepower, Meraki, Duo, Umbrella). Cisco XDR and Splunk convergence ongoing.
- **AI-assisted SOC:** All major platforms now offer generative AI for investigation. Natural language queries, automated incident summaries, playbook suggestions.
- **OCSF adoption:** Open Cybersecurity Schema Framework standardizing event formats across vendors (AWS Security Hub adopted June 2025).

**Splunk SOAR capabilities:** 350+ integrations (apps), visual playbook builder, case management, automated enrichment and response. Previously Phantom (acquired 2018).

**Microsoft Sentinel SOAR:** Logic Apps-based automation. Playbooks triggered by analytics rules. Native integration with Defender XDR for automated investigation and response. Cost advantage: Microsoft customers can ingest M365/Azure logs at reduced or free rates.

**CrowdStrike LogScale (Falcon LogScale):** Formerly Humio. Streaming architecture — no indexing required. Sub-second search at petabyte scale. Best when combined with Falcon XDR for endpoint + cloud + identity correlation. Entered Gartner SIEM Magic Quadrant as Visionary in 2025.

**Google Security Operations (Chronicle):** Merged Chronicle SIEM + Chronicle SOAR. Google Threat Intelligence (Mandiant + VirusTotal). Integration with SCC Enterprise for cloud security events. Pricing based on data retention, not ingestion volume (disruptive model).

---

## 11. Decision Matrices

### "Which Zero Trust Platform?" Decision Tree

```
Start
  ├─ Already on Cloudflare for CDN/DNS?
  │     └─ YES → Cloudflare Access (simplest integration)
  ├─ Running Palo Alto firewalls?
  │     └─ YES → Prisma Access (extend existing NGFW policies)
  ├─ Fortune 500 / complex multi-cloud / 10,000+ users?
  │     └─ YES → Zscaler ZPA (largest cloud, strongest SSE)
  ├─ Developer team / internal tooling / < 500 users?
  │     └─ YES → Tailscale (fastest setup, WireGuard mesh)
  └─ Data-centric / strong DLP requirements?
        └─ YES → Netskope One (strongest DLP/CASB integration)
```

### "Which CSPM/CNAPP?" Decision Tree

```
Start
  ├─ AWS only?
  │     └─ AWS Security Hub + GuardDuty + Inspector (native, free tier)
  ├─ Azure-centric / Microsoft shop?
  │     └─ Microsoft Defender for Cloud (CSPM + CWPP combined)
  ├─ GCP-centric?
  │     └─ GCP SCC Enterprise + Wiz (post-acquisition integration)
  ├─ Multi-cloud, want fast agentless deployment?
  │     └─ Wiz (Security Graph) or Orca (SideScanning)
  ├─ Existing Palo Alto investment?
  │     └─ Prisma Cloud (broadest CNAPP, module-based)
  └─ Need lowest alert noise?
        └─ Wiz or Orca (~20-30 actionable/day vs Prisma's 100-150)
```

### "Which SIEM?" Decision Tree

```
Start
  ├─ Microsoft 365 E5 / Azure-heavy?
  │     └─ Microsoft Sentinel (30-50% cost savings, Copilot integration)
  ├─ CrowdStrike Falcon already deployed?
  │     └─ Falcon LogScale (unified endpoint + SIEM, streaming architecture)
  ├─ GCP / Chronicle available?
  │     └─ Google SecOps (retention-based pricing, Mandiant intelligence)
  ├─ Large heterogeneous environment / mature SOC?
  │     └─ Splunk ES (2,800+ integrations, deepest ecosystem)
  └─ Want open-source / self-managed control?
        └─ Elastic Security (flexible deployment, transparent architecture)
```

### "Which Runtime Security?" Decision Tree

```
Start
  ├─ Need real-time enforcement (kill/block)?
  │     └─ Tetragon (in-kernel enforcement, lowest overhead)
  ├─ Need broadest detection rules + compliance auditing?
  │     └─ Falco (largest rule library, CNCF Graduated, multi-source)
  ├─ Need network microsegmentation + L7 policy?
  │     └─ Cilium (eBPF CNI, identity-aware, WireGuard encryption)
  └─ Need all three?
        └─ Cilium (networking) + Tetragon (runtime enforcement) + Falco (detection breadth)
```

### Vulnerability Prioritization Quick Reference

```
Priority 1 (Patch NOW — hours):
  - In CISA KEV catalog
  - EPSS > 0.7
  - Internet-facing asset

Priority 2 (Patch within days):
  - EPSS > 0.4
  - CVSS v4 Base ≥ 9.0
  - Business-critical system

Priority 3 (Patch within sprint):
  - EPSS 0.1-0.4
  - CVSS v4 Base ≥ 7.0
  - Internal-facing asset

Priority 4 (Scheduled maintenance):
  - EPSS < 0.1
  - CVSS v4 Base < 7.0
  - Compensating controls in place
```
