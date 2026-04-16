#!/usr/bin/env python3

from __future__ import annotations

import os

from common import emit, load_payload, load_state, now_iso, prompt_block_reason, save_state


DEFAULT_CONTEXT = (
    "ETYB Codex runtime: default plan storage is `.etyb/plans/`. "
    "Prefer `etyb_explorer` for bounded discovery, `etyb_planner` for plan updates, "
    "`etyb_reviewer` for independent review, and `etyb_docs_researcher` for doc verification. "
    "Codex hooks can guard prompts, Bash commands, and turn stop, but edit-before-test is still a model-trusted gap."
)


def main() -> None:
    payload = load_payload()
    cwd = payload.get("cwd") or os.getcwd()
    prompt = payload.get("prompt", "")
    state = load_state(cwd)
    state["last_prompt"] = {"at": now_iso(), "text": prompt}
    save_state(cwd, state)

    reason = prompt_block_reason(prompt)
    if reason:
        emit({"decision": "block", "reason": reason})
        return

    emit(
        {
            "hookSpecificOutput": {
                "hookEventName": "UserPromptSubmit",
                "additionalContext": DEFAULT_CONTEXT,
            }
        }
    )


if __name__ == "__main__":
    main()
