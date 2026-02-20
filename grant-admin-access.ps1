# Grant Admin Access Script
# This script helps you grant admin access to a user

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Grant Admin Access to User" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Copy and run these SQL queries in Supabase SQL Editor:" -ForegroundColor Yellow
Write-Host "https://supabase.com/dashboard/project/vojwwcolmnbzogsrmwap/sql/new`n" -ForegroundColor Cyan

Write-Host "STEP 1: Find your user ID" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host @"
SELECT id, email, created_at 
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 10;
"@ -ForegroundColor White

Write-Host "`nCopy the 'id' value of your Google email from the results.`n" -ForegroundColor Yellow

Write-Host "STEP 2: Insert admin role into user_metadata table" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host "Replace 'YOUR-USER-ID-HERE' with the id from Step 1:`n" -ForegroundColor Yellow
Write-Host @"
INSERT INTO user_metadata (user_id, role, is_active)
VALUES ('YOUR-USER-ID-HERE', 'admin', true)
ON CONFLICT (user_id) DO UPDATE
SET role = 'admin', is_active = true;
"@ -ForegroundColor White

Write-Host "`n" -ForegroundColor Yellow
Write-Host "STEP 3: Verify the record was created" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host @"
SELECT user_id, role, is_active, created_at
FROM user_metadata
ORDER BY created_at DESC
LIMIT 5;
"@ -ForegroundColor White

Write-Host "`n" -ForegroundColor Yellow
Write-Host "STEP 4: Refresh your admin dashboard" -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Gray
Write-Host "Go to: http://localhost:5500/#/admin" -ForegroundColor Cyan
Write-Host "Press F5 to refresh the page" -ForegroundColor White

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Alternative: One-liner (if you know your email)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$email = Read-Host "Enter your Google email (or press Enter to skip)"
if ($email) {
    Write-Host "`nRun this in Supabase SQL Editor:" -ForegroundColor Yellow
    Write-Host @"
-- All-in-one script
DO `$`$
DECLARE
    v_user_id uuid;
BEGIN
    -- Get user ID by email
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE email = '$email'
    LIMIT 1;

    -- Insert or update user_metadata
    IF v_user_id IS NOT NULL THEN
        INSERT INTO user_metadata (user_id, role, is_active)
        VALUES (v_user_id, 'admin', true)
        ON CONFLICT (user_id) DO UPDATE
        SET role = 'admin', is_active = true;
        
        RAISE NOTICE 'Admin role granted to user: %', v_user_id;
    ELSE
        RAISE NOTICE 'User not found with email: $email';
    END IF;
END `$`$;
"@ -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "After running the SQL, refresh your browser!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan
