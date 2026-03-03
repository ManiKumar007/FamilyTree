# Cloudflare Worker — Supabase Proxy

## Why?
Indian ISPs (Jio, Airtel, ACT) are blocking Supabase API domains under MeitY's Section 69A order. This Cloudflare Worker acts as a transparent reverse proxy so your app can reach Supabase through Cloudflare's unblocked infrastructure.

**How it works:**
```
User (India) → Cloudflare Worker (unblocked) → Supabase API (blocked by ISP)
```

## Setup (One-time, ~5 minutes)

### 1. Create a free Cloudflare account
Go to [dash.cloudflare.com](https://dash.cloudflare.com) and sign up (no credit card needed).

### 2. Install Wrangler CLI
```bash
npm install -g wrangler
```

### 3. Login to Cloudflare
```bash
wrangler login
```

### 4. Install dependencies
```bash
cd cloudflare-proxy
npm install
```

### 5. Deploy the worker
```bash
npm run deploy
```

This will output a URL like:
```
https://supabase-proxy.<your-account>.workers.dev
```

### 6. Update your environment variables

Replace your `SUPABASE_URL` with the Cloudflare Worker URL everywhere:

#### Flutter app (.env or dart-define)
```
SUPABASE_URL=https://supabase-proxy.<your-account>.workers.dev
```

#### Backend (.env)
```
SUPABASE_URL=https://supabase-proxy.<your-account>.workers.dev
```

#### GitHub Actions secrets
Update the `SUPABASE_URL` secret in your GitHub repo settings.

#### Vercel environment variables
Update `SUPABASE_URL` in both frontend and backend Vercel projects.

## Custom Domain (Optional)
If you want a cleaner URL like `api.familytree.com`:

1. Add a custom domain in Cloudflare Dashboard → Workers → your worker → Triggers → Custom Domains
2. Update all environment variables to use the custom domain

## Testing
```bash
# Test the proxy locally
cd cloudflare-proxy
npm run dev

# Then test with curl
curl http://localhost:8787/rest/v1/ -H "apikey: YOUR_ANON_KEY"
```

## Security Notes
- The worker only proxies requests — it does **not** store or log any data
- All Supabase auth tokens pass through as-is
- CORS headers are set to allow your app origins
- For production, consider restricting `Access-Control-Allow-Origin` to your specific domains

## Reverting (if block is lifted)
Simply change `SUPABASE_URL` back to `https://vojwwcolmnbzogsrmwap.supabase.co` in all environments.
