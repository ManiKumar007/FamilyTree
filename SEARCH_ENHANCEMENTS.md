# Search Network Feature Enhancements

## Overview

Enhanced the family network search functionality to fix authentication issues and enable comprehensive searching by multiple criteria including occupation, city, state, and company.

## Issues Fixed

### 1. ✅ "Invalid or expired token" Error

**Problem:** Search page was showing "Invalid or expired token" error, preventing users from searching their family network.

**Solution:**

- Added automatic session refresh before search operations
- Enhanced error handling with specific error messages
- Added recovery options (retry, sign in again, set up profile)

**Files Modified:**

- `app/lib/providers/providers.dart` - Added session refresh in SearchNotifier
- `app/lib/features/search/screens/search_screen.dart` - Improved error UI

### 2. ✅ Limited Search Capabilities

**Problem:** Users could only search by name and occupation. No way to find family members by location (city/state) or company.

**Solution:**

- Enhanced backend to support city and state filtering
- Updated frontend to pass location parameters
- Improved free-text search to include city and state in results

**Files Modified:**

- `backend/src/routes/search.ts` - Added city and state parameters
- `backend/src/services/graphService.ts` - Enhanced search filtering
- `app/lib/services/api_service.dart` - Added city/state parameters

## New Search Capabilities

### What You Can Search For

Users can now find family members by:

1. **👤 Name**
   - Full name or partial name
   - Example: "John", "Kumar", "Sharma"

2. **💼 Occupation / Job Title**
   - Job titles, professions, roles
   - Examples: "Engineer", "Doctor", "Teacher", "Manager"

3. **🏢 Company Name**
   - Companies where family members work
   - Examples: "Google", "Microsoft", "Infosys", "Wipro"

4. **🏙️ City**
   - City of residence
   - Examples: "Bangalore", "Delhi", "Mumbai", "Chennai"

5. **🗺️ State**
   - State/region
   - Examples: "Karnataka", "Maharashtra", "Tamil Nadu"

6. **Skills / Expertise**
   - Since occupation field can include skills
   - Examples: "Python", "Java", "Accountant"

### Search Features

#### Free Text Search

Type anything in the search box - it will match against:

- Name
- Occupation
- City
- State

#### Advanced Filters

Use the filter button to:

- Filter by specific occupation
- Filter by marital status
- Adjust search depth (how many circles/relationships to search through)

#### Search Depth

- **1 circle**: Immediate family (parents, siblings, children, spouse)
- **2 circles**: Extended family (grandparents, aunts, uncles, cousins)
- **3 circles** (default): Second cousins and further relations
- **Up to 10 circles**: Very distant relations

## Technical Implementation

### Frontend (Flutter)

#### Session Management

```dart
// SearchNotifier now refreshes session before search
await _authService.refreshSession();
```

#### Enhanced Error Handling

```dart
// Specific error messages for different scenarios
if (errorMessage.contains('Invalid or expired token')) {
  errorMessage = 'Session expired. Please sign out and sign in again.';
} else if (errorMessage.contains('Profile not found')) {
  errorMessage = 'Please complete your profile setup first.';
}
```

#### Search API Call

```dart
Future<List<SearchResult>> search({
  String? query,        // Free text search
  String? occupation,   // Specific occupation filter
  String? city,         // City filter
  String? state,        // State filter
  String? maritalStatus, // Marital status filter
  int depth = 3,        // Search depth (circles)
})
```

### Backend (Node.js/TypeScript)

#### Enhanced Search Query Schema

```typescript
const searchQuerySchema = z.object({
  query: z.string().optional(),
  occupation: z.string().optional(),
  city: z.string().optional(),
  state: z.string().optional(),
  marital_status: z
    .enum(["single", "married", "divorced", "widowed"])
    .optional(),
  depth: z.coerce.number().min(1).max(10).default(3),
});
```

#### Search Algorithm

Uses breadth-first search (BFS) with batch loading:

1. Start from user's profile
2. Load all connections at each depth level
3. Apply filters (name, occupation, city, state, marital status)
4. Return matching results with connection path

#### Filtering Logic

```typescript
// Free text search matches multiple fields
if (query) {
  const q = query.toLowerCase();
  matches =
    matches &&
    (person.name.toLowerCase().includes(q) ||
      (person.occupation?.toLowerCase().includes(q) ?? false) ||
      (person.city?.toLowerCase().includes(q) ?? false) ||
      (person.state?.toLowerCase().includes(q) ?? false));
}

// Specific filters
if (city) {
  matches =
    matches &&
    (person.city?.toLowerCase().includes(city.toLowerCase()) ?? false);
}
```

## User Interface Improvements

### Empty State

When no search is performed, the UI now shows:

- Search icon
- "Search Your Family Network" title
- Helpful hints showing what can be searched:
  - 👤 Name
  - 💼 Occupation
  - 🏙️ City
  - 🗺️ State
  - 🏢 Company name

