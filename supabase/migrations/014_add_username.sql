-- Migration: Add username column to persons table
-- Allows users to choose a unique human-friendly username during signup
-- Used for sharing identity (e.g., in Connection Finder) instead of UUIDs

ALTER TABLE persons
  ADD COLUMN IF NOT EXISTS username TEXT;

-- Unique constraint (case-insensitive via unique index on lower())
CREATE UNIQUE INDEX IF NOT EXISTS idx_persons_username_unique
  ON persons (LOWER(username))
  WHERE username IS NOT NULL;

-- Fast lookup by username
CREATE INDEX IF NOT EXISTS idx_persons_username
  ON persons (username)
  WHERE username IS NOT NULL;

-- Constraint: username must be 3-20 chars, alphanumeric + underscores, start with a letter
ALTER TABLE persons
  ADD CONSTRAINT chk_username_format
  CHECK (
    username IS NULL
    OR (
      LENGTH(username) BETWEEN 3 AND 20
      AND username ~ '^[a-zA-Z][a-zA-Z0-9_]*$'
    )
  );
