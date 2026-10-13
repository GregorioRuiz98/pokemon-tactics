const { chromium } = require('playwright');
const fs = require('node:fs'), path = require('node:path'), assert = require('node:assert/strict');
const { createBattle, activeUnit, living, attackPlan, chooseTacticalCommand, applyCommand } = require('../src/rules/battle.ts');
const { routesFrom } = require('../src/rules/movement.ts');
const { pokemonFor } = require('../src/domain/Pokemon.ts');
const catalog = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../public/data/pokemon.json'), 'utf8'));
const output = path.resolve(__dirname, '../docs/qa/sprint-3');
fs.mkdirSync(output, { recursive: true });
const base = process.env.TACTICS_URL || 'http://127.0.0.1:5173/';
const checks = [], errors = [], external = [];
const pass = name => { checks.push({ name, status: 'pass' }); console.log('PASS', name); };
(async () => {
  const browser = await chromium.launch({ channel: process.platform === 'win32' ? 'msedge' : undefined, headless: true });
  try {
    const context = await browser.newContext({ viewport: { width: 1440, height: 1000 }, reducedMotion: 'reduce' });
    const page = await context.newPage();
    page.on('pageerror', e => errors.push(e.message));
    page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
    page.on('request', r => { const u = new URL(r.url()); if (['http:', 'https:'].includes(u.protocol) && !['127.0.0.1', 'localhost'].includes(u.hostname)) external.push(r.url()); });
    const cell = (x, y) => page.locator(`[data-cell="${x},${y}"]`);
    let model = createBattle(catalog);
    function apply(command) { const r = applyCommand(model, command); assert(r.ok, r.reason); model = r.state; }
    async function assertModel() {
      const actual = await page.locator('[data-unit]').evaluateAll(buttons => buttons.map(b => ({
        id: Number(b.dataset.unit), hp: Number(b.dataset.hp), x: Number(b.dataset.x), y: Number(b.dataset.y), team: b.dataset.team,
        tp: Number(b.dataset.tp), status: b.dataset.status, duration: Number(b.dataset.duration), guarded: b.dataset.guarded === 'true',
      })).sort((a,b) => a.id - b.id));
      assert.deepEqual(actual, model.units.map(u => ({ id: u.id, hp: u.hp, x: u.x, y: u.y, team: u.team, tp: u.tp, status: u.status?.kind ?? '', duration: u.status?.remaining ?? 0, guarded: u.guarded })).sort((a,b) => a.id - b.id));
    }
    async function settle() {
      let count = 0;
      while (model.outcome === 'playing' && activeUnit(model)?.team === 'enemy') { apply(chooseTacticalCommand(model)); assert(++count < 30); }
      await page.waitForFunction(expected => {
        const root = document.querySelector('#battle-root');
        return root && root.dataset.busy === 'false' && root.dataset.round === String(expected.round) && root.dataset.outcome === expected.outcome && root.dataset.active === String(expected.active ?? '');
      }, { round: model.round, outcome: model.outcome, active: activeUnit(model)?.id });
      await assertModel();
    }
    async function selectTarget(targetId, actionId = 'basic') {
      await page.locator(`[data-action="${actionId}"]`).click();
      const target = model.units.find(u => u.id === targetId);
      await cell(target.x, target.y).click();
    }
    async function issue(command) {
      assert.equal(activeUnit(model).team, 'ally');
      if (command.kind === 'finish') await page.locator('#finish-turn').click();
      else {
        if (command.kind === 'move') { await page.locator('#mode-move').click(); await cell(command.destination.x, command.destination.y).click(); }
        else await selectTarget(command.target, command.actionId);
        assert(await page.locator('#confirm').isEnabled());
        await page.locator('#confirm').click();
      }
      apply(command);
      await settle();
    }
    async function openOptions() { if (!(await page.locator('#game-options').evaluate(e => e.open))) await page.locator('#game-options > summary').click(); }
    async function restart(seed = 'kanto-001', variance = 0.05, composition = 'starters') {
      await openOptions();
      await page.locator('#seed').fill(seed);
      await page.locator('#variance').selectOption(String(variance));
      await page.locator('#composition').selectOption(composition);
      await page.locator('#restart').click();
      model = createBattle(catalog, seed, variance, composition);
      await settle();
    }
    async function autoBattle(passive = false) {
      let count = 0;
      while (model.outcome === 'playing' && count++ < 160) await issue(passive ? { kind: 'finish' } : chooseTacticalCommand(model));
      assert.notEqual(model.outcome, 'playing');
      return structuredClone(model);
    }
    async function geometry() {
      assert.equal(await page.evaluate(() => document.documentElement.scrollWidth > innerWidth), false);
      const overlap = await page.evaluate(() => {
        const grid = document.querySelector('#board-grid').getBoundingClientRect();
        return ['.actor-hud', '.orders-hud', '.target-hud', '.initiative-strip', '.game-topbar'].filter(selector => {
          const box = document.querySelector(selector).getBoundingClientRect();
          return Math.min(grid.right,box.right) - Math.max(grid.left,box.left) > 1 && Math.min(grid.bottom,box.bottom) - Math.max(grid.top,box.top) > 1;
        });
      });
      assert.deepEqual(overlap, [], 'HUD must leave all playable cells free');
    }
    await page.goto(base, { waitUntil: 'networkidle' });
    await settle();
    assert.equal(await page.getByRole('gridcell').count(), 64);
    assert.equal(await page.locator('#initiative li').count(), 6);
    assert.equal(await page.locator('[data-team="ally"][data-unit]').count(), 3);
    assert.equal(await page.locator('[data-action]').count(), 3);
    assert((await page.locator('#actor-tp').innerText()).includes('3/5'));
    pass('Local battle loads six units, one basic and two skills; activation grants exactly one PT');
    await geometry();
    await page.screenshot({ path: path.join(output, 'desktop.png'), fullPage: true });
    pass('Desktop HUD remains integrated and leaves every board cell free');
    await page.locator('[data-inspect="1"]').click();
    assert.equal(await page.locator('#actor-name').innerText(), 'Charmander');
    assert.equal(await page.locator('#inspect-name').innerText(), 'Bulbasaur');
    pass('Inspection shows another Pokémon without changing the active turn');
    const target = living(model).find(u => u.team === 'enemy' && attackPlan(model, u.id, undefined, 'flamethrower').ok);
    assert(target);
    const forecast = attackPlan(model, target.id, undefined, 'flamethrower');
    await selectTarget(target.id, 'flamethrower');
    assert.equal(await page.locator('#forecast-damage').innerText(), String(forecast.damage));
    assert.equal(await page.locator('#forecast-accuracy').innerText(), `${forecast.accuracy} %`);
    assert((await page.locator('#forecast-effect').innerText()).includes(`eficacia ×${forecast.multiplier}`));
    assert((await page.locator('#forecast-effect').innerText()).includes('3 PT'));
    await geometry();
    await assertModel();
    await page.screenshot({ path: path.join(output, 'skill-preview.png'), fullPage: true });
    await page.locator('#confirm').focus();
    await page.keyboard.press('Escape');
    assert.equal(await page.locator('#confirm').isEnabled(), false);
    await assertModel();
    pass('Typed skill forecast matches rules and Escape preserves HP, PT, action and RNG-dependent replay');
    await issue({ kind: 'attack', target: target.id, actionId: 'flamethrower' });
    assert.equal(activeUnit(model).tp, 0);
    assert.equal(await page.locator('[data-action="flamethrower"]').isEnabled(), false);
    assert.equal(await page.locator('#mode-move').isEnabled(), true);
    await issue({ kind: 'move', destination: { x: 4, y: 6 } });
    assert.equal(await page.locator('#mode-move').isEnabled(), false);
    pass('Skill spends PT/action once; movement remains available after acting');
    await restart();
    await page.locator('#mode-move').click();
    await cell(3,6).focus(); await page.keyboard.press('ArrowRight');
    assert.equal(await page.evaluate(() => document.activeElement.dataset.cell), '4,6');
    assert.equal(await cell(4,6).evaluate(e => getComputedStyle(e).outlineWidth), '3px');
    await page.keyboard.press('Enter'); await page.keyboard.press('Escape'); await assertModel();
    await openOptions(); await page.keyboard.press('Escape');
    assert.equal(await page.evaluate(() => document.activeElement.matches('#game-options > summary')), true);
    pass('Keyboard grid, cancel and Options preserve visible focus');
    while (activeUnit(model)?.id !== 7) await issue({ kind: 'finish' });
    await issue({ kind: 'attack', target: 7, actionId: 'cover' });
    assert(model.units.find(u => u.id === 7).guarded);
    assert((await page.locator('#actor-status').innerText()).includes('Protegido'));
    await page.screenshot({ path: path.join(output, 'guard.png'), fullPage: true });
    pass('Support skill accepts a friendly target and displays its protection and remaining PT');
    await restart('control-1', 0.05, 'mixed');
    assert.equal(activeUnit(model).id, 25);
    assert.equal(await page.locator('[data-unit="25"]').getAttribute('data-team'), 'ally');
    const routes = routesFrom(model.board, living(model), 25);
    const approach = [...routes.values()].filter(r => r.cost > 0 && r.cost <= activeUnit(model).remaining).sort((a,b) => a.cost-b.cost).flatMap(route => living(model).filter(u => u.team === 'enemy').map(unit => ({ route, unit }))).find(({route,unit}) => attackPlan(model, unit.id, route.path.at(-1), 'thunder-wave').ok);
    assert(approach);
    await issue({ kind: 'move', destination: approach.route.path.at(-1) });
    await selectTarget(approach.unit.id, 'thunder-wave');
    assert.equal(await page.locator('#forecast-accuracy').innerText(), '90 %');
    assert((await page.locator('#order-detail').innerText()).includes('Parálisis 100 % al acertar, 3 activaciones'));
    await page.locator('#cancel').click(); await assertModel();
    await issue({ kind: 'attack', target: approach.unit.id, actionId: 'thunder-wave' });
    assert(model.units.find(u => u.id === approach.unit.id).status);
    await page.screenshot({ path: path.join(output, 'paralysis.png'), fullPage: true });
    pass('Second composition plays movement then status skill; chance, duration and applied paralysis match the model');
    await restart();
    const first = await autoBattle();
    assert.equal(first.outcome, 'victory');
    assert.equal(await page.locator('#finish-turn').isEnabled(), false);
    assert.equal(await page.locator('.tile.team-enemy').count(), 0);
    await page.screenshot({ path: path.join(output, 'victory.png'), fullPage: true });
    pass('A complete battle with typed skills reaches victory without stalled activations');
    await restart(); assert.deepEqual(await autoBattle(), first);
    pass('Same seed and orders reproduce HP, PT, status, initiative, result and log exactly');
    await restart('portfolio', 0.1);
    const defeat = await autoBattle(true);
    assert.equal(defeat.outcome, 'defeat');
    assert.equal(await page.locator('.tile.team-ally').count(), 0);
    await page.screenshot({ path: path.join(output, 'defeat.png'), fullPage: true });
    pass('Passive play reaches defeat; poison/burn casualties and ordinary damage cannot block the queue');
    await restart('control-1', 0.05, 'mixed');
    const second = await autoBattle();
    pass('Alternative composition completes a full battle using the other three species');
    await restart();
    await selectTarget(living(model).find(u => u.team === 'enemy' && attackPlan(model,u.id,undefined,'will-o-wisp').ok).id, 'will-o-wisp');
    for (const viewport of [{width:1280,height:768},{width:900,height:1000},{width:390,height:844}]) { await page.setViewportSize(viewport); await geometry(); }
    await page.screenshot({ path: path.join(output, 'mobile.png'), fullPage: true });
    await page.locator('#cancel').click();
    await issue({ kind: 'attack', target: living(model).find(u => u.team === 'enemy' && attackPlan(model,u.id).ok).id });
    pass('Skills, long descriptions and orders fit intermediate/mobile layouts with a playable confirmation flow');
    await openOptions();
    await page.locator('.battle-nav a[href="?view=training"]').click();
    await page.waitForLoadState('networkidle');
    await page.waitForFunction(() => !!document.querySelector('#reset') && !document.querySelector('#reset').disabled);
    await page.goto(new URL('?view=camp',base).href, { waitUntil: 'networkidle' });
    await page.locator('#load-status').waitFor({state:'hidden'});
    assert.equal(await page.locator('[data-species]').count(), 6);
    pass('Training and camp remain reachable');
    assert.deepEqual(errors, []); assert.deepEqual(external, []);
    pass('Normal play emits no console/JavaScript errors or remote requests');
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
    fs.writeFileSync(path.join(output,'browser-results.json'), JSON.stringify({ browser:'Microsoft Edge headless (Playwright)', url:base, checks, consoleErrors:errors, externalRequests:external, victoryRound:first.round, defeatRound:defeat.round, secondComposition:{ outcome:second.outcome, round:second.round } },null,2));
    console.log(`${checks.length} browser checks passed.`);
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
