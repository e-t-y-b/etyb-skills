---
title: Strands Agents SDK
description: AWS-blessed open-source agent authoring SDK — Apache 2.0, agent loop + tool use + planning built in. Pairs with AgentCore Runtime for production deployment.
product:
  name: Strands Agents SDK
  stack: aws
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect]
  authoritative_url: https://strandsagents.com/
  notes: "Open-sourced May 2025; API stabilizing; integration with AgentCore Runtime + Bedrock evolving release-over-release."
---

## What it is

Strands Agents is AWS's blessed open-source agent authoring SDK — Apache 2.0 licensed, agent-loop + tool-use + planning built in, multi-model-provider support (Bedrock first, also Anthropic API direct, OpenAI, others). Pairs with [AgentCore Runtime](/stacks/aws/agentcore/) for production deployment.

Canonical surface: [strandsagents.com](https://strandsagents.com/).

## When to use

| Need | Use Strands? |
|---|---|
| Production agent on AWS — tool use, planning, agent loop | Yes — Strands + AgentCore Runtime |
| Local prototyping of an agent before deploy | Yes — Strands locally, deploy when ready |
| Tightly integrated with [Bedrock](/stacks/aws/bedrock/) | Yes — Bedrock model provider first-class |
| LangChain/LangGraph already in production | Either works — Strands is the AWS-native + tighter Bedrock + AgentCore integration |
| Simple LLM call with no agent loop | No — call Bedrock Converse directly |

## 2025-2026 currency anchors

- **Strands Agents SDK** was open-sourced **May 2025** — Apache 2.0, community + AWS development.
- **Multi-model providers** — Bedrock primary, Anthropic API direct, OpenAI, others.
- **Streaming** — `agent.stream(prompt)` for token-by-token output.
- **Memory** — short-term (in-session) built-in; long-term integrates with [AgentCore Memory](/stacks/aws/agentcore/).
- **Pairs with AgentCore Runtime** for production execution.

## Patterns

### Basic agent

```python
from strands import Agent, tool
from strands.models.bedrock import BedrockModel

@tool
def get_order_status(order_id: str) -> dict:
    """Get the current status of an order by ID."""
    return {'order_id': order_id, 'status': 'shipped', 'tracking': '1Z999...'}

@tool
def refund_order(order_id: str, reason: str) -> dict:
    """Initiate a refund for an order with the given reason."""
    return {'order_id': order_id, 'refund_id': 'r-456', 'amount': 49.99}

model = BedrockModel(
    model_id='anthropic.claude-sonnet-4-7-20251015-v1:0',
    region_name='us-east-2',
    temperature=0.0,
    max_tokens=4096,
)

agent = Agent(
    model=model,
    tools=[get_order_status, refund_order],
    system_prompt=(
        "You are a customer service agent. Help users check order status and process refunds. "
        "Confirm refund requests before processing. Use only the tools provided."
    ),
)

response = agent("My order ABC-123 hasn't arrived. Can I get a refund?")
print(response.message)
```

Key properties:
- **`@tool` decorator** — functions with type hints become tools the agent can call.
- **Agent loop built-in** — `agent(prompt)` runs reasoning → tool call → result → next reasoning until done.
- **Multiple model providers** — Bedrock first for AWS-native; Anthropic direct or OpenAI as alternatives.
- **Streaming** via `agent.stream(prompt)`.

### Production deployment

Local development with Strands → deploy to [AgentCore Runtime](/stacks/aws/agentcore/). AgentCore handles:
- Isolated session execution.
- Built-in observability ([CloudWatch](/stacks/aws/cloudwatch/) + [X-Ray](/stacks/aws/x-ray/)).
- Guardrail integration ([Bedrock Guardrails](/stacks/aws/bedrock/)).
- Memory integration (AgentCore Memory).
- IAM-based access control per session.
- Auto-scaling for concurrent sessions.

### Tool design

- **Type hints are the contract** — Strands generates JSON schemas from Python signatures.
- **Docstrings describe behavior** — the LLM reads them to decide when to call.
- **Return JSON-serializable** — dicts, lists, primitives. Complex objects need explicit serialization.
- **Idempotent when possible** — agent may retry on transient errors.

### Eval-driven development

Before deploying a prompt or tool change:
1. Run against an eval set (50-200 examples).
2. Score with a programmatic eval (regex, structured output check, LLM-as-judge).
3. Compare deltas vs baseline.

Regression tests on agent flows: replay past sessions through the new agent; assert tool-use shape + output quality didn't regress.

## Anti-patterns

- **Free-form tool descriptions instead of typed schemas.** Typed tools beat free-form prompts.
- **Stateful tools without idempotency.** Retries duplicate side effects.
- **Long-running tools** in the agent loop. Push to async; have the agent poll.
- **Model ID pinned to `latest`** in production. Pin to exact version (`anthropic.claude-sonnet-4-7-20251015-v1:0`).
- **No guardrail integration** in production. Always pair with Bedrock Guardrails.
- **Prompts edited in production console.** Version control prompts.
- **No eval set in repo.** Every prompt change PR should run the eval.

## Gotchas

- **Strands is open-source + young** — API is stabilizing; pin SDK versions.
- **Tool functions execute in agent process** — not isolated; security implications for tool inputs.
- **Bedrock model ID format** — `anthropic.claude-sonnet-4-7-20251015-v1:0` vs `us.anthropic.claude-sonnet-4-7-20251015-v1:0` for cross-region inference.
- **`temperature=0.0`** for deterministic tool selection; bump for creative tasks.
- **`max_tokens`** caps output; agent loops can hit this if not sized for full responses.

## Cross-references

- [`/stacks/aws/agentcore/`](/stacks/aws/agentcore/) — production deployment target
- [`/stacks/aws/bedrock/`](/stacks/aws/bedrock/) — model provider
- [`/stacks/aws/ai-ml-engineer/`](/stacks/aws/ai-ml-engineer/) — role view; agent design
- [Strands docs](https://strandsagents.com/)
