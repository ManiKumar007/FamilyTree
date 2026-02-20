import { Router, Response } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import { CalendarEventTypeEnum } from '../models/types';
import { successResponse, errorResponse, ErrorCodes } from '../utils/response';
import { sanitizeObject } from '../utils/sanitize';

export const calendarRouter = Router();

// All routes require authentication
calendarRouter.use(authMiddleware);

// Validation schemas
const createEventSchema = z.object({
  title: z.string().min(1).max(200),
  event_type: CalendarEventTypeEnum,
  event_date: z.string(),
  description: z.string().optional(),
  location: z.string().max(200).optional(),
  related_person_id: z.string().uuid().optional(),
  all_day: z.boolean().optional(),
  recurrence_rule: z.string().optional(),
});

const updateEventSchema = createEventSchema.partial();

/**
 * POST /api/calendar/events — Create a new family event
 */
calendarRouter.post('/events', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const parsed = createEventSchema.parse(req.body);

    const sanitized = sanitizeObject(parsed, ['title', 'description', 'location']);

    const eventData = {
      ...sanitized,
      created_by_user_id: req.userId,
    };

    const { data, error } = await supabaseAdmin
      .from('family_events')
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
 * GET /api/calendar/events — Get all family events
 */
calendarRouter.get('/events', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const startDate = req.query.start_date as string;
    const endDate = req.query.end_date as string;
    const eventType = req.query.event_type as string;

    let query = supabaseAdmin
      .from('family_events')
      .select('*, person:persons(name, photo_url)')
      .order('event_date', { ascending: true });

    if (startDate) {
      query = query.gte('event_date', startDate);
    }

    if (endDate) {
      query = query.lte('event_date', endDate);
    }

    if (eventType) {
      query = query.eq('event_type', eventType);
    }

    const { data, error } = await query;

    if (error) throw error;

    res.json(successResponse(data || []));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * GET /api/calendar/events/:id — Get a single event
 */
calendarRouter.get('/events/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('family_events')
      .select('*, person:persons(name, photo_url)')
      .eq('id', req.params.id)
      .single();

    if (error || !data) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Event not found'));
      return;
    }

    res.json(successResponse(data));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * PUT /api/calendar/events/:id — Update an event
 */
calendarRouter.put('/events/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const parsed = updateEventSchema.parse(req.body);

    // Verify ownership
    const { data: existing } = await supabaseAdmin
      .from('family_events')
      .select('created_by_user_id')
      .eq('id', req.params.id)
      .single();

    if (!existing) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Event not found'));
      return;
    }

    if (existing.created_by_user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'You can only edit events you created'));
      return;
    }

    const sanitized = sanitizeObject(parsed, ['title', 'description', 'location']);

    const { data, error } = await supabaseAdmin
      .from('family_events')
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
 * DELETE /api/calendar/events/:id — Delete an event
 */
calendarRouter.delete('/events/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data: existing } = await supabaseAdmin
      .from('family_events')
      .select('created_by_user_id, title')
      .eq('id', req.params.id)
      .single();

    if (!existing) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Event not found'));
      return;
    }

    if (existing.created_by_user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'You can only delete events you created'));
      return;
    }

    const { error } = await supabaseAdmin
      .from('family_events')
      .delete()
      .eq('id', req.params.id);

    if (error) throw error;

    res.json(successResponse({ message: `Event '${existing.title}' deleted successfully` }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * GET /api/calendar/upcoming — Get upcoming events
 */
calendarRouter.get('/upcoming', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const limit = Math.min(parseInt(req.query.limit as string) || 10, 50);
    const today = new Date().toISOString().split('T')[0];

    const { data, error } = await supabaseAdmin
      .from('family_events')
      .select('*, person:persons(name, photo_url)')
      .gte('event_date', today)
      .order('event_date', { ascending: true })
      .limit(limit);

    if (error) throw error;

    res.json(successResponse(data || []));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});
