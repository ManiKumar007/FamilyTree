import request from 'supertest';
import app from '../../index';
import { supabaseAdmin } from '../../config/supabase';

jest.mock('../../config/supabase');

describe('Relationships API', () => {
  const mockRelationship = {
    id: 'rel-123',
    person_id: 'person-1',
    related_person_id: 'person-2',
    type: 'child',
    created_by_user_id: 'mock-user-123',
    created_at: new Date().toISOString(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/relationships', () => {
    it('should create a new relationship', async () => {
      const mockSupabaseChain = {
        insert: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        single: jest.fn().mockResolvedValue({ data: mockRelationship, error: null }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      const newRelationship = {
        person_id: 'person-1',
        related_person_id: 'person-2',
        type: 'child',
      };

      const response = await request(app)
        .post('/api/relationships')
        .send(newRelationship)
        .expect(201);

      expect(response.body).toMatchObject({
        person_id: newRelationship.person_id,
        related_person_id: newRelationship.related_person_id,
        type: newRelationship.type,
      });
    });

    it('should reject invalid relationship type', async () => {
      const invalidRelationship = {
        person_id: 'person-1',
        related_person_id: 'person-2',
        type: 'invalid-type',
      };

      const response = await request(app)
        .post('/api/relationships')
        .send(invalidRelationship)
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('should reject self-referencing relationship', async () => {
      const selfRelationship = {
        person_id: 'person-1',
        related_person_id: 'person-1',
        type: 'child',
      };

      const response = await request(app)
        .post('/api/relationships')
        .send(selfRelationship)
        .expect(400);

      expect(response.body.error).toContain('cannot relate to themselves');
    });
  });

  describe('GET /api/relationships/:personId', () => {
    it('should return all relationships for a person', async () => {
      const mockRelationships = [
        { ...mockRelationship, id: 'rel-1' },
        { ...mockRelationship, id: 'rel-2' },
      ];

      const mockSupabaseChain = {
        select: jest.fn().mockReturnThis(),
        or: jest.fn().mockResolvedValue({ data: mockRelationships, error: null }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      const response = await request(app)
        .get('/api/relationships/person-1')
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBe(2);
    });
  });

  describe('DELETE /api/relationships/:id', () => {
    it('should delete a relationship', async () => {
      const mockSupabaseChain = {
        delete: jest.fn().mockReturnThis(),
        eq: jest.fn().mockResolvedValue({ error: null }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      await request(app)
        .delete('/api/relationships/rel-123')
        .expect(204);
    });
  });
});
