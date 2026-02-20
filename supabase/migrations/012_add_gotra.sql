-- ============================================
-- MyFamilyTree: Add gotra field to persons table
-- ============================================

-- Add gotra column
ALTER TABLE persons ADD COLUMN gotra TEXT;

-- Create index for gotra for better query performance
CREATE INDEX idx_persons_gotra ON persons(gotra);

-- Comment
COMMENT ON COLUMN persons.gotra IS 'Gotra (clan/lineage) of the person, commonly used in Indian communities';
