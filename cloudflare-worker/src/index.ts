/**
 * Cloudflare Worker Proxy for Supabase
 * Proxies all Supabase API requests through Cloudflare to bypass regional blocking
 * Deploy with: wrangler deploy
 */

export interface Env {
  SUPABASE_URL?: string;
  SUPABASE_ANON_KEY?: string;
  SUPABASE_SERVICE_ROLE_KEY?: string;
}

// Hardcoded fallback values (will be overridden by wrangler.toml vars)
const DEFAULT_SUPABASE_URL = 'https://vojwwcolmnbzogsrmwap.supabase.co';
const DEFAULT_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvand3Y29sbW5iem9nc3Jtd2FwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExNDgyNDYsImV4cCI6MjA4NjcyNDI0Nn0.xVU1_igSVhUm4iFGtV7bPLkHGZG-VtRBBfBugPEa-7g';

// Add CORS headers to response
function addCorsHeaders(response: Response): Response {
  const headers = new Headers(response.headers);
  headers.set('Access-Control-Allow-Origin', '*');
  headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
  headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Client-Info, X-Supabase-RLS-Bypass-Authorizer');
  headers.set('Access-Control-Max-Age', '86400');
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

// Handle CORS preflight requests
function handleCorsPreFlight(request: Request): Response | null {
  if (request.method === 'OPTIONS') {
    return addCorsHeaders(new Response(null, { status: 204 }));
  }
  return null;
}

// Validate request path
function isValidSupabasePath(path: string): boolean {
  // Allow REST API paths
  if (path.startsWith('/rest/v1/')) return true;
  // Allow Auth paths
  if (path.startsWith('/auth/v1/')) return true;
  // Allow Realtime paths
  if (path.startsWith('/realtime/v1/')) return true;
  return false;
}

async function handleSupabaseRequest(
  request: Request,
  env: Env
): Promise<Response> {
  const url = new URL(request.url);
  const path = url.pathname;

  // Use environment variables or fallback to defaults
  const supabaseUrl = env.SUPABASE_URL || DEFAULT_SUPABASE_URL;
  const anonKey = env.SUPABASE_ANON_KEY || DEFAULT_ANON_KEY;

  // Validate path
  if (!isValidSupabasePath(path)) {
    return new Response(JSON.stringify({
      error: 'Invalid path',
      message: 'Only Supabase API paths are allowed',
    }), {
      status: 403,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // Build the target URL
  const targetUrl = new URL(supabaseUrl);
  targetUrl.pathname = path;
  targetUrl.search = url.search;

  // Prepare headers
  const headers = new Headers(request.headers);
  
  // Handle authorization: convert Bearer token to apikey header if needed
  if (!headers.has('apikey')) {
    const authHeader = headers.get('Authorization');
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.slice(7); // Remove "Bearer " prefix
      headers.set('apikey', token);
      headers.delete('Authorization'); // Remove the Authorization header
    } else if (anonKey) {
      // Use the default anon key if no autherization provided
      headers.set('apikey', anonKey);
    }
  }

  // Ensure Content-Type is set for POST/PUT/PATCH
  if (['POST', 'PUT', 'PATCH'].includes(request.method) && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json');
  }

  // Create the proxy request
  const proxyRequest = new Request(targetUrl, {
    method: request.method,
    headers,
    body: ['GET', 'HEAD', 'DELETE'].includes(request.method) ? undefined : request.body,
  });

  try {
    // Forward the request to Supabase
    const response = await fetch(proxyRequest);
    
    // Add CORS headers to the response
    return addCorsHeaders(response);
  } catch (error) {
    console.error('Proxy request failed:', error);
    return new Response(JSON.stringify({
      error: 'Proxy error',
      message: error instanceof Error ? error.message : 'Failed to forward request to Supabase',
    }), {
      status: 502,
      headers: { 'Content-Type': 'application/json' },
    });
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // Handle CORS preflight
    const corsResponse = handleCorsPreFlight(request);
    if (corsResponse) return corsResponse;

    // Handle Supabase API requests
    return handleSupabaseRequest(request, env);
  },
} satisfies ExportedHandler<Env>;
