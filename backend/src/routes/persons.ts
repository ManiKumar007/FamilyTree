import { Router, Response } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import { GenderEnum, MaritalStatusEnum } from '../models/types';
import { normalizePhone, isValidPhone } from '../utils/phone';
import { detectMergeByPhone, detectConflicts, createMergeRequest } from '../services/mergeService';

export const personsRouter = Router();

// All routes require authentication
personsRouter.use(authMiddleware);

// Validation schemas
const createPersonSchema = z.object({
  name: z.string().min(1).max(200),
  date_of_birth: z.string().optional(),
  gender: GenderEnum,
  phone: z.string().min(5),
  email: z.string().email().optional(),
  photo_url: z.string().url().optional(),
  occupation: z.string().max(200).optional(),
  community: z.string().max(200).optional(),
  city: z.string().max(200).optional(),
  state: z.string().max(200).optional(),
  marital_status: MaritalStatusEnum.optional().default('single'),
  wedding_date: z.string().optional(),
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
      res.status(400).json({ error: 'Invalid phone number format' });
      return;
    }

    const personData = {
      ...parsed,
      phone,
      created_by_user_id: req.userId,
      verified: false,
    };

    const { data, error } = await supabaseAdmin
      .from('persons')
      .insert(personData)
      .select()
      .single();

    if (error) {
      if (error.code === '23505') {
        res.status(409).json({ error: 'A person with this phone number already exists' });
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

    res.status(201).json({
      person: data,
      mergeRequest,
    });
  } catch (err: any) {
    if (err instanceof z.ZodError) {
      res.status(400).json({ error: 'Validation failed', details: err.errors });
      return;
    }
    res.status(500).json({ error: err.message });
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
      res.status(404).json({ error: 'Person not found' });
      return;
    }

    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * PUT /api/persons/:id — Update a person
 */
personsRouter.put('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const parsed = updatePersonSchema.parse(req.body);

    // Normalize phone if provided
    if (parsed.phone) {
      parsed.phone = normalizePhone(parsed.phone);
      if (!isValidPhone(parsed.phone)) {
        res.status(400).json({ error: 'Invalid phone number format' });
        return;
      }
    }

    // Verify ownership
    const { data: existing } = await supabaseAdmin
      .from('persons')
      .select('created_by_user_id, auth_user_id')
      .eq('id', req.params.id)
      .single();

    if (!existing) {
      res.status(404).json({ error: 'Person not found' });
      return;
    }

    if (existing.created_by_user_id !== req.userId && existing.auth_user_id !== req.userId) {
      res.status(403).json({ error: 'You can only edit persons you created or your own profile' });
      return;
    }

    const { data, error } = await supabaseAdmin
      .from('persons')
      .update(parsed)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    res.json(data);
  } catch (err: any) {
    if (err instanceof z.ZodError) {
      res.status(400).json({ error: 'Validation failed', details: err.errors });
      return;
    }
    res.status(500).json({ error: err.message });
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
      res.status(404).json({ error: 'Person not found' });
      return;
    }

    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /api/persons/me — Get the current user's person record
 */
personsRouter.get('/me/profile', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('persons')
      .select('*')
      .eq('auth_user_id', req.userId)
      .single();

    if (error || !data) {
      res.status(404).json({ error: 'Profile not found. Complete profile setup first.' });
      return;
    }

    res.json(data);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});
