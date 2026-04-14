# Tenant Onboarding & Activation — Deep Reference

**Always use `WebSearch` to verify identity provider features, onboarding tool capabilities, and SSO/SCIM specifications before giving advice. The SaaS identity space is evolving rapidly — WorkOS, Clerk, and Stytch ship major features frequently. Last verified: April 2026.**

## Table of Contents
1. [Tenant Provisioning Pipeline](#1-tenant-provisioning-pipeline)
2. [Self-Serve Onboarding Flow](#2-self-serve-onboarding-flow)
3. [User Activation & Time-to-First-Value](#3-user-activation--time-to-first-value)
4. [Identity Providers for Multi-Tenant SaaS](#4-identity-providers-for-multi-tenant-saas)
5. [SSO & SAML Integration](#5-sso--saml-integration)
6. [SCIM User Provisioning](#6-scim-user-provisioning)
7. [Team & Workspace Management](#7-team--workspace-management)
8. [Data Migration from Competitors](#8-data-migration-from-competitors)
9. [Tenant Configuration & White-Labeling](#9-tenant-configuration--white-labeling)
10. [Enterprise Onboarding Playbooks](#10-enterprise-onboarding-playbooks)
11. [Onboarding UX Patterns](#11-onboarding-ux-patterns)
12. [Onboarding Metrics & Optimization](#12-onboarding-metrics--optimization)

---

## 1. Tenant Provisioning Pipeline

### Provisioning Architecture

```
┌──────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Signup  │───▶│   Validate   │───▶│  Provision   │───▶│   Activate   │
│  Form    │    │  & Verify    │    │  Resources   │    │  & Onboard   │
└──────────┘    └──────────────┘    └──────────────┘    └──────────────┘
                      │                     │                    │
                      ▼                     ▼                    ▼
                Email verify          Create tenant         Welcome email
                Check spam            Setup database        Onboarding flow
                Rate limit            Create Stripe         Sample data
                Duplicate check       Setup identity        First invite
```

### Idempotent Tenant Provisioning

```typescript
// Provisioning pipeline with step tracking for idempotent retries
interface ProvisioningState {
    tenant_id: string;
    steps_completed: string[];
    current_step: string | null;
    error: string | null;
    started_at: Date;
    completed_at: Date | null;
}

async function provisionTenant(input: SignupInput): Promise<Tenant> {
    // Idempotency: check if this signup is already in progress or completed
    const existing = await db.provisioningState.findByEmail(input.email);
    if (existing?.completed_at) {
        return db.tenants.findById(existing.tenant_id);
    }

    const steps = [
        { name: 'create_tenant', fn: createTenantRecord },
        { name: 'setup_database', fn: setupDatabaseIsolation },
        { name: 'create_admin_user', fn: createAdminUser },
        { name: 'setup_billing', fn: setupBilling },
        { name: 'setup_defaults', fn: setupDefaultSettings },
        { name: 'send_welcome', fn: sendWelcomeEmail },
    ];

    const state: ProvisioningState = existing || {
        tenant_id: generateUUID(),
        steps_completed: [],
        current_step: null,
        error: null,
        started_at: new Date(),
        completed_at: null,
    };

    for (const step of steps) {
        // Skip already-completed steps (idempotent retry)
        if (state.steps_completed.includes(step.name)) continue;

        state.current_step = step.name;
        await db.provisioningState.upsert(state);

        try {
            await step.fn(state.tenant_id, input);
            state.steps_completed.push(step.name);
        } catch (error) {
            state.error = error.message;
            await db.provisioningState.upsert(state);
            throw error;  // Caller can retry; completed steps won't re-run
        }
    }

    state.completed_at = new Date();
    state.current_step = null;
    await db.provisioningState.upsert(state);

    await events.emit('tenant.provisioned', { tenantId: state.tenant_id });

    return db.tenants.findById(state.tenant_id);
}
```

### Provisioning for Different Tenancy Models

**Pool model provisioning (< 1 second):**
```typescript
async function provisionPoolTenant(tenantId: string, input: SignupInput): Promise<void> {
    // Just insert rows — shared database, shared compute
    await db.transaction(async (tx) => {
        await tx.tenants.create({
            id: tenantId,
            slug: input.slug,
            name: input.companyName,
            plan: 'free',
            status: 'active',
        });

        await tx.tenantSettings.create({
            tenant_id: tenantId,
            timezone: input.timezone || 'UTC',
            locale: input.locale || 'en',
        });
    });
    // That's it — RLS handles isolation automatically
}
```

**Bridge model provisioning (seconds):**
```typescript
async function provisionBridgeTenant(tenantId: string, input: SignupInput): Promise<void> {
    const schemaName = `tenant_${input.slug}`;

    // Create schema and run migrations
    await db.raw(`CREATE SCHEMA IF NOT EXISTS ${schemaName}`);
    await runMigrations(schemaName);  // Apply all schema migrations

    // Create tenant record in shared tenants table
    await db.tenants.create({
        id: tenantId,
        slug: input.slug,
        schema_name: schemaName,
        status: 'active',
    });
}
```

**Silo model provisioning (minutes):**
```typescript
async function provisionSiloTenant(tenantId: string, input: SignupInput): Promise<void> {
    // 1. Create dedicated database (e.g., Neon, RDS)
    const database = await neon.createProject({
        name: `tenant-${input.slug}`,
        region_id: input.region,  // Data residency
    });

    // 2. Run migrations on dedicated database
    await runMigrations(database.connectionString);

    // 3. Create dedicated compute (if needed)
    const namespace = await k8s.createNamespace(`tenant-${input.slug}`, {
        labels: { tenant: input.slug, tier: 'enterprise' },
        resourceQuotas: ENTERPRISE_RESOURCE_QUOTAS,
    });

    // 4. Store routing information
    await db.tenants.create({
        id: tenantId,
        slug: input.slug,
        isolation_model: 'silo',
        connection_string: database.connectionString,
        namespace: namespace.name,
        status: 'active',
    });
}
```

---

## 2. Self-Serve Onboarding Flow

### The Optimal Signup Flow

```
Step 1: Signup
├── Email + password (or OAuth: Google, GitHub, Microsoft)
├── Company name (optional — can be asked later)
├── CAPTCHA (invisible reCAPTCHA or Turnstile)
└── Email verification (magic link or 6-digit code)

Step 2: Workspace Setup
├── Workspace name (pre-filled from company name or email domain)
├── Workspace slug/URL (auto-generated, editable)
├── Use case / role selection (optional — for personalization)
└── Skip to app (don't gate on too many questions)

Step 3: First Value
├── Show the core feature immediately
├── Pre-populate with sample data or templates
├── Interactive walkthrough of key action
└── Team invite prompt (deferred, not blocking)

Step 4: Team Growth (deferred)
├── "Invite your team" CTA (in-app, not during signup)
├── Shareable invite link
├── Domain-based auto-join (anyone with @acme.com can join)
└── Role assignment (admin, member, viewer)
```

### Signup Form Best Practices

```typescript
// Signup API endpoint
async function handleSignup(req: Request): Promise<Response> {
    const { email, password, name, companyName } = req.body;

    // 1. Rate limit by IP (prevent abuse)
    await rateLimit.check(`signup:${req.ip}`, { maxRequests: 5, windowMs: 60000 });

    // 2. Validate email (format, not disposable, not already registered)
    const validation = await validateEmail(email);
    if (validation.isDisposable) {
        return error(400, 'Please use a work email address');
    }
    if (validation.isRegistered) {
        // Don't reveal if email exists — send "check your email" for both cases
        await sendLoginLink(email);
        return success({ message: 'Check your email' });
    }

    // 3. Create user (but don't create tenant yet — wait for verification)
    const user = await createUnverifiedUser({ email, password, name });

    // 4. Send verification email
    await sendVerificationEmail(user.email, {
        type: 'magic-link',  // or '6-digit-code'
        expiresIn: '24h',
    });

    return success({ message: 'Check your email to continue' });
}

// After email verification → create tenant
async function handleEmailVerification(token: string): Promise<Response> {
    const user = await verifyEmailToken(token);

    // Create the tenant/workspace
    const tenant = await provisionTenant({
        admin_user: user,
        slug: generateSlug(user.email),
        name: user.companyName || emailDomain(user.email),
    });

    // Sign the user in and redirect to onboarding
    const session = await createSession(user, tenant);
    return redirect(`/${tenant.slug}/getting-started`, {
        headers: { 'Set-Cookie': session.cookie },
    });
}
```

### Domain-Based Auto-Join

Allow users with the same email domain to auto-join an existing workspace:

```typescript
async function handleSignup(email: string): Promise<{ action: 'create' | 'join', tenant?: Tenant }> {
    const domain = email.split('@')[1];

    // Check if any existing tenant has auto-join enabled for this domain
    const tenant = await db.tenants.findByAutoJoinDomain(domain);

    if (tenant) {
        return {
            action: 'join',
            tenant,
            // Show: "Your team at Acme is already using [Product]. Join them?"
        };
    }

    return { action: 'create' };
}
```

---

## 3. User Activation & Time-to-First-Value

### Activation Frameworks

**Activation = the moment a user experiences the core value of your product.** It's not signup — it's the "aha moment."

| Product | Aha Moment | Time to Activation Target |
|---------|-----------|--------------------------|
| Slack | Sending a message in a channel with teammates | < 10 minutes |
| Notion | Creating a page with content | < 5 minutes |
| Linear | Creating an issue and moving it across the board | < 10 minutes |
| Figma | Creating a design with collaboration | < 15 minutes |
| Vercel | Deploying a project and seeing it live | < 5 minutes |
| Supabase | Creating a database table and querying it | < 10 minutes |

### Activation Milestones

Define a series of milestones that indicate a user is progressing toward activation:

```typescript
interface ActivationMilestones {
    // Example for a project management SaaS
    milestones: [
        { key: 'account_created', weight: 0.1, description: 'User created account' },
        { key: 'workspace_named', weight: 0.1, description: 'Named their workspace' },
        { key: 'first_project', weight: 0.2, description: 'Created first project' },
        { key: 'first_task', weight: 0.2, description: 'Created first task' },
        { key: 'invited_teammate', weight: 0.2, description: 'Invited at least one teammate' },
        { key: 'teammate_joined', weight: 0.1, description: 'Teammate accepted invite' },
        { key: 'task_completed', weight: 0.1, description: 'Completed first task' },
    ];
    activated_threshold: 0.7;  // 70% of weighted milestones = "activated"
}

// Track milestone completion
async function trackMilestone(tenantId: string, userId: string, milestone: string): Promise<void> {
    const existing = await db.activationMilestones.find(tenantId, userId, milestone);
    if (existing) return;  // Already completed

    await db.activationMilestones.create({
        tenant_id: tenantId,
        user_id: userId,
        milestone,
        completed_at: new Date(),
    });

    // Check if user is now "activated"
    const completedMilestones = await db.activationMilestones.findByUser(tenantId, userId);
    const activationScore = calculateActivationScore(completedMilestones);

    if (activationScore >= 0.7 && !user.activated_at) {
        await db.users.update(userId, { activated_at: new Date() });
        await events.emit('user.activated', { tenantId, userId });
    }
}
```

### Sample Data & Templates

Pre-populate new workspaces with sample content so users see a living product, not empty states:

```typescript
async function setupSampleData(tenantId: string, useCase: string): Promise<void> {
    const templates = {
        'engineering': {
            projects: [
                { name: 'Example: Sprint Board', template: 'kanban' },
                { name: 'Example: Bug Tracker', template: 'bug-tracking' },
            ],
            sampleTasks: 5,
        },
        'marketing': {
            projects: [
                { name: 'Example: Campaign Tracker', template: 'campaign' },
                { name: 'Example: Content Calendar', template: 'calendar' },
            ],
            sampleTasks: 4,
        },
        'general': {
            projects: [
                { name: 'Getting Started', template: 'onboarding' },
            ],
            sampleTasks: 3,
        },
    };

    const template = templates[useCase] || templates.general;

    for (const project of template.projects) {
        const p = await createProject(tenantId, {
            name: project.name,
            is_sample: true,  // Mark as deletable sample data
        });

        await applySampleTasks(p.id, project.sampleTasks);
    }
}
```

---

## 4. Identity Providers for Multi-Tenant SaaS

### Platform Comparison

| Feature | WorkOS | Clerk | Auth0 | Stytch | PropelAuth |
|---------|--------|-------|-------|--------|-----------|
| **Best for** | Enterprise SSO/SCIM | Full auth + UI | Complex auth | API-first auth | B2B auth |
| **SSO (SAML/OIDC)** | Excellent | Good | Excellent | Good | Good |
| **SCIM** | Yes | Limited | Yes | Limited | Yes |
| **Multi-tenant orgs** | Yes (Organizations) | Yes (Organizations) | Yes (Organizations) | Yes | Yes |
| **Pre-built UI** | Admin Portal only | Full component library | Universal Login | Headless (API) | Full UI |
| **MFA** | Via IdP | Yes | Yes | Yes | Yes |
| **Social login** | Via IdP | Yes | Yes | Yes | Yes |
| **Pricing model** | Per SSO connection | Per MAU | Per MAU | Per MAU | Per MAU |
| **Free tier** | Free up to 1M users | Free up to 10K MAU | Free up to 25K MAU | Free up to 25K | Free up to 10K MAU |

### When to Use Each

**WorkOS** — Best for enterprise SSO and SCIM:
- Your primary need is SSO/SAML for enterprise customers
- You want to manage the auth UX yourself but need enterprise identity features
- Per-connection pricing (not per-user) — better economics at scale with few SSO tenants
- Directory sync (SCIM) is a must-have
- Used by: Vercel, Webflow, Loom, Perplexity

**Clerk** — Best for full-stack auth with pre-built UI:
- You want the fastest auth integration with beautiful pre-built components
- React/Next.js focus — deep framework integration
- Organization management built-in
- Good for PLG products that need polished auth UX out of the box
- Used by: Turso, Convex

**Auth0 (Okta)** — Best for complex auth requirements:
- Advanced auth flows (passwordless, adaptive MFA, breached password detection)
- Heavy customization via Actions (serverless hooks)
- Mature enterprise features
- Limitations: Complex pricing, can get expensive, Okta acquisition has slowed innovation

**Stytch** — Best for API-first / headless auth:
- You want full control over the auth UX
- Strong passwordless support (magic links, OTPs, passkeys)
- Device fingerprinting and fraud detection
- Good for API-first products

**PropelAuth** — Best for B2B-specific auth:
- Purpose-built for B2B SaaS (not consumer auth)
- Organization management, roles, RBAC built-in
- Quick setup for multi-tenant auth

### Integration Example (WorkOS)

```typescript
// WorkOS SSO integration
import WorkOS from '@workos-inc/node';

const workos = new WorkOS(process.env.WORKOS_API_KEY);

// 1. Create an organization for the tenant
const org = await workos.organizations.createOrganization({
    name: tenant.name,
    domains: [tenant.emailDomain],  // e.g., 'acme.com'
});

// 2. When tenant configures SSO, redirect admin to WorkOS portal
const portalLink = await workos.portal.generateLink({
    organization: org.id,
    intent: 'sso',  // SSO configuration portal
    return_url: `${APP_URL}/settings/sso/callback`,
});

// 3. SSO login flow
app.get('/auth/sso', async (req, res) => {
    const authorizationUrl = workos.sso.getAuthorizationURL({
        organization: tenant.workosOrgId,
        redirectURI: `${APP_URL}/auth/callback`,
        clientID: process.env.WORKOS_CLIENT_ID,
    });
    res.redirect(authorizationUrl);
});

// 4. Handle SSO callback
app.get('/auth/callback', async (req, res) => {
    const { code } = req.query;
    const { profile } = await workos.sso.getProfileAndToken({
        code,
        clientID: process.env.WORKOS_CLIENT_ID,
    });

    // Find or create user in your system
    const user = await findOrCreateUser({
        email: profile.email,
        name: `${profile.first_name} ${profile.last_name}`,
        idp_id: profile.idp_id,
        tenant_id: tenant.id,
    });

    const session = await createSession(user, tenant);
    res.redirect(`/${tenant.slug}/dashboard`);
});
```

---

## 5. SSO & SAML Integration

### SAML Flow

```
┌────────┐     ┌─────────┐     ┌──────────┐
│  User  │────▶│ Your App│────▶│   IdP    │
│        │     │  (SP)   │     │  (Okta/  │
│        │     │         │     │  Azure AD)│
└────────┘     └────┬────┘     └─────┬────┘
                    │                │
              1. User visits        │
                 app login          │
              2. App creates        │
                 SAML AuthnRequest  │
              3. ─────────────────▶ │
              4.                    │ IdP authenticates
              5. ◀───────────────── │ (SAML Response + Assertion)
              6. App validates      │
                 assertion          │
              7. Create/update      │
                 session            │
```

### SSO Configuration Data Model

```sql
CREATE TABLE sso_connections (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    provider TEXT NOT NULL,           -- 'okta', 'azure_ad', 'google_workspace', 'onelogin'
    protocol TEXT NOT NULL,           -- 'saml', 'oidc'
    status TEXT DEFAULT 'pending',    -- 'pending', 'active', 'inactive'

    -- SAML configuration
    idp_entity_id TEXT,
    idp_sso_url TEXT,
    idp_certificate TEXT,            -- X.509 certificate (PEM format)

    -- OIDC configuration
    oidc_client_id TEXT,
    oidc_client_secret TEXT,         -- Encrypted
    oidc_discovery_url TEXT,

    -- Settings
    enforce_sso BOOLEAN DEFAULT false,        -- If true, only SSO login allowed
    auto_create_users BOOLEAN DEFAULT true,   -- JIT provisioning
    default_role TEXT DEFAULT 'member',

    -- External provider reference
    workos_connection_id TEXT,        -- If using WorkOS
    workos_organization_id TEXT,

    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),

    UNIQUE (tenant_id, provider)
);
```

### SSO Enforcement

When a tenant enables SSO enforcement, password login is disabled for their users:

```typescript
async function authenticateUser(email: string, method: string): Promise<User | Error> {
    const user = await db.users.findByEmail(email);
    if (!user) return new Error('User not found');

    const tenant = await db.tenants.findById(user.tenantId);
    const ssoConnection = await db.ssoConnections.findActive(tenant.id);

    // If SSO is enforced and user is trying to login with password
    if (ssoConnection?.enforce_sso && method === 'password') {
        return new Error('SSO is required for this organization. Please login via SSO.');
    }

    return user;
}
```

---

## 6. SCIM User Provisioning

SCIM (System for Cross-domain Identity Management) allows enterprise IdPs to automatically create, update, and deactivate users in your SaaS.

### SCIM Flow

```
┌──────────┐     ┌──────────┐     ┌──────────┐
│   IdP    │────▶│  Your    │────▶│ Database │
│  (Okta)  │     │  SCIM    │     │          │
│          │     │  Endpoint│     │          │
└──────────┘     └──────────┘     └──────────┘
     │                │
     │ POST /scim/v2/Users         Create user
     │ PUT  /scim/v2/Users/:id     Update user
     │ PATCH /scim/v2/Users/:id    Partial update (deactivate)
     │ DELETE /scim/v2/Users/:id   Delete user
     │ GET  /scim/v2/Users         List users
     │ POST /scim/v2/Groups        Create group/team
```

### SCIM Implementation with WorkOS

```typescript
// WorkOS handles SCIM complexity — you handle directory sync webhooks
app.post('/webhooks/workos', async (req, res) => {
    const event = workos.webhooks.constructEvent(req);

    switch (event.event) {
        case 'dsync.user.created': {
            const { data } = event;
            await createUser({
                tenant_id: tenantFromOrg(data.organization_id),
                email: data.emails[0]?.value,
                name: `${data.first_name} ${data.last_name}`,
                idp_id: data.idp_id,
                role: 'member',
                source: 'scim',
            });
            break;
        }

        case 'dsync.user.updated': {
            const { data } = event;
            await updateUser(data.idp_id, {
                name: `${data.first_name} ${data.last_name}`,
                email: data.emails[0]?.value,
                active: data.state === 'active',
            });
            break;
        }

        case 'dsync.user.deleted': {
            const { data } = event;
            await deactivateUser(data.idp_id);  // Soft-delete, don't hard-delete
            break;
        }

        case 'dsync.group.created':
        case 'dsync.group.updated':
        case 'dsync.group.deleted':
            await syncGroup(event);
            break;
    }

    res.json({ received: true });
});
```

---

## 7. Team & Workspace Management

### Organization Hierarchy

```
Organization (Tenant)
├── Workspace(s)
│   ├── Project(s)
│   │   ├── Members (from Team)
│   │   └── Resources
│   └── Settings
├── Team(s) / Group(s)
│   └── Members
├── Members
│   ├── Role (Owner, Admin, Member, Viewer, Guest)
│   └── Status (Active, Invited, Deactivated)
└── Settings
    ├── Billing
    ├── SSO/SCIM
    ├── Branding
    └── Security policies
```

### Role-Based Access Control (RBAC)

```sql
CREATE TABLE roles (
    id UUID PRIMARY KEY,
    tenant_id UUID REFERENCES tenants(id),  -- NULL for system roles
    name TEXT NOT NULL,                      -- 'owner', 'admin', 'member', 'viewer', 'guest'
    permissions JSONB NOT NULL,              -- Array of permission strings
    is_system BOOLEAN DEFAULT false,
    UNIQUE (tenant_id, name)
);

CREATE TABLE tenant_memberships (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    user_id UUID NOT NULL REFERENCES users(id),
    role_id UUID NOT NULL REFERENCES roles(id),
    status TEXT DEFAULT 'active',        -- 'active', 'invited', 'deactivated'
    invited_by UUID REFERENCES users(id),
    invited_at TIMESTAMPTZ,
    joined_at TIMESTAMPTZ,
    deactivated_at TIMESTAMPTZ,
    UNIQUE (tenant_id, user_id)
);

-- Default system roles
INSERT INTO roles (name, permissions, is_system) VALUES
    ('owner', '["*"]', true),
    ('admin', '["members.manage", "settings.manage", "billing.view", "projects.manage"]', true),
    ('member', '["projects.view", "projects.edit", "tasks.manage"]', true),
    ('viewer', '["projects.view", "tasks.view"]', true),
    ('guest', '["projects.view"]', true);  -- Limited access, for external collaborators
```

### Invitation Flow

```typescript
async function inviteUser(
    tenantId: string,
    inviterUserId: string,
    inviteeEmail: string,
    role: string
): Promise<Invitation> {
    // 1. Check inviter has permission
    const inviter = await getMembership(tenantId, inviterUserId);
    if (!hasPermission(inviter, 'members.manage')) {
        throw new ForbiddenError('You do not have permission to invite members');
    }

    // 2. Check seat limit
    const seatCheck = await entitlements.checkLimit(tenantId, 'seats');
    if (!seatCheck.allowed) {
        throw new LimitExceededError('Seat limit reached. Upgrade your plan to invite more members.');
    }

    // 3. Check if user is already a member
    const existing = await db.memberships.findByEmail(tenantId, inviteeEmail);
    if (existing) {
        throw new ConflictError('This user is already a member of this workspace');
    }

    // 4. Create invitation
    const invitation = await db.invitations.create({
        tenant_id: tenantId,
        email: inviteeEmail,
        role,
        invited_by: inviterUserId,
        token: generateSecureToken(),
        expires_at: addDays(new Date(), 7),
    });

    // 5. Send invitation email
    await sendEmail(inviteeEmail, 'workspace-invitation', {
        inviter_name: inviter.user.name,
        workspace_name: tenant.name,
        accept_url: `${APP_URL}/invite/${invitation.token}`,
    });

    return invitation;
}
```

---

## 8. Data Migration from Competitors

### Migration Architecture

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│    Import     │────▶│  Transform   │────▶│    Load      │────▶│   Verify     │
│    Source     │     │  & Validate  │     │  Into Tenant │     │  & Report    │
└──────────────┘     └──────────────┘     └──────────────┘     └──────────────┘
       │                     │                     │                    │
  CSV, JSON, API        Map fields             Batch insert          Count check
  competitor export     Validate data          Handle conflicts      Integrity check
                        Transform schema       Track progress        User notification
```

### Import Job Pattern

```typescript
interface ImportJob {
    id: string;
    tenant_id: string;
    source: 'csv' | 'api' | 'competitor_name';
    status: 'pending' | 'processing' | 'completed' | 'failed';
    progress: {
        total_records: number;
        processed: number;
        succeeded: number;
        failed: number;
        skipped: number;
    };
    error_log: ImportError[];
    started_at: Date | null;
    completed_at: Date | null;
}

async function processImport(job: ImportJob): Promise<void> {
    const records = await readImportSource(job);
    job.progress.total_records = records.length;

    const batchSize = 100;
    for (let i = 0; i < records.length; i += batchSize) {
        const batch = records.slice(i, i + batchSize);

        for (const record of batch) {
            try {
                const transformed = transformRecord(record, job.source);
                await validateRecord(transformed);
                await insertRecord(job.tenant_id, transformed);
                job.progress.succeeded++;
            } catch (error) {
                job.progress.failed++;
                job.error_log.push({
                    record_index: i,
                    error: error.message,
                    data: record,
                });
            }
            job.progress.processed++;
        }

        // Update progress (for real-time UI)
        await db.importJobs.update(job.id, { progress: job.progress });
    }

    job.status = job.progress.failed > 0 ? 'completed_with_errors' : 'completed';
    job.completed_at = new Date();
    await db.importJobs.update(job.id, job);
}
```

---

## 9. Tenant Configuration & White-Labeling

### Configuration Data Model

```sql
CREATE TABLE tenant_settings (
    tenant_id UUID PRIMARY KEY REFERENCES tenants(id),

    -- Branding
    logo_url TEXT,
    favicon_url TEXT,
    primary_color TEXT DEFAULT '#6366f1',    -- Brand color
    accent_color TEXT DEFAULT '#8b5cf6',

    -- Custom domain
    custom_domain TEXT UNIQUE,
    custom_domain_verified BOOLEAN DEFAULT false,
    ssl_certificate_status TEXT,  -- 'pending', 'active', 'expired'

    -- White-labeling (enterprise feature)
    hide_powered_by BOOLEAN DEFAULT false,
    custom_email_domain TEXT,
    custom_login_page BOOLEAN DEFAULT false,

    -- Preferences
    timezone TEXT DEFAULT 'UTC',
    locale TEXT DEFAULT 'en',
    date_format TEXT DEFAULT 'YYYY-MM-DD',
    first_day_of_week INT DEFAULT 1,  -- 1=Monday

    -- Security policies
    mfa_required BOOLEAN DEFAULT false,
    session_timeout_minutes INT DEFAULT 1440,  -- 24 hours
    ip_allowlist TEXT[],                        -- Empty = allow all
    password_policy JSONB,                     -- min length, complexity, etc.

    updated_at TIMESTAMPTZ DEFAULT now()
);
```

### Custom Domain Setup

```typescript
async function setupCustomDomain(tenantId: string, domain: string): Promise<void> {
    // 1. Validate domain format
    if (!isValidDomain(domain)) {
        throw new Error('Invalid domain format');
    }

    // 2. Store domain (unverified)
    await db.tenantSettings.update(tenantId, {
        custom_domain: domain,
        custom_domain_verified: false,
    });

    // 3. Generate DNS verification records
    const verificationToken = generateVerificationToken(tenantId, domain);

    // Return instructions to user:
    // "Add a CNAME record pointing to app.yoursaas.com"
    // "Add a TXT record: _verification.domain.com → {verificationToken}"

    // 4. Start periodic verification check
    await queue.add('verify-custom-domain', { tenantId, domain }, {
        repeat: { every: 60000 },  // Check every minute
        maxRetries: 1440,          // Try for 24 hours
    });
}

async function verifyCustomDomain(tenantId: string, domain: string): Promise<boolean> {
    // Check CNAME record
    const cname = await dns.resolveCname(domain);
    if (!cname.includes('app.yoursaas.com')) return false;

    // Check TXT record
    const txt = await dns.resolveTxt(`_verification.${domain}`);
    const expectedToken = generateVerificationToken(tenantId, domain);
    if (!txt.flat().includes(expectedToken)) return false;

    // Issue SSL certificate
    await provisionSSLCertificate(domain);

    // Mark as verified
    await db.tenantSettings.update(tenantId, {
        custom_domain_verified: true,
        ssl_certificate_status: 'active',
    });

    return true;
}
```

---

## 10. Enterprise Onboarding Playbooks

### Enterprise vs Self-Serve Onboarding

| Aspect | Self-Serve | Enterprise |
|--------|-----------|------------|
| Timeline | Minutes | Weeks-months |
| Provisioning | Automated | Semi-automated with custom steps |
| Identity | Email/password, social | SSO (SAML/OIDC), SCIM |
| Data migration | Self-serve CSV import | Managed migration with support |
| Training | In-app walkthroughs | Dedicated training sessions |
| Configuration | Self-service settings | Custom setup by CS/solutions team |
| Support | Documentation, community | Dedicated CSM, Slack channel |
| Success metrics | Activation rate, TTV | Go-live date, adoption rate |

### Enterprise Onboarding Phases

```
Phase 1: Technical Setup (Week 1-2)
├── SSO/SAML configuration
├── SCIM directory sync
├── Custom domain setup
├── Security policy configuration
├── API key provisioning
└── Network/firewall allowlisting

Phase 2: Data Migration (Week 2-4)
├── Data export from current tool
├── Data mapping and transformation
├── Test import into sandbox
├── Verify data integrity
├── Production import
└── Historical data handling

Phase 3: Configuration (Week 3-4)
├── Workspace structure setup
├── Custom fields and workflows
├── Integration configuration (Slack, Jira, GitHub, etc.)
├── Permission and role setup
├── Branding customization
└── Notification preferences

Phase 4: Rollout (Week 4-6)
├── Admin training
├── Pilot group rollout (10-20 users)
├── Feedback collection and adjustments
├── Full rollout to all users
├── User training and documentation
└── Go-live support
```

---

## 11. Onboarding UX Patterns

### Progressive Disclosure

Don't show everything at once. Reveal complexity as the user is ready:

```
Visit 1: Core feature (create first item)
Visit 2: Customization (settings, preferences)
Visit 3: Collaboration (invite team, share)
Visit 4: Power features (integrations, automation)
Visit 5: Advanced (API, custom workflows)
```

### Onboarding Checklist Pattern

```typescript
interface OnboardingChecklist {
    tenant_id: string;
    items: ChecklistItem[];
    dismissed: boolean;
}

interface ChecklistItem {
    key: string;
    title: string;
    description: string;
    completed: boolean;
    cta_url: string;
    order: number;
}

// Example checklist
const defaultChecklist: ChecklistItem[] = [
    {
        key: 'create_project',
        title: 'Create your first project',
        description: 'Start organizing your work',
        completed: false,
        cta_url: '/projects/new',
        order: 1,
    },
    {
        key: 'invite_teammate',
        title: 'Invite a teammate',
        description: 'Collaboration is better together',
        completed: false,
        cta_url: '/settings/members/invite',
        order: 2,
    },
    {
        key: 'install_integration',
        title: 'Connect your tools',
        description: 'Sync with Slack, GitHub, or Jira',
        completed: false,
        cta_url: '/settings/integrations',
        order: 3,
    },
    {
        key: 'customize_workspace',
        title: 'Customize your workspace',
        description: 'Add your logo and brand colors',
        completed: false,
        cta_url: '/settings/appearance',
        order: 4,
    },
];
```

### Empty States

Empty states are critical onboarding touchpoints. Every empty list should guide the user to create their first item:

```
┌─────────────────────────────────────┐
│                                     │
│       📋 No projects yet            │
│                                     │
│  Projects help you organize your    │
│  team's work. Create your first     │
│  one to get started.                │
│                                     │
│      [Create a project →]           │
│                                     │
│  Or, import from:                   │
│  [Asana] [Jira] [Trello] [CSV]     │
│                                     │
└─────────────────────────────────────┘
```

---

## 12. Onboarding Metrics & Optimization

### Key Metrics

| Metric | Definition | Good Benchmark |
|--------|-----------|----------------|
| **Signup-to-activation rate** | % of signups that reach activation milestone | 20-40% (PLG) |
| **Time-to-first-value (TTFV)** | Time from signup to first meaningful action | < 10 minutes |
| **Day-1 retention** | % of users who return the day after signup | > 40% |
| **Day-7 retention** | % of users who return 7 days after signup | > 20% |
| **Invite rate** | % of activated users who invite a teammate | > 30% |
| **Team activation rate** | % of tenants with 2+ active users | > 50% (B2B) |
| **Onboarding completion rate** | % of users who complete the onboarding checklist | > 60% |
| **Free-to-paid conversion** | % of free users who convert to paid | 2-5% (PLG), 15-25% (reverse trial) |

### Onboarding Funnel Analysis

```
Signup         1,000  (100%)
  │
  ├── Email verified      800  (80%)   ← If < 80%, improve email deliverability
  │
  ├── Workspace created   700  (70%)   ← If low, simplify workspace setup
  │
  ├── First action        400  (40%)   ← If low, improve empty states/templates
  │
  ├── Invited teammate    200  (20%)   ← If low, prompt invites at right moment
  │
  ├── Team active         120  (12%)   ← If low, improve invite acceptance UX
  │
  └── Converted to paid    40  (4%)    ← PLG conversion target
```
