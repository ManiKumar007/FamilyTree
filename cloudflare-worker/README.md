# Cloudflare Worker Proxy for Supabase

This directory contains a Cloudflare Worker that proxies all Supabase API requests through Cloudflare's global network. This is useful for bypassing regional blocking (especially in India).

## Quick Start

```bash
# Install dependencies
npm install

# Authenticate with Cloudflare
wrangler auth

# Deploy to production
npm run deploy:production

# Or deploy to staging
npm run deploy:staging

# View logs
npm run logs
```

## What It Does

The worker intercepts all HTTPS requests to Supabase and forwards them through Cloudflare's network. This allows users in blocked regions to access Supabase services.

### Supported Paths

- `/rest/v1/*` - REST API
- `/auth/v1/*` - Authentication API
- `/realtime/v1/*` - Realtime API

### CORS Support

The worker automatically adds CORS headers to all responses, allowing requests from your frontend application.

## Configuration

Environment variables are set via `wrangler.toml`:

```toml
[env.production]
name = "familytree-supabase-proxy-prod"
route = "https://supabase-proxy.yourdomain.com/*"

[env.staging]
name = "familytree-supabase-proxy-staging"
route = "https://supabase-proxy-staging.yourdomain.com/*"
```

## Deployment

### Option 1: Cloudflare Workers Subdomain (Free)

```bash
wrangler deploy --env production
```

Your worker will be available at: `https://familytree-supabase-proxy.your-subdomain.workers.dev`

### Option 2: Custom Domain

1. Add your domain to Cloudflare
2. Update `wrangler.toml` with your domain and zone ID
3. Deploy: `wrangler deploy --env production`

## Usage

Update your application to use the proxy URL:

### Backend (Node.js)

```env
SUPABASE_PROXY_URL=https://familytree-supabase-proxy.your-subdomain.workers.dev
```

### Frontend (Flutter)

```bash
flutter build web \
  --dart-define=SUPABASE_PROXY_URL='https://familytree-supabase-proxy.your-subdomain.workers.dev'
```

## Monitoring

```bash
# View real-time logs
wrangler tail --env production

# Check deployments
wrangler deployments list

# View analytics
# Visit: https://dash.cloudflare.com/workers
```

## Security

- All requests are encrypted (HTTPS)
- Authorization headers are preserved
- Service role keys should never be used from frontend
- Invalid paths are rejected with 403

## Testing

```bash
# Test the proxy directly
curl -X GET "https://your-proxy-url/rest/v1/users?limit=1" \
  -H "Authorization: Bearer your_anon_key"

# Or use the verification script
node ../scripts/verify-proxy.js
```

## Troubleshooting

**502 Bad Gateway**: Supabase URL is incorrect or service is down
**403 Forbidden**: Missing or invalid authorization header
**CORS Errors**: Check browser console, worker should handle CORS
**Timeouts**: Worker has 30s limit on free tier, upgrade to paid for longer operations

## Links

- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
- [Supabase API Docs](https://supabase.com/docs/reference)
- [Setup Guide](../doc/CLOUDFLARE_PROXY_SETUP.md)
