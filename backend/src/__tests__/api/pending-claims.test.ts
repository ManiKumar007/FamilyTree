import request from 'supertest';
import app from '../../index';
import { supabaseAdmin } from '../../config/supabase';
import * as emailService from '../../services/emailService';

// ── Mocks ────────────────────────────────────────────────────────────────────

jest.mock('../../config/supabase', () => ({
  supabaseAdmin: {
    from: jest.fn(),
    auth: {
      getUser: jest.fn(),
      admin: { getUserById: jest.fn() },
    },
  },
}));

jest.mock('../../services/emailService', () => ({
  sendClaimApprovalRequest: jest.fn().mockResolvedValue(undefined),
  sendClaimOutcomeEmail:    jest.fn().mockResolvedValue(undefined),
}));

// ── Test data ─────────────────────────────────────────────────────────────────

const CLAIMANT_ID = 'claimant-user-111';
const OWNER_ID    = 'owner-user-222';
const PERSON_ID   = 'person-aaa-111';
const CLAIM_ID    = 'claim-bbb-222';

const APPROVE_TOKEN = 'approve-token-aaa';
const REJECT_TOKEN  = 'reject-token-bbb';

const mockPerson = {
  id: PERSON_ID,
  name: 'Arjun Test',
  auth_user_id: null,
  created_by_user_id: OWNER_ID,
  phone: '+919000000001',
  email: 'owner@example.com',
};

const mockPendingClaim = {
  id: CLAIM_ID,
  person_id: PERSON_ID,
  claimed_by_user_id: CLAIMANT_ID,
  created_by_user_id: OWNER_ID,
  status: 'pending',
  approve_token: APPROVE_TOKEN,
  reject_token: REJECT_TOKEN,
  profile_updates: { given_name: 'Arjun', surname: 'Test' },
  claimant_email: 'claimant@example.com',
  expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
  created_at: new Date().toISOString(),
};

const expiredClaim = {
  ...mockPendingClaim,
  id: 'claim-expired-333',
  expires_at: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(), // yesterday
};

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Returns an auth header using the test AUTH_BYPASS mechanism. */
function makeQuery() {
  // The auth middleware uses AUTH_BYPASS env var — set in beforeAll.
  // We still send an Authorization header so the header check passes.
  return { headers: { Authorization: 'Bearer test-bypass-token' } };
}

/**
 * Build a full Supabase query-builder chain mock.
 * Each call to .from() can return a different chain object.
 */
function makeChain(overrides: Record<string, jest.Mock> = {}): Record<string, jest.Mock> {
  const chain: Record<string, jest.Mock> = {
    select:      jest.fn().mockReturnThis(),
    insert:      jest.fn().mockReturnThis(),
    update:      jest.fn().mockReturnThis(),
    delete:      jest.fn().mockReturnThis(),
    eq:          jest.fn().mockReturnThis(),
    neq:         jest.fn().mockReturnThis(),
    order:       jest.fn().mockReturnThis(),
    limit:       jest.fn().mockReturnThis(),
    single:      jest.fn().mockResolvedValue({ data: null, error: null }),
    maybeSingle: jest.fn().mockResolvedValue({ data: null, error: null }),
    ...overrides,
  };
  // Make every chainable method return `this`
  (Object.keys(chain) as (keyof typeof chain)[]).forEach(k => {
    if (k !== 'single' && k !== 'maybeSingle') {
      chain[k].mockReturnThis();
    }
  });
  return chain;
}

// ── Test suites ───────────────────────────────────────────────────────────────

