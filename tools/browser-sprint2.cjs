const { chromium } = require('playwright');
const fs = require('node:fs'),
  path = require('node:path'),
  assert = require('node:assert/strict');
const {
  createBattle,
  activeUnit,
  chooseTacticalCommand,
  applyCommand,
} = require('../src/rules/battle.ts');
const catalog = JSON.parse(
  fs.readFileSync(
    path.resolve(__dirname, '../public/data/pokemon.json'),
    'utf8',
  ),
);
const output = path.resolve(__dirname, '../docs/qa/sprint-2');
fs.mkdirSync(output, { recursive: true });
const base = process.env.TACTICS_URL || 'http://127.0.0.1:5173/';
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
        reducedMotion: 'reduce',
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
        !['127.0.0.1', 'localhost'].includes(u.hostname)
      )
        external.push(r.url());
    });
    const cell = (x, y) => page.locator(`[data-cell="${x},${y}"]`);
    let model = createBattle(catalog);
    const apply = (c) => {
      const r = applyCommand(model, c);
      assert(r.ok, r.reason);
      model = r.state;
    };
    async function assertModel() {
      const actual = await page.locator('[data-unit]').evaluateAll((buttons) =>
        buttons.map((b) => ({
          id: Number(b.dataset.unit),
          hp: Number(b.dataset.hp),
          x: Number(b.dataset.x),
          y: Number(b.dataset.y),
        })),
      );
      assert.deepEqual(
        actual,
        model.units.map((u) => ({ id: u.id, hp: u.hp, x: u.x, y: u.y })),
      );
    }
    async function settle() {
      let count = 0;
      while (
        model.outcome === 'playing' &&
        activeUnit(model)?.team === 'enemy'
      ) {
        apply(chooseTacticalCommand(model));
        assert(++count < 30);
      }
      await page.waitForFunction(
        (expected) => {
          const root = document.querySelector('#battle-root');
          return (
            root &&
            root.dataset.busy === 'false' &&
            root.dataset.round === String(expected.round) &&
            root.dataset.outcome === expected.outcome &&
            root.dataset.active === String(expected.active ?? '')
          );
        },
        {
          round: model.round,
          outcome: model.outcome,
          active: activeUnit(model)?.id,
        },
      );
      await assertModel();
    }
    async function issue(c) {
      assert.equal(activeUnit(model).team, 'ally');
      if (c.kind === 'finish') {
        await page.locator('#finish-turn').click();
      } else {
        if (c.kind === 'move') {
          await page.locator('#mode-move').click();
          await cell(c.destination.x, c.destination.y).click();
        } else {
          const t = model.units.find((u) => u.id === c.target);
          await cell(t.x, t.y).click();
        }
        assert.equal(await page.locator('#confirm').isEnabled(), true);
        await page.locator('#confirm').click();
      }
      apply(c);
      await settle();
    }
    async function restart(seed = 'kanto-001', variance = 0.05) {
      await page.locator('#seed').fill(seed);
      await page.locator('#variance').selectOption(String(variance));
      await page.locator('#restart').click();
      model = createBattle(catalog, seed, variance);
      await settle();
    }
    async function autoBattle(passive = false) {
      let turns = 0;
      while (model.outcome === 'playing' && turns < 160) {
        await issue(
          passive ? { kind: 'finish' } : chooseTacticalCommand(model),
        );
        turns++;
      }
      assert.notEqual(model.outcome, 'playing');
      return structuredClone(model);
    }
    await page.goto(base, { waitUntil: 'domcontentloaded' });
    await page.locator('#battle-root').waitFor();
    assert.equal(await page.locator('#confirm').isEnabled(), false);
    assert.equal(await page.locator('#finish-turn').isEnabled(), false);
    pass('Enemy activations disable player orders');
    await settle();
    assert.equal(await page.getByRole('gridcell').count(), 64);
    assert.equal(await page.locator('#initiative li').count(), 6);
    assert.equal(
      await page.locator('[data-unit][data-team="ally"]').count(),
      3,
    );
    assert.equal(
      await page.locator('[data-unit][data-team="enemy"]').count(),
      3,
    );
    pass('Three versus three loads with HP, teams and six initiative entries');
    const initialInitiative = await page
      .locator('#initiative button')
      .evaluateAll((bs) =>
        bs.map(
          (b) => b.getAttribute('aria-label').match(/iniciativa ([\d.]+)/)[1],
        ),
      );
    await page.locator('[data-unit="1"]').click();
    assert.equal(await page.locator('#inspect-name').innerText(), 'Bulbasaur');
    assert.equal(await page.locator('#actor-name').innerText(), 'Charmander');
    pass('Inspecting another unit never transfers the active turn');
    await cell(3, 4).click();
    assert((await page.locator('#order-detail').innerText()).includes('17 PS'));
    await page.locator('#confirm').focus();
    await page.keyboard.press('Escape');
    await assertModel();
    assert.equal(await page.locator('#confirm').isEnabled(), false);
    pass('Attack preview and Escape cancellation preserve HP and resources');
    await page.locator('#mode-move').click();
    await cell(2, 2).click();
    assert((await page.locator('#feedback').innerText()).includes('bloquea'));
    await cell(7, 0).click();
    assert(
      (await page.locator('#feedback').innerText()).includes('No hay camino'),
    );
    await assertModel();
    pass('Blocked and unreachable movement reject without state changes');
    await issue({ kind: 'attack', target: 25 });
    assert.equal(await page.locator('#mode-attack').isEnabled(), false);
    assert.equal(await page.locator('#mode-move').isEnabled(), true);
    await issue({ kind: 'move', destination: { x: 4, y: 6 } });
    assert.equal(await page.locator('#mode-move').isEnabled(), false);
    assert.equal(await page.locator('#mode-attack').isEnabled(), false);
    assert.equal(await page.locator('#finish-turn').isEnabled(), true);
    assert.deepEqual(
      await page
        .locator('#initiative button')
        .evaluateAll((bs) =>
          bs.map(
            (b) => b.getAttribute('aria-label').match(/iniciativa ([\d.]+)/)[1],
          ),
        ),
      initialInitiative,
    );
    pass(
      'Attack then movement works once each and keeps the current initiative rolls',
    );
    await issue({ kind: 'finish' });
    const move = chooseTacticalCommand(model);
    assert.equal(move.kind, 'move');
    await issue(move);
    const attack = chooseTacticalCommand(model);
    assert.equal(attack.kind, 'attack');
    await issue(attack);
    pass('Movement then attack also works within one activation');
    await restart();
    await page.screenshot({
      path: path.join(output, 'desktop.png'),
      fullPage: true,
    });
    await page.locator('[data-unit="25"]').click();
    assert.equal(await page.locator('#inspect-team').innerText(), 'Enemigo');
    await page.locator('#mode-attack').click();
    await cell(3, 4).click();
    await page.screenshot({
      path: path.join(output, 'attack-preview.png'),
      fullPage: true,
    });
    await page.locator('#cancel').click();
    await page.locator('#mode-move').click();
    await cell(3, 6).focus();
    await page.keyboard.press('ArrowRight');
    assert.equal(
      await page.evaluate(() => document.activeElement.dataset.cell),
      '4,6',
    );
    assert.equal(
      await cell(4, 6).evaluate((e) => getComputedStyle(e).outlineWidth),
      '3px',
    );
    await page.keyboard.press('Enter');
    assert.equal(await page.locator('#confirm').isEnabled(), true);
    await page.keyboard.press('Escape');
    await assertModel();
    pass(
      'Keyboard grid, visible focus, Enter and Escape complete the preview flow',
    );
    const first = await autoBattle();
    assert.equal(first.outcome, 'victory');
    await page.locator('#battle-result').waitFor({ state: 'visible' });
    assert.equal(await page.locator('#confirm').isEnabled(), false);
    assert.equal(await page.locator('#finish-turn').isEnabled(), false);
    assert(
      (await page.locator('#result-title').innerText()).includes('Victoria'),
    );
    assert.equal(await page.locator('.tile.team-enemy').count(), 0);
    await page.screenshot({
      path: path.join(output, 'victory.png'),
      fullPage: true,
    });
    pass(
      'A complete seeded battle reaches victory; defeated enemies leave cells and orders lock',
    );
    await restart();
    const replay = await autoBattle();
    assert.deepEqual(replay, first);
    pass(
      'Restarting the same seed reproduces the complete battle outcome and log',
    );
    await restart('portfolio', 0.1);
    const defeat = await autoBattle(true);
    assert.equal(defeat.outcome, 'defeat');
    assert.equal(await page.locator('.tile.team-ally').count(), 0);
    assert.equal(await page.locator('#finish-turn').isEnabled(), false);
    await page.screenshot({
      path: path.join(output, 'defeat.png'),
      fullPage: true,
    });
    pass(
      'Waiting through player activations reaches defeat without stalled rounds',
    );
    await page.locator('#play-again').click();
    model = createBattle(catalog, 'portfolio', 0.1);
    await settle();
    assert.equal(model.outcome, 'playing');
    assert.equal(await page.locator('#battle-result').isVisible(), false);
    pass('The result screen can restart a playable battle');
    await page.locator('#seed').fill('old-seed');
    await page.locator('#restart').click();
    await page.locator('#seed').fill('new-seed');
    await page.locator('#restart').click();
    model = createBattle(catalog, 'new-seed', 0.1);
    await settle();
    pass('Restarting during enemy thinking cancels obsolete scheduled turns');
    await restart();
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
    await page.screenshot({
      path: path.join(output, 'mobile.png'),
      fullPage: true,
    });
    await issue({ kind: 'attack', target: 25 });
    pass(
      'Intermediate and narrow layouts fit; an attack can be completed on the narrow layout',
    );
    await page.locator('.battle-nav a[href="?view=training"]').click();
    await page.waitForLoadState('networkidle');
    await page.waitForFunction(
      () =>
        !!document.querySelector('#reset') &&
        !document.querySelector('#reset').disabled,
    );
    assert.equal(await page.locator('[data-species]').count(), 0);
    assert.equal(await page.locator('[data-unit]').count(), 6);
    await page.goto(new URL('?view=camp', base).href, {
      waitUntil: 'networkidle',
    });
    await page.locator('#load-status').waitFor({ state: 'hidden' });
    assert.equal(await page.locator('[data-species]').count(), 6);
    pass('Movement trial and camp remain reachable as separate prototypes');
    assert.deepEqual(errors, []);
    assert.deepEqual(external, []);
    pass(
      'Successful combat and prototype visits emit no JavaScript/console errors or external requests',
    );
    const normal = await browser.newContext({
        viewport: { width: 1440, height: 1000 },
      }),
      np = await normal.newPage();
    await np.goto(base, { waitUntil: 'networkidle' });
    await np.waitForFunction(
      () =>
        document.querySelector('#battle-root')?.dataset.team === 'ally' &&
        document.querySelector('#battle-root').dataset.busy === 'false',
    );
    await np.locator('#mode-move').click();
    await np.locator('[data-cell="4,6"]').click();
    await np.locator('#confirm').click();
    assert.equal(await np.locator('#finish-turn').isEnabled(), false);
    await np.waitForFunction(
      () => document.querySelector('#battle-root').dataset.busy === 'false',
    );
    assert.equal(
      await np.locator('[data-unit="4"]').getAttribute('data-x'),
      '4',
    );
    await np.locator('#pause').click();
    const still1 = await np.locator('canvas').screenshot();
    await np.waitForTimeout(180);
    const still2 = await np.locator('canvas').screenshot();
    assert(still1.equals(still2));
    await np.locator('#pause').click();
    pass(
      'Animated movement locks orders and resting animations support pause/resume',
    );
    await normal.close();
    const faults = await browser.newContext({
        viewport: { width: 1440, height: 1000 },
        reducedMotion: 'reduce',
      }),
      fp = await faults.newPage();
    const faultErrors = [];
    fp.on('pageerror', (e) => faultErrors.push(e.message));
    await fp.route('**/assets/pokemon/*/*.png', async (r) => {
      await new Promise((resolve) => setTimeout(resolve, 600));
      await r.continue();
    });
    await fp.goto(base, { waitUntil: 'domcontentloaded' });
    await fp.locator('#resource-status').waitFor();
    assert.equal(await fp.locator('#restart').isEnabled(), false);
    await fp.screenshot({
      path: path.join(output, 'loading.png'),
      fullPage: true,
    });
    await fp.waitForFunction(
      () =>
        document.querySelector('#battle-root')?.dataset.team === 'ally' &&
        document.querySelector('#battle-root').dataset.busy === 'false',
    );
    await fp.unroute('**/assets/pokemon/*/*.png');
    pass('Slow loading gives progress and keeps commands disabled');
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
        document.querySelector('#battle-root')?.dataset.team === 'ally' &&
        document.querySelector('#battle-root').dataset.busy === 'false',
    );
    pass('Invalid/empty catalogue exposes a retry and recovers combat');
    await fp.route('**/assets/pokemon/1/Idle.png', (r) => r.abort());
    await fp.reload({ waitUntil: 'networkidle' });
    await fp.waitForFunction(
      () =>
        document.querySelector('#battle-root')?.dataset.team === 'ally' &&
        document.querySelector('#battle-root').dataset.busy === 'false',
    );
    assert(
      (await fp.locator('#resource-status').innerText()).includes('Faltan'),
    );
    while (
      (await fp.locator('#battle-root').getAttribute('data-active')) !== '1'
    ) {
      await fp.locator('#finish-turn').click();
      await fp.waitForFunction(
        () =>
          document.querySelector('#battle-root')?.dataset.team === 'ally' &&
          document.querySelector('#battle-root').dataset.busy === 'false',
      );
    }
    await fp.locator('#mode-move').click();
    await fp.locator('[data-cell="0,6"]').click();
    await fp.locator('#confirm').click();
    await fp.waitForFunction(
      () => document.querySelector('[data-unit="1"]').dataset.x === '0',
    );
    await fp.screenshot({
      path: path.join(output, 'partial.png'),
      fullPage: true,
    });
    await fp.unroute('**/assets/pokemon/1/Idle.png');
    await fp.getByRole('button', { name: 'Volver a cargar' }).click();
    await fp.locator('#resource-status').waitFor({ state: 'hidden' });
    assert.deepEqual(faultErrors, []);
    pass(
      'A missing sprite becomes a movable marker; reload recovers it without JS errors',
    );
    await faults.close();
    fs.writeFileSync(
      path.join(output, 'browser-results.json'),
      JSON.stringify(
        {
          browser: 'Microsoft Edge headless (Playwright)',
          url: base,
          checks,
          consoleErrors: errors,
          externalRequests: external,
          victoryRound: first.round,
          defeatRound: defeat.round,
        },
        null,
        2,
      ) + '\n',
    );
    console.log(`Completed ${checks.length} combat browser checks`);
  } finally {
    await browser.close();
  }
})().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
