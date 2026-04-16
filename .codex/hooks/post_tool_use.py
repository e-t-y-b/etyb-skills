#!/usr/bin/env python3

from __future__ import annotations

import os

from common import emit, extract_exit_code, flatten_text, is_test_command, load_payload, load_state, now_iso, parse_tool_response, save_state


def main() -> None:
    payload = load_payload()
    cwd = payload.get("cwd") or os.getcwd()
    command = (payload.get("tool_input") or {}).get("command", "")
    state = load_state(cwd)

    if not is_test_command(command):
        emit({})
        return

    parsed_response = parse_tool_response(payload.get("tool_response"))
    exit_code = extract_exit_code(parsed_response)
    output_excerpt = flatten_text(parsed_response)[:400]

    if exit_code == 0:
        state["last_successful_test"] = {
            "at": now_iso(),
            "command": command,
            "output_excerpt": output_excerpt,
        }
        state.pop("last_failed_test", None)
        save_state(cwd, state)
        emit(
            {
                "systemMessage": (
                    "ETYB verification updated: the latest Bash test command passed. "
                    "Merge or ship only after review evidence and the five verification answers are also ready."
                ),
                "hookSpecificOutput": {
                    "hookEventName": "PostToolUse",
                    "additionalContext": (
                        "The latest Bash test command passed. Treat the workspace as test-verified only for work "
                        "completed before this point."
                    ),
                },
            }
        )
        return

    state["last_failed_test"] = {
        "at": now_iso(),
        "command": command,
        "output_excerpt": output_excerpt,
    }
    save_state(cwd, state)
    emit(
        {
            "systemMessage": (
                "ETYB verification guardrail: the latest Bash test command failed. "
                "Do not merge, ship, or claim completion yet. Switch to debugging-protocol until a later run passes."
            ),
            "hookSpecificOutput": {
                "hookEventName": "PostToolUse",
                "additionalContext": (
                    "A Bash test command failed. The workspace is currently unverified for merge or completion claims."
                ),
            },
        }
    )


if __name__ == "__main__":
    main()
