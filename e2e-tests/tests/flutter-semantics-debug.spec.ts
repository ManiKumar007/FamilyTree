import { test, expect } from '@playwright/test';

/**
 * Debug test to explore Flutter Web semantics tree after enabling accessibility.
 * This helps us understand what selectors to use for actual tests.
 */

/** Helper: enable Flutter accessibility mode via JS click on hidden element */
async function enableFlutterAccessibility(page: any) {
  await page.evaluate(() => {
    const el = document.querySelector('[aria-label="Enable accessibility"]') as HTMLElement;
    if (el) el.click();
  });
  await page.waitForTimeout(2000);
}

test('Detailed form structure on signup page', async ({ page }) => {
  await page.goto('/#/signup');
  await page.waitForLoadState('networkidle');
  console.log('Waiting 20s for Flutter to load...');
  await page.waitForTimeout(20000);

  await enableFlutterAccessibility(page);

  // Dump ALL semantic nodes with their text content, position, and attributes
  const nodes = await page.evaluate(() => {
    const results: any[] = [];
    document.querySelectorAll('flt-semantics, form').forEach((el, i) => {
      const rect = el.getBoundingClientRect();
      const text = (el as HTMLElement).innerText?.trim().substring(0, 100) || '';
      const attrs: { [key: string]: string } = {};
      for (const attr of Array.from(el.attributes)) {
        attrs[attr.name] = attr.value;
      }
      results.push({
        index: i,
        tag: el.tagName,
        id: el.id,
        role: el.getAttribute('role'),
        tappable: el.hasAttribute('flt-tappable'),
        text: text,
        x: Math.round(rect.x),
        y: Math.round(rect.y),
        w: Math.round(rect.width),
        h: Math.round(rect.height),
        children: el.children.length,
        hasInput: el.querySelector('input') !== null,
      });
    });
    return results;
  });

  console.log(`\n=== ALL SEMANTIC NODES (${nodes.length}) ===`);
  for (const n of nodes) {
    const flags = [
      n.role ? `role=${n.role}` : '',
      n.tappable ? 'TAPPABLE' : '',
      n.hasInput ? 'HAS_INPUT' : '',
      n.text ? `"${n.text}"` : '',
    ].filter(Boolean).join(' ');
    console.log(`  [${n.index}] ${n.tag} #${n.id} (${n.x},${n.y} ${n.w}x${n.h}) children=${n.children} ${flags}`);
  }

  // Specifically look for form and its children
  const formNodes = await page.evaluate(() => {
    const form = document.querySelector('form');
    if (!form) return [];
    const results: any[] = [];
    form.querySelectorAll('flt-semantics').forEach((el, i) => {
      const rect = el.getBoundingClientRect();
      results.push({
        index: i,
        id: el.id,
        role: el.getAttribute('role'),
        tappable: el.hasAttribute('flt-tappable'),
        text: (el as HTMLElement).innerText?.trim().substring(0, 80) || '',
        x: Math.round(rect.x),
        y: Math.round(rect.y),
        w: Math.round(rect.width),
        h: Math.round(rect.height),
      });
    });
    return results;
  });

  console.log(`\n=== FORM CHILDREN (${formNodes.length}) ===`);
  for (const n of formNodes) {
    const flags = [n.role || '', n.tappable ? 'TAPPABLE' : '', n.text ? `"${n.text}"` : ''].filter(Boolean).join(' ');
    console.log(`  [${n.index}] #${n.id} (${n.x},${n.y} ${n.w}x${n.h}) ${flags}`);
  }
});

test('Detailed form structure on login page', async ({ page }) => {
  await page.goto('/#/login');
  await page.waitForLoadState('networkidle');
  console.log('Waiting 20s for Flutter to load...');
  await page.waitForTimeout(20000);

  await enableFlutterAccessibility(page);

  const nodes = await page.evaluate(() => {
    const results: any[] = [];
    document.querySelectorAll('flt-semantics, form').forEach((el, i) => {
      const rect = el.getBoundingClientRect();
      results.push({
        index: i,
        tag: el.tagName,
        id: el.id,
        role: el.getAttribute('role'),
        tappable: el.hasAttribute('flt-tappable'),
        text: (el as HTMLElement).innerText?.trim().substring(0, 100) || '',
        x: Math.round(rect.x),
        y: Math.round(rect.y),
        w: Math.round(rect.width),
        h: Math.round(rect.height),
        children: el.children.length,
      });
    });
    return results;
  });

  console.log(`\n=== ALL NODES ON LOGIN (${nodes.length}) ===`);
  for (const n of nodes) {
    const flags = [
      n.role ? `role=${n.role}` : '',
      n.tappable ? 'TAPPABLE' : '',
      n.text ? `"${n.text}"` : '',
    ].filter(Boolean).join(' ');
    console.log(`  [${n.index}] ${n.tag} #${n.id} (${n.x},${n.y} ${n.w}x${n.h}) children=${n.children} ${flags}`);
  }

  // Look for tappable form-field-like elements
  const tappable = await page.evaluate(() => {
    const results: any[] = [];
    document.querySelectorAll('flt-semantics[flt-tappable]').forEach((el, i) => {
      const rect = el.getBoundingClientRect();
      results.push({
        index: i,
        id: el.id,
        text: (el as HTMLElement).innerText?.trim().substring(0, 80) || '',
        x: Math.round(rect.x),
        y: Math.round(rect.y),
        w: Math.round(rect.width),
        h: Math.round(rect.height),
      });
    });
    return results;
  });

  console.log(`\n=== TAPPABLE ELEMENTS (${tappable.length}) ===`);
  for (const t of tappable) {
    console.log(`  [${t.index}] #${t.id} (${t.x},${t.y} ${t.w}x${t.h}) "${t.text}"`);
  }
});
