import request from 'supertest';
import app from '../../index';
import { supabaseAdmin } from '../../config/supabase';

jest.mock('../../config/supabase');

describe('Tree API', () => {
  const mockPerson = {
    id: 'person-1',
    name: 'John Doe',
    phone: '+919876543210',
    gender: 'male',
  };

  const mockRelationships = [
    {
      id: 'rel-1',
      person_id: 'person-1',
      related_person_id: 'person-2',
      type: 'child',
    },
  ];

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('GET /api/tree', () => {
    it('should return user family tree', async () => {
      const mockGetPersonChain = {
        select: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        single: jest.fn().mockResolvedValue({ data: mockPerson, error: null }),
      };

      const mockGetRelChain = {
        select: jest.fn().mockReturnThis(),
        or: jest.fn().mockResolvedValue({ data: mockRelationships, error: null }),
      };

      (supabaseAdmin.from as jest.Mock)
        .mockReturnValueOnce(mockGetPersonChain)
        .mockReturnValue(mockGetRelChain);

      const response = await request(app)
        .get('/api/tree')
        .expect(200);

      expect(response.body).toHaveProperty('persons');
      expect(response.body).toHaveProperty('relationships');
      expect(response.body).toHaveProperty('rootPersonId');
    });
  });

  describe('GET /api/tree/:personId', () => {
    it('should return tree centered on specific person', async () => {
      const mockGetRelChain = {
        select: jest.fn().mockReturnThis(),
        or: jest.fn().mockResolvedValue({ data: mockRelationships, error: null }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockGetRelChain);

      const response = await request(app)
        .get('/api/tree/person-1')
        .expect(200);

      expect(response.body).toHaveProperty('persons');
      expect(response.body).toHaveProperty('relationships');
      expect(response.body.rootPersonId).toBe('person-1');
    });
  });
});
