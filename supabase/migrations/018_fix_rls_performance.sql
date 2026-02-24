-- ============================================
-- Migration 018: Fix RLS Performance Issues
-- Fixes identified by Supabase database linter:
-- 1. auth.uid() calls wrapped in (select auth.uid()) for better performance
-- 2. Multiple permissive policies combined into single policies
-- 3. Missing foreign key indexes added
-- ============================================

-- ===========================================
-- PART 1: Fix auth.uid() in PERSONS table policies
-- ===========================================

-- Drop existing policies on persons table
DROP POLICY IF EXISTS "Users can read own created persons" ON persons;
DROP POLICY IF EXISTS "Users can read own profile" ON persons;
DROP POLICY IF EXISTS "Users can read connected persons" ON persons;
DROP POLICY IF EXISTS "Users can create persons" ON persons;
DROP POLICY IF EXISTS "Users can update own created persons" ON persons;
DROP POLICY IF EXISTS "Users can update own profile" ON persons;

-- Combined SELECT policy (fixes multiple_permissive_policies)
CREATE POLICY "Users can read accessible persons"
  ON persons FOR SELECT
  USING (
    created_by_user_id = (select auth.uid())
    OR auth_user_id = (select auth.uid())
    OR id IN (
      WITH RECURSIVE connected AS (
        SELECT p.id FROM persons p WHERE p.auth_user_id = (select auth.uid())
        UNION
        SELECT r.related_person_id
        FROM relationships r
        JOIN connected c ON r.person_id = c.id
      )
      SELECT id FROM connected
    )
  );

-- INSERT policy with optimized auth.uid()
CREATE POLICY "Users can create persons"
  ON persons FOR INSERT
  WITH CHECK (created_by_user_id = (select auth.uid()));

-- Combined UPDATE policy (fixes multiple_permissive_policies)
CREATE POLICY "Users can update accessible persons"
  ON persons FOR UPDATE
  USING (
    created_by_user_id = (select auth.uid())
    OR auth_user_id = (select auth.uid())
  );

-- ===========================================
-- PART 2: Fix auth.uid() in RELATIONSHIPS table policies
-- ===========================================

DROP POLICY IF EXISTS "Users can read relationships" ON relationships;
DROP POLICY IF EXISTS "Users can create relationships" ON relationships;
DROP POLICY IF EXISTS "Users can delete own relationships" ON relationships;

CREATE POLICY "Users can read relationships"
  ON relationships FOR SELECT
  USING (
    created_by_user_id = (select auth.uid())
    OR person_id IN (
      SELECT id FROM persons 
      WHERE created_by_user_id = (select auth.uid()) 
         OR auth_user_id = (select auth.uid())
    )
  );

CREATE POLICY "Users can create relationships"
  ON relationships FOR INSERT
  WITH CHECK (created_by_user_id = (select auth.uid()));

CREATE POLICY "Users can delete own relationships"
  ON relationships FOR DELETE
  USING (created_by_user_id = (select auth.uid()));

-- ===========================================
-- PART 3: Fix auth.uid() in MERGE_REQUESTS table policies
-- ===========================================

DROP POLICY IF EXISTS "Users can read own merge requests" ON merge_requests;
DROP POLICY IF EXISTS "Users can read targeted merge requests" ON merge_requests;
DROP POLICY IF EXISTS "Users can create merge requests" ON merge_requests;
DROP POLICY IF EXISTS "Users can resolve merge requests" ON merge_requests;

-- Combined SELECT policy (fixes multiple_permissive_policies)
CREATE POLICY "Users can read merge requests"
  ON merge_requests FOR SELECT
  USING (
    requester_user_id = (select auth.uid())
    OR target_person_id IN (
      SELECT id FROM persons 
      WHERE created_by_user_id = (select auth.uid()) 
         OR auth_user_id = (select auth.uid())
    )
  );

CREATE POLICY "Users can create merge requests"
  ON merge_requests FOR INSERT
  WITH CHECK (requester_user_id = (select auth.uid()));

CREATE POLICY "Users can resolve merge requests"
  ON merge_requests FOR UPDATE
  USING (
    target_person_id IN (
      SELECT id FROM persons 
      WHERE created_by_user_id = (select auth.uid()) 
         OR auth_user_id = (select auth.uid())
    )
  );

-- ===========================================
-- PART 4: Fix auth.uid() in USER_METADATA table policies
-- ===========================================

DROP POLICY IF EXISTS "Users can view own metadata" ON user_metadata;
DROP POLICY IF EXISTS "Users can update own preferences" ON user_metadata;

CREATE POLICY "Users can view own metadata"
  ON user_metadata FOR SELECT
  USING ((select auth.uid()) = user_id);

CREATE POLICY "Users can update own preferences"
  ON user_metadata FOR UPDATE
  USING ((select auth.uid()) = user_id)
  WITH CHECK (
    (select auth.uid()) = user_id 
    AND role = (SELECT role FROM user_metadata WHERE user_id = (select auth.uid()))
  );

