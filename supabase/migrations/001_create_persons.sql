-- ============================================
-- MyFamilyTree: Persons table
-- ============================================

-- Custom types
CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');
CREATE TYPE marital_status_type AS ENUM ('single', 'married', 'divorced', 'widowed');

-- Persons table: every individual in any family tree
CREATE TABLE persons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Basic info
  name TEXT NOT NULL,
  date_of_birth DATE,
  gender gender_type NOT NULL,
  photo_url TEXT,
  
  -- Contact
  phone TEXT NOT NULL,  -- E.164 format: +91XXXXXXXXXX
  email TEXT,
  
  -- Profile details
  occupation TEXT,
  community TEXT,
  city TEXT,
  state TEXT,
  marital_status marital_status_type DEFAULT 'single',
  wedding_date DATE,
  
  -- Ownership & verification
  created_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,  -- set when they sign up & claim
  verified BOOLEAN DEFAULT FALSE,  -- true once the person claims their profile
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  
  -- Constraints
  CONSTRAINT phone_format CHECK (phone ~ '^\+[1-9]\d{6,14}$')
);

-- Indexes
CREATE INDEX idx_persons_phone ON persons(phone);
CREATE INDEX idx_persons_created_by ON persons(created_by_user_id);
CREATE INDEX idx_persons_auth_user ON persons(auth_user_id);
CREATE INDEX idx_persons_community ON persons(community);
CREATE INDEX idx_persons_occupation ON persons(occupation);
CREATE INDEX idx_persons_city_state ON persons(city, state);
CREATE INDEX idx_persons_marital_status ON persons(marital_status);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_persons_updated_at
  BEFORE UPDATE ON persons
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
