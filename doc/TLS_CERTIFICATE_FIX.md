# TLS Certificate Fix Guide

## Problem

Backend was returning 503 "Service unavailable" errors when trying to validate authentication tokens with Supabase.

### Root Cause

The error was caused by a **self-signed certificate in the certificate chain**. This typically happens when:

- Running behind a corporate proxy that intercepts HTTPS traffic
- Using a corporate firewall that performs SSL inspection
- Network security software inserting its own certificates

Node.js by default validates SSL/TLS certificates and rejects self-signed certificates for security reasons.

### Error Details

```
TypeError: fetch failed
  cause: Error: self-signed certificate in certificate chain
  code: 'SELF_SIGNED_CERT_IN_CHAIN'
```

## Solution

### Development Environment (Current Fix)

For development purposes, we've disabled TLS certificate verification in the backend by setting the `NODE_TLS_REJECT_UNAUTHORIZED` environment variable to `0`.

**File:** `backend/src/index.ts`

```typescript
// Fix for corporate proxy/firewall with self-signed certificates
// WARNING: This disables TLS verification - only for development!
// In production, properly configure trusted certificates instead
if (process.env.NODE_ENV !== "production") {
  process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
  console.warn("⚠️  TLS certificate verification disabled for development");
  console.warn(
    "   This is required if behind a corporate proxy with self-signed certificates",
  );
  console.warn("   Do NOT use this in production!");
}
```

### Production Environment (Recommended)

For production deployments, you should **NOT** disable certificate verification. Instead:

#### Option 1: Add Corporate CA Certificate (Recommended)

1. Get your organization's root CA certificate (usually available from IT department)
2. Add it to Node.js trusted certificates:

```typescript
import https from "https";
import fs from "fs";

const corporateCACert = fs.readFileSync("./path/to/corporate-ca-cert.pem");

const httpsAgent = new https.Agent({
  ca: corporateCACert,
});

// Use this agent for Supabase client
export const supabaseAdmin = createClient(
  env.SUPABASE_URL,
  env.SUPABASE_SERVICE_ROLE_KEY,
  {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
    global: {
      fetch: (url, options) => {
        return fetch(url, {
          ...options,
          agent: httpsAgent,
        });
      },
    },
  },
);
```

#### Option 2: System-Wide Certificate Installation

1. Install the corporate CA certificate in the system's trusted certificate store
2. For Windows: Use `certmgr.msc` to import to "Trusted Root Certification Authorities"
3. For Linux: Copy to `/usr/local/share/ca-certificates/` and run `update-ca-certificates`
4. For macOS: Use Keychain Access to add to System keychain

#### Option 3: Configure Proxy Settings

If using a corporate proxy, configure Node.js to use it properly:

```bash
# Set proxy environment variables
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080
export NODE_EXTRA_CA_CERTS=/path/to/corporate-ca-cert.pem
```

## Testing the Fix

### 1. Test Supabase Connection

Run the connection test script:

```bash
cd backend
node test-supabase-connection.js
```

**Expected output (before fix):**

```
❌ CONNECTION ERROR - Cannot reach Supabase
Error: self-signed certificate in certificate chain
```

**Expected output (after fix):**

```
✅ CONNECTION OK - Got expected auth error (not connection error)
Error: invalid JWT (this is expected for test token)
```

### 2. Test Profile Creation

Start the backend and frontend:

```bash
.\start-all.ps1
```

Then test profile creation in the app:

1. Sign up with a new account
2. Log in
3. Fill out profile setup form
4. Click "Save Profile"
5. Should successfully create profile without 503 error

### 3. Run Automated Integration Test

```bash
.\run-profile-setup-test.ps1
```

This will automatically test the complete profile creation flow.

## Security Considerations

### ⚠️ Why This is a Development-Only Fix

Disabling TLS certificate verification (`NODE_TLS_REJECT_UNAUTHORIZED=0`) is **dangerous in production** because:

1. **Man-in-the-Middle Attacks**: Attackers can intercept and modify traffic
2. **Data Exposure**: Sensitive data (passwords, tokens) can be stolen
3. **Compliance Violations**: Fails security audits and compliance requirements (PCI DSS, HIPAA, etc.)

### ✅ Safe for Development

This fix is acceptable for development because:

1. Only applies when `NODE_ENV !== 'production'`
2. Development environment is behind corporate firewall (already trusted network)
3. No production data or real user credentials involved
4. Alternative would prevent development entirely

### Production Deployment Checklist

Before deploying to production:

- [ ] Remove `NODE_TLS_REJECT_UNAUTHORIZED` setting or ensure it only applies in development
- [ ] Configure proper CA certificates if needed
- [ ] Test SSL/TLS connection in production environment
- [ ] Verify certificate validation is working
- [ ] Run security audit on deployed application

## Related Files

- `backend/src/index.ts` - TLS fix implementation
- `backend/test-supabase-connection.js` - Connection test script
- `backend/src/middleware/auth.ts` - Auth middleware using Supabase connection
- `backend/src/config/supabase.ts` - Supabase client configuration

## Troubleshooting

### Still getting 503 errors after fix?

1. **Check if NODE_ENV is set correctly:**

   ```bash
   # Should be empty or 'development' for local development
   echo $env:NODE_ENV
   ```

2. **Verify backend was restarted:**

   ```bash
   .\stop-all.ps1
   .\start-all.ps1
   ```

3. **Check backend logs for TLS warning:**
   - Should see: `⚠️  TLS certificate verification disabled for development`

4. **Test connection directly:**
   ```bash
   cd backend
   node test-supabase-connection.js
   ```

### Different certificate error?

If you see a different certificate error like `UNABLE_TO_VERIFY_LEAF_SIGNATURE` or `CERT_HAS_EXPIRED`, the same fix applies.

### Production deployment fails?

Make sure the `NODE_ENV` environment variable is set to `'production'` in your deployment environment. The TLS fix will automatically NOT apply in production.

## References

- [Node.js TLS Documentation](https://nodejs.org/api/tls.html)
- [Supabase JS Client Documentation](https://supabase.com/docs/reference/javascript/initializing)
- [Corporate Proxy SSL Inspection](https://en.wikipedia.org/wiki/TLS_interception)

## Change History

- **2024-02-17**: Initial fix implemented for corporate proxy TLS issue
- Added TLS rejection bypass for development environment
- Created connection test script
- Added warnings and documentation
