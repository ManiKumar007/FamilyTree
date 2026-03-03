# Cloudflare Proxy Architecture & Flow Diagrams

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        INTERNET (Global)                            │
└─────────────────────────────────────────────────────────────────────┘
                    ↑                           ↑
                    │                           │
        ┌───────────┘                           └───────────┐
        │                                                   │
        ▼                                                   ▼
   ┌──────────────┐                          ┌─────────────────────┐
   │   Frontend   │                          │  Cloudflare Edge    │
   │   (Flutter)  │                          │  (Global Network)   │
   │              │          BLOCKED         │                     │
   │  Users in    │──────────────X────────▶ │  • Caches           │
   │  India       │     Direct Connection   │  • Proxies requests │
   │              │                          │  • Adds CORS headers│
   └──────────────┘                          └──────────┬──────────┘
                                                        │
        ┌───────────────────────────────────────────────┘
        │
        ▼
   ┌──────────────┐        UNBLOCKED       ┌──────────────────────┐
   │   Backend    │                        │    Supabase          │
   │  (Vercel)    │◄──────────────────────▶│  (vojwwcolmnbzogsrmw)│
   │              │   Worker Proxy Used    │                      │
   │              │                        │  • Database          │
   │              │                        │  • Auth              │
   └──────────────┘                        │  • Realtime          │
        ▲                                  │  • Storage           │
        │                                  └──────────────────────┘
        │
        └──── Uses Proxy When Available
             Falls back to Direct URL
```

## Request Flow: With Cloudflare Proxy

```
SCENARIO: User in India trying to access Supabase

1. Frontend Request
   ┌─────────────────────────────────────────┐
   │ User clicks "Login" button              │
   │→ App calls Supabase Auth endpoint       │
   │→ Checks for SUPABASE_PROXY_URL          │
   │→ Found: Use proxy URL                   │
   └─────────────────────────────────────────┘

2. Request to Cloudflare Worker
   GET https://familytree-supabase-proxy.workers.dev/auth/v1/signup
   Headers: Authorization: Bearer <anon-key>
   Body: { email: "user@example.com", password: "..." }

3. Worker Processes Request
   ┌─────────────────────────────────────────┐
   │ Worker receives request                 │
   │ ✓ Validate path (/auth/v1/signup)       │
   │ ✓ Check authorization header            │
   │ ✓ Forward to Supabase                   │
   │   GET https://vojwwcolmnbzogsrmwap    │
   │       .supabase.co/auth/v1/signup       │
   └─────────────────────────────────────────┘

4. Supabase Response
   ← Response: { session: {...}, user: {...} }

5. Worker Adds CORS Headers
   ┌─────────────────────────────────────────┐
   │ Response Headers added:                 │
   │ • Access-Control-Allow-Origin: *        │
   │ • Access-Control-Allow-Methods: ...     │
   │ • Access-Control-Allow-Headers: ...     │
   │ • Content-Type: application/json        │
   └─────────────────────────────────────────┘

6. Frontend Gets Response
   ← Returns to app
   → User successfully logged in!
```

## Request Flow: Direct Connection (Fallback)

```
SCENARIO: Direct Supabase connection available OR proxy not configured

1. Frontend Request
   ┌─────────────────────────────────────────┐
   │ User clicks "Login" button              │
   │→ App calls Supabase Auth endpoint       │
   │→ Checks for SUPABASE_PROXY_URL          │
   │→ Not set: Use direct URL                │
   └─────────────────────────────────────────┘

2. Request to Supabase (Direct)
   GET https://vojwwcolmnbzogsrmwap.supabase.co/auth/v1/signup
   Headers: Authorization: Bearer <anon-key>
   Body: { email: "user@example.com", password: "..." }

3. Supabase Response
   ← Response: { session: {...}, user: {...} }

4. Frontend Gets Response
   ← Returns to app
   → User successfully logged in!
