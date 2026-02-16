import { Request, Response, NextFunction } from 'express';
import { supabaseAdmin } from '../config/supabase';
import { env } from '../config/env';

export interface AuthenticatedRequest extends Request {
  userId?: string;
  userEmail?: string;
}

/**
 * Middleware to verify Supabase JWT from Authorization header.
 * Extracts user ID and attaches it to the request.
 *
 * Set AUTH_BYPASS=true in .env for local development only.
 * Never enable AUTH_BYPASS in production.
 */
export async function authMiddleware(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  // Development-only auth bypass (controlled via AUTH_BYPASS env variable)
  if (env.AUTH_BYPASS) {
    if (env.NODE_ENV === 'production') {
      console.error('CRITICAL: AUTH_BYPASS is enabled in production! Refusing to bypass.');
    } else {
      req.userId = env.AUTH_BYPASS_USER_ID;
      req.userEmail = env.AUTH_BYPASS_EMAIL;
      next();
      return;
    }
  }

  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing or invalid Authorization header' });
    return;
  }

  const token = authHeader.split(' ')[1];

  try {
    console.log('🔐 Validating token...');
    console.log('Token length:', token.length);
    console.log('Token preview:', token.substring(0, 30) + '...');
    console.log('Supabase URL:', env.SUPABASE_URL);
    
    const { data, error } = await supabaseAdmin.auth.getUser(token);

    if (error) {
      console.error('❌ Token validation error:', error.message);
      console.error('Error details:', JSON.stringify(error, null, 2));
      res.status(401).json({ error: 'Invalid or expired token', details: error.message });
      return;
    }
    
    if (!data.user) {
      console.error('❌ No user data returned for token');
      res.status(401).json({ error: 'Invalid or expired token' });
      return;
    }

    console.log('✅ Token validated for user:', data.user.email);
    req.userId = data.user.id;
    req.userEmail = data.user.email;
    next();
  } catch (err) {
    console.error('❌ Authentication exception:', err);
    res.status(401).json({ error: 'Authentication failed', exception: String(err) });
  }
}
