# API Test Specialist — Deep Reference

**Always use `WebSearch` to verify current tool versions, breaking changes, and framework updates before giving API testing advice. Tools like Hurl, Bruno, and Schemathesis release frequently.**

## Table of Contents
1. [API Testing Fundamentals](#1-api-testing-fundamentals)
2. [API Test Framework Comparison](#2-api-test-framework-comparison)
3. [Postman and Newman](#3-postman-and-newman)
4. [Hurl — HTTP File Testing](#4-hurl--http-file-testing)
5. [REST Assured (Java)](#5-rest-assured-java)
6. [Supertest (Node.js)](#6-supertest-nodejs)
7. [Karate DSL](#7-karate-dsl)
8. [REST API Testing Patterns](#8-rest-api-testing-patterns)
9. [GraphQL Testing](#9-graphql-testing)
10. [gRPC Testing](#10-grpc-testing)
11. [Schema Validation](#11-schema-validation)
12. [Property-Based API Testing](#12-property-based-api-testing)
13. [API Mocking](#13-api-mocking)
14. [Authentication and Authorization Testing](#14-authentication-and-authorization-testing)
15. [API Test Decision Framework](#15-api-test-decision-framework)

---

## 1. API Testing Fundamentals

### The API Test Checklist

For every API endpoint, verify:

| Category | What to Test | Example |
|----------|-------------|---------|
| **Happy path** | Valid input returns expected output | POST /orders with valid items → 201 + order object |
| **Validation** | Invalid input returns proper errors | POST /orders with empty items → 400 + error message |
| **Authentication** | Unauthenticated requests are rejected | GET /orders without token → 401 |
| **Authorization** | Unauthorized users can't access resources | GET /admin/users as regular user → 403 |
| **Not found** | Missing resources return 404 | GET /orders/nonexistent-id → 404 |
| **Idempotency** | Repeated requests behave correctly | PUT /orders/123 twice → same result |
| **Pagination** | Large collections paginate correctly | GET /products?page=2&limit=20 |
| **Filtering/sorting** | Query parameters work correctly | GET /products?category=electronics&sort=price |
| **Rate limiting** | Excessive requests are throttled | 100 rapid requests → some 429s |
| **Content negotiation** | Correct Content-Type handling | Accept: application/json vs text/html |
| **Error format** | Errors follow consistent format | All errors have { error, message, statusCode } |
| **Edge cases** | Boundary values, empty strings, special characters | Name with emoji, zero quantity, max int price |

### HTTP Status Code Testing Guide

| Code | When to Verify | Test Pattern |
|------|----------------|-------------|
| **200 OK** | GET (found), PUT (updated), PATCH (updated) | Standard success assertions |
| **201 Created** | POST (created new resource) | Check Location header, response body |
| **204 No Content** | DELETE (deleted), PUT (no body response) | Verify empty body |
| **301/302** | Redirects | Check Location header |
| **400 Bad Request** | Invalid input | Submit malformed data, verify error messages |
| **401 Unauthorized** | Missing/invalid auth | Omit token, use expired token |
| **403 Forbidden** | Valid auth but insufficient permissions | Use low-privilege token |
| **404 Not Found** | Resource doesn't exist | Request nonexistent ID |
| **409 Conflict** | Duplicate resource, version conflict | Create duplicate, concurrent updates |
| **422 Unprocessable** | Valid format but invalid semantics | Valid JSON but negative quantity |
| **429 Too Many Requests** | Rate limit exceeded | Rapid-fire requests |
| **500 Internal Server Error** | Server-side failure | Should never happen in normal testing |

---

## 2. API Test Framework Comparison

### Framework Selection Matrix (2025-2026)

| Tool | Language | Approach | Strengths | Best For |
|------|----------|----------|-----------|----------|
| **Postman/Newman** | JS (collections) | GUI + CLI | Visual design, collaboration | Teams, non-developers, manual + automated |
| **Hurl** | DSL (plain text) | CLI-first | Simple, fast, git-friendly | CI/CD, developers who like plain text |
| **REST Assured 6.x** | Java 17+ | Code | Fluent API, JUnit integration, Spring 7 | Java backend teams |
| **Supertest** | Node.js/TS | Code | Express/Fastify integration, async/await | Node.js backend teams |
| **Karate** | Gherkin-like DSL | Hybrid | BDD syntax, no coding needed | Teams wanting BDD-style API tests |
| **Bruno** | DSL + GUI | Desktop app + CLI | Git-friendly, no cloud dependency | Postman alternative, privacy-focused |
| **httpx/requests** | Python | Code | Simple HTTP library | Python backend teams |
| **Step CI** | YAML | CLI | Minimal YAML config | Quick CI checks |
| **Schemathesis** | Python | Generative | Auto-generates tests from OpenAPI | Schema compliance, fuzz testing |

---

## 3. Postman and Newman

### Postman Collection Tests

```javascript
// POST /api/orders — Test script
pm.test("Status code is 201", () => {
  pm.response.to.have.status(201)
})

pm.test("Response has order ID", () => {
  const response = pm.response.json()
  pm.expect(response.id).to.be.a('string')
  pm.expect(response.id).to.have.lengthOf.above(0)

  // Save for subsequent requests
  pm.environment.set("orderId", response.id)
})

pm.test("Order total matches expected", () => {
  const response = pm.response.json()
  pm.expect(response.total).to.be.a('number')
  pm.expect(response.total).to.be.above(0)
})

pm.test("Response time < 500ms", () => {
  pm.expect(pm.response.responseTime).to.be.below(500)
})

// Schema validation
const schema = {
  type: "object",
  required: ["id", "status", "total", "items"],
  properties: {
    id: { type: "string" },
    status: { type: "string", enum: ["pending", "confirmed"] },
    total: { type: "number", minimum: 0 },
    items: { type: "array", minItems: 1 },
  },
}

pm.test("Response matches schema", () => {
  pm.response.to.have.jsonSchema(schema)
})
```

### Newman (CLI Runner)

```bash
# Run collection
newman run collection.json \
  --environment staging.json \
  --reporters cli,htmlextra,json \
  --reporter-htmlextra-export report.html

# CI integration
newman run collection.json \
  --environment ci.json \
  --bail \               # stop on first failure
  --timeout-request 10000
```

### Newman in CI

```yaml
# GitHub Actions
api-tests:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - run: npm install -g newman newman-reporter-htmlextra
    - run: |
        newman run tests/api/collection.json \
          --environment tests/api/ci-environment.json \
          --reporters cli,htmlextra,json \
          --reporter-htmlextra-export test-report.html
    - uses: actions/upload-artifact@v4
      if: always()
      with:
        name: api-test-report
        path: test-report.html
```

---

## 4. Hurl — HTTP File Testing

Hurl (v6.1.1, March 2026) is a CLI tool for running HTTP requests defined in plain text files. Written in Rust, wraps libcurl. Lightweight, fast, CI-friendly, with parallel test execution and HTTP/3 support.

### Basic Hurl Syntax

```hurl
# tests/api/orders.hurl

# Test 1: Create an order
POST http://localhost:3000/api/orders
Content-Type: application/json
Authorization: Bearer {{token}}
{
  "items": [
    {"productId": "prod-1", "quantity": 2},
    {"productId": "prod-2", "quantity": 1}
  ]
}

HTTP 201
[Captures]
order_id: jsonpath "$.id"
[Asserts]
jsonpath "$.status" == "pending"
jsonpath "$.total" > 0
jsonpath "$.items" count == 2
header "Location" matches "^/api/orders/"

# Test 2: Retrieve the order
GET http://localhost:3000/api/orders/{{order_id}}
Authorization: Bearer {{token}}

HTTP 200
[Asserts]
jsonpath "$.id" == {{order_id}}
jsonpath "$.status" == "pending"
jsonpath "$.items[0].productId" == "prod-1"
jsonpath "$.items[0].quantity" == 2

# Test 3: Delete the order
DELETE http://localhost:3000/api/orders/{{order_id}}
Authorization: Bearer {{token}}

HTTP 204

# Test 4: Verify deletion
GET http://localhost:3000/api/orders/{{order_id}}
Authorization: Bearer {{token}}

HTTP 404
```

### Hurl Variables and Assertions

```hurl
# Variables from file or CLI
# hurl --variable token=abc123 --variable base_url=http://localhost:3000

# Rich assertions
GET {{base_url}}/api/products

HTTP 200
[Asserts]
jsonpath "$" count >= 10
jsonpath "$[0].name" isString
jsonpath "$[0].price" isFloat
jsonpath "$[0].price" > 0
jsonpath "$[*].category" includes "electronics"
header "Content-Type" contains "application/json"
header "Cache-Control" exists
duration < 200        # response time < 200ms
body matches "\"products\""
```

```bash
# Run Hurl tests
hurl --test tests/api/*.hurl --variable base_url=http://localhost:3000

# With report
hurl --test tests/api/*.hurl --report-html report/

# Retry on flaky tests
hurl --test --retry 3 tests/api/orders.hurl
```

**Why Hurl over Postman/Newman:**
- Plain text files — git-friendly, easy diffs in PRs
- No GUI dependency — everything in version control
- Fast CLI execution — no Node.js overhead
- Simple syntax — anyone can read and write HTTP requests
- Built-in assertions and variable capture

---

## 5. REST Assured (Java)

```java
import static io.restassured.RestAssured.*;
import static org.hamcrest.Matchers.*;

@TestInstance(Lifecycle.PER_CLASS)
class OrderApiTest {

    @BeforeAll
    void setup() {
        RestAssured.baseURI = "http://localhost:3000";
        RestAssured.basePath = "/api";
    }

    @Test
    void shouldCreateOrder() {
        String orderId =
            given()
                .contentType(ContentType.JSON)
                .header("Authorization", "Bearer " + token)
                .body("""
                    {
                      "items": [
                        {"productId": "prod-1", "quantity": 2}
                      ]
                    }
                    """)
            .when()
                .post("/orders")
            .then()
                .statusCode(201)
                .body("status", equalTo("pending"))
                .body("total", greaterThan(0f))
                .body("items", hasSize(1))
                .body("items[0].productId", equalTo("prod-1"))
                .header("Location", matchesPattern("/api/orders/.*"))
                .time(lessThan(500L))  // response time < 500ms
            .extract()
                .path("id");

        // Verify the order exists
        given()
            .header("Authorization", "Bearer " + token)
        .when()
            .get("/orders/{id}", orderId)
        .then()
            .statusCode(200)
            .body("id", equalTo(orderId));
    }

    @Test
    void shouldReturn400ForEmptyItems() {
        given()
            .contentType(ContentType.JSON)
            .header("Authorization", "Bearer " + token)
            .body("""{"items": []}""")
        .when()
            .post("/orders")
        .then()
            .statusCode(400)
            .body("error", equalTo("VALIDATION_ERROR"))
            .body("message", containsString("items"));
    }

    @Test
    void shouldReturn401WithoutAuth() {
        given()
            .contentType(ContentType.JSON)
            .body("""{"items": [{"productId": "prod-1", "quantity": 1}]}""")
        .when()
            .post("/orders")
        .then()
            .statusCode(401);
    }
}
```

---

## 6. Supertest (Node.js)

```typescript
import request from 'supertest'
import { app } from '../src/app'  // Express/Fastify app instance

describe('Orders API', () => {
  let authToken: string

  beforeAll(async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'test@example.com', password: 'password123' })
    authToken = res.body.token
  })

  describe('POST /api/orders', () => {
    test('creates order with valid data', async () => {
      const res = await request(app)
        .post('/api/orders')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          items: [{ productId: 'prod-1', quantity: 2 }],
        })
        .expect(201)
        .expect('Content-Type', /json/)

      expect(res.body).toMatchObject({
        id: expect.any(String),
        status: 'pending',
        items: expect.arrayContaining([
          expect.objectContaining({ productId: 'prod-1', quantity: 2 }),
        ]),
      })
      expect(res.body.total).toBeGreaterThan(0)
    })

    test('returns 400 for missing items', async () => {
      const res = await request(app)
        .post('/api/orders')
        .set('Authorization', `Bearer ${authToken}`)
        .send({})
        .expect(400)

      expect(res.body.error).toBe('VALIDATION_ERROR')
    })

    test('returns 401 without auth token', async () => {
      await request(app)
        .post('/api/orders')
        .send({ items: [{ productId: 'prod-1', quantity: 1 }] })
        .expect(401)
    })
  })

  describe('GET /api/orders/:id', () => {
    test('returns order by ID', async () => {
      // Create order first
      const createRes = await request(app)
        .post('/api/orders')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ items: [{ productId: 'prod-1', quantity: 1 }] })

      const res = await request(app)
        .get(`/api/orders/${createRes.body.id}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200)

      expect(res.body.id).toBe(createRes.body.id)
    })

    test('returns 404 for nonexistent order', async () => {
      await request(app)
        .get('/api/orders/nonexistent-id')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404)
    })
  })
})
```

---

## 7. Karate DSL

Karate combines API testing, mocking, and performance testing in a BDD-style syntax.

```gherkin
# tests/orders.feature
Feature: Orders API

  Background:
    * url 'http://localhost:3000/api'
    * header Authorization = 'Bearer ' + token

  Scenario: Create and retrieve an order
    Given path 'orders'
    And request { items: [{ productId: 'prod-1', quantity: 2 }] }
    When method post
    Then status 201
    And match response.status == 'pending'
    And match response.total > 0
    And match response.items == '#[1]'
    * def orderId = response.id

    Given path 'orders', orderId
    When method get
    Then status 200
    And match response.id == orderId

  Scenario Outline: Validation errors
    Given path 'orders'
    And request <body>
    When method post
    Then status 400
    And match response.error == 'VALIDATION_ERROR'

    Examples:
      | body                          |
      | { items: [] }                 |
      | { items: null }               |
      | {}                            |
```

---

## 8. REST API Testing Patterns

### CRUD Testing Template

```typescript
describe('Resource CRUD', () => {
  let resourceId: string

  test('CREATE — POST /resources', async () => {
    const res = await request(app)
      .post('/api/resources')
      .send(validPayload)
      .expect(201)

    resourceId = res.body.id
    expect(res.body).toMatchObject(validPayload)
  })

  test('READ — GET /resources/:id', async () => {
    const res = await request(app)
      .get(`/api/resources/${resourceId}`)
      .expect(200)

    expect(res.body.id).toBe(resourceId)
  })

  test('LIST — GET /resources', async () => {
    const res = await request(app)
      .get('/api/resources')
      .expect(200)

    expect(res.body.data).toBeInstanceOf(Array)
    expect(res.body.total).toBeGreaterThan(0)
  })

  test('UPDATE — PUT /resources/:id', async () => {
    const res = await request(app)
      .put(`/api/resources/${resourceId}`)
      .send(updatedPayload)
      .expect(200)

    expect(res.body).toMatchObject(updatedPayload)
  })

  test('DELETE — DELETE /resources/:id', async () => {
    await request(app)
      .delete(`/api/resources/${resourceId}`)
      .expect(204)

    await request(app)
      .get(`/api/resources/${resourceId}`)
      .expect(404)
  })
})
```

### Pagination Testing

```typescript
describe('Pagination', () => {
  test('returns paginated results with metadata', async () => {
    const res = await request(app)
      .get('/api/products?page=2&limit=10')
      .expect(200)

    expect(res.body).toMatchObject({
      data: expect.any(Array),
      pagination: {
        page: 2,
        limit: 10,
        total: expect.any(Number),
        totalPages: expect.any(Number),
      },
    })
    expect(res.body.data.length).toBeLessThanOrEqual(10)
  })

  test('first page has correct links', async () => {
    const res = await request(app)
      .get('/api/products?page=1&limit=5')
      .expect(200)

    expect(res.body.pagination.page).toBe(1)
    // Should not have "previous" on first page
  })

  test('returns empty data for page beyond total', async () => {
    const res = await request(app)
      .get('/api/products?page=9999&limit=10')
      .expect(200)

    expect(res.body.data).toEqual([])
  })
})
```

---

## 9. GraphQL Testing

### Query and Mutation Testing

```typescript
describe('GraphQL API', () => {
  const graphql = (query: string, variables?: Record<string, any>) =>
    request(app)
      .post('/graphql')
      .set('Authorization', `Bearer ${token}`)
      .send({ query, variables })

  test('query: list products', async () => {
    const res = await graphql(`
      query ListProducts($category: String, $limit: Int) {
        products(category: $category, limit: $limit) {
          id
          name
          price
          category
        }
      }
    `, { category: 'electronics', limit: 10 })
      .expect(200)

    expect(res.body.errors).toBeUndefined()
    expect(res.body.data.products).toBeInstanceOf(Array)
    expect(res.body.data.products.length).toBeLessThanOrEqual(10)
    res.body.data.products.forEach((product: any) => {
      expect(product.category).toBe('electronics')
    })
  })

  test('mutation: create order', async () => {
    const res = await graphql(`
      mutation CreateOrder($input: CreateOrderInput!) {
        createOrder(input: $input) {
          id
          status
          total
        }
      }
    `, {
      input: { items: [{ productId: 'prod-1', quantity: 2 }] },
    })
      .expect(200)

    expect(res.body.errors).toBeUndefined()
    expect(res.body.data.createOrder).toMatchObject({
      id: expect.any(String),
      status: 'PENDING',
      total: expect.any(Number),
    })
  })

  test('should return validation errors for invalid input', async () => {
    const res = await graphql(`
      mutation CreateOrder($input: CreateOrderInput!) {
        createOrder(input: $input) { id }
      }
    `, {
      input: { items: [] },
    })
      .expect(200)  // GraphQL returns 200 with errors

    expect(res.body.errors).toBeDefined()
    expect(res.body.errors[0].message).toContain('items')
  })
})
```

### GraphQL-Specific Testing Concerns

| Concern | Test Pattern |
|---------|-------------|
| **N+1 queries** | Enable query logging, check for excessive queries in nested resolvers |
| **Query depth/complexity** | Send deeply nested query, verify rejection |
| **Field authorization** | Query fields user shouldn't see, verify null/error |
| **Pagination (Relay)** | Test `first`, `after`, `last`, `before` cursors |
| **Subscriptions** | WebSocket connection, verify event delivery |
| **Introspection** | Verify disabled in production (if desired) |
| **Batching** | Send multiple operations, verify correct execution |

---

## 10. gRPC Testing

### Tools for gRPC Testing

| Tool | Type | Best For |
|------|------|----------|
| **grpcurl** | CLI | Quick manual testing, CI scripts |
| **Postman** | GUI | Visual gRPC testing (2025+) |
| **BloomRPC / Evans** | GUI | Desktop gRPC client |
| **buf** | CLI | Schema linting, breaking change detection |
| **ghz** | CLI | gRPC load testing |
| **grpc-testing** (library) | Code | Integration tests in Java/Go/Python |

### gRPC Testing with grpcurl

```bash
# List services
grpcurl -plaintext localhost:50051 list

# Describe service
grpcurl -plaintext localhost:50051 describe order.OrderService

# Call unary RPC
grpcurl -plaintext \
  -d '{"items": [{"productId": "prod-1", "quantity": 2}]}' \
  localhost:50051 order.OrderService/CreateOrder

# Call with metadata (auth)
grpcurl -plaintext \
  -H 'Authorization: Bearer token123' \
  -d '{"orderId": "order-123"}' \
  localhost:50051 order.OrderService/GetOrder
```

### Breaking Change Detection with buf

```bash
# buf.yaml — lint and breaking change detection for protobuf
buf lint
buf breaking --against '.git#branch=main'
```

---

## 11. Schema Validation

### OpenAPI Schema Validation

```typescript
// Validate responses against OpenAPI spec
import SwaggerParser from '@apidevtools/swagger-parser'
import Ajv from 'ajv'

let api: any
let ajv: Ajv

beforeAll(async () => {
  api = await SwaggerParser.dereference('./openapi.yaml')
  ajv = new Ajv({ allErrors: true })
})

test('GET /api/products matches OpenAPI schema', async () => {
  const res = await request(app).get('/api/products').expect(200)

  const schema = api.paths['/api/products'].get.responses['200'].content['application/json'].schema
  const valid = ajv.validate(schema, res.body)

  expect(ajv.errors).toBeNull()
  expect(valid).toBe(true)
})
```

### JSON Schema Validation

```typescript
import { expect } from 'vitest'
import Ajv from 'ajv'
import addFormats from 'ajv-formats'

const ajv = new Ajv()
addFormats(ajv)

const orderSchema = {
  type: 'object',
  required: ['id', 'status', 'total', 'items', 'createdAt'],
  properties: {
    id: { type: 'string', format: 'uuid' },
    status: { type: 'string', enum: ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'] },
    total: { type: 'number', minimum: 0 },
    items: {
      type: 'array',
      minItems: 1,
      items: {
        type: 'object',
        required: ['productId', 'quantity', 'price'],
        properties: {
          productId: { type: 'string' },
          quantity: { type: 'integer', minimum: 1 },
          price: { type: 'number', minimum: 0 },
        },
      },
    },
    createdAt: { type: 'string', format: 'date-time' },
  },
  additionalProperties: false,
}

test('order response matches schema', async () => {
  const res = await request(app).post('/api/orders').send(validOrder).expect(201)

  const validate = ajv.compile(orderSchema)
  const valid = validate(res.body)

  if (!valid) {
    console.error('Schema validation errors:', validate.errors)
  }
  expect(valid).toBe(true)
})
```

---

## 12. Property-Based API Testing

### Schemathesis — Auto-Generated API Tests

Schemathesis generates test cases automatically from your OpenAPI/GraphQL schema.

```bash
# Run against live API
schemathesis run http://localhost:3000/openapi.json

# With specific checks
schemathesis run http://localhost:3000/openapi.json \
  --checks all \
  --base-url http://localhost:3000 \
  --hypothesis-max-examples 100 \
  --stateful=links  # follow API links for stateful testing

# Output options
schemathesis run http://localhost:3000/openapi.json \
  --report \
  --cassette-path recorded-failures.yaml  # record failing requests for replay
```

**What Schemathesis tests automatically:**
- Response status codes match the spec
- Response body matches the declared schema
- No 500 errors for any valid input
- Content-Type headers are correct
- Response times are reasonable
- Edge cases: empty strings, long strings, special characters, boundary numbers, unicode

### When to Use Schemathesis

- **CI/CD gating**: Run on every PR to catch spec violations
- **New endpoints**: Generate comprehensive tests immediately from the spec
- **Fuzz testing**: Find edge cases in input validation
- **Regression**: Catch schema drift between code and documentation

---

## 13. API Mocking

### MSW (Mock Service Worker) for Frontend

```typescript
// handlers.ts
import { http, HttpResponse } from 'msw'

export const handlers = [
  http.get('/api/products', () => {
    return HttpResponse.json([
      { id: '1', name: 'Widget', price: 9.99, category: 'electronics' },
      { id: '2', name: 'Gadget', price: 24.99, category: 'electronics' },
    ])
  }),

  http.post('/api/orders', async ({ request }) => {
    const body = await request.json() as any
    if (!body.items || body.items.length === 0) {
      return HttpResponse.json(
        { error: 'VALIDATION_ERROR', message: 'Items required' },
        { status: 400 },
      )
    }
    return HttpResponse.json(
      { id: 'order-123', status: 'pending', items: body.items, total: 49.97 },
      { status: 201 },
    )
  }),
]
```

### Prism (OpenAPI Mock Server)

```bash
# Generate mock server from OpenAPI spec
npx @stoplight/prism-cli mock openapi.yaml

# Starts mock server that returns realistic responses matching your spec
# Dynamic mode generates different responses each time
npx @stoplight/prism-cli mock openapi.yaml --dynamic
```

### API Mock Selection Guide

| Tool | Mechanism | Best For |
|------|-----------|----------|
| **MSW** | Service Worker (browser) / Node interceptor | Frontend dev/testing, React/Vue/Angular |
| **Prism** | OpenAPI-based mock server | API-first development, design-first teams |
| **WireMock** | Standalone HTTP server | Backend integration tests, Java ecosystem |
| **MockServer** | Standalone HTTP server | Backend tests, proxy recording |
| **json-server** | JSON file → REST API | Quick prototyping, simple CRUD mocks |
| **Mirage JS** | In-browser mock server | Ember/React apps, data layer testing |

---

## 14. Authentication and Authorization Testing

### Authentication Test Patterns

```typescript
describe('Authentication', () => {
  test('rejects requests without token', async () => {
    await request(app).get('/api/orders').expect(401)
  })

  test('rejects expired tokens', async () => {
    const expiredToken = generateToken({ userId: '123', expiresIn: '-1h' })
    await request(app)
      .get('/api/orders')
      .set('Authorization', `Bearer ${expiredToken}`)
      .expect(401)
  })

  test('rejects malformed tokens', async () => {
    await request(app)
      .get('/api/orders')
      .set('Authorization', 'Bearer not-a-real-token')
      .expect(401)
  })

  test('rejects wrong auth scheme', async () => {
    await request(app)
      .get('/api/orders')
      .set('Authorization', `Basic ${btoa('user:pass')}`)
      .expect(401)
  })
})
```

### Authorization Test Patterns

```typescript
describe('Authorization', () => {
  test('regular user cannot access admin endpoints', async () => {
    await request(app)
      .get('/api/admin/users')
      .set('Authorization', `Bearer ${userToken}`)
      .expect(403)
  })

  test('user cannot access other user resources', async () => {
    await request(app)
      .get('/api/users/other-user-id/orders')
      .set('Authorization', `Bearer ${userToken}`)
      .expect(403)
  })

  test('admin can access admin endpoints', async () => {
    await request(app)
      .get('/api/admin/users')
      .set('Authorization', `Bearer ${adminToken}`)
      .expect(200)
  })
})
```

---

## 15. API Test Decision Framework

### Choosing the Right API Test Approach

| Need | Best Tool | Why |
|------|-----------|-----|
| Quick manual testing | **Hurl** or **Bruno** | Fast, git-friendly, plain text |
| Team collaboration + collections | **Postman** | Visual editor, shared collections |
| Java backend tests | **REST Assured** | Fluent Java API, JUnit integration |
| Node.js backend tests | **Supertest** | Direct app instance testing, no server needed |
| BDD-style API tests | **Karate** | Gherkin syntax, no code |
| Schema compliance | **Schemathesis** | Auto-generated from OpenAPI |
| Frontend development mocking | **MSW** | Network-level interception |
| API-first development | **Prism** | Mock from spec before implementation |
| CI smoke tests | **Hurl** | Fast, simple, exit code on failure |
| gRPC testing | **grpcurl** + **buf** | CLI-first, breaking change detection |
| Load testing APIs | See Performance Test Specialist | k6, Artillery, etc. |

### API Test Coverage Guide

| Priority | What to Test | How |
|----------|-------------|-----|
| **P0** | All endpoints return correct status codes | Automated (Schemathesis + custom) |
| **P0** | Authentication works / is enforced | Automated (custom tests) |
| **P0** | Response schema matches spec | Automated (schema validation) |
| **P1** | All validation rules enforced | Automated (boundary testing) |
| **P1** | Authorization rules enforced | Automated (role-based tests) |
| **P1** | Error responses have consistent format | Automated (schema validation) |
| **P2** | Pagination, filtering, sorting work | Automated (parameterized tests) |
| **P2** | Rate limiting enforced | Automated (rapid-fire test) |
| **P3** | Concurrent request handling | Automated (load test) |
| **P3** | Idempotency for PUT/DELETE | Automated (repeat requests) |
