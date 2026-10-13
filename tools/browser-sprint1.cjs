const { chromium } = require('playwright');
const fs = require('node:fs'),
  path = require('node:path'),
  assert = require('node:assert/strict');
const output = path.resolve(__dirname, '../docs/qa/sprint-1');
fs.mkdirSync(output, { recursive: true });
const checks = [];
const pass = (name) => {
  checks.push({ name, status: 'pass' });
  console.log('PASS', name);
};
(async () => {
  const browser = await chromium.launch({
    channel: process.platform === 'win32' ? 'msedge' : undefined,
    headless: true,
  });
  try {
    const context = await browser.newContext({
        viewport: { width: 1440, height: 1000 },
      }),
      page = await context.newPage();
    const errors = [],
      external = [];
    page.on('pageerror', (e) => errors.push(e.message));
    page.on('console', (m) => {
      if (m.type() === 'error') errors.push(m.text());
    });
    page.on('request', (r) => {
      const u = new URL(r.url());
      if (
        ['http:', 'https:'].includes(u.protocol) &&
        !['localhost', '127.0.0.1'].includes(u.hostname)
      )
        external.push(r.url());
    });
    const cell = (x, y) => page.locator(`[data-cell="${x},${y}"]`);
    const text = (selector) => page.locator(selector).innerText();
    const ready = () =>
      page.waitForFunction(
        () =>
          !!document.querySelector('#reset') &&
          !document.querySelector('#reset').disabled,
      );
    const reset = async () => {
      await page.locator('#reset').click();
      assert.equal(await text('#position'), 'B6');
      assert.equal(await text('#remaining'), '4');
    };
    const confirm = async (x, y) => {
      await cell(x, y).click();
      assert.equal(await page.locator('#confirm').isEnabled(), true);
      await page.locator('#confirm').click();
      await ready();
      assert.equal(
        await text('#position'),
        String.fromCharCode(65 + x) + (y + 1),
      );
    };
    await page.goto('http://127.0.0.1:5173/?view=training', { waitUntil: 'networkidle' });
    await ready();
    assert.equal(await page.getByRole('gridcell').count(), 64);
    assert.equal(await page.locator('[data-unit]').count(), 6);
    assert.equal(await page.locator('canvas').count(), 1);
    assert.equal(await text('#position'), 'B6');
    pass('Board loads with 64 keyboard cells, six units and local sprites');
    await cell(1, 3).hover();
    assert((await cell(1, 4).getAttribute('class')).includes('path-tile'));
    assert.equal(await page.locator('#confirm').isEnabled(), false);
    pass('Hover previews a weighted route without creating an order');
    await cell(1, 3).click();
    assert((await text('#route-summary')).includes('3 puntos'));
    assert.equal(await text('#position'), 'B6');
    assert.equal(await text('#remaining'), '4');
    await page.screenshot({
      path: path.join(output, 'desktop-route.png'),
      fullPage: true,
    });
    await page.locator('#cancel').click();
    assert.equal(await text('#position'), 'B6');
    assert.equal(await text('#remaining'), '4');
    assert.equal(await page.locator('#confirm').isEnabled(), false);
    pass(
      'Pending route costs three points; cancellation preserves position and budget',
    );
    await cell(1, 3).click();
    await page.locator('#confirm').focus();
    await page.keyboard.press('Escape');
    assert.equal(await page.locator('#confirm').isEnabled(), false);
    pass('Escape cancels from order controls as well as the grid');
    for (const [x, y, reason] of [
      [2, 2, 'bloquea'],
      [6, 3, 'bloquea'],
      [7, 0, 'No hay camino'],
      [7, 7, 'Necesita'],
    ]) {
      await cell(x, y).click();
      assert((await text('#feedback')).includes(reason));
      assert.equal(await text('#remaining'), '4');
      assert.equal(await text('#position'), 'B6');
      assert.equal(await page.locator('#confirm').isEnabled(), false);
    }
    pass(
      'Rock, water, unreachable destination and excessive cost reject without changes',
    );
    await cell(5, 4).click();
    assert.equal(await text('#unit-name'), 'Geodude');
    assert.equal(await text('#position'), 'F5');
    assert.equal(await text('#remaining'), '3');
    for (const [id, name] of [
      [1, 'Bulbasaur'],
      [4, 'Charmander'],
      [7, 'Squirtle'],
      [25, 'Pikachu'],
      [12, 'Butterfree'],
      [74, 'Geodude'],
    ]) {
      await page.locator(`[data-unit="${id}"]`).click();
      assert.equal(await text('#unit-name'), name);
    }
    pass('Occupied cells select their unit; all six roster controls work');
    await page.locator('[data-unit="1"]').click();
    await cell(1, 3).click();
    await page.locator('#confirm').click();
    assert.equal(await page.locator('#reset').isEnabled(), false);
    assert.equal(await page.locator('[data-unit="4"]').isEnabled(), false);
    assert.equal(await cell(0, 0).isEnabled(), false);
    await page.locator('#pause').click();
    await page.waitForTimeout(250);
    assert.equal(await page.locator('#reset').isEnabled(), false);
    await page.locator('#pause').click();
    await ready();
    assert.equal(await text('#position'), 'B4');
    assert.equal(await text('#remaining'), '1');
    assert.equal(await text('#facing'), 'Norte');
    pass(
      'Animated confirmation locks orders, supports pause/resume and charges terrain cost',
    );
    await confirm(0, 3);
    assert.equal(await text('#remaining'), '0');
    assert.equal(await text('#facing'), 'Oeste');
    await cell(0, 2).click();
    assert((await text('#feedback')).includes('quedan 0'));
    pass(
      'Repeated movement uses remaining budget; exhausted units cannot move',
    );
    await reset();
    await page.locator('[data-unit="25"]').click();
    for (const [x, y, facing] of [
      [5, 7, 'Sur'],
      [4, 7, 'Oeste'],
      [4, 6, 'Norte'],
      [5, 6, 'Este'],
    ]) {
      await confirm(x, y);
      assert.equal(await text('#facing'), facing);
    }
    pass('Cardinal movement updates final facing in all four directions');
    await reset();
    await cell(1, 5).focus();
    await page.keyboard.press('ArrowLeft');
    assert.equal(
      await page.evaluate(() => document.activeElement.dataset.cell),
      '0,5',
    );
    assert.equal(
      await cell(0, 5).evaluate((e) => getComputedStyle(e).outlineWidth),
      '3px',
    );
    await page.keyboard.press('Enter');
    await page.locator('#confirm').click();
    await ready();
    assert.equal(await text('#position'), 'A6');
    pass(
      'Arrow keys, Enter, visible focus and post-move focus complete keyboard flow',
    );
    await reset();
    await page.locator('.unit-details summary').click();
    assert(
      (await page.locator('#unit-stats').innerText()).includes('Velocidad'),
    );
    await page.locator('.unit-details summary').click();
    await page.locator('#pause').click();
    const frame1 = await page.locator('canvas').screenshot();
    await page.waitForTimeout(220);
    const frame2 = await page.locator('canvas').screenshot();
    assert(frame1.equals(frame2));
    await page.locator('#pause').click();
    pass(
      'Statistics disclose real data; pausing keeps the resting canvas still',
    );
    await page.screenshot({
      path: path.join(output, 'desktop.png'),
      fullPage: true,
    });
    assert.equal(
      await page.evaluate(
        () => document.documentElement.scrollWidth > innerWidth,
      ),
      false,
    );
    await page.setViewportSize({ width: 900, height: 1000 });
    assert.equal(
      await page.evaluate(
        () => document.documentElement.scrollWidth > innerWidth,
      ),
      false,
    );
    await page.setViewportSize({ width: 390, height: 844 });
    assert.equal(
      await page.evaluate(
        () => document.documentElement.scrollWidth > innerWidth,
      ),
      false,
    );
    await cell(1, 3).click();
    await page.screenshot({
      path: path.join(output, 'mobile-route.png'),
      fullPage: true,
    });
    await page.locator('#cancel').click();
    await confirm(0, 5);
    assert.equal(await text('#remaining'), '3');
    await reset();
    await page.screenshot({
      path: path.join(output, 'mobile.png'),
      fullPage: true,
    });
    pass(
      'Desktop, intermediate and narrow layouts do not overflow; narrow click flow works',
    );
    assert.equal(
      await page
        .locator('img')
        .evaluateAll((imgs) =>
          imgs.every((i) => i.complete && i.naturalWidth > 0),
        ),
      true,
    );
    await page.locator('.camp-link').click();
    await page.waitForLoadState('networkidle');
    await page.locator('#load-status').waitFor({ state: 'hidden' });
    assert.equal(await page.locator('[data-species]').count(), 6);
    await page.locator('[data-species="12"]').click();
    assert.equal(await text('#species-heading'), 'Butterfree');
    pass('Camp from sprint zero remains available with species selection');
    assert.deepEqual(errors, []);
    assert.deepEqual(external, []);
    pass(
      'Successful visits have no JavaScript/console errors, external requests or broken images',
    );
    const reduced = await browser.newContext({
      viewport: { width: 1440, height: 1000 },
      reducedMotion: 'reduce',
    });
    const rp = await reduced.newPage();
    await rp.goto('http://127.0.0.1:5173/?view=training', { waitUntil: 'networkidle' });
    await rp.waitForFunction(
      () =>
        !!document.querySelector('#reset') &&
        !document.querySelector('#reset').disabled,
    );
    assert((await rp.locator('#pause').innerText()).includes('Reanudar'));
    await rp.locator('[data-cell="1,3"]').click();
    await rp.locator('#confirm').click();
    await rp.waitForFunction(
      () => document.querySelector('#position').textContent === 'B4',
    );
    assert.equal(await rp.locator('#remaining').innerText(), '1');
    pass(
      'Reduced motion starts paused and commits displacement without walking tween',
    );
    await reduced.close();
    const faults = await browser.newContext({
        viewport: { width: 1440, height: 1000 },
      }),
      fp = await faults.newPage();
    await fp.route('**/data/pokemon.json', async (route) => {
      await new Promise((r) => setTimeout(r, 350));
      await route.continue();
    });
    await fp.route('**/assets/pokemon/*/*.png', async (route) => {
      await new Promise((r) => setTimeout(r, 450));
      await route.continue();
    });
    await fp.goto('http://127.0.0.1:5173/?view=training', { waitUntil: 'domcontentloaded' });
    await fp.locator('#resource-status').waitFor();
    assert.equal(await fp.locator('#confirm').isEnabled(), false);
    await fp.screenshot({
      path: path.join(output, 'loading.png'),
      fullPage: true,
    });
    await fp.waitForFunction(
      () =>
        !!document.querySelector('#reset') &&
        !document.querySelector('#reset').disabled,
    );
    pass('Slow resource loading keeps the board stable and orders disabled');
    await fp.unroute('**/data/pokemon.json');
    await fp.unroute('**/assets/pokemon/*/*.png');
    await fp.route('**/data/pokemon.json', (r) => r.fulfill({ json: [] }));
    await fp.reload({ waitUntil: 'networkidle' });
    assert(
      (await fp.locator('body').innerText()).includes('Catálogo incompleto'),
    );
    await fp.screenshot({
      path: path.join(output, 'error.png'),
      fullPage: true,
    });
    await fp.unroute('**/data/pokemon.json');
    await fp.locator('#retry').click();
    await fp.waitForFunction(
      () =>
        !!document.querySelector('#reset') &&
        !document.querySelector('#reset').disabled,
    );
    pass('Empty/invalid catalogue fails explicitly; retry recovers the board');
    await fp.route('**/assets/pokemon/1/Idle.png', (r) => r.abort());
    await fp.reload({ waitUntil: 'networkidle' });
    await fp.waitForFunction(
      () =>
        !!document.querySelector('#reset') &&
        !document.querySelector('#reset').disabled,
    );
    assert(
      (await fp.locator('#resource-status').innerText()).includes('Faltan'),
    );
    await fp.locator('[data-cell="0,5"]').click();
    await fp.locator('#confirm').click();
    await fp.waitForFunction(
      () => document.querySelector('#position').textContent === 'A6',
    );
    await fp.screenshot({
      path: path.join(output, 'partial.png'),
      fullPage: true,
    });
    await fp.unroute('**/assets/pokemon/1/Idle.png');
    await fp.getByRole('button', { name: 'Volver a cargar' }).click();
    await fp.locator('#resource-status').waitFor({ state: 'hidden' });
    pass(
      'Missing animation uses marker, preserves movement and recovers through reload',
    );
    await faults.close();
    fs.writeFileSync(
      path.join(output, 'browser-results.json'),
      JSON.stringify(
        {
          browser: 'Microsoft Edge headless (Playwright)',
          checks,
          consoleErrors: errors,
          externalRequests: external,
        },
        null,
        2,
      ) + '\n',
    );
    console.log(`Completed ${checks.length} browser checks`);
  } finally {
    await browser.close();
  }
})().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
