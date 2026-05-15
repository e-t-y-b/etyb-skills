---
title: Vercel Sandbox
description: microVM-isolated execution for untrusted code — AI-generated code, agent tool outputs, user-submitted scripts. The canonical answer for "let an LLM run code" on Vercel.
product:
  name: Vercel Sandbox
  stack: vercel
  drift_risk: high
  last_verified_on: "2026-05-14"
  applies_to_roles: [ai-ml-engineer, backend-architect, system-architect]
  authoritative_url: https://vercel.com/docs/sandbox
  notes: "GA 2025; rapidly evolving. The canonical answer when you need to run untrusted code. Never run untrusted code in your main Vercel Function — Sandbox is the only safe path."
---

## What it is

Vercel Sandbox runs each session in an **isolated microVM** — file system, network, and memory are not shared with your function. It supports multiple runtimes (Node, Python, Deno) and exposes a `runCommand` API for executing user-supplied code in isolation. See [vercel.com/docs/sandbox](https://vercel.com/docs/sandbox).

## When to use

If the request involves "let an LLM run code" or "execute user-submitted code," Sandbox is the answer. Standard use cases:

1. **AI agent code-execution tools** — Claude/GPT generates code; Sandbox executes it; output returns to the model.
2. **User-submitted data transforms** — users paste a snippet to process their data; Sandbox runs it.
3. **Partner integrations** — third-party Lambdas/scripts you don't control.
4. **CI-like operations** — running tests against user code (CodeSandbox-style products).

**Do NOT** run untrusted code in your main Vercel Function — even with `vm` / `vm2`. Sandbox is the answer. There is no second path.

## 2025-2026 currency anchors

- **GA 2025.** Rapidly evolving — verify runtime list + limits in current docs.
- **microVM isolation** is the security boundary; not a JavaScript sandbox like `vm2`.
- **Network egress controlled** via allowlist configuration; default-deny is safest.
- **Per-second billing** for sandbox runtime; separate line item from Vercel Functions.

## Patterns + anti-patterns

**Pattern: One sandbox per tool call, then stop.**

```ts
import { Sandbox } from '@vercel/sandbox';
import { tool } from 'ai';
import { z } from 'zod';

const runPython = tool({
  description: 'Run a Python snippet and return its stdout. Use for calculations and data analysis.',
  inputSchema: z.object({ code: z.string() }),
  execute: async ({ code }) => {
    const sb = await Sandbox.create({ runtime: 'python3.13', timeout: 30_000 });
    try {
      const result = await sb.runCommand({ cmd: 'python', args: ['-c', code] });
      return {
        stdout: result.stdout.slice(0, 4000),  // cap output
        stderr: result.stderr.slice(0, 1000),
        exitCode: result.exitCode,
      };
    } finally {
      await sb.stop();
    }
  },
});
```

**Pattern: Always cap output.** LLM context windows aren't infinite; a 10MB stdout breaks the agent loop.

**Pattern: Always set timeout.** Runaway scripts cost money.

**Pattern: Default-deny network egress.** Allowlist exactly what the script needs.

**Anti-pattern: Reusing a sandbox across requests.** State leaks; isolate per-request.

**Anti-pattern: Running untrusted code in your function** with `eval()` / `vm.runInNewContext` — escape, RCE history. Use Sandbox.

**Anti-pattern: Uncapped stdout.** LLM agents will choke on multi-MB outputs.

## Gotchas

- **microVM lifecycle is per-request** unless you keep handles — and keeping handles introduces state-leak risk.
- **File system writes are ephemeral** — they don't persist across `Sandbox.create` calls.
- **Cost is per second of Sandbox runtime** — not the same line item as your function.
- **Cold start of a sandbox** is on the order of low seconds — acceptable for agent tool calls; not for hot-path serving.

## Cross-references

- [Vercel Functions](/stacks/vercel/vercel-functions/) — what calls Sandbox
- [AI SDK](/stacks/vercel/ai-sdk/) — `tool()` definitions that exec via Sandbox
- [Vercel Agent](/stacks/vercel/vercel-agent/) — uses Sandbox for tool execution
- [ai-ml-engineer on Vercel](/stacks/vercel/ai-ml-engineer/) — Sandbox in AI tool patterns
- [backend-architect on Vercel](/stacks/vercel/backend-architect/) — Sandbox for untrusted code generally
- Authoritative: [Sandbox docs](https://vercel.com/docs/sandbox)
- Delegate: `vercel:vercel-sandbox`
