const { chromium } = require('playwright');
const fs = require('node:fs'), path = require('node:path'), assert = require('node:assert/strict');
const { createRun, enterRoom, leaveService, enterEncounter, withBattle, completeEncounter, performRunEvent, migrateLegacyRun } = require('../src/rules/run.ts');
const { createRun: legacyRun, enterEncounter: legacyEnter } = require('../src/rules/legacy-run.ts');
const { activeUnit, applyCommand, chooseTacticalCommand } = require('../src/rules/battle.ts');
const { validateRun, SAVE_KEY, SAVE_VERSION, LEGACY_BACKUP_KEY } = require('../src/data/run-store.ts');
const catalog = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../public/data/pokemon.json'), 'utf8'));
const base = process.env.TACTICS_URL || 'http://127.0.0.1:5173/';
const output = path.resolve(process.env.TACTICS_QA_DIR || path.resolve(__dirname, '../docs/qa/sprint-6'));
fs.mkdirSync(output, { recursive: true });
const checks = [], errors = [], external = [];
const pass = name => { checks.push({ name, status: 'pass' }); console.log('PASS', name); };
(async () => {
  const browser = await chromium.launch({ channel: process.platform === 'win32' ? 'msedge' : undefined, headless: true });
  try {
    const context = await browser.newContext({ viewport: { width:1440, height:1000 }, reducedMotion:'reduce' });
    const page = await context.newPage();
    page.on('pageerror', error => errors.push(error.message));
    page.on('console', message => { if(message.type()==='error') errors.push(message.text()); });
    page.on('request', request => { const url=new URL(request.url());if(['http:','https:'].includes(url.protocol)&&!['127.0.0.1','localhost'].includes(url.hostname))external.push(url.href); });
    const capture = name => page.screenshot({path:path.join(output,`${name}.png`),fullPage:true});
    const saved = () => page.evaluate(key=>JSON.parse(localStorage.getItem(key)).run,SAVE_KEY);
    let run;
    async function matches() { const actual=await saved();assert.deepEqual(actual,run);validateRun(actual,catalog); }
    async function start(seed) {
      await page.goto(base);await page.waitForSelector('#new-run');await page.locator('#run-seed').fill(seed);await page.locator('#new-run button[type=submit]').click();
      if(await page.locator('#replace-save').isVisible())await page.locator('#confirm-new').click();
      run=createRun(catalog,seed);await page.waitForSelector('[data-node="shop-0"]');await matches();
    }
    async function resume() {await page.reload();await page.waitForSelector('#continue-run');await page.locator('#continue-run').click();}
    async function settle() {
      let count=0;
      while(run.battle.outcome==='playing'&&activeUnit(run.battle)?.team==='enemy'){
        const result=applyCommand(run.battle,chooseTacticalCommand(run.battle));assert(result.ok,result.reason);run=withBattle(run,result.state);assert(++count<40);
      }
      await page.waitForFunction(expected=>{const root=document.querySelector('#battle-root');return root&&root.dataset.busy==='false'&&root.dataset.active===String(expected.active??'')&&root.dataset.round===String(expected.round)&&root.dataset.outcome===expected.outcome&&!document.querySelector('#pause').disabled;},{active:activeUnit(run.battle)?.id,round:run.battle.round,outcome:run.battle.outcome});
      await matches();
      const actual=await page.locator('[data-unit]').evaluateAll(buttons=>buttons.map(button=>({id:Number(button.dataset.unit),hp:Number(button.dataset.hp),x:Number(button.dataset.x),y:Number(button.dataset.y),held:button.dataset.held})));
      assert.deepEqual(actual,run.battle.units.map(unit=>({id:unit.id,hp:unit.hp,x:unit.x,y:unit.y,held:unit.heldItem??''})));
    }
    async function enter(id) {await page.locator(`[data-node="${id}"]`).click();run=enterRoom(run,id,catalog);if(run.status==='combat')await settle();else{await page.waitForSelector('#leave-service');await matches();}}
    async function leave() {await page.locator('#leave-service').click();run=leaveService(run,catalog);await matches();}
    async function transaction(event,selector) {await page.locator(selector).click();run=performRunEvent(run,event,catalog);await matches();}
    async function bag() {if(await page.locator('#tab-bag').count())await page.locator('#tab-bag').click();else await page.locator('#open-bag').click();await page.waitForSelector('#manage-member');}
    async function member(id) {await page.locator('#manage-member').selectOption(String(id));assert.equal(await page.locator('#manage-member').inputValue(),String(id));}
    async function issue(command) {
      if(command.kind==='finish'){await page.locator('#finish-turn').click();if(command.facing!==undefined)await page.locator(`#facing-controls [data-facing="${command.facing}"]`).click();}
      else if(command.kind==='move'){await page.locator('#mode-move').click();await page.locator(`[data-cell="${command.destination.x},${command.destination.y}"]`).click();}
      else{await page.locator(`[data-action="${command.actionId||'basic'}"]`).click();const target=run.battle.units.find(unit=>unit.id===command.target);await page.locator(`[data-cell="${target.x},${target.y}"]`).click();}
      await page.locator('#confirm').click();const result=applyCommand(run.battle,command);assert(result.ok,result.reason);run=withBattle(run,result.state);await settle();
    }
    async function fight() {let count=0;while(run.battle.outcome==='playing'){await issue(chooseTacticalCommand(run.battle));assert(++count<300);}await page.locator('#play-again').click();run=completeEncounter(run,catalog);await matches();}
    async function installFixture(fixture) {
      validateRun(fixture,catalog);await page.evaluate(({key,run,version})=>localStorage.setItem(key,JSON.stringify({schema:'pokemon-tactics/run',version,run})),{key:SAVE_KEY,run:fixture,version:SAVE_VERSION});run=fixture;await resume();await matches();
    }
    await start('route-79');assert.equal(await page.locator('[data-node]').count(),22);assert.equal(await page.locator('[data-node]:enabled').count(),2);await capture('route-desktop');
    pass('Three initial members and seeded combat maps join a connected shop/recruit route');
    await page.locator('[data-node="shop-0"]').focus();await page.keyboard.press('Enter');run=enterRoom(run,'shop-0',catalog);await matches();await capture('shop-desktop');
    await transaction({kind:'buy',itemId:'leftovers'},'[data-buy="leftovers"]');await transaction({kind:'buy',itemId:'potion'},'[data-buy="potion"]');
    assert(await page.locator('[data-buy="leftovers"]').isDisabled());assert.equal(run.money,80);pass('Keyboard enters shop; purchases charge exact prices and limited stock becomes unavailable');
    await resume();await matches();assert(await page.locator('[data-buy="leftovers"]').isDisabled());pass('Reload during a visit retains money, bag and remaining stock without rerolling');
    await bag();await member(1);await transaction({kind:'equip',memberId:1,itemId:'leftovers'},'[data-equip="leftovers"]');await capture('bag-desktop');
    await transaction({kind:'equip',memberId:1,itemId:null},'[data-equip=""]');await transaction({kind:'equip',memberId:1,itemId:'leftovers'},'[data-equip="leftovers"]');
    assert.equal(run.bag.leftovers,0);pass('Equip, remove and re-equip conserve one copy of the item and its single slot');
    await leave();assert.equal(await page.locator('[data-node="shop-0"]').isEnabled(),false);await enter('1-1');await capture('held-item-battle');
    assert.equal(await page.locator('[data-unit="1"]').getAttribute('data-held'),'leftovers');await fight();assert.equal(run.money,180);pass('Held item reaches combat and a real victory grants the reward once');
    await bag();await member(2);const wounded=run.roster.find(member=>member.id===2).hp;await transaction({kind:'heal',memberId:2,itemId:'potion'},'[data-heal="potion"]');assert.equal(run.roster.find(member=>member.id===2).hp,Math.min(48,wounded+20));
    await resume();await matches();pass('Outside-combat healing previews and consumes once; reload retains the healed HP');
    await enter('recruit-1');const offers=run.nodes.find(node=>node.id==='recruit-1').offers;await capture('recruit-desktop');
    const beforeOptional=await saved();await page.locator(`[data-replace-recruit="${offers[0].id}"]`).click();await page.keyboard.press('Escape');assert.deepEqual(await saved(),beforeOptional);assert.equal(await page.locator(`[data-replace-recruit="${offers[0].id}"]`).evaluate(element=>element===document.activeElement),true);pass('Optional early substitution cancels without charge and restores its exact trigger focus');
    for(const offer of offers.slice(0,2))await transaction({kind:'recruit',offerId:offer.id,replaceId:null},`[data-recruit="${offer.id}"]`);
    assert.equal(run.roster.length,5);assert(await page.locator(`[data-recruit="${offers[2].id}"]`).isDisabled());await resume();await matches();pass('Recruitment adds new identities, limits each offer to one use and blocks insufficient money');
    await leave();await enter('2-2');assert.equal(run.battle.units.filter(unit=>unit.team==='ally').length,5);await fight();
    await enter('recruit-2');const sixth=run.nodes.find(node=>node.id==='recruit-2').offers[0];await transaction({kind:'recruit',offerId:sixth.id,replaceId:null},`[data-recruit="${sixth.id}"]`);await leave();await enter('3-2');
    assert.equal(run.battle.units.filter(unit=>unit.team==='ally').length,6);await capture('six-allies');await page.setViewportSize({width:390,height:844});await capture('six-allies-mobile');assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));await page.setViewportSize({width:1440,height:1000});
    pass('Six allies deploy with separate sprites, complete initiative and a usable mobile HUD');
    await fight();assert(run.departed.some(member=>member.reason==='fallen'));await capture('casualties');await bag();
    const options=await page.locator('#manage-member option').evaluateAll(options=>options.map(option=>Number(option.value)));assert(run.departed.every(member=>!options.includes(member.id)));await resume();await matches();pass('Real casualties leave the active team and cannot be selected for healing after reload');
    // Full-roster replacement edge case: valid synthetic combat receipts preserve all six members.
    let fixture=enterRoom(createRun(catalog,'replacement-qa'),'recruit-0',catalog);
    for(const offer of fixture.nodes.find(node=>node.id==='recruit-0').offers)fixture=performRunEvent(fixture,{kind:'recruit',offerId:offer.id,replaceId:null},catalog);
    const receipt=r=>performRunEvent(r,{kind:'result',nodeId:r.currentNodeId,outcome:'victory',round:2,hp:r.roster.map(member=>({id:member.id,hp:member.hp}))},catalog);
    fixture=receipt(enterEncounter(leaveService(fixture,catalog),'1-1',catalog));fixture=enterRoom(fixture,'shop-1',catalog);fixture=performRunEvent(fixture,{kind:'buy',itemId:'heavy-duty-boots'},catalog);fixture=performRunEvent(fixture,{kind:'equip',itemId:'heavy-duty-boots',memberId:1},catalog);
    fixture=receipt(enterEncounter(leaveService(fixture,catalog),'2-1',catalog));fixture=enterRoom(fixture,'recruit-2',catalog);await installFixture(fixture);const replacement=run.nodes.find(node=>node.id==='recruit-2').offers[0];
    const original=await saved();await page.locator(`[data-recruit="${replacement.id}"]`).click();await page.keyboard.press('Escape');assert.deepEqual(await saved(),original);assert.equal(await page.locator(`[data-recruit="${replacement.id}"]`).evaluate(element=>element===document.activeElement),true);
    await page.locator(`[data-recruit="${replacement.id}"]`).click();await page.locator('#cancel-recruit').click();assert.deepEqual(await saved(),original);pass('Replacement preview and cancellation/Escape preserve roster, offer, equipment and money');
    await page.locator(`[data-recruit="${replacement.id}"]`).click();await page.locator('#replace-member').selectOption('1');await page.setViewportSize({width:390,height:844});await capture('replacement-mobile');assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));await page.setViewportSize({width:1440,height:1000});await capture('replacement-desktop');
    await transaction({kind:'recruit',offerId:replacement.id,replaceId:1},'#confirm-recruit');assert.equal(run.roster.length,6);assert.equal(run.bag['heavy-duty-boots'],1);assert.equal(run.departed.find(member=>member.id===1).reason,'released');await resume();await matches();pass('Confirmed replacement charges once, returns gear and preserves the new member after reload');
    // Complete six real encounters with the unchanged sprint-5 policy/seed and skip service spending.
    await start('route-79');for(let floor=1;floor<=6;floor++){await enter(`shop-${floor-1}`);await leave();await enter(`${floor}-${floor===1||floor===6?1:2}`);await fight();assert.notEqual(run.status,'defeat');}
    assert.equal(run.status,'victory');assert.equal(run.money,840);await capture('victory');await resume();await matches();pass('Six real combats reach the provisional final with exactly six rewards and persistent losses');
    const old=legacyEnter(legacyRun(catalog,'legacy-qa'),'1-1',catalog);old.battle.units.forEach(unit=>delete unit.heldItem);const oldRaw=JSON.stringify({schema:'pokemon-tactics/run',version:1,run:old});await page.evaluate(({key,raw})=>localStorage.setItem(key,raw),{key:SAVE_KEY,raw:oldRaw});run=migrateLegacyRun(old,catalog);await page.reload();await page.waitForSelector('#continue-run');assert.equal(await page.evaluate(key=>localStorage.getItem(key),LEGACY_BACKUP_KEY),oldRaw);await page.locator('#continue-run').click();await settle();pass('Version-1 ongoing fight migrates with its original backup and preserves battle progress');
    const forged=await saved();forged.money++;const corruptRaw=JSON.stringify({schema:'pokemon-tactics/run',version:SAVE_VERSION,run:forged});await page.evaluate(({key,raw})=>localStorage.setItem(key,raw),{key:SAVE_KEY,raw:corruptRaw});await page.reload();await page.waitForSelector('#discard-save');assert.equal(await page.evaluate(key=>localStorage.getItem(key),SAVE_KEY),corruptRaw);await page.locator('#discard-save').click();pass('A corrupted economic total is rejected without overwriting the save until explicit discard');
    await start('long-'+'a'.repeat(59));await enter('shop-0');await page.setViewportSize({width:390,height:844});await capture('shop-mobile');assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));await bag();await capture('bag-mobile');assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));await page.setViewportSize({width:1440,height:1000});pass('Shop and bag support long seeds, native controls, keyboard focus and mobile without overflow');
    await page.locator('#run-menu').click();await page.locator('#continue-run').click();const other=await context.newPage();await other.goto(base);await other.waitForSelector('#new-run');await other.locator('#run-seed').fill('another-tab');await other.locator('#new-run button[type=submit]').click();await other.locator('#confirm-new').click();await other.waitForSelector('[data-node="shop-0"]');await page.locator('#tab-service').click();await page.locator('[data-buy="potion"]').click();await page.waitForSelector('#reload-save');assert.equal((await saved()).seed,'another-tab');await other.close();pass('A stale shopping tab cannot replace the latest run or debit its money');
    assert.deepEqual(errors,[]);assert.deepEqual(external,[]);pass('Gameplay visits have no JavaScript errors or external asset requests');
    fs.writeFileSync(path.join(output,'browser-results.json'),JSON.stringify({browser:'Microsoft Edge headless / Playwright',url:base,checks,consoleErrors:errors,externalRequests:external,syntheticFixtures:'Full-roster replacement only; gameplay encounters and final are reached with legal real commands.'},null,2)+'\n');console.log(`${checks.length} browser checks passed.`);
  } finally { await browser.close(); }
})().catch(error=>{console.error(error);process.exitCode=1;});
