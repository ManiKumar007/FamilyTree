import { Router, Response } from 'express';
import { z } from 'zod';
import { supabaseAdmin } from '../config/supabase';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import { ForumPostTypeEnum } from '../models/types';
import { successResponse, errorResponse, paginatedResponse, ErrorCodes } from '../utils/response';
import { sanitizeObject } from '../utils/sanitize';

export const forumRouter = Router();

// All routes require authentication
forumRouter.use(authMiddleware);

// Validation schemas
const createPostSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1),
  post_type: ForumPostTypeEnum,
  tags: z.array(z.string()).optional(),
});

const updatePostSchema = createPostSchema.partial();

const createCommentSchema = z.object({
  post_id: z.string().uuid(),
  content: z.string().min(1),
  parent_comment_id: z.string().uuid().optional(),
});

const uploadMediaSchema = z.object({
  post_id: z.string().uuid(),
  media_url: z.string().url(),
  media_type: z.enum(['image', 'video', 'document']),
  caption: z.string().max(500).optional(),
});

/**
 * POST /api/forum/posts — Create a new forum post
 */
forumRouter.post('/posts', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const parsed = createPostSchema.parse(req.body);

    const sanitized = sanitizeObject(parsed, ['title', 'content']);

    const postData = {
      ...sanitized,
      author_user_id: req.userId,
    };

    const { data, error } = await supabaseAdmin
      .from('forum_posts')
      .insert(postData)
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
 * GET /api/forum/posts — Get all forum posts (paginated)
 */
forumRouter.get('/posts', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = Math.min(parseInt(req.query.limit as string) || 20, 100);
    const offset = (page - 1) * limit;
    const postType = req.query.post_type as string;

    let query = supabaseAdmin
      .from('forum_posts')
      .select('*', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (postType) {
      query = query.eq('post_type', postType);
    }

    const { data, error, count } = await query;

    if (error) throw error;

    // Enrich posts with author data from persons table
    if (data && data.length > 0) {
      const authorIds = [...new Set(data.map(p => p.author_user_id))];
      const { data: authors } = await supabaseAdmin
        .from('persons')
        .select('auth_user_id, name, email, photo_url')
        .in('auth_user_id', authorIds);

      const authorsMap = new Map(authors?.map(a => [a.auth_user_id, a]) || []);
      
      const enrichedData = data.map(post => ({
        ...post,
        author: authorsMap.get(post.author_user_id) || { name: 'Unknown User', email: '' },
      }));

      res.json(paginatedResponse(enrichedData, count || 0, page, limit));
    } else {
      res.json(paginatedResponse(data || [], count || 0, page, limit));
    }
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * GET /api/forum/posts/:id — Get a single forum post
 */
forumRouter.get('/posts/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data, error } = await supabaseAdmin
      .from('forum_posts')
      .select(`
        *,
        media:forum_media(*),
        comments:forum_comments(*)
      `)
      .eq('id', req.params.id)
      .single();

    if (error || !data) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Post not found'));
      return;
    }

    // Enrich with author data from persons table
    const { data: author } = await supabaseAdmin
      .from('persons')
      .select('name, email, photo_url')
      .eq('auth_user_id', data.author_user_id)
      .single();

    const enrichedData = {
      ...data,
      author: author || { name: 'Unknown User', email: '' },
    };

    // Enrich comments with author data
    if (enrichedData.comments && enrichedData.comments.length > 0) {
      const authorIds = [...new Set(enrichedData.comments.map((c: any) => c.author_user_id))];
      const { data: commentAuthors } = await supabaseAdmin
        .from('persons')
        .select('auth_user_id, name, email, photo_url')
        .in('auth_user_id', authorIds);

      const authorsMap = new Map(commentAuthors?.map(a => [a.auth_user_id, a]) || []);
      
      enrichedData.comments = enrichedData.comments.map((comment: any) => ({
        ...comment,
        author: authorsMap.get(comment.author_user_id) || { name: 'Unknown User', email: '' },
      }));
    }

    res.json(successResponse(enrichedData));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * PUT /api/forum/posts/:id — Update a forum post
 */
forumRouter.put('/posts/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const parsed = updatePostSchema.parse(req.body);

    // Verify ownership
    const { data: existing } = await supabaseAdmin
      .from('forum_posts')
      .select('author_user_id')
      .eq('id', req.params.id)
      .single();

    if (!existing) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Post not found'));
      return;
    }

    if (existing.author_user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'You can only edit your own posts'));
      return;
    }

    const sanitized = sanitizeObject(parsed, ['title', 'content']);

    const { data, error } = await supabaseAdmin
      .from('forum_posts')
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
 * DELETE /api/forum/posts/:id — Delete a forum post
 */
forumRouter.delete('/posts/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data: existing } = await supabaseAdmin
      .from('forum_posts')
      .select('author_user_id, title')
      .eq('id', req.params.id)
      .single();

    if (!existing) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Post not found'));
      return;
    }

    if (existing.author_user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'You can only delete your own posts'));
      return;
    }

    const { error } = await supabaseAdmin
      .from('forum_posts')
      .delete()
      .eq('id', req.params.id);

    if (error) throw error;

    res.json(successResponse({ message: `Post '${existing.title}' deleted successfully` }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * POST /api/forum/posts/:id/media — Upload media to a post (max 5 for free users)
 */
forumRouter.post('/posts/:id/media', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const parsed = uploadMediaSchema.parse({ ...req.body, post_id: req.params.id });

    // Verify post ownership
    const { data: post } = await supabaseAdmin
      .from('forum_posts')
      .select('author_user_id')
      .eq('id', req.params.id)
      .single();

    if (!post) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Post not found'));
      return;
    }

    if (post.author_user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'You can only add media to your own posts'));
      return;
    }

    // Check media count limit (5 for free users)
    const { count } = await supabaseAdmin
      .from('forum_media')
      .select('*', { count: 'exact', head: true })
      .eq('post_id', req.params.id);

    if (count && count >= 5) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Maximum 5 media items allowed per post'));
      return;
    }

    const { data, error } = await supabaseAdmin
      .from('forum_media')
      .insert(parsed)
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
 * DELETE /api/forum/media/:id — Delete a media item
 */
