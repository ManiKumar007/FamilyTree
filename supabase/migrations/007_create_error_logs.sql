-- Migration 007: Create error logs table for error tracking and monitoring
-- Stores application errors for admin panel visibility and debugging

CREATE TABLE IF NOT EXISTS error_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timestamp TIMESTAMPTZ NOT NULL DEFAULT now(),
  error_type TEXT NOT NULL, -- 'api_error', 'validation', 'database', 'auth', 'client', etc.
  severity TEXT NOT NULL DEFAULT 'error' CHECK (severity IN ('debug', 'info', 'warn', 'error', 'critical')),
  status_code INTEGER,
  message TEXT NOT NULL,
  stack_trace TEXT,
  request_url TEXT,
  request_method TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ip_address INET,
  user_agent TEXT,
  additional_data JSONB DEFAULT '{}'::jsonb,
  resolved BOOLEAN DEFAULT false,
  resolved_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for efficient querying
CREATE INDEX idx_error_logs_timestamp ON error_logs(timestamp DESC);
CREATE INDEX idx_error_logs_user_id ON error_logs(user_id) WHERE user_id IS NOT NULL;
CREATE INDEX idx_error_logs_error_type ON error_logs(error_type);
CREATE INDEX idx_error_logs_severity ON error_logs(severity);
CREATE INDEX idx_error_logs_status_code ON error_logs(status_code) WHERE status_code IS NOT NULL;
CREATE INDEX idx_error_logs_unresolved ON error_logs(resolved, timestamp DESC) WHERE resolved = false;

-- Composite index for common admin queries
CREATE INDEX idx_error_logs_admin_view ON error_logs(timestamp DESC, error_type, severity);

-- Function to auto-delete old error logs (90-day retention)
CREATE OR REPLACE FUNCTION cleanup_old_error_logs()
RETURNS void AS $$
BEGIN
  DELETE FROM error_logs
  WHERE timestamp < now() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to clean up old errors (requires pg_cron extension)
-- Run this via Supabase dashboard SQL editor if pg_cron is available:
-- SELECT cron.schedule('cleanup-error-logs', '0 2 * * *', 'SELECT cleanup_old_error_logs();');

-- Function to get error statistics
CREATE OR REPLACE FUNCTION get_error_statistics(
  time_range INTERVAL DEFAULT '24 hours'
)
RETURNS TABLE (
  error_type TEXT,
  severity TEXT,
  count BIGINT,
  latest_occurrence TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    e.error_type,
    e.severity,
    COUNT(*)::BIGINT as count,
    MAX(e.timestamp) as latest_occurrence
  FROM error_logs e
  WHERE e.timestamp > now() - time_range
  GROUP BY e.error_type, e.severity
  ORDER BY count DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to get error rate by time window
CREATE OR REPLACE FUNCTION get_error_rate_by_hour(
  hours_back INTEGER DEFAULT 24
)
RETURNS TABLE (
  hour_bucket TIMESTAMPTZ,
  error_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    date_trunc('hour', timestamp) as hour_bucket,
    COUNT(*)::BIGINT as error_count
  FROM error_logs
  WHERE timestamp > now() - (hours_back || ' hours')::INTERVAL
  GROUP BY hour_bucket
  ORDER BY hour_bucket DESC;
END;
$$ LANGUAGE plpgsql;

-- Row Level Security (RLS) Policies
ALTER TABLE error_logs ENABLE ROW LEVEL SECURITY;

-- Only admins can view error logs (backend uses service_role to bypass)
-- Regular users cannot see any error logs
CREATE POLICY "Only admins view errors"
  ON error_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_metadata
      WHERE user_id = auth.uid()
      AND role IN ('admin', 'super_admin')
    )
  );

-- Only admins can mark errors as resolved
CREATE POLICY "Only admins resolve errors"
  ON error_logs FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_metadata
      WHERE user_id = auth.uid()
      AND role IN ('admin', 'super_admin')
    )
  );

-- Backend service_role can insert error logs (bypasses RLS)

-- Comments for documentation
COMMENT ON TABLE error_logs IS 'Application error logs for monitoring and debugging';
COMMENT ON COLUMN error_logs.error_type IS 'Category of error: api_error, validation, database, auth, client';
COMMENT ON COLUMN error_logs.severity IS 'Error severity level: debug, info, warn, error, critical';
COMMENT ON COLUMN error_logs.additional_data IS 'JSON object with extra context (request body, query params, etc)';
COMMENT ON COLUMN error_logs.resolved IS 'Whether an admin has reviewed and resolved this error';
