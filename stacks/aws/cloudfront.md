---
title: CloudFront
description: AWS CDN — global edge network, CloudFront Functions for sub-1ms header/URL manipulation, Lambda@Edge for full Node/Python runtime, WAF integration for HTTP API.
product:
  name: CloudFront
  stack: aws
  drift_risk: low
  last_verified_on: "2026-05-14"
  applies_to_roles: [backend-architect, system-architect, security-engineer]
  authoritative_url: https://docs.aws.amazon.com/cloudfront/
  notes: "IPv6/BYOIP added 2025-2026; core surface mature; CloudFront Functions vs Lambda@Edge decision stable."
---

## What it is

Amazon CloudFront is AWS's CDN — global edge network for content delivery, with edge compute via CloudFront Functions (sub-1ms JS) and Lambda@Edge (full Node/Python runtime). Sits in front of S3, ALB, API Gateway, or any HTTP origin.

Canonical surface: [docs.aws.amazon.com/cloudfront](https://docs.aws.amazon.com/cloudfront/).

## When to use

| Need | Use CloudFront? |
|---|---|
| Global content distribution | Yes |
| Cache layer in front of S3 static site / SPA | Yes |
| Cache + WAF in front of [API Gateway HTTP API](/stacks/aws/api-gateway/) | Yes |
| Cache + WAF in front of ALB / [ECS](/stacks/aws/ecs/) / [EKS](/stacks/aws/eks/) | Yes |
| Header manipulation, URL rewrites, simple A/B | Yes — CloudFront Functions |
| Auth check, origin selection, complex logic | Yes — Lambda@Edge |
| Single-region API with no caching | Probably not — just put ALB or API Gateway directly |

## 2025-2026 currency anchors

- **IPv6 + BYOIP** added 2025-2026.
- **CloudFront Functions** matured — JS, sub-1ms, 2 MB code limit, runs at every edge.
- **Lambda@Edge** for full Node/Python runtime (5-30s, 128MB-3GB).
- **Origin Access Control (OAC)** preferred over legacy Origin Access Identity (OAI) for S3 origins.
- **Real-time logs** to Kinesis Data Streams.

## Patterns

### CloudFront Functions vs Lambda@Edge

| Choice | Use for |
|---|---|
| **CloudFront Functions** | Header manipulation, URL rewrites, simple A/B, sub-1ms, 2 MB code, JS only |
| **Lambda@Edge** | Auth, origin selection, full Node/Python runtime, 5-30s, 128MB-3GB |

Default: CloudFront Functions for what they support; Lambda@Edge for the rest.

### S3 + OAC

```typescript
const distribution = new cloudfront.Distribution(this, 'SpaDistribution', {
  defaultBehavior: {
    origin: cloudfront_origins.S3BucketOrigin.withOriginAccessControl(spaBucket),
    viewerProtocolPolicy: cloudfront.ViewerProtocolPolicy.REDIRECT_TO_HTTPS,
    cachePolicy: cloudfront.CachePolicy.CACHING_OPTIMIZED,
  },
  defaultRootObject: 'index.html',
  errorResponses: [{
    httpStatus: 404,
    responseHttpStatus: 200,
    responsePagePath: '/index.html',  // SPA fallback
  }],
});
```

OAC replaces OAI for S3 origins; supports SigV4 with KMS-encrypted buckets.

### WAF integration

CloudFront supports AWS WAF web ACLs (`SCOPE = CLOUDFRONT`):
- Managed rule groups (CommonRuleSet, KnownBadInputsRuleSet, SQLiRuleSet).
- Rate-based rules.
- Geo blocking, IP allow/deny.
- Bot Control v2.

See [`/stacks/aws/security-engineer/`](/stacks/aws/security-engineer/) for WAF configuration.

### Origin failover

```typescript
new cloudfront.OriginGroup({
  primaryOrigin: primaryAlb,
  fallbackOrigin: secondaryAlb,
  fallbackStatusCodes: [500, 502, 503, 504],
});
```

For multi-region failover at the edge.

### Cache invalidation

```bash
aws cloudfront create-invalidation \
  --distribution-id ABCDEF \
  --paths "/index.html" "/static/*"
```

First 1000 invalidation paths/month are free; after that paid. **Don't invalidate on every deploy** — use versioned asset URLs (content-hash filenames) so cache invalidation is rare.

### Real-time logs

To Kinesis Data Streams (subset of standard logs, but real-time). Use for:
- Real-time monitoring dashboards.
- Bot detection / WAF feeding.

Standard logs to S3 are cheaper for archival + Athena.

## Anti-patterns

- **OAI for new S3 origins.** Use OAC.
- **Cache invalidation on every deploy.** Version asset URLs.
- **No WAF on production CloudFront.** Free DDoS protection from Shield Standard is included, but L7 attacks need WAF.
- **Lambda@Edge for things CloudFront Functions can do.** CFF is sub-ms and cheaper.
- **Single origin for global apps without failover.** Configure origin failover.
- **No HSTS / security headers** on CloudFront responses. Add via response headers policy or CloudFront Functions.

## Gotchas

- **Distribution deploys take 5-30 minutes** to propagate to all edges. Plan deployment windows.
- **Cache policies vs cache behaviors** — cache policy is reusable; behavior is per-path-pattern.
- **HTTP/2 + HTTP/3** support varies — enable both for modern clients.
- **OAC requires bucket policy updates** at the S3 side — CDK handles this; manual setups need attention.
- **Origin Shield** ($) reduces origin load by adding a tier between edges and origin; not needed for low-traffic.
- **Edge function execution cost** is significant at high RPS — measure.

## Cross-references

- [`/stacks/aws/s3/`](/stacks/aws/s3/) — common origin
- [`/stacks/aws/api-gateway/`](/stacks/aws/api-gateway/) — HTTP API + CloudFront for WAF + cache
- [`/stacks/aws/route-53/`](/stacks/aws/route-53/) — DNS + alias record to CloudFront
- [`/stacks/aws/security-engineer/`](/stacks/aws/security-engineer/) — WAF + Shield posture
- [CloudFront Functions docs](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cloudfront-functions.html)
