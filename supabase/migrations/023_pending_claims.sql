-- ============================================
-- 023: Pending Claims
-- Purpose: Store profile-claim requests that require approval from the
--          original tree owner before the auth_user_id is linked.
-- ============================================

CREATE TABLE IF NOT EXISTS pending_claims (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  person_id           UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
  claimed_by_user_id  UUID NOT NULL,   -- auth user ID of the person claiming
  created_by_user_id  UUID,            -- auth user ID of the original tree owner
  status              TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'approved', 'rejected', 'expired', 'auto_approved')),
  approve_token       UUID NOT NULL DEFAULT gen_random_uuid(),
  reject_token        UUID NOT NULL DEFAULT gen_random_uuid(),
  profile_updates     JSONB DEFAULT '{}',
  claimant_email      TEXT,            -- stored so we can notify claimant on outcome
  created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at          TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '7 days'),
  resolved_at         TIMESTAMPTZ
);

-- Only one active pending claim per person at a time
CREATE UNIQUE INDEX idx_pending_claims_person_pending
  ON pending_claims(person_id)
  WHERE (status = 'pending');

CREATE INDEX idx_pending_claims_approve_token ON pending_claims(approve_token);
CREATE INDEX idx_pending_claims_reject_token  ON pending_claims(reject_token);
CREATE INDEX idx_pending_claims_status        ON pending_claims(status);
CREATE INDEX idx_pending_claims_claimant      ON pending_claims(claimed_by_user_id);
CREATE INDEX idx_pending_claims_expires_at    ON pending_claims(expires_at) WHERE (status = 'pending');

-- Backend accesses this table via the service-role key only.
-- Disable direct client access via RLS.
ALTER TABLE pending_claims ENABLE ROW LEVEL SECURITY;
CREATE POLICY "No direct client access" ON pending_claims USING (false);
