# Supabase Storage Setup for Profile Images

## Overview

This guide explains how to set up Supabase Storage for profile image uploads in the MyFamilyTree application.

---

## 📁 Storage Bucket Setup

### 1. Create Storage Bucket

1. Go to your Supabase project dashboard
2. Navigate to **Storage** in the left sidebar
3. Click **New bucket**
4. Configure the bucket:
   - **Name**: `avatars`
   - **Public bucket**: ✅ **Yes** (so images are publicly accessible)
   - Click **Create bucket**

### 2. Set Up Storage Policies

The `avatars` bucket needs policies to allow:

- **Upload**: Authenticated users can upload images
- **Read**: Anyone can view images (public)
- **Delete**: Users can delete their own images

#### Policy 1: Enable Public Read Access

```sql
-- Allow public read access to all files in avatars bucket
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'avatars' );
```

#### Policy 2: Enable Authenticated Upload

```sql
-- Allow authenticated users to upload files
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( bucket_id = 'avatars' );
```

#### Policy 3: Enable User Delete Own Files

```sql
-- Allow users to delete their own files
CREATE POLICY "Users can delete own avatars"
ON storage.objects FOR DELETE
TO authenticated
USING ( bucket_id = 'avatars' AND auth.uid() = owner );
```

#### Policy 4: Enable User Update Own Files

```sql
-- Allow users to update their own files
CREATE POLICY "Users can update own avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING ( bucket_id = 'avatars' AND auth.uid() = owner );
```

---

## 🔧 Alternative: Using Supabase Dashboard

If you prefer using the dashboard instead of SQL:

### Step 1: Navigate to Policies

1. Go to **Storage** → **Policies**
2. Select the `avatars` bucket

### Step 2: Add Policies

1. **Public Select Policy**
   - Operation: `SELECT`
   - Policy name: `Public Access`
   - Target roles: `public`
   - Policy definition: `true` (allow all)

2. **Authenticated Insert Policy**
   - Operation: `INSERT`
   - Policy name: `Authenticated Upload`
   - Target roles: `authenticated`
   - Policy definition: `bucket_id = 'avatars'`

3. **User Delete Policy**
   - Operation: `DELETE`
   - Policy name: `User Delete Own`
   - Target roles: `authenticated`
   - Policy definition: `bucket_id = 'avatars' AND auth.uid() = owner`

4. **User Update Policy**
   - Operation: `UPDATE`
   - Policy name: `User Update Own`
   - Target roles: `authenticated`
   - Policy definition: `bucket_id = 'avatars' AND auth.uid() = owner`

---

## 📝 File Structure in Storage

Images will be stored with the following structure:

```
avatars/
└── profiles/
    ├── {personId}-{timestamp}.jpg
    ├── {personId}-{timestamp}.png
    └── ...
```

### Example

```
avatars/
└── profiles/
    ├── abc123-1234567890.jpg
    ├── def456-1234567891.png
    └── ghi789-1234567892.jpg
```

---

## 🔒 Security Considerations

### Current Setup (Development)

- ✅ Public read access (anyone can view images)
- ✅ Authenticated upload (only logged-in users can upload)
- ✅ User can delete own images

### Recommended for Production

1. **Rate Limiting**: Enable rate limiting on uploads
2. **File Size Limits**: Set max file size (currently handled in Flutter: 1024x1024)
3. **File Type Validation**: Only allow image types
4. **Scan for Malware**: Consider virus scanning service
5. **CDN**: Use Supabase CDN for faster image delivery

### Storage Quota

- **Free Tier**: 1 GB storage
- **Pro Tier**: 100 GB storage
- **Enterprise**: Custom

Monitor your usage in the Supabase dashboard under **Settings** → **Billing**.

---

## 🧪 Testing the Setup

### Test Upload via Flutter App

1. Run the Flutter app
2. Go to **Edit Profile**
3. Tap on the profile photo
4. Select **Camera** or **Gallery**
5. Choose an image
6. Wait for upload to complete
7. Verify the image URL is saved in the database

### Test via Supabase Dashboard

1. Go to **Storage** → **avatars** bucket
2. You should see uploaded files in `profiles/` folder
3. Click on an image to view details
4. Copy the public URL and open in browser
5. Image should be visible

### Test Public Access

Open the public URL in an incognito window to verify public access works.

---

## 🚨 Troubleshooting

### Issue: "Failed to upload image"

**Possible Causes:**

1. Bucket doesn't exist
2. Policies not set correctly
3. Network connection issue
4. File size too large
5. Invalid file type

**Solutions:**

1. Verify bucket name is exactly `avatars`
2. Check policies are active
3. Test network connection
4. Check image file size
5. Ensure file is a valid image (jpg, png)

### Issue: "Cannot view image"

**Possible Causes:**

1. Public read policy not set
2. Invalid URL
3. File was deleted

**Solutions:**

1. Add public SELECT policy
2. Check URL format
3. Verify file exists in storage

### Issue: "Permission denied"

**Possible Causes:**

1. User not authenticated
2. Upload policy not set
3. User trying to delete someone else's file

**Solutions:**

1. Ensure user is logged in
2. Add INSERT policy for authenticated users
3. Check owner field matches auth.uid()

---

## 📊 Monitoring

### Check Upload Statistics

1. Go to **Storage** dashboard
2. View:
   - Total storage used
   - Number of files
   - Bandwidth usage
   - API requests

### Set Up Alerts

1. Go to **Settings** → **Alerts**
2. Configure alerts for:
   - Storage quota (e.g., 80% full)
   - Bandwidth limits
   - API rate limits

---

## 🔄 Migration Notes

If you already have existing users and want to migrate:

1. **Existing Database Photos**
   - If you have `photo_url` fields pointing to external URLs
   - They will continue to work
   - New uploads will use Supabase Storage
   - Optionally migrate existing images to Supabase

2. **Batch Upload Script** (Optional)

   ```javascript
   // Example: Migrate existing external images to Supabase
   // Run this in Supabase Edge Function or Node.js script
   const supabase = createClient(...)

   const persons = await supabase
     .from('persons')
     .select('id, photo_url')
     .not('photo_url', 'is', null)
     .like('photo_url', 'http%')

   for (const person of persons.data) {
     // Download image from external URL
     // Upload to Supabase Storage
     // Update photo_url in database
   }
   ```

---

## ✅ Quick Setup Checklist

- [ ] Created `avatars` bucket in Supabase
- [ ] Set bucket as **public**
- [ ] Added public SELECT policy
- [ ] Added authenticated INSERT policy
- [ ] Added authenticated DELETE policy (own files)
- [ ] Added authenticated UPDATE policy (own files)
- [ ] Tested upload from Flutter app
- [ ] Verified image is viewable via public URL
- [ ] Checked storage usage in dashboard
- [ ] Set up storage alerts (optional)

---

## 🎯 Summary

Your Supabase Storage is now configured for profile image uploads with:

- ✅ Public read access for all images
- ✅ Authenticated upload capability
- ✅ User ownership and deletion rights
- ✅ Organized file structure
- ✅ Secure and scalable storage

Users can now upload profile photos directly from the app, and the images will be stored securely in Supabase Storage.
