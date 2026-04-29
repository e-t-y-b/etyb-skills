#!/usr/bin/env python3
"""Generate plain-text bundle manifests from .claude-plugin/marketplace.json.

marketplace.json is the single source of truth for bundle composition. It is
the format Claude Code's native plugin marketplace consumes. For every other
install path (install.sh, curl|sh bootstrap, manual copy) we need a
dependency-free representation — hence this generator.

For each plugin entry in marketplace.json we write bundles/<plugin>.txt
containing one skill directory name per line (stripped of the leading
"./skills/" prefix). install.sh reads these at runtime with zero deps.

Usage:
  scripts/generate-bundles.py          # regenerate bundles/
  scripts/generate-bundles.py --check  # exit 1 if bundles/ is out of date
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
MARKETPLACE = REPO_ROOT / ".claude-plugin" / "marketplace.json"
BUNDLE_DIR = REPO_ROOT / "bundles"
SKILL_PREFIX = "./skills/"


def load_bundles() -> dict[str, list[str]]:
    data = json.loads(MARKETPLACE.read_text())
    bundles: dict[str, list[str]] = {}
    for plugin in data.get("plugins", []):
        name = plugin["name"]
        skills = []
        for entry in plugin.get("skills", []):
            if not entry.startswith(SKILL_PREFIX):
                raise SystemExit(
                    f"marketplace.json: skill entry {entry!r} in plugin "
                    f"{name!r} must start with {SKILL_PREFIX!r}"
                )
            skills.append(entry[len(SKILL_PREFIX):])
        # Install order is author-meaningful (etyb first in most bundles),
        # so preserve it rather than sorting alphabetically.
        bundles[name] = skills
    return bundles


def render(skills: list[str]) -> str:
    return "\n".join(skills) + "\n"


def write_bundles(bundles: dict[str, list[str]]) -> None:
    BUNDLE_DIR.mkdir(exist_ok=True)
    existing = {p.name for p in BUNDLE_DIR.glob("*.txt")}
    written: set[str] = set()
    for name, skills in bundles.items():
        path = BUNDLE_DIR / f"{name}.txt"
        path.write_text(render(skills))
        written.add(path.name)
    # Remove stale manifests from deleted plugins.
    for stale in existing - written:
        (BUNDLE_DIR / stale).unlink()


def check(bundles: dict[str, list[str]]) -> int:
    errors: list[str] = []
    for name, skills in bundles.items():
        path = BUNDLE_DIR / f"{name}.txt"
        if not path.exists():
            errors.append(f"missing: bundles/{name}.txt")
            continue
        expected = render(skills)
        actual = path.read_text()
        if actual != expected:
            errors.append(f"out of date: bundles/{name}.txt")
    existing = {p.stem for p in BUNDLE_DIR.glob("*.txt")} if BUNDLE_DIR.exists() else set()
    for stale in existing - set(bundles):
        errors.append(f"stale: bundles/{stale}.txt (no matching plugin)")
    if errors:
        print("bundle manifests are out of date:", file=sys.stderr)
        for e in errors:
            print(f"  - {e}", file=sys.stderr)
        print(
            "\nregenerate with: scripts/generate-bundles.py",
            file=sys.stderr,
        )
        return 1
    print(f"bundles/ is in sync ({len(bundles)} manifests)")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="exit 1 if bundles/ differs from marketplace.json",
    )
    args = parser.parse_args()

    bundles = load_bundles()
    if args.check:
        return check(bundles)
    write_bundles(bundles)
    print(f"wrote {len(bundles)} bundle manifests to {BUNDLE_DIR.relative_to(REPO_ROOT)}/")
    for name, skills in bundles.items():
        print(f"  {name}: {len(skills)} skills")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