-- ===========================================
-- PART 5: Fix auth.uid() in ERROR_LOGS table policies
-- ===========================================

DROP POLICY IF EXISTS "Only admins view errors" ON error_logs;
DROP POLICY IF EXISTS "Only admins resolve errors" ON error_logs;

CREATE POLICY "Only admins view errors"
  ON error_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_metadata
      WHERE user_id = (select auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

CREATE POLICY "Only admins resolve errors"
  ON error_logs FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_metadata
      WHERE user_id = (select auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- ===========================================
-- PART 6: Fix auth.uid() in AUDIT_LOGS table policies
-- ===========================================

DROP POLICY IF EXISTS "Only admins view audit logs" ON audit_logs;

CREATE POLICY "Only admins view audit logs"
  ON audit_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_metadata
      WHERE user_id = (select auth.uid())
      AND role IN ('admin', 'super_admin')
    )
  );

-- ===========================================
-- PART 7: Fix auth.uid() in LIFE_EVENTS table policies
-- ===========================================

DROP POLICY IF EXISTS "Users can create life events" ON life_events;
DROP POLICY IF EXISTS "Users can update own life events" ON life_events;
DROP POLICY IF EXISTS "Users can delete own life events" ON life_events;

CREATE POLICY "Users can create life events"
  ON life_events FOR INSERT 
  WITH CHECK (created_by_user_id = (select auth.uid()));

CREATE POLICY "Users can update own life events"
  ON life_events FOR UPDATE 
  USING (created_by_user_id = (select auth.uid()));

CREATE POLICY "Users can delete own life events"
  ON life_events FOR DELETE 
  USING (created_by_user_id = (select auth.uid()));

-- ===========================================
-- PART 8: Fix auth.uid() in FORUM_POSTS table policies
-- ===========================================

DROP POLICY IF EXISTS "Auth users can create posts" ON forum_posts;
DROP POLICY IF EXISTS "Authors can update posts" ON forum_posts;
DROP POLICY IF EXISTS "Authors can delete posts" ON forum_posts;

CREATE POLICY "Auth users can create posts" 
  ON forum_posts FOR INSERT 
  WITH CHECK (author_user_id = (select auth.uid()));

CREATE POLICY "Authors can update posts" 
  ON forum_posts FOR UPDATE 
  USING (author_user_id = (select auth.uid()));

CREATE POLICY "Authors can delete posts" 
  ON forum_posts FOR DELETE 
  USING (author_user_id = (select auth.uid()));

-- ===========================================
-- PART 9: Fix auth.uid() in FORUM_COMMENTS table policies
-- ===========================================

DROP POLICY IF EXISTS "Auth users can comment" ON forum_comments;
DROP POLICY IF EXISTS "Authors can update comments" ON forum_comments;
DROP POLICY IF EXISTS "Authors can delete comments" ON forum_comments;

CREATE POLICY "Auth users can comment" 
  ON forum_comments FOR INSERT 
  WITH CHECK (author_user_id = (select auth.uid()));

CREATE POLICY "Authors can update comments" 
  ON forum_comments FOR UPDATE 
  USING (author_user_id = (select auth.uid()));

CREATE POLICY "Authors can delete comments" 
  ON forum_comments FOR DELETE 
  USING (author_user_id = (select auth.uid()));

-- ===========================================
-- PART 10: Fix auth.uid() in FORUM_LIKES table policies
-- ===========================================

DROP POLICY IF EXISTS "Users can like" ON forum_likes;
DROP POLICY IF EXISTS "Users can unlike" ON forum_likes;

CREATE POLICY "Users can like" 
  ON forum_likes FOR INSERT 
  WITH CHECK (user_id = (select auth.uid()));

CREATE POLICY "Users can unlike" 
  ON forum_likes FOR DELETE 
  USING (user_id = (select auth.uid()));

-- ===========================================
-- PART 11: Fix auth.uid() in PERSON_DOCUMENTS table policies
-- ===========================================

DROP POLICY IF EXISTS "Users can upload docs" ON person_documents;
DROP POLICY IF EXISTS "Uploaders can delete docs" ON person_documents;

CREATE POLICY "Users can upload docs" 
  ON person_documents FOR INSERT 
  WITH CHECK (uploaded_by_user_id = (select auth.uid()));

CREATE POLICY "Uploaders can delete docs" 
  ON person_documents FOR DELETE 
  USING (uploaded_by_user_id = (select auth.uid()));

-- ===========================================
-- PART 12: Fix auth.uid() in NOTIFICATIONS table policies
-- ===========================================

DROP POLICY IF EXISTS "Users see own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can delete own notifications" ON notifications;

CREATE POLICY "Users see own notifications" 
  ON notifications FOR SELECT 
  USING (user_id = (select auth.uid()));

