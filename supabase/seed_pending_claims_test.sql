-- ============================================================
-- Pending Claims Feature — Test Seed Data
-- Run this in Supabase SQL Editor (or supabase db execute)
-- BEFORE running, replace the two placeholder UUIDs below
-- with real user IDs from your auth.users table.
-- ============================================================
-- How to find user IDs:
--   Supabase Dashboard → Authentication → Users → copy the UUID
-- ============================================================

-- ── STEP 1: set the two test-user IDs ──────────────────────
DO $$
DECLARE
  -- The tree OWNER (person A who originally added these profiles)
  -- Replace with a real auth.users UUID from Supabase dashboard
  v_owner_id    UUID := 'REPLACE_WITH_TREE_OWNER_USER_ID';

  -- The CLAIMANT (person B who is signing up and claiming)
  -- Replace with a different real auth.users UUID
  v_claimant_id UUID := 'REPLACE_WITH_CLAIMANT_USER_ID';

  -- Fixed tokens so you can test approve/reject URLs deterministically
  v_approve_token UUID := 'aaaaaaaa-0001-0001-0001-000000000001';
  v_reject_token  UUID := 'bbbbbbbb-0002-0002-0002-000000000002';
  v_approve2_token UUID := 'cccccccc-0003-0003-0003-000000000003';
  v_reject2_token  UUID := 'dddddddd-0004-0004-0004-000000000004';
  v_expire_token   UUID := 'eeeeeeee-0005-0005-0005-000000000005';

  v_person1_id UUID;
  v_person2_id UUID;
  v_person3_id UUID;
BEGIN

-- ── STEP 2: insert three claimable persons ────────────────
-- Person 1: no auth_user_id — pending claim will be created below
INSERT INTO persons (name, phone, email, gender, city, state, occupation,
                     date_of_birth, created_by_user_id, is_alive)
VALUES ('Arjun Test (Pending Claim)', '+919000000001', 'claimant.test@example.com',
        'male', 'Bangalore', 'Karnataka', 'Engineer',
        '1990-04-01', v_owner_id, true)
ON CONFLICT (phone) DO NOTHING;
SELECT id INTO v_person1_id FROM persons WHERE phone = '+919000000001';

-- Person 2: for testing the REJECT flow
INSERT INTO persons (name, phone, email, gender, city, state,
                     created_by_user_id, is_alive)
VALUES ('Meena Test (Reject Flow)', '+919000000002', 'reject.test@example.com',
        'female', 'Mumbai', 'Maharashtra', v_owner_id, true)
ON CONFLICT (phone) DO NOTHING;
SELECT id INTO v_person2_id FROM persons WHERE phone = '+919000000002';

-- Person 3: for testing the AUTO-APPROVE (expired) flow
INSERT INTO persons (name, phone, email, gender, city, state,
                     created_by_user_id, is_alive)
VALUES ('Suresh Test (Auto-Approve)', '+919000000003', 'autotest@example.com',
        'male', 'Chennai', 'Tamil Nadu', v_owner_id, true)
ON CONFLICT (phone) DO NOTHING;
SELECT id INTO v_person3_id FROM persons WHERE phone = '+919000000003';

-- ── STEP 3: insert pending_claims records ─────────────────
-- Claim 1 — ACTIVE (7 days from now), waiting for approval
DELETE FROM pending_claims WHERE person_id = v_person1_id;
INSERT INTO pending_claims (person_id, claimed_by_user_id, created_by_user_id,
                             approve_token, reject_token,
                             profile_updates, claimant_email,
                             status, expires_at)
VALUES (v_person1_id, v_claimant_id, v_owner_id,
        v_approve_token, v_reject_token,
        '{"given_name": "Arjun", "surname": "Test", "occupation": "Engineer"}',
        'claimant.test@example.com',
        'pending', now() + interval '7 days');

-- Claim 2 — ACTIVE, for reject-flow testing
DELETE FROM pending_claims WHERE person_id = v_person2_id;
INSERT INTO pending_claims (person_id, claimed_by_user_id, created_by_user_id,
                             approve_token, reject_token,
                             claimant_email, status, expires_at)
VALUES (v_person2_id, v_claimant_id, v_owner_id,
        v_approve2_token, v_reject2_token,
        'claimant.test@example.com',
        'pending', now() + interval '7 days');

-- Claim 3 — EXPIRED (created 8 days ago), triggers auto-approve on next check
DELETE FROM pending_claims WHERE person_id = v_person3_id;
INSERT INTO pending_claims (person_id, claimed_by_user_id, created_by_user_id,
                             approve_token, reject_token,
                             claimant_email, status,
                             created_at, expires_at)
VALUES (v_person3_id, v_claimant_id, v_owner_id,
        v_expire_token, gen_random_uuid(),
        'autotest@example.com',
        'pending',
        now() - interval '8 days',   -- created 8 days ago
        now() - interval '1 day');   -- expired yesterday

RAISE NOTICE '==============================================';
RAISE NOTICE 'Seed complete. Test tokens:';
RAISE NOTICE '';
RAISE NOTICE 'APPROVE (Claim 1): %', v_approve_token;
RAISE NOTICE 'REJECT  (Claim 2): %', v_reject_token;
RAISE NOTICE 'REJECT  (Claim 2): %', v_reject2_token;
RAISE NOTICE 'EXPIRE  (Claim 3 - auto approve): %', v_expire_token;
RAISE NOTICE '';
RAISE NOTICE 'Person 1 ID: %', v_person1_id;
RAISE NOTICE 'Person 2 ID: %', v_person2_id;
RAISE NOTICE 'Person 3 ID: %', v_person3_id;
RAISE NOTICE '==============================================';

END $$;
