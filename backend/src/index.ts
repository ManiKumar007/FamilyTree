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

const app = express();

// Security
app.use(helmet());
app.use(cors({
  origin: env.APP_URL,
  credentials: true,
}));

// Rate limiting
app.use(rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
}));

// Body parsing
app.use(express.json({ limit: '10mb' }));

// Health check
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Routes
app.use('/api/persons', personsRouter);
app.use('/api/relationships', relationshipsRouter);
app.use('/api/tree', treeRouter);
app.use('/api/search', searchRouter);
app.use('/api/merge', mergeRouter);
app.use('/api/invite', inviteRouter);

// Error handler (must be last)
app.use(errorHandler);

app.listen(env.PORT, () => {
  console.log(`🚀 MyFamilyTree API running on port ${env.PORT}`);
});

export default app;
