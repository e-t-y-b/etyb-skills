# Integration Test Specialist — Deep Reference

**Always use `WebSearch` to verify current tool versions, breaking changes, and framework updates before giving integration testing advice. Testcontainers, Pact, and related tools release frequently.**

## Table of Contents
1. [Integration Testing Fundamentals](#1-integration-testing-fundamentals)
2. [Testcontainers](#2-testcontainers)
3. [Contract Testing with Pact](#3-contract-testing-with-pact)
4. [Contract Testing Alternatives](#4-contract-testing-alternatives)
5. [HTTP Service Mocking](#5-http-service-mocking)
6. [Database Integration Testing](#6-database-integration-testing)
7. [Message Broker Testing](#7-message-broker-testing)
8. [Event-Driven System Testing](#8-event-driven-system-testing)
9. [External Service Testing Strategies](#9-external-service-testing-strategies)
10. [CI/CD Integration for Integration Tests](#10-cicd-integration-for-integration-tests)
11. [Microservice Integration Patterns](#11-microservice-integration-patterns)
12. [Integration Test Anti-Patterns](#12-integration-test-anti-patterns)
13. [Integration Test Decision Framework](#13-integration-test-decision-framework)

---

## 1. Integration Testing Fundamentals

### What Makes It an Integration Test

An integration test verifies that **two or more components work correctly together**. The "components" can be:

| Integration Boundary | Example | Tool |
|---------------------|---------|------|
| Application → Database | ORM queries, migrations, constraints | Testcontainers |
| Service → Service | REST/gRPC/GraphQL calls between microservices | Pact, WireMock |
| Application → Message Broker | Publishing/consuming Kafka, RabbitMQ messages | Testcontainers |
| Application → Cache | Redis operations, cache invalidation | Testcontainers |
| Application → Search Engine | Elasticsearch indexing and queries | Testcontainers |
| Application → External API | Stripe, Twilio, AWS services | WireMock, LocalStack |
| Application → File Storage | S3, GCS operations | LocalStack, MinIO |

### Integration Test vs Unit Test vs E2E

```
Unit Test:
  ┌──────────────┐
  │  Your Code   │  ← Tests this in isolation (mocks everything else)
  └──────────────┘

Integration Test:
  ┌──────────────┐     ┌──────────────┐
  │  Your Code   │────▶│  Real DB /   │  ← Tests the boundary
  └──────────────┘     │  Service     │
                       └──────────────┘

E2E Test:
  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
  │ Browser  │───▶│ Frontend │───▶│ Backend  │───▶│ Database │
  └──────────┘    └──────────┘    └──────────┘    └──────────┘
  ← Tests the entire stack
```

### When to Write Integration Tests

- **Database queries**: ORM-generated SQL may surprise you — test against a real database
- **Schema migrations**: Verify migrations work on a real database engine
- **Service contracts**: Verify that two services agree on API format
- **Cache behavior**: Verify cache invalidation, TTL, serialization/deserialization
- **Message handling**: Verify message serialization, routing, dead letter handling
- **External APIs**: Verify your client code works with the real API contract

---

## 2. Testcontainers

Testcontainers provides lightweight, throwaway containers for integration testing. Containers start before tests and are destroyed after. This gives you real databases, message brokers, and services in your test suite.

### Language Support (2025-2026)

| Language | Package | Maturity |
|----------|---------|----------|
| Java | `org.testcontainers:testcontainers` | Most mature, widest module support |
| Node.js/TS | `testcontainers` (npm) | Full-featured, actively maintained |
| Python | `testcontainers` (PyPI) | Good coverage, actively maintained |
| Go | `github.com/testcontainers/testcontainers-go` | Full-featured |
| .NET | `Testcontainers` (NuGet) | Full-featured |
| Rust | `testcontainers` (crate) | Growing |

### Testcontainers for Node.js/TypeScript

```typescript
import { PostgreSqlContainer, StartedPostgreSqlContainer } from '@testcontainers/postgresql'
import { Client } from 'pg'

describe('UserRepository', () => {
  let container: StartedPostgreSqlContainer
  let client: Client

  beforeAll(async () => {
    container = await new PostgreSqlContainer('postgres:16-alpine')
      .withDatabase('testdb')
      .withUsername('test')
      .withPassword('test')
      .start()

    client = new Client({ connectionString: container.getConnectionUri() })
    await client.connect()

    // Run migrations
    await runMigrations(container.getConnectionUri())
  }, 60_000) // Generous timeout for container startup

  afterAll(async () => {
    await client.end()
    await container.stop()
  })

  afterEach(async () => {
    // Clean up between tests
    await client.query('DELETE FROM users')
  })

  test('should insert and retrieve a user', async () => {
    const repo = new UserRepository(client)

    await repo.create({ name: 'Alice', email: 'alice@example.com' })
    const user = await repo.findByEmail('alice@example.com')

    expect(user).toMatchObject({ name: 'Alice', email: 'alice@example.com' })
    expect(user.id).toBeDefined()
    expect(user.createdAt).toBeInstanceOf(Date)
  })

  test('should enforce unique email constraint', async () => {
    const repo = new UserRepository(client)

    await repo.create({ name: 'Alice', email: 'alice@example.com' })

    await expect(
      repo.create({ name: 'Bob', email: 'alice@example.com' })
    ).rejects.toThrow(/unique.*email/i)
  })
})
```

### Testcontainers for Java (JUnit 5)

```java
@Testcontainers
class UserRepositoryTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine")
        .withDatabaseName("testdb")
        .withUsername("test")
        .withPassword("test");

    private UserRepository repository;

    @BeforeEach
    void setUp() {
        var dataSource = DataSourceBuilder.create()
            .url(postgres.getJdbcUrl())
            .username(postgres.getUsername())
            .password(postgres.getPassword())
            .build();
        repository = new UserRepository(dataSource);
    }

    @Test
    void shouldInsertAndRetrieveUser() {
        repository.create(new User("Alice", "alice@example.com"));

        var user = repository.findByEmail("alice@example.com");

        assertThat(user).isPresent();
        assertThat(user.get().getName()).isEqualTo("Alice");
    }
}
```

### Testcontainers for Python

```python
import pytest
from testcontainers.postgres import PostgresContainer

@pytest.fixture(scope="session")
def postgres():
    with PostgresContainer("postgres:16-alpine") as pg:
        yield pg

@pytest.fixture
def db_connection(postgres):
    import psycopg2
    conn = psycopg2.connect(postgres.get_connection_url())
    yield conn
    conn.rollback()
    conn.close()

def test_insert_and_retrieve_user(db_connection):
    repo = UserRepository(db_connection)
    repo.create(name="Alice", email="alice@example.com")

    user = repo.find_by_email("alice@example.com")

    assert user.name == "Alice"
    assert user.email == "alice@example.com"
```

### Testcontainers for Go

```go
func TestUserRepository(t *testing.T) {
    ctx := context.Background()

    container, err := postgres.Run(ctx,
        "postgres:16-alpine",
        postgres.WithDatabase("testdb"),
        postgres.WithUsername("test"),
        postgres.WithPassword("test"),
        testcontainers.WithWaitStrategy(
            wait.ForLog("database system is ready to accept connections").
                WithOccurrence(2).WithStartupTimeout(5*time.Second),
        ),
    )
    require.NoError(t, err)
    defer container.Terminate(ctx)

    connStr, err := container.ConnectionString(ctx, "sslmode=disable")
    require.NoError(t, err)

    repo := NewUserRepository(connStr)

    t.Run("insert and retrieve", func(t *testing.T) {
        err := repo.Create(ctx, User{Name: "Alice", Email: "alice@example.com"})
        require.NoError(t, err)

        user, err := repo.FindByEmail(ctx, "alice@example.com")
        require.NoError(t, err)
        assert.Equal(t, "Alice", user.Name)
    })
}
```

### Available Container Modules

| Category | Containers |
|----------|-----------|
| **Databases** | PostgreSQL, MySQL, MariaDB, MongoDB, Redis, Cassandra, CockroachDB, ClickHouse, Neo4j, DynamoDB (via LocalStack) |
| **Message Brokers** | Kafka (KRaft), RabbitMQ, Redis Streams, Pulsar, NATS |
| **Search** | Elasticsearch, OpenSearch, Meilisearch |
| **Cloud** | LocalStack (AWS), Azurite (Azure), GCS emulator |
| **Other** | MinIO (S3-compatible), Vault, Keycloak, WireMock, MockServer |

### Performance Tips

| Tip | Impact |
|-----|--------|
| Use `scope="session"` / `@Container static` | Container starts once for all tests, not per test |
| Use Alpine images | Faster pull times |
| Use Docker layer caching in CI | Avoid repulling images |
| Clean data between tests, don't restart containers | Much faster than stopping/starting |
| Use transactions for cleanup (`ROLLBACK` after each test) | Fastest cleanup method |
| Pre-pull images in CI setup step | Parallel pull, not during test execution |
| Reuse containers across test runs (dev only) | `testcontainers.reuse.enable=true` |

---

## 3. Contract Testing with Pact

### What Is Contract Testing?

Contract testing verifies that a **consumer** (client) and **provider** (server) agree on the API contract without needing both running simultaneously. Each side is tested independently.

```
Traditional integration test:
  Consumer ──────────▶ Provider    (both must be running)

Contract test:
  Consumer ──▶ Pact Mock ──▶ Contract File ──▶ Provider Verification
  (generates contract)           (verifies contract)
```

### Consumer-Driven Contract Testing with Pact

**Consumer side** — generates a "pact" (contract file):

```typescript
// consumer.pact.test.ts
import { PactV4, MatchersV3 } from '@pact-foundation/pact'

const provider = new PactV4({
  consumer: 'OrderService',
  provider: 'UserService',
})

describe('User Service Client', () => {
  test('get user by ID', async () => {
    await provider
      .addInteraction()
      .given('user 123 exists')
      .uponReceiving('a request for user 123')
      .withRequest('GET', '/users/123', (builder) => {
        builder.headers({ Accept: 'application/json' })
      })
      .willRespondWith(200, (builder) => {
        builder
          .headers({ 'Content-Type': 'application/json' })
          .jsonBody({
            id: MatchersV3.integer(123),
            name: MatchersV3.string('Alice'),
            email: MatchersV3.email('alice@example.com'),
          })
      })
      .executeTest(async (mockServer) => {
        const client = new UserServiceClient(mockServer.url)
        const user = await client.getUserById(123)

        expect(user.id).toBe(123)
        expect(user.name).toBeDefined()
        expect(user.email).toContain('@')
      })
  })
})
```

**Provider side** — verifies the pact:

```typescript
// provider.pact.verify.test.ts
import { Verifier } from '@pact-foundation/pact'

describe('User Service Provider Verification', () => {
  test('should honor the contract with OrderService', async () => {
    const verifier = new Verifier({
      providerBaseUrl: 'http://localhost:3001',
      pactUrls: ['./pacts/OrderService-UserService.json'],
      // Or from Pact Broker:
      // pactBrokerUrl: 'https://your-pact-broker.pactflow.io',
      // providerVersion: process.env.GIT_SHA,
      stateHandlers: {
        'user 123 exists': async () => {
          await seedDatabase({ id: 123, name: 'Alice', email: 'alice@example.com' })
        },
      },
    })

    await verifier.verifyProvider()
  })
})
```

### Pact Broker / PactFlow

The Pact Broker stores and shares contracts between teams. PactFlow is the managed SaaS version.

**Key features:**
- **Can-I-Deploy**: Check if a version can be safely deployed (are all contracts verified?)
- **Webhooks**: Trigger provider verification when a new consumer contract is published
- **Network diagram**: Visualize service dependencies
- **Tags/branches**: Track contracts per branch/environment

```bash
# Check if OrderService can be deployed to production
pact-broker can-i-deploy \
  --pacticipant OrderService \
  --version $(git rev-parse HEAD) \
  --to-environment production
```

### When to Use Contract Testing

| Scenario | Use Contract Testing? | Why |
|----------|----------------------|-----|
| Microservices with many consumers | Yes | Catch breaking changes before deployment |
| Internal APIs between teams | Yes | Teams can evolve independently |
| Public APIs with external consumers | Yes (provider-driven) | Verify backward compatibility |
| Single team owning both sides | Maybe | Simpler to do integration tests |
| Third-party APIs you consume | No (use WireMock) | You can't run their provider verification |
| Simple CRUD with one consumer | No | Over-engineering |

---

## 4. Contract Testing Alternatives

### Specmatic (formerly Qontract)

Contract-first testing from OpenAPI specs. No consumer-side code needed.

```bash
# Generate tests from OpenAPI spec
specmatic test --contract=openapi.yaml --host=localhost --port=3000
```

**Best for:** Teams already using OpenAPI specs, want zero-code contract verification.

### Schema Validation as Lightweight Contracts

For simpler needs, validate API responses against OpenAPI/JSON Schema in your existing tests:

```typescript
import Ajv from 'ajv'

test('GET /users/:id matches OpenAPI schema', async () => {
  const response = await fetch('/users/123')
  const body = await response.json()

  const ajv = new Ajv()
  const schema = loadOpenAPISchema('paths./users.{id}.get.responses.200.content.application/json.schema')

  expect(ajv.validate(schema, body)).toBe(true)
})
```

---

## 5. HTTP Service Mocking

### WireMock

WireMock creates an HTTP server that returns predefined responses. Ideal for mocking external APIs in integration tests.

```java
// Java — WireMock JUnit 5
@WireMockTest(httpPort = 8089)
class PaymentClientTest {

    @Test
    void shouldProcessPayment(WireMockRuntimeInfo wmRuntimeInfo) {
        stubFor(post(urlPathEqualTo("/v1/charges"))
            .withHeader("Authorization", matching("Bearer sk_test_.*"))
            .withRequestBody(matchingJsonPath("$.amount", equalTo("1999")))
            .willReturn(okJson("""
                {"id": "ch_123", "status": "succeeded", "amount": 1999}
                """)));

        var client = new PaymentClient(wmRuntimeInfo.getHttpBaseUrl());
        var result = client.charge(1999, "usd");

        assertThat(result.getStatus()).isEqualTo("succeeded");
        verify(postRequestedFor(urlPathEqualTo("/v1/charges")));
    }
}
```

### MockServer

Similar to WireMock but with additional features like forward proxying and request verification.

### MSW (Mock Service Worker) — Frontend

MSW intercepts HTTP requests at the network level. Ideal for frontend integration tests and development.

```typescript
// src/mocks/handlers.ts
import { http, HttpResponse } from 'msw'

export const handlers = [
  http.get('/api/users/:id', ({ params }) => {
    return HttpResponse.json({
      id: Number(params.id),
      name: 'Alice',
      email: 'alice@example.com',
    })
  }),

  http.post('/api/orders', async ({ request }) => {
    const body = await request.json()
    return HttpResponse.json(
      { id: 'order-123', status: 'created', items: body.items },
      { status: 201 },
    )
  }),

  // Error scenario
  http.get('/api/users/999', () => {
    return HttpResponse.json(
      { error: 'User not found' },
      { status: 404 },
    )
  }),
]

// src/mocks/server.ts (for Node.js/test environment)
import { setupServer } from 'msw/node'
import { handlers } from './handlers'
export const server = setupServer(...handlers)

// test setup
beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())
```

### Choosing a Mocking Approach

| Tool | Level | Best For |
|------|-------|----------|
| **MSW** | Network (Service Worker / Node) | Frontend tests, React/Vue/Angular integration |
| **WireMock** | HTTP server (standalone) | Backend integration tests, Java ecosystem |
| **MockServer** | HTTP server (standalone) | Backend tests, forward proxy scenarios |
| **Prism** | HTTP server (from OpenAPI) | API mocking from OpenAPI specs |
| **nock** (Node.js) | HTTP client interception | Simple Node.js HTTP mocking |
| **responses** (Python) | HTTP client interception | Python requests library mocking |
| **httpmock** (Go) | HTTP client interception | Go HTTP mocking |

---

## 6. Database Integration Testing

### Test Database Strategies

| Strategy | Speed | Isolation | Realism | Best For |
|----------|-------|-----------|---------|----------|
| **Testcontainers** | Slow startup, fast tests | Excellent | 100% real | CI, critical paths |
| **Shared test DB + transactions** | Fast | Good (rollback) | 100% real | Local dev, fast iteration |
| **SQLite in-memory** | Fastest | Excellent | Low (different SQL) | Simple ORM tests only |
| **In-memory DB (H2)** | Fast | Excellent | Medium | Java-specific, simple queries |

**Recommendation:** Use Testcontainers in CI (real database engine, proper isolation). Use a shared local database with transaction rollback for fast local development.

### Transaction Rollback Pattern

```typescript
// Wrap each test in a transaction that gets rolled back
describe('UserRepository', () => {
  let db: Database
  let trx: Transaction

  beforeEach(async () => {
    trx = await db.transaction()
  })

  afterEach(async () => {
    await trx.rollback()
  })

  test('creates a user', async () => {
    const repo = new UserRepository(trx)  // pass transaction, not connection
    await repo.create({ name: 'Alice', email: 'alice@test.com' })

    const user = await repo.findByEmail('alice@test.com')
    expect(user.name).toBe('Alice')
    // Transaction rolls back — no data persists between tests
  })
})
```

### Testing Migrations

```typescript
// Verify migrations apply cleanly on an empty database
test('all migrations apply successfully', async () => {
  const container = await new PostgreSqlContainer().start()
  const migrator = new Migrator(container.getConnectionUri())

  await expect(migrator.up()).resolves.not.toThrow()

  // Verify expected tables exist
  const tables = await migrator.listTables()
  expect(tables).toContain('users')
  expect(tables).toContain('orders')
  expect(tables).toContain('order_items')
})

// Verify migrations are reversible
test('migrations can be rolled back', async () => {
  const container = await new PostgreSqlContainer().start()
  const migrator = new Migrator(container.getConnectionUri())

  await migrator.up()
  await expect(migrator.down()).resolves.not.toThrow()
})
```

---

## 7. Message Broker Testing

### Kafka Testing with Testcontainers

```typescript
import { KafkaContainer } from '@testcontainers/kafka'
import { Kafka } from 'kafkajs'

describe('OrderEventPublisher', () => {
  let container: StartedKafkaContainer
  let kafka: Kafka

  beforeAll(async () => {
    container = await new KafkaContainer('confluentinc/cp-kafka:7.7.0')
      .withKraft()  // KRaft mode (no ZooKeeper)
      .start()

    kafka = new Kafka({
      brokers: [container.getBootstrapServers()],
    })

    // Create topic
    const admin = kafka.admin()
    await admin.createTopics({
      topics: [{ topic: 'order-events', numPartitions: 1 }],
    })
    await admin.disconnect()
  }, 120_000)

  test('publishes OrderCreated event', async () => {
    const publisher = new OrderEventPublisher(kafka)
    const consumer = kafka.consumer({ groupId: 'test-group' })

    await consumer.connect()
    await consumer.subscribe({ topic: 'order-events', fromBeginning: true })

    const messages: any[] = []
    await consumer.run({
      eachMessage: async ({ message }) => {
        messages.push(JSON.parse(message.value!.toString()))
      },
    })

    // Publish event
    await publisher.publishOrderCreated({
      orderId: 'order-123',
      userId: 'user-456',
      total: 49.99,
    })

    // Wait for message to arrive
    await waitFor(() => expect(messages).toHaveLength(1))

    expect(messages[0]).toMatchObject({
      type: 'OrderCreated',
      data: { orderId: 'order-123', userId: 'user-456', total: 49.99 },
    })

    await consumer.disconnect()
  })
})
```

### RabbitMQ Testing

```typescript
import { RabbitMQContainer } from '@testcontainers/rabbitmq'
import amqplib from 'amqplib'

describe('NotificationConsumer', () => {
  let container: StartedRabbitMQContainer

  beforeAll(async () => {
    container = await new RabbitMQContainer('rabbitmq:3.13-management-alpine').start()
  }, 60_000)

  test('processes notification messages', async () => {
    const conn = await amqplib.connect(container.getAmqpUrl())
    const channel = await conn.createChannel()

    await channel.assertQueue('notifications')

    // Send test message
    channel.sendToQueue('notifications', Buffer.from(JSON.stringify({
      type: 'order_confirmation',
      userId: 'user-123',
      orderId: 'order-456',
    })))

    // Verify consumer processes it
    const consumer = new NotificationConsumer(container.getAmqpUrl())
    const processed = await consumer.processNext()

    expect(processed.type).toBe('order_confirmation')
    expect(processed.status).toBe('sent')

    await conn.close()
  })
})
```

---

## 8. Event-Driven System Testing

### Testing Event Handlers

```typescript
// Test that an event handler correctly processes events and produces side effects
test('OrderCreatedHandler sends confirmation email and updates inventory', async () => {
  // Arrange
  const emailService = new FakeEmailService()
  const inventoryService = new FakeInventoryService()
  const handler = new OrderCreatedHandler(emailService, inventoryService)

  const event: OrderCreatedEvent = {
    orderId: 'order-123',
    userId: 'user-456',
    items: [{ sku: 'WIDGET-1', qty: 2 }],
  }

  // Act
  await handler.handle(event)

  // Assert
  expect(emailService.sentEmails).toHaveLength(1)
  expect(emailService.sentEmails[0]).toMatchObject({
    to: 'user-456',
    template: 'order_confirmation',
  })
  expect(inventoryService.reservations).toContainEqual({
    sku: 'WIDGET-1',
    qty: 2,
    orderId: 'order-123',
  })
})
```

### Testing Event Ordering and Idempotency

```typescript
test('handler is idempotent — processing same event twice has no additional effect', async () => {
  const event = createOrderEvent({ orderId: 'order-123' })

  await handler.handle(event)
  await handler.handle(event)  // duplicate

  expect(emailService.sentEmails).toHaveLength(1)  // only one email sent
  expect(inventoryService.reservations).toHaveLength(1)  // only one reservation
})
```

---

## 9. External Service Testing Strategies

### Strategy Comparison

| Strategy | Realism | Speed | Reliability | Cost | Best For |
|----------|---------|-------|-------------|------|----------|
| **Mock/Stub** | Low | Fast | High | Free | Unit tests, fast feedback |
| **Record/Replay** | High | Fast (replay) | High | Low | Stable external APIs |
| **Sandbox/Test Environment** | Very High | Slow | Medium (sandbox uptime) | Free-Medium | Payment, shipping APIs |
| **Contract Test** | Medium | Fast | High | Low | Internal microservices |
| **LocalStack** | High | Medium | High | Free (local) | AWS services |

### LocalStack for AWS Services

```typescript
import { LocalstackContainer } from '@testcontainers/localstack'
import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3'

describe('FileStorageService', () => {
  let container: StartedLocalstackContainer
  let s3: S3Client

  beforeAll(async () => {
    container = await new LocalstackContainer('localstack/localstack:3.8')
      .withServices('s3')
      .start()

    s3 = new S3Client({
      endpoint: container.getConnectionUri(),
      region: 'us-east-1',
      credentials: { accessKeyId: 'test', secretAccessKey: 'test' },
      forcePathStyle: true,
    })

    // Create test bucket
    await s3.send(new CreateBucketCommand({ Bucket: 'test-uploads' }))
  }, 60_000)

  test('uploads and retrieves a file', async () => {
    const storage = new FileStorageService(s3, 'test-uploads')

    await storage.upload('reports/q4.pdf', Buffer.from('PDF content'))
    const content = await storage.download('reports/q4.pdf')

    expect(content.toString()).toBe('PDF content')
  })
})
```

### Record/Replay with Polly.js or VCR

Record real HTTP interactions once, replay them in future test runs:

```typescript
// Using Polly.js
import { Polly } from '@pollyjs/core'
import NodeHTTPAdapter from '@pollyjs/adapter-node-http'
import FSPersister from '@pollyjs/persister-fs'

Polly.register(NodeHTTPAdapter)
Polly.register(FSPersister)

describe('GitHubClient', () => {
  let polly: Polly

  beforeEach(() => {
    polly = new Polly('github-api', {
      adapters: ['node-http'],
      persister: 'fs',
      persisterOptions: { fs: { recordingsDir: '__recordings__' } },
      recordIfMissing: process.env.RECORD === 'true',  // Only record when explicitly asked
    })
  })

  afterEach(async () => await polly.stop())

  test('fetches repository info', async () => {
    const client = new GitHubClient()
    const repo = await client.getRepo('facebook/react')

    expect(repo.name).toBe('react')
    expect(repo.stars).toBeGreaterThan(0)
  })
})
```

---

## 10. CI/CD Integration for Integration Tests

### GitHub Actions — Service Containers

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]

jobs:
  integration-tests:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: testdb
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379

    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22' }
      - run: npm ci
      - run: npm run test:integration
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/testdb
          REDIS_URL: redis://localhost:6379
```

### Testcontainers in CI

Testcontainers works in CI with Docker-in-Docker or Docker socket:

```yaml
# GitHub Actions — Testcontainers (no service containers needed)
integration-tests:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with: { node-version: '22' }
    - run: npm ci
    - run: npm run test:integration
      env:
        TESTCONTAINERS_RYUK_DISABLED: 'true'  # Recommended for CI
```

### Test Splitting and Parallelization

```yaml
# Split integration tests across multiple runners
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: npm run test:integration -- --shard=${{ matrix.shard }}/4
```

---

## 11. Microservice Integration Patterns

### Testing Service Mesh / API Gateway

```typescript
// Test that requests route correctly through the API gateway
describe('API Gateway Routing', () => {
  test('routes /api/users to UserService', async () => {
    // Mock UserService
    const userService = await new GenericContainer('wiremock/wiremock:latest')
      .withExposedPorts(8080)
      .start()

    // Configure gateway to point to mock
    const gateway = new APIGateway({
      userServiceUrl: `http://localhost:${userService.getMappedPort(8080)}`,
    })

    const response = await gateway.handle(new Request('GET', '/api/users/123'))

    expect(response.status).toBe(200)
    // Verify the request reached WireMock
  })
})
```

### Testing Saga / Distributed Transactions

```typescript
// Test a multi-step saga with compensating actions
describe('OrderSaga', () => {
  test('compensates when payment fails after inventory reservation', async () => {
    const inventory = new FakeInventoryService()
    inventory.reserveResult = { reservationId: 'res-123' }

    const payment = new FakePaymentService()
    payment.chargeResult = new PaymentDeclinedError()

    const saga = new OrderSaga(inventory, payment)
    const result = await saga.execute(orderRequest)

    // Payment failed → inventory should be released
    expect(result.status).toBe('failed')
    expect(result.reason).toBe('payment_declined')
    expect(inventory.releases).toContainEqual('res-123')
  })
})
```

---

## 12. Integration Test Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| **Shared test database** (no cleanup) | Tests interfere with each other | Use transaction rollback or truncate between tests |
| **Hardcoded ports** | Port conflicts in CI | Use dynamic ports (Testcontainers provides this) |
| **Testing against real external APIs** | Slow, flaky, costs money | Mock, use sandbox, or record/replay |
| **Giant integration tests** | Slow, hard to debug failures | Narrow the integration boundary |
| **No timeout** | Tests hang forever on network issues | Set timeouts on all I/O operations |
| **Order-dependent tests** | Pass individually, fail together | Randomize test order, ensure isolation |
| **Mocking the wrong thing** | Tests pass but integration is broken | Mock at the boundary, not inside it |
| **Not testing error paths** | Happy path works, errors crash | Test timeouts, 5xx, malformed responses |

---

## 13. Integration Test Decision Framework

### Which Integration Test Approach?

| What You're Testing | Approach | Tool |
|--------------------|----------|------|
| Database queries and migrations | Real DB in container | Testcontainers |
| HTTP API you consume (internal) | Contract test | Pact |
| HTTP API you consume (external) | Mock or record/replay | WireMock, Polly.js |
| HTTP API you provide | Schema validation | Schemathesis, Dredd |
| Kafka/RabbitMQ messaging | Real broker in container | Testcontainers |
| AWS services (S3, SQS, DynamoDB) | Local emulator | LocalStack via Testcontainers |
| Cache behavior (Redis) | Real cache in container | Testcontainers |
| Search (Elasticsearch) | Real engine in container | Testcontainers |
| Multi-service workflow | Component test | Docker Compose or Testcontainers |

### Integration Test Checklist

Before writing an integration test, ask:

1. **Could this be a unit test?** If you're only testing your own logic, unit test it
2. **What's the integration boundary?** Test exactly one boundary at a time
3. **How will tests clean up?** Transaction rollback, truncate, or fresh container
4. **What's the timeout?** Set explicit timeouts for all I/O
5. **Can this run in CI?** Ensure containers/services are available
6. **Is it deterministic?** No randomness, no wall clock time, no network to external services
