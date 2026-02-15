-- ============================================
-- MyFamilyTree: Merge Requests table
-- ============================================

CREATE TYPE merge_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

CREATE TABLE merge_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Who is requesting the merge
  requester_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- The existing person in the DB (target tree)
  target_person_id UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
  
  -- The person in the requester's tree that matches
  matched_person_id UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
  
  -- Status
  status merge_status DEFAULT 'PENDING',
  
  -- Stores differing fields for conflict resolution UI
  -- e.g., {"date_of_birth": {"target": "1990-01-01", "matched": "1990-06-15"}}
  field_conflicts JSONB DEFAULT '{}',
  
  -- Resolution details
  resolved_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  resolved_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  
  -- Prevent duplicate merge requests for same pair
  CONSTRAINT unique_merge_pair UNIQUE (target_person_id, matched_person_id)
);

CREATE INDEX idx_merge_requester ON merge_requests(requester_user_id);
CREATE INDEX idx_merge_status ON merge_requests(status);
CREATE INDEX idx_merge_target ON merge_requests(target_person_id);
