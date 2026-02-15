import { supabaseAdmin } from '../config/supabase';
import { Person, MergeRequest } from '../models/types';

/**
 * MergeService: handles tree merge detection and execution.
 * MVP uses phone number matching only.
 */

/**
 * Check if a phone number already exists in the database
 * (in a different user's tree). Returns the matching person if found.
 */
export async function detectMergeByPhone(
  phone: string,
  excludeCreatedBy: string
): Promise<Person | null> {
  const { data, error } = await supabaseAdmin
    .from('persons')
    .select('*')
    .eq('phone', phone)
    .neq('created_by_user_id', excludeCreatedBy)
    .limit(1)
    .single();

  if (error || !data) return null;
  return data as Person;
}

/**
 * Compare two person records and detect field conflicts.
 */
export function detectConflicts(
  target: Person,
  matched: Person
): Record<string, { target: any; matched: any }> {
  const conflicts: Record<string, { target: any; matched: any }> = {};
  const fieldsToCompare: (keyof Person)[] = [
    'name',
    'date_of_birth',
    'gender',
    'occupation',
    'community',
    'city',
    'state',
    'marital_status',
  ];

  for (const field of fieldsToCompare) {
    const targetVal = target[field];
    const matchedVal = matched[field];

    // Only flag as conflict if both have values and they differ
    if (targetVal && matchedVal && targetVal !== matchedVal) {
      conflicts[field] = { target: targetVal, matched: matchedVal };
    }
  }

  return conflicts;
}

/**
 * Create a merge request between two persons.
 */
export async function createMergeRequest(
  requesterUserId: string,
  targetPersonId: string,
  matchedPersonId: string,
  fieldConflicts: Record<string, any>
): Promise<MergeRequest> {
  const { data, error } = await supabaseAdmin
    .from('merge_requests')
    .insert({
      requester_user_id: requesterUserId,
      target_person_id: targetPersonId,
      matched_person_id: matchedPersonId,
      field_conflicts: fieldConflicts,
      status: 'PENDING',
    })
    .select()
    .single();

  if (error) throw new Error(`Failed to create merge request: ${error.message}`);
  return data as MergeRequest;
}

/**
 * Approve a merge request: merge the two person records and link trees.
 * - The target person is kept as the canonical record
 * - All relationships from matched person are transferred to target
 * - The matched person record is deleted
 */
export async function approveMerge(
  mergeRequestId: string,
  resolvedByUserId: string,
  resolvedFields?: Record<string, any>
): Promise<void> {
  // Get the merge request
  const { data: mr, error: mrError } = await supabaseAdmin
    .from('merge_requests')
    .select('*')
    .eq('id', mergeRequestId)
    .single();

  if (mrError || !mr) throw new Error('Merge request not found');

  const mergeRequest = mr as MergeRequest;

  if (mergeRequest.status !== 'PENDING') {
    throw new Error('Merge request is not pending');
  }

  const targetId = mergeRequest.target_person_id;
  const matchedId = mergeRequest.matched_person_id;

  // 1. If resolvedFields provided, update the target person
  if (resolvedFields && Object.keys(resolvedFields).length > 0) {
    await supabaseAdmin
      .from('persons')
      .update(resolvedFields)
      .eq('id', targetId);
  }

  // 2. Transfer all relationships from matched to target
  // Update person_id references
  await supabaseAdmin
    .from('relationships')
    .update({ person_id: targetId })
    .eq('person_id', matchedId);

  // Update related_person_id references
  await supabaseAdmin
    .from('relationships')
    .update({ related_person_id: targetId })
    .eq('related_person_id', matchedId);

  // 3. Transfer auth_user_id if matched person was verified
  const { data: matchedPerson } = await supabaseAdmin
    .from('persons')
    .select('auth_user_id, verified')
    .eq('id', matchedId)
    .single();

  if (matchedPerson?.auth_user_id) {
    await supabaseAdmin
      .from('persons')
      .update({
        auth_user_id: matchedPerson.auth_user_id,
        verified: true,
      })
      .eq('id', targetId);
  }

  // 4. Delete the matched (duplicate) person record
  await supabaseAdmin
    .from('persons')
    .delete()
    .eq('id', matchedId);

  // 5. Update merge request status
  await supabaseAdmin
    .from('merge_requests')
    .update({
      status: 'APPROVED',
      resolved_by_user_id: resolvedByUserId,
      resolved_at: new Date().toISOString(),
    })
    .eq('id', mergeRequestId);
}

/**
 * Reject a merge request.
 */
export async function rejectMerge(
  mergeRequestId: string,
  resolvedByUserId: string
): Promise<void> {
  await supabaseAdmin
    .from('merge_requests')
    .update({
      status: 'REJECTED',
      resolved_by_user_id: resolvedByUserId,
      resolved_at: new Date().toISOString(),
    })
    .eq('id', mergeRequestId);
}

/**
 * Get pending merge requests for a user (both as requester and as target).
 */
export async function getPendingMergeRequests(userId: string): Promise<MergeRequest[]> {
  // Get person IDs created by or belonging to this user
  const { data: userPersons } = await supabaseAdmin
    .from('persons')
    .select('id')
    .or(`created_by_user_id.eq.${userId},auth_user_id.eq.${userId}`);

  if (!userPersons || userPersons.length === 0) return [];

  const personIds = userPersons.map((p: any) => p.id);

  const { data, error } = await supabaseAdmin
    .from('merge_requests')
    .select('*')
    .eq('status', 'PENDING')
    .or(`requester_user_id.eq.${userId},target_person_id.in.(${personIds.join(',')})`);

  if (error || !data) return [];
  return data as MergeRequest[];
}