```

## Deployment Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    DEVELOPMENT ENVIRONMENT                   │
│                                                               │
│  Your Machine                                                │
│  ├── backend/ → npm run dev → localhost:3000                │
│  ├── app/ → flutter run → localhost:8080                    │
│  └── env: SUPABASE_PROXY_URL=local or disabled              │
└──────────────────────────────────────────────────────────────┘

         ║
         ║ git push
         ║
         ▼

┌──────────────────────────────────────────────────────────────┐
│                   CLOUD DEPLOYMENT                           │
│                                                               │
│  Cloudflare                                                  │
│  ├── familytree-supabase-proxy.workers.dev                  │
│  │   └── Proxies all Supabase requests via Cloudflare edge  │
│  └── env: SUPABASE_URL=supa.supabase.co (no proxy needed)   │
│                                                               │
│  Vercel (Backend)                                            │
│  ├── https://familytree-api.vercel.app                      │
│  ├── Uses proxy for Supabase in India                        │
│  └── env: SUPABASE_PROXY_URL=cloudflare-worker-url          │
│                                                               │
│  Vercel (Frontend)                                           │
│  ├── https://familytree-web.vercel.app                      │
│  ├── Requests through proxy for India users                 │
│  └── env: SUPABASE_PROXY_URL=cloudflare-worker-url          │
│                                                               │
│  Supabase (Blocked in India from direct)                    │
│  └── vojwwcolmnbzogsrmwap.supabase.co                       │
│      Response times ↓ when accessed through Cloudflare       │
└──────────────────────────────────────────────────────────────┘

         ║
         ║ Users in India
         ║ Can now access all services
         ║
         ▼

┌──────────────────────────────────────────────────────────────┐
│                      USERS (INDIA)                           │
│                                                               │
│  Mobile App (iOS/Android)                                    │
│  └── Works through proxy! ✓                                  │
│                                                               │
│  Web App (Browser)                                           │
│  └── Works through proxy! ✓                                  │
│                                                               │
│  Backend API                                                 │
│  └── Works through proxy! ✓                                  │
└──────────────────────────────────────────────────────────────┘
```

## Data Flow: Complete Journey

```
┌──────────────────────────────────────────────────────────────┐
│ USER IN INDIA TRIES TO LOGIN                                 │
└──────────────────────────────────────────────────────────────┘
                            │
                            ▼
                  ┌────────────────────┐
                  │ App Initialization │
                  │ (main.dart)        │
                  │                    │
                  │ SupabaseConfig     │
                  │  .initialize()     │
                  └────────────────────┘
                            │
                            ▼
             ┌──────────────────────────────┐
             │ Check Environment Variables: │
             │                              │
             │ SUPABASE_PROXY_URL set?      │
             └──────────────────────────────┘
                    │              │
            YES ▲   │              │   ▼ NO
                │   │              │
            ┌───────────┐    ┌──────────┐
            │ Use       │    │ Use      │
            │ Proxy     │    │ Direct   │
            │ URL       │    │ URL      │
            └─────┬─────┘    └────┬─────┘
                  │               │
                  ▼               ▼
            ┌──────────────────────────┐
            │ Create Supabase Client   │
            │ with selected URL        │
            └──────────┬───────────────┘
                       │
                       ▼
            ┌──────────────────────────┐
            │ User Clicks "Login"      │
            └──────────┬───────────────┘
                       │
                       ▼
         Via Proxy ──────────── Via Direct
              │                │
              ▼                ▼
         ┌──────────┐   ┌────────────┐
         │ CF Worker│   │ Supabase   │
         │ (Global) │   │ (May fail) │
         └────┬─────┘   └┼───────────┘
              │         ✓ or ✗
              ▼
         ┌──────────────────────────┐
         │ Add CORS Headers ✓       │
         │ Validate Authorization ✓ │
         │ Forward to Supabase ✓    │
         └────┬─────────────────────┘
              │
              ▼
         ┌──────────────────────┐
         │ Supabase (Working!)  │
         │ Returns Session ✓    │
         └────┬─────────────────┘
              │
              ▼
       ┌────────────────────┐
       │ Frontend Receives  │
       │ Session Token ✓    │
       │ User Logged In ✓   │
       └────────────────────┘
```

