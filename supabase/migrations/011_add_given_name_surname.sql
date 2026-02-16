-- ============================================
-- Add given_name and surname columns to persons
-- The existing 'name' column becomes a computed display name.
-- ============================================

-- Add new columns (nullable initially for backwards compat)
ALTER TABLE persons
  ADD COLUMN IF NOT EXISTS given_name TEXT,
  ADD COLUMN IF NOT EXISTS surname TEXT;

-- Populate given_name from existing name (best-effort split)
-- First word → given_name, rest → surname
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
