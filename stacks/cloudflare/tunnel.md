---
title: Cloudflare Tunnel
description: cloudflared-based outbound tunnel from your origin to Cloudflare — expose private services to Workers, Access, or the public without opening inbound firewall holes.
product:
  name: Cloudflare Tunnel
  stack: cloudflare
  drift_risk: medium
  last_verified_on: "2026-05-14"
  authoritative_url: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/
  applies_to_roles: [security-engineer, devops-engineer, system-architect]
  notes: "cloudflared replaces VPN ingress; preferred path to expose private origins. Config syntax and route models evolve through 2025-2026."
---

## What it is

Cloudflare Tunnel uses the `cloudflared` daemon to establish outbound connections from your origin (a corp datacenter, a VPC private subnet, a developer laptop) to Cloudflare. Cloudflare then routes inbound traffic — from the public internet, from a [Worker](/stacks/cloudflare/workers/), from [Hyperdrive](/stacks/cloudflare/hyperdrive/), from [Access](/stacks/cloudflare/access/) — through the tunnel to that origin. **The origin has no public IP and no inbound firewall holes.**

Authoritative reference: [developers.cloudflare.com/cloudflare-one/connections/connect-networks](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/).

## When to use

- **Expose a private origin to the public internet** with TLS terminated at Cloudflare and no public IP on the origin.
- **Replace a VPN for employee access** to internal services — pair with [Access](/stacks/cloudflare/access/) for ZTNA.
- **Connect [Hyperdrive](/stacks/cloudflare/hyperdrive/) to a private Postgres/MySQL** that you don't want exposed publicly.
- **Site-to-site connectivity from non-Cloudflare networks** — `cloudflared` running on the corp side, route TCP/UDP through the tunnel.
- **Developer laptops exposing local services** for sharing or testing without ngrok-style intermediaries.

Don't reach for Tunnel when:

- The origin is already a Cloudflare Workers / Pages / Static Assets surface — there's nothing to tunnel.
- The origin is a public cloud LB you control and trust — Cloudflare proxy + Authenticated Origin Pulls covers the threat model with less moving parts.

## 2025-2026 currency anchors

- **Tunnels are the recommended path** for any private origin behind Cloudflare; the older "Argo Tunnel" branding is retired.
- **Config-as-code** via Cloudflare API + Terraform `cloudflare_tunnel` + `cloudflare_tunnel_config` resources is canonical.
- **Hyperdrive + Tunnel** is the standard pattern for serverless access to a private DB — see [Hyperdrive](/stacks/cloudflare/hyperdrive/).
- **WARP-to-Tunnel** connects WARP-enrolled devices into private networks reached via Tunnel.

## Patterns

### Create a tunnel, route a hostname

```bash
cloudflared tunnel create my-tunnel
cloudflared tunnel route dns my-tunnel internal.example.com
# config.yml on the origin:
#   tunnel: <tunnel-id>
#   credentials-file: /etc/cloudflared/<tunnel-id>.json
#   ingress:
#     - hostname: internal.example.com
#       service: http://localhost:8080
#     - service: http_status:404
cloudflared tunnel run my-tunnel
```

### Terraform-managed tunnel

```hcl
resource "cloudflare_tunnel" "private_origin" {
  account_id = var.account_id
  name       = "private-origin"
  secret     = random_password.tunnel_secret.result
}

resource "cloudflare_tunnel_config" "private_origin" {
  account_id = var.account_id
  tunnel_id  = cloudflare_tunnel.private_origin.id
  config {
    ingress_rule {
      hostname = "internal.example.com"
      service  = "http://internal:8080"
    }
    ingress_rule { service = "http_status:404" }
  }
}
```

### Hyperdrive over Tunnel for a private Postgres

```bash
cloudflared tunnel create pg-tunnel
cloudflared tunnel route ip add 10.0.1.0/24 pg-tunnel
wrangler hyperdrive create my-hyperdrive --connection-string="postgres://user:pass@10.0.1.42:5432/db"
```

The DB binds to a private IP. Hyperdrive resolves through the tunnel; the Postgres host firewall denies anything not from `cloudflared`'s local address.

### Tunnel + Access — modern ZTNA

```
[User] -> [Cloudflare zone, Access policy] -> [Tunnel] -> [Private origin, no public IP]
```

Origin firewall denies all inbound. Identity is enforced at Cloudflare. The user never sees the origin IP; the origin never sees the public internet.

## Anti-patterns

- **Tunnel for a public origin you already control.** If the origin sits behind a public LB, Cloudflare proxy + [Authenticated Origin Pulls](/stacks/cloudflare/waf/) gives most of the value with fewer moving parts.
- **Running `cloudflared` as root or with broad network access** in the origin environment. Scope the host's outbound allow-list; treat the daemon like any other privileged agent.
- **Hand-managing tunnel configs across many environments.** Use Terraform / Pulumi — the resource shape maps cleanly to IaC.
- **Forgetting to wire `cloudflared` health into your monitoring.** A dead tunnel = downtime; the daemon should be a watched service.

## Gotchas

1. **`cloudflared` requires an outbound HTTPS/QUIC path** from origin to Cloudflare — locked-down egress firewalls need explicit allow-lists for Cloudflare's tunnel IPs.
2. **Tunnel credentials are sensitive.** The `<tunnel-id>.json` file is a secret; store it in your secrets manager and inject at boot, not in the repo.
3. **One tunnel can route many hostnames** — don't create a tunnel per app unless isolation is a real requirement.
4. **TCP/UDP routing requires the WARP client** on the consuming side, or [Workers](/stacks/cloudflare/workers/) for HTTP fronting.
5. **`cloudflared` versions matter** — older releases miss QUIC support and reconnect behaviors; pin a recent release and roll on a cadence.

## Cross-references

- [Access (ZTNA)](/stacks/cloudflare/access/) — identity layer composed with tunnels
- [Hyperdrive](/stacks/cloudflare/hyperdrive/) — private DB access pattern
- [Workers](/stacks/cloudflare/workers/) — Worker → Tunnel → private origin
- [WAF + Managed Rulesets](/stacks/cloudflare/waf/) — Authenticated Origin Pulls alternative for public origins
- [Magic Transit](/stacks/cloudflare/magic-transit/) — L3/L4 enterprise networking when Tunnel isn't enough
- Role overlay: [security-engineer on Cloudflare](/stacks/cloudflare/security-engineer/), [devops-engineer on Cloudflare](/stacks/cloudflare/devops-engineer/)
- Authoritative: [developers.cloudflare.com/cloudflare-one/connections/connect-networks](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
