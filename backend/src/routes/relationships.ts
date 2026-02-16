import { Router, Response } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import { RelationshipTypeEnum } from '../models/types';
import { successResponse, errorResponse, paginatedResponse, ErrorCodes } from '../utils/response';

export const relationshipsRouter = Router();

relationshipsRouter.use(authMiddleware);

const createRelationshipSchema = z.object({
  person_id: z.string().uuid(),
  related_person_id: z.string().uuid(),
  type: RelationshipTypeEnum,
});

/**
 * POST /api/relationships — Create a relationship between two persons.
 * The inverse relationship is automatically created by a database trigger.
 */
relationshipsRouter.post('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const parsed = createRelationshipSchema.parse(req.body);

    if (parsed.person_id === parsed.related_person_id) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Cannot create a relationship with oneself'));
      return;
    }

    // Verify both persons exist
    const { data: persons, error: pError } = await supabaseAdmin
      .from('persons')
      .select('id')
      .in('id', [parsed.person_id, parsed.related_person_id]);

    if (pError || !persons || persons.length !== 2) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'One or both persons not found'));
      return;
    }

    const { data, error } = await supabaseAdmin
      .from('relationships')
      .insert({
        ...parsed,
        created_by_user_id: req.userId,
      })
      .select()
      .single();

    if (error) {
      if (error.code === '23505') {
        res.status(409).json(errorResponse(ErrorCodes.CONFLICT, 'This relationship already exists'));
        return;
      }
      throw error;
    }

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
 * GET /api/relationships/:personId — Get all relationships for a person (paginated)
 *
 * Query params:
 *   page     — Page number (default 1)
 *   pageSize — Items per page (default 20, max 100)
 */
relationshipsRouter.get('/:personId', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const pageSize = Math.min(100, Math.max(1, parseInt(req.query.pageSize as string) || 20));

    const { data, error, count } = await supabaseAdmin
      .from('relationships')
      .select(`
        *,
        related_person:persons!relationships_related_person_id_fkey(id, name, gender, photo_url, date_of_birth)
      `, { count: 'exact' })
      .eq('person_id', req.params.personId)
      .range((page - 1) * pageSize, page * pageSize - 1);

    if (error) throw error;

    res.json(paginatedResponse(data || [], page, pageSize, count || 0));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * DELETE /api/relationships/:id — Delete a relationship (and its inverse)
 */
relationshipsRouter.delete('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    // Get the relationship first
    const { data: rel, error: getError } = await supabaseAdmin
      .from('relationships')
      .select('*')
      .eq('id', req.params.id)
      .single();

    if (getError || !rel) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Relationship not found'));
      return;
    }

    // Verify ownership
    if (rel.created_by_user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'You can only delete relationships you created'));
      return;
    }

    // Delete the relationship (inverse will need to be cleaned up too)
    await supabaseAdmin
      .from('relationships')
      .delete()
      .eq('id', req.params.id);

    // Delete inverse relationship
    await supabaseAdmin
      .from('relationships')
      .delete()
      .eq('person_id', rel.related_person_id)
      .eq('related_person_id', rel.person_id);

    res.status(204).send();
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});
