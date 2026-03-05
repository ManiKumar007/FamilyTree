import { Router, Response } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import { GenderEnum, MaritalStatusEnum } from '../models/types';
import { normalizePhone, isValidPhone } from '../utils/phone';
import { detectMergeByPhone, detectConflicts, createMergeRequest } from '../services/mergeService';
import { successResponse, errorResponse, paginatedResponse, ErrorCodes } from '../utils/response';
import { sanitizeObject, PERSON_SANITIZE_FIELDS } from '../utils/sanitize';
import { sendClaimApprovalRequest, sendClaimOutcomeEmail } from '../services/emailService';

export const personsRouter = Router();

// ---------------------------------------------------------------------------
// PUBLIC routes (no auth required — token in URL acts as credential)
// Must be registered BEFORE the authMiddleware use() call.
// ---------------------------------------------------------------------------

/** Helper: apply a claim to the persons record and mark it resolved. */
async function applyClaimToPerson(
  claim: { id: string; person_id: string; claimed_by_user_id: string; claimant_email?: string; profile_updates?: Record<string, any> },
  resolvedStatus: 'approved' | 'auto_approved',
): Promise<void> {
  const allowedFields = [
    'username', 'given_name', 'surname', 'name', 'date_of_birth',
    'occupation', 'community', 'gotra', 'city', 'state',
    'nakshatra', 'rashi', 'native_place', 'ancestral_village',
    'sub_caste', 'kula_devata', 'pravara',
  ];
  const updateData: Record<string, any> = {
    auth_user_id: claim.claimed_by_user_id,
    verified: true,
    ...(claim.claimant_email ? { email: claim.claimant_email } : {}),
  };
  if (claim.profile_updates) {
    for (const field of allowedFields) {
      if (claim.profile_updates[field] != null) updateData[field] = claim.profile_updates[field];
    }
  }
  await supabaseAdmin.from('persons').update(updateData).eq('id', claim.person_id);
  await supabaseAdmin
    .from('pending_claims')
    .update({ status: resolvedStatus, resolved_at: new Date().toISOString() })
    .eq('id', claim.id);
}

/**
 * GET /api/persons/claim-approve/:token
 * Called from the email link — no auth required (token is the credential).
 * Approves the pending claim and redirects to the frontend.
 */
personsRouter.get('/claim-approve/:token', async (req: any, res: Response) => {
  const { token } = req.params;
  const frontendUrl = process.env.FRONTEND_URL || 'https://myfamilytree.app';
  try {
    const { data: claim, error } = await supabaseAdmin
      .from('pending_claims')
      .select('*')
      .eq('approve_token', token)
      .single();

    if (error || !claim) {
      res.status(404).send('<html><body><h2>Link not found or already used.</h2></body></html>');
      return;
    }
    if (claim.status !== 'pending') {
      res.redirect(`${frontendUrl}/tree?claim_already_processed=true`);
      return;
    }

    await applyClaimToPerson(claim, 'approved');

    // Notify claimant
    const { data: personData } = await supabaseAdmin
      .from('persons')
      .select('name')
      .eq('id', claim.person_id)
      .single();
    const personName = personData?.name ?? 'the profile';

    if (claim.claimant_email) {
      await sendClaimOutcomeEmail({
        to: claim.claimant_email,
        personName,
        approved: true,
        frontendUrl,
      }).catch(e => console.warn('Claim outcome email failed:', e));
    }

    // In-app notification to creator
    if (claim.created_by_user_id) {
      try {
        await supabaseAdmin.from('notifications').insert({
          user_id: claim.created_by_user_id,
          type: 'invite_accepted',
          title: 'Profile Claim Approved',
          message: `You approved ${personName}'s profile claim.`,
          data: { person_id: claim.person_id },
        });
      } catch (_) { /* non-critical */ }
    }

    res.redirect(`${frontendUrl}/tree?claim_approved=true`);
  } catch (err) {
    console.error('[claim-approve]', err);
    res.status(500).send('<html><body><h2>Something went wrong. Please open the app.</h2></body></html>');
  }
});

/**
 * GET /api/persons/claim-reject/:token
 * Called from the email link — no auth required (token is the credential).
 * Rejects the pending claim.
 */
