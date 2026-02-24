# 🚀 Quick Deployment Guide - Render.com

## Prerequisites
- [x] Code pushed to GitHub
- [ ] Render.com account ([sign up free](https://render.com))
- [ ] Supabase credentials ready

## 5-Minute Deploy (Using Render MCP)

If you have the Render MCP configured, you can use it to deploy. Otherwise, follow the manual steps below.

### Option 1: Automatic Deploy with render.yaml

1. **Login to Render.com**
   ```
   https://render.com
   ```

2. **Create New Blueprint**
   - Click "New +" → "Blueprint"
   - Connect GitHub: `ManiKumar007/FamilyTree`
   - Render will detect `render.yaml` automatically

3. **Configure Environment Variables**
   
   In Render Dashboard → Backend Service → Environment:
   ```
   SUPABASE_URL=https://vojwwcolmnbzogsrmwap.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=[your_service_key]
   SUPABASE_ANON_KEY=[your_anon_key]
   NODE_ENV=production
   PORT=10000
   ```

4. **Update Frontend to Point to Backend**
   
   After backend deploys, get its URL (e.g., `https://familytree-backend.onrender.com`)
   
   Create `app/.env` file:
   ```env
   SUPABASE_URL=https://vojwwcolmnbzogsrmwap.supabase.co
   SUPABASE_ANON_KEY=[your_anon_key]
   API_BASE_URL=https://familytree-backend.onrender.com/api
   ```
   
   Commit and push:
   ```bash
   git add app/.env
   git commit -m "Add production environment config"
   git push origin master
   ```

5. **Deploy!**
   - Click "Apply" in Render dashboard
   - Wait 10-15 minutes for initial deploy
   - Frontend: `https://familytree-web.onrender.com`
   - Backend: `https://familytree-backend.onrender.com`

### Option 2: Manual Service Creation

#### Backend First

1. Render Dashboard → "New +" → "Web Service"
2. Connect GitHub repo
3. Settings:
   - **Name**: `familytree-backend`
   - **Root Directory**: `backend`
   - **Build Command**: `npm install && npm run build`
   - **Start Command**: `npm start`
   - **Add Environment Variables** (see above)

#### Frontend Second

1. Render Dashboard → "New +" → "Static Site"
2. Connect same GitHub repo
3. Settings:
   - **Name**: `familytree-web`
   - **Build Command**:
     ```bash
     git clone https://github.com/flutter/flutter.git -b stable --depth 1 && \
     export PATH="$PATH:`pwd`/flutter/bin" && \
     cd app && \
     flutter pub get && \
     flutter build web --release --web-renderer canvaskit && \
     cp -r build/web/* ../public/
     ```
   - **Publish Directory**: `public`
   - **Rewrite Rule**: `/*` → `/index.html`

## Post-Deployment

### Update Supabase CORS

1. Go to Supabase Dashboard → Settings → API
2. Add to **Redirect URLs**:
   ```
   https://familytree-web.onrender.com/**
   ```
3. Set **Site URL**:
   ```
   https://familytree-web.onrender.com
   ```

### Test Deployment

```bash
# Test backend
curl https://familytree-backend.onrender.com/api/health

# Expected response:
# {"status":"ok","timestamp":"...","service":"familytree-backend","version":"1.1.0"}
```

Open frontend: `https://familytree-web.onrender.com`

## Common Issues

**Backend won't start**
- Check environment variables are set
- View logs: Service → Logs tab

**Frontend shows blank page**
- Check browser console for errors
- Verify API_BASE_URL points to backend
- Check rewrite rule is configured

**CORS errors**
- Add frontend URL to backend CORS (already configured)
- Add frontend URL to Supabase allowed origins

## Free Tier Limits

- Services spin down after 15 min inactivity
- Cold start: 30-60 seconds
- Upgrade to $7/month Starter plan for always-on backend

## Support

- Detailed guide: `DEPLOYMENT.md`
- Render docs: https://render.com/docs
- Run pre-deployment checks: `.\deploy-check.ps1`

---

**Deployment Time**: ~15-20 minutes first time  
**Zero-downtime updates**: Every git push to master auto-deploys
