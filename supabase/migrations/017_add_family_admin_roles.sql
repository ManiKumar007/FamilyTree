-- ============================================
-- Family Tree Admin & Permissions System
-- ============================================

/**
 * This migration adds a family tree ownership model where:
 * - Each family tree has one or more administrators
 * - Admins can manage all persons in their tree
 * - Regular members can only edit their own profile
 * - Admins can promote other family members to admin
 */

-- Family Tree Admin Roles
CREATE TYPE family_role AS ENUM ('member', 'admin', 'owner');

-- Family Tree Members with Roles
CREATE TABLE IF NOT EXISTS family_tree_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  person_id UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
  family_tree_id UUID NOT NULL, -- References the root person of the tree
  role family_role NOT NULL DEFAULT 'member',
  granted_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  -- One person can only have one role per tree
  UNIQUE(person_id, family_tree_id)
);

CREATE INDEX idx_family_tree_members_tree ON family_tree_members(family_tree_id);
CREATE INDEX idx_family_tree_members_person ON family_tree_members(person_id);
CREATE INDEX idx_family_tree_members_role ON family_tree_members(role) WHERE role IN ('admin', 'owner');

-- Trigger to update updated_at
CREATE TRIGGER update_family_tree_members_updated_at
  BEFORE UPDATE ON family_tree_members
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS Policies
ALTER TABLE family_tree_members ENABLE ROW LEVEL SECURITY;

-- Members can view their own tree memberships
CREATE POLICY "Members can view own tree memberships"
  ON family_tree_members FOR SELECT
  USING (person_id IN (SELECT id FROM persons WHERE auth_user_id = auth.uid()));

-- Admins can view all members in their tree
CREATE POLICY "Admins can view tree members"
  ON family_tree_members FOR SELECT
  USING (
    family_tree_id IN (
      SELECT family_tree_id 
      FROM family_tree_members ftm
      JOIN persons p ON p.id = ftm.person_id
      WHERE p.auth_user_id = auth.uid() 
        AND ftm.role IN ('admin', 'owner')
    )
  );

-- Only owners can grant/revoke admin roles
CREATE POLICY "Owners can manage roles"
  ON family_tree_members FOR ALL
  USING (
    family_tree_id IN (
      SELECT family_tree_id 
      FROM family_tree_members ftm
      JOIN persons p ON p.id = ftm.person_id
      WHERE p.auth_user_id = auth.uid() 
        AND ftm.role = 'owner'
    )
  );

-- ============================================
-- Helper Functions
-- ============================================

/**
 * Check if user is admin of the family tree containing a person
 */
CREATE OR REPLACE FUNCTION is_family_admin(
  auth_user_id UUID,
  target_person_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  is_admin BOOLEAN;
BEGIN
  -- Check if user has admin or owner role for this person's tree
  SELECT EXISTS(
    SELECT 1
    FROM family_tree_members ftm
    JOIN persons p ON p.id = ftm.person_id
    WHERE p.auth_user_id = is_family_admin.auth_user_id
      AND ftm.role IN ('admin', 'owner')
      AND ftm.family_tree_id IN (
        SELECT family_tree_id 
        FROM family_tree_members 
        WHERE person_id = target_person_id
      )
  ) INTO is_admin;
  
  RETURN is_admin;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

/**
 * Auto-assign owner role when user creates their first person (profile setup)
 */
CREATE OR REPLACE FUNCTION auto_assign_tree_owner()
RETURNS TRIGGER AS $$
BEGIN
  -- If this is the user's own profile (auth_user_id is set)
  IF NEW.auth_user_id IS NOT NULL THEN
    INSERT INTO family_tree_members (person_id, family_tree_id, role)
    VALUES (NEW.id, NEW.id, 'owner')
    ON CONFLICT (person_id, family_tree_id) DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-assign owner role
CREATE TRIGGER trigger_auto_assign_tree_owner
  AFTER INSERT ON persons
  FOR EACH ROW
  WHEN (NEW.auth_user_id IS NOT NULL)
  EXECUTE FUNCTION auto_assign_tree_owner();

-- ============================================
-- Update Authorization Functions
-- ============================================

/**
 * Enhanced permission check: user can access person if:
 * 1. They're connected in tree (existing check), OR
 * 2. They're an admin of the person's family tree
 */
CREATE OR REPLACE FUNCTION can_user_edit_person(
  auth_user_id UUID,
  target_person_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  user_person_id UUID;
  can_edit BOOLEAN;
BEGIN
  -- Get the person record for this auth user
  SELECT id INTO user_person_id
  FROM persons
  WHERE persons.auth_user_id = can_user_edit_person.auth_user_id
  LIMIT 1;

  -- If user has no person record, deny access
  IF user_person_id IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Check if user is the owner (created the person)
  IF EXISTS(
    SELECT 1 FROM persons 
    WHERE id = target_person_id 
      AND (created_by_user_id = can_user_edit_person.auth_user_id 
           OR auth_user_id = can_user_edit_person.auth_user_id)
  ) THEN
    RETURN TRUE;
  END IF;

  -- Check if user is family admin
  SELECT is_family_admin(can_user_edit_person.auth_user_id, target_person_id) INTO can_edit;
  
  RETURN can_edit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Comments
COMMENT ON TABLE family_tree_members IS 'Tracks family tree membership and admin roles';
COMMENT ON FUNCTION is_family_admin IS 'Check if user is admin/owner of a family tree';
COMMENT ON FUNCTION can_user_edit_person IS 'Check if user can edit a person (owner or family admin)';
