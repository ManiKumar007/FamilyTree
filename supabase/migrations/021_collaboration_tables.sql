-- ============================================
-- MyFamilyTree: Collaboration & Tree Sharing
-- Migration 021
-- ============================================

-- ===========================================
-- 1. TREE COLLABORATORS TABLE
-- ===========================================

CREATE TABLE IF NOT EXISTS tree_collaborators (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tree_owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  collaborator_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  permission_level TEXT NOT NULL CHECK (permission_level IN ('viewer', 'editor', 'admin')),
  invited_at TIMESTAMPTZ DEFAULT now(),
  accepted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT unique_tree_collaborator UNIQUE(tree_owner_id, collaborator_user_id)
);

CREATE INDEX idx_tree_collaborators_owner ON tree_collaborators(tree_owner_id);
CREATE INDEX idx_tree_collaborators_user ON tree_collaborators(collaborator_user_id);
CREATE INDEX idx_tree_collaborators_permission ON tree_collaborators(permission_level);

COMMENT ON TABLE tree_collaborators IS 'Manages who has access to view/edit family trees';
COMMENT ON COLUMN tree_collaborators.permission_level IS 'viewer: read-only, editor: can add/edit, admin: full control';

-- Auto-update updated_at
CREATE TRIGGER update_tree_collaborators_updated_at
  BEFORE UPDATE ON tree_collaborators
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ===========================================
-- 2. TREE INVITATIONS TABLE
-- ===========================================

CREATE TABLE IF NOT EXISTS tree_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tree_owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  invitee_identifier TEXT NOT NULL,  -- email or phone number
  permission_level TEXT NOT NULL CHECK (permission_level IN ('viewer', 'editor', 'admin')),
  status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'declined', 'expired')) DEFAULT 'pending',
  message TEXT,  -- Optional personal message from inviter
  invitation_token UUID DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '30 days'),
  accepted_at TIMESTAMPTZ,
  declined_at TIMESTAMPTZ
);

CREATE INDEX idx_tree_invitations_owner ON tree_invitations(tree_owner_id);
CREATE INDEX idx_tree_invitations_identifier ON tree_invitations(invitee_identifier);
CREATE INDEX idx_tree_invitations_status ON tree_invitations(status);
CREATE INDEX idx_tree_invitations_token ON tree_invitations(invitation_token);

COMMENT ON TABLE tree_invitations IS 'Pending invitations to collaborate on family trees';
COMMENT ON COLUMN tree_invitations.invitee_identifier IS 'Email or phone number of the person being invited';
COMMENT ON COLUMN tree_invitations.invitation_token IS 'Unique token for accepting invitation via link';

-- ===========================================
-- 3. USER ACTIVE TREE SELECTION
-- ===========================================

