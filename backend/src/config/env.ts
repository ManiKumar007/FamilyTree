import dotenv from 'dotenv';

// Load environment variables before exporting
dotenv.config();

export const env = {
  SUPABASE_URL: process.env.SUPABASE_URL || '',
  SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY || '',
  SUPABASE_ANON_KEY: process.env.SUPABASE_ANON_KEY || '',
  PORT: parseInt(process.env.PORT || '3000', 10),
  NODE_ENV: process.env.NODE_ENV || 'development',
  APP_URL: process.env.APP_URL || 'http://localhost:8080',
  INVITE_BASE_URL: process.env.INVITE_BASE_URL || 'http://localhost:8080/invite',
  // Set AUTH_BYPASS=true in .env for local development ONLY
  AUTH_BYPASS: process.env.AUTH_BYPASS === 'true',
  AUTH_BYPASS_USER_ID: process.env.AUTH_BYPASS_USER_ID || '00000000-0000-0000-0000-000000000001',
  AUTH_BYPASS_EMAIL: process.env.AUTH_BYPASS_EMAIL || 'dev@myfamilytree.local',
};