personsRouter.get('/claim-reject/:token', async (req: any, res: Response) => {
  const { token } = req.params;
  const frontendUrl = process.env.FRONTEND_URL || 'https://myfamilytree.app';
  try {
    const { data: claim, error } = await supabaseAdmin
      .from('pending_claims')
      .select('*')
      .eq('reject_token', token)
      .single();

    if (error || !claim) {
      res.status(404).send('<html><body><h2>Link not found or already used.</h2></body></html>');
      return;
    }
    if (claim.status !== 'pending') {
      res.redirect(`${frontendUrl}/?claim_already_processed=true`);
      return;
    }

    await supabaseAdmin
      .from('pending_claims')
      .update({ status: 'rejected', resolved_at: new Date().toISOString() })
      .eq('id', claim.id);

    // Notify claimant
    const { data: personData } = await supabaseAdmin
      .from('persons')
      .select('name')
      .eq('id', claim.person_id)
      .single();
    const personName = personData?.name ?? 'the profile';

    if (claim.claimant_email) {
      await sendClaimOutcomeEmail({
        to: claim.claimant_email,
        personName,
        approved: false,
        frontendUrl,
      }).catch(e => console.warn('Claim outcome email failed:', e));
    }

    res.redirect(`${frontendUrl}/?claim_rejected=true`);
  } catch (err) {
    console.error('[claim-reject]', err);
    res.status(500).send('<html><body><h2>Something went wrong. Please open the app.</h2></body></html>');
  }
});

// All authenticated routes from here down require a valid JWT
personsRouter.use(authMiddleware);

// Validation schemas
const usernameSchema = z.string()
  .min(3, 'Username must be at least 3 characters')
  .max(20, 'Username must be at most 20 characters')
  .regex(/^[a-zA-Z][a-zA-Z0-9_]*$/, 'Username must start with a letter and contain only letters, numbers, and underscores');

const createPersonSchema = z.object({
  username: usernameSchema.nullish(),
  name: z.string().min(1).max(200),
  given_name: z.string().min(1).max(100).optional(),
  surname: z.string().max(100).nullish(),
  date_of_birth: z.string().nullish(),
  date_of_death: z.string().nullish(),
  place_of_death: z.string().max(200).nullish(),
  is_alive: z.boolean().nullish().default(true),
  gender: GenderEnum,
  phone: z.string().min(5),
  email: z.string().email().nullish(),
  photo_url: z.string().url().nullish(),
  occupation: z.string().max(200).nullish(),
  community: z.string().max(200).nullish(),
  city: z.string().max(200).nullish(),
  state: z.string().max(200).nullish(),
  marital_status: MaritalStatusEnum.nullish().default('single'),
  wedding_date: z.string().nullish(),
  nakshatra: z.string().max(100).nullish(),
  rashi: z.string().max(100).nullish(),
  native_place: z.string().max(200).nullish(),
  ancestral_village: z.string().max(200).nullish(),
  sub_caste: z.string().max(200).nullish(),
  kula_devata: z.string().max(200).nullish(),
  pravara: z.string().max(200).nullish(),
  gotra: z.string().max(200).nullish(),
  is_profile_public: z.boolean().nullish().default(false),
  auth_user_id: z.string().uuid().nullish(), // Allow linking to auth user for profile setup
  verified: z.boolean().nullish(), // Allow setting verified status
});

const updatePersonSchema = createPersonSchema.partial();

/**
 * POST /api/persons — Create a new person
 */
