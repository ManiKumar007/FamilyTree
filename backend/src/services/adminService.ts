import { supabaseAdmin } from '../config/supabase';

/**
 * Admin Service
 * Provides administrative analytics and user management functions
 */

export interface DashboardStats {
  totalUsers: number;
  activeUsers: number;
  totalPeople: number;
  totalRelationships: number;
  totalErrors: number;
  unresolvedErrors: number;
  errorRate24h: number;
  newUsersToday: number;
  newUsersThisWeek: number;
  avgPeoplePerUser: number;
}

export interface UserGrowthData {
  date: string;
  count: number;
}

export interface TreeSizeDistribution {
  size_range: string;
  user_count: number;
}

export interface ActiveUser {
  user_id: string;
  email: string;
  total_people: number;
  total_relationships: number;
  last_login_at: string | null;
  created_at: string;
}

export interface ErrorSummary {
  error_type: string;
  count: number;
  severity: string;
  latest_occurrence: string;
}

class AdminService {
  /**
   * Get dashboard statistics for admin overview
   */
  async getDashboardStats(): Promise<DashboardStats> {
    try {
      // Total users
      const { count: totalUsers } = await supabaseAdmin
        .from('user_metadata')
        .select('*', { count: 'exact', head: true });

      // Active users (logged in within last 30 days)
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      const { count: activeUsers } = await supabaseAdmin
        .from('user_metadata')
        .select('*', { count: 'exact', head: true })
        .gte('last_login_at', thirtyDaysAgo.toISOString());

      // Total people records
      const { count: totalPeople } = await supabaseAdmin
        .from('persons')
        .select('*', { count: 'exact', head: true });

      // Total relationships
      const { count: totalRelationships } = await supabaseAdmin
        .from('relationships')
        .select('*', { count: 'exact', head: true });

      // Error statistics
      const { count: totalErrors } = await supabaseAdmin
        .from('error_logs')
        .select('*', { count: 'exact', head: true });

      const { count: unresolvedErrors } = await supabaseAdmin
        .from('error_logs')
        .select('*', { count: 'exact', head: true })
        .eq('resolved', false);

      // Error rate in last 24 hours
      const oneDayAgo = new Date();
      oneDayAgo.setHours(oneDayAgo.getHours() - 24);
      const { data: errorRate } = await supabaseAdmin
        .rpc('get_error_rate_by_hour', {
          hours_back: 24
        });
      const errorRate24h = errorRate?.[0]?.error_rate || 0;

      // New users today
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const { count: newUsersToday } = await supabaseAdmin
        .from('user_metadata')
        .select('*', { count: 'exact', head: true })
        .gte('created_at', today.toISOString());

      // New users this week
      const weekAgo = new Date();
      weekAgo.setDate(weekAgo.getDate() - 7);
      weekAgo.setHours(0, 0, 0, 0);
      const { count: newUsersThisWeek } = await supabaseAdmin
        .from('user_metadata')
        .select('*', { count: 'exact', head: true })
        .gte('created_at', weekAgo.toISOString());

      // Average people per user
      const avgPeoplePerUser = totalUsers && totalUsers > 0
        ? Math.round((totalPeople || 0) / totalUsers)
        : 0;

      return {
        totalUsers: totalUsers || 0,
        activeUsers: activeUsers || 0,
        totalPeople: totalPeople || 0,
        totalRelationships: totalRelationships || 0,
        totalErrors: totalErrors || 0,
        unresolvedErrors: unresolvedErrors || 0,
        errorRate24h,
        newUsersToday: newUsersToday || 0,
        newUsersThisWeek: newUsersThisWeek || 0,
        avgPeoplePerUser,
      };
    } catch (error) {
      console.error('Failed to get dashboard stats:', error);
      throw new Error('Failed to fetch dashboard statistics');
    }
  }

  /**
   * Get user growth data over time (daily for last 30 days)
   */
  async getUserGrowthData(days: number = 30): Promise<UserGrowthData[]> {
    try{
      const { data, error } = await supabaseAdmin
        .rpc('get_user_growth_by_day', { days_back: days });

      if (error) {
        console.error('Failed to get user growth data:', error);
        return [];
      }

      return data || [];
    } catch (error) {
      console.error('Failed to get user growth data:', error);
      return [];
    }
  }

  /**
   * Get tree size distribution (number of users by family tree size)
   */
  async getTreeSizeDistribution(): Promise<TreeSizeDistribution[]> {
    try {
      const { data, error } = await supabaseAdmin.rpc('get_tree_size_distribution');

      if (error) {
        console.error('Failed to get tree size distribution:', error);
        return [];
      }

      return data || [];
    } catch (error) {
      console.error('Failed to get tree size distribution:', error);
      return [];
    }
  }

