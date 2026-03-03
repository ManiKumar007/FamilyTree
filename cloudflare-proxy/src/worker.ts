/**
 * Cloudflare Worker - Supabase Reverse Proxy
 * 
 * Bypasses ISP-level blocks on Supabase API domains in India.
 * Acts as a transparent proxy: all requests to this worker are forwarded
 * to the actual Supabase project URL.
 * 
 * How it works:
 *   User → Cloudflare Worker (unblocked) → Supabase (blocked by ISP)
 * 
 * Deploy: cd cloudflare-proxy && npx wrangler deploy
 * The worker URL becomes your new SUPABASE_URL in the app.
 * 
 * Based on the "Jiobase" approach described in:
 * https://analyticsindiamag.com/global-tech/indias-supabase-block-leaves-developers-and-startups-scrambling
 */

export interface Env {
  SUPABASE_URL: string;
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const supabaseUrl = env.SUPABASE_URL;

    if (!supabaseUrl) {
      return new Response(
        JSON.stringify({ error: 'SUPABASE_URL not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Parse the incoming request URL
    const url = new URL(request.url);

    // Build the target Supabase URL preserving path and query params
    const targetUrl = new URL(url.pathname + url.search, supabaseUrl);

    // Clone headers, replacing the Host header with Supabase's host
    const headers = new Headers(request.headers);
    headers.set('Host', new URL(supabaseUrl).host);
    // Remove Cloudflare-specific headers that might cause issues
    headers.delete('cf-connecting-ip');
    headers.delete('cf-ipcountry');
    headers.delete('cf-ray');
    headers.delete('cf-visitor');

    // Forward the request to Supabase
    const supabaseResponse = await fetch(targetUrl.toString(), {
      method: request.method,
      headers: headers,
      body: request.method !== 'GET' && request.method !== 'HEAD'
        ? request.body
        : undefined,
      redirect: 'follow',
    });

    // Clone the response and add CORS headers
    const responseHeaders = new Headers(supabaseResponse.headers);

    // Allow the requesting origin (or * for simplicity in dev)
    const origin = request.headers.get('Origin');
    if (origin) {
      responseHeaders.set('Access-Control-Allow-Origin', origin);
    } else {
      responseHeaders.set('Access-Control-Allow-Origin', '*');
    }
    responseHeaders.set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
    responseHeaders.set('Access-Control-Allow-Headers', 'Authorization, Content-Type, apikey, x-client-info, x-supabase-api-version');
    responseHeaders.set('Access-Control-Allow-Credentials', 'true');
    responseHeaders.set('Access-Control-Expose-Headers', 'Content-Range, X-Supabase-Api-Version');

    // Handle CORS preflight (OPTIONS)
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: responseHeaders,
      });
    }

    return new Response(supabaseResponse.body, {
      status: supabaseResponse.status,
      statusText: supabaseResponse.statusText,
      headers: responseHeaders,
    });
  },
};
