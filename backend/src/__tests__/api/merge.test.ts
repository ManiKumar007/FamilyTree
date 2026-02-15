import request from 'supertest';
import app from '../../index';
import { supabaseAdmin } from '../../config/supabase';

jest.mock('../../config/supabase');

describe('Merge API', () => {
  const mockMergeRequest = {
    id: 'merge-123',
    requester_user_id: 'user-1',
    person_a_id: 'person-1',
    person_b_id: 'person-2',
    status: 'pending',
    conflicts: [],
    created_at: new Date().toISOString(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /api/merge/requests', () => {
    it('should return pending merge requests', async () => {
      const mockSupabaseChain = {
        select: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        order: jest.fn().mockResolvedValue({
          data: [mockMergeRequest],
          error: null,
        }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      const response = await request(app)
        .get('/api/merge/requests')
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
    });
  });

  describe('POST /api/merge/:id/approve', () => {
    it('should approve a merge request', async () => {
      const mockSupabaseChain = {
        update: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        single: jest.fn().mockResolvedValue({
          data: { ...mockMergeRequest, status: 'approved' },
          error: null,
        }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      const response = await request(app)
        .post('/api/merge/merge-123/approve')
        .send({ resolution: {} })
        .expect(200);

      expect(response.body.status).toBe('approved');
    });
  });

  describe('POST /api/merge/:id/reject', () => {
    it('should reject a merge request', async () => {
      const mockSupabaseChain = {
        update: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        single: jest.fn().mockResolvedValue({
          data: { ...mockMergeRequest, status: 'rejected' },
          error: null,
        }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      const response = await request(app)
        .post('/api/merge/merge-123/reject')
        .expect(200);

      expect(response.body.status).toBe('rejected');
    });
  });
});
