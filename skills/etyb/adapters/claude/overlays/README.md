# Claude frontmatter overlays

Each `<skill>.yaml` here holds Claude-only frontmatter for the matching
`skills/<skill>/SKILL.md`. The adapter generator (M2-T5) deep-merges the
overlay's top-level keys into the frontmatter of the *emitted* plugin copy
of that SKILL.md — overlay keys win on conflict; body and all other
frontmatter pass through unchanged. The shared tree keeps only portable
open-spec fields, so `lint-portability.sh` guarantees still hold: never
add `context:`/`agent:` (or any Claude-only field) to `skills/*/SKILL.md`
directly — add it here instead.
