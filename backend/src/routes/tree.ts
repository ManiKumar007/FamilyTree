import { Router, Response } from 'express';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import { getFullTree, getPersonByAuthUser } from '../services/graphService';

export const treeRouter = Router();

treeRouter.use(authMiddleware);

/**
 * GET /api/tree — Get the full family tree for the authenticated user.
 * Returns all connected persons and relationships for rendering.
 */
treeRouter.get('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    // Get the user's person record
    const person = await getPersonByAuthUser(req.userId!);

    if (!person) {
      // 🚧 TEMPORARY: Return empty tree instead of error during auth bypass
      res.json({ nodes: [], rootPersonId: null });
      return;
      
      /* ORIGINAL CODE (commented out):
      res.status(404).json({
        error: 'Profile not found. Complete profile setup first.',
      });
      return;
      */
    }

    const tree = await getFullTree(person.id);
    res.json(tree);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /api/tree/:personId — Get the family tree centered on a specific person.
 */
treeRouter.get('/:personId', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const tree = await getFullTree(req.params.personId);

    if (tree.nodes.length === 0) {
      res.status(404).json({ error: 'Person not found or no tree data' });
      return;
    }

    res.json(tree);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});
