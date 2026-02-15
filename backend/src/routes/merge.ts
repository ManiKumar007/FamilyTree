import { Router, Response } from 'express';
import { z } from 'zod';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import {
  getPendingMergeRequests,
  approveMerge,
  rejectMerge,
} from '../services/mergeService';

export const mergeRouter = Router();

mergeRouter.use(authMiddleware);

/**
 * GET /api/merge/pending — Get all pending merge requests for the user.
 */
mergeRouter.get('/pending', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const requests = await getPendingMergeRequests(req.userId!);
    res.json(requests);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
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
    res.json({ status: 'approved' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * PUT /api/merge/:id/reject — Reject a merge request.
 */
mergeRouter.put('/:id/reject', async (req: AuthenticatedRequest, res: Response) => {
  try {
    await rejectMerge(req.params.id, req.userId!);
    res.json({ status: 'rejected' });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});
