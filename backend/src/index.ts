import dotenv from 'dotenv';
dotenv.config();

import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { rateLimit } from 'express-rate-limit';
import { env } from './config/env';
import { errorHandler } from './middleware/errorHandler';
import { personsRouter } from './routes/persons';
import { relationshipsRouter } from './routes/relationships';
import { treeRouter } from './routes/tree';
import { searchRouter } from './routes/search';
import { mergeRouter } from './routes/merge';
import { inviteRouter } from './routes/invite';
import adminRouter from './routes/admin';
import { logger, requestLogger } from './config/logger';

const app = express();

// Security
app.use(helmet());
app.use(cors({
  origin: env.NODE_ENV === 'production' ? env.APP_URL : true, // Allow all origins in development
  credentials: true,
}));

// Rate limiting — per-route-category limits
const defaultLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300, // Read-heavy endpoints
  standardHeaders: true,
  legacyHeaders: false,
});

const writeLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 50, // Write endpoints
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many write requests. Please try again later.' },
});

const searchLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30, // Search is expensive (graph traversal)
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many search requests. Please try again later.' },
});

const adminLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
});

// Apply default rate limit globally
app.use(defaultLimiter);

// Body parsing
app.use(express.json({ limit: '10mb' }));

// Structured request logging
app.use(requestLogger);

// Health check
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Routes with per-category rate limiting
app.use('/api/persons', personsRouter);           // Uses default (300/15min) for reads; POST/PUT are low volume
app.use('/api/relationships', relationshipsRouter);
app.use('/api/tree', treeRouter);
app.use('/api/search', searchLimiter, searchRouter);   // Search is expensive — 30/15min
app.use('/api/merge', writeLimiter, mergeRouter);      // Merge writes — 50/15min
app.use('/api/invite', writeLimiter, inviteRouter);    // Invite generation — 50/15min
app.use('/api/admin', adminLimiter, adminRouter);      // Admin — 200/15min

// Error handler (must be last)
app.use(errorHandler);

app.listen(env.PORT, () => {
  logger.info(`MyFamilyTree API running on port ${env.PORT}`, { env: env.NODE_ENV });
  if (env.AUTH_BYPASS) {
    logger.warn('AUTH_BYPASS is enabled. Authentication is disabled for development.');
  }
});

export default app;
