import { test, expect } from '@playwright/test';
import {
  initFlutterPage,
  waitForFlutter,
  enableAccessibility,
  fillField,
  clickButton,
  findButton,
  findByText,
  getFormFields,
} from './flutter-helpers';

/**
 * User Flow E2E Tests — compatible with Flutter Web's Canvas/Semantics rendering.
 *
 * Flutter Web renders to <canvas> so standard DOM selectors don't work.
 * Instead we:
 *   1. Enable the Flutter accessibility/semantics tree
 *   2. Locate elements via flt-semantics nodes (role, text, position)
 *   3. Click at element centers to activate text fields
 *   4. Type via keyboard into the Flutter text-editing-host input
 */

test.describe('Critical User Flows', () => {
  const existingUser = {
    email: 'chinni070707@gmail.com',
    password: 'Ssd@88788',
  };

  // ───────────────────────────────────────────────
  // 1. App loads and Flutter initializes correctly
  // ───────────────────────────────────────────────
  test('App loads and Flutter initializes', async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');

    // Wait for Flutter's bootstrap to create flutter-view
    const flutterView = page.locator('flutter-view');
    await flutterView.waitFor({ state: 'attached', timeout: 30000 });
    expect(await flutterView.count()).toBe(1);

    // Verify the canvas is rendered (CanvasKit)
    const canvas = page.locator('flutter-view canvas, flt-glass-pane canvas');
    await page.waitForTimeout(15000);
    expect(await canvas.count()).toBeGreaterThan(0);

    console.log('✅ Flutter app loaded and canvas rendered');
  });

  // ───────────────────────────────────────────────
  // 2. Page navigation via hash routes
  // ───────────────────────────────────────────────
  test('Hash route navigation works', async ({ page }) => {
    await page.goto('/');
    await waitForFlutter(page);
    expect(page.url()).toMatch(/\/($|#)/);

    await page.goto('/#/login');
    await page.waitForTimeout(3000);
    expect(page.url()).toContain('/login');

    await page.goto('/#/signup');
    await page.waitForTimeout(3000);
    expect(page.url()).toContain('/signup');

    console.log('✅ Hash route navigation works');
  });

  // ───────────────────────────────────────────────
  // 3. Login page structure is correct
  // ───────────────────────────────────────────────
  test('Login page has correct form structure', async ({ page }) => {
    await initFlutterPage(page, '/login');

    const welcomeText = findByText(page, 'Welcome back');
    expect(await welcomeText.count()).toBeGreaterThan(0);

    const fields = await getFormFields(page);
    console.log(`Found ${fields.length} form fields`);
    expect(fields.length).toBeGreaterThanOrEqual(2);

    const signInBtn = findButton(page, 'Sign In');
    expect(await signInBtn.count()).toBeGreaterThan(0);

    const googleBtn = findButton(page, 'Continue with Google');
    expect(await googleBtn.count()).toBeGreaterThan(0);

    console.log('✅ Login page structure verified');
  });

  // ───────────────────────────────────────────────
  // 4. Signup page structure is correct
  // ───────────────────────────────────────────────
  test('Signup page has correct form structure', async ({ page }) => {
    await initFlutterPage(page, '/signup');

    const heading = findByText(page, 'Create account');
    expect(await heading.count()).toBeGreaterThan(0);

    const fields = await getFormFields(page);
    console.log(`Found ${fields.length} form fields`);
    expect(fields.length).toBeGreaterThanOrEqual(4);

    const createBtn = findButton(page, 'Create Account');
    expect(await createBtn.count()).toBeGreaterThan(0);

    console.log('✅ Signup page structure verified');
  });

  // ───────────────────────────────────────────────
  // 5. Login flow with real credentials
  // ───────────────────────────────────────────────
  test('Login with existing user redirects to tree', async ({ page }) => {
    // Monitor network to see if Supabase auth call is made
    const networkLogs: string[] = [];
    page.on('request', req => {
      const url = req.url();
      if (url.includes('supabase') || url.includes('auth') || url.includes('token')) {
        networkLogs.push(`REQ: ${req.method()} ${url}`);
      }
    });
    page.on('response', res => {
      const url = res.url();
      if (url.includes('supabase') || url.includes('auth') || url.includes('token')) {
        networkLogs.push(`RES: ${res.status()} ${url}`);
      }
    });

    // Navigate to login
    await page.goto('/#/login');
    await waitForFlutter(page);

    // === Strategy ===
    // 1. Click field center on glass-pane → Flutter focuses text field
    // 2. Clear & type via keyboard → Flutter updates text controller
    // 3. Click neutral area to BLUR/COMMIT text (closes editing session)
    // 4. Repeat for password
    // 5. Re-enable accessibility to get fresh semantic tree
    // 6. Click Sign In via JS .click() on semantic node

    // --- EMAIL ---
    await page.mouse.click(996, 250);
    await page.waitForTimeout(1000);
    await page.keyboard.press('Control+a');
    await page.waitForTimeout(100);
    await page.keyboard.press('Backspace');
    await page.waitForTimeout(200);
    await page.keyboard.type(existingUser.email, { delay: 30 });
    await page.waitForTimeout(300);

    const emailVal = await page.evaluate(() => {
      const input = document.querySelector('flt-text-editing-host input') as HTMLInputElement;
      return input?.value || '';
    });
    console.log(`Email entered: "${emailVal}"`);

    // Click the page title to blur email field and commit value
    await page.mouse.click(996, 170);
    await page.waitForTimeout(1000);
    console.log('Blurred email field');

    // --- PASSWORD ---
    await page.mouse.click(996, 314);
    await page.waitForTimeout(1000);
    await page.keyboard.press('Control+a');
    await page.waitForTimeout(100);
    await page.keyboard.press('Backspace');
    await page.waitForTimeout(200);
    await page.keyboard.type(existingUser.password, { delay: 30 });
    await page.waitForTimeout(300);

    const pwVal = await page.evaluate(() => {
      const input = document.querySelector('flt-text-editing-host input') as HTMLInputElement;
      return input?.value || '';
    });
    console.log(`Password entered: "${pwVal}" (length: ${pwVal.length})`);

    // Click neutral area to blur password field and commit value
    await page.mouse.click(996, 170);
    await page.waitForTimeout(1000);
    console.log('Blurred password field');

    // Take debug screenshot showing form state before submit
    await page.screenshot({ path: 'test-results/debug-login-before-submit.png' });

    // Re-enable accessibility to get fresh semantic tree
    await enableAccessibility(page);
    await page.waitForTimeout(2000);

    // Log what's visible in the semantic tree now
    const semanticTexts = await page.evaluate(() => {
      const texts: string[] = [];
      document.querySelectorAll('flt-semantics').forEach(el => {
        const t = (el as HTMLElement).innerText?.trim();
        if (t && t.length > 0 && t.length < 100) texts.push(t);
      });
      return texts;
    });
    console.log(`Semantic tree after blur: ${JSON.stringify(semanticTexts)}`);

    // === SUBMIT: Try multiple click approaches ===

    // Approach 1: JS .click() on the Sign In semantic node (like accessibility button)
    const jsClickResult = await page.evaluate(() => {
      const nodes = document.querySelectorAll('flt-semantics[flt-tappable]');
      for (const node of nodes) {
        if ((node as HTMLElement).innerText?.includes('Sign In')) {
          (node as HTMLElement).click();
          return `clicked: ${node.id}, text: ${(node as HTMLElement).innerText?.trim()}`;
        }
      }
      return 'Sign In button not found in semantics';
    });
    console.log(`JS click result: ${jsClickResult}`);
    await page.waitForTimeout(5000);

    let url = page.url();
    console.log(`URL after JS click: ${url}`);

    // Approach 2: If JS click didn't work, try mouse click on glass-pane directly
    if (url.includes('/login')) {
      // Disable semantics so click goes directly to glass-pane
      await page.evaluate(() => {
        const host = document.querySelector('flt-semantics-host') as HTMLElement;
        if (host) host.style.display = 'none';
      });
      await page.waitForTimeout(500);
      await page.mouse.click(996, 411);
      await page.waitForTimeout(5000);
      // Re-show semantics host
      await page.evaluate(() => {
        const host = document.querySelector('flt-semantics-host') as HTMLElement;
        if (host) host.style.display = '';
      });
      url = page.url();
      console.log(`URL after glass-pane click: ${url}`);
    }

    // Approach 3: Click password field again and press Enter (onFieldSubmitted)
    if (url.includes('/login')) {
      await page.mouse.click(996, 314);
      await page.waitForTimeout(500);
      await page.keyboard.press('Enter');
      await page.waitForTimeout(5000);
      url = page.url();
      console.log(`URL after Enter in password: ${url}`);
    }

    // Log all network activity
    console.log(`Network activity: ${JSON.stringify(networkLogs)}`);

    // Check for error messages
    if (url.includes('/login')) {
      await enableAccessibility(page);
      await page.waitForTimeout(1000);
      const visTexts = await page.evaluate(() => {
        const texts: string[] = [];
        document.querySelectorAll('flt-semantics').forEach(el => {
          const t = (el as HTMLElement).innerText?.trim();
          if (t && t.length > 0 && t.length < 100) texts.push(t);
        });
        return texts;
      });
      console.log(`Final visible texts: ${JSON.stringify(visTexts)}`);
    }

    await page.screenshot({ path: 'test-results/debug-login-after-submit.png' });

    // Assert navigation away from login
    expect(url).not.toContain('/login');
    console.log('✅ Login successful');
  });

  // ───────────────────────────────────────────────
  // 6. Session persistence after login
  // ───────────────────────────────────────────────
  test('Session persists across page reload', async ({ page }) => {
    await initFlutterPage(page, '/login');
    await fillField(page, 0, existingUser.email);
    await fillField(page, 1, existingUser.password);
    await clickButton(page, 'Sign In');
    await page.waitForTimeout(8000);

    const urlAfterLogin = page.url();
    expect(urlAfterLogin).not.toContain('/login');

    await page.reload();
    await waitForFlutter(page);

    const urlAfterReload = page.url();
    console.log(`URL after reload: ${urlAfterReload}`);
    expect(urlAfterReload).not.toContain('/login');

    console.log('✅ Session persists after reload');
  });

  // ───────────────────────────────────────────────
  // 7. Navigation between authenticated pages
  // ───────────────────────────────────────────────
  test('Navigate authenticated routes after login', async ({ page }) => {
    await initFlutterPage(page, '/login');
    await fillField(page, 0, existingUser.email);
    await fillField(page, 1, existingUser.password);
    await clickButton(page, 'Sign In');
    await page.waitForTimeout(8000);

    await page.goto('/#/search');
    await page.waitForTimeout(3000);
    console.log(`Search page URL: ${page.url()}`);
    expect(page.url()).not.toContain('/login');

    await page.goto('/#/tree/add-member');
    await page.waitForTimeout(3000);
    console.log(`Add member URL: ${page.url()}`);
    expect(page.url()).not.toContain('/login');

    await page.goto('/#/tree');
    await page.waitForTimeout(3000);
    console.log(`Tree URL: ${page.url()}`);
    expect(page.url()).not.toContain('/login');

    console.log('✅ Authenticated route navigation works');
  });
});
