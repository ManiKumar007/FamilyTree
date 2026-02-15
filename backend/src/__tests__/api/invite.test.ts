import request from 'supertest';
import app from '../../index';
import { supabaseAdmin } from '../../config/supabase';

jest.mock('../../config/supabase');

describe('Invite API', () => {
  const mockInviteToken = {
    id: 'token-123',
    token: 'abc123xyz',
    inviter_user_id: 'user-1',
    person_id: 'person-1',
    expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
    created_at: new Date().toISOString(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/invite/create', () => {
    it('should create an invite token', async () => {
      const mockSupabaseChain = {
        insert: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        single: jest.fn().mockResolvedValue({
          data: mockInviteToken,
          error: null,
        }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      const response = await request(app)
        .post('/api/invite/create')
        .send({ person_id: 'person-1' })
        .expect(201);

      expect(response.body).toHaveProperty('token');
      expect(response.body).toHaveProperty('inviteUrl');
    });

    it('should return 400 if person_id is missing', async () => {
      const response = await request(app)
        .post('/api/invite/create')
        .send({})
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });
  });

  describe('GET /api/invite/:token', () => {
    it('should validate and return invite details', async () => {
      const mockSupabaseChain = {
        select: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        single: jest.fn().mockResolvedValue({
          data: mockInviteToken,
          error: null,
        }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      const response = await request(app)
        .get('/api/invite/abc123xyz')
        .expect(200);

      expect(response.body).toHaveProperty('token');
    });

    it('should return 404 for invalid token', async () => {
      const mockSupabaseChain = {
        select: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        single: jest.fn().mockResolvedValue({
          data: null,
          error: { code: 'PGRST116' },
        }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      await request(app)
        .get('/api/invite/invalid-token')
        .expect(404);
    });

    it('should return 410 for expired token', async () => {
      const expiredToken = {
        ...mockInviteToken,
        expires_at: new Date(Date.now() - 1000).toISOString(),
      };

      const mockSupabaseChain = {
        select: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        single: jest.fn().mockResolvedValue({
          data: expiredToken,
          error: null,
        }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      const response = await request(app)
        .get('/api/invite/abc123xyz')
        .expect(410);

      expect(response.body.error).toContain('expired');
    });
  });

  describe('POST /api/invite/:token/accept', () => {
    it('should accept an invite and link to user', async () => {
      const mockGetTokenChain = {
        select: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        single: jest.fn().mockResolvedValue({
          data: mockInviteToken,
          error: null,
        }),
      };

      const mockUpdatePersonChain = {
        update: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        single: jest.fn().mockResolvedValue({
          data: { id: 'person-1', user_id: 'user-2' },
          error: null,
        }),
      };

      const mockDeleteTokenChain = {
        delete: jest.fn().mockReturnThis(),
        eq: jest.fn().mockResolvedValue({ error: null }),
      };

      (supabaseAdmin.from as jest.Mock)
        .mockReturnValueOnce(mockGetTokenChain)
        .mockReturnValueOnce(mockUpdatePersonChain)
        .mockReturnValueOnce(mockDeleteTokenChain);

      const response = await request(app)
        .post('/api/invite/abc123xyz/accept')
        .expect(200);

      expect(response.body).toHaveProperty('id');
    });
  });
});
