# Incident Response & Management — Deep Reference

**Always use `WebSearch` to verify version numbers, tool features, and best practices before giving advice. This reference provides architectural context; the ecosystem evolves rapidly.**

## Table of Contents
1. [Incident Management Tool Selection](#1-incident-management-tool-selection)
2. [Incident Classification & Severity](#2-incident-classification--severity)
3. [On-Call Design](#3-on-call-design)
4. [Incident Response Process](#4-incident-response-process)
5. [Runbook Creation](#5-runbook-creation)
6. [Postmortem / Blameless Retrospective](#6-postmortem--blameless-retrospective)
7. [Status Page Management](#7-status-page-management)
8. [Incident Metrics & Analytics](#8-incident-metrics--analytics)
9. [Tabletop Exercises & Simulations](#9-tabletop-exercises--simulations)
10. [Communication During Incidents](#10-communication-during-incidents)

---

## 1. Incident Management Tool Selection

### Comparison Matrix (2025-2026)

| Feature | PagerDuty | Opsgenie | incident.io | Rootly | FireHydrant | Grafana OnCall | Squadcast |
|---------|-----------|----------|-------------|--------|-------------|----------------|-----------|
| **On-Call Scheduling** | Excellent | Good | Good | Good | Good | Good | Good |
| **Slack-Native Response** | Add-on | Limited | Core | Core | Core | Limited | Moderate |
| **Teams Integration** | Yes | Yes | Yes | Yes | Yes | Limited | Yes |
| **Workflow Automation** | Business+ | Yes | Yes | Excellent | Good | Basic | Good |
| **Status Pages** | Add-on | Included | Included | Included | Included | No | Included |
| **Postmortem Generation** | Business+ | Basic | Auto-generated | Auto-generated | Auto-generated | No | Yes |
| **AI/ML Features** | Event Intelligence | Alert grouping | AI SRE | AI-native | AI-native | No | Intelligent alerts |
| **Runbook Automation** | PD Automation | Basic | Workflows | Workflows | Runbooks | No | Runbooks |
| **Integrations** | 700+ | 200+ | 80+ | 100+ | 100+ | Grafana stack | 100+ |
| **Free Tier** | 5 users | N/A (sunsetting) | No | No | No | Yes (OSS archived) | 5 users |
| **Self-Hosted Option** | No | No | No | No | No | Archived 2026 | No |

### Pricing (2025-2026)

| Platform | Entry Plan | Mid Tier | Enterprise |
|----------|-----------|----------|------------|
| **PagerDuty** | Free (5 users), Professional $21/user/mo | Business $41/user/mo | Custom |
| **Opsgenie** | Sunsetting (new sales ended Jun 2025, shutdown Apr 2027) | -- | -- |
| **incident.io** | Team $25/user/mo (+$12 for on-call) | Pro $45/user/mo (+$20 for on-call) | Custom |
| **Rootly** | Starter $20/user/mo | Pro (custom) | Custom |
| **FireHydrant** | Platform Pro $9,600/yr (up to 20 responders) | Enterprise (custom) | Freshworks bundle |
| **Grafana OnCall** | Free tier in Grafana Cloud ($25K/yr min commit) | Part of Grafana Cloud IRM | Custom |
| **Squadcast** | Free (5 users), Essentials $9/user/mo | Pro $19/user/mo | Enterprise $39/user/mo |

### Critical Market Notes

**Opsgenie end-of-life**: Atlassian ended new Opsgenie sales on June 4, 2025. Full shutdown scheduled for April 5, 2027. Teams on Opsgenie should migrate now. Atlassian is consolidating into Jira Service Management.

**FireHydrant acquired by Freshworks**: Announced December 2025, closed Q1 2026. FireHydrant is being integrated into Freshworks' Freshservice as a unified AI-native ServiceOps platform. Existing standalone contracts are honored, but long-term roadmap is ITSM convergence.

**Grafana OnCall OSS archived**: The open-source version was archived on March 24, 2026. Only the Grafana Cloud managed version continues active development.

### Decision Framework

**Choose PagerDuty when**: You need the largest integration ecosystem, enterprise-grade event intelligence, and your organization is already invested in the PagerDuty platform. Best for large enterprises with complex routing needs.

**Choose incident.io when**: Your team lives in Slack, you want opinionated defaults that work immediately, and you value auto-generated postmortems and timelines. Best for mid-size engineering teams (50-500 engineers) that want fast time-to-value.

**Choose Rootly when**: You need deep workflow customization, conditional automation logic, and the ability to replicate complex Opsgenie configurations. Best for teams migrating from Opsgenie or those with sophisticated automation requirements.

**Choose FireHydrant when**: You want to codify incident response as code through flexible runbooks, and you are already in or planning to adopt the Freshworks ecosystem. Best for teams that want process standardization.

**Choose Squadcast when**: You need a cost-effective all-in-one platform with intelligent alert noise reduction. Best for small-to-mid teams (5-100 engineers) and budget-conscious organizations.

**Choose Grafana OnCall when**: Your observability stack is Grafana-native (Prometheus, Loki, Tempo) and you want tight integration without context-switching. Best for compact SRE teams with simple escalation needs.

### Integration Architecture Pattern

```
Monitoring (Datadog/Grafana/New Relic)
    |
    v
Alert Routing (PagerDuty / incident.io / Rootly)
    |
    +---> Slack/Teams Channel (War Room)
    |         |
    |         +---> Status Page Update
    |         +---> Stakeholder Notification
    |         +---> Runbook Trigger
    |
    +---> On-Call Notification (Phone/SMS/Push)
    |
    +---> Escalation Chain
    |
    v
Postmortem Generation --> Action Item Tracker (Jira/Linear)
```

---

## 2. Incident Classification & Severity

### Severity Level Definitions

Use this template as a starting point. Calibrate thresholds to your service's SLOs.

#### SEV1 / P1 — Critical

| Criterion | Definition |
|-----------|-----------|
| **User Impact** | >50% of users cannot use the primary service function |
| **Revenue Impact** | Revenue-generating systems are down or transactions are failing |
| **Data Impact** | Active data loss or data corruption occurring |
| **SLO Impact** | Error budget for the quarter will be exhausted within hours |
| **Security** | Active security breach with data exfiltration |
| **Response Time** | Acknowledge within 5 minutes, all-hands response |
| **Communication** | Executive notification within 15 minutes, status page updated within 10 minutes |
| **Examples** | Production database down, payment processing failure, authentication system outage, complete API gateway failure |

#### SEV2 / P2 — High

| Criterion | Definition |
|-----------|-----------|
| **User Impact** | 10-50% of users affected, or a critical feature is degraded |
| **Revenue Impact** | Revenue impact is occurring but partial (some transactions succeed) |
| **Data Impact** | Risk of data loss but not actively occurring |
| **SLO Impact** | Error budget burn rate is 10x normal |
| **Security** | Vulnerability identified with known exploit, no active breach |
| **Response Time** | Acknowledge within 15 minutes, dedicated team response |
| **Communication** | Engineering leadership notified within 30 minutes, status page updated within 20 minutes |
| **Examples** | Search degraded for a region, elevated error rates on checkout, one availability zone down in multi-AZ setup |

#### SEV3 / P3 — Moderate

| Criterion | Definition |
|-----------|-----------|
| **User Impact** | <10% of users affected, or a non-critical feature is broken |
| **Revenue Impact** | Minor or no direct revenue impact |
| **Data Impact** | No data loss risk |
| **SLO Impact** | Error budget burn rate is 2-5x normal |
| **Security** | Vulnerability identified, no known exploit |
| **Response Time** | Acknowledge within 1 hour, addressed during business hours |
| **Communication** | Team lead notified, status page updated if customer-visible |
| **Examples** | Internal dashboard down, non-critical background job failures, slow search in one region, mobile app minor feature broken |

#### SEV4 / P4 — Low

| Criterion | Definition |
|-----------|-----------|
| **User Impact** | Cosmetic issues or edge cases affecting very few users |
| **Revenue Impact** | None |
| **Data Impact** | None |
| **SLO Impact** | Within normal error budget burn |
| **Security** | Informational finding, best practice deviation |
| **Response Time** | Addressed in next sprint |
| **Communication** | Ticket created, no escalation |
| **Examples** | Typo in error message, UI alignment issue in one browser, deprecated API returning wrong status code |

### Impact Matrix

```
                    Business Impact
                    Low         Medium      High        Critical
                +-----------+-----------+-----------+-----------+
User     Low    |   SEV4    |   SEV4    |   SEV3    |   SEV3    |
Impact          +-----------+-----------+-----------+-----------+
         Medium |   SEV4    |   SEV3    |   SEV2    |   SEV2    |
                +-----------+-----------+-----------+-----------+
         High   |   SEV3    |   SEV2    |   SEV1    |   SEV1    |
                +-----------+-----------+-----------+-----------+
         Crit   |   SEV3    |   SEV2    |   SEV1    |   SEV1    |
                +-----------+-----------+-----------+-----------+
```

### Priority vs Severity

**Severity** = the technical impact right now. It is an objective assessment of the blast radius.

**Priority** = how urgently should we fix it. This is a business decision factoring in severity, workarounds, upcoming events, contractual obligations, and cost of delay.

A SEV3 bug on your highest-revenue customer's account may be **P1 priority**. A SEV1 failure in a staging environment may be **P3 priority**. Always capture both.

### Avoiding the "Everything is SEV1" Trap

1. **Tie severity to SLOs** — if you have an error budget and the incident does not threaten it, it cannot be SEV1
2. **Require SEV1 declarations to come from the Incident Commander or on-call lead** — not the reporter
3. **Review severity accuracy in postmortems** — was it over-classified or under-classified?
4. **Publish severity statistics quarterly** — if >15% of incidents are SEV1, your definitions are wrong
5. **Make SEV1 expensive** — it pages the entire on-call chain, wakes people up, and triggers exec comms. Teams learn quickly to classify accurately when SEV1 means disrupting people
6. **Create a SEV0 for true catastrophic events** — some organizations use SEV0 (multi-service outage, complete platform failure) so that SEV1 does not become the catch-all

---

## 3. On-Call Design

### Rotation Patterns

#### Weekly Rotation
```
Week 1: Alice (primary), Bob (secondary)
Week 2: Bob (primary), Carol (secondary)
Week 3: Carol (primary), Alice (secondary)
Handoff: Monday 10:00 AM local time
```
- **Pros**: Simple, predictable, engineers can plan their week
- **Cons**: Full week of on-call is exhausting if noisy, weekend coverage means 168 hours straight
- **Best for**: Low-alert-volume services, teams of 4+ engineers

#### Daily Rotation
```
Mon: Alice | Tue: Bob | Wed: Carol | Thu: Dave | Fri: Alice
Sat: Bob  | Sun: Carol
Handoff: 09:00 AM local time
```
- **Pros**: Lower per-person burden, faster recovery between shifts
- **Cons**: More handoffs mean more context-loss risk, harder to follow multi-day incidents
- **Best for**: High-alert-volume services, teams that want to minimize individual burden

#### Follow-the-Sun
```
US Pacific (08:00-16:00 PT): Team West
US Eastern (08:00-16:00 ET / 11:00-19:00 PT): Team East
Europe (08:00-16:00 CET / 23:00-07:00 PT): Team EU
APAC (08:00-16:00 SGT / 16:00-00:00 PT): Team APAC
```
- **Pros**: No overnight pages for anyone, reduces burnout by up to 67%, respects sleep
- **Cons**: Requires 3+ regional teams, demands excellent handoff documentation, expensive to staff
- **Best for**: Global companies with distributed engineering teams, critical 24/7 services

#### Hybrid (Business Hours + Reduced After-Hours)
```
Business hours (09:00-18:00): Full on-call with all alerts
After hours (18:00-09:00): Only SEV1/SEV2 alerts page; SEV3/SEV4 go to queue
Weekends: SEV1 only pages; everything else waits for Monday
```
- **Pros**: Balances coverage with quality of life, reduces alert fatigue
- **Cons**: Requires good severity classification in alerting rules
- **Best for**: Most teams as a pragmatic middle ground

### Primary / Secondary / Escalation Chain

```
Alert Fired
    |
    v
Primary On-Call (5 min to acknowledge)
    |
    | (no ack after 5 min)
    v
Secondary On-Call (5 min to acknowledge)
    |
    | (no ack after 5 min)
    v
Team Lead / Engineering Manager (10 min to acknowledge)
    |
    | (no ack after 10 min OR SEV1 declared)
    v
VP Engineering / CTO (for SEV1 only)
```

**Rules for escalation**:
- Primary gets first notification via push + SMS + phone call
- Secondary gets notification only after primary fails to acknowledge
- Manager escalation is automatic after 10 minutes of no response on any SEV1/SEV2
- Never skip levels unless the incident is already declared SEV1

### On-Call Compensation Models

| Model | Structure | Example | Best For |
|-------|-----------|---------|----------|
| **Flat weekly stipend** | Fixed payment per on-call week | $350-$1,000/week regardless of pages | Most common, simple to administer |
| **Daily rate** | Fixed payment per on-call day | $50-$150/day | Daily rotations, part-time on-call |
| **Hourly on-call rate** | Percentage of base rate for each hour on-call | 10-35% of hourly rate | Regulated industries, FLSA compliance |
| **Tiered response** | Different rates by response time requirement | Tier-1 (5-min): 66% base rate, Tier-2 (30-min): 33% base rate | Google-style, large SRE orgs |
| **Per-incident bonus** | Base stipend + bonus per page answered | $500/week + $50/incident outside business hours | High-severity services |
| **Time-off-in-lieu (TOIL)** | Compensatory time off after on-call shift | 1 day off after 1 week on-call | Non-US companies, startups |
| **Included in salary** | On-call expectation baked into higher base compensation | Base salary 10-20% above market for role | Common at FAANG, controversial |

**Industry benchmarks (2025-2026)**:
- US SaaS companies: $350-$600/week flat stipend
- Financial services: $400-$800/week + per-incident bonuses
- Healthcare/regulated: $500-$1,000/week (higher due to compliance requirements)
- Startups (<50 eng): Often TOIL or included in salary

### Burnout Prevention

1. **Maximum on-call frequency**: No more than 1 week in 4 (Google SRE recommendation). Ideally 1 in 6 for high-volume services
2. **Track off-hours pages per shift**: Target <2 off-hours pages per on-call week. If consistently higher, invest in alert tuning
3. **Mandatory post-on-call review**: Every rotation handoff should include a 15-minute review of what happened, what was noisy, what needs fixing
4. **On-call load balancing**: Use tooling to track pages per person. If one engineer gets 3x the pages due to their service ownership, redistribute
5. **Protected recovery time**: After a night of incident response (>2 hours of active work between 22:00-06:00), the engineer gets the next morning off
6. **On-call health dashboards**: Track and publish pages-per-shift, off-hours pages, time-to-acknowledge, and escalation rate. Review monthly
7. **Alert hygiene sprints**: Dedicate 1-2 sprints per quarter to reducing alert noise, improving runbooks, and automating common remediations

### On-Call Onboarding — Shadow Rotation

```
Week 1: Shadow reads all alerts and runbooks, does NOT carry the pager
Week 2: Shadow joins as "observer" on primary's shift, follows along on incidents
Week 3: Shadow takes primary with experienced secondary as explicit backup
Week 4: Shadow is fully onboarded primary with normal secondary
```

**Shadow rotation checklist**:
- [ ] Access to all monitoring dashboards (Grafana, Datadog, etc.)
- [ ] Access to incident management tool (PagerDuty, incident.io, etc.)
- [ ] Access to Slack incident channels and escalation channels
- [ ] Completed runbook walkthrough for top 10 most common alerts
- [ ] Successfully resolved at least 1 incident (simulated or real) with supervision
- [ ] Knows how to declare an incident and escalate to secondary
- [ ] Has tested notification delivery (phone, SMS, push) with the on-call tool
- [ ] Has access to production systems needed for common remediations
- [ ] Understands service architecture and critical dependencies

### On-Call Metrics to Track

| Metric | Target | Red Flag |
|--------|--------|----------|
| Pages per on-call week | <10 total, <2 off-hours | >20 total or >5 off-hours |
| Time to acknowledge | <5 minutes | >15 minutes average |
| Escalation rate | <10% of incidents | >25% of incidents |
| False positive rate | <20% of alerts | >40% of alerts |
| Mean time on-call per engineer per month | 1 week | >2 weeks |
| On-call satisfaction score (survey) | >3.5/5 | <2.5/5 |

---

## 4. Incident Response Process

### The Full Lifecycle

```
Detection --> Triage --> Response --> Mitigation --> Resolution --> Postmortem --> Prevention
   |            |          |            |              |              |              |
 Alerts      Severity   War room     Stop the      Fix root       Learn          Ship
 Monitors    assign     assemble     bleeding      cause          from it        fixes
 Customers   IC named   Roles set    Workaround    Verify         Action items   Automate
 report      Comms      Diagnose     applied       clean          Follow up      Test
```

### Phase 1: Detection

**Sources of detection (ordered by preference)**:
1. **Automated monitoring alerts** — SLO-based burn rate alerts, error rate spikes, latency degradation
2. **Synthetic monitoring** — Health checks, canary requests, synthetic transactions
3. **Log-based anomaly detection** — Error log pattern matching, ML-based anomaly detection
4. **Customer reports** — Support tickets, social media, direct reports
5. **Internal reports** — Engineers noticing issues during normal work

The goal is to minimize MTTD by catching issues through automated means before customers report them. If >20% of incidents are first reported by customers, your monitoring has gaps.

### Phase 2: Triage

**The 5-minute triage checklist**:
1. What service is affected? Check the alert source and service map
2. What is the user impact? Check dashboards for error rates, latency, availability
3. What severity is this? Use the impact matrix from Section 2
4. Is there an obvious recent change? Check deployment logs (last 2 hours)
5. Is this a known issue? Check recent incident history and known issues board

**Triage outcome**: Severity assigned, Incident Commander named, response initiated or alert dismissed as false positive.

### Phase 3: Response — Roles

#### Incident Commander (IC)

The IC is responsible for driving the incident to resolution. They do NOT debug the issue themselves.

**Responsibilities**:
- Declare the incident and set severity
- Create the incident channel (automated via tooling)
- Assign roles (Tech Lead, Comms Lead, Scribe)
- Drive the timeline: "What do we know? What are we trying? When is the next update?"
- Make decisions on escalation, rollback, and customer communication
- Call for additional responders as needed
- Ensure handoffs happen if the incident spans shifts

**Who should be IC**: Experienced engineers or engineering managers who can stay calm under pressure, facilitate cross-team collaboration, and make decisions with incomplete information. IC is a skill that requires practice. Many organizations maintain an IC rotation separate from the on-call rotation.

#### Technical Lead (Tech Lead)

**Responsibilities**:
- Lead the technical investigation and debugging
- Coordinate with other engineers on root cause analysis
- Propose and execute mitigation steps
- Communicate technical status to the IC in plain language
- Document technical findings for the postmortem timeline

#### Communications Lead (Comms Lead)

**Responsibilities**:
- Draft and publish status page updates
- Communicate with internal stakeholders (leadership, support, sales)
- Coordinate customer communications with support team
- Maintain the cadence of updates (every 30 minutes for SEV1, every hour for SEV2)
- Shield the Tech Lead from non-technical interruptions

#### Scribe

**Responsibilities**:
- Maintain a real-time timeline in the incident channel
- Log key decisions, actions taken, and their outcomes
- Capture who said what and when
- This timeline becomes the foundation of the postmortem

### Phase 4: Mitigation

Mitigation is about stopping the bleeding, NOT finding root cause. Prioritize in this order:

1. **Rollback** — If a recent deployment caused the issue, roll it back immediately. Do not debug in production while users suffer
2. **Feature flag disable** — If the issue is behind a feature flag, disable it
3. **Traffic shift** — Route traffic away from the affected region/service/host
4. **Scale up** — If the issue is capacity-related, add capacity
5. **Restart** — If the service is in a bad state, restart it (but investigate why afterward)
6. **Manual workaround** — Apply a temporary fix to restore service while root cause is investigated

**Key principle**: Mitigate first, debug second. The goal is to restore service for users as fast as possible. Root cause analysis happens in the postmortem.

### Phase 5: Resolution

- Confirm the mitigation is holding (monitor for 30-60 minutes)
- Verify through dashboards, synthetic checks, and customer reports that service is restored
- Downgrade the incident if partial restoration is achieved
- Close the incident channel with a summary and link to the postmortem
- Update the status page to "Resolved"

### Phase 6-7: Postmortem and Prevention

See Sections 5 and 6 below.

### Incident Channel Structure (Slack/Teams)

```
#inc-2024-0147-api-latency          <-- Incident war room (auto-created)
#inc-2024-0147-api-latency-internal <-- Internal coordination (optional, for sensitive discussion)
#incidents                           <-- Feed of all active incidents (bot-managed)
#incident-postmortems               <-- Postmortem announcements
#on-call-handoff                    <-- On-call rotation handoffs
```

**War room conventions**:
- Pin the incident summary (severity, IC, status, last update) at the top
- Use threads for long technical discussions to keep the main channel scannable
- Bot posts automatic updates: status changes, severity changes, responder additions
- IC posts structured updates: "STATUS UPDATE: We have identified the root cause as [X]. Mitigation is [Y]. ETA to resolution: [Z]."

### Escalation Procedures

```
[Alert Fired]
    |
    v
[On-Call Engineer] -- Can resolve? --> YES --> Resolve, document
    |
    NO (within 15 min)
    |
    v
[Declare Incident] --> [Assign IC] --> [IC evaluates]
    |
    +-- SEV3/4 --> Team handles during business hours
    |
    +-- SEV2 --> IC + Tech Lead + Comms Lead assembled
    |              |
    |              +-- Not resolved in 1 hour --> Escalate to senior engineers
    |
    +-- SEV1 --> All hands: IC + Tech Lead + Comms Lead + Scribe
                   |
                   +-- Immediate exec notification
                   +-- Not resolved in 30 min --> Escalate to VP Eng
                   +-- Not resolved in 2 hours --> Escalate to CTO
                   +-- Vendor involvement if third-party dependency
```

---

## 5. Runbook Creation

### Runbook Template

```markdown
# Runbook: [Alert Name / Scenario]

## Metadata
- **Service**: [service-name]
- **Alert**: [alert-name-in-monitoring-tool]
- **Severity**: [Typical severity when this fires]
- **Last Reviewed**: [YYYY-MM-DD]
- **Owner**: [team-name]
- **Estimated Resolution Time**: [X minutes]

## Overview
[1-2 sentences: What this alert means and why it fires]

## Prerequisites
- [ ] Access to [production environment / dashboard / tool]
- [ ] Permissions: [specific IAM role or access level]
- [ ] Tools: [kubectl, aws cli, database client, etc.]

## Diagnosis

### Step 1: Verify the alert is real
[Commands to check if this is a true positive]

### Step 2: Assess impact
[How to determine user impact — dashboard links, queries]

### Step 3: Identify root cause
[Decision tree or diagnostic steps]

## Mitigation

### Option A: [Most common fix, e.g., "Restart the service"]
[Exact commands with copy-pasteable snippets]

### Option B: [Second most common fix, e.g., "Scale up"]
[Exact commands]

### Option C: [Nuclear option, e.g., "Rollback deployment"]
[Exact commands with warnings]

## Verification
- [ ] [How to confirm the fix worked — dashboard, query, synthetic check]
- [ ] [How long to monitor before considering resolved]

## Escalation
- If none of the above works, escalate to: [team / person / channel]
- Include this information when escalating: [what to share]

## Post-Resolution
- [ ] File postmortem if SEV1/SEV2
- [ ] Update this runbook if steps were inaccurate
- [ ] Create ticket for permanent fix if a workaround was applied

## History
| Date | Change | Author |
|------|--------|--------|
| YYYY-MM-DD | Created | [name] |
| YYYY-MM-DD | Updated Step 3 | [name] |
```

### Decision Trees vs Linear Procedures

**Use a decision tree when**:
- Multiple root causes can trigger the same alert
- Diagnosis requires branching logic ("If metric X > threshold, go to Step A; otherwise, go to Step B")
- The runbook covers a class of failures rather than a specific one

```
Alert: API Latency > 500ms p99
    |
    +-- Is CPU > 80%?
    |       YES --> Check for hot partitions (Step 3A)
    |       NO  --> Continue
    |
    +-- Is DB connection pool exhausted?
    |       YES --> Check for slow queries (Step 3B)
    |       NO  --> Continue
    |
    +-- Was there a recent deployment?
    |       YES --> Check deployment diff (Step 3C)
    |       NO  --> Continue
    |
    +-- Is upstream dependency degraded?
            YES --> Check dependency status page (Step 3D)
            NO  --> Escalate to senior engineer
```

**Use a linear procedure when**:
- The failure mode is well-understood and always has the same fix
- The runbook is for a specific, narrow scenario (e.g., "Certificate expiration renewal")
- Each step must be followed in order

### Runbook Automation

#### PagerDuty Runbook Automation (Rundeck)

PagerDuty acquired Rundeck and offers it as "PagerDuty Runbook Automation" (formerly Rundeck Enterprise). Key capabilities:

- **Automation Actions**: Trigger automated diagnostics directly from a PagerDuty incident — the responder clicks a button, and the automation runs predefined diagnostic commands
- **Rundeck Runners**: Secure execution agents deployed behind firewalls, within VPCs, and at edge locations. Runners poll the PagerDuty SaaS endpoint for work — no inbound firewall rules needed
- **Access Control**: Define ACLs per team, project, or job type. Use API tokens with minimal required access
- **Audit trail**: Structured logging shows who ran what, when, and the outcome — critical for compliance
- **Deployment options**: SaaS (managed by PagerDuty) or self-hosted (maximum flexibility)

**Crawl-walk-run adoption**:
1. **Crawl**: Automated diagnostics (gather information, no changes) — "Show me the last 10 log lines", "What is the current pod count?"
2. **Walk**: Automated remediation with human approval — "Restart the pod after IC approves"
3. **Run**: Fully automated remediation — "Auto-scale when queue depth exceeds threshold"

#### Runbook-as-Code

Store runbooks alongside the services they support:

```
repo/
  src/
  runbooks/
    high-latency.md
    disk-full.md
    certificate-renewal.md
  alerts/
    high-latency.yaml     <-- alert definition references runbook
  terraform/
```

**Alert-to-runbook linking**: Every alert rule should contain a `runbook_url` annotation that links directly to the relevant runbook:

```yaml
# Prometheus alert rule example
groups:
  - name: api-alerts
    rules:
      - alert: HighLatency
        expr: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m])) > 0.5
        for: 5m
        labels:
          severity: warning
          team: platform
        annotations:
          summary: "API p99 latency is above 500ms"
          runbook_url: "https://github.com/org/repo/blob/main/runbooks/high-latency.md"
```

### Runbook Maintenance

- **Review cadence**: Every runbook must be reviewed at least quarterly. Set a `last_reviewed` date in the metadata
- **Trigger review**: Any time a runbook is used during an incident and a step was wrong or missing, update it immediately as part of the postmortem action items
- **Ownership**: Every runbook has an owning team. Orphaned runbooks are dangerous — they rot faster than code
- **Testing**: Run through runbooks during tabletop exercises (Section 9). If an engineer cannot follow the steps, the runbook needs rewriting
- **Staleness alert**: Set up automation to flag runbooks not reviewed in >90 days

### Runbook Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Wall of text | Engineers skip steps under pressure | Use numbered steps, copy-pasteable commands |
| Assumes expert knowledge | New on-call cannot follow it | Write for someone who has never seen this service |
| Out-of-date commands | Wrong CLI flags, deprecated tools | Review quarterly, test in staging |
| No escalation path | Engineer is stuck with no way forward | Always end with "if this does not work, escalate to..." |
| Missing verification | No way to confirm the fix worked | Include dashboards/queries to verify |
| Generic for all environments | Dev commands run in prod | Include environment-specific variables |
| No decision tree for ambiguous alerts | Engineer guesses which fix to try | Add diagnostic steps before remediation |

---

## 6. Postmortem / Blameless Retrospective

### Postmortem Template

```markdown
# Postmortem: [Incident Title]

**Incident ID**: INC-YYYY-NNNN
**Date**: YYYY-MM-DD
**Duration**: X hours Y minutes
**Severity**: SEV[1-4]
**Incident Commander**: [Name]
**Author**: [Name]
**Status**: [Draft / In Review / Final]

---

## Executive Summary
[2-3 sentences: What happened, what was the impact, how was it resolved]

## Impact
- **User Impact**: [X% of users affected, what they experienced]
- **Duration of Impact**: [Start time - End time, timezone]
- **Revenue Impact**: [Estimated $ lost, or "none"]
- **SLO Impact**: [Which SLOs were breached, error budget consumed]
- **Support Tickets**: [Number of customer reports]
- **Data Impact**: [Any data loss or corruption, or "none"]

## Timeline (all times UTC)

| Time | Event |
|------|-------|
| 14:00 | Monitoring alert fires: API error rate > 5% |
| 14:03 | On-call engineer acknowledges the page |
| 14:05 | On-call checks dashboard, confirms elevated 500s |
| 14:10 | Incident declared as SEV2, IC assigned |
| 14:12 | Slack channel #inc-2024-0147 created |
| 14:15 | Tech Lead identifies recent deployment as potential cause |
| 14:20 | Decision made to rollback deployment v2.3.1 to v2.3.0 |
| 14:25 | Rollback initiated |
| 14:35 | Rollback complete, error rate returning to normal |
| 14:50 | Error rate at baseline, monitoring for stability |
| 15:20 | Incident resolved, status page updated |

## Root Cause Analysis

### What happened
[Detailed technical explanation of the failure chain]

### Contributing Factors
1. [Factor 1: e.g., "The deployment pipeline did not include a canary step"]
2. [Factor 2: e.g., "The configuration change was not covered by integration tests"]
3. [Factor 3: e.g., "The alert threshold was too high, delaying detection by 10 minutes"]

### 5 Whys Analysis
1. **Why** did the API return 500 errors? — Because the database connection pool was exhausted
2. **Why** was the connection pool exhausted? — Because a new query was holding connections 10x longer than expected
3. **Why** was the query so slow? — Because it was missing an index on the `orders.user_id` column
4. **Why** was the missing index not caught? — Because the query was only introduced in the latest deployment and was not load-tested
5. **Why** was there no load testing? — Because the team does not have automated load tests in CI for database queries

**Root cause**: Missing database index on `orders.user_id` introduced by deployment v2.3.1, combined with lack of load testing in the CI pipeline.

## What Went Well
- [ ] On-call engineer acknowledged within 3 minutes
- [ ] Incident was declared and IC assigned within 10 minutes
- [ ] Rollback was executed cleanly within 15 minutes of decision
- [ ] Status page was updated promptly
- [ ] Customer communication was clear and timely

## What Did Not Go Well
- [ ] Alert threshold was too high — we detected the issue 10 minutes after it started
- [ ] No canary deployment — the bad change went to 100% of traffic immediately
- [ ] Load testing is not part of the CI pipeline for database changes
- [ ] The on-call runbook for this alert did not include a "check recent deployments" step

## Action Items

| ID | Action | Owner | Priority | Due Date | Status |
|----|--------|-------|----------|----------|--------|
| AI-1 | Add index on orders.user_id | @backend-team | P1 | YYYY-MM-DD | Done |
| AI-2 | Lower alert threshold from 5% to 2% error rate | @sre-team | P1 | YYYY-MM-DD | In Progress |
| AI-3 | Implement canary deployment for API service | @platform-team | P2 | YYYY-MM-DD | Not Started |
| AI-4 | Add load testing step to CI for DB migration PRs | @backend-team | P2 | YYYY-MM-DD | Not Started |
| AI-5 | Update runbook to include deployment check | @sre-team | P3 | YYYY-MM-DD | Not Started |

## Lessons Learned
[Key takeaways that should be shared broadly with the engineering organization]

---

**Postmortem Review Meeting**: [Date]
**Attendees**: [List]
**Reviewed By**: [Senior engineering leadership name]
```

### Blameless Culture Principles

1. **Assume good intent**: The people involved were intelligent, well-intentioned, and making the best choices they could with the information they had at the time. We cannot "fix" the people — we fix the systems and processes
2. **Use roles, not names**: Write "the on-call engineer" not "Alice" in the postmortem. This keeps the focus on process, not people
3. **Reframe blame as system questions**: Instead of "Why did the engineer push to production without testing?" ask "What about our deployment process allowed an untested change to reach production?"
4. **Celebrate finding the issue**: Thank the people who found and reported the problem. Finding issues is a contribution, not an embarrassment
5. **No postmortem as punishment**: Writing a postmortem is a learning opportunity for the entire organization, never a punitive exercise. If people fear postmortems, they will hide incidents
6. **Leadership sets the tone**: Executives and managers must model blameless behavior. One instance of public blame undoes months of culture building

### Root Cause Analysis Techniques

#### 5 Whys
Ask "why" iteratively until you reach a systemic cause. Stop when you reach a process or system that can be changed. Usually 3-7 levels deep.

**Pitfall**: The 5 Whys can lead to a single linear chain. Real incidents usually have multiple contributing factors. Use it as a starting point, then map the full causal graph.

#### Fault Tree Analysis
Work backward from the failure and map all possible causes as a tree:

```
                        [Service Outage]
                       /                \
            [Code Bug]                [Infra Failure]
           /          \               /            \
    [Missing Index]  [No Tests]  [AZ Down]    [No Failover]
```

#### Contributing Factor Analysis
List ALL factors that contributed to the incident, including:
- **Direct cause**: The thing that broke
- **Enabling conditions**: Things that allowed the failure to happen (no tests, no canary, etc.)
- **Detection gaps**: Why we did not catch it sooner
- **Process gaps**: Why our response was slower than it should have been

### Postmortem Facilitation Guide

**Before the meeting**:
- Author writes the postmortem draft and shares it 24 hours before the meeting
- All participants read the draft beforehand
- Facilitator (often the IC or a dedicated postmortem facilitator) prepares questions

**During the meeting (60 minutes)**:
1. (5 min) **Set the stage**: "This is a blameless postmortem. We are here to learn, not to blame."
2. (10 min) **Walk through the timeline**: Author presents the timeline. Attendees add corrections
3. (15 min) **Root cause discussion**: Facilitate the 5 Whys or contributing factor analysis
4. (10 min) **What went well**: Celebrate what worked — do not skip this
5. (15 min) **Action items**: Review proposed action items, assign owners, set due dates. Every action item needs an owner and a date
6. (5 min) **Close**: "What is the one thing we should change to prevent this from happening again?"

**After the meeting**:
- Finalize the postmortem document
- Post to #incident-postmortems for the broader organization
- Track action items in your project tracker (Jira, Linear, etc.)
- Review action item completion in the next postmortem review cycle

### Action Item Follow-Through

The most common failure mode of the postmortem process is not writing postmortems — it is writing them and then not following through on action items.

**Tracking mechanisms**:
- Every action item becomes a ticket in the team's project tracker with a `postmortem` label
- A monthly "postmortem action item review" meeting checks completion status
- Dashboard showing % of postmortem action items completed on time
- Overdue action items are surfaced in engineering all-hands

**Target**: >80% of postmortem action items completed within 30 days of the postmortem.

---

## 7. Status Page Management

### Tool Selection (2025-2026)

| Tool | Type | Starting Price | Key Strength |
|------|------|---------------|--------------|
| **Atlassian Statuspage** | SaaS | $29/mo (Hobby) | Market leader, most integrations |
| **Instatus** | SaaS | Free tier, Pro $20/mo | Fastest load times (Jamstack), beautiful design, 30+ languages |
| **Better Stack (Uptime)** | SaaS | Free tier, paid from $29/mo | Combined monitoring + status page + incident management |
| **Cachet** | Self-hosted (OSS) | Free | Full control, self-hosted, no vendor lock-in |
| **Sorry** | SaaS | From $29/mo | Simple and focused |
| **incident.io** | SaaS | Included in plans | Integrated with incident workflow |
| **Rootly** | SaaS | Included in plans | Auto-updates from Slack incident channel |
| **OpenStatus** | Open Source | Free (self-hosted), SaaS available | Modern, open-source, community-driven |

**Selection guidance**:
- **Best design/speed**: Instatus (Jamstack architecture loads up to 10x faster than Statuspage)
- **Best integration**: Atlassian Statuspage (if you are already in the Atlassian ecosystem)
- **Best value**: Better Stack or Instatus free tier
- **Best for self-hosted**: Cachet or OpenStatus
- **Best unified experience**: incident.io or Rootly (status page updates from incident channel)

### Component-Based Status Architecture

Structure your status page around user-facing services, not internal infrastructure:

```
System Status: Operational / Degraded Performance / Partial Outage / Major Outage

Components:
  ├── Web Application          [Operational]
  ├── Mobile Application       [Operational]
  ├── API                      [Degraded Performance]
  │   ├── REST API             [Degraded Performance]
  │   └── GraphQL API          [Operational]
  ├── Authentication           [Operational]
  ├── Payments                 [Operational]
  ├── Notifications            [Partial Outage]
  │   ├── Email                [Operational]
  │   ├── SMS                  [Major Outage]
  │   └── Push                 [Operational]
  └── Data Export              [Operational]
```

**Rules for component design**:
- Group by what customers care about, not by internal service names
- Customers do not know what "kafka-cluster-prod-3" is — they know "Notifications"
- Use sub-components for granularity without overwhelming the page
- Include only components that have independent failure modes

### Incident Communication Templates

#### Investigating (First Update)

```
Title: Increased error rates on [Component]

We are investigating reports of [brief user-visible symptom].
Some users may experience [specific impact].
We are actively investigating and will provide an update within 30 minutes.
```

#### Identified (Root Cause Found)

```
Title: [Component] — Issue Identified

We have identified the cause of [brief description of the issue].
[Brief, non-technical explanation of what happened].
Our team is implementing a fix. We expect to have this resolved by [ETA if possible].
We will provide another update within [30/60] minutes.
```

#### Monitoring (Fix Applied)

```
Title: [Component] — Fix Deployed, Monitoring

We have deployed a fix for the [issue description].
We are monitoring the situation to ensure stability.
Some users may still experience [residual effects, e.g., "cached errors for a few minutes"].
We will provide a final update once we confirm full resolution.
```

#### Resolved

```
Title: [Component] — Resolved

The issue affecting [component] has been resolved.
[Brief summary of what happened and what was done].
Total duration of impact: [X hours Y minutes].
We apologize for any inconvenience. A full postmortem will be published within [48 hours / 5 business days].
```

### Internal vs External Communication

| Aspect | Internal | External |
|--------|----------|----------|
| **Audience** | Engineering, support, leadership, sales | Customers, partners, public |
| **Detail level** | Technical root cause, specific services, error codes | User-facing impact, plain language |
| **Cadence** | Every 15-30 min for SEV1, every 30-60 min for SEV2 | Every 30-60 min for SEV1/SEV2 |
| **Channel** | Slack #incidents, email to eng-all, exec briefing | Status page, Twitter/X, email to affected customers |
| **Tone** | Direct, technical, action-oriented | Empathetic, clear, reassuring |
| **What to include** | Service names, error rates, deployment versions | Impact description, ETA, what users should do |
| **What to exclude** | Nothing (within engineering) | Internal service names, blame, speculation about root cause |

### Scheduled Maintenance

**Template for scheduled maintenance notice**:
```
Title: Scheduled Maintenance — [Component]

We will be performing scheduled maintenance on [component] on [date] from [start time] to [end time] [timezone].

During this window:
- [What will be unavailable or degraded]
- [What will continue to work normally]
- [Any action required by users]

We will update this notice when maintenance begins and when it is complete.
```

**Best practices**:
- Post maintenance notices at least 72 hours in advance for major maintenance
- Post at least 24 hours in advance for minor maintenance
- Choose maintenance windows based on lowest-traffic periods (use your analytics data)
- Always update the status page when maintenance starts and completes
- If maintenance runs over the window, post an update explaining the delay

---

## 8. Incident Metrics & Analytics

### Core Metrics

#### MTTD — Mean Time to Detect

**Definition**: Time from when a problem starts affecting users to when the team is aware of it.

```
MTTD = Timestamp(alert_fired OR customer_reported) - Timestamp(issue_began)
```

| MTTD Range | Assessment | Action |
|------------|-----------|--------|
| <5 min | Excellent | Maintain current monitoring |
| 5-15 min | Good | Fine-tune alert thresholds |
| 15-30 min | Needs improvement | Add missing monitors, lower thresholds |
| >30 min | Critical gap | Review monitoring coverage, add synthetic checks |

**How to reduce MTTD**:
- SLO-based burn rate alerts catch issues faster than static thresholds
- Synthetic monitoring (canary requests) detects issues before real users are affected
- Error rate anomaly detection catches unexpected patterns
- Deploy-time health checks catch regressions immediately

#### MTTR — Mean Time to Resolve

**Definition**: Time from when the team is aware of the problem to when the service is fully restored.

```
MTTR = Timestamp(incident_resolved) - Timestamp(incident_declared)
```

Note: Some organizations split MTTR into sub-components:
- **MTTA** (Mean Time to Acknowledge): Time to respond to the page
- **MTTM** (Mean Time to Mitigate): Time to stop user impact (even if root cause is not fixed)
- **MTTR** (Mean Time to Resolve): Time to fully resolve including root cause fix

| MTTR Range (SEV1) | Assessment | Action |
|--------------------|-----------|--------|
| <30 min | Excellent | Document what made this fast |
| 30-60 min | Good | Look for automation opportunities |
| 1-4 hours | Average | Invest in runbooks and training |
| >4 hours | Needs improvement | Review escalation process, tooling, and knowledge gaps |

**How to reduce MTTR**:
- Runbooks with copy-pasteable commands for common failures
- Automated rollback capabilities
- Feature flags for instant disable without deployment
- Pre-built dashboards for faster diagnosis
- Regular incident response practice (tabletop exercises)

#### MTBF — Mean Time Between Failures

**Definition**: Average time between incidents (measured per service or globally).

```
MTBF = Total_Operational_Time / Number_of_Incidents
```

| MTBF | Assessment |
|------|-----------|
| >30 days | Healthy service |
| 7-30 days | Needs attention |
| <7 days | Reliability crisis — stop feature work and focus on stability |

### Advanced Metrics

| Metric | Definition | Target |
|--------|-----------|--------|
| **Incident frequency by severity** | Count of incidents per severity per month | SEV1: <1/mo, SEV2: <4/mo |
| **Recurring incident rate** | % of incidents that are repeat occurrences | <15% |
| **Postmortem completion rate** | % of SEV1/SEV2 incidents with completed postmortems | >95% |
| **Action item completion rate** | % of postmortem AIs completed on time | >80% |
| **Customer-reported incident rate** | % of incidents first reported by customers | <20% |
| **Escalation rate** | % of incidents that required escalation beyond primary | <15% |
| **False positive rate** | % of alerts that did not correspond to real issues | <20% |
| **On-call page volume** | Pages per on-call shift | <10/week |
| **After-hours page rate** | % of pages outside business hours | Track trend |
| **SLO error budget remaining** | How much error budget has been consumed | >25% at any point |

### Recurring Incident Tracking

**What to track**:
- Incidents with the same root cause or contributing factors
- Alerts that fire for the same reason within 30 days
- Postmortem action items that, if completed, would have prevented subsequent incidents

**Process**:
1. Tag every incident with a category (deployment, infrastructure, dependency, configuration, capacity, security)
2. Monthly review: group incidents by category and service
3. If the same service has 3+ incidents in a month, trigger a reliability review
4. If the same root cause recurs after a postmortem, escalate — the action items are not working

### Leadership Reporting

**Weekly incident report** (for engineering leadership):
```
Week of [Date]:
- Total incidents: X (SEV1: Y, SEV2: Z)
- MTTR (SEV1 avg): X hours
- MTTR (SEV2 avg): X hours
- Notable incidents: [Brief summaries]
- Trends: [Up/down from last week, contributing factors]
- Open postmortem action items: X (Y overdue)
```

**Monthly reliability report** (for VP/C-level):
```
Month of [Date]:
- SLO status: [X of Y SLOs met]
- Error budget: [X% remaining for the quarter]
- Incident trend: [Chart showing incidents over time]
- MTTR trend: [Chart showing MTTR over time]
- Top 3 reliability risks: [Brief descriptions]
- Top 3 completed reliability improvements: [Brief descriptions]
- Headcount/investment needs: [If any]
```

### SLO Impact Tracking

Every SEV1/SEV2 incident should be mapped to the SLOs it affected:

```
Incident INC-2024-0147:
  - SLO: API Availability (99.95% target)
    - Budget consumed: 0.8% of quarterly budget
    - Remaining budget: 23.2%
  - SLO: API Latency p99 < 500ms (99.9% target)
    - Budget consumed: 1.2% of quarterly budget
    - Remaining budget: 15.1%
```

This directly ties incident impact to business outcomes and helps prioritize reliability investments.

---

## 9. Tabletop Exercises & Simulations

### Planning Game Days

**Game day**: A live exercise where real failures are injected into production (or staging) systems and the team responds as if it were a real incident.

**Tabletop exercise**: A discussion-based exercise where a scenario is presented on paper and the team talks through their response without touching any systems.

| Aspect | Tabletop | Game Day |
|--------|----------|----------|
| Risk level | None (discussion only) | Low-moderate (real system changes) |
| Preparation time | 2-4 hours | 1-2 weeks |
| Duration | 60-90 minutes | 2-4 hours |
| Participants | 5-15 people | 3-8 responders + 2-3 observers |
| Environment | Conference room / Zoom | Staging or production |
| Cost | Time only | Time + potential staging environment cost |
| Frequency | Monthly or quarterly | Quarterly or bi-annually |
| Best for | Process validation, new team members, cross-team coordination | Technical readiness, tooling validation, confidence building |

### Scenario Design

#### Scenario Template

```markdown
# Tabletop Exercise: [Scenario Name]

## Metadata
- **Difficulty**: [Easy / Medium / Hard]
- **Duration**: [60 / 90 / 120 minutes]
- **Target Audience**: [On-call engineers / ICs / Full incident team]
- **Services Tested**: [List of services involved]
- **Skills Tested**: [Detection, triage, communication, escalation, rollback, etc.]

## Scenario Setup
[Background information participants need before the exercise begins]

## Inject 1 (T+0 minutes): The Alert
[Initial alert or symptom. Include realistic alert text, dashboard screenshots if available]

**Facilitator prompt**: "You are the on-call engineer. It is 2:00 AM on a Tuesday.
Your phone wakes you up with this alert. What do you do first?"

## Inject 2 (T+10 minutes): Escalation
[Additional information or worsening conditions]

**Facilitator prompt**: "The error rate is now at 25% and climbing.
Customer support reports 50 tickets in the last 10 minutes. What is your next step?"

## Inject 3 (T+20 minutes): Complexity
[A complication — dependency failure, wrong diagnosis, simultaneous issue]

**Facilitator prompt**: "The deployment rollback did not fix the issue.
You discover that the database replica is 15 minutes behind the primary. What now?"

## Inject 4 (T+30 minutes): Resolution Path
[Clues or options that lead to resolution]

**Facilitator prompt**: "A senior engineer notices that the connection pool
configuration was changed in a config management PR merged 3 hours ago. How do you proceed?"

## Expected Outcomes
- [ ] Incident declared within 5 minutes of first inject
- [ ] IC assigned and war room opened
- [ ] Correct severity assessed
- [ ] Stakeholder communication initiated
- [ ] Escalation path followed correctly
- [ ] Root cause identified
- [ ] Mitigation applied

## Debrief Questions
1. What was the first thing you did, and why?
2. At what point did you decide to escalate? Was that the right time?
3. How did you communicate with stakeholders?
4. What information did you wish you had sooner?
5. What would you do differently next time?
```

#### Sample Scenarios by Category

**Region Failure**:
- AWS us-east-1 partial AZ outage
- DNS provider (Route 53 / Cloudflare) returning errors
- CDN origin pull failures in EU region
- Cross-region database replication lag exceeds 30 seconds

**Database Corruption**:
- Primary database returns corrupt reads for a specific table
- Failed migration leaves schema in inconsistent state
- Point-in-time recovery needed for accidental data deletion
- Connection pool exhaustion due to connection leak

**Security Breach**:
- Leaked API credentials on GitHub
- Suspicious admin API calls from unknown IP
- Customer reports seeing another customer's data
- Ransomware notification on infrastructure host

**Dependency Outage**:
- Payment processor (Stripe/Adyen) returns 503 for all requests
- Email delivery provider (SendGrid/SES) is down
- Authentication provider (Auth0/Okta) is unreachable
- Third-party API rate limiting triggered

**Cascade Failure**:
- One service failure causes retry storms in dependent services
- Circuit breaker not configured, resulting in cascading timeouts
- Memory leak during high traffic causes progressive pod evictions
- Cache failure causes thundering herd to database

### Facilitation Guide

**Before the exercise**:
1. Select the scenario and customize it for your environment
2. Identify the facilitator (Game Master) and observers
3. Brief observers on what to look for (communication patterns, decision-making speed, role adherence)
4. Set up the room (or video call) with dashboards, architecture diagrams
5. Prepare printed copies of injects (do not reveal them in advance)

**During the exercise**:
1. Set expectations: "This is a safe space to practice. There are no wrong answers. We are here to learn."
2. Present injects at the planned intervals
3. Stay in character — if participants ask "is this real?", remind them to treat it as real
4. Observe and take notes, but do not coach during the exercise unless participants are completely stuck
5. If the exercise stalls for >5 minutes, provide a hint

**After the exercise (debrief, 30 minutes)**:
1. "How did that feel?" — Let participants decompress
2. Walk through the debrief questions
3. Observers share their notes (what went well, what did not)
4. Identify 3-5 specific action items
5. Schedule the next exercise

### Evaluating Team Response

Score each dimension on a 1-5 scale:

| Dimension | 1 (Poor) | 3 (Adequate) | 5 (Excellent) |
|-----------|----------|--------------|----------------|
| **Detection speed** | Missed the alert | Responded within 15 min | Responded within 5 min |
| **Severity assessment** | Wrong severity | Correct but slow | Correct and fast |
| **Role assignment** | No IC, chaotic response | IC assigned late | IC assigned immediately, clear roles |
| **Communication** | No updates, stakeholders in the dark | Sporadic updates | Regular cadence, clear updates |
| **Technical diagnosis** | Wrong root cause identified | Correct but slow | Systematic, efficient diagnosis |
| **Mitigation** | No mitigation applied | Mitigation applied late | Fast mitigation, user impact minimized |
| **Escalation** | No escalation when needed | Escalation but delayed | Timely, appropriate escalation |
| **Documentation** | No timeline kept | Partial timeline | Complete timeline with decisions |

### Frequency and Scheduling

| Exercise Type | Frequency | Duration | Participants |
|--------------|-----------|----------|-------------|
| Alert response drill | Monthly | 15-30 min | Individual on-call engineers |
| Tabletop exercise | Monthly or quarterly | 60-90 min | 5-15 team members |
| Game day (staging) | Quarterly | 2-4 hours | 3-8 responders + observers |
| Game day (production) | Bi-annually | 2-4 hours | Full incident team |
| Cross-team exercise | Bi-annually | 90-120 min | Representatives from multiple teams |
| Executive tabletop | Annually | 60 min | Engineering leadership + communications |

---

## 10. Communication During Incidents

### Internal Communication Matrix

| Audience | Channel | When | What |
|----------|---------|------|------|
| Responding engineers | Slack incident channel | Immediately | Technical details, actions, updates |
| Engineering leadership | Slack #eng-incidents or direct message | SEV1: within 15 min, SEV2: within 30 min | Summary, impact, ETA, help needed |
| VP/CTO | Slack DM or phone call | SEV1 only, within 15 min | 2-sentence summary, expected resolution time |
| Customer Support | Slack #support-incidents or dedicated channel | SEV1/2: within 15 min | User-facing impact, talking points for customers, ETA |
| Sales / Account Management | Email or Slack | SEV1 affecting named accounts | Customer-specific impact, talking points |
| Entire engineering org | Slack #incidents feed (automated) | All incidents | Automated incident notifications from tooling |

### Internal Communication Templates

#### SEV1 — Executive Notification

```
INCIDENT: [Service] is experiencing [brief description]

Impact: [X]% of users are affected. [Revenue/Core function] is impacted.
Current status: [Investigating / Identified / Mitigating]
IC: [Name]
Channel: #inc-YYYY-NNNN
Next update: [Time]

No action needed from you at this time. I will provide updates every 30 minutes.
```

#### SEV1/2 — Support Team Briefing

```
INCIDENT NOTIFICATION — [Severity]

What is happening: [User-visible description in plain language]
Who is affected: [All users / Region / Specific feature users]
Workaround: [If any, describe what customers can do]
What to tell customers: "[Draft response for support tickets]"
ETA: [If known, otherwise "We are investigating and will update within 30 minutes"]
Status page: [Link]

DO NOT share: internal service names, root cause speculation, or timeline details.
```

#### SEV2 — Engineering Leadership Update

```
INCIDENT UPDATE — SEV2 — [Service]

Impact: [Brief impact description]
Started: [Time]
Duration so far: [X minutes/hours]
Root cause: [Identified / Under investigation]
Current mitigation: [What is being done]
Next step: [What we are trying next]
Help needed: [None / Specific expertise]
Next update: [Time]
```

### External Communication Guidelines

**Principles**:
1. **Be transparent but not reckless** — Share what you know, do not speculate
2. **Focus on impact, not internals** — Customers care about what is broken, not which pod crashed
3. **Give an ETA only if confident** — "We are working to resolve this as quickly as possible" is better than a missed ETA
4. **Apologize genuinely** — "We apologize for the impact to your operations" not "We are sorry for any inconvenience"
5. **Do not assign blame externally** — Even if a third-party vendor caused it, your customers signed up for your service

**What to communicate externally**:
- What is affected (in user-facing terms)
- What the impact looks like for users
- What they should do (workaround, wait, contact support)
- When you will next update

**What to NEVER communicate externally**:
- Internal service or infrastructure names
- Specific vendor names (unless they have their own public status page update)
- Root cause speculation before confirmed
- Individual engineer names
- Unverified timelines for resolution

### External Communication Templates by Severity

#### SEV1 — Major Outage (Status Page + Customer Email)

**Status page**:
```
Title: Major Outage — [Feature/Service]

We are experiencing a major outage affecting [feature/service].
Users may be unable to [specific action, e.g., "log in", "process payments", "access their data"].
Our engineering team is actively working to resolve this issue.
We will provide updates every 30 minutes.
We apologize for the disruption.
```

**Customer email (for affected enterprise accounts)**:
```
Subject: [Urgent] Service Disruption — [Your Product Name]

Dear [Customer],

We are writing to inform you of a service disruption affecting [Your Product Name].

What is happening: [Brief, plain-language description of the issue]
Impact to you: [Specific impact to this customer, if known]
What we are doing: Our engineering team has been engaged since [time] and is
actively working to restore full service.
Workaround: [If any]

We will send an update within [30 minutes / 1 hour] with the latest status.

We understand this impacts your operations and sincerely apologize. If you
have urgent questions, please contact your account manager at [email] or our
support team at [support email].

[Name], [Title]
[Company]
```

#### SEV2 — Degraded Service

**Status page**:
```
Title: Degraded Performance — [Feature/Service]

Some users may experience [slow response times / intermittent errors / degraded functionality]
when using [feature].
Our team is investigating. Core functionality remains available.
We will update this notice within 60 minutes.
```

### Bridge/War Room Etiquette

**Do**:
- Keep the main channel for actionable updates and decisions
- Use threads for extended technical discussions
- Prefix messages with your role: "[IC]:", "[Tech Lead]:", "[Comms]:"
- Post periodic status summaries even if nothing has changed ("No new information. We are still investigating [X]. Next check-in in 15 minutes.")
- Mute non-essential notifications during the incident

**Do Not**:
- Ask "What is happening?" if you just joined — read the pinned summary and scrollback first
- Share theories without evidence in the main channel — use a thread
- Page or @-mention people who are not in the incident unless you need them
- Post screenshots without context
- Argue about severity in the middle of response — the IC decides, revisit in the postmortem
- Send messages that are not actionable ("This is bad", "Yikes", "Is it fixed yet?")

### Post-Incident Customer Communication

**Within 24 hours of resolution** (for SEV1):
```
Subject: Resolved — [Issue Summary] on [Date]

Dear [Customer],

The service disruption affecting [feature/service] on [date] has been fully resolved.

Summary:
- Duration: [Start time] to [End time] ([X hours Y minutes])
- Impact: [What users experienced]
- Resolution: [Brief, non-technical description of how it was fixed]

We take the reliability of our service seriously. We are conducting a thorough
review of this incident and implementing changes to prevent recurrence.

A detailed incident report will be available within [5 business days] at [link / upon request].

We apologize for the disruption to your operations. If you have any questions
or experienced residual issues, please contact your account manager or our
support team at [email].

[Name], [Title]
[Company]
```

**Published postmortem summary (for customers, 3-5 business days post-incident)**:

```
Subject: Incident Report — [Issue Summary] on [Date]

Summary: [2-3 sentences describing what happened in non-technical language]

Timeline:
- [Start time]: Issue began
- [Detection time]: Our systems detected the issue
- [Key milestones]: Actions taken
- [Resolution time]: Service fully restored

Root Cause: [Non-technical description of what caused the issue]

Preventive Measures:
- [Action 1: What you are doing to prevent this from happening again]
- [Action 2]
- [Action 3]

We are committed to earning your trust through reliable service.
Thank you for your patience.
```

---

## Appendix A: On-Call Rotation Setup Guide

### Step-by-Step Setup

1. **Define your rotation model** (Section 3)
   - Choose weekly, daily, follow-the-sun, or hybrid based on team size and alert volume

2. **Determine team roster**
   - Minimum 4 engineers for a sustainable weekly rotation (1 in 4 weeks)
   - Minimum 6 engineers for a healthy weekly rotation (1 in 6 weeks, recommended)
   - For follow-the-sun, minimum 3 engineers per region

3. **Set up the on-call tool**
   - Configure rotation schedule in PagerDuty / incident.io / Rootly / Squadcast
   - Set up escalation policy: Primary (5 min) -> Secondary (5 min) -> Manager (10 min)
   - Configure notification channels: push notification, then SMS, then phone call

4. **Connect to monitoring**
   - Route alerts from your monitoring tool (Datadog, Grafana, etc.) to the on-call tool
   - Map alert severity to notification urgency (SEV1 = high urgency always, SEV3/4 = low urgency off-hours)

5. **Configure Slack/Teams integration**
   - Auto-create incident channels on incident declaration
   - Post on-call schedule changes to team channel
   - Enable slash commands for incident management (`/incident`, `/page`, `/escalate`)

6. **Write initial runbooks** (Section 5)
   - Start with the top 5 most common alerts
   - Link each alert to its runbook via `runbook_url` annotation

7. **Run a shadow rotation** (Section 3)
   - New on-call engineers shadow for 2-4 weeks before taking primary

8. **Set up on-call review**
   - Weekly handoff meeting (15 min) during rotation change
   - Monthly on-call health review (pages per shift, false positives, etc.)

---

## Appendix B: Tabletop Exercise Scenario — Complete Example

### Scenario: Payment Processing Outage

**Difficulty**: Hard
**Duration**: 90 minutes
**Target Audience**: Full incident response team
**Services Tested**: Payment service, order service, notification service
**Skills Tested**: Detection, cross-team coordination, vendor escalation, customer communication

**Setup**: It is a regular Wednesday. Black Friday sales event starts in 48 hours. The team is wrapping up final preparations.

**Inject 1 (T+0)**: PagerDuty alert fires: "Payment Service error rate > 5% — currently at 8%". The Datadog dashboard shows a spike in 500 errors on the `/v1/payments/charge` endpoint starting 3 minutes ago.

*Facilitator questions: What is your first action? What dashboards do you check?*

**Inject 2 (T+10)**: Error rate climbs to 15%. Customer support Slack channel has 12 new tickets reporting "Payment failed" errors. Your payment processor (Stripe) status page shows "All Systems Operational."

*Facilitator questions: What severity do you assign? Who do you notify? Do you update the status page?*

**Inject 3 (T+20)**: A junior engineer discovers that a configuration change merged this morning switched the Stripe API from `2024-12-01` to `2025-01-15`. The new API version has a breaking change in the `payment_method` field format. However, rolling back the config takes 15 minutes and requires a production deployment.

*Facilitator questions: Do you roll back? What is your mitigation strategy while the rollback deploys? How do you communicate the 15-minute ETA?*

**Inject 4 (T+35)**: During the rollback, the deployment pipeline fails because another engineer merged a broken CI config. The payment error rate is now at 30%.

*Facilitator questions: How do you handle the blocked deployment? Do you escalate? What do you tell customers and leadership?*

**Inject 5 (T+50)**: A platform engineer manually forces the rollback through an emergency deploy path. The error rate starts dropping within 2 minutes.

*Facilitator questions: When do you declare the incident resolved? What monitoring do you put in place? What is the first postmortem action item you can identify?*

**Debrief (T+60-90)**:
1. Was the severity assigned correctly at each stage?
2. How quickly was the IC identified and war room established?
3. Was customer communication timely and accurate?
4. How did the team handle the deployment pipeline failure (the surprise complication)?
5. With Black Friday in 48 hours, what actions would you take before the sales event?

---

## Appendix C: Quick Reference — Incident Severity Cheat Sheet

```
SEV1 — CRITICAL
  Trigger: >50% users down, revenue loss, data loss, security breach
  Response: All-hands, IC required, exec notification in 15 min
  Updates: Every 15-30 min (status page + internal)
  Postmortem: Required within 3 business days

SEV2 — HIGH
  Trigger: 10-50% users affected, critical feature degraded, SLO breach rate 10x
  Response: Dedicated team, IC assigned, leadership notified in 30 min
  Updates: Every 30-60 min (status page + internal)
  Postmortem: Required within 5 business days

SEV3 — MODERATE
  Trigger: <10% users affected, non-critical feature broken, elevated error rate
  Response: On-call handles during business hours, team lead aware
  Updates: Status page if customer-visible, internal as needed
  Postmortem: Optional, at team discretion

SEV4 — LOW
  Trigger: Cosmetic issues, edge cases, minor bugs
  Response: Ticket created, addressed in next sprint
  Updates: None
  Postmortem: Not required
```

---

## Appendix D: Tool Integration Quick Start Commands

### PagerDuty CLI

```bash
# Install PagerDuty CLI
brew install pagerduty/homebrew-pd/pd

# Trigger an incident
pd incident:create --title "API latency elevated" --service-id P123ABC --urgency high

# Acknowledge an incident
pd incident:ack --id P456DEF

# Resolve an incident
pd incident:resolve --id P456DEF

# List on-call for a schedule
pd oncall:list --schedule-id SCHED123
```

### incident.io CLI / API

```bash
# Create an incident via API
curl -X POST https://api.incident.io/v2/incidents \
  -H "Authorization: Bearer $INCIDENT_IO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "API latency elevated",
    "severity_id": "sev2",
    "idempotency_key": "unique-key-123"
  }'
```

### Slack Incident Commands (common across tools)

```
/incident new "API latency elevated" severity=sev2
/incident update "Root cause identified — rolling back deployment"
/incident resolve "Rollback complete, service restored"
/page @oncall-backend "Need help diagnosing database connection issue"
```

### Statuspage CLI (Atlassian)

```bash
# Create an incident on Statuspage
curl -X POST https://api.statuspage.io/v1/pages/$PAGE_ID/incidents \
  -H "Authorization: OAuth $STATUSPAGE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "incident": {
      "name": "Elevated API error rates",
      "status": "investigating",
      "impact_override": "minor",
      "body": "We are investigating elevated error rates on the API.",
      "component_ids": ["comp123"],
      "components": {"comp123": "degraded_performance"}
    }
  }'
```
