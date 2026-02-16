/**
 * Structured logging configuration using a lightweight approach.
 * Outputs JSON in production for log aggregation tools,
 * and human-readable format in development.
 */

import { env } from './env';

type LogLevel = 'debug' | 'info' | 'warn' | 'error' | 'fatal';

interface LogEntry {
  level: LogLevel;
  timestamp: string;
  message: string;
  [key: string]: any;
}

function formatLog(level: LogLevel, message: string, meta?: Record<string, any>): LogEntry {
  return {
    level,
    timestamp: new Date().toISOString(),
    message,
    ...(meta || {}),
  };
}

function writeLog(entry: LogEntry): void {
  const output = env.NODE_ENV === 'production'
    ? JSON.stringify(entry)
    : `[${entry.timestamp}] ${entry.level.toUpperCase()}: ${entry.message}${
        Object.keys(entry).length > 3
          ? ' ' + JSON.stringify(
              Object.fromEntries(
                Object.entries(entry).filter(([k]) => !['level', 'timestamp', 'message'].includes(k))
              )
            )
          : ''
      }`;

  switch (entry.level) {
    case 'error':
    case 'fatal':
      console.error(output);
      break;
    case 'warn':
      console.warn(output);
      break;
    default:
      console.log(output);
  }
}

export const logger = {
  debug(message: string, meta?: Record<string, any>) {
    if (env.NODE_ENV !== 'production') {
      writeLog(formatLog('debug', message, meta));
    }
  },

  info(message: string, meta?: Record<string, any>) {
    writeLog(formatLog('info', message, meta));
  },

  warn(message: string, meta?: Record<string, any>) {
    writeLog(formatLog('warn', message, meta));
  },

  error(message: string, meta?: Record<string, any>) {
    writeLog(formatLog('error', message, meta));
  },

  fatal(message: string, meta?: Record<string, any>) {
    writeLog(formatLog('fatal', message, meta));
  },

  /**
   * Create a child logger with preset context (e.g., requestId).
   */
  child(context: Record<string, any>) {
    return {
      debug: (msg: string, meta?: Record<string, any>) =>
        logger.debug(msg, { ...context, ...meta }),
      info: (msg: string, meta?: Record<string, any>) =>
        logger.info(msg, { ...context, ...meta }),
      warn: (msg: string, meta?: Record<string, any>) =>
        logger.warn(msg, { ...context, ...meta }),
      error: (msg: string, meta?: Record<string, any>) =>
        logger.error(msg, { ...context, ...meta }),
      fatal: (msg: string, meta?: Record<string, any>) =>
        logger.fatal(msg, { ...context, ...meta }),
    };
  },
};

/**
 * Express middleware to log incoming requests.
 */
export function requestLogger(req: any, res: any, next: any) {
  const start = Date.now();
  const requestId = `req_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

  // Attach requestId to request for use in downstream logging
  req.requestId = requestId;

  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info('HTTP Request', {
      requestId,
      method: req.method,
      url: req.originalUrl,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      userAgent: req.headers['user-agent'],
      ip: req.ip,
    });
  });

  next();
}
