# Content Moderation & Trust and Safety

Content moderation is the immune system of a social platform. Without it, spam, harassment, illegal content, and abuse overwhelm the user experience within weeks. This reference covers the architecture of moderation systems at every scale — from manual review queues to multi-model ML pipelines processing millions of pieces of content per day.

## Table of Contents

1. [Content Moderation Architecture Overview](#1-content-moderation-architecture-overview)
2. [Automated Moderation](#2-automated-moderation)
3. [Human Moderation Systems](#3-human-moderation-systems)
4. [Trust and Safety Infrastructure](#4-trust-and-safety-infrastructure)
5. [Spam and Bot Detection](#5-spam-and-bot-detection)
6. [Reporting Systems](#6-reporting-systems)
7. [Content Policy Enforcement](#7-content-policy-enforcement)
8. [Legal Compliance](#8-legal-compliance)
9. [Community Moderation](#9-community-moderation)
10. [Moderation at Scale: Real-World Systems](#10-moderation-at-scale-real-world-systems)

---

## 1. Content Moderation Architecture Overview

### Pre-Publish vs Post-Publish Moderation

**Pre-publish (synchronous):**
- Content is checked BEFORE it becomes visible to other users
- Adds latency to the post creation flow (50-500ms for ML models)
- Required for: CSAM detection (legal requirement), high-risk content categories
- Trade-off: Safer but slower, can frustrate users if false positive rate is high

**Post-publish (asynchronous):**
- Content is published immediately, checked in the background
- Content may be visible for seconds to minutes before being flagged/removed
- Required for: Scale — pre-publish can't handle millions of posts/hour without massive infra
- Trade-off: Faster UX but harmful content is temporarily visible

**Hybrid (recommended for most platforms):**
- Pre-publish: Hash matching for known-bad content (CSAM, known spam), basic keyword filters
- Post-publish: ML classifiers for toxicity, spam, misinformation, policy violations
- Escalation: Flagged content goes to human review queue

```
Content Submitted
       │
       ▼
┌──────────────┐     ┌──────────────┐
│ Pre-Publish  │────▶│   Publish    │
│  Checks      │     │   Content    │
│              │     └──────┬───────┘
│ - Hash match │            │
│ - Keyword    │     ┌──────▼───────┐
│ - Known spam │     │ Post-Publish │
│ - Rate limit │     │   Pipeline   │
└──────┬───────┘     │              │
       │             │ - ML classify│
   BLOCK if          │ - Toxicity   │
   matched           │ - Spam score │
                     │ - Image/video│
                     └──────┬───────┘
                            │
                     ┌──────▼───────┐
                     │   Decision   │
                     │              │
                     │ Score > thresh│
                     │   → Remove   │
                     │ Score medium │
                     │   → Queue    │
                     │ Score low    │
                     │   → Pass     │
                     └──────────────┘
```

### The Moderation Pipeline

```
┌─────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Ingest  │───▶│  Filter  │───▶│ Classify │───▶│  Decide  │───▶│  Action  │
│          │    │  Layer   │    │  Layer   │    │  Layer   │    │  Layer   │
└─────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
     │              │               │               │               │
     ▼              ▼               ▼               ▼               ▼
 Extract text   Hash matching   ML models:     Score-based     Remove/
 Extract image  Known bad URLs  - Toxicity     threshold:      Restrict/
 Extract video  Keyword lists   - Spam         - Auto-remove   Flag/
 Metadata       Regex patterns  - NSFW         - Human review  Warn/
 Rate check     Block lists     - Violence     - Pass          Notify
                                - Misinfo
```

Each layer operates independently with different latency/accuracy tradeoffs:
- **Filter layer**: <5ms, high precision, low recall (catches known-bad content)
- **Classify layer**: 50-500ms, moderate precision/recall (ML-based scoring)
- **Decide layer**: <1ms, applies business logic thresholds to scores
- **Action layer**: <10ms, executes the moderation decision

---

## 2. Automated Moderation

### Text Classification

```python
# Multi-label toxicity classifier (conceptual)
class TextModerator:
    def __init__(self):
        self.models = {
            'toxicity': load_model('toxicity_v3'),
            'spam': load_model('spam_v5'),
            'harassment': load_model('harassment_v2'),
            'hate_speech': load_model('hate_speech_v4'),
            'self_harm': load_model('self_harm_v2'),
            'misinformation': load_model('misinfo_v1'),
        }

    async def classify(self, text: str, context: dict) -> dict:
        results = {}
        for label, model in self.models.items():
            score = await model.predict(text, context)
            results[label] = {
                'score': score,
                'action': self.get_action(label, score),
            }
        return results

    def get_action(self, label: str, score: float) -> str:
        thresholds = {
            'toxicity':     {'remove': 0.95, 'review': 0.70, 'warn': 0.50},
            'spam':         {'remove': 0.90, 'review': 0.60},
            'harassment':   {'remove': 0.90, 'review': 0.65, 'warn': 0.45},
            'hate_speech':  {'remove': 0.85, 'review': 0.55},
            'self_harm':    {'remove': 0.80, 'review': 0.50, 'escalate': 0.40},
            'misinformation': {'label': 0.80, 'review': 0.60},
        }
        config = thresholds.get(label, {})
        for action, threshold in sorted(config.items(), key=lambda x: -x[1]):
            if score >= threshold:
                return action
        return 'pass'
```

**Key considerations for text classification:**
- **Context matters**: "I'll kill it!" means different things in gaming vs a threat. Include context (post type, community, reply chain) as model input.
- **Multilingual support**: Train or use multilingual models. English-only moderation fails for global platforms.
- **Adversarial evasion**: Users intentionally misspell words, use unicode substitution (h@te), leetspeak (h4t3), or zero-width characters. Normalize text before classification.
- **False positive cost**: Removing legitimate content angers users. Set thresholds conservatively for auto-removal, use human review for borderline cases.

### Image and Video Moderation

**Hash-based matching (for known-bad content):**

```python
# Perceptual hashing for near-duplicate detection
import imagehash
from PIL import Image

def compute_hashes(image_path: str) -> dict:
    img = Image.open(image_path)
    return {
        'phash': str(imagehash.phash(img)),        # Perceptual hash
        'dhash': str(imagehash.dhash(img)),        # Difference hash
        'whash': str(imagehash.whash(img)),        # Wavelet hash
    }

async def check_known_bad(hashes: dict) -> bool:
    """Check against database of known-bad image hashes."""
    for hash_type, hash_value in hashes.items():
        # Check exact match
        if await hash_db.exists(hash_type, hash_value):
            return True
        # Check near-match (Hamming distance < threshold)
        near_matches = await hash_db.find_near(hash_type, hash_value, max_distance=8)
        if near_matches:
            return True
    return False
```

**ML-based image classification:**
- **NSFW detection**: Multi-class classifiers (safe, suggestive, explicit, pornographic)
- **Violence detection**: Detect graphic violence, gore, weapons
- **CSAM detection**: Use PhotoDNA (Microsoft) or CSAI Match (Google) — industry-standard hash databases. CSAM detection is a legal requirement in most jurisdictions.
- **Text-in-image detection**: OCR + text classifier to catch policy-violating text in images

**Video moderation:**
- Sample key frames (every N seconds or at scene changes)
- Run image classifiers on key frames
- Audio transcription + text classification for speech content
- Much more computationally expensive — use sampling and prioritization

### Keyword and Pattern Matching

The simplest form of moderation — still useful as a fast first layer:

```python
class KeywordFilter:
    def __init__(self):
        self.exact_match = set()      # Exact word matches
        self.regex_patterns = []       # Regex patterns for evasion
        self.phrase_blocklist = set()   # Multi-word phrases

    def check(self, text: str) -> list[str]:
        violations = []
        normalized = self.normalize(text)

        # Exact word match
        words = set(normalized.split())
        matches = words & self.exact_match
        if matches:
            violations.extend([f"keyword:{w}" for w in matches])

        # Regex patterns (catches leetspeak, character substitution)
        for pattern in self.regex_patterns:
            if pattern.search(normalized):
                violations.append(f"pattern:{pattern.pattern}")

        return violations

    def normalize(self, text: str) -> str:
        """Normalize text to catch evasion attempts."""
        text = text.lower()
        # Remove zero-width characters
        text = text.replace('\u200b', '').replace('\u200c', '').replace('\u200d', '')
        # Normalize unicode (confusable characters)
        text = unicodedata.normalize('NFKD', text)
        # Common substitutions
        subs = {'@': 'a', '0': 'o', '1': 'i', '3': 'e', '$': 's', '!': 'i'}
        for char, replacement in subs.items():
            text = text.replace(char, replacement)
        return text
```

---

## 3. Human Moderation Systems

### Review Queue Architecture

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│  Flagged     │────▶│   Priority   │────▶│   Moderator  │
│  Content     │     │   Router     │     │   Dashboard  │
│              │     │              │     │              │
│ - ML flagged │     │ - Severity   │     │ - View item  │
│ - User report│     │ - Content    │     │ - Context    │
│ - Auto-flag  │     │   type       │     │ - Decision   │
└─────────────┘     │ - Queue load │     │ - Notes      │
                    └──────────────┘     └──────┬───────┘
                                                │
                                         ┌──────▼───────┐
                                         │   Action     │
                                         │              │
                                         │ - Remove     │
                                         │ - Keep       │
                                         │ - Escalate   │
                                         │ - Warn user  │
                                         └──────────────┘
```

### Priority Routing

Not all flagged content is equally urgent. Route by severity:

```python
def calculate_priority(item: ModerationItem) -> int:
    """Higher number = higher priority (reviewed first)."""
    priority = 0

    # Content type severity
    if item.ml_labels.get('csam', 0) > 0.5:
        return 1000  # CSAM is always highest priority (legal requirement)
    if item.ml_labels.get('self_harm', 0) > 0.5:
        priority += 100  # Self-harm is urgent (safety)
    if item.ml_labels.get('violence', 0) > 0.5:
        priority += 80
    if item.ml_labels.get('hate_speech', 0) > 0.5:
        priority += 70

    # Report volume (multiple reports = more urgent)
    priority += min(item.report_count * 10, 50)

    # Content reach (viral content is more urgent)
    if item.view_count > 10000:
        priority += 30
    elif item.view_count > 1000:
        priority += 15

    # Recency (newer content is more urgent — still spreading)
    hours_old = (now() - item.created_at).total_seconds() / 3600
    if hours_old < 1:
        priority += 20
    elif hours_old < 6:
        priority += 10

    return priority
```

### Moderator Tools

Essential features for a moderation dashboard:

1. **Content view**: The flagged content with full context (parent post, thread, community)
2. **User history**: The author's past violations, account age, posting patterns
3. **ML scores**: What the automated systems flagged and their confidence scores
4. **Similar content**: Other content from this user or matching the same pattern
5. **Quick actions**: One-click remove, keep, escalate, warn, ban
6. **Notes field**: Moderator can document their reasoning (important for appeals)
7. **Keyboard shortcuts**: Power moderators review hundreds of items per day — keyboard shortcuts are essential

### Moderator Well-being

Content moderation exposes reviewers to disturbing content. This is a real and serious concern:

- **Limit exposure time**: Max 4-6 hours of active moderation per day, mandatory breaks
- **Content blurring**: Auto-blur graphic content, moderator clicks to reveal (reduces involuntary exposure)
- **Rotation**: Rotate moderators across content categories — don't have the same person review CSAM or violence exclusively
- **Counseling access**: Provide mental health support and regular check-ins
- **Gradual ramp**: New moderators start with lower-severity content and gradually increase

---

## 4. Trust and Safety Infrastructure

### User Reputation System

Track user trustworthiness based on their behavior history:

```python
class UserTrustScore:
    """
    Trust score: 0.0 (completely untrusted) to 1.0 (highly trusted).
    New accounts start at 0.5 and move based on behavior.
    """
    def calculate(self, user: User) -> float:
        score = 0.5  # Base score

        # Positive signals
        score += min(user.account_age_days / 365, 0.1)    # Up to +0.1 for account age
        score += min(user.verified_email * 0.05, 0.05)    # +0.05 for verified email
        score += min(user.verified_phone * 0.05, 0.05)    # +0.05 for verified phone
        score += min(user.posts_not_removed / 100, 0.1)   # Up to +0.1 for clean history

        # Negative signals
        score -= user.removed_posts_count * 0.05           # -0.05 per removed post
        score -= user.warnings_count * 0.1                 # -0.1 per warning
        score -= user.temp_ban_count * 0.15                # -0.15 per temp ban
        score -= user.reports_upheld_count * 0.03          # -0.03 per upheld report

        return max(0.0, min(1.0, score))
```

**How trust scores affect the platform:**
- **Low trust (<0.3)**: Pre-publish moderation, rate limited, can't DM new users, restricted from certain features
- **Medium trust (0.3-0.7)**: Normal platform experience, post-publish moderation
- **High trust (>0.7)**: Relaxed rate limits, reports given higher weight, eligible for community moderation roles

### Progressive Enforcement

Escalating consequences for repeat violations:

```python
ENFORCEMENT_LADDER = [
    {'level': 1, 'action': 'warn',              'description': 'Content removed with warning'},
    {'level': 2, 'action': 'restrict_24h',       'description': 'Posting restricted for 24 hours'},
    {'level': 3, 'action': 'restrict_7d',        'description': 'Posting restricted for 7 days'},
    {'level': 4, 'action': 'suspend_30d',        'description': 'Account suspended for 30 days'},
    {'level': 5, 'action': 'permanent_ban',       'description': 'Account permanently banned'},
]

async def enforce(user_id: int, violation: Violation):
    # Get user's current enforcement level
    history = await get_enforcement_history(user_id)
    current_level = len([h for h in history if h.created_at > now() - timedelta(days=90)])

    # Severe violations skip the ladder
    if violation.severity == 'critical':  # CSAM, credible threats
        action = 'permanent_ban'
    else:
        step = min(current_level, len(ENFORCEMENT_LADDER) - 1)
        action = ENFORCEMENT_LADDER[step]['action']

    await execute_enforcement(user_id, action, violation)
    await notify_user(user_id, action, violation)
```

### Ban Evasion Detection

Users who are banned often create new accounts. Detecting this:

```python
EVASION_SIGNALS = {
    'device_fingerprint_match': 0.8,    # Same device as banned user
    'ip_address_match': 0.3,            # Same IP (weak — shared IPs exist)
    'ip_subnet_match': 0.1,             # Same /24 subnet
    'email_pattern_match': 0.4,         # Similar email (john1@ → john2@)
    'phone_linked': 0.7,               # Same phone number
    'behavioral_similarity': 0.5,       # Similar posting patterns
    'content_similarity': 0.4,          # Similar content to banned user
    'connection_overlap': 0.3,          # Follows same users as banned account
}

async def check_ban_evasion(new_user: User) -> float:
    """Returns probability [0, 1] that this is a ban evading user."""
    score = 0.0
    for signal, weight in EVASION_SIGNALS.items():
        if await signal_matches(new_user, signal):
            score += weight
    return min(score, 1.0)
```

---

## 5. Spam and Bot Detection

### Behavioral Signals

```python
SPAM_INDICATORS = {
    # Account signals
    'new_account': lambda u: u.account_age_days < 7,
    'no_profile_photo': lambda u: not u.has_avatar,
    'no_bio': lambda u: not u.bio,
    'suspicious_username': lambda u: re.match(r'^[a-z]+\d{4,}$', u.username),

    # Activity signals
    'high_post_rate': lambda u: u.posts_last_hour > 20,
    'high_follow_rate': lambda u: u.follows_last_hour > 50,
    'high_dm_rate': lambda u: u.dms_last_hour > 30,
    'repetitive_content': lambda u: u.unique_post_ratio_last_24h < 0.3,

    # Engagement signals
    'low_engagement': lambda u: u.avg_engagement_rate < 0.001,
    'no_replies_received': lambda u: u.replies_received_7d == 0,
    'bulk_mentions': lambda u: u.avg_mentions_per_post > 5,

    # Content signals
    'external_links_only': lambda u: u.posts_with_links_ratio > 0.8,
    'same_link_repeated': lambda u: u.unique_links_ratio < 0.5,
}
```

### Rate Limiting for Abuse Prevention

```python
# Tiered rate limits based on user trust score
RATE_LIMITS = {
    'new_user': {        # Account < 24h old
        'posts_per_hour': 5,
        'comments_per_hour': 10,
        'follows_per_hour': 10,
        'dms_per_hour': 5,
        'likes_per_hour': 30,
    },
    'low_trust': {       # Trust score < 0.3
        'posts_per_hour': 10,
        'comments_per_hour': 20,
        'follows_per_hour': 20,
        'dms_per_hour': 10,
        'likes_per_hour': 60,
    },
    'normal': {          # Trust score 0.3-0.7
        'posts_per_hour': 30,
        'comments_per_hour': 60,
        'follows_per_hour': 50,
        'dms_per_hour': 30,
        'likes_per_hour': 200,
    },
    'high_trust': {      # Trust score > 0.7
        'posts_per_hour': 60,
        'comments_per_hour': 120,
        'follows_per_hour': 100,
        'dms_per_hour': 60,
        'likes_per_hour': 500,
    },
}
```

### Bot Detection

```python
class BotDetector:
    """
    Multi-signal bot detection. No single signal is conclusive —
    combine multiple weak signals for a strong classification.
    """
    def score(self, user: User, session: Session) -> float:
        signals = []

        # Timing regularity (bots post at suspiciously regular intervals)
        posting_intervals = get_posting_intervals(user.id)
        if coefficient_of_variation(posting_intervals) < 0.1:
            signals.append(('regular_timing', 0.3))

        # Session patterns (bots don't browse, they just post)
        if session.pages_viewed < 3 and session.posts_created > 0:
            signals.append(('no_browsing', 0.2))

        # Mouse/touch behavior (available in web/mobile clients)
        if session.mouse_movement_entropy < 0.1:
            signals.append(('robotic_movement', 0.4))

        # API usage patterns
        if session.api_only and not user.is_developer:
            signals.append(('api_only', 0.3))

        # Content analysis
        if user.unique_post_ratio < 0.5:
            signals.append(('repetitive_content', 0.2))

        total = sum(weight for _, weight in signals)
        return min(total, 1.0)
```

### Coordinated Inauthentic Behavior (CIB)

Detecting networks of accounts acting in coordination:

- **Temporal correlation**: Multiple accounts posting the same content within a short window
- **Network analysis**: Accounts that all follow each other and/or the same targets
- **Content similarity**: Near-identical posts across multiple accounts (copy-paste with minor variations)
- **Behavioral clustering**: Accounts that start posting at the same time, use similar hashtags, and engage with the same content

```python
async def detect_coordination(content: str, author_id: int):
    """Flag potential coordinated activity."""
    # Check for near-duplicate content from different users in last hour
    content_hash = compute_simhash(content)
    similar_posts = await find_similar_posts(content_hash, max_distance=3, hours=1)

    if len(similar_posts) >= 3:
        unique_authors = set(p.author_id for p in similar_posts)
        if len(unique_authors) >= 3:
            await flag_coordination(
                authors=unique_authors,
                sample_posts=similar_posts[:10],
                reason="near_duplicate_content_from_multiple_accounts"
            )
```

---

## 6. Reporting Systems

### User Report Flow

```
User clicks "Report"
       │
       ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Report Form │────▶│  Deduplicate │────▶│  Priority    │
│              │     │  & Aggregate │     │  Score       │
│ - Category   │     │              │     │              │
│ - Details    │     │ - Same post? │     │ - Category   │
│ - Evidence   │     │ - Same user? │     │ - Volume     │
└──────────────┘     └──────────────┘     │ - Reporter   │
                                          │   trust      │
                                          └──────┬───────┘
                                                 │
                                          ┌──────▼───────┐
                                          │  Moderation  │
                                          │  Queue       │
                                          └──────────────┘
```

### Report Data Model

```sql
CREATE TABLE reports (
    id           BIGINT PRIMARY KEY,
    reporter_id  BIGINT NOT NULL REFERENCES users(id),
    content_type VARCHAR(20) NOT NULL,  -- 'post', 'comment', 'user', 'dm'
    content_id   BIGINT NOT NULL,
    category     VARCHAR(50) NOT NULL,  -- 'spam', 'harassment', 'hate_speech', 'violence',
                                        -- 'self_harm', 'misinformation', 'copyright', 'other'
    details      TEXT,
    status       VARCHAR(20) NOT NULL DEFAULT 'pending',  -- 'pending', 'reviewed', 'actioned', 'dismissed'
    priority     INT NOT NULL DEFAULT 0,
    assigned_to  BIGINT REFERENCES moderators(id),
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    reviewed_at  TIMESTAMP,
    reviewed_by  BIGINT REFERENCES moderators(id),
    decision     VARCHAR(20),  -- 'remove', 'keep', 'escalate', 'warn'
    notes        TEXT
);

CREATE INDEX idx_reports_status ON reports (status, priority DESC, created_at);
CREATE INDEX idx_reports_content ON reports (content_type, content_id);
```

### Report Categories

```python
REPORT_CATEGORIES = {
    'spam': {
        'label': 'Spam or misleading',
        'subcategories': ['commercial_spam', 'scam', 'misleading_content', 'fake_engagement'],
        'auto_action_threshold': 5,  # Auto-remove after 5 reports
    },
    'harassment': {
        'label': 'Harassment or bullying',
        'subcategories': ['targeted_harassment', 'threats', 'doxxing', 'sexual_harassment'],
        'auto_action_threshold': 3,
        'escalation_required': True,  # Always escalate to senior moderator
    },
    'hate_speech': {
        'label': 'Hate speech or discrimination',
        'subcategories': ['racial', 'religious', 'gender', 'sexual_orientation', 'disability'],
        'auto_action_threshold': 3,
    },
    'violence': {
        'label': 'Violence or graphic content',
        'subcategories': ['threats', 'graphic_violence', 'self_harm', 'terrorism'],
        'auto_action_threshold': 2,
        'escalation_required': True,
    },
    'csam': {
        'label': 'Child sexual abuse material',
        'auto_action': 'immediate_remove',  # Never wait for threshold
        'report_to_ncmec': True,            # Legal requirement
        'preserve_evidence': True,           # Do not delete underlying data
    },
    'copyright': {
        'label': 'Copyright or intellectual property',
        'subcategories': ['dmca', 'trademark', 'counterfeit'],
        'requires_legal_review': True,
    },
    'misinformation': {
        'label': 'False or misleading information',
        'subcategories': ['health', 'political', 'crisis', 'manipulated_media'],
        'action': 'label_not_remove',  # Typically labeled, not removed
    },
}
```

### Report Abuse Prevention

Users sometimes weaponize the reporting system to harass others (mass-reporting to trigger automated removal):

- **Reporter trust weighting**: Reports from users with good track records carry more weight
- **Report volume normalization**: A single piece of content reported 100 times by bots should not outweigh one genuine report
- **False reporter tracking**: Track users whose reports are consistently dismissed — reduce their report weight
- **Counter-reporting**: Allow reported users to appeal and flag false reports

---

## 7. Content Policy Enforcement

### Strike System

```python
class StrikeSystem:
    """
    Progressive enforcement based on violation history.
    Strikes decay over time — a user shouldn't be permanently penalized
    for a single mistake months ago.
    """
    STRIKE_DECAY_DAYS = 90  # Strikes older than 90 days don't count

    ENFORCEMENT_MAP = {
        1: {'action': 'warn', 'duration': None},
        2: {'action': 'restrict', 'duration': timedelta(hours=24)},
        3: {'action': 'restrict', 'duration': timedelta(days=7)},
        4: {'action': 'suspend', 'duration': timedelta(days=30)},
        5: {'action': 'permanent_ban', 'duration': None},
    }

    async def add_strike(self, user_id: int, violation: Violation):
        # Record the strike
        await db.execute("""
            INSERT INTO strikes (user_id, violation_type, violation_id, created_at)
            VALUES ($1, $2, $3, NOW())
        """, user_id, violation.type, violation.id)

        # Count active strikes (within decay window)
        active_strikes = await db.fetchval("""
            SELECT COUNT(*) FROM strikes
            WHERE user_id = $1 AND created_at > NOW() - INTERVAL '90 days'
        """, user_id)

        # Apply enforcement
        enforcement = self.ENFORCEMENT_MAP.get(
            min(active_strikes, max(self.ENFORCEMENT_MAP.keys()))
        )
        await self.apply_enforcement(user_id, enforcement, violation)
```

### Appeals System

```sql
CREATE TABLE appeals (
    id            BIGINT PRIMARY KEY,
    user_id       BIGINT NOT NULL REFERENCES users(id),
    enforcement_id BIGINT NOT NULL REFERENCES enforcements(id),
    reason        TEXT NOT NULL,
    status        VARCHAR(20) NOT NULL DEFAULT 'pending',  -- 'pending', 'approved', 'denied'
    reviewed_by   BIGINT REFERENCES moderators(id),
    reviewed_at   TIMESTAMP,
    reviewer_notes TEXT,
    created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);
```

**Appeal review guidelines:**
- Appeals must be reviewed by a DIFFERENT moderator than the one who made the original decision
- Provide clear reasoning for appeal decisions
- If the appeal is approved, reverse the enforcement AND remove the strike
- Track appeal overturn rates per moderator for quality assurance

### Transparency Reports

Major platforms publish regular transparency reports. Track and be able to report:

- Total content removed, broken down by category
- Percentage of content removed proactively (ML) vs reported (user)
- Average time from report to action
- Appeal volume and overturn rate
- Government requests for content removal or user data
- Strike distribution across user base

---

## 8. Legal Compliance

### CSAM (Child Sexual Abuse Material)

**This is the most critical legal requirement. Getting it wrong has criminal consequences.**

- **Detection**: Use industry-standard tools (Microsoft PhotoDNA, Google CSAI Match) for hash matching against known CSAM databases
- **Reporting**: US law (18 U.S.C. § 2258A) requires reporting to NCMEC (National Center for Missing & Exploited Children) within a specific timeframe
- **Preservation**: Preserve the content and associated metadata for law enforcement — do NOT delete the underlying data even after removing it from the platform
- **Never review directly**: Route suspected CSAM to specialized trained reviewers only. Regular moderators should never be exposed to this content.

### DMCA (Digital Millennium Copyright Act)

```python
async def handle_dmca_notice(notice: DMCANotice):
    """DMCA takedown procedure."""
    # 1. Validate the notice (required fields per 17 U.S.C. § 512)
    if not notice.is_valid():
        return DMCAResponse(status='invalid', missing_fields=notice.get_missing())

    # 2. Remove the content (must act "expeditiously")
    await remove_content(notice.content_id, reason='dmca_takedown')

    # 3. Notify the content author
    await notify_user(notice.content_author_id, {
        'type': 'dmca_takedown',
        'content_id': notice.content_id,
        'claimant': notice.claimant_name,
        'counter_notice_deadline': now() + timedelta(days=14),
    })

    # 4. Log for transparency reporting
    await log_dmca(notice)
```

### EU Digital Services Act (DSA)

Requirements for platforms operating in the EU:
- **Trusted flaggers**: Give priority to reports from qualified organizations
- **Notice-and-action**: Respond to user reports with specific timelines
- **Transparency database**: Publish moderation decisions in a public database
- **Illegal content obligations**: Expeditious removal of content that is illegal under EU member state law
- **Systemic risk assessments**: Large platforms must assess and mitigate systemic risks (annually)

### Regional Content Laws

Different jurisdictions have different requirements:
- **Germany (NetzDG)**: Remove "manifestly unlawful" content within 24 hours
- **India (IT Rules 2021)**: Appoint compliance officers, enable content tracing
- **Australia (Online Safety Act)**: Mandatory reporting of cyberbullying, CSAM
- **Brazil (Marco Civil)**: Court order required for content removal (different from US notice-and-takedown)

Build moderation systems that can apply different rules per jurisdiction — content legal in one country may be illegal in another.

---

## 9. Community Moderation

### Reddit's AutoModerator Pattern

Reddit delegates significant moderation to community moderators, with AutoModerator as a rule-based tool:

```yaml
# Example AutoModerator rules (Reddit's YAML-based config)
---
# Remove posts from new accounts
type: submission
author:
    account_age: "< 7 days"
action: remove
action_reason: "Account too new"
comment: "Your account must be at least 7 days old to post here."

---
# Flag posts with certain keywords for manual review
type: any
body (regex): ["crypto", "nft", "buy now", "limited offer"]
action: filter  # Sends to mod queue
action_reason: "Potential spam keywords"
```

**Key insights from Reddit's model:**
- Community moderators understand context better than global ML models
- AutoModerator handles volume, human moderators handle nuance
- Each community can have different rules (r/science has much stricter moderation than r/memes)
- Moderator tools matter — Reddit invested heavily in mod tools, mobile mod features, and modmail

### Twitter's Community Notes (Birdwatch)

Crowd-sourced fact-checking where users add context to tweets:

```
Rating system:
1. Users write notes providing context on potentially misleading content
2. Other raters evaluate the note's helpfulness
3. Notes are shown on tweets when raters from diverse perspectives agree
   the note is helpful (bridging-based ranking — prevents partisan pile-on)
```

**Key insights:**
- Uses a "bridging" algorithm that requires agreement across ideological lines
- Notes from users who typically disagree are weighted more heavily when they agree
- This makes it harder to game with coordinated campaigns

---

## 10. Moderation at Scale: Real-World Systems

### Scale Tiers and Approaches

| Scale | Daily Content Volume | Moderation Approach | Team Size |
|-------|---------------------|---------------------|-----------|
| Startup | <10K posts/day | Manual review + keyword filters | 1-2 moderators |
| Growth | 10K-100K posts/day | Rules + ML classifiers + manual escalation | 5-15 moderators |
| Scale | 100K-1M posts/day | ML pipeline + priority routing + human review | 30-100 moderators |
| Hyper-scale | 1M+ posts/day | Multi-model ML + trust scores + community mod + human review | 500+ moderators (often outsourced) |

### Cost of Moderation

Moderation is expensive. Rough cost estimates:

- **Manual review**: $0.01-0.05 per item reviewed (outsourced), $0.10-0.50 (in-house)
- **ML inference**: $0.0001-0.001 per item (text), $0.001-0.01 per item (image/video)
- **At hyper-scale**: A platform processing 10M posts/day with 1% flagging rate needs to review 100K items/day — at $0.03/item, that's $3K/day or ~$1M/year for human review alone

### Architecture for Scale

```
                    ┌─────────────────────────────────────────────┐
                    │              ML Moderation Pipeline          │
                    │                                             │
Content ──────────▶ │  Text     Image    Video    Audio          │
                    │  Model    Model    Model    Model          │
                    │    │        │        │        │             │
                    │    └────────┴────────┴────────┘             │
                    │                  │                           │
                    │           Score Aggregator                   │
                    │                  │                           │
                    │    ┌─────────────┼─────────────┐            │
                    │    ▼             ▼             ▼            │
                    │  Auto-Remove  Human Queue   Auto-Pass      │
                    │  (>0.95)      (0.5-0.95)    (<0.5)         │
                    └─────────────────────────────────────────────┘
                                      │
                                      ▼
                    ┌─────────────────────────────────────────────┐
                    │           Human Review Layer                 │
                    │                                             │
                    │  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐   │
                    │  │ Tier │  │ Tier │  │ Tier │  │Legal │   │
                    │  │  1   │  │  2   │  │  3   │  │Review│   │
                    │  │      │  │      │  │      │  │      │   │
                    │  │ Easy │  │Medium│  │ Hard │  │DMCA/ │   │
                    │  │ spam │  │hate/ │  │CSAM/ │  │Gov   │   │
                    │  │      │  │harass│  │threat│  │      │   │
                    │  └──────┘  └──────┘  └──────┘  └──────┘   │
                    └─────────────────────────────────────────────┘
```

### Key Metrics to Track

| Metric | Target | Why It Matters |
|--------|--------|---------------|
| Proactive detection rate | >95% | % of violating content caught by ML before user reports |
| Time to action | <1 hour for severe, <24 hours for standard | How fast harmful content is addressed |
| False positive rate | <2% | Content incorrectly removed — frustrates users |
| False negative rate | <5% | Violating content that slips through — harms users |
| Appeal overturn rate | <10% | High rate means moderation quality is poor |
| Moderator throughput | 200-500 items/day | Items reviewed per moderator per day |
| User report resolution time | <48 hours | Time from report to resolution |

---

## Design Checklist

When designing a content moderation system, verify:

- [ ] **CSAM detection**: Hash matching against industry databases (PhotoDNA/CSAI Match) — mandatory
- [ ] **Pre-publish filters**: At minimum, hash matching and basic keyword filters before content goes live
- [ ] **Post-publish ML pipeline**: Classifiers for toxicity, spam, hate speech, violence, NSFW
- [ ] **Human review queue**: Priority-routed queue with moderator tools and context
- [ ] **User reporting**: Category-based reporting with deduplication and priority scoring
- [ ] **Rate limiting**: Tiered rate limits based on account age and trust score
- [ ] **Progressive enforcement**: Strike system with escalating consequences
- [ ] **Appeals process**: Allow users to contest moderation decisions
- [ ] **Moderator well-being**: Exposure limits, content blurring, mental health support
- [ ] **Legal compliance**: CSAM reporting (NCMEC), DMCA process, regional content laws (DSA, NetzDG)
- [ ] **Transparency**: Regular transparency reports on moderation volumes and decisions
- [ ] **Audit trail**: Every moderation action logged with who, what, when, why

Always verify current legal requirements with `WebSearch` — content moderation laws evolve rapidly, especially in the EU (DSA), UK (Online Safety Act), and India (IT Rules).
