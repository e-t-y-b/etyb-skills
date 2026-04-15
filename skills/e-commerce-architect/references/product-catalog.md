# Product Catalog Architecture — Deep Reference

**Always use `WebSearch` to verify platform features, search engine capabilities, and pricing before giving advice. This reference provides architectural context; the ecosystem evolves rapidly.**

## Table of Contents
1. [Product Data Modeling](#1-product-data-modeling)
2. [Category & Taxonomy Design](#2-category--taxonomy-design)
3. [Pricing Architecture](#3-pricing-architecture)
4. [Search & Discovery](#4-search--discovery)
5. [Product Information Management (PIM)](#5-product-information-management-pim)
6. [Media & Asset Management](#6-media--asset-management)
7. [Marketplace Catalog Design](#7-marketplace-catalog-design)
8. [Performance Patterns](#8-performance-patterns)
9. [Catalog API Design](#9-catalog-api-design)
10. [Platform Comparison](#10-platform-comparison)

---

## 1. Product Data Modeling

### The Core Product Model

Every e-commerce catalog has this fundamental hierarchy:

```
Product (abstract, "Nike Air Max 90")
  ├── Variant 1 (purchasable, "Black / Size 10", SKU: NAM90-BLK-10)
  ├── Variant 2 (purchasable, "White / Size 9", SKU: NAM90-WHT-9)
  └── Variant 3 (purchasable, "Red / Size 11", SKU: NAM90-RED-11)
```

**Key principle**: A **Product** is what the customer browses. A **Variant** is what they buy. A **SKU** is what the warehouse ships. Keep these concepts distinct.

### Data Modeling Approaches

#### Approach 1: Relational with Dedicated Columns (Simple Catalogs)

Best for: <1,000 products, uniform product types, known attributes upfront.

```sql
CREATE TABLE products (
  id          BIGINT PRIMARY KEY,
  name        VARCHAR(255) NOT NULL,
  slug        VARCHAR(255) UNIQUE NOT NULL,
  description TEXT,
  brand       VARCHAR(100),
  status      VARCHAR(20) DEFAULT 'draft', -- draft, active, archived
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE product_variants (
  id          BIGINT PRIMARY KEY,
  product_id  BIGINT REFERENCES products(id),
  sku         VARCHAR(100) UNIQUE NOT NULL,
  title       VARCHAR(255),   -- "Black / Size 10"
  price       NUMERIC(12,2) NOT NULL,
  compare_at  NUMERIC(12,2),  -- original price for "on sale" display
  weight      NUMERIC(8,2),
  barcode     VARCHAR(100),   -- UPC/EAN/ISBN
  position    INTEGER DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE product_options (
  id          BIGINT PRIMARY KEY,
  product_id  BIGINT REFERENCES products(id),
  name        VARCHAR(100) NOT NULL, -- "Color", "Size"
  position    INTEGER DEFAULT 0
);

CREATE TABLE product_option_values (
  id          BIGINT PRIMARY KEY,
  option_id   BIGINT REFERENCES product_options(id),
  value       VARCHAR(100) NOT NULL, -- "Black", "10"
  position    INTEGER DEFAULT 0
);

-- Junction: which option values define each variant
CREATE TABLE variant_option_values (
  variant_id        BIGINT REFERENCES product_variants(id),
  option_value_id   BIGINT REFERENCES product_option_values(id),
  PRIMARY KEY (variant_id, option_value_id)
);
```

This is the Shopify model. It's clean and query-friendly but limited: Shopify caps at 3 option types and 2,048 variants per product.

#### Approach 2: EAV (Entity-Attribute-Value) for Dynamic Attributes

Best for: Marketplaces with diverse product types, catalogs where product categories have very different attributes.

```sql
CREATE TABLE attribute_definitions (
  id          BIGINT PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,  -- "Screen Size"
  slug        VARCHAR(100) UNIQUE,
  data_type   VARCHAR(20) NOT NULL,   -- string, integer, decimal, boolean, enum
  unit        VARCHAR(20),            -- "inches", "GB", "kg"
  filterable  BOOLEAN DEFAULT FALSE,
  searchable  BOOLEAN DEFAULT FALSE,
  position    INTEGER DEFAULT 0
);

CREATE TABLE attribute_enum_values (
  id              BIGINT PRIMARY KEY,
  attribute_id    BIGINT REFERENCES attribute_definitions(id),
  value           VARCHAR(255) NOT NULL,
  position        INTEGER DEFAULT 0
);

CREATE TABLE product_attributes (
  product_id      BIGINT REFERENCES products(id),
  attribute_id    BIGINT REFERENCES attribute_definitions(id),
  value_string    VARCHAR(500),
  value_integer   BIGINT,
  value_decimal   NUMERIC(12,4),
  value_boolean   BOOLEAN,
  value_enum_id   BIGINT REFERENCES attribute_enum_values(id),
  PRIMARY KEY (product_id, attribute_id)
);
```

**EAV tradeoffs:**
- Pro: Unlimited attributes per product, self-service attribute creation, category-specific attributes
- Con: Multi-attribute queries require self-joins or pivoting, complex reporting, hard to enforce constraints
- Mitigation: Use materialized views or search index (Elasticsearch) for filtering — don't query EAV tables directly for customer-facing browse

#### Approach 3: JSON/JSONB Columns (Hybrid)

Best for: Most modern applications. Combines relational structure for core fields with JSON flexibility for extended attributes.

```sql
CREATE TABLE products (
  id          BIGINT PRIMARY KEY,
  name        VARCHAR(255) NOT NULL,
  slug        VARCHAR(255) UNIQUE NOT NULL,
  description TEXT,
  product_type VARCHAR(100),  -- "apparel", "electronics", "digital"
  status      VARCHAR(20) DEFAULT 'draft',
  
  -- Structured core attributes
  brand       VARCHAR(100),
  
  -- Flexible extended attributes
  attributes  JSONB DEFAULT '{}',
  -- Example: {"color": "blue", "material": "cotton", "screen_size": 6.1}
  
  -- SEO and metadata
  metadata    JSONB DEFAULT '{}',
  
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- GIN index for JSONB queries
CREATE INDEX idx_products_attributes ON products USING GIN (attributes);

-- Expression indexes for common attribute queries
CREATE INDEX idx_products_brand ON products ((attributes->>'brand'));
CREATE INDEX idx_products_color ON products ((attributes->>'color'));
```

**Recommended approach**: Use relational columns for fields you query frequently (name, brand, status, price). Use JSONB for long-tail attributes that vary by product type. Push all customer-facing search/filter to a search index (Elasticsearch, Algolia, Typesense).

### Product Type Patterns

#### Configurable Products (Build-to-Order)

For products with customer-selected configurations (custom laptops, personalized jewelry, made-to-order furniture):

```sql
CREATE TABLE product_configurations (
  id              BIGINT PRIMARY KEY,
  product_id      BIGINT REFERENCES products(id),
  name            VARCHAR(100),  -- "Processor", "RAM", "Storage"
  required        BOOLEAN DEFAULT TRUE,
  position        INTEGER DEFAULT 0
);

CREATE TABLE configuration_choices (
  id                  BIGINT PRIMARY KEY,
  configuration_id    BIGINT REFERENCES product_configurations(id),
  label               VARCHAR(255),   -- "Intel i7-13700K"
  price_adjustment    NUMERIC(12,2) DEFAULT 0,  -- +$200.00
  sku_suffix          VARCHAR(20),    -- "-i7"
  position            INTEGER DEFAULT 0
);
```

#### Bundles and Kits

```sql
CREATE TABLE bundles (
  id              BIGINT PRIMARY KEY,
  product_id      BIGINT REFERENCES products(id), -- bundle is itself a product
  discount_type   VARCHAR(20),  -- 'percentage', 'fixed', 'none'
  discount_value  NUMERIC(12,2)
);

CREATE TABLE bundle_items (
  bundle_id   BIGINT REFERENCES bundles(id),
  variant_id  BIGINT REFERENCES product_variants(id),
  quantity    INTEGER NOT NULL DEFAULT 1,
  optional    BOOLEAN DEFAULT FALSE,  -- can customer remove this item?
  PRIMARY KEY (bundle_id, variant_id)
);
```

#### Digital Products

```sql
CREATE TABLE digital_assets (
  id          BIGINT PRIMARY KEY,
  variant_id  BIGINT REFERENCES product_variants(id),
  file_url    VARCHAR(500),       -- S3 signed URL generated on purchase
  file_name   VARCHAR(255),
  file_size   BIGINT,             -- bytes
  mime_type   VARCHAR(100),
  download_limit  INTEGER,        -- NULL = unlimited
  expiry_days     INTEGER         -- NULL = never expires
);
```

### How Platforms Model Products

| Platform | Product-Variant Model | Variant Limits | Attributes | Schema Approach |
|----------|----------------------|---------------|------------|-----------------|
| **Shopify** | Product → Variants (via Options) | 2,048 variants, 3 options | Metafields (key-value) | Relational + metafields |
| **Medusa** | Product → Variants (via Options) | Unlimited | Custom attributes module | Relational + JSON |
| **Saleor** | Product Type → Product → Variants | Unlimited | Attribute system (typed) | EAV-style |
| **Commercetools** | Product Type → Product → Variants | Unlimited | Product Type attributes | Schema-per-type |
| **BigCommerce** | Product → Variants (via Options) | 600 variants | Custom fields | Relational |

---

## 2. Category & Taxonomy Design

### Hierarchical Categories

Most e-commerce sites use a tree structure:

```
All Products
├── Electronics
│   ├── Phones
│   │   ├── iPhone
│   │   └── Android
│   └── Laptops
├── Clothing
│   ├── Men's
│   └── Women's
└── Home & Garden
```

### Tree Storage Strategies

#### Adjacency List (Simplest)

```sql
CREATE TABLE categories (
  id          BIGINT PRIMARY KEY,
  parent_id   BIGINT REFERENCES categories(id),
  name        VARCHAR(255),
  slug        VARCHAR(255) UNIQUE,
  position    INTEGER DEFAULT 0,
  is_active   BOOLEAN DEFAULT TRUE
);
```

- Pro: Simple inserts, moves, deletes
- Con: Recursive queries for full path/subtree (PostgreSQL supports `WITH RECURSIVE`, so this is manageable)
- Best for: Shallow trees (3-5 levels), infrequent tree traversal

#### Materialized Path

```sql
CREATE TABLE categories (
  id          BIGINT PRIMARY KEY,
  parent_id   BIGINT REFERENCES categories(id),
  name        VARCHAR(255),
  slug        VARCHAR(255) UNIQUE,
  path        VARCHAR(500),  -- "/1/5/23/" or "electronics.phones.iphone"
  depth       INTEGER,
  position    INTEGER DEFAULT 0
);

-- Find all descendants of category 5:
-- SELECT * FROM categories WHERE path LIKE '/5/%';
-- (very fast with a trigram or prefix index)
CREATE INDEX idx_categories_path ON categories USING btree (path);
```

- Pro: Fast subtree queries (single index scan), easy breadcrumb generation
- Con: Path updates cascade on category moves
- Best for: Read-heavy catalogs (which is almost all of them), deep trees

#### Nested Set (ltree)

PostgreSQL's `ltree` extension provides built-in hierarchical query operators:

```sql
CREATE EXTENSION ltree;

CREATE TABLE categories (
  id    BIGINT PRIMARY KEY,
  name  VARCHAR(255),
  path  ltree  -- 'electronics.phones.iphone'
);

CREATE INDEX idx_categories_ltree ON categories USING GIST (path);

-- All descendants of "electronics":
SELECT * FROM categories WHERE path <@ 'electronics';

-- All ancestors of "electronics.phones.iphone":
SELECT * FROM categories WHERE 'electronics.phones.iphone' <@ path;
```

**Recommended approach**: Use adjacency list + materialized path (or ltree). Adjacency list for writes (moving categories), materialized path for reads (subtree queries, breadcrumbs). Sync them via a trigger or application-level update.

### Faceted Navigation

Facets are the filter panels on category pages: "Color: Red (23), Blue (15) | Size: S (8), M (12), L (18)".

Faceted navigation should NOT be powered by SQL queries against your product tables. Use a search index:

| Search Engine | Faceting | Best For |
|--------------|---------|---------|
| **Algolia** | Built-in, automatic | Small-medium catalogs, fastest time-to-market |
| **Typesense** | Built-in, automatic | Open-source alternative to Algolia, great DX |
| **Meilisearch** | Built-in, automatic | Open-source, very easy setup, growing fast |
| **Elasticsearch** | Aggregations API | Large catalogs, complex faceting logic, full control |
| **OpenSearch** | Aggregations API | AWS-native alternative to Elasticsearch |

Pattern: Write product data to your database (source of truth), then sync to your search index via events or a change data capture pipeline. All browse/filter/search queries hit the search index, not the database.

---

## 3. Pricing Architecture

### Simple Pricing (B2C)

For most DTC brands, pricing is straightforward:

```sql
-- Price lives on the variant
CREATE TABLE product_variants (
  id              BIGINT PRIMARY KEY,
  product_id      BIGINT REFERENCES products(id),
  sku             VARCHAR(100) UNIQUE,
  price           NUMERIC(12,2) NOT NULL,     -- selling price
  compare_at_price NUMERIC(12,2),             -- "was" price (strikethrough)
  cost_price      NUMERIC(12,2),              -- cost for margin calculation
  currency        CHAR(3) DEFAULT 'USD'
);
```

### Multi-Currency Pricing

Two approaches:

**Approach 1: Auto-conversion (simpler, less accurate)**
- Store prices in one base currency
- Convert at checkout using real-time exchange rates
- Pro: One price to manage. Con: Prices look "weird" ($47.23 instead of $49.99), margins fluctuate with FX

**Approach 2: Price lists per currency (recommended for serious multi-currency)**

```sql
CREATE TABLE price_lists (
  id          BIGINT PRIMARY KEY,
  name        VARCHAR(100),     -- "USD Retail", "EUR Retail", "GBP Wholesale"
  currency    CHAR(3) NOT NULL,
  type        VARCHAR(20),      -- 'retail', 'wholesale', 'vip'
  priority    INTEGER DEFAULT 0 -- higher = takes precedence
);

CREATE TABLE prices (
  id              BIGINT PRIMARY KEY,
  price_list_id   BIGINT REFERENCES price_lists(id),
  variant_id      BIGINT REFERENCES product_variants(id),
  amount          NUMERIC(12,2) NOT NULL,
  min_quantity    INTEGER DEFAULT 1,  -- for volume pricing
  max_quantity    INTEGER,            -- NULL = no upper limit
  starts_at       TIMESTAMPTZ,       -- NULL = always active
  ends_at         TIMESTAMPTZ,       -- NULL = no expiry
  UNIQUE (price_list_id, variant_id, min_quantity)
);
```

**Price resolution order** (first match wins):
1. Customer-specific price list (VIP, contract)
2. Customer group price list (wholesale, partner)
3. Sale/promotional price list (time-bounded)
4. Currency-specific retail price list
5. Default price on the variant

### B2B Pricing Patterns

B2B pricing is fundamentally more complex than B2C:

| Feature | B2C | B2B |
|---------|-----|-----|
| Price visibility | Public | Often hidden ("request a quote") |
| Quantity discounts | Rare | Standard (tiered, volume breaks) |
| Customer-specific pricing | Unusual | Expected |
| Net terms | Never (pay now) | Common (Net 30/60/90) |
| Contract pricing | No | Yes, with validity periods |
| Minimum order quantities | No | Often required |

```sql
-- Volume/tiered pricing example
-- Buy 1-9: $50 each, 10-49: $45 each, 50+: $40 each
INSERT INTO prices (price_list_id, variant_id, amount, min_quantity, max_quantity)
VALUES
  (1, 101, 50.00, 1, 9),
  (1, 101, 45.00, 10, 49),
  (1, 101, 40.00, 50, NULL);
```

### Dynamic Pricing

For marketplaces or high-volume sellers wanting price optimization:
- Competitor price monitoring (Prisync, Competera)
- Demand-based adjustments (raise price when demand spikes)
- Time-based (happy hour, off-peak discounts)
- Inventory-based (lower price to clear slow movers)
- A/B price testing

**Warning**: Dynamic pricing requires careful UX. Customers who see different prices feel cheated. Be transparent about why prices vary (member pricing, time-limited deals, quantity breaks).

---

## 4. Search & Discovery

### Search Engine Selection

| Engine | Hosting | Price | Strengths | Best For |
|--------|---------|-------|-----------|---------|
| **Algolia** | Managed SaaS | $$$$ (from $1/1K search requests) | Fastest, best DX, InstantSearch UI widgets, AI features | Teams wanting turnkey search, budget allows |
| **Typesense** | Self-hosted or cloud | $ (open-source, cloud from $0.015/hr) | Fast, easy setup, typo tolerance, geo search | Open-source alternative to Algolia |
| **Meilisearch** | Self-hosted or cloud | $ (open-source, cloud from $0.014/hr) | Extremely easy setup, great defaults | Small-medium catalogs, developer-first teams |
| **Elasticsearch** | Self-hosted or Elastic Cloud | $$ (self-host) / $$$ (cloud) | Most powerful, full-text + analytics, vector search | Large catalogs (100K+ SKUs), complex requirements |
| **OpenSearch** | Self-hosted or AWS | $$ (AWS managed) | Fork of Elasticsearch, good AWS integration | AWS-native shops, avoiding Elastic licensing |

### Search Architecture Pattern

```
Product DB (source of truth)
       │
       ├── CDC / Event Stream ──▶ Search Index (Elasticsearch/Algolia/Typesense)
       │                                │
       │                         Customer-facing search/browse/filter
       │
       └── Admin/backoffice queries ──▶ Direct DB queries (OK for admin)
```

### Key Search Features to Implement

1. **Typo tolerance**: "iphoen" → "iphone" (all modern search engines handle this)
2. **Synonyms**: "couch" = "sofa", "sneakers" = "trainers"
3. **Faceted filtering**: Color, size, price range, brand, ratings
4. **Autocomplete/Suggest**: As-you-type suggestions with product thumbnails
5. **Boosting and ranking**: Boost by popularity, margin, stock level, newness
6. **Personalization**: Re-rank results based on user history and preferences

### Vector Search for Semantic Discovery

Modern search engines now support vector search alongside traditional keyword search. Use cases:
- "Show me something like this" (visual similarity)
- "Comfortable shoes for standing all day" (intent-based search)
- "Gifts for a 10-year-old who likes science" (natural language queries)

Implementation: Generate embeddings for product titles + descriptions using an embedding model (OpenAI `text-embedding-3-small`, Cohere `embed-english-v3.0`), store in your search engine (Elasticsearch kNN, Typesense vector search, Pinecone), and do hybrid keyword + vector retrieval.

### Recommendation Engine Patterns

| Pattern | Complexity | Data Needed | Examples |
|---------|-----------|------------|---------|
| **"Frequently bought together"** | Low | Order history | Amazon's "Customers also bought" |
| **"Similar products"** | Low-Medium | Product attributes | Same category, similar price/features |
| **Collaborative filtering** | Medium | User behavior (views, purchases) | "People who bought X also bought Y" |
| **Content-based** | Medium | Product embeddings | Vector similarity on product features |
| **Personalized ranking** | High | User profiles + behavior | Re-rank search/browse by individual preferences |

Start with "frequently bought together" (simple co-occurrence in orders) and "similar products" (attribute matching). Add collaborative filtering only when you have enough data (>10K orders).

---

## 5. Product Information Management (PIM)

### When to Introduce a PIM

You need a PIM when:
- Product data comes from multiple sources (suppliers, manufacturers, internal teams)
- You sell on multiple channels (website, Amazon, eBay, retail POS) and need consistent data
- You have >5,000 SKUs with rich attribute data
- Multiple teams edit product data and need workflows/approvals
- Product data quality is a problem (missing images, inconsistent descriptions, wrong specs)
- You need multi-language product content

You do NOT need a PIM when:
- You have <1,000 products managed by one person
- Your commerce platform's built-in catalog tools are sufficient
- You sell on a single channel

### PIM Options

| PIM | Type | Best For | Price |
|-----|------|---------|-------|
| **Akeneo** | Open-source + Enterprise | Mid-large businesses, strong community, good integrations | Free (CE) / $$$ (Enterprise) |
| **Pimcore** | Open-source + Enterprise | Enterprises wanting PIM + DAM + CMS in one platform | Free (CE) / $$$$ (Enterprise) |
| **Salsify** | SaaS | Enterprise, strong in retail/CPG, shelf analytics | $$$$ |
| **inRiver** | SaaS | Manufacturing, complex product relationships | $$$$ |
| **Plytix** | SaaS | Small-medium businesses, affordable entry point | $$ |

### PIM Integration Pattern

```
Supplier Feeds ──┐
Internal Teams ──┤
Manufacturer    ──┤──▶ PIM (Akeneo) ──▶ Commerce Platform (Shopify/Medusa)
  Data Sheets    ──┘        │                    │
                            ├──▶ Marketplace (Amazon) API
                            ├──▶ Print catalog export
                            └──▶ POS system sync
```

---

## 6. Media & Asset Management

### Image Optimization Pipeline

Product images are often the largest page weight on e-commerce sites. A proper pipeline:

```
Original Upload (5MB JPEG)
       │
       ▼
  Image Processing Service (Cloudinary / imgix / Cloudflare Images)
       │
       ├── Thumbnail: 200x200, WebP, quality 80, 15KB
       ├── Card: 400x400, WebP, quality 85, 40KB
       ├── Detail: 800x800, WebP, quality 90, 80KB
       ├── Zoom: 1600x1600, WebP, quality 92, 200KB
       └── OG Image: 1200x630, JPEG, quality 85
       │
       ▼
  CDN (Cloudflare, CloudFront, Fastly)
       │
       ▼
  Browser (responsive <picture> element with srcset)
```

### Image Service Comparison

| Service | Model | Transforms | CDN | Best For |
|---------|-------|-----------|-----|---------|
| **Cloudinary** | Usage-based | URL-based, extensive | Built-in | Rich transformations, AI features (background removal) |
| **imgix** | Usage-based | URL-based | Built-in | Performance-focused, real-time rendering |
| **Cloudflare Images** | Flat per-image | Variants | Cloudflare CDN | Cost-effective at scale, integrated with Cloudflare |
| **Bunny Optimizer** | Bandwidth-based | On-the-fly | Bunny CDN | Cheapest option, good enough for most |
| **Self-hosted (Sharp/libvips)** | Infra cost | Custom pipeline | Your CDN | Full control, no per-image fees |

### Frontend Implementation

```html
<picture>
  <source srcset="product-400.avif 400w, product-800.avif 800w" type="image/avif">
  <source srcset="product-400.webp 400w, product-800.webp 800w" type="image/webp">
  <img src="product-800.jpg" alt="Nike Air Max 90 Black"
       loading="lazy" decoding="async"
       width="800" height="800"
       sizes="(max-width: 768px) 100vw, 50vw">
</picture>
```

### 3D / AR Product Visualization

Growing trend, especially in furniture, fashion, and eyewear:
- **Google Model Viewer**: Web component for 3D/AR, uses `<model-viewer>` tag
- **Shopify AR**: Built-in for Shopify stores (upload .glb files)
- **Apple Quick Look**: AR on iOS via USDZ files
- **8thWall / Niantic Studio**: Custom WebAR experiences

Cost-effective starting point: 3D product photography with turntable rigs (Orbitvu, Shutter Stream), generate 360-degree spin images without full 3D modeling.

---

## 7. Marketplace Catalog Design

### Multi-Vendor Catalog Architecture

In a marketplace, multiple sellers can list products. Key challenges:
- Product deduplication (multiple sellers selling the same product)
- Consistent product data quality across sellers
- Buy Box logic (which seller's offer is shown by default)

```sql
-- Global product catalog (marketplace-managed)
CREATE TABLE catalog_products (
  id          BIGINT PRIMARY KEY,
  name        VARCHAR(255),
  brand       VARCHAR(100),
  category_id BIGINT REFERENCES categories(id),
  gtin        VARCHAR(14),  -- Global Trade Item Number (UPC/EAN)
  attributes  JSONB
);

-- Seller-specific offerings (one product, many sellers)
CREATE TABLE seller_listings (
  id              BIGINT PRIMARY KEY,
  product_id      BIGINT REFERENCES catalog_products(id),
  seller_id       BIGINT REFERENCES sellers(id),
  price           NUMERIC(12,2) NOT NULL,
  quantity        INTEGER NOT NULL DEFAULT 0,
  condition       VARCHAR(20) DEFAULT 'new',  -- new, refurbished, used
  shipping_time   INTEGER,    -- days to ship
  fulfillment     VARCHAR(20), -- 'seller', 'marketplace' (like FBA)
  is_buybox       BOOLEAN DEFAULT FALSE,
  UNIQUE (product_id, seller_id)
);
```

### Product Matching / Deduplication

When a new seller lists "Apple iPhone 15 128GB Black", match it to the existing catalog entry:
1. **GTIN/UPC matching**: Exact match on barcode — most reliable
2. **Fuzzy title matching**: Elasticsearch more_like_this query or embedding similarity
3. **Attribute matching**: Brand + key specs (storage, color, model) combination
4. **Manual review**: Queue ambiguous matches for admin review

### Buy Box Algorithm

Factors typically considered (Amazon-inspired):
1. Price (including shipping)
2. Seller rating / metrics
3. Fulfillment method (marketplace-fulfilled preferred)
4. Shipping speed
5. Stock availability
6. Return policy

---

## 8. Performance Patterns

### Catalog Caching Strategy

```
┌─────────────────────────────────────────────────────┐
│ Layer 1: CDN / Edge Cache                            │
│ - Product pages (SSG or ISR with 60s revalidation)  │
│ - Category pages (ISR with 5-min revalidation)      │
│ - Image/media assets (long-lived, immutable URLs)   │
├─────────────────────────────────────────────────────┤
│ Layer 2: Application Cache (Redis)                   │
│ - Product objects (TTL: 5 min)                       │
│ - Category trees (TTL: 15 min)                       │
│ - Price lists (TTL: 1 min or event-invalidated)     │
│ - Search facet counts (TTL: 5 min)                   │
├─────────────────────────────────────────────────────┤
│ Layer 3: Search Index (Elasticsearch/Algolia)        │
│ - Denormalized product documents                     │
│ - All browse/filter/search queries hit here          │
├─────────────────────────────────────────────────────┤
│ Layer 4: Database (PostgreSQL)                       │
│ - Source of truth for writes                         │
│ - Admin/backoffice reads                             │
│ - Connection pool (PgBouncer)                        │
└─────────────────────────────────────────────────────┘
```

### Denormalization for Read Performance

For customer-facing pages, create denormalized read models:

```sql
CREATE MATERIALIZED VIEW product_cards AS
SELECT
  p.id, p.name, p.slug, p.brand,
  pv.sku, pv.price, pv.compare_at_price,
  pi.url AS primary_image_url,
  c.name AS category_name, c.slug AS category_slug,
  inv.quantity AS stock_count,
  COALESCE(r.avg_rating, 0) AS avg_rating,
  COALESCE(r.review_count, 0) AS review_count
FROM products p
JOIN product_variants pv ON pv.product_id = p.id AND pv.position = 0
LEFT JOIN product_images pi ON pi.product_id = p.id AND pi.position = 0
LEFT JOIN categories c ON c.id = p.category_id
LEFT JOIN inventory inv ON inv.variant_id = pv.id
LEFT JOIN (
  SELECT product_id, AVG(rating) AS avg_rating, COUNT(*) AS review_count
  FROM reviews WHERE status = 'approved' GROUP BY product_id
) r ON r.product_id = p.id
WHERE p.status = 'active';

-- Refresh periodically (or via trigger)
REFRESH MATERIALIZED VIEW CONCURRENTLY product_cards;
```

### Event-Driven Catalog Updates

Instead of refreshing materialized views on a timer, use events:

```
Product Updated (DB write)
       │
       ▼
  Event Bus (Kafka / NATS / Redis Streams)
       │
       ├──▶ Update search index
       ├──▶ Invalidate CDN cache for product URL
       ├──▶ Invalidate Redis cache
       └──▶ Update materialized views (async)
```

---

## 9. Catalog API Design

### REST vs GraphQL for Catalogs

| Factor | REST | GraphQL |
|--------|------|---------|
| Simplicity | Simpler to build and cache | More complex server, better client DX |
| Over-fetching | Returns fixed shape (may over-fetch) | Client requests exactly what it needs |
| Caching | HTTP caching works natively (CDN, browser) | Requires custom caching (Apollo, urql) |
| N+1 queries | Multiple roundtrips for related data | Single query for nested data |
| Best for | Public APIs, simple catalogs | Complex storefronts, mobile apps, varied clients |

**Recommendation**: For headless storefronts, GraphQL wins — product pages need data from many entities (product, variants, images, reviews, inventory, related products) and GraphQL avoids N+1 roundtrips. For public API/partner integrations, REST is simpler. Many platforms (Shopify, Saleor) offer both.

### Pagination for Large Catalogs

**Offset-based** (`?page=3&limit=20`): Simple but slow for large offsets (PostgreSQL scans and discards rows). Fine for <100K products.

**Cursor-based** (`?after=eyJpZCI6MTIzfQ&limit=20`): Encode the last item's sort key as an opaque cursor. Consistent performance regardless of depth. Required for infinite scroll. Shopify Storefront API uses this exclusively.

```graphql
# Shopify-style cursor pagination
query {
  products(first: 20, after: "cursor_xyz") {
    edges {
      cursor
      node { id title handle priceRange { ... } }
    }
    pageInfo { hasNextPage endCursor }
  }
}
```

---

## 10. Platform Comparison

### Headless Commerce Platforms (2025-2026)

| Platform | Language | DB | API | Open Source | Best For |
|----------|---------|------|-----|------------|---------|
| **Medusa** | TypeScript/Node | PostgreSQL | REST + JS SDK | Yes (MIT) | Custom DTC, flexibility, developer-first |
| **Saleor** | Python/Django | PostgreSQL | GraphQL | Yes (BSD) | Teams wanting GraphQL-first, strong typing |
| **Commercetools** | SaaS | Managed | REST + GraphQL | No | Enterprise, massive catalogs, multi-brand |
| **Elasticpath** | SaaS | Managed | REST | No | Enterprise, composable commerce |
| **Vendure** | TypeScript/Node | PostgreSQL/MySQL | GraphQL | Yes (MIT) | Plugin architecture, customizable |
| **Shopify Hydrogen** | TypeScript/React | Shopify | Storefront API (GraphQL) | Partially | Shopify merchants wanting custom storefront |

### Build vs Buy Decision Framework

| Factor | Use a Platform | Build Custom |
|--------|---------------|-------------|
| Time to market | Need to launch in weeks | Can invest months |
| Product complexity | Standard products | Highly custom (configurable, BTO) |
| Checkout | Standard checkout is fine | Need radical checkout customization |
| Multi-tenant | No | Marketplace with complex commission logic |
| Team size | <5 engineers | 10+ engineers |
| Budget | Limited | Can invest significantly |
| Compliance | Platform handles PCI | Have security team for PCI SAQ D |
| Scale | <$100M GMV | Any scale (but platform scales too) |
