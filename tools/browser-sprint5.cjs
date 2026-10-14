const { chromium } = require('playwright');
const fs = require('node:fs'), path = require('node:path'), assert = require('node:assert/strict');
const { createRun, enterEncounter, completeEncounter, withBattle, availableNodes } = require('../src/rules/run.ts');
const { activeUnit, applyCommand, chooseTacticalCommand } = require('../src/rules/battle.ts');
const { validateRun, SAVE_KEY } = require('../src/data/run-store.ts');
const catalog = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../public/data/pokemon.json'), 'utf8'));
const base = process.env.TACTICS_URL || 'http://127.0.0.1:5173/';
const output = path.resolve(process.env.TACTICS_QA_DIR || path.resolve(__dirname, '../docs/qa/sprint-5'));
fs.mkdirSync(output, { recursive: true });
const checks = [], errors = [], external = [];
const pass = name => { checks.push({ name, status: 'pass' }); console.log('PASS', name); };
(async () => {
  const browser = await chromium.launch({ channel: process.platform === 'win32' ? 'msedge' : undefined, headless: true });
  try {
    const context = await browser.newContext({ viewport: { width:1440, height:1000 }, reducedMotion:'reduce' });
    const page = await context.newPage();
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
    page.on('request', request => { const url=new URL(request.url()); if(['http:','https:'].includes(url.protocol) && !['127.0.0.1','localhost'].includes(url.hostname)) external.push(url.href); });
    const capture = async name => page.screenshot({ path:path.join(output,`${name}.png`),fullPage:true });
    const saved = async () => page.evaluate(key => JSON.parse(localStorage.getItem(key)).run, SAVE_KEY);
    let run;
    async function readMatches() { const actual=await saved(); assert.deepEqual(actual,run); validateRun(actual,catalog); }
    async function settle() {
      let iterations=0;
      while(run.battle.outcome==='playing' && activeUnit(run.battle)?.team==='enemy') {
        const result=applyCommand(run.battle,chooseTacticalCommand(run.battle)); assert(result.ok,result.reason); run=withBattle(run,result.state); assert(++iterations<40);
      }
      await page.waitForFunction(expected => {
        const root=document.querySelector('#battle-root');
        return root && root.dataset.busy==='false' && root.dataset.round===String(expected.round) && root.dataset.active===String(expected.active ?? '') && root.dataset.outcome===expected.outcome && !document.querySelector('#pause').disabled;
      },{round:run.battle.round,active:activeUnit(run.battle)?.id,outcome:run.battle.outcome});
      await readMatches();
      const units=await page.locator('[data-unit]').evaluateAll(buttons=>buttons.map(button=>({id:Number(button.dataset.unit),hp:Number(button.dataset.hp),x:Number(button.dataset.x),y:Number(button.dataset.y),tp:Number(button.dataset.tp)})));
      assert.deepEqual(units,run.battle.units.map(unit=>({id:unit.id,hp:unit.hp,x:unit.x,y:unit.y,tp:unit.tp})));
    }
    async function start(seed) {
      await page.goto(base); await page.waitForSelector('#new-run');
      await page.locator('#run-seed').fill(seed);
      await page.locator('#new-run button[type="submit"]').click();
      if (await page.locator('#replace-save').isVisible()) await page.locator('#confirm-new').click();
      run=createRun(catalog,seed);
      await page.waitForSelector('[data-node="1-1"]'); await readMatches();
    }
    async function enter(id, keyboard=false) {
      const choice=page.locator(`[data-node="${id}"]`);
      if(keyboard) { await choice.focus(); await page.keyboard.press('Enter'); } else await choice.click();
      run=enterEncounter(run,id,catalog); await settle();
    }
    async function issue(command) {
      assert.equal(activeUnit(run.battle).team,'ally');
      if(command.kind==='finish') {
        await page.locator('#finish-turn').click();
        if(command.facing!==undefined) await page.locator(`#facing-controls [data-facing="${command.facing}"]`).click();
      } else if(command.kind==='move') {
        await page.locator('#mode-move').click();
        await page.locator(`[data-cell="${command.destination.x},${command.destination.y}"]`).click();
      } else {
        await page.locator(`[data-action="${command.actionId || 'basic'}"]`).click();
        const target=run.battle.units.find(unit=>unit.id===command.target);
        await page.locator(`[data-cell="${target.x},${target.y}"]`).click();
      }
      assert(await page.locator('#confirm').isEnabled());
      await page.locator('#confirm').click();
      const result=applyCommand(run.battle,command);assert(result.ok,result.reason);run=withBattle(run,result.state);
      await settle();
    }
    async function fight() {
      let orders=0;
      while(run.battle.outcome==='playing') { await issue(chooseTacticalCommand(run.battle)); assert(++orders<300); }
    }
    await page.goto(base);await page.waitForSelector('#new-run');await page.waitForLoadState('networkidle');
    assert.equal(await page.locator('.starter-pool img').count(),6);
    assert(await page.locator('.starter-pool img').evaluateAll(images=>images.every(image=>image.complete && image.naturalWidth>0)));
    assert.equal(await page.title(),'Ruta de Kanto · Pokémon Tactics');
    await capture('menu-desktop');pass('Menu loads six local species, controls and current metadata');
    await start('route-79');
    assert.equal(await page.locator('[data-node]:enabled').count(),1);
    assert.equal(await page.locator('#route-lines line').count(),16);
    assert.equal(await page.locator('[data-member]').count(),3);
    await capture('route-desktop');pass('Seed creates three distinct members and a connected six-layer branching route');
    await enter('1-1',true);
    assert.equal(await page.locator('#battle-settings').isVisible(),false);
    const sameSpecies=run.battle.units.filter(unit=>unit.speciesId===74);assert.equal(sameSpecies.length,2);
    assert.equal(await page.locator('#game-container canvas').count(),1);
    await capture('battle-desktop');pass('Keyboard opens encounter; repeated allied/enemy species have independent units and local sprites');
    await issue(chooseTacticalCommand(run.battle));
    await page.reload();await page.waitForSelector('#continue-run');await page.locator('#continue-run').click();await settle();
    pass('Reload during combat resumes the exact accepted commands, HP, PT and RNG');
    await page.locator('#leave-run').click();await page.locator('#continue-run').click();await settle();
    pass('Exit/continue disposes the previous scene and resumes without restarting enemies');
    let sawLoss=false;
    for(let floor=1;floor<=6;floor++) {
      if(floor>1) await enter(`${floor}-${floor===6 ? 1 : 2}`);
      await fight();assert.equal(run.battle.outcome,'victory');
      await page.locator('#play-again').click();run=completeEncounter(run);await readMatches();
      if(floor<6) {
        assert.equal(await page.locator('[data-node]:enabled').count(),availableNodes(run).length);
        const hp=await page.locator('[data-member]').evaluateAll(elements=>elements.map(element=>Number(element.dataset.hp)));
        assert.deepEqual(hp,run.roster.map(member=>member.hp));
        if(run.roster.some(member=>member.hp===0) && !sawLoss) {
          sawLoss=true;await capture('route-casualty');
          await page.reload();await page.waitForSelector('#continue-run');await page.locator('#continue-run').click();await readMatches();
          assert.equal(await page.locator('.run-party .lost').count(),run.roster.filter(member=>member.hp===0).length);
          pass('Between-room reload preserves wounds and permanent casualties');
        }
      }
    }
    assert(sawLoss);assert.equal(run.status,'victory');await capture('victory');
    pass('Six real encounters complete via gameplay controls; surviving HP carries over and dead members never redeploy');
    await page.reload();await page.waitForSelector('#continue-run');await page.locator('#continue-run').click();
    assert.equal(await page.locator('h1').innerText(),'Ruta superada');await readMatches();
    pass('Provisional final summary and completed route survive a browser reload');
    await page.locator('#result-menu').click();
    const unchanged=await saved();await page.locator('#new-run button[type="submit"]').click();await page.locator('#cancel-new').click();assert.deepEqual(await saved(),unchanged);
    pass('Preparing and cancelling a new run preserves the existing save');
    await start('route-1');await enter('1-1');await fight();assert.equal(run.battle.outcome,'defeat');await page.locator('#play-again').click();run=completeEncounter(run);await readMatches();
    assert.equal(await page.locator('.run-party .lost').count(),3);await capture('defeat');pass('A real team defeat ends the run with three permanent losses');
    for(const [name,raw] of [['corrupt','{broken'],['incompatible',JSON.stringify({schema:'pokemon-tactics/run',version:999,run:{}})]]) {
      await page.evaluate(({key,raw})=>localStorage.setItem(key,raw),{key:SAVE_KEY,raw});await page.reload();await page.waitForSelector('#discard-save');
      assert.equal(await page.evaluate(key=>localStorage.getItem(key),SAVE_KEY),raw);
      assert(await page.locator('#new-run button[type="submit"]').isDisabled());await capture(`save-${name}`);
      await page.locator('#discard-save').click();assert.equal(await page.evaluate(key=>localStorage.getItem(key),SAVE_KEY),null);
      pass(`${name} save stays untouched until explicit discard, then new run becomes available`);
    }
    await start('mobile-'+'a'.repeat(57));
    await page.setViewportSize({width:390,height:844});await capture('route-mobile');
    assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
    assert(await page.locator('[data-node="1-1"]').isEnabled());
    await page.locator('#run-menu').click();await capture('menu-mobile');
    assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
    pass('Mobile route/menu handle a 64-character seed, readable nodes, native scroll and visible keyboard focus');
    await page.setViewportSize({width:1440,height:1000});
    // Two tabs share storage: a stale run must not overwrite another tab's newer one.
    await page.locator('#continue-run').click();
    const other=await context.newPage();await other.goto(base);await other.waitForSelector('#new-run');await other.locator('#run-seed').fill('other-tab');await other.locator('#new-run button[type="submit"]').click();await other.locator('#confirm-new').click();await other.waitForSelector('[data-node="1-1"]');
    await page.locator('[data-node="1-1"]').click();await page.waitForSelector('#reload-save');
    assert.equal((await saved()).seed,'other-tab');await page.locator('#reload-save').click();await page.waitForSelector('#continue-run');await other.close();
    pass('A stale tab cannot replace the newer run; recovery loads the latest save');
    const quotaContext=await browser.newContext({viewport:{width:390,height:844},reducedMotion:'reduce'});
    await quotaContext.addInitScript(()=>{const original=Storage.prototype.setItem;window.__restoreStorage=()=>{Storage.prototype.setItem=original;};Storage.prototype.setItem=function(){throw new DOMException('quota','QuotaExceededError');};});
    const quotaPage=await quotaContext.newPage();await quotaPage.goto(base);await quotaPage.waitForSelector('#new-run');await quotaPage.locator('#new-run button[type="submit"]').click();await quotaPage.waitForSelector('[data-node="1-1"]');
    assert(await quotaPage.locator('#save-notice').isVisible());
    await quotaPage.evaluate(()=>window.__restoreStorage());await quotaPage.locator('#retry-save').click();assert(await quotaPage.locator('#save-notice').isHidden());
    assert(await quotaPage.evaluate(key=>Boolean(localStorage.getItem(key)),SAVE_KEY));
    await quotaContext.close();pass('Quota failure allows in-memory play, warns honestly and retries storage successfully');
    const blockedContext=await browser.newContext();await blockedContext.addInitScript(()=>Object.defineProperty(window,'localStorage',{get(){throw new DOMException('blocked','SecurityError');}}));
    const blocked=await blockedContext.newPage();await blocked.goto(base);await blocked.waitForSelector('#new-run');await blocked.locator('#new-run button[type="submit"]').click();await blocked.waitForSelector('[data-node="1-1"]');assert(await blocked.locator('#save-notice').isVisible());await blockedContext.close();
    pass('Disabled local storage does not block starting a playable in-memory route');
    const faultContext=await browser.newContext();const faulty=await faultContext.newPage();
    await faulty.route('**/data/pokemon.json',route=>route.fulfill({status:200,contentType:'application/json',body:'[]'}));await faulty.goto(base);await faulty.waitForSelector('#retry');await faulty.unroute('**/data/pokemon.json');await faulty.locator('#retry').click();await faulty.waitForSelector('#new-run');await faultContext.close();
    pass('Invalid local catalog exposes retry and recovers the run menu');
    assert.deepEqual(errors,[]);assert.deepEqual(external,[]);
    pass('Main gameplay run has no browser errors or external resource requests');
    fs.writeFileSync(path.join(output,'browser-results.json'),JSON.stringify({browser:'Microsoft Edge headless (Playwright)',url:base,checks,consoleErrors:errors,externalRequests:external,winningSeed:'route-79',losingSeed:'route-1'},null,2)+'\n');
    console.log(`${checks.length} browser checks passed.`);
  } finally { await browser.close(); }
})().catch(error=>{console.error(error);process.exitCode=1;});
