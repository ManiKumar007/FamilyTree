-- ============================================
-- MyFamilyTree: Row-Level Security Policies
-- ============================================

-- Enable RLS on all tables
ALTER TABLE persons ENABLE ROW LEVEL SECURITY;
ALTER TABLE relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE merge_requests ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PERSONS policies
-- ============================================

-- Users can read persons they created
CREATE POLICY "Users can read own created persons"
  ON persons FOR SELECT
  USING (created_by_user_id = auth.uid());

-- Users can read their own claimed profile
CREATE POLICY "Users can read own profile"
  ON persons FOR SELECT
  USING (auth_user_id = auth.uid());

-- Users can read persons connected to their tree (via relationships)
-- This uses a subquery to find all person IDs reachable from the user's person record
CREATE POLICY "Users can read connected persons"
  ON persons FOR SELECT
  USING (
    id IN (
      WITH RECURSIVE connected AS (
        -- Start from the user's own person record
        SELECT p.id FROM persons p WHERE p.auth_user_id = auth.uid()
        UNION
        -- Traverse relationships
        SELECT r.related_person_id
        FROM relationships r
        JOIN connected c ON r.person_id = c.id
      )
      SELECT id FROM connected
    )
  );

-- Users can insert persons (they become the creator)
CREATE POLICY "Users can create persons"
  ON persons FOR INSERT
  WITH CHECK (created_by_user_id = auth.uid());

-- Users can update persons they created
CREATE POLICY "Users can update own created persons"
  ON persons FOR UPDATE
  USING (created_by_user_id = auth.uid());

-- Users can update their own claimed profile
CREATE POLICY "Users can update own profile"
  ON persons FOR UPDATE
  USING (auth_user_id = auth.uid());

-- ============================================
-- RELATIONSHIPS policies
-- ============================================

-- Users can read relationships involving persons they can see
CREATE POLICY "Users can read relationships"
  ON relationships FOR SELECT
  USING (
    created_by_user_id = auth.uid()
    OR person_id IN (
      SELECT id FROM persons WHERE created_by_user_id = auth.uid() OR auth_user_id = auth.uid()
    )
  );

-- Users can create relationships
CREATE POLICY "Users can create relationships"
  ON relationships FOR INSERT
  WITH CHECK (created_by_user_id = auth.uid());

-- Users can delete relationships they created
CREATE POLICY "Users can delete own relationships"
  ON relationships FOR DELETE
  USING (created_by_user_id = auth.uid());

-- ============================================
-- MERGE_REQUESTS policies
-- ============================================

-- Users can see merge requests they created
CREATE POLICY "Users can read own merge requests"
  ON merge_requests FOR SELECT
  USING (requester_user_id = auth.uid());

-- Users can see merge requests targeting their persons
CREATE POLICY "Users can read targeted merge requests"
  ON merge_requests FOR SELECT
  USING (
    target_person_id IN (
      SELECT id FROM persons WHERE created_by_user_id = auth.uid() OR auth_user_id = auth.uid()
    )
  );

-- Users can create merge requests
CREATE POLICY "Users can create merge requests"
  ON merge_requests FOR INSERT
  WITH CHECK (requester_user_id = auth.uid());

-- Users can update (approve/reject) merge requests targeting their persons
CREATE POLICY "Users can resolve merge requests"
  ON merge_requests FOR UPDATE
  USING (
    target_person_id IN (
      SELECT id FROM persons WHERE created_by_user_id = auth.uid() OR auth_user_id = auth.uid()
    )
  );

-- ============================================
-- Service role bypass (for backend API)
-- ============================================
-- The Node.js backend uses the service_role key which bypasses RLS.
-- This is intentional: complex graph queries and merge logic run server-side.
