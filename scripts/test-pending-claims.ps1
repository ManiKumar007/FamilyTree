# ============================================================
# Test script: Pending Claims feature
# Tests all three scenarios: Approve, Reject, Auto-Approve
# ============================================================
# Prerequisites:
#   1. Run supabase/seed_pending_claims_test.sql first
#   2. Set $BackendUrl below (local or Vercel)
#   3. Set $AuthToken to a valid JWT for the CLAIMANT user
#      (copy from Flutter DevTools → Supabase client → session.accessToken
#       OR from Supabase Dashboard → SQL Editor: select * from auth.sessions;)
# ============================================================

param(
    [string]$BackendUrl  = "http://localhost:3000",
    [string]$AuthToken   = "REPLACE_WITH_CLAIMANT_JWT",
    # From seed_pending_claims_test.sql output (NOTICE lines)
    [string]$ApproveToken = "aaaaaaaa-0001-0001-0001-000000000001",
    [string]$RejectToken  = "dddddddd-0004-0004-0004-000000000004",
    [string]$PersonId1    = "REPLACE_WITH_PERSON1_ID",  # from NOTICE output
    [string]$PersonId3    = "REPLACE_WITH_PERSON3_ID"   # expired claim person
)

$Headers = @{
    "Authorization" = "Bearer $AuthToken"
    "Content-Type"  = "application/json"
}

function Write-Section($title) {
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Cyan
}

function Invoke-Test($name, $method, $url, $body = $null, [switch]$NoAuth) {
    Write-Host "`n>> $name" -ForegroundColor Yellow
    Write-Host "   $method $url" -ForegroundColor DarkGray
    try {
        $params = @{
            Method  = $method
            Uri     = $url
            Headers = if ($NoAuth) { @{"Content-Type" = "application/json"} } else { $Headers }
        }
        if ($body) { $params.Body = ($body | ConvertTo-Json) }
        $resp = Invoke-WebRequest @params -ErrorAction Stop -MaximumRedirection 0
        Write-Host "   Status: $($resp.StatusCode)" -ForegroundColor Green
        try {
            $json = $resp.Content | ConvertFrom-Json
            Write-Host "   Body:   $($json | ConvertTo-Json -Depth 4 -Compress)" -ForegroundColor White
        } catch {
            Write-Host "   Body:   $($resp.Content.Substring(0,[Math]::Min(200,$resp.Content.Length)))" -ForegroundColor White
        }
    } catch {
        $code = $_.Exception.Response.StatusCode.value__
        if ($code -in 301,302,307,308) {
            $loc = $_.Exception.Response.Headers.Location
            Write-Host "   Redirect ($code) → $loc" -ForegroundColor Magenta
        } else {
            Write-Host "   ERROR: $($_.Exception.Message)" -ForegroundColor Red
            try {
                $errBody = $_.ErrorDetails.Message | ConvertFrom-Json
                Write-Host "   Detail: $($errBody | ConvertTo-Json -Compress)" -ForegroundColor Red
            } catch {}
        }
    }
}

# ── 1. Health check ───────────────────────────────────────────────────────
Write-Section "1. Health Check"
Invoke-Test "Backend health" GET "$BackendUrl/api/health" -NoAuth

# ── 2. Claim-profile → pending response ──────────────────────────────────
Write-Section "2. POST /claim-profile  (should return status='pending')"
Invoke-Test "Submit claim for Person 1" POST "$BackendUrl/api/persons/claim-profile" @{
    person_id       = $PersonId1
    email           = "claimant.test@example.com"
    profile_updates = @{ given_name = "Arjun"; surname = "Test" }
}

# ── 3. my-pending-claim — active ─────────────────────────────────────────
Write-Section "3. GET /my-pending-claim  (hasPendingClaim=true)"
Invoke-Test "Check pending status" GET "$BackendUrl/api/persons/my-pending-claim"

# ── 4. Claim-profile duplicate → still-pending response ──────────────────
Write-Section "4. POST /claim-profile again  (should return same pending status)"
Invoke-Test "Re-submit same claim" POST "$BackendUrl/api/persons/claim-profile" @{
    person_id = $PersonId1
}

# ── 5. Approve via email-link token ──────────────────────────────────────
Write-Section "5. GET /claim-approve/:token  (simulates tree-owner clicking email link)"
Write-Host "   Open this URL in your browser, or hit it with curl:" -ForegroundColor DarkGray
Write-Host "   $BackendUrl/api/persons/claim-approve/$ApproveToken" -ForegroundColor White
Invoke-Test "Approve claim (no auth, token-based)" GET "$BackendUrl/api/persons/claim-approve/$ApproveToken" -NoAuth

# ── 6. my-pending-claim after approval ───────────────────────────────────
Write-Section "6. GET /my-pending-claim  (should now be hasPendingClaim=false)"
Invoke-Test "Check status after approval" GET "$BackendUrl/api/persons/my-pending-claim"

# ── 7. Reject via email-link token ───────────────────────────────────────
Write-Section "7. GET /claim-reject/:token  (reject flow)"
Invoke-Test "Reject claim (no auth, token-based)" GET "$BackendUrl/api/persons/claim-reject/$RejectToken" -NoAuth

# ── 8. Approve an already-processed token ────────────────────────────────
Write-Section "8. GET /claim-approve  on already-used token  (should redirect with claim_already_processed)"
Invoke-Test "Re-approve used token" GET "$BackendUrl/api/persons/claim-approve/$ApproveToken" -NoAuth

# ── 9. Auto-approve (expired claim via Check-Status) ─────────────────────
Write-Section "9. GET /my-pending-claim  for expired claim  (should autoApprove=true)"
Write-Host "   Note: This requires Person 3's claim to be the newest for this user." -ForegroundColor DarkGray
Write-Host "         If Person 1's claim was just approved it won't be pending anymore." -ForegroundColor DarkGray
Write-Host "         Run seed_pending_claims_test.sql again with a fresh claimant user if needed." -ForegroundColor DarkGray
Invoke-Test "Check expired claim (auto-approve)" GET "$BackendUrl/api/persons/my-pending-claim"

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Green
Write-Host "  Test run complete." -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Green
Write-Host ""
Write-Host "Manual steps also worth checking:" -ForegroundColor Cyan
Write-Host "  1. In the Flutter app, enter phone '+919000000001' during profile setup"
Write-Host "     → ClaimProfileScreen should show Person 1 as a match"
Write-Host "     → Tap 'Yes, this is me' → should show Awaiting Approval screen"
Write-Host "  2. Open: $BackendUrl/api/persons/claim-approve/$ApproveToken in browser"
Write-Host "     → Should redirect to /tree?claim_approved=true"
Write-Host "  3. Back in Flutter app, tap 'Check Status' → should navigate to /tree"
Write-Host ""
