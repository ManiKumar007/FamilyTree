-- ============================================
-- Fix: Inverse relationship gender bug
--
-- Problem: When creating "A is CHILD_OF B" and B's gender is 'other',
-- the trigger defaults to FATHER_OF instead of a gender-neutral type.
--
-- Solution: Add PARENT_OF enum value and update the trigger to use it
-- when gender is unknown/other.
-- ============================================

-- Add PARENT_OF to the relationship_type enum
ALTER TYPE relationship_type ADD VALUE IF NOT EXISTS 'PARENT_OF';

-- Update the helper function to handle PARENT_OF
CREATE OR REPLACE FUNCTION inverse_relationship(rel_type relationship_type)
RETURNS relationship_type AS $$
BEGIN
  CASE rel_type
    WHEN 'FATHER_OF' THEN RETURN 'CHILD_OF';
    WHEN 'MOTHER_OF' THEN RETURN 'CHILD_OF';
    WHEN 'PARENT_OF' THEN RETURN 'CHILD_OF';
    WHEN 'CHILD_OF' THEN
      -- Cannot determine FATHER_OF vs MOTHER_OF from CHILD_OF alone;
      -- default to gender-neutral PARENT_OF
      RETURN 'PARENT_OF';
    WHEN 'SPOUSE_OF' THEN RETURN 'SPOUSE_OF';
    WHEN 'SIBLING_OF' THEN RETURN 'SIBLING_OF';
  END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Replace the trigger function to use PARENT_OF for unknown/other gender
CREATE OR REPLACE FUNCTION create_inverse_relationship()
RETURNS TRIGGER AS $$
DECLARE
  inv_type relationship_type;
BEGIN
  CASE NEW.type
    WHEN 'FATHER_OF' THEN inv_type := 'CHILD_OF';
    WHEN 'MOTHER_OF' THEN inv_type := 'CHILD_OF';
    WHEN 'PARENT_OF' THEN inv_type := 'CHILD_OF';
    WHEN 'CHILD_OF' THEN
      -- Determine if parent is father or mother based on their gender
      SELECT CASE WHEN gender = 'male' THEN 'FATHER_OF'::relationship_type
                  WHEN gender = 'female' THEN 'MOTHER_OF'::relationship_type
                  ELSE 'PARENT_OF'::relationship_type
             END INTO inv_type
      FROM persons WHERE id = NEW.related_person_id;
    WHEN 'SPOUSE_OF' THEN inv_type := 'SPOUSE_OF';
    WHEN 'SIBLING_OF' THEN inv_type := 'SIBLING_OF';
  END CASE;

  -- Insert inverse row (ignore if already exists)
  INSERT INTO relationships (person_id, related_person_id, type, created_by_user_id)
  VALUES (NEW.related_person_id, NEW.person_id, inv_type, NEW.created_by_user_id)
  ON CONFLICT (person_id, related_person_id, type) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
