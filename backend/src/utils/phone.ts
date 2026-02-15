/**
 * Phone number normalization utilities.
 * Normalizes Indian phone numbers to E.164 format: +91XXXXXXXXXX
 */

/**
 * Normalize an Indian phone number to E.164 format.
 * Handles: +91XXXXXXXXXX, 91XXXXXXXXXX, 0XXXXXXXXXX, XXXXXXXXXX
 */
export function normalizePhone(phone: string): string {
  // Remove all non-digit characters except leading +
  let cleaned = phone.replace(/[^\d+]/g, '');

  // Remove leading + for processing
  const hasPlus = cleaned.startsWith('+');
  if (hasPlus) cleaned = cleaned.substring(1);

  // Handle different formats
  if (cleaned.length === 10) {
    // Just the 10-digit number
    return `+91${cleaned}`;
  } else if (cleaned.length === 11 && cleaned.startsWith('0')) {
    // 0XXXXXXXXXX format
    return `+91${cleaned.substring(1)}`;
  } else if (cleaned.length === 12 && cleaned.startsWith('91')) {
    // 91XXXXXXXXXX format
    return `+${cleaned}`;
  } else if (cleaned.length === 12 && hasPlus) {
    // Already +91XXXXXXXXXX
    return `+${cleaned}`;
  }

  // Return as-is with + prefix for non-Indian numbers
  return hasPlus ? `+${cleaned}` : `+${cleaned}`;
}

/**
 * Validate that a phone number is a valid E.164 format
 */
export function isValidPhone(phone: string): boolean {
  return /^\+[1-9]\d{6,14}$/.test(phone);
}
