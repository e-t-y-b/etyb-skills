# Billing & Subscriptions Architecture — Deep Reference

**Always use `WebSearch` to verify billing platform features, pricing, and API capabilities before giving advice. The billing infrastructure space is evolving rapidly — Stripe, Orb, Lago, and others ship major features quarterly. Last verified: April 2026.**

## Table of Contents
1. [Billing Platform Selection](#1-billing-platform-selection)
2. [Pricing Model Implementation](#2-pricing-model-implementation)
3. [Subscription Lifecycle State Machine](#3-subscription-lifecycle-state-machine)
4. [Entitlements Engine](#4-entitlements-engine)
5. [Dunning & Failed Payment Recovery](#5-dunning--failed-payment-recovery)
6. [Plan Migration & Proration](#6-plan-migration--proration)
7. [Tax Handling](#7-tax-handling)
8. [Revenue Recognition](#8-revenue-recognition)
9. [Webhook Architecture for Billing](#9-webhook-architecture-for-billing)
10. [Self-Serve vs Sales-Assisted Billing](#10-self-serve-vs-sales-assisted-billing)
11. [Billing Data Model](#11-billing-data-model)
12. [Billing Infrastructure Anti-Patterns](#12-billing-infrastructure-anti-patterns)

---

## 1. Billing Platform Selection

### Platform Comparison

| Platform | Best For | Pricing Model Support | Self-Serve | Enterprise | Open Source | MoR |
|----------|---------|----------------------|------------|------------|-------------|-----|
| **Stripe Billing** | Most SaaS | Flat, seat, usage, hybrid | Excellent | Good | No | No |
| **Chargebee** | Mid-market SaaS | All models | Good | Excellent | No | No |
| **Recurly** | Subscription-heavy | Flat, seat, tiered | Good | Good | No | No |
| **Paddle** | Global SaaS (tax) | Flat, seat, usage | Good | Good | No | **Yes** |
| **LemonSqueezy** | Indie/small SaaS | Flat, seat | Simple | Limited | No | **Yes** |
| **Orb** | Usage-based billing | Usage, hybrid, credit | Good | Excellent | No | No |
| **Metronome** | Usage-based billing | Usage, hybrid, commit | Good | Excellent | No | No |
| **Lago** | Self-hosted billing | All models | Good | Good | **Yes** | No |
| **Kill Bill** | Custom billing | All models | DIY | DIY | **Yes** | No |

### When to Use Each

**Stripe Billing** — The default choice for most SaaS:
- Widest payment method coverage (cards, ACH, SEPA, wallets)
- Best developer experience and documentation
- Native usage-based billing with meters API (2024+)
- Huge ecosystem (tax, invoicing, revenue recognition, fraud)
- Limitations: Complex usage rating needs Orb/Metronome on top; pricing can be expensive at scale (2.9% + 30c per transaction)

**Paddle / LemonSqueezy** — When you don't want to handle tax/compliance:
- Merchant of Record (MoR): they handle sales tax, VAT, GST globally
- You don't need a tax registration in every country
- Simpler for indie developers and small teams
- Limitations: Less control, higher fees (5%+ for Paddle), limited customization

**Orb** — When usage-based billing is core:
- Purpose-built for usage-based and hybrid pricing
- Powerful event ingestion and aggregation
- Real-time metering with billing-grade accuracy
- Flexible plan configuration (usage + subscription combos)
- Used by: Vercel, Stytch, Replit, Perplexity

**Metronome** — When usage + commitments matter:
- Usage-based billing with commit/drawdown contracts
- Pre-paid credit models (common for API companies)
- Enterprise contract management
- Used by: OpenAI, Databricks, Cloudflare

**Lago** — When you need control or self-hosting:
- Open-source (MIT license) billing engine
- Self-hostable for data sovereignty or compliance
- All pricing models supported
- Good for teams that want to own their billing infrastructure
- Limitations: Smaller community than Stripe, need to manage infrastructure

### Cost Comparison at Scale

| Monthly Revenue | Stripe (2.9%+30c) | Paddle (~5%) | Self-hosted (Lago) |
|----------------|-------------------|-------------|-------------------|
| $10K MRR | ~$320/mo | ~$500/mo | ~$200/mo (infra) |
| $100K MRR | ~$3,100/mo | ~$5,000/mo | ~$500/mo (infra) |
| $1M MRR | ~$30,100/mo | ~$50,000/mo | ~$2,000/mo (infra) |
| $10M MRR | Negotiated | Negotiated | ~$5,000/mo (infra) |

Note: Stripe and Paddle negotiate rates for high-volume customers. Self-hosted costs don't include engineering time.

---

## 2. Pricing Model Implementation

### Per-Seat Pricing

The simplest model. Charge based on the number of users/seats in the tenant.

```typescript
// Stripe: Per-seat subscription
const subscription = await stripe.subscriptions.create({
    customer: tenant.stripeCustomerId,
    items: [{
        price: 'price_pro_per_seat',  // $15/seat/month
        quantity: teamSize,            // Number of seats
    }],
});

// When a user is added, update the quantity
await stripe.subscriptions.update(subscription.id, {
    items: [{
        id: subscription.items.data[0].id,
        quantity: newTeamSize,
    }],
    proration_behavior: 'create_prorations',  // Charge for the new seat immediately
});
```

**Variants:**
- **Exact seat count**: Charge for every active user (Linear, Notion)
- **Seat tiers**: 1-5 seats = $49, 6-20 = $99, 21-50 = $199 (Basecamp-style)
- **Active seat pricing**: Only charge for users who logged in this month (Slack's historical model)
- **Minimum seats**: Charge for at least N seats even if fewer are used

### Usage-Based Pricing

Charge based on actual consumption — API calls, compute hours, storage, etc.

```typescript
// Stripe Meters API (2024+)
const meter = await stripe.billing.meters.create({
    display_name: 'API Calls',
    event_name: 'api_call',
    default_aggregation: { formula: 'sum' },
});

// Record usage events
await stripe.billing.meterEvents.create({
    event_name: 'api_call',
    payload: {
        stripe_customer_id: tenant.stripeCustomerId,
        value: '1',
    },
});

// Subscription with usage-based price
const subscription = await stripe.subscriptions.create({
    customer: tenant.stripeCustomerId,
    items: [{
        price: 'price_api_calls',  // $0.001 per API call
    }],
});
```

**For complex usage billing, use Orb or Metronome:**
```typescript
// Orb: Define a plan with usage-based pricing
const plan = await orb.plans.create({
    name: 'Pro Plan',
    prices: [{
        name: 'API Calls',
        item_id: 'api_calls',
        cadence: 'monthly',
        model_type: 'tiered',
        tiered_config: {
            tiers: [
                { first_unit: 0, last_unit: 10000, unit_amount: '0.000' },   // First 10K free
                { first_unit: 10001, last_unit: 100000, unit_amount: '0.001' }, // $0.001/call
                { first_unit: 100001, unit_amount: '0.0005' },                  // Volume discount
            ],
        },
    }],
});

// Ingest usage events
await orb.events.ingest({
    events: [{
        event_name: 'api_call',
        external_customer_id: tenant.id,
        timestamp: new Date().toISOString(),
        properties: {
            endpoint: '/v1/generate',
            model: 'gpt-4',
            tokens: 1500,
        },
    }],
});
```

### Hybrid Pricing (Platform Fee + Usage)

Most modern SaaS uses hybrid pricing: a base subscription fee + usage charges.

```
Plan: Pro ($49/month)
├── Includes: 5 seats, 10,000 API calls, 50GB storage
├── Additional seats: $10/seat/month
├── Additional API calls: $0.002/call after 10K
└── Additional storage: $0.10/GB/month after 50GB
```

### Credit-Based Pricing

Pre-paid credits consumed by usage. Common for AI/API products.

```typescript
// Credit system data model
interface CreditLedger {
    tenant_id: string;
    entries: CreditEntry[];
}

interface CreditEntry {
    id: string;
    type: 'purchase' | 'consumption' | 'grant' | 'expiry' | 'refund';
    amount: number;       // Positive for additions, negative for consumption
    balance_after: number;
    description: string;
    metadata: {
        invoice_id?: string;
        feature?: string;
        usage_event_id?: string;
    };
    created_at: Date;
    expires_at?: Date;
}

// Check credit balance before allowing action
async function consumeCredits(tenantId: string, amount: number, feature: string): Promise<boolean> {
    return db.transaction(async (tx) => {
        const balance = await tx.creditLedger.getBalance(tenantId);

        if (balance < amount) {
            return false;  // Insufficient credits
        }

        await tx.creditLedger.addEntry({
            tenant_id: tenantId,
            type: 'consumption',
            amount: -amount,
            balance_after: balance - amount,
            description: `${feature} usage`,
        });

        return true;
    });
}
```

### Freemium & Reverse Trial

**Freemium:** Free tier with limited features, paid tiers unlock more.
```
Free: 3 projects, 1 user, 1GB storage, community support
Pro ($15/user/mo): Unlimited projects, unlimited storage, email support
Enterprise (custom): SSO, SCIM, dedicated support, SLA, audit logs
```

**Reverse trial:** Start users on the full-featured plan, downgrade to free after trial ends. Users experience the best version first.
```typescript
// Reverse trial implementation
async function createTrialSubscription(tenantId: string): Promise<void> {
    // Start on Pro plan for 14 days
    await stripe.subscriptions.create({
        customer: tenant.stripeCustomerId,
        items: [{ price: 'price_pro_monthly' }],
        trial_period_days: 14,
        trial_settings: {
            end_behavior: { missing_payment_method: 'cancel' },
        },
    });

    // Schedule downgrade notification
    await queue.add('trial-ending-notification', { tenantId }, {
        delay: 11 * 24 * 60 * 60 * 1000,  // Day 11: "3 days left"
    });
}

// When trial ends without payment method → downgrade to Free
async function handleTrialEnd(tenantId: string): Promise<void> {
    await updateTenantPlan(tenantId, 'free');
    await revokeEntitlements(tenantId, 'pro');
    // User keeps their data, but loses Pro features
}
```

---

## 3. Subscription Lifecycle State Machine

```
                    ┌──────────────┐
                    │   Created    │
                    └──────┬───────┘
                           │ start trial / activate
                    ┌──────▼───────┐     trial ends + no payment
                    │   Trialing   │─────────────────────┐
                    └──────┬───────┘                      │
                           │ payment method added         │
                    ┌──────▼───────┐                      │
               ┌───▶│    Active    │◀──────────┐          │
               │    └──────┬───────┘           │          │
               │           │ payment fails     │ payment  │
               │    ┌──────▼───────┐           │ recovers │
               │    │   Past Due   │───────────┘          │
               │    └──────┬───────┘                      │
               │           │ dunning exhausted            │
               │    ┌──────▼───────┐                      │
               │    │  Unpaid /    │                      │
               │    │  Suspended   │◀─────────────────────┘
               │    └──────┬───────┘
               │           │ reactivation / cancel
               │    ┌──────▼───────┐
               │    │   Canceled   │
               │    └──────┬───────┘
               │           │ resubscribe
               └───────────┘
```

### State Transition Rules

```typescript
const subscriptionStateMachine = {
    created: {
        transitions: ['trialing', 'active'],
        on_enter: ['create_stripe_subscription', 'emit_subscription_created'],
    },
    trialing: {
        transitions: ['active', 'canceled', 'suspended'],
        on_enter: ['grant_trial_entitlements', 'schedule_trial_reminders'],
        on_exit: ['cancel_trial_reminders'],
    },
    active: {
        transitions: ['past_due', 'canceled'],
        on_enter: ['grant_plan_entitlements', 'emit_subscription_activated'],
    },
    past_due: {
        transitions: ['active', 'unpaid', 'canceled'],
        on_enter: ['start_dunning_sequence', 'notify_billing_admin'],
        max_duration_days: 14,  // Auto-transition to unpaid after 14 days
    },
    unpaid: {
        transitions: ['active', 'canceled'],
        on_enter: ['suspend_non_critical_features', 'notify_all_admins'],
    },
    canceled: {
        transitions: ['active'],  // Resubscription
        on_enter: ['revoke_entitlements', 'schedule_data_retention', 'emit_churn_event'],
    },
};
```

### Grace Periods

```typescript
// Grace period configuration
const gracePeriodConfig = {
    past_due: {
        duration_days: 7,             // 7 days before restricting features
        restricted_features: [],       // No restrictions during grace
        notification_schedule: [0, 3, 5, 7],  // Days: immediately, day 3, 5, 7
    },
    unpaid: {
        duration_days: 14,            // 14 days before data deletion warning
        restricted_features: [
            'new_project_creation',
            'team_invitations',
            'api_access',
            'integrations',
        ],
        retained_features: [
            'data_export',            // ALWAYS allow data export
            'read_access',            // Read-only access to existing data
            'billing_management',     // Allow them to fix payment
        ],
    },
};
```

---

## 4. Entitlements Engine

An entitlements engine maps plans to features, enforcing what each tenant can access.

### Architecture

```
┌──────────────────────────────────────────────────────┐
│                 Entitlements Engine                    │
│                                                       │
│  Plan ──▶ Features ──▶ Limits ──▶ Access Decision    │
│                                                       │
│  Pro Plan:                                            │
│  ├── feature:sso = true                              │
│  ├── feature:api_access = true                       │
│  ├── limit:seats = 25                                │
│  ├── limit:projects = unlimited                      │
│  └── limit:storage_gb = 100                          │
└──────────────────────────────────────────────────────┘
```

### Data Model

```sql
CREATE TABLE plans (
    id UUID PRIMARY KEY,
    name TEXT NOT NULL,         -- 'free', 'pro', 'enterprise'
    display_name TEXT NOT NULL, -- 'Free', 'Pro', 'Enterprise'
    is_public BOOLEAN DEFAULT true,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE plan_entitlements (
    id UUID PRIMARY KEY,
    plan_id UUID NOT NULL REFERENCES plans(id),
    feature_key TEXT NOT NULL,           -- 'sso', 'api_access', 'custom_domains'
    entitlement_type TEXT NOT NULL,      -- 'boolean', 'limit', 'tier'
    boolean_value BOOLEAN,              -- for boolean features
    limit_value BIGINT,                 -- for numeric limits (-1 = unlimited)
    tier_value TEXT,                     -- for tiered features ('basic', 'advanced')
    UNIQUE (plan_id, feature_key)
);

CREATE TABLE tenant_entitlement_overrides (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    feature_key TEXT NOT NULL,
    entitlement_type TEXT NOT NULL,
    boolean_value BOOLEAN,
    limit_value BIGINT,
    tier_value TEXT,
    reason TEXT,                         -- 'enterprise_contract', 'grandfathered', 'trial_extension'
    expires_at TIMESTAMPTZ,
    UNIQUE (tenant_id, feature_key)
);

-- Example data
INSERT INTO plan_entitlements (plan_id, feature_key, entitlement_type, boolean_value, limit_value) VALUES
    ('free-plan-id', 'sso', 'boolean', false, NULL),
    ('free-plan-id', 'seats', 'limit', NULL, 5),
    ('free-plan-id', 'projects', 'limit', NULL, 3),
    ('free-plan-id', 'api_access', 'boolean', false, NULL),
    ('pro-plan-id', 'sso', 'boolean', true, NULL),
    ('pro-plan-id', 'seats', 'limit', NULL, 25),
    ('pro-plan-id', 'projects', 'limit', NULL, -1),  -- unlimited
    ('pro-plan-id', 'api_access', 'boolean', true, NULL);
```

### Entitlement Check API

```typescript
class EntitlementsService {
    // Cache entitlements per tenant (invalidate on plan change)
    private cache = new Map<string, TenantEntitlements>();

    async checkFeature(tenantId: string, featureKey: string): Promise<boolean> {
        const entitlements = await this.getEntitlements(tenantId);
        const entitlement = entitlements.get(featureKey);

        if (!entitlement) return false;
        if (entitlement.type === 'boolean') return entitlement.booleanValue;
        return true;  // Feature exists for this plan
    }

    async checkLimit(tenantId: string, featureKey: string): Promise<{
        allowed: boolean;
        limit: number;
        current: number;
        remaining: number;
    }> {
        const entitlements = await this.getEntitlements(tenantId);
        const entitlement = entitlements.get(featureKey);

        if (!entitlement || entitlement.type !== 'limit') {
            return { allowed: false, limit: 0, current: 0, remaining: 0 };
        }

        if (entitlement.limitValue === -1) {
            return { allowed: true, limit: -1, current: 0, remaining: -1 };  // Unlimited
        }

        const currentUsage = await this.getCurrentUsage(tenantId, featureKey);
        const remaining = entitlement.limitValue - currentUsage;

        return {
            allowed: remaining > 0,
            limit: entitlement.limitValue,
            current: currentUsage,
            remaining: Math.max(0, remaining),
        };
    }

    private async getEntitlements(tenantId: string): Promise<Map<string, Entitlement>> {
        // Check cache first
        if (this.cache.has(tenantId)) return this.cache.get(tenantId)!;

        // Load from plan + overrides
        const tenant = await db.tenants.findById(tenantId);
        const planEntitlements = await db.planEntitlements.findByPlan(tenant.planId);
        const overrides = await db.tenantEntitlementOverrides.findByTenant(tenantId);

        // Merge: overrides take precedence over plan defaults
        const merged = new Map<string, Entitlement>();
        for (const pe of planEntitlements) {
            merged.set(pe.featureKey, pe);
        }
        for (const override of overrides) {
            if (!override.expiresAt || override.expiresAt > new Date()) {
                merged.set(override.featureKey, override);
            }
        }

        this.cache.set(tenantId, merged);
        return merged;
    }

    // Call this when plan changes, override added, etc.
    invalidateCache(tenantId: string): void {
        this.cache.delete(tenantId);
    }
}
```

### Middleware for Entitlement Checks

```typescript
// Express middleware: check entitlement before route handler
function requireFeature(featureKey: string) {
    return async (req: Request, res: Response, next: NextFunction) => {
        const result = await entitlements.checkFeature(req.tenantId, featureKey);
        if (!result) {
            return res.status(403).json({
                error: 'feature_not_available',
                feature: featureKey,
                upgrade_url: `/billing/upgrade?feature=${featureKey}`,
                message: `This feature requires a plan upgrade.`,
            });
        }
        next();
    };
}

function requireLimit(featureKey: string) {
    return async (req: Request, res: Response, next: NextFunction) => {
        const result = await entitlements.checkLimit(req.tenantId, featureKey);
        if (!result.allowed) {
            return res.status(403).json({
                error: 'limit_exceeded',
                feature: featureKey,
                limit: result.limit,
                current: result.current,
                upgrade_url: `/billing/upgrade?feature=${featureKey}`,
                message: `You've reached the ${featureKey} limit for your plan.`,
            });
        }
        next();
    };
}

// Usage
app.post('/api/projects', requireLimit('projects'), createProjectHandler);
app.get('/api/sso/config', requireFeature('sso'), getSSOConfigHandler);
```

---

## 5. Dunning & Failed Payment Recovery

Dunning (recovering failed payments) is one of the highest-ROI billing features. Failed payments cause 20-40% of all churn in SaaS (involuntary churn).

### Retry Schedule

```typescript
const dunningConfig = {
    // Stripe Smart Retries handles most of this automatically.
    // Configure in Stripe Dashboard > Settings > Subscriptions and emails > Manage failed payments.

    retry_schedule: [
        { day: 0, action: 'retry_payment' },           // Immediate retry
        { day: 1, action: 'retry_payment' },           // Day 1
        { day: 3, action: 'retry_payment', notify: 'billing_admin' },  // Day 3
        { day: 5, action: 'retry_payment', notify: 'billing_admin' },  // Day 5
        { day: 7, action: 'retry_payment', notify: 'all_admins', restrict: true }, // Day 7: restrict
        { day: 10, action: 'retry_payment', notify: 'all_admins' },    // Day 10
        { day: 14, action: 'final_attempt', notify: 'all_admins' },    // Day 14: last try
        { day: 15, action: 'cancel_subscription' },    // Day 15: cancel
    ],

    // In-app notifications
    notifications: {
        banner: true,           // Show "Payment failed" banner in app
        email_sequence: true,   // Send email sequence
        in_app_modal: true,     // Show modal after 7 days
    },

    // Feature restrictions during dunning
    restrictions: {
        after_day_7: ['new_project_creation', 'team_invitations'],
        after_day_14: ['api_access', 'integrations', 'exports'],
        never_restrict: ['data_export', 'billing_management', 'read_access'],
    },
};
```

### Update Payment Method UX

```typescript
// Generate a Stripe Billing Portal link for self-serve payment update
const session = await stripe.billingPortal.sessions.create({
    customer: tenant.stripeCustomerId,
    return_url: `${APP_URL}/settings/billing`,
    flow_data: {
        type: 'payment_method_update',  // Direct to payment method update
    },
});

// Redirect user to session.url
```

---

## 6. Plan Migration & Proration

### Upgrade/Downgrade Flows

```typescript
// Upgrade: immediate, with proration
async function upgradePlan(tenantId: string, newPriceId: string): Promise<void> {
    const tenant = await db.tenants.findById(tenantId);
    const subscription = await stripe.subscriptions.retrieve(tenant.stripeSubscriptionId);

    await stripe.subscriptions.update(subscription.id, {
        items: [{
            id: subscription.items.data[0].id,
            price: newPriceId,
        }],
        proration_behavior: 'create_prorations',  // Charge the difference immediately
    });

    // Update entitlements immediately
    await entitlements.upgradePlan(tenantId, newPriceId);
    await entitlements.invalidateCache(tenantId);

    await events.emit('subscription.upgraded', { tenantId, newPriceId });
}

// Downgrade: at end of billing period
async function downgradePlan(tenantId: string, newPriceId: string): Promise<void> {
    const tenant = await db.tenants.findById(tenantId);
    const subscription = await stripe.subscriptions.retrieve(tenant.stripeSubscriptionId);

    // Schedule downgrade for end of period
    await stripe.subscriptions.update(subscription.id, {
        items: [{
            id: subscription.items.data[0].id,
            price: newPriceId,
        }],
        proration_behavior: 'none',  // Don't prorate — change at period end
    });

    // Schedule entitlement change for end of period
    await queue.add('apply-downgrade', {
        tenantId,
        newPriceId,
        effective_at: subscription.current_period_end,
    });

    await events.emit('subscription.downgrade_scheduled', { tenantId, newPriceId });
}
```

### Proration Calculation

```
Upgrade from $49/mo to $99/mo on day 15 of 30-day cycle:

Remaining days: 15/30 = 50% of cycle remaining

Credit for unused Pro time: $49 * 50% = $24.50 (credit)
Charge for remaining Business time: $99 * 50% = $49.50 (charge)

Net charge: $49.50 - $24.50 = $25.00 (charged immediately)
Next month: $99.00 (full Business price)
```

---

## 7. Tax Handling

### Merchant of Record (MoR) vs DIY Tax

**MoR (Paddle, LemonSqueezy):** They are the seller of record. They handle all tax collection, remittance, and compliance. You receive payouts net of tax. Simplest approach but highest fees.

**DIY with Tax API (Stripe Tax, Avalara):** You are the seller. You must register for tax in applicable jurisdictions, collect the right amount, file returns, and remit. More control, lower fees, more work.

**Decision guide:**
- Selling globally to individuals/SMB with < $5M ARR → MoR (Paddle/LemonSqueezy)
- Selling primarily B2B in US/EU with existing entity → Stripe Tax or Avalara
- Enterprise with in-house finance team → Avalara or custom tax engine

### Stripe Tax Integration

```typescript
// Enable Stripe Tax on subscription creation
const subscription = await stripe.subscriptions.create({
    customer: tenant.stripeCustomerId,
    items: [{ price: 'price_pro_monthly' }],
    automatic_tax: { enabled: true },
});

// Stripe Tax automatically:
// - Determines the customer's tax jurisdiction from their address
// - Calculates the correct tax rate
// - Adds tax to the invoice
// - Reports it for your tax filings
```

---

## 8. Revenue Recognition

### ASC 606 / IFRS 15 Basics for SaaS

Revenue must be recognized when (or as) performance obligations are satisfied — not when cash is collected.

**SaaS revenue recognition patterns:**

| Scenario | Recognition Pattern |
|----------|-------------------|
| Monthly subscription (flat) | Recognize evenly over the month |
| Annual subscription (prepaid) | Recognize 1/12 each month (deferred revenue) |
| Usage-based | Recognize when usage occurs |
| Setup/onboarding fee | Recognize over estimated customer lifetime (or contract term) |
| Credits purchased | Recognize when credits are consumed |
| Enterprise contract with commit | Recognize as delivered against the commit |

### Deferred Revenue Tracking

```sql
CREATE TABLE revenue_schedules (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    invoice_id TEXT NOT NULL,       -- Stripe invoice ID
    total_amount BIGINT NOT NULL,   -- Total revenue in cents
    recognized BIGINT DEFAULT 0,    -- Amount recognized so far
    deferred BIGINT NOT NULL,       -- Amount still deferred
    recognition_start DATE NOT NULL,
    recognition_end DATE NOT NULL,
    cadence TEXT DEFAULT 'monthly', -- 'daily', 'monthly'
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Monthly recognition job
-- For an annual plan of $1,200 (paid upfront):
-- Each month: recognize $100, reduce deferred by $100
INSERT INTO revenue_schedules (tenant_id, invoice_id, total_amount, deferred,
                                recognition_start, recognition_end)
VALUES ('tenant-uuid', 'in_xxx', 120000, 120000, '2026-01-01', '2026-12-31');
```

---

## 9. Webhook Architecture for Billing

### Essential Stripe Webhooks

```typescript
// Webhook handler for billing events
app.post('/webhooks/stripe', async (req, res) => {
    const event = stripe.webhooks.constructEvent(
        req.body,
        req.headers['stripe-signature'],
        STRIPE_WEBHOOK_SECRET
    );

    // Idempotency: check if we've already processed this event
    const processed = await db.webhookEvents.findByStripeEventId(event.id);
    if (processed) {
        return res.json({ received: true, duplicate: true });
    }

    switch (event.type) {
        case 'customer.subscription.created':
            await handleSubscriptionCreated(event.data.object);
            break;

        case 'customer.subscription.updated':
            await handleSubscriptionUpdated(event.data.object);
            break;

        case 'customer.subscription.deleted':
            await handleSubscriptionCanceled(event.data.object);
            break;

        case 'invoice.payment_succeeded':
            await handlePaymentSucceeded(event.data.object);
            break;

        case 'invoice.payment_failed':
            await handlePaymentFailed(event.data.object);
            break;

        case 'customer.subscription.trial_will_end':
            await handleTrialEnding(event.data.object);  // 3 days before trial ends
            break;
    }

    // Record that we processed this event
    await db.webhookEvents.create({
        stripe_event_id: event.id,
        type: event.type,
        processed_at: new Date(),
    });

    res.json({ received: true });
});
```

### Webhook Reliability Patterns

1. **Always verify the signature** — never trust raw webhook payloads
2. **Idempotent processing** — Stripe may deliver the same event multiple times
3. **Respond quickly (< 5 seconds)** — process asynchronously if heavy work is needed
4. **Handle out-of-order events** — `subscription.updated` may arrive before `subscription.created`
5. **Store raw events** — for debugging, replay, and audit trail

```typescript
// Async processing pattern for reliable webhooks
app.post('/webhooks/stripe', async (req, res) => {
    const event = stripe.webhooks.constructEvent(/* ... */);

    // Respond immediately
    res.json({ received: true });

    // Process asynchronously
    await queue.add('process-stripe-webhook', {
        eventId: event.id,
        eventType: event.type,
        data: event.data.object,
    });
});
```

---

## 10. Self-Serve vs Sales-Assisted Billing

### PLG (Product-Led Growth) Billing

```
User flow:
1. Sign up (no credit card required)
2. Use free tier / trial
3. Hit a limit or discover a premium feature
4. Self-serve upgrade via in-app checkout
5. Manage subscription via billing portal
```

**Key features for PLG billing:**
- Transparent pricing page (no "contact sales" for standard plans)
- Self-serve checkout (Stripe Checkout or embedded payment form)
- In-app upgrade prompts at the moment of need
- Self-serve billing portal (Stripe Customer Portal)
- Plan comparison visible from within the app

### Sales-Assisted / Enterprise Billing

```
User flow:
1. Contact sales (or sales reaches out based on usage)
2. Custom quote / proposal
3. Contract negotiation (custom terms, SLAs, pricing)
4. PO / invoice-based payment (net-30, net-60)
5. Annual or multi-year commitment
6. Managed account with CSM
```

**Key features for enterprise billing:**
- Custom pricing (per-tenant overrides)
- Invoice-based payment (not just credit card)
- PO (purchase order) support
- Multi-year contract management
- Usage commitments with drawdown
- Enterprise entitlement overrides (custom limits beyond any standard plan)

### Hybrid: PLG + Sales

Most successful B2B SaaS uses hybrid billing:

```
Free → Self-serve Pro ($15/user/mo) → "Talk to Sales" Enterprise (custom)
        │                                    │
        │ Self-serve checkout               │ Custom quote + contract
        │ Credit card payment               │ Invoice, PO, net-30
        │ Monthly or annual                 │ Annual or multi-year
        │ Standard entitlements             │ Custom entitlements
        │ In-app support                    │ Dedicated CSM + SLA
```

---

## 11. Billing Data Model

```sql
-- Core billing tables (supplement what Stripe stores)
CREATE TABLE billing_customers (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL UNIQUE REFERENCES tenants(id),
    stripe_customer_id TEXT NOT NULL UNIQUE,
    billing_email TEXT NOT NULL,
    billing_name TEXT,
    tax_id TEXT,
    address JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE subscriptions (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES tenants(id),
    stripe_subscription_id TEXT NOT NULL UNIQUE,
    plan_id UUID NOT NULL REFERENCES plans(id),
    status TEXT NOT NULL,              -- 'trialing', 'active', 'past_due', 'canceled'
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    trial_end TIMESTAMPTZ,
    cancel_at TIMESTAMPTZ,
    canceled_at TIMESTAMPTZ,
    quantity INT,                       -- Seat count
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE billing_events (
    id UUID PRIMARY KEY,
    tenant_id UUID NOT NULL,
    stripe_event_id TEXT NOT NULL UNIQUE,
    event_type TEXT NOT NULL,
    data JSONB NOT NULL,
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX idx_subscriptions_tenant ON subscriptions(tenant_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_billing_events_tenant ON billing_events(tenant_id);
CREATE INDEX idx_billing_events_type ON billing_events(event_type);
```

---

## 12. Billing Infrastructure Anti-Patterns

### 1. Building Your Own Payment Processing

**Problem:** Building custom payment forms, PCI compliance, tokenization.
**Fix:** Use Stripe Elements or Checkout. Stay at PCI SAQ A (hosted payment fields). Never let card data touch your servers.

### 2. Billing as an Afterthought

**Problem:** Adding billing after the product is built, leading to entitlements being scattered across codebase.
**Fix:** Design the entitlements engine early. Every feature gate should check the entitlements service, not hardcode plan names.

### 3. Hardcoding Plan Names in Code

**Problem:** `if (plan === 'pro')` scattered everywhere.
**Fix:** Use the entitlements engine: `if (await entitlements.checkFeature(tenantId, 'sso'))`.

### 4. Not Handling Failed Payments

**Problem:** Ignoring `invoice.payment_failed` webhooks. Customers churn silently.
**Fix:** Implement proper dunning: retry schedule, notifications, payment update flow. This recovers 30-60% of failed payments.

### 5. Ignoring Proration Edge Cases

**Problem:** Upgrade/downgrade mid-cycle with incorrect proration. Customers are overcharged or undercharged.
**Fix:** Let Stripe handle proration (`proration_behavior: 'create_prorations'`). Test all plan change scenarios.

### 6. Not Storing Billing Events Locally

**Problem:** Relying solely on Stripe Dashboard for billing history. Can't correlate billing with app events.
**Fix:** Store all webhook events and maintain local subscription state. Mirror essential Stripe data.

### 7. Tax Non-Compliance

**Problem:** Not collecting sales tax, VAT, or GST. This is a ticking time bomb.
**Fix:** Enable Stripe Tax or use a MoR. Consult a tax advisor for your specific situation.
