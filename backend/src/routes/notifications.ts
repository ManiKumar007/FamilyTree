import { Router, Response } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import { NotificationTypeEnum } from '../models/types';
import { successResponse, errorResponse, paginatedResponse, ErrorCodes } from '../utils/response';

export const notificationsRouter = Router();

// All routes require authentication
notificationsRouter.use(authMiddleware);

/**
 * GET /api/notifications — Get all notifications for the current user
 */
notificationsRouter.get('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);
    const offset = (page - 1) * limit;
    const unreadOnly = req.query.unread_only === 'true';

    let query = supabaseAdmin
      .from('notifications')
      .select('*', { count: 'exact' })
      .eq('user_id', req.userId!)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (unreadOnly) {
      query = query.eq('is_read', false);
    }

    const { data, error, count } = await query;

    if (error) throw error;

    res.json(paginatedResponse(data || [], count || 0, page, limit));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * GET /api/notifications/unread-count — Get count of unread notifications
 */
notificationsRouter.get('/unread-count', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { count } = await supabaseAdmin
      .from('notifications')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', req.userId!)
      .eq('is_read', false);

    res.json(successResponse({ count: count || 0 }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * PUT /api/notifications/:id/read — Mark a notification as read
 */
notificationsRouter.put('/:id/read', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data: existing } = await supabaseAdmin
      .from('notifications')
      .select('user_id')
      .eq('id', req.params.id)
      .single();

    if (!existing) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Notification not found'));
      return;
    }

    if (existing.user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'You can only mark your own notifications as read'));
      return;
    }

    const { data, error } = await supabaseAdmin
      .from('notifications')
      .update({ is_read: true })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    res.json(successResponse(data));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * PUT /api/notifications/mark-all-read — Mark all notifications as read
 */
notificationsRouter.put('/mark-all-read', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('notifications')
      .update({ is_read: true })
      .eq('user_id', req.userId!)
      .eq('is_read', false)
      .select();

    if (error) throw error;

    res.json(successResponse({ message: `Marked ${data?.length || 0} notifications as read` }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * DELETE /api/notifications/:id — Delete a notification
 */
notificationsRouter.delete('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data: existing } = await supabaseAdmin
      .from('notifications')
      .select('user_id')
      .eq('id', req.params.id)
      .single();

    if (!existing) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Notification not found'));
      return;
    }

    if (existing.user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'You can only delete your own notifications'));
      return;
    }

    const { error } = await supabaseAdmin
      .from('notifications')
      .delete()
      .eq('id', req.params.id);

    if (error) throw error;

    res.json(successResponse({ message: 'Notification deleted successfully' }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * POST /api/notifications — Create a notification (admin or system use)
 */
notificationsRouter.post('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const schema = z.object({
      user_id: z.string().uuid(),
      notification_type: NotificationTypeEnum,
      title: z.string().min(1).max(200),
      message: z.string().min(1),
      related_person_id: z.string().uuid().optional(),
      related_post_id: z.string().uuid().optional(),
    });

    const parsed = schema.parse(req.body);

    const { data, error } = await supabaseAdmin
      .from('notifications')
      .insert(parsed)
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
