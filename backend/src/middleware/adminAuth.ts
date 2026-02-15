import { Response, NextFunction } from 'express';
import { supabaseAdmin } from '../config/supabase';
import { AuthenticatedRequest } from './auth';

export interface AdminRequest extends AuthenticatedRequest {
  userRole?: 'user' | 'admin' | 'super_admin';
  isAdmin: boolean;
}

/**
 * Middleware to verify user has admin privileges.
 * Must be used AFTER authMiddleware.
 * Checks user_metadata table for admin/super_admin role.
 */
export async function adminMiddleware(
  req: AdminRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  if (!req.userId) {
    res.status(401).json({ error: 'Authentication required' });
    return;
  }

  try {
    // Query user_metadata for role
    const { data: userMeta, error } = await supabaseAdmin
      .from('user_metadata')
      .select('role, is_active')
      .eq('user_id', req.userId)
      .single();

    if (error) {
      console.error('Error fetching user metadata:', error);
      res.status(500).json({ error: 'Failed to verify admin status' });
      return;
    }

    // Check if user exists in metadata table
    if (!userMeta) {
      res.status(403).json({ error: 'User metadata not found' });
      return;
    }

    // Check if account is active
    if (!userMeta.is_active) {
      res.status(403).json({ error: 'Account is disabled' });
      return;
    }

    // Check for admin or super_admin role
    if (userMeta.role !== 'admin' && userMeta.role !== 'super_admin') {
      res.status(403).json({ 
        error: 'Admin access required',
        message: 'This endpoint requires administrator privileges'
      });
      return;
    }

    // Attach role info to request for downstream use
    req.userRole = userMeta.role;
    req.isAdmin = true;

    next();
  } catch (err: any) {
    console.error('Admin middleware error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
}

/**
 * Middleware to verify user has super_admin privileges specifically.
 * Use for sensitive operations like deleting users or changing roles.
 */
export async function superAdminMiddleware(
  req: AdminRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  if (!req.userId) {
    res.status(401).json({ error: 'Authentication required' });
    return;
  }

  try {
    const { data: userMeta, error } = await supabaseAdmin
      .from('user_metadata')
      .select('role, is_active')
      .eq('user_id', req.userId)
      .single();

    if (error || !userMeta) {
      res.status(403).json({ error: 'Access denied' });
      return;
    }

    if (!userMeta.is_active) {
      res.status(403).json({ error: 'Account is disabled' });
      return;
    }

    if (userMeta.role !== 'super_admin') {
      res.status(403).json({ 
        error: 'Super admin access required',
        message: 'This operation requires super administrator privileges'
      });
      return;
    }

    req.userRole = 'super_admin';
    req.isAdmin = true;

    next();
  } catch (err: any) {
    console.error('Super admin middleware error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
}
