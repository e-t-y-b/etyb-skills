# Tenant Isolation & Security — Deep Reference

**Always use `WebSearch` to verify cloud provider isolation features, Kubernetes multi-tenancy tools, and compliance requirements before giving advice. Cloud provider capabilities and compliance standards evolve frequently. Last verified: April 2026.**

## Table of Contents
1. [Isolation Models & Framework](#1-isolation-models--framework)
2. [Data Isolation](#2-data-isolation)
3. [Compute Isolation](#3-compute-isolation)
4. [Network Isolation](#4-network-isolation)
5. [Storage Isolation](#5-storage-isolation)
6. [Noisy Neighbor Prevention](#6-noisy-neighbor-prevention)
7. [Cross-Tenant Attack Prevention](#7-cross-tenant-attack-prevention)
8. [Tenant-Aware IAM & Access Control](#8-tenant-aware-iam--access-control)
9. [Encryption Strategies](#9-encryption-strategies)
10. [Kubernetes Multi-Tenancy](#10-kubernetes-multi-tenancy)
11. [Compliance-Driven Isolation](#11-compliance-driven-isolation)
12. [Tenant-Aware Observability & Audit](#12-tenant-aware-observability--audit)

---

## 1. Isolation Models & Framework

### The Isolation Spectrum

```
Weakest                                                              Strongest
   │                                                                    │
   ▼                                                                    ▼
Application    Row-Level     Schema-Per-   Database-Per-  VPC-Per-   Account-Per-
Layer Only     Security      Tenant        Tenant         Tenant     Tenant
   │           (RLS)            │              │             │          │
   │              │             │              │             │          │
Shared DB    Shared DB     Shared Server   Dedicated DB  Dedicated  Dedicated
Shared Code  Shared Code   Shared Code     Shared Code   Network    Everything
No DB Guard  DB Enforced   Schema Walls    DB Walls      Infra      AWS Account
```

### AWS SaaS Lens Isolation Framework

AWS's Well-Architected SaaS Lens defines isolation across dimensions:

| Dimension | Pool | Bridge | Silo |
|-----------|------|--------|------|
| **Compute** | Shared containers/Lambda | Namespaced containers | Dedicated ECS/EKS cluster |
| **Storage** | Shared bucket, prefix isolation | Dedicated prefix + IAM | Dedicated bucket |
| **Database** | Shared DB + RLS | Shared server, separate schemas/DBs | Dedicated RDS instance |
| **Network** | Shared VPC, security groups | Shared VPC, network policies | Dedicated VPC |
| **Identity** | Shared user pool, tenant claims | Shared pool, tenant scopes | Separate user pool per tenant |
| **Encryption** | Shared KMS key | Shared key, tenant-prefixed | Per-tenant KMS key |

### Choosing Isolation Level Per Layer

Not every layer needs the same isolation. A common pattern is different isolation strengths for different concerns:

```
┌─────────────────────────────────────────────────────┐
│                Tenant: Acme Corp                     │
│                                                      │
│  Compute:   Pool (shared K8s cluster, namespaced)   │  ← Medium
│  Database:  Bridge (schema-per-tenant, RLS)          │  ← Medium-High
│  Storage:   Pool (shared S3, prefix isolation)       │  ← Medium
│  Network:   Pool (shared VPC, security groups)       │  ← Low-Medium
│  Encryption: Silo (per-tenant KMS key)              │  ← High
│  Audit:     Silo (per-tenant audit trail)           │  ← High
└─────────────────────────────────────────────────────┘
```

---

## 2. Data Isolation

### Row-Level Security (RLS) — Pool Model

See `multi-tenancy.md` for detailed RLS implementation. Key points for isolation:

```sql
-- Defense-in-depth: FORCE RLS even for table owner
ALTER TABLE documents FORCE ROW LEVEL SECURITY;

-- Policy: tenant can only see their own rows
CREATE POLICY tenant_isolation ON documents
    FOR ALL
    USING (tenant_id = current_setting('app.current_tenant_id')::UUID)
    WITH CHECK (tenant_id = current_setting('app.current_tenant_id')::UUID);

-- CRITICAL: Test that RLS actually works
-- This should return 0 rows (not tenant B's data)
SET app.current_tenant_id = 'tenant-a-uuid';
SELECT * FROM documents WHERE tenant_id = 'tenant-b-uuid';
-- ✅ RLS blocks this — returns 0 rows even though WHERE matches
```

### Schema-Level Isolation — Bridge Model

```sql
-- Each tenant gets a separate schema
CREATE SCHEMA tenant_acme;
CREATE SCHEMA tenant_beta;

-- Tables are schema-scoped — no cross-tenant access possible
-- (unless you explicitly cross schemas)
SET search_path TO tenant_acme;
SELECT * FROM documents;  -- Only sees tenant_acme.documents

-- PREVENT cross-schema access: revoke USAGE on other schemas
REVOKE ALL ON SCHEMA tenant_beta FROM tenant_acme_role;
```

### Database-Level Isolation — Silo Model

Each tenant gets a dedicated database instance. Strongest data isolation.

```typescript
// Tenant routing to dedicated database
class TenantDatabaseRouter {
    private connections = new Map<string, Pool>();

    async getConnection(tenantId: string): Promise<Pool> {
        if (this.connections.has(tenantId)) {
            return this.connections.get(tenantId)!;
        }

        const tenant = await controlPlane.getTenant(tenantId);

        if (tenant.isolation_model === 'silo') {
            // Dedicated database
            const pool = new Pool({
                connectionString: tenant.connection_string,
                max: 20,
                idleTimeoutMillis: 30000,
            });
            this.connections.set(tenantId, pool);
            return pool;
        }

        // Pool/bridge model: shared database
        return this.sharedPool;
    }
}
```

### Per-Tenant Encryption at Rest

Encrypt each tenant's data with a separate key so that even with database access, one tenant's data can't be read with another tenant's key:

```sql
-- Per-tenant encryption using pgcrypto + per-tenant keys
CREATE TABLE sensitive_data (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    encrypted_payload BYTEA NOT NULL,  -- Encrypted with tenant-specific key
    encryption_key_id TEXT NOT NULL,    -- Reference to KMS key
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Application-level encryption (recommended over DB-level for key management)
-- Encrypt before INSERT, decrypt after SELECT
```

```typescript
// Application-level per-tenant encryption
import { KMSClient, EncryptCommand, DecryptCommand } from '@aws-sdk/client-kms';

class TenantEncryption {
    private kms = new KMSClient({});

    async encrypt(tenantId: string, plaintext: Buffer): Promise<EncryptedData> {
        const keyId = await this.getTenantKeyId(tenantId);

        const result = await this.kms.send(new EncryptCommand({
            KeyId: keyId,
            Plaintext: plaintext,
            EncryptionContext: {
                tenant_id: tenantId,  // Bound to tenant — can't decrypt with wrong context
            },
        }));

        return {
            ciphertext: result.CiphertextBlob,
            keyId,
        };
    }

    async decrypt(tenantId: string, ciphertext: Buffer, keyId: string): Promise<Buffer> {
        const result = await this.kms.send(new DecryptCommand({
            KeyId: keyId,
            CiphertextBlob: ciphertext,
            EncryptionContext: {
                tenant_id: tenantId,  // Must match — prevents cross-tenant decryption
            },
        }));

        return Buffer.from(result.Plaintext);
    }

    private async getTenantKeyId(tenantId: string): Promise<string> {
        // Look up or create per-tenant KMS key
        const tenant = await db.tenants.findById(tenantId);
        if (tenant.kms_key_id) return tenant.kms_key_id;

        // Create a new KMS key for this tenant
        const key = await this.kms.send(new CreateKeyCommand({
            Description: `Tenant encryption key: ${tenantId}`,
            Tags: [{ TagKey: 'tenant_id', TagValue: tenantId }],
        }));

        await db.tenants.update(tenantId, { kms_key_id: key.KeyMetadata.KeyId });
        return key.KeyMetadata.KeyId;
    }
}
```

---

## 3. Compute Isolation

### Shared Cluster with Namespaces (Pool/Bridge)

```yaml
# Kubernetes: per-tenant namespace with resource quotas
apiVersion: v1
kind: Namespace
metadata:
  name: tenant-acme
  labels:
    tenant: acme
    tier: pro
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: tenant-quota
  namespace: tenant-acme
spec:
  hard:
    requests.cpu: "4"           # Max 4 CPU cores
    requests.memory: "8Gi"      # Max 8GB memory
    limits.cpu: "8"
    limits.memory: "16Gi"
    pods: "20"                  # Max 20 pods
    services: "10"
---
apiVersion: v1
kind: LimitRange
metadata:
  name: tenant-limits
  namespace: tenant-acme
spec:
  limits:
    - type: Container
      default:
        cpu: "500m"
        memory: "512Mi"
      defaultRequest:
        cpu: "250m"
        memory: "256Mi"
      max:
        cpu: "2"
        memory: "4Gi"
```

### Container-Per-Tenant (Bridge/Silo)

For stronger isolation, run tenant workloads in dedicated containers:

```typescript
// Provision dedicated container per tenant
async function provisionTenantCompute(tenant: Tenant): Promise<void> {
    // Option 1: Kubernetes Deployment per tenant
    const deployment = {
        apiVersion: 'apps/v1',
        kind: 'Deployment',
        metadata: {
            name: `app-${tenant.slug}`,
            namespace: `tenant-${tenant.slug}`,
        },
        spec: {
            replicas: tenant.plan === 'enterprise' ? 3 : 1,
            selector: { matchLabels: { tenant: tenant.slug } },
            template: {
                metadata: { labels: { tenant: tenant.slug } },
                spec: {
                    containers: [{
                        name: 'app',
                        image: `app:${APP_VERSION}`,
                        env: [
                            { name: 'TENANT_ID', value: tenant.id },
                            { name: 'DATABASE_URL', value: tenant.connectionString },
                        ],
                        resources: RESOURCE_LIMITS[tenant.plan],
                    }],
                },
            },
        },
    };

    await k8sClient.createNamespacedDeployment(`tenant-${tenant.slug}`, deployment);
}
```

### Serverless Isolation (Lambda/Cloud Functions)

Serverless functions provide natural isolation — each invocation runs in its own sandbox:

```typescript
// AWS Lambda: tenant context via environment or invocation payload
// Each invocation is isolated — no shared memory between tenants

// Fly.io Machines: per-tenant machines
async function provisionFlyMachine(tenant: Tenant): Promise<void> {
    const machine = await fly.machines.create({
        app_name: 'saas-platform',
        config: {
            image: 'registry.fly.io/saas-app:latest',
            env: {
                TENANT_ID: tenant.id,
                DATABASE_URL: tenant.connectionString,
            },
            guest: {
                cpus: tenant.plan === 'enterprise' ? 4 : 1,
                memory_mb: tenant.plan === 'enterprise' ? 4096 : 512,
            },
            auto_destroy: true,  // Scale to zero when idle
        },
        region: tenant.region,
    });
}
```

### Firecracker MicroVMs (Strongest Compute Isolation)

For maximum isolation (security-sensitive workloads), Firecracker microVMs provide hardware-level isolation:

```
┌─────────────────────────────────────────────┐
│              Host Machine                    │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐    │
│  │ MicroVM │  │ MicroVM │  │ MicroVM │    │
│  │ Tenant A│  │ Tenant B│  │ Tenant C│    │
│  │         │  │         │  │         │    │
│  │ App     │  │ App     │  │ App     │    │
│  │ Runtime │  │ Runtime │  │ Runtime │    │
│  └─────────┘  └─────────┘  └─────────┘    │
│       ▲              ▲             ▲        │
│       └──── KVM Hypervisor ────────┘        │
└─────────────────────────────────────────────┘
```

Used by: AWS Lambda, Fly.io, Cloudflare Workers (V8 isolates)

---

## 4. Network Isolation

### Shared VPC with Security Groups (Pool)

```terraform
# AWS: Security group per tenant tier
resource "aws_security_group" "tenant_enterprise" {
  name        = "tenant-enterprise-sg"
  description = "Security group for enterprise tier tenants"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Enterprise tenants can access dedicated resources
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.dedicated_db.id]
  }
}
```

### Kubernetes Network Policies (Bridge)

```yaml
# Deny all traffic between tenant namespaces
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-cross-tenant
  namespace: tenant-acme
spec:
  podSelector: {}  # Apply to all pods in namespace
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              tenant: acme  # Only allow traffic from same tenant
        - namespaceSelector:
            matchLabels:
              system: ingress  # Allow from ingress controller
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              tenant: acme
        - namespaceSelector:
            matchLabels:
              system: shared-services  # DNS, logging, etc.
    - ports:
        - port: 53
          protocol: UDP  # DNS
```

### VPC Per Tenant (Silo)

```terraform
# Dedicated VPC per enterprise tenant
resource "aws_vpc" "tenant_vpc" {
  for_each = var.silo_tenants

  cidr_block = each.value.cidr_block

  tags = {
    Name      = "tenant-${each.key}-vpc"
    Tenant    = each.key
    Isolation = "silo"
  }
}

# VPC Peering to control plane (for management)
resource "aws_vpc_peering_connection" "tenant_to_control" {
  for_each = var.silo_tenants

  vpc_id      = aws_vpc.tenant_vpc[each.key].id
  peer_vpc_id = var.control_plane_vpc_id

  auto_accept = true
}
```

### AWS PrivateLink (Enterprise Feature)

For enterprise customers who want to access your SaaS via their own VPC without traversing the internet:

```terraform
# Create a VPC Endpoint Service (your side)
resource "aws_vpc_endpoint_service" "saas_api" {
  acceptance_required        = true
  network_load_balancer_arns = [aws_lb.saas_nlb.arn]

  allowed_principals = [
    "arn:aws:iam::${var.enterprise_tenant_account_id}:root"
  ]
}

# Customer creates a VPC Endpoint (their side)
# They get a private DNS name that resolves to their VPC
# Traffic never leaves AWS network
```

---

## 5. Storage Isolation

### S3 Prefix-Based Isolation (Pool)

```typescript
// S3: tenant-prefixed paths
const uploadPath = `tenants/${tenantId}/uploads/${filename}`;
await s3.putObject({
    Bucket: SHARED_BUCKET,
    Key: uploadPath,
    Body: fileBuffer,
    ServerSideEncryption: 'aws:kms',
    SSEKMSKeyId: tenantKmsKeyId,  // Per-tenant encryption key
});

// IAM policy: restrict access to tenant prefix
const policy = {
    Version: '2012-10-17',
    Statement: [{
        Effect: 'Allow',
        Action: ['s3:GetObject', 's3:PutObject', 's3:DeleteObject'],
        Resource: `arn:aws:s3:::${SHARED_BUCKET}/tenants/${tenantId}/*`,
    }],
};
```

### S3 Bucket Per Tenant (Silo)

```typescript
// Create dedicated bucket per enterprise tenant
async function provisionTenantStorage(tenant: Tenant): Promise<void> {
    const bucketName = `${APP_NAME}-tenant-${tenant.slug}-${tenant.region}`;

    await s3.createBucket({
        Bucket: bucketName,
        CreateBucketConfiguration: {
            LocationConstraint: tenant.region,
        },
    });

    // Enable encryption with tenant KMS key
    await s3.putBucketEncryption({
        Bucket: bucketName,
        ServerSideEncryptionConfiguration: {
            Rules: [{
                ApplyServerSideEncryptionByDefault: {
                    SSEAlgorithm: 'aws:kms',
                    KMSMasterKeyID: tenant.kmsKeyId,
                },
                BucketKeyEnabled: true,
            }],
        },
    });

    // Block public access
    await s3.putPublicAccessBlock({
        Bucket: bucketName,
        PublicAccessBlockConfiguration: {
            BlockPublicAcls: true,
            IgnorePublicAcls: true,
            BlockPublicPolicy: true,
            RestrictPublicBuckets: true,
        },
    });
}
```

---

## 6. Noisy Neighbor Prevention

### The Noisy Neighbor Problem

One tenant's heavy usage degrades performance for all other tenants sharing the same resources.

```
Tenant A: Normal usage     ──▶  [  CPU  ] ──▶ 50ms response
Tenant B: Normal usage     ──▶  [  CPU  ] ──▶ 50ms response
Tenant C: HEAVY BATCH JOB  ──▶  [  CPU  ] ──▶ 5000ms response  ← All tenants affected
```

### Resource Quotas & Limits

```typescript
// Per-tenant resource limits
const RESOURCE_LIMITS = {
    free: {
        max_concurrent_requests: 10,
        max_request_rate_per_second: 5,
        max_db_connections: 3,
        max_cpu_time_per_request_ms: 5000,
        max_memory_per_request_mb: 128,
        max_background_jobs: 2,
    },
    pro: {
        max_concurrent_requests: 100,
        max_request_rate_per_second: 50,
        max_db_connections: 10,
        max_cpu_time_per_request_ms: 30000,
        max_memory_per_request_mb: 512,
        max_background_jobs: 20,
    },
    enterprise: {
        max_concurrent_requests: 1000,
        max_request_rate_per_second: 500,
        max_db_connections: 50,
        max_cpu_time_per_request_ms: 60000,
        max_memory_per_request_mb: 2048,
        max_background_jobs: 100,
    },
};
```

### Connection Pool Per Tenant

```typescript
import { Pool } from 'pg';

class TenantConnectionPool {
    private pools = new Map<string, Pool>();

    getPool(tenantId: string, plan: string): Pool {
        if (this.pools.has(tenantId)) {
            return this.pools.get(tenantId)!;
        }

        const maxConnections = {
            free: 3,
            pro: 10,
            enterprise: 50,
        }[plan] || 3;

        const pool = new Pool({
            connectionString: DATABASE_URL,
            max: maxConnections,
            idleTimeoutMillis: 30000,
            connectionTimeoutMillis: 5000,
            // Set tenant context on every new connection
            async connect(client) {
                await client.query('SET app.current_tenant_id = $1', [tenantId]);
            },
        });

        this.pools.set(tenantId, pool);
        return pool;
    }
}
```

### Priority Queues Per Tenant Tier

```typescript
// BullMQ: separate queues per tenant tier
const queues = {
    enterprise: new Queue('jobs-enterprise', {
        connection: redis,
        defaultJobOptions: { priority: 1 },  // Highest priority
    }),
    pro: new Queue('jobs-pro', {
        connection: redis,
        defaultJobOptions: { priority: 5 },
    }),
    free: new Queue('jobs-free', {
        connection: redis,
        defaultJobOptions: { priority: 10 },  // Lowest priority
    }),
};

// Workers: process enterprise first
const worker = new Worker('jobs-*', processJob, {
    connection: redis,
    concurrency: 50,
    // Enterprise queue gets more worker capacity
});
```

### Circuit Breaker Per Tenant

```typescript
import CircuitBreaker from 'opossum';

class TenantCircuitBreaker {
    private breakers = new Map<string, CircuitBreaker>();

    getBreaker(tenantId: string): CircuitBreaker {
        if (this.breakers.has(tenantId)) {
            return this.breakers.get(tenantId)!;
        }

        const breaker = new CircuitBreaker(async (fn: Function) => fn(), {
            timeout: 10000,           // 10s timeout per request
            errorThresholdPercentage: 50,  // Open circuit at 50% error rate
            resetTimeout: 30000,      // Try again after 30s
            volumeThreshold: 10,      // Min requests before triggering
            name: `tenant-${tenantId}`,
        });

        breaker.on('open', () => {
            log.warn(`Circuit breaker OPEN for tenant ${tenantId}`);
            // Don't affect other tenants — only this tenant's requests fail fast
        });

        this.breakers.set(tenantId, breaker);
        return breaker;
    }
}
```

---

## 7. Cross-Tenant Attack Prevention

### IDOR (Insecure Direct Object References)

The #1 cross-tenant vulnerability. An attacker changes an ID in a URL/API call to access another tenant's resource.

```typescript
// VULNERABLE: No tenant check on resource access
app.get('/api/documents/:id', async (req, res) => {
    const doc = await db.documents.findById(req.params.id);
    res.json(doc);  // ❌ Returns doc regardless of tenant
});

// SECURE: Always scope by tenant
app.get('/api/documents/:id', async (req, res) => {
    const doc = await db.documents.findOne({
        id: req.params.id,
        tenant_id: req.tenantId,  // ✅ Scoped to current tenant
    });
    if (!doc) return res.status(404).json({ error: 'Not found' });
    res.json(doc);
});
```

### Cross-Tenant Testing Checklist

```typescript
// Automated cross-tenant isolation tests
describe('Tenant Isolation', () => {
    let tenantA: Tenant;
    let tenantB: Tenant;
    let docInTenantA: Document;

    beforeAll(async () => {
        tenantA = await createTestTenant('tenant-a');
        tenantB = await createTestTenant('tenant-b');
        docInTenantA = await createDocument(tenantA.id, { title: 'Secret' });
    });

    // Test every API endpoint for cross-tenant access
    test('GET /api/documents/:id - cannot access other tenant document', async () => {
        const response = await api
            .get(`/api/documents/${docInTenantA.id}`)
            .set('Authorization', `Bearer ${tenantB.token}`);

        expect(response.status).toBe(404);  // Not 200, not 403
    });

    test('PUT /api/documents/:id - cannot modify other tenant document', async () => {
        const response = await api
            .put(`/api/documents/${docInTenantA.id}`)
            .set('Authorization', `Bearer ${tenantB.token}`)
            .send({ title: 'Hacked' });

        expect(response.status).toBe(404);

        // Verify document was not modified
        const doc = await db.documents.findById(docInTenantA.id);
        expect(doc.title).toBe('Secret');
    });

    test('DELETE /api/documents/:id - cannot delete other tenant document', async () => {
        const response = await api
            .delete(`/api/documents/${docInTenantA.id}`)
            .set('Authorization', `Bearer ${tenantB.token}`);

        expect(response.status).toBe(404);

        // Verify document still exists
        const doc = await db.documents.findById(docInTenantA.id);
        expect(doc).not.toBeNull();
    });

    test('GET /api/documents - cannot list other tenant documents', async () => {
        const response = await api
            .get('/api/documents')
            .set('Authorization', `Bearer ${tenantB.token}`);

        expect(response.status).toBe(200);
        expect(response.body.documents).toHaveLength(0);
        // Should not contain tenantA's documents
        expect(response.body.documents.map(d => d.id)).not.toContain(docInTenantA.id);
    });

    test('RLS blocks direct SQL cross-tenant access', async () => {
        // Set context to tenant B
        await db.raw("SET LOCAL app.current_tenant_id = $1", [tenantB.id]);

        // Try to query tenant A's documents directly
        const result = await db.raw(
            "SELECT * FROM documents WHERE id = $1",
            [docInTenantA.id]
        );

        expect(result.rows).toHaveLength(0);  // RLS blocks it
    });
});
```

### Tenant Context Injection Prevention

```typescript
// VULNERABLE: Tenant ID from user input
app.get('/api/tenants/:tenantId/data', async (req, res) => {
    const data = await getData(req.params.tenantId);  // ❌ Attacker can change tenantId
});

// SECURE: Tenant ID from authenticated session only
app.get('/api/data', async (req, res) => {
    // req.tenantId is set by auth middleware from JWT, never from URL params
    const data = await getData(req.tenantId);  // ✅ From verified auth token
});
```

### Data Leakage Through Side Channels

Watch for indirect data leaks:

```typescript
// LEAK: Error messages reveal tenant existence
app.post('/api/signup', async (req, res) => {
    const existing = await db.tenants.findBySlug(req.body.slug);
    if (existing) {
        return res.status(409).json({ error: 'This workspace name is taken' });
        // ❌ Reveals that "acme" is a customer
    }
});

// SAFE: Generic error
app.post('/api/signup', async (req, res) => {
    const existing = await db.tenants.findBySlug(req.body.slug);
    if (existing) {
        return res.status(409).json({ error: 'Please choose a different workspace name' });
        // ✅ Doesn't confirm whether "acme" is a customer
    }
});
```

---

## 8. Tenant-Aware IAM & Access Control

### JWT Claims for Tenant Context

```typescript
// JWT payload for multi-tenant SaaS
interface TenantJWTPayload {
    sub: string;          // User ID
    org_id: string;       // Tenant/Organization ID
    org_slug: string;     // Tenant slug (for routing)
    role: string;         // User's role in this tenant
    permissions: string[];// Explicit permissions
    plan: string;         // Tenant plan (for entitlement checks)
    iat: number;
    exp: number;
}

// Verify and extract tenant context from JWT
function verifyTenantToken(token: string): TenantJWTPayload {
    const payload = jwt.verify(token, JWT_SECRET) as TenantJWTPayload;

    // Ensure required tenant claims are present
    if (!payload.org_id || !payload.org_slug) {
        throw new AuthError('Missing tenant claims in token');
    }

    return payload;
}
```

### AWS IAM Dynamic Policies (Per-Tenant Scoping)

```typescript
// Generate STS credentials scoped to a specific tenant's S3 prefix
async function getTenantScopedCredentials(tenantId: string): Promise<Credentials> {
    const policy = JSON.stringify({
        Version: '2012-10-17',
        Statement: [{
            Effect: 'Allow',
            Action: ['s3:GetObject', 's3:PutObject'],
            Resource: `arn:aws:s3:::${BUCKET}/tenants/${tenantId}/*`,
        }, {
            Effect: 'Allow',
            Action: ['kms:Decrypt', 'kms:GenerateDataKey'],
            Resource: `arn:aws:kms:*:*:key/${tenantKmsKeyId}`,
        }],
    });

    const sts = new STSClient({});
    const result = await sts.send(new AssumeRoleCommand({
        RoleArn: TENANT_ACCESS_ROLE_ARN,
        RoleSessionName: `tenant-${tenantId}`,
        Policy: policy,  // Further restricts the role's permissions
        DurationSeconds: 3600,
    }));

    return result.Credentials;
}
```

---

## 9. Encryption Strategies

### Encryption Hierarchy

```
┌─────────────────────────────────────────────┐
│           AWS KMS Root Key                   │
│  (AWS managed, never leaves KMS)            │
└──────────────────┬──────────────────────────┘
                   │
        ┌──────────┴──────────┐
        ▼                     ▼
┌──────────────┐    ┌──────────────┐
│ Tenant A Key │    │ Tenant B Key │   ← Per-tenant CMK in KMS
│  (KMS CMK)   │    │  (KMS CMK)   │
└──────┬───────┘    └──────┬───────┘
       │                    │
       ▼                    ▼
┌──────────────┐    ┌──────────────┐
│  Data Key A  │    │  Data Key B  │   ← Data Encryption Keys (DEK)
│  (encrypted) │    │  (encrypted) │      generated per operation
└──────┬───────┘    └──────┬───────┘
       │                    │
       ▼                    ▼
┌──────────────┐    ┌──────────────┐
│  Tenant A    │    │  Tenant B    │   ← Encrypted data at rest
│  Data        │    │  Data        │
└──────────────┘    └──────────────┘
```

### Envelope Encryption Implementation

```typescript
// Envelope encryption: encrypt data with a data key, encrypt the data key with KMS
async function encryptTenantData(tenantId: string, plaintext: Buffer): Promise<EncryptedEnvelope> {
    const tenantKeyId = await getTenantKmsKeyId(tenantId);

    // 1. Generate a data encryption key (DEK) from KMS
    const { CiphertextBlob: encryptedDEK, Plaintext: plaintextDEK } = await kms.send(
        new GenerateDataKeyCommand({
            KeyId: tenantKeyId,
            KeySpec: 'AES_256',
            EncryptionContext: { tenant_id: tenantId },
        })
    );

    // 2. Encrypt data with the plaintext DEK (locally, fast)
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipheriv('aes-256-gcm', plaintextDEK, iv);
    const encrypted = Buffer.concat([cipher.update(plaintext), cipher.final()]);
    const authTag = cipher.getAuthTag();

    // 3. Securely erase the plaintext DEK from memory
    plaintextDEK.fill(0);

    // 4. Return the envelope (encrypted DEK + encrypted data)
    return {
        encrypted_dek: encryptedDEK,  // Store alongside encrypted data
        iv: iv,
        auth_tag: authTag,
        ciphertext: encrypted,
        kms_key_id: tenantKeyId,
    };
}
```

### Customer-Managed Keys (BYOK / CMK)

Enterprise customers may require control over their encryption keys:

```typescript
// BYOK: Customer provides their own KMS key ARN
interface TenantEncryptionConfig {
    tenant_id: string;
    key_type: 'platform_managed' | 'customer_managed';
    kms_key_arn?: string;          // Customer's KMS key (BYOK)
    key_rotation_days: number;      // Auto-rotation period
}

// Validate customer-provided key
async function configureBYOK(tenantId: string, customerKeyArn: string): Promise<void> {
    // 1. Verify we can use the key (customer must grant our role access)
    try {
        await kms.send(new DescribeKeyCommand({ KeyId: customerKeyArn }));
    } catch (error) {
        throw new Error(
            'Cannot access the provided KMS key. Please grant our role ' +
            `(${OUR_ROLE_ARN}) kms:Encrypt, kms:Decrypt, kms:GenerateDataKey permissions.`
        );
    }

    // 2. Test encrypt/decrypt
    const testData = Buffer.from('validation-test');
    const encrypted = await kms.send(new EncryptCommand({
        KeyId: customerKeyArn,
        Plaintext: testData,
        EncryptionContext: { tenant_id: tenantId },
    }));

    const decrypted = await kms.send(new DecryptCommand({
        KeyId: customerKeyArn,
        CiphertextBlob: encrypted.CiphertextBlob,
        EncryptionContext: { tenant_id: tenantId },
    }));

    if (Buffer.compare(Buffer.from(decrypted.Plaintext), testData) !== 0) {
        throw new Error('Key validation failed: decrypt mismatch');
    }

    // 3. Store configuration
    await db.tenantEncryption.upsert({
        tenant_id: tenantId,
        key_type: 'customer_managed',
        kms_key_arn: customerKeyArn,
    });

    // 4. Re-encrypt existing data with new key (async, background job)
    await queue.add('re-encrypt-tenant-data', { tenantId, newKeyArn: customerKeyArn });
}
```

---

## 10. Kubernetes Multi-Tenancy

### Approach Comparison

| Approach | Isolation | Complexity | Best For |
|----------|-----------|------------|----------|
| **Namespaces** | Logical (soft boundary) | Low | Most SaaS (pool/bridge) |
| **Namespaces + NetworkPolicy + ResourceQuota** | Moderate | Medium | Bridge tier with resource limits |
| **vCluster** | Virtual cluster per tenant | Medium-High | Strong isolation without full cluster cost |
| **Capsule** | Namespace groups with policies | Medium | Multi-tenant Kubernetes RBAC |
| **Dedicated cluster** | Full (hardware) | Highest | Silo tier / regulated tenants |

### vCluster (Virtual Clusters)

vCluster creates lightweight virtual Kubernetes clusters inside a host cluster. Each tenant gets their own API server, control plane, and namespace — but shares the underlying nodes.

```bash
# Install vCluster CLI
brew install loft-sh/tap/vcluster

# Create a virtual cluster for a tenant
vcluster create tenant-acme \
    --namespace host-tenant-acme \
    --set "sync.nodes.enabled=true" \
    --set "isolation.enabled=true" \
    --set "isolation.resourceQuota.enabled=true" \
    --set "isolation.limitRange.enabled=true" \
    --set "isolation.networkPolicy.enabled=true"

# Connect to tenant's virtual cluster
vcluster connect tenant-acme --namespace host-tenant-acme
```

**When to use vCluster:**
- You need cluster-level isolation per tenant (separate API server, RBAC, resources)
- You don't want to manage full dedicated clusters
- Tenants need to deploy their own workloads (platform-as-a-service)
- 10-500 tenants (beyond that, consider a different approach)

### Capsule (Multi-Tenant Kubernetes)

Capsule provides multi-tenancy through "Tenant" custom resources that group namespaces and enforce policies:

```yaml
# Capsule: tenant definition
apiVersion: capsule.clastix.io/v1beta2
kind: Tenant
metadata:
  name: acme
spec:
  owners:
    - name: acme-admin
      kind: User
  namespaceOptions:
    quota: 5  # Max 5 namespaces
  limitRanges:
    items:
      - limits:
          - type: Container
            default:
              cpu: "500m"
              memory: "512Mi"
            defaultRequest:
              cpu: "100m"
              memory: "128Mi"
  resourceQuota:
    items:
      - hard:
          pods: "50"
          services: "10"
  networkPolicies:
    items:
      - policyTypes:
          - Ingress
          - Egress
        ingress:
          - from:
              - namespaceSelector:
                  matchLabels:
                    capsule.clastix.io/tenant: acme
```

---

## 11. Compliance-Driven Isolation

### SOC 2 Type II Requirements

What auditors look for in multi-tenant SaaS:

| Control Area | What Auditors Check | How to Satisfy |
|-------------|-------------------|----------------|
| **Logical access** | Can one tenant access another's data? | RLS + application-level checks + integration tests |
| **Data separation** | Is tenant data logically or physically separated? | Document your tenancy model and isolation mechanisms |
| **Encryption** | Is data encrypted at rest and in transit? | TLS everywhere, AES-256 at rest, document key management |
| **Audit trails** | Are tenant-affecting actions logged? | Per-tenant audit logs with who/what/when |
| **Change management** | How are changes to tenant infrastructure managed? | IaC (Terraform), CI/CD with approval gates |
| **Incident response** | Can you determine which tenants were affected? | Tenant-tagged logs, per-tenant incident scoping |
| **Access reviews** | Who has access to tenant data? | Regular access reviews, principle of least privilege |

### HIPAA Tenant Isolation

For healthcare SaaS handling PHI (Protected Health Information):

```
HIPAA Requirements for Multi-Tenant:
├── BAA (Business Associate Agreement) with each covered entity
├── PHI must be encrypted at rest AND in transit
├── Access controls: minimum necessary access
├── Audit controls: log all PHI access
├── Physical separation NOT required (logical isolation with encryption is acceptable)
├── BUT: some covered entities contractually require dedicated infrastructure
└── Data retention and destruction policies per tenant
```

**Practical HIPAA isolation for SaaS:**
- Bridge model minimum (schema-per-tenant or database-per-tenant)
- Per-tenant encryption keys (envelope encryption)
- Comprehensive audit logging (every PHI access logged)
- Access controls with role-based access
- BAA with your cloud provider (AWS, GCP, Azure all offer BAA)

### FedRAMP Isolation

FedRAMP (for US government SaaS) is the strictest common compliance requirement:

```
FedRAMP Requirements:
├── Moderate: Logical isolation sufficient, dedicated KMS keys
├── High: Physical or virtual isolation, dedicated compute
├── ALL: Continuous monitoring, incident response, vulnerability scanning
├── Data residency: US-only infrastructure
└── Annual assessment by a 3PAO (Third-Party Assessment Organization)
```

### Data Residency Requirements

```typescript
// Route tenant data to correct region
const DATA_RESIDENCY_MAP = {
    'eu': { region: 'eu-west-1', database: 'prod-eu', storage: 'data-eu' },
    'us': { region: 'us-east-1', database: 'prod-us', storage: 'data-us' },
    'apac': { region: 'ap-southeast-1', database: 'prod-apac', storage: 'data-apac' },
};

async function routeToRegion(tenantId: string): Promise<RegionConfig> {
    const tenant = await db.tenants.findById(tenantId);
    const config = DATA_RESIDENCY_MAP[tenant.data_residency_region];

    if (!config) {
        throw new Error(`Unknown data residency region: ${tenant.data_residency_region}`);
    }

    return config;
}
```

---

## 12. Tenant-Aware Observability & Audit

### Per-Tenant Metrics

```typescript
// Prometheus/OpenTelemetry: tag all metrics with tenant_id
import { metrics } from '@opentelemetry/api';

const meter = metrics.getMeter('saas-app');

const requestCounter = meter.createCounter('http_requests_total', {
    description: 'Total HTTP requests',
});

const requestDuration = meter.createHistogram('http_request_duration_ms', {
    description: 'HTTP request duration in milliseconds',
});

// Middleware: record per-tenant metrics
function metricsMiddleware(req: Request, res: Response, next: NextFunction) {
    const start = Date.now();

    res.on('finish', () => {
        const duration = Date.now() - start;
        const labels = {
            tenant_id: req.tenantId,
            tenant_plan: req.tenant?.plan || 'unknown',
            method: req.method,
            path: req.route?.path || req.path,
            status: res.statusCode.toString(),
        };

        requestCounter.add(1, labels);
        requestDuration.record(duration, labels);
    });

    next();
}
```

### Per-Tenant Audit Trail

```sql
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    actor_id UUID,                    -- User who performed the action (null for system)
    actor_type TEXT NOT NULL,          -- 'user', 'api_key', 'system', 'support'
    action TEXT NOT NULL,              -- 'document.created', 'member.invited', 'settings.updated'
    resource_type TEXT NOT NULL,       -- 'document', 'member', 'project', 'settings'
    resource_id TEXT,                  -- ID of the affected resource
    metadata JSONB,                   -- Additional context (old/new values, IP, user agent)
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Partition by month for performance
-- Retention: keep 2 years for compliance, then archive to cold storage

-- Index for tenant-scoped queries
CREATE INDEX idx_audit_log_tenant ON audit_log(tenant_id, created_at DESC);
CREATE INDEX idx_audit_log_actor ON audit_log(tenant_id, actor_id, created_at DESC);
CREATE INDEX idx_audit_log_resource ON audit_log(tenant_id, resource_type, resource_id);
```

### Structured Audit Logging

```typescript
// Audit logger that captures before/after state
async function auditLog(params: {
    tenantId: string;
    actorId: string;
    actorType: 'user' | 'api_key' | 'system' | 'support';
    action: string;
    resourceType: string;
    resourceId: string;
    before?: Record<string, any>;   // Previous state (for updates)
    after?: Record<string, any>;    // New state (for creates/updates)
    metadata?: Record<string, any>;
}): Promise<void> {
    await db.auditLog.create({
        tenant_id: params.tenantId,
        actor_id: params.actorId,
        actor_type: params.actorType,
        action: params.action,
        resource_type: params.resourceType,
        resource_id: params.resourceId,
        metadata: {
            ...params.metadata,
            before: params.before,
            after: params.after,
            ip_address: getCurrentRequest()?.ip,
            user_agent: getCurrentRequest()?.headers['user-agent'],
        },
    });
}

// Usage
await auditLog({
    tenantId: req.tenantId,
    actorId: req.userId,
    actorType: 'user',
    action: 'member.role_changed',
    resourceType: 'member',
    resourceId: memberId,
    before: { role: 'member' },
    after: { role: 'admin' },
});
```

### Tenant-Aware Alerting

```typescript
// Alert when a single tenant consumes disproportionate resources
const ALERTS = {
    noisy_neighbor: {
        condition: 'tenant CPU usage > 3x average for 5 minutes',
        action: 'alert ops team, consider throttling tenant',
    },
    isolation_breach_attempt: {
        condition: 'RLS policy violation detected OR cross-tenant resource access attempt',
        action: 'alert security team immediately, log full request details',
    },
    quota_exceeded: {
        condition: 'tenant usage > 100% of quota',
        action: 'enforce limit, notify tenant admin',
    },
    data_residency_violation: {
        condition: 'tenant data written to wrong region',
        action: 'alert compliance team, halt writes, investigate',
    },
};
```