CREATE POLICY "Users can update own notifications" 
  ON notifications FOR UPDATE 
  USING (user_id = (select auth.uid()));

CREATE POLICY "Users can delete own notifications" 
  ON notifications FOR DELETE 
  USING (user_id = (select auth.uid()));

-- ===========================================
-- PART 13: Fix auth.uid() in FAMILY_EVENTS table policies
-- ===========================================

DROP POLICY IF EXISTS "Users create events" ON family_events;
DROP POLICY IF EXISTS "Users update own events" ON family_events;
DROP POLICY IF EXISTS "Users delete own events" ON family_events;

CREATE POLICY "Users create events" 
  ON family_events FOR INSERT 
  WITH CHECK (created_by_user_id = (select auth.uid()));

CREATE POLICY "Users update own events" 
  ON family_events FOR UPDATE 
  USING (created_by_user_id = (select auth.uid()));

CREATE POLICY "Users delete own events" 
  ON family_events FOR DELETE 
  USING (created_by_user_id = (select auth.uid()));

-- ===========================================
-- PART 14: Add missing foreign key indexes
-- ===========================================

-- forum_comments.author_user_id
CREATE INDEX IF NOT EXISTS idx_forum_comments_author_user_id 
  ON forum_comments(author_user_id);

-- forum_likes.comment_id (partial index for non-null values)
CREATE INDEX IF NOT EXISTS idx_forum_likes_comment_id 
  ON forum_likes(comment_id) WHERE comment_id IS NOT NULL;

-- forum_likes.post_id (partial index for non-null values)
CREATE INDEX IF NOT EXISTS idx_forum_likes_post_id 
  ON forum_likes(post_id) WHERE post_id IS NOT NULL;

-- invite_tokens.invited_by_user_id
CREATE INDEX IF NOT EXISTS idx_invite_tokens_invited_by_user_id 
  ON invite_tokens(invited_by_user_id);

-- invite_tokens.used_by_user_id (partial index for non-null values)
CREATE INDEX IF NOT EXISTS idx_invite_tokens_used_by_user_id 
  ON invite_tokens(used_by_user_id) WHERE used_by_user_id IS NOT NULL;

-- life_events.created_by_user_id
CREATE INDEX IF NOT EXISTS idx_life_events_created_by_user_id 
  ON life_events(created_by_user_id);

-- merge_requests.matched_person_id
CREATE INDEX IF NOT EXISTS idx_merge_requests_matched_person_id 
  ON merge_requests(matched_person_id);

-- merge_requests.resolved_by_user_id (partial index for non-null values)
CREATE INDEX IF NOT EXISTS idx_merge_requests_resolved_by_user_id 
  ON merge_requests(resolved_by_user_id) WHERE resolved_by_user_id IS NOT NULL;

-- person_documents.uploaded_by_user_id
CREATE INDEX IF NOT EXISTS idx_person_documents_uploaded_by_user_id 
  ON person_documents(uploaded_by_user_id);

-- relationships.created_by_user_id
CREATE INDEX IF NOT EXISTS idx_relationships_created_by_user_id 
  ON relationships(created_by_user_id);

-- ===========================================
-- PART 15: Add composite index for better admin queries
-- ===========================================

-- Already exists but creating if not exists for safety
CREATE INDEX IF NOT EXISTS idx_audit_logs_admin_user_timestamp 
  ON audit_logs(admin_user_id, timestamp DESC);

-- Add index for created_by lookups
CREATE INDEX IF NOT EXISTS idx_persons_created_by_created_at 
  ON persons(created_by_user_id, created_at DESC);

-- ===========================================
-- Comments
-- ===========================================

COMMENT ON INDEX idx_forum_comments_author_user_id IS 'Index for FK forum_comments.author_user_id';
COMMENT ON INDEX idx_forum_likes_comment_id IS 'Index for FK forum_likes.comment_id';
COMMENT ON INDEX idx_forum_likes_post_id IS 'Index for FK forum_likes.post_id';
COMMENT ON INDEX idx_invite_tokens_invited_by_user_id IS 'Index for FK invite_tokens.invited_by_user_id';
COMMENT ON INDEX idx_invite_tokens_used_by_user_id IS 'Index for FK invite_tokens.used_by_user_id';
COMMENT ON INDEX idx_life_events_created_by_user_id IS 'Index for FK life_events.created_by_user_id';
COMMENT ON INDEX idx_merge_requests_matched_person_id IS 'Index for FK merge_requests.matched_person_id';
COMMENT ON INDEX idx_merge_requests_resolved_by_user_id IS 'Index for FK merge_requests.resolved_by_user_id';
COMMENT ON INDEX idx_person_documents_uploaded_by_user_id IS 'Index for FK person_documents.uploaded_by_user_id';
COMMENT ON INDEX idx_relationships_created_by_user_id IS 'Index for FK relationships.created_by_user_id';
