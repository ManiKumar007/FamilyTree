import { test, expect } from '@playwright/test';

/**
 * Authentication E2E Tests
 * Tests for signup and login functionality with email/password
 */

test.describe('Authentication', () => {
  // Generate unique test user credentials
  const timestamp = Date.now();
  const testEmail = `test${timestamp}@example.com`;
  const testPassword = 'TestPassword123!';
  const testName = `Test User ${timestamp}`;

  test.beforeEach(async ({ page }) => {
    // Navigate to landing page and wait for it to load
    await page.goto('/#/landing', { waitUntil: 'networkidle' });
  });

  test('should sign up with email and password', async ({ page }) => {
    // Navigate to signup page
    await page.goto('/#/signup', { waitUntil: 'networkidle' });
    await page.waitForLoadState('domcontentloaded');

    // Wait for signup form to load
    await expect(page.locator('text=Create Account')).toBeVisible({ timeout: 10000 });

    // Fill in signup form
    await page.fill('input[type="text"]', testName);
    await page.fill('input[type="email"]', testEmail);
    
    // Fill password fields
    const passwordFields = page.locator('input[type="password"]');
    await passwordFields.nth(0).fill(testPassword);
    await passwordFields.nth(1).fill(testPassword);

    // Submit the form
    await page.click('button:has-text("Sign Up")');

    // Wait for success message or redirect
    // Since Supabase may require email verification, we check for the success message
    await page.waitForSelector('text=/Account created|check your email/i', { timeout: 10000 });
    
    // Verify we're redirected to login page
    await expect(page).toHaveURL(/\/#\/login/);
  });

  test('should show error for duplicate email', async ({ page }) => {
    // Try to sign up with the same email again
    await page.goto('/#/signup', { waitUntil: 'networkidle' });
    await page.waitForLoadState('domcontentloaded');
    
    await page.fill('input[type="text"]', testName);
    await page.fill('input[type="email"]', testEmail);
    
    const passwordFields = page.locator('input[type="password"]');
    await passwordFields.nth(0).fill(testPassword);
    await passwordFields.nth(1).fill(testPassword);

    await page.click('button:has-text("Sign Up")');

    // Should show error message
    await expect(page.locator('text=/already registered|already exists/i')).toBeVisible({ timeout: 5000 });
  });

  test('should show validation errors for invalid signup data', async ({ page }) => {
    await page.goto('/#/signup', { waitUntil: 'networkidle' });
    await page.waitForLoadState('domcontentloaded');

    // Try to submit without filling anything
    await page.click('button:has-text("Sign Up")');

    // Should show validation errors
    await expect(page.locator('text=/Please enter your name/i')).toBeVisible();
    await expect(page.locator('text=/Please enter your email/i')).toBeVisible();
  });

  test('should show error for password mismatch', async ({ page }) => {
    await page.goto('/#/signup', { waitUntil: 'networkidle' });
    await page.waitForLoadState('domcontentloaded');

    await page.fill('input[type="text"]', testName);
    await page.fill('input[type="email"]', `test${Date.now()}@example.com`);
    
    const passwordFields = page.locator('input[type="password"]');
    await passwordFields.nth(0).fill(testPassword);
    await passwordFields.nth(1).fill('DifferentPassword123!');

    await page.click('button:has-text("Sign Up")');

    // Should show password mismatch error
    await expect(page.locator('text=/Passwords do not match/i')).toBeVisible();
  });

  test('should login with valid credentials', async ({ page }) => {
    // Note: This test assumes the user from the first test exists
    // In a real scenario, you'd want to ensure the user is verified first
    await page.goto('/#/login', { waitUntil: 'networkidle' });
    await page.waitForLoadState('domcontentloaded');

    // Wait for login form
    await expect(page.locator('text=Sign In')).toBeVisible({ timeout: 10000 });

    // Fill in login credentials
    await page.fill('input[type="email"]', testEmail);
    await page.fill('input[type="password"]', testPassword);

    // Click sign in
    await page.click('button:has-text("Sign In")');

    // Should redirect to tree view
    await page.waitForURL(/\/#\/tree/, { timeout: 10000 });
    await expect(page).toHaveURL(/\/#\/tree/);
  });

  test('should show error for invalid credentials', async ({ page }) => {
    await page.goto('/#/login', { waitUntil: 'networkidle' });
    await page.waitForLoadState('domcontentloaded');

    await page.fill('input[type="email"]', 'wrong@example.com');
    await page.fill('input[type="password"]', 'wrongpassword');

    await page.click('button:has-text("Sign In")');

    // Should show error message
    await expect(page.locator('text=/Invalid|incorrect|wrong/i')).toBeVisible({ timeout: 5000 });
  });

  test('should show validation errors for empty login form', async ({ page }) => {
    await page.goto('/#/login', { waitUntil: 'networkidle' });
    await page.waitForLoadState('domcontentloaded');

    // Try to submit without filling anything
    await page.click('button:has-text("Sign In")');

    // Should show validation errors
    await expect(page.locator('text=/Please enter your email/i')).toBeVisible();
    await expect(page.locator('text=/Please enter your password/i')).toBeVisible();
  });

  test('should navigate between login and signup screens', async ({ page }) => {
    await page.goto('/#/login', { waitUntil: 'networkidle' });
    await page.waitForLoadState('domcontentloaded');

    // Click "Sign Up" link
    await page.click('text=/Sign Up/i');
    await expect(page).toHaveURL(/\/#\/signup/);
    await expect(page.locator('text=Create Account')).toBeVisible();

    // Click "Sign In" link
    await page.click('text=/Sign In/i');
    await expect(page).toHaveURL(/\/#\/login/);
    await expect(page.locator('text=Welcome back')).toBeVisible();
  });

  test('should toggle password visibility', async ({ page }) => {
    await page.goto('/#/login', { waitUntil: 'networkidle' });
    await page.waitForLoadState('domcontentloaded');

    const passwordInput = page.locator('input[type="password"]');
    const toggleButton = page.locator('button:has(svg)').filter({ hasText: '' }).first();

    // Initially password should be hidden
    await expect(passwordInput).toHaveAttribute('type', 'password');

    // Click toggle button
    await toggleButton.click();

    // Password should be visible (type="text")
    await expect(page.locator('input[type="text"]').last()).toBeVisible();

    // Click again to hide
    await toggleButton.click();
    await expect(passwordInput).toHaveAttribute('type', 'password');
  });
});