personsRouter.post('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const parsed = createPersonSchema.parse(req.body);
    const phone = normalizePhone(parsed.phone);

    if (!isValidPhone(phone)) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Invalid phone number format'));
      return;
    }

    // Security: If auth_user_id is provided, it must match the current user
    if (parsed.auth_user_id && parsed.auth_user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'Cannot create profile for another user'));
      return;
    }

    // Sanitize text fields to prevent XSS
    const sanitized = sanitizeObject(parsed, [...PERSON_SANITIZE_FIELDS]);

    // Derive name ↔ given_name/surname:
    // If given_name provided, compute name; otherwise split name into parts.
    let givenName = sanitized.given_name as string | undefined;
    let surname = sanitized.surname as string | null | undefined;
    let fullName = sanitized.name as string;

    if (givenName) {
      // Build full name from parts
      fullName = surname ? `${givenName} ${surname}` : givenName;
    } else {
      // Split full name into parts
      const parts = fullName.trim().split(/\s+/);
      givenName = parts[0];
      surname = parts.length > 1 ? parts.slice(1).join(' ') : null;
    }

    const personData = {
      ...sanitized,
      name: fullName,
      given_name: givenName,
      surname: surname ?? null,
      phone,
      created_by_user_id: req.userId,
      // If auth_user_id is provided (profile setup), use it; otherwise leave null
      auth_user_id: parsed.auth_user_id || null,
      // If verified is provided, use it; otherwise default to false
      verified: parsed.verified !== undefined ? parsed.verified : false,
    };

    const { data, error } = await supabaseAdmin
      .from('persons')
      .insert(personData)
      .select()
      .single();

    if (error) {
      if (error.code === '23505') {
        res.status(409).json(errorResponse(ErrorCodes.CONFLICT, 'A person with this phone number already exists'));
        return;
      }
      throw error;
    }

    // Check for merge candidates (same phone in another tree)
    const mergeCandidate = await detectMergeByPhone(phone, req.userId!);
    let mergeRequest = null;

    if (mergeCandidate) {
      const conflicts = detectConflicts(mergeCandidate, data);
      mergeRequest = await createMergeRequest(
        req.userId!,
        mergeCandidate.id,
        data.id,
        conflicts
      );
    }

    res.status(201).json(successResponse({ person: data, mergeRequest }));
  } catch (err: any) {
    if (err instanceof z.ZodError) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Validation failed', err.errors));
      return;
    }
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, 'An internal error occurred'));
  }
});

/**
 * GET /api/persons/check-duplicates — Check for potential duplicate persons
 * Query params: name (required), phone, date_of_birth, city
 */
personsRouter.get('/check-duplicates', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const name = req.query.name as string;
    if (!name) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Name is required'));
      return;
    }

    const phone = req.query.phone as string | undefined;
    const dateOfBirth = req.query.date_of_birth as string | undefined;
    const city = req.query.city as string | undefined;

    // Build query: search by name similarity
    // Escape ILIKE wildcard characters to prevent pattern injection
    const escapedName = name.replace(/%/g, '\\%').replace(/_/g, '\\_');
    let query = supabaseAdmin
      .from('persons')
      .select('id, name, given_name, surname, phone, date_of_birth, city, gender, photo_url')
      .ilike('name', `%${escapedName}%`)
      .limit(10);

    const { data: nameMatches, error: nameError } = await query;
    if (nameError) throw nameError;

    // Also check by phone if provided
    let phoneMatches: any[] = [];
    if (phone) {
      const normalizedPhone = normalizePhone(phone);
      if (isValidPhone(normalizedPhone)) {
        const { data, error } = await supabaseAdmin
          .from('persons')
          .select('id, name, given_name, surname, phone, date_of_birth, city, gender, photo_url')
          .eq('phone', normalizedPhone)
          .limit(5);
        if (!error && data) phoneMatches = data;
      }
    }

    // Merge and deduplicate results
    const allMatches = [...(nameMatches || [])];
    for (const pm of phoneMatches) {
      if (!allMatches.find(m => m.id === pm.id)) {
        allMatches.push(pm);
      }
    }

    // Calculate match scores
    const matches = allMatches.map(person => {
      let score = 0;
      const nameLower = name.toLowerCase();
      const personNameLower = (person.name || '').toLowerCase();

      // Name similarity (basic)
      if (personNameLower === nameLower) {
        score += 0.5;
      } else if (personNameLower.includes(nameLower) || nameLower.includes(personNameLower)) {
        score += 0.3;
      }

      // Phone match (strong signal)
      if (phone && person.phone) {
        const normalizedPhone = normalizePhone(phone);
        if (person.phone === normalizedPhone) score += 0.4;
      }

      // Date of birth match
      if (dateOfBirth && person.date_of_birth) {
        if (person.date_of_birth === dateOfBirth) score += 0.1;
      }

      // City match
      if (city && person.city) {
        if (person.city.toLowerCase() === city.toLowerCase()) score += 0.05;
      }

      return {
        person,
        matchScore: Math.min(score, 1.0),
        matchReason: score >= 0.8 ? 'Strong match' : score >= 0.5 ? 'Possible match' : 'Weak match',
      };
    });

    // Filter out very weak matches and sort by score
    const filtered = matches
      .filter(m => m.matchScore > 0.2)
      .sort((a, b) => b.matchScore - a.matchScore);

    res.json(successResponse({ matches: filtered }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, 'An internal error occurred'));
  }
});

