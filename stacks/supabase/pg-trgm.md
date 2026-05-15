---
title: pg_trgm
description: Trigram-based fuzzy text matching and ILIKE acceleration. Pairs with pgvector for hybrid search.
product:
  name: pg_trgm
  stack: supabase
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [database-architect, ai-ml-engineer, backend-architect]
  authoritative_url: https://www.postgresql.org/docs/current/pgtrgm.html
  notes: "Stable Postgres extension; the only Supabase-specific story is its role in hybrid search alongside pgvector + tsvector."
---

## What it is

`pg_trgm` provides trigram (3-character substring) decomposition of text, with similarity operators and GIN/GIST index support. On Supabase it's the right tool for fuzzy keyword search, `ILIKE '%query%'` acceleration, and the keyword leg of hybrid search.

Source: [Postgres pg_trgm docs](https://www.postgresql.org/docs/current/pgtrgm.html).

## When to use

Use pg_trgm for:
- **Fuzzy text matching** ("did you mean..." suggestions).
- **`ILIKE '%query%'` acceleration** — a GIN index with `gin_trgm_ops` makes substring search fast.
- **Keyword leg of hybrid search** — combine with pgvector for semantic + lexical.

Don't use for:
- **Full-text search with ranking** — use `tsvector` + `to_tsquery` instead.
- **Exact equality lookups** — B-tree on the column is faster.
- **High-cardinality structured data** — pg_trgm shines on free text.

## 2025-2026 currency anchors

Stable. The Supabase-specific story is its **role in hybrid search alongside pgvector + tsvector** — see [pgvector](/stacks/supabase/pgvector/) for the combined query pattern.

## Patterns and anti-patterns

### Patterns

**Enable and index:**

```sql
create extension if not exists pg_trgm;

create index documents_content_trgm_idx
  on public.documents
  using gin (content gin_trgm_ops);
```

**ILIKE acceleration:**

```sql
select * from public.documents
where content ilike '%postgres%';
-- Uses the trgm GIN index.
```

**Similarity-ranked match:**

```sql
select *, similarity(content, 'postgres tuning') as score
from public.documents
where content % 'postgres tuning'  -- threshold-based filter
order by score desc
limit 10;
```

**Hybrid search — vector + trigram + tsvector (combined with [pgvector](/stacks/supabase/pgvector/)):**

```sql
with vec as (
  select id, 1 - (embedding <=> $1) as vec_score
  from public.documents
  order by embedding <=> $1 limit 50
),
fts as (
  select id, ts_rank_cd(ts, plainto_tsquery('english', $2)) as fts_score
  from public.documents
  where ts @@ plainto_tsquery('english', $2)
  order by fts_score desc limit 50
)
select d.id, d.content,
  coalesce(vec.vec_score, 0) * 0.6 + coalesce(fts.fts_score, 0) * 0.4 as score
from public.documents d
left join vec on d.id = vec.id
left join fts on d.id = fts.id
where vec.id is not null or fts.id is not null
order by score desc
limit 10;
```

### Anti-patterns

- **Trigram for full-text search with relevance** — `tsvector` is built for that; trgm is for substring/fuzzy.
- **No GIN index** — `ILIKE '%foo%'` without a trgm GIN index is a sequential scan.
- **`similarity_threshold` left at default** without tuning — defaults often return too many noisy matches.

## Gotchas

- **Index build time on large tables** — trigram GIN indexes are larger and slower to build than B-tree.
- **GIN vs GIST** — GIN is faster to query, GIST is faster to update. For mostly-read corpora, GIN wins.
- **Trigrams are character-level**, not word-level — works across languages with Latin-ish alphabets; non-Latin scripts may need different tokenization.
- **Combining `<%` (word similarity) vs `%` (similarity)** — different operators with different semantics; check docs.

## Cross-references

- [pgvector](/stacks/supabase/pgvector/) — pairs for hybrid search
- [ai-ml-engineer role view](/stacks/supabase/ai-ml-engineer/) — hybrid retrieval patterns
- [database-architect role view](/stacks/supabase/database-architect/) — extension strategy
- Postgres docs: [pg_trgm](https://www.postgresql.org/docs/current/pgtrgm.html)
