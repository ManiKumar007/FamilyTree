import { Router, Response } from 'express';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import { getFullTree, getPersonByAuthUser, findConnection } from '../services/graphService';
import { calculateRelationship, RelationshipPath } from '../services/relationshipCalculator';
import { supabaseAdmin } from '../config/supabase';
import { successResponse, errorResponse, ErrorCodes } from '../utils/response';
import { canUserAccessTree } from '../services/authorizationService';

export const treeRouter = Router();

treeRouter.use(authMiddleware);

/**
 * Helper: resolve a username to a person ID.
 * Returns the person UUID or null if not found.
 */
async function resolveUsernameToId(username: string): Promise<string | null> {
  const { data } = await supabaseAdmin
    .from('persons')
    .select('id')
    .ilike('username', username)
    .maybeSingle();
  return data?.id ?? null;
}

/**
 * GET /api/tree — Get the full family tree for the authenticated user.
 * Returns all connected persons and relationships for rendering.
 */
treeRouter.get('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    // Get the user's person record
    const person = await getPersonByAuthUser(req.userId!);

    if (!person) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Profile not found. Complete profile setup first.'));
      return;
    }

    const tree = await getFullTree(person.id);
    res.json(successResponse(tree));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * GET /api/tree/connection-by-username/:usernameA/:usernameB — Find connection using usernames.
 * Resolves usernames to person IDs and delegates to findConnection.
 * NOTE: Must be defined BEFORE /:personId to avoid route conflict.
 */
treeRouter.get('/connection-by-username/:usernameA/:usernameB', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { usernameA, usernameB } = req.params;

    if (!usernameA || !usernameB) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Both usernames are required'));
      return;
    }

    const [personAId, personBId] = await Promise.all([
      resolveUsernameToId(usernameA),
      resolveUsernameToId(usernameB),
    ]);

    if (!personAId) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, `Username '${usernameA}' not found`));
      return;
    }
    if (!personBId) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, `Username '${usernameB}' not found`));
      return;
    }

    const result = await findConnection(personAId, personBId);

    if (result === null) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'One or both persons not found'));
      return;
    }

    // Add calculated relationships for each path
    const enhancedResult = {
      ...result,
      paths: result.paths.map(pathData => {
        const relPath: RelationshipPath[] = pathData.relationships.map(r => ({
          personId: r.to,
          relationshipType: r.type,
        }));
        
        const startGender = pathData.path[0]?.gender || 'other';
        const endGender = pathData.path[pathData.path.length - 1]?.gender || 'other';
        const calculated = calculateRelationship(relPath, startGender, endGender);
        
        return {
          ...pathData,
          calculatedRelationship: calculated,
        };
      }),
    };

    res.json(successResponse(enhancedResult));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * GET /api/tree/connection/:personAId/:personBId — Find connection between two persons.
 * Returns the shortest relationship path between them.
 * NOTE: Must be defined BEFORE /:personId to avoid route conflict.
 */
treeRouter.get('/connection/:personAId/:personBId', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { personAId, personBId } = req.params;

    if (!personAId || !personBId) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Both person IDs are required'));
      return;
    }

    const result = await findConnection(personAId, personBId);

    if (result === null) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'One or both persons not found'));
      return;
    }

    // Add calculated relationships for each path
    const enhancedResult = {
      ...result,
      paths: result.paths.map(pathData => {
        const relPath: RelationshipPath[] = pathData.relationships.map(r => ({
          personId: r.to,
          relationshipType: r.type,
        }));
        
        const startGender = pathData.path[0]?.gender || 'other';
        const endGender = pathData.path[pathData.path.length - 1]?.gender || 'other';
        const calculated = calculateRelationship(relPath, startGender, endGender);
        
        return {
          ...pathData,
          calculatedRelationship: calculated,
        };
      }),
    };

    res.json(successResponse(enhancedResult));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * GET /api/tree/:personId — Get the family tree centered on a specific person.
 */
treeRouter.get('/:personId', async (req: AuthenticatedRequest, res: Response) => {
  try {
    // Authorization check: verify user can access this tree
    const hasAccess = await canUserAccessTree(req.userId!, req.params.personId);
    if (!hasAccess) {
      res.status(403).json(errorResponse(
        ErrorCodes.FORBIDDEN,
        'You do not have permission to view this family tree. The person must be connected to your tree.'
      ));
      return;
    }

    const tree = await getFullTree(req.params.personId);

    if (tree.nodes.length === 0) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Person not found or no tree data'));
      return;
    }

    res.json(successResponse(tree));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});
