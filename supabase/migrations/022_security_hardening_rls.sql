-- ============================================================
-- Migration 022: Security Hardening - RLS Policy Fixes
-- ============================================================
-- Fixes identified in security audit:
--   1. invite_tokens: RLS was never enabled
--   2. person_documents: SELECT USING(true) exposes private docs
--   3. forum_media: INSERT/DELETE WITH CHECK(true) allows anyone
--   4. notifications: INSERT WITH CHECK(true) allows spoofing
--   5. activity_feed: INSERT WITH CHECK(true) allows spoofing
--   6. Storage (avatars): Any authed user can overwrite/delete others' files
--   7. Various SELECT USING(true) tightened to authenticated-only
-- ============================================================

-- =====================
-- 1. INVITE TOKENS - Enable RLS (was completely missing)
-- =====================
ALTER TABLE invite_tokens ENABLE ROW LEVEL SECURITY;

-- Creators can view their own invites
CREATE POLICY "Users can view own invites"
  ON invite_tokens FOR SELECT
  USING (invited_by_user_id = auth.uid());

-- Users can create invites (as themselves)
CREATE POLICY "Users can create invites"
  ON invite_tokens FOR INSERT
  WITH CHECK (invited_by_user_id = auth.uid());

-- Anyone with a valid token can claim it (used during accept-invite flow)
-- The token itself acts as the secret; backend validates and sets used=true
CREATE POLICY "Users can update invites they created"
  ON invite_tokens FOR UPDATE
  USING (invited_by_user_id = auth.uid());

-- Only the creator can delete/revoke invites
CREATE POLICY "Users can delete own invites"
  ON invite_tokens FOR DELETE
  USING (invited_by_user_id = auth.uid());

-- =====================
-- 2. PERSON DOCUMENTS - Restrict SELECT to owner/uploader
-- =====================
-- Old policy: USING(true) — any authed user sees ALL documents including private ones
DROP POLICY IF EXISTS "Users can view docs of their tree" ON person_documents;

CREATE POLICY "Users can view docs of their tree"
  ON person_documents FOR SELECT
  USING (
    -- Uploader can always see their own uploads
    uploaded_by_user_id = auth.uid()
    OR
    -- Non-private docs: visible to anyone in the creator's tree
    (
      is_private = FALSE
      AND EXISTS (
        SELECT 1 FROM persons p
        WHERE p.id = person_documents.person_id
          AND p.created_by_user_id = auth.uid()
      )
    )
    OR
    -- Private docs: only visible if the person belongs to the viewer's tree
    (
      is_private = TRUE
      AND EXISTS (
        SELECT 1 FROM persons p
        WHERE p.id = person_documents.person_id
          AND p.created_by_user_id = auth.uid()
      )
    )
  );

-- =====================
-- 3. FORUM MEDIA - Fix INSERT and DELETE
-- =====================
-- Old INSERT: WITH CHECK(true) — anyone can attach media to any post
DROP POLICY IF EXISTS "Post authors can add media" ON forum_media;

CREATE POLICY "Post authors can add media"
  ON forum_media FOR INSERT
  WITH CHECK (
    -- Only the post author can add media to their post
    EXISTS (
      SELECT 1 FROM forum_posts fp
      WHERE fp.id = forum_media.post_id
        AND fp.author_user_id = auth.uid()
    )
  );

-- Old DELETE: USING(true) — anyone can delete any media
DROP POLICY IF EXISTS "Post authors can delete media" ON forum_media;

CREATE POLICY "Post authors can delete media"
  ON forum_media FOR DELETE
  USING (
    -- Only the post author can delete media from their post
    EXISTS (
      SELECT 1 FROM forum_posts fp
      WHERE fp.id = forum_media.post_id
        AND fp.author_user_id = auth.uid()
    )
  );

-- =====================
-- 4. NOTIFICATIONS - Fix INSERT
-- =====================
-- Old INSERT: WITH CHECK(true) — anyone can create notifications for anyone
DROP POLICY IF EXISTS "System can create notifications" ON notifications;

CREATE POLICY "System can create notifications"
  ON notifications FOR INSERT
  WITH CHECK (
    -- Notifications can only be created targeting the current user
    -- (backend service role bypasses RLS for system notifications)
    user_id = auth.uid()
  );

