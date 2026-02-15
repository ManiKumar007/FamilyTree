# MyFamilyTree 🌳

**MyFamilyTree** is a collaborative Indian family tree app with Geni.com-style visualization, automatic tree merging via phone numbers, and network-based matchmaking discovery.

Built specifically for **Indian families** with features like N-circle network search, WhatsApp invite links, and intelligent conflict resolution when family trees connect.

---

## ✨ Key Features

### Core Functionality (v1.0 MVP)
- ✅ **Google + Email (Magic Link) Authentication** via Supabase
- ✅ **Interactive Family Tree Canvas** — Geni-style pannable/zoomable visualization with color-coded gender cards
- ✅ **Phone-based Automatic Tree Merging** — Detects duplicate persons across independent trees
- ✅ **N-Circle Network Search** — Find relatives and potential matches within 1-10 relationship hops
- ✅ **WhatsApp Invite Flow** — Generate shareable links for family members to claim their profiles
- ✅ **Smart Conflict Resolution** — Review & approve merges with side-by-side profile comparison
- ✅ **Rich Indian Profiles** — Community, occupation, city, marital status, and more

### Coming Soon
- 📸 Photo uploads (Cloudinary/Supabase Storage)
- 🔔 Real-time updates (Supabase Realtime subscriptions)
- 🤖 Advanced matching (name similarity, DOB validation)
- 🔒 Privacy controls & data ownership settings
- 📄 Export tree to PDF/PNG
- 📱 Push notifications for merge requests

---

## 🏗️ Architecture

```
├── backend/          # Node.js + Express + TypeScript API
│   ├── src/
│   │   ├── routes/   # REST endpoints (persons, tree, search, merge, invite)
│   │   ├── services/ # Business logic (graph traversal, merge detection)
│   │   ├── middleware/ # Auth verification, error handling
│   │   └── config/   # Supabase client, environment
│   └── package.json
│
├── app/              # Flutter mobile app (Android + Web)
│   ├── lib/
│   │   ├── features/ # Auth, Tree, Search, Invite, Merge screens
│   │   ├── services/ # API client, Supabase auth service
│   │   ├── providers/ # Riverpod state management
│   │   ├── models/   # Dart data models
│   │   ├── router/   # GoRouter navigation
│   │   └── config/   # Theme, constants
│   └── pubspec.yaml
│
├── supabase/         # PostgreSQL database schema
│   ├── migrations/   # SQL DDL (tables, RLS policies, triggers)
│   └── seed.sql      # Sample Chinni family tree data
│
└── README.md         # This file
```

**Tech Stack:**
- **Backend:** Node.js 24, Express, TypeScript, Supabase SDK
- **Frontend:** Flutter 3.24+, Riverpod, GoRouter, Material 3
- **Database:** Supabase (PostgreSQL 15) with Row-Level Security
- **Auth:** Supabase Auth (Google OAuth + Magic Links)
- **Deployment:** Backend on Railway/Render, App on Firebase Hosting/Play Store

---

## 🚀 Quick Start

### Prerequisites
- Node.js 24+ and npm 11+
- Flutter 3.24+ with Dart 3.5+
- Supabase account (free tier works)

### 1. Database Setup
1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Run migrations in the SQL Editor (in order):
   - `supabase/migrations/001_create_persons.sql`
   - `supabase/migrations/002_create_relationships.sql`
   - `supabase/migrations/003_create_merge_requests.sql`
   - `supabase/migrations/004_rls_policies.sql`
   - `supabase/migrations/005_create_invite_tokens.sql`
3. Copy your **Supabase URL** and **anon key**

### 2. Backend Setup
```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your Supabase credentials
npm run dev
```
API runs at `http://localhost:3000`

### 3. Flutter App Setup
```bash
cd app
flutter pub get
cp .env.example .env
# Edit .env with your Supabase credentials and API URL
flutter run -d chrome
```

📖 **Detailed setup instructions:** See [How-To-Setup-DevelopmentEnv.md](How-To-Setup-DevelopmentEnv.md)

---

## 📱 How It Works

### The Family Tree Experience

1. **Sign In** — Google or email magic link
2. **Create Your Profile** — Name, phone, DOB, city, occupation
3. **Build Your Tree** — Add parents, siblings, spouse, children
   - **Phone number is required** for merge detection & invites
