import { supabaseAdmin } from '../config/supabase';
import { Request } from 'express';

export type ErrorSeverity = 'debug' | 'info' | 'warn' | 'error' | 'critical';
export type ErrorType = 'api_error' | 'validation' | 'database' | 'auth' | 'client' | 'system';

interface ErrorLogData {
  errorType: ErrorType;
  severity?: ErrorSeverity;
  statusCode?: number;
  message: string;
  stackTrace?: string;
  requestUrl?: string;
  requestMethod?: string;
  userId?: string;
  ipAddress?: string;
  userAgent?: string;
  additionalData?: Record<string, any>;
}

/**
 * Service for logging errors to the database and console.
 * Provides centralized error tracking for the admin panel.
 */
class ErrorLogger {
  /**
   * Log an error to the database
   */
  async logError(data: ErrorLogData): Promise<void> {
    try {
      // Sanitize sensitive data from stack trace
      const sanitizedStackTrace = this.sanitizeStackTrace(data.stackTrace);
      
      // Prepare error log entry
      const errorLog = {
        error_type: data.errorType,
        severity: data.severity || 'error',
        status_code: data.statusCode,
        message: this.sanitizeMessage(data.message),
        stack_trace: sanitizedStackTrace,
        request_url: data.requestUrl,
        request_method: data.requestMethod,
        user_id: data.userId || null,
        ip_address: data.ipAddress || null,
        user_agent: data.userAgent,
        additional_data: data.additionalData || {},
      };

      // Insert into database
      const { error } = await supabaseAdmin
        .from('error_logs')
        .insert(errorLog);

      if (error) {
        // Don't throw - we don't want error logging to crash the app
        console.error('Failed to log error to database:', error);
      }
    } catch (err) {
      // Silently fail - error logging should never crash the app
      console.error('Error in error logger:', err);
    }
  }

  /**
   * Log error from Express error handler
   */
  async logExpressError(
    err: Error,
    req: Request,
    statusCode: number = 500
  ): Promise<void> {
    const errorType: ErrorType = this.determineErrorType(err, statusCode);
    const severity: ErrorSeverity = this.determineSeverity(statusCode);

    await this.logError({
      errorType,
      severity,
      statusCode,
      message: err.message,
      stackTrace: err.stack,
      requestUrl: req.originalUrl || req.url,
      requestMethod: req.method,
      userId: (req as any).userId,
      ipAddress: this.getClientIp(req),
      userAgent: req.get('user-agent'),
      additionalData: {
        body: this.sanitizeRequestBody(req.body),
        query: req.query,
        params: req.params,
      },
    });
  }

  /**
   * Log a validation error
   */
  async logValidationError(
    message: string,
    req: Request,
    errors?: any
  ): Promise<void> {
    await this.logError({
      errorType: 'validation',
      severity: 'warn',
      statusCode: 400,
      message,
      requestUrl: req.originalUrl || req.url,
      requestMethod: req.method,
      userId: (req as any).userId,
      ipAddress: this.getClientIp(req),
      userAgent: req.get('user-agent'),
      additionalData: { errors },
    });
  }

  /**
   * Log a database error
   */
  async logDatabaseError(
    message: string,
    error: any,
    userId?: string
  ): Promise<void> {
    await this.logError({
      errorType: 'database',
      severity: 'error',
      message,
      stackTrace: error?.stack,
      userId,
      additionalData: {
        code: error?.code,
        details: error?.details,
        hint: error?.hint,
      },
    });
  }

  /**
   * Log an authentication error
   */
  async logAuthError(
    message: string,
    req: Request,
    details?: any
  ): Promise<void> {
    await this.logError({
      errorType: 'auth',
      severity: 'warn',
      statusCode: 401,
      message,
      requestUrl: req.originalUrl || req.url,
      requestMethod: req.method,
      ipAddress: this.getClientIp(req),
      userAgent: req.get('user-agent'),
      additionalData: details,
    });
  }

  /**
   * Determine error type based on error and status code
   */
  private determineErrorType(err: Error, statusCode: number): ErrorType {
    const message = err.message.toLowerCase();
    
    if (statusCode === 401 || statusCode === 403 || message.includes('auth')) {
      return 'auth';
    }
    if (statusCode === 400 || message.includes('validation')) {
      return 'validation';
    }
    if (message.includes('database') || message.includes('sql') || message.includes('postgres')) {
      return 'database';
    }
    if (statusCode >= 400 && statusCode < 500) {
      return 'client';
    }
    return 'api_error';
  }

  /**
   * Determine severity based on status code
   */
  private determineSeverity(statusCode: number): ErrorSeverity {
    if (statusCode >= 500) return 'critical';
    if (statusCode >= 400) return 'error';
    if (statusCode >= 300) return 'warn';
    return 'info';
  }

  /**
   * Get client IP address from request
   */
  private getClientIp(req: Request): string | undefined {
    const forwarded = req.headers['x-forwarded-for'];
    if (typeof forwarded === 'string') {
      return forwarded.split(',')[0].trim();
    }
    return req.socket.remoteAddress;
  }

  /**
   * Sanitize stack trace to remove sensitive information
   */
  private sanitizeStackTrace(stackTrace?: string): string | undefined {
    if (!stackTrace) return undefined;
    
    // Remove environment variables, file paths with sensitive data
    return stackTrace
      .replace(/password[^,\s}]*/gi, 'password=***')
      .replace(/token[^,\s}]*/gi, 'token=***')
      .replace(/key[^,\s}]*/gi, 'key=***')
      .replace(/secret[^,\s}]*/gi, 'secret=***');
  }

  /**
   * Sanitize error message
   */
  private sanitizeMessage(message: string): string {
    return message
      .replace(/password[^,\s}]*/gi, 'password=***')
      .replace(/token[^,\s}]*/gi, 'token=***')
      .replace(/key[^,\s}]*/gi, 'key=***')
      .replace(/secret[^,\s}]*/gi, 'secret=***');
  }

  /**
   * Sanitize request body
   */
  private sanitizeRequestBody(body: any): any {
    if (!body || typeof body !== 'object') return body;

    const sanitized = { ...body };
    const sensitiveFields = ['password', 'token', 'secret', 'key', 'apiKey', 'api_key'];
    
    for (const field of sensitiveFields) {
      if (field in sanitized) {
        sanitized[field] = '***';
      }
    }

    return sanitized;
  }
}

// Export singleton instance
export const errorLogger = new ErrorLogger();
