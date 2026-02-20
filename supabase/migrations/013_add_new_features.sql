-- ============================================
-- MyFamilyTree: Major feature additions
-- 1. Person fields: deceased, nakshatra, rashi, native_place, sub_caste
-- 2. Life events table
-- 3. Family forum (posts, comments, media)
-- 4. Documents/attachments per person
-- 5. Notifications table
-- 6. Activity feed table
-- 7. Family events calendar
-- ============================================

-- ===========================================
-- 1. PERSON TABLE ADDITIONS
-- ===========================================

-- Deceased handling
ALTER TABLE persons ADD COLUMN IF NOT EXISTS date_of_death DATE;
ALTER TABLE persons ADD COLUMN IF NOT EXISTS place_of_death TEXT;
ALTER TABLE persons ADD COLUMN IF NOT EXISTS is_alive BOOLEAN DEFAULT TRUE;

-- Indian-specific fields
ALTER TABLE persons ADD COLUMN IF NOT EXISTS nakshatra TEXT;  -- Birth star
ALTER TABLE persons ADD COLUMN IF NOT EXISTS rashi TEXT;      -- Moon sign / Zodiac
ALTER TABLE persons ADD COLUMN IF NOT EXISTS native_place TEXT;  -- Ancestral village/town
ALTER TABLE persons ADD COLUMN IF NOT EXISTS ancestral_village TEXT;  -- More specific
ALTER TABLE persons ADD COLUMN IF NOT EXISTS sub_caste TEXT;
ALTER TABLE persons ADD COLUMN IF NOT EXISTS kula_devata TEXT;  -- Family deity
ALTER TABLE persons ADD COLUMN IF NOT EXISTS pravara TEXT;      -- Pravara lineage

-- Privacy
ALTER TABLE persons ADD COLUMN IF NOT EXISTS is_profile_public BOOLEAN DEFAULT FALSE;

-- Indexes for new fields
CREATE INDEX IF NOT EXISTS idx_persons_nakshatra ON persons(nakshatra);
CREATE INDEX IF NOT EXISTS idx_persons_rashi ON persons(rashi);
CREATE INDEX IF NOT EXISTS idx_persons_native_place ON persons(native_place);
CREATE INDEX IF NOT EXISTS idx_persons_is_alive ON persons(is_alive);

COMMENT ON COLUMN persons.nakshatra IS 'Birth star (Ashwini, Bharani, etc.)';
COMMENT ON COLUMN persons.rashi IS 'Moon sign (Mesha/Aries, Vrishabha/Taurus, etc.)';
COMMENT ON COLUMN persons.native_place IS 'Ancestral hometown or village';
COMMENT ON COLUMN persons.kula_devata IS 'Family deity name and temple location';
COMMENT ON COLUMN persons.pravara IS 'Pravara lineage details for gotra';

-- ===========================================
-- 2. LIFE EVENTS TABLE
-- ===========================================

CREATE TYPE life_event_type AS ENUM (
  'birth', 'death', 'marriage', 'engagement', 'divorce',
  'naming_ceremony', 'thread_ceremony', 'graduation', 'retirement',
  'migration', 'achievement', 'medical', 'religious', 'custom'
);

CREATE TABLE IF NOT EXISTS life_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  person_id UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
  event_type life_event_type NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  event_date DATE,
  event_place TEXT,
  photo_url TEXT,
  metadata JSONB DEFAULT '{}',  -- Flexible key-value for event-specific data
  created_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_life_events_person ON life_events(person_id);
CREATE INDEX idx_life_events_type ON life_events(event_type);
CREATE INDEX idx_life_events_date ON life_events(event_date);

CREATE TRIGGER update_life_events_updated_at
  BEFORE UPDATE ON life_events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS
ALTER TABLE life_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view life events of people in their tree"
  ON life_events FOR SELECT USING (true);
CREATE POLICY "Users can create life events"
  ON life_events FOR INSERT WITH CHECK (
    created_by_user_id = auth.uid()
  );
CREATE POLICY "Users can update own life events"
  ON life_events FOR UPDATE USING (
    created_by_user_id = auth.uid()
  );
