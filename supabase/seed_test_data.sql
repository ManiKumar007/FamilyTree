-- ============================================
-- MyFamilyTree: Test/Demo Data Seed Script
-- Creates dummy users, persons, forum posts, life events, and calendar events
-- ============================================

-- Note: This assumes you have at least one real user in auth.users
-- We'll use existing users or create references to them

-- First, let's check if we have users and get their IDs
-- You'll need to replace these with actual user IDs from your auth.users table

-- ============================================
-- 1. CREATE ADDITIONAL TEST PERSONS
-- ============================================

-- Insert test persons (linking to existing auth users if available)
INSERT INTO persons (name, date_of_birth, gender, phone, email, occupation, community, city, state, marital_status, is_alive, created_at)
VALUES
  -- Family members
  ('Rajesh Kumar', '1965-03-15', 'male', '+919876543210', 'rajesh.kumar@example.com', 'Retired Teacher', 'Brahmin', 'Bangalore', 'Karnataka', 'married', true, now() - interval '2 years'),
  ('Sunita Kumar', '1968-07-22', 'female', '+919876543211', 'sunita.kumar@example.com', 'Homemaker', 'Brahmin', 'Bangalore', 'Karnataka', 'married', true, now() - interval '2 years'),
  ('Amit Kumar', '1992-11-08', 'male', '+919876543212', 'amit.kumar@example.com', 'Software Engineer', 'Brahmin', 'Bangalore', 'Karnataka', 'married', true, now() - interval '1 year'),
  ('Priya Sharma', '1995-05-14', 'female', '+919876543213', 'priya.sharma@example.com', 'Doctor', 'Brahmin', 'Mumbai', 'Maharashtra', 'married', true, now() - interval '1 year'),
  ('Ravi Patel', '1988-09-20', 'male', '+919876543214', 'ravi.patel@example.com', 'Business Owner', 'Patel', 'Ahmedabad', 'Gujarat', 'single', true, now() - interval '1 year'),
  ('Deepa Iyer', '1990-12-03', 'female', '+919876543215', 'deepa.iyer@example.com', 'Teacher', 'Iyer', 'Chennai', 'Tamil Nadu', 'married', true, now() - interval '6 months'),
  ('Vikram Reddy', '1985-04-18', 'male', '+919876543216', 'vikram.reddy@example.com', 'Architect', 'Reddy', 'Hyderabad', 'Telangana', 'married', true, now() - interval '3 years'),
  ('Lakshmi Nair', '1987-08-25', 'female', '+919876543217', 'lakshmi.nair@example.com', 'Lawyer', 'Nair', 'Kochi', 'Kerala', 'married', true, now() - interval '3 years'),
  
  -- Elder generation (some deceased)
  ('Vishwanath Kumar', '1935-01-10', 'male', '+919876543218', 'vishwanath@example.com', 'Retired Government Officer', 'Brahmin', 'Mysore', 'Karnataka', 'widowed', false, now() - interval '5 years'),
  ('Kamala Devi', '1938-06-15', 'female', '+919876543219', 'kamala@example.com', 'Homemaker', 'Brahmin', 'Mysore', 'Karnataka', 'widowed', true, now() - interval '5 years'),
  
  -- Younger generation
  ('Aarav Kumar', '2015-03-20', 'male', '+919876543220', '', 'Student', 'Brahmin', 'Bangalore', 'Karnataka', 'single', true, now() - interval '3 months'),
  ('Ananya Kumar', '2018-07-12', 'female', '+919876543221', '', 'Student', 'Brahmin', 'Bangalore', 'Karnataka', 'single', true, now() - interval '3 months')
ON CONFLICT (phone) DO NOTHING;

-- Update deceased person details
UPDATE persons 
SET date_of_death = '2020-08-15', 
    place_of_death = 'Mysore, Karnataka',
    is_alive = false
WHERE name = 'Vishwanath Kumar';

-- Update some persons with Indian-specific details
UPDATE persons 
SET nakshatra = 'Ashwini', 
    rashi = 'Mesha', 
    native_place = 'Mysore',
    sub_caste = 'Smartha',
    kula_devata = 'Sri Chamundeshwari, Mysore'
WHERE name IN ('Rajesh Kumar', 'Sunita Kumar');

UPDATE persons 
SET nakshatra = 'Rohini', 
    rashi = 'Vrishabha',
    native_place = 'Vadodara'
