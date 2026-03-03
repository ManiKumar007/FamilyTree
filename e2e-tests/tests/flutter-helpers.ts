import { Page } from '@playwright/test';

/**
 * Flutter Web Test Helpers
 *
 * Flutter Web renders everything on a <canvas> via CanvasKit. User interaction
 * happens through pointer events on the flt-glass-pane, NOT through DOM events
 * on individual elements.
 *
 * After enabling accessibility, Flutter creates a semantics tree with flt-semantics
 * nodes that mirror the widget tree. These nodes have accurate positions and text
 * content, but most have pointer-events: none (clicks pass through to canvas).
 *
 * Text input goes through a single transparent <input> in flt-text-editing-host
 * that Flutter repositions to whichever field is active.
 *
 * Interaction strategy:
 *   - Use page.mouse.click(x, y) at element centers — clicks go through semantic
 *     overlay to the glass-pane canvas where Flutter processes the hit test
 *   - Use page.keyboard for text input after a field is focused
 *   - Use semantic nodes only for discovering element positions and text content
 */

/** Time to wait for Flutter to fully initialize (CanvasKit + app) */
export const FLUTTER_LOAD_WAIT = 20000;

/**
 * Wait for Flutter to fully load on the page.
 */
export async function waitForFlutter(page: Page, timeoutMs = FLUTTER_LOAD_WAIT) {
  await page.waitForLoadState('networkidle');
  await page.waitForSelector('flutter-view', { timeout: timeoutMs }).catch(() => null);
  await page.waitForTimeout(Math.min(timeoutMs, 15000));
}

/**
 * Enable Flutter accessibility mode by clicking the hidden semantics placeholder.
 * This populates flt-semantics-host with interactive DOM elements.
 * The element is at position (-1,-1) so we use JS click.
 */
export async function enableAccessibility(page: Page) {
  await page.evaluate(() => {
    const el = document.querySelector('[aria-label="Enable accessibility"]') as HTMLElement;
    if (el) el.click();
  });
  await page.waitForTimeout(2000);
}

/**
 * Find a Flutter semantic node by its text content.
 */
export function findByText(page: Page, text: string | RegExp) {
  if (typeof text === 'string') {
    return page.locator(`flt-semantics:has-text("${text}")`).first();
  }
  return page.locator('flt-semantics').filter({ hasText: text }).first();
}

/**
 * Find a tappable Flutter button by its text content.
 */
export function findButton(page: Page, text: string) {
  return page.locator(`flt-semantics[flt-tappable]:has-text("${text}")`).first();
}

/**
 * Click a Flutter button by text — uses mouse click at the element's center
 * so the pointer event reaches Flutter's glass-pane hit testing.
 */
export async function clickButton(page: Page, text: string) {
  const btn = findButton(page, text);
  await btn.waitFor({ state: 'attached', timeout: 10000 });
  const box = await btn.boundingBox();
  if (!box) throw new Error(`Button "${text}" has no bounding box`);
  // Click at center of the button
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  await page.waitForTimeout(500);
}

/**
 * Get all form field positions from the semantic tree.
 * Form fields are non-button semantic nodes ~48px tall inside a <form>.
 */
export async function getFormFields(page: Page) {
  return page.evaluate(() => {
    const form = document.querySelector('form');
    if (!form) return [];

    const fields: Array<{ id: string; x: number; y: number; w: number; h: number; text: string }> = [];
    form.querySelectorAll('flt-semantics').forEach((el) => {
      const rect = el.getBoundingClientRect();
      const hasTappable = el.hasAttribute('flt-tappable');
      const height = rect.height;
      // Form fields: ~48px tall, not a tappable button, width > 100
      const isFieldContainer = !hasTappable && height >= 40 && height <= 60 && rect.width > 100;

      if (isFieldContainer) {
        fields.push({
          id: el.id,
          x: Math.round(rect.x),
          y: Math.round(rect.y),
          w: Math.round(rect.width),
          h: Math.round(rect.height),
          text: (el as HTMLElement).innerText?.trim().substring(0, 50) || '',
        });
      }
    });
    return fields;
  });
}

/**
 * Fill a Flutter text field by clicking at its center, then typing via keyboard.
 *
 * After the mouse click hits the canvas, Flutter focuses the text field and
 * positions the transparent input overlay there. Then keyboard.type() sends
 * text through that input into the Flutter widget.
 */
export async function fillField(page: Page, fieldIndex: number, value: string) {
  const fields = await getFormFields(page);
  if (fieldIndex >= fields.length) {
    throw new Error(`Field index ${fieldIndex} out of range (${fields.length} fields found)`);
  }

  const field = fields[fieldIndex];
  const centerX = field.x + field.w / 2;
  const centerY = field.y + field.h / 2;

  // Click the center of the field — goes through semantic layer to glass-pane
  await page.mouse.click(centerX, centerY);
  await page.waitForTimeout(800);

  // Select all existing text and delete it
  await page.keyboard.press('Control+a');
  await page.waitForTimeout(100);
  await page.keyboard.press('Backspace');
  await page.waitForTimeout(200);

  // Type the value character by character
  await page.keyboard.type(value, { delay: 30 });
  await page.waitForTimeout(500);
}

/**
 * Full initialization sequence for Flutter Web tests.
 * Navigates to a route, waits for Flutter, and enables accessibility.
 */
export async function initFlutterPage(page: Page, route: string) {
  await page.goto(`/#${route}`);
  await waitForFlutter(page);
  await enableAccessibility(page);
}

/**
 * Take a screenshot for debugging.
 */
export async function debugScreenshot(page: Page, name: string) {
  await page.screenshot({ path: `test-results/debug-${name}.png`, fullPage: true });
}
