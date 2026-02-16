# MyFamilyTree — Indian Family Tree App

> **Status**: Idea / Pre-MVP
> **Last updated**: February 15, 2026

---

## Problem Statement

In India, family networks are central to life — marriages, business referrals, and social support all flow through extended family and community connections. Yet these networks exist only in the memories of elders and scattered WhatsApp groups. There is no structured, digital way to:

- Visualize your extended family across generations
- Discover who in your network is available for marriage
- Find professionals (doctors, lawyers, solar installers) within your trusted circle
- Preserve family history, photos, and milestones

---

## Solution

**MyFamilyTree** is a cross-platform app (Android, iOS, Web) where users can:

1. **Build their family tree** — Add family members with details like name, photo, birthday, wedding anniversary, occupation, age, community, and mobile number.
2. **Merge trees** — When two users share a common relative, they can merge their trees to form a larger connected family graph.
3. **Discover connections** — Search within N circles (hops) of their family network for people, occupations, or matchmaking.

---

## Core Use Cases

### A. Matchmaking within trusted circles
Indian arranged marriages prefer matches within known circles. A user can search for unmarried individuals within 3–5 relationship hops — people connected through real family links, not strangers on a matrimony site. This provides:
- **Trust**: Every connection is traceable through known relatives
- **Context**: You can see the family background, not just a profile
- **Warm introductions**: Reach out through the connecting relatives

### B. Professional / business search
"Who in my close circle runs a solar business?" Users can search by occupation within their network, enabling trusted referrals and business within the community.

### C. Family memory preservation
Birthdays, anniversaries, photos, and milestones — a living family archive that automatically reminds you of important dates.

---

## Virality Mechanism

The app has a **built-in viral loop**:

1. User A signs up and adds 10–20 family members (with phone numbers)
2. Added relatives receive an **SMS/WhatsApp notification**: _"Ramesh added you to the Kumar family tree. Claim your profile and add your side of the family."_
3. Relative B signs up, adds their own family members
4. Those relatives get notified → cycle continues
5. Trees merge as overlapping members are identified

Each user who joins brings in 5–15 new potential users. **The product is the distribution channel.**

---

## Target Audience

- **Primary**: Indian families (25–50 age group, smartphone users)
- **Initial wedge**: Specific communities (e.g., one caste/region at a time for dense network effects)
- **Geography**: India-first, Indian diaspora second

---

## Technical Architecture

### Stack

| Layer              | Technology                                          | Free Tier                              |
|--------------------|------------------------------------------------------|----------------------------------------|
| Frontend           | Flutter (single codebase: Android, iOS, Web)         | Open source                            |
| Backend            | Node.js + Express                                    | Open source                            |
| Primary Database   | PostgreSQL (via Supabase)                            | Supabase Free: 500 MB, unlimited API   |
| Auth               | Phone OTP (Supabase Auth)                            | Supabase Free: 50k MAUs                |
| File Storage       | Supabase Storage                                     | Supabase Free: 1 GB                    |
| Notifications      | Firebase Cloud Messaging (push) + free WhatsApp (later) | FCM is free                         |
| Graph Queries      | PostgreSQL recursive CTEs (Neo4j later if needed)    | Included in Supabase                   |
| Hosting (backend)  | Render / Railway (free tier)                         | Render Free: 750 hrs/mo, Railway: $5 credit/mo |
| CI/CD              | GitHub Actions                                       | Free for public repos                  |

> **Cost at prototype stage: $0/month.** All services used are within free tiers. No AWS needed until scale.

### Why PostgreSQL over Neo4j?

Family trees are **shallow, sparse graphs** (max ~15 generations, each node has limited edges). PostgreSQL recursive CTEs handle "find people within N hops" efficiently at this scale. Neo4j is overkill initially and expensive to host.

Neo4j can be added later as a **read-optimized secondary store** if graph query complexity or data volume demands it (10M+ edges).

### Data Model

