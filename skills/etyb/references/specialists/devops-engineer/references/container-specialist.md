# Container Engineering — Deep Reference

**Always use `WebSearch` to verify version numbers, benchmarks, and features before giving advice. This reference provides architectural context; the ecosystem evolves rapidly.**

## Table of Contents
1. [Docker and Dockerfile Best Practices](#1-docker-and-dockerfile-best-practices)
2. [Base Image Selection](#2-base-image-selection)
3. [Image Optimization](#3-image-optimization)
4. [Container Security](#4-container-security)
5. [OCI Standards](#5-oci-standards)
6. [Container Runtimes](#6-container-runtimes)
7. [Build Tools Beyond Docker](#7-build-tools-beyond-docker)
8. [Container Registries](#8-container-registries)
9. [WebAssembly Containers](#9-webassembly-containers)
10. [Debugging Containers](#10-debugging-containers)
11. [Container Patterns](#11-container-patterns)
12. [Decision Matrices](#12-decision-matrices)

---

## 1. Docker and Dockerfile Best Practices

### Docker Desktop and Engine (2025-2026)

Docker Desktop ships biweekly since v4.45.0 (Aug 2025). Key milestones:

| Version | Release | Highlights |
|---------|---------|------------|
| **4.37** | Late 2024 | Desktop CLI controller (beta) |
| **4.39** | Mar 2025 | Smart AI Agent with MCP + K8s, Desktop CLI GA, multi-platform enhancements |
| **4.45+** | Aug 2025 | Biweekly release cadence begins |
| **Compose v5** | Dec 2025 | Delegates builds to Docker Bake, new Go SDK |

**Docker Build Cloud** offloads builds to remote AMD + ARM builders with shared cache (up to 39x faster). Included in Pro (200 min), Team (500 min), Business (1500 min). Cache management is automatic -- no `cache-to` / `cache-from` needed.

**Docker Scout** generates SBOMs for every image automatically (2026), integrates into Desktop, CLI, and CI/CD. Zero setup if your team uses Docker Desktop.

**Docker Init** scaffolds Dockerfile, Compose file, and `.dockerignore` for Go, Node, Python, Java (Maven), Rust, PHP, ASP.NET Core, and a generic "Other" template.

### Multi-Stage Builds

Multi-stage builds are the single most impactful optimization. They separate build-time dependencies from runtime, reducing images by up to 97%.

**Node.js -- production multi-stage:**

```dockerfile
# syntax=docker/dockerfile:1
FROM node:22-slim AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --production

FROM node:22-slim AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci
COPY . .
RUN npm run build

FROM gcr.io/distroless/nodejs22-debian12
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
USER nonroot
EXPOSE 3000
CMD ["dist/server.js"]
```

**Go -- scratch-based:**

```dockerfile
FROM golang:1.23 AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download
COPY . .
RUN --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app ./cmd/server

FROM scratch
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=build /app /app
USER 65534:65534
ENTRYPOINT ["/app"]
```

**Python -- distroless:**

```dockerfile
FROM python:3.13-slim AS build
WORKDIR /app
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --no-compile -r requirements.txt
COPY . .

FROM gcr.io/distroless/python3-debian12
WORKDIR /app
COPY --from=build /opt/venv /opt/venv
COPY --from=build /app .
ENV PATH="/opt/venv/bin:$PATH"
USER nonroot
CMD ["main.py"]
```

**Java -- Jib-style layered:**

```dockerfile
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app
COPY gradlew build.gradle.kts settings.gradle.kts ./
COPY gradle ./gradle
RUN --mount=type=cache,target=/root/.gradle \
    ./gradlew dependencies --no-daemon
COPY src ./src
RUN --mount=type=cache,target=/root/.gradle \
    ./gradlew bootJar --no-daemon -x test

FROM eclipse-temurin:21-jre-alpine
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
USER app
EXPOSE 8080
ENTRYPOINT ["java", "-XX:+UseZGC", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
```

### BuildKit Cache Mounts

Cache mounts (`--mount=type=cache`) persist package manager caches between builds:

| Language | Cache Target |
|----------|-------------|
| **npm** | `--mount=type=cache,target=/root/.npm` |
| **pip** | `--mount=type=cache,target=/root/.cache/pip` |
| **Go** | `--mount=type=cache,target=/go/pkg/mod` and `target=/root/.cache/go-build` |
| **Gradle** | `--mount=type=cache,target=/root/.gradle` |
| **Maven** | `--mount=type=cache,target=/root/.m2` |
| **Cargo** | `--mount=type=cache,target=/usr/local/cargo/registry` |

### Compose v5 and Watch Mode

Compose Watch (`docker compose watch`, GA 2025) monitors local files and syncs changes into running containers without rebuild. Supports `sync` (copy files in), `rebuild` (trigger full rebuild), and `sync+restart` strategies. The `initial_sync` feature (Sep 2025) syncs all files on startup before monitoring.

Profiles manage environment variants from one file:

```yaml
services:
  api:
    build: .
    profiles: [dev, prod]
  debug-tools:
    image: nicolaka/netshoot
    profiles: [dev]
  monitoring:
    image: prom/prometheus
    profiles: [prod]
```

### .dockerignore Best Practices

Start with an allowlist pattern -- ignore everything, then selectively include:

```
*
!src/
!package.json
!package-lock.json
!tsconfig.json
```

Always exclude: `.git`, `node_modules`, `__pycache__`, `.env`, `*.md`, `docker-compose*.yml`, `.vscode`, `.idea`, `coverage/`, `dist/` (if rebuilding in container).

---

## 2. Base Image Selection

### Comparison Matrix

| Base Image | Compressed Size | Package Manager | Shell | glibc/musl | Known CVEs (typical) | Debugging | Best For |
|------------|----------------|-----------------|-------|------------|---------------------|-----------|----------|
| **Ubuntu 24.04** | ~30 MB | apt | yes | glibc | 20-50 | easy | dev/test environments |
| **Debian 12 slim** | ~25 MB | apt | yes | glibc | 15-40 | easy | apps needing apt packages |
| **Alpine 3.21** | ~3.5 MB | apk | yes | musl | 5-15 | moderate | small images with shell access |
| **Distroless (static)** | ~2 MB | none | no | glibc | 0-3 | hard | Go, Rust (static binaries) |
| **Distroless (base)** | ~15 MB | none | no | glibc | 0-5 | hard | Node, Python, Java |
| **Chainguard/Wolfi** | ~5-15 MB | apk | optional | glibc | 0 (target) | moderate | security-critical production |
| **scratch** | 0 MB | none | no | none | 0 | very hard | fully static binaries only |

### When to Use Each

**scratch** -- Only for statically compiled binaries (Go with `CGO_ENABLED=0`, Rust with `musl`). Include CA certificates manually if making HTTPS calls.

**Distroless** -- Google-maintained. Contains CA certs, timezone data, glibc. No shell, no package manager. Variants: `static` (no libc), `base` (glibc), `cc` (libgcc), `python3`, `nodejs`, `java`. Use `gcr.io/distroless/static-debian12` for Go, `gcr.io/distroless/nodejs22-debian12` for Node.

**Chainguard/Wolfi** -- Built with `apko`/`melange` toolchain. Zero or near-zero CVEs on release day. Rebuilt within 4 hours of upstream patches. 2000+ images available. Multi-layer images (May 2025) achieved ~70% reduction in unique layer data across catalog. Uses glibc (not musl), which avoids Alpine DNS resolution and performance edge cases.

**Alpine** -- Excellent for images needing a shell and package manager at small size. Watch for `musl` compatibility issues with some C libraries. Pin versions: `alpine:3.21`, never `alpine:latest`.

---

## 3. Image Optimization

### Layer Ordering for Cache Efficiency

Order Dockerfile instructions from least-frequently-changed to most:

1. Base image (FROM)
2. System dependencies (apt/apk install)
3. Language runtime configuration
4. Dependency manifests (package.json, go.mod, requirements.txt)
5. Dependency install
6. Application source code
7. Build step
8. Runtime configuration

### Reducing Image Size

| Technique | Typical Savings |
|-----------|----------------|
| Multi-stage builds | 70-97% |
| Switch `ubuntu` to `distroless/static` | 800 MB to 15-30 MB |
| `--mount=type=cache` (avoid re-downloading) | Build time: 2-10x faster |
| Combine RUN commands | 5-20% (fewer layers) |
| `--no-install-recommends` (apt) | 10-40% |
| Strip binaries (`-ldflags="-s -w"` for Go) | 20-30% of binary size |
| Use `.dockerignore` | Prevents context bloat |

### Multi-Platform Builds

Build for AMD64 and ARM64 simultaneously with `docker buildx`:

```bash
# Create and use a multi-platform builder
docker buildx create --name multiarch --driver docker-container --use

# Build and push for both architectures
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag myregistry/app:1.0.0 \
  --push .
```

Docker Build Cloud provides native AMD + ARM builders -- no QEMU emulation needed. For CI, kaniko and Buildah also support multi-platform via manifest lists.

### Build Cache Strategies

| Strategy | Use When |
|----------|----------|
| **Inline cache** (`--cache-to type=inline`) | Simple setups, single-platform |
| **Registry cache** (`--cache-to type=registry`) | CI/CD with shared registry |
| **Local cache** (`--cache-to type=local`) | Single-machine builds |
| **Docker Build Cloud** | Team-shared cache, automatic management |
| **GitHub Actions cache** (`--cache-to type=gha`) | GitHub Actions CI |

---

## 4. Container Security

### Image Scanning Tools

| Tool | Type | SBOM Generation | VEX Support | CI Integration | Pricing |
|------|------|----------------|-------------|---------------|---------|
| **Trivy** (v0.68+) | OSS (Aqua) | CycloneDX, SPDX | CSAF, CycloneDX, OCI VEX | Native | Free |
| **Grype** | OSS (Anchore) | via Syft | Limited | CLI-based | Free |
| **Docker Scout** | Commercial | Automatic | Yes | Docker CLI native | Included in Docker plans |
| **Snyk Container** | Commercial | Yes | Yes | GitHub, GitLab, CI | Free tier + paid |

**Trivy** is the default recommendation -- fastest scans, broadest coverage, built-in SBOM generation, VEX support, and Kubernetes misconfiguration scanning. Use in CI:

```bash
trivy image --severity HIGH,CRITICAL --exit-code 1 myapp:latest
trivy image --format cyclonedx --output sbom.json myapp:latest
```

### Supply Chain Security

**Image signing with cosign** (Sigstore, CNCF graduated):

```bash
# Keyless signing (uses OIDC identity, Fulcio CA, Rekor transparency log)
cosign sign myregistry/app@sha256:abc123...

# Verify signature
cosign verify myregistry/app@sha256:abc123... \
  --certificate-identity=ci@github.com \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

**Notation** (CNCF Notary v2) is the alternative standard -- preferred by Azure/ACR ecosystems.

**SBOM generation with Syft:**

```bash
syft packages myapp:latest -o spdx-json > sbom.spdx.json
```

EU Cyber Resilience Act (September 2026) mandates SBOM generation for all software sold in the EU.

### Rootless and Read-Only Containers

```dockerfile
# Create non-root user
RUN addgroup -S app && adduser -S app -G app
USER app

# In Kubernetes pod spec
securityContext:
  runAsNonRoot: true
  runAsUser: 65534
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
  seccompProfile:
    type: RuntimeDefault
```

### Seccomp and AppArmor

**Seccomp** restricts system calls. Use `RuntimeDefault` profile (mandatory under Kubernetes Restricted policy) or generate custom profiles with tools like `oci-seccomp-bpf-hook`.

**AppArmor** restricts resource access. From Kubernetes v1.30+, configured via `securityContext` in the pod spec (no longer annotations). Azure Linux 3.0 added AppArmor support in Nov 2025.

Rule of thumb: seccomp stops privilege escalation, AppArmor stops resource access.

---

## 5. OCI Standards

### Specification Overview

| Spec | Version | Purpose |
|------|---------|---------|
| **Image Spec** | v1.1.0 (Feb 2024) | Defines layers, configs, manifests, index structure |
| **Distribution Spec** | v1.1.0 (Feb 2024) | Registry API for push/pull by digest, referrers API |
| **Runtime Spec** | v1.3.0 (Nov 2025) | How runtimes unpack and run OCI bundles |

### OCI Artifacts (v1.1 Key Feature)

OCI v1.1 added `subject` and `artifactType` fields to the image spec, enabling:

- **Signatures** -- cosign stores signatures as OCI artifacts alongside the image
- **SBOMs** -- Attach CycloneDX/SPDX documents to images via referrers
- **Helm charts** -- Stored and distributed as OCI artifacts
- **Wasm modules** -- Distributed via OCI registries
- **OPA bundles** -- Policy as OCI artifact

The **referrers API** in the distribution spec enables querying all artifacts associated with an image by digest. Tools like ORAS (`oras.land`) provide CLI support for pushing/pulling arbitrary OCI artifacts.

---

## 6. Container Runtimes

### Runtime Architecture

**High-level runtimes** (CRI implementations) manage container lifecycle:
- **containerd** -- Default in Docker and most Kubernetes distributions
- **CRI-O** -- Kubernetes-only, lightweight CRI implementation (Red Hat, SUSE)

**Low-level runtimes** (OCI implementations) create and run containers:
- **runc** -- Reference implementation, default everywhere
- **crun** -- C-based, faster startup, cgroups v2 first-mover
- **youki** -- Rust-based, lower memory usage
- **gVisor (runsc)** -- Application kernel intercepting syscalls
- **Kata Containers** -- Lightweight VM-based isolation

### Comparison Table

| Runtime | Language | Isolation | Startup Overhead | Memory Overhead | Use Case |
|---------|----------|-----------|-----------------|----------------|----------|
| **runc** | Go | namespaces/cgroups | baseline | baseline | Default for everything |
| **crun** | C | namespaces/cgroups | ~30% faster | ~50% less | Resource-constrained environments |
| **youki** | Rust | namespaces/cgroups | faster than runc | less than runc | Performance-critical, safety-focused |
| **gVisor** | Go | user-space kernel | moderate | ~20-50 MB | Multi-tenant, untrusted workloads |
| **Kata** | Go/Rust | micro-VM | 200-500ms | ~30-60 MB | Strict isolation requirements |

### containerd 2.x Timeline

| Version | Release | Key Features |
|---------|---------|-------------|
| **2.0** | Late 2024 | Stable 2.x baseline, removed Schema 1, io_uring removed from seccomp default |
| **2.1** | May 2025 | OCI Image Volumes, transfer service default in CRI, parallel HTTP range requests, writable cgroups for unprivileged containers |
| **2.2** | Late 2025 | Mount manager service, parallel layer unpacking (overlayfs, EROFS) |
| **2.3** | Apr 2026 | New 4-month release cadence (Apr/Aug/Dec) |

---

## 7. Build Tools Beyond Docker

### Comparison Table

| Tool | Daemon Required | Rootless | Dockerfile Compatible | Best For |
|------|----------------|----------|----------------------|----------|
| **Docker + BuildKit** | yes (containerd) | partial | yes | Default local development |
| **Buildah** | no | yes | yes | Rootless builds, Podman ecosystem |
| **Podman** | no | yes | yes (via Buildah) | Docker-free development, systemd integration |
| **kaniko** | no | no (runs as root in container) | yes | CI builds inside K8s without privileged access |
| **BuildKit standalone** | no (can run daemonless) | yes | yes | Advanced caching, parallel builds |
| **Earthly** | BuildKit under hood | yes | Earthfile (Dockerfile-like) | Monorepos, reproducible CI |
| **Dagger** | BuildKit under hood | yes | SDK (Go/Python/TS) | Programmable CI/CD pipelines |
| **ko** | no | yes | no (Go only) | Go services, zero-config images |
| **Jib** | no | yes | no (Java only) | Java/Gradle/Maven, no Docker needed |
| **Cloud Native Buildpacks** | no | yes | no (auto-detection) | Platform teams, standardized builds |

### When to Use Each

**kaniko** -- CI builds inside Kubernetes. Runs in unprivileged pods. Slower than BuildKit for large images due to snapshot approach, but requires no Docker daemon or privileged containers.

**Earthly** -- Monorepo builds. Earthfiles combine Dockerfile + Makefile syntax. Earthly Satellites provide remote build runners with shared cache. Parallel target execution by default.

**Dagger** -- Programmable CI/CD. Write pipelines in Go, Python, TypeScript (8 SDKs total). Every operation is containerized and cached. Dagger Cloud provides managed compute with traces/telemetry.

**ko** -- Go microservices. Single command (`ko build ./cmd/server`), produces distroless-based images with no Dockerfile. Integrates with Kubernetes manifests (`ko apply -f deploy.yaml`).

**Jib** -- Java applications. Gradle/Maven plugin, no Dockerfile, no Docker daemon. Produces layered images following best practices automatically. Fast incremental builds.

**Buildpacks** (`pack build`) -- Platform teams that want consistent image builds across languages without developers writing Dockerfiles. Auto-detects framework, applies security patches to base images independently.

---

## 8. Container Registries

### Feature Comparison

| Registry | Type | Vulnerability Scan | Lifecycle Policies | Replication | OCI Artifacts | Pricing Model |
|----------|------|-------------------|-------------------|-------------|--------------|---------------|
| **ECR** | Managed (AWS) | Basic + Enhanced (Inspector) | Yes (tag/age rules) | Cross-region, cross-account | Yes (OCI 1.1) | $0.10/GB/month + transfer |
| **Artifact Registry** | Managed (GCP) | On-demand + auto | Yes | Multi-region | Yes | $0.10/GB/month |
| **ACR** | Managed (Azure) | Defender for Cloud | Yes (retention) | Geo-replication (Premium) | Yes | Basic $0.167/day, Standard $0.667/day |
| **Docker Hub** | SaaS | Docker Scout | Inactive image cleanup | No native | Yes | Free (1 repo private), Pro $5/mo |
| **GHCR** | SaaS (GitHub) | Dependabot | Via GitHub Actions | No | Yes | Free for public, follows GitHub storage |
| **Harbor** | Self-hosted (CNCF) | Trivy, Clair | Tag retention rules | Multi-target (Hub, ECR, GAR, ACR) | Yes | Free (self-hosted) |
| **Zot** | Self-hosted | Via extensions | Built-in | Yes | Native OCI-first | Free (single binary) |

**GCR is shut down** -- As of March 18, 2025, writing images to Container Registry is unavailable. Migrate to Artifact Registry.

**Harbor** is the best self-hosted option -- RBAC per project, quota limits, Trivy/Clair scanning built in, replication to any OCI-compliant registry, OIDC authentication.

**Zot** is OCI-native -- Single static binary, no external dependencies. Built from the ground up on OCI Distribution Spec. Native support for OCI referrers (cosign signatures, SBOMs). Best for edge deployments and minimal infrastructure.

### Lifecycle Policy Example (ECR)

```json
{
  "rules": [{
    "rulePriority": 1,
    "description": "Keep last 10 tagged images",
    "selection": {
      "tagStatus": "tagged",
      "tagPrefixList": ["v"],
      "countType": "imageCountMoreThan",
      "countNumber": 10
    },
    "action": { "type": "expire" }
  }, {
    "rulePriority": 2,
    "description": "Expire untagged after 7 days",
    "selection": {
      "tagStatus": "untagged",
      "countType": "sinceImagePushed",
      "countUnit": "days",
      "countNumber": 7
    },
    "action": { "type": "expire" }
  }]
}
```

---

## 9. WebAssembly Containers

### Wasm vs Containers

Wasm is not replacing containers -- it complements them for specific workloads. Docker's position: "use together, not either/or."

| Aspect | Linux Containers | Wasm Containers |
|--------|-----------------|-----------------|
| **Cold start** | 200-500ms | Sub-1ms (native Wasm); 65-325ms (Docker+Wasm shim) |
| **Image size** | 10-500 MB | 1-10 MB |
| **Isolation** | namespace/cgroup | Wasm sandbox (capability-based) |
| **Language support** | Any | Rust, Go, C/C++, JS/TS, Python (growing) |
| **Ecosystem maturity** | Production-ready | Early production (2025-2026) |
| **Syscall access** | Full (filtered by seccomp) | WASI capabilities only |

### Key Projects

**runwasi** (Bytecode Alliance) -- Abstraction layer between containerd shims and Wasm runtimes. Supports Wasmtime, WasmEdge, Wasmer.

**Spin** (Fermyon) -- Wasm runtime for microservices and serverless. Spin v3.5 shipped WASIp3 RC support (Nov 2025) with native async I/O. **SpinKube** runs Spin apps natively on Kubernetes.

**containerd Wasm shim** -- Enables Wasm workloads managed as standard Kubernetes Pods. The `RuntimeClass` mechanism routes pods to the Wasm shim instead of runc.

### Real-World Adoption

- Fermyon demonstrated sub-0.5ms cold starts at SUSECON 2025
- American Express built internal FaaS platform on wasmCloud
- Fermyon's edge platform handles 75M requests/second
- Wasm adoption grew 28% year-over-year

---

## 10. Debugging Containers

### Tools Comparison

| Tool | Purpose | Works With Distroless | How It Works |
|------|---------|----------------------|-------------|
| **docker debug** | Attach debug shell to any container | Yes | Injects toolbox (vim, nano, networking tools) into running container |
| **kubectl debug** | Ephemeral containers in K8s pods | Yes | Adds temporary container sharing pod namespaces |
| **dive** | Analyze image layers and wasted space | N/A (offline) | TUI showing layer-by-layer diff, wasted space score |
| **nsenter** | Enter container namespaces from host | Yes | Direct namespace attachment (`nsenter -t <PID> -m -u -i -n -p`) |
| **slim.ai** | Optimize and analyze images | N/A | Profile-guided image minification |

### Ephemeral Containers (Kubernetes)

Ephemeral containers are the primary debugging mechanism for distroless/minimal production pods:

```bash
# Attach a debug container to a running pod
kubectl debug -it pod/myapp \
  --image=nicolaka/netshoot \
  --target=app-container

# Debug a node
kubectl debug node/worker-1 -it --image=ubuntu

# Copy pod and add debug container (non-destructive)
kubectl debug pod/myapp -it \
  --image=busybox \
  --copy-to=myapp-debug \
  --share-processes
```

### dive for Image Analysis

```bash
# Analyze an image interactively
dive myapp:latest

# CI mode -- fail if efficiency < 90% or wasted space > 20MB
CI=true dive myapp:latest --highestWastedBytes 20MB --lowestEfficiency 0.9
```

dive supports both Docker and Podman engines.

---

## 11. Container Patterns

### Sidecar Pattern

A helper container runs alongside the main application in the same pod, sharing network and optionally volumes.

| Use Case | Sidecar Example |
|----------|----------------|
| **Service mesh** | Envoy proxy (Istio, Linkerd) |
| **Log shipping** | Fluentd/Fluent Bit collecting from shared volume |
| **TLS termination** | nginx/Envoy handling certificates |
| **Secret refresh** | Vault agent injecting rotated secrets |

Kubernetes v1.29+ supports native sidecar containers via `initContainers` with `restartPolicy: Always`, guaranteeing startup/shutdown ordering.

### Init Container Pattern

Runs to completion before the main container starts. Use for:

- **Database migrations** -- Run schema changes before app boots
- **Config fetching** -- Download config from Vault/Parameter Store
- **Dependency checks** -- Wait for database/queue to be ready
- **Permission setup** -- Fix volume ownership (`chown`)

```yaml
initContainers:
  - name: wait-for-db
    image: busybox:1.37
    command: ['sh', '-c', 'until nc -z postgres 5432; do sleep 1; done']
  - name: run-migrations
    image: myapp:latest
    command: ['./migrate', 'up']
```

### Ambassador Pattern

A proxy container that handles outbound connections on behalf of the main container, abstracting external service access (connection pooling, retries, circuit breaking).

### Adapter Pattern

A container that transforms or normalizes the output of the main container for external consumption (log format conversion, metrics exposition, protocol translation).

---

## 12. Decision Matrices

### Choosing a Base Image

```
Need shell access for debugging?
  Yes -> Need glibc compatibility?
    Yes -> Debian slim or Chainguard (Wolfi)
    No  -> Alpine
  No  -> Statically compiled binary?
    Yes -> scratch (include CA certs if HTTPS needed)
    No  -> Distroless (match language variant)

Security is the primary concern?
  Yes -> Chainguard (zero-CVE target, auto-patched in 4 hours)
```

### Choosing a Build Tool

```
Building in Kubernetes CI?
  Yes -> kaniko (no daemon, unprivileged)

Need Docker-free environment?
  Yes -> Buildah + Podman

Go-only services?
  Yes -> ko (zero-config, distroless-based)

Java-only services?
  Yes -> Jib (no Docker, layered by default)

Monorepo with complex dependencies?
  Yes -> Earthly (Makefile + Dockerfile hybrid)

Programmable CI/CD pipelines?
  Yes -> Dagger (SDK-based, cached, containerized)

Platform team standardizing across languages?
  Yes -> Cloud Native Buildpacks

Default?
  -> Docker + BuildKit (widest ecosystem, best documentation)
```

### Choosing a Registry

```
AWS shop?          -> ECR (native IAM, lifecycle policies, cross-region replication)
GCP shop?          -> Artifact Registry (GCR is dead as of Mar 2025)
Azure shop?        -> ACR (Defender integration, geo-replication on Premium)
GitHub-native CI?  -> GHCR (free for public, tight Actions integration)
Self-hosted/hybrid -> Harbor (CNCF, RBAC, scanning, multi-target replication)
Edge/minimal?      -> Zot (single binary, OCI-native, no dependencies)
Open source project -> Docker Hub (visibility) + GHCR (CI automation)
```

### Container Security Checklist

1. **Build time**: Use minimal base images (distroless/Chainguard)
2. **Build time**: Pin image digests, not tags (`@sha256:...`)
3. **Build time**: Scan with Trivy in CI, fail on HIGH/CRITICAL
4. **Build time**: Generate SBOM (Syft or Trivy) -- EU CRA requires this by Sep 2026
5. **Build time**: Sign images with cosign (keyless via Sigstore)
6. **Runtime**: Run as non-root (`USER 65534`)
7. **Runtime**: Read-only root filesystem
8. **Runtime**: Drop all capabilities, add back only what is needed
9. **Runtime**: Set seccomp profile to RuntimeDefault
10. **Runtime**: Use Pod Security Admission (Restricted profile)
