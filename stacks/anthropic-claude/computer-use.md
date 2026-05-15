---
title: Computer Use
description: Claude drives a real screen — takes screenshots, moves the mouse, clicks, types. Beta in Oct 2024; production-grade by 2025-2026. Sandboxed VM required; tool version is tied to model version.
product:
  name: Computer Use
  stack: anthropic-claude
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, system-architect, security-engineer]
  authoritative_url: https://docs.anthropic.com/en/docs/agents-and-tools/computer-use
  notes: "Tool versions tied to model versions (computer_20250124, computer_20251022...); sandboxed VM mandatory."
---

## What it is

Computer Use lets Claude drive a real screen — emit `screenshot`, `key`, `type`, `mouse_move`, `left_click`, `right_click` actions; your harness executes them on a sandboxed VM and returns the resulting screenshot; the loop continues. Released as beta Oct 2024; matured through 2025-2026.

You enable Computer Use by including the `computer_<date>` tool in the `tools` array. The tool version is dated and **tied to model version** — `computer_20250124` does not work with a 2026-vintage model; `computer_20251022` doesn't work with an early-2025 model. Mismatches throw an API error. See [Computer Use Guide](https://docs.anthropic.com/en/docs/agents-and-tools/computer-use).

## When to use

Computer Use is right for:

- **Legacy GUI automation** — interacting with software that has no API and no accessible automation surface (old enterprise apps, vendor portals without APIs).
- **End-to-end UI testing** — Claude drives the app like a user; verifies behaviors not coverable by unit/integration tests.
- **Research / exploration** — letting Claude explore an interface you're studying or documenting.

Computer Use is the **wrong call** when:

- **There's an API.** Always prefer the API. Computer Use is the option of last resort — slower, more expensive, less reliable.
- **The task is high-stakes and irreversible.** Claude clicks "delete" on the wrong file sometimes. Don't let it drive production systems.
- **Latency matters.** Screenshots → vision → action → execute → screenshot is slow. Each iteration is seconds.
- **You can't sandbox.** Never run Computer Use on a host you care about. Sandboxing is not optional.

## 2025-2026 currency anchors

- **Production-grade trajectory.** From beta Oct 2024 to production-grade 2025-2026. Quality and reliability have improved; the operational discipline (sandbox, iteration cap, approval gates) has not relaxed.
- **Dated tool versions tied to model versions.** `computer_20250124` was the early-2025 surface; `computer_20251022` is current as of late 2025. Verify the current tool version for your model in the [Computer Use docs](https://docs.anthropic.com/en/docs/agents-and-tools/computer-use).
- **Anthropic publishes reference VM images** (Docker, cloud-deployable). Use these as starting points; don't roll your own sandbox without explicit threat-model work.
- **Provider-cloud availability:** Computer Use historically shipped to the [Anthropic API](/stacks/anthropic-claude/claude-api/) first; verify availability on [Bedrock](/stacks/anthropic-claude/bedrock-provider/) and [Vertex AI](/stacks/anthropic-claude/vertex-ai-provider/) before assuming.

## Patterns + anti-patterns

### Pattern — sandboxed VM with constrained network

Run Claude's screen-driving in a Docker container or cloud VM with:

- **No persistent storage** beyond what the task requires.
- **Network egress restricted** to the specific hosts the task needs.
- **No prod credentials.** Per-task scoped credentials only.
- **Reset between tasks.** Fresh state each invocation; no carry-over.

### Pattern — iteration cap + human escalation

Set an explicit max-iterations cap (e.g., 30 screenshots) on Computer Use loops. On hitting the cap, escalate to human with the current screenshot — don't loop indefinitely.

### Pattern — pre-action approval for destructive operations

For irreversible actions (delete, send email, submit form, charge payment), gate with explicit user approval *before* Claude clicks. Show the about-to-happen action; require human confirmation; then execute. See [security-engineer overlay on pre-action approval](/stacks/anthropic-claude/security-engineer/#agents-with-side-effects).

### Pattern — Computer Use for testing, not production

UI automation testing in CI: Claude drives the staging app, verifies user flows, reports. This is a sweet spot — high-value, lower-stakes than production driving.

### Anti-pattern — Computer Use on a developer laptop without isolation

One bad action and your filesystem is touched. Use a VM or container, full stop.

### Anti-pattern — Computer Use as a substitute for missing automation

It's a bridge — eventually build the API. Computer Use is the most expensive automation tier (vision tokens + roundtrip latency + iteration cost).

### Anti-pattern — Combining Computer Use with high-budget agent loops

Costs and risk compound. Cap iterations aggressively (10-30); fail fast.

### Anti-pattern — Mixing tool versions and model versions

`computer_20250124` with a Sonnet 4.7 model throws an API error. Pin to the matched pair documented in the current Computer Use docs.

## Gotchas

- **Vision tokens are expensive.** Each screenshot is a vision input — sized at full screen resolution. Costs add up fast on long loops.
- **The model can misread complex UIs.** Buttons it can't see clearly = wrong clicks. Test on the actual UI; don't assume parity with cleaner screenshots.
- **Multi-monitor / scaled displays** require careful coordinate handling. Verify against the resolution the model is seeing.
- **Keyboard shortcuts vary by OS.** Cmd vs Ctrl, Option vs Alt — bake the OS into the system prompt or the tool harness.
- **Tool version mismatch** is a common bug source after model upgrades. Update both together.

## Cross-references

- [Claude API (Messages)](/stacks/anthropic-claude/claude-api/) — Computer Use is a tool in the `tools` array
- [Tool Use](/stacks/anthropic-claude/tool-use/) — the protocol Computer Use rides on
- [Vision](/stacks/anthropic-claude/vision/) — image processing underneath Computer Use
- [Claude Agent SDK](/stacks/anthropic-claude/claude-agent-sdk/) — agent harness with Computer Use support
- [security-engineer overlay](/stacks/anthropic-claude/security-engineer/) — sandboxing, pre-action approval
- [Computer Use Guide](https://docs.anthropic.com/en/docs/agents-and-tools/computer-use)
