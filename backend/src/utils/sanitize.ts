/**
 * XSS sanitization utility.
 * Strips potentially dangerous HTML/script content from user-provided text fields.
 *
 * Uses a simple regex-based approach to avoid adding a heavy dependency.
 * For more comprehensive sanitization, consider the `xss` or `sanitize-html` npm package.
 */

/**
 * Strip HTML tags and common XSS attack vectors from a string.
 */
export function sanitizeString(input: string): string {
  return input
    // Remove HTML tags
    .replace(/<[^>]*>/g, '')
    // Remove javascript: protocol
    .replace(/javascript\s*:/gi, '')
    // Remove on* event handlers
    .replace(/\bon\w+\s*=/gi, '')
    // Remove data: URIs (can contain scripts)
    .replace(/data\s*:[^,]*,/gi, '')
    // Trim whitespace
    .trim();
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
] as const;
