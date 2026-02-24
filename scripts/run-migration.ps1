# Run Database Migration: Add given_name and surname columns
# This script provides the SQL to run in Supabase SQL Editor

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Database Migration Required" -ForegroundColor Yellow
Write-Host "==================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "The 'given_name' column is missing from the persons table." -ForegroundColor White
Write-Host "You need to run migration 011_add_given_name_surname.sql" -ForegroundColor White

Write-Host ""
Write-Host "==== STEPS TO FIX ====" -ForegroundColor Green

Write-Host ""
Write-Host "1. Open Supabase Dashboard:" -ForegroundColor Cyan
Write-Host "   https://supabase.com/dashboard/project/vojwwcolmnbzogsrmwap" -ForegroundColor Gray

Write-Host ""
Write-Host "2. Go to SQL Editor (left sidebar)" -ForegroundColor Cyan

Write-Host ""
Write-Host "3. Copy and paste this SQL:" -ForegroundColor Cyan
Write-Host "   ----------------------------------------" -ForegroundColor Gray

$sql = @"
-- Add given_name and surname columns to persons
ALTER TABLE persons
  ADD COLUMN IF NOT EXISTS given_name TEXT,
  ADD COLUMN IF NOT EXISTS surname TEXT;

-- Populate given_name from existing name (best-effort split)
-- First word -> given_name, rest -> surname
UPDATE persons
SET
  given_name = split_part(name, ' ', 1),
  surname    = CASE
    WHEN position(' ' in name) > 0
      THEN substring(name from position(' ' in name) + 1)
    ELSE NULL
  END
WHERE given_name IS NULL;

-- Make given_name NOT NULL going forward
ALTER TABLE persons ALTER COLUMN given_name SET NOT NULL;

-- Create index on surname for search
CREATE INDEX IF NOT EXISTS idx_persons_surname ON persons(surname);
"@

Write-Host $sql -ForegroundColor Yellow
Write-Host "   ----------------------------------------" -ForegroundColor Gray

Write-Host ""
Write-Host "4. Click 'Run' to execute the migration" -ForegroundColor Cyan

Write-Host ""
Write-Host "5. After successful migration, try adding a family member again!" -ForegroundColor Green

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan

# Copy SQL to clipboard
$sql | Set-Clipboard
Write-Host ""
Write-Host " SQL copied to clipboard! Just paste it in Supabase SQL Editor." -ForegroundColor Green
Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan

