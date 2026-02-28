import { Router, Response } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import { GenderEnum, MaritalStatusEnum } from '../models/types';
import { normalizePhone, isValidPhone } from '../utils/phone';
import { detectMergeByPhone, detectConflicts, createMergeRequest } from '../services/mergeService';
import { successResponse, errorResponse, paginatedResponse, ErrorCodes } from '../utils/response';
import { sanitizeObject, PERSON_SANITIZE_FIELDS } from '../utils/sanitize';

export const personsRouter = Router();

// All routes require authentication
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
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
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
    let query = supabaseAdmin
      .from('persons')
      .select('id, name, given_name, surname, phone, date_of_birth, city, gender, photo_url')
      .ilike('name', `%${name}%`)
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
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
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
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * POST /api/persons/claim-profile — Claim an existing person profile.
 * Links the current user's auth_user_id to the person record and 
 * optionally updates fields the user provided.
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

    // Verify the person is claimable (no auth_user_id yet)
    if (person.auth_user_id) {
      res.status(409).json(errorResponse(ErrorCodes.CONFLICT, 'This profile has already been claimed'));
      return;
    }

    // Build update data: link auth user + apply any profile updates
    const updateData: Record<string, any> = {
      auth_user_id: req.userId,
      verified: true,
      email: req.body.email || person.email,
    };

    // Apply optional profile updates (user's input wins for provided fields)
    if (profile_updates) {
      const allowedFields = [
        'username', 'given_name', 'surname', 'name', 'date_of_birth',
        'occupation', 'community', 'gotra', 'city', 'state',
        'nakshatra', 'rashi', 'native_place', 'ancestral_village',
        'sub_caste', 'kula_devata', 'pravara',
      ];
      for (const field of allowedFields) {
        if (profile_updates[field] !== undefined && profile_updates[field] !== null) {
          updateData[field] = profile_updates[field];
        }
      }
    }

    // Update the person record
    const { data: updated, error: updateError } = await supabaseAdmin
      .from('persons')
      .update(updateData)
      .eq('id', person_id)
      .select()
      .single();

    if (updateError) throw updateError;

    // Notify the original creator that the profile was claimed
    try {
      await supabaseAdmin
        .from('notifications')
        .insert({
          user_id: person.created_by_user_id,
          type: 'invite_accepted',
          title: 'Profile Claimed',
          message: `${updated.name} has claimed their profile in your family tree!`,
          data: { person_id: updated.id, claimed_by: req.userId },
        });
    } catch (notifError) {
      // Non-critical — don't fail the claim if notification fails
      console.warn('Failed to send claim notification:', notifError);
    }

    res.json(successResponse({ 
      person: updated, 
      message: 'Profile claimed successfully! You are now part of this family tree.' 
    }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
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
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
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
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
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
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
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
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
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
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
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
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
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
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});
