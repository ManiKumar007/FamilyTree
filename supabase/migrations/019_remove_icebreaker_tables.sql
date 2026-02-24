-- ============================================
-- Migration 019: Remove Icebreaker App Tables
-- Removes tables from the merged icebreaker/events app
-- that are not part of FamilyTree
-- ============================================

-- Drop tables in dependency order (children first, then parents)

-- Drop push_subscriptions (depends on profiles)
DROP TABLE IF EXISTS public.push_subscriptions CASCADE;

-- Drop connections (depends on events, profiles)
DROP TABLE IF EXISTS public.connections CASCADE;

-- Drop profiles (depends on events)
DROP TABLE IF EXISTS public.profiles CASCADE;

-- Drop events (depends on organizers)
DROP TABLE IF EXISTS public.events CASCADE;

-- Drop organizers (standalone)
DROP TABLE IF EXISTS public.organizers CASCADE;

-- Drop user_roles (standalone - different from FamilyTree's user_metadata)
DROP TABLE IF EXISTS public.user_roles CASCADE;

-- Note: All FamilyTree tables remain intact:
-- persons, relationships, merge_requests, invite_tokens, user_metadata,
-- error_logs, audit_logs, life_events, forum_posts, forum_comments,
-- forum_likes, forum_media, person_documents, notifications, activity_feed,
-- family_events, family_tree_members