```
persons
├── id (UUID, PK)
├── name
├── date_of_birth
├── gender
├── photo_url
├── occupation
├── community
├── phone (unique, used for identity matching)
├── marital_status (single, married, divorced, widowed)
├── wedding_date
├── created_by_user_id (FK → users)
├── verified (boolean — has this person claimed their profile?)
├── created_at, updated_at

relationships
├── id (UUID, PK)
├── person_id (FK → persons)
├── related_person_id (FK → persons)
├── type (PARENT_OF, SPOUSE_OF, SIBLING_OF)
├── created_at

merge_requests
├── id (UUID, PK)
├── requester_user_id
├── target_person_id (existing in DB)
├── matched_person_id (in requester's tree)
├── status (PENDING, APPROVED, REJECTED)
├── field_conflicts (JSONB)
├── created_at
```

### N-Circle Query (PostgreSQL)

```sql
WITH RECURSIVE circle AS (
  SELECT person_id, related_person_id, 1 AS depth
  FROM relationships
  WHERE person_id = :user_id

  UNION ALL

  SELECT r.person_id, r.related_person_id, c.depth + 1
  FROM relationships r
  JOIN circle c ON r.person_id = c.related_person_id
  WHERE c.depth < :max_circles
)
SELECT DISTINCT p.*
FROM persons p
JOIN circle c ON p.id = c.related_person_id
WHERE p.marital_status = 'single';
```

---

## Tree Merging Workflow

1. **User A** and **User B** both have separate trees
2. System detects a potential overlap (same phone number, or fuzzy match on name + DOB)
3. A **merge request** is created showing the matched person and any field conflicts
4. The tree owner (or the matched person, if verified) approves/rejects the merge
5. On approval, a relationship edge links the two trees — they become one connected graph

### Merge challenges (solved in application logic, not DB):
- **Identity resolution**: Fuzzy matching on name + DOB + phone
- **Conflict resolution**: UI lets users pick correct values when data differs
- **Privacy**: Users control who can see their sub-tree

---

## Monetization (Future)

| Model | Details |
|-------|---------|
| **Freemium** | Free for basic tree + search. Premium for advanced matchmaking, unlimited tree size, export |
| **Matchmaking premium** | Pay to unlock detailed profiles / contact info for marriage prospects |
| **Community features** | Event planning, group announcements for family/community |
| **Business directory** | Promoted listings for professionals within the network |
| **API / partnerships** | Matrimony sites, insurance (family health history), genealogy services |

> **Principle**: Don't monetize until strong network effects are established. Premature paywalls kill virality.

---

## Competitive Landscape

| Competitor | What they do | Our differentiation |
|------------|-------------|---------------------|
| Shaadi.com / BharatMatrimony | Matrimony (stranger matching) | We match through **real family connections**, not algorithms |
| MyHeritage / FamilySearch | Western family tree apps | Not India-focused, no matchmaking, no community features |
| WhatsApp groups | Informal family coordination | Unstructured, no tree visualization, no search |

---

## Go-to-Market Strategy

1. **Phase 1**: Launch in ONE community (e.g., one caste/region in one city) via WhatsApp-first onboarding
2. **Phase 2**: Expand to adjacent communities in the same region
3. **Phase 3**: Pan-India expansion, community by community
4. **Phase 4**: Indian diaspora (US, UK, UAE, Canada)

**Key metric**: Trees merged per week (indicates network growth)

---

## Risks

| Risk | Mitigation |
|------|-----------|
| **Data privacy / leaks** | End-to-end encryption for sensitive fields, granular visibility controls, SOC2 compliance |
| **Data entry friction** | WhatsApp bot onboarding, voice input, smart suggestions, minimal required fields |
| **Low engagement after tree creation** | Birthday/anniversary reminders, matchmaking alerts, occupation search |
| **Community resistance** | Partner with community leaders, temple/mosque/gurudwara networks |
| **Regulatory (data protection)** | Comply with India's DPDP Act 2023, explicit consent for each person added |

---

## Next Steps

- [ ] Validate idea: Create a WhatsApp bot / Google Form MVP for one community
- [ ] Design Flutter app wireframes
- [ ] Set up Supabase project (DB + Auth + Storage) — free tier
- [ ] Set up Node.js + Express backend, deploy on Render (free tier)
- [ ] Build MVP: tree creation + invite flow + basic search
- [ ] Beta launch with 50 families in one community
