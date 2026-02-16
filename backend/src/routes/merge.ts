import { Router, Response } from 'express';
import { z } from 'zod';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import {
  getPendingMergeRequests,
  approveMerge,
  rejectMerge,
} from '../services/mergeService';
import { successResponse, errorResponse, paginatedResponse, ErrorCodes } from '../utils/response';

export const mergeRouter = Router();

mergeRouter.use(authMiddleware);

/**
 * GET /api/merge/pending — Get all pending merge requests for the user (paginated).
 *
 * Query params:
 *   page     — Page number (default 1)
 *   pageSize — Items per page (default 20, max 100)
 */
mergeRouter.get('/pending', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const page = Math.max(1, parseInt(req.query.page as string) || 1);
    const pageSize = Math.min(100, Math.max(1, parseInt(req.query.pageSize as string) || 20));

    const allRequests = await getPendingMergeRequests(req.userId!);
    const total = allRequests.length;
    const start = (page - 1) * pageSize;
    const paged = allRequests.slice(start, start + pageSize);

    res.json(paginatedResponse(paged, page, pageSize, total));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * PUT /api/merge/:id/approve — Approve a merge request.
 */
const approveSchema = z.object({
  resolved_fields: z.record(z.any()).optional(),
});

mergeRouter.put('/:id/approve', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const parsed = approveSchema.parse(req.body);
    await approveMerge(req.params.id, req.userId!, parsed.resolved_fields);
    res.json(successResponse({ status: 'approved' }));
  } catch (err: any) {
    if (err instanceof z.ZodError) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Validation failed', err.errors));
      return;
    }
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * PUT /api/merge/:id/reject — Reject a merge request.
 */
mergeRouter.put('/:id/reject', async (req: AuthenticatedRequest, res: Response) => {
  try {
    await rejectMerge(req.params.id, req.userId!);
    res.json(successResponse({ status: 'rejected' }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});