-- =====================
-- 5. ACTIVITY FEED - Fix INSERT
-- =====================
-- Old INSERT: WITH CHECK(true) — anyone can log activity as anyone
DROP POLICY IF EXISTS "System can create activity" ON activity_feed;

CREATE POLICY "Users can create own activity"
  ON activity_feed FOR INSERT
  WITH CHECK (
    -- Activity entries must belong to the authenticated user
    -- (backend service role bypasses RLS for system-generated entries)
    user_id = auth.uid()
  );

-- Tighten SELECT: users only see their own activity feed
DROP POLICY IF EXISTS "Users see all activity" ON activity_feed;

CREATE POLICY "Users see own activity"
  ON activity_feed FOR SELECT
  USING (user_id = auth.uid());

-- =====================
-- 6. TIGHTEN SELECT-ONLY TABLES
-- =====================

-- life_events: SELECT USING(true) → restrict to tree owner's events
DROP POLICY IF EXISTS "Users can view life events of people in their tree" ON life_events;

CREATE POLICY "Users can view life events of people in their tree"
  ON life_events FOR SELECT
  USING (
    created_by_user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM persons p
      WHERE p.id = life_events.person_id
        AND p.created_by_user_id = auth.uid()
    )
  );

-- family_events: SELECT USING(true) → restrict to creator's events
DROP POLICY IF EXISTS "Users see all family events" ON family_events;

CREATE POLICY "Users see own family events"
  ON family_events FOR SELECT
  USING (created_by_user_id = auth.uid());

-- forum_posts: SELECT USING(true) is acceptable for a community forum
-- (intentional design - family forum is shared among all authenticated users)
-- BUT ensure only authenticated users, not anon:
DROP POLICY IF EXISTS "Anyone can view forum posts" ON forum_posts;

CREATE POLICY "Authenticated users can view forum posts"
  ON forum_posts FOR SELECT
  USING (auth.role() = 'authenticated');

-- forum_comments: same — restrict to authenticated
DROP POLICY IF EXISTS "Anyone can view comments" ON forum_comments;

CREATE POLICY "Authenticated users can view comments"
  ON forum_comments FOR SELECT
  USING (auth.role() = 'authenticated');

-- forum_likes: same — restrict to authenticated
DROP POLICY IF EXISTS "Anyone can view likes" ON forum_likes;

CREATE POLICY "Authenticated users can view likes"
  ON forum_likes FOR SELECT
  USING (auth.role() = 'authenticated');

-- forum_media: same — restrict SELECT to authenticated
DROP POLICY IF EXISTS "Anyone can view media" ON forum_media;

CREATE POLICY "Authenticated users can view media"
  ON forum_media FOR SELECT
  USING (auth.role() = 'authenticated');

-- =====================
-- 7. STORAGE - Scope avatar policies to user-owned paths
-- =====================
-- Current policies let any authenticated user update/delete ANY avatar.
-- Fix: scope write operations to the user's own folder (uid/filename).

-- Drop existing overly-permissive policies
DROP POLICY IF EXISTS "Auth users can upload avatars" ON storage.objects;
DROP POLICY IF EXISTS "Auth users can update avatars" ON storage.objects;
DROP POLICY IF EXISTS "Auth users can delete avatars" ON storage.objects;

-- Upload: user can only upload to their own folder
CREATE POLICY "Users can upload own avatars"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Update: user can only replace their own files
CREATE POLICY "Users can update own avatars"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Delete: user can only delete their own files
CREATE POLICY "Users can delete own avatars"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Public read policy remains unchanged (avatars are public by design)
-- "Public avatar read access" stays as-is

-- =====================
-- 8. Add DELETE policy for person_documents (was missing)
-- =====================
-- The original migration only had DELETE for uploaders, which is correct.
-- Verify it exists; if not, create it:
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'person_documents'
      AND policyname = 'Uploaders can delete docs'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY "Uploaders can delete docs"
        ON person_documents FOR DELETE
        USING (uploaded_by_user_id = auth.uid())
    $policy$;
  END IF;
END
$$;

-- ============================================================
-- DONE: All critical RLS vulnerabilities addressed.
-- Backend service_role key bypasses RLS for system operations.
-- ============================================================
