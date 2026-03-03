# Code Quality & Error Prevention Guide

## Problem
TypeScript errors (like `.is_()` instead of `.is()`) can slip through to production if not caught during development.

## Multi-Layer Protection Strategy

### Layer 1: IDE/Editor Integration (Real-time)
**VS Code Settings** (`.vscode/settings.json`):
```json
{
  "typescript.tsdk": "backend/node_modules/typescript/lib",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "eslint.workingDirectories": ["backend"],
  "typescript.enablePromptUseWorkspaceTsdk": true
}
```

**Benefits**: Catches errors as you type before committing.

### Layer 2: Pre-Commit Hooks (Local)
**Location**: [scripts/pre-commit.ps1](../scripts/pre-commit.ps1)

**What it checks**:
- ✅ TypeScript compilation (`npx tsc --noEmit`)
- ✅ ESLint warnings/errors (`npm run lint`)
- ✅ Flutter analyze for Dart files

**Installation** (if not already installed):
```powershell
# Windows
Copy-Item scripts\pre-commit .git\hooks\pre-commit -Force

# Linux/Mac
cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**⚠️ Important**: Pre-commit hooks can be bypassed with:
```bash
git commit --no-verify  # ❌ This skips all pre-commit checks!
```

### Layer 3: CI/CD Checks (GitHub Actions)
**Location**: [.github/workflows/pr-checks.yml](../.github/workflows/pr-checks.yml)

**Runs on**: Every push and pull request

**What it checks**:
- TypeScript compilation
- ESLint
- Unit tests
- Flutter analyze

**Benefits**: 
- Cannot be bypassed
- Runs in clean environment
- Blocks deployment on failure

### Layer 4: Build-time Checks (Deployment)
**Location**: [.github/workflows/deploy-backend.yml](../.github/workflows/deploy-backend.yml)

**What it checks**:
- Full TypeScript build (`npm run build`)
- Vercel deployment preparation

**Benefits**: Final safety net before production deployment.

## Setup Instructions

### 1. Install ESLint Dependencies
```powershell
cd backend
npm install
```

This installs:
- `eslint`
- `@typescript-eslint/parser`
- `@typescript-eslint/eslint-plugin`

### 2. Configure VS Code
Create `.vscode/settings.json` in workspace root:
```json
{
  "typescript.tsdk": "backend/node_modules/typescript/lib",
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true
  },
  "eslint.validate": ["typescript"],
  "eslint.workingDirectories": ["backend", "app"]
}
```

### 3. Verify Pre-Commit Hook
```powershell
# Check if installed
Test-Path .git\hooks\pre-commit

# Test it by making a change
cd backend\src\routes
# Make a syntax error, try to commit
git add .
git commit -m "test"  # Should fail if error exists
```

### 4. Test ESLint
```powershell
cd backend
npm run lint
```

### 5. Enable CI Checks
The PR checks workflow is now active. It will run on every push to master or any pull request.

## Best Practices

### ✅ DO
- Let pre-commit hooks run (don't use `--no-verify`)
- Fix TypeScript errors before committing
- Review CI check results before merging
- Use descriptive commit messages that explain what was fixed
- Run `npm run lint` manually before committing large changes

### ❌ DON'T
- Don't use `git commit --no-verify` unless absolutely necessary
- Don't ignore ESLint warnings (they often indicate real issues)
- Don't push directly to master without CI checks passing
- Don't disable TypeScript strict mode
- Don't use `@ts-ignore` to suppress errors without understanding them

## Troubleshooting

### "Pre-commit hook not running"
```powershell
# Reinstall the hook
Copy-Item scripts\pre-commit .git\hooks\pre-commit -Force
```

### "ESLint not found"
```powershell
cd backend
npm install
```

### "TypeScript errors in CI but not locally"
```powershell
# Clean install to match CI environment
cd backend
Remove-Item -Recurse -Force node_modules
Remove-Item package-lock.json
npm install
npx tsc --noEmit
```

### "Need to bypass pre-commit for urgent fix"
```powershell
# Only use in emergencies!
git commit --no-verify -m "urgent: description"
# Then immediately create a follow-up PR to fix properly
```

## Summary

With this multi-layer approach:
1. **IDE catches errors** as you type
2. **Pre-commit hook** catches errors before they're committed
3. **CI checks** catch errors before they're deployed
4. **Build process** provides final validation

The `.is_()` typo would have been caught by:
- TypeScript in VS Code (red squiggly line)
- `npx tsc --noEmit` in pre-commit hook
- CI workflow TypeScript check
- Vercel build process

**Most important**: Don't bypass the pre-commit hooks with `--no-verify`!
