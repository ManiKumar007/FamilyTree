import request from 'supertest';
import app from '../../index';
import { supabaseAdmin } from '../../config/supabase';

jest.mock('../../config/supabase');

describe('Search API', () => {
  const mockSearchResults = [
    {
      id: 'person-1',
      name: 'John Doe',
      phone: '+919876543210',
      gender: 'male',
    },
    {
      id: 'person-2',
      name: 'Jane Doe',
      phone: '+919876543211',
      gender: 'female',
    },
  ];

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /api/search', () => {
    it('should search by name', async () => {
      const mockSupabaseChain = {
        select: jest.fn().mockReturnThis(),
        ilike: jest.fn().mockReturnThis(),
        limit: jest.fn().mockResolvedValue({ data: mockSearchResults, error: null }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      const response = await request(app)
        .get('/api/search?q=John')
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(mockSupabaseChain.ilike).toHaveBeenCalledWith('name', '%John%');
    });

    it('should search by phone', async () => {
      const mockSupabaseChain = {
        select: jest.fn().mockReturnThis(),
        ilike: jest.fn().mockReturnThis(),
        limit: jest.fn().mockResolvedValue({ data: [mockSearchResults[0]], error: null }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      const response = await request(app)
        .get('/api/search?q=9876543210')
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
    });

    it('should return empty array when no results', async () => {
      const mockSupabaseChain = {
        select: jest.fn().mockReturnThis(),
        ilike: jest.fn().mockReturnThis(),
        limit: jest.fn().mockResolvedValue({ data: [], error: null }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      const response = await request(app)
        .get('/api/search?q=NonExistent')
        .expect(200);

      expect(response.body).toEqual([]);
    });

    it('should require query parameter', async () => {
      const response = await request(app)
        .get('/api/search')
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('should limit results', async () => {
      const mockSupabaseChain = {
        select: jest.fn().mockReturnThis(),
        ilike: jest.fn().mockReturnThis(),
        limit: jest.fn().mockResolvedValue({ data: mockSearchResults, error: null }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      await request(app)
        .get('/api/search?q=Doe&limit=10')
        .expect(200);

      expect(mockSupabaseChain.limit).toHaveBeenCalledWith(10);
    });
  });
});
