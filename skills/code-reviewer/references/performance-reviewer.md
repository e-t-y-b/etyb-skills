# Performance Reviewer — Deep Reference

**Always use `WebSearch` to verify current tool versions, benchmark data, and framework-specific performance advice before making recommendations. Performance characteristics change with language/framework updates — what was slow in v1 might be optimized in v2.**

## Table of Contents
1. [Algorithmic Complexity in Code Review](#1-algorithmic-complexity-in-code-review)
2. [N+1 Query Detection](#2-n1-query-detection)
3. [Database Query Performance](#3-database-query-performance)
4. [Memory Leak Detection](#4-memory-leak-detection)
5. [Frontend Performance (React and Beyond)](#5-frontend-performance-react-and-beyond)
6. [Backend Performance Patterns](#6-backend-performance-patterns)
7. [Profiling Tools by Language](#7-profiling-tools-by-language)
8. [Performance Budgets](#8-performance-budgets)
9. [Concurrency and Parallelism Pitfalls](#9-concurrency-and-parallelism-pitfalls)
10. [Language-Specific Performance Pitfalls](#10-language-specific-performance-pitfalls)
11. [Performance Review Checklist](#11-performance-review-checklist)

---

## 1. Algorithmic Complexity in Code Review

### What to Look For

Most real-world performance issues don't come from choosing quicksort vs mergesort — they come from accidentally quadratic (or worse) code in data processing pipelines.

**Common O(n^2) patterns hiding in plain sight**:

```
# Pattern 1: Nested loops over the same collection
for user in users:
    for other in users:  # O(n^2)
        if user.id != other.id and user.email == other.email:
            duplicates.append(user)

# Fix: Use a set/dict for O(n)
email_map = defaultdict(list)
for user in users:
    email_map[user.email].append(user)
duplicates = [u for users in email_map.values() if len(users) > 1 for u in users]
```

```
# Pattern 2: Repeated linear search
for item in cart_items:
    product = next(p for p in products if p.id == item.product_id)  # O(n) each time
    # Total: O(n*m)

# Fix: Build a lookup map
product_map = {p.id: p for p in products}  # O(m) once
for item in cart_items:
    product = product_map[item.product_id]  # O(1) each time
    # Total: O(n+m)
```

```
# Pattern 3: String concatenation in a loop
result = ""
for line in lines:
    result += line + "\n"  # Creates a new string each iteration — O(n^2) total

# Fix: Use join
result = "\n".join(lines)  # O(n) total
```

```
# Pattern 4: Sorting inside a loop
for category in categories:
    items = get_items(category)
    items.sort()  # O(m log m) * n categories = O(nm log m)
    top_item = items[0]

# Fix: Use min() — O(m) per category
for category in categories:
    top_item = min(get_items(category))  # O(m) * n = O(nm)
```

```
# Pattern 5: Array operations that should be set operations
blocked_ids = [user.id for user in blocked_users]  # list
for comment in comments:
    if comment.author_id in blocked_ids:  # O(n) membership test on list
        hide(comment)

# Fix: Use a set
blocked_ids = {user.id for user in blocked_users}  # set
for comment in comments:
    if comment.author_id in blocked_ids:  # O(1) membership test
        hide(comment)
```

### Big-O Quick Reference for Review

| Operation | Array/List | Hash Map/Set | Sorted Array | Balanced BST |
|-----------|-----------|-------------|-------------|-------------|
| Search | O(n) | O(1) avg | O(log n) | O(log n) |
| Insert | O(1) append, O(n) middle | O(1) avg | O(n) | O(log n) |
| Delete | O(n) | O(1) avg | O(n) | O(log n) |
| Membership | O(n) | O(1) avg | O(log n) | O(log n) |
| Min/Max | O(n) | O(n) | O(1) | O(log n) |

### When Complexity Matters vs. When It Doesn't

- **Dataset < 100 items**: Almost any algorithm is fine. Don't optimize.
- **Dataset 100 - 10K**: O(n^2) starts mattering. Watch for it.
- **Dataset 10K - 1M**: O(n^2) is unacceptable. O(n log n) minimum.
- **Dataset > 1M**: Even O(n) with a high constant factor matters. Consider streaming.

Always ask: what's the *expected* data size, and what's the *worst case*? A user list might be 50 today and 50,000 next year.

---

## 2. N+1 Query Detection

### The Problem

An N+1 query bug occurs when code executes 1 query to fetch a list of N items, then executes N additional queries to fetch related data for each item. With N=1000, you get 1001 database queries instead of 2.

### How to Spot It in Code Review

**ORM red flags** (the code looks clean but hides N queries):

```python
# Django — N+1 (each user.profile triggers a query)
users = User.objects.all()
for user in users:
    print(user.profile.bio)  # 💥 N queries

# Fix: select_related (for ForeignKey/OneToOne — uses JOIN)
users = User.objects.select_related('profile').all()

# Fix: prefetch_related (for ManyToMany/reverse FK — uses 2 queries)
users = User.objects.prefetch_related('posts').all()
```

```ruby
# Rails — N+1 (each post.comments triggers a query)
posts = Post.all
posts.each { |post| post.comments.count }  # 💥 N queries

# Fix: includes (eager loading)
posts = Post.includes(:comments).all

# Fix: counter_cache for counts
# In Comment model: belongs_to :post, counter_cache: true
```

```java
// JPA/Hibernate — N+1 (lazy loading is the default)
List<Order> orders = orderRepo.findAll();
for (Order order : orders) {
    order.getItems().size();  // 💥 N queries (lazy fetch)
}

// Fix: JOIN FETCH in JPQL
@Query("SELECT o FROM Order o JOIN FETCH o.items")
List<Order> findAllWithItems();

// Fix: EntityGraph
@EntityGraph(attributePaths = {"items"})
List<Order> findAll();
```

```typescript
// Prisma — N+1
const users = await prisma.user.findMany();
for (const user of users) {
    const posts = await prisma.post.findMany({ where: { authorId: user.id } }); // 💥
}

// Fix: include
const users = await prisma.user.findMany({ include: { posts: true } });
```

### Detection Tools

| Tool | Language/Framework | Detection Method |
|------|-------------------|-----------------|
| **Django Debug Toolbar** | Django | Shows all queries per request with duplicates highlighted |
| **django-silk** | Django | Profiling middleware with query analysis |
| **nplusone** | Python (Django, SQLAlchemy) | Raises errors on N+1 in dev/test |
| **Bullet** | Ruby (Rails) | Detects N+1 and unused eager loading |
| **Hibernate Statistics** | Java | Logs query counts per session |
| **Sentry Performance** | Any | Automatic N+1 detection in production |
| **MiniProfiler** | .NET, Ruby | In-page query profiler |

### The DataLoader Pattern (GraphQL)

For GraphQL APIs, the DataLoader pattern batches individual requests into bulk queries:

```javascript
// Without DataLoader: N+1 for each user's posts
resolve(user) {
    return db.query('SELECT * FROM posts WHERE author_id = ?', [user.id]); // N queries
}

// With DataLoader: batched into one query
const postLoader = new DataLoader(async (userIds) => {
    const posts = await db.query('SELECT * FROM posts WHERE author_id IN (?)', [userIds]);
    return userIds.map(id => posts.filter(p => p.authorId === id));
});
resolve(user) {
    return postLoader.load(user.id); // Batched: 1 query for all users
}
```

---

## 3. Database Query Performance

### EXPLAIN Plan Review

When reviewing database queries, request or check EXPLAIN output for queries that touch large tables or run frequently.

**PostgreSQL EXPLAIN key indicators**:

| Indicator | Warning Sign | Action |
|-----------|-------------|--------|
| **Seq Scan** on large table | Missing index | Add index on filtered/joined columns |
| **Nested Loop** with large outer table | Potential O(n^2) | Check if Hash Join or Merge Join is possible |
| **Sort** with high cost | Sorting large result set | Add index matching ORDER BY |
| **Hash Join** with large hash table | High memory usage | Consider reducing result set before join |
| **Rows estimated vs actual** far apart | Stale statistics | Run ANALYZE |
| **Filter: removes most rows** | Query reads far more than it returns | Tighter WHERE clause or better index |

### Common Query Anti-Patterns

| Anti-Pattern | Example | Fix |
|-------------|---------|-----|
| **SELECT *** | `SELECT * FROM users` | Select only needed columns |
| **Missing LIMIT** | Fetching all rows when displaying 20 | Add `LIMIT` and pagination |
| **Function on indexed column** | `WHERE LOWER(email) = 'foo'` | Functional index or store lowercase |
| **Implicit type conversion** | `WHERE id = '123'` (id is int) | Use matching types |
| **OR on different columns** | `WHERE email = x OR phone = y` | Use UNION or separate indexes |
| **NOT IN with NULLs** | `WHERE id NOT IN (SELECT nullable_col...)` | Use `NOT EXISTS` instead |
| **LIKE with leading wildcard** | `WHERE name LIKE '%smith'` | Full-text search or trigram index |
| **Unnecessary DISTINCT** | Covering up a join that produces duplicates | Fix the join instead |
| **Correlated subquery** | Subquery referencing outer query | Convert to JOIN |

### Index Review Checklist

- [ ] Foreign key columns are indexed
- [ ] Columns used in WHERE clauses have appropriate indexes
- [ ] Composite indexes match query patterns (leftmost prefix rule)
- [ ] No redundant indexes (index on `(a, b)` covers queries on `a`)
- [ ] Covering indexes for frequently-run queries
- [ ] Partial indexes for queries on subsets (`WHERE status = 'active'`)
- [ ] Index bloat is monitored (especially after bulk updates/deletes)

---

## 4. Memory Leak Detection

### Language-Specific Memory Leak Patterns

**JavaScript/Node.js**:

| Leak Pattern | How It Happens | Detection |
|-------------|---------------|-----------|
| Event listener accumulation | Adding listeners without removing on cleanup | Chrome DevTools → Event Listeners panel |
| Closures holding references | Closure captures large object, prevents GC | Heap snapshot comparison |
| Detached DOM trees | DOM elements removed from page but referenced in JS | Chrome DevTools → Detached elements |
| Unbounded caches/maps | Map/object grows without eviction | Monitor heap growth over time |
| Timer accumulation | `setInterval` without `clearInterval` | Search codebase for uncleared intervals |
| React effect cleanup | Missing cleanup in `useEffect` return | ESLint `react-hooks/exhaustive-deps` |

**Detection tools**: Chrome DevTools Heap Snapshots (take 3 snapshots: initial, after operations, after GC — compare retained sizes), clinic.js (Node.js), memwatch-next.

**Python**:
- Circular references preventing GC (CPython uses reference counting + cycle collector, but cycles with `__del__` are problematic)
- Global state accumulation (module-level lists/dicts that grow)
- Unclosed file handles and database connections
- Large objects in closures/callbacks
- Detection: objgraph (visualize object growth), tracemalloc (track allocations), memory_profiler (`@profile` decorator)

**Go**:
- Goroutine leaks (goroutine blocked forever on channel, no cancellation)
- Slice header retaining large backing array (`a = bigSlice[:10]` — the full array stays in memory)
- Finalizer misuse
- Detection: `pprof` heap profiles, `runtime.NumGoroutine()` monitoring

**Java**:
- Static collections that grow (class-level `List` or `Map`)
- Unclosed resources (streams, connections)
- Custom classloaders preventing class unloading
- String interning of user data
- Detection: JFR (Java Flight Recorder), VisualVM heap analysis, async-profiler

---

## 5. Frontend Performance (React and Beyond)

### React Performance Review

**Unnecessary Re-Renders** — the most common React performance issue:

| Pattern | Problem | Fix |
|---------|---------|-----|
| Inline object/function in JSX | New reference every render → child re-renders | Extract to variable, use `useMemo`/`useCallback` |
| Context wrapping entire app | Any context change re-renders all consumers | Split contexts by update frequency |
| State too high in tree | State change re-renders large subtree | Lift state down, use composition |
| Missing `key` on lists | React can't track items, re-renders everything | Use stable unique IDs (not array index for dynamic lists) |
| Props drilling causing cascading renders | Parent re-render → all children re-render | Use React.memo(), component composition, or state management |

**React 19 / React Compiler**: The React Compiler automatically memoizes components and values, making `React.memo`, `useMemo`, and `useCallback` unnecessary in many cases. If the project uses React 19+ with the compiler, don't suggest manual memoization unless profiling shows the compiler isn't handling it.

### Bundle Size Review

**What to check**:
- Large dependencies imported entirely (`import _ from 'lodash'` → `import get from 'lodash/get'`)
- Missing tree shaking (barrel file re-exports can prevent tree shaking)
- Missing code splitting (`React.lazy()` / dynamic `import()` for routes)
- Heavy polyfills for modern browsers
- Development dependencies in production bundle
- Duplicate dependencies (different versions of the same package)

**Tools**: Webpack Bundle Analyzer, source-map-explorer, `next build` output analysis, `import-cost` VS Code extension.

**Budget thresholds** (general guidance):
| Metric | Budget | Rationale |
|--------|--------|-----------|
| Initial JS (compressed) | < 200 KB | First load performance |
| Per-route chunk | < 50 KB | Navigation speed |
| Total JS | < 500 KB | Memory and parse time |
| Largest image | < 200 KB | LCP impact |

### Core Web Vitals During Review

| Metric | What It Measures | Target | Code Review Signal |
|--------|-----------------|--------|-------------------|
| **LCP** (Largest Contentful Paint) | Loading speed | < 2.5s | Missing image optimization, render-blocking resources, no lazy loading |
| **INP** (Interaction to Next Paint) | Responsiveness | < 200ms | Long synchronous operations on main thread, missing `startTransition` |
| **CLS** (Cumulative Layout Shift) | Visual stability | < 0.1 | Missing width/height on images, dynamic content insertion above fold |

---

## 6. Backend Performance Patterns

### Connection Pooling

**Why it matters**: Database connection establishment takes 20-100ms (TCP + TLS + authentication). Without pooling, every request pays this cost. With pooling, connections are reused.

**What to review**:
- Pool exists (don't create new connections per request)
- Pool size is configured appropriately (not too small → queuing, not too large → exhausting DB connections)
- Connection idle timeout is set (prevent stale connections)
- Connection validation on borrow (health check before use)

**Defaults by framework**:
| Framework | Default Pool | Recommended Starting Config |
|-----------|-------------|----------------------------|
| Django | Per-request by default | `CONN_MAX_AGE=600`, or django-db-connection-pool |
| Rails | 5 connections | Pool size = `puma_threads + headroom` |
| Spring Boot | HikariCP (10 connections) | Good default, tune `maximumPoolSize` |
| Go `database/sql` | Unlimited by default | Set `SetMaxOpenConns`, `SetMaxIdleConns` |
| Node.js pg | 10 connections | Tune for expected concurrency |

### Caching Strategy Review

**What to check in review**:
- Is there a caching layer for expensive operations? (database queries, API calls, computations)
- Is the cache invalidation strategy correct? (stale data is worse than no cache)
- Are cache keys specific enough? (avoid cache pollution between users/tenants)
- Is cache TTL appropriate? (too long → stale data, too short → cache thrashing)
- Is there a thundering herd protection? (mutex/singleflight for cache misses)

**Cache patterns**:
| Pattern | How It Works | Best For |
|---------|-------------|----------|
| **Cache-Aside** | App checks cache, falls back to DB, populates cache | General purpose, read-heavy |
| **Write-Through** | Write to cache and DB simultaneously | Consistency-critical |
| **Write-Behind** | Write to cache, async write to DB | High write throughput |
| **Read-Through** | Cache fetches from DB on miss | CDN, proxy caches |

### Async and Non-Blocking Patterns

**What to check**:
- Synchronous I/O in async code paths (blocking the event loop / thread pool)
- Missing pagination on database queries (fetching all records when the consumer only needs a page)
- Sequential requests that could be parallel (`Promise.all()` / `asyncio.gather()`)
- Missing timeouts on external calls (network requests without deadline)
- Unbounded queues (producer faster than consumer → memory growth)

---

## 7. Profiling Tools by Language

### When to Recommend Profiling vs. Code Review

If a performance concern is obvious from reading the code (O(n^2), N+1 query, missing index), flag it in review. If it's ambiguous ("is this slow enough to matter?"), recommend profiling to validate before optimizing.

| Language | CPU Profiler | Memory Profiler | Tracing | Continuous |
|----------|-------------|----------------|---------|------------|
| **JS/Node** | Chrome DevTools, clinic.js | Chrome Heap Snapshots, heapdump | Chrome Trace, node `--trace` | Datadog, Sentry |
| **Python** | py-spy (sampling, no code change), cProfile | memory_profiler, tracemalloc, objgraph | OpenTelemetry | Datadog, Sentry |
| **Go** | pprof CPU profile | pprof heap profile | `runtime/trace`, OpenTelemetry | Parca, Polar Signals |
| **Java** | async-profiler, JFR | JFR, VisualVM | OpenTelemetry, Zipkin | Datadog, Pyroscope |
| **Rust** | cargo-flamegraph, perf | Valgrind (massif) | tracing crate | Custom |

### Reading Flame Graphs

Flame graphs are the most useful profiling visualization for identifying bottlenecks:
- **Width** = time spent (wider = more time)
- **Height** = call depth (deeper = more nested calls)
- **Plateaus** = functions consuming significant time
- Look for wide bars that *aren't* your code (framework overhead)
- Look for unexpected deep call stacks (excessive recursion, unnecessary abstraction layers)

---

## 8. Performance Budgets

### Setting Budgets for Different Application Types

| App Type | LCP | INP | JS Bundle (initial) | API Response (p95) | Database Query (p95) |
|----------|-----|-----|--------------------|--------------------|---------------------|
| E-commerce | < 2.0s | < 150ms | < 150 KB | < 200ms | < 50ms |
| SaaS Dashboard | < 2.5s | < 200ms | < 300 KB | < 500ms | < 100ms |
| Content/Blog | < 1.5s | < 100ms | < 100 KB | < 200ms | < 50ms |
| Internal Tool | < 3.0s | < 300ms | < 500 KB | < 1s | < 200ms |

### CI Enforcement

- **Bundle size**: `bundlesize` or `size-limit` npm packages — fail CI if bundle exceeds budget
- **Lighthouse CI**: Run Lighthouse in CI, fail on Core Web Vitals regression
- **Database query count**: Log query count per request in tests, fail if it exceeds threshold
- **API response time**: Load test in CI with p95 threshold gates

---

## 9. Concurrency and Parallelism Pitfalls

### What to Look For in Review

**Race conditions**:
- Shared mutable state accessed from multiple threads/goroutines without synchronization
- Read-modify-write operations that aren't atomic (check-then-act)
- Go: Missing mutex, use `-race` flag in tests
- Java: Non-synchronized access to shared collections, missing `volatile`
- Python: GIL doesn't protect against all races — `threading` + shared data still needs locks
- JavaScript: Single-threaded, but async operations can interleave (race between `await` calls)

**Deadlocks**:
- Lock ordering inconsistency (Thread A locks X then Y, Thread B locks Y then X)
- Holding locks across async boundaries
- Database deadlocks from conflicting transaction order

**Goroutine/Thread leaks**:
- Go: Goroutines blocked on channels with no sender, missing `context.WithCancel`
- Java: Thread pool threads blocked indefinitely
- Node.js: Promise chains that never resolve

---

## 10. Language-Specific Performance Pitfalls

### JavaScript/TypeScript

| Pitfall | Impact | Fix |
|---------|--------|-----|
| `JSON.parse(JSON.stringify(obj))` for deep clone | Slow, doesn't handle special types | `structuredClone()` (built-in) |
| `Array.prototype.find()` in a loop | O(n^2) | Build a Map for lookups |
| Regex creation inside loops | Re-compilation each iteration | Create regex outside loop |
| `delete obj.prop` | Deoptimizes V8 hidden classes | Set to `undefined` or use Map |
| `forEach` with async callbacks | Doesn't await — all fire at once | Use `for...of` with `await` |

### Python

| Pitfall | Impact | Fix |
|---------|--------|-----|
| `+` string concatenation in loop | O(n^2) | `"".join(parts)` or f-strings |
| `list.append` in comprehension-eligible code | Slower, more verbose | Use list comprehension |
| Global variable access in tight loops | Slower than local | Assign to local variable |
| Not using `__slots__` for data classes with many instances | Higher memory per instance | Add `__slots__` or use `@dataclass(slots=True)` |
| Synchronous I/O in async context | Blocks event loop | Use async libraries (aiohttp, asyncpg) |

### Go

| Pitfall | Impact | Fix |
|---------|--------|-----|
| String concatenation in loop | O(n^2) | `strings.Builder` |
| Unnecessary `interface{}` boxing | Allocation overhead, no type safety | Use generics (Go 1.18+) |
| Large struct passed by value | Copy overhead | Pass pointer `*Struct` |
| Unbuffered channels in producer-consumer | Goroutine blocking | Size buffer appropriately |
| `defer` in tight loop | Accumulated defer overhead | Move defer outside loop |

### Java

| Pitfall | Impact | Fix |
|---------|--------|-----|
| Autoboxing in tight loops | Allocation churn, GC pressure | Use primitive types |
| `String.format()` in hot paths | Slow formatting | StringBuilder or concatenation |
| Stream API for tiny collections | Overhead exceeds benefit for < 100 elements | Simple loop |
| Synchronized on every method | Excessive contention | Lock striping or concurrent collections |
| Creating `Pattern` inside loop | Re-compilation each iteration | Compile once as static field |

---

## 11. Performance Review Checklist

### Algorithmic
- [ ] No accidentally quadratic (or worse) code paths
- [ ] Appropriate data structures for the access patterns (hash maps for lookups, not linear search)
- [ ] No sorting where min/max would suffice
- [ ] String building uses efficient patterns (join, StringBuilder)
- [ ] Set/map used for membership testing, not list/array

### Database
- [ ] No N+1 queries (check for ORM lazy loading in loops)
- [ ] Queries have appropriate indexes (check EXPLAIN for large tables)
- [ ] No `SELECT *` — fetch only needed columns
- [ ] Pagination for potentially large result sets
- [ ] Connection pooling configured

### Frontend
- [ ] No unnecessary re-renders (check React DevTools Profiler)
- [ ] Code splitting for routes / large components
- [ ] Images optimized and lazy-loaded below fold
- [ ] No entire-library imports where tree-shakeable imports work
- [ ] Bundle size within budget

### Backend
- [ ] External calls have timeouts
- [ ] Expensive computations cached where appropriate
- [ ] No synchronous I/O blocking async event loops
- [ ] Requests that could be parallel aren't sequential
- [ ] Resource pools sized appropriately (DB connections, HTTP clients)

### Memory
- [ ] No unbounded growth (caches, queues, logs)
- [ ] Resources cleaned up (connections, file handles, event listeners)
- [ ] No closures/callbacks holding references to large objects
- [ ] No goroutine/thread leaks
