# Quick Start Guide for Cloudflare Proxy Setup

## 1-Minute Setup

### Prerequisites

```bash
# Install Wrangler CLI
npm install -g wrangler

# Authenticate with Cloudflare
wrangler auth
```

### Deploy Worker

```bash
cd cloudflare-worker
npm install
npm run deploy:production
```

### Configure Backend

```bash
cd backend

# Update .env with proxy URL
# SUPABASE_PROXY_URL=https://familytree-supabase-proxy.your-subdomain.workers.dev
```

### Configure Frontend

```bash
cd app

# Build with proxy URL
flutter build web \
  --dart-define=SUPABASE_PROXY_URL='https://your-worker-url' \
  --dart-define=SUPABASE_ANON_KEY='your-anon-key'
```

## Test Proxy

```bash
# Get the Cloudflare Worker URL from deployment output
# Test with curl
curl -X GET "https://your-worker-url/rest/v1/users?limit=1" \
  -H "Authorization: Bearer your_anon_key"

# Expected: JSON response with users or empty array
```

## Vercel Environment Variables

Set these in Vercel project settings:

| Variable                  | Value                 |
| ------------------------- | --------------------- |
| SUPABASE_URL              | Direct Supabase URL   |
| SUPABASE_PROXY_URL        | Cloudflare Worker URL |
| SUPABASE_ANON_KEY         | Your anon key         |
| SUPABASE_SERVICE_ROLE_KEY | Your service role key |

## Monitoring

```bash
# View real-time logs
wrangler tail --env production

# Check deployment
wrangler deployments list

# Test connectivity
npm run test:proxy
```

See [CLOUDFLARE_PROXY_SETUP.md](CLOUDFLARE_PROXY_SETUP.md) for detailed guide.