describe('Pending Claims Feature', () => {
  const fromMock = supabaseAdmin.from as jest.Mock;
  const getUserMock = supabaseAdmin.auth.getUser as jest.Mock;
  const getByIdMock = (supabaseAdmin.auth.admin as any).getUserById as jest.Mock;

  beforeAll(() => {
    process.env.AUTH_BYPASS         = 'true';
    process.env.AUTH_BYPASS_USER_ID = CLAIMANT_ID;
    process.env.AUTH_BYPASS_EMAIL   = 'claimant@example.com';
    process.env.FRONTEND_URL        = 'https://test.app';
    process.env.BACKEND_URL         = 'https://test-api.app';
  });

  afterAll(() => {
    delete process.env.AUTH_BYPASS;
    delete process.env.AUTH_BYPASS_USER_ID;
    delete process.env.AUTH_BYPASS_EMAIL;
  });

  beforeEach(() => {
    jest.clearAllMocks();
    // Default: auth succeeds
    getUserMock.mockResolvedValue({ data: { user: { id: CLAIMANT_ID } }, error: null });
  });

  // ── POST /claim-profile ────────────────────────────────────────────────────

  describe('POST /api/persons/claim-profile', () => {
    it('creates a pending claim and returns status=pending', async () => {
      fromMock.mockImplementation((table: string) => {
        if (table === 'persons') {
          return makeChain({
            // First call returns existing-profile check (none)
            // Second call returns the person to claim
            maybeSingle: jest.fn()
              .mockResolvedValueOnce({ data: null, error: null })   // no existing profile for claimant
              .mockResolvedValueOnce({ data: null, error: null }), // no existing pending claim
            single: jest.fn().mockResolvedValue({ data: mockPerson, error: null }),
          });
        }
        if (table === 'pending_claims') {
          return makeChain({
            maybeSingle: jest.fn().mockResolvedValue({ data: null, error: null }), // no existing claim
            single: jest.fn().mockResolvedValue({ data: mockPendingClaim, error: null }),
          });
        }
        if (table === 'notifications') {
          return makeChain({ insert: jest.fn().mockResolvedValue({ data: {}, error: null }) });
        }
        return makeChain();
      });

      getByIdMock.mockResolvedValue({
        data: { user: { email: 'owner@example.com' } },
        error: null,
      });

      const res = await request(app)
        .post('/api/persons/claim-profile')
        .set('Authorization', 'Bearer test-bypass-token')
        .send({
          person_id:       PERSON_ID,
          email:           'claimant@example.com',
          profile_updates: { given_name: 'Arjun', surname: 'Test' },
        });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe('pending');
      expect(res.body.data).toHaveProperty('expires_at');
      expect(emailService.sendClaimApprovalRequest).toHaveBeenCalledTimes(1);
      expect(emailService.sendClaimApprovalRequest).toHaveBeenCalledWith(
        expect.objectContaining({
          to: 'owner@example.com',
          personName: mockPerson.name,
          approveUrl: expect.stringContaining(APPROVE_TOKEN),
          rejectUrl:  expect.stringContaining(REJECT_TOKEN),
        }),
      );
    });

    it('returns status=pending (not 409) when same claim re-submitted within window', async () => {
      fromMock.mockImplementation((table: string) => {
        if (table === 'persons') {
          return makeChain({
            maybeSingle: jest.fn().mockResolvedValue({ data: null, error: null }),
            single: jest.fn().mockResolvedValue({ data: mockPerson, error: null }),
          });
        }
        if (table === 'pending_claims') {
          return makeChain({
            // Existing active (non-expired) claim found
            maybeSingle: jest.fn().mockResolvedValue({ data: mockPendingClaim, error: null }),
          });
        }
        return makeChain();
      });

      const res = await request(app)
        .post('/api/persons/claim-profile')
        .set('Authorization', 'Bearer test-bypass-token')
        .send({ person_id: PERSON_ID });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe('pending');
      // Should NOT send another email
      expect(emailService.sendClaimApprovalRequest).not.toHaveBeenCalled();
    });

    it('auto-approves and returns status=approved when existing claim is expired', async () => {
      const updatedPerson = { ...mockPerson, auth_user_id: CLAIMANT_ID };

      fromMock.mockImplementation((table: string) => {
        if (table === 'persons') {
          return makeChain({
            maybeSingle: jest.fn().mockResolvedValue({ data: null, error: null }),
            single: jest.fn()
              .mockResolvedValueOnce({ data: mockPerson, error: null })  // get person to claim
              .mockResolvedValueOnce({ data: updatedPerson, error: null }), // after apply
            update: jest.fn().mockReturnThis(),
          });
        }
        if (table === 'pending_claims') {
          return makeChain({
            maybeSingle: jest.fn().mockResolvedValue({ data: expiredClaim, error: null }),
            update: jest.fn().mockReturnThis(),
          });
        }
        return makeChain();
      });

      const res = await request(app)
        .post('/api/persons/claim-profile')
        .set('Authorization', 'Bearer test-bypass-token')
        .send({ person_id: PERSON_ID });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe('approved');
      expect(res.body.data).toHaveProperty('person');
    });

    it('returns 400 when person_id is missing', async () => {
      const res = await request(app)
        .post('/api/persons/claim-profile')
        .set('Authorization', 'Bearer test-bypass-token')
        .send({});

      expect(res.status).toBe(400);
    });

    it('returns 409 when person is already claimed', async () => {
      fromMock.mockImplementation((table: string) => {
        if (table === 'persons') {
          return makeChain({
            maybeSingle: jest.fn().mockResolvedValue({ data: null, error: null }),
            single: jest.fn().mockResolvedValue({
              data: { ...mockPerson, auth_user_id: 'some-other-user' },
              error: null,
            }),
          });
        }
        return makeChain();
      });

      const res = await request(app)
        .post('/api/persons/claim-profile')
        .set('Authorization', 'Bearer test-bypass-token')
        .send({ person_id: PERSON_ID });

      expect(res.status).toBe(409);
      expect(res.body.error.message).toMatch(/already been claimed/i);
    });

    it('returns 409 when claimant already has a profile', async () => {
      fromMock.mockImplementation((table: string) => {
        if (table === 'persons') {
          return makeChain({
            maybeSingle: jest.fn().mockResolvedValue({
              data: { id: 'existing-person-id' }, // claimant already has a profile
              error: null,
            }),
          });
        }
        return makeChain();
      });

      const res = await request(app)
        .post('/api/persons/claim-profile')
        .set('Authorization', 'Bearer test-bypass-token')
        .send({ person_id: PERSON_ID });

      expect(res.status).toBe(409);
      expect(res.body.error.message).toMatch(/already have a profile/i);
    });

    it('returns 401 when no auth header is provided', async () => {
      // Temporarily disable bypass
      const saved = process.env.AUTH_BYPASS;
      delete process.env.AUTH_BYPASS;

      const res = await request(app)
        .post('/api/persons/claim-profile')
        .send({ person_id: PERSON_ID });

      expect(res.status).toBe(401);
      process.env.AUTH_BYPASS = saved;
    });
  });

  // ── GET /my-pending-claim ─────────────────────────────────────────────────

  describe('GET /api/persons/my-pending-claim', () => {
    it('returns hasPendingClaim=true when an active claim exists', async () => {
      const personSummary = { id: PERSON_ID, name: 'Arjun Test', photo_url: null };

      fromMock.mockImplementation((table: string) => {
        if (table === 'pending_claims') {
          return makeChain({
            maybeSingle: jest.fn().mockResolvedValue({ data: mockPendingClaim, error: null }),
          });
        }
        if (table === 'persons') {
          return makeChain({
            single: jest.fn().mockResolvedValue({ data: personSummary, error: null }),
          });
        }
        return makeChain();
      });

      const res = await request(app)
        .get('/api/persons/my-pending-claim')
        .set('Authorization', 'Bearer test-bypass-token');

      expect(res.status).toBe(200);
      expect(res.body.data.hasPendingClaim).toBe(true);
      expect(res.body.data.claim.person_name).toBe('Arjun Test');
      expect(res.body.data.claim).toHaveProperty('expires_at');
    });

    it('returns hasPendingClaim=false when no claim exists', async () => {
      fromMock.mockImplementation(() =>
        makeChain({ maybeSingle: jest.fn().mockResolvedValue({ data: null, error: null }) }),
      );

      const res = await request(app)
        .get('/api/persons/my-pending-claim')
        .set('Authorization', 'Bearer test-bypass-token');

      expect(res.status).toBe(200);
      expect(res.body.data.hasPendingClaim).toBe(false);
    });

    it('auto-approves and returns autoApproved=true when claim is expired', async () => {
      const updatedPerson = { ...mockPerson, auth_user_id: CLAIMANT_ID };

      fromMock.mockImplementation((table: string) => {
        if (table === 'pending_claims') {
          return makeChain({
            maybeSingle: jest.fn().mockResolvedValue({ data: expiredClaim, error: null }),
            update: jest.fn().mockReturnThis(),
          });
        }
        if (table === 'persons') {
          return makeChain({
            single: jest.fn().mockResolvedValue({ data: updatedPerson, error: null }),
            update: jest.fn().mockReturnThis(),
          });
        }
        return makeChain();
      });

      const res = await request(app)
        .get('/api/persons/my-pending-claim')
        .set('Authorization', 'Bearer test-bypass-token');

      expect(res.status).toBe(200);
      expect(res.body.data.hasPendingClaim).toBe(false);
      expect(res.body.data.autoApproved).toBe(true);
      expect(res.body.data).toHaveProperty('person');
    });
  });

  // ── GET /claim-approve/:token  (public) ───────────────────────────────────

  describe('GET /api/persons/claim-approve/:token  (public)', () => {
    it('approves claim and redirects to /tree?claim_approved=true', async () => {
      fromMock.mockImplementation((table: string) => {
        if (table === 'pending_claims') {
          return makeChain({
            single: jest.fn().mockResolvedValue({ data: mockPendingClaim, error: null }),
            update: jest.fn().mockReturnThis(),
          });
        }
        if (table === 'persons') {
          return makeChain({
            single: jest.fn().mockResolvedValue({ data: mockPerson, error: null }),
            update: jest.fn().mockReturnThis(),
          });
        }
        if (table === 'notifications') {
          return makeChain({ insert: jest.fn().mockResolvedValue({ data: {}, error: null }) });
        }
        return makeChain();
      });

      const res = await request(app)
        .get(`/api/persons/claim-approve/${APPROVE_TOKEN}`)
        .redirects(0); // don't follow the redirect — inspect it directly

      expect(res.status).toBe(302);
      expect(res.headers.location).toContain('claim_approved=true');
      expect(emailService.sendClaimOutcomeEmail).toHaveBeenCalledWith(
        expect.objectContaining({ approved: true, personName: mockPerson.name }),
      );
    });

    it('redirects with claim_already_processed when claim is not pending', async () => {
      const resolvedClaim = { ...mockPendingClaim, status: 'approved' };

      fromMock.mockImplementation((table: string) => {
        if (table === 'pending_claims') {
          return makeChain({
            single: jest.fn().mockResolvedValue({ data: resolvedClaim, error: null }),
          });
        }
        return makeChain();
      });

      const res = await request(app)
        .get(`/api/persons/claim-approve/${APPROVE_TOKEN}`)
        .redirects(0);

      expect(res.status).toBe(302);
      expect(res.headers.location).toContain('claim_already_processed=true');
    });

    it('returns 404 HTML when token is not found', async () => {
      fromMock.mockImplementation((table: string) => {
        if (table === 'pending_claims') {
          return makeChain({
            single: jest.fn().mockResolvedValue({ data: null, error: { message: 'not found' } }),
          });
        }
        return makeChain();
      });

      const res = await request(app)
        .get('/api/persons/claim-approve/invalid-token')
        .redirects(0);

      expect(res.status).toBe(404);
      expect(res.text).toContain('not found');
    });
  });

  // ── GET /claim-reject/:token  (public) ────────────────────────────────────

  describe('GET /api/persons/claim-reject/:token  (public)', () => {
    it('rejects claim and redirects to /?claim_rejected=true', async () => {
      fromMock.mockImplementation((table: string) => {
        if (table === 'pending_claims') {
          return makeChain({
            single: jest.fn().mockResolvedValue({ data: mockPendingClaim, error: null }),
            update: jest.fn().mockReturnThis(),
          });
        }
        if (table === 'persons') {
          return makeChain({
            single: jest.fn().mockResolvedValue({ data: mockPerson, error: null }),
          });
        }
        return makeChain();
      });

      const res = await request(app)
        .get(`/api/persons/claim-reject/${REJECT_TOKEN}`)
        .redirects(0);

      expect(res.status).toBe(302);
      expect(res.headers.location).toContain('claim_rejected=true');
      expect(emailService.sendClaimOutcomeEmail).toHaveBeenCalledWith(
        expect.objectContaining({ approved: false, personName: mockPerson.name }),
      );
    });

    it('redirects with claim_already_processed when claim already resolved', async () => {
      const resolvedClaim = { ...mockPendingClaim, status: 'rejected' };

      fromMock.mockImplementation((table: string) => {
        if (table === 'pending_claims') {
          return makeChain({
            single: jest.fn().mockResolvedValue({ data: resolvedClaim, error: null }),
          });
        }
        return makeChain();
      });

      const res = await request(app)
        .get(`/api/persons/claim-reject/${REJECT_TOKEN}`)
        .redirects(0);

      expect(res.status).toBe(302);
      expect(res.headers.location).toContain('claim_already_processed=true');
    });

    it('returns 404 HTML when reject token is not found', async () => {
      fromMock.mockImplementation((table: string) => {
        if (table === 'pending_claims') {
          return makeChain({
            single: jest.fn().mockResolvedValue({ data: null, error: { message: 'not found' } }),
          });
        }
        return makeChain();
      });

      const res = await request(app)
        .get('/api/persons/claim-reject/invalid-token')
        .redirects(0);

      expect(res.status).toBe(404);
    });
  });

  // ── Email service integration ─────────────────────────────────────────────

  describe('Email service (mock verification)', () => {
    it('does NOT send email when creator has no email address', async () => {
      fromMock.mockImplementation((table: string) => {
        if (table === 'persons') {
          return makeChain({
            maybeSingle: jest.fn().mockResolvedValue({ data: null, error: null }),
            single: jest.fn().mockResolvedValue({
              // Person with no created_by_user_id
              data: { ...mockPerson, created_by_user_id: null },
              error: null,
            }),
          });
        }
        if (table === 'pending_claims') {
          return makeChain({
            maybeSingle: jest.fn().mockResolvedValue({ data: null, error: null }),
            single: jest.fn().mockResolvedValue({ data: mockPendingClaim, error: null }),
          });
        }
        return makeChain();
      });

      await request(app)
        .post('/api/persons/claim-profile')
        .set('Authorization', 'Bearer test-bypass-token')
        .send({ person_id: PERSON_ID });

      // No created_by_user_id → no email lookup → no email sent
      expect(emailService.sendClaimApprovalRequest).not.toHaveBeenCalled();
    });
  });
});
