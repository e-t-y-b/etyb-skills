#!/usr/bin/env python3

from __future__ import annotations

import os

from common import completion_claimed, emit, failed_test_is_newer_than_success, has_recent_successful_test, load_payload, load_state


def main() -> None:
    payload = load_payload()
    cwd = payload.get("cwd") or os.getcwd()
    state = load_state(cwd)

    if payload.get("stop_hook_active"):
        emit({})
        return

    if failed_test_is_newer_than_success(state):
        emit(
            {
                "decision": "block",
                "reason": (
                    "ETYB stop guardrail: the last observed Bash test command failed. "
                    "Stay in the turn, use debugging-protocol, rerun the relevant test suite, "
                    "and only close out after it passes with a five-question verification summary."
                ),
            }
        )
        return

    last_message = payload.get("last_assistant_message")
    if completion_claimed(last_message) and not has_recent_successful_test(state):
        emit(
            {
                "decision": "block",
                "reason": (
                    "ETYB stop guardrail: before ending on a completion claim, run the relevant Bash test or "
                    "verification command, answer the five verification questions, and note any remaining risk. "
                    "Codex hooks can only validate Bash evidence, so make that evidence explicit now."
                ),
            }
        )
        return

    emit({})


if __name__ == "__main__":
    main()
