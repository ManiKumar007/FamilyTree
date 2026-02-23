import { Router } from 'express';

const router = Router();

/**
 * Health check endpoint
 * Used by Render.com and monitoring tools to verify the service is running
 */
router.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'familytree-backend',
    version: '1.1.0',
  });
});

export default router;
