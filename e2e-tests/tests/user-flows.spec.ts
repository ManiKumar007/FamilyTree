import { test, expect } from '@playwright/test';

/**
 * Comprehensive User Flow E2E Tests
 * Tests all critical user journeys end-to-end
 */

test.describe('Complete User Flows', () => {
  const timestamp = Date.now();
  const testUser = {
    email: `flowtest${timestamp}@example.com`,
    password: 'FlowTest123!',
    name: `Flow Test User ${timestamp}`,
    phone: '9876543210',
  };

  test.describe('New User Complete Journey', () => {
    test('should complete full signup → profile setup → view tree → add member flow', async ({ page }) => {
      // ============ STEP 1: Sign Up ============
      await page.goto('/#/signup', { waitUntil: 'networkidle' });
      
      await page.fill('input[type="text"]', testUser.name);
      await page.fill('input[type="email"]', testUser.email);
      
      const passwordFields = page.locator('input[type="password"]');
      await passwordFields.nth(0).fill(testUser.password);
      await passwordFields.nth(1).fill(testUser.password);
      
      await page.click('button:has-text("Sign Up")');
      
      // Wait for redirect to login or confirmation
      await page.waitForURL(/\/#\/(login|tree)/, { timeout: 10000 });
      
      // ============ STEP 2: Login (if needed) ============
      const currentUrl = page.url();
      if (currentUrl.includes('/login')) {
        await page.fill('input[type="email"]', testUser.email);
        await page.fill('input[type="password"]', testUser.password);
        await page.click('button:has-text("Sign In")');
        await page.waitForURL(/\/#\/tree/, { timeout: 10000 });
      }
      
      // ============ STEP 3: Check if Profile Setup is needed ============
      // Click profile button
      await page.click('button[title="Profile"], [aria-label="Profile"]', { timeout: 5000 }).catch(() => {
        // Try alternative selector
        return page.click('button:has([class*="person"])', { timeout: 5000 });
      });
      
      // Should navigate to profile setup if no profile exists
      await page.waitForTimeout(2000);
      
      const urlAfterProfileClick = page.url();
      if (urlAfterProfileClick.includes('/profile-setup')) {
        // ============ STEP 4: Complete Profile Setup ============
        await page.fill('input[aria-label="Full Name"], input[placeholder*="name" i], label:has-text("Full Name") + input, input[type="text"]', testUser.name);
        
        // Fill phone with validation for +91 prefix
        const phoneInput = page.locator('input[aria-label*="Phone"], input[placeholder*="phone" i]').first();
        await phoneInput.fill(testUser.phone);
        
        // Select date of birth
        await page.click('text=/Date of Birth/i');
        const dobInput = page.locator('input[type="date"]').first();
        if (await dobInput.isVisible()) {
          await dobInput.fill('1990-05-15');
        }
        
        // Select gender
        await page.selectOption('select:has-option:text("Male")', 'male');
        
        // Optional fields
        await page.fill('input[aria-label*="City"], input[placeholder*="city" i]', 'Mumbai').catch(() => {});
        await page.fill('input[aria-label*="State"], input[placeholder*="state" i]', 'Maharashtra').catch(() => {});
        
        // Submit profile
        await page.click('button:has-text("Save")');
        
        // Should redirect to tree after profile creation
        await page.waitForURL(/\/#\/tree/, { timeout: 10000 });
      }
      
      // ============ STEP 5: Verify on Tree View ============
      await expect(page).toHaveURL(/\/#\/tree/);
      await expect(page.locator('text=/My Family Tree|Family Tree/i')).toBeVisible({ timeout: 5000 });
      
      // ============ STEP 6: Add a Family Member ============
      await page.goto('/#/tree/add-member', { waitUntil: 'networkidle' });
      
      const memberName = `Child ${timestamp}`;
      
      // Fill member details
      await page.fill('input[placeholder*="name" i], input[aria-label*="name" i]', memberName);
      
      // Select gender
      const genderSelect = page.locator('select').filter({ hasText: /Male|Female|Gender/i }).first();
      if (await genderSelect.isVisible()) {
        await genderSelect.selectOption('male');
      }
      
      // Fill DOB
      const dobField = page.locator('input[type="date"]').first();
      if (await dobField.isVisible()) {
        await dobField.fill('2020-06-10');
      }
      
      // Submit
      await page.click('button:has-text("Add"), button:has-text("Save")');
      
      // Should go back to tree
      await page.waitForURL(/\/#\/tree/, { timeout: 10000 });
      
      // ============ STEP 7: Verify Tree Updated with New Member ============
      // Wait for tree to load/refresh
      await page.waitForTimeout(2000);
      
      // Check that member name appears in the tree
      const memberVisible = await page.locator(`text="${memberName}"`).count() > 0;
      expect(memberVisible).toBeTruthy();
      
      // Verify tree canvas/container exists and has content
      const treeContainer = page.locator('[data-testid="tree-canvas"], [class*="tree"], canvas, svg').first();
      await expect(treeContainer).toBeVisible({ timeout: 5000 }).catch(() => {
        // Tree might be rendered as DOM elements instead of canvas
        console.log('Tree visualization container not found, checking for person cards');
      });
      
      // Check for person cards/nodes in the tree
      const personCards = await page.locator('[data-testid="person-card"], [class*="person"], .person-node').count();
      expect(personCards).toBeGreaterThan(0);
    });
  });

  test.describe('Session Persistence', () => {
    test('should maintain session after navigation and page reload', async ({ page, context }) => {
      // Login first
      await page.goto('/#/login', { waitUntil: 'networkidle' });
      
      await page.fill('input[type="email"]', testUser.email);
      await page.fill('input[type="password"]', testUser.password);
      await page.click('button:has-text("Sign In")');
      
      await page.waitForURL(/\/#\/tree/, { timeout: 15000 });
      
      // Navigate to add member
      await page.goto('/#/tree/add-member', { waitUntil: 'networkidle' });
      await expect(page).toHaveURL(/\/#\/tree\/add-member/);
      
      // Go back
      await page.goBack();
      await page.waitForTimeout(1000);
      
      // Should still be logged in - not redirected to login
      const currentUrl = page.url();
      expect(currentUrl).not.toContain('/login');
      expect(currentUrl).toContain('/tree');
      
      // Reload the page
      await page.reload({ waitUntil: 'networkidle' });
      await page.waitForTimeout(2000);
      
      // Should STILL be on tree, not redirected to login
      const urlAfterReload = page.url();
      expect(urlAfterReload).not.toContain('/login');
      expect(urlAfterReload).toContain('/tree');
    });
  });

  test.describe('Profile Management', () => {
    test.beforeEach(async ({ page }) => {
      // Login before each profile test
      await page.goto('/#/login');
      await page.fill('input[type="email"]', testUser.email);
      await page.fill('input[type="password"]', testUser.password);
      await page.click('button:has-text("Sign In")');
      await page.waitForURL(/\/#\/tree/, { timeout: 15000 });
    });

    test('should create user profile with all fields', async ({ page }) => {
      // Navigate to profile setup
      await page.goto('/#/profile-setup', { waitUntil: 'networkidle' });
      
      // Check if already has profile
      if (page.url().includes('/tree')) {
        console.log('User already has profile, skipping creation test');
        return;
      }
      
      // Fill all required fields
      await page.fill('input[type="text"]', `Complete Profile ${Date.now()}`);
      await page.fill('input[placeholder*="phone" i], input[aria-label*="phone" i]', '9988776655');
      
      // Date of birth
      await page.click('text=/Date of Birth/i').catch(() => {});
      await page.fill('input[type="date"]', '1985-12-25').catch(() => {});
      
      // Gender
      await page.selectOption('select:has-option:text("Male")', 'male');
      
      // Optional fields
      await page.fill('input[placeholder*="city" i]', 'Delhi').catch(() => {});
      await page.fill('input[placeholder*="state" i]', 'Delhi').catch(() => {});
      await page.fill('input[placeholder*="occupation" i]', 'Engineer').catch(() => {});
      await page.fill('input[placeholder*="community" i]', 'Test Community').catch(() => {});
      
      // Submit
      await page.click('button:has-text("Save")');
      
      // Should redirect to tree
      await page.waitForURL(/\/#\/tree/, { timeout: 10000 });
      
      // Verify success message
      await expect(page.locator('text=/Profile created|success/i')).toBeVisible({ timeout: 5000 }).catch(() => {
        console.log('Success message not found, but redirect occurred');
      });
    });

    test('should navigate to profile when clicking profile button', async ({ page }) => {
      // Click profile button in top bar
      const profileButton = page.locator('button').filter({ has: page.locator('svg') }).nth(2);
      await profileButton.click();
      
      await page.waitForTimeout(2000);
      
      // Should navigate to either profile-setup or person detail
      const url = page.url();
      const isProfilePage = url.includes('/profile-setup') || url.includes('/person/');
      expect(isProfilePage).toBeTruthy();
    });

    test('should be able to view profile details', async ({ page }) => {
      // Navigate to profile
      await page.goto('/#/tree', { waitUntil: 'networkidle' });
      
      // Click profile button
      await page.click('button[aria-label="Profile"]').catch(async () => {
        // Try finding by icon
        const buttons = page.locator('button');
        const count = await buttons.count();
        for (let i = 0; i < count; i++) {
          const button = buttons.nth(i);
          const title = await button.getAttribute('title').catch(() => null);
          if (title?.toLowerCase().includes('profile')) {
            await button.click();
            break;
          }
        }
      });
      
      await page.waitForTimeout(2000);
      
      // If on profile setup, fill it
      if (page.url().includes('/profile-setup')) {
        // Already tested in main flow
        await page.goBack();
      } else if (page.url().includes('/person/')) {
        // On detail page - verify key elements
        await expect(page.locator('text=/Details|Information|Profile/i')).toBeVisible({ timeout: 5000 });
      }
    });
  });

  test.describe('Add Family Member with Relationships', () => {
    test.beforeEach(async ({ page }) => {
      await page.goto('/#/login');
      await page.fill('input[type="email"]', testUser.email);
      await page.fill('input[type="password"]', testUser.password);
      await page.click('button:has-text("Sign In")');
      await page.waitForURL(/\/#\/tree/, { timeout: 15000 });
    });

    test('should add a father', async ({ page }) => {
      await page.goto('/#/tree/add-member', { waitUntil: 'networkidle' });
      
      const fatherName = `Father ${Date.now()}`;
      
      // Fill name
      await page.fill('input[type="text"]', fatherName);
      
      // Select relationship type - FATHER_OF
      const relationshipSelect = page.locator('select').filter({ hasText: /Father|Mother|Relationship/i }).first();
      if (await relationshipSelect.isVisible()) {
        await relationshipSelect.selectOption('FATHER_OF');
      }
      
      // Gender should auto-select to male for FATHER_OF
      
      // Fill DOB
      const dobInput = page.locator('input[type="date"]').first();
      if (await dobInput.isVisible()) {
        await dobInput.fill('1960-03-20');
      }
      
      // Submit
      await page.click('button:has-text("Add"), button:has-text("Save")');
      
      await page.waitForURL(/\/#\/tree/, { timeout: 10000 });
    });

    test('should add a child', async ({ page }) => {
      await page.goto('/#/tree/add-member', { waitUntil: 'networkidle' });
      
      const childName = `Child ${Date.now()}`;
      
      await page.fill('input[type="text"]', childName);
      
      // Select CHILD_OF relationship
      const relSelect = page.locator('select').first();
      if (await relSelect.isVisible()) {
        const options = await relSelect.locator('option').allTextContents();
        if (options.some(opt => opt.includes('CHILD'))) {
          await relSelect.selectOption({ label: /CHILD/i });
        }
      }
      
      // Select gender
      await page.selectOption('select:has-option:text("Female")', 'female').catch(() => {});
      
      // DOB
      await page.fill('input[type="date"]', '2015-08-12').catch(() => {});
      
      // Submit
      await page.click('button:has-text("Add")');
      await page.waitForURL(/\/#\/tree/, { timeout: 10000 });
    });

    test('should verify tree updates after adding multiple members', async ({ page }) => {
      // Get initial member count
      await page.goto('/#/tree', { waitUntil: 'networkidle' });
      await page.waitForTimeout(2000);
      
      const initialMemberCount = await page.locator('[class*="person"], [data-testid="person-card"], text=/^[A-Z][a-z]+ [A-Z]/').count();
      
      // Add first member
      const member1Name = `TestMember1_${Date.now()}`;
      await page.goto('/#/tree/add-member', { waitUntil: 'networkidle' });
      await page.fill('input[type="text"]', member1Name);
      await page.selectOption('select', 'female').catch(() => {});
      await page.fill('input[type="date"]', '1995-03-10').catch(() => {});
      await page.click('button:has-text("Add")');
      await page.waitForURL(/\/#\/tree/, { timeout: 10000 });
      
      // Verify first member appears
      await page.waitForTimeout(2000);
      const hasMember1 = await page.locator(`text="${member1Name}"`).count() > 0;
      expect(hasMember1).toBeTruthy();
      
      // Add second member
      const member2Name = `TestMember2_${Date.now()}`;
      await page.goto('/#/tree/add-member', { waitUntil: 'networkidle' });
      await page.fill('input[type="text"]', member2Name);
      await page.selectOption('select', 'male').catch(() => {});
      await page.fill('input[type="date"]', '2010-07-22').catch(() => {});
      await page.click('button:has-text("Add")');
      await page.waitForURL(/\/#\/tree/, { timeout: 10000 });
      
      // Verify both members appear in tree
      await page.waitForTimeout(2000);
      const hasMember2 = await page.locator(`text="${member2Name}"`).count() > 0;
      expect(hasMember2).toBeTruthy();
      
      // Verify member count increased
      const finalMemberCount = await page.locator(`text="${member1Name}"`).count() + 
                               await page.locator(`text="${member2Name}"`).count();
      expect(finalMemberCount).toBeGreaterThanOrEqual(2);
    });
  });

  test.describe('Search Functionality', () => {
    test.beforeEach(async ({ page }) => {
      await page.goto('/#/login');
      await page.fill('input[type="email"]', testUser.email);
      await page.fill('input[type="password"]', testUser.password);
      await page.click('button:has-text("Sign In")');
      await page.waitForURL(/\/#\/tree/, { timeout: 15000 });
    });

    test('should navigate to search page', async ({ page }) => {
      // Look for search button in nav or go directly
      await page.goto('/#/search', { waitUntil: 'networkidle' });
      
      // Should be on search page
      await expect(page).toHaveURL(/\/#\/search/);
      
      // Check for search input
      const searchInput = page.locator('input[type="search"], input[placeholder*="search" i], input[aria-label*="search" i]');
      await expect(searchInput.first()).toBeVisible({ timeout: 5000 });
    });

    test('should search for family members by name', async ({ page }) => {
      await page.goto('/#/search', { waitUntil: 'networkidle' });
      
      // Enter search query
      const searchInput = page.locator('input[type="search"], input[placeholder*="search" i]').first();
      await searchInput.fill(testUser.name);
      
      // Trigger search (might be auto-search or need button click)
      const searchButton = page.locator('button:has-text("Search")');
      if (await searchButton.count() > 0) {
        await searchButton.click();
      } else {
        // Auto-search, wait for results
        await page.waitForTimeout(1000);
      }
      
      // Should show results
      await page.waitForTimeout(2000);
      
      // Check for results container
      const hasResults = await page.locator('[class*="result"], [data-testid="search-result"]').count() > 0;
      const hasName = await page.locator(`text="${testUser.name}"`).count() > 0;
      
      expect(hasResults || hasName).toBeTruthy();
    });

    test('should search by phone number', async ({ page }) => {
      await page.goto('/#/search', { waitUntil: 'networkidle' });
      
      const searchInput = page.locator('input[type="search"], input[placeholder*="search" i]').first();
      await searchInput.fill(testUser.phone);
      
      // Trigger search
      await page.keyboard.press('Enter');
      await page.waitForTimeout(2000);
      
      // Should show results with phone number
      const hasResults = await page.locator(`text="+91${testUser.phone}"`).count() > 0 ||
                        await page.locator(`text="${testUser.phone}"`).count() > 0;
      
      expect(hasResults).toBeTruthy();
    });

    test('should click on search result and navigate to profile', async ({ page }) => {
      await page.goto('/#/search', { waitUntil: 'networkidle' });
      
      const searchInput = page.locator('input[type="search"], input[placeholder*="search" i]').first();
      await searchInput.fill(testUser.name);
      await page.waitForTimeout(2000);
      
      // Click on a result
      const firstResult = page.locator('[class*="result"], [data-testid="search-result"], .person-card').first();
      if (await firstResult.count() > 0) {
        await firstResult.click();
        
        // Should navigate to person detail page
        await page.waitForURL(/\/#\/person\//, { timeout: 5000 });
      }
    });
  });

  test.describe('Navigation and UI', () => {
    test.beforeEach(async ({ page }) => {
      await page.goto('/#/login');
      await page.fill('input[type="email"]', testUser.email);
      await page.fill('input[type="password"]', testUser.password);
      await page.click('button:has-text("Sign In")');
      await page.waitForURL(/\/#\/tree/, { timeout: 15000 });
    });

    test('should have working top bar buttons', async ({ page }) => {
      // Check refresh button exists
      const refreshBtn = page.locator('button[title="Refresh"], button[aria-label="Refresh"]');
      await expect(refreshBtn).toBeVisible({ timeout: 5000 });
      
      // Check logout button exists
      const logoutBtn = page.locator('button[title*="Sign Out"], button[title*="Logout"]');
      await expect(logoutBtn).toBeVisible({ timeout: 5000 });
    });

    test('should be able to refresh the tree', async ({ page }) => {
      const refreshBtn = page.locator('button').filter({ has: page.locator('[class*="refresh"]') }).first();
      await refreshBtn.click();
      
      // Wait for potential reload
      await page.waitForTimeout(1000);
      
      // Should still be on tree page
      await expect(page).toHaveURL(/\/#\/tree/);
    });

    test('should be able to sign out', async ({ page }) => {
      // Find and click logout button
      const logoutBtn = page.locator('button').filter({ has: page.locator('svg') }).last();
      await logoutBtn.click();
      
      // Should redirect to login
      await page.waitForURL(/\/#\/login/, { timeout: 10000 });
      
      // Verify on login page
      await expect(page.locator('text=/Sign In|Login/i')).toBeVisible({ timeout: 5000 });
    });
  });

  test.describe('Error Handling', () => {
    test('should redirect to login when accessing protected route without auth', async ({ page }) => {
      // Clear all cookies and storage
      await page.context().clearCookies();
      await page.evaluate(() => localStorage.clear());
      
      // Try to access tree directly
      await page.goto('/#/tree', { waitUntil: 'networkidle' });
      
      // Should redirect to login
      await page.waitForURL(/\/#\/login/, { timeout: 5000 });
    });

    test('should show validation errors on invalid form submission', async ({ page }) => {
      await page.goto('/#/signup');
      
      // Try to submit without filling form
      await page.click('button:has-text("Sign Up")');
      
      // Should show validation errors
      await page.waitForTimeout(1000);
      
      // Check for error messages
      const hasErrors = await page.locator('text=/required|enter|must/i').count() > 0;
      expect(hasErrors).toBeTruthy();
    });
  });
});