-- Track which tree a user is currently viewing (their own or a shared one)
CREATE TABLE IF NOT EXISTS user_active_tree (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  active_tree_owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  switched_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_user_active_tree_owner ON user_active_tree(active_tree_owner_id);

COMMENT ON TABLE user_active_tree IS 'Tracks which family tree a user is currently viewing/editing';

-- ===========================================
-- 4. RLS POLICIES
-- ===========================================

-- Tree Collaborators Policies
ALTER TABLE tree_collaborators ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see collaborators of their own tree"
  ON tree_collaborators FOR SELECT 
  USING (tree_owner_id = auth.uid());

CREATE POLICY "Users see trees they collaborate on"
  ON tree_collaborators FOR SELECT 
  USING (collaborator_user_id = auth.uid());

CREATE POLICY "Tree owners can add collaborators"
  ON tree_collaborators FOR INSERT 
  WITH CHECK (tree_owner_id = auth.uid());

CREATE POLICY "Tree owners can update collaborator permissions"
  ON tree_collaborators FOR UPDATE 
  USING (tree_owner_id = auth.uid());

CREATE POLICY "Tree owners can remove collaborators"
  ON tree_collaborators FOR DELETE 
  USING (tree_owner_id = auth.uid());

-- Tree Invitations Policies
ALTER TABLE tree_invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see their own invitations"
  ON tree_invitations FOR SELECT 
  USING (tree_owner_id = auth.uid());

CREATE POLICY "Users can view invitations sent to their email/phone"
  ON tree_invitations FOR SELECT 
  USING (
    invitee_identifier = (SELECT email FROM auth.users WHERE id = auth.uid())
    OR invitee_identifier = (SELECT phone FROM auth.users WHERE id = auth.uid())
  );

CREATE POLICY "Users can create invitations for their tree"
  ON tree_invitations FOR INSERT 
  WITH CHECK (tree_owner_id = auth.uid());

CREATE POLICY "Users can update their own invitations"
  ON tree_invitations FOR UPDATE 
  USING (tree_owner_id = auth.uid());

CREATE POLICY "Invitees can update invitation status"
  ON tree_invitations FOR UPDATE 
  USING (
    invitee_identifier = (SELECT email FROM auth.users WHERE id = auth.uid())
    OR invitee_identifier = (SELECT phone FROM auth.users WHERE id = auth.uid())
  );

CREATE POLICY "Users can delete their own invitations"
  ON tree_invitations FOR DELETE 
  USING (tree_owner_id = auth.uid());

-- User Active Tree Policies
ALTER TABLE user_active_tree ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage their own active tree selection"
  ON user_active_tree FOR ALL 
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ===========================================
-- 5. HELPER FUNCTIONS
-- ===========================================

-- Function to get user's current permission level on a tree
CREATE OR REPLACE FUNCTION get_user_tree_permission(p_user_id UUID, p_tree_owner_id UUID)
RETURNS TEXT AS $$
DECLARE
  v_permission TEXT;
BEGIN
  -- If user is the tree owner, they have admin permission
  IF p_user_id = p_tree_owner_id THEN
    RETURN 'admin';
  END IF;
  
  -- Check if user is a collaborator
  SELECT permission_level INTO v_permission
  FROM tree_collaborators
  WHERE tree_owner_id = p_tree_owner_id 
    AND collaborator_user_id = p_user_id
    AND accepted_at IS NOT NULL;
  
  -- Return the permission level, or 'none' if not found
  RETURN COALESCE(v_permission, 'none');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can edit a person in the tree
CREATE OR REPLACE FUNCTION can_user_edit_person(p_user_id UUID, p_person_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_person_owner_id UUID;
  v_permission TEXT;
BEGIN
  -- Get the owner of the person (who created them)
  SELECT created_by_user_id INTO v_person_owner_id
  FROM persons
  WHERE id = p_person_id;
  
  IF v_person_owner_id IS NULL THEN
    RETURN FALSE;
  END IF;
  
  -- Get user's permission on this tree
  v_permission := get_user_tree_permission(p_user_id, v_person_owner_id);
  
  -- Admin and Editor can edit, Viewer cannot
  RETURN v_permission IN ('admin', 'editor');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to auto-accept invitation when user signs up
CREATE OR REPLACE FUNCTION auto_accept_tree_invitation()
RETURNS TRIGGER AS $$
DECLARE
  v_invitation RECORD;
BEGIN
  -- Find pending invitations matching the new user's email or phone
  FOR v_invitation IN 
    SELECT * FROM tree_invitations
    WHERE status = 'pending'
      AND (invitee_identifier = NEW.email OR invitee_identifier = NEW.phone)
      AND expires_at > now()
  LOOP
    -- Create collaborator record
    INSERT INTO tree_collaborators (
      tree_owner_id,
      collaborator_user_id,
      permission_level,
      invited_at,
      accepted_at
    ) VALUES (
      v_invitation.tree_owner_id,
      NEW.id,
      v_invitation.permission_level,
      v_invitation.created_at,
      now()
    )
    ON CONFLICT (tree_owner_id, collaborator_user_id) DO NOTHING;
    
    -- Update invitation status
    UPDATE tree_invitations
    SET status = 'accepted',
        accepted_at = now()
    WHERE id = v_invitation.id;
  END LOOP;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-accept invitations when user signs up
CREATE TRIGGER on_auth_user_created_accept_invitations
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION auto_accept_tree_invitation();

-- Function to mark expired invitations
CREATE OR REPLACE FUNCTION mark_expired_invitations()
RETURNS void AS $$
BEGIN
  UPDATE tree_invitations
  SET status = 'expired'
  WHERE status = 'pending'
    AND expires_at < now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- 6. CRON JOB for Expiring Invitations
-- ===========================================

-- Note: Requires pg_cron extension
-- Run this separately if pg_cron is available:
-- SELECT cron.schedule('expire-tree-invitations', '0 0 * * *', 'SELECT mark_expired_invitations()');

COMMENT ON FUNCTION mark_expired_invitations IS 'Marks invitations as expired if past their expiry date. Should be run daily via cron.';

-- ===========================================
-- 7. INITIAL DATA
-- ===========================================

-- Set current user's active tree to their own tree
INSERT INTO user_active_tree (user_id, active_tree_owner_id)
SELECT id, id FROM auth.users
ON CONFLICT (user_id) DO NOTHING;

-- ===========================================
-- MIGRATION COMPLETE
-- ===========================================

-- Migration 021: Collaboration & Tree Sharing
-- Created: 2026-02-25
-- Tables: tree_collaborators, tree_invitations, user_active_tree
-- Features: Permission management, tree sharing, invitation system
