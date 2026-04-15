# Security Policy

## Supported Versions

We support the latest minor version of the current major release. The 2.x line is the current supported line as of v2.0.0.

| Version | Supported |
|---------|-----------|
| 2.x     | ✅ |
| 1.x     | ❌ (please upgrade — see [CHANGELOG.md](CHANGELOG.md) migration notes) |

## Reporting a Vulnerability

**Please do not open a public issue for security vulnerabilities.**

If you have discovered a vulnerability in any ETYB-Skills component — the skills themselves, the install/update scripts, or the adapter layer — please use GitHub's private vulnerability reporting:

1. Go to <https://github.com/e-t-y-b/etyb-skills/security/advisories/new>
2. Describe the issue with enough detail to reproduce
3. We will acknowledge within 72 hours and work with you on a fix and disclosure timeline

## What Counts as a Vulnerability

For this project specifically:
- **Install/update scripts** — anything that could delete data, execute arbitrary code, or affect files outside the install target
- **Skill content** — a skill that instructs the model to exfiltrate secrets, bypass security reviews, or introduce dangerous patterns
- **Dependency chain** — CVEs in npm or Python packages this repo pulls in

For skills that teach security practices (e.g. `security-engineer`), the content *describes* attacks and defenses — these are educational and not themselves vulnerabilities.

## Out of Scope

- Model output quality (routing decisions, advice, tone) — file a regular issue
- Compatibility bugs with specific agent runtimes — file a regular issue
- Theoretical concerns without a concrete attack path

Thank you for keeping ETYB-Skills safe for the community.
