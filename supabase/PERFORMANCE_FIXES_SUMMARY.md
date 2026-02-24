# Database Performance Optimization Summary

**Date**: February 25, 2026  
**Migration**: `020_comprehensive_performance_fixes.sql`  
**Status**: ✅ Ready to Apply

---

## 🎯 Issues Addressed

Based on Supabase Database Linter report, this migration fixes **all critical performance issues**:

### 1. ✅ Auth RLS Initialization Plan (14 Policies - WARN)

**Problem**: `auth.uid()` and `auth.<function>()` calls in RLS policies were being re-evaluated for each row, causing suboptimal performance at scale.

**Solution**: Wrap all `auth.uid()` calls in `(select auth.uid())` to evaluate once per query.

**Fixed Policies**:
- `forum_posts`: 3 policies (create, update, delete)
- `forum_comments`: 3 policies (create, update, delete)
- `forum_likes`: 2 policies (like, unlike)
- `person_documents`: 2 policies (upload, delete)
- `notifications`: 3 policies (select, update, delete)
- `family_events`: 3 policies (create, update, delete)

**Before**:
```sql
CREATE POLICY "Users can like" 
  ON forum_likes FOR INSERT 
  WITH CHECK (user_id = auth.uid());  -- ❌ Evaluated per row
```

**After**:
```sql
CREATE POLICY "Users can like" 
  ON forum_likes FOR INSERT 
  WITH CHECK (user_id = (select auth.uid()));  -- ✅ Evaluated once
```

---

### 2. ✅ Multiple Permissive Policies (12 Warnings - WARN)

**Problem**: Multiple permissive policies for the same role + action are suboptimal. Each policy must be executed for every query.

**Solution**: Consolidate multiple policies into single policies with OR conditions.

**Fixed Tables**:

#### `merge_requests` (4 warnings)
- **Before**: 2 separate SELECT policies
  - "Users can read own merge requests"
  - "Users can read targeted merge requests"
- **After**: 1 combined SELECT policy
  - "Users can read merge requests"

#### `persons` (8 warnings)
- **Before**: 3 separate SELECT policies + 2 separate UPDATE policies
  - "Users can read own created persons"
  - "Users can read own profile"
  - "Users can read connected persons"
  - "Users can update own created persons"
  - "Users can update own profile"
- **After**: 1 combined SELECT + 1 combined UPDATE
  - "Users can read accessible persons"
  - "Users can update accessible persons"

---

### 3. ✅ Unindexed Foreign Keys (10 Missing - INFO)

**Problem**: Foreign key constraints without covering indexes lead to slow JOIN operations and constraint checks.

**Solution**: Add indexes for all foreign key columns.

**Indexes Added**:
```sql
idx_forum_comments_author_user_id
idx_forum_likes_comment_id (partial)
idx_forum_likes_post_id (partial)
idx_invite_tokens_invited_by_user_id
idx_invite_tokens_used_by_user_id (partial)
idx_life_events_created_by_user_id
idx_merge_requests_matched_person_id
idx_merge_requests_resolved_by_user_id (partial)
idx_person_documents_uploaded_by_user_id
idx_relationships_created_by_user_id
```

**Note**: Partial indexes used for nullable foreign keys to save space.

---

### 4. ✅ Unused Index Cleanup (18 Removed - INFO)

**Problem**: Unused indexes consume disk space and slow down writes.

**Solution**: Remove truly unused indexes while keeping strategic ones.

**Removed Indexes** (18 total):
- **Astrology**: `idx_persons_nakshatra`, `idx_persons_rashi` (low priority features)
- **Location**: `idx_persons_native_place`, `idx_persons_city_state` (can recreate if needed)
- **Metadata**: `idx_user_metadata_created_at`, `idx_user_metadata_active`
- **Relationships**: `idx_rel_type` (enum, rarely queried)
- **Error Logs**: 6 indexes (timestamp, user_id, error_type, severity, status_code, unresolved)
- **Audit Logs**: 5 indexes (timestamp, admin_user, action_type, resource, admin_view)
- **Composite**: `idx_persons_created_by_created_at` (redundant)

