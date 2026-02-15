import { createClient } from '@supabase/supabase-js';
import { env } from './env';

// Admin client with service_role key — bypasses RLS
// Use this for backend operations (graph queries, merge logic, etc.)
export const supabaseAdmin = createClient(env.SUPABASE_URL, env.SUPABASE_SERVICE_ROLE_KEY, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

// Client with anon key — respects RLS
// Use this when you want to act as the authenticated user
export function createUserClient(accessToken: string) {
  return createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
    global: {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    },
  });
}