/**
 * POST /api/persons/check-phone-claim — Check if a phone number has existing 
 * unclaimed profiles that the current user can claim.
 * Returns matching persons that were added by other users and have no auth_user_id.
 */
personsRouter.post('/check-phone-claim', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { phone } = req.body;
    if (!phone) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Phone number is required'));
      return;
    }

    const normalizedPhone = normalizePhone(phone);
    if (!isValidPhone(normalizedPhone)) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Invalid phone number format'));
      return;
    }

    // Find persons with this phone number that are:
    // 1. Not created by the current user
    // 2. Not already claimed (no auth_user_id)
    const { data, error } = await supabaseAdmin
      .from('persons')
      .select('*, relationships:relationships!person_id(id, type, related_person_id)')
      .eq('phone', normalizedPhone)
      .is('auth_user_id', null)
      .neq('created_by_user_id', req.userId!);

    if (error) throw error;

    if (!data || data.length === 0) {
      res.json(successResponse({ claimable: false, matches: [] }));
      return;
    }

    // For each match, get the creator's info and relationship count
    const matches = await Promise.all(data.map(async (person: any) => {
      // Get the creator's name
      let creatorName = 'Someone';
      if (person.created_by_user_id) {
        const { data: creator } = await supabaseAdmin
          .from('persons')
          .select('name')
          .eq('auth_user_id', person.created_by_user_id)
          .single();
        if (creator) creatorName = creator.name;
      }

      return {
        person: {
          id: person.id,
          name: person.name,
          given_name: person.given_name,
          surname: person.surname,
          phone: person.phone,
          gender: person.gender,
          date_of_birth: person.date_of_birth,
          city: person.city,
          state: person.state,
          photo_url: person.photo_url,
        },
        addedBy: creatorName,
        relationshipCount: person.relationships?.length ?? 0,
      };
    }));

    res.json(successResponse({ claimable: true, matches }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, 'An internal error occurred'));
  }
});

/**
 * POST /api/persons/claim-profile — Request to claim an existing person profile.
 * Creates a pending_claims record and emails the original tree owner for approval.
 * Auto-approves if an existing pending claim has passed its 7-day expiry.
 */
personsRouter.post('/claim-profile', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { person_id, profile_updates } = req.body;

    if (!person_id) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'person_id is required'));
      return;
    }

    // Check that the current user doesn't already have a profile
    const { data: existingProfile } = await supabaseAdmin
      .from('persons')
      .select('id')
      .eq('auth_user_id', req.userId!)
      .maybeSingle();

    if (existingProfile) {
      res.status(409).json(errorResponse(ErrorCodes.CONFLICT, 'You already have a profile. Use merge instead.'));
      return;
    }

    // Get the person to claim
    const { data: person, error: personError } = await supabaseAdmin
      .from('persons')
      .select('*')
      .eq('id', person_id)
      .single();

    if (personError || !person) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Person not found'));
      return;
    }

    if (person.auth_user_id) {
      res.status(409).json(errorResponse(ErrorCodes.CONFLICT, 'This profile has already been claimed'));
      return;
    }

    // Check for an existing pending claim for this person by this user
    const { data: existingClaim } = await supabaseAdmin
      .from('pending_claims')
      .select('*')
      .eq('person_id', person_id)
      .eq('status', 'pending')
      .maybeSingle();

    if (existingClaim) {
      const isExpired = new Date(existingClaim.expires_at) <= new Date();
      if (!isExpired) {
        // Still within window — tell the user to wait
        res.json(successResponse({
          status: 'pending',
          message: 'Your claim request is awaiting approval from the family tree owner.',
          expires_at: existingClaim.expires_at,
        }));
        return;
      }
      // Expired — auto-approve and immediately link the user
      await applyClaimToPerson(
        { ...existingClaim, profile_updates: profile_updates || existingClaim.profile_updates },
        'auto_approved',
      );
      const { data: updated } = await supabaseAdmin
        .from('persons').select('*').eq('id', person_id).single();
      res.json(successResponse({
        status: 'approved',
        person: updated,
        message: 'Profile claimed! Welcome to your family tree.',
      }));
      return;
    }

    // Create a new pending claim
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    const { data: newClaim, error: insertError } = await supabaseAdmin
      .from('pending_claims')
      .insert({
        person_id,
        claimed_by_user_id: req.userId,
        created_by_user_id: person.created_by_user_id ?? null,
        profile_updates: profile_updates ?? {},
        claimant_email: req.body.email ?? null,
        expires_at: expiresAt.toISOString(),
      })
      .select()
      .single();

    if (insertError) throw insertError;

    // Send approval email to the original tree owner
    try {
      if (person.created_by_user_id) {
        const { data: creatorAuth } = await supabaseAdmin.auth.admin.getUserById(
          person.created_by_user_id,
        );
        const creatorEmail = creatorAuth?.user?.email;
        if (creatorEmail) {
          const backendBase =
            process.env.BACKEND_URL ||
            `https://${(req.headers.host ?? 'api.myfamilytree.app')}`;
          await sendClaimApprovalRequest({
            to: creatorEmail,
            claimantName: profile_updates?.given_name
              ? `${profile_updates.given_name}${profile_updates.surname ? ' ' + profile_updates.surname : ''}`
              : 'Someone',
            personName: person.name,
            approveUrl: `${backendBase}/api/persons/claim-approve/${newClaim.approve_token}`,
            rejectUrl:  `${backendBase}/api/persons/claim-reject/${newClaim.reject_token}`,
            expiresAt,
          });
        }
      }
    } catch (emailErr) {
      console.warn('[claim-profile] Email send failed (non-critical):', emailErr);
    }

    // In-app notification to original creator
    try {
      if (person.created_by_user_id) {
        await supabaseAdmin.from('notifications').insert({
          user_id: person.created_by_user_id,
          type: 'invite_accepted',
          title: 'Profile Claim Request',
          message: `Someone is requesting to claim ${person.name}'s profile. Open the email we sent you to approve or reject.`,
          data: { person_id, pending_claim_id: newClaim.id },
        });
      }
    } catch (notifErr) {
      console.warn('[claim-profile] Notification failed (non-critical):', notifErr);
    }

    res.json(successResponse({
      status: 'pending',
      message: `Your claim request has been sent to ${person.name}'s family tree owner for approval. You'll be notified by email once they respond (auto-approves in 7 days).`,
      expires_at: expiresAt.toISOString(),
    }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, 'An internal error occurred'));
  }
});

