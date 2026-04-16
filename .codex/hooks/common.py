#!/usr/bin/env python3

"""Shared utilities for ETYB Codex lifecycle hooks."""

from __future__ import annotations

import datetime as dt
import hashlib
import json
import os
import re
import sys
import tempfile
from pathlib import Path
from typing import Any


TEST_COMMAND_MARKERS = (
    "pytest",
    "go test",
    "cargo test",
    "gradle test",
    "mvn test",
    "pnpm test",
    "npm test",
    "pnpm run test",
    "npm run test",
    "vitest",
    "jest",
    "rspec",
    "ctest",
    "phpunit",
    "uv run pytest",
    "make test",
    "playwright test",
    "pnpm check",
    "npm run check",
)


def load_payload() -> dict[str, Any]:
    raw = sys.stdin.read()
    if not raw.strip():
        return {}
    return json.loads(raw)


def emit(payload: dict[str, Any]) -> None:
    json.dump(payload, sys.stdout)


def now_iso() -> str:
    return dt.datetime.now(dt.timezone.utc).isoformat()


def parse_iso(value: str | None) -> dt.datetime | None:
    if not value:
        return None
    try:
        return dt.datetime.fromisoformat(value)
    except ValueError:
        return None


def state_path(cwd: str) -> Path:
    ident = hashlib.sha256(cwd.encode("utf-8")).hexdigest()[:16]
    root = Path(tempfile.gettempdir()) / "etyb-codex-hooks" / ident
    root.mkdir(parents=True, exist_ok=True)
    return root / "state.json"


def load_state(cwd: str) -> dict[str, Any]:
    path = state_path(cwd)
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text())
    except json.JSONDecodeError:
        return {}


def save_state(cwd: str, state: dict[str, Any]) -> None:
    path = state_path(cwd)
    path.write_text(json.dumps(state, indent=2, sort_keys=True))


def parse_tool_response(value: Any) -> Any:
    if isinstance(value, str):
        stripped = value.strip()
        if stripped.startswith("{") or stripped.startswith("["):
            try:
                return json.loads(stripped)
            except json.JSONDecodeError:
                return {"raw": value}
        return {"raw": value}
    return value


def extract_exit_code(value: Any) -> int | None:
    codes: list[int] = []

    def walk(node: Any) -> None:
        if isinstance(node, dict):
            for key, inner in node.items():
                if key in {"exit_code", "exitCode", "code", "status"} and isinstance(inner, int):
                    codes.append(inner)
                else:
                    walk(inner)
        elif isinstance(node, list):
            for item in node:
                walk(item)

    walk(value)
    return codes[0] if codes else None


def flatten_text(value: Any) -> str:
    chunks: list[str] = []

    def walk(node: Any) -> None:
        if isinstance(node, str):
            chunks.append(node)
        elif isinstance(node, dict):
            for inner in node.values():
                walk(inner)
        elif isinstance(node, list):
            for item in node:
                walk(item)
        elif node is not None:
            chunks.append(str(node))

    walk(value)
    return "\n".join(chunks)


def is_test_command(command: str) -> bool:
    lowered = command.lower()
    return any(marker in lowered for marker in TEST_COMMAND_MARKERS)


def is_merge_command(command: str) -> bool:
    return bool(re.search(r"(^|\s)(git\s+merge|gh\s+pr\s+merge)(\s|$)", command))


def is_commit_command(command: str) -> bool:
    return bool(re.search(r"(^|\s)git\s+commit(\s|$)", command))


def has_recent_successful_test(state: dict[str, Any], max_age_minutes: int = 90) -> bool:
    record = state.get("last_successful_test")
    if not isinstance(record, dict):
        return False
    recorded_at = parse_iso(record.get("at"))
    if recorded_at is None:
        return False
    age = dt.datetime.now(dt.timezone.utc) - recorded_at
    return age <= dt.timedelta(minutes=max_age_minutes)


def failed_test_is_newer_than_success(state: dict[str, Any]) -> bool:
    failed = parse_iso((state.get("last_failed_test") or {}).get("at"))
    passed = parse_iso((state.get("last_successful_test") or {}).get("at"))
    if failed is None:
        return False
    if passed is None:
        return True
    return failed > passed


def prompt_block_reason(prompt: str) -> str | None:
    lowered = prompt.lower()
    nontrivial = len(prompt) > 120 or any(
        marker in lowered
        for marker in (
            "build ",
            "platform",
            "service",
            "system",
            "workflow",
            "feature",
            "api",
            "database",
            "auth",
            "billing",
            "payment",
            "migration",
            "architecture",
        )
    )

    patterns = (
        (
            r"\bskip (the )?(design|plan|review|verify|verification|tests?|testing|gate)\b",
            "ETYB does not skip lifecycle gates or quality checks. Keep the gate, but make it lighter if the scope allows.",
        ),
        (
            r"\b(don't|do not) (make|create|write|use) (a )?plan\b",
            "ETYB defaults to `.etyb/plans/` for non-trivial work on Codex. Use a lightweight plan if needed, but do not skip plan tracking entirely.",
        ),
        (
            r"\bwithout (tests?|testing|review|verification)\b",
            "ETYB requires verification evidence before commit, merge, or ship. Run the checks first and then continue.",
        ),
        (
            r"\b(commit|merge|ship) anyway\b",
            "ETYB will not bypass review, test, or verification discipline just because the deadline is tight.",
        ),
    )

    for pattern, reason in patterns:
        if re.search(pattern, lowered):
            return reason

    if nontrivial and re.search(r"\bjust write the code\b", lowered):
        return "This sounds larger than a trivial change. Start with the correct gate, create or update the `.etyb/plans/` artifact, and then implement from there."

    return None


def completion_claimed(last_message: str | None) -> bool:
    if not last_message:
        return False
    lowered = last_message.lower()
    patterns = (
        "done",
        "complete",
        "completed",
        "ready to ship",
        "ready to merge",
        "ready for merge",
        "verified",
        "all set",
    )
    return any(pattern in lowered for pattern in patterns)
