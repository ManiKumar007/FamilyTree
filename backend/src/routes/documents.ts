import { Router, Response } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import { DocumentTypeEnum } from '../models/types';
import { successResponse, errorResponse, ErrorCodes } from '../utils/response';
import { sanitizeObject } from '../utils/sanitize';

export const documentsRouter = Router();

// All routes require authentication
documentsRouter.use(authMiddleware);

// Validation schemas
const uploadDocumentSchema = z.object({
  person_id: z.string().uuid(),
  document_type: DocumentTypeEnum,
  document_url: z.string().url(),
  document_name: z.string().min(1).max(200),
  description: z.string().optional(),
});

const updateDocumentSchema = uploadDocumentSchema.partial().omit({ person_id: true });

/**
 * POST /api/documents — Upload a new document
 */
documentsRouter.post('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const parsed = uploadDocumentSchema.parse(req.body);

    // Verify person exists and user has access
    const { data: person } = await supabaseAdmin
      .from('persons')
      .select('created_by_user_id, auth_user_id')
      .eq('id', parsed.person_id)
      .single();

    if (!person) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Person not found'));
      return;
    }

    if (person.created_by_user_id !== req.userId && person.auth_user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'You can only upload documents for persons you created or your own profile'));
      return;
    }

    const sanitized = sanitizeObject(parsed, ['document_name', 'description']);

    const documentData = {
      ...sanitized,
      uploaded_by_user_id: req.userId,
    };

    const { data, error } = await supabaseAdmin
      .from('person_documents')
      .insert(documentData)
      .select()
      .single();

    if (error) throw error;

    res.status(201).json(successResponse(data));
  } catch (err: any) {
    if (err instanceof z.ZodError) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Validation failed', err.errors));
      return;
    }
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * GET /api/documents/person/:personId — Get all documents for a person
 */
documentsRouter.get('/person/:personId', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('person_documents')
      .select('*')
      .eq('person_id', req.params.personId)
      .order('uploaded_at', { ascending: false });

    if (error) throw error;

    res.json(successResponse(data || []));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * GET /api/documents/:id — Get a single document
 */
documentsRouter.get('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('person_documents')
      .select('*')
      .eq('id', req.params.id)
      .single();

    if (error || !data) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Document not found'));
      return;
    }

    res.json(successResponse(data));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * PUT /api/documents/:id — Update a document
 */
documentsRouter.put('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const parsed = updateDocumentSchema.parse(req.body);

    // Verify ownership
    const { data: existing } = await supabaseAdmin
      .from('person_documents')
      .select('uploaded_by_user_id')
      .eq('id', req.params.id)
      .single();

    if (!existing) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Document not found'));
      return;
    }

    if (existing.uploaded_by_user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'You can only edit documents you uploaded'));
      return;
    }

    const sanitized = sanitizeObject(parsed, ['document_name', 'description']);

    const { data, error } = await supabaseAdmin
      .from('person_documents')
      .update(sanitized)
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    res.json(successResponse(data));
  } catch (err: any) {
    if (err instanceof z.ZodError) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Validation failed', err.errors));
      return;
    }
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * DELETE /api/documents/:id — Delete a document
 */
documentsRouter.delete('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data: existing } = await supabaseAdmin
      .from('person_documents')
      .select('uploaded_by_user_id, document_name')
      .eq('id', req.params.id)
      .single();

    if (!existing) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Document not found'));
      return;
    }

    if (existing.uploaded_by_user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'You can only delete documents you uploaded'));
      return;
    }

    const { error } = await supabaseAdmin
      .from('person_documents')
      .delete()
      .eq('id', req.params.id);

    if (error) throw error;

    res.json(successResponse({ message: `Document '${existing.document_name}' deleted successfully` }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});
