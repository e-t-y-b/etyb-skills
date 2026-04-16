#!/usr/bin/env python3

from __future__ import annotations

import os

from common import emit, has_recent_successful_test, is_commit_command, is_merge_command, load_payload, load_state


def main() -> None:
    payload = load_payload()
    cwd = payload.get("cwd") or os.getcwd()
    command = (payload.get("tool_input") or {}).get("command", "")
    state = load_state(cwd)

    if is_merge_command(command) and not has_recent_successful_test(state):
        emit(
            {
                "decision": "block",
                "reason": (
                    "ETYB branch safety: run the project test suite with a Bash command and get a green result "
                    "before merging. Codex hooks can validate recent Bash verification evidence, but they cannot "
                    "infer it from file edits alone."
                ),
            }
        )
        return

    if is_commit_command(command):
        emit(
            {
                "systemMessage": (
                    "ETYB review discipline: before committing Tier 2+ work, run an independent review "
                    "(prefer the `etyb_reviewer` agent) and keep verification evidence ready. "
                    "Codex hooks can remind here, but review completion is still model-trusted."
                )
            }
        )
        return

    emit({})


if __name__ == "__main__":
    main()
