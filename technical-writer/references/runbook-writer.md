# Runbook Writer — Deep Reference

**Always use `WebSearch` to verify current platform features, incident management tool capabilities, and SRE best practices before giving runbook advice. The incident management and runbook automation landscape evolves rapidly. Last verified: April 2026.**

## Table of Contents
1. [Runbook Structure and Templates](#1-runbook-structure-and-templates)
2. [Runbook Platforms](#2-runbook-platforms)
3. [Automated and Executable Runbooks](#3-automated-and-executable-runbooks)
4. [Incident Response Playbooks](#4-incident-response-playbooks)
5. [Troubleshooting Guides](#5-troubleshooting-guides)
6. [Postmortem Templates](#6-postmortem-templates)
7. [Operational Procedures](#7-operational-procedures)
8. [Change Management Documentation](#8-change-management-documentation)
9. [Disaster Recovery Documentation](#9-disaster-recovery-documentation)
10. [Alert Runbooks and SLO Documentation](#10-alert-runbooks-and-slo-documentation)
11. [Toil Documentation](#11-toil-documentation)
12. [Knowledge Management for Ops](#12-knowledge-management-for-ops)
13. [Production Readiness Reviews](#13-production-readiness-reviews)
14. [Compliance and Audit Documentation](#14-compliance-and-audit-documentation)
15. [Communication Templates](#15-communication-templates)

---

## 1. Runbook Structure and Templates

### Standard Sections

Every runbook should include these sections:

1. **Title and Metadata** — service name, owning team, last-reviewed date, environment/region, version
2. **Purpose/Objective** — one sentence: what this runbook achieves
3. **Prerequisites** — required access, tools, permissions, environment setup
4. **Step-by-Step Instructions** — commands (not paragraphs); every step actionable and executable; include expected output for each step
5. **Verification/Validation Steps** — how to confirm each step succeeded
6. **Rollback/Recovery Instructions** — how to safely undo changes
7. **Safety Notes** — timeouts, rate limits, blast radius warnings
8. **Troubleshooting / Common Errors** — FAQ for known failure modes at each step
9. **Escalation Contacts** — who to contact if the runbook doesn't resolve the issue
10. **References** — links to architecture docs, dashboards, related runbooks
11. **Changelog** — version history of the runbook itself

### The 5 A's of Trustworthy Runbooks

A reliable runbook is:
- **Actionable** — every step is a command or a clear decision point
- **Accessible** — scannable in seconds under stress; formatted for 3 AM readability
- **Accurate** — tested and current; last-verified date visible
- **Authoritative** — has a named owner responsible for accuracy
- **Adaptable** — versioned, backwards-compatible, handles edge cases

### Writing Runbook Steps

```markdown
## Step 3: Restart the API Service

**Safety check:** Verify current error rate is above 5% before restarting.

Run:
```bash
kubectl rollout restart deployment/api-service -n production
```

**Expected output:**
```
deployment.apps/api-service restarted
```

**Verify:**
```bash
kubectl rollout status deployment/api-service -n production --timeout=120s
```

**Expected output:**
```
deployment "api-service" successfully rolled out
```

**If verification fails:** Do NOT retry. Escalate to the platform team (#platform-oncall in Slack).
```

### Key Principles

- Write for the engineer at 3 AM who has never seen this service before
- Every step must have a command, an expected output, and a "what if it fails" section
- Use monospace code blocks for every command — no inline commands in paragraphs
- Include the "why" for non-obvious steps — it helps the operator make judgment calls
- Test runbooks by having someone unfamiliar with the service follow them

---

## 2. Runbook Platforms

### Platform Comparison

| Platform | Category | Key Strength | Best For |
|----------|----------|-------------|----------|
| **PagerDuty Process Automation** (formerly Rundeck) | Runbook automation | 700+ integrations, mature, self-hosted option | Enterprise teams with complex automation needs |
| **Rootly** | AI-driven incident management | AI-powered workflows, dynamic context-aware runbooks, Slack-native | Modern teams wanting AI-assisted incident response |
| **incident.io** | Slack-native incident management | Conditional workflows (per service/severity/time-of-day), service catalog, status pages | Teams wanting Slack-native L1 support |
| **Shoreline.io** (NVIDIA) | Automated remediation | Jupyter-style notebooks, agents on every host, Op Pack library | Fast automation building (30x faster claim) |
| **FireHydrant** | Reliability platform | Service catalog, runbook automation, incident analytics | Teams wanting combined catalog + runbooks |
| **Backstage** (Spotify) | Developer portal | Software catalog + TechDocs + runbook integration | Centralized service documentation |

### Specialized / Adjacent Tools

| Tool | Focus |
|------|-------|
| **Cutover** | Enterprise runbook automation with AI, MCP Server for LLM integration |
| **Harness** | AI SRE with "AI Scribe Agent" for autonomous incident documentation |
| **HCL BigFix Runbook AI** | GenAI-powered runbook automation at enterprise scale |
| **Relvy.ai** | AI-powered on-call runbook automation |

### Market Trends (2025-2026)

- **Chat-native** (Slack/Teams) is the dominant architecture — reduces coordination overhead by ~15 min per incident
- **AI copilots** for incident response becoming table stakes
- AI-powered SRE platforms claim to cut toil by 60% and save ~4.87 hours per incident

---

## 3. Automated and Executable Runbooks

### Automation Levels

| Level | Description | Example |
|-------|-------------|---------|
| **Static/Manual** | Markdown/wiki pages with copy-paste commands | Confluence page |
| **Semi-Automated** | Documents with embedded executable code blocks, human-triggered | Runme with manual execution |
| **Executable** | Notebook-style; operators click to execute steps and see results inline | Shoreline notebooks, Jupyter + Rubix |
| **Fully Automated** | Triggered by monitoring alerts, execute without human intervention | PagerDuty automation, Rootly AI workflows |

### Executable Runbook Tools

| Tool | Approach | Best For |
|------|----------|----------|
| **Runme** | Shell/Bash kernel for Markdown; VS Code extension, CLI, GitHub Action | Best-in-class "runbooks as code" |
| **Stew** | Executable Markdown in terminal, SSH, or browser | Lightweight executable runbooks |
| **Runbook.md** | Bash-executable Markdown | Simple automation |
| **Jupyter + Rubix** | Jupyter notebooks with DevOps-specific library (CloudWatch, ECS/K8s) | Data-driven operational investigation |
| **Octopus Deploy** | Config-as-Code for Runbooks (2025.1); version-controlled in Git | Deployment-focused runbook automation |

### Runbook-as-Code Best Practices

- Store runbooks in Git alongside application code
- Use structured Markdown with executable code blocks (Runme format)
- YAML metadata headers for tagging, ownership, and search
- CI/CD testing of runbook validity (Runme GitHub Action)
- Version control everything for audit trail and rollback
- Progressive automation: start manual, identify repetitive steps, automate incrementally

---

## 4. Incident Response Playbooks

### Severity Level Framework

| Level | Name | Description | Response Time | Auto-Escalation |
|-------|------|-------------|---------------|-----------------|
| **SEV1/P1** | Critical | Complete outage, all users affected | Immediate (< 15 min) | Page IC, Eng Manager, VP |
| **SEV2/P2** | High | Partial outage, major feature unavailable | 15 minutes | Page on-call + service owners |
| **SEV3/P3** | Medium | Degraded performance, workaround available | 1 hour | Notify on-call |
| **SEV4/P4** | Low | Minor issue, no user impact | Next business day | Queue for triage |

### Auto-Escalation Rules

- No acknowledgment in 10 min → page secondary on-call
- No acknowledgment in 20 min → page engineering manager
- SEV1 not resolved in 1 hour → VP of Engineering notification

### Playbook Structure

1. **Severity classification criteria** — objective, measurable thresholds (not subjective judgment)
2. **Role assignments** — Incident Commander, Communications Lead, Scribe, Subject Matter Experts; each with pre-authorized decision authority
3. **Communication plan** — who gets notified, through what channel, at what frequency
4. **Response procedures** — step-by-step per severity level
5. **Escalation paths** — clear chain with contact information
6. **Testing protocol** — tabletop exercises (minimum semi-annually)

### War Room Protocols

- Auto-create dedicated Slack channel + video call + page on-call when war room activates
- One consistent link for all war rooms; anyone in org can access
- Focused team composition — dismiss people not needed for resolution
- One shared screen showing primary investigation
- Maintain singular focus: **restore service first, investigate root cause later**
- Account for human factors: stress, fatigue, timezone differences in virtual war rooms
- Run tabletop exercises semi-annually at minimum

---

## 5. Troubleshooting Guides

### Decision Tree Format

Best for common, well-understood failure modes:

```
Symptom: API returning 5xx errors
├── Check: Is the database reachable?
│   ├── No → Run: [database connectivity runbook]
│   └── Yes → Continue
├── Check: Are pods healthy?
│   ├── No (CrashLoopBackOff) → Run: [pod restart runbook]
│   └── Yes → Continue
├── Check: Is memory usage above 90%?
│   ├── Yes → Run: [memory pressure runbook]
│   └── No → Escalate to service owner
```

### Symptom-Based Diagnosis Structure

1. **Symptom Entry Point** — "What are you seeing?" (e.g., high latency, 5xx errors, pod crash loops)
2. **Diagnostic Commands** — specific commands to run at each branch
3. **Expected vs. Actual Output** — what "good" looks like vs. failure indicators
4. **Root Cause Mapping** — symptom → possible causes → verification steps → fix
5. **Escalation Point** — when to stop and escalate (with specific criteria)

### Best Practices

- Every alert should map to a troubleshooting section with the first 3 minutes of triage pre-scripted
- Include diagnostic commands with expected outputs for both healthy and unhealthy states
- Provide links to relevant dashboards, logs, and traces
- Include "common red herrings" — symptoms that look like one problem but are actually another
- Update troubleshooting guides after every incident that revealed a new failure mode

---

## 6. Postmortem Templates

### Blameless Postmortem Template (Google SRE Standard)

1. **Incident Summary** — one-paragraph description of what happened
2. **Impact** — duration, users affected, revenue impact, SLO impact / error budget consumed
3. **Timeline** — minute-by-minute chronology: detection → escalation → mitigation → resolution
4. **Root Cause Analysis** — contributing factors (NOT blame on individuals)
5. **What Went Well** — things that worked during response (positive reinforcement matters)
6. **Where We Got Lucky** — near-misses that could have made it worse
7. **What Can Be Improved** — process, tooling, monitoring gaps
8. **Action Items** — each with: owner, priority, due date, verification criteria
9. **Lessons Learned** — systemic insights applicable beyond this incident
10. **Supporting Data** — links to dashboards, logs, graphs, Slack threads

### Postmortem Best Practices

- Focus on contributing causes, NOT indicting individuals — "the deployment pipeline lacked a canary stage" not "engineer X deployed without testing"
- **Error budget rule**: if a single incident consumes > 20% of error budget over 4 weeks → mandatory postmortem with at least one P0 action item
- Action items MUST have: owner, priority, due date, and verification criteria — "improve monitoring" is not an action item; "add latency p99 alert for /checkout endpoint with 500ms threshold by 2026-05-01 (owner: @alice)" is
- Conduct review meeting with cross-functional stakeholders
- Publish postmortems internally — they build organizational learning
- Track action item completion rate — postmortems without follow-through erode trust

### Tooling

- **Rootly**: auto-generates postmortem drafts from incident data
- **Harness AI Scribe Agent**: autonomously documents incidents
- **Miro**: Blameless Postmortem Canvas template for visual collaboration
- Google SRE Workbook: canonical example postmortems

---

## 7. Operational Procedures

### Deployment Checklist Template

1. **Pre-deployment**:
   - [ ] Code review approved
   - [ ] Tests passing (unit, integration, e2e)
   - [ ] Feature flags configured
   - [ ] Rollback plan documented
   - [ ] Stakeholders notified
   - [ ] Monitoring dashboards open
2. **Deployment execution**:
   - [ ] Deploy to staging
   - [ ] Run smoke tests on staging
   - [ ] Deploy canary (if applicable)
   - [ ] Monitor canary metrics for [X] minutes
   - [ ] Gradual rollout (25% → 50% → 100%)
3. **Post-deployment**:
   - [ ] Verify key metrics (error rate, latency, throughput)
   - [ ] Confirm feature functionality
   - [ ] Update status in deployment tracker
4. **Rollback triggers** (defined thresholds):
   - Error rate exceeds [X]% for [Y] minutes
   - Latency p99 exceeds [X]ms for [Y] minutes
   - Any SEV1/SEV2 alert fires

### On-Call Handoff Documentation

Template for shift transitions (Google SRE pattern):

- **Active incidents**: current status, working theories, pending actions
- **Unusual system behavior**: observations that don't constitute incidents but warrant attention
- **Pending actions**: scheduled maintenance, expected deployments, expiring certificates
- **Incident mental models**: working theories about ongoing problems for incoming engineer
- **Upcoming maintenance**: windows, expected impact, responsible teams

Allocate 15-30 minutes for structured handover. Send handoff email/Slack at end of shift; read incoming handoff at start of shift.

### Maintenance Window Documentation

- Window duration, affected services, expected impact
- Step-by-step maintenance procedure with verification
- Rollback procedure and criteria
- Stakeholder notification list and templates
- Post-maintenance verification checklist

---

## 8. Change Management Documentation

### Change Request Template

1. **Change description and justification** — what, why, and what's the alternative (doing nothing)
2. **Risk assessment** — risk factor scoring, probability, severity
3. **Impact assessment** — affected services, dependencies, users, downstream consumers
4. **Implementation plan** — detailed steps with roles, timelines, verification points
5. **Rollback plan** — specific steps, responsible roles, required tools, timeline
6. **Testing/validation plan** — how the change will be verified before and after
7. **Approval workflow** — who must sign off before proceeding
8. **Communication plan** — who needs to know, when, through what channel
9. **Post-change verification** — metrics to confirm success

### Rollback Documentation

Every change must have a documented rollback procedure before approval:
- Specific reversal steps (not "undo the change")
- Rollback decision criteria (when to trigger)
- Who has authority to decide on rollback
- Expected rollback time
- Verification that rollback succeeded
- Rollback procedures must be **tested**, not just documented

---

## 9. Disaster Recovery Documentation

### DR Plan Structure (NIST SP 800-34)

1. **Activation criteria** — specific conditions that trigger DR plan activation
2. **Recovery procedures** — step-by-step per recovery strategy
3. **Reconstitution steps** — how to return to normal operations
4. **Roles and communication trees** — who does what, contact chains
5. **Recovery site locations** — primary, secondary, tertiary

### Recovery Strategy Documentation

| Strategy | RTO | RPO | Cost | When to Use |
|----------|-----|-----|------|-------------|
| **Backup & Restore** | Hours-days | Hours | Lowest | Non-critical services, cost-sensitive |
| **Pilot Light** | Minutes-hours | Minutes | Medium | Core infrastructure stays warm |
| **Warm Standby** | Minutes | Seconds-minutes | Medium-High | Important services needing fast recovery |
| **Hot Standby / Multi-Site** | Minutes | Near-zero | Highest | Mission-critical, zero-tolerance for downtime |

### DR Testing Protocols (NIST, ascending rigor)

1. **Tabletop exercises** (quarterly) — walkthrough on paper, identify gaps
2. **Structured walk-throughs** — detailed step-by-step review with all participants
3. **Simulation tests** — controlled simulation without affecting production
4. **Full-interruption tests** (annually; monthly for critical systems) — actual failover

### Documentation Requirements

- RTO/RPO targets per service tier
- Data backup verification records (prove backups are restorable)
- Cross-region failover procedures
- Communication plan during DR activation
- Contact trees for all roles
- Regular review and update cadence (minimum annually)

---

## 10. Alert Runbooks and SLO Documentation

### Alert Runbook Requirements

Every alert MUST have a linked runbook containing:
- Short title, owner, last-reviewed date
- Which alerts map to this runbook (symptom mapping)
- Minimum triage checklist (first 3 minutes pre-scripted)
- Remediation steps with safety checks and rollback
- Post-incident logging with tags for SLO attribution

**The test: if the on-call engineer has to think about what to investigate at 3 AM, the alert is incomplete.**

### SLO Document Structure (Google SRE Workbook)

1. **Service description** and user journeys
2. **SLI definitions** — end-to-end outcomes: success rate, latency percentiles, data correctness, durability
3. **SLO targets** — start with 2-3 user-impacting indicators per service
4. **Measurement window** — rolling 28-day or calendar month
5. **Error budget policy** — what happens when budget is exhausted

### Error Budget Policy Template

| Condition | Action |
|-----------|--------|
| Performing at/above SLO | Releases proceed normally |
| Error budget approaching exhaustion (< 20% remaining) | Increase change review rigor; prioritize reliability work |
| Error budget exceeded for preceding 4-week window | Halt all changes except P0/security fixes |
| Single incident consuming > 20% of 4-week budget | Mandatory postmortem with P0 action item |
| Disagreement on budget enforcement | Escalate to CTO / VP Engineering |

### Alert Strategy Best Practices

- Use multiwindow, multi-burn-rate alerting (Google SRE recommended)
- Alert on **symptoms**, not causes — "error rate exceeds SLO" not "CPU usage high"
- Every alert must be actionable — "alert fatigue is an engineering failure"
- Link every alert to a runbook — no alert without a documented response

### SLO Tooling

Grafana SLO, Nobl9, Splunk Observability, Google Cloud SLO Monitoring, Datadog SLO

---

## 11. Toil Documentation

### Definition (Google SRE)

Toil is work that is manual, repetitive, automatable, tactical, devoid of enduring value, and scales linearly with service growth. SRE teams should spend no more than 50% of time on toil.

### Toil Identification Process

1. Run a **5-day toil log** during on-call: write down each repetitive task with trigger, steps, time, frequency, pain level
2. Look for patterns in tickets, surveys, and incident response
3. Score using: Frequency + Duration + Risk
4. Sort by score, start with top 5 automation candidates

### Toil Documentation Template

| Task | Trigger | Steps | Time (min) | Frequency | Automatable? | Priority |
|------|---------|-------|-----------|-----------|-------------|----------|
| Certificate renewal | Alert: cert expiry < 30d | 4 manual steps | 30 | Monthly | Yes (cert-manager) | High |
| Log disk cleanup | Alert: disk > 90% | SSH, delete old logs | 15 | Weekly | Yes (logrotate) | Medium |
| Access provisioning | Ticket | 6 manual steps | 20 | Daily | Yes (Terraform) | High |

### Automation ROI Calculation

- Aggregate human-hours per toil category
- Multiply by engineer compensation
- Compare against engineering time needed to automate
- Prioritize: high-frequency, high-cost toil first
- Review toil budget monthly or quarterly in retrospectives

---

## 12. Knowledge Management for Ops

### Searchable Runbook Repository Requirements

- Full-text search with semantic/meaning-based retrieval (not just keywords)
- Automated tagging and categorization
- Lightweight metadata header on every page: owning team, service, last validated date, environment
- Every article has a **named owner**

### Review Cadence

- **Monthly review** for active runbooks; weekly refresh if incident volume is high
- Explicit ownership + review cadence is mandatory, not optional
- **Stale runbooks are worse than no runbooks** — they erode trust
- Trigger review when: a runbook is used in an incident, a service architecture changes, or 3 months pass without review

### Knowledge Management Platforms

| Platform | Best For |
|----------|----------|
| **Backstage TechDocs** | Integrated with service catalog |
| **Confluence** | Enterprise; structured templates |
| **GitBook** | Modern, managed KB |
| **Notion** | Flexible internal wiki |
| **Glean** | AI-powered semantic search across all sources |

### Key Metric

Measure knowledge management capability by linking runbooks to incident outcomes. Track whether runbook usage correlates with faster MTTR (Mean Time to Resolution).

---

## 13. Production Readiness Reviews

### PRR Checklist (Grafana Labs / Google SRE)

A formal multidisciplinary verification before a service goes to production:

1. **Reliability** — SLOs defined, error budgets set, alerting configured
2. **Observability** — logging, metrics, tracing, dashboards in place
3. **Deployment Safety** — rollback procedures documented, canary analysis configured
4. **Performance** — load testing completed, capacity planning documented
5. **Cost Controls** — resource utilization reviewed, budget allocated
6. **Compliance** — security review completed, access controls configured
7. **Documentation** — runbooks written, architecture docs current, on-call procedures defined

### PRR Process

- Analysis phase: SRE reviewers learn the service, check against PRR checklist
- Checklist is specific to the service, based on domain expertise
- Create fresh PRR template for each review — do NOT reuse previous PRR docs
- Document findings and track action items to completion
- PRR is a gate, not a formality — services that fail PRR don't go to production

---

## 14. Compliance and Audit Documentation

### SOC 2 Documentation Requirements

- Evidence of control operation: logs, screenshots, tickets, access reviews (especially Type 2)
- Documented change management procedures
- Incident response documentation with timeline and resolution
- Access control logs and periodic access reviews (quarterly minimum)
- Business continuity documentation

### ISO 27001 Documentation Requirements

- Complete ISMS documentation (Information Security Management System)
- Stage 1: documentation assessment
- Stage 2: implementation and effectiveness audit
- Recertification against 2022 version required by October 31, 2025

### Reusable Evidence

Both SOC 2 and ISO 27001 require documentation for: access control, change management, incident response, business continuity, risk management, security policies. Structure evidence to serve both audits.

### Compliance Platforms

Drata, Vanta, Secureframe, TrustCloud — automate evidence collection and map controls to framework requirements.

---

## 15. Communication Templates

### Status Page Updates (Phase-Based)

| Phase | Template |
|-------|----------|
| **Investigating** | "We are aware of [issue description] affecting [service]. Our team is investigating. Next update in [X] minutes." |
| **Identified** | "We have identified [root cause summary]. [Impact description]. We are working on [remediation]. Next update in [X] minutes." |
| **Monitoring** | "A fix has been implemented for [issue]. We are monitoring to confirm resolution. Users may still experience [residual impact]." |
| **Resolved** | "The issue affecting [service] has been resolved as of [time]. [Brief summary]. We will publish a full postmortem within [timeframe]." |

### Communication Rules

- Tell customers: are they impacted, what changed, what's the workaround, when is the next update
- **Talk about impact, not internals** — "Users may experience slower load times" not "Our Kafka cluster is experiencing partition rebalancing"
- Update every 15 minutes on canonical source (status page or email)
- Always include the next update time — silence creates anxiety
- Use pre-prepared templates so the incident team fills in blanks under stress

### Audience-Specific Templates

| Audience | Focus | Detail Level |
|----------|-------|-------------|
| **Customers** | Impact, workaround, timeline | Plain language, no technical jargon |
| **Executives** | Business impact, revenue risk, timeline | Concise, focus on business metrics |
| **Engineering** | Technical details, incident ID, severity | Full technical context |
| **Support team** | Customer-facing impact, known workarounds, FAQ | Actionable for customer conversations |

### Status Page Platforms

Statuspage (Atlassian), Hyperping, incident.io, Instatus, StatusHub, Site24x7 StatusIQ