/**
 * GET /api/persons/my-pending-claim
 * Returns any pending claim for the current user, auto-approving if expired.
 * Called by the Flutter app on startup / tree load to check claim state.
 */
personsRouter.get('/my-pending-claim', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data: claim } = await supabaseAdmin
      .from('pending_claims')
      .select('*')
      .eq('claimed_by_user_id', req.userId!)
      .eq('status', 'pending')
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (!claim) {
      res.json(successResponse({ hasPendingClaim: false }));
      return;
    }

    const isExpired = new Date(claim.expires_at) <= new Date();
    if (isExpired) {
      await applyClaimToPerson(claim, 'auto_approved');
      const { data: person } = await supabaseAdmin
        .from('persons').select('*').eq('id', claim.person_id).single();
      res.json(successResponse({ hasPendingClaim: false, autoApproved: true, person }));
      return;
    }

    const { data: person } = await supabaseAdmin
      .from('persons')
      .select('id, name, photo_url')
      .eq('id', claim.person_id)
      .single();

    res.json(successResponse({
      hasPendingClaim: true,
      claim: {
        id: claim.id,
        person_id: claim.person_id,
        person_name: person?.name,
        person_photo: person?.photo_url,
        expires_at: claim.expires_at,
        created_at: claim.created_at,
      },
    }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, 'An internal error occurred'));
  }
});

/**
 * GET /api/persons/:id — Get a person by ID
 */
personsRouter.get('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('persons')
      .select('*')
      .eq('id', req.params.id)
      .single();

    if (error || !data) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Person not found'));
      return;
    }

    res.json(successResponse(data));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, 'An internal error occurred'));
  }
});

/**
 * PUT /api/persons/:id — Update a person
 */