### Error States

- **Profile Setup Required**: Button to navigate to profile setup
- **Session Expired**: Button to sign in again
- **Generic Error**: Button to try again

### Search Results

Each result shows:

- Name and avatar
- Occupation
- Location (city, state)
- Connection depth (circles away)
- Connection path (Via: Parent → Grandparent → etc.)
- Marital status

## Testing the Search Feature

### 1. Basic Test

```
1. Navigate to Search page
2. Type a common name (e.g., "Kumar")
3. Click Search
4. Should see matching family members
```

### 2. Occupation Search

```
1. Type an occupation (e.g., "Engineer")
2. Click Search
3. Should see all engineers in your network
```

### 3. Location Search

```
1. Type a city (e.g., "Bangalore")
2. Click Search
3. Should see all family members in Bangalore
```

### 4. Company Search

```
1. Type a company name (e.g., "Google")
2. Click Search
3. Should see family members working at Google (if occupation mentions it)
```

### 5. Advanced Filter Test

```
1. Click filter button
2. Select specific occupation from dropdown
3. Select marital status
4. Adjust depth slider
5. Click Search
6. Results should match all criteria
```

## API Examples

### Search by Name

```
GET /api/search?query=Kumar&depth=3
```

### Search by Occupation

```
GET /api/search?occupation=Engineer&depth=3
```

### Search by City

```
GET /api/search?city=Bangalore&depth=3
```

### Search by State

```
GET /api/search?state=Karnataka&depth=3
```

### Combined Search

```
GET /api/search?query=Engineer&city=Bangalore&marital_status=married&depth=5
```

## Response Format

```json
{
  "data": [
    {
      "person": {
        "id": "uuid",
        "name": "Full Name",
        "occupation": "Software Engineer",
        "city": "Bangalore",
        "state": "Karnataka",
        "gender": "male",
        "marital_status": "married"
      },
      "depth": 2,
      "pathNames": ["Your Name", "Parent Name", "Person Name"],
      "connectionPath": "Your Name → Parent Name → Person Name"
    }
  ],
  "page": 1,
  "pageSize": 20,
  "total": 1,
  "totalPages": 1,
  "depth": 3
}
```

## Performance

### Batch Loading

- Uses batch queries to avoid N+1 problem
- Loads all persons at each depth level in 2 queries
- Typical 3-circle search: ~6 database queries
- Much faster than sequential per-person queries

### Pagination

- Default: 20 results per page
- Maximum: 100 results per page
- Backend supports efficient pagination

## Troubleshooting

### "Invalid or expired token"

**Solution:**

1. The app will now automatically refresh your session
2. If it persists, click "Sign In Again" button
3. Sign out and sign back in

### "Profile not found"

**Solution:**

1. Click the "Set Up Profile" button
2. Complete your profile with required fields
3. Return to search

### No Results Found

**Possible reasons:**

1. No family members match your search criteria
2. Search depth is too low (try increasing circles)
3. Misspelled search term
4. Family members haven't filled in that information

**Solutions:**

- Try broader search terms
- Increase search depth
- Use filters instead of free text
- Check if family members have completed their profiles

## Future Enhancements

Potential improvements:

1. **Auto-suggest**: Show matching occupations/cities as user types
2. **Recent searches**: Save and show recent search queries
3. **Saved searches**: Allow users to save common searches
4. **Search history**: Track and display search history
5. **Export results**: Download search results as PDF/CSV
6. **Advanced filters**: Age range, gender, date of birth filters
7. **Fuzzy matching**: Handle typos and alternative spellings
8. **Skill tags**: Dedicated skill field with tag-based search

## Files Changed

### Frontend

- `app/lib/features/search/screens/search_screen.dart`
  - Enhanced error handling UI
  - Added helpful empty state with search hints
  - Better error recovery buttons
  - Search hint chips component

- `app/lib/providers/providers.dart`
  - Added session refresh to SearchNotifier
  - Enhanced error messages
  - Added detailed logging

- `app/lib/services/api_service.dart`
  - Added city and state parameters to search method

### Backend

- `backend/src/routes/search.ts`
  - Added city and state to query schema
  - Updated API documentation
  - Pass new parameters to search service

- `backend/src/services/graphService.ts`
  - Enhanced searchInCircles function
  - Added city and state filtering
  - Updated free-text query to include location fields

## Summary

The search feature now:

- ✅ Works without token errors (automatic session refresh)
- ✅ Searches by name, occupation, city, state, company
- ✅ Shows helpful hints when empty
- ✅ Provides clear error messages with recovery options
- ✅ Displays connection paths to found members
- ✅ Supports adjustable search depth
- ✅ Uses efficient batch loading for performance

Users can now find family members by any combination of:
**Name • Occupation • Company • City • State • Skills**
