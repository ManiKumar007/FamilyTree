-- ============================================
-- MyFamilyTree: Relationships table
-- ============================================

CREATE TYPE relationship_type AS ENUM (
  'FATHER_OF',
  'MOTHER_OF',
  'CHILD_OF',
  'SPOUSE_OF',
  'SIBLING_OF'
);

-- Relationships: directed edges between persons
-- We store BIDIRECTIONAL rows for easy recursive CTE traversal
-- e.g., if A is FATHER_OF B, we also store B is CHILD_OF A
CREATE TABLE relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  person_id UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
  related_person_id UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
  type relationship_type NOT NULL,
  created_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),

  -- Prevent duplicate relationships
  CONSTRAINT unique_relationship UNIQUE (person_id, related_person_id, type),
  -- Prevent self-referencing
  CONSTRAINT no_self_relationship CHECK (person_id != related_person_id)
);

-- Indexes for fast traversal in both directions
CREATE INDEX idx_rel_person ON relationships(person_id);
CREATE INDEX idx_rel_related ON relationships(related_person_id);
CREATE INDEX idx_rel_type ON relationships(type);
CREATE INDEX idx_rel_person_type ON relationships(person_id, type);

-- ============================================
-- Helper function: get the inverse relationship type
-- ============================================
CREATE OR REPLACE FUNCTION inverse_relationship(rel_type relationship_type)
RETURNS relationship_type AS $$
BEGIN
  CASE rel_type
    WHEN 'FATHER_OF' THEN RETURN 'CHILD_OF';
    WHEN 'MOTHER_OF' THEN RETURN 'CHILD_OF';
    WHEN 'CHILD_OF' THEN
      -- We can't determine FATHER_OF vs MOTHER_OF from CHILD_OF alone
      -- The caller should handle this; default to FATHER_OF
      RETURN 'FATHER_OF';
    WHEN 'SPOUSE_OF' THEN RETURN 'SPOUSE_OF';
    WHEN 'SIBLING_OF' THEN RETURN 'SIBLING_OF';
  END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================
-- Trigger: auto-create inverse relationship row
-- ============================================
CREATE OR REPLACE FUNCTION create_inverse_relationship()
RETURNS TRIGGER AS $$
DECLARE
  inv_type relationship_type;
BEGIN
  -- Determine inverse type
  CASE NEW.type
    WHEN 'FATHER_OF' THEN inv_type := 'CHILD_OF';
    WHEN 'MOTHER_OF' THEN inv_type := 'CHILD_OF';
    WHEN 'CHILD_OF' THEN
      -- Determine if parent is father or mother based on their gender
      SELECT CASE WHEN gender = 'male' THEN 'FATHER_OF'::relationship_type
                  WHEN gender = 'female' THEN 'MOTHER_OF'::relationship_type
                  ELSE 'FATHER_OF'::relationship_type
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

CREATE TRIGGER trigger_inverse_relationship
  AFTER INSERT ON relationships
  FOR EACH ROW
  EXECUTE FUNCTION create_inverse_relationship();
