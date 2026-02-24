# Vercel Auto-Deployment Setup Guide

## Current Status

✅ **CI Tests**: Passing (no critical errors)  
⚠️ **Auto-Deployment**: Needs configuration  
✅ **vercel.json**: Configured correctly

---

## Why Commits Aren't Auto-Deploying

Auto-deployment from GitHub to Vercel requires proper integration. Here's how to fix it:

### Solution: Connect GitHub Repository to Vercel

1. **Go to Vercel Dashboard**
   - Visit: https://vercel.com/dashboard
   - Sign in with your GitHub account

2. **Import Your Repository**
   - Click **"Add New..."** → **"Project"**
   - Select **GitHub** as the source
   - Find and import: `ManiKumar007/FamilyTree`

3. **Configure Project Settings**
   
   **Framework Preset**: Other (or None)
   
   **Root Directory**: Leave empty (we have root vercel.json)
   
   **Build & Development Settings**:
   - Build Command: `cd app && export PATH="$PATH:$HOME/flutter/bin" && chmod +x build.sh && bash build.sh`
   - Output Directory: `app/build/web`
   - Install Command: `git clone https://github.com/flutter/flutter.git -b stable --depth 1 ~/flutter`
   
   **Environment Variables** (Add these):
   ```
   SUPABASE_URL=https://vojwwcolmnbzogsrmwap.supabase.co
   SUPABASE_ANON_KEY=<your-anon-key>
   API_BASE_URL=https://backend-five-blue-16.vercel.app/api
   APP_URL=https://familytree-web.vercel.app
   GOOGLE_CLIENT_ID=<your-google-client-id>
   ```

4. **Deploy**
   - Click **"Deploy"**
   - Vercel will build and deploy your app
   - Future commits to `master` will auto-deploy

---

## Vercel GitHub Integration Settings

After initial setup, verify integration:

1. **Go to Project Settings**
   - Your Vercel project → **Settings** → **Git**

2. **Check Integration Settings**:
   - ✅ **Production Branch**: `master` (or `main`)
   - ✅ **Auto-Deploy**: Enabled
   - ✅ **Deploy Hooks**: Optional (for manual triggers)

3. **Branch Protection** (Optional but recommended):
   - Enable **"Ignored Build Step"** for branches other than master
   - This prevents deploying from feature branches

---

## Ensure CI Tests Pass on Every Commit

### Current GitHub Actions Workflow

Location: `.github/workflows/ci.yml`

**What it tests**:
1. ✅ Flutter build (errors only, ignores warnings)
2. ✅ Backend TypeScript compilation
3. ✅ Backend build

### Fixing Common CI Failures

#### 1. Flutter Analyze Errors

If Flutter analyze fails:
```bash
# Run locally to see errors
cd app
flutter analyze --no-fatal-infos --no-fatal-warnings

# Fix any ERROR-level issues (WARN and INFO are ignored)
```

#### 2. Backend TypeScript Errors

If TypeScript compilation fails:
```bash
# Run locally
cd backend
npx tsc --noEmit

# Fix any type errors
```

#### 3. Missing Dependencies

If build fails due to missing packages:

**Flutter**:
```bash
cd app
flutter pub get
flutter pub upgrade
```

**Backend**:
```bash
cd backend
npm install
```

---

## Vercel Configuration Files

### Root `vercel.json` (Current)
```json
{
  "version": 2,
  "buildCommand": "cd app && export PATH=\"$PATH:$HOME/flutter/bin\" && chmod +x build.sh && bash build.sh",
  "outputDirectory": "app/build/web",
  "installCommand": "git clone https://github.com/flutter/flutter.git -b stable --depth 1 ~/flutter",
  "framework": null,
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

### App `app/vercel.json` (Backup config)
Used if deploying from `app/` directory directly.

---

## Deployment Checklist

Before each deployment, ensure:

- [ ] All tests pass locally
- [ ] GitHub Actions CI is green ✅
- [ ] Environment variables are set in Vercel
- [ ] No `.env` files committed to Git
- [ ] `vercel.json` is correct
- [ ] Flutter dependencies are up to date

---

## Manual Deployment (Alternative)

If auto-deployment isn't working, deploy manually:

### Using Vercel CLI

1. **Install Vercel CLI**:
   ```bash
   npm install -g vercel
   ```

2. **Login**:
   ```bash
   vercel login
   ```

3. **Deploy**:
   ```bash
   vercel --prod
   ```

### Using GitHub Actions Deployment

Add this to `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Vercel

on:
  push:
    branches: [master]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
          working-directory: ./
```

---

## Troubleshooting

### Issue: Build Fails with "Flutter not found"

**Solution**: Vercel's install command should clone Flutter. If it fails:
- Check `installCommand` in vercel.json
- Verify build logs in Vercel dashboard
- Ensure build.sh is executable

### Issue: "No Output Directory found"

**Solution**: We already fixed this! 
- Root vercel.json points to `app/build/web`
- If issue persists, set Root Directory to `app` in Vercel Settings

### Issue: Environment Variables Not Working

**Solution**:
- Add all env vars in Vercel Dashboard → Settings → Environment Variables
- Add for both Production and Preview environments
- Redeploy after adding

### Issue: CI Passes but Vercel Deploy Fails

**Solution**:
- CI uses placeholder env vars
- Vercel needs real env vars
- Check Vercel build logs for specific errors
- Ensure all npm/flutter dependencies are specified correctly

---

## Monitoring Deployments

### Check Deployment Status

1. **Vercel Dashboard**: https://vercel.com/dashboard
2. **GitHub Actions**: https://github.com/ManiKumar007/FamilyTree/actions
3. **Deployment Logs**: Vercel project → Deployments → Click deployment → Logs

### Enable Notifications

1. **Vercel**: Settings → Notifications → Enable GitHub comments
2. **GitHub**: Enable email notifications for Actions

---

## Summary

**To fix auto-deployment**:
1. Import repository to Vercel via dashboard
2. Configure build settings (or it reads from vercel.json)
3. Add environment variables
4. Enable GitHub integration

**To ensure CI passes**:
1. Run tests locally before committing
2. Fix any errors (warnings are allowed)
3. Keep dependencies updated

**Current status**:
- ✅ vercel.json configured
- ✅ CI workflow configured
- ✅ No blocking errors
- ⏳ Needs: Vercel GitHub integration setup
