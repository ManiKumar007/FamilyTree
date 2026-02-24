-- ============================================
-- Authorization Helper Functions
-- ============================================

/**
 * Check if two persons are connected in the family tree.
 * Uses recursive CTE to traverse relationships bidirectionally.
 * 
 * @param user_person_id - The person ID of the requesting user
 * @param target_person_id - The person ID to check access for
 * @returns true if connected, false otherwise
 */
CREATE OR REPLACE FUNCTION is_person_connected(
  user_person_id UUID,
  target_person_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  is_connected BOOLEAN;
BEGIN
  -- Same person = always connected
  IF user_person_id = target_person_id THEN
    RETURN TRUE;
  END IF;

  -- Check if target_person_id is reachable from user_person_id via relationships
  WITH RECURSIVE connected AS (
    -- Start from the user's person record
    SELECT id FROM persons WHERE id = user_person_id
    
    UNION
    
    -- Traverse relationships bidirectionally
    SELECT DISTINCT r.related_person_id
    FROM relationships r
    JOIN connected c ON r.person_id = c.id
    
    UNION
    
    -- Also traverse inverse relationships (person can be on either side)
    SELECT DISTINCT r.person_id
    FROM relationships r
    JOIN connected c ON r.related_person_id = c.id
  )
  SELECT EXISTS(
    SELECT 1 FROM connected WHERE id = target_person_id
  ) INTO is_connected;

  RETURN is_connected;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

/**
 * Get the person ID for an authenticated user.
 * 
 * @param auth_user_id - The auth.users ID
 * @returns person UUID or NULL if not found
 */
CREATE OR REPLACE FUNCTION get_person_id_by_auth_user(
  auth_user_id UUID
)
RETURNS UUID AS $$
DECLARE
  person_id UUID;
BEGIN
  SELECT id INTO person_id
  FROM persons
  WHERE persons.auth_user_id = get_person_id_by_auth_user.auth_user_id
  LIMIT 1;

  RETURN person_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

/**
 * Check if a user can access a specific person.
 * Combines person lookup with connection check.
 * 
 * @param auth_user_id - The auth.users ID of the requesting user
 * @param target_person_id - The person ID to check access for
 * @returns true if user can access, false otherwise
 */
CREATE OR REPLACE FUNCTION can_user_access_person(
  auth_user_id UUID,
  target_person_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  user_person_id UUID;
  has_access BOOLEAN;
BEGIN
  -- Get the person record for this auth user
  SELECT id INTO user_person_id
  FROM persons
  WHERE persons.auth_user_id = can_user_access_person.auth_user_id
  LIMIT 1;

  -- If user has no person record, deny access
  IF user_person_id IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Check if they're connected in the family tree
  SELECT is_person_connected(user_person_id, target_person_id) INTO has_access;

  RETURN has_access;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comments for documentation
COMMENT ON FUNCTION is_person_connected IS 'Check if two persons are connected in the family tree via relationships';
COMMENT ON FUNCTION get_person_id_by_auth_user IS 'Get person record ID for an authenticated user';
COMMENT ON FUNCTION can_user_access_person IS 'Check if an authenticated user can access a specific person record';
