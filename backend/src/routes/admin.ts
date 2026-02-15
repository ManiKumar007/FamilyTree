import { Router, Request, Response, NextFunction } from 'express';
import { adminService } from '../services/adminService';
import { authMiddleware } from '../middleware/auth';
import { adminMiddleware, superAdminMiddleware } from '../middleware/adminAuth';
import { supabaseAdmin } from '../config/supabase';

const router = Router();

// All admin routes require authentication and admin role
router.use(authMiddleware as any, adminMiddleware as any);

/**
 * GET /api/admin/stats
 * Get dashboard statistics
 */
router.get('/stats', async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const stats = await adminService.getDashboardStats();
    res.json(stats);
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/admin/analytics/growth
 * Get user growth data over time
 */
router.get('/analytics/growth', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const days = parseInt(req.query.days as string) || 30;
    const data = await adminService.getUserGrowthData(days);
    res.json(data);
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/admin/analytics/tree-distribution
 * Get tree size distribution
 */
router.get('/analytics/tree-distribution', async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await adminService.getTreeSizeDistribution();
    res.json(data);
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/admin/analytics/active-users
 * Get most active users
 */
router.get('/analytics/active-users', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const limit = parseInt(req.query.limit as string) || 10;
    const data = await adminService.getMostActiveUsers(limit);
    res.json(data);
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/admin/errors
 * Get error logs with pagination and filtering
 */
router.get('/errors', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 50;
    const errorType = req.query.type as string || null;
    const severity = req.query.severity as string || null;

    const { data, error } = await supabaseAdmin
      .rpc('get_recent_errors', {
        page_size: pageSize,
        page_number: page,
        filter_type: errorType,
        filter_severity: severity,
      });

    if (error) throw error;

    // Get total count for pagination
    let countQuery = supabaseAdmin
      .from('error_logs')
      .select('*', { count: 'exact', head: true });

    if (errorType) {
      countQuery = countQuery.eq('error_type', errorType);
    }
    if (severity) {
      countQuery = countQuery.eq('severity', severity);
    }

    const { count } = await countQuery;

    res.json({
      errors: data || [],
      pagination: {
        page,
        pageSize,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / pageSize),
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/admin/errors/stats
 * Get error statistics
 */
router.get('/errors/stats', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const days = parseInt(req.query.days as string) || 7;
    const stats = await adminService.getErrorStats(days);
    res.json(stats);
  } catch (error) {
    next(error);
  }
});

/**
 * PUT /api/admin/errors/:id/resolve
 * Mark error as resolved
 */
router.put('/errors/:id/resolve', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const adminUserId = (req as any).userId;

    await adminService.resolveError(id, adminUserId);
    res.json({ success: true, message: 'Error marked as resolved' });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/admin/users
 * Get all users with pagination
 */
router.get('/users', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 20;
    const role = req.query.role as string || null;
    const search = req.query.search as string || null;

    let query = supabaseAdmin
      .from('user_metadata')
      .select('*', { count: 'exact' });

    if (role) {
      query = query.eq('role', role);
    }

    const { data, error, count } = await query
      .order('created_at', { ascending: false })
      .range((page - 1) * pageSize, page * pageSize - 1);

    if (error) throw error;

    res.json({
      users: data || [],
      pagination: {
        page,
        pageSize,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / pageSize),
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * PUT /api/admin/users/:id/role
 * Update user role (super admin only)
 */
router.put('/users/:id/role', superAdminMiddleware as any, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const { role } = req.body;

    if (!['user', 'admin', 'super_admin'].includes(role)) {
      return res.status(400).json({ error: 'Invalid role' });
    }

    await adminService.updateUserRole(id, role);

    // Log the action
    const adminUserId = (req as any).userId;
    await supabaseAdmin.rpc('log_admin_action', {
      p_admin_user_id: adminUserId,
      p_action_type: 'role_change',
      p_resource_type: 'user',
      p_resource_id: id,
      p_new_value: { role },
      p_metadata: {},
    });

    res.json({ success: true, message: 'User role updated' });
  } catch (error) {
    next(error);
  }
});

/**
 * PUT /api/admin/users/:id/status
 * Enable/disable user account
 */
router.put('/users/:id/status', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;
    const { isActive } = req.body;

    if (typeof isActive !== 'boolean') {
      return res.status(400).json({ error: 'isActive must be a boolean' });
    }

    await adminService.updateUserStatus(id, isActive);

    // Log the action
    const adminUserId = (req as any).userId;
    await supabaseAdmin.rpc('log_admin_action', {
      p_admin_user_id: adminUserId,
      p_action_type: isActive ? 'enable_user' : 'disable_user',
      p_resource_type: 'user',
      p_resource_id: id,
      p_new_value: { is_active: isActive },
      p_metadata: {},
    });

    res.json({ success: true, message: `User ${isActive ? 'enabled' : 'disabled'}` });
  } catch (error) {
    next(error);
  }
});

/**
 * DELETE /api/admin/persons/:id
 * Delete a person record (admin override)
 */
router.delete('/persons/:id', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const { id } = req.params;

    // Get person details before deletion for logging
    const { data: person } = await supabaseAdmin
      .from('persons')
      .select('*')
      .eq('id', id)
      .single();

    // Delete the person
    const { error } = await supabaseAdmin
      .from('persons')
      .delete()
      .eq('id', id);

    if (error) throw error;

    // Log the action
    const adminUserId = (req as any).userId;
    await supabaseAdmin.rpc('log_admin_action', {
      p_admin_user_id: adminUserId,
      p_action_type: 'delete',
      p_resource_type: 'person',
      p_resource_id: id,
      p_old_value: person,
      p_metadata: {},
    });

    res.json({ success: true, message: 'Person deleted successfully' });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/admin/audit-logs
 * Get audit log entries
 */
router.get('/audit-logs', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const pageSize = parseInt(req.query.pageSize as string) || 50;

    const { data, error, count } = await supabaseAdmin
      .from('audit_logs')
      .select('*', { count: 'exact' })
      .order('timestamp', { ascending: false })
      .range((page - 1) * pageSize, page * pageSize - 1);

    if (error) throw error;

    res.json({
      logs: data || [],
      pagination: {
        page,
        pageSize,
        total: count || 0,
        totalPages: Math.ceil((count || 0) / pageSize),
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/admin/health
 * Get system health status
 */
router.get('/health', async (_req: Request, res: Response, next: NextFunction) => {
  try {
    const health = await adminService.getSystemHealth();
    res.json(health);
  } catch (error) {
    next(error);
  }
});

export default router;