4. **Invite Family** — Share WhatsApp link, they claim their profile
5. **Automatic Connections** — When someone adds a person with a duplicate phone:
   - 🔔 Merge request created
   - 📊 Side-by-side comparison shown
   - ✅ Approve → Trees connect
   - ❌ Reject → Profiles stay separate

### N-Circle Network Search

Search your extended family network for:
- **People by name:** "Find everyone named Ravi"
- **By occupation:** "Find all doctors within 5 circles"
- **By marital status:** "Find all single relatives within 3 circles"
- **Connection path shown:** "You → Father → Uncle → Match"

Perfect for:
- 🤝 Professional networking within family
- 💍 Marriage proposals (rishta)
- 🎓 Finding mentors in your field
- 🏠 Discovering relatives in a new city

---

## 🔒 Security & Privacy

### Data Isolation
- **Row-Level Security (RLS)** enforced at database level
- Users can only see persons **in their connected tree**
- Graph traversal algorithm ensures no leaks across disconnected trees

### Authentication
- JWT tokens validated on every API request
- Supabase handles OAuth & magic links securely
- Service role key never exposed to clients

### Phone Numbers
- Stored in E.164 format: `+91XXXXXXXXXX`
- Normalized before storage to prevent duplicates
- Used only for merge detection & invites (not publicly displayed)

---

## 🧪 Testing

### Manual Test Checklist
- [ ] Sign in with Google
- [ ] Sign in with email (check magic link in inbox)
- [ ] Complete profile setup
- [ ] Add father, mother, spouse, child
- [ ] Pan/zoom the tree canvas
- [ ] Generate invite link and share
- [ ] Claim invite in incognito browser
- [ ] Trigger merge by adding duplicate phone
- [ ] Review and approve merge request
- [ ] Search network for "doctor" within 3 circles
- [ ] View connection path in search results

### Running Automated Tests (Coming Soon)
```bash
# Backend
cd backend && npm test

# Flutter
cd app && flutter test
```

---

## 🚢 Deployment

### Backend (Railway)
1. Push to GitHub
2. Connect repo to Railway
3. Set environment variables
4. Deploy ✅

### Flutter Web (Firebase Hosting)
```bash
cd app
flutter build web --release
firebase init
firebase deploy
```

### Android APK
```bash
cd app
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
```

---

## 📊 Database Schema

```sql
-- Core Tables
persons (id, name, phone, gender, dob, city, occupation, community, ...)
relationships (id, person_id, related_person_id, type) -- FATHER_OF, SPOUSE_OF, etc.
merge_requests (id, target_person_id, matched_person_id, status, field_conflicts)
invite_tokens (id, person_id, token, expires_at)

-- Relationship Types
- FATHER_OF, MOTHER_OF
- SPOUSE_OF
- SIBLING_OF
- CHILD_OF
```

The `relationships` table has a trigger that automatically creates inverse relationships (e.g., if A is `FATHER_OF` B, then B gets `CHILD_OF` A).

---

## 🗺️ Roadmap

### ✅ v1.0 (MVP) — Feb 2026
- Core tree visualization
- Phone-based merging
- N-circle search
- Invite flow
- Auth (Google + Email)

### 🚧 v1.1 — Q2 2026
- Photo uploads
- Real-time updates
- Advanced merge detection (name + DOB)
- Export to PDF/PNG

### 📅 v1.2 — Q3 2026
- iOS app
- Privacy settings
- Family timeline (birthdays, anniversaries)
- Push notifications

### 🔮 v2.0 — Q4 2026
- AI-powered duplicate detection
- Genetic ancestry integration
- Community forums & events

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- **Geni.com** — Inspiration for tree visualization UI/UX
- **Supabase** — Excellent BaaS for auth, database, and hosting
- **Flutter** — Beautiful cross-platform framework
- **Indian families** — For the inspiration to build better family connection tools

---

## 📞 Support & Community

- 🐛 **Bug reports:** [Open a GitHub Issue](https://github.com/ManiKumar007/FamilyTree/issues)
- 💡 **Feature requests:** [Discussions](https://github.com/ManiKumar007/FamilyTree/discussions)
- 📧 **Email:** support@myfamilytree.app
- 💬 **Discord:** [Join our community](#)

---

**Built with ❤️ for Indian families**

*Connecting generations, one tree at a time* 🌳
