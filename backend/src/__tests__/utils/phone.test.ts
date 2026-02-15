import { normalizePhone, isValidPhone } from '../../utils/phone';

describe('Phone Utilities', () => {
  describe('normalizePhone', () => {
    it('should add +91 prefix for 10-digit numbers', () => {
      expect(normalizePhone('9876543210')).toBe('+919876543210');
    });

    it('should preserve existing country code', () => {
      expect(normalizePhone('+919876543210')).toBe('+919876543210');
    });

    it('should handle numbers with spaces', () => {
      expect(normalizePhone('98765 43210')).toBe('+919876543210');
    });

    it('should handle numbers with dashes', () => {
      expect(normalizePhone('98765-43210')).toBe('+919876543210');
    });

    it('should remove parentheses', () => {
      expect(normalizePhone('(987) 654-3210')).toBe('+919876543210');
    });

    it('should handle international format with 0', () => {
      expect(normalizePhone('09876543210')).toBe('+919876543210');
    });
  });

  describe('isValidPhone', () => {
    it('should validate correct Indian phone numbers', () => {
      expect(isValidPhone('+919876543210')).toBe(true);
    });

    it('should reject too short numbers', () => {
      expect(isValidPhone('+9198765')).toBe(false);
    });

    it('should reject too long numbers', () => {
      expect(isValidPhone('+91987654321012345')).toBe(false);
    });

    it('should reject numbers without +', () => {
      expect(isValidPhone('919876543210')).toBe(false);
    });

    it('should reject empty strings', () => {
      expect(isValidPhone('')).toBe(false);
    });

    it('should accept various country codes', () => {
      expect(isValidPhone('+14155551234')).toBe(true); // US
      expect(isValidPhone('+447911123456')).toBe(true); // UK
    });
  });
});
