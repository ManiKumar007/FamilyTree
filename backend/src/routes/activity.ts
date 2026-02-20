import { Router, Response } from 'express';
import { supabaseAdmin } from '../config/supabase';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import { successResponse, errorResponse, paginatedResponse, ErrorCodes } from '../utils/response';

export const activityRouter = Router();

// All routes require authentication
activityRouter.use(authMiddleware);

/**
 * GET /api/activity — Get activity feed for the current user's family tree
 */
activityRouter.get('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);
    const offset = (page - 1) * limit;

    // Get all persons created by the current user (their tree)
    const { data: userPersons } = await supabaseAdmin
      .from('persons')
      .select('id')
      .eq('created_by_user_id', req.userId!);

    const personIds = userPersons?.map(p => p.id) || [];

    if (personIds.length === 0) {
      res.json(paginatedResponse([], 0, page, limit));
      return;
    }

    // Get activity related to these persons
    const { data, error, count } = await supabaseAdmin
      .from('activity_feed')
      .select('*, person:persons(name, photo_url), actor:auth.users!activity_feed_actor_user_id_fkey(email)', { count: 'exact' })
      .in('person_id', personIds)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;

    res.json(paginatedResponse(data || [], count || 0, page, limit));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * GET /api/activity/person/:personId — Get activity for a specific person
 */
activityRouter.get('/person/:personId', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('activity_feed')
      .select('*, person:persons(name, photo_url), actor:auth.users!activity_feed_actor_user_id_fkey(email)')
      .eq('person_id', req.params.personId)
      .order('created_at', { ascending: false })
      .limit(50);

    if (error) throw error;

    res.json(successResponse(data || []));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});
