-- Analytics Helper Functions for Admin Panel
-- This migration creates utility functions for generating analytics data

-- Function: Get user growth by day
-- Returns number of new users per day for the last N days
CREATE OR REPLACE FUNCTION get_user_growth_by_day(days_back integer DEFAULT 30)
RETURNS TABLE (
  date text,
  count bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    to_char(date_trunc('day', created_at), 'YYYY-MM-DD') as date,
    COUNT(*) as count
  FROM user_metadata
  WHERE created_at >= NOW() - (days_back || ' days')::interval
  GROUP BY date_trunc('day', created_at)
  ORDER BY date_trunc('day', created_at) ASC;
END;
$$ LANGUAGE plpgsql;

-- Function: Get tree size distribution
-- Returns distribution of users by family tree size (number of people)
CREATE OR REPLACE FUNCTION get_tree_size_distribution()
RETURNS TABLE (
  size_range text,
  user_count bigint
) AS $$
BEGIN
  RETURN QUERY
  WITH user_tree_sizes AS (
    SELECT
      created_by_user_id as user_id,
      COUNT(*) as persons_count
    FROM persons
    WHERE created_by_user_id IS NOT NULL
    GROUP BY created_by_user_id
  )
  SELECT
    CASE
      WHEN persons_count = 1 THEN '1 person'
      WHEN persons_count BETWEEN 2 AND 5 THEN '2-5 people'
      WHEN persons_count BETWEEN 6 AND 10 THEN '6-10 people'
      WHEN persons_count BETWEEN 11 AND 20 THEN '11-20 people'
      WHEN persons_count BETWEEN 21 AND 50 THEN '21-50 people'
      WHEN persons_count BETWEEN 51 AND 100 THEN '51-100 people'
      WHEN persons_count > 100 THEN '100+ people'
      ELSE 'Unknown'
    END as size_range,
    COUNT(*) as user_count
  FROM user_tree_sizes
  GROUP BY size_range
  ORDER BY
    CASE size_range
      WHEN '1 person' THEN 1
      WHEN '2-5 people' THEN 2
      WHEN '6-10 people' THEN 3
      WHEN '11-20 people' THEN 4
      WHEN '21-50 people' THEN 5
      WHEN '51-100 people' THEN 6
      WHEN '100+ people' THEN 7
      ELSE 99
    END;
END;
$$ LANGUAGE plpgsql;

-- Function: Get admin activity statistics
-- Returns summary of admin actions in the last N days
CREATE OR REPLACE FUNCTION get_admin_activity_summary(days_back integer DEFAULT 7)
RETURNS TABLE (
  admin_user_id uuid,
  action_count bigint,
  latest_action timestamp with time zone
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    a.admin_user_id,
    COUNT(*) as action_count,
    MAX(a.timestamp) as latest_action
  FROM audit_logs a
  WHERE a.timestamp >= NOW() - (days_back || ' days')::interval
  GROUP BY a.admin_user_id
  ORDER BY action_count DESC;
END;
$$ LANGUAGE plpgsql;

-- Function: Get recent errors with details
-- Returns recent errors with pagination support
CREATE OR REPLACE FUNCTION get_recent_errors(
  page_size integer DEFAULT 50,
  page_number integer DEFAULT 1,
  filter_type text DEFAULT NULL,
  filter_severity text DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  error_timestamp timestamp with time zone,
  error_type text,
  severity text,
  status_code integer,
  message text,
  resolved boolean,
  resolved_at timestamp with time zone
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    e.id,
    e.timestamp as error_timestamp,
    e.error_type,
    e.severity,
    e.status_code,
    e.message,
    e.resolved,
    e.resolved_at
  FROM error_logs e
  WHERE
    (filter_type IS NULL OR e.error_type = filter_type)
    AND (filter_severity IS NULL OR e.severity = filter_severity)
  ORDER BY e.timestamp DESC
  LIMIT page_size
  OFFSET (page_number - 1) * page_size;
END;
$$ LANGUAGE plpgsql;

-- Add index for faster analytics queries
CREATE INDEX IF NOT EXISTS idx_user_metadata_created_at ON user_metadata(created_at);
CREATE INDEX IF NOT EXISTS idx_persons_created_by_created_at ON persons(created_by_user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_admin_user_timestamp ON audit_logs(admin_user_id, timestamp);
