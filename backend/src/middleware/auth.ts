import { Request, Response, NextFunction } from 'express';
import { supabaseAdmin } from '../config/supabase';
import { env } from '../config/env';
import { logger } from '../config/logger';

export interface AuthenticatedRequest extends Request {
  userId?: string;
  userEmail?: string;
}

/**
 * Middleware to verify Supabase JWT from Authorization header.
 * Extracts user ID and attaches it to the request.
 */
export async function authMiddleware(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  // Development-only auth bypass (controlled via AUTH_BYPASS env variable)
  if (env.AUTH_BYPASS) {
    if (env.NODE_ENV === 'production') {
      logger.error('CRITICAL: AUTH_BYPASS is enabled in production! Blocking request.');
      res.status(500).json({ error: 'Server misconfiguration detected' });
      return;
    }
    req.userId = env.AUTH_BYPASS_USER_ID;
    req.userEmail = env.AUTH_BYPASS_EMAIL;
    next();
    return;
  }

  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing or invalid Authorization header' });
    return;
  }

  const token = authHeader.split(' ')[1];

  try {
    // Check if Supabase is configured
    if (!env.SUPABASE_URL || !env.SUPABASE_SERVICE_ROLE_KEY) {
      logger.error('Supabase configuration missing');
      res.status(500).json({ error: 'Server configuration error' });
      return;
    }
    
    let result;
    try {
      result = await supabaseAdmin.auth.getUser(token);
    } catch (err) {
      logger.error('Exception in getUser()', { error: err instanceof Error ? err.message : String(err) });
      res.status(503).json({ error: 'Authentication service unavailable' });
      return;
    }

    const { data, error } = result;

    if (error) {
      logger.warn('Token validation failed', { errorName: error.name });
      
      // Check if it's a connection error
      if (error.message && (error.message.includes('fetch') || error.message.includes('network') || error.message.includes('Failed to fetch'))) {
        res.status(503).json({ error: 'Authentication service unavailable' });
      } else {
        res.status(401).json({ error: 'Invalid or expired token' });
      }
      return;
    }
    
    if (!data.user) {
      res.status(401).json({ error: 'Invalid or expired token' });
      return;
    }

    req.userId = data.user.id;
    req.userEmail = data.user.email;
    next();
  } catch (err: any) {
    logger.error('Authentication exception', { type: err?.constructor?.name });
    
    // Check for network/connection errors
    if (err.message && (err.message.includes('fetch') || err.message.includes('ECONNREFUSED') || err.message.includes('ETIMEDOUT'))) {
      res.status(503).json({ error: 'Authentication service unavailable' });
    } else {
      res.status(401).json({ error: 'Authentication failed' });
    }
  }
}