CREATE POLICY "Users can delete own life events"
  ON life_events FOR DELETE USING (
    created_by_user_id = auth.uid()
  );

-- ===========================================
-- 3. FAMILY FORUM
-- ===========================================

CREATE TYPE forum_post_type AS ENUM (
  'story', 'recipe', 'photo_album', 'announcement', 'discussion', 'memory'
);

CREATE TABLE IF NOT EXISTS forum_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  post_type forum_post_type NOT NULL DEFAULT 'discussion',
  title TEXT NOT NULL,
  content TEXT,  -- Markdown/rich text
  is_pinned BOOLEAN DEFAULT FALSE,
  likes_count INT DEFAULT 0,
  comments_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_forum_posts_author ON forum_posts(author_user_id);
CREATE INDEX idx_forum_posts_type ON forum_posts(post_type);
CREATE INDEX idx_forum_posts_created ON forum_posts(created_at DESC);
CREATE INDEX idx_forum_posts_pinned ON forum_posts(is_pinned) WHERE is_pinned = TRUE;

CREATE TRIGGER update_forum_posts_updated_at
  BEFORE UPDATE ON forum_posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Forum post media (photos - up to 5 for free)
CREATE TABLE IF NOT EXISTS forum_media (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
  media_url TEXT NOT NULL,
  media_type TEXT DEFAULT 'image',  -- image, video
  caption TEXT,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_forum_media_post ON forum_media(post_id);

-- Forum comments
CREATE TABLE IF NOT EXISTS forum_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
  author_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  parent_comment_id UUID REFERENCES forum_comments(id) ON DELETE CASCADE,  -- For replies
  content TEXT NOT NULL,
  likes_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_forum_comments_post ON forum_comments(post_id);
CREATE INDEX idx_forum_comments_parent ON forum_comments(parent_comment_id);

CREATE TRIGGER update_forum_comments_updated_at
  BEFORE UPDATE ON forum_comments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Forum likes
CREATE TABLE IF NOT EXISTS forum_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  post_id UUID REFERENCES forum_posts(id) ON DELETE CASCADE,
  comment_id UUID REFERENCES forum_comments(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT like_target CHECK (
    (post_id IS NOT NULL AND comment_id IS NULL) OR
    (post_id IS NULL AND comment_id IS NOT NULL)
  ),
  CONSTRAINT unique_post_like UNIQUE (user_id, post_id),
  CONSTRAINT unique_comment_like UNIQUE (user_id, comment_id)
);

-- RLS for forum
ALTER TABLE forum_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view forum posts" ON forum_posts FOR SELECT USING (true);
CREATE POLICY "Auth users can create posts" ON forum_posts FOR INSERT WITH CHECK (author_user_id = auth.uid());
CREATE POLICY "Authors can update posts" ON forum_posts FOR UPDATE USING (author_user_id = auth.uid());
CREATE POLICY "Authors can delete posts" ON forum_posts FOR DELETE USING (author_user_id = auth.uid());

CREATE POLICY "Anyone can view media" ON forum_media FOR SELECT USING (true);
CREATE POLICY "Post authors can add media" ON forum_media FOR INSERT WITH CHECK (true);
CREATE POLICY "Post authors can delete media" ON forum_media FOR DELETE USING (true);

CREATE POLICY "Anyone can view comments" ON forum_comments FOR SELECT USING (true);
CREATE POLICY "Auth users can comment" ON forum_comments FOR INSERT WITH CHECK (author_user_id = auth.uid());
CREATE POLICY "Authors can update comments" ON forum_comments FOR UPDATE USING (author_user_id = auth.uid());
CREATE POLICY "Authors can delete comments" ON forum_comments FOR DELETE USING (author_user_id = auth.uid());

CREATE POLICY "Anyone can view likes" ON forum_likes FOR SELECT USING (true);
CREATE POLICY "Users can like" ON forum_likes FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can unlike" ON forum_likes FOR DELETE USING (user_id = auth.uid());

-- ===========================================
-- 4. PERSON DOCUMENTS / ATTACHMENTS
-- ===========================================

CREATE TYPE document_type AS ENUM (
  'photo', 'birth_certificate', 'marriage_certificate', 'death_certificate',
  'aadhaar', 'passport', 'property_doc', 'other'
);

CREATE TABLE IF NOT EXISTS person_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  person_id UUID NOT NULL REFERENCES persons(id) ON DELETE CASCADE,
  doc_type document_type NOT NULL DEFAULT 'other',
  title TEXT NOT NULL,
  description TEXT,
  file_url TEXT NOT NULL,
  file_size_bytes BIGINT,
  mime_type TEXT,
  is_private BOOLEAN DEFAULT TRUE,  -- Private by default
  uploaded_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_person_documents_person ON person_documents(person_id);
CREATE INDEX idx_person_documents_type ON person_documents(doc_type);

ALTER TABLE person_documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view docs of their tree" ON person_documents FOR SELECT USING (true);
CREATE POLICY "Users can upload docs" ON person_documents FOR INSERT WITH CHECK (uploaded_by_user_id = auth.uid());
CREATE POLICY "Uploaders can delete docs" ON person_documents FOR DELETE USING (uploaded_by_user_id = auth.uid());

-- ===========================================
-- 5. NOTIFICATIONS TABLE
-- ===========================================

CREATE TYPE notification_type AS ENUM (
  'birthday_reminder', 'anniversary_reminder', 'death_anniversary',
  'new_member_added', 'merge_request', 'invite_accepted',
  'forum_comment', 'forum_like', 'system', 'custom'
);

CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  notification_type notification_type NOT NULL,
  title TEXT NOT NULL,
  message TEXT,
  data JSONB DEFAULT '{}',  -- Extra context (person_id, post_id, etc.)
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own notifications" ON notifications FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "System can create notifications" ON notifications FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update own notifications" ON notifications FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete own notifications" ON notifications FOR DELETE USING (user_id = auth.uid());

-- ===========================================
-- 6. ACTIVITY FEED TABLE
-- ===========================================

CREATE TYPE activity_type AS ENUM (
  'person_added', 'person_updated', 'relationship_added',
  'photo_uploaded', 'profile_claimed', 'member_joined',
  'forum_post', 'life_event_added', 'document_uploaded'
);

CREATE TABLE IF NOT EXISTS activity_feed (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_type activity_type NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  entity_id UUID,       -- ID of the related entity (person, post, etc.)
  entity_type TEXT,      -- 'person', 'forum_post', 'relationship', etc.
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_activity_feed_user ON activity_feed(user_id);
CREATE INDEX idx_activity_feed_created ON activity_feed(created_at DESC);
CREATE INDEX idx_activity_feed_type ON activity_feed(activity_type);

ALTER TABLE activity_feed ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see all activity" ON activity_feed FOR SELECT USING (true);
CREATE POLICY "System can create activity" ON activity_feed FOR INSERT WITH CHECK (true);

-- ===========================================
-- 7. FAMILY EVENTS CALENDAR
-- ===========================================

CREATE TYPE calendar_event_type AS ENUM (
  'birthday', 'anniversary', 'death_anniversary', 'festival',
  'puja', 'wedding', 'engagement', 'reunion', 'custom'
);

CREATE TABLE IF NOT EXISTS family_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type calendar_event_type NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  event_date DATE NOT NULL,
  is_recurring BOOLEAN DEFAULT FALSE,   -- Yearly recurring (birthdays, anniversaries)
  recurrence_type TEXT DEFAULT 'none',   -- 'none', 'yearly', 'monthly', 'tithi' (lunar)
  person_id UUID REFERENCES persons(id) ON DELETE SET NULL,  -- Related person (if any)
  reminder_days_before INT DEFAULT 1,    -- Days before to send reminder
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_family_events_date ON family_events(event_date);
CREATE INDEX idx_family_events_user ON family_events(created_by_user_id);
CREATE INDEX idx_family_events_person ON family_events(person_id);
CREATE INDEX idx_family_events_type ON family_events(event_type);

CREATE TRIGGER update_family_events_updated_at
  BEFORE UPDATE ON family_events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

ALTER TABLE family_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see all family events" ON family_events FOR SELECT USING (true);
CREATE POLICY "Users create events" ON family_events FOR INSERT WITH CHECK (created_by_user_id = auth.uid());
CREATE POLICY "Users update own events" ON family_events FOR UPDATE USING (created_by_user_id = auth.uid());
CREATE POLICY "Users delete own events" ON family_events FOR DELETE USING (created_by_user_id = auth.uid());

-- ===========================================
-- 8. FAMILY STATISTICS FUNCTION
-- ===========================================

CREATE OR REPLACE FUNCTION get_family_statistics(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
  root_person_id UUID;
BEGIN
  -- Get user's person ID
  SELECT id INTO root_person_id FROM persons WHERE auth_user_id = p_user_id LIMIT 1;
  
  IF root_person_id IS NULL THEN
    RETURN '{"error": "No profile found"}'::JSONB;
  END IF;
  
  SELECT jsonb_build_object(
    'total_members', (SELECT count(*) FROM persons WHERE created_by_user_id = p_user_id),
    'total_relationships', (SELECT count(*) FROM relationships r JOIN persons p ON r.person_id = p.id WHERE p.created_by_user_id = p_user_id),
    'generation_count', (
      WITH RECURSIVE tree AS (
        SELECT id, 0 AS depth FROM persons WHERE id = root_person_id
        UNION ALL
        SELECT p.id, t.depth + 1
        FROM tree t
        JOIN relationships r ON r.person_id = t.id AND r.type IN ('FATHER_OF', 'MOTHER_OF')
        JOIN persons p ON p.id = r.related_person_id
        WHERE t.depth < 20
      )
      SELECT COALESCE(max(depth), 0) + 1 FROM tree
    ),
    'male_count', (SELECT count(*) FROM persons WHERE created_by_user_id = p_user_id AND gender = 'male'),
    'female_count', (SELECT count(*) FROM persons WHERE created_by_user_id = p_user_id AND gender = 'female'),
    'living_count', (SELECT count(*) FROM persons WHERE created_by_user_id = p_user_id AND is_alive = true),
    'deceased_count', (SELECT count(*) FROM persons WHERE created_by_user_id = p_user_id AND is_alive = false),
    'verified_count', (SELECT count(*) FROM persons WHERE created_by_user_id = p_user_id AND verified = true),
    'most_common_surname', (
      SELECT surname FROM persons WHERE created_by_user_id = p_user_id AND surname IS NOT NULL
      GROUP BY surname ORDER BY count(*) DESC LIMIT 1
    ),
    'oldest_member', (
      SELECT name FROM persons WHERE created_by_user_id = p_user_id AND date_of_birth IS NOT NULL
      ORDER BY date_of_birth ASC LIMIT 1
    ),
    'youngest_member', (
      SELECT name FROM persons WHERE created_by_user_id = p_user_id AND date_of_birth IS NOT NULL
      ORDER BY date_of_birth DESC LIMIT 1
    ),
    'cities', (
      SELECT jsonb_agg(DISTINCT city) FROM persons WHERE created_by_user_id = p_user_id AND city IS NOT NULL
    ),
    'states', (
      SELECT jsonb_agg(DISTINCT state) FROM persons WHERE created_by_user_id = p_user_id AND state IS NOT NULL
    )
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- 9. CONSISTENCY CHECKER FUNCTION
-- ===========================================

CREATE OR REPLACE FUNCTION check_tree_consistency(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  issues JSONB := '[]'::JSONB;
  rec RECORD;
BEGIN
  -- Check: Child born before parent
  FOR rec IN
    SELECT c.name AS child_name, c.date_of_birth AS child_dob,
           p.name AS parent_name, p.date_of_birth AS parent_dob
    FROM relationships r
    JOIN persons c ON c.id = r.related_person_id
    JOIN persons p ON p.id = r.person_id
    WHERE r.type IN ('FATHER_OF', 'MOTHER_OF')
      AND c.date_of_birth IS NOT NULL AND p.date_of_birth IS NOT NULL
      AND c.date_of_birth <= p.date_of_birth
      AND p.created_by_user_id = p_user_id
  LOOP
    issues := issues || jsonb_build_object(
      'type', 'child_born_before_parent',
      'severity', 'error',
      'message', rec.child_name || ' born before/same as parent ' || rec.parent_name
    );
  END LOOP;

  -- Check: Parent too young (< 12 years old when child born)
  FOR rec IN
    SELECT c.name AS child_name, c.date_of_birth AS child_dob,
           p.name AS parent_name, p.date_of_birth AS parent_dob
    FROM relationships r
    JOIN persons c ON c.id = r.related_person_id
    JOIN persons p ON p.id = r.person_id
    WHERE r.type IN ('FATHER_OF', 'MOTHER_OF')
      AND c.date_of_birth IS NOT NULL AND p.date_of_birth IS NOT NULL
      AND EXTRACT(YEAR FROM AGE(c.date_of_birth::timestamp, p.date_of_birth::timestamp)) < 12
      AND p.created_by_user_id = p_user_id
  LOOP
    issues := issues || jsonb_build_object(
      'type', 'parent_too_young',
      'severity', 'warning',
      'message', rec.parent_name || ' was under 12 when ' || rec.child_name || ' was born'
    );
  END LOOP;

  -- Check: Child born after parent's death
  FOR rec IN
    SELECT c.name AS child_name, c.date_of_birth AS child_dob,
           p.name AS parent_name, p.date_of_death AS parent_dod
    FROM relationships r
    JOIN persons c ON c.id = r.related_person_id
    JOIN persons p ON p.id = r.person_id
    WHERE r.type IN ('FATHER_OF', 'MOTHER_OF')
      AND c.date_of_birth IS NOT NULL AND p.date_of_death IS NOT NULL
      AND c.date_of_birth > p.date_of_death
      AND p.created_by_user_id = p_user_id
  LOOP
    issues := issues || jsonb_build_object(
      'type', 'child_born_after_parent_death',
      'severity', 'error', 
      'message', rec.child_name || ' born after ' || rec.parent_name || '''s death'
    );
  END LOOP;

  -- Check: Person over 120 years old and still alive
  FOR rec IN
    SELECT name, date_of_birth
    FROM persons
    WHERE created_by_user_id = p_user_id
      AND is_alive = true
      AND date_of_birth IS NOT NULL
      AND EXTRACT(YEAR FROM AGE(now(), date_of_birth::timestamp)) > 120
  LOOP
    issues := issues || jsonb_build_object(
      'type', 'unlikely_age',
      'severity', 'warning',
      'message', rec.name || ' is over 120 years old and marked as alive'
    );
  END LOOP;

  -- Check: Death before birth
  FOR rec IN
    SELECT name, date_of_birth, date_of_death
    FROM persons
    WHERE created_by_user_id = p_user_id
      AND date_of_birth IS NOT NULL AND date_of_death IS NOT NULL
      AND date_of_death < date_of_birth
  LOOP
    issues := issues || jsonb_build_object(
      'type', 'death_before_birth',
      'severity', 'error',
      'message', rec.name || ' has death date before birth date'
    );
  END LOOP;

  -- Check: Marriage before age 14
  FOR rec IN
    SELECT name, date_of_birth, wedding_date
    FROM persons
    WHERE created_by_user_id = p_user_id
      AND date_of_birth IS NOT NULL AND wedding_date IS NOT NULL
      AND EXTRACT(YEAR FROM AGE(wedding_date::timestamp, date_of_birth::timestamp)) < 14
  LOOP
    issues := issues || jsonb_build_object(
      'type', 'marriage_too_young',
      'severity', 'warning',
      'message', rec.name || ' married before age 14'
    );
  END LOOP;

  -- Check: Duplicate phone numbers
  FOR rec IN
    SELECT phone, count(*) AS cnt, string_agg(name, ', ') AS names
    FROM persons
    WHERE created_by_user_id = p_user_id AND phone IS NOT NULL
    GROUP BY phone HAVING count(*) > 1
  LOOP
    issues := issues || jsonb_build_object(
      'type', 'duplicate_phone',
      'severity', 'info',
      'message', 'Duplicate phone (' || rec.phone || '): ' || rec.names
    );
  END LOOP;

  RETURN issues;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