  /**
   * Get most active users (by number of people created)
   */
  async getMostActiveUsers(limit: number = 10): Promise<ActiveUser[]> {
    try {
      // Get users with their people count
      const { data, error } = await supabaseAdmin
        .from('persons')
        .select('created_by_user_id')
        .order('created_at', { ascending: false });

      if (error) throw error;

      // Count people per user
      const userCounts = new Map<string, number>();
      data?.forEach(person => {
        if (person.created_by_user_id) {
          const count = userCounts.get(person.created_by_user_id) || 0;
          userCounts.set(person.created_by_user_id, count + 1);
        }
      });

      // Get top users
      const topUserIds = Array.from(userCounts.entries())
        .sort((a, b) => b[1] - a[1])
        .slice(0, limit)
        .map(([userId]) => userId);

      if (topUserIds.length === 0) return [];

      // Get user metadata for top users
      const { data: users, error: usersError } = await supabaseAdmin
        .from('user_metadata')
        .select('user_id, last_login_at, created_at')
        .in('user_id', topUserIds);

      if (usersError) throw usersError;

      // Combine with counts
      const activeUsers: ActiveUser[] = users?.map(user => ({
        user_id: user.user_id,
        email: '', // We don't have email in user_metadata, would need auth.users
        total_people: userCounts.get(user.user_id) || 0,
        total_relationships: 0, // TODO: Calculate relationships count
        last_login_at: user.last_login_at,
        created_at: user.created_at,
      })) || [];

      return activeUsers.sort((a, b) => b.total_people - a.total_people);
    } catch (error) {
      console.error('Failed to get active users:', error);
      return [];
    }
  }

  /**
   * Get error summary by type
   */
  async getErrorStats(days: number = 7): Promise<ErrorSummary[]> {
    try {
      const daysAgo = new Date();
      daysAgo.setDate(daysAgo.getDate() - days);

      const { data, error } = await supabaseAdmin
        .from('error_logs')
        .select('error_type, severity, timestamp')
        .gte('timestamp', daysAgo.toISOString())
        .order('timestamp', { ascending: false });

      if (error) throw error;

      // Group by error type
      const errorMap = new Map<string, ErrorSummary>();
      data?.forEach(err => {
        const key = err.error_type;
        if (!errorMap.has(key)) {
          errorMap.set(key, {
            error_type: err.error_type,
            count: 0,
            severity: err.severity,
            latest_occurrence: err.timestamp,
          });
        }
        const summary = errorMap.get(key)!;
        summary.count++;
        // Update to latest occurrence
        if (new Date(err.timestamp) > new Date(summary.latest_occurrence)) {
          summary.latest_occurrence = err.timestamp;
          summary.severity = err.severity; // Use severity from latest occurrence
        }
      });

      return Array.from(errorMap.values())
        .sort((a, b) => b.count - a.count);
    } catch (error) {
      console.error('Failed to get error stats:', error);
      return [];
    }
  }

  /**
   * Get system health metrics
   */
  async getSystemHealth() {
    try {
      // Test database connection
      const startTime = Date.now();
      const { error } = await supabaseAdmin
        .from('persons')
        .select('id', { count: 'exact', head: true })
        .limit(1);
      const dbLatency = Date.now() - startTime;

      return {
        status: error ? 'degraded' : 'healthy',
        database: {
          connected: !error,
          latency_ms: dbLatency,
        },
        timestamp: new Date().toISOString(),
      };
    } catch (error) {
      console.error('Failed to get system health:', error);
      return {
        status: 'unhealthy',
        database: {
          connected: false,
          latency_ms: -1,
        },
        timestamp: new Date().toISOString(),
      };
    }
  }

  /**
   * Update user role (super admin only)
   */
  async updateUserRole(userId: string, role: 'user' | 'admin' | 'super_admin'): Promise<void> {
    try {
      const { error } = await supabaseAdmin
        .from('user_metadata')
        .update({ role })
        .eq('user_id', userId);

      if (error) throw error;
    } catch (error) {
      console.error('Failed to update user role:', error);
      throw new Error('Failed to update user role');
    }
  }

  /**
   * Enable/disable user account
   */
  async updateUserStatus(userId: string, isActive: boolean): Promise<void> {
    try {
      const { error } = await supabaseAdmin
        .from('user_metadata')
        .update({ is_active: isActive })
        .eq('user_id', userId);

      if (error) throw error;
    } catch (error) {
      console.error('Failed to update user status:', error);
      throw new Error('Failed to update user status');
    }
  }

  /**
   * Mark error as resolved
   */
  async resolveError(errorId: string, adminUserId: string): Promise<void> {
    try {
      const { error } = await supabaseAdmin
        .from('error_logs')
        .update({
          resolved: true,
          resolved_at: new Date().toISOString(),
          resolved_by: adminUserId,
        })
        .eq('id', errorId);

      if (error) throw error;
    } catch (error) {
      console.error('Failed to resolve error:', error);
      throw new Error('Failed to resolve error');
    }
  }
}

export const adminService = new AdminService();
