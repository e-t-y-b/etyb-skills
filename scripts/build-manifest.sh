#!/usr/bin/env bash
#
# build-manifest.sh — regenerate the root manifest.json (M3-T1).
#
# What it does
#   Scans every stacks/**/*.md page, extracts currency metadata from YAML
#   frontmatter, and rewrites manifest.json with a regenerated top-level
#   "stacks_pages" array. All other top-level sections (bundle, skill,
#   stacks, platforms) are hand-maintained and preserved verbatim from the
#   existing manifest.json — this script only owns "stacks_pages".
#
# Shape choice (why a new top-level "stacks_pages" array, not per-stack nesting)
#   scripts/maintainer/validate-version-sync.sh iterates .stacks.*.version and
#   scripts/maintainer/validate-skill-manifest-sync.sh asserts .skill keys,
#   the absence of .tiers, and that .stacks entries carry no
#   available_on_tiers. Nesting pages inside .stacks.<name> would put a
#   generated blob inside a hand-maintained, validator-scrutinized section;
#   a sibling top-level array keeps both validators untouched and green, and
#   gives the M3-T2 stack-researcher and M3-T3 currency CI one flat, sorted
#   list to consume.
#
# Per-page fields (sorted by path; keys in fixed order):
#   path              — repo-relative page path (e.g. "stacks/aws/lambda.md")
#   last_verified_on  — from the page's own frontmatter (product.*,
#                       role_overlay.*, stack.*, or metadata.* block)
#   drift_risk        — resolution order:
#                         1. page frontmatter (product.drift_risk)
#                         2. the stack SKILL.md products_covered entry whose
#                            name matches the page's product name (or whose
#                            slug matches the page filename)
#                         3. the stack default: stack.drift_risk_default from
#                            stacks/<stack>/index.md, else "medium"
#   authoritative_url — from page frontmatter, only when present
#
# Determinism / CI drift idiom
#   Output is byte-stable: fixed key order, paths sorted, JSON rendered with
#   2-space indent + trailing newline, and no run-varying data (no
#   timestamps — bundle.published_at is hand-maintained and passed through).
#   Running the script twice produces byte-identical output, so CI checks
#   drift with:
#       bash scripts/build-manifest.sh && git diff --exit-code manifest.json
#
# Dependencies: python3 + pyyaml (frontmatter uses YAML flow mappings, which
#   rules out naive grep parsing). jq is not required.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

command -v python3 >/dev/null 2>&1 || { echo "✗ build-manifest: python3 is required" >&2; exit 1; }
python3 -c 'import yaml' 2>/dev/null || { echo "✗ build-manifest: python3 module 'yaml' (pyyaml) is required" >&2; exit 1; }

python3 - <<'PY'
import json
import re
import sys
from pathlib import Path

import yaml

MANIFEST = Path("manifest.json")
STACKS = Path("stacks")
FALLBACK_DRIFT_RISK = "medium"

def frontmatter(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not m:
        sys.exit(f"✗ build-manifest: {path}: no YAML frontmatter block")
    try:
        fm = yaml.safe_load(m.group(1))
    except yaml.YAMLError as e:
        sys.exit(f"✗ build-manifest: {path}: frontmatter is not valid YAML: {e}")
    if not isinstance(fm, dict):
        sys.exit(f"✗ build-manifest: {path}: frontmatter did not parse to a mapping")
    return fm

def slugify(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")

# --- Pass 1: per-stack context (SKILL.md products_covered + index.md default) ---

stack_dirs = sorted(d for d in STACKS.iterdir() if d.is_dir())
stack_ctx = {}
for d in stack_dirs:
    ctx = {"default": FALLBACK_DRIFT_RISK, "products": {}}
    index = d / "index.md"
    if index.exists():
        fm = frontmatter(index)
        default = (fm.get("stack") or {}).get("drift_risk_default")
        if default:
            ctx["default"] = str(default)
    skill = d / "SKILL.md"
    if skill.exists():
        fm = frontmatter(skill)
        for entry in fm.get("products_covered") or []:
            if isinstance(entry, dict) and entry.get("name") and entry.get("drift_risk"):
                risk = str(entry["drift_risk"])
                ctx["products"][entry["name"].lower()] = risk
                ctx["products"][slugify(entry["name"])] = risk
    stack_ctx[d.name] = ctx

# --- Pass 2: one manifest entry per page ---

def page_block(fm: dict) -> dict:
    for key in ("product", "role_overlay", "stack", "metadata"):
        block = fm.get(key)
        if isinstance(block, dict):
            return block
    return {}

def resolve_drift_risk(page: Path, block: dict, ctx: dict) -> str:
    own = block.get("drift_risk")
    if own:
        return str(own)
    products = ctx["products"]
    name = block.get("name")
    if isinstance(name, str):
        risk = products.get(name.lower()) or products.get(slugify(name))
        if risk:
            return risk
    risk = products.get(page.stem.lower())
    if risk:
        return risk
    return ctx["default"]

pages = []
for path in sorted(STACKS.rglob("*.md"), key=lambda p: str(p)):
    fm = frontmatter(path)
    block = page_block(fm)
    last_verified_on = block.get("last_verified_on")
    if not last_verified_on:
        sys.exit(f"✗ build-manifest: {path}: no last_verified_on in frontmatter")
    entry = {
        "path": str(path),
        "last_verified_on": str(last_verified_on),
        "drift_risk": resolve_drift_risk(path, block, stack_ctx[path.parts[1]]),
    }
    url = block.get("authoritative_url")
    if url:
        entry["authoritative_url"] = str(url)
    pages.append(entry)

# --- Rewrite manifest.json: preserve hand-maintained sections, replace stacks_pages ---

manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
manifest["stacks_pages"] = pages
MANIFEST.write_text(
    json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
    encoding="utf-8",
)
print(f"✓ build-manifest: manifest.json regenerated with {len(pages)} stack pages "
      f"across {len(stack_dirs)} stacks")
PY
