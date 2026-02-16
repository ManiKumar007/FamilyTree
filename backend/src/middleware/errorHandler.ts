import { Request, Response, NextFunction } from 'express';
import { errorLogger } from '../services/errorLogger';
import { logger } from '../config/logger';
import { errorResponse, ErrorCodes } from '../utils/response';

export function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  _next: NextFunction
): void {
  const statusCode = (err as any).statusCode || 500;
  const message = process.env.NODE_ENV === 'production'
    ? 'Internal server error'
    : err.message;

  logger.error('Unhandled error', {
    error: err.message,
    statusCode,
    method: req.method,
    url: req.originalUrl,
    requestId: (req as any).requestId,
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack }),
  });

  // Log the error to database (async, fire-and-forget)
  errorLogger.logExpressError(err, req).catch(logErr => {
    logger.error('Failed to log error to database', { error: logErr.message });
  });

  res.status(statusCode).json(
    errorResponse(ErrorCodes.INTERNAL_ERROR, message)
  );
}

/**
 * Helper to create errors with status codes
 */
export class AppError extends Error {
  statusCode: number;

  constructor(message: string, statusCode: number = 400) {
    super(message);
    this.statusCode = statusCode;
    this.name = 'AppError';
  }
}