forumRouter.delete('/media/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data: media } = await supabaseAdmin
      .from('forum_media')
      .select('post_id, forum_posts!inner(author_user_id)')
      .eq('id', req.params.id)
      .single();

    if (!media) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Media not found'));
      return;
    }

    // @ts-ignore - Supabase join syntax
    if (media.forum_posts.author_user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'You can only delete media from your own posts'));
      return;
    }

    const { error } = await supabaseAdmin
      .from('forum_media')
      .delete()
      .eq('id', req.params.id);

    if (error) throw error;

    res.json(successResponse({ message: 'Media deleted successfully' }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * POST /api/forum/comments — Create a comment on a post
 */
forumRouter.post('/comments', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const parsed = createCommentSchema.parse(req.body);

    const sanitized = sanitizeObject(parsed, ['content']);

    const commentData = {
      ...sanitized,
      author_user_id: req.userId,
    };

    const { data, error } = await supabaseAdmin
      .from('forum_comments')
      .insert(commentData)
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
 * DELETE /api/forum/comments/:id — Delete a comment
 */
forumRouter.delete('/comments/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { data: existing } = await supabaseAdmin
      .from('forum_comments')
      .select('author_user_id')
      .eq('id', req.params.id)
      .single();

    if (!existing) {
      res.status(404).json(errorResponse(ErrorCodes.NOT_FOUND, 'Comment not found'));
      return;
    }

    if (existing.author_user_id !== req.userId) {
      res.status(403).json(errorResponse(ErrorCodes.FORBIDDEN, 'You can only delete your own comments'));
      return;
    }

    const { error } = await supabaseAdmin
      .from('forum_comments')
      .delete()
      .eq('id', req.params.id);

    if (error) throw error;

    res.json(successResponse({ message: 'Comment deleted successfully' }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * POST /api/forum/likes — Toggle like on a post or comment
 */
forumRouter.post('/likes', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const schema = z.object({
      post_id: z.string().uuid().optional(),
      comment_id: z.string().uuid().optional(),
    }).refine(data => data.post_id || data.comment_id, {
      message: 'Either post_id or comment_id must be provided',
    });

    const parsed = schema.parse(req.body);

    // Check if like already exists
    let query = supabaseAdmin
      .from('forum_likes')
      .select('id')
      .eq('user_id', req.userId!);

    if (parsed.post_id) {
      query = query.eq('post_id', parsed.post_id);
    } else {
      query = query.eq('comment_id', parsed.comment_id!);
    }

    const { data: existing } = await query.single();

    if (existing) {
      // Unlike
      await supabaseAdmin
        .from('forum_likes')
        .delete()
        .eq('id', existing.id);

      res.json(successResponse({ liked: false, message: 'Like removed' }));
    } else {
      // Like
      const { data, error } = await supabaseAdmin
        .from('forum_likes')
        .insert({
          user_id: req.userId,
          post_id: parsed.post_id || null,
          comment_id: parsed.comment_id || null,
        })
        .select()
        .single();

      if (error) throw error;

      res.json(successResponse({ liked: true, data }));
    }
  } catch (err: any) {
    if (err instanceof z.ZodError) {
      res.status(400).json(errorResponse(ErrorCodes.VALIDATION_FAILED, 'Validation failed', err.errors));
      return;
    }
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});

/**
 * GET /api/forum/posts/:id/likes — Get like count for a post
 */
forumRouter.get('/posts/:id/likes', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { count } = await supabaseAdmin
      .from('forum_likes')
      .select('*', { count: 'exact', head: true })
      .eq('post_id', req.params.id);

    res.json(successResponse({ count: count || 0 }));
  } catch (err: any) {
    res.status(500).json(errorResponse(ErrorCodes.INTERNAL_ERROR, err.message));
  }
});
