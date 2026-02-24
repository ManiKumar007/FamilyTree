import { Router, Response } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import { LifeEventTypeEnum } from '../models/types';
import { successResponse, errorResponse, ErrorCodes } from '../utils/response';
import { sanitizeObject } from '../utils/sanitize';

export const lifeEventsRouter = Router();

// All routes require authentication
lifeEventsRouter.use(authMiddleware);

// Validation schemas
const createLifeEventSchema = z.object({
  person_id: z.string().uuid(),
  event_type: LifeEventTypeEnum,
  title: z.string().min(1).max(200),
  description: z.string().optional(),
  event_date: z.string().optional(), // ISO date string
  event_place: z.string().max(200).optional(),
  photo_url: z.string().url().optional(),
  metadata: z.record(z.any()).optional(),
});

const updateLifeEventSchema = createLifeEventSchema.partial().omit({ person_id: true });

/**
 * POST /api/life-events — Create a new life event
 */
lifeEventsRouter.post('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const parsed = createLifeEventSchema.parse(req.body);

    // Verify person exists and user has access
    const { data: person } = await supabaseAdmin
      .from('persons')
      .select('created_by_user_id, auth_user_id')
      .eq('id', parsed.person_id)
      .single();

    if (!person) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Person not found'));
      return;
    }

    if (person.created_by_user_id !== req.userId && person.auth_user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'You can only add events to persons you created or your own profile'));
      return;
    }

    const sanitized = sanitizeObject(parsed, ['title', 'description', 'event_place']);

    const eventData = {
      ...sanitized,
      created_by_user_id: req.userId,
    };

    const { data, error } = await supabaseAdmin
      .from('life_events')
      .insert(eventData)
      .select()
      .single();

    if (error) throw error;

    res.status(201).json(successResponse(data));
  } catch (err: any) {
    if (err instanceof z.ZodError) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Validation failed', err.errors));
      return;
    }
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * GET /api/life-events/person/:personId — Get all life events for a person
 */
lifeEventsRouter.get('/person/:personId', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('life_events')
      .select('*')
      .eq('person_id', req.params.personId)
      .order('event_date', { ascending: true });

    if (error) throw error;

    res.json(successResponse(data || []));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * GET /api/life-events/:id — Get a single life event
 */
lifeEventsRouter.get('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('life_events')
      .select('*')
      .eq('id', req.params.id)
      .single();

    if (error || !data) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Life event not found'));
      return;
    }

    res.json(successResponse(data));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * PUT /api/life-events/:id — Update a life event
 */
lifeEventsRouter.put('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const parsed = updateLifeEventSchema.parse(req.body);

    // Verify ownership
    const { data: existing } = await supabaseAdmin
      .from('life_events')
      .select('created_by_user_id')
      .eq('id', req.params.id)
      .single();

    if (!existing) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Life event not found'));
      return;
    }

    if (existing.created_by_user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'You can only edit life events you created'));
      return;
    }

    const sanitized = sanitizeObject(parsed, ['title', 'description', 'event_place']);

    const { data, error } = await supabaseAdmin
      .from('life_events')
      .update(sanitized)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

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
 * DELETE /api/life-events/:id — Delete a life event
 */
lifeEventsRouter.delete('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data: existing } = await supabaseAdmin
      .from('life_events')
      .select('created_by_user_id, event_type')
      .eq('id', req.params.id)
      .single();

    if (!existing) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Life event not found'));
      return;
    }

    if (existing.created_by_user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'You can only delete life events you created'));
      return;
    }

    const { error } = await supabaseAdmin
      .from('life_events')
      .delete()
      .eq('id', req.params.id);

    if (error) throw error;

    res.json(successResponse({ message: `Life event '${existing.event_type}' deleted successfully` }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});
