import { supabaseAdmin } from '../config/supabase';

/**
 * Authorization Service
 * 
 * Handles authorization checks for user access to family tree data.
 * All functions use the database RPC functions with service_role key.
 */

/**
 * Check if a user can access a specific person record.
 * 
 * @param authUserId - The authenticated user's ID (from auth.users)
 * @param targetPersonId - The person record ID to check
 * @returns true if user can access, false otherwise
 */
export async function canUserAccessPerson(
  authUserId: string,
  targetPersonId: string
): Promise<boolean> {
  try {
    const { data, error } = await supabaseAdmin.rpc('can_user_access_person', {
      auth_user_id: authUserId,
      target_person_id: targetPersonId,
    });

    if (error) {
      console.error('Error checking person access:', error);
      return false;
    }

    return data === true;
  } catch (err) {
    console.error('Exception checking person access:', err);
    return false;
  }
}

/**
 * Check if two persons are connected in the family tree.
 * 
 * @param userPersonId - The person ID of the requesting user
 * @param targetPersonId - The person ID to check connection to
 * @returns true if connected, false otherwise
 */
export async function arePersonsConnected(
  userPersonId: string,
  targetPersonId: string
): Promise<boolean> {
  try {
    const { data, error } = await supabaseAdmin.rpc('is_person_connected', {
      user_person_id: userPersonId,
      target_person_id: targetPersonId,
    });

    if (error) {
      console.error('Error checking person connection:', error);
      return false;
    }

    return data === true;
  } catch (err) {
    console.error('Exception checking person connection:', err);
    return false;
  }
}

/**
 * Get person record ID for an authenticated user.
 * 
 * @param authUserId - The authenticated user's ID (from auth.users)
 * @returns person UUID or null if not found
 */
export async function getPersonIdByAuthUser(
  authUserId: string
): Promise<string | null> {
  try {
    const { data, error } = await supabaseAdmin
      .from('persons')
      .select('id')
      .eq('auth_user_id', authUserId)
      .maybeSingle();

    if (error || !data) {
      return null;
    }

    return data.id;
  } catch (err) {
    console.error('Exception getting person ID:', err);
    return null;
  }
}

/**
 * Verify that a user can access a tree rooted at a specific person.
 * 
 * @param authUserId - The authenticated user's ID
 * @param rootPersonId - The root person ID of the tree
 * @returns true if user can access the tree, false otherwise
 */
export async function canUserAccessTree(
  authUserId: string,
  rootPersonId: string
): Promise<boolean> {
  // Same as checking person access
  return canUserAccessPerson(authUserId, rootPersonId);
}
