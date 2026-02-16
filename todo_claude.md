# MyFamilyTree - Code Review & Improvement Tracker

## Status Legend
- [ ] Not started
- [~] In progress
- [x] Completed

---

## Critical Issues

- [x] **C1: Fix Auth Bypass** — `backend/src/middleware/auth.ts` + `backend/src/config/env.ts`
  - Replaced hardcoded auth bypass with env-controlled `AUTH_BYPASS` flag
  - JWT validation enabled by default; bypass only works in non-production
  - Added startup warning when bypass is active

- [x] **C2: Fix RLS Bypass** — Added ownership checks to route handlers
  - `persons.ts` GET/PUT/DELETE all verify `created_by_user_id` or `auth_user_id`
  - Pattern replicable across other routes

- [x] **C3: Fix Rate Limiter** — `backend/src/index.ts`
  - Per-route rate limiters: reads (300/15min), writes (50/15min), search (30/15min), admin (200/15min)

---

## Improvement Tasks

- [x] **1a: Add Pagination to List Endpoints**
  - `relationships.ts` GET /:personId — Supabase `.range()` + `{ count: 'exact' }`
  - `search.ts` GET / — page/pageSize query params, in-memory pagination after enrichment
  - `merge.ts` GET /pending — in-memory pagination of merge requests
  - All use `paginatedResponse()` helper from `utils/response.ts`

- [x] **1b: Add Structured Logging**
  - Created `backend/src/config/logger.ts` — JSON output in production, pretty-print in dev
  - Request ID tracking via `requestLogger` middleware
  - Child logger support for scoped logging
  - Updated `errorHandler.ts` and `index.ts` to use logger

- [x] **2: Fix Inverse Relationship Gender Bug**
  - Created `supabase/migrations/010_fix_inverse_relationship.sql`
  - Added `PARENT_OF` to `relationship_type` enum
  - Updated trigger: uses `PARENT_OF` when gender is 'other' or unknown
  - Updated `models/types.ts` with `PARENT_OF` in TypeScript types

- [x] **3: Add XSS Sanitization**
  - Created `backend/src/utils/sanitize.ts` — strips HTML tags, JS protocols, event handlers
  - `sanitizeObject()` applied to person text fields in POST/PUT routes
  - Fields sanitized: name, occupation, community, city, state, email

- [x] **4: Add DELETE Endpoint for Persons**
  - `DELETE /api/persons/:id` in `persons.ts`
  - Ownership verification: `created_by_user_id` or `auth_user_id` must match
  - Relationships auto-cascade via `ON DELETE CASCADE`

- [x] **5: Fix N+1 Query (Batch Load)**
  - Rewrote `graphService.ts` `getFullTreeFallback()`:
    - Batch-loads persons + relationships per hop (2 queries/hop vs 2 queries/person)
    - Typical tree: 4-8 queries total instead of 200+
  - Rewrote `searchInCircles()`:
    - Same batch-loading approach with depth tracking
    - Results sorted by depth (closest connections first)

- [x] **6: Standardize API Response Format**
  - Created `backend/src/utils/response.ts` with helpers:
    - `successResponse(data)` → `{ success: true, data }`
    - `errorResponse(code, message, details?)` → `{ success: false, error: { code, message } }`
    - `paginatedResponse(data, page, pageSize, total)` → includes pagination metadata
  - Updated ALL route files: persons, relationships, search, tree, merge, invite
  - Updated `errorHandler.ts` middleware

---

## Files Created/Modified

| File | Status | Changes |
|---|---|---|
| `backend/src/middleware/auth.ts` | Modified | Env-based auth bypass |
| `backend/src/config/env.ts` | Modified | Added AUTH_BYPASS flags |
| `backend/src/config/logger.ts` | **Created** | Structured logging utility |
| `backend/src/utils/response.ts` | **Created** | Standardized API response helpers |
| `backend/src/utils/sanitize.ts` | **Created** | XSS sanitization utility |
| `backend/src/index.ts` | Modified | Per-route rate limiting, request logging |
| `backend/src/middleware/errorHandler.ts` | Modified | Logger + response helpers |
| `backend/src/routes/persons.ts` | Modified | XSS, DELETE, standardized responses |
| `backend/src/routes/relationships.ts` | Modified | Pagination, standardized responses |
| `backend/src/routes/search.ts` | Modified | Pagination, standardized responses |
| `backend/src/routes/tree.ts` | Modified | Standardized responses |
| `backend/src/routes/merge.ts` | Modified | Pagination, standardized responses |
| `backend/src/routes/invite.ts` | Modified | Standardized responses |
| `backend/src/services/graphService.ts` | Modified | Batch-load N+1 fix |
| `backend/src/models/types.ts` | Modified | Added PARENT_OF enum value |
| `supabase/migrations/010_fix_inverse_relationship.sql` | **Created** | Gender bug fix migration |

---

## Future Improvements (Not in Current Sprint)

- [ ] Add Playwright E2E tests
- [ ] Add Docker Compose for local dev
- [ ] Add CI/CD (GitHub Actions)
- [ ] Add OpenAPI/Swagger API docs
- [ ] Add Flutter widget & integration tests
- [ ] Add offline caching in Flutter
- [ ] Add database connection pooling
- [ ] Fix `as any` type casts in admin routes
- [ ] Fix CORS to allow multiple origins
- [ ] Fix stubbed `currentPersonProvider` in Flutter
- [ ] Install test dependencies (@types/jest, supertest) to fix test compilation
