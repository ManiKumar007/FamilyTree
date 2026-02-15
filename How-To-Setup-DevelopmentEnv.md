# MyFamilyTree — Development Environment Setup

> This guide walks you through setting up the project locally from scratch.

---

## Prerequisites

Make sure the following are installed on your machine before proceeding:

| Tool | Minimum Version | Install Link |
|------|----------------|--------------|
| **Node.js** | v18+ (LTS recommended) | https://nodejs.org/ |
| **npm** | v9+ (ships with Node.js) | — |
| **Git** | Any recent version | https://git-scm.com/ |
| **Supabase CLI** (optional) | v1.100+ | https://supabase.com/docs/guides/cli |
| **VS Code** (recommended) | Latest | https://code.visualstudio.com/ |

### Verify installations

```bash
node --version    # Should print v18.x or higher
npm --version     # Should print 9.x or higher
git --version
```

---

## 1. Clone the Repository

```bash
git clone <repository-url>
cd FamilyTree
```

---

## 2. Install Backend Dependencies

```bash
cd backend
npm install
```

This installs all required packages defined in `package.json`, including:

| Package | Purpose |
|---------|---------|
| `express` | HTTP server framework |
| `@supabase/supabase-js` | Supabase client SDK (database, auth) |
| `cors` | Cross-origin resource sharing |
| `helmet` | Security headers |
| `express-rate-limit` | API rate limiting |
| `dotenv` | Environment variable loading |
| `zod` | Request validation / schema parsing |
| `typescript` | TypeScript compiler |
| `tsx` | TypeScript execution with hot-reload for dev |

---

## 3. Configure Environment Variables

Create a `.env` file in the `backend/` directory:

```bash
cp .env.example .env   # If .env.example exists, otherwise create manually
```

Add the following variables to `backend/.env`:

```env
# Supabase
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_ANON_KEY=<your-supabase-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<your-supabase-service-role-key>

# Server
PORT=3000
NODE_ENV=development

# App URLs
APP_URL=http://localhost:8080
INVITE_BASE_URL=http://localhost:8080/invite
```

### Where to find Supabase keys

1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Select your project (or create a new one)
3. Navigate to **Settings → API**
4. Copy the **Project URL**, **anon public** key, and **service_role secret** key

> ⚠️ **Never commit `.env` to version control.** Make sure `.gitignore` includes `.env`.

---

## 4. Set Up Supabase Database

### Option A: Using Supabase Dashboard (Web UI)

1. Go to your Supabase project → **SQL Editor**
2. Run each migration file in order from the `supabase/migrations/` folder:
   - `001_create_persons.sql`
   - `002_create_relationships.sql`
   - `003_create_merge_requests.sql`
   - `004_rls_policies.sql`
   - `005_create_invite_tokens.sql`
3. (Optional) Run `supabase/seed.sql` to populate sample data

### Option B: Using Supabase CLI (Local Development)

```bash
# Install the Supabase CLI if you haven't already
npm install -g supabase

# From the project root
supabase init        # Only if supabase/ config doesn't exist yet
supabase start       # Starts local Supabase (Docker required)
supabase db reset    # Applies migrations + seed data
```

> **Note**: The Supabase CLI local dev requires [Docker Desktop](https://www.docker.com/products/docker-desktop/) to be installed and running.

---

## 5. Run the Backend (Development Mode)

```bash
cd backend
npm run dev
```

This starts the server using `tsx watch` with hot-reload. The API will be available at:

```
http://localhost:3000
```

### Verify the server is running

```bash
curl http://localhost:3000/api/health
# Expected: {"status":"ok","timestamp":"..."}
```

---

## 6. Build for Production

```bash
cd backend
npm run build    # Compiles TypeScript → dist/
npm start        # Runs compiled JS from dist/
```

---

## 7. Available npm Scripts

Run these from the `backend/` directory:

| Script | Command | Description |
|--------|---------|-------------|
| `npm run dev` | `tsx watch src/index.ts` | Start dev server with hot-reload |
| `npm run build` | `tsc` | Compile TypeScript to JavaScript |
| `npm start` | `node dist/index.js` | Run the compiled production build |
| `npm run lint` | `eslint src/` | Lint the source code |
| `npm test` | `jest` | Run tests |

---

## 8. API Endpoints

Once the server is running, the following route groups are available:

| Route | Description |
|-------|-------------|
| `GET /api/health` | Health check |
| `/api/persons` | CRUD operations for family members |
| `/api/relationships` | Manage family relationships |
| `/api/tree` | Family tree traversal / graph queries |
| `/api/search` | Search within N-circle network |
| `/api/merge` | Tree merge requests |
| `/api/invite` | Invitation token management |

---

## 9. Project Structure

```
FamilyTree/
├── backend/
│   ├── package.json
│   ├── tsconfig.json
│   └── src/
│       ├── index.ts              # Express app entry point
│       ├── config/
│       │   ├── env.ts            # Environment variable definitions
│       │   └── supabase.ts       # Supabase client setup
│       ├── middleware/
│       │   ├── auth.ts           # Authentication middleware
│       │   └── errorHandler.ts   # Global error handler
│       ├── models/
│       │   └── types.ts          # TypeScript type definitions
│       ├── routes/
│       │   ├── persons.ts        # Person CRUD routes
│       │   ├── relationships.ts  # Relationship routes
│       │   ├── tree.ts           # Tree traversal routes
│       │   ├── search.ts         # Network search routes
│       │   ├── merge.ts          # Merge request routes
│       │   └── invite.ts         # Invite token routes
│       ├── services/
│       │   ├── graphService.ts   # Graph traversal logic
│       │   └── mergeService.ts   # Tree merge logic
│       └── utils/
│           └── phone.ts          # Phone number utilities
├── supabase/
│   ├── seed.sql                  # Sample seed data
│   └── migrations/               # Database migration scripts
├── IDEA.md                       # Product concept & architecture
└── README.md
```

---

## 10. Recommended VS Code Extensions

| Extension | ID | Purpose |
|-----------|----|---------|
| ESLint | `dbaeumer.vscode-eslint` | Linting |
| Prettier | `esbenp.prettier-vscode` | Code formatting |
| Thunder Client | `rangav.vscode-thunder-client` | API testing (Postman alternative) |
| DotENV | `mikestead.dotenv` | `.env` file syntax highlighting |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `npm install` fails | Make sure you're using Node.js v18+. Run `node --version` to check. |
| Server won't start | Ensure `.env` file exists in `backend/` with all required variables. |
| Supabase connection errors | Verify `SUPABASE_URL` and keys in `.env`. Check the Supabase dashboard to confirm the project is active. |
| Port 3000 already in use | Change `PORT` in `.env` or stop the process using port 3000: `npx kill-port 3000` |
| TypeScript compilation errors | Run `npm install` again to ensure all `@types/*` packages are installed. |

---

## Questions?

Reach out to the project maintainer or check [IDEA.md](IDEA.md) for the full product concept and technical architecture.
