import { Router, Response } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import { successResponse, errorResponse, ErrorCodes } from '../utils/response';

export const statsRouter = Router();

// All routes require authentication
statsRouter.use(authMiddleware);

/**
 * GET /api/stats/family — Get comprehensive family statistics
 */
statsRouter.get('/family', async (req: AuthenticatedRequest, res: Response) => {
  try {
    // Call the database function with user ID
    const { data, error } = await supabaseAdmin.rpc('get_family_statistics', {
      p_user_id: req.userId!
    });

    if (error) throw error;

    res.json(successResponse(data));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * GET /api/stats/consistency — Run tree consistency checks
 */
statsRouter.get('/consistency', async (req: AuthenticatedRequest, res: Response) => {
  try {
    // Call the database function with user ID
    const { data, error } = await supabaseAdmin.rpc('check_tree_consistency', {
      p_user_id: req.userId!
    });

    if (error) throw error;

    // Group issues by type
    const issuesByType: Record<string, any[]> = {};
    if (data && Array.isArray(data)) {
      data.forEach((issue: any) => {
        if (!issuesByType[issue.issue_type]) {
          issuesByType[issue.issue_type] = [];
        }
        issuesByType[issue.issue_type].push(issue);
      });
    }

    res.json(successResponse({
      total_issues: data?.length || 0,
      issues: data || [],
      issues_by_type: issuesByType,
    }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * POST /api/stats/relationship-path — Find relationship path between two persons
 */
statsRouter.post('/relationship-path', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const schema = z.object({
      person1_id: z.string().uuid(),
      person2_id: z.string().uuid(),
      max_depth: z.number().int().min(1).max(10).optional().default(5),
    });

    const parsed = schema.parse(req.body);

    // Breadth-first search to find shortest path
    type QueueItem = {
      personId: string;
      path: string[];
      depth: number;
    };

    const visited = new Set<string>();
    const queue: QueueItem[] = [{ personId: parsed.person1_id, path: [parsed.person1_id], depth: 0 }];
    visited.add(parsed.person1_id);

    while (queue.length > 0) {
      const current = queue.shift()!;

      if (current.personId === parsed.person2_id) {
        // Found the target - fetch person details for the path
        const { data: persons } = await supabaseAdmin
          .from('persons')
          .select('id, name, photo_url')
          .in('id', current.path);

        // Preserve order
        const orderedPersons = current.path.map(id => 
          persons?.find(p => p.id === id)
        ).filter(Boolean);

        res.json(successResponse({
          found: true,
          depth: current.depth,
          path: orderedPersons,
        }));
        return;
      }

      if (current.depth >= parsed.max_depth) {
        continue;
      }

      // Get all relationships for the current person
      const { data: relationships } = await supabaseAdmin
        .from('relationships')
        .select('person_id, related_person_id, type')
        .or(`person_id.eq.${current.personId},related_person_id.eq.${current.personId}`);

      if (relationships) {
        for (const rel of relationships) {
          const nextPersonId = rel.person_id === current.personId 
            ? rel.related_person_id 
            : rel.person_id;

          if (!visited.has(nextPersonId)) {
            visited.add(nextPersonId);
            queue.push({
              personId: nextPersonId,
              path: [...current.path, nextPersonId],
              depth: current.depth + 1,
            });
          }
        }
      }
    }

    // No path found
    res.json(successResponse({
      found: false,
      message: `No relationship path found within ${parsed.max_depth} degrees`,
    }));
  } catch (err: any) {
    if (err instanceof z.ZodError) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Validation failed', err.errors));
      return;
    }
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * GET /api/stats/tree-depth — Calculate the maximum depth of the family tree
 */
statsRouter.get('/tree-depth', async (req: AuthenticatedRequest, res: Response) => {
  try {
    // Get the user's person record
    const { data: userPerson } = await supabaseAdmin
      .from('persons')
      .select('id')
      .eq('auth_user_id', req.userId!)
      .single();

    if (!userPerson) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'User profile not found'));
      return;
    }

    // BFS to find maximum depth
    let maxDepth = 0;
    const visited = new Set<string>();
    const queue: { personId: string; depth: number }[] = [{ personId: userPerson.id, depth: 0 }];
    visited.add(userPerson.id);

    while (queue.length > 0) {
      const current = queue.shift()!;
      maxDepth = Math.max(maxDepth, current.depth);

      const { data: relationships } = await supabaseAdmin
        .from('relationships')
        .select('person_id, related_person_id')
        .or(`person_id.eq.${current.personId},related_person_id.eq.${current.personId}`);

      if (relationships) {
        for (const rel of relationships) {
          const nextPersonId = rel.person_id === current.personId 
            ? rel.related_person_id 
            : rel.person_id;

          if (!visited.has(nextPersonId)) {
            visited.add(nextPersonId);
            queue.push({ personId: nextPersonId, depth: current.depth + 1 });
          }
        }
      }
    }

    res.json(successResponse({
      max_depth: maxDepth,
      total_persons: visited.size,
    }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});
