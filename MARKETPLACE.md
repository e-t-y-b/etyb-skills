# Marketplace Listing Copy

Copy-paste-ready pitches in three lengths for marketplace listings (skills.sh, SkillsMP, LobeHub, mdskills, etc.) and social posts. Update the bundle version in the tagline if this file falls behind.

Canonical version: see [`VERSION`](VERSION) • Repo: <https://github.com/e-t-y-b/etyb-skills> • Changelog: [`CHANGELOG.md`](CHANGELOG.md)

---

## 1. One-liner (tagline)

> **ETYB — install a virtual engineering company. A CTO, 20 specialists, and 9 always-on engineering disciplines for your AI coding agent.**

---

## 2. Short pitch (for skills.sh / SkillsMP / LobeHub card — ~50 words)

Install a virtual engineering team. ETYB routes your request to 20 specialists — backend, frontend, security, SRE, fintech, healthcare, and more — and enforces 9 engineering disciplines (TDD, review, verification, debugging, branch safety) through 5 quality gates. Works on Claude Code, Codex, and Antigravity. No more yolo-mode AI.

---

## 3. Medium pitch (for repo About / marketplace detail page — ~150 words)

**Stop prompting individual skills. Install a team.**

ETYB-Skills is 31 coordinated AI agent skills organized as a virtual engineering company. You get a CTO-level orchestrator that classifies every request, routes to the right specialist, enforces phase gates (Design → Plan → Implement → Verify → Ship), and tracks living plans — plus 20 domain experts and 9 always-on engineering disciplines.

**Why it's different from a bag of skills:**
- The CTO routes work to specialists; specialists don't step on each other
- Deterministic hook enforcement on Claude Code — TDD, review, and branch-safety gates *cannot be reasoned around*
- Cross-platform portable core (Claude Code, OpenAI Codex, Google Antigravity)
- Every specialist works standalone; the CTO is optional
- Full SDLC coverage — research → architecture → code → test → deploy → operate
- Six domain verticals: fintech, healthcare, e-commerce, SaaS, real-time, social platforms

Install with one command. Update with one command. No silent changes.

---

## 4. Long pitch (for a blog post / launch announcement — ~500 words)

**ETYB: Your Virtual Engineering Company**

Most AI coding agents behave like enthusiastic interns — skilled, fast, and dangerously willing to say yes. They skip tests when deadlines are mentioned. They rubber-stamp code reviews. They fix symptoms instead of root causes. They give you the code you asked for, not the code you needed.

ETYB is different. ETYB is a *team*.

When you install ETYB-Skills on Claude Code, OpenAI Codex, or Google Antigravity, you get 31 coordinated AI agent skills organized like a disciplined engineering company:

- **1 CTO (ETYB)** that classifies every request into tiers (trivial → urgent → moderate → complex), routes to the right experts, and enforces 5 quality gates: Design → Plan → Implement → Verify → Ship
- **14 core teams** covering the full SDLC — research, architecture, frontend, backend, database, mobile, AI/ML, QA, DevOps, SRE, security, docs, project planning, code review
- **6 domain specialists** — fintech (ledgers, PCI, AML), healthcare (HIPAA, HL7/FHIR), e-commerce (checkout, inventory), SaaS (multi-tenancy, billing), real-time (WebSockets, CRDTs), social platforms (feeds, fan-out)
- **9 always-on process protocols** — TDD, code review, verification, debugging, subagent coordination, git workflow, plan execution, brainstorming-before-solving, self-improvement

**Gates that can't be reasoned around.** On Claude Code, ETYB wires up five deterministic hooks: a pre-edit check warns if you're editing source without a test file; a pre-commit check blocks commits without review evidence; a pre-merge check blocks merges with failing tests. These fire outside the LLM. No "just this once" escape hatches.

**Independent or orchestrated.** Every specialist works standalone — you can invoke `security-engineer` directly when you want a focused conversation, and it operates with full depth on its own. Or you can activate ETYB, state your goal, and watch the team self-organize: brainstorming, architecture, implementation, verification, and shipping with the right experts mandated at the right gates.

**Cross-platform, honestly.** Claude Code is the flagship — hooks, subagents, native plan mode. Codex and Antigravity are fully supported; their gates are model-trusted (no hooks exist on those platforms). The adapters are transparent about what's deterministic vs. what relies on the model following instructions.

**Install in one command:**
```bash
/plugin marketplace add e-t-y-b/etyb-skills
/plugin install etyb-full@etyb-skills
```

Or on Codex / Antigravity / manual:
```bash
git clone https://github.com/e-t-y-b/etyb-skills.git
./etyb-skills/scripts/install.sh
```

**Update in one command:** `./scripts/update.sh` — no silent changes, preserves your plans and local settings, uses fast-forward merge, shows before/after versions.

**MIT-licensed. Version 2.0.0 is live.** Works today on Claude Code; works today on Codex and Antigravity with the appropriate adapter. Built in the open at [github.com/e-t-y-b/etyb-skills](https://github.com/e-t-y-b/etyb-skills).

Stop prompting individual skills. Install a team.

---

## 5. Keywords (for repo topics, package keywords, SEO)

```
ai-agent, engineering, sdlc, orchestrator, virtual-team, cto,
tdd, code-review, security, devops, sre, architecture,
backend, frontend, database, mobile, ai-ml, fintech, healthcare,
e-commerce, saas, real-time, social-platform, process-protocols,
verification, debugging, quality-gates, agentskills, claude-code,
openai-codex, google-antigravity
```

## 6. Recommended GitHub repo settings

- **About:** `ETYB — virtual engineering company for AI coding agents. 31 skills: CTO + 20 specialists + 9 engineering disciplines. Claude Code, Codex, Antigravity.`
- **Website:** manifest URL or a landing page once available
- **Topics:** pick 10-15 from the keywords list above

## 7. Badges (optional, for README top)

```markdown
[![agentskills.io compliant](https://img.shields.io/badge/agentskills.io-compliant-blue)](https://agentskills.io)
[![version](https://img.shields.io/badge/version-2.0.0-green)](CHANGELOG.md)
[![license](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![platforms](https://img.shields.io/badge/platforms-Claude%20Code%20%7C%20Codex%20%7C%20Antigravity-purple)](docs/installation.md)
```