personsRouter.put('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    console.log(`📝 PUT /persons/${req.params.id} - Body keys:`, Object.keys(req.body));
    if (req.body.photo_url !== undefined) {
      console.log('📸 photo_url in request body:', req.body.photo_url);
    }

    const parsed = updatePersonSchema.parse(req.body);
    console.log('✅ Zod validation passed. Parsed keys:', Object.keys(parsed));
    if ((parsed as any).photo_url !== undefined) {
      console.log('📸 photo_url after Zod parse:', (parsed as any).photo_url);
    } else {
      console.log('⚠️ photo_url NOT in parsed output');
    }

    // Normalize phone if provided
    if (parsed.phone) {
      parsed.phone = normalizePhone(parsed.phone);
      if (!isValidPhone(parsed.phone)) {
        res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Invalid phone number format'));
        return;
      }
    }

    // Sanitize text fields to prevent XSS
    const sanitized = sanitizeObject(parsed, [...PERSON_SANITIZE_FIELDS]);
    console.log('🧹 After sanitize. photo_url:', (sanitized as any).photo_url);

    // Keep name ↔ given_name/surname in sync on updates
    if (sanitized.given_name || sanitized.surname !== undefined) {
      const gn = sanitized.given_name as string | undefined;
      const sn = sanitized.surname as string | null | undefined;
      if (gn) {
        sanitized.name = sn ? `${gn} ${sn}` : gn;
      }
    } else if (sanitized.name) {
      const parts = (sanitized.name as string).trim().split(/\s+/);
      sanitized.given_name = parts[0];
      sanitized.surname = parts.length > 1 ? parts.slice(1).join(' ') : null;
    }

    // Verify ownership
    const { data: existing } = await supabaseAdmin
      .from('persons')
      .select('created_by_user_id, auth_user_id')
      .eq('id', req.params.id)
      .single();

    if (!existing) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Person not found'));
      return;
    }

    if (existing.created_by_user_id !== req.userId && existing.auth_user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'You can only edit persons you created or your own profile'));
      return;
    }

    const { data, error } = await supabaseAdmin
      .from('persons')
      .update(sanitized)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) {
      console.error('❌ DB update error:', error);
      throw error;
    }
    console.log('✅ Person updated. photo_url in DB response:', data?.photo_url);

    res.json(successResponse(data));
  } catch (err: any) {
    if (err instanceof z.ZodError) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Validation failed', err.errors));
      return;
    }
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, 'An internal error occurred'));
  }
});

/**
 * DELETE /api/persons/:id — Delete a person (and cascade-delete relationships)
 */
personsRouter.delete('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    // Verify ownership before deletion
    const { data: existing } = await supabaseAdmin
      .from('persons')
      .select('created_by_user_id, auth_user_id, name')
      .eq('id', req.params.id)
      .single();

    if (!existing) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Person not found'));
      return;
    }

    if (existing.created_by_user_id !== req.userId && existing.auth_user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'You can only delete persons you created or your own profile'));
      return;
    }

    // Delete the person — relationships auto-cascade (ON DELETE CASCADE)
    const { error } = await supabaseAdmin
      .from('persons')
      .delete()
      .eq('id', req.params.id);

    if (error) throw error;

    res.json(successResponse({ message: `Person '${existing.name}' deleted successfully` }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, 'An internal error occurred'));
  }
});

/**
 * GET /api/persons/check-username/:username — Check if a username is available
 */
personsRouter.get('/check-username/:username', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const username = req.params.username.toLowerCase();

    // Validate format
    const parsed = usernameSchema.safeParse(req.params.username);
    if (!parsed.success) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, parsed.error.errors[0].message));
      return;
    }

    const { data } = await supabaseAdmin
      .from('persons')
      .select('id')
      .ilike('username', username)
      .maybeSingle();

    res.json(successResponse({ available: !data }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, 'An internal error occurred'));
  }
});

/**
 * GET /api/persons/by-username/:username — Find a person by username
 */
personsRouter.get('/by-username/:username', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('persons')
      .select('*')
      .ilike('username', req.params.username)
      .single();

    if (error || !data) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Person not found'));
      return;
    }

    res.json(successResponse(data));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, 'An internal error occurred'));
  }
});

/**
 * GET /api/persons/by-phone/:phone — Find a person by phone number
 */
personsRouter.get('/by-phone/:phone', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const phone = normalizePhone(req.params.phone);

    const { data, error } = await supabaseAdmin
      .from('persons')
      .select('*')
      .eq('phone', phone)
      .single();

    if (error || !data) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Person not found'));
      return;
    }

    res.json(successResponse(data));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, 'An internal error occurred'));
  }
});

/**
 * GET /api/persons/me/profile — Get the current user's person record
 */
personsRouter.get('/me/profile', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('persons')
      .select('*')
      .eq('auth_user_id', req.userId)
      .single();

    if (error || !data) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Profile not found. Complete profile setup first.'));
      return;
    }

    res.json(successResponse(data));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, 'An internal error occurred'));
  }
});
