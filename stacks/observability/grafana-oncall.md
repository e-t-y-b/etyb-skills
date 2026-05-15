---
title: Grafana OnCall + IRM
description: Grafana's paging + incident response surface — schedules, escalation, incident orchestration. PagerDuty alternative.
product:
  name: Grafana OnCall + IRM
  stack: observability
  drift_risk: medium
  last_verified_on: "2026-05-14"
  applies_to_roles: [sre-engineer, devops-engineer]
  authoritative_url: https://grafana.com/docs/oncall/
  notes: "OnCall + IRM consolidating; still maturing vs PagerDuty + incident.io as of 2026."
---

## What it is

**Grafana OnCall** — schedules + escalation policies + paging routes. The PagerDuty-equivalent surface.
**Grafana IRM (Incident Response Management)** — structured incident response on top of OnCall: incident commander assignment, Slack channel auto-creation, postmortem templates.

See [grafana.com/docs/oncall](https://grafana.com/docs/oncall/) and [grafana.com/docs/grafana-cloud/incident](https://grafana.com/docs/grafana-cloud/incident/).

## When to use

Pick Grafana OnCall + IRM when:
- You're in the Grafana ecosystem and want bundled paging.
- Cost-sensitive — Grafana OnCall is cheaper than PagerDuty at scale.

Pick PagerDuty + incident.io / FireHydrant / Rootly when:
- Maximum maturity matters — PagerDuty is the gold standard for paging.
- Cross-platform integration matters — PagerDuty's integrations are broader.

## 2025-2026 currency anchors

- **OnCall + IRM consolidating** into one product line.
- **Still maturing** vs PagerDuty + incident.io for full IR lifecycle.

## Patterns

- **Schedules via Terraform** — `grafana_oncall_schedule`.
- **Escalation policies** by team, severity, time-of-day.
- **Connect to [Grafana Alerting](/stacks/observability/grafana-alerting/)** as the alert source.

## Anti-patterns

- **No on-call rotation** — single-person paging guarantees burnout.
- **No runbooks linked from alerts** — first responder loses 5+ minutes.
- **No quarterly alert audit** — noise accumulates.

## Gotchas

- **IRM features lag PagerDuty Incident Response + incident.io** as of 2026.
- **Mobile app maturity** is behind PagerDuty.

## Cross-references

- Grafana Alerting (the alert source) → [grafana-alerting](/stacks/observability/grafana-alerting/)
- Incident response patterns → [sre-engineer overlay](/stacks/observability/sre-engineer/)
- Authoritative: [grafana.com/docs/oncall](https://grafana.com/docs/oncall/)
