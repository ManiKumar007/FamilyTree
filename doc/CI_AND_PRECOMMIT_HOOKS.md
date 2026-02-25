# GitHub CI & Pre-Commit Hooks Setup

## What GitHub CI Tests Are Running

Every push to `master` triggers these checks:

### 1. **Flutter Web Build**
- ✅ `flutter analyze --no-fatal-infos --no-fatal-warnings`
- ✅ `flutter build web --release`

### 2. **Backend Build**
- ✅ `npx tsc --noEmit` (TypeScript type checking)
- ✅ `npm run build` (Compile to JavaScript)

**Note:** Currently NO E2E tests are running in CI. Tests are validation/build checks only.

---

## Pre-Commit Hook Now Installed! ✅

The hook runs **the same checks as GitHub CI** before allowing commits.

### What It Does

When you run `git commit`:
1. Detects which files changed (.dart or backend files)
2. Runs **Flutter analyze** if Dart files changed
3. Runs **TypeScript check** if backend files changed
4. Blocks the commit if any errors found

### Files Created

- `scripts/pre-commit.ps1` - PowerShell pre-commit hook
- `scripts/setup-git-hooks.ps1` - Installation script
- `.git/hooks/pre-commit` - Active hook (auto-installed)

### How to Use

**Normal commits** (hook runs automatically):
```powershell
git add .
git commit -m "your message"  # Hook validates before commit
```

**Skip validation** (emergency only):
```powershell
git commit --no-verify -m "hotfix"
```

**Test the hook manually**:
```powershell
pwsh scripts\pre-commit.ps1
```

**Reinstall the hook** (if needed):
```powershell
.\scripts\setup-git-hooks.ps1
```

---

## Why CI May Be Failing

Common reasons GitHub CI fails:

### 1. **Flutter Analyze Errors**
```
flutter analyze --no-fatal-infos --no-fatal-warnings
```
- Type errors
- Null safety issues  
- Unused imports
- Missing @override annotations

**Fix:** Run locally: `cd app; flutter analyze`

### 2. **TypeScript Compilation Errors**
```
npx tsc --noEmit
```
- Type mismatches
- Missing imports
- Invalid syntax

**Fix:** Run locally: `cd backend; npx tsc --noEmit`

### 3. **Build Failures**
- Missing dependencies
- Outdated package-lock.json
- Platform-specific issues

**Fix:** 
```powershell
cd app; flutter pub get; flutter build web
cd backend; npm ci; npm run build
```

---

## Quick Local Validation

Run the same checks as CI before pushing:

```powershell
# Full validation
.\scripts\pre-commit.ps1

# Or run individual checks:
cd app
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter build web

cd ..\backend  
npx tsc --noEmit
npm run build
```

---

## Future: Adding E2E Tests to CI

Currently, E2E tests exist in `e2e-tests/` but don't run in CI.

To add them to GitHub Actions, update `.github/workflows/ci.yml`:

```yaml
  e2e-tests:
    name: E2E Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: cd e2e-tests && npm ci
      - run: npx playwright install --with-deps
      - run: npm test
```

---

## Troubleshooting

**Hook not running?**
```powershell
# Reinstall
.\scripts\setup-git-hooks.ps1

# Check if installed
Get-Content .git\hooks\pre-commit
```

**Want to disable temporarily?**
```powershell
# Rename to disable
Rename-Item .git\hooks\pre-commit .git\hooks\pre-commit.disabled

# Rename back to enable
Rename-Item .git\hooks\pre-commit.disabled .git\hooks\pre-commit
```

---

**Last updated:** 2026-02-25
