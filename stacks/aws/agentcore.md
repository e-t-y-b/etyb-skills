---
title: AgentCore
description: Production agent layer on Bedrock — Runtime (isolated session execution), Browser (managed web tool), Memory (long-term agent memory). GA'd through 2025-2026.
product:
  name: AgentCore
  stack: aws
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, system-architect]
  authoritative_url: https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/
  notes: "Runtime/Browser/Memory GA'd through 2025-2026; SDKs evolving release-over-release; AgentCore is the new path, not legacy Bedrock Agents."
---

## What it is

Bedrock **AgentCore** is the production agent layer on AWS — managed runtime, browser tool, and memory for agentic workloads. AgentCore Runtime gives you isolated, ephemeral, secure session execution; AgentCore Browser is a managed web interaction tool; AgentCore Memory is long-term + short-term memory for agents.

This is the **new path** for production agentic workloads — **not** the older "Bedrock Agents" feature.

Canonical surface: [docs.aws.amazon.com/bedrock-agentcore](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/).

## When to use

| Pattern | Use AgentCore? |
|---|---|
| Production agent — LLM decides which tool to call, in what order | **Yes** — AgentCore Runtime + [Strands Agents SDK](/stacks/aws/strands-agents/) |
| Conversational interface with memory + tools + RAG | Yes — Runtime + Memory + Knowledge Bases |
| Deterministic workflow with occasional LLM call | No — use [Step Functions + Lambda + Bedrock InvokeModel](/stacks/aws/step-functions/) |
| Local prototyping | Strands locally; deploy to AgentCore Runtime when production |

Most "agent" requirements are actually workflows with an LLM call inside. Promote to true agent only when LLM-decided control flow adds value.

## 2025-2026 currency anchors

- **AgentCore Runtime** — production execution environment for agents with isolated, ephemeral, secure sessions. Replaces "deploy your own agent on Lambda + custom orchestration."
- **AgentCore Browser** — managed browser tool (fill forms, click, scrape, screenshot, accessibility tree). Replaces hand-rolled Playwright orchestration.
- **AgentCore Memory** — managed long-term + short-term memory with hooks for retention/forgetting policies.
- Additional AgentCore components shipped through 2025 (Tools, Gateway, etc.) — **verify current state against the AgentCore docs.**
- **Pairs with [Strands Agents SDK](/stacks/aws/strands-agents/)** for the authoring side.

## Patterns

### Deploying to AgentCore Runtime

```python
# After developing locally with Strands, deploy to AgentCore Runtime
# Pseudo-flow — verify exact AgentCore SDK against latest docs

from agentcore import Runtime, RuntimeConfig

runtime = Runtime(
    name='customer-service-agent',
    config=RuntimeConfig(
        max_session_duration='1h',
        memory_backend='agentcore-memory',
        guardrail_id='gr-xxxxx',
        observability='cloudwatch',
    ),
)

runtime.deploy(agent_module='customer_service.agent')
```

What AgentCore Runtime gives you:
- **Isolated session execution** — each session in its own ephemeral environment, no cross-session data leak.
- **Built-in observability** — sessions surfaced in [CloudWatch](/stacks/aws/cloudwatch/) + [X-Ray](/stacks/aws/x-ray/).
- **Guardrail integration** — every model call evaluated against [Bedrock Guardrails](/stacks/aws/bedrock/).
- **Memory integration** — long-term memory via AgentCore Memory.
- **IAM-based access control** — each session runs with a scoped role.
- **Auto-scaling** — handles concurrent sessions without you sizing infrastructure.

### AgentCore Browser

For agents that need to interact with web pages:

```python
from agentcore.browser import Browser

browser = Browser()
page = browser.navigate('https://example.com/order/lookup')
page.fill('input[name="orderId"]', 'ABC-123')
page.click('button[type="submit"]')
result = page.read('selector .status')
```

vs hand-rolling Playwright + headless Chrome + screenshot capture. AgentCore Browser handles session isolation, screenshot + accessibility tree extraction for LLM context, and audit logging of actions.

### AgentCore Memory

Long-term memory for agents — preferences, history, derived facts:

```python
from agentcore.memory import Memory

memory = Memory(memory_id='user-123-prefs')
memory.put('preferred_language', 'en')
memory.put('past_orders', [...])

# In a new session
prefs = memory.get('preferred_language')
```

Patterns:
- **User-scoped memory** — persists across sessions for a single user.
- **Session-scoped memory** — only within a single session.
- **Org-scoped memory** — shared facts across users (FAQs, company policy).

Retention policies — forget after N days, on user request (GDPR right-to-be-forgotten), or never. Set explicitly.

### Composing with Knowledge Bases + Guardrails

```
[User → AgentCore Runtime session]
   ↓
[Strands Agent loops]
   ↓
[Tool calls — DB lookups, Knowledge Base queries, Browser actions]
   ↓
[Bedrock Converse + Guardrails on each invocation]
   ↓
[AgentCore Memory writes for cross-session continuity]
```

## Anti-patterns

- **Custom Lambda-based agent orchestration** when AgentCore fits.
- **Old Bedrock Agents for new builds.** AgentCore is the new path.
- **Hand-rolled Playwright on EC2** for browser-tool agents. Use AgentCore Browser.
- **Cross-session memory in DynamoDB by hand** when AgentCore Memory has retention + scoping primitives built in.
- **No guardrail on AgentCore Runtime config.** Always attach.
- **Long-lived memory without retention policy.** GDPR / privacy time bomb.

## Gotchas

- **AgentCore is a 2025-2026 surface** — SDKs and IAM shape are still evolving release-over-release. Pin SDK versions; verify against current docs.
- **Per-session isolation cost** — ephemeral environments have a per-session overhead. Aggregate sessions for cost efficiency where business semantics allow.
- **AgentCore Memory is not a substitute for proper data tier** — it's optimized for agent context, not as primary application storage.
- **Browser tool rate-limits / CAPTCHA** behavior varies by site; verify against your target sites.
- **AgentCore region availability** — verify before designing.

## Cross-references

- [`/stacks/aws/strands-agents/`](/stacks/aws/strands-agents/) — agent authoring SDK
- [`/stacks/aws/bedrock/`](/stacks/aws/bedrock/) — model gateway underneath
- [`/stacks/aws/ai-ml-engineer/`](/stacks/aws/ai-ml-engineer/) — role view; agent vs workflow decision
- [`/stacks/aws/cloudwatch/`](/stacks/aws/cloudwatch/) — session observability
- [AgentCore Developer Guide](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/)
