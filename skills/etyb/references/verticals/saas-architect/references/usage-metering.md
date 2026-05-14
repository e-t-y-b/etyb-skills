# Usage Metering & Rate Limiting — Deep Reference

**Always use `WebSearch` to verify metering platform features, pricing, and API capabilities before giving advice. The usage-based billing space is evolving rapidly — Orb, Metronome, and Lago ship major features quarterly. Last verified: April 2026.**

## Table of Contents
1. [Usage Metering Architecture](#1-usage-metering-architecture)
2. [Metering Platform Selection](#2-metering-platform-selection)
3. [Event Ingestion at Scale](#3-event-ingestion-at-scale)
4. [Aggregation Patterns](#4-aggregation-patterns)
5. [Rate Limiting for SaaS](#5-rate-limiting-for-saas)
6. [Quota Management](#6-quota-management)
7. [Usage Tracking Data Model](#7-usage-tracking-data-model)
8. [Idempotency & Deduplication](#8-idempotency--deduplication)
9. [Real-Time Usage Dashboards](#9-real-time-usage-dashboards)
10. [Cost Attribution & Unit Economics](#10-cost-attribution--unit-economics)
11. [How Leading SaaS Companies Meter](#11-how-leading-saas-companies-meter)
12. [Metering Anti-Patterns](#12-metering-anti-patterns)

---

## 1. Usage Metering Architecture

### The Metering Pipeline

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Ingest  │───▶│  Dedup   │───▶│ Aggregate│───▶│   Rate   │───▶│  Billing │
│  Events  │    │  & Store │    │  & Roll  │    │  & Price │    │  Invoice │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
     │               │               │               │               │
  API calls      Idempotency     Per-hour/day    Apply pricing    Generate
  Compute time   keys, dedup     aggregation     tiers/rates      invoice items
  Storage bytes  window, store   to raw events   per meter        at period end
  Tokens used    raw events                                        
```

### Key Design Decisions

| Decision | Options | When to Choose |
|----------|---------|---------------|
| **Ingestion** | Synchronous API / Async queue / Sidecar | Sync for low-volume; async for high-volume; sidecar for infrastructure metrics |
| **Storage** | OLTP (PostgreSQL) / OLAP (ClickHouse) / Time-series (TimescaleDB) | OLTP for < 1M events/day; OLAP for analytics; time-series for infra metrics |
| **Aggregation** | Real-time (streaming) / Batch (scheduled) / Hybrid | Real-time for quotas/limits; batch for billing; hybrid for both |
| **Rating** | Simple (per-unit) / Tiered / Volume / Credit-based | Depends on pricing model complexity |
| **Billing integration** | Direct to Stripe / Via metering platform (Orb/Metronome) | Direct for simple; platform for complex usage billing |

---

## 2. Metering Platform Selection

### Platform Comparison

| Feature | Orb | Metronome | Lago | Amberflo | m3ter | Stripe Meters |
|---------|-----|-----------|------|----------|-------|---------------|
| **Best for** | Usage-based SaaS | Enterprise usage + commits | Self-hosted billing | Real-time metering | Complex B2B | Simple usage |
| **Event ingestion** | REST API, bulk | REST API, bulk | REST API | REST, SDK, Kafka | REST API | REST API |
| **Aggregation** | Real-time + batch | Real-time + batch | Batch | Real-time | Real-time + batch | Batch |
| **Pricing models** | Usage, tiered, hybrid, credit | Usage, commit, drawdown | All models | Usage, tiered | Usage, hybrid, commit | Per-unit, tiered |
| **Entitlements** | Yes | Yes | Planned | Limited | Yes | No |
| **Self-hosted** | No | No | **Yes (MIT)** | No | No | No |
| **Real-time dashboards** | Yes | Yes | Yes | Yes | Yes | Limited |
| **Invoice generation** | Yes (via Stripe) | Yes (via Stripe) | Yes (built-in) | Via integration | Yes | Via Stripe |
| **Used by** | Vercel, Stytch, Replit | OpenAI, Databricks, Cloudflare | Self-hosters | Various | Enterprise B2B | General |

### When to Use Each

**Orb** — Best all-around usage billing platform:
- Flexible pricing models (usage, tiered, package, credit, hybrid)
- Strong event ingestion with deduplication
- Plan versioning and migration tooling
- Handles complex plan configurations without code changes
- Good for: Developer tools, API companies, infrastructure SaaS

**Metronome** — Best for enterprise usage + commitments:
- Excels at commit/drawdown contracts (common for API companies selling to enterprise)
- Pre-paid credit consumption tracking
- Contract management with custom terms
- Good for: AI/ML APIs, data platforms, enterprise infrastructure

**Lago** — Best for self-hosted / data sovereignty:
- Open-source (MIT license) billing engine
- Self-hostable for full control over billing data
- All pricing models supported
- Good for: Companies that can't send billing data to third parties, data-sovereign environments

**Stripe Meters** — Best for simple usage billing without a separate platform:
- Native Stripe integration (no additional vendor)
- Simple per-unit and tiered pricing
- Good for: Early-stage products with straightforward usage pricing
- Limitations: Less flexible aggregation, no real-time quota enforcement

### Build vs Buy Decision

| Scenario | Recommendation |
|----------|---------------|
| Simple per-unit pricing, < 100K events/day | Stripe Meters |
| Complex usage + subscription hybrid | Orb or Metronome |
| Enterprise with commitments/drawdowns | Metronome |
| Data sovereignty / self-hosting requirement | Lago |
| > 1B events/day with custom aggregation | Custom pipeline + ClickHouse |

---

## 3. Event Ingestion at Scale

### Event Schema Design

```typescript
interface UsageEvent {
    // Required fields
    event_id: string;           // Globally unique, for idempotency
    event_name: string;         // e.g., 'api_call', 'compute_seconds', 'storage_bytes'
    tenant_id: string;          // Which tenant generated this usage
    timestamp: string;          // ISO 8601, when the usage occurred
    value: number;              // The quantity (1 API call, 3600 seconds, 1073741824 bytes)

    // Optional fields
    properties: {               // Billing dimensions for aggregation
        endpoint?: string;      // '/v1/generate', '/v1/embeddings'
        model?: string;         // 'gpt-4', 'claude-3'
        region?: string;        // 'us-east-1', 'eu-west-1'
        tier?: string;          // 'standard', 'premium'
        [key: string]: string | number | boolean;
    };
}
```

### Ingestion API

```typescript
// High-throughput event ingestion endpoint
app.post('/v1/usage/events', async (req, res) => {
    const { events } = req.body;  // Batch of up to 1000 events

    // 1. Validate events
    for (const event of events) {
        validateUsageEvent(event);
    }

    // 2. Write to Kafka/Kinesis for async processing
    await producer.sendBatch({
        topic: 'usage-events',
        messages: events.map(event => ({
            key: event.tenant_id,      // Partition by tenant for ordering
            value: JSON.stringify(event),
            headers: {
                'event-id': event.event_id,  // For deduplication
            },
        })),
    });

    // 3. Respond immediately (events processed async)
    res.status(202).json({
        accepted: events.length,
        message: 'Events accepted for processing',
    });
});
```

### Kafka-Based Event Pipeline

```
┌──────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  API     │───▶│    Kafka     │───▶│   Consumer   │───▶│  ClickHouse  │
│  Gateway │    │  (partitioned│    │  (dedup +    │    │  (raw events │
│          │    │  by tenant)  │    │   validate)  │    │   + rollups) │
└──────────┘    └──────────────┘    └──────┬───────┘    └──────────────┘
                                           │
                                    ┌──────▼───────┐
                                    │   Redis      │
                                    │  (real-time  │
                                    │   counters)  │
                                    └──────────────┘
```

### Direct Database Ingestion (Simpler, Lower Scale)

For < 1M events/day, you can ingest directly into PostgreSQL:

```sql
-- Usage events table with partitioning
CREATE TABLE usage_events (
    id UUID DEFAULT gen_random_uuid(),
    event_id TEXT NOT NULL,         -- Client-provided idempotency key
    tenant_id UUID NOT NULL,
    event_name TEXT NOT NULL,
    value BIGINT NOT NULL,
    properties JSONB,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

-- Monthly partitions
CREATE TABLE usage_events_2026_04 PARTITION OF usage_events
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

-- Unique constraint for deduplication
CREATE UNIQUE INDEX idx_usage_events_dedup
    ON usage_events(event_id, tenant_id);

-- Index for aggregation queries
CREATE INDEX idx_usage_events_tenant_name
    ON usage_events(tenant_id, event_name, recorded_at);
```

---

## 4. Aggregation Patterns

### Real-Time Aggregation (for Quotas & Dashboards)

Use Redis for real-time counters that need sub-second latency:

```typescript
// Real-time counter using Redis
async function recordUsage(tenantId: string, meter: string, value: number): Promise<void> {
    const hourKey = `usage:${tenantId}:${meter}:${formatHour(new Date())}`;
    const dayKey = `usage:${tenantId}:${meter}:${formatDay(new Date())}`;
    const monthKey = `usage:${tenantId}:${meter}:${formatMonth(new Date())}`;

    const pipeline = redis.pipeline();
    pipeline.incrby(hourKey, value);
    pipeline.expire(hourKey, 7200);       // 2 hour TTL
    pipeline.incrby(dayKey, value);
    pipeline.expire(dayKey, 172800);      // 2 day TTL
    pipeline.incrby(monthKey, value);
    pipeline.expire(monthKey, 2764800);   // 32 day TTL
    await pipeline.exec();
}

// Check current usage
async function getCurrentUsage(tenantId: string, meter: string, period: 'hour' | 'day' | 'month'): Promise<number> {
    const key = `usage:${tenantId}:${meter}:${formatPeriod(new Date(), period)}`;
    return parseInt(await redis.get(key) || '0', 10);
}
```

### Batch Aggregation (for Billing)

Billing-grade aggregation needs to be exact. Run batch aggregation jobs from the raw event store:

```sql
-- Hourly rollup job (run every hour)
INSERT INTO usage_rollups (tenant_id, event_name, period_start, period_end, total_value, event_count)
SELECT
    tenant_id,
    event_name,
    date_trunc('hour', recorded_at) AS period_start,
    date_trunc('hour', recorded_at) + interval '1 hour' AS period_end,
    SUM(value) AS total_value,
    COUNT(*) AS event_count
FROM usage_events
WHERE recorded_at >= date_trunc('hour', now() - interval '1 hour')
  AND recorded_at < date_trunc('hour', now())
GROUP BY tenant_id, event_name, date_trunc('hour', recorded_at)
ON CONFLICT (tenant_id, event_name, period_start)
DO UPDATE SET
    total_value = EXCLUDED.total_value,
    event_count = EXCLUDED.event_count,
    updated_at = now();
```

### ClickHouse for Usage Analytics

For high-volume event analytics, ClickHouse is the industry standard:

```sql
-- ClickHouse: usage events table
CREATE TABLE usage_events (
    event_id String,
    tenant_id UUID,
    event_name LowCardinality(String),
    value UInt64,
    properties Map(String, String),
    recorded_at DateTime64(3)
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(recorded_at)
ORDER BY (tenant_id, event_name, recorded_at)
TTL recorded_at + INTERVAL 13 MONTH;

-- Materialized view for hourly rollups (auto-aggregated)
CREATE MATERIALIZED VIEW usage_hourly_mv
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(period_start)
ORDER BY (tenant_id, event_name, period_start)
AS SELECT
    tenant_id,
    event_name,
    toStartOfHour(recorded_at) AS period_start,
    sum(value) AS total_value,
    count() AS event_count
FROM usage_events
GROUP BY tenant_id, event_name, period_start;

-- Query: monthly usage for billing
SELECT
    tenant_id,
    event_name,
    sum(total_value) AS monthly_total
FROM usage_hourly_mv
WHERE period_start >= toStartOfMonth(now())
  AND period_start < toStartOfMonth(now()) + INTERVAL 1 MONTH
  AND tenant_id = {tenant_id:UUID}
GROUP BY tenant_id, event_name;
```

---

## 5. Rate Limiting for SaaS

### Per-Tenant Rate Limiting

```typescript
import { Ratelimit } from '@upstash/ratelimit';
import { Redis } from '@upstash/redis';

// Create rate limiters for different tiers
const rateLimiters = {
    free: new Ratelimit({
        redis: Redis.fromEnv(),
        limiter: Ratelimit.slidingWindow(100, '1 m'),   // 100 requests/minute
        prefix: 'ratelimit:free',
    }),
    pro: new Ratelimit({
        redis: Redis.fromEnv(),
        limiter: Ratelimit.slidingWindow(1000, '1 m'),  // 1000 requests/minute
        prefix: 'ratelimit:pro',
    }),
    enterprise: new Ratelimit({
        redis: Redis.fromEnv(),
        limiter: Ratelimit.slidingWindow(10000, '1 m'), // 10000 requests/minute
        prefix: 'ratelimit:enterprise',
    }),
};

// Middleware
async function rateLimitMiddleware(req: Request, res: Response, next: NextFunction) {
    const tenant = req.tenant;
    const limiter = rateLimiters[tenant.plan] || rateLimiters.free;

    const { success, limit, remaining, reset } = await limiter.limit(tenant.id);

    // Always set rate limit headers
    res.setHeader('X-RateLimit-Limit', limit);
    res.setHeader('X-RateLimit-Remaining', remaining);
    res.setHeader('X-RateLimit-Reset', reset);

    if (!success) {
        res.setHeader('Retry-After', Math.ceil((reset - Date.now()) / 1000));
        return res.status(429).json({
            error: 'rate_limit_exceeded',
            message: `Rate limit exceeded. Try again in ${Math.ceil((reset - Date.now()) / 1000)} seconds.`,
            upgrade_url: '/billing/upgrade',
        });
    }

    next();
}
```

### Rate Limiting Algorithms

| Algorithm | Behavior | Best For |
|-----------|----------|----------|
| **Fixed Window** | N requests per time window (e.g., 100/minute). Resets at window boundary. | Simple, easy to understand. Can have burst at window boundaries. |
| **Sliding Window** | N requests in the last N seconds. Smooth rate enforcement. | Most SaaS APIs. Fair, predictable behavior. |
| **Token Bucket** | Tokens refill at constant rate. Allows bursts up to bucket size. | APIs where short bursts are acceptable (e.g., batch operations). |
| **Leaky Bucket** | Requests processed at constant rate. Queue fills up. | Smoothing traffic. Good for rate-limited downstream services. |

### Redis-Based Sliding Window

```lua
-- Redis Lua script for atomic sliding window rate limiting
-- KEYS[1] = rate limit key
-- ARGV[1] = window size in ms
-- ARGV[2] = max requests
-- ARGV[3] = current timestamp in ms

local key = KEYS[1]
local window = tonumber(ARGV[1])
local max_requests = tonumber(ARGV[2])
local now = tonumber(ARGV[3])
local window_start = now - window

-- Remove expired entries
redis.call('ZREMRANGEBYSCORE', key, '-inf', window_start)

-- Count current requests in window
local current = redis.call('ZCARD', key)

if current < max_requests then
    -- Allow request, add to sorted set
    redis.call('ZADD', key, now, now .. ':' .. math.random(1000000))
    redis.call('EXPIRE', key, math.ceil(window / 1000) + 1)
    return {1, max_requests - current - 1}  -- {allowed, remaining}
else
    return {0, 0}  -- {denied, remaining}
end
```

### Multi-Dimensional Rate Limits

```typescript
// Rate limit per tenant AND per endpoint AND per API key
const limits = {
    global: { per_minute: 1000 },                    // Total for tenant
    per_endpoint: {
        '/v1/generate': { per_minute: 100 },         // Heavy endpoint
        '/v1/embeddings': { per_minute: 500 },        // Lighter endpoint
        '/v1/models': { per_minute: 60 },             // Metadata
    },
    per_api_key: { per_minute: 200 },                // Per individual key
};

async function checkRateLimits(tenant: Tenant, endpoint: string, apiKey: string): Promise<RateLimitResult> {
    const checks = await Promise.all([
        checkLimit(`tenant:${tenant.id}`, limits.global.per_minute),
        checkLimit(`tenant:${tenant.id}:endpoint:${endpoint}`, limits.per_endpoint[endpoint]?.per_minute || 1000),
        checkLimit(`tenant:${tenant.id}:key:${apiKey}`, limits.per_api_key.per_minute),
    ]);

    // Return the most restrictive result
    const denied = checks.find(c => !c.allowed);
    if (denied) return denied;

    return { allowed: true, remaining: Math.min(...checks.map(c => c.remaining)) };
}
```

---

## 6. Quota Management

### Quota Types

| Quota Type | Enforcement | Example |
|-----------|------------|---------|
| **Hard limit** | Block the action | "You've used 100/100 projects. Upgrade to create more." |
| **Soft limit** | Warn but allow | "You're at 90% of your API quota. Consider upgrading." |
| **Overage** | Allow with charges | "You've exceeded your included API calls. Additional calls: $0.002 each." |
| **Burst** | Allow temporary spike, enforce on average | "100 req/s sustained, burst to 200 req/s for 30 seconds." |

### Quota Enforcement Architecture

```typescript
interface QuotaConfig {
    meter: string;              // 'api_calls', 'storage_bytes', 'seats'
    period: 'monthly' | 'daily' | 'hourly' | 'none';  // Reset period
    limit: number;              // Maximum value (-1 for unlimited)
    soft_limit_pct: number;     // Alert at this % (e.g., 0.8 for 80%)
    enforcement: 'hard' | 'soft' | 'overage';
    overage_rate?: number;      // Cost per unit over the limit (cents)
}

async function enforceQuota(
    tenantId: string,
    quota: QuotaConfig,
    requestedAmount: number
): Promise<QuotaResult> {
    if (quota.limit === -1) {
        return { allowed: true, remaining: -1, limit: -1 };
    }

    const currentUsage = await getCurrentUsage(tenantId, quota.meter, quota.period);
    const afterUsage = currentUsage + requestedAmount;

    // Hard limit: block if over
    if (quota.enforcement === 'hard' && afterUsage > quota.limit) {
        return {
            allowed: false,
            remaining: Math.max(0, quota.limit - currentUsage),
            limit: quota.limit,
            current: currentUsage,
            error: `Quota exceeded: ${quota.meter}. Current: ${currentUsage}/${quota.limit}.`,
        };
    }

    // Overage: allow but track overage
    if (quota.enforcement === 'overage' && afterUsage > quota.limit) {
        const overageAmount = afterUsage - quota.limit;
        await recordOverage(tenantId, quota.meter, overageAmount, quota.overage_rate);
    }

    // Soft limit: allow but warn
    if (currentUsage / quota.limit >= quota.soft_limit_pct) {
        await notifyQuotaApproaching(tenantId, quota.meter, currentUsage, quota.limit);
    }

    return {
        allowed: true,
        remaining: Math.max(0, quota.limit - afterUsage),
        limit: quota.limit,
        current: afterUsage,
    };
}
```

### Usage Alert Notifications

```typescript
const alertThresholds = [
    { pct: 0.50, message: 'You have used 50% of your {meter} quota.' },
    { pct: 0.80, message: 'You have used 80% of your {meter} quota. Consider upgrading.' },
    { pct: 0.90, message: 'You have used 90% of your {meter} quota. Upgrade to avoid service interruption.' },
    { pct: 1.00, message: 'You have reached your {meter} quota limit.' },
];

async function checkAndNotify(tenantId: string, meter: string): Promise<void> {
    const usage = await getCurrentUsage(tenantId, meter, 'monthly');
    const limit = await getQuotaLimit(tenantId, meter);
    const pct = usage / limit;

    for (const threshold of alertThresholds) {
        if (pct >= threshold.pct) {
            const alreadyNotified = await wasNotified(tenantId, meter, threshold.pct);
            if (!alreadyNotified) {
                await sendQuotaAlert(tenantId, threshold.message.replace('{meter}', meter));
                await markNotified(tenantId, meter, threshold.pct);
            }
        }
    }
}
```

---

## 7. Usage Tracking Data Model

```sql
-- Meter definitions
CREATE TABLE meters (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,           -- 'api_calls', 'compute_seconds', 'storage_bytes'
    display_name TEXT NOT NULL,           -- 'API Calls', 'Compute Time', 'Storage'
    unit TEXT NOT NULL,                   -- 'calls', 'seconds', 'bytes'
    aggregation TEXT NOT NULL,            -- 'sum', 'max', 'count', 'last'
    event_name TEXT NOT NULL,             -- Event name to match against
    filter_properties JSONB,             -- Optional: only count events matching these properties
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Raw usage events (partitioned by month)
CREATE TABLE usage_events (
    id UUID DEFAULT gen_random_uuid(),
    event_id TEXT NOT NULL,              -- Client-provided idempotency key
    tenant_id UUID NOT NULL,
    event_name TEXT NOT NULL,
    value BIGINT NOT NULL,
    properties JSONB,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

-- Pre-aggregated rollups (for billing and dashboards)
CREATE TABLE usage_rollups (
    id UUID DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    meter_id UUID NOT NULL REFERENCES meters(id),
    period_start TIMESTAMPTZ NOT NULL,
    period_end TIMESTAMPTZ NOT NULL,
    granularity TEXT NOT NULL,           -- 'hourly', 'daily', 'monthly'
    total_value BIGINT NOT NULL,
    event_count BIGINT NOT NULL,
    dimensions JSONB,                    -- Aggregation dimensions (endpoint, model, region)
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (tenant_id, meter_id, period_start, granularity, dimensions)
);

-- Quota allocations per tenant
CREATE TABLE tenant_quotas (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    meter_id UUID NOT NULL REFERENCES meters(id),
    quota_limit BIGINT NOT NULL,         -- -1 for unlimited
    period TEXT NOT NULL,                -- 'monthly', 'daily'
    enforcement TEXT DEFAULT 'hard',     -- 'hard', 'soft', 'overage'
    overage_rate_cents INT,             -- Cost per unit over limit
    source TEXT DEFAULT 'plan',         -- 'plan', 'override', 'addon'
    UNIQUE (tenant_id, meter_id)
);

-- Indexes
CREATE INDEX idx_usage_events_tenant ON usage_events(tenant_id, event_name, recorded_at);
CREATE INDEX idx_usage_rollups_tenant ON usage_rollups(tenant_id, meter_id, period_start);
```

---

## 8. Idempotency & Deduplication

### Why Idempotency Matters for Metering

Usage events can be delivered more than once due to:
- Client retries (network timeout, 5xx response)
- Queue redelivery (consumer crash before ACK)
- Webhook retry (billing system retry)

Double-counted usage = overcharging customers = trust erosion + refund requests.

### Client-Side Idempotency

```typescript
// Client SDK: generate deterministic event IDs
function createUsageEvent(tenantId: string, eventName: string, value: number): UsageEvent {
    // Deterministic ID = same event always gets same ID
    const eventId = crypto.createHash('sha256')
        .update(`${tenantId}:${eventName}:${value}:${new Date().toISOString().slice(0, 13)}`)
        .digest('hex');

    return {
        event_id: eventId,
        tenant_id: tenantId,
        event_name: eventName,
        value,
        timestamp: new Date().toISOString(),
    };
}
```

### Server-Side Deduplication

```typescript
// Option 1: Database UNIQUE constraint (simplest)
async function insertEvent(event: UsageEvent): Promise<boolean> {
    try {
        await db.usageEvents.create(event);
        return true;  // New event
    } catch (error) {
        if (error.code === '23505') {  // Unique violation (PostgreSQL)
            return false;  // Duplicate, already processed
        }
        throw error;
    }
}

// Option 2: Redis-based dedup window (faster for high throughput)
async function isDuplicate(eventId: string): Promise<boolean> {
    // SETNX returns 1 if key was set (new), 0 if already exists (duplicate)
    const result = await redis.set(`dedup:${eventId}`, '1', 'NX', 'EX', 86400);  // 24h window
    return result === null;  // null = key already existed = duplicate
}

// Option 3: Kafka-based dedup (for streaming pipelines)
// Use Kafka's exactly-once semantics with idempotent producer + transactions
const producer = kafka.producer({
    idempotent: true,
    transactionalId: 'usage-metering-producer',
});
```

---

## 9. Real-Time Usage Dashboards

### Customer-Facing Usage Dashboard

```typescript
// API endpoint for tenant's usage dashboard
app.get('/api/usage', async (req, res) => {
    const tenantId = req.tenantId;
    const period = req.query.period || 'current_month';

    const [usage, quotas, history] = await Promise.all([
        // Current period usage per meter
        getUsageSummary(tenantId, period),
        // Quota limits per meter
        getQuotas(tenantId),
        // Daily usage for the chart
        getDailyUsageHistory(tenantId, 30),  // Last 30 days
    ]);

    res.json({
        meters: usage.map(u => ({
            name: u.meter_name,
            display_name: u.display_name,
            current: u.total_value,
            limit: quotas[u.meter_name]?.limit || -1,
            unit: u.unit,
            pct_used: quotas[u.meter_name]?.limit > 0
                ? u.total_value / quotas[u.meter_name].limit
                : 0,
        })),
        history: history,
        billing_period: {
            start: period.start,
            end: period.end,
            days_remaining: period.daysRemaining,
        },
    });
});
```

### Admin Dashboard Metrics

```sql
-- Top tenants by usage (admin view)
SELECT
    t.name AS tenant_name,
    t.plan,
    SUM(ur.total_value) AS total_api_calls,
    tq.quota_limit,
    ROUND(SUM(ur.total_value)::NUMERIC / NULLIF(tq.quota_limit, 0) * 100, 1) AS pct_used
FROM usage_rollups ur
JOIN tenants t ON t.id = ur.tenant_id
LEFT JOIN tenant_quotas tq ON tq.tenant_id = t.id AND tq.meter_id = ur.meter_id
WHERE ur.granularity = 'daily'
  AND ur.period_start >= date_trunc('month', now())
  AND ur.meter_id = (SELECT id FROM meters WHERE name = 'api_calls')
GROUP BY t.id, t.name, t.plan, tq.quota_limit
ORDER BY total_api_calls DESC
LIMIT 20;
```

---

## 10. Cost Attribution & Unit Economics

### Per-Tenant Cost Tracking

Understanding your cost per tenant is essential for pricing:

```typescript
interface TenantCostAttribution {
    tenant_id: string;
    period: string;           // '2026-04'
    costs: {
        compute: number;      // CPU/memory hours * unit cost
        storage: number;      // GB-months * unit cost
        bandwidth: number;    // GB transferred * unit cost
        third_party: number;  // External API costs (OpenAI, Twilio, etc.)
        database: number;     // Proportional DB cost
        support: number;      // Support ticket cost attribution
    };
    revenue: number;          // What this tenant pays us
    margin: number;           // revenue - total_cost
    margin_pct: number;       // margin / revenue
}
```

### Infrastructure Cost Tools

| Tool | What It Does | Best For |
|------|-------------|----------|
| **Kubecost** | Per-namespace/pod cost allocation in Kubernetes | K8s-based SaaS with per-tenant namespaces |
| **Vantage** | Cloud cost management across AWS/GCP/Azure | Multi-cloud cost visibility |
| **AWS Cost & Usage Reports** | Detailed AWS resource-level costs | AWS-only SaaS |
| **OpenCost** | Open-source Kubernetes cost monitoring | K8s cost attribution without vendor lock-in |
| **Infracost** | Cost estimates for Terraform changes | Estimating per-tenant infrastructure cost before provisioning |

### Unit Economics Calculations

```
Gross Margin per Tenant = (Revenue - COGS) / Revenue

COGS includes:
├── Compute (proportional CPU/memory)
├── Storage (proportional disk/S3)
├── Bandwidth (proportional egress)
├── Third-party APIs (per-tenant usage)
├── Database (proportional query/storage)
└── Support (proportional ticket volume)

Target: > 70% gross margin for healthy SaaS
Warning: < 50% gross margin — pricing or architecture problem
```

---

## 11. How Leading SaaS Companies Meter

### Vercel
- **Model**: Usage-based (bandwidth, serverless function invocations, build minutes, edge middleware invocations)
- **Metering**: Custom pipeline → Orb for billing
- **Pricing**: Free tier with generous limits → Pro ($20/mo + usage) → Enterprise (custom)
- **Key insight**: Bundle a base platform fee with generous included usage, charge for overages

### OpenAI / Anthropic
- **Model**: Token-based (input tokens + output tokens, different rates per model)
- **Metering**: Custom pipeline → Metronome for billing
- **Pricing**: Pay-as-you-go with per-token rates, or prepaid credits with volume discounts
- **Key insight**: Different price points per model/capability creates natural upsell

### Twilio
- **Model**: Per-message, per-minute, per-number pricing
- **Metering**: Custom high-throughput pipeline (billions of events/day)
- **Pricing**: Pay-as-you-go with volume discounts at committed tiers
- **Key insight**: Simple per-unit pricing makes cost predictable for customers

### Supabase
- **Model**: Hybrid (base plan + usage for database, storage, bandwidth, edge functions)
- **Pricing**: Free → Pro ($25/mo + usage) → Team ($599/mo) → Enterprise
- **Key insight**: Generous free tier drives PLG adoption, usage overages drive expansion revenue

### Datadog
- **Model**: Per-host, per-GB ingested, per-span (different meters for different products)
- **Pricing**: Per-host pricing with committed annual contracts for enterprise
- **Key insight**: Multi-product metering where each product has its own pricing dimension

---

## 12. Metering Anti-Patterns

### 1. Metering After the Fact

**Problem:** Building billing first, then trying to add metering. Leads to inaccurate usage data.
**Fix:** Instrument usage events from day one, even if you start with flat-rate pricing. You need the data when you eventually move to usage-based.

### 2. Synchronous Metering in the Hot Path

**Problem:** Blocking API responses on metering writes. If metering is slow, the whole API is slow.
**Fix:** Record events asynchronously. The API call succeeds immediately; metering happens in the background.

### 3. Missing Idempotency

**Problem:** No deduplication, leading to double-counted usage and customer overcharges.
**Fix:** Require `event_id` on every usage event. Deduplicate at the ingestion layer.

### 4. Single Counter Instead of Events

**Problem:** Using `INCREMENT counter` instead of recording individual events. Loses all dimension data.
**Fix:** Record individual events with properties. Aggregate for billing. The raw events are your audit trail.

### 5. Billing-Metering Mismatch

**Problem:** Metering in one system, billing in another, with no reconciliation. Amounts drift.
**Fix:** Use a single source of truth for usage (metering system) and reconcile with billing invoices.

### 6. No Backfill Strategy

**Problem:** Metering pipeline goes down, usage events are lost, customers aren't billed correctly.
**Fix:** Store raw events durably (Kafka with retention, S3 backup). Build a backfill pipeline that can replay events.
