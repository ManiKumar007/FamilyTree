# 🌱 Seed Data Documentation

## Overview

The application comes pre-loaded with sample family tree data to help you test functionality immediately. This data represents a complete three-generation family tree.

## Sample Family Structure

```
        Rajesh Kumar ═══════ Lakshmi Devi
        (Father)              (Mother)
              │
        ┌─────┴─────┐
        │           │
   Mani Kumar   Kavya Kumar
   (You/Main)    (Sister)
        │
        ║ (married to)
        ║
   Priya Sharma
   (Spouse)
        │
    ┌───┴───┐
    │       │
 Aarav    Ananya
 (Son)    (Daughter)
```

## 👥 Sample Persons

### 1. 👤 Main User - Mani Kumar

- **ID:** `eb784d43-4536-42a0-824e-c18279616ec7`
- **Email:** manich623@gmail.com
- **Phone:** +919876543210
- **Date of Birth:** January 15, 1990 (36 years old)
- **Gender:** Male
- **Occupation:** Software Engineer
- **Location:** Hyderabad, Telangana
- **Marital Status:** Married (June 20, 2015)
- **Status:** ✅ Verified
- **Note:** This is the logged-in user's profile

### 2. 👨 Father - Rajesh Kumar

- **ID:** `e761942c-1ef2-4731-acb4-0eac0cc8096e`
- **Phone:** +919876543211
- **Email:** rajesh.kumar@example.com
- **Date of Birth:** May 10, 1960 (65 years old)
- **Gender:** Male
- **Occupation:** Retired Teacher
- **Location:** Hyderabad, Telangana
- **Marital Status:** Married (April 15, 1985)
- **Status:** ✅ Verified

### 3. 👩 Mother - Lakshmi Devi

- **ID:** `1ccff712-04e0-43f8-8ce5-11698586fef5`
- **Phone:** +919876543212
- **Email:** lakshmi.devi@example.com
- **Date of Birth:** August 22, 1965 (60 years old)
- **Gender:** Female
- **Occupation:** Homemaker
- **Location:** Hyderabad, Telangana
- **Marital Status:** Married (April 15, 1985)
- **Status:** ✅ Verified

### 4. 💍 Spouse - Priya Sharma

- **ID:** `e134edf2-69d1-4e8e-8bb0-77938b1c8eee`
- **Phone:** +919876543213
- **Email:** priya.sharma@example.com
- **Date of Birth:** March 25, 1992 (33 years old)
- **Gender:** Female
- **Occupation:** Doctor
- **Location:** Hyderabad, Telangana
- **Marital Status:** Married (June 20, 2015)
- **Status:** ✅ Verified

### 5. 👦 Son - Aarav Kumar

- **ID:** `3da0379d-8d51-4a16-969a-46e79660be58`
- **Phone:** +919876543214
- **Email:** aarav.future@example.com
- **Date of Birth:** September 12, 2016 (9 years old)
- **Gender:** Male
- **Location:** Hyderabad, Telangana
- **Marital Status:** Single
- **Status:** ✅ Verified

### 6. 👧 Daughter - Ananya Kumar

- **ID:** `77bbdb8d-0588-4a63-8eff-6ccd315282fd`
- **Phone:** +919876543215
- **Email:** ananya.future@example.com
- **Date of Birth:** November 5, 2019 (6 years old)
- **Gender:** Female
- **Location:** Hyderabad, Telangana
- **Marital Status:** Single
- **Status:** ✅ Verified

### 7. 👩 Sister - Kavya Kumar

- **ID:** `e8e94b8c-3bfb-4783-aac7-cbd32903a971`
- **Phone:** +919876543216
- **Email:** kavya.kumar@example.com
- **Date of Birth:** July 18, 1993 (32 years old)
- **Gender:** Female
- **Occupation:** Architect
- **Location:** Bangalore, Karnataka
- **Marital Status:** Married (December 10, 2018)
- **Status:** ✅ Verified

## 🔗 Relationships

Total: **14 relationships** connecting the family

### Parent-Child Relationships