WHERE name = 'Ravi Patel';

-- ============================================
-- 2. CREATE FORUM POSTS
-- ============================================

-- Get a user ID to use as author (use your actual user ID or the first one)
DO $$
DECLARE
  v_user_id UUID;
  v_post_id1 UUID;
  v_post_id2 UUID;
  v_post_id3 UUID;
  v_post_id4 UUID;
  v_post_id5 UUID;
BEGIN
  -- Get the first auth user ID (replace with your actual user ID if needed)
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;
  
  IF v_user_id IS NULL THEN
    RAISE NOTICE 'No auth users found. Please create at least one user first.';
    RETURN;
  END IF;

  -- Insert forum posts
  INSERT INTO forum_posts (author_user_id, post_type, title, content, is_pinned, created_at)
  VALUES
    (v_user_id, 'story', 'Our Family''s Journey from Mysore to Bangalore', 
     E'It was 1985 when our family decided to move from Mysore to Bangalore. My grandfather Vishwanath Kumar had just retired from government service...\n\nThose were different times. The journey that takes 2 hours today used to take us almost 4-5 hours on the old bus routes. But the memories we made during those trips are priceless.\n\nI remember my grandmother packing fresh idlis and coconut chutney for the journey. The aroma would fill the entire bus!',
     true, now() - interval '30 days')
  RETURNING id INTO v_post_id1;

  INSERT INTO forum_posts (author_user_id, post_type, title, content, likes_count, created_at)
  VALUES
    (v_user_id, 'recipe', 'Grandma''s Special Bisi Bele Bath Recipe', 
     E'This is my grandmother Kamala Devi''s famous recipe that has been passed down three generations!\n\n**Ingredients:**\n- 1 cup rice\n- 1/2 cup toor dal\n- Mixed vegetables (carrot, beans, potato)\n- 2 tablespoons Bisi Bele Bath powder\n- Tamarind (lemon-sized ball)\n- Jaggery (optional, for taste)\n- Ghee for tempering\n\n**Method:**\n1. Cook rice and dal together\n2. Add vegetables and cook until soft\n3. Mix in tamarind extract and Bisi Bele Bath powder\n4. Simmer for 10 minutes\n5. Temper with mustard seeds, curry leaves, and ghee\n\nServe hot with papad and raita! 🍛',
     12, now() - interval '20 days')
  RETURNING id INTO v_post_id2;

  INSERT INTO forum_posts (author_user_id, post_type, title, content, likes_count, created_at)
  VALUES
    (v_user_id, 'announcement', 'Annual Family Reunion - Save the Date!', 
     E'Dear Family Members,\n\nWe are excited to announce our annual family reunion!\n\n**Date:** December 25, 2026\n**Time:** 10:00 AM onwards\n**Venue:** Kumar Family Home, Bangalore\n\nPlease mark your calendars. More details will follow soon.\n\nLooking forward to seeing everyone!\n\n- Rajesh Kumar',
     8, now() - interval '15 days')
  RETURNING id INTO v_post_id3;

  INSERT INTO forum_posts (author_user_id, post_type, title, content, comments_count, created_at)
  VALUES
    (v_user_id, 'discussion', 'Planning a Trip to Our Ancestral Village', 
     E'Hi everyone!\n\nI''m thinking of organizing a trip to our ancestral village in Mysore for the younger generation. It would be great for the kids to see where their great-grandparents lived.\n\nWould anyone be interested in joining? We could plan for a weekend in November.\n\nPlease share your thoughts!',
     5, now() - interval '10 days')
  RETURNING id INTO v_post_id4;

  INSERT INTO forum_posts (author_user_id, post_type, title, content, created_at)
  VALUES
    (v_user_id, 'memory', 'Remembering Grandfather Vishwanath', 
     E'Today marks 6 years since we lost our beloved grandfather Vishwanath Kumar.\n\nHe was a man of principles, always putting family first. I remember his stories about working in the government during India''s early years of independence.\n\nHis favorite saying was: "Education is the foundation, but values are the building."\n\nWe miss you, Thatha. Your legacy lives on in all of us. 🙏',
     now() - interval '5 days')
  RETURNING id INTO v_post_id5;

  -- Add some comments to the discussion post
  INSERT INTO forum_comments (post_id, author_user_id, content, created_at)
  VALUES
    (v_post_id4, v_user_id, 'Great idea! I would love to bring my kids along. November works well for us.', now() - interval '9 days'),
    (v_post_id4, v_user_id, 'Count me in! We should also visit the old temple near the house.', now() - interval '8 days'),
    (v_post_id4, v_user_id, 'I can arrange accommodation at my cousin''s place if needed.', now() - interval '7 days');

  -- Add media to the photo album post (you'll need to upload actual images to Supabase Storage)
  -- For now, using placeholder URLs
  INSERT INTO forum_posts (author_user_id, post_type, title, content, created_at)
  VALUES
    (v_user_id, 'photo_album', 'Diwali 2025 Celebrations', 
     E'Sharing some wonderful moments from our Diwali celebrations last year!\n\nThe whole family came together and we had an amazing time. From lighting diyas to bursting crackers, and of course, the delicious feast!',
     now() - interval '60 days')
  RETURNING id INTO v_post_id1;

  -- Note: In production, you'd upload real images to Supabase Storage and use those URLs
  INSERT INTO forum_media (post_id, media_url, media_type, caption, sort_order)
  VALUES
    (v_post_id1, 'https://picsum.photos/800/600?random=1', 'image', 'Family photo during Lakshmi Puja', 1),
    (v_post_id1, 'https://picsum.photos/800/600?random=2', 'image', 'Kids lighting diyas', 2),
    (v_post_id1, 'https://picsum.photos/800/600?random=3', 'image', 'Traditional rangoli', 3),
    (v_post_id1, 'https://picsum.photos/800/600?random=4', 'image', 'Festive dinner spread', 4);

  RAISE NOTICE 'Forum posts created successfully!';
END $$;

-- ============================================
-- 3. CREATE LIFE EVENTS
-- ============================================

DO $$
DECLARE
  v_person_id UUID;
  v_user_id UUID;
BEGIN
  -- Get user ID for created_by
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;
  
  -- Get Rajesh Kumar's ID
  SELECT id INTO v_person_id FROM persons WHERE name = 'Rajesh Kumar' LIMIT 1;
  IF v_person_id IS NOT NULL THEN
    INSERT INTO life_events (person_id, event_type, title, description, event_date, event_place, created_by_user_id)
    VALUES
      (v_person_id, 'birth', 'Born in Mysore', 'Born in a small house near Chamundi Hills', '1965-03-15', 'Mysore, Karnataka', v_user_id),
      (v_person_id, 'graduation', 'Completed B.Ed', 'Graduated with Bachelor of Education from Mysore University', '1987-05-20', 'Mysore University', v_user_id),
      (v_person_id, 'marriage', 'Married Sunita', 'Traditional wedding ceremony', '1990-11-25', 'Mysore, Karnataka', v_user_id),
      (v_person_id, 'retirement', 'Retired from Teaching', 'After 35 years of dedicated service', '2020-06-30', 'Bangalore, Karnataka', v_user_id);
  END IF;

  -- Get Amit Kumar's ID
  SELECT id INTO v_person_id FROM persons WHERE name = 'Amit Kumar' LIMIT 1;
  IF v_person_id IS NOT NULL THEN
    INSERT INTO life_events (person_id, event_type, title, description, event_date, event_place, created_by_user_id)
    VALUES
      (v_person_id, 'birth', 'Born in Bangalore', 'Born at St. Martha''s Hospital', '1992-11-08', 'Bangalore, Karnataka', v_user_id),
      (v_person_id, 'graduation', 'B.Tech in Computer Science', 'Graduated from PES University', '2014-06-15', 'Bangalore, Karnataka', v_user_id),
      (v_person_id, 'marriage', 'Married Priya Sharma', 'Destination wedding in Goa', '2019-12-20', 'Goa', v_user_id),
      (v_person_id, 'achievement', 'Promoted to Senior Engineer', 'Recognition for outstanding work', '2023-01-15', 'Bangalore, Karnataka', v_user_id);
  END IF;

  -- Get Vishwanath Kumar's ID (deceased)
  SELECT id INTO v_person_id FROM persons WHERE name = 'Vishwanath Kumar' LIMIT 1;
  IF v_person_id IS NOT NULL THEN
    INSERT INTO life_events (person_id, event_type, title, description, event_date, event_place, created_by_user_id)
    VALUES
      (v_person_id, 'birth', 'Born in Mysore', 'Born during British India', '1935-01-10', 'Mysore, Karnataka', v_user_id),
      (v_person_id, 'marriage', 'Married Kamala Devi', 'Arranged marriage as per tradition', '1960-04-05', 'Mysore, Karnataka', v_user_id),
      (v_person_id, 'retirement', 'Retired from Government Service', 'After 40 years in public service', '1995-01-31', 'Bangalore, Karnataka', v_user_id),
      (v_person_id, 'death', 'Passed Away Peacefully', 'Surrounded by family', '2020-08-15', 'Mysore, Karnataka', v_user_id);
  END IF;

  RAISE NOTICE 'Life events created successfully!';
END $$;

-- ============================================
-- 4. CREATE CALENDAR EVENTS
-- ============================================

DO $$
DECLARE
  v_user_id UUID;
BEGIN
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;

  INSERT INTO calendar_events (title, description, event_date, event_time, location, event_type, created_by_user_id)
  VALUES
    ('Aarav''s 11th Birthday Party', 'Birthday celebration for Aarav', '2026-03-20', '16:00:00', 'Kumar Residence, Bangalore', 'birthday', v_user_id),
    ('Annual Family Reunion', 'All family members gathering', '2026-12-25', '10:00:00', 'Kumar Family Home, Bangalore', 'gathering', v_user_id),
    ('Deepavali Celebration', 'Festival of Lights celebration', '2026-11-01', '18:00:00', 'Community Hall', 'festival', v_user_id),
    ('Ugadi Festival', 'Kannada New Year celebration', '2027-03-30', '09:00:00', 'Temple and Home', 'festival', v_user_id),
    ('Kamala Devi''s 88th Birthday', 'Special celebration for grandmother', '2026-06-15', '11:00:00', 'Home', 'birthday', v_user_id),
    ('Wedding Anniversary - Rajesh & Sunita', '36 years of togetherness', '2026-11-25', '19:00:00', 'Restaurant Booking', 'anniversary', v_user_id),
    ('Ancestral Village Visit', 'Trip to Mysore heritage sites', '2026-11-15', '08:00:00', 'Mysore, Karnataka', 'other', v_user_id),
    ('Sankranti Celebration', 'Harvest festival', '2027-01-14', '10:00:00', 'Village Square', 'festival', v_user_id);

  RAISE NOTICE 'Calendar events created successfully!';
END $$;

-- ============================================
-- 5. CREATE SOME NOTIFICATIONS (for testing)
-- ============================================

DO $$
DECLARE
  v_user_id UUID;
BEGIN
  SELECT id INTO v_user_id FROM auth.users LIMIT 1;

  INSERT INTO notifications (user_id, notification_type, title, message, related_entity_type, is_read)
  VALUES
    (v_user_id, 'new_post', 'New Forum Post', 'Someone shared "Our Family''s Journey from Mysore to Bangalore"', 'forum_post', false),
    (v_user_id, 'comment', 'New Comment', 'Someone commented on "Planning a Trip to Our Ancestral Village"', 'forum_post', false),
    (v_user_id, 'event_reminder', 'Upcoming Event', 'Reminder: Aarav''s Birthday Party is in 3 days', 'calendar_event', false),
    (v_user_id, 'profile_update', 'Profile Updated', 'Life event added for Amit Kumar', 'person', true),
    (v_user_id, 'new_member', 'New Family Member', 'Ananya Kumar was added to the family tree', 'person', true);

  RAISE NOTICE 'Notifications created successfully!';
END $$;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

SELECT 
  (SELECT COUNT(*) FROM persons) as total_persons,
  (SELECT COUNT(*) FROM forum_posts) as total_forum_posts,
  (SELECT COUNT(*) FROM forum_comments) as total_comments,
  (SELECT COUNT(*) FROM life_events) as total_life_events,
  (SELECT COUNT(*) FROM calendar_events) as total_calendar_events,
  (SELECT COUNT(*) FROM notifications) as total_notifications;

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Test data seeded successfully! ✅';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'You now have:';
  RAISE NOTICE '- 12 test persons across 3 generations';
  RAISE NOTICE '- 6 forum posts (various types)';
  RAISE NOTICE '- Multiple comments on posts';
  RAISE NOTICE '- Life events for key family members';
  RAISE NOTICE '- 8 upcoming calendar events';
  RAISE NOTICE '- 5 test notifications';
  RAISE NOTICE '========================================';
END $$;
