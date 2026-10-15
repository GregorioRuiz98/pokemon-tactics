const { chromium } = require('playwright');
const fs = require('node:fs'), assert = require('node:assert/strict'), path = require('node:path');
const { createRun, CURRENT_EDITION, enterRoom, leaveService, enterEncounter } = require('../src/rules/run.ts');
const { activeUnit } = require('../src/rules/battle.ts');
const { routesFrom } = require('../src/rules/movement.ts');
const catalog = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../public/data/pokemon.json'), 'utf8'));
const base = process.env.TACTICS_URL || 'http://127.0.0.1:5173/';
const output = path.resolve(process.env.TACTICS_QA_DIR || path.resolve(__dirname, '../docs/qa/sprint-11/lifecycle'));
(async () => {
  const browser = await chromium.launch({ channel: process.platform === 'win32' ? 'msedge' : undefined, headless: true });
  try {
    const context = await browser.newContext({ viewport: { width: 1280, height: 768 }, reducedMotion: 'reduce' });
    const page = await context.newPage(), errors = [];
    page.on('pageerror', error => errors.push(error.message));
    const modified = structuredClone(catalog);
    modified[0].name = '<img src=x onerror=alert(1)>';
    await page.route('**/data/pokemon.json', route => route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(modified) }));
    await page.goto(base); await page.waitForSelector('#new-run');
    assert.equal(await page.locator('img[src=x]').count(), 0);
    assert((await page.locator('.starter-pool').innerText()).includes('<img src=x'));
    await page.unroute('**/data/pokemon.json');
    await page.reload(); await page.waitForSelector('#new-run');
    await page.locator('#run-seed').fill('route-79');
    await page.locator('#new-run button[type=submit]').click();
    await page.locator('[data-node="shop-0"]').click(); await page.locator('#leave-service').click(); await page.waitForSelector('[data-node="zone-1-1"]');
    let release;
    const gate = new Promise(resolve => { release = resolve; });
    await page.route('**/assets/pokemon/**/Idle.png', async route => {
      await gate;
      try { await route.continue(); } catch { /* Destroyed scene may abort its request. */ }
    });
    await page.locator('[data-node="zone-1-1"]').click(); await page.waitForSelector('#leave-run');
    assert(await page.locator('#pause').isDisabled());
    await page.locator('#leave-run').click();
    release();
    await page.waitForLoadState('networkidle');
    assert(await page.locator('#continue-run').isVisible());
    assert.deepEqual(errors, []);
    await context.close();
    const normal = await browser.newContext({ viewport: { width: 1280, height: 768 }, reducedMotion: 'no-preference' });
    const animated = await normal.newPage();
    animated.on('pageerror', error => errors.push(error.message));
    let run;
    for (let seed = 0; seed < 30; seed++) {
      const candidate = enterEncounter(leaveService(enterRoom(createRun(catalog, `animation-${seed}`, .05, CURRENT_EDITION), 'shop-0', catalog), catalog), 'zone-1-1', catalog);
      if (activeUnit(candidate.battle).team === 'ally') { run = candidate; break; }
    }
    assert(run);
    await animated.goto(base); await animated.waitForSelector('#new-run');
    await animated.locator('#run-seed').fill(run.seed);
    await animated.locator('#new-run button[type=submit]').click();
    await animated.locator('[data-node="shop-0"]').click(); await animated.locator('#leave-service').click(); await animated.locator('[data-node="zone-1-1"]').click();
    await animated.waitForFunction(() => document.querySelector('#battle-root')?.dataset.team === 'ally' && !document.querySelector('#pause')?.disabled);
    const actor = activeUnit(run.battle);
    const destination = [...routesFrom(run.battle.board, run.battle.units, actor.id).values()].find(route => route.cost >= 2 && route.cost <= actor.remaining).path.at(-1);
    await animated.locator('#mode-move').click();
    await animated.locator(`[data-cell="${destination.x},${destination.y}"]`).click();
    await animated.locator('#confirm').click();
    const stored = await animated.evaluate(() => JSON.parse(localStorage.getItem('pokemon-tactics.run')).run);
    assert.equal(stored.battle.units.find(unit => unit.id === actor.id).x, destination.x);
    assert.equal(stored.battle.units.find(unit => unit.id === actor.id).y, destination.y);
    assert.equal(await animated.locator('#battle-root').getAttribute('data-busy'), 'true');
    await animated.reload(); await animated.locator('#continue-run').click();
    await animated.waitForFunction(() => document.querySelector('#battle-root')?.dataset.busy === 'false' && !document.querySelector('#pause')?.disabled);
    assert.deepEqual(await animated.evaluate(() => JSON.parse(localStorage.getItem('pokemon-tactics.run')).run), stored);
    assert.deepEqual(errors, []);
    await normal.close();
    fs.mkdirSync(output, { recursive: true });
    fs.writeFileSync(path.join(output, 'lifecycle-results.json'), JSON.stringify({
      url: base, checks: ['Catalog names render as text, not HTML', 'Exit during delayed sprite loading leaves no stale callbacks or browser errors', 'Reload during a normal movement tween resumes the accepted saved position'], consoleErrors: errors,
    }, null, 2) + '\n');
    console.log('PASS catalog text escaping, delayed-loader exit and reload during movement animation');
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
