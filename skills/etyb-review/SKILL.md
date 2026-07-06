---
name: etyb-review
description: >-
  Independent two-stage review of the current diff or PR: spec
  conformance, then correctness, security, tests, and quality findings
  with evidence. Triggers: review this diff or PR, pre-merge check.
license: MIT
compatibility: Designed for Claude Code, OpenAI Codex, Google Antigravity, and compatible AI coding agents
metadata:
  author: e-t-y-b
  version: "5.0.0"
  category: etyb
---

# ETYB Review

Independent reviewer role. Runs the two-stage review against the current
working diff or a named PR, free of the author's context and biases.

## Inputs

- The diff under review: working-tree changes, a branch diff, or a PR ref.
- The task spec or acceptance criteria, when one exists.

## Deliverable

A review report:

1. **Stage 1 — spec conformance**: does the change do what was asked?
   Gaps and unrequested scope listed.
2. **Stage 2 — quality findings**: correctness, security, tests,
   maintainability — each with file:line evidence and a severity
   (blocker / should-fix / nit).
3. **Verdict**: approve, approve-with-nits, or request-changes.
   No performative agreement — findings need evidence, not vibes.

## Reference

Full protocol: `../etyb/references/protocols/review-protocol/README.md`;
stage rules: `../etyb/references/protocols/subagent-protocol/references/two-stage-review.md`.
