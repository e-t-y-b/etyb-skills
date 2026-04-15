# Python Backend Stack — Deep Reference

**Always use `WebSearch` to verify version numbers and features before giving advice. This reference provides architectural context; the ecosystem evolves rapidly.**

## Table of Contents
1. [Modern Python (3.12+)](#1-modern-python-312)
2. [Framework Decision Matrix](#2-framework-decision-matrix)
3. [FastAPI](#3-fastapi)
4. [Django](#4-django)
5. [Other Frameworks](#5-other-frameworks)
6. [ASGI vs WSGI](#6-asgi-vs-wsgi)
7. [Data Access](#7-data-access)
8. [Validation](#8-validation)
9. [Task Queues and Messaging](#9-task-queues-and-messaging)
10. [Testing](#10-testing)
11. [Type Checking and Tooling](#11-type-checking-and-tooling)
12. [Package Management](#12-package-management)
13. [Deployment](#13-deployment)
14. [Performance](#14-performance)
15. [When Python Shines](#15-when-python-shines)

---

## 1. Modern Python (3.12+)

### Python 3.12 (LTS-quality, supported through 2028)
- **Type Parameter Syntax (PEP 695)**: `def max[T](args: Iterable[T]) -> T`, `type Point = tuple[float, float]`
- **F-string overhaul**: Quote reuse, multi-line expressions with comments, backslashes allowed
- **Per-Interpreter GIL (PEP 684)**: Sub-interpreters with own GIL (C API only)
- **Performance**: asyncio ~75% faster, comprehensions ~2x faster via inlining

### Python 3.13 (October 2024)
- **Free-Threaded CPython (PEP 703)**: Experimental. Separate build `python3.13t`. Disable GIL via `PYTHON_GIL=0`. ~40% single-threaded penalty in this release.
- **Experimental JIT Compiler (PEP 744)**: Copy-and-patch JIT. Modest improvements, expected to grow.
- **New interactive REPL**: Multiline editing, color tracebacks, history
- **TypeIs (PEP 742)**: Better type narrowing than TypeGuard
- **ReadOnly TypedDict (PEP 705)**: Immutable TypedDict fields
- Removed 19 legacy modules (cgi, telnetlib, etc.)

### Python 3.14 (October 2025)
- **Deferred Annotations (PEP 649/749)**: Annotations evaluated lazily. Eliminates `from __future__ import annotations`.
- **Template Strings / t-strings (PEP 750)**: `t"Hello {name}"` returns `Template` object. Safe SQL, HTML, shell construction.
- **Multiple Interpreters (PEP 734)**: `concurrent.interpreters` in stdlib. True multi-core parallelism without GIL. CSP/actor-model concurrency.
- **Free-Threaded improvements**: Penalty reduced to 5-10%. Officially supported (PEP 779).
- **Incremental GC**: Reduces max GC pause by order of magnitude
- **Asyncio introspection**: `python -m asyncio ps PID` for live task inspection
- **Zstandard compression** in stdlib

### Free-Threaded Python (No-GIL) Timeline
- **3.13**: Experimental, ~40% penalty. Not production-ready.
- **3.14**: 5-10% penalty. Officially supported. Major libraries adding support.
- **3.17+ (est. 2028)**: Expected to become the default build.

---

## 2. Framework Decision Matrix

| Framework | Best For | Performance | DX | Ecosystem |
|-----------|---------|-------------|-----|-----------|
| **FastAPI** | Modern APIs, microservices, ML serving | Excellent (async) | Excellent | Large, growing |
| **Django** | Full-stack apps, admin-heavy CRUD | Good | Excellent (batteries) | Largest |
| **Django Ninja** | FastAPI-like on Django | ~9x faster than DRF | Excellent | Medium |
| **Litestar** | Structured APIs, class-based | Excellent | Very good | Growing |
| **Flask** | Simple APIs, prototyping | Adequate | Simple | Large (legacy) |

### Quick Recommendation
- **Modern API / microservice**: FastAPI
- **Full-stack web app with admin**: Django
- **Django project needing fast APIs**: Django Ninja
- **More structure than FastAPI**: Litestar
- **Simple prototype**: Flask

---

## 3. FastAPI

### Key Strengths
- **Async-first** built on Starlette and Pydantic
- **Auto-generated OpenAPI/Swagger** docs from type annotations
- **Pydantic v2 integration**: Rust-powered validation, 5-50x faster than v1
- **Dependency injection**: Clean DI system for auth, DB sessions, pagination
- **Performance**: Comparable to Node.js/Go for I/O-bound workloads
- **SSE support** (v0.135+): Native Server-Sent Events streaming
- **JSON serialization**: Via Pydantic's Rust core — faster than orjson

### Pattern
```python
from fastapi import FastAPI, Depends
from pydantic import BaseModel

app = FastAPI()

class UserCreate(BaseModel):
    name: str
    email: str

@app.post("/users")
async def create_user(user: UserCreate, db=Depends(get_db)):
    return await db.create_user(user)
```

### When to Use
- New API projects, microservices
- ML model serving (FastAPI + PyTorch/transformers)
- Real-time applications (WebSocket, SSE)
- Any project where auto-generated API docs save time

---

## 4. Django

### Latest (5.2 LTS, April 2025)
- Composite primary keys, automatic model imports in shell
- Async views/middleware/ORM maturing across 4.1-5.x
- Generated fields, facet filters in admin

### Django API Options
- **Django Ninja**: Pydantic-powered, ~9x faster than DRF. FastAPI-like DX on Django.
- **Django REST Framework** (DRF): Battle-tested. Serializers, viewsets, routers. Massive ecosystem.

### When to Use
- Full-featured web apps with admin panel
- Content management systems
- Projects needing batteries-included auth/ORM/admin/migrations
- Internal tools (admin UI in hours not weeks)

---

## 5. Other Frameworks

### Litestar (v2.x, formerly Starlite)
- High-performance ASGI with class-based controllers
- Built-in DTO layer, session/cache/rate-limiting middleware
- SQLAlchemy plugin, msgspec support (faster than Pydantic)
- Own ASGI implementation (not Starlette)

### Flask (3.x)
- Minimal, flexible, maximum control
- Async views supported but not truly async-native (WSGI)
- Flask-RESTX for Swagger, Flask-Smorest for marshmallow
- Best for: simple APIs, rapid prototyping, legacy projects

### Starlette (v1.0)
- Lightweight ASGI foundation (FastAPI is built on it)
- Use when: building custom frameworks or need ASGI primitives

---

## 6. ASGI vs WSGI

| Factor | WSGI | ASGI |
|--------|------|------|
| I/O model | Synchronous | Async-native |
| Concurrency | Thread per request | Event loop (thousands concurrent) |
| WebSocket | No | Yes |
| Frameworks | Flask, Django (traditional) | FastAPI, Starlette, Django (async), Litestar |

### ASGI Servers
- **Uvicorn**: Standard for FastAPI/Starlette. Based on uvloop + httptools.
- **Gunicorn + UvicornWorker**: Production pattern. `gunicorn -w 4 -k uvicorn.workers.UvicornWorker`
- **Granian**: Rust-based, 30-80% higher throughput than Uvicorn. Handles process management + ASGI.
- **Hypercorn**: HTTP/1, HTTP/2, HTTP/3 (QUIC) support.

### Production Pattern
```
Internet → Reverse Proxy (nginx/Caddy) → Gunicorn (process manager) → Uvicorn workers → FastAPI app
```
Or simpler with Granian:
```
Internet → Reverse Proxy → Granian (Rust-based, all-in-one) → FastAPI app
```
Workers rule of thumb: `2 * CPU_CORES + 1`

---

## 7. Data Access

### SQLAlchemy 2.0
- Complete rewrite of query API: `select(User).where(User.name == "alice")`
- **Full async support**: `create_async_engine()`, `AsyncSession`, asyncpg/aiosqlite
- **Typed columns**: `Mapped[T]` with mapped_column for mypy/pyright
- Built-in connection pooling
- Best for: complex queries, multiple DB support, mature projects

### SQLModel
- By FastAPI's author. Combines SQLAlchemy + Pydantic in single model.
- One model serves as both DB entity and API schema.
- Best for: FastAPI projects wanting minimal boilerplate. Pre-1.0, less battle-tested.

### Django ORM
- Async support maturing: `await QuerySet.aget()`, `async for`, async managers
- Generated fields (5.0), composite primary keys (5.2)
- Tight admin integration, migrations built-in

### Tortoise ORM
- Async-native, Django-like API, Aerich for migrations
- Best for: async-first projects preferring Django ORM syntax without Django

### Alembic
- Standard migration tool for SQLAlchemy/SQLModel
- Autogenerate migrations from model changes, async engine support

---

## 8. Validation

### Pydantic v2
- **Rust-powered core**: 5-50x faster than v1
- Strict/lax mode, computed fields, JSON Schema generation
- `model_dump()`, `model_dump_json()` with Rust-powered serialization
- **Default choice** for Python data validation. Industry standard.

### Alternatives
- **msgspec**: C-based, 2-5x faster than Pydantic for serialization. Struct types. Litestar native.
- **attrs**: Mature class creation library. Validators, slots, converters. Library development.
- **dataclasses** (stdlib): Simple containers, zero dependencies, no validation.

---

## 9. Task Queues and Messaging

### Celery (v5.5+)
- Industry standard distributed task queue
- Redis, RabbitMQ, SQS backends
- Canvas workflow primitives: chain, group, chord
- No native async. Heavy dependencies. Battle-tested reliability.

### Lighter Alternatives
- **Dramatiq**: Simpler API, better defaults than Celery. Redis/RabbitMQ.
- **ARQ**: Async Redis queue. Lightweight, async-native. Good for FastAPI.
- **Huey**: Minimal dependencies. Redis/SQLite/in-memory backends.

### Kafka
- **confluent-kafka-python**: Highest performance (librdkafka wrapper)
- **aiokafka**: Async Kafka client for asyncio

---

## 10. Testing

### Core Stack
- **pytest**: De facto standard. Fixtures, parametrize, plugins ecosystem (1000+).
- **pytest-asyncio**: Async test support. Essential for FastAPI/async code.
- **HTTPX**: Async HTTP client for testing FastAPI apps. `AsyncClient(app=app)`.
- **factory_boy**: Test fixture generation. Django, SQLAlchemy integrations.
- **Testcontainers**: Real Docker containers (PostgreSQL, Redis, Kafka) in tests.
- **coverage.py + pytest-cov**: Code coverage measurement.

### FastAPI Testing Pattern
```python
from httpx import AsyncClient, ASGITransport

async def test_create_user():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        response = await ac.post("/users", json={"name": "Alice", "email": "alice@test.com"})
    assert response.status_code == 200
```

---

## 11. Type Checking and Tooling

### Type Checkers
- **mypy**: Most established. Strict mode, plugins for Django/SQLAlchemy. Can be slow.
- **Pyright**: Microsoft's, faster than mypy. Powers VS Code Pylance. Better inference.
- **basedpyright**: Community fork with extra strict rules.

### Ruff (Astral)
- **Rust-powered linter + formatter**. Replaces flake8, isort, black, and 50+ tools.
- 10-100x faster than flake8/black. 800+ rules.
- `ruff check` + `ruff format`. **Use on every Python project.**

### Type Annotation Best Practices (3.12+)
- `X | Y` union syntax (not `Union[X, Y]`)
- `list[int]` lowercase generics (not `List[int]`)
- PEP 695 syntax: `def func[T](x: T) -> T`
- `type` statement for aliases: `type Vector = list[float]`

---

## 12. Package Management

### uv (Astral) — Recommended Default
- **Rust-powered**, 10-100x faster than pip
- Package install, venv management, lockfiles, Python version management
- `uv init`, `uv add`, `uv run`, `uv sync`
- Rapidly becoming the standard (2025-2026)

### Alternatives
- **Poetry**: Mature, `pyproject.toml`-based. Slower than uv. Good for existing projects.
- **pip**: Standard, ships with Python. No lockfile (use pip-tools).
- **Hatch**: PyPA-backed. Build backend + environment management.
- **Rye**: Deprecated in favor of uv. Don't start new projects with it.

---

## 13. Deployment

### Docker
```dockerfile
FROM python:3.13-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
WORKDIR /app
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev
COPY . .

FROM python:3.13-slim
WORKDIR /app
COPY --from=builder /app /app
USER nobody
CMD ["granian", "app:app", "--interface", "asgi", "--host", "0.0.0.0", "--port", "8000"]
```

### Serverless (AWS Lambda)
- **Mangum**: ASGI adapter for Lambda + API Gateway
- **AWS Lambda Web Adapter**: AWS-provided, any web framework on Lambda
- Cold starts: ~200-800ms depending on package size

### Containers
- **Cloud Run**: Excellent for ASGI apps, scales to zero, handles TLS
- **ECS/Fargate**: AWS container orchestration
- **Kubernetes**: Deploy as Deployment with health probes

---

## 14. Performance

### async/await
- **I/O-bound**: async shines (DB queries, HTTP calls). Single thread handles thousands concurrent.
- **CPU-bound**: async does NOT help. Use `ProcessPoolExecutor`, `concurrent.interpreters` (3.14), or free-threaded Python.
- **Pitfall**: Blocking calls in async code. Use `run_in_executor` for sync libraries.

### Key Tools
- **uvloop**: Drop-in asyncio replacement, 2-4x faster. Used by Uvicorn.
- **Connection pooling**: SQLAlchemy built-in pool, asyncpg pool, redis ConnectionPool
- **Profiling**: py-spy (CPU, zero overhead, flame graphs), memray (memory), Scalene (CPU+memory+GPU)

### Python vs Other Languages
- **I/O-bound APIs**: Comparable to Node.js/Go with async FastAPI
- **CPU-bound**: Slower than Go/Java/Rust. Free-threaded Python narrowing the gap.
- **ML serving**: Python is the only practical choice (PyTorch, transformers ecosystem)
- **Dev velocity**: Fastest time-to-working-API of any language

---

## 15. When Python Shines

### ML/AI Model Serving
FastAPI + PyTorch/transformers/vLLM is the standard pattern. Python owns the ML ecosystem.

### Data Pipelines
Airflow, Prefect, Dagster for orchestration. Pandas/Polars for transformation. Unmatched ecosystem.

### Rapid Prototyping
Django admin = instant CRUD UI. FastAPI = API in minutes with auto-docs.

### Django Admin for CRUD Apps
Auto-generated admin from models. Customizable list views, filters, search, inline editing. Internal tools in hours.

### Where Python is NOT Best
- **Ultra-low latency** (<1ms): Use Go, Rust, or C++
- **Extreme concurrency** (millions of connections): Go goroutines or Rust tokio
- **CPU-intensive at scale**: Go/Rust (though free-threaded Python is improving)
- **Mobile/embedded**: Not Python's domain

---

## Recommended Stack (2025-2026)

| Layer | Recommended | Alternative |
|-------|------------|-------------|
| Python | 3.13 (stable) / 3.14 (latest) | 3.12 (widely supported) |
| Package manager | uv | Poetry (existing projects) |
| Linter/Formatter | Ruff | — |
| Type checker | Pyright | mypy |
| Web framework | FastAPI (APIs) / Django (full-stack) | Litestar, Django Ninja |
| ASGI server | Granian or Gunicorn+Uvicorn | Hypercorn |
| ORM | SQLAlchemy 2.0 (async) | Django ORM, SQLModel |
| Validation | Pydantic v2 | msgspec |
| Migrations | Alembic | Django migrations |
| Task queue | Celery (complex) / ARQ (simple async) | Dramatiq |
| Testing | pytest + pytest-asyncio + httpx | Testcontainers |
| Profiling | py-spy + memray | Scalene |