1. **Rajesh Kumar** → FATHER_OF → **Mani Kumar**
2. **Lakshmi Devi** → MOTHER_OF → **Mani Kumar**
3. **Rajesh Kumar** → FATHER_OF → **Kavya Kumar**
4. **Lakshmi Devi** → MOTHER_OF → **Kavya Kumar**
5. **Mani Kumar** → FATHER_OF → **Aarav Kumar**
6. **Mani Kumar** → FATHER_OF → **Ananya Kumar**
7. **Priya Sharma** → MOTHER_OF → **Aarav Kumar**
8. **Priya Sharma** → MOTHER_OF → **Ananya Kumar**

### Spouse Relationships

9. **Rajesh Kumar** ↔ SPOUSE_OF ↔ **Lakshmi Devi** (2 entries - bidirectional)
10. **Mani Kumar** ↔ SPOUSE_OF ↔ **Priya Sharma** (2 entries - bidirectional)

### Sibling Relationships

11. **Mani Kumar** ↔ SIBLING_OF ↔ **Kavya Kumar** (2 entries - bidirectional)

## 📊 Statistics

- **Total Persons:** 7
- **Total Relationships:** 14
- **Generations:** 3
- **Married Couples:** 2
- **Children:** 2
- **Siblings:** 2
- **Cities Represented:** 2 (Hyderabad, Bangalore)
- **States Represented:** 2 (Telangana, Karnataka)

## 🧪 Testing Scenarios

### Scenario 1: View Family Tree

- Login as Mani Kumar
- Navigate to Family Tree
- **Expected:** See all 7 family members connected properly

### Scenario 2: Add New Family Member

- Try adding a new child or parent
- **Expected:** Successfully create person and relationship

### Scenario 3: Search Functionality

- Search for "Kumar" → Should find 6 people
- Search by phone "+919876543210" → Should find Mani Kumar
- **Expected:** Search results display correctly

### Scenario 4: Edit Profile

- Edit Mani Kumar's occupation or city
- **Expected:** Changes save successfully

### Scenario 5: View Relationships

- Select Mani Kumar
- **Expected:** See parents, spouse, children, and sibling

## 🔑 Test Credentials

**Main User Account:**

- **Email:** manich623@gmail.com
- **User ID:** 81f049e2-2273-4db9-87dc-2676c0b505ac
- **Person ID:** eb784d43-4536-42a0-824e-c18279616ec7
- **Phone:** +919876543210

## 🗄️ Database Queries

### View All Persons

```sql
SELECT id, name, gender, phone, occupation
FROM persons
ORDER BY name;
```

### View All Relationships

```sql
SELECT
  p1.name as person,
  r.type,
  p2.name as related_to
FROM relationships r
JOIN persons p1 ON r.person_id = p1.id
JOIN persons p2 ON r.related_person_id = p2.id
ORDER BY p1.name;
```

### View Family Tree for Mani Kumar

```sql
SELECT
  p.name,
  p.gender,
  p.occupation,
  COUNT(r.id) as connection_count
FROM persons p
LEFT JOIN relationships r ON (p.id = r.person_id OR p.id = r.related_person_id)
GROUP BY p.id
ORDER BY p.name;
```

## 🔄 Reset Seed Data

If you need to reset the seed data:

```powershell
# Clear all data
DELETE FROM relationships;
DELETE FROM persons;

# Then re-run the seed script (to be created)
# Or manually insert using SEED_DATA.md as reference
```

## 📝 Notes

- All persons are marked as **verified** (no pending verifications needed)
- All phone numbers are normalized to international format (+91 prefix)
- All email addresses use example.com domain (except main user)
- Birth dates are realistic relative to relationships
- Wedding dates are consistent between spouses
- The auth bypass middleware uses the main user's ID for all operations

## 🚀 Quick Verification

After starting the app with `.\quick-start.ps1`:

```powershell
# Check persons count
curl http://localhost:3000/api/persons/me -UseBasicParsing

# Test search
curl "http://localhost:3000/api/search?q=Kumar" -UseBasicParsing

# View family tree
curl http://localhost:3000/api/tree -UseBasicParsing
```

## 🎯 Next Steps

1. **Explore the UI:** Navigate through the family tree visualization
2. **Test CRUD Operations:** Add, edit, delete family members
3. **Test Search:** Try different search queries
4. **Test Relationships:** Add new relationships between people
5. **Test Merge Requests:** Try creating duplicate entries to see merge detection

---

**Last Updated:** February 15, 2026  
**Total Family Members:** 7  
**Total Relationships:** 14  
**Status:** ✅ Loaded and Verified
