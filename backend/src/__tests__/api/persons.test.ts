import request from 'supertest';
import app from '../../index';
import { supabaseAdmin } from '../../config/supabase';

// Mock Supabase
jest.mock('../../config/supabase', () => ({
  supabaseAdmin: {
    from: jest.fn(),
    auth: {
      getUser: jest.fn(),
    },
  },
}));

describe('Persons API', () => {
  const mockUserId = 'mock-user-123';
  const mockPerson = {
    id: 'person-123',
    name: 'John Doe',
    phone: '+919876543210',
    gender: 'male',
    email: 'john@example.com',
    date_of_birth: '1990-01-01',
    created_by_user_id: mockUserId,
    verified: false,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/persons', () => {
    it('should create a new person with valid data', async () => {
      const mockSupabaseChain = {
        insert: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        single: jest.fn().mockResolvedValue({ data: mockPerson, error: null }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      const newPerson = {
        name: 'John Doe',
        phone: '+919876543210',
        gender: 'male',
        email: 'john@example.com',
        date_of_birth: '1990-01-01',
      };

      const response = await request(app)
        .post('/api/persons')
        .send(newPerson)
        .expect(201);

      expect(response.body).toHaveProperty('person');
      expect(response.body.person).toMatchObject({
        name: newPerson.name,
        phone: newPerson.phone,
      });
    });

    it('should reject invalid phone number', async () => {
      const invalidPerson = {
        name: 'John Doe',
        phone: '123', // Invalid phone
        gender: 'male',
      };

      const response = await request(app)
        .post('/api/persons')
        .send(invalidPerson)
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('should reject missing required fields', async () => {
      const incompletePerson = {
        name: 'John Doe',
        // Missing phone and gender
      };

      const response = await request(app)
        .post('/api/persons')
        .send(incompletePerson)
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    it('should handle duplicate phone number', async () => {
      const mockSupabaseChain = {
        insert: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        single: jest.fn().mockResolvedValue({
          data: null,
          error: { code: '23505', message: 'duplicate key value' },
        }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      const newPerson = {
        name: 'John Doe',
        phone: '+919876543210',
        gender: 'male',
      };

      const response = await request(app)
        .post('/api/persons')
        .send(newPerson)
        .expect(409);

      expect(response.body.error).toContain('already exists');
    });
  });

  describe('GET /api/persons/:id', () => {
    it('should return person by ID', async () => {
      const mockSupabaseChain = {
        select: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        single: jest.fn().mockResolvedValue({ data: mockPerson, error: null }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      const response = await request(app)
        .get('/api/persons/person-123')
        .expect(200);

      expect(response.body).toMatchObject({
        id: mockPerson.id,
        name: mockPerson.name,
      });
    });

    it('should return 404 for non-existent person', async () => {
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
        .get('/api/persons/non-existent-id')
        .expect(404);
    });
  });

  describe('PUT /api/persons/:id', () => {
    it('should update person details', async () => {
      const updatedPerson = { ...mockPerson, name: 'Jane Doe' };
      const mockSupabaseChain = {
        update: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        single: jest.fn().mockResolvedValue({ data: updatedPerson, error: null }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      const response = await request(app)
        .put('/api/persons/person-123')
        .send({ name: 'Jane Doe' })
        .expect(200);

      expect(response.body.name).toBe('Jane Doe');
    });

    it('should validate updated phone number', async () => {
      const response = await request(app)
        .put('/api/persons/person-123')
        .send({ phone: '123' }) // Invalid phone
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });
  });

  describe('GET /api/persons/me', () => {
    it('should return current user profile', async () => {
      const mockSupabaseChain = {
        select: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        single: jest.fn().mockResolvedValue({ data: mockPerson, error: null }),
      };

      (supabaseAdmin.from as jest.Mock).mockReturnValue(mockSupabaseChain);

      const response = await request(app)
        .get('/api/persons/me')
        .expect(200);

      expect(response.body).toHaveProperty('id');
    });
  });
});
