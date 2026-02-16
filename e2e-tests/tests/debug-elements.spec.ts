import { test } from '@playwright/test';

test('Debug: What elements exist on signup page', async ({ page }) => {
  await page.goto('/#/signup');
  await page.waitForLoadState('networkidle');
  console.log('Waiting 20 seconds for Flutter to fully load...');
  await page.waitForTimeout(20000); // Flutter web needs time to initialize

  // Take screenshot
  await page.screenshot({ path: 'test-results/signup-debug.png', fullPage: true });

  // Log all input elements
  const inputs = await page.locator('input').all();
  console.log(`Found ${inputs.length} input elements`);
  
  for (let i = 0; i < inputs.length; i++) {
    const input = inputs[i];
    const type = await input.getAttribute('type').catch(() => 'unknown');
    const placeholder = await input.getAttribute('placeholder').catch(() => '');
    const ariaLabel = await input.getAttribute('aria-label').catch(() => '');
    const id = await input.getAttribute('id').catch(() => '');
    const className = await input.getAttribute('class').catch(() => '');
    
    console.log(`Input ${i}: type=${type}, placeholder="${placeholder}", aria-label="${ariaLabel}", id="${id}", class="${className}"`);
  }

  // Log all buttons
  const buttons = await page.locator('button').all();
  console.log(`\nFound ${buttons.length} button elements`);
  
  for (let i = 0; i < buttons.length; i++) {
    const button = buttons[i];
    const text = await button.textContent().catch(() => '');
    const ariaLabel = await button.getAttribute('aria-label').catch(() => '');
    
    console.log(`Button ${i}: text="${text.trim()}", aria-label="${ariaLabel}"`);
  }

  // Log flt- prefixed elements (Flutter web specific)
  const fltElements = await page.locator('[class*="flt-"]').all();
  console.log(`\nFound ${fltElements.length} Flutter-specific elements`);

  // Check for semantics
  const semantics = await page.locator('flt-semantics').all();
  console.log(`Found ${semantics.length} flt-semantics elements`);

  // Log page HTML structure
  const bodyHTML = await page.locator('body').innerHTML();
  console.log('\n=== BODY HTML (first 2000 chars) ===');
  console.log(bodyHTML.substring(0, 2000));
});

test('Debug: What elements exist on login page', async ({ page }) => {
  await page.goto('/#/login');
  await page.waitForLoadState('networkidle');
  console.log('Waiting 20 seconds for Flutter to fully load...');
  await page.waitForTimeout(20000);

  await page.screenshot({ path: 'test-results/login-debug.png', fullPage: true });

  const inputs = await page.locator('input').all();
  console.log(`Found ${inputs.length} input elements on login`);
  
  for (let i = 0; i < inputs.length; i++) {
    const input = inputs[i];
    const type = await input.getAttribute('type').catch(() => 'unknown');
    const placeholder = await input.getAttribute('placeholder').catch(() => '');
    
    console.log(`Login Input ${i}: type=${type}, placeholder="${placeholder}"`);
  }
});

test('Debug: What elements exist on tree page after manual login', async ({ page }) => {
  // This test requires manual login or existing session
  await page.goto('/#/login');
  await page.waitForLoadState('networkidle');
  await page.waitForTimeout(3000);

  // Try to login
  const inputs = page.locator('input');
  if (await inputs.count() >= 2) {
    await inputs.nth(0).fill('chinni070707@gmail.com');
    await inputs.nth(1).fill('Ssd@88788');
    
    const button = page.locator('button').first();
    await button.click();
    
    await page.waitForTimeout(5000);
  }

  await page.screenshot({ path: 'test-results/tree-debug.png', fullPage: true });

  // Log buttons on tree page
  const buttons = await page.locator('button').all();
  console.log(`\nFound ${buttons.length} buttons on tree page`);
  
  for (let i = 0; i < buttons.length; i++) {
    const button = buttons[i];
    const ariaLabel = await button.getAttribute('aria-label').catch(() => '');
    const title = await button.getAttribute('title').catch(() => '');
    
    console.log(`Tree Button ${i}: aria-label="${ariaLabel}", title="${title}"`);
  }
});
