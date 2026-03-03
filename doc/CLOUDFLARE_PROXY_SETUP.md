# Cloudflare Worker Proxy for Supabase - Setup Guide

## Overview

This guide helps you set up a Cloudflare Worker proxy to bypass Supabase blocking in India and other regions. The proxy routes all Supabase API requests through Cloudflare's global network, avoiding regional blocks.

## Architecture

```
┌─────────────┐     ┌─────────────────────┐     ┌──────────────┐
│   Frontend  │────▶│ Cloudflare Worker   │────▶│   Supabase   │
│   (Flutter) │     │    (Proxy)          │     │   (Blocked)  │
└─────────────┘     └─────────────────────┘     └──────────────┘

┌─────────────┐     ┌─────────────────────┐     ┌──────────────┐
│   Backend   │────▶│ Cloudflare Worker   │────▶│   Supabase   │
│   (Node.js) │     │    (Proxy)          │     │   (Blocked)  │
└─────────────┘     └─────────────────────┘     └──────────────┘
```

## Prerequisites

1. **Cloudflare Account**
   - Sign up at https://dash.cloudflare.com
   - Add your domain to Cloudflare (if using custom domain)

2. **Wrangler CLI** (for deploying workers)

   ```bash
   npm install -g wrangler
   ```

3. **Supabase Credentials**
   - Supabase URL (e.g., `https://vojwwcolmnbzogsrmwap.supabase.co`)
   - Anon Key
   - Service Role Key

## Step 1: Deploy Cloudflare Worker

### Option A: Deploy to Cloudflare Workers (Free tier available)

1. Install Wrangler (if not already installed):

   ```bash
   npm install -g wrangler
   ```

2. Authenticate with Cloudflare:

   ```bash
   wrangler auth
   ```

3. Deploy the worker:

   ```bash
   cd cloudflare-worker
   npm install
   wrangler deploy
   ```

4. Your worker will be available at: `https://familytree-supabase-proxy.your-subdomain.workers.dev`

### Option B: Use Custom Domain