**Kept Strategic Indexes** (22 total):
These are unused now but important for upcoming features:
- Name search: `idx_persons_surname`
- User queries: `idx_persons_created_by`
- Filtering: `idx_persons_community`, `idx_persons_occupation`, `idx_persons_marital_status`, `idx_persons_is_alive`
- Relationships: `idx_rel_person`
- Forum: `idx_forum_posts_author`, `idx_forum_posts_pinned`, `idx_forum_comments_post`, `idx_forum_comments_parent`
- Documents: `idx_person_documents_type`
- Activity: `idx_activity_feed_user`, `idx_activity_feed_created`, `idx_activity_feed_type`
- Events: `idx_life_events_type`, `idx_life_events_date`, `idx_family_events_user`, `idx_family_events_type`
- Notifications: `idx_notifications_user`, `idx_notifications_created`
- Admin: `idx_audit_logs_admin_user_timestamp`

---

## 📊 Performance Impact

### Expected Improvements:

1. **RLS Policy Evaluation**: 
   - **Before**: O(n) - evaluated per row
   - **After**: O(1) - evaluated once per query
   - **Impact**: Up to 100x faster for large result sets

2. **Multiple Policies**:
   - **Before**: 2-3 policies evaluated per query
   - **After**: 1 policy evaluated per query
   - **Impact**: 2-3x reduction in policy evaluation overhead

3. **Foreign Key Lookups**:
   - **Before**: Sequential scans on FK lookups
   - **After**: Index scans
   - **Impact**: 10-1000x faster depending on table size

4. **Write Performance**:
   - **Before**: 18 unused indexes maintained on writes
   - **After**: Only active indexes maintained
   - **Impact**: ~30% faster INSERT/UPDATE/DELETE on affected tables

---

## 🚀 How to Apply

### Option 1: PowerShell Script (Recommended)

```powershell
cd scripts
.\apply-db-performance-fixes.ps1
```

### Option 2: Supabase CLI

```bash
supabase db push
```

### Option 3: Supabase Dashboard

1. Go to: https://supabase.com/dashboard/project/[YOUR-PROJECT-REF]/sql/new
2. Copy contents of `supabase/migrations/020_comprehensive_performance_fixes.sql`
3. Click "Run"

### Option 4: Direct psql

```bash
psql postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres \
  -f supabase/migrations/020_comprehensive_performance_fixes.sql
```

---

## ✅ Verification Steps

After applying the migration:

1. **Run Database Linter** (Supabase Dashboard):
   - Database > Database Linter
   - All WARN issues should be resolved
   - INFO issues should be significantly reduced

2. **Check Migrations**:
   - Database > Migrations
   - Verify `020_comprehensive_performance_fixes` is listed

3. **Test Application**:
   - Login/signup flows
   - Family tree queries
   - Forum interactions
   - Search functionality

4. **Monitor Performance** (24-48 hours):
   - Database > Query Performance
   - Look for improved query times
   - Check slow query log

---

## 🔄 Rollback Plan

If issues arise, rollback by:

1. **Re-create original policies** (from migration 004 or 018)
2. **Re-add removed indexes**:
   ```sql
   CREATE INDEX idx_persons_nakshatra ON persons(nakshatra);
   -- ... etc
   ```
3. **Drop new foreign key indexes if causing issues**

**Note**: Original migration files are preserved in `supabase/migrations/` for reference.

---

## 📝 Related Files

- **Migration**: `supabase/migrations/020_comprehensive_performance_fixes.sql`
- **Apply Script**: `scripts/apply-db-performance-fixes.ps1`
- **Linter Report**: `supabase/supabase-issues.md`
- **Previous Fix**: `supabase/migrations/018_fix_rls_performance.sql`

---

## 🎓 Learn More

- [Supabase RLS Performance](https://supabase.com/docs/guides/database/postgres/row-level-security#call-functions-with-select)
- [Database Linter](https://supabase.com/docs/guides/database/database-linter)
- [PostgreSQL Index Usage](https://www.postgresql.org/docs/current/indexes.html)

