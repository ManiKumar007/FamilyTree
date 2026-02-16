import { test, expect } from '@playwright/test';

test.describe('Debug', () => {
  test('check what renders on /signup', async ({ page }) => {
    await page.goto('/signup', { waitUntil: 'networkidle' });
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(3000); // Wait extra time

    // Get the page content
    const content = await page.content();
    console.log('=== PAGE HTML ===');
    console.log(content);
    console.log('=== END HTML ===');

    // Get the URL
    const url = page.url();
    console.log('Current URL:', url);

    // Try to find  any visible text
    const bodyText = await page.locator('body').textContent();
    console.log('=== PAGE TEXT ===');
    console.log(bodyText);
    console.log('=== END TEXT ===');

    // Check for presence of specific elements
    const hasCreateAccount = await page.locator('text=Create Account').count();
    const hasSignUp = await page.locator('text=Sign Up').count();
    const hasEmail = await page.locator('input[type="email"]').count();
    
    console.log('Create Account count:', hasCreateAccount);
    console.log('Sign Up count:', hasSignUp);
    console.log('Email input count:', hasEmail);
  });

  test('check what renders on /login', async ({ page }) => {
    await page.goto('/login', { waitUntil: 'networkidle' });
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(3000); // Wait extra time

    // Get the URL
    const url = page.url();
    console.log('Current URL:', url);

    // Try to find any visible text
    const bodyText = await page.locator('body').textContent();
    console.log('=== PAGE TEXT ===');
    console.log(bodyText);
    console.log('=== END TEXT ===');

    // Check for presence of specific elements
    const hasSignIn = await page.locator('text=Sign In').count();
    const hasEmail = await page.locator('input[type="email"]').count();
    const hasPassword = await page.locator('input[type="password"]').count();
    
    console.log('Sign In count:', hasSignIn);
    console.log('Email input count:', hasEmail);
    console.log('Password input count:', hasPassword);
  });

  test('check what renders on /landing', async ({ page }) => {
    await page.goto('/landing', { waitUntil: 'networkidle' });
    await page.waitForLoadState('domcontentloaded');
    await page.waitForTimeout(3000); // Wait extra time

    // Get the URL
    const url = page.url();
    console.log('Current URL:', url);

    // Try to find any visible text
    const bodyText = await page.locator('body').textContent();
    console.log('=== PAGE TEXT (first 500 chars) ===');
    console.log(bodyText?.substring(0, 500));
    console.log('=== END TEXT ===');
  });
});
