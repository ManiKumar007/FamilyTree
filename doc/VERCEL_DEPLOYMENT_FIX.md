# Vercel Deployment Fix - GitHub Actions Approach

## Problem
Vercel's build environment times out when trying to install Flutter and build the web app (>15 minute build limit).

## Solution
Use GitHub Actions to build the Flutter web app, then deploy the pre-built static files to Vercel using Vercel CLI.

## Setup Instructions

### 1. Get Vercel Tokens

1. Go to https://vercel.com/account/tokens
2. Create a new token with name "GitHub Actions Deploy"
3. Copy the token (you'll only see it once)

### 2. Get Vercel Project IDs

Run these commands in your terminal:

```bash
# Install Vercel CLI if not installed
npm i -g vercel

# Link to your Vercel project
cd <your-project-directory>
vercel link

# Get your Organization ID and Project ID
cat .vercel/project.json
```

You'll see output like:
```json
{
  "orgId": "team_xxxxx",
  "projectId": "prj_xxxxx"
}
```

### 3. Add GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:

- `VERCEL_TOKEN` - The token you created in step 1
- `VERCEL_ORG_ID` - The `orgId` from `.vercel/project.json`
- `VERCEL_PROJECT_ID` - The `projectId` from `.vercel/project.json`

Also add your app environment variables (if not already set):
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `API_BASE_URL`
- `APP_URL`
- `GOOGLE_CLIENT_ID`

### 4. How It Works

1. When you push changes to the `app/` directory
2. GitHub Actions workflow triggers (`.github/workflows/deploy-web.yml`)
3. Flutter web app is built in GitHub's environment (no timeout issues)
4. Pre-built static files are deployed to Vercel using Vercel CLI
5. Deployment completes in under 2 minutes

### 5. Manual Deployment

You can also manually build and deploy:

```bash
# Build Flutter web app
cd app
flutter build web --release

# Deploy to Vercel
cd build/web
vercel --prod
```

## Files Changed

- `.github/workflows/deploy-web.yml` - New deployment workflow
- `vercel.json` - Simplified to serve static files only (no build commands)
- `build-web.sh` - No longer needed (GitHub Actions handles build)

## Advantages

✅ No build timeouts
✅ Faster deployments (pre-built)
✅ Better error visibility in GitHub Actions
✅ Can test builds before deployment
✅ Consistent build environment

## Troubleshooting

**Q: Workflow not triggering?**
- Check that you pushed changes to `app/` directory
- Verify workflow file is in `.github/workflows/` 
- Check GitHub Actions tab for errors

**Q: Deployment failing?**
- Verify all secrets are set correctly in GitHub
- Check that VERCEL_PROJECT_ID matches your frontend project (not backend)
- Review GitHub Actions logs for specific errors

**Q: Want to disable GitHub auto-deploy?**
- Comment out or delete `.github/workflows/deploy-web.yml`
- Vercel will still auto-deploy (but builds will timeout)
