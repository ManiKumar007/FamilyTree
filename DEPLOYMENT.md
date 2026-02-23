# MyFamilyTree - Deployment Guide

This guide covers deploying the MyFamilyTree application to **Render.com**.

## 🏗️ Architecture Overview

- **Frontend**: Flutter Web (Static Site)
- **Backend**: Node.js/Express API (Web Service)
- **Database**: Supabase PostgreSQL (Already hosted)
- **Storage**: Supabase Storage (Already hosted)

## 📋 Prerequisites

1. **GitHub Repository**: Code pushed to GitHub (already done ✓)
2. **Render.com Account**: [Sign up for free](https://render.com)
3. **Supabase Credentials**: From your Supabase project dashboard

## 🚀 Deployment Steps

### Option 1: Infrastructure as Code (Recommended)

This method uses the `render.yaml` blueprint file for automatic setup.

1. **Login to Render.com**
   - Go to [render.com](https://render.com) and sign in

2. **Create New Blueprint**
   - Click "New +" → "Blueprint"
   - Connect your GitHub repository: `ManiKumar007/FamilyTree`
   - Render will detect the `render.yaml` file

3. **Configure Environment Variables**
   
   For the **backend service**, set these in Render dashboard:
   ```
   SUPABASE_URL=https://vojwwcolmnbzogsrmwap.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=[Your service role key from Supabase]
   SUPABASE_ANON_KEY=[Your anon key from Supabase]
   NODE_ENV=production
   PORT=10000
   APP_URL=https://familytree-web.onrender.com
   INVITE_BASE_URL=https://familytree-web.onrender.com/invite
   ```

4. **Update Frontend URL**
   - After backend deploys, note its URL (e.g., `https://familytree-backend.onrender.com`)
   - Update `app/lib/config/constants.dart`:
     ```dart
     static const String apiBaseUrl = 
       kIsWeb && !kDebugMode
         ? 'https://familytree-backend.onrender.com'
         : 'http://localhost:3000';
     ```
   - Commit and push the change

5. **Deploy**
   - Click "Apply" to deploy both services
   - Backend will deploy first (~3-5 minutes)
   - Frontend will deploy next (~10-15 minutes due to Flutter build)

### Option 2: Manual Setup

#### Deploy Backend

1. **Create Web Service**
   - Dashboard → "New +" → "Web Service"
   - Connect GitHub repo
   - Name: `familytree-backend`
   - Region: Oregon (or your choice)
   - Branch: `master`
   - Root Directory: `backend`
   - Runtime: Node
   - Build Command: `npm install && npm run build`
   - Start Command: `npm start`
   - Plan: Free (or Starter for production)

2. **Add Environment Variables** (same as above)

3. **Add Health Check**
   - Health Check Path: `/api/health`

#### Deploy Frontend

1. **Create Static Site**
   - Dashboard → "New +" → "Static Site"
   - Connect same GitHub repo
   - Name: `familytree-web`
   - Region: Oregon (same as backend)
   - Branch: `master`
   - Build Command:
     ```bash
     git clone https://github.com/flutter/flutter.git -b stable --depth 1 && \
     export PATH="$PATH:`pwd`/flutter/bin" && \
     cd app && \
     flutter pub get && \
     flutter build web --release --web-renderer canvaskit && \
     cp -r build/web/* ../public/
     ```
   - Publish Directory: `public`

2. **Configure Redirects**
   - Add rewrite rule: `/*` → `/index.html`
   - This enables client-side routing

## 🔧 Post-Deployment Configuration

### 1. Update Supabase CORS Settings

Add your Render URLs to Supabase allowed origins:

1. Go to Supabase Dashboard → Settings → API
2. Under "URL Configuration" → "Site URL", add:
   - `https://familytree-web.onrender.com`
3. Under "Redirect URLs", add:
   - `https://familytree-web.onrender.com/**`

### 2. Update Backend CORS in Code

Edit `backend/src/index.ts` to allow your frontend:

```typescript
const corsOptions = {
  origin: [
    'http://localhost:5500',
    'https://familytree-web.onrender.com'  // Add your production URL
  ],
  credentials: true
};
```

### 3. Configure Custom Domain (Optional)

**Backend:**
- Render Dashboard → Backend Service → Settings → Custom Domain
- Add: `api.yourdomain.com`
- Update DNS with provided CNAME records

**Frontend:**
- Render Dashboard → Frontend Service → Settings → Custom Domain
- Add: `yourdomain.com` or `www.yourdomain.com`
- Update DNS with provided CNAME records

Then update all references to use your custom domains.

## 📊 Monitoring & Logs

### View Logs
- Render Dashboard → Service → Logs tab
- Real-time logs for debugging

### Monitor Health
- Backend: `https://familytree-backend.onrender.com/api/health`
- Should return: `{"status":"ok","timestamp":"..."}`

### Common Issues

**Backend not starting:**
- Check environment variables are set correctly
- View logs for error messages
- Verify Supabase credentials

**Frontend 404 errors:**
- Ensure rewrite rule is configured: `/*` → `/index.html`
- Check build logs for Flutter build errors

**CORS errors:**
- Verify backend CORS settings include frontend URL
- Check Supabase allowed origins

## 💰 Cost Estimates

### Free Tier (Perfect for Testing)
- Backend: Free
- Frontend: Free
- **Limitations**:
  - Spins down after 15 min of inactivity
  - Cold start: 30-60 seconds
  - 750 hrs/month

### Production Tier (Recommended)
- Backend: $7/month (Starter plan)
- Frontend: Free (static sites are always free)
- **Benefits**:
  - Always on (no cold starts)
  - Custom domains
  - Automatic SSL
  - Better performance

## 🔄 Continuous Deployment

Once configured, every push to `master` branch triggers:
1. Automatic build
2. Automatic deployment
3. Zero-downtime updates

To deploy only specific commits:
- Use manual deploy in Render dashboard
- Or configure a deployment branch (e.g., `production`)

## 🛡️ Security Checklist

- [ ] All secrets set as environment variables (not in code)
- [ ] HTTPS enabled (automatic with Render)
- [ ] CORS properly configured
- [ ] Supabase RLS policies enabled
- [ ] Rate limiting configured (already in backend)
- [ ] Helmet.js security headers active (already in backend)

## 🧪 Testing Production

1. **Test Backend API:**
   ```bash
   curl https://familytree-backend.onrender.com/api/health
   ```

2. **Test Frontend:**
   - Open `https://familytree-web.onrender.com`
   - Check browser console for errors
   - Test login/signup flow
   - Verify API calls work

3. **Test Full Flow:**
   - Create account
   - Add family members
   - Upload photos
   - Create forum posts
   - Verify emails/notifications

## 📱 Mobile App Deployment

For Flutter mobile apps (Android/iOS):
- Build APK/IPA locally
- Deploy to Google Play Store / Apple App Store
- Update backend URL in app config
- See `FLUTTER_INIT.md` for mobile build instructions

## 🔧 Environment Variables Reference

### Backend (Required)
| Variable | Description | Example |
|----------|-------------|---------|
| `NODE_ENV` | Environment | `production` |
| `PORT` | Server port | `10000` |
| `SUPABASE_URL` | Supabase project URL | `https://xxx.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key (secret!) | `eyJhbGci...` |
| `SUPABASE_ANON_KEY` | Anonymous key | `eyJhbGci...` |
| `APP_URL` | Frontend URL | `https://familytree-web.onrender.com` |
| `INVITE_BASE_URL` | Invite link base | `${APP_URL}/invite` |

### Frontend (Build-time)
All configuration is baked into the build via `constants.dart`. For production, update:
- `apiBaseUrl` to point to production backend
- Rebuild and redeploy

## 📞 Support

- **Render Support**: [render.com/docs](https://render.com/docs)
- **Supabase Support**: [supabase.com/docs](https://supabase.com/docs)
- **App Issues**: Check GitHub issues or create new one

---

**Last Updated**: February 23, 2026  
**Version**: 1.1
