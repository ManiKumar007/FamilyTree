-- ============================================
-- MyFamilyTree: Seed data for development
-- ============================================

-- NOTE: These use hardcoded UUIDs for predictable testing.
-- In production, auth.users rows are created by Supabase Auth.
-- For local dev, you can create test users via the Supabase dashboard.

-- ============================================
-- Sample family: The Chinni Family
-- ============================================

-- Grandparents
INSERT INTO persons (id, name, date_of_birth, gender, phone, occupation, community, city, state, marital_status, verified)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Ramulu Chinni',    '1940-03-15', 'male',   '+919876543001', 'Farmer',        'Telugu', 'Vijayawada', 'Andhra Pradesh', 'married', false),
  ('a0000000-0000-0000-0000-000000000002', 'Lakshmi Chinni',   '1945-07-20', 'female', '+919876543002', 'Homemaker',     'Telugu', 'Vijayawada', 'Andhra Pradesh', 'married', false);

-- Parents generation
INSERT INTO persons (id, name, date_of_birth, gender, phone, occupation, community, city, state, marital_status, verified)
VALUES
  ('b0000000-0000-0000-0000-000000000001', 'Hari Babu Chinni', '1965-05-10', 'male',   '+919876543003', 'Teacher',       'Telugu', 'Guntur',     'Andhra Pradesh', 'married', false),
  ('b0000000-0000-0000-0000-000000000002', 'Surekha Chinni',   '1969-08-22', 'female', '+919876543004', 'Homemaker',     'Telugu', 'Guntur',     'Andhra Pradesh', 'married', false),
  ('b0000000-0000-0000-0000-000000000003', 'Sitha Chinni',     '1968-11-05', 'female', '+919876543005', 'Nurse',         'Telugu', 'Hyderabad',  'Telangana',      'married', false),
  ('b0000000-0000-0000-0000-000000000004', 'Anjaneyelu Kothuri','1963-02-14','male',   '+919876543006', 'Engineer',      'Telugu', 'Hyderabad',  'Telangana',      'married', false);

-- Current generation
INSERT INTO persons (id, name, date_of_birth, gender, phone, occupation, community, city, state, marital_status, verified)
VALUES
  ('c0000000-0000-0000-0000-000000000001', 'Chinni Mahesh',        '1990-04-12', 'male',   '+919876543007', 'Software Engineer', 'Telugu', 'Bangalore', 'Karnataka',      'married', true),
  ('c0000000-0000-0000-0000-000000000002', 'Sasikala Anantha Chinni','1992-09-18','female', '+919876543008', 'Teacher',           'Telugu', 'Bangalore', 'Karnataka',      'married', true),
  ('c0000000-0000-0000-0000-000000000003', 'Bhanu Prakash Chinni', '1992-06-25', 'male',   '+919876543009', 'Business',          'Telugu', 'Guntur',    'Andhra Pradesh', 'single',  false),
  ('c0000000-0000-0000-0000-000000000004', 'Pavani Chinni',        '1988-12-03', 'female', '+919876543010', 'Doctor',            'Telugu', 'Chennai',   'Tamil Nadu',     'married', false),
  ('c0000000-0000-0000-0000-000000000005', 'Mallikarjuna Chinni',  '1985-01-19', 'male',   '+919876543011', 'Solar Business',    'Telugu', 'Vijayawada','Andhra Pradesh', 'married', false);

-- Next generation (kids)
INSERT INTO persons (id, name, date_of_birth, gender, phone, occupation, community, city, state, marital_status, verified)
VALUES
  ('d0000000-0000-0000-0000-000000000001', 'Sahasra Chinni',       '2018-03-10', 'female', '+919876543012', NULL, 'Telugu', 'Bangalore', 'Karnataka', 'single', false),
  ('d0000000-0000-0000-0000-000000000002', 'Haasini Chinni',       '2020-11-25', 'female', '+919876543013', NULL, 'Telugu', 'Bangalore', 'Karnataka', 'single', false);

-- ============================================
-- Relationships (only one direction — trigger creates inverse)
-- ============================================

-- Grandparents are spouses
INSERT INTO relationships (person_id, related_person_id, type)
VALUES ('a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 'SPOUSE_OF');

-- Grandparents → Parents
INSERT INTO relationships (person_id, related_person_id, type)
VALUES
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'FATHER_OF'),
  ('a0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', 'MOTHER_OF'),
  ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000003', 'FATHER_OF'),
  ('a0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000003', 'MOTHER_OF');

-- Parents are spouses
INSERT INTO relationships (person_id, related_person_id, type)
VALUES
  ('b0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 'SPOUSE_OF'),
  ('b0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000004', 'SPOUSE_OF');

-- Siblings
INSERT INTO relationships (person_id, related_person_id, type)
VALUES
  ('b0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000003', 'SIBLING_OF');

-- Parents → Current generation
INSERT INTO relationships (person_id, related_person_id, type)
VALUES
  ('b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'FATHER_OF'),
  ('b0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001', 'MOTHER_OF'),
  ('b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'FATHER_OF'),
  ('b0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000003', 'MOTHER_OF'),
  ('b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000004', 'FATHER_OF'),
  ('b0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000004', 'MOTHER_OF'),
  ('b0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000005', 'FATHER_OF'),
  ('b0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000005', 'MOTHER_OF');

-- Current gen spouses
INSERT INTO relationships (person_id, related_person_id, type)
VALUES
  ('c0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'SPOUSE_OF');

-- Siblings in current gen
INSERT INTO relationships (person_id, related_person_id, type)
VALUES
  ('c0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000003', 'SIBLING_OF'),
  ('c0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000004', 'SIBLING_OF'),
  ('c0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000005', 'SIBLING_OF');

-- Current gen → Kids
INSERT INTO relationships (person_id, related_person_id, type)
VALUES
  ('c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000001', 'FATHER_OF'),
  ('c0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000001', 'MOTHER_OF'),
  ('c0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000002', 'FATHER_OF'),
  ('c0000000-0000-0000-0000-000000000002', 'd0000000-0000-0000-0000-000000000002', 'MOTHER_OF');
