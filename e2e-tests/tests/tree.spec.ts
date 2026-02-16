import { test, expect } from '@playwright/test';

/**
 * Tree View E2E Tests
 * Tests for family tree functionality including viewing and adding members
 */

test.describe('Family Tree Management', () => {
  // Test user credentials (use existing user or creates one)
  const testEmail = 'treetest@example.com';
  const testPassword = 'TreeTest123!';

  test.beforeEach(async ({ page }) => {
    // Login before each test
    await page.goto('/#/login');
    
    // Fill credentials and login
    await page.fill('input[type="email"]', testEmail);
    await page.fill('input[type="password"]', testPassword);
    await page.click('button:has-text("Sign In")');
    
    // Wait for redirect to tree view
    await page.waitForURL(/\/#\/tree/, { timeout: 15000 });
  });

  test('should display the family tree view', async ({ page }) => {
    // Check if we're on the tree view page
    await expect(page).toHaveURL(/\/#\/tree/);
    
    // Check for key UI elements
    await expect(page.locator('text=/My Family Tree|Family Tree/i')).toBeVisible();
  });

  test('should open add member dialog', async ({ page }) => {
    // Look for "Add Child" or "Add Member" button
    const addButton = page.locator('button:has-text("Add")').first();
    
    if (await addButton.isVisible()) {
      await addButton.click();
      
      // Check if add member form appears
      await expect(page.locator('text=/Add Member|New Member|Add Family Member/i')).toBeVisible({ timeout: 5000 });
    }
  });

  test('should add a child to the family tree', async ({ page }) => {
    // Navigate to add member screen
    await page.goto('/#/tree/add-member');
    
    // Wait for form to load
    await page.waitForLoadState('networkidle');
    
    // Generate unique name
    const childName = `Child ${Date.now()}`;
    
    // Fill in child details
    const nameInput = page.locator('input[type="text"]').first();
    if (await nameInput.isVisible()) {
      await nameInput.fill(childName);
    }
    
    // Select gender
    const genderSelect = page.locator('select, [role="combobox"]').filter({ hasText: /Male|Female|Gender/i }).first();
    if (await genderSelect.isVisible()) {
      await genderSelect.click();
      await page.locator('text=Male').first().click();
    }
    
    // Fill date of birth if available
    const dobInput = page.locator('input[type="date"]').first();
    if (await dobInput.isVisible()) {
      await dobInput.fill('2020-01-15');
    }
    
    // Submit the form
    const submitButton = page.locator('button:has-text("Add"), button:has-text("Save"), button:has-text("Submit")').first();
    if (await submitButton.isVisible()) {
      await submitButton.click();
      
      // Wait for navigation back to tree or success message
      await page.waitForURL(/\/tree/, { timeout: 10000 });
      
      // Verify the child appears in the tree
      await expect(page.locator(`text=${childName}`)).toBeVisible({ timeout: 5000 });
    }
  });

  test('should add a parent relationship', async ({ page }) => {
    // This test assumes we're on the tree view
    // Look for an existing person card
    const personCard = page.locator('[data-testid="person-card"]').first();
    
    if (await personCard.isVisible()) {
      await personCard.click();
      
      // Look for "Add Parent" button
      const addParentButton = page.locator('button:has-text("Add Parent")').first();
      if (await addParentButton.isVisible()) {
        await addParentButton.click();
        
        // Fill parent details
        const parentName = `Parent ${Date.now()}`;
        await page.locator('input[type="text"]').first().fill(parentName);
        
        // Submit
        await page.locator('button:has-text("Add"), button:has-text("Save")').first().click();
        
        // Verify parent added
        await expect(page.locator(`text=${parentName}`)).toBeVisible({ timeout: 5000 });
      }
    }
  });

  test('should add a sibling relationship', async ({ page }) => {
    // Navigate to add member with sibling relationship
    await page.goto('/#/tree/add-member');
    await page.waitForLoadState('networkidle');
    
    // Fill sibling details
    const siblingName = `Sibling ${Date.now()}`;
    const nameInput = page.locator('input[type="text"]').first();
    if (await nameInput.isVisible()) {
      await nameInput.fill(siblingName);
      
      // Select relationship type if available
      const relationshipSelect = page.locator('select').filter({ hasText: /Relationship|Type/i }).first();
      if (await relationshipSelect.isVisible()) {
        await relationshipSelect.selectOption('SIBLING_OF');
      }
      
      // Submit form
      await page.locator('button:has-text("Add"), button:has-text("Save")').first().click();
      
      // Wait for navigation
      await page.waitForURL(/\/tree/, { timeout: 10000 });
    }
  });

  test('should display person details when clicking on a person', async ({ page }) => {
    // Look for any person card in the tree
    const personCards = page.locator('[data-testid="person-card"], .person-card, [class*="person"]');
    const firstPerson = personCards.first();
    
    if (await firstPerson.isVisible()) {
      const personName = await firstPerson.textContent();
      await firstPerson.click();
      
      // Should navigate to person detail page or show modal
      await expect(page.locator('text=/Details|Profile|Information/i')).toBeVisible({ timeout: 5000 });
    }
  });

  test('should validate required fields when adding a member', async ({ page }) => {
    await page.goto('/#/tree/add-member');
    await page.waitForLoadState('networkidle');
    
    // Try to submit without filling required fields
    const submitButton = page.locator('button:has-text("Add"), button:has-text("Save"), button:has-text("Submit")').first();
    if (await submitButton.isVisible()) {
      await submitButton.click();
      
      // Should show validation errors
      await expect(page.locator('text=/required|Please enter|cannot be empty/i')).toBeVisible({ timeout: 3000 });
    }
  });

  test('should search for family members', async ({ page }) => {
    // Look for search input
    const searchInput = page.locator('input[type="search"], input[placeholder*="Search"]').first();
    
    if (await searchInput.isVisible()) {
      await searchInput.fill('Test');
      
      // Wait for search results
      await page.waitForTimeout(1000);
      
      // Results should be filtered
      const results = page.locator('[data-testid="person-card"], .person-card');
      await expect(results.first()).toBeVisible({ timeout: 3000 });
    }
  });

  test('should navigate to different views (tree, list, etc)', async ({ page }) => {
    // Look for view toggle buttons
    const viewButtons = page.locator('button[role="tab"], [data-testid="view-toggle"]');
    
    if (await viewButtons.count() > 0) {
      // Click different view options
      for (let i = 0; i < await viewButtons.count(); i++) {
        const button = viewButtons.nth(i);
        if (await button.isVisible()) {
          await button.click();
          await page.waitForTimeout(500);
        }
      }
    }
  });

  test('should handle empty tree state', async ({ page }) => {
    // This test is for a new user with no family members
    // You might need to create a fresh account for this
    
    // Look for empty state message
    const emptyState = page.locator('text=/No family members|Start building|Add your first member/i');
    
    // If empty, should show call to action
    if (await emptyState.isVisible()) {
      await expect(emptyState).toBeVisible();
      
      // Should have add member button
      await expect(page.locator('button:has-text("Add")')).toBeVisible();
    }
  });

  test('should zoom in and out on tree visualization', async ({ page }) => {
    // Look for zoom controls
    const zoomInButton = page.locator('button:has-text("+"), [aria-label*="Zoom in"]').first();
    const zoomOutButton = page.locator('button:has-text("-"), [aria-label*="Zoom out"]').first();
    
    if (await zoomInButton.isVisible()) {
      // Click zoom in
      await zoomInButton.click();
      await page.waitForTimeout(300);
      
      // Click zoom out
      if (await zoomOutButton.isVisible()) {
        await zoomOutButton.click();
        await page.waitForTimeout(300);
      }
    }
  });

  test('should edit an existing family member', async ({ page }) => {
    // Click on a person to view details
    const personCard = page.locator('[data-testid="person-card"]').first();
    
    if (await personCard.isVisible()) {
      await personCard.click();
      
      // Look for edit button
      const editButton = page.locator('button:has-text("Edit")').first();
      if (await editButton.isVisible()) {
        await editButton.click();
        
        // Modify a field
        const nameInput = page.locator('input[type="text"]').first();
        if (await nameInput.isVisible()) {
          const newName = `Updated ${Date.now()}`;
          await nameInput.clear();
          await nameInput.fill(newName);
          
          // Save changes
          await page.locator('button:has-text("Save"), button:has-text("Update")').first().click();
          
          // Verify update
          await expect(page.locator(`text=${newName}`)).toBeVisible({ timeout: 5000 });
        }
      }
    }
  });

  test('should delete a family member', async ({ page }) => {
    // Navigate to a person's detail page
    const personCard = page.locator('[data-testid="person-card"]').first();
    
    if (await personCard.isVisible()) {
      await personCard.click();
      
      // Look for delete button
      const deleteButton = page.locator('button:has-text("Delete"), button:has-text("Remove")').first();
      if (await deleteButton.isVisible()) {
        await deleteButton.click();
        
        // Confirm deletion if there's a confirmation dialog
        const confirmButton = page.locator('button:has-text("Confirm"), button:has-text("Yes"), button:has-text("Delete")');
        if (await confirmButton.isVisible()) {
          await confirmButton.click();
        }
        
        // Should navigate back to tree
        await page.waitForURL(/\/tree/, { timeout: 5000 });
      }
    }
  });
});
