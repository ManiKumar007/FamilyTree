# Migration Guide: Enable Cloudflare Proxy for Supabase

This guide helps you migrate your existing FamilyTree application to use the Cloudflare Worker proxy for Supabase.

## Overview

The proxy setup requires minimal code changes. The existing codebase was already designed to support a proxy layer through environment variables.

## Step 1: Deploy the Cloudflare Worker

### For Windows Users (PowerShell)

```powershell
# Run the helper script
.\scripts\deploy-proxy.ps1

# Or use the interactive menu and select option 8 (Run All Setup Steps)
```

### For Mac/Linux Users

```bash
# Install Wrangler
npm install -g wrangler

# Authenticate
wrangler auth

# Deploy
cd cloudflare-worker
npm install
npm run deploy:production
```

**Note the deployed worker URL** from the output. It will look like:

```
familytree-supabase-proxy.your-subdomain.workers.dev
```

## Step 2: Update Backend Configuration

The backend files have been updated to support the proxy. You need to:

1. **Copy the new configuration files** (these support proxy):

   ```bash
   # These files are already in the repo:
   backend/src/config/env.ts       # Updated with SUPABASE_PROXY_URL
   backend/src/config/supabase.ts  # Updated with proxy logic
   ```

2. **Update your .env file**:

   ```bash
   cd backend

   # Add this line (replace with your actual worker URL)
   SUPABASE_PROXY_URL=https://familytree-supabase-proxy.your-subdomain.workers.dev

   # Keep existing variables
   SUPABASE_URL=https://vojwwcolmnbzogsrmwap.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=your_key
   SUPABASE_ANON_KEY=your_key
   ```

3. **No code changes needed** - The existing code automatically uses the proxy if `SUPABASE_PROXY_URL` is set.

## Step 3: Update Frontend Configuration

### For Flutter Web

1. **Update your build command** to include the proxy URL:

   ```bash
   cd app

   flutter build web \
     --dart-define=SUPABASE_URL='https://vojwwcolmnbzogsrmwap.supabase.co' \
     --dart-define=SUPABASE_PROXY_URL='https://familytree-supabase-proxy.your-subdomain.workers.dev' \
     --dart-define=SUPABASE_ANON_KEY='your_anon_key'
   ```

2. **Or create a .env file** in the `app` directory:

   ```env
   SUPABASE_URL=https://vojwwcolmnbzogsrmwap.supabase.co
   SUPABASE_PROXY_URL=https://familytree-supabase-proxy.your-subdomain.workers.dev
   SUPABASE_ANON_KEY=your_anon_key
   ```

3. **The app initialization** is already configured to use the proxy. Update main.dart if not already done:

   ```dart
   import 'package:myfamilytree/config/supabase_config.dart';

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();

     // Initialize Supabase with proxy support
     await SupabaseConfig.initialize();

     runApp(const MyApp());
   }
   ```

## Step 4: Test the Setup

### Quick Test

```bash
# Using the verification script
node scripts/verify-proxy.js

# Expected output:
# ✓ Direct Supabase: SUCCESS
# ✓ Cloudflare Proxy: SUCCESS
```

### Manual Test

```bash
# Test the proxy endpoint
curl -X GET "https://your-proxy-url/rest/v1/users?limit=1" \
  -H "Authorization: Bearer your_anon_key"

# Should return JSON response
```

### Application Test

1. Start backend: `npm run dev` (from backend directory)
2. Start frontend: `flutter run` (from app directory)
3. Try logging in - should work through proxy
4. Check browser console for "[Supabase] Using proxy URL: ..." message

## Step 5: Deploy to Production

### Deploy Backend to Vercel

```bash
cd backend

# Set environment variables in Vercel project settings
# SUPABASE_PROXY_URL=your-worker-url
# SUPABASE_ANON_KEY=your-key
# SUPABASE_SERVICE_ROLE_KEY=your-key

vercel --prod --yes
```

### Deploy Frontend to Vercel

```bash
cd app

# Build with proxy URL
flutter build web \
  --dart-define=SUPABASE_PROXY_URL='your-worker-url' \
  --dart-define=SUPABASE_ANON_KEY='your-key'

# Deploy
vercel --prod
```

## Fallback to Direct Connection

If for any reason you want to disable the proxy:

### Backend

Remove or clear `SUPABASE_PROXY_URL` from .env. The app will automatically use `SUPABASE_URL`.

### Frontend

Don't pass `--dart-define=SUPABASE_PROXY_URL` when building. The app will use the direct URL.

## Advanced Configuration

### Use Custom Domain for Proxy

If you want a nicer domain name:

1. Add your domain to Cloudflare
2. Update `cloudflare-worker/wrangler.toml`:
   ```toml
   [env.production]
   route = "https://supabase-proxy.yourdomain.com/*"
   zone_id = "your-zone-id"
   ```
3. Redeploy: `npm run deploy:production`

### Monitor Proxy Usage

View real-time logs:

```bash
cd cloudflare-worker
wrangler tail --env production
```

Check analytics in Cloudflare dashboard:
https://dash.cloudflare.com/workers

## Troubleshooting

### Proxy returns 502 Bad Gateway

- Verify `SUPABASE_URL` is correct
- Check Supabase service status
- Try direct connection first: remove `SUPABASE_PROXY_URL` and test

### CORS errors in browser

- Ensure worker has CORS headers (it does - check Network tab)
- May indicate connection issue to Supabase

### Timeout errors

- Cloudflare Workers free tier has 30 second limit
- For longer operations, upgrade to paid plan
- Or split queries into smaller pieces

### Connection still doesn't work in India

- Verify proxy URL is accessible: `curl https://your-proxy-url`
- Ensure anon key is correct
- Try from a different network (VPN, mobile hotspot)
- Contact Cloudflare support if worker is down

## Files Modified/Added

```
✓ cloudflare-worker/src/index.ts        - Worker implementation
✓ cloudflare-worker/wrangler.toml       - Worker configuration
✓ cloudflare-worker/package.json        - Dependencies
✓ cloudflare-worker/README.md           - Worker documentation
✓ backend/src/config/env.ts             - Added SUPABASE_PROXY_URL
✓ backend/src/config/supabase.ts        - Added proxy logic
✓ app/lib/config/supabase_config.dart   - Flutter proxy support
✓ doc/CLOUDFLARE_PROXY_SETUP.md         - Full setup guide
✓ doc/CLOUDFLARE_QUICK_START.md         - Quick reference
✓ scripts/verify-proxy.js               - Verification script
✓ scripts/deploy-proxy.ps1              - Windows deployment helper
```

## Support

If you encounter issues:

1. Check the logs: `wrangler tail --env production`
2. Verify your Cloudflare Worker is deployed
3. Test with curl to isolate the issue
4. Review [CLOUDFLARE_PROXY_SETUP.md](./CLOUDFLARE_PROXY_SETUP.md) for detailed troubleshooting

## Questions?

- Cloudflare Workers: https://developers.cloudflare.com/workers/
- Supabase: https://supabase.com/docs
- This project: See [CLOUDFLARE_PROXY_SETUP.md](./CLOUDFLARE_PROXY_SETUP.md)
