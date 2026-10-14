const { chromium } = require('playwright');
const fs = require('node:fs'), path = require('node:path'), assert = require('node:assert/strict');
const { createBattle, activeUnit, living, attackPlan, chooseTacticalCommand, applyCommand } = require('../src/rules/battle.ts');
const { routesFrom } = require('../src/rules/movement.ts');
const { pokemonFor } = require('../src/domain/Pokemon.ts');
const catalog = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../public/data/pokemon.json'), 'utf8'));
const output = path.resolve(process.env.TACTICS_QA_DIR || path.resolve(__dirname, '../docs/qa/sprint-6/combat'));
fs.mkdirSync(output, { recursive: true });
const base = new URL('?view=battle', process.env.TACTICS_URL || 'http://127.0.0.1:5173/').href;
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
        tp: Number(b.dataset.tp), status: b.dataset.status, duration: Number(b.dataset.duration), guarded: b.dataset.guarded === 'true', facing:Number(b.dataset.facing), profile:b.dataset.profile, remaining:Number(b.dataset.remaining),
      })).sort((a,b) => a.id - b.id));
      assert.deepEqual(JSON.parse(await page.locator('#battle-root').getAttribute('data-fields')), model.fields);
      assert.deepEqual(actual, model.units.map(u => ({ id: u.id, hp: u.hp, x: u.x, y: u.y, team: u.team, tp: u.tp, status: u.status?.kind ?? '', duration: u.status?.remaining ?? 0, guarded: u.guarded, facing:u.facing, profile:u.profile, remaining:u.remaining })).sort((a,b) => a.id - b.id));
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
      if (command.kind === 'finish') { await page.locator('#finish-turn').click(); if (command.facing !== undefined) await page.locator(`#facing-controls [data-facing="${command.facing}"]`).click(); await page.locator('#confirm').click(); }
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
    async function prepareArea() {
      const actor = activeUnit(model);
      assert.equal(actor.id, 4);
      let target = living(model).find(unit => unit.team !== actor.team && attackPlan(model,unit.id,undefined,'flamethrower').ok);
      if (!target) {
        const approach = [...routesFrom(model.board,living(model),actor.id).values()].filter(route => route.cost > 0 && route.cost <= actor.remaining).sort((a,b) => a.cost-b.cost).flatMap(route => living(model).filter(unit => unit.team !== actor.team).map(unit => ({route,unit}))).find(({route,unit}) => attackPlan(model,unit.id,route.path.at(-1),'flamethrower').ok);
        assert(approach, 'An area needs a legal approach first');
        await issue({kind:'move',destination:approach.route.path.at(-1)});
        target = approach.unit;
      }
      return target;
    }
    await page.goto(base, { waitUntil:'networkidle' });
    await settle();
    assert.equal(await page.getByRole('gridcell').count(),64);
    assert.equal(await page.locator('.facing-marker').count(),6);
    assert.equal(await page.locator('[data-action]').count(),3);
    await geometry();
    pass('Tactical board, profiles and six orientation arrows load without covering cells');
    const originalActor = activeUnit(model).id;
    await page.locator('#finish-turn').click();
    assert.equal(await page.evaluate(() => !!document.activeElement.closest('#facing-controls')),true);
    await page.locator('#facing-controls [data-facing="2"]').click();
    assert.equal(await page.locator('#facing-controls [data-facing="2"]').getAttribute('aria-pressed'),'true');
    await assertModel();
    await page.screenshot({path:path.join(output,'facing-preview.png'),fullPage:true});
    await page.keyboard.press('Escape');
    assert.equal(await page.locator('#facing-controls').isVisible(),false);
    await assertModel();
    pass('Final facing is previewed and can be cancelled without closing the turn or spending RNG');
    await issue({kind:'finish',facing:4});
    assert.equal(model.units.find(u=>u.id===originalActor).facing,4);
    assert.equal(await page.locator(`[data-unit="${originalActor}"]`).getAttribute('data-facing'),'4');
    pass('Confirmed facing persists while other units act and the next activation receives focus');
    await restart();
    const areaTarget=await prepareArea();
    assert(areaTarget);
    const forecast=attackPlan(model,areaTarget.id,undefined,'flamethrower');
    await selectTarget(areaTarget.id,'flamethrower');
    assert.equal(await page.locator('#forecast-damage').innerText(),String(forecast.damage));
    assert.equal(await page.locator('#forecast-accuracy').innerText(),`${forecast.accuracy} %`);
    assert((await page.locator('#forecast-effect').innerText()).includes(forecast.side==='front'?'Frente':forecast.side==='flank'?'Flanco':'Espalda'));
    assert.equal(await page.locator('.effect-area').count(),forecast.tiles.length);
    assert.equal(await page.locator('#area-forecast li').count(),forecast.hits.length+1);
    await assertModel(); await geometry();
    await page.screenshot({path:path.join(output,'area-preview.png'),fullPage:true});
    await page.locator('#cancel').click(); await assertModel();
    pass('Area, per-target accuracy, positional side and collateral preview match pure rules');
    await issue({kind:'attack',target:areaTarget.id,actionId:'flamethrower'});
    assert.equal(model.fields.length,forecast.embers.length);
    assert.equal(await page.locator('.ember-tile').count(),model.fields.length);
    await page.screenshot({path:path.join(output,'embers.png'),fullPage:true});
    pass('Confirmed area affects each unit once, spends PT once and paints legal ember tiles');
    let crossing=null;
    for(let attempt=0;attempt<5&&!crossing;attempt++) {
      await restart(`ally-path-${attempt}`);
      for(let turn=0;turn<6&&model.outcome==='playing'&&!crossing;turn++){
        const actor=activeUnit(model);
        crossing=[...routesFrom(model.board,living(model),actor.id).values()].filter(r=>r.cost>0&&r.cost<=actor.remaining).sort((a,b)=>a.cost-b.cost).find(r=>r.path.slice(1,-1).some(p=>living(model).some(u=>u.id!==actor.id&&u.team===actor.team&&u.x===p.x&&u.y===p.y)));
        if(!crossing) await issue({kind:'finish',facing:4});
      }
    }
    assert(crossing,'Need a live allied transit route');
    const destination=crossing.path.at(-1);
    await page.locator('#mode-move').click(); await cell(destination.x,destination.y).click();
    await page.screenshot({path:path.join(output,'allied-transit.png'),fullPage:true});
    await assertModel();
    await issue({kind:'move',destination});
    assert.equal(new Set(living(model).map(u=>`${u.x},${u.y}`)).size,living(model).length);
    pass('A real route crosses allied sprites and ends on a free square at its exact terrain cost');
    await restart('control-1',0.05,'mixed');
    await issue({kind:'finish',facing:4});
    assert.equal(activeUnit(model).id,12);
    await issue({kind:'move',destination:{x:4,y:4}});
    assert.equal(model.board[activeUnit(model).y][activeUnit(model).x],3);
    assert.equal(await page.locator('[data-unit="12"]').getAttribute('data-profile'),'fly');
    await page.screenshot({path:path.join(output,'water.png'),fullPage:true});
    pass('Flying movement crosses the pond using its own costs while occupancy remains legal');
    await restart();
    await cell(3,6).focus(); await page.keyboard.press('ArrowRight');
    assert.equal(await page.evaluate(()=>document.activeElement.dataset.cell),'4,6');
    await page.keyboard.press('Enter'); await page.keyboard.press('Escape'); await assertModel();
    await openOptions(); await page.keyboard.press('Escape');
    assert.equal(await page.evaluate(()=>document.activeElement.matches('#game-options > summary')),true);
    pass('Grid, cancellation and menu support keyboard focus');
    const first=await autoBattle();
    assert.equal(first.outcome,'victory');
    assert.equal(await page.locator('.tile.team-enemy').count(),0);
    await page.screenshot({path:path.join(output,'victory.png'),fullPage:true});
    pass('Full battle reaches victory and clears defeated units without stalled rounds');
    await restart(); assert.deepEqual(await autoBattle(),first);
    pass('Same seed and commands replay positions, orientations, fields, HP, PT and status exactly');
    await restart('portfolio',0.1);
    const defeat=await autoBattle(true);
    assert.equal(defeat.outcome,'defeat');
    await page.screenshot({path:path.join(output,'defeat.png'),fullPage:true});
    pass('Passive turns reach defeat with orientation and terrain effects resolving normally');
    await restart('kanto-001',0.05,'mixed');
    let pushSeen=false,pushResolved=false,steps=0;
    while(model.outcome==='playing'&&steps++<160){
      const command=chooseTacticalCommand(model);
      const plan=command.kind==='attack'?attackPlan(model,command.target,undefined,command.actionId):null;
      if(plan?.ok&&plan.push){
        pushSeen=true;
        await selectTarget(command.target,command.actionId);
        assert((await page.locator('#order-detail').innerText()).includes('empuje a'));
        assert.equal(await page.locator('.push-destination').count(),1);
        await page.screenshot({path:path.join(output,'push-preview.png'),fullPage:true});
        const predicted=applyCommand(model,command);
        pushResolved ||= predicted.ok&&predicted.hits.some(hit=>hit.push);
      }
      await issue(command);
    }
    const second=structuredClone(model);
    assert.notEqual(second.outcome,'playing'); assert(pushSeen); assert(pushResolved);
    pass('Alternative composition previews and resolves a real push without occupied destinations');
    await restart();
    const previewTarget=await prepareArea();
    await selectTarget(previewTarget.id,'flamethrower');
    for(const viewport of [{width:1440,height:1000},{width:1280,height:768},{width:900,height:1000},{width:390,height:844}]){await page.setViewportSize(viewport);await geometry();}
    await page.screenshot({path:path.join(output,'mobile-area.png'),fullPage:true});
    await page.locator('#cancel').click();
    await page.locator('#finish-turn').click(); await page.locator('#facing-controls [data-facing="6"]').click(); await geometry();
    await page.screenshot({path:path.join(output,'mobile-facing.png'),fullPage:true});
    await page.locator('#confirm').click(); apply({kind:'finish',facing:6});await settle();
    pass('Long area previews and final-facing controls fit desktop, short and mobile windows');
    await openOptions();await page.locator('.battle-nav a[href="?view=training"]').click();
    await page.waitForLoadState('networkidle');await page.waitForFunction(()=>!!document.querySelector('#reset')&&!document.querySelector('#reset').disabled);
    await page.goto(new URL('?view=camp',base).href,{waitUntil:'networkidle'});await page.locator('#load-status').waitFor({state:'hidden'});
    assert.equal(await page.locator('[data-species]').count(),6);
    pass('Training and camp remain available');
    assert.deepEqual(errors,[]);assert.deepEqual(external,[]);
    pass('Normal play has no JavaScript errors or remote asset requests');
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
      await fp.locator('#confirm').click();
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