## Technology Stack

```
┌──────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                       │
├──────────────────────────────────────────────────────────────┤
│ • Flutter (Mobile & Web)                                     │
│ • Dart runtime                                               │
│ • HTTPS client (with proxy support)                          │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│                    PROXY/CDN LAYER                           │
├──────────────────────────────────────────────────────────────┤
│ • Cloudflare Workers (Edge Runtime)                          │
│ • Global CDN                                                 │
│ • Request forwarding & header manipulation                   │
│ • CORS handling                                              │
│ • Path validation                                            │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│                    BACKEND API LAYER                         │
├──────────────────────────────────────────────────────────────┤
│ • Node.js + Express                                          │
│ • TypeScript                                                 │
│ • Business logic                                             │
│ • Supabase client integration                                │
│ • Deployed on Vercel                                         │
└────────────────────────┬─────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────┐
│               DATABASE & SERVICES LAYER                       │
├──────────────────────────────────────────────────────────────┤
│ • Supabase PostgreSQL Database                               │
│ • Supabase Authentication                                    │
│ • Supabase Realtime                                          │
│ • Supabase Storage                                           │
│ • Row Level Security (RLS)                                   │
└──────────────────────────────────────────────────────────────┘
```

## Configuration Matrix

```
╔════════════════════════╦═════════════════════════════════════╗
║     ENVIRONMENT        ║      CONFIGURATION                  ║
╠════════════════════════╬═════════════════════════════════════╣
║ Local Development      ║ SUPABASE_PROXY_URL: (empty)        ║
║                        ║ → Uses direct Supabase             ║
║                        ║ → Fast feedback loop               ║
╠════════════════════════╬═════════════════════════════════════╣
║ Staging (Cloudflare)   ║ SUPABASE_PROXY_URL: staging-url    ║
║                        ║ → Tests proxy in production        ║
║                        ║ → Deploys worker-staging           ║
╠════════════════════════╬═════════════════════════════════════╣
║ Production (India)     ║ SUPABASE_PROXY_URL: prod-url       ║
║                        ║ → Users bypass Supabase block      ║
║                        ║ → Deploys worker-production        ║
║                        ║ → Fast response times              ║
╠════════════════════════╬═════════════════════════════════════╣
║ Production (Other)     ║ SUPABASE_PROXY_URL: (or empty)     ║
║                        ║ → Can use proxy or direct          ║
║                        ║ → Proxy adds latency but more      ║
║                        ║   resilient to blocking            ║
╚════════════════════════╩═════════════════════════════════════╝
```

## Failover Logic

```
Request Attempt
     │
     ▼
Is SUPABASE_PROXY_URL set?
     │
     ├─ YES ──▶ Try Proxy URL
     │         │
     │         ├─ Success ──▶ Return Response ✓
     │         │
     │         └─ Failure ──▶ Error (Check worker logs)
     │
     └─ NO ──▶ Try Direct URL
              │
              ├─ Success ──▶ Return Response ✓
              │
              └─ Failure ──▶ Error (Supabase may be blocked)
```

## Performance Comparison

```
DIRECT CONNECTION (India - Blocked)
Request ──▶ Supabase ──▗ BLOCKED ✗
Time: ∞ (connection timeout)

DIRECT CONNECTION (US - Works)
Request ──▶ Supabase ──▶ Response ✓
Time: ~200ms

VIA CLOUDFLARE PROXY (India)
Request ──▶ Cloudflare Edge ──▶ Supabase ──▶ Response ✓
Time: ~150ms (Cached)
      ~250ms (Not cached)

CONCLUSION:
- Proxy solves blocking issue ✓
- Adds minimal latency (50-100ms)
- Cloudflare caching helps with repeated requests
```

---

_For detailed setup instructions, see [CLOUDFLARE_PROXY_SETUP.md](./CLOUDFLARE_PROXY_SETUP.md)_
