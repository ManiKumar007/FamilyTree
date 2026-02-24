-- Create the avatars storage bucket for profile images
-- Public bucket so images are served via public URLs without auth
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  5242880,  -- 5 MB limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Anyone can read public avatar images
CREATE POLICY IF NOT EXISTS "Public avatar read access"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

-- Authenticated users can upload images
CREATE POLICY IF NOT EXISTS "Auth users can upload avatars"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
  );

-- Authenticated users can update (replace) images
CREATE POLICY IF NOT EXISTS "Auth users can update avatars"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
  );

-- Authenticated users can delete images
CREATE POLICY IF NOT EXISTS "Auth users can delete avatars"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars'
    AND auth.role() = 'authenticated'
  );
