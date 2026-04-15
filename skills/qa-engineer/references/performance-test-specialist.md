# Performance Test Specialist — Deep Reference

**Always use `WebSearch` to verify current tool versions, cloud pricing, and framework updates before giving performance testing advice. k6, Artillery, and cloud load testing services evolve rapidly.**

## Table of Contents
1. [Performance Testing Fundamentals](#1-performance-testing-fundamentals)
2. [Performance Test Framework Comparison](#2-performance-test-framework-comparison)
3. [k6 — The Modern Default](#3-k6--the-modern-default)
4. [JMeter](#4-jmeter)
5. [Locust](#5-locust)
6. [Artillery](#6-artillery)
7. [Gatling](#7-gatling)
8. [Load Test Design](#8-load-test-design)
9. [Performance Test Types](#9-performance-test-types)
10. [Web Performance Testing](#10-web-performance-testing)
11. [Performance Testing in CI/CD](#11-performance-testing-in-cicd)
12. [Profiling and Bottleneck Identification](#12-profiling-and-bottleneck-identification)
13. [Distributed Load Testing](#13-distributed-load-testing)
14. [Database Performance Testing](#14-database-performance-testing)
15. [Performance Test Decision Framework](#15-performance-test-decision-framework)

---

## 1. Performance Testing Fundamentals

### Key Metrics

| Metric | What It Measures | Target (typical web app) |
|--------|-----------------|-------------------------|
| **Response time (p50)** | Median latency | < 200ms |
| **Response time (p95)** | Tail latency | < 500ms |
| **Response time (p99)** | Worst case (excl. outliers) | < 1s |
| **Throughput (RPS)** | Requests per second | Varies by capacity |
| **Error rate** | % of failed requests | < 0.1% under normal load |
| **Concurrent users** | Simultaneous active sessions | Varies by product |
| **TTFB** | Time to first byte | < 200ms |
| **Apdex score** | User satisfaction index (0-1) | > 0.9 |

### Performance Budget Example

```
API Endpoints:
  - GET /api/users/:id     → p95 < 50ms,  p99 < 100ms
  - POST /api/orders       → p95 < 200ms, p99 < 500ms
  - GET /api/search?q=...  → p95 < 300ms, p99 < 800ms

Web Vitals:
  - LCP  < 2.5s
  - FID  < 100ms (INP < 200ms)
  - CLS  < 0.1

Load Capacity:
  - 500 concurrent users with error rate < 0.1%
  - 1000 concurrent users with error rate < 1%
  - Graceful degradation above 1000 users
```

---

## 2. Performance Test Framework Comparison

### Framework Selection Matrix (2025-2026)

| Feature | k6 | JMeter | Locust | Artillery | Gatling |
|---------|-----|--------|--------|-----------|---------|
| **Language** | JavaScript/TS | XML/GUI + Java | Python | YAML/JS | Scala/Java/Kotlin |
| **Protocol** | HTTP, WS, gRPC, Browser | HTTP, WS, JDBC, JMS, FTP | HTTP, WS, custom | HTTP, WS, Socket.io | HTTP, WS, JMS |
| **Script as code** | Yes (native) | Limited (BeanShell/Groovy) | Yes (native) | YAML + JS | Yes (native) |
| **CI-friendly** | Excellent (CLI) | Good (CLI mode) | Good (headless) | Excellent (CLI) | Excellent (CLI) |
| **Distributed** | k6 Cloud, k6 Operator | JMeter distributed | Built-in distributed | Artillery Cloud | Gatling Enterprise |
| **Resource efficiency** | Very high (Go engine) | Low (JVM, heavy) | Medium (Python) | Medium (Node.js) | High (async, JVM) |
| **Learning curve** | Low (JS developers) | Medium (GUI) / High (scripting) | Low (Python developers) | Very low (YAML) | Medium (Scala DSL) |
| **Real browser** | k6 browser module | JMeter WebDriver plugin | No | Playwright integration | No |
| **Cost** | Free (OSS) + Cloud paid | Free (Apache 2.0) | Free (MIT) | Free + Cloud paid | Free + Enterprise paid |
| **Best for** | Modern teams, CI/CD | Enterprise, legacy | Python teams, simple scripts | Quick tests, YAML fans | Java/Scala teams |

### Quick Selection Guide

| Scenario | Recommendation |
|----------|---------------|
| Modern team, JS/TS stack, CI/CD | **k6** |
| Enterprise with existing JMeter | **Stay with JMeter** |
| Python team, simple load tests | **Locust** |
| Quick YAML-based tests, simple scenarios | **Artillery** |
| Java/Scala team, Gatling experience | **Gatling** |
| Need real browser rendering metrics | **k6 browser** or **Artillery + Playwright** |
| Budget: zero, no cloud dependency | **k6**, **Locust**, or **JMeter** |
| Managed cloud load testing | **k6 Cloud** (Grafana) or **Gatling Enterprise** |

---

## 3. k6 — The Modern Default

k6 is an open-source load testing tool built by Grafana Labs (v1.7.1, April 2026). Written in Go for performance, scripted in JavaScript/TypeScript. Since v1.0, k6 has first-class TypeScript support (no transpilation needed) and automatic extension resolution via imports.

### Basic Load Test

```javascript
// load-test.js
import http from 'k6/http'
import { check, sleep } from 'k6'
import { Rate, Trend } from 'k6/metrics'

// Custom metrics
const errorRate = new Rate('errors')
const orderDuration = new Trend('order_duration')

export const options = {
  stages: [
    { duration: '1m', target: 50 },    // ramp up to 50 users
    { duration: '3m', target: 50 },    // stay at 50 users
    { duration: '1m', target: 100 },   // ramp up to 100 users
    { duration: '3m', target: 100 },   // stay at 100 users
    { duration: '2m', target: 0 },     // ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],  // 95% of requests < 500ms
    http_req_failed: ['rate<0.01'],                   // error rate < 1%
    errors: ['rate<0.05'],
    order_duration: ['p(95)<800'],
  },
}

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000'

export default function () {
  // Browse products
  const productsRes = http.get(`${BASE_URL}/api/products`)
  check(productsRes, {
    'products status 200': (r) => r.status === 200,
    'products returned': (r) => JSON.parse(r.body).length > 0,
  })

  sleep(1) // think time

  // View product detail
  const products = JSON.parse(productsRes.body)
  const product = products[Math.floor(Math.random() * products.length)]
  http.get(`${BASE_URL}/api/products/${product.id}`)

  sleep(0.5)

  // Place order
  const orderStart = Date.now()
  const orderRes = http.post(
    `${BASE_URL}/api/orders`,
    JSON.stringify({
      items: [{ productId: product.id, quantity: 1 }],
    }),
    { headers: { 'Content-Type': 'application/json' } },
  )

  orderDuration.add(Date.now() - orderStart)
  errorRate.add(orderRes.status !== 201)

  check(orderRes, {
    'order created': (r) => r.status === 201,
    'order has id': (r) => JSON.parse(r.body).id !== undefined,
  })

  sleep(1)
}
```

### k6 Scenarios (Advanced)

```javascript
export const options = {
  scenarios: {
    // Scenario 1: Constant browsing load
    browse: {
      executor: 'constant-vus',
      vus: 50,
      duration: '10m',
      exec: 'browseProducts',
    },
    // Scenario 2: Ramping order placement
    orders: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 20 },
        { duration: '5m', target: 20 },
        { duration: '2m', target: 0 },
      ],
      exec: 'placeOrder',
    },
    // Scenario 3: Spike test
    spike: {
      executor: 'ramping-arrival-rate',
      startRate: 10,
      timeUnit: '1s',
      preAllocatedVUs: 200,
      stages: [
        { duration: '1m', target: 10 },
        { duration: '10s', target: 200 },   // sudden spike
        { duration: '3m', target: 200 },
        { duration: '10s', target: 10 },
        { duration: '1m', target: 10 },
      ],
      exec: 'browseProducts',
    },
  },
}

export function browseProducts() { /* ... */ }
export function placeOrder() { /* ... */ }
```

### k6 Browser Module

```javascript
import { browser } from 'k6/browser'

export const options = {
  scenarios: {
    ui: {
      executor: 'shared-iterations',
      options: { browser: { type: 'chromium' } },
    },
  },
  thresholds: {
    'browser_web_vital_lcp': ['p(95) < 2500'],
    'browser_web_vital_fid': ['p(95) < 100'],
    'browser_web_vital_cls': ['p(95) < 0.1'],
  },
}

export default async function () {
  const page = await browser.newPage()

  try {
    await page.goto('http://localhost:3000')
    await page.waitForSelector('.product-grid')

    // Interact like a real user
    await page.locator('.product-card:first-child').click()
    await page.waitForSelector('.product-detail')

    await page.locator('#add-to-cart').click()
    await page.waitForSelector('.cart-count')
  } finally {
    await page.close()
  }
}
```

### k6 Extensions

| Extension | Purpose |
|-----------|---------|
| `xk6-sql` | SQL database load testing |
| `xk6-kafka` | Kafka producer/consumer load testing |
| `xk6-redis` | Redis load testing |
| `xk6-grpc` | gRPC load testing |
| `xk6-dashboard` | Real-time HTML dashboard |
| `xk6-output-prometheus` | Push metrics to Prometheus |

---

## 4. JMeter

### When JMeter Is the Right Choice

- Enterprise environments with established JMeter expertise
- Need to test non-HTTP protocols (JDBC, JMS, LDAP, FTP, SMTP)
- GUI-based test creation for non-developers
- Existing test plans that work well

### JMeter DSL (Java)

For developers who prefer code over XML/GUI:

```java
import static us.abstracta.jmeter.javadsl.JmeterDsl.*;

public class PerformanceTest {
    @Test
    void loadTest() throws IOException {
        TestPlanStats stats = testPlan(
            threadGroup(50, 300,  // 50 threads, 300 iterations
                httpSampler("http://localhost:3000/api/products")
                    .method(HttpMethod.GET),
                uniformRandomTimer(1000, 3000),  // 1-3s think time
                httpSampler("http://localhost:3000/api/orders")
                    .method(HttpMethod.POST)
                    .body("{\"items\": [{\"productId\": 1, \"quantity\": 1}]}")
                    .contentType(ContentType.APPLICATION_JSON)
            ),
            htmlReporter("target/jmeter-report")
        ).run();

        assertThat(stats.overall().sampleTimePercentile99()).isLessThan(Duration.ofSeconds(1));
        assertThat(stats.overall().errorsCount()).isZero();
    }
}
```

---

## 5. Locust

### Python-Based Load Testing

```python
from locust import HttpUser, task, between, tag

class WebsiteUser(HttpUser):
    wait_time = between(1, 3)  # 1-3 seconds think time

    @tag('browse')
    @task(3)  # weight: 3x more likely than other tasks
    def browse_products(self):
        with self.client.get("/api/products", catch_response=True) as response:
            if response.status_code == 200:
                products = response.json()
                if len(products) == 0:
                    response.failure("No products returned")
            else:
                response.failure(f"Status {response.status_code}")

    @tag('browse')
    @task(2)
    def view_product(self):
        self.client.get("/api/products/1")

    @tag('order')
    @task(1)
    def place_order(self):
        self.client.post("/api/orders", json={
            "items": [{"productId": 1, "quantity": 1}]
        })

    def on_start(self):
        """Runs once per user at start — login, setup, etc."""
        self.client.post("/api/auth/login", json={
            "email": "test@example.com",
            "password": "password123",
        })
```

```bash
# CLI mode (headless, good for CI)
locust -f locustfile.py --headless -u 100 -r 10 --run-time 5m \
  --host http://localhost:3000 --csv results

# Web UI mode (interactive)
locust -f locustfile.py --host http://localhost:3000
# Open http://localhost:8089
```

---

## 6. Artillery

### YAML-Based Load Testing

```yaml
# artillery.yml
config:
  target: "http://localhost:3000"
  phases:
    - duration: 60
      arrivalRate: 5
      name: "Warm up"
    - duration: 300
      arrivalRate: 20
      name: "Sustained load"
    - duration: 60
      arrivalRate: 50
      name: "Peak"

  defaults:
    headers:
      Content-Type: "application/json"

  ensure:
    thresholds:
      - http.response_time.p95: 500
      - http.response_time.p99: 1000
      - http.codes.5xx: 0

scenarios:
  - name: "Browse and Order"
    weight: 70
    flow:
      - get:
          url: "/api/products"
          capture:
            - json: "$[0].id"
              as: "productId"
      - think: 2
      - get:
          url: "/api/products/{{ productId }}"
      - think: 1
      - post:
          url: "/api/orders"
          json:
            items:
              - productId: "{{ productId }}"
                quantity: 1

  - name: "Search"
    weight: 30
    flow:
      - get:
          url: "/api/search?q=widget"
```

```bash
artillery run artillery.yml
artillery run artillery.yml --output report.json
artillery report report.json  # generates HTML report
```

---

## 7. Gatling

### Scala DSL

```scala
class OrderSimulation extends Simulation {

  val httpProtocol = http
    .baseUrl("http://localhost:3000")
    .acceptHeader("application/json")
    .contentTypeHeader("application/json")

  val browse = scenario("Browse Products")
    .exec(http("List Products").get("/api/products"))
    .pause(1, 3)
    .exec(http("View Product").get("/api/products/1"))
    .pause(1)

  val order = scenario("Place Order")
    .exec(http("Create Order")
      .post("/api/orders")
      .body(StringBody("""{"items": [{"productId": 1, "quantity": 1}]}"""))
      .check(status.is(201))
    )

  setUp(
    browse.inject(rampUsers(100).during(60)),
    order.inject(rampUsers(20).during(60))
  ).protocols(httpProtocol)
    .assertions(
      global.responseTime.percentile(95).lt(500),
      global.successfulRequests.percent.gt(99)
    )
}
```

---

## 8. Load Test Design

### Key Parameters

| Parameter | Description | How to Set |
|-----------|-------------|-----------|
| **Virtual Users (VUs)** | Simulated concurrent users | Start from production analytics (peak concurrent sessions) |
| **Ramp-up time** | Time to reach target VUs | 10-20% of total test duration |
| **Think time** | Pause between actions | Measure from real user behavior (1-5s typical) |
| **Test duration** | How long to sustain load | At least 5-10 minutes at steady state |
| **Request mix** | Ratio of different operations | Match production traffic patterns (e.g., 70% read, 20% search, 10% write) |

### Realistic Traffic Patterns

```
Production traffic (from analytics):
  - 70% browsing (GET /products, GET /product/:id)
  - 15% searching (GET /search?q=...)
  - 10% cart operations (POST /cart, PUT /cart/:id)
  - 5% checkout (POST /orders)

Peak traffic:
  - Normal: 200 concurrent users
  - Peak (Monday morning): 500 concurrent users
  - Black Friday: 2000 concurrent users
```

---

## 9. Performance Test Types

### Test Type Comparison

| Type | Goal | Duration | Load Pattern | When to Run |
|------|------|----------|-------------|-------------|
| **Load test** | Verify expected traffic | 5-15 min | Ramp to expected peak | Every sprint / pre-release |
| **Stress test** | Find breaking point | 10-30 min | Ramp beyond capacity | Before major releases |
| **Soak test** | Find memory leaks, degradation | 2-8 hours | Constant moderate load | Monthly or before major releases |
| **Spike test** | Verify auto-scaling | 5-10 min | Sudden load burst | When changing auto-scaling config |
| **Breakpoint test** | Find absolute max capacity | 15-30 min | Continuous ramp until failure | Capacity planning |
| **Benchmark** | Establish baseline | 5-10 min | Fixed load | After each deployment |

### Soak Test (Memory Leak Detection)

```javascript
// k6 soak test
export const options = {
  stages: [
    { duration: '5m', target: 100 },    // ramp up
    { duration: '4h', target: 100 },    // sustain for 4 hours
    { duration: '5m', target: 0 },      // ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
  },
}
```

**What to monitor during soak tests:**
- Memory usage (should be stable, not growing)
- CPU usage (should be stable)
- Response times (should not degrade over time)
- Database connection pool (no leaks)
- File descriptors (no leaks)
- Disk usage (log rotation working)

---

## 10. Web Performance Testing

### Lighthouse CI

```yaml
# lighthouserc.yml
ci:
  collect:
    url:
      - http://localhost:3000/
      - http://localhost:3000/products
      - http://localhost:3000/checkout
    numberOfRuns: 3
    settings:
      preset: desktop  # or 'mobile'

  assert:
    assertions:
      categories:performance:
        - error
        - minScore: 0.9
      first-contentful-paint:
        - error
        - maxNumericValue: 1500
      largest-contentful-paint:
        - error
        - maxNumericValue: 2500
      interactive:
        - error
        - maxNumericValue: 3500
      cumulative-layout-shift:
        - error
        - maxNumericValue: 0.1

  upload:
    target: filesystem
    outputDir: ./lighthouse-results
```

```bash
npx lhci autorun
```

### Core Web Vitals Targets (2025-2026)

| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| **LCP** (Largest Contentful Paint) | < 2.5s | 2.5s - 4.0s | > 4.0s |
| **INP** (Interaction to Next Paint) | < 200ms | 200ms - 500ms | > 500ms |
| **CLS** (Cumulative Layout Shift) | < 0.1 | 0.1 - 0.25 | > 0.25 |
| **TTFB** (Time to First Byte) | < 800ms | 800ms - 1800ms | > 1800ms |

### WebPageTest Integration

```bash
# WebPageTest API
curl -X POST "https://www.webpagetest.org/runtest.php" \
  -d "url=https://your-site.com" \
  -d "k=YOUR_API_KEY" \
  -d "runs=3" \
  -d "location=Dulles:Chrome"
```

---

## 11. Performance Testing in CI/CD

### k6 in GitHub Actions

```yaml
# .github/workflows/performance.yml
name: Performance Tests
on:
  pull_request:
    branches: [main]

jobs:
  load-test:
    runs-on: ubuntu-latest
    services:
      app:
        image: myapp:${{ github.sha }}
        ports: ['3000:3000']

    steps:
      - uses: actions/checkout@v4

      - uses: grafana/k6-action@v0.3.1
        with:
          filename: tests/performance/load-test.js
        env:
          BASE_URL: http://localhost:3000

      # k6 exits non-zero if thresholds fail → PR check fails
```

### Performance Regression Detection

```javascript
// k6 thresholds act as performance gates
export const options = {
  thresholds: {
    // These thresholds fail the CI job if not met
    'http_req_duration{name:list_products}': ['p(95)<200'],
    'http_req_duration{name:create_order}': ['p(95)<500'],
    'http_req_failed': ['rate<0.01'],
  },
}
```

---

## 12. Profiling and Bottleneck Identification

### Common Bottleneck Checklist

| Symptom | Likely Bottleneck | How to Verify |
|---------|------------------|---------------|
| High p99, OK p50 | Database slow queries, lock contention | Check slow query log, `pg_stat_activity` |
| Increasing response times under load | Connection pool exhaustion | Monitor pool stats, max connections |
| CPU at 100% | Compute-heavy operation, N+1 queries | CPU profiling, query analysis |
| Memory growing | Memory leak, unbounded cache | Heap snapshots, memory profiling |
| Intermittent timeouts | External dependency, DNS, GC pauses | Distributed tracing, GC logs |
| Everything slow | Network saturation, disk I/O | Network monitoring, `iostat` |

### Server-Side Profiling Tools

| Language | CPU Profiling | Memory Profiling | Tracing |
|----------|--------------|------------------|---------|
| Node.js | `node --prof`, `clinic.js` | `node --inspect` + Chrome DevTools | OpenTelemetry, Datadog APM |
| Java | JFR (Java Flight Recorder), async-profiler | JFR, VisualVM | OpenTelemetry, Datadog APM |
| Python | py-spy, cProfile | memray, tracemalloc | OpenTelemetry |
| Go | `pprof` (built-in) | `pprof` (built-in) | OpenTelemetry |

---

## 13. Distributed Load Testing

### k6 Operator (Kubernetes)

```yaml
# k6-test.yaml
apiVersion: k6.io/v1alpha1
kind: TestRun
metadata:
  name: order-load-test
spec:
  parallelism: 4        # 4 k6 pods
  script:
    configMap:
      name: load-test-script
  runner:
    resources:
      limits:
        cpu: "1000m"
        memory: "512Mi"
```

### Distributed Locust

```bash
# Start master
locust -f locustfile.py --master --host http://target:3000

# Start workers (on different machines)
locust -f locustfile.py --worker --master-host master-ip
```

---

## 14. Database Performance Testing

### Query Benchmarking

```javascript
// k6 with xk6-sql extension
import sql from 'k6/x/sql'

const db = sql.open('postgres', 'postgresql://user:pass@localhost:5432/testdb')

export default function () {
  // Benchmark a specific query
  const results = sql.query(db, `
    SELECT o.id, o.total, u.name
    FROM orders o
    JOIN users u ON u.id = o.user_id
    WHERE o.created_at > NOW() - INTERVAL '7 days'
    ORDER BY o.created_at DESC
    LIMIT 50
  `)
}
```

### Connection Pool Testing

```javascript
// Test connection pool under load
export const options = {
  scenarios: {
    pool_stress: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 50 },
        { duration: '2m', target: 100 },    // exceed pool size
        { duration: '2m', target: 200 },    // way exceed pool size
        { duration: '1m', target: 0 },
      ],
    },
  },
  thresholds: {
    // Monitor for connection pool exhaustion
    http_req_duration: ['p(95)<1000'],
    http_req_failed: ['rate<0.05'],
  },
}
```

---

## 15. Performance Test Decision Framework

### When to Run Which Test

| Trigger | Test Type | Scope |
|---------|-----------|-------|
| Every PR | Benchmark (quick, 2-3 min) | Critical API endpoints only |
| Pre-release | Load test (10-15 min) | Full user journey simulation |
| Quarterly | Stress test + Soak test | Find limits and leaks |
| After infrastructure change | Load test + Spike test | Verify capacity unchanged |
| After database migration | Query benchmark | Verify query performance unchanged |
| Before peak traffic event | Stress test + Spike test | Validate auto-scaling |

### Performance Test Environment Requirements

| Requirement | Why | How |
|-------------|-----|-----|
| **Production-like data volume** | Query plans differ on empty vs full tables | Seed with realistic data (anonymized prod backup) |
| **Production-like infrastructure** | Different server specs → different results | Use same instance types, same DB config |
| **Isolated environment** | Other traffic affects results | Dedicated performance test environment |
| **Baseline established** | Need something to compare against | Run same test on known-good version |
| **Monitoring in place** | Need to identify bottlenecks | APM, database metrics, infrastructure metrics |