1. Configure your domain in Cloudflare (https://dash.cloudflare.com)

2. Update `wrangler.toml`:

   ```toml
   [env.production]
   route = "https://supabase-proxy.yourdomain.com/*"
   zone_id = "your-cloudflare-zone-id"
   ```

3. Deploy:
   ```bash
   wrangler deploy --env production
   ```

## Step 2: Set Environment Variables

### For Backend (Node.js/Express)

Create or update `.env` file in the `backend` directory:

```env
# Original Supabase URL (for direct connection)
SUPABASE_URL=https://vojwwcolmnbzogsrmwap.supabase.co

# Proxy URL (uses Cloudflare Worker to bypass blocks)
SUPABASE_PROXY_URL=https://familytree-supabase-proxy.your-subdomain.workers.dev

# OR use custom domain if configured
# SUPABASE_PROXY_URL=https://supabase-proxy.yourdomain.com

# API Keys (unchanged)
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
SUPABASE_ANON_KEY=your_anon_key

# Other existing config...
PORT=3000
NODE_ENV=production
```

### For Frontend (Flutter)

Create `.env` file in the `app` directory:

```env
# Add these build arguments when building
SUPABASE_URL=https://vojwwcolmnbzogsrmwap.supabase.co
SUPABASE_PROXY_URL=https://familytree-supabase-proxy.your-subdomain.workers.dev
SUPABASE_ANON_KEY=your_anon_key
```

Or set environment variables when building:

```bash
flutter build web \
  --dart-define=SUPABASE_URL='https://vojwwcolmnbzogsrmwap.supabase.co' \
  --dart-define=SUPABASE_PROXY_URL='https://familytree-supabase-proxy.your-subdomain.workers.dev' \
  --dart-define=SUPABASE_ANON_KEY='your_anon_key'
```

## Step 3: Update Application Code

### Backend Code

The backend configuration already supports the proxy. Make sure to use the updated files:

```typescript
// src/config/env.ts - Now includes SUPABASE_PROXY_URL
// src/config/supabase.ts - Automatically uses proxy if available
```

The `getSupabaseUrl()` function automatically selects:

- Proxy URL if `SUPABASE_PROXY_URL` is set
- Direct URL otherwise

### Frontend Code

Initialize Supabase with proxy support:

```dart
// In your main.dart or app initialization
import 'package:myfamilytree/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with proxy support
  await SupabaseConfig.initialize();

  runApp(const MyApp());
}
```

## Step 4: Test the Connection

### Test Backend Connection

```bash
# Navigate to backend directory
cd backend

# Test if proxy is working
npm run dev

# In another terminal, test API
curl -X GET "http://localhost:3000/api/health"
```

### Test Frontend Connection

```bash
# Run Flutter app with proxy
flutter run --dart-define=SUPABASE_PROXY_URL='your-worker-url'

# Check console logs for connection status
# Should show: "[Supabase] Using proxy URL: ..."
```

### Direct Proxy Test

```bash
# Test the proxy endpoint directly
curl -X GET "https://your-worker-url/rest/v1/users?limit=1" \
  -H "Authorization: Bearer your_anon_key"
```

## Step 5: Deploy to Production

### Deploy Backend to Vercel

```bash
cd backend
vercel --prod --yes
```

Update Vercel environment variables:

- Set `SUPABASE_PROXY_URL` to your Cloudflare Worker URL
- Keep `SUPABASE_URL` as backup

### Deploy Frontend to Vercel

```bash
cd app/web
vercel --prod --yes
```

Or use Flutter web build:

```bash
flutter build web \
  --dart-define=SUPABASE_PROXY_URL='your-worker-url' \
  --dart-define=SUPABASE_ANON_KEY='your_anon_key'

vercel --prod
```

## Monitoring & Troubleshooting

### View Worker Logs

```bash
wrangler tail --env production
```

### Check Supabase Connectivity

```bash
# From backend
curl -X GET "https://your-proxy-url/rest/v1/users?limit=1" \
  -H "Authorization: Bearer your_anon_key"

# Should return: {"data": [...], "status": 200}
```

### Common Issues

**Issue: 403 Forbidden from Worker**

- Cause: Invalid or missing authorization header
- Fix: Ensure `SUPABASE_ANON_KEY` is correctly set

**Issue: CORS errors**

- Cause: Worker not returning CORS headers
- Fix: Worker automatically handles CORS, check browser console for actual error

**Issue: 502 Bad Gateway**

- Cause: Proxy can't reach Supabase
- Fix: Verify `SUPABASE_URL` is correct and Supabase service is running

**Issue: Connection timeouts**

- Cause: Cloudflare Worker timeout (30 second limit on free tier)
- Fix: For long operations, upgrade to paid Cloudflare plan or use shorter queries

## Performance Considerations

1. **First Request**: Slightly slower due to Cloudflare routing
2. **Subsequent Requests**: Cached at Cloudflare edge (faster for most regions)
3. **Database Queries**: Still limited by Supabase, not the proxy
4. **Free Tier Limits**: 100,000 requests/day on Cloudflare Workers Free

## Security Notes

- ✅ All requests are encrypted in transit (HTTPS)
- ✅ Authorization headers are preserved and forwarded
- ✅ CORS headers are properly configured
- ⚠️ Never expose service role keys in frontend
- ⚠️ Use Row Level Security (RLS) in Supabase for data protection

## Alternative: Direct Regional Supabase Setup

If you want to avoid the proxy entirely, consider:

1. Setting up a Supabase project in the Asia region
2. Using a VPN service that's not blocked
3. Contacting Supabase support for India-specific solutions

## Reference Files

- Cloudflare Worker: [`cloudflare-worker/src/index.ts`](../../cloudflare-worker/src/index.ts)
- Backend Config: [`backend/src/config/env.ts`](../../backend/src/config/env.ts)
- Backend Supabase: [`backend/src/config/supabase.ts`](../../backend/src/config/supabase.ts)
- Flutter Config: [`app/lib/config/supabase_config.dart`](../../app/lib/config/supabase_config.dart)

## Support

For issues:

1. Check Cloudflare Worker logs: `wrangler tail`
2. Verify Supabase status: https://status.supabase.com
3. Test with direct URL to isolate proxy issues
4. Check CORS headers in browser DevTools Network tab
