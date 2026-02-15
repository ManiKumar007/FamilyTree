-- Migration 008: Create audit logs table for tracking admin actions
-- Records all administrative actions for accountability and compliance

CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
  admin_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  action_type TEXT NOT NULL, -- 'create', 'update', 'delete', 'approve', 'reject', 'disable', 'enable'
  resource_type TEXT NOT NULL, -- 'user', 'person', 'relationship', 'merge_request', 'error_log'
  resource_id UUID,
  old_value JSONB,
  new_value JSONB,
  changes JSONB, -- Specific fields that changed
  ip_address INET,
  user_agent TEXT,
  notes TEXT, -- Optional admin notes about the action
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for efficient admin audit trail queries
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp DESC);
CREATE INDEX idx_audit_logs_admin_user ON audit_logs(admin_user_id, timestamp DESC);
CREATE INDEX idx_audit_logs_action_type ON audit_logs(action_type);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);

-- Composite index for common admin queries
CREATE INDEX idx_audit_logs_admin_view ON audit_logs(timestamp DESC, action_type, resource_type);

-- Function to log admin actions (called from backend)
CREATE OR REPLACE FUNCTION log_admin_action(
  p_admin_user_id UUID,
  p_action_type TEXT,
  p_resource_type TEXT,
  p_resource_id UUID DEFAULT NULL,
  p_old_value JSONB DEFAULT NULL,
  p_new_value JSONB DEFAULT NULL,
  p_ip_address INET DEFAULT NULL,
  p_user_agent TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_audit_id UUID;
  v_changes JSONB;
BEGIN
  -- Calculate what actually changed
  IF p_old_value IS NOT NULL AND p_new_value IS NOT NULL THEN
    SELECT jsonb_object_agg(key, value)
    INTO v_changes
    FROM jsonb_each(p_new_value)
    WHERE value IS DISTINCT FROM p_old_value->key;
  END IF;

  INSERT INTO audit_logs (
    admin_user_id,
    action_type,
    resource_type,
    resource_id,
    old_value,
    new_value,
    changes,
    ip_address,
    user_agent,
    notes
  ) VALUES (
    p_admin_user_id,
    p_action_type,
    p_resource_type,
    p_resource_id,
    p_old_value,
    p_new_value,
    v_changes,
    p_ip_address,
    p_user_agent,
    p_notes
  )
  RETURNING id INTO v_audit_id;

  RETURN v_audit_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get recent admin activity
CREATE OR REPLACE FUNCTION get_recent_admin_activity(
  limit_count INTEGER DEFAULT 50,
  admin_filter UUID DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  timestamp TIMESTAMPTZ,
  admin_email TEXT,
  action_type TEXT,
  resource_type TEXT,
  resource_id UUID,
  changes JSONB,
  notes TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    a.id,
    a.timestamp,
    u.email as admin_email,
    a.action_type,
    a.resource_type,
    a.resource_id,
    a.changes,
    a.notes
  FROM audit_logs a
  JOIN auth.users u ON u.id = a.admin_user_id
  WHERE admin_filter IS NULL OR a.admin_user_id = admin_filter
  ORDER BY a.timestamp DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get admin activity statistics
CREATE OR REPLACE FUNCTION get_admin_activity_stats(
  time_range INTERVAL DEFAULT '7 days'
)
RETURNS TABLE (
  admin_email TEXT,
  action_type TEXT,
  action_count BIGINT,
  last_action TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.email as admin_email,
    a.action_type,
    COUNT(*)::BIGINT as action_count,
    MAX(a.timestamp) as last_action
  FROM audit_logs a
  JOIN auth.users u ON u.id = a.admin_user_id
  WHERE a.timestamp > now() - time_range
  GROUP BY u.email, a.action_type
  ORDER BY action_count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to auto-delete old audit logs (1 year retention)
CREATE OR REPLACE FUNCTION cleanup_old_audit_logs()
RETURNS void AS $$
BEGIN
  DELETE FROM audit_logs
  WHERE timestamp < now() - INTERVAL '1 year';
END;
$$ LANGUAGE plpgsql;

-- Row Level Security (RLS) Policies
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Only admins can view audit logs
CREATE POLICY "Only admins view audit logs"
  ON audit_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_metadata
      WHERE user_id = auth.uid()
      AND role IN ('admin', 'super_admin')
    )
  );

-- Backend service_role can insert audit logs (bypasses RLS)

-- Prevent updates/deletes to maintain audit integrity
CREATE POLICY "Prevent audit log modifications"
  ON audit_logs FOR UPDATE
  USING (false);

CREATE POLICY "Prevent audit log deletions"
  ON audit_logs FOR DELETE
  USING (false);

-- Comments for documentation
COMMENT ON TABLE audit_logs IS 'Audit trail of all administrative actions for accountability';
COMMENT ON COLUMN audit_logs.action_type IS 'Type of action performed: create, update, delete, approve, reject, etc.';
COMMENT ON COLUMN audit_logs.resource_type IS 'Type of resource acted upon: user, person, relationship, etc.';
COMMENT ON COLUMN audit_logs.changes IS 'JSON object showing only the fields that changed';
COMMENT ON FUNCTION log_admin_action IS 'Helper function to log admin actions with automatic change tracking';
