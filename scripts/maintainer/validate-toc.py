#!/usr/bin/env python3
"""
Validate that every TOC link in SKILL.md and references/*.md targets a
heading anchor that actually exists in the same file.

A TOC is a numbered list of `[text](#anchor)` items appearing in the
first 80 lines of the file. Files without a TOC are skipped.

Anchor slugification matches GitHub's behavior:
  - lowercase
  - drop characters that are not alphanumeric, space, hyphen, or underscore
  - map each whitespace character to a single hyphen (no run-collapsing —
    so ``Foo & Bar`` (which has two spaces after dropping ``&``) becomes
    ``foo--bar``, matching what GitHub generates)
  - on collision within the same file, append ``-1``, ``-2``, ...
    (so two ``## Overview`` headings produce anchors ``overview`` and
    ``overview-1``)

Pre-existing drift is tracked in
``scripts/maintainer/.toc-baseline.txt`` — one ``relpath:line:anchor``
entry per line. Errors matching the baseline are reported as warnings
and do not fail the run. New errors not in the baseline fail the run.
Refresh the baseline with ``--update-baseline`` after a deliberate
cleanup pass.

Exits non-zero with a clear message listing every offending TOC link.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
BASELINE_PATH = Path(__file__).resolve().parent / ".toc-baseline.txt"

HEADING_RE = re.compile(r"^(#{2,6})\s+(.+?)\s*$")
TOC_LINK_RE = re.compile(r"\[([^\]]+)\]\(#([^)]+)\)")
NUMBERED_LIST_RE = re.compile(r"^\s*\d+\.\s")
SLUG_DROP_RE = re.compile(r"[^a-z0-9\s\-_]")
WHITESPACE_RE = re.compile(r"\s")


def slugify(text: str) -> str:
    text = re.sub(r"`([^`]+)`", r"\1", text)
    s = text.lower().strip()
    s = SLUG_DROP_RE.sub("", s)
    s = WHITESPACE_RE.sub("-", s)
    return s.strip("-")


def collect_anchors(lines: list[str]) -> dict[str, int]:
    """Return a map of unique anchor slug → line number, applying
    GitHub's ``-N`` suffix on collisions."""
    anchors: dict[str, int] = {}
    counts: dict[str, int] = {}
    in_code = False
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped.startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        m = HEADING_RE.match(line)
        if not m:
            continue
        slug = slugify(m.group(2))
        if not slug:
            continue
        if slug in counts:
            counts[slug] += 1
            unique = f"{slug}-{counts[slug]}"
        else:
            counts[slug] = 0
            unique = slug
        anchors[unique] = i
    return anchors


def find_toc(lines: list[str]) -> list[tuple[int, str, str]]:
    """Return list of (line_number, link_text, anchor_target) from the
    first numbered-list TOC found inside the first 80 lines."""
    toc: list[tuple[int, str, str]] = []
    in_block = False
    for i, line in enumerate(lines[:80], 1):
        if NUMBERED_LIST_RE.match(line):
            in_block = True
            for m in TOC_LINK_RE.finditer(line):
                toc.append((i, m.group(1), m.group(2)))
            continue
        if in_block:
            if line.strip() == "" or line.startswith(" "):
                continue
            break
    return toc


class TocError:
    __slots__ = ("rel", "line", "target", "message")

    def __init__(self, rel: str, line: int, target: str, message: str) -> None:
        self.rel = rel
        self.line = line
        self.target = target
        self.message = message

    def key(self) -> str:
        return f"{self.rel}:{self.line}:{self.target}"


def check_file(path: Path) -> list[TocError]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    toc = find_toc(lines)
    if not toc:
        return []
    anchors = collect_anchors(lines)
    rel = str(path.relative_to(ROOT))
    errors: list[TocError] = []
    for line_no, link_text, target in toc:
        if target not in anchors:
            close = [a for a in anchors if target.split("-", 1)[0] in a][:3]
            hint = f" (similar headings: {', '.join(close)})" if close else ""
            errors.append(
                TocError(
                    rel=rel,
                    line=line_no,
                    target=target,
                    message=(
                        f"{rel}:{line_no}: TOC link "
                        f"'[{link_text}](#{target})' has no matching heading"
                        f"{hint}"
                    ),
                )
            )
    return errors


def load_baseline() -> set[str]:
    if not BASELINE_PATH.is_file():
        return set()
    out: set[str] = set()
    for line in BASELINE_PATH.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        out.add(line)
    return out


def write_baseline(errors: list[TocError]) -> None:
    keys = sorted({e.key() for e in errors})
    header = (
        "# TOC drift baseline — pre-existing failures the validator\n"
        "# tolerates so CI can ship. Each line is `relpath:line:anchor`.\n"
        "# When you fix a TOC, delete its line here. Add new lines only\n"
        "# when consciously deferring a fix; the validator will then warn\n"
        "# instead of failing.\n"
    )
    BASELINE_PATH.write_text(header + "\n".join(keys) + "\n", encoding="utf-8")


def main(argv: list[str]) -> int:
    update = "--update-baseline" in argv

    targets: list[Path] = []
    skills = ROOT / "skills"
    for skill in sorted(skills.iterdir()):
        if not skill.is_dir():
            continue
        skill_md = skill / "SKILL.md"
        if skill_md.is_file():
            targets.append(skill_md)
        refs = skill / "references"
        if refs.is_dir():
            for md in sorted(refs.rglob("*.md")):
                targets.append(md)

    all_errors: list[TocError] = []
    for path in targets:
        all_errors.extend(check_file(path))

    if update:
        write_baseline(all_errors)
        print(
            f"✓ validate-toc: wrote {len(all_errors)} entries to "
            f"{BASELINE_PATH.relative_to(ROOT)}"
        )
        return 0

    baseline = load_baseline()
    new_errors = [e for e in all_errors if e.key() not in baseline]
    tolerated = [e for e in all_errors if e.key() in baseline]

    if tolerated:
        print(
            f"⚠ validate-toc: {len(tolerated)} pre-existing TOC drift "
            f"entries tolerated via baseline (run --update-baseline after "
            f"a cleanup pass to refresh)",
            file=sys.stderr,
        )

    if new_errors:
        print("✗ validate-toc: new TOC drift detected:", file=sys.stderr)
        for err in new_errors:
            print(f"  {err.message}", file=sys.stderr)
        return 1

    print(f"✓ validate-toc: {len(targets)} markdown files scanned, no new TOC drift")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
