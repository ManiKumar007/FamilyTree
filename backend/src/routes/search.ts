import { Router, Response } from 'express';
import { z } from 'zod';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import { searchInCircles, getPersonByAuthUser, getPathNames } from '../services/graphService';
import { successResponse, errorResponse, paginatedResponse, ErrorCodes } from '../utils/response';

export const searchRouter = Router();

searchRouter.use(authMiddleware);

const searchQuerySchema = z.object({
  query: z.string().optional(),
  occupation: z.string().optional(),
  marital_status: z.enum(['single', 'married', 'divorced', 'widowed']).optional(),
  depth: z.coerce.number().min(1).max(10).default(3),
  page: z.coerce.number().min(1).default(1),
  pageSize: z.coerce.number().min(1).max(100).default(20),
});

/**
 * GET /api/search — Search for people within N circles.
 *
 * Query params:
 *   query        — Free text search (matches name or occupation)
 *   occupation   — Filter by occupation
 *   marital_status — Filter by marital status
 *   depth        — Max number of relationship hops (1-10, default 3)
 *   page         — Page number (default 1)
 *   pageSize     — Items per page (default 20, max 100)
 */
searchRouter.get('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const params = searchQuerySchema.parse(req.query);

    // Get user's person record
    const person = await getPersonByAuthUser(req.userId!);
    if (!person) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Profile not found. Complete profile setup first.'));
      return;
    }

    const results = await searchInCircles({
      personId: person.id,
      maxDepth: params.depth,
      query: params.query,
      occupation: params.occupation,
      maritalStatus: params.marital_status,
    });

    // Enrich results with connection path names
    const enrichedResults = await Promise.all(
      results.map(async (result) => {
        const pathNames = await getPathNames(result.path);
        return {
          ...result,
          pathNames,
          connectionPath: pathNames.join(' → '),
        };
      })
    );

    // Paginate enriched results
    const total = enrichedResults.length;
    const start = (params.page - 1) * params.pageSize;
    const paged = enrichedResults.slice(start, start + params.pageSize);

    res.json({
      ...paginatedResponse(paged, params.page, params.pageSize, total),
      depth: params.depth,
    });
  } catch (err: any) {
    if (err instanceof z.ZodError) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Invalid query parameters', err.errors));
      return;
    }
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});
