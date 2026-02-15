-- Migration 006: Create user metadata table for admin roles and user preferences
-- This table extends Supabase auth.users with application-specific metadata

CREATE TABLE IF NOT EXISTS user_metadata (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin', 'super_admin')),
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_login_at TIMESTAMPTZ,
  preferences JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for fast admin lookups
CREATE INDEX idx_user_metadata_role ON user_metadata(role) WHERE role IN ('admin', 'super_admin');
CREATE INDEX idx_user_metadata_active ON user_metadata(is_active);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_user_metadata_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at on row changes
CREATE TRIGGER trigger_update_user_metadata_updated_at
  BEFORE UPDATE ON user_metadata
  FOR EACH ROW
  EXECUTE FUNCTION update_user_metadata_updated_at();

-- Function to auto-create user_metadata when auth.users is created
CREATE OR REPLACE FUNCTION create_user_metadata_on_signup()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_metadata (user_id, role, is_active)
  VALUES (NEW.id, 'user', true)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users to auto-create metadata
-- Note: This requires superuser privileges, may need to be created via Supabase dashboard
-- CREATE TRIGGER on_auth_user_created
--   AFTER INSERT ON auth.users
--   FOR EACH ROW
--   EXECUTE FUNCTION create_user_metadata_on_signup();

-- Seed initial admin user (update with your actual Supabase auth user ID)
-- Get your user ID from: SELECT id FROM auth.users WHERE email = 'manich623@gmail.com';
-- For now, using the mock user ID from auth bypass
INSERT INTO user_metadata (user_id, role, is_active, created_at)
VALUES 
  ('mock-user-123', 'super_admin', true, now())
ON CONFLICT (user_id) DO UPDATE
  SET role = 'super_admin', is_active = true;

-- Row Level Security (RLS) Policies
ALTER TABLE user_metadata ENABLE ROW LEVEL SECURITY;

-- Users can view their own metadata
CREATE POLICY "Users can view own metadata"
  ON user_metadata FOR SELECT
  USING (auth.uid() = user_id);

-- Users can update their own preferences (not role)
CREATE POLICY "Users can update own preferences"
  ON user_metadata FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id 
    AND role = (SELECT role FROM user_metadata WHERE user_id = auth.uid())
  );

-- Admins can view all user metadata (requires service_role in backend)
-- Backend will bypass RLS using service_role key

-- Comment for documentation
COMMENT ON TABLE user_metadata IS 'User roles, preferences, and account status';
COMMENT ON COLUMN user_metadata.role IS 'User role: user, admin, or super_admin';
COMMENT ON COLUMN user_metadata.is_active IS 'Whether the user account is active (false = disabled)';
COMMENT ON COLUMN user_metadata.preferences IS 'JSON object for user preferences (theme, notifications, etc)';
