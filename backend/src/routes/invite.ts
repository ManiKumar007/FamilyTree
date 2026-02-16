import { Router, Response } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import { env } from '../config/env';
import { successResponse, errorResponse, ErrorCodes } from '../utils/response';

export const inviteRouter = Router();

inviteRouter.use(authMiddleware);

/**
 * POST /api/invite/generate — Generate an invite link for an unclaimed person.
 */
const generateSchema = z.object({
  person_id: z.string().uuid(),
});

inviteRouter.post('/generate', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const parsed = generateSchema.parse(req.body);

    // Verify person exists and is unclaimed
    const { data: person, error: pError } = await supabaseAdmin
      .from('persons')
      .select('id, name, verified, phone')
      .eq('id', parsed.person_id)
      .single();

    if (pError || !person) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Person not found'));
      return;
    }

    if (person.verified) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'This person has already claimed their profile'));
      return;
    }

    // Check if an active invite already exists
    const { data: existingInvite } = await supabaseAdmin
      .from('invite_tokens')
      .select('*')
      .eq('person_id', parsed.person_id)
      .eq('used', false)
      .gte('expires_at', new Date().toISOString())
      .single();

    if (existingInvite) {
      const inviteUrl = `${env.INVITE_BASE_URL}?token=${existingInvite.token}`;
      res.json(successResponse({
        invite_url: inviteUrl,
        token: existingInvite.token,
        person_name: person.name,
        expires_at: existingInvite.expires_at,
      }));
      return;
    }

    // Create new invite token
    const { data: invite, error: iError } = await supabaseAdmin
      .from('invite_tokens')
      .insert({
        person_id: parsed.person_id,
        invited_by_user_id: req.userId,
      })
      .select()
      .single();

    if (iError) throw iError;

    const inviteUrl = `${env.INVITE_BASE_URL}?token=${invite.token}`;

    res.status(201).json(successResponse({
      invite_url: inviteUrl,
      token: invite.token,
      person_name: person.name,
      phone: person.phone,
      expires_at: invite.expires_at,
      message: `${person.name}, you've been added to a family tree on MyFamilyTree! Claim your profile: ${inviteUrl}`,
    }));
  } catch (err: any) {
    if (err instanceof z.ZodError) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Validation failed', err.errors));
      return;
    }
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * POST /api/invite/claim — Claim an invite and link the person to the auth user.
 */
const claimSchema = z.object({
  token: z.string().min(1),
});

inviteRouter.post('/claim', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const parsed = claimSchema.parse(req.body);

    // Find the invite token
    const { data: invite, error: iError } = await supabaseAdmin
      .from('invite_tokens')
      .select('*')
      .eq('token', parsed.token)
      .single();

    if (iError || !invite) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Invalid invite token'));
      return;
    }

    if (invite.used) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'This invite has already been used'));
      return;
    }

    if (new Date(invite.expires_at) < new Date()) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'This invite has expired'));
      return;
    }

    // Claim the person record
    const { data: person, error: pError } = await supabaseAdmin
      .from('persons')
      .update({
        auth_user_id: req.userId,
        verified: true,
      })
      .eq('id', invite.person_id)
      .select()
      .single();

    if (pError) throw pError;

    // Mark invite as used
    await supabaseAdmin
      .from('invite_tokens')
      .update({
        used: true,
        used_by_user_id: req.userId,
      })
      .eq('id', invite.id);

    res.json(successResponse({
      message: 'Profile claimed successfully!',
      person,
    }));
  } catch (err: any) {
    if (err instanceof z.ZodError) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Validation failed', err.errors));
      return;
    }
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});
