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
    
    // Check if Supabase is configured
    if (!env.SUPABASE_URL || !env.SUPABASE_SERVICE_ROLE_KEY) {
      console.error('❌ Supabase configuration missing!');
      console.error('   SUPABASE_URL:', env.SUPABASE_URL ? 'Set' : 'Missing');
      console.error('   SUPABASE_SERVICE_ROLE_KEY:', env.SUPABASE_SERVICE_ROLE_KEY ? 'Set' : 'Missing');
      res.status(500).json({ 
        error: 'Server configuration error', 
        details: 'Supabase credentials not configured' 
      });
      return;
    }
    
    let result;
    try {
      console.log('Calling supabaseAdmin.auth.getUser()...');
      result = await supabaseAdmin.auth.getUser(token);
      console.log('getUser result:', JSON.stringify(result, null, 2));
    } catch (err) {
      console.error('❌ EXCEPTION in getUser():', err);
      console.error('Exception type:', typeof err);
      console.error('Exception stack:', err instanceof Error ? err.stack : 'No stack');
      res.status(503).json({ 
        error: 'Service unavailable', 
        details: 'Exception while connecting to authentication service. Please contact administrator.' 
      });
      return;
    }

    const { data, error } = result;

    if (error) {
      console.error('❌ Token validation error:', error.message);
      console.error('Error details:', JSON.stringify(error, null, 2));
      console.error('Error name:', error.name);
      console.error('Error status:', (error as any).status);
      
      // Check if it's a connection error
      if (error.message && (error.message.includes('fetch') || error.message.includes('network') || error.message.includes('Failed to fetch'))) {
        console.error('❌ CRITICAL: Cannot connect to Supabase!');
        console.error('   Check SUPABASE_URL and network connectivity');
        res.status(503).json({ 
          error: 'Service unavailable', 
          details: 'Cannot connect to authentication service. Please contact administrator.' 
        });
      } else {
        res.status(401).json({ 
          error: 'Invalid or expired token', 
          details: error.message 
        });
      }
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
  } catch (err: any) {
    console.error('❌ Authentication exception:', err);
    console.error('Exception type:', err.constructor.name);
    console.error('Exception message:', err.message);
    
    // Check for network/connection errors
    if (err.message && (err.message.includes('fetch') || err.message.includes('ECONNREFUSED') || err.message.includes('ETIMEDOUT'))) {
      console.error('❌ CRITICAL: Network error connecting to Supabase');
      console.error('   Verify SUPABASE_URL is correct and accessible');
      res.status(503).json({ 
        error: 'Service unavailable', 
        details: 'Cannot reach authentication service. Please check server configuration.' 
      });
    } else {
      res.status(401).json({ 
        error: 'Authentication failed', 
        exception: String(err) 
      });
    }
  }
}
