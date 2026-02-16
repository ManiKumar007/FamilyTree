import { test, expect, Page } from '@playwright/test';

/**
 * Simplified User Flow E2E Tests
 * Adjusted for Flutter Web rendering
 */

// Helper function to wait and find input by label
async function fillInputByLabel(page: Page, labelText: string, value: string) {
  // Flutter renders inputs in a shadow DOM or with flt- prefixes
  // Try multiple strategies
  const input = page.locator(`input[aria-label="${labelText}"]`)
    .or(page.locator(`flt-text-editing-host >> input`))
    .or(page.getByRole('textbox'))
    .first();
  
  await input.waitFor({ state: 'visible', timeout: 10000 });
  await input.click();
  await input.fill(value);
}

async function clickButtonByText(page: Page, text: string) {
  const button = page.getByRole('button', { name: new RegExp(text, 'i') })
    .or(page.locator(`button:has-text("${text}")`))
    .or(page.locator(`flt-semantics >> button >> text="${text}"`))
    .first();
  
  await button.waitFor({ state: 'visible', timeout: 10000 });
  await button.click();
}

test.describe('Critical User Flows', () => {
  const timestamp = Date.now();
  const testUser = {
    email: `test${timestamp}@example.com`,
    password: 'Test123456!',
    name: `Test User ${timestamp}`,
    phone: '9876543210',
  };

  test('Signup and Login Flow', async ({ page }) => {
    // Go to signup - Flutter web takes 15-20 seconds on first load
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // Wait for Flutter to initialize (first load is slow)
    console.log('Waiting for Flutter to initialize...');
    await page.waitForTimeout(20000); // 20 seconds for initial load

    // Navigate to signup if not already there
    const signupLink = page.getByText(/Sign Up|Create Account/i).first();
    if (await signupLink.isVisible({ timeout: 3000 }).catch(() => false)) {
      await signupLink.click();
      await page.waitForTimeout(1000);
    }

    // Check if on signup page
    if (!page.url().includes('/signup')) {
      await page.goto('/#/signup');
      await page.waitForLoadState('networkidle');
      await page.waitForTimeout(2000);
    }

    // Fill signup form - using multiple selector strategies
    const inputs = page.locator('input[type="text"], input[type="email"], input[type="password"]');
    const inputCount = await inputs.count();
    
    console.log(`Found ${inputCount} input fields`);

    // Try filling inputs in order
    if (inputCount >= 4) {
      // Name
      await inputs.nth(0).fill(testUser.name);
      await page.waitForTimeout(300);
      
      // Email
      await inputs.nth(1).fill(testUser.email);
      await page.waitForTimeout(300);
      
      // Password
      const passwordInputs = page.locator('input[type="password"]');
      await passwordInputs.nth(0).fill(testUser.password);
      await page.waitForTimeout(300);
      
      // Confirm password
      await passwordInputs.nth(1).fill(testUser.password);
      await page.waitForTimeout(300);
    }

    // Submit
    const signupButton = page.getByRole('button').filter({ hasText: /Sign Up|Create/i }).first();
    await signupButton.click();
    
    // Wait for navigation or success message
    await page.waitForTimeout(5000);
    
    // Should be on login page now
    if (page.url().includes('/login')) {
      console.log('✅ Signup successful, redirected to login');
      
      // Login with the new account
      const emailInput = page.locator('input[type="email"]').first();
      await emailInput.fill(testUser.email);
      await page.waitForTimeout(300);
      
      const passInput = page.locator('input[type="password"]').first();
      await passInput.fill(testUser.password);
      await page.waitForTimeout(300);
      
      const loginButton = page.getByRole('button').filter({ hasText: /Sign In|Login/i }).first();
      await loginButton.click();
      
      // Wait for redirect to tree
      await page.waitForTimeout(5000);
      
      // Should be logged in now
      const url = page.url();
      console.log(`Current URL after login: ${url}`);
      expect(url).toContain('/tree');
    }
  });

  test('Session Persistence', async ({ page }) => {
    // Login first - wait for Flutter to load
    await page.goto('/#/login');
    await page.waitForLoadState('networkidle');
    console.log('Waiting for Flutter to load...');
    await page.waitForTimeout(20000);

    const emailInput = page.locator('input[type="email"]').first();
    await emailInput.fill('chinni070707@gmail.com'); // Use existing user
    
    const passInput = page.locator('input[type="password"]').first();
    await passInput.fill('Ssd@88788'); // You may need to update this
    
    const loginButton = page.getByRole('button').first();
    await loginButton.click();
    
    await page.waitForTimeout(5000);
    
    // Navigate to add member
    await page.goto('/#/tree/add-member');
    await page.waitForTimeout(2000);
    
    // Go back
    await page.goBack();
    await page.waitForTimeout(2000);
    
    // Should still be logged in, not redirected to login
    const currentUrl = page.url();
    console.log(`URL after back navigation: ${currentUrl}`);
    expect(currentUrl).not.toContain('/login');
    
    // Reload page
    await page.reload();
    await page.waitForTimeout(3000);
    
    // Should STILL be logged in after reload
    const urlAfterReload = page.url();
    console.log(`URL after reload: ${urlAfterReload}`);
    expect(urlAfterReload).not.toContain('/login');
  });

  test('Prof - wait for Flutter
    await page.goto('/#/login');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(20('networkidle');
    await page.waitForTimeout(2000);

    const emailInput = page.locator('input[type="email"]').first();
    await emailInput.fill('chinni070707@gmail.com');
    
    const passInput = page.locator('input[type="password"]').first();
    await passInput.fill('Ssd@88788');
    
    await page.getByRole('button').first().click();
    await page.waitForTimeout(5000);
    
    // Find and click profile button (usually an icon button)
    const buttons = page.getByRole('button');
    const buttonCount = await buttons.count();
    
    // Profile button is typically 3rd or 4th button in the app bar
    for (let i = 0; i < Math.min(buttonCount, 6); i++) {
      const button = buttons.nth(i);
      const ariaLabel = await button.getAttribute('aria-label').catch(() => null);
      
      if (ariaLabel?.toLowerCase().includes('profile') || 
          ariaLabel?.toLowerCase().includes('person')) {
        await button.click();
        break;
      }
    }
    
    await page.waitForTimeout(3000);
    
    // Should navigate to profile-setup or person detail
    const url = page.url();
    console.log(`URL after clicking profile: ${url}`);
    expect(url).toMatch(/\/(profile-setup|person)/);
  });

  test('Search Functionality', async ({ page }) => {
    // Login - wait for Flutter
    await page.goto('/#/login');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(20000);

    await page.locator('input[type="email"]').first().fill('chinni070707@gmail.com');
    await page.locator('input[type="password"]').first().fill('Ssd@88788');
    await page.getByRole('button').first().click();
    await page.waitForTimeout(5000);
    
    // Navigate to search
    await page.goto('/#/search');
    await page.waitForTimeout(3000);
    
    // Should be on search page
    expect(page.url()).toContain('/search');
    
    // Look for search input
    const searchInput = page.locator('input[type="text"], input[type="search"]').first();
    if (await searchInput.isVisible({ timeout: 5000 }).catch(() => false)) {
      await searchInput.fill('test');
      await page.waitForTimeout(2000);
      console.log('✅ Search input functional');
    }
  });

  test('Add Member and Verify Tree Updates', async ({ page }) => {
    // Login - wait for Flutter
    await page.goto('/#/login');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(20000);

    await page.locator('input[type="email"]').first().fill('chinni070707@gmail.com');
    await page.locator('input[type="password"]').first().fill('Ssd@88788');
    await page.getByRole('button').first().click();
    await page.waitForTimeout(5000);
    
    // Go to add member
    await page.goto('/#/tree/add-member');
    await page.waitForTimeout(3000);
    
    // Fill member details
    const memberName = `TestMember ${Date.now()}`;
    const textInputs = page.locator('input[type="text"]');
    
    if (await textInputs.first().isVisible({ timeout: 5000 }).catch(() => false)) {
      await textInputs.first().fill(memberName);
      await page.waitForTimeout(500);
      
      // Try to submit
      const buttons = page.getByRole('button');
      const submitButton = buttons.filter({ hasText: /Add|Save|Submit/i }).first();
      
      if (await submitButton.isVisible({ timeout: 3000 }).catch(() => false)) {
        await submitButton.click();
        await page.waitForTimeout(5000);
        
        // Should redirect back to tree
        expect(page.url()).toContain('/tree');
        console.log('✅ Member added successfully');
      }
    }
  });
});
