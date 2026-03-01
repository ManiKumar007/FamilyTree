/**
 * XSS sanitization utility.
 * Uses a robust multi-pass approach to strip dangerous HTML/script content.
 *
 * For richer HTML contexts (user-generated formatted content), consider
 * adding the `xss` or `sanitize-html` npm package.
 */

/**
 * Strip HTML tags and common XSS attack vectors from a string.
 * Multi-pass to handle nested/encoded payloads.
 */
export function sanitizeString(input: string): string {
  let sanitized = input;

  // Decode HTML entities that could hide payloads
  sanitized = sanitized
    .replace(/&lt;/gi, '<')
    .replace(/&gt;/gi, '>')
    .replace(/&amp;/gi, '&')
    .replace(/&quot;/gi, '"')
    .replace(/&#x27;/gi, "'")
    .replace(/&#x2F;/gi, '/');

  // Multi-pass tag removal (handles nested tags like <<script>script>)
  let previous = '';
  while (previous !== sanitized) {
    previous = sanitized;
    // Remove HTML tags
    sanitized = sanitized.replace(/<[^>]*>/g, '');
  }

  sanitized = sanitized
    // Remove javascript: protocol (with possible whitespace/encoding tricks)
    .replace(/j\s*a\s*v\s*a\s*s\s*c\s*r\s*i\s*p\s*t\s*:/gi, '')
    // Remove vbscript: protocol
    .replace(/v\s*b\s*s\s*c\s*r\s*i\s*p\s*t\s*:/gi, '')
    // Remove on* event handlers (e.g. onerror=, onclick=)
    .replace(/\bon\w+\s*=/gi, '')
    // Remove data: URIs (can contain scripts)
    .replace(/data\s*:[^,]*,/gi, '')
    // Remove expression() CSS (IE)
    .replace(/expression\s*\(/gi, '')
    // Remove url() CSS with javascript
    .replace(/url\s*\(\s*['"]?\s*javascript/gi, '')
    // Trim whitespace
    .trim();

  return sanitized;
}

/**
 * Sanitize all string fields in an object (shallow, one level deep).
 * Non-string fields and null/undefined values are left unchanged.
 */
export function sanitizeObject<T extends Record<string, any>>(
  obj: T,
  fieldsToSanitize: (keyof T)[]
): T {
  const sanitized = { ...obj };
  for (const field of fieldsToSanitize) {
    const value = sanitized[field];
    if (typeof value === 'string') {
      (sanitized as any)[field] = sanitizeString(value);
    }
  }
  return sanitized;
}

/**
 * Fields in the Person model that should be sanitized.
 */
export const PERSON_SANITIZE_FIELDS = [
  'name',
  'given_name',
  'surname',
  'occupation',
  'community',
  'city',
  'state',
  'email',
  'place_of_death',
  'nakshatra',
  'rashi',
  'native_place',
  'ancestral_village',
  'sub_caste',
  'kula_devata',
  'pravara',
  'gotra',
] as const;
